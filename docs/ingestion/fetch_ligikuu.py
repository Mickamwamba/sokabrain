#!/usr/bin/env python3
"""Download the official league site's SportsPress data.

ligikuu.co.tz runs WordPress with the SportsPress plugin, whose REST API is
open and unauthenticated, so this reads structured JSON rather than scraping
rendered pages.

Usage:  python3 fetch_ligikuu.py <output-directory>
"""
import json
import pathlib
import sys
import time
import urllib.request

BASE = "https://ligikuu.co.tz/wp-json/sportspress/v2"
UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")

# The top-flight leagues. `normalize_ligikuu.py` maps each to its real season;
# the site's own season taxonomy is not reliable enough to select on.
TOP_FLIGHT = [20, 91, 134, 236, 287, 418, 432]


def get(path):
    req = urllib.request.Request(f"{BASE}/{path}", headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r), r.headers


def all_pages(path, per_page=100):
    rows, page = [], 1
    while True:
        sep = "&" if "?" in path else "?"
        batch, headers = get(f"{path}{sep}per_page={per_page}&page={page}")
        rows += batch
        if page >= int(headers.get("X-WP-TotalPages", 1)):
            return rows
        page += 1
        time.sleep(0.4)


def main(out):
    out = pathlib.Path(out)
    out.mkdir(parents=True, exist_ok=True)

    for name in ("teams", "players", "venues", "seasons", "leagues"):
        rows = all_pages(name)
        (out / f"{name}.json").write_text(json.dumps(rows))
        print(f"{name}: {len(rows)}")

    events = []
    for league in TOP_FLIGHT:
        rows = all_pages(f"events?leagues={league}")
        for r in rows:
            r["_league"] = league          # the only reliable season marker
        events += rows
        print(f"events, league {league}: {len(rows)}")
    (out / "events.json").write_text(json.dumps(events))
    print(f"events total: {len(events)}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "raw/ligikuu")
