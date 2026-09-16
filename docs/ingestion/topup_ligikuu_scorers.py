"""Repair Premier League goal logs from a fresh ligikuu harvest.

    python3 topup_ligikuu_scorers.py raw/ligikuu            # dry run
    python3 topup_ligikuu_scorers.py raw/ligikuu --commit

`load.py` refuses to touch a season whose edition already holds matches, which
is right for a bulk load and useless for a repair. This does the repair.

It only ever considers a match whose goal log is **already defective** -- short
of its score, contradicting it, or naming no scorer for one of its goals -- and
only acts when the official site's own log for that match reconciles exactly
with the score the vault holds. A healthy match is never touched.

Where both conditions hold, the match's goal events are replaced by ligikuu's,
which is the only safe way to repair a log that is wrong rather than merely
incomplete: naming events one by one cannot fix a 3-2 recorded as 4-1. Cards,
assists and lineups are left alone -- this is about goals. Every deleted event
is recorded as a reconciliation diff first, so nothing disappears silently.

Own-goal orientation is decided by `normalize_ligikuu.orient_own_goals`, which
settles each match on its score; the site changed convention in early 2026 and
that function is the one place that knows it.
"""
import json
import sys
from collections import defaultdict

import psycopg2

from normalize_ligikuu import normalize

DSN = "host=127.0.0.1 port=5432 dbname=sokabrain"
COMPETITION_ID = 1                 # Premier League
GOAL_TYPES = ("GOAL", "PENALTY_GOAL", "OWN_GOAL")


def credited(ev_type, side):
    """Which side a goal counts for. An own goal counts for the other one."""
    if ev_type == "OWN_GOAL":
        return "away" if side == "home" else "home"
    return side


class Repair:
    def __init__(self, conn):
        self.c = conn.cursor()
        self.stats = defaultdict(int)
        self.skipped = []
        self.acted = []
        self.c.execute("SELECT id FROM data_sources WHERE name = 'ligikuu'")
        self.source_id = self.c.fetchone()[0]
        # ligikuu player id -> vault player id, from the provenance the first
        # load wrote. A player the vault has never seen is created.
        self.c.execute("""
            SELECT esm.external_id, esm.entity_id FROM entity_source_map esm
             WHERE esm.entity_type = 'player' AND esm.data_source_id = %s
        """, (self.source_id,))
        self.players = {k: v for k, v in self.c.fetchall()}
        self.c.execute("""
            SELECT esm.external_id, esm.entity_id FROM entity_source_map esm
             WHERE esm.entity_type = 'match' AND esm.data_source_id = %s
        """, (self.source_id,))
        self.matches = {k: v for k, v in self.c.fetchall()}

    def vault_state(self, match_id):
        self.c.execute("""
            SELECT m.home_team_id, m.away_team_id, m.home_score, m.away_score, s.label
              FROM matches m
              JOIN competition_editions ce ON ce.id = m.competition_edition_id
              JOIN seasons s ON s.id = ce.season_id
             WHERE m.id = %s AND ce.competition_id = %s
        """, (match_id, COMPETITION_ID))
        row = self.c.fetchone()
        if not row:
            return None
        home_id, away_id, hs, as_, season = row
        self.c.execute("""
            SELECT id, team_id, player_id, minute, type FROM match_events
             WHERE match_id = %s AND type = ANY(%s)
        """, (match_id, list(GOAL_TYPES)))
        events = self.c.fetchall()
        tally = {"home": 0, "away": 0}
        unnamed = 0
        for _id, team_id, player_id, _minute, typ in events:
            side = "home" if team_id == home_id else "away" if team_id == away_id else None
            if side is None:
                continue
            tally[credited(typ, side)] += 1
            if player_id is None and typ != "OWN_GOAL":
                unnamed += 1
        return dict(home_id=home_id, away_id=away_id, hs=hs, as_=as_, season=season,
                    events=events, tally=tally, unnamed=unnamed)

    def player(self, source_id, name):
        """The vault player for a ligikuu player id, created if new."""
        key = str(source_id)
        if key in self.players:
            return self.players[key]
        if not name:
            return None
        self.c.execute("INSERT INTO players (full_name) VALUES (%s) RETURNING id", (name,))
        pid = self.c.fetchone()[0]
        self.c.execute("""
            INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
            VALUES ('player', %s, %s, %s, 1.0)
            ON CONFLICT (entity_type, data_source_id, external_id) DO NOTHING
        """, (pid, self.source_id, key))
        self.players[key] = pid
        self.stats["players created"] += 1
        return pid

    def repair(self, rec, run_id):
        match_id = self.matches.get(rec["source_match_id"])
        if match_id is None:
            return                                   # not a Premier League match we hold
        state = self.vault_state(match_id)
        if state is None or state["hs"] is None:
            return

        defective = (state["tally"]["home"] != state["hs"]
                     or state["tally"]["away"] != state["as_"]
                     or state["unnamed"] > 0)
        if not defective:
            return                                   # healthy: never touched

        label = (f"{state['season']} match {match_id} "
                 f"score {state['hs']}-{state['as_']}, "
                 f"log {state['tally']['home']}-{state['tally']['away']}"
                 + (f", {state['unnamed']} unnamed" if state["unnamed"] else ""))

        incoming = [e for e in rec["events"] if e["type"] in GOAL_TYPES]
        want = {"home": 0, "away": 0}
        for e in incoming:
            want[credited(e["type"], e["side"])] += 1
        if not incoming:
            self.skipped.append(f"{label}: ligikuu has no goals for it")
            self.stats["skipped, source has nothing"] += 1
            return
        if want["home"] != state["hs"] or want["away"] != state["as_"]:
            self.skipped.append(
                f"{label}: ligikuu reads {want['home']}-{want['away']}, which does not reconcile either")
            self.stats["skipped, source does not reconcile"] += 1
            return
        if any(e["player_source_id"] and not e["player_name"] for e in incoming):
            self.skipped.append(f"{label}: ligikuu names a deleted player")
            self.stats["skipped, source player missing"] += 1
            return

        # Record what is being removed before removing it.
        for ev_id, team_id, player_id, minute, typ in state["events"]:
            self.c.execute("""
                INSERT INTO reconciliation_diffs
                  (reconciliation_run_id, entity_id_a, entity_id_b, field_name,
                   value_a, value_b, resolution, resolved_value, resolved_at)
                VALUES (%s, %s, %s, 'match_events.replaced', %s, %s, 'ACCEPT_B', 'ligikuu', now())
            """, (run_id, ev_id, match_id,
                  f"{typ} team {team_id} player {player_id} minute {minute}",
                  "replaced by the official site's goal log"))
        ids = [e[0] for e in state["events"]]
        if ids:
            self.c.execute("DELETE FROM entity_source_map WHERE entity_type='match_event' AND entity_id = ANY(%s)", (ids,))
            self.c.execute("DELETE FROM match_events WHERE id = ANY(%s)", (ids,))
            self.stats["goal events replaced"] += len(ids)

        for n, e in enumerate(incoming, 1):
            team_id = state["home_id"] if e["side"] == "home" else state["away_id"]
            pid = self.player(e["player_source_id"], e["player_name"])
            self.c.execute("""
                INSERT INTO match_events (match_id, team_id, player_id, minute, added_time, type)
                VALUES (%s, %s, %s, %s, %s, %s) RETURNING id
            """, (match_id, team_id, pid, e.get("minute"), e.get("added_time"), e["type"]))
            ev_id = self.c.fetchone()[0]
            self.c.execute("""
                INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
                VALUES ('match_event', %s, %s, %s, 1.0)
                ON CONFLICT (entity_type, data_source_id, external_id) DO NOTHING
            """, (ev_id, self.source_id, f"{rec['source_match_id']}-g{n}"))
            self.stats[f"goal events written ({e['type']})"] += 1
        self.acted.append(f"{label} -> {want['home']}-{want['away']} from ligikuu")
        self.stats["matches repaired"] += 1


def verify(cur):
    print("\nPremier League, after the repair:")
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
                    ELSE e.team_id END) = m.away_team_id) a,
            count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL') AND e.player_id IS NULL) unnamed
          FROM matches m
          JOIN competition_editions ce ON ce.id = m.competition_edition_id
          JOIN seasons s ON s.id = ce.season_id
          LEFT JOIN match_events e ON e.match_id = m.id
         WHERE ce.competition_id = %s AND m.home_score IS NOT NULL
         GROUP BY m.id, s.label, 3, 4)
        SELECT season,
               count(*) FILTER (WHERE (h > 0 OR a > 0) AND (h <> hs OR a <> as_)) AS log_disagrees,
               count(*) FILTER (WHERE unnamed > 0) AS with_unnamed
          FROM ev GROUP BY season HAVING
               count(*) FILTER (WHERE (h > 0 OR a > 0) AND (h <> hs OR a <> as_)) > 0
            OR count(*) FILTER (WHERE unnamed > 0) > 0
         ORDER BY season
    """, (COMPETITION_ID,))
    rows = cur.fetchall()
    if not rows:
        print("  every match with a goal log reconciles, and no goal is unnamed")
    for season, bad, unnamed in rows:
        print(f"  {season}: {bad} logs disagree, {unnamed} matches with an unnamed goal")


def main(src, commit):
    records = normalize(src)
    conn = psycopg2.connect(DSN)
    conn.autocommit = False
    cur = conn.cursor()
    cur.execute("SET timezone = 'UTC'")
    cur.execute("""
        INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
        VALUES ('match_event',
                (SELECT id FROM data_sources WHERE name='legacy_sokafc'),
                (SELECT id FROM data_sources WHERE name='ligikuu'),
                'Premier League goal logs repaired from a fresh ligikuu harvest: only matches whose log was short of, contradicted, or unnamed against their stored score, and only where the official site''s own log reconciles exactly.')
        RETURNING id
    """)
    run_id = cur.fetchone()[0]

    r = Repair(conn)
    for rec in records:
        r.repair(rec, run_id)

    print(f"{len(records)} ligikuu records considered")
    for k in sorted(r.stats):
        print(f"  {k}: {r.stats[k]}")
    if r.acted:
        print(f"\nrepaired ({len(r.acted)}):")
        for a in r.acted:
            print(f"  {a}")
    if r.skipped:
        print(f"\nleft alone ({len(r.skipped)}):")
        for s in r.skipped:
            print(f"  {s}")
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
