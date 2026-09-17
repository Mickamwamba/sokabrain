"""Check RSSSF's Tanzanian scorers against the vault before anything loads.

    python3 validate_rsssf_tpl.py raw/rsssf_tpl/canon.json

Nothing here writes. It answers the three questions that decide what is safe to
load, and in what shape.

1. **Does each RSSSF match find exactly one vault match?** Matching is on the
   season plus the ordered pair of clubs, via `teamnames.key`, which already
   knows this league's aliases -- "Young Africans" is "Yanga SC", "Kinondoni MC"
   is "KMC FC". A league season is a double round robin, so an ordered pair
   occurs once and needs no date. The stored score must then agree, or the two
   sources disagree about the result and that match is nobody's to load.

2. **Do the scorers account for the score?** RSSSF's coverage is partial: it
   often names two of three goals. A match whose scorers add up exactly can be
   loaded as it stands. One that falls short can only be loaded by padding the
   difference with events that name nobody -- honest about what is known, and
   the shape the vault already uses for the 2019/20 legacy data, but it does
   create rows no source wrote.

3. **Which vault players do these names resolve to?** Full names, unlike
   Flashscore's abbreviations, so `playermatch.resolve` can attach them to the
   players the vault already holds instead of doubling them.
"""
import json
import sys
from collections import defaultdict

import psycopg2

from playermatch import fold, resolve, words
from teamnames import key as team_key

DSN = "host=127.0.0.1 port=5432 dbname=sokabrain"
COMPETITION_ID = 1


def vault_matches(cur):
    cur.execute("""
        SELECT m.id, s.label, m.home_team_id, ht.name, m.away_team_id, at.name,
               m.home_score, m.away_score,
               (SELECT count(*) FROM match_events e WHERE e.match_id = m.id
                 AND e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL')) AS events,
               (SELECT count(*) FROM match_events e WHERE e.match_id = m.id
                 AND e.type IN ('GOAL','PENALTY_GOAL') AND e.player_id IS NOT NULL) AS named
          FROM matches m
          JOIN competition_editions ce ON ce.id = m.competition_edition_id
          JOIN seasons s ON s.id = ce.season_id
          JOIN teams ht ON ht.id = m.home_team_id JOIN teams at ON at.id = m.away_team_id
         WHERE ce.competition_id = %s AND m.home_score IS NOT NULL
    """, (COMPETITION_ID,))
    keys = ["id", "season", "home_id", "home", "away_id", "away", "hs", "as", "events", "named"]
    return [dict(zip(keys, r)) for r in cur.fetchall()]


def main(path):
    staged = json.load(open(path))
    conn = psycopg2.connect(DSN)
    cur = conn.cursor()
    cur.execute("SET timezone = 'UTC'")
    vault = vault_matches(cur)

    index = defaultdict(list)
    for v in vault:
        index[(v["season"], team_key(v["home"]), team_key(v["away"]))].append(v)

    seasons = defaultdict(lambda: defaultdict(int))
    unmatched_team = defaultdict(int)
    score_conflicts = []
    matched = []

    for m in staged:
        s = seasons[m["season"]]
        s["staged"] += 1
        cands = index.get((m["season"], team_key(m["home"]), team_key(m["away"])), [])
        if len(cands) != 1:
            s["no_vault_match" if not cands else "ambiguous"] += 1
            if not cands:
                # Is it the season, or the club names?
                if not any(v["season"] == m["season"] for v in vault):
                    s["season_absent"] += 1
                else:
                    for side in (m["home"], m["away"]):
                        if not any(team_key(v["home"]) == team_key(side)
                                   or team_key(v["away"]) == team_key(side)
                                   for v in vault if v["season"] == m["season"]):
                            unmatched_team[f'{m["season"]} {side}'] += 1
            continue
        v = cands[0]
        if (v["hs"], v["as"]) != (m["homeScore"], m["awayScore"]):
            s["score_conflict"] += 1
            score_conflicts.append(
                f'{m["season"]} {m["home"]} v {m["away"]}: RSSSF {m["homeScore"]}-{m["awayScore"]}, '
                f'vault {v["hs"]}-{v["as"]} (match {v["id"]})')
            continue
        s["matched"] += 1
        h = sum(1 for g in m["goals"] if g["side"] == "home")
        a = sum(1 for g in m["goals"] if g["side"] == "away")
        total_score = m["homeScore"] + m["awayScore"]
        if not m["goals"]:
            s["no_scorers"] += 1
        elif (h, a) == (m["homeScore"], m["awayScore"]):
            s["exact"] += 1
            s["goals_exact"] += total_score
        elif h <= m["homeScore"] and a <= m["awayScore"]:
            s["partial"] += 1
            s["goals_partial"] += h + a
            s["goals_padding"] += total_score - (h + a)
        else:
            s["over"] += 1
            score_conflicts.append(
                f'{m["season"]} {m["home"]} v {m["away"]}: scorers read {h}-{a} '
                f'for a {m["homeScore"]}-{m["awayScore"]}')
        if v["events"] == 0:
            s["vault_has_no_log"] += 1
        matched.append((m, v))

    hdr = (f"{'season':11} {'staged':>6} {'matched':>7} {'exact':>6} {'partial':>7} {'none':>5} "
           f"{'over':>5} {'conflict':>8} {'unmatched':>9} {'newGoals':>8} {'padding':>7}")
    print(hdr)
    tot = defaultdict(int)
    for season in sorted(seasons):
        s = seasons[season]
        for k, v in s.items():
            tot[k] += v
        newg = s["goals_exact"] + s["goals_partial"]
        print(f"{season:11} {s['staged']:>6} {s['matched']:>7} {s['exact']:>6} {s['partial']:>7} "
              f"{s['no_scorers']:>5} {s['over']:>5} {s['score_conflict']:>8} "
              f"{s['no_vault_match']:>9} {newg:>8} {s['goals_padding']:>7}")
    newg = tot["goals_exact"] + tot["goals_partial"]
    print(f"{'TOTAL':11} {tot['staged']:>6} {tot['matched']:>7} {tot['exact']:>6} {tot['partial']:>7} "
          f"{tot['no_scorers']:>5} {tot['over']:>5} {tot['score_conflict']:>8} "
          f"{tot['no_vault_match']:>9} {newg:>8} {tot['goals_padding']:>7}")
    print(f"\nnamed goals available: {newg} "
          f"({tot['goals_exact']} in matches that account for their score exactly, "
          f"{tot['goals_partial']} in matches that fall short by {tot['goals_padding']})")
    print(f"seasons absent from the vault: {tot['season_absent']} staged matches")

    if unmatched_team:
        print(f"\nclub names that matched nothing in their season ({len(unmatched_team)}):")
        for k, n in sorted(unmatched_team.items())[:25]:
            print(f"    {k}  ({n})")
    if score_conflicts:
        print(f"\nscore or scorer-count conflicts ({len(score_conflicts)}), none loadable:")
        for c in score_conflicts[:20]:
            print(f"    {c}")

    # Player resolution, on the matches that could load.
    cur.execute("""
        SELECT DISTINCT p.id, p.full_name, e.team_id
          FROM match_events e JOIN players p ON p.id = e.player_id
         WHERE e.type IN ('GOAL','PENALTY_GOAL')
    """)
    by_team = defaultdict(list)
    for pid, nm, tid in cur.fetchall():
        by_team[tid].append((pid, nm))

    names, counts = set(), defaultdict(set)
    for m, v in matched:
        for g in m["goals"]:
            if not g["player"]:
                continue
            side = g["side"]
            if g["type"] == "OWN_GOAL":
                side = "away" if side == "home" else "home"
            tid = v["home_id"] if side == "home" else v["away_id"]
            names.add((tid, g["player"]))
            if words(g["player"]):
                counts[(tid, words(g["player"])[-1])].add(fold(g["player"]))

    buckets = defaultdict(int)
    for tid, nm in names:
        per = {sn: len(v) for (t, sn), v in counts.items() if t == tid}
        how, _pid = resolve(nm, by_team.get(tid, []), per)
        buckets[how] += 1
    print(f"\ndistinct scorer/club pairs: {len(names)}")
    for how in sorted(buckets):
        print(f"  {how:10} {buckets[how]}")
    conn.close()


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    main(sys.argv[1])
