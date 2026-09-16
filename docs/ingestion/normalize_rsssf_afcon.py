"""RSSSF's African Nations Cup pages (1957-2000) -> one canonical JSON.

    python3 normalize_rsssf_afcon.py raw/afcon_pre2002 canon_afcon_pre2002.json

Only the FINAL TOURNAMENT is taken. Every page also carries the qualifying
tournament, which belongs to a different competition ("African Cup of Nations
Qualification" already exists in the vault) and is left alone.

The pages are hand-written plain text, and the layout drifts across four
decades: the venue moves from a trailing "[in Cairo]" to a column between the
date and the teams, half-time scores appear in the 1990s, and walkovers,
abandonments, extra time and shoot-outs are all written in prose. So this
parser never guesses a team name: it builds each tournament's vocabulary from
the printed group tables and from the unambiguous right-hand side of match
lines, then reads the left-hand side against it. Anything it cannot read is
reported as an `unparsed` line rather than dropped, so nothing disappears
quietly.
"""
import json
import re
import sys
import unicodedata
from html import unescape
from pathlib import Path

YEARS = "57 59 62 63 65 68 70 72 74 76 78 80 82 84 86 88 90 92 94 96 98 00".split()

# Seed vocabulary. A team that only ever plays at home in a tournament (Egypt
# in 1957) never appears on the unambiguous right-hand side, so the parser
# would have nothing to recognise it by. Includes the names these countries
# played under at the time -- Zaire, Upper Volta, Dahomey -- which is what the
# pages say; mapping them to today's names is the loader's job, not this one.
KNOWN_TEAMS = [
    "Algeria", "Angola", "Benin", "Botswana", "Burkina Faso", "Burundi", "Cameroon",
    "Cape Verde", "Central African Republic", "Cen. Afr. Rep.", "C.A.R.", "Chad", "Comoros",
    "Congo", "Congo-Brazzaville", "Congo-Brazzav.", "Congo (Brazzaville)", "Congo-Kinshasa",
    "Congo (Kinshasa)", "DR Congo", "Djibouti", "Egypt", "Equatorial Guinea", "Equat. Guinea",
    "Eritrea", "Ethiopia", "Gabon", "Gambia", "Ghana", "Guinea", "Guinea-Bissau",
    "Ivory Coast", "Kenya", "Lesotho", "Liberia", "Libya", "Madagascar", "Malawi", "Mali",
    "Mauritania", "Mauritius", "Morocco", "Mozambique", "Namibia", "Niger", "Nigeria",
    "Rwanda", "Senegal", "Seychelles", "Sierra Leone", "Somalia", "South Africa", "Sudan",
    "Swaziland", "Tanzania", "Togo", "Tunisia", "Uganda", "Zambia", "Zimbabwe",
    # Names these sides played under at the time; mapping them to today's
    # names is the loader's job, not this one.
    "Zaire", "Rhodesia", "Upper Volta", "Dahomey", "Tanganyika", "United Arab Republic",
    "Zanzibar", "Somaliland",
]

DATE = re.compile(r"^\s*(\d{1,2})-\s*(\d{1,2})-(\d{2})\s+(.*)$")
# " 2-1 ", " 2-1 (1-0) ", " w/o ", " abd " — the pivot of a match line.
SCORE = re.compile(r"\s(?:(\d{1,2})\s*-\s*(\d{1,2})(?:\s*\(\s*(\d{1,2})\s*-\s*(\d{1,2})\s*\))?|(w/o|awd)|(abd))\s")
TABLE_ROW = re.compile(r"^\s*\d{1,2}\.\s*([A-Za-z][A-Za-z .'\-()]+?)\s{2,}(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*-\s*(\d+)\s+(\d+)\s*$")
STOP = re.compile(r"^\s*(Topscorer|Top scorer|Squad|All-time|Qualifying Tournament|Final Standings|Champions)", re.I)


def clean(raw: bytes) -> list[str]:
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        text = raw.decode("cp1252")
    text = unescape(re.sub(r"<[^>]+>", "", text))
    return [l.rstrip() for l in text.splitlines()]


CANONICAL = {}


def canonical(name: str) -> str:
    """One spelling per team. Printed tables capitalise whoever went through."""
    if not CANONICAL:
        CANONICAL.update({norm(k): k for k in KNOWN_TEAMS})
    known = CANONICAL.get(norm(name))
    if known:
        return known
    return name.title() if name.isupper() else name


def norm(name: str) -> str:
    n = unicodedata.normalize("NFKD", name).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z]", "", n.lower())



# --------------------------------------------------------------------- goals
# Scorer lines, e.g.
#   [Ali Abugreisha 6, A.Khalil 52; Mubiru 28]        minute after the name
#   [13' Siasia, 89' Keshi; 36' Bocande; Ref: ...]    minute before (1990s)
#   [Mohammed Diab El-Attar 'El-Diba' 2' 7' 68' 89']  one scorer, four goals
#   [Kobinan (2); Mubiru (2)]                         a count, no minutes
#   [Kamel (og) 42, El Borosi 83]                     see OWN GOALS below
#   [Girma Asmerom, Luciano Vassalo pen / Polly Ouma] '/' separates the sides
#
# OWN GOALS: RSSSF lists a goal under the side it COUNTS FOR, so "(og)" on the
# home list means an away player put it in his own net. The vault stores the
# opposite -- an OWN_GOAL belongs to the scorer's own team (design principle 5)
# -- so the loader flips the side. Getting this backwards is exactly the defect
# the 2026-09-12 ligikuu correction had to undo.
META = re.compile(r"\b(Ref|Referee|Att|Attendance|Note|Topscorer)\b\s*:", re.I)
LINEUP = re.compile(r"^\[[^\]:0-9]{2,30}:")
MINUTE_FIRST = re.compile(r"^(\d{1,3})\s*'?\s*\+?(\d+)?\s*(.*)$")
MINUTE_LAST = re.compile(r"^(.*?)[\s,]+(\d{1,3})\s*'?\s*(?:\+\s*\d+)?$")


def scorer_notes(notes):
    """The bracketed text that lists scorers, metadata trimmed off."""
    out = []
    for n in notes:
        if not n.startswith("[") or LINEUP.match(n):
            continue
        body = n.strip().lstrip("[").rstrip("]")
        if body.lower().startswith(("aet", "in ", "at ", "awarded", "replay", "ht ", "*")):
            continue
        body = META.split(body)[0]
        if re.search(r"[A-Za-z]", body) and not body.lower().startswith("some "):
            out.append(body.strip().rstrip(";,"))
    return out


def parse_side(text):
    """One side's scorers: [{name, minute, penalty, own}] in the order given."""
    goals, last = [], None
    for raw in re.split(r",", text):
        token = raw.strip().rstrip(".;")
        if not token:
            continue
        # Loosen the forms these pages use before reading anything off the
        # token: "55pen" and "3og" hang the marker straight off the minute,
        # "(pen)" wraps it, and one 1992 line prefixes the running score.
        token = re.sub(r"\(\s*(pen|o\.?g)\.?\s*\)", r" \1 ", token, flags=re.I)
        token = re.sub(r"(\d)\s*(pen|og)\b", r"\1 \2 ", token, flags=re.I)
        token = re.sub(r"^\s*\d{1,2}\s*-\s*\d{1,2}\s+", "", token)

        own = bool(re.search(r"\bo\.?g\.?\b", token, re.I))
        pen = bool(re.search(r"\bpen\b|\bpen\.", token, re.I))
        token = re.sub(r"\bo\.?g\.?\b", " ", token, flags=re.I)
        token = re.sub(r"\bpen\.?\b", " ", token, flags=re.I)
        token = re.sub(r"\(\s*\)", " ", token).strip()

        # "Williams 72, 74" -- a bare number is another goal for the last scorer.
        if re.fullmatch(r"\d{1,3}\s*'?", token) and last:
            goals.append({**last, "minute": int(token.rstrip("' ")), "penalty": pen, "own": own})
            continue
        # "Kobinan (2)" and "Edward Acquah x2" -- a count with no minutes.
        count = re.search(r"\((\d)\)\s*$|\bx\s*(\d)\s*$", token)
        repeat = int(count.group(1) or count.group(2)) if count else 1
        token = re.sub(r"\((\d)\)\s*$|\bx\s*\d\s*$", "", token).strip()
        # Any remaining bracketed aside is an annotation, not part of a name:
        # a running score "(1-3)", or "(other sources: Aluka)". Counts like
        # "(2)" are digits only and were taken above.
        token = re.sub(r"\([^)]*[^\d)][^)]*\)", " ", token)
        token = re.sub(r"\s{2,}", " ", token).strip()

        minutes, name = [], token
        m = MINUTE_FIRST.match(token)
        if m and m.group(3).strip():
            minutes, name = [int(m.group(1))], m.group(3).strip()
        else:
            # trailing minutes, possibly several: "El-Diba 2' 7' 68' 89'"
            trail = re.search(r"^(.*?)((?:\s+\d{1,3}\s*'(?:\s*\+\s*\d+)?)+)$", token)
            if trail:
                name = trail.group(1).strip()
                minutes = [int(x) for x in re.findall(r"\d{1,3}", trail.group(2))]
            else:
                m2 = MINUTE_LAST.match(token)
                if m2 and re.search(r"[A-Za-z?]", m2.group(1)):
                    name, minutes = m2.group(1).strip(), [int(m2.group(2))]
        name = re.sub(r"^[\d'\s.-]+", "", name).strip(" '.-")
        unknown = name in ("", "?") or not re.search(r"[A-Za-z]", name)
        entry = {"name": None if unknown else name, "penalty": pen, "own": own}
        for i in range(max(repeat, len(minutes) or 1)):
            goals.append({**entry, "minute": minutes[i] if i < len(minutes) else None})
        last = entry
    return goals


def parse_goals(notes, home_score, away_score):
    """Both sides' scorers — only when they add up to the score.

    The separator between the sides is usually ';' (or '/'), but the 1992 page
    also uses ';' between two scorers for the SAME side, so the separator alone
    cannot be trusted. Every split point is tried and the one that reconciles
    with the score is taken; if none does, this returns None and the match is
    loaded without goal events rather than with wrong ones.
    """
    text = "; ".join(scorer_notes(notes))
    if not text.strip():
        return None

    def sided(home_goals, away_goals):
        for g in home_goals:
            g["side"] = "home"
        for g in away_goals:
            g["side"] = "away"
        return home_goals + away_goals

    sep = ";" if ";" in text else "/" if "/" in text else None
    if sep:
        segments = [parse_side(part) for part in text.split(sep)]
        fits = [
            i for i in range(len(segments) + 1)
            if sum(len(x) for x in segments[:i]) == home_score
            and sum(len(x) for x in segments[i:]) == away_score
        ]
        if len(fits) != 1:
            return None
        i = fits[0]
        return sided([g for seg in segments[:i] for g in seg], [g for seg in segments[i:] for g in seg])

    goals = parse_side(text)
    if len(goals) == home_score and away_score == 0:
        return sided(goals, [])
    if len(goals) == away_score and home_score == 0:
        return sided([], goals)
    return None


def stage_of(line: str):
    """The round a heading announces, or None if the line is not a heading."""
    s = line.strip().rstrip(":")
    if re.match(r"^Group\s+([A-D]|\d)\b", s, re.I):
        return "GROUP", re.sub(r"^Group\s+", "", s, flags=re.I).split()[0].strip("()")
    for pattern, stage in (
        (r"^(Quarter[- ]?finals?|Quarterfinals)\b", "QUARTER FINAL"),
        (r"^(Semi[- ]?finals?|Semifinals)\b", "SEMI FINAL"),
        (r"^(Match for |Play-?off for |)(3rd|Third)[ -]?(and 4th )?[Pp]lace", "THIRD PLACE"),
        # 1959, 1976: the tournament was decided by a final round-robin, not a
        # final. Its matches are group matches with a section of their own.
        (r"^Final (Phase|Round|Group|Pool)\b", "FINAL ROUND"),
        (r"^Finals?$", "FINAL"),
        (r"^Final\b(?!\s*Tournament)", "FINAL"),
        (r"^(First|1st) Round\b", "GROUP"),
        (r"^(Second|2nd) Round\b", "SECOND ROUND"),
    ):
        if re.match(pattern, s, re.I):
            return stage, None
    return None


def final_tournament(lines: list[str]) -> list[str]:
    # 2000 carries a second "Final Tournament" heading for the squad lists, so
    # the section is the first one that actually has match lines under it.
    starts = [i for i, l in enumerate(lines) if re.match(r"^\s*Final Tournament", l) and "squad" not in l.lower()]
    if not starts:
        return []
    start = next((i for i in starts if any(DATE.match(x) for x in lines[i + 1:i + 60])), starts[-1])
    out = []
    for line in lines[start + 1:]:
        if STOP.match(line):
            break
        out.append(line)
    return out


def parse_tournament(year: int, lines: list[str]) -> dict:
    body = final_tournament(lines)
    host = ""
    for i, l in enumerate(lines):
        if re.match(r"^\s*Final Tournament", l):
            m = re.search(r"\((.+?)\)", l)
            host = m.group(1) if m else ""
    # Vocabulary: printed tables, then the right-hand side of match lines,
    # which needs no vocabulary to read.
    vocab: set[str] = set(KNOWN_TEAMS)
    tables = []
    table_section = None
    for l in body:
        head = stage_of(l)
        if head and not DATE.match(l):
            table_section = f"GROUP {head[1]}" if head[0] == "GROUP" and head[1] else head[0]
        t = TABLE_ROW.match(l)
        if t:
            vocab.add(t.group(1).strip())
            tables.append({
                "section": table_section,
                "team": canonical(t.group(1).strip()), "played": int(t.group(2)), "won": int(t.group(3)),
                "drawn": int(t.group(4)), "lost": int(t.group(5)),
                "goalsFor": int(t.group(6)), "goalsAgainst": int(t.group(7)), "points": int(t.group(8)),
            })
    for l in body:
        d = DATE.match(l)
        if not d:
            continue
        s = SCORE.search(d.group(4))
        if s:
            right = d.group(4)[s.end():].split("[")[0].strip().rstrip("*").strip()
            if right:
                vocab.add(right)
    by_norm = {norm(v): v for v in vocab if norm(v)}

    matches, unparsed = [], []
    stage, group = None, None
    current = None
    for line in body:
        if not line.strip():
            continue
        head = stage_of(line)
        if head and not DATE.match(line):
            stage, group = head[0], head[1]
            current = None
            continue
        if TABLE_ROW.match(line):
            current = None
            continue

        d = DATE.match(line)
        if d:
            day, month, yy, rest = int(d.group(1)), int(d.group(2)), int(d.group(3)), d.group(4)
            s = SCORE.search(rest)
            if not s:
                unparsed.append(line)
                current = None
                continue
            left, right = rest[:s.start()], rest[s.end():]
            # The right-hand side is always "TeamB [notes]".
            away = right.split("[")[0].strip().rstrip("*").strip()
            note = right[len(right.split("[")[0]):].strip()
            paren = re.search(r"\s*\(([^)]*)\)\s*$", away)
            if paren:
                away = away[: paren.start()].strip()
                note = (note + " " + paren.group(0).strip()).strip()
            # The left-hand side may carry a venue column before the team.
            home, venue = None, None
            for length in range(len(left), 0, -1):
                candidate = left[:length].strip()
                if norm(candidate) in by_norm:
                    home, venue = by_norm[norm(candidate)], None
                    break
            if home is None:
                for name_norm, name in sorted(by_norm.items(), key=lambda kv: -len(kv[0])):
                    if norm(left).endswith(name_norm):
                        home = name
                        # Whatever precedes the team on that side is the venue
                        # column the 1990s pages introduced.
                        idx = left.lower().rfind(name.split()[0].lower())
                        venue = left[:idx].strip().rstrip(",") or None
                        break
            if home is None or not away:
                unparsed.append(line)
                current = None
                continue
            century = 1900 if yy >= 50 else 2000
            current = {
                "stage": stage or "UNKNOWN",
                "group": group,
                "date": f"{century + yy:04d}-{month:02d}-{day:02d}",
                "home": canonical(home), "away": canonical(away),
                "homeScore": int(s.group(1)) if s.group(1) else None,
                "awayScore": int(s.group(2)) if s.group(2) else None,
                "htHome": int(s.group(3)) if s.group(3) else None,
                "htAway": int(s.group(4)) if s.group(4) else None,
                "walkover": bool(s.group(5)),
                "abandoned": bool(s.group(6)),
                "venue": venue,
                "goals": None,  # filled once the match's note lines are all in
                "notes": [note] if note else [],
            }
            matches.append(current)
            continue

        # A continuation line: scorers, attendance, shoot-out, referee.
        if current is not None and line.strip().startswith("["):
            current["notes"].append(line.strip())
        elif current is not None and current["notes"] and current["notes"][-1].count("[") > current["notes"][-1].count("]"):
            # The previous note's bracket is still open: this line continues it,
            # as a scorer list too long for one line does.
            current["notes"][-1] = current["notes"][-1].rstrip() + " " + line.strip()
        elif current is not None and re.match(r"^\s{5,}\S", line) and re.search(r"penalt|\bpen\b|on pens", line, re.I):
            current["notes"].append(line.strip())

    # 1959 has no headings at all: three teams, one round-robin, one table.
    if matches and all(m["stage"] in (None, "UNKNOWN") for m in matches) and len(tables) >= 2:
        for m in matches:
            m["stage"] = "FINAL ROUND"
        for row in tables:
            row["section"] = "FINAL ROUND"

    for m in matches:
        m["goals"] = parse_goals(m["notes"], m["homeScore"] or 0, m["awayScore"] or 0)

    return {
        "year": 1900 + int(f"{year:02d}") if year >= 50 else 2000 + year,
        "host": host,
        "matches": matches,
        "tables": tables,
        "unparsed": unparsed,
    }


def main(raw_dir: str, out: str):
    tournaments = []
    for y in YEARS:
        lines = clean(Path(raw_dir, f"{y}.html").read_bytes())
        t = parse_tournament(int(y), lines)
        tournaments.append(t)
        print(f"{t['year']}  {len(t['matches']):3} matches  {len(t['tables']):2} table rows  "
              f"{len(t['unparsed']):3} unparsed  host={t['host'][:28]}")
    Path(out).write_text(json.dumps(tournaments, indent=1, ensure_ascii=False))
    print(f"\n{sum(len(t['matches']) for t in tournaments)} matches -> {out}")
    print(f"{sum(len(t['unparsed']) for t in tournaments)} lines unparsed")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
