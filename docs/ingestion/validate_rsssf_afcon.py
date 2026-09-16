"""Check the parsed pre-2002 AFCON tournaments before anything is merged.

    python3 validate_rsssf_afcon.py raw/afcon_pre2002/canon_afcon_pre2002.json raw/afcon_pre2002

Nothing here writes to the vault. Every check either passes or prints what is
wrong, so the decision to merge is made on evidence rather than on a match
count looking about right.

The strongest check is the group tables: RSSSF prints final standings next to
the fixtures, and those are written by a different hand than the match lines.
Recomputing them from the parsed matches catches a misread score, a match
attributed to the wrong team, and a match dropped entirely.
"""
import json
import re
import sys
import unicodedata
from collections import defaultdict
from html import unescape
from pathlib import Path

# RSSSF's own index (tablesa/afrchamp.html), independent of the per-tournament
# pages this parse came from.
WINNERS = {
    1957: ("Egypt", "Sudan"), 1959: ("Egypt", "Egypt"), 1962: ("Ethiopia", "Ethiopia"),
    1963: ("Ghana", "Ghana"), 1965: ("Ghana", "Tunisia"), 1968: ("Congo (Kinshasa)", "Ethiopia"),
    1970: ("Sudan", "Sudan"), 1972: ("Congo (Brazzaville)", "Cameroon"), 1974: ("Zaire", "Egypt"),
    1976: ("Morocco", "Ethiopia"), 1978: ("Ghana", "Ghana"), 1980: ("Nigeria", "Nigeria"),
    1982: ("Ghana", "Libya"), 1984: ("Cameroon", "Ivory Coast"), 1986: ("Egypt", "Egypt"),
    1988: ("Cameroon", "Morocco"), 1990: ("Algeria", "Algeria"), 1992: ("Ivory Coast", "Senegal"),
    1994: ("Nigeria", "Tunisia"), 1996: ("South Africa", "South Africa"), 1998: ("Egypt", "Burkina Faso"),
    2000: ("Cameroon", "Nigeria/Ghana"),
}

def strip_paren(name):
    return re.sub(r"\s*\(.*?\)", "", name).strip()


def same_team(a, b):
    """Congo (Brazzaville) is "Congo" on its own pages; Zaire is Congo (Kinshasa)."""
    ALIAS = {"congokinshasa": "zaire", "drcongo": "zaire", "congobrazzaville": "congo"}
    na, nb = (ALIAS.get(norm(x), norm(x)) for x in (a, b))
    return na == nb or norm(strip_paren(a)) == norm(strip_paren(b))


def groupby_section(rows):
    out = defaultdict(list)
    for r in rows:
        out[r["section"] or "GROUP"].append(r)
    return out


def norm(s):
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z]", "", s.lower())

def source_match_lines(raw_dir, year_key):
    raw = Path(raw_dir, f"{year_key}.html").read_bytes()
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        text = raw.decode("cp1252")
    lines = [l.rstrip() for l in unescape(re.sub(r"<[^>]+>", "", text)).splitlines()]
    starts = [i for i, l in enumerate(lines) if re.match(r"^\s*Final Tournament", l) and "squad" not in l.lower()]
    date = re.compile(r"^\s*\d{1,2}-\s*\d{1,2}-\d{2}\s")
    start = next((i for i in starts if any(date.match(x) for x in lines[i + 1:i + 60])), starts[-1])
    stop = re.compile(r"^\s*(Topscorer|Top scorer|Squad|All-time|Qualifying Tournament|Final Standings|Champions)", re.I)
    out = []
    for l in lines[start + 1:]:
        if stop.match(l):
            break
        if date.match(l):
            out.append(l)
    return out

def main(canon_path, raw_dir):
    tournaments = json.load(open(canon_path))
    year_keys = {t["year"]: f"{t['year'] % 100:02d}" for t in tournaments}
    problems, notes = [], []

    for t in tournaments:
        y = t["year"]
        tag = f"{y}"
        ms = t["matches"]

        # 1. Nothing dropped: every dated line in the source became a match.
        src = source_match_lines(raw_dir, year_keys[y])
        if len(src) != len(ms):
            problems.append(f"{tag}: source has {len(src)} match lines, parsed {len(ms)}")

        # 2. Scores present and sane.
        for m in ms:
            if m["walkover"] or m["abandoned"]:
                continue
            if m["homeScore"] is None or m["awayScore"] is None:
                problems.append(f"{tag}: no score — {m['date']} {m['home']} v {m['away']}")
            elif not (0 <= m["homeScore"] <= 15 and 0 <= m["awayScore"] <= 15):
                problems.append(f"{tag}: improbable score — {m['date']} {m['home']} {m['homeScore']}-{m['awayScore']} {m['away']}")
            if m["htHome"] is not None and (m["htHome"] > m["homeScore"] or m["htAway"] > m["awayScore"]):
                problems.append(f"{tag}: half-time beats full-time — {m['date']} {m['home']} v {m['away']}")

        # 3. Dates inside one tournament window, and in the right year.
        dates = sorted(m["date"] for m in ms)
        if dates:
            span = (int(dates[-1][:4]) - int(dates[0][:4])) * 365 + (int(dates[-1][5:7]) - int(dates[0][5:7])) * 31
            if span > 62:
                problems.append(f"{tag}: matches span {dates[0]} to {dates[-1]}")
            years = {d[:4] for d in dates}
            if years != {str(y)}:
                problems.append(f"{tag}: dates in {sorted(years)}, expected {y}")

        # 4. Duplicates.
        seen = defaultdict(int)
        for m in ms:
            seen[(m["date"], norm(m["home"]), norm(m["away"]))] += 1
        for key, n in seen.items():
            if n > 1:
                problems.append(f"{tag}: {n} identical matches — {key[0]} {key[1]} v {key[2]}")

        # 5. The tournament's winner. Most are decided by a final; 1959 and
        #    1976 were decided by a final round-robin, which is not the same
        #    thing and must not be read as one.
        finals = [m for m in ms if m["stage"] == "FINAL"]
        final_round = [r for r in t["tables"] if r["section"] == "FINAL ROUND"]
        want = WINNERS[y][0]
        if finals:
            f = finals[-1]  # 1974's final was replayed
            if f["homeScore"] is None or f["awayScore"] is None:
                problems.append(f"{tag}: final has no score ({f['home']} v {f['away']})")
            else:
                blob = " ".join(f["notes"])
                if f["homeScore"] > f["awayScore"]:
                    won = f["home"]
                elif f["awayScore"] > f["homeScore"]:
                    won = f["away"]
                else:
                    shootout = re.search(r"(\w[\w .'-]*?)\s+(?:won|win)\s+(\d+)-(\d+)\s+on penalties", blob, re.I)
                    pens = re.search(r"(\d+)\s*-\s*(\d+)\s*pen", blob, re.I)
                    if shootout:
                        won = shootout.group(1).strip()
                    elif pens:
                        won = f["home"] if int(pens.group(1)) > int(pens.group(2)) else f["away"]
                    else:
                        problems.append(f"{tag}: final drawn {f['homeScore']}-{f['awayScore']} with nothing recorded to decide it")
                        won = None
                if won and not same_team(won, want):
                    problems.append(f"{tag}: final won by {won}, RSSSF's index says {want}")
        elif final_round:
            top = max(final_round, key=lambda r: (r["points"], r["goalsFor"] - r["goalsAgainst"]))
            notes.append(f"{tag}: decided by a final round-robin, not a final — won by {top['team']}")
            if not same_team(top["team"], want):
                problems.append(f"{tag}: final round topped by {top['team']}, RSSSF's index says {want}")
        else:
            problems.append(f"{tag}: no final and no final round parsed")

        # 6. Every printed table recomputed from the matches of its own section.
        by_section = defaultdict(list)
        for m in ms:
            if m["stage"] == "GROUP":
                by_section[f"GROUP {m['group']}" if m["group"] else "GROUP"].append(m)
            elif m["stage"] == "FINAL ROUND":
                by_section["FINAL ROUND"].append(m)
        for section, rows in groupby_section(t["tables"]).items():
            tally = defaultdict(lambda: dict(P=0, W=0, D=0, L=0, GF=0, GA=0))
            for m in by_section.get(section, []):
                if m["homeScore"] is None or m["awayScore"] is None:
                    continue
                for team, gf, ga in ((m["home"], m["homeScore"], m["awayScore"]), (m["away"], m["awayScore"], m["homeScore"])):
                    r = tally[norm(team)]
                    r["P"] += 1; r["GF"] += gf; r["GA"] += ga
                    r["W" if gf > ga else "D" if gf == ga else "L"] += 1
            for row in rows:
                # Tables abbreviate: 1968 prints "Congo-Brazzav." for Congo-Brazzaville.
                key = norm(row["team"])
                c = tally.get(key) or tally.get(norm(strip_paren(row["team"])))
                if not c and row["team"].rstrip().endswith("."):
                    c = next((v for k, v in tally.items() if k.startswith(key)), None)
                if not c:
                    problems.append(f"{tag}: {section} lists {row['team']} but no match was parsed for them")
                    continue
                got = (c["P"], c["W"], c["D"], c["L"], c["GF"], c["GA"])
                exp = (row["played"], row["won"], row["drawn"], row["lost"], row["goalsFor"], row["goalsAgainst"])
                if got != exp:
                    problems.append(f"{tag} {section}: {row['team']} computes {got}, printed table says {exp} (P W D L GF GA)")

    print(f"{len(tournaments)} tournaments, {sum(len(t['matches']) for t in tournaments)} matches\n")
    print(f"PROBLEMS ({len(problems)}):")
    for p in problems:
        print("  ✗", p)
    print(f"\nWORTH KNOWING ({len(notes)}):")
    for n in notes:
        print("  •", n)

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
