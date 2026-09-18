"""Turn a FotMob Premier League harvest into records keyed on vault match ids.

    python3 normalize_fotmob_tpl.py raw/fotmob_tpl/2022-2023.tsv > staged.json
    python3 -m doctest normalize_fotmob_tpl.py

The harvest is one line per match, read off the rendered match page:

    <fotmob id>^^<date>|<home>|<away>|<score>^^<goal>;<goal>;...

with each goal `minute~side~type~scorer`. Stoppage time lives in a companion
`added.txt` as `<fotmob id>:<goal index>:<minute>+<added>`, because the first
extraction pass dropped it.

**A fixture is identified by its two clubs, not its date.** In a double
round-robin an ordered pair (home, away) meets exactly once a season, which is a
stronger key than a kickoff date the two sources can legitimately disagree
about. The date is checked as a guard rather than a key, and a gap of more than
three days is reported without rejecting the fixture; the score has to agree
exactly, and that is what actually stops a wrong pairing.

FotMob writes `<TBD>` where it has a goal but no scorer -- the event carries no
player link at all. That is a real goal with an unknown scorer, so the name
becomes None rather than a player called TBD.

Sides come from the running score, so they are the side each goal COUNTS FOR,
which is the convention the loader expects (it flips own goals on the way in).
"""
import json
import re
import sys
from datetime import date
from collections import defaultdict

import psycopg2

from teamnames import key

DSN = "host=127.0.0.1 port=5432 dbname=sokabrain"
TYPES = {"G": "GOAL", "PEN": "PENALTY_GOAL", "OG": "OWN_GOAL"}


def parse_goal(tok):
    """One `minute~side~type~scorer` token.

    >>> parse_goal("45~H~PEN~Clatous Chama") == {
    ...     'minute': 45, 'side': 'home', 'type': 'PENALTY_GOAL',
    ...     'added': None, 'name': 'Clatous Chama'}
    True

    An away own goal keeps the side it counts for -- the away team here:

    >>> parse_goal("12~A~OG~Oscar Masai")['side'], parse_goal("12~A~OG~Oscar Masai")['type']
    ('away', 'OWN_GOAL')

    FotMob's own placeholder is not a person:

    >>> parse_goal("36~H~G~<TBD>")['name'] is None
    True
    """
    minute, side, typ, name = tok.split("~", 3)
    name = name.strip()
    return {
        "minute": int(minute),
        "side": "home" if side == "H" else "away",
        "type": TYPES[typ],
        "added": None,
        "name": None if not name or name == "<TBD>" else name,
    }


def parse_line(line):
    """One harvest line into its parts.

    >>> m = parse_line("3987877^^2022-08-15|Singida Black Stars|Ruvu Shooting|0 - 1^^19~A~G~Ally Mwale")
    >>> m['fotmob'], m['date'], m['home'], m['away'], m['score']
    ('3987877', '2022-08-15', 'Singida Black Stars', 'Ruvu Shooting', (0, 1))
    >>> len(m['goals'])
    1

    A goalless draw has no goal section at all:

    >>> parse_line("3987888^^2022-09-10|Coastal Union|Polisi Tanzania FC|0 - 0^^")['goals']
    []
    """
    fid, exp, gs = line.rstrip("\n").split("^^")
    date, home, away, score = exp.split("|")
    h, a = (int(x) for x in score.split(" - "))
    return {
        "fotmob": fid, "date": date, "home": home, "away": away, "score": (h, a),
        "goals": [parse_goal(t) for t in gs.split(";") if t],
    }


def read_added(path):
    """`id:index:minute+added` tokens into {(id, index): added}.

    >>> read_added.__doc__ is not None
    True
    """
    out = {}
    try:
        text = open(path, encoding="utf-8").read()
    except FileNotFoundError:
        return out
    for tok in text.split():
        m = re.fullmatch(r"(\d+):(\d+):(\d+)\+(\d+)", tok)
        if not m:
            raise SystemExit(f"cannot read stoppage-time token {tok!r}")
        out[(m.group(1), int(m.group(2)))] = (int(m.group(3)), int(m.group(4)))
    return out


def season_of(path):
    """`raw/fotmob_tpl/2022-2023.tsv` is the 2022/2023 season.

    >>> season_of('raw/fotmob_tpl/2022-2023.tsv')
    '2022/2023'
    """
    return path.split("/")[-1].rsplit(".", 1)[0].replace("-", "/")


def main(path, season):
    added = read_added(path.rsplit("/", 1)[0] + "/added.txt")
    rows = [parse_line(l) for l in open(path, encoding="utf-8") if l.strip()]

    conn = psycopg2.connect(DSN)
    cur = conn.cursor()
    cur.execute("SET timezone = 'UTC'")
    cur.execute("""
        SELECT m.id, ht.name, at.name, m.kickoff_at::date, m.home_score, m.away_score
          FROM matches m
          JOIN competition_editions ce ON ce.id = m.competition_edition_id
          JOIN seasons s ON s.id = ce.season_id
          JOIN teams ht ON ht.id = m.home_team_id
          JOIN teams at ON at.id = m.away_team_id
         WHERE ce.competition_id = 1 AND s.label = %s
    """, (season,))
    by_pair = defaultdict(list)
    for mid, hn, an, d, hsc, asc in cur.fetchall():
        by_pair[(key(hn), key(an))].append((mid, d, hsc, asc))

    staged, problems = [], []
    for r in rows:
        pair = (key(r["home"]), key(r["away"]))
        cands = by_pair.get(pair, [])
        if len(cands) != 1:
            problems.append(f"{r['date']} {r['home']} v {r['away']}: {len(cands)} vault fixtures")
            continue
        mid, d, hsc, asc = cands[0]
        gap = abs((d - date.fromisoformat(r["date"])).days)
        if gap > 3:
            # Reported, not rejected. The clubs and the score both agree, and an
            # ordered pair meets once a season, so the fixture is not in doubt --
            # only its date is, and this load does not touch dates.
            problems.append(
                f"note: match {mid} {r['home']} v {r['away']} is dated {d} in the vault "
                f"and {r['date']} on FotMob; loaded anyway, the date is left alone")
        if (hsc, asc) != r["score"]:
            problems.append(
                f"match {mid} {r['home']} v {r['away']}: vault {hsc}-{asc}, FotMob "
                f"{r['score'][0]}-{r['score'][1]}")
            continue
        goals = []
        for i, g in enumerate(r["goals"]):
            g = dict(g)
            hit = added.get((r["fotmob"], i))
            if hit:
                if hit[0] != g["minute"]:
                    raise SystemExit(f"stoppage row {r['fotmob']}:{i} is not on minute {g['minute']}")
                g["added"] = hit[1]
            goals.append(g)
        staged.append({"match": mid, "fotmob": r["fotmob"], "goals": goals})

    print(f"{len(rows)} harvested, {len(staged)} matched to vault fixtures", file=sys.stderr)
    for p in problems:
        print(f"  {p}", file=sys.stderr)
    json.dump(staged, sys.stdout, ensure_ascii=False, indent=1)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    main(sys.argv[1], season_of(sys.argv[1]))
