#!/usr/bin/env python3
"""Add assists to matches that are already in the vault.

`load.py` deliberately skips an edition that already holds matches, so it cannot
be re-run to pick up a field that was missed. This adds one thing to existing
rows: ASSIST events.

Matches are found through their `entity_source_map` provenance rather than by
re-matching on names and dates -- the ligikuu event id was recorded when the
match was loaded, so the join is exact.

Idempotent: a match that already has ASSIST rows is left alone, so re-running
cannot double anyone's tally.

Usage:  python3 load_assists.py <canon_ligikuu.json> [--commit]
"""
import json
import sys
from collections import defaultdict

import psycopg2
import psycopg2.extras

sys.path.insert(0, __file__.rsplit("/", 1)[0])
from load import DSN, norm_person, team_key  # noqa: E402


def main():
    rows = json.load(open(sys.argv[1]))
    commit = "--commit" in sys.argv

    conn = psycopg2.connect(DSN)
    cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    stats = defaultdict(int)
    unresolved = set()

    cur.execute("SELECT id FROM data_sources WHERE name = 'ligikuu'")
    source_id = cur.fetchone()[0]

    # ligikuu event id -> vault match id, from the provenance written at load.
    cur.execute(
        """SELECT external_id, entity_id FROM entity_source_map
            WHERE entity_type = 'match' AND data_source_id = %s""", (source_id,))
    match_of = {r["external_id"]: r["entity_id"] for r in cur.fetchall()}

    cur.execute("SELECT id, full_name FROM players")
    players = {}
    for r in cur.fetchall():
        players.setdefault(norm_person(r["full_name"]), r["id"])

    # Matches that already carry assists, so a re-run adds nothing.
    cur.execute("SELECT DISTINCT match_id FROM match_events WHERE type = 'ASSIST'")
    already = {r[0] for r in cur.fetchall()}

    try:
        for rec in rows:
            assists = [e for e in (rec.get("events") or []) if e["type"] == "ASSIST"]
            if not assists:
                continue
            match_id = match_of.get(rec["source_match_id"])
            if match_id is None:
                stats["skipped: match not in the vault"] += 1
                continue
            if match_id in already:
                stats["skipped: already has assists"] += 1
                continue

            cur.execute(
                "SELECT home_team_id, away_team_id FROM matches WHERE id = %s", (match_id,))
            m = cur.fetchone()
            side_team = {"home": m["home_team_id"], "away": m["away_team_id"]}

            for a in assists:
                pid = players.get(norm_person(a.get("player_name")))
                if pid is None:
                    # Every assister also appears elsewhere in the same feed, so
                    # this should not happen; if it does, record the assist
                    # unattributed rather than dropping it.
                    unresolved.add(a.get("player_name"))
                cur.execute(
                    """INSERT INTO match_events
                           (match_id, team_id, player_id, minute, added_time, type, detail)
                       VALUES (%s,%s,%s,NULL,NULL,'ASSIST',%s)""",
                    (match_id, side_team[a["side"]], pid,
                     psycopg2.extras.Json({"source": "ligikuu", "linkedToGoal": False})))
                stats["assists inserted"] += 1
            stats["matches touched"] += 1

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
        if unresolved:
            print(f"  unresolved player names: {sorted(unresolved)}")
        conn.close()


if __name__ == "__main__":
    main()
