#!/usr/bin/env python3
"""Give a season's fixtures their round numbers, from a FotMob fixture list.

    python3 load_rounds_fotmob.py raw/fotmob_tpl/2026-2027_rounds.txt 2026/2027           # dry run
    python3 load_rounds_fotmob.py raw/fotmob_tpl/2026-2027_rounds.txt 2026/2027 --commit

The input is one line per fixture, `round|home|away`, taken from the league
page's embedded `fixtures.allMatches` -- every entry there carries a `round`,
and the official site's own SportsPress export does not: its `day` field is
empty for all 215 of 2026/27's events.

`load_rounds.py` exists already and loads RSSSF's rounds for the older seasons;
this is the same job from the source that covers the current one.

**A round is only written where the vault has none.** A fixture that already
has one is left alone and, if the two disagree, reported -- the same rule as
every other loader here (principle 2).

Two checks run before anything is written, because a round list that is wrong
is worse than no rounds at all:

* the source's own shape must be consistent -- every round the same size, and
  no fixture listed twice;
* every fixture must match exactly one vault fixture on its two clubs.

Either failing stops the load rather than writing part of it.
"""
import sys
from collections import Counter, defaultdict

import psycopg2

sys.path.insert(0, __file__.rsplit("/", 1)[0])

from teamnames import key as team_key  # noqa: E402

DSN = "host=127.0.0.1 port=5432 dbname=sokabrain"


def read(path):
    """Either one `round|home|away` line per fixture, or the compact form.

    The compact form exists because getting a season out of the browser costs a
    call per ~950 characters, and naming both clubs on every line spends most of
    those characters repeating twenty club names. Indexing the clubs once turns
    a season from eight chunks into two:

        SEASON|2026/2027
        CLUBS|Pamba Jiji|Mbeya City|...
        1|0>5,1>6,...
    """
    lines = [l.rstrip("\n") for l in open(path, encoding="utf-8") if l.strip()]
    clubs = None
    for l in lines:
        if l.startswith("CLUBS|"):
            clubs = l.split("|")[1:]
    if clubs is None:
        return [tuple(x.strip() for x in l.split("|")) for l in lines]

    rows = []
    for l in lines:
        if l.startswith(("CLUBS|", "SEASON|")):
            continue
        rnd, _, pairs = l.partition("|")
        for pair in pairs.split(","):
            if not pair:
                continue
            h, _, a = pair.partition(">")
            rows.append((rnd.strip(), clubs[int(h)], clubs[int(a)]))
    return rows


def check_source(rows):
    """The list has to be a coherent fixture list before it is trusted."""
    problems = []
    pairs = [(team_key(h), team_key(a)) for _, h, a in rows]
    dupes = [p for p, n in Counter(pairs).items() if n > 1]
    if dupes:
        problems.append(f"{len(dupes)} club pairs appear more than once, e.g. {dupes[0]}")
    sizes = Counter(r for r, _, _ in rows)
    odd = {r: n for r, n in sizes.items() if n != max(sizes.values())}
    if odd:
        problems.append(f"rounds not all the same size: {odd}")
    clubs = {c for _, h, a in rows for c in (team_key(h), team_key(a))}
    expected = len(clubs) * (len(clubs) - 1)
    if len(rows) != expected:
        problems.append(
            f"{len(rows)} fixtures for {len(clubs)} clubs; a double round-robin is {expected}")

    # A club plays once per round. FotMob's `round` is trustworthy for the
    # seasons it has match pages for, but on the older fixture-list-only seasons
    # it buckets fixtures rather than reading a real matchday, and puts the same
    # club in one round twice. That is the signature of a derived round number,
    # and it disqualifies the whole season -- the rounds that look clean were
    # produced by the same guess as the ones that do not.
    twice = defaultdict(list)
    for r, h, a in rows:
        for c in (team_key(h), team_key(a)):
            twice[(r, c)].append(c)
    clashes = sorted({r for (r, _), got in twice.items() if len(got) > 1})
    if clashes:
        problems.append(
            f"{len(clashes)} rounds put a club in two fixtures at once: "
            f"{', '.join(clashes[:8])}")
    return problems


def main():
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    path, season = sys.argv[1], sys.argv[2]
    commit = "--commit" in sys.argv

    rows = read(path)
    problems = check_source(rows)
    print(f"{len(rows)} fixtures in {path}")
    for p in problems:
        print(f"  REFUSED: {p}")
    if problems:
        raise SystemExit("the source list is not a coherent fixture list; nothing written")
    print(f"  {len(set(r for r, _, _ in rows))} rounds, "
          f"{max(Counter(r for r, _, _ in rows).values())} fixtures each -- consistent")

    conn = psycopg2.connect(DSN)
    conn.autocommit = False
    cur = conn.cursor()
    cur.execute("SET timezone='UTC'")
    cur.execute("""
        SELECT m.id, ht.name, at.name, m.round
          FROM matches m
          JOIN competition_editions ce ON ce.id = m.competition_edition_id
          JOIN seasons s ON s.id = ce.season_id
          JOIN teams ht ON ht.id = m.home_team_id
          JOIN teams at ON at.id = m.away_team_id
         WHERE ce.competition_id = 1 AND s.label = %s
    """, (season,))
    by_pair = defaultdict(list)
    for mid, hn, an, rnd in cur.fetchall():
        by_pair[(team_key(hn), team_key(an))].append((mid, rnd))

    plan, unmatched, disagree, disagree_rows, already = [], [], [], [], 0
    for rnd, home, away in rows:
        cands = by_pair.get((team_key(home), team_key(away)), [])
        if len(cands) != 1:
            unmatched.append(f"{home} v {away} ({len(cands)} vault fixtures)")
            continue
        mid, have = cands[0]
        if have is None:
            plan.append((mid, rnd))
        elif str(have) != rnd:
            disagree.append(f"match {mid} {home} v {away}: vault round {have}, FotMob {rnd}")
            disagree_rows.append((mid, have, rnd))
        else:
            already += 1

    print(f"  {len(plan)} fixtures would get a round, {already} already agree, "
          f"{len(disagree)} disagree, {len(unmatched)} unmatched")
    for u in unmatched[:10]:
        print(f"    unmatched: {u}")
    for d in disagree[:10]:
        print(f"    left alone: {d}")
    if unmatched:
        raise SystemExit("some fixtures do not match the vault; nothing written")

    cur.execute("""
        INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
        VALUES ('match',
                (SELECT id FROM data_sources WHERE name='ligikuu'),
                (SELECT id FROM data_sources WHERE name='fotmob'), %s) RETURNING id
    """, (f"Premier League {season}: round numbers, which the official site's export does "
          f"not carry, taken from FotMob's fixture list.",))
    run_id = cur.fetchone()[0]

    for mid, rnd in plan:
        cur.execute("""
            INSERT INTO reconciliation_diffs
              (reconciliation_run_id, entity_id_a, entity_id_b, field_name,
               value_a, value_b, resolution, resolved_value, resolved_at)
            VALUES (%s,%s,NULL,'matches.round','no round',%s,'ACCEPT_B',%s,now())
        """, (run_id, mid, f"round {rnd} (fotmob)", rnd))
        cur.execute("UPDATE matches SET round=%s WHERE id=%s", (rnd, mid))

    # A round the vault already has is kept (principle 2), but the disagreement
    # is recorded rather than left in terminal output -- these are the rows a
    # human needs in order to decide which source numbered the season right.
    for mid, have, rnd in disagree_rows:
        cur.execute("""
            INSERT INTO reconciliation_diffs
              (reconciliation_run_id, entity_id_a, entity_id_b, field_name,
               value_a, value_b, resolution)
            VALUES (%s,%s,NULL,'matches.round',%s,%s,'PENDING')
        """, (run_id, mid, f"round {have} (vault)", f"round {rnd} (fotmob)"))

    cur.execute("""
        SELECT count(*) , count(round), count(DISTINCT round)
          FROM matches m
          JOIN competition_editions ce ON ce.id=m.competition_edition_id
          JOIN seasons s ON s.id=ce.season_id
         WHERE ce.competition_id=1 AND s.label=%s
    """, (season,))
    total, withr, distinct = cur.fetchone()
    print(f"\n{season}: {withr} of {total} fixtures have a round, across {distinct} rounds")

    if commit:
        conn.commit()
        print("\nCOMMITTED")
    else:
        conn.rollback()
        print("\nrolled back (dry run) -- pass --commit to apply")
    conn.close()


if __name__ == "__main__":
    main()
