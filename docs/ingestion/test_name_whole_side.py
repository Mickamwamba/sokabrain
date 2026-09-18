"""Check that the loader can re-name a side whose scorers have been erased.

    python3 test_name_whole_side.py

The "name a whole unnamed side" step in `load_fotmob_tpl.py` exists for 2019/20
and 2018/19, whose event logs are complete and whose scorers are mostly absent.
Neither season can be filled from FotMob -- its match pages carry no goal
timeline before 2020/21 -- so that step has no season to run against yet, and
untested code that writes to the vault is worth less than no code.

This exercises it on real data instead of waiting. For a handful of 2022/23
matches it strips the scorers from one side, runs the loader over the harvest
that named them in the first place, and checks the same names come back. The
whole thing happens inside a transaction that is rolled back, so the vault is
untouched either way.

The point being tested is the safety argument: where every goal event on a side
is unnamed, the events are interchangeable, so pairing them with the source's
goals for that side restores exactly the facts that were there.
"""
import json
import sys

import psycopg2

from load_fotmob_tpl import GOALS, Loader, credited_in_vault

DSN = "host=127.0.0.1 port=5432 dbname=sokabrain"
STAGED = "/private/tmp/claude-501/-Users-michaelkimollo-Projects-soka-brain/" \
         "a2fbfbaa-2a45-4d40-8e2f-0a786b03b80b/scratchpad/staged_2022_23.json"
HOW_MANY = 12


def main():
    staged = {r["match"]: r for r in json.load(open(STAGED))}
    conn = psycopg2.connect(DSN)
    conn.autocommit = False
    cur = conn.cursor()
    cur.execute("SET timezone = 'UTC'")

    # Matches whose goals came FROM FotMob and are all named. Restricting to
    # FotMob's own events is the whole point: where a scorer was named by
    # another source, FotMob may spell the same man differently ("Dejan
    # Georgejivec" against "Dejan Georgijevic"), and the step giving FotMob's
    # answer to FotMob's question is right even though the name changed. A test
    # that mixed the sources would be measuring their disagreement, not this.
    cur.execute("""
        SELECT m.id, m.home_team_id, m.away_team_id
          FROM matches m
          JOIN competition_editions ce ON ce.id = m.competition_edition_id
          JOIN seasons s ON s.id = ce.season_id
         WHERE ce.competition_id = 1 AND s.label = '2022/2023'
           AND NOT EXISTS (SELECT 1 FROM match_events e
                            WHERE e.match_id = m.id AND e.type = ANY(%s)
                              AND e.player_id IS NULL)
           AND NOT EXISTS (SELECT 1 FROM match_events e
                            WHERE e.match_id = m.id AND e.type = ANY(%s)
                              AND NOT EXISTS (
                                SELECT 1 FROM entity_source_map es
                                 JOIN data_sources ds ON ds.id = es.data_source_id
                                 WHERE es.entity_type = 'match_event'
                                   AND es.entity_id = e.id AND ds.name = 'fotmob'))
         ORDER BY m.id
    """, (list(GOALS), list(GOALS)))
    candidates = [r for r in cur.fetchall() if r[0] in staged]

    picked, before = [], {}
    for mid, home_id, away_id in candidates:
        cur.execute("""
            SELECT id, team_id, player_id, minute, type FROM match_events
             WHERE match_id = %s AND type = ANY(%s)
        """, (mid, list(GOALS)))
        evs = cur.fetchall()
        for side, in (("home",), ("away",)):
            on_side = [e for e in evs
                       if credited_in_vault(e[4], "home" if e[1] == home_id else "away") == side]
            if len(on_side) < 2:
                continue            # a single goal proves little about pairing
            picked.append((mid, side))
            before[(mid, side)] = {e[0]: e[2] for e in on_side}
            break
        if len(picked) >= HOW_MANY:
            break

    if len(picked) < 3:
        raise SystemExit("not enough 2022/23 matches with a fully named multi-goal side")

    erased = 0
    for key in picked:
        for ev_id in before[key]:
            cur.execute("UPDATE match_events SET player_id = NULL WHERE id = %s", (ev_id,))
            erased += 1
    print(f"erased {erased} scorers across {len(picked)} match-sides")

    cur.execute("""
        INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
        VALUES ('match_event',
                (SELECT id FROM data_sources WHERE name='ligikuu'),
                (SELECT id FROM data_sources WHERE name='fotmob'),
                'test run, rolled back') RETURNING id
    """)
    run_id = cur.fetchone()[0]

    loader = Loader(conn)
    for mid, _side in picked:
        loader.do_match(staged[mid], run_id)

    ok = bad = 0
    for (mid, side), want in before.items():
        cur.execute("SELECT id, player_id FROM match_events WHERE id = ANY(%s)",
                    (list(want),))
        got = dict(cur.fetchall())
        # Compare as MULTISETS: which event holds which name is not a fact the
        # vault records, because the events were interchangeable. The set of
        # scorers on the side is the fact, and that is what must come back.
        if sorted(filter(None, got.values())) == sorted(filter(None, want.values())):
            ok += 1
        else:
            bad += 1
            print(f"  MISMATCH match {mid} {side}: was {sorted(want.values())}, "
                  f"now {sorted(got.values())}")

    conn.rollback()
    conn.close()
    print(f"\n{ok} of {ok + bad} match-sides came back with exactly the same scorers")
    if bad:
        print("FAILED")
        return 1
    print("PASSED -- and the vault was rolled back, so nothing changed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
