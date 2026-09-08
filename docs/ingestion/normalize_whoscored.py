#!/usr/bin/env python3
"""Turn the harvested WhoScored fixture list into canonical match records.

WhoScored is the only source that covers the early seasons, but it carries
fixtures and scores only -- no lineups, no scorers, no cards beyond team
totals. Records it produces therefore have empty `lineups` and `events`.

Input is the two files the browser harvest writes: `teams.json` (id -> name)
and `fixtures.txt`, whose first block lists the seasons and whose second block
is one comma-separated match per line:

    seasonIndex,matchId,yyyymmddhhmm,homeId,awayId,homeScore,awayScore,status
"""
import json
import sys
from pathlib import Path

# WhoScored status 6 is a finished match; anything else has no result yet.
FINISHED = "6"


def normalize(src):
    src = Path(src)
    teams = json.loads((src / "teams.json").read_text())
    head, body = (src / "fixtures.txt").read_text().split("=====\n")
    seasons = head.strip().split("\n")

    out = []
    for line in body.strip().split("\n"):
        si, mid, ts, hid, aid, hs, a_s, status = line.split(",")
        played = status == FINISHED and hs != "" and a_s != ""
        out.append({
            "source": "whoscored",
            "season": seasons[int(si)],
            "source_match_id": mid,
            "source_url": f"https://www.whoscored.com/matches/{mid}/live",
            # The feed's startTimeUtc, so this is genuinely UTC.
            "kickoff_utc": f"{ts[0:4]}-{ts[4:6]}-{ts[6:8]}T{ts[8:10]}:{ts[10:12]}:00",
            "home_source_id": int(hid), "home_name": teams[hid],
            "away_source_id": int(aid), "away_name": teams[aid],
            "home_score": int(hs) if played else None,
            "away_score": int(a_s) if played else None,
            "status": "FULL_TIME" if played else "SCHEDULED",
            "venue": None,
            "lineups": [],
            "events": [],
        })
    return out


if __name__ == "__main__":
    rows = normalize(sys.argv[1])
    Path(sys.argv[2]).write_text(json.dumps(rows, indent=1))
    import collections
    per = collections.Counter(r["season"] for r in rows)
    scored = collections.Counter(r["season"] for r in rows if r["home_score"] is not None)
    print(f"{'season':<12}{'matches':>9}{'scored':>8}")
    for s in sorted(per):
        print(f"{s:<12}{per[s]:>9}{scored[s]:>8}")
