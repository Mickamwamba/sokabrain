"""Turn Wikipedia AFCON wikitext into canonical match-and-scorer records.

    python3 normalize_wikipedia_afcon.py 1996 1998 > raw/afcon_wikipedia/canon.json

This exists to attach scorers to tournaments the vault already holds as results
only: RSSSF names a scorer for 4 of the 171 goals in 1996 and 1998, and
Wikipedia names nearly all of them. It therefore emits NO fixtures of its own --
just each match's identity (date, sides, score) so the loader can find the
vault's row, and the goals.

The goal grammar, all of it observed in these two articles:

    {{goal|15}}                 one goal, 15'
    {{goal|30||33}}             the same player twice; the empty argument is
                                the separator, not a missing minute
    {{goal|36|pen.}}            a penalty
    {{goal|90|o.g.}}            an own goal
    {{goal|57|pen.|73|pen.}}    two penalties
    {{goal|16||85|pen.}}        one ordinary goal and one penalty
    {{golden goal|105}}         the 1996 quarter-final winner

So: a numeric argument opens a goal, and a following non-numeric argument
qualifies the goal just opened. Anything else is reported rather than dropped.

**Own goals keep Wikipedia's side here, which is the side the goal COUNTS FOR.**
Flipping them to the scorer's own team is the loader's job (design principle 5),
for the same reason it is in load_afcon_pre2002.py -- one place, one decision.

Players are taken from the link TARGET, not the display text: "[[Phil
Masinga|Masinga]]" yields "Phil Masinga". That is the whole reason this source
is worth having for these years -- it can name a player the vault holds only as
a surname, and a full name is what lets the loader recognise him.
"""
import json
import re
import sys
from pathlib import Path

RAW = Path(__file__).parent / "raw" / "afcon_wikipedia"

# Wikipedia's three-letter codes, mapped to the vault's spelling. The vault
# misspells Morocco and Sierra Leone; nationnames.py explains why those stand.
# BUR and BFA are both Burkina Faso in these articles (Burundi would be BDI and
# played in neither tournament); ZAI and COD are both DR Congo.
CODES = {
    "ALG": "Algeria", "ANG": "Angola", "BFA": "Burkina Faso", "BUR": "Burkina Faso",
    "CIV": "Ivory Coast", "CMR": "Cameroon", "COD": "DR Congo", "ZAI": "DR Congo",
    "EGY": "Egypt", "GAB": "Gabon", "GHA": "Ghana", "GUI": "Guinea", "LBR": "Liberia",
    "MAR": "Morroco", "MOZ": "Mozambique", "NAM": "Namibia", "RSA": "South Africa",
    "SLE": "Sierra Leon", "TOG": "Togo", "TUN": "Tunisia", "ZAM": "Zambia",
}

BOX = re.compile(r"\{\{football ?box.*?\n\}\}", re.S | re.I)
FIELD = r"\|\s*%s\s*=(.*?)(?=\n\s*\|\s*\w+\s*=|\n\}\})"
TEAM = re.compile(r"\{\{fb(?:-rt)?\|([A-Z]{3})", re.I)
SCORE = re.compile(r"(\d+)\s*[-–—]\s*(\d+)")
GOAL_TMPL = re.compile(r"\{\{(goal|golden goal)\|([^}]*)\}\}", re.I)
# A scorer is whatever sits between the previous goal template and this one.
LINK = re.compile(r"\[\[([^\]|]+)(?:\|([^\]]+))?\]\]")

PEN = re.compile(r"^pen", re.I)
OWN = re.compile(r"^o\.?\s*g", re.I)


def field(block, name):
    m = re.search(FIELD % name, block, re.S)
    return m.group(1).strip() if m else ""


def player_name(chunk, previous, problems, where):
    """The link target, or the bare text when Wikipedia has no article.

    A chunk holding nothing but punctuation means the same player scored again:
    Wikipedia writes "[[Benni McCarthy|McCarthy]] {{goal|60}}, {{golden
    goal|112}}" for a man who scored twice. Inheriting the previous scorer is
    the only reading that keeps the goal, and dropping it would leave the match
    a goal short of its own score.
    """
    chunk = re.sub(r"<br\s*/?>", " ", chunk)
    chunk = re.sub(r"\{\{[^}]*\}\}", " ", chunk)          # stray flag icons etc.
    links = LINK.findall(chunk)
    if links:
        # The target is the canonical name; the display text is usually a
        # surname. Wikipedia disambiguates article titles for common names --
        # "Mark Williams (South African footballer)", "Joni (footballer, born
        # 1970)" -- and that parenthetical is a property of the encyclopaedia,
        # not of the man, so it never belongs in the vault.
        target = links[-1][0].split("#")[0]
        return re.sub(r"\s*\([^)]*\)\s*$", "", target).strip()
    bare = re.sub(r"[\[\]']", " ", chunk).strip(" ,;")
    bare = " ".join(bare.split())
    if bare:
        return bare
    if previous:
        return previous
    problems.append(f"{where}: a goal with no scorer name")
    return None


def parse_goals(text, side, problems, where):
    """Every goal in one team's goal field, in the order written."""
    out = []
    if not text.strip():
        return out
    cursor = 0
    who = None
    for m in GOAL_TMPL.finditer(text):
        who = player_name(text[cursor:m.start()], who, problems, where)
        cursor = m.end()
        args = [a.strip() for a in m.group(2).split("|")]
        golden = m.group(1).lower() == "golden goal"
        opened = None
        for arg in args:
            if not arg:
                continue                                   # the || separator
            if arg.isdigit():
                opened = {"side": side, "player": who, "minute": int(arg),
                          "type": "GOAL", "golden": golden}
                out.append(opened)
            elif opened is None:
                problems.append(f"{where}: qualifier '{arg}' before any minute")
            elif PEN.match(arg):
                opened["type"] = "PENALTY_GOAL"
            elif OWN.match(arg):
                opened["type"] = "OWN_GOAL"
            else:
                problems.append(f"{where}: unknown goal qualifier '{arg}'")
    trailing = text[cursor:]
    if LINK.search(trailing) or re.search(r"[A-Za-z]{3}", re.sub(r"\{\{[^}]*\}\}", "", trailing)):
        problems.append(f"{where}: text after the last goal template: {' '.join(trailing.split())[:60]!r}")
    return out


def tournament(year, problems):
    text = (RAW / f"{year}.wikitext").read_text()
    matches = []
    for block in BOX.findall(text):
        date = field(block, "date")
        codes = TEAM.findall(field(block, "team1") + "\n" + field(block, "team2"))
        score = SCORE.search(field(block, "score"))
        where = f"{year} {'/'.join(codes)} {date}"
        if len(codes) != 2:
            problems.append(f"{where}: could not read both teams")
            continue
        unknown = [c for c in codes if c.upper() not in CODES]
        if unknown:
            problems.append(f"{where}: unmapped team code(s) {unknown}")
            continue
        if not score:
            problems.append(f"{where}: no score")
            continue
        goals = (parse_goals(field(block, "goals1"), "home", problems, where)
                 + parse_goals(field(block, "goals2"), "away", problems, where))
        matches.append({
            "year": int(year),
            "date": date,
            "home": CODES[codes[0].upper()],
            "away": CODES[codes[1].upper()],
            "homeScore": int(score.group(1)),
            "awayScore": int(score.group(2)),
            "goals": goals,
        })
    return matches


def main(years):
    problems, out = [], []
    for y in years:
        out.extend(tournament(y, problems))
    for p in problems:
        print(f"PROBLEM {p}", file=sys.stderr)
    print(f"{len(out)} matches, {sum(len(m['goals']) for m in out)} goals, "
          f"{len(problems)} problems", file=sys.stderr)
    json.dump(out, sys.stdout, ensure_ascii=False, indent=1)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    main(sys.argv[1:])
