"""Load the staged AFCON 1957-2000 tournaments into the vault.

    python3 load_afcon_pre2002.py raw/afcon_pre2002/canon_afcon_pre2002.json          # dry run
    python3 load_afcon_pre2002.py raw/afcon_pre2002/canon_afcon_pre2002.json --commit

Without --commit everything runs inside a transaction that is rolled back, and
the summary printed is exactly what committing would do.

Decisions this encodes (see AFCON_PRE2002.md for the alternatives):

* **Extra time.** RSSSF gives only the result after extra time, so it is
  written to both the score and the extra-time columns. The 90-minute score is
  unknown, not zero, and a later source can correct it.
* **Shoot-outs** go to `*_score_pens`, from either written form.
* **Matches that were never played** (1957 South Africa's disqualification,
  1978 Tunisia's walk-off) are recorded as CANCELLED with no score, so the
  fixture exists but no invented result reaches a table.
* **1959 and 1976 were decided by a final round-robin**, so those matches load
  as group matches in a group called "Final" -- a table, which is what it was,
  rather than a bracket.
* **Own goals.** RSSSF lists a goal under the side it COUNTS FOR. The vault
  stores an OWN_GOAL under the scorer's OWN team (design principle 5), so the
  side is flipped here. This is the same trap the 2026-09-12 ligikuu
  correction had to undo.
* **Scorers load only where they reconcile** with the stored score: 264 of 352
  played matches. The rest load as results, and the audit reports them as
  missing their event log, which is true.
"""
import json
import re
import sys
from collections import defaultdict
from datetime import datetime, timezone

import psycopg2
import psycopg2.extras

DSN = "host=127.0.0.1 port=5432 dbname=sokabrain"
COMPETITION_ID = 16          # Africa Cup of Nations
SOURCE = "rsssf"

# The names these sides played under, mapped to the vault's spelling. The
# vault misspells two of them; nationnames.py explains why those stand.
TEAMS = {
    "Congo-Léopoldville": "DR Congo", "Congo (Kinshasa)": "DR Congo", "Zaire": "DR Congo",
    "Congo (Brazzaville)": "Congo", "Congo": "Congo",
    "Upper Volta": "Burkina Faso",
    "Morocco": "Morroco", "Sierra Leone": "Sierra Leon",
}

STAGE_ROUND = {
    "GROUP": "GROUP", "FINAL ROUND": "GROUP", "QUARTER FINAL": "QUARTER FINAL",
    "SEMI FINAL": "SEMI FINAL", "THIRD PLACE": "THIRD PLACE", "FINAL": "FINAL",
}


def shootout(match):
    """Penalties as (home, away), from either written form."""
    blob = " ".join(match["notes"])
    inline = re.search(r"(\d{1,2})\s*-\s*(\d{1,2})\s*pen", blob, re.I)
    if inline:
        return int(inline.group(1)), int(inline.group(2))
    prose = re.search(r"([A-Za-zÀ-ÿ'. -]+?)\s+(?:won|win)\s+(\d{1,2})\s*-\s*(\d{1,2})\s+on pen", blob, re.I)
    if prose:
        winner, a, b = prose.group(1).strip(), int(prose.group(2)), int(prose.group(3))
        hi, lo = max(a, b), min(a, b)
        return (hi, lo) if winner.lower() in match["home"].lower() else (lo, hi)
    return None


def aet(match):
    return any(re.search(r"\baet\b", n, re.I) for n in match["notes"])


class Loader:
    def __init__(self, conn):
        self.c = conn.cursor()
        self.stats = defaultdict(int)
        self.c.execute("SELECT id FROM data_sources WHERE name = %s", (SOURCE,))
        self.source_id = self.c.fetchone()[0]
        self.c.execute("SELECT id, name FROM teams WHERE type = 'NATIONAL'")
        self.teams = {name: tid for tid, name in self.c.fetchall()}
        self.players = {}

    def team(self, name):
        vault = TEAMS.get(name, name)
        if vault not in self.teams:
            raise SystemExit(f"No national team in the vault for '{name}' (looked for '{vault}')")
        return self.teams[vault]

    def provenance(self, entity_type, entity_id, external_id):
        self.c.execute(
            """INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
               VALUES (%s, %s, %s, %s, 1.0)
               ON CONFLICT (entity_type, data_source_id, external_id) DO UPDATE SET last_synced_at = now()""",
            (entity_type, entity_id, self.source_id, external_id))

    def season(self, label):
        self.c.execute("SELECT id FROM seasons WHERE label = %s", (label,))
        row = self.c.fetchone()
        if row:
            return row[0]
        self.c.execute("INSERT INTO seasons (label) VALUES (%s) RETURNING id", (label,))
        self.stats["seasons created"] += 1
        return self.c.fetchone()[0]

    def player(self, name, team_id):
        """An existing player of the same name who already played for this
        country, or a new one. Name alone is too weak: 'Hossam Hassan' spans
        both sides of 2002."""
        key = (name.lower(), team_id)
        if key in self.players:
            return self.players[key]
        # A surname on its own is not enough to say two players are the same
        # person: "Touré" scoring for Ivory Coast in 1992 and in 2006 is two
        # careers as easily as one. Only a name with at least two parts can
        # join an existing player; anything shorter starts its own record.
        row = None
        if len(name.split()) > 1:
            self.c.execute(
                """SELECT p.id FROM players p
                    WHERE lower(p.full_name) = lower(%s)
                      AND EXISTS (SELECT 1 FROM match_events e WHERE e.player_id = p.id AND e.team_id = %s)
                    LIMIT 1""", (name, team_id))
            row = self.c.fetchone()
        elif self.c.execute(
                """SELECT 1 FROM players p WHERE lower(p.full_name) = lower(%s)
                    AND EXISTS (SELECT 1 FROM match_events e WHERE e.player_id = p.id AND e.team_id = %s)
                    LIMIT 1""", (name, team_id)) or self.c.fetchone():
            self.stats["one-name players kept separate from a same-named existing player"] += 1
        if row:
            pid = row[0]
            self.stats["players matched to existing"] += 1
        else:
            self.c.execute("INSERT INTO players (full_name) VALUES (%s) RETURNING id", (name,))
            pid = self.c.fetchone()[0]
            self.provenance("player", pid, f"afcon-{name}")
            self.stats["players created"] += 1
        self.players[key] = pid
        return pid

    def tournament(self, t):
        year = str(t["year"])
        season_id = self.season(year)
        self.c.execute(
            "SELECT id FROM competition_editions WHERE competition_id = %s AND season_id = %s",
            (COMPETITION_ID, season_id))
        if self.c.fetchone():
            print(f"  {year}: already in the vault, skipped")
            self.stats["editions skipped"] += 1
            return

        teams = {n for m in t["matches"] for n in (m["home"], m["away"])}
        stages = {m["stage"] for m in t["matches"]}
        fmt = ("ROUND_ROBIN" if stages <= {"GROUP", "FINAL ROUND"} and len(teams) <= 4
               else "KNOCKOUT" if "GROUP" not in stages and "FINAL ROUND" not in stages
               else "GROUPS_KNOCKOUT")
        self.c.execute(
            """INSERT INTO competition_editions (competition_id, season_id, format, num_teams, is_published)
               VALUES (%s, %s, %s, %s, FALSE) RETURNING id""",
            (COMPETITION_ID, season_id, fmt, len(teams)))
        edition_id = self.c.fetchone()[0]
        self.provenance("competition_edition", edition_id, f"afcon-{year}")
        self.stats["editions created"] += 1

        # Groups. A final round-robin is a group called "Final" (the column
        # holds 10 characters, and "Group A" reads as "A").
        groups = {}
        for m in t["matches"]:
            label = "Final" if m["stage"] == "FINAL ROUND" else m["group"]
            if not label or label in groups:
                continue
            self.c.execute(
                "INSERT INTO competition_groups (competition_edition_id, name) VALUES (%s, %s) RETURNING id",
                (edition_id, label))
            groups[label] = self.c.fetchone()[0]
            self.stats["groups created"] += 1

        # Participants, each in the group they played in.
        entered = {}
        for m in t["matches"]:
            label = "Final" if m["stage"] == "FINAL ROUND" else m["group"]
            for name in (m["home"], m["away"]):
                if name not in entered or (label and entered[name] is None):
                    entered[name] = groups.get(label) if label else entered.get(name)
        for name, group_id in entered.items():
            self.c.execute(
                """INSERT INTO competition_edition_teams (competition_edition_id, team_id, group_id)
                   VALUES (%s, %s, %s) ON CONFLICT DO NOTHING""",
                (edition_id, self.team(name), group_id))
            self.stats["participants"] += 1

        for i, m in enumerate(t["matches"], start=1):
            self.match(edition_id, groups, m, f"afcon-{year}-{i:02d}")

    def match(self, edition_id, groups, m, external_id):
        home_id, away_id = self.team(m["home"]), self.team(m["away"])
        label = "Final" if m["stage"] == "FINAL ROUND" else m["group"]
        played = not (m["walkover"] or m["abandoned"]) and m["homeScore"] is not None
        pens = shootout(m) if played else None
        extra = aet(m) and played
        kickoff = datetime.strptime(m["date"], "%Y-%m-%d").replace(tzinfo=timezone.utc)

        self.c.execute(
            """INSERT INTO matches (competition_edition_id, group_id, round, home_team_id, away_team_id,
                                    kickoff_at, status, home_score, away_score,
                                    home_score_et, away_score_et, home_score_pens, away_score_pens)
               VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s) RETURNING id""",
            (edition_id, groups.get(label), STAGE_ROUND[m["stage"]], home_id, away_id, kickoff,
             "FULL_TIME" if played else "CANCELLED",
             m["homeScore"] if played else None, m["awayScore"] if played else None,
             m["homeScore"] if extra else None, m["awayScore"] if extra else None,
             pens[0] if pens else None, pens[1] if pens else None))
        match_id = self.c.fetchone()[0]
        self.provenance("match", match_id, external_id)
        self.stats["matches" if played else "matches not played (cancelled)"] += 1
        if extra:
            self.stats["matches after extra time"] += 1
        if pens:
            self.stats["shoot-outs"] += 1

        for n, goal in enumerate(m["goals"] or [], start=1):
            scored_for = home_id if goal["side"] == "home" else away_id
            # RSSSF lists an own goal under the side it counts for; the vault
            # stores it under the scorer's own team.
            team_id = (away_id if goal["side"] == "home" else home_id) if goal["own"] else scored_for
            kind = "OWN_GOAL" if goal["own"] else "PENALTY_GOAL" if goal["penalty"] else "GOAL"
            player_id = self.player(goal["name"], team_id) if goal["name"] else None
            self.c.execute(
                """INSERT INTO match_events (match_id, team_id, player_id, minute, type, detail)
                   VALUES (%s,%s,%s,%s,%s,%s) RETURNING id""",
                (match_id, team_id, player_id, goal["minute"], kind,
                 psycopg2.extras.Json({"source": SOURCE})))
            self.provenance("match_event", self.c.fetchone()[0], f"{external_id}-g{n}")
            self.stats[f"events: {kind}"] += 1


def verify(loader):
    """Checks run inside the transaction, against what was actually written."""
    c = loader.c
    print("\nChecks on the loaded rows:")

    # The event log must reproduce the score, with own goals credited to the
    # other side — the same arithmetic the read side and the audit use.
    c.execute("""
        WITH ev AS (
          SELECT m.id,
            count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL') AND
              (CASE WHEN e.type='OWN_GOAL' THEN CASE WHEN e.team_id=m.home_team_id THEN m.away_team_id ELSE m.home_team_id END
                    ELSE e.team_id END) = m.home_team_id)::int AS h,
            count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL') AND
              (CASE WHEN e.type='OWN_GOAL' THEN CASE WHEN e.team_id=m.home_team_id THEN m.away_team_id ELSE m.home_team_id END
                    ELSE e.team_id END) = m.away_team_id)::int AS a
          FROM matches m JOIN match_events e ON e.match_id = m.id
          JOIN competition_editions ce ON ce.id = m.competition_edition_id
          JOIN seasons s ON s.id = ce.season_id
          WHERE ce.competition_id = %s AND s.label ~ '^[0-9]{4}$' AND s.label::int < 2002
          GROUP BY m.id)
        SELECT count(*), count(*) FILTER (WHERE ev.h = m.home_score AND ev.a = m.away_score)
          FROM ev JOIN matches m ON m.id = ev.id""", (COMPETITION_ID,))
    total, agree = c.fetchone()
    print(f"  event logs that reproduce their score: {agree} of {total}")

    c.execute("""
        SELECT s.label, count(*) FILTER (WHERE m.status='FULL_TIME'), count(*),
               (SELECT count(*) FROM competition_edition_teams t WHERE t.competition_edition_id = ce.id)
          FROM competition_editions ce JOIN seasons s ON s.id = ce.season_id
          LEFT JOIN matches m ON m.competition_edition_id = ce.id
         WHERE ce.competition_id = %s AND s.label ~ '^[0-9]{4}$' AND s.label::int < 2002
         GROUP BY s.label, ce.id ORDER BY s.label""", (COMPETITION_ID,))
    rows = c.fetchall()
    print(f"  editions loaded: {len(rows)} — " + ", ".join(f"{r[0]}:{r[2]}m/{r[3]}t" for r in rows[:6]) + " …")

    c.execute("""SELECT count(*) FROM competition_editions ce JOIN seasons s ON s.id=ce.season_id
                  WHERE ce.competition_id=%s AND s.label ~ '^[0-9]{4}$' AND s.label::int < 2002 AND ce.is_published""", (COMPETITION_ID,))
    print(f"  editions published (must be 0): {c.fetchone()[0]}")

    c.execute("""SELECT p.full_name FROM players p
                  JOIN match_events e ON e.player_id = p.id
                  JOIN matches m ON m.id = e.match_id
                  JOIN competition_editions ce ON ce.id = m.competition_edition_id
                  JOIN seasons s ON s.id = ce.season_id
                 WHERE ce.competition_id=%s AND s.label ~ '^[0-9]{4}$' AND s.label::int < 2002
                   AND EXISTS (SELECT 1 FROM match_events e2 JOIN matches m2 ON m2.id=e2.match_id
                               JOIN competition_editions ce2 ON ce2.id=m2.competition_edition_id
                               JOIN seasons s2 ON s2.id=ce2.season_id
                               WHERE e2.player_id=p.id AND (s2.label !~ '^[0-9]{4}$' OR s2.label::int >= 2002))
                 GROUP BY p.full_name ORDER BY p.full_name""", (COMPETITION_ID,))
    shared = [r[0] for r in c.fetchall()]
    print(f"  players shared with 2002+ AFCON: {len(shared)} — {', '.join(shared)}")

    c.execute("""SELECT count(*) FROM matches m JOIN competition_editions ce ON ce.id=m.competition_edition_id
                  JOIN seasons s ON s.id=ce.season_id
                 WHERE ce.competition_id=%s AND s.label ~ '^[0-9]{4}$' AND s.label::int < 2002 AND m.home_team_id = m.away_team_id""",
              (COMPETITION_ID,))
    print(f"  teams playing themselves (must be 0): {c.fetchone()[0]}")


def main(path, commit):
    tournaments = json.load(open(path))
    conn = psycopg2.connect(DSN)
    loader = Loader(conn)
    try:
        for t in tournaments:
            loader.tournament(t)
        verify(loader)
        print()
        for k in sorted(loader.stats):
            print(f"  {loader.stats[k]:6,}  {k}")
        if commit:
            conn.commit()
            print("\nCOMMITTED")
        else:
            conn.rollback()
            print("\nrolled back (dry run) — pass --commit to apply")
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


if __name__ == "__main__":
    main(sys.argv[1], "--commit" in sys.argv)
