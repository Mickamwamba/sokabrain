#!/usr/bin/env python3
"""Parse RSSSF's round-by-round Tanzanian Premier League pages.

RSSSF publishes each season as plain text under headings, which is why it works
where the JavaScript-rendered live-score sites do not:

    Round 1
    [Aug 15]
    Ihefu            0-1 Geita Gold
    Namungo          0-1 JKT Tanzania
      [Martin Kigi 43]

The page is named by the season's END year -- tanz2024.html is 2023/24 -- and a
date has no year on it, so the year is inferred from the month: months from July
belong to the first calendar year of the season, the rest to the second.

Two parsing traps, both learned the hard way on earlier seasons:

* Club names are padded to a fixed width, so a long one leaves only ONE space
  before the score. Anchoring on two spaces silently drops a match per round.
* An abandoned match can appear twice, once as the abandonment and once as the
  replay, which inflates the season by one.
* **The same page also carries the cup**, with its own "Round 1", "Round 2"
  headers further down. Reading straight through mixes 133 cup ties into the
  league. The league is the first ascending run of rounds, so parsing stops as
  soon as a round number goes backwards.
* The final league table sits under the last round heading and its rows look
  like results ("1.Simba SC  38  29  6  3  77-15  93"), so a line whose club
  name starts with a table position is not a match.

Usage:  python3 parse_rsssf_rounds.py <html-file> [<html-file> ...] > rounds.json
"""
import html
import json
import re
import sys
from pathlib import Path

MONTHS = {m: i + 1 for i, m in enumerate(
    "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec".split())}

ROUND_RE = re.compile(r"^\s*(?:Round|Matchday|Week)\s+(\d+)", re.I)
DATE_RE = re.compile(r"^\s*\[([A-Z][a-z]{2})\s+(\d{1,2})\]")
# One space is enough between a padded club name and the score.
MATCH_RE = re.compile(r"^\s*(\S.*?)\s+(\d+)\s*-\s*(\d+)\s+(\S.*?)\s*$")
# Lines that look like matches but are not: scorer notes, footnotes, headings.
SKIP_RE = re.compile(r"^\s*[\[(]|^\s*(?:Round|Matchday|Week|Table|Final|Note|Play)", re.I)


def parse(path):
    end_year = int(re.search(r"(\d{4})", Path(path).stem).group(1))
    season = f"{end_year - 1}/{end_year}"

    text = re.sub(r"<[^>]+>", "", Path(path).read_text(encoding="utf8", errors="replace"))
    text = html.unescape(text)

    out, seen = [], set()
    rnd = None
    date = None
    max_round = 0
    for line in text.split("\n"):
        m = ROUND_RE.match(line)
        if m:
            n = int(m.group(1))
            # The league runs 1..N ascending; a round number that goes backwards
            # means the page has moved on to the cup.
            if max_round >= 5 and n < max_round:
                break
            rnd = n
            max_round = max(max_round, n)
            date = None
            continue
        m = DATE_RE.match(line)
        if m and m.group(1) in MONTHS:
            month = MONTHS[m.group(1)]
            year = end_year - 1 if month >= 7 else end_year
            date = f"{year}-{month:02d}-{int(m.group(2)):02d}"
            continue
        if rnd is None or SKIP_RE.match(line):
            continue
        m = MATCH_RE.match(line)
        if not m:
            continue
        home, hs, as_, away = m.group(1).strip(), int(m.group(2)), int(m.group(3)), m.group(4).strip()
        # A final-table row reads like a result; its "club" starts with a
        # position number and its "away" side is a points total.
        if re.match(r"^\d+[.)]", home) or not re.match(r"^[A-Za-z]", home):
            continue
        if not re.match(r"^[A-Za-z]", away):
            continue
        # Trailing footnote markers and awarded/abandoned annotations.
        away = re.sub(r"\s*[\[(].*$", "", away).strip()
        home = re.sub(r"\s*[\[(].*$", "", home).strip()
        if not home or not away or home == away:
            continue
        key = (home.lower(), away.lower())
        if key in seen:      # abandoned match listed twice; keep the first
            continue
        seen.add(key)
        out.append({"season": season, "round": rnd, "date": date,
                    "home": home, "away": away, "hs": hs, "as": as_})
    return out


if __name__ == "__main__":
    rows = []
    for p in sys.argv[1:]:
        rows += parse(p)
    print(json.dumps(rows, indent=1))
