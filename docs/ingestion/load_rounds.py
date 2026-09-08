#!/usr/bin/env python3
"""Set matches.round from RSSSF's round-by-round pages.

Neither WhoScored nor the official site publishes a round number, so 16 of the
19 ingested seasons had none and could not be browsed by matchday. RSSSF does,
in plain text, for most seasons.

The parse does not need to be clean, because the **join** is the filter: a
parsed line that does not correspond to a real fixture is simply dropped. On top
of that, a round is accepted only from a row **whose score also agrees with the
vault**. That second rule is what makes this safe -- it rejects a
confidently-wrong join rather than trusting a club-name alias.

It earns its keep: RSSSF's "Singida BS" means Singida Big Stars (now Fountain
Gate) in some seasons and Singida Black Stars in others, an ambiguity no alias
table can express. The score gate throws those rows out on its own.

Usage:  python3 load_rounds.py <rsssf_rounds.json> [--commit]
"""
import json
import sys
from collections import Counter, defaultdict

import psycopg2
import psycopg2.extras

sys.path.insert(0, __file__.rsplit("/", 1)[0])
from load import DSN  # noqa: E402
from teamnames import key as team_key  # noqa: E402


def main():
    rows = json.load(open(sys.argv[1]))
    commit = "--commit" in sys.argv

    conn = psycopg2.connect(DSN)
    cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

    cur.execute("""
        SELECT m.id, s.label, th.name AS home, ta.name AS away,
               m.home_score, m.away_score, m.round
          FROM matches m
          JOIN competition_editions ce ON ce.id = m.competition_edition_id
          JOIN seasons s ON s.id = ce.season_id
          JOIN teams th ON th.id = m.home_team_id
          JOIN teams ta ON ta.id = m.away_team_id
         WHERE ce.competition_id = 1""")
    vault = {}
    for r in cur.fetchall():
        vault[(r["label"], team_key(r["home"]), team_key(r["away"]))] = r

    assign, stats = {}, Counter()
    rejected = defaultdict(list)
    for x in rows:
        v = vault.get((x["season"], team_key(x["home"]), team_key(x["away"])))
        if v is None:
            stats["rsssf rows with no matching fixture"] += 1
            continue
        if v["id"] in assign:
            stats["duplicate rsssf rows"] += 1
            continue
        if v["home_score"] is not None and (v["home_score"], v["away_score"]) != (x["hs"], x["as"]):
            stats["REJECTED: score disagrees"] += 1
            rejected[x["season"]].append(f'{x["home"]} v {x["away"]}')
            continue
        if v["round"] is not None:
            stats["already had a round"] += 1
            continue
        assign[v["id"]] = str(x["round"])
        stats["rounds assigned"] += 1

    try:
        if assign:
            psycopg2.extras.execute_values(
                cur,
                """UPDATE matches m SET round = v.round
                     FROM (VALUES %s) AS v(id, round)
                    WHERE m.id = v.id""",
                [(mid, rnd) for mid, rnd in assign.items()])
        if commit:
            conn.commit()
            print("COMMITTED")
        else:
            conn.rollback()
            print("ROLLED BACK (dry run -- pass --commit to apply)")
    except Exception:
        conn.rollback()
        raise
    finally:
        for k in sorted(stats):
            print(f"  {k:<40} {stats[k]}")
        for s in sorted(rejected):
            print(f"  rejected in {s}: {len(rejected[s])}  e.g. {rejected[s][:2]}")
        conn.close()


if __name__ == "__main__":
    main()
