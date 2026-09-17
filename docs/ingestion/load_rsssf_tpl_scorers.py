"""Attach RSSSF's Tanzanian scorers to Premier League matches the vault has.

    python3 load_rsssf_tpl_scorers.py raw/rsssf_tpl/canon.json            # dry run
    python3 load_rsssf_tpl_scorers.py raw/rsssf_tpl/canon.json --commit

Creates no matches and no scores. Every match must already exist, be found by
season and club pair, and agree on the score.

**Only matches whose scorers account for the whole score are loaded.** RSSSF
often names two goals of three; loading those would leave the event log
disagreeing with the score, which is the one invariant the league's data still
holds everywhere. Partial matches are counted and reported, not written.

**A match that already has goal events is left alone**, so this only ever fills
a hole. Cards and lineups are untouched.

Own goals are stored under the scorer's OWN team (design principle 5); RSSSF
lists them under the side they count for, as every other source does.
"""
import json
import sys
from collections import defaultdict

import psycopg2

from playermatch import fold, resolve, words
from teamnames import key as team_key

DSN = "host=127.0.0.1 port=5432 dbname=sokabrain"
COMPETITION_ID = 1
SOURCE = "rsssf"
GOALS = ("GOAL", "PENALTY_GOAL", "OWN_GOAL")


def credited(typ, side):
    if typ == "OWN_GOAL":
        return "away" if side == "home" else "home"
    return side


class Loader:
    def __init__(self, conn):
        self.c = conn.cursor()
        self.stats = defaultdict(int)
        self.skipped = defaultdict(int)
        self.notes = []
        self.c.execute("SELECT id FROM data_sources WHERE name = %s", (SOURCE,))
        self.source_id = self.c.fetchone()[0]
        self.c.execute("""
            SELECT DISTINCT p.id, p.full_name, e.team_id
              FROM match_events e JOIN players p ON p.id = e.player_id
             WHERE e.type IN ('GOAL','PENALTY_GOAL')
        """)
        self.candidates = defaultdict(list)
        for pid, nm, tid in self.c.fetchall():
            self.candidates[tid].append((pid, nm))
        self.resolved = {}
        self.surnames = {}

    def count_surnames(self, pairs):
        seen = defaultdict(set)
        for tid, name in pairs:
            if words(name):
                seen[(tid, words(name)[-1])].add(fold(name))
        self.surnames = {k: len(v) for k, v in seen.items()}

    def provenance(self, entity_type, entity_id, external_id):
        self.c.execute("""
            INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
            VALUES (%s, %s, %s, %s, 1.0)
            ON CONFLICT (entity_type, data_source_id, external_id) DO UPDATE SET last_synced_at = now()
        """, (entity_type, entity_id, self.source_id, external_id))

    def player(self, name, team_id):
        if not name:
            return None
        key = (team_id, fold(name))
        if key in self.resolved:
            return self.resolved[key]
        per = {sn: n for (t, sn), n in self.surnames.items() if t == team_id}
        how, pid = resolve(name, self.candidates.get(team_id, []), per)
        if pid is None:
            self.c.execute("INSERT INTO players (full_name) VALUES (%s) RETURNING id", (name,))
            pid = self.c.fetchone()[0]
            self.candidates[team_id].append((pid, name))
            self.stats["players created"] += 1
        else:
            self.stats[f"players matched to existing ({how})"] += 1
        self.provenance("player", pid, f"rsssf-tpl-{team_id}-{name}")
        self.resolved[key] = pid
        return pid

    def load(self, rec, vault):
        goals = [g for g in rec["goals"] if g["type"] in GOALS]
        tally = defaultdict(int)
        for g in goals:
            tally[credited(g["type"], g["side"])] += 1
        if not goals:
            self.skipped["no scorers in the source"] += 1
            return
        if tally["home"] != rec["homeScore"] or tally["away"] != rec["awayScore"]:
            self.skipped["source names only some of the goals"] += 1
            return
        if vault["events"]:
            self.skipped["vault already has a goal log"] += 1
            return

        for n, g in enumerate(goals, 1):
            # An own goal's scorer plays for the side it does NOT count for.
            side = g["side"]
            scorer_side = ("away" if side == "home" else "home") if g["type"] == "OWN_GOAL" else side
            team_id = vault["home_id"] if scorer_side == "home" else vault["away_id"]
            pid = self.player(g["player"], team_id)
            self.c.execute("""
                INSERT INTO match_events (match_id, team_id, player_id, minute, added_time, type)
                VALUES (%s, %s, %s, %s, %s, %s) RETURNING id
            """, (vault["id"], team_id, pid, g["minute"], g.get("added"), g["type"]))
            self.provenance("match_event", self.c.fetchone()[0], f"tpl-{vault['id']}-g{n}")
            self.stats[f"events written ({g['type']})"] += 1
            if pid is None:
                self.stats["events written with no scorer named"] += 1
        self.stats["matches given a goal log"] += 1
        self.stats[f"  in {rec['season']}"] += 1


def vault_index(cur):
    cur.execute("""
        SELECT m.id, s.label, m.home_team_id, ht.name, m.away_team_id, at.name,
               m.home_score, m.away_score,
               (SELECT count(*) FROM match_events e WHERE e.match_id = m.id
                 AND e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL')) AS events
          FROM matches m
          JOIN competition_editions ce ON ce.id = m.competition_edition_id
          JOIN seasons s ON s.id = ce.season_id
          JOIN teams ht ON ht.id = m.home_team_id JOIN teams at ON at.id = m.away_team_id
         WHERE ce.competition_id = %s AND m.home_score IS NOT NULL
    """, (COMPETITION_ID,))
    keys = ["id", "season", "home_id", "home", "away_id", "away", "hs", "as", "events"]
    idx = defaultdict(list)
    for r in cur.fetchall():
        v = dict(zip(keys, r))
        idx[(v["season"], team_key(v["home"]), team_key(v["away"]))].append(v)
    return idx


def verify(cur):
    print("\nPremier League, after the load:")
    cur.execute("""
        WITH ev AS (
          SELECT m.id, s.label season,
            coalesce(m.home_score_et, m.home_score) hs, coalesce(m.away_score_et, m.away_score) as_,
            count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL') AND
              (CASE WHEN e.type='OWN_GOAL'
                    THEN CASE WHEN e.team_id=m.home_team_id THEN m.away_team_id ELSE m.home_team_id END
                    ELSE e.team_id END) = m.home_team_id) h,
            count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL') AND
              (CASE WHEN e.type='OWN_GOAL'
                    THEN CASE WHEN e.team_id=m.home_team_id THEN m.away_team_id ELSE m.home_team_id END
                    ELSE e.team_id END) = m.away_team_id) a
          FROM matches m
          JOIN competition_editions ce ON ce.id = m.competition_edition_id
          JOIN seasons s ON s.id = ce.season_id
          LEFT JOIN match_events e ON e.match_id = m.id
         WHERE ce.competition_id = %s AND m.home_score IS NOT NULL
         GROUP BY m.id, s.label, 3, 4)
        SELECT count(*) FILTER (WHERE (h > 0 OR a > 0) AND (h <> hs OR a <> as_)) AS disagree
          FROM ev
    """, (COMPETITION_ID,))
    print(f"  matches whose goal log contradicts the score (must be 0): {cur.fetchone()[0]}")
    cur.execute("""
        WITH m AS (SELECT m.id, coalesce(m.home_score_et,m.home_score)+coalesce(m.away_score_et,m.away_score) g
                     FROM matches m JOIN competition_editions ce ON ce.id=m.competition_edition_id
                    WHERE ce.competition_id=%s AND m.home_score IS NOT NULL),
             ev AS (SELECT e.match_id, count(*) FILTER (
                      WHERE e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL')
                        AND (e.player_id IS NOT NULL OR e.type='OWN_GOAL')) named
                      FROM match_events e GROUP BY 1)
        SELECT sum(m.g), sum(coalesce(ev.named,0)),
               round(100.0*sum(coalesce(ev.named,0))/sum(m.g), 1)
          FROM m LEFT JOIN ev ON ev.match_id = m.id
    """, (COMPETITION_ID,))
    g, named, pct = cur.fetchone()
    print(f"  goals with a named scorer: {named} of {g} ({pct}%)")


def main(path, commit):
    staged = json.load(open(path))
    conn = psycopg2.connect(DSN)
    conn.autocommit = False
    cur = conn.cursor()
    cur.execute("SET timezone = 'UTC'")
    idx = vault_index(cur)

    cur.execute("""
        INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
        VALUES ('match_event',
                (SELECT id FROM data_sources WHERE name='whoscored'),
                (SELECT id FROM data_sources WHERE name='rsssf'),
                'Premier League scorers from RSSSF season pages, for matches the vault held as a result with no event log, and only where RSSSF''s scorers account for the whole score.')
        RETURNING id
    """)
    cur.fetchone()

    loader = Loader(conn)
    # Resolve the surname counts over everything that could load, so two
    # incoming players never both claim one bare-surname record.
    pairs = set()
    for rec in staged:
        cands = idx.get((rec["season"], team_key(rec["home"]), team_key(rec["away"])), [])
        if len(cands) != 1:
            continue
        v = cands[0]
        for g in rec["goals"]:
            if not g["player"]:
                continue
            side = g["side"]
            if g["type"] == "OWN_GOAL":
                side = "away" if side == "home" else "home"
            pairs.add((v["home_id"] if side == "home" else v["away_id"], g["player"]))
    loader.count_surnames(pairs)

    for rec in staged:
        cands = idx.get((rec["season"], team_key(rec["home"]), team_key(rec["away"])), [])
        if len(cands) != 1:
            loader.skipped["no single vault match" if not cands else "ambiguous vault match"] += 1
            continue
        v = cands[0]
        if (v["hs"], v["as"]) != (rec["homeScore"], rec["awayScore"]):
            loader.skipped["score disagrees with the vault"] += 1
            continue
        loader.load(rec, v)

    print(f"{len(staged)} staged matches")
    for k in sorted(loader.stats):
        print(f"  {k}: {loader.stats[k]}")
    print("\nnot loaded:")
    for k in sorted(loader.skipped, key=lambda k: -loader.skipped[k]):
        print(f"  {k}: {loader.skipped[k]}")
    verify(cur)

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
