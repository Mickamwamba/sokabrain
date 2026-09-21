#!/usr/bin/env python3
"""Harvest the Uganda Premier League's player directory from its open API.

    python3 fetch_upl_players.py > raw/upl/players.json

upl.co.ug runs SportsPress on WordPress, the same stack as Tanzania's
ligikuu.co.tz, and its REST API is open at `/wp-json/sportspress/v2/`. Its
robots.txt allows everything (`Disallow:` with no path), so this is the
friendliest source encountered for any of these leagues -- no HTML parsing, no
per-player page fetch, and full names rather than initials.

Output matches `fetch_rpl_players.py` so `topup_scorers_from_directory.py` can
read either without caring which league it came from. The one difference is
that `full_name` is already populated here, because the API gives it directly.
"""
import gzip
import json
import sys
import time
import urllib.request
from html import unescape

BASE = "https://upl.co.ug/wp-json/sportspress/v2"
UA = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/129.0 Safari/537.36"
)
PAUSE = 0.3


def get(path: str, attempts: int = 4):
    """One GET, gzipped and trimmed — without both, this endpoint times out.

    Two things make the difference between 90 seconds and one, and they are the
    whole reason this function is not a two-liner:

    * **`_fields`.** SportsPress computes a statistics block per player, and
      asking for the full object makes the server render it for all fifty. A
      trimmed request answers in 0.9s where the full one times out at 90.
    * **gzip.** `urllib` asks for `identity` by default, so a page travels as
      430KB rather than 26KB. That alone took a page from a timeout to 20s.

    A retry is kept on top because the host still stalls occasionally.
    """
    req = urllib.request.Request(
        f"{BASE}{path}",
        headers={"User-Agent": UA, "Accept-Encoding": "gzip",
                 "Accept": "application/json"},
    )
    for attempt in range(attempts):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                raw = r.read()
                if r.headers.get("Content-Encoding") == "gzip":
                    raw = gzip.decompress(raw)
                return json.loads(raw)
        except Exception as exc:  # noqa: BLE001 - any transport failure retries
            if attempt == attempts - 1:
                raise
            print(f"  retry {attempt + 1} on {path}: {exc}", file=sys.stderr)
            time.sleep(2 * (attempt + 1))


def paged(path: str, per_page: int = 50):
    out, page = [], 1
    while page <= 60:
        sep = "&" if "?" in path else "?"
        got = get(f"{path}{sep}per_page={per_page}&page={page}")
        if not got:
            break
        out.extend(got)
        if len(got) < per_page:
            break
        page += 1
        time.sleep(PAUSE)
    return out


def main():
    teams = {
        t["id"]: unescape(t["title"]["rendered"])
        for t in paged("/teams?_fields=id,title")
    }
    print(f"teams: {len(teams)}", file=sys.stderr)

    rows = []
    for p in paged("/players?_fields=id,title,number,current_teams,teams,seasons"):
        # `current_teams` is where the player is now; `teams` is everywhere they
        # have been. Prefer the former, fall back to the latter, so a player who
        # has moved is still findable under the club he scored for.
        ids = (p.get("current_teams") or []) or (p.get("teams") or [])
        name = unescape(p["title"]["rendered"]).strip()
        for tid in ids or [None]:
            rows.append(
                {
                    "id": p["id"],
                    "listed": name,
                    "full_name": name,
                    "club": teams.get(tid),
                    "number": p.get("number"),
                    "seasons": p.get("seasons"),
                }
            )
    print(f"player-club rows: {len(rows)}", file=sys.stderr)
    json.dump(rows, sys.stdout, ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main()
