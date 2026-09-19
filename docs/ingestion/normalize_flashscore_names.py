"""Turn a Flashscore harvest into records keyed on vault match ids.

    python3 normalize_flashscore_names.py raw/flashscore_tpl/2019-2020.tsv 2019/2020 > staged.json
    python3 -m doctest normalize_flashscore_names.py

Same job as `normalize_fotmob_tpl.py`, and it emits the same shape, so the one
loader serves both. Two differences are worth the separate file:

**Flashscore gives a slug, not a name.** Its timeline abbreviates ("Nado I.")
and the scorer's link carries the whole name ("/player/seleman-iddi/"). The slug
is turned into a readable name by `match_flashscore_players.name_from`, which is
already doctested and already knows that a slug reads surname-first.

**A goal can have no scorer at all.** Flashscore lists the goal with its minute
and side but no player link for some matches -- 9 of 2019/20's 169. Those are
written as a goal with no name, exactly like FotMob's `<TBD>`.

A fixture is identified by its two clubs and its score, never its date; see the
FotMob normaliser for why.
"""
import json
import sys
from collections import defaultdict
from datetime import date

import psycopg2

from match_flashscore_players import name_from
from teamnames import key

DSN = "host=127.0.0.1 port=5432 dbname=sokabrain"
TYPES = {"G": "GOAL", "PEN": "PENALTY_GOAL", "OG": "OWN_GOAL"}


def parse_goal(tok):
    """One `minute~side~type~slug` token.

    >>> g = parse_goal("62~H~G~chirwa-aubrey")
    >>> g['minute'], g['side'], g['type'], g['name']
    (62, 'home', 'GOAL', 'Aubrey Chirwa')

    Stoppage time rides on the minute:

    >>> g = parse_goal("90+4~A~G~chidiebere-abasalim")
    >>> g['minute'], g['added']
    (90, 4)

    An own goal keeps the side it counts for:

    >>> parse_goal("41~H~OG~natley-david")['type']
    'OWN_GOAL'

    A goal Flashscore lists without a scorer has no name:

    >>> parse_goal("2~H~G~?")['name'] is None
    True
    """
    minute, side, typ, slug = tok.split("~", 3)
    base, _, extra = minute.partition("+")
    slug = slug.strip()
    return {
        "minute": int(base),
        "added": int(extra) if extra else None,
        "side": "home" if side == "H" else "away",
        "type": TYPES[typ],
        "name": None if slug in ("", "?") else name_from(slug),
        "slug": None if slug in ("", "?") else slug,
    }


def parse_line(line):
    """One harvest line into its parts.

    >>> m = parse_line("W4zDVTNk^^2020-06-23|Mbao|Coastal Union|1-0^^7~H~G~john-jordan")
    >>> m['ext'], m['date'], m['home'], m['away'], m['score']
    ('W4zDVTNk', '2020-06-23', 'Mbao', 'Coastal Union', (1, 0))
    >>> m['goals'][0]['name']
    'Jordan John'
    """
    ext, exp, gs = line.rstrip("\n").split("^^")
    d, home, away, score = exp.split("|")
    h, a = (int(x) for x in score.split("-"))
    return {"ext": ext, "date": d, "home": home, "away": away, "score": (h, a),
            "goals": [parse_goal(t) for t in gs.split(";") if t]}


def main(path, season):
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
        cands = by_pair.get((key(r["home"]), key(r["away"])), [])
        if len(cands) != 1:
            problems.append(f"{r['date']} {r['home']} v {r['away']}: {len(cands)} vault fixtures")
            continue
        mid, d, hsc, asc = cands[0]
        if (hsc, asc) != r["score"]:
            problems.append(
                f"match {mid} {r['home']} v {r['away']}: vault {hsc}-{asc}, "
                f"Flashscore {r['score'][0]}-{r['score'][1]}")
            continue
        gap = abs((d - date.fromisoformat(r["date"])).days)
        if gap > 3:
            problems.append(
                f"note: match {mid} {r['home']} v {r['away']} is dated {d} in the vault and "
                f"{r['date']} on Flashscore; loaded anyway, the date is left alone")
        staged.append({"match": mid, "ext": r["ext"], "goals": r["goals"]})

    print(f"{len(rows)} harvested, {len(staged)} matched to vault fixtures", file=sys.stderr)
    for p in problems:
        print(f"  {p}", file=sys.stderr)
    json.dump(staged, sys.stdout, ensure_ascii=False, indent=1)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    main(sys.argv[1], sys.argv[2])
