#!/usr/bin/env python3
"""Harvest the Rwanda Premier League's public player directory.

    python3 fetch_rpl_players.py > raw/rpl/players.json

The official site publishes a directory of every registered player at
`/players`, paged ten at a time, and an individual page per player at
`players.php?id=N`. Both are ordinary public pages: the site's robots.txt
disallows only `/admins/`, `/includes/`, `/uploads/temp/` and a handful of
named scripts, none of which this touches. The match-events endpoint under
`/admins/` IS disallowed and is deliberately not used anywhere here.

**Why this exists.** SportMonks, the licensed provider, gives this league's
scorers as initials -- "G. Ndonga Bivula" -- with no player id to resolve them
against. Roughly ninety goals across three Rwandan seasons are unattributed for
that reason alone. A club-scoped directory of real names turns most of them
into people.

Two things about the directory are worth knowing before reading the parser:

* **The listing abbreviates too.** A row reads "G. N. Bivula", not the full
  name. Only the individual player page carries it, in its <title>:
  "Gedeon Ndonga Bivula - Rwanda Premier League Player Profile". So the
  directory is the index and the player page is the answer.
* **The row's player id is in an onclick**, not an href:
  `<tr onclick="window.location.href='players.php?id=70'">`.

Fetching every player page would be 737 requests. The caller usually wants only
the handful that match an unresolved scorer, so `--ids` fetches names for a
given set; `--full` walks them all when a complete directory is genuinely
wanted.
"""
import argparse
import json
import re
import sys
import time
import urllib.request
from html import unescape

BASE = "https://rwandapremierleague.rw"
UA = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/129.0 Safari/537.36"
)
# The site sets no Crawl-delay, so this is a courtesy rather than a rule.
PAUSE = 0.4


def get(path: str) -> str:
    req = urllib.request.Request(f"{BASE}{path}", headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read().decode("utf-8", "replace")


def strip(html: str) -> str:
    return re.sub(r"\s+", " ", unescape(re.sub(r"<[^>]+>", " ", html))).strip()


def parse_directory_page(html: str):
    """Rows of (id, listed_name, club, position, dob, nationality).

    >>> row = '''<tbody><tr onclick="window.location.href='players.php?id=70'">
    ... <td><div class="player-name"> C. O. Djibril </div></td>
    ... <td><div class="club-name">APR FC</div></td>
    ... <td><span class="position-badge"> Forward </span></td>
    ... <td><span class="dob-date">9 Jul 2000</span></td>
    ... <td><span class="nat-name">Burkina Faso</span></td></tr></tbody>'''
    >>> parse_directory_page(row)
    [{'id': 70, 'listed': 'C. O. Djibril', 'club': 'APR FC', 'position': 'Forward', 'dob': '9 Jul 2000', 'nationality': 'Burkina Faso'}]
    """
    body = re.search(r"<tbody[^>]*>(.*?)</tbody>", html, re.S)
    if not body:
        return []
    out = []
    for row in re.findall(r"<tr[^>]*>.*?</tr>", body.group(1), re.S):
        pid = re.search(r"players\.php\?id=(\d+)", row)
        if not pid:
            continue

        def pick(cls):
            m = re.search(rf'class="{cls}"[^>]*>(.*?)</', row, re.S)
            return strip(m.group(1)) if m else None

        out.append(
            {
                "id": int(pid.group(1)),
                "listed": pick("player-name"),
                "club": pick("club-name"),
                "position": pick("position-badge"),
                "dob": pick("dob-date"),
                "nationality": pick("nat-name"),
            }
        )
    return out


def full_name(player_id: int) -> str | None:
    """The player's real name, from the page title.

    >>> title_of('<title>Gedeon Ndonga Bivula &mdash; Rwanda Premier League Player Profile</title>')
    'Gedeon Ndonga Bivula'
    """
    return title_of(get(f"/players.php?id={player_id}"))


def title_of(html: str) -> str | None:
    m = re.search(r"<title[^>]*>(.*?)</title>", html, re.S)
    if not m:
        return None
    t = unescape(m.group(1)).strip()
    # "Name — Rwanda Premier League Player Profile"; the dash may be any of
    # several characters depending on how the page was generated.
    return re.split(r"\s+[—–-]\s+", t)[0].strip() or None


def directory(season: str | None):
    """Every row of the directory, following its pagination to the end."""
    rows, page = [], 1
    while True:
        q = f"/players?page={page}" + (f"&filter_season={season}" if season else "")
        html = get(q)
        got = parse_directory_page(html)
        if not got:
            break
        rows.extend(got)
        total = re.search(r"of\s+([\d,]+)\s+players", html)
        if total and len(rows) >= int(total.group(1).replace(",", "")):
            break
        page += 1
        if page > 200:  # refuse to loop forever on an unexpected pager
            break
        time.sleep(PAUSE)
    return rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--season", help="site's season value, e.g. 2025-2026")
    ap.add_argument("--full", action="store_true", help="resolve every full name")
    ap.add_argument("--ids", help="comma-separated player ids to resolve names for")
    ap.add_argument("--doctest", action="store_true")
    args = ap.parse_args()

    if args.doctest:
        import doctest

        print(doctest.testmod())
        return

    rows = directory(args.season)
    print(f"directory rows: {len(rows)}", file=sys.stderr)

    want = None
    if args.ids:
        want = {int(x) for x in args.ids.split(",") if x.strip()}
    if args.full or want:
        for i, r in enumerate(rows):
            if want is not None and r["id"] not in want:
                continue
            r["full_name"] = full_name(r["id"])
            if i % 25 == 0:
                print(f"  resolved {i}/{len(rows)}", file=sys.stderr)
            time.sleep(PAUSE)

    json.dump(rows, sys.stdout, ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main()
