"""Check the staged Wikipedia scorers against the vault before anything loads.

    python3 validate_wikipedia_afcon.py raw/afcon_wikipedia/canon.json

Nothing here writes. It answers the questions that decide whether this source
can be trusted for these two tournaments:

1. Does every staged match find exactly one match already in the vault? Matching
   is on the unordered pair of teams plus a date within a day, because the two
   sources do not always agree which side was "home" -- RSSSF has
   "Guinea 2-2 Madagascar" where Wikipedia has Madagascar at home. A fixture
   that matches two vault rows, or none, is reported and must not load.

2. Where the sides are reversed, does the score still agree once flipped? If it
   does, the disagreement is presentational and the goals can be mapped onto the
   vault's own orientation. If it does not, the two sources disagree about the
   result, which is a reconciliation question and not something to overwrite
   (design principle 2).

3. Does each match's goal list add up to its score, with own goals credited to
   the side they count for? This is the same arithmetic the loader and the audit
   use, and it is the gate: a match that fails it loads no scorers.

4. Which vault players do these names resolve to, and how many new players would
   be created? This is the question that matters most, having just merged 45
   duplicate records: a full name from Wikipedia should attach to the surname
   the vault already holds, not sit beside it as a second person.
"""
import json
import re
import sys
import unicodedata
from collections import defaultdict
from datetime import datetime, timedelta

import psycopg2

from playermatch import fold, resolve, words

DSN = "host=127.0.0.1 port=5432 dbname=sokabrain"
COMPETITION_ID = 16


def load_vault(cur, years):
    cur.execute("""
        SELECT m.id, s.label, m.kickoff_at::date, m.home_team_id, ht.name, m.away_team_id, at.name,
               m.home_score, m.away_score,
               (SELECT count(*) FROM match_events e WHERE e.match_id = m.id
                 AND e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL')) AS goal_events
          FROM matches m
          JOIN competition_editions ce ON ce.id = m.competition_edition_id
          JOIN seasons s ON s.id = ce.season_id
          JOIN teams ht ON ht.id = m.home_team_id
          JOIN teams at ON at.id = m.away_team_id
         WHERE ce.competition_id = %s AND s.label = ANY(%s)
    """, (COMPETITION_ID, [str(y) for y in years]))
    return [dict(zip(
        ["id", "season", "date", "home_id", "home", "away_id", "away", "hs", "as", "events"], r))
        for r in cur.fetchall()]


def pair(a, b):
    return tuple(sorted([a, b]))


def resolve_players(cur, staged):
    """How each staged name would resolve against players already in the vault.

    Only players who already have a goal event for that same national team are
    candidates, so a Ghanaian "Ayew" can never absorb a Senegalese one. The
    rules live in playermatch.py, with their reasoning and doctests.
    """
    cur.execute("""
        SELECT DISTINCT p.id, p.full_name, e.team_id
          FROM match_events e JOIN players p ON p.id = e.player_id
          JOIN teams t ON t.id = e.team_id
         WHERE t.type = 'NATIONAL' AND e.type IN ('GOAL','PENALTY_GOAL')
    """)
    by_team = defaultdict(list)
    for pid, name, team_id in cur.fetchall():
        by_team[team_id].append((pid, name))

    # How many DIFFERENT incoming players share a surname within one team. Two
    # of them must never both claim the vault's single bare-surname record.
    counts = defaultdict(set)
    for team_id, _team, name in staged:
        if words(name):
            counts[(team_id, words(name)[-1])].add(fold(name))

    decisions = {}
    for (team_id, team_name, name) in sorted(staged):
        per_team = {sn: len(v) for (tid, sn), v in counts.items() if tid == team_id}
        decisions[(team_id, name)] = resolve(name, by_team.get(team_id, []), per_team)

    # Nothing may resolve two incoming players onto one vault record.
    claimed = defaultdict(list)
    for (team_id, name), (how, pid) in decisions.items():
        if pid is not None:
            claimed[pid].append(name)
    for pid, who in claimed.items():
        if len(who) > 1:
            for name in who:
                for (team_id, n) in list(decisions):
                    if n == name:
                        decisions[(team_id, n)] = ("COLLISION", pid)
    return decisions


def main(path):
    staged = json.load(open(path))
    years = sorted({m["year"] for m in staged})
    conn = psycopg2.connect(DSN)
    cur = conn.cursor()
    cur.execute("SET timezone = 'UTC'")
    vault = load_vault(cur, years)

    by_pair = defaultdict(list)
    for v in vault:
        by_pair[pair(v["home"], v["away"])].append(v)

    problems, flipped, matched, unmatched = [], [], {}, []
    for m in staged:
        want_date = datetime.strptime(m["date"], "%d %B %Y").date()
        cands = [v for v in by_pair.get(pair(m["home"], m["away"]), [])
                 if abs((v["date"] - want_date).days) <= 1]
        label = f"{m['year']} {m['date']} {m['home']} {m['homeScore']}-{m['awayScore']} {m['away']}"
        if len(cands) != 1:
            (unmatched if not cands else problems).append(
                f"{label}: {len(cands)} vault matches" if cands else f"{label}: no vault match")
            continue
        v = cands[0]
        same_way = v["home"] == m["home"]
        want = (m["homeScore"], m["awayScore"]) if same_way else (m["awayScore"], m["homeScore"])
        if (v["hs"], v["as"]) != want:
            problems.append(
                f"{label}: vault has {v['home']} {v['hs']}-{v['as']} {v['away']} (match {v['id']})")
            continue
        if not same_way:
            flipped.append(f"{label} -> vault {v['home']} v {v['away']} (match {v['id']})")
        matched[m["date"], m["home"], m["away"]] = (v, same_way)

        h = sum(1 for g in m["goals"] if g["side"] == "home")
        a = sum(1 for g in m["goals"] if g["side"] == "away")
        if (h, a) != (m["homeScore"], m["awayScore"]):
            problems.append(f"{label}: goal list reads {h}-{a}")

    print(f"staged:           {len(staged)} matches, {sum(len(m['goals']) for m in staged)} goals")
    print(f"vault, {years}:   {len(vault)} matches, {sum(v['events'] for v in vault)} goal events")
    print(f"matched to vault: {len(matched)}")
    print(f"sides reversed:   {len(flipped)} (score agrees once flipped)")
    for f in flipped:
        print(f"    {f}")
    if unmatched:
        print(f"\nNO VAULT MATCH ({len(unmatched)}):")
        for u in unmatched:
            print(f"    {u}")
    if problems:
        print(f"\nPROBLEMS ({len(problems)}):")
        for p in problems:
            print(f"    {p}")

    # Player resolution, the part that decides whether this creates duplicates.
    cur.execute("SELECT id, name FROM teams WHERE type = 'NATIONAL'")
    team_ids = {name: tid for tid, name in cur.fetchall()}
    names = set()
    for m in staged:
        for g in m["goals"]:
            # An own goal is credited to the other side, so the scorer belongs
            # to the team that did NOT get the goal.
            side = g["side"]
            if g["type"] == "OWN_GOAL":
                side = "away" if side == "home" else "home"
            team = m[side]
            names.add((team_ids[team], team, g["player"]))
    decisions = resolve_players(cur, names)

    buckets = defaultdict(list)
    for (team_id, name), (how, who) in decisions.items():
        buckets[how].append((name, who))
    print(f"\nplayers referenced: {len(decisions)}")
    for how in ("exact", "forename", "initial", "surname", "COLLISION", "new"):
        rows = buckets.get(how, [])
        print(f"  {how:10} {len(rows)}")
        if how != "new":
            for name, who in sorted(rows):
                print(f"      {name}  ->  player {who}")
    collisions = len(buckets.get("COLLISION", []))
    print(f"\n{'FAILED' if problems or unmatched or collisions else 'OK'}: "
          f"{len(problems) + len(unmatched) + collisions} problems")
    conn.close()
    return 1 if problems or unmatched or collisions else 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    sys.exit(main(sys.argv[1]))
