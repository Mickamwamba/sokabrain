"""Turn RSSSF's Tanzanian season pages into canonical matches and scorers.

    python3 -m doctest normalize_rsssf_tpl.py -v
    python3 normalize_rsssf_tpl.py raw/rsssf_tpl > raw/rsssf_tpl/canon.json

RSSSF publishes a page per Tanzanian season with round-by-round results and, for
some matches, the scorers with their minutes and **full names**. That is the one
thing the vault's other two league sources do not have: ligikuu holds no scorers
before 2023/24 and WhoScored holds none at all.

The page layout, which every season from 2007/08 to 2025/26 follows:

    Premier League 2020/21 (Ligi Kuu Tanzania Bara)     <- names its own season
    Final Table: ...
    Round 1
    [Sep 6]                                            <- day and month only
    Namungo          1-0 Coastal Union
    KMC              4-0 Mbeya City
      [Emmanuel Mvuyekure 22, Hassan Kabunda 39, ...]   <- [home; away]
    ...
    Cup Tournaments                                    <- the league block ends

The scorer grammar is richer than the AFCON pages', and every form below was
found by surveying all nineteen pages before writing the parser -- the same
discipline that the first AFCON load skipped, at the cost of five penalties
recorded as ordinary goals.

**Own goals keep RSSSF's side here, which is the side the goal COUNTS FOR.**
The loader flips them to the scorer's own team (design principle 5), as it does
for every other source.
"""
import json
import re
import sys
import unicodedata
from pathlib import Path

SECTION = re.compile(r"^\s*(?:Premier League|Ligi Kuu)\b[^\n]*?(\d{4})/(\d{2})", re.I)
SECTION_END = re.compile(r"^\s*(Cup Tournament|Ligi Daraja|First Division|Federation Cup)", re.I)
ROUND = re.compile(r"^\s*Round\s+(\d+)\s*$", re.I)
DATE = re.compile(r"^\s*\[([A-Z][a-z]{2})\s+(\d{1,2})\??\]\s*$")
RESULT = re.compile(r"^(\S.{1,28}?)\s{2,}(\d{1,2})\s*-\s*(\d{1,2})\s*(\S.{0,28}?)\s*$")
BRACKET = re.compile(r"^\s*\[(.+)\]\s*$")

MONTHS = {m: i for i, m in enumerate(
    "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec".split(), start=1)}

# Prose that means the bracket is a note, not a scorer list.
PROSE = re.compile(r"\b(due|abandoned|awarded|walkover|moved|rain|pitch|waterlogged|crowd|referee)\b", re.I)


def _text(path):
    raw = Path(path).read_text(errors="replace")
    import html as _html
    return _html.unescape(re.sub(r"<[^>]+>", "", raw))


def parse_entry(chunk, problems, where):
    """One scorer entry: a name, then whatever RSSSF wrote after it.

    A bare name is one goal whose minute is not given:

    >>> [ (g['player'], g['minute'], g['type']) for g in parse_entry('Oscar Joshua', [], '') ]
    [('Oscar Joshua', None, 'GOAL')]

    A minute, a penalty, an own goal, and stoppage time:

    >>> [ (g['minute'], g['added'], g['type']) for g in parse_entry('Hassan Kabunda 39', [], '') ]
    [(39, None, 'GOAL')]
    >>> [ (g['minute'], g['type']) for g in parse_entry('Salum Chuku 80pen', [], '') ]
    [(80, 'PENALTY_GOAL')]
    >>> [ (g['minute'], g['type']) for g in parse_entry('Ayoub Lyanga 90og', [], '') ]
    [(90, 'OWN_GOAL')]
    >>> [ (g['minute'], g['added']) for g in parse_entry('Peter Mapunda 90+5', [], '') ]
    [(90, 5)]

    A parenthesised count is that many goals, not a minute -- the trap that
    would otherwise lose two of "Stephanie Aziz Ki (3)":

    >>> [ (g['player'], g['minute']) for g in parse_entry('Stephanie Aziz Ki (3)', [], '') ]
    [('Stephanie Aziz Ki', None), ('Stephanie Aziz Ki', None), ('Stephanie Aziz Ki', None)]

    An own goal can be marked in parentheses instead:

    >>> [ g['type'] for g in parse_entry('Ayoub Lyanga (og)', [], '') ]
    ['OWN_GOAL']

    A running score is not a minute, and the goal survives without one:

    >>> [ (g['player'], g['minute']) for g in parse_entry('Yona Ndabila 0-2', [], '') ]
    [('Yona Ndabila', None)]

    Several minutes after one name are several goals by that player:

    >>> [ g['minute'] for g in parse_entry('Vitalis Mayanga 3 20', [], '') ]
    [3, 20]

    An unknown scorer still counts as a goal:

    >>> [ (g['player'], g['minute']) for g in parse_entry('?', [], '') ]
    [(None, None)]

    A penalty can also be written with an apostrophe and a parenthesised P, and
    a lone question mark stands in for a minute nobody recorded:

    >>> [ (g['minute'], g['type']) for g in parse_entry("Shabani 60'(P)", [], '') ]
    [(60, 'PENALTY_GOAL')]
    >>> [ (g['player'], g['minute']) for g in parse_entry('Boniface Ambani ? 71', [], '') ]
    [('Boniface Ambani', 71)]
    """
    chunk = chunk.strip()
    if not chunk:
        return []
    if chunk in ("?", "??"):
        return [{"player": None, "minute": None, "added": None, "type": "GOAL"}]

    own_in_parens = bool(re.search(r"\(\s*og\.?\s*\)", chunk, re.I))
    chunk = re.sub(r"\(\s*og\.?\s*\)", " ", chunk, flags=re.I)

    repeat = 1
    m = re.search(r"\((\d)\)", chunk)
    if m:
        repeat = int(m.group(1))
        chunk = chunk[:m.start()] + " " + chunk[m.end():]

    # The name is everything up to the first standalone number or marker.
    m = re.search(r"\s(?=\d|\?)", chunk)
    name = (chunk[:m.start()] if m else chunk).strip(" .,'")
    rest = chunk[m.start():] if m else ""
    name = re.sub(r"\s+", " ", name) or None

    goals = []
    for tok in re.findall(r"[^\s,]+", rest):
        if "-" in tok and re.fullmatch(r"\d{1,2}-\d{1,2}", tok):
            continue                                    # a running score
        if tok in ("?", "??"):
            continue                                    # minute not given
        # "60'(P)" is a penalty, the same as "60pen"; the apostrophe and the
        # parenthesised P are both optional decoration.
        tok = re.sub(r"'?\(\s*p\s*\)$", "pen", tok, flags=re.I)
        mm = re.fullmatch(r"(\d{1,3})(\+(\d{1,2})?)?(pen\.?|og\.?)?'?", tok, re.I)
        if not mm:
            problems.append(f"{where}: unreadable token {tok!r} in {chunk!r}")
            continue
        minute = int(mm.group(1))
        added = int(mm.group(3)) if mm.group(3) else (0 if mm.group(2) else None)
        marker = (mm.group(4) or "").lower().rstrip(".")
        typ = "PENALTY_GOAL" if marker == "pen" else "OWN_GOAL" if marker == "og" else "GOAL"
        goals.append({"player": name, "minute": minute, "added": added, "type": typ})

    if not goals:
        goals = [{"player": name, "minute": None, "added": None, "type": "GOAL"}]
    if own_in_parens:
        for g in goals:
            g["type"] = "OWN_GOAL"
    if repeat > 1 and len(goals) == 1:
        goals = [dict(goals[0]) for _ in range(repeat)]
    return goals


def parse_bracket(text, home_score, away_score, problems, where):
    """A whole scorer bracket, as (home goals, away goals).

    RSSSF separates the sides with a semicolon and the scorers with commas. A
    comma-separated item starting with a digit is another minute for the
    previous scorer, not a new one.

    >>> h, a = parse_bracket('Hance Masoud 89; Daniel Amoah 50', 1, 1, [], '')
    >>> [(g['player'], g['minute']) for g in h], [(g['player'], g['minute']) for g in a]
    ([('Hance Masoud', 89)], [('Daniel Amoah', 50)])
    >>> h, a = parse_bracket('Vitalis Mayanga 3, 20', 2, 0, [], '')
    >>> [(g['player'], g['minute']) for g in h]
    [('Vitalis Mayanga', 3), ('Vitalis Mayanga', 20)]
    >>> parse_bracket('24, due to waterlogged pitch', 1, 1, [], 'x')
    (None, None)

    With no semicolon the goals belong to whichever side scored, which is NOT
    always the home one -- "Toto African 0-1 Mtibwa Sugar [Mecky Mexime 2]" is
    the away team's goal:

    >>> h, a = parse_bracket('Mecky Mexime 2', 0, 1, [], '')
    >>> h, [(g['player'], g['minute']) for g in a]
    ([], [('Mecky Mexime', 2)])

    When both sides scored and there is no semicolon, it cannot be divided, so
    it is reported instead of guessed:

    >>> parse_bracket('Someone 10, Another 20', 1, 1, [], 'x')
    (None, None)
    """
    if PROSE.search(text):
        problems.append(f"{where}: prose in the scorer bracket, skipped: {text.strip()[:70]!r}")
        return (None, None)
    sides = text.split(";")
    if len(sides) > 2:
        problems.append(f"{where}: {len(sides)} semicolon-separated sides")
        return (None, None)
    if len(sides) == 1:
        # No divider. If only one side scored, everything is theirs; if both
        # did, the bracket cannot be split and is not worth guessing at.
        if home_score and away_score:
            problems.append(f"{where}: no semicolon in a bracket for a match both sides scored in")
            return (None, None)
        if not home_score and not away_score:
            problems.append(f"{where}: scorers listed for a goalless match")
            return (None, None)
        sides = [text, ""] if home_score else ["", text]
    out = []
    for side in (sides + [""])[:2]:
        goals, last_name = [], None
        for item in side.split(","):
            item = item.strip()
            if not item:
                continue
            if re.match(r"^\d|^\?", item) and last_name:
                # another minute for whoever scored last
                for g in parse_entry(f"{last_name} {item}", problems, where):
                    goals.append(g)
            else:
                got = parse_entry(item, problems, where)
                if got:
                    last_name = got[0]["player"]
                goals += got
        out.append(goals)
    return (out[0], out[1])


def season_label(start, end2):
    """RSSSF writes "2020/21"; the vault stores "2020/2021".

    >>> season_label('2020', '21')
    '2020/2021'
    >>> season_label('1999', '00')
    '1999/2000'
    """
    century = int(start[:2]) + (1 if end2 == "00" or int(end2) < int(start[2:]) else 0)
    return f"{start}/{century:02d}{end2}"


def normalize_page(path, problems):
    lines = _text(path).splitlines()
    start = next((i for i, l in enumerate(lines) if SECTION.search(l)), None)
    if start is None:
        problems.append(f"{Path(path).stem}: no Premier League section")
        return []
    m = SECTION.search(lines[start])
    season = season_label(m.group(1), m.group(2))
    end = next((i for i in range(start + 1, len(lines)) if SECTION_END.match(lines[i])), len(lines))
    year_start = int(m.group(1))

    out, rnd, date = [], None, None
    for i in range(start, end):
        line = lines[i]
        r = ROUND.match(line)
        if r:
            rnd = int(r.group(1)); continue
        d = DATE.match(line)
        if d:
            mon = MONTHS.get(d.group(1))
            if mon:
                # A season spans two calendar years; months from July on belong
                # to the first, the rest to the second.
                year = year_start if mon >= 7 else year_start + 1
                date = f"{year}-{mon:02d}-{int(d.group(2)):02d}"
            continue
        res = RESULT.match(line)
        if not res:
            continue
        home, hs, as_, away = res.group(1).strip(), int(res.group(2)), int(res.group(3)), res.group(4).strip()
        where = f"{season} {home} {hs}-{as_} {away}"
        goals = []
        nxt = next((lines[j] for j in range(i + 1, min(i + 3, end)) if lines[j].strip()), "")
        b = BRACKET.match(nxt)
        if b and DATE.match(nxt):
            b = None            # "[Sep 6]" heads the next day, it is not a scorer
        if b:
            h, a = parse_bracket(b.group(1), hs, as_, problems, where)
            if h is not None:
                goals = ([{**g, "side": "home"} for g in h]
                         + [{**g, "side": "away"} for g in a])
        out.append({
            "source": "rsssf", "season": season, "round": rnd, "date": date,
            "home": home, "away": away, "homeScore": hs, "awayScore": as_,
            "goals": goals,
        })
    return out


def main(src):
    problems, out = [], []
    for f in sorted(Path(src).glob("*.html")):
        out += normalize_page(f, problems)
    for p in problems:
        print(f"PROBLEM {p}", file=sys.stderr)
    named = sum(len(m["goals"]) for m in out)
    print(f"{len(out)} matches, {named} named goals, {len(problems)} problems", file=sys.stderr)
    json.dump(out, sys.stdout, ensure_ascii=False, indent=1)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    main(sys.argv[1])
