"""Attach Wikipedia's 1996 and 1998 AFCON scorers to matches the vault already has.

    python3 load_wikipedia_afcon_scorers.py raw/afcon_wikipedia/canon.json           # dry run
    python3 load_wikipedia_afcon_scorers.py raw/afcon_wikipedia/canon.json --commit

Without --commit everything runs in a transaction that is rolled back, and the
summary printed is exactly what committing would do.

This loader creates **no matches and no scores**. The vault already holds all 61
of these fixtures from RSSSF; what it lacks is who scored, because RSSSF names a
scorer for 4 of the 171 goals. So every match here must already exist, and its
stored score must agree with Wikipedia's, or that match is skipped.

Decisions this encodes:

* **The vault's own orientation wins.** The two sources disagree about which
  side was home in 18 of the 61 matches. Where the score agrees once flipped,
  the goals are mapped onto the vault's sides; the fixture is never rewritten.
* **Own goals** are stored under the scorer's OWN team (design principle 5).
  Wikipedia lists them under the side they count for, which is the same trap
  RSSSF and ligikuu set.
* **A match that already has goal events is skipped, never added to.** Both
  finals have their scorers from RSSSF already. They are reported with whether
  Wikipedia agrees, which is a cross-source check worth seeing, but nothing is
  written over them.
* **Scorers load only where the goal list reconciles with the stored score**,
  the same gate as load_afcon_pre2002.py.
* **Player identity is decided by playermatch.py**, which refuses a match it
  cannot justify. Creating a duplicate costs a record the audit will raise;
  claiming the wrong man silently moves goals onto him.
"""
import json
import sys
from collections import defaultdict
from datetime import datetime

import psycopg2

from playermatch import fold, resolve, words

DSN = "host=127.0.0.1 port=5432 dbname=sokabrain"
COMPETITION_ID = 16
SOURCE = "wikipedia"


class Loader:
    def __init__(self, conn):
        self.c = conn.cursor()
        self.stats = defaultdict(int)
        self.notes = []
        self.c.execute("SELECT id FROM data_sources WHERE name = %s", (SOURCE,))
        row = self.c.fetchone()
        if not row:
            raise SystemExit(f"No data_sources row named '{SOURCE}'")
        self.source_id = row[0]
        self.c.execute("SELECT id, name FROM teams WHERE type = 'NATIONAL'")
        self.team_ids = {name: tid for tid, name in self.c.fetchall()}
        self.c.execute("""
            SELECT DISTINCT p.id, p.full_name, e.team_id
              FROM match_events e JOIN players p ON p.id = e.player_id
              JOIN teams t ON t.id = e.team_id
             WHERE t.type = 'NATIONAL' AND e.type IN ('GOAL','PENALTY_GOAL')
        """)
        self.candidates = defaultdict(list)
        for pid, name, team_id in self.c.fetchall():
            self.candidates[team_id].append((pid, name))
        self.resolved = {}
        self.surname_counts = defaultdict(int)

    def provenance(self, entity_type, entity_id, external_id):
        self.c.execute(
            """INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
               VALUES (%s, %s, %s, %s, 1.0)
               ON CONFLICT (entity_type, data_source_id, external_id) DO UPDATE SET last_synced_at = now()""",
            (entity_type, entity_id, self.source_id, external_id))

    def count_surnames(self, staged):
        """How many different incoming players share a surname within a team."""
        seen = defaultdict(set)
        for m in staged:
            for g in m["goals"]:
                side = g["side"]
                if g["type"] == "OWN_GOAL":
                    side = "away" if side == "home" else "home"
                team_id = self.team_ids[m[side]]
                w = words(g["player"])
                if w:
                    seen[(team_id, w[-1])].add(fold(g["player"]))
        self.surname_counts = {k: len(v) for k, v in seen.items()}

    def player(self, name, team_id):
        key = (team_id, fold(name))
        if key in self.resolved:
            return self.resolved[key]
        per_team = {sn: n for (tid, sn), n in self.surname_counts.items() if tid == team_id}
        how, pid = resolve(name, self.candidates.get(team_id, []), per_team)
        if pid is None:
            self.c.execute("INSERT INTO players (full_name) VALUES (%s) RETURNING id", (name,))
            pid = self.c.fetchone()[0]
            # Keyed on the country too: two players called Traoré for different
            # nations are two people, and a shared key would leave the second
            # with no provenance row at all.
            self.provenance("player", pid, f"wikipedia-afcon-{team_id}-{name}")
            self.stats["players created"] += 1
            # A player created now is a candidate for the next name, so a second
            # spelling in the same tournament lands on him rather than a third row.
            self.candidates[team_id].append((pid, name))
        else:
            self.stats[f"players matched to existing ({how})"] += 1
            self.provenance("player", pid, f"wikipedia-afcon-{team_id}-{name}")
        self.resolved[key] = pid
        return pid

    def goals_for(self, m, vault, same_way):
        """Wikipedia's goals, mapped onto the vault's home/away."""
        out = []
        for g in m["goals"]:
            side = g["side"] if same_way else ("away" if g["side"] == "home" else "home")
            counts_for = vault["home_id"] if side == "home" else vault["away_id"]
            other = vault["away_id"] if side == "home" else vault["home_id"]
            # The scorer of an own goal plays for the side it does NOT count for.
            scorer_team = other if g["type"] == "OWN_GOAL" else counts_for
            out.append({**g, "team_id": scorer_team, "counts_for": counts_for})
        return out

    def match(self, m, vault, same_way):
        goals = self.goals_for(m, vault, same_way)
        for n, g in enumerate(goals, 1):
            pid = self.player(g["player"], g["team_id"])
            detail = json.dumps({"goldenGoal": True}) if g.get("golden") else None
            self.c.execute(
                """INSERT INTO match_events (match_id, team_id, player_id, minute, type, detail)
                   VALUES (%s, %s, %s, %s, %s, %s) RETURNING id""",
                (vault["id"], g["team_id"], pid, g["minute"], g["type"], detail))
            self.provenance("match_event", self.c.fetchone()[0], f"wikipedia-afcon-{vault['id']}-g{n}")
            self.stats[f"events written ({g['type']})"] += 1
        self.stats["matches given scorers"] += 1


def vault_matches(cur, years):
    cur.execute("""
        SELECT m.id, s.label, m.kickoff_at::date, m.home_team_id, ht.name, m.away_team_id, at.name,
               m.home_score, m.away_score,
               (SELECT count(*) FROM match_events e WHERE e.match_id = m.id
                 AND e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL')) AS goal_events
          FROM matches m
          JOIN competition_editions ce ON ce.id = m.competition_edition_id
          JOIN seasons s ON s.id = ce.season_id
          JOIN teams ht ON ht.id = m.home_team_id JOIN teams at ON at.id = m.away_team_id
         WHERE ce.competition_id = %s AND s.label = ANY(%s)
    """, (COMPETITION_ID, [str(y) for y in years]))
    keys = ["id", "season", "date", "home_id", "home", "away_id", "away", "hs", "as", "events"]
    return [dict(zip(keys, r)) for r in cur.fetchall()]


def verify(loader, years):
    c = loader.c
    print("\nChecks on the loaded rows:")
    c.execute("""
        WITH ev AS (
          SELECT m.id,
            count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL') AND
              (CASE WHEN e.type='OWN_GOAL'
                    THEN CASE WHEN e.team_id=m.home_team_id THEN m.away_team_id ELSE m.home_team_id END
                    ELSE e.team_id END) = m.home_team_id)::int AS h,
            count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL') AND
              (CASE WHEN e.type='OWN_GOAL'
                    THEN CASE WHEN e.team_id=m.home_team_id THEN m.away_team_id ELSE m.home_team_id END
                    ELSE e.team_id END) = m.away_team_id)::int AS a
          FROM matches m JOIN match_events e ON e.match_id = m.id
          JOIN competition_editions ce ON ce.id = m.competition_edition_id
          JOIN seasons s ON s.id = ce.season_id
          WHERE ce.competition_id = %s AND s.label = ANY(%s)
          GROUP BY m.id)
        SELECT count(*), count(*) FILTER (WHERE ev.h = m.home_score AND ev.a = m.away_score)
          FROM ev JOIN matches m ON m.id = ev.id
    """, (COMPETITION_ID, years))
    total, agree = c.fetchone()
    print(f"  event logs that reproduce their score: {agree} of {total}")

    c.execute("""
        SELECT count(*) FROM match_events e JOIN matches m ON m.id = e.match_id
          JOIN competition_editions ce ON ce.id = m.competition_edition_id
          JOIN seasons s ON s.id = ce.season_id
         WHERE ce.competition_id = %s AND s.label = ANY(%s)
           AND (e.team_id IS NULL OR e.team_id NOT IN (m.home_team_id, m.away_team_id))
    """, (COMPETITION_ID, years))
    print(f"  events on a team not in the match (must be 0): {c.fetchone()[0]}")

    c.execute("""
        SELECT count(*) FROM match_events e JOIN matches m ON m.id = e.match_id
          JOIN competition_editions ce ON ce.id = m.competition_edition_id
          JOIN seasons s ON s.id = ce.season_id
         WHERE ce.competition_id = %s AND s.label = ANY(%s)
           AND e.type IN ('GOAL','PENALTY_GOAL') AND e.player_id IS NULL
    """, (COMPETITION_ID, years))
    print(f"  goals still with no scorer (must be 0): {c.fetchone()[0]}")

    c.execute("""
        SELECT p.full_name, count(DISTINCT e.team_id)
          FROM match_events e JOIN players p ON p.id = e.player_id
          JOIN teams t ON t.id = e.team_id
         WHERE t.type = 'NATIONAL' AND e.type IN ('GOAL','PENALTY_GOAL')
         GROUP BY p.id, p.full_name HAVING count(DISTINCT e.team_id) > 1
    """)
    rows = c.fetchall()
    print(f"  players scoring for two nations (must be 0): {len(rows)}"
          + (f" -- {rows}" if rows else ""))

    c.execute("""
        SELECT count(*) FROM players p
         WHERE NOT EXISTS (SELECT 1 FROM entity_source_map m
                            WHERE m.entity_type = 'player' AND m.entity_id = p.id)
    """)
    print(f"  players with no provenance anywhere (must be 0): {c.fetchone()[0]}")

    c.execute("""
        SELECT s.label, count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL'))
          FROM match_events e JOIN matches m ON m.id = e.match_id
          JOIN competition_editions ce ON ce.id = m.competition_edition_id
          JOIN seasons s ON s.id = ce.season_id
         WHERE ce.competition_id = %s AND s.label = ANY(%s)
         GROUP BY s.label ORDER BY s.label
    """, (COMPETITION_ID, years))
    for label, n in c.fetchall():
        print(f"  {label}: {n} goal events")


def main(path, commit):
    staged = json.load(open(path))
    years = sorted({str(m["year"]) for m in staged})
    conn = psycopg2.connect(DSN)
    conn.autocommit = False
    cur = conn.cursor()
    cur.execute("SET timezone = 'UTC'")
    loader = Loader(conn)
    loader.count_surnames(staged)

    vault = vault_matches(cur, years)
    by_pair = defaultdict(list)
    for v in vault:
        by_pair[tuple(sorted([v["home"], v["away"]]))].append(v)

    skipped = []
    for m in staged:
        want = datetime.strptime(m["date"], "%d %B %Y").date()
        cands = [v for v in by_pair.get(tuple(sorted([m["home"], m["away"]])), [])
                 if abs((v["date"] - want).days) <= 1]
        label = f"{m['year']} {m['date']} {m['home']} {m['homeScore']}-{m['awayScore']} {m['away']}"
        if len(cands) != 1:
            skipped.append(f"{label}: {len(cands)} vault matches")
            continue
        v = cands[0]
        same_way = v["home"] == m["home"]
        expect = (m["homeScore"], m["awayScore"]) if same_way else (m["awayScore"], m["homeScore"])
        if (v["hs"], v["as"]) != expect:
            skipped.append(f"{label}: vault has {v['hs']}-{v['as']} for {v['home']} v {v['away']}")
            continue
        h = sum(1 for g in m["goals"] if g["side"] == "home")
        a = sum(1 for g in m["goals"] if g["side"] == "away")
        if (h, a) != (m["homeScore"], m["awayScore"]):
            skipped.append(f"{label}: goal list reads {h}-{a}, not loading it")
            continue
        if v["events"]:
            names = ", ".join(f"{g['player']} {g['minute']}'" for g in m["goals"])
            skipped.append(f"{label}: match {v['id']} already has {v['events']} goal events, "
                           f"left alone (Wikipedia says {names})")
            continue
        loader.match(m, v, same_way)

    print(f"staged {len(staged)} matches, {sum(len(m['goals']) for m in staged)} goals")
    for k in sorted(loader.stats):
        print(f"  {k}: {loader.stats[k]}")
    if skipped:
        print(f"\nnot loaded ({len(skipped)}):")
        for s in skipped:
            print(f"  {s}")
    verify(loader, years)

    if commit:
        conn.commit()
        print("\nCOMMITTED")
    else:
        conn.rollback()
        print("\nrolled back (dry run) -- pass --commit to apply")
    conn.close()


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    main(sys.argv[1], "--commit" in sys.argv)
