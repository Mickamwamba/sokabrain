#!/usr/bin/env python3
"""Turn the official league site's SportsPress export into canonical match records.

Input is whatever `fetch_ligikuu.py` wrote: events.json, teams.json,
players.json, venues.json, leagues.json. Output is one JSON file of canonical
records, the same shape `normalize_whoscored.py` produces, so the two sources
can be compared and loaded by the same code.

The season a match belongs to is taken from its **league**, never from its
`seasons` taxonomy: several leagues on the site are tagged with the wrong
season (NBC PREMIER LEAGUE 2022/23's events are tagged 2023/24).
"""
import json
import re
import sys
from pathlib import Path

# The top-flight leagues, and the season each one actually is. Lower divisions
# and play-off mini-leagues are deliberately excluded.
TOP_FLIGHT = {
    20:  "2020/2021",   # "VODACOM PREMIER LEAGUE"
    91:  "2021/2022",   # "LIGI KUU 2021/22"
    134: "2022/2023",
    236: "2023/2024",
    287: "2024/2025",
    418: "2025/2026",
    432: "2026/2027",
}

# SportsPress ships with demo content; league 20 still contains some of it.
DEMO_TEAMS = {"Kangaroos", "Bluebirds", "Rovers", "Wanderers", "Eagles", "Strikers"}

GOAL_RE = re.compile(r"(\d+)\s*(?:\(([^)]*)\))?")
MINUTE_RE = re.compile(r"(\d+)(?:\+(\d+))?")


def parse_goals(value):
    """`"2 (45+3', 61')"` -> (2, [(45, 3), (61, None)]).

    The count is authoritative; minutes are a bonus the site does not always
    record, so a goal with no minute is still a goal.
    """
    v = str(value or "").strip()
    if not v or v == "0":
        return 0, []
    m = GOAL_RE.match(v)
    if not m:
        return 0, []
    count = int(m.group(1))
    minutes = []
    if m.group(2):
        for mm in MINUTE_RE.finditer(m.group(2)):
            minutes.append((int(mm.group(1)), int(mm.group(2)) if mm.group(2) else None))
    return count, minutes


def count_only(value):
    v = str(value or "").strip()
    m = re.match(r"^(\d+)", v)
    return int(m.group(1)) if m else 0


def orient_own_goals(events, home_score, away_score):
    """Put each own goal under the scoring player's OWN team, as the vault needs.

    The site is not consistent about it. Until early 2026 its editors listed an
    own-goal scorer in the table of the team the goal COUNTS FOR; from April 2026
    (and in two matches in late 2024) under the scorer's own team. There is no
    field that says which, so the stored score decides: if the goal events only
    reproduce the score with the own goals flipped to the other side, they are
    flipped. Both readings agreeing, or neither (an incomplete log), leaves the
    events as listed -- there is nothing to decide on.

    Found by the data audit on TPL 2023/24-2025/26: 19 matches read the wrong
    result, e.g. TRA United 3-0 KMC FC read 2-1. Corrected in the vault by
    docs/reconciliation/fixes/2026-09-12_ligikuu_own_goal_sides.sql.

    >>> ev = [{"type": "GOAL", "side": "home"}, {"type": "GOAL", "side": "home"},
    ...       {"type": "OWN_GOAL", "side": "home"}]
    >>> [e["side"] for e in orient_own_goals(ev, 3, 0)]
    ['home', 'home', 'away']
    >>> [e["side"] for e in orient_own_goals([{"type": "OWN_GOAL", "side": "away"}], 1, 0)]
    ['away']
    >>> [e["side"] for e in orient_own_goals([{"type": "GOAL", "side": "home"}], 2, 0)]
    ['home']
    """
    goals = [e for e in events if e["type"] in ("GOAL", "PENALTY_GOAL", "OWN_GOAL")]
    own = [e for e in goals if e["type"] == "OWN_GOAL"]
    if not own or len(goals) != home_score + away_score:
        return events

    def home_tally(flip):
        n = 0
        for e in goals:
            side = e["side"]
            if e["type"] == "OWN_GOAL":
                # As stored in the vault, an own goal counts for the other side;
                # "flip" first moves it to the other team's table.
                side = {"home": "away", "away": "home"}[side] if flip else side
                side = {"home": "away", "away": "home"}[side]
            n += side == "home"
        return n

    as_listed, flipped = home_tally(False) == home_score, home_tally(True) == home_score
    if flipped and not as_listed:
        other = {"home": "away", "away": "home"}
        return [dict(e, side=other[e["side"]]) if e["type"] == "OWN_GOAL" else e for e in events]
    return events


def load(src):
    src = Path(src)
    data = {}
    for name in ("events", "teams", "players", "venues", "leagues"):
        data[name] = json.loads((src / f"{name}.json").read_text())
    return data


def title_of(row):
    return (row.get("title") or {}).get("rendered", "").strip()


def normalize(src):
    d = load(src)
    teams = {t["id"]: title_of(t) for t in d["teams"]}
    players = {p["id"]: title_of(p) for p in d["players"]}
    venues = {v["id"]: title_of(v) for v in d["venues"]}

    out = []
    for e in d["events"]:
        league = e.get("_league")
        if league not in TOP_FLIGHT:
            continue

        sides = [t for t in (e.get("teams") or []) if t]
        if len(sides) != 2:
            continue
        home_id, away_id = sides[0], sides[1]

        # A handful of teams were deleted from the site but are still referenced
        # by their events. The event title is "Home vs Away", so the name
        # survives even where the team record does not.
        title = title_of(e)
        halves = re.split(r"\s+vs\.?\s+", title, maxsplit=1, flags=re.I)
        home_name = teams.get(home_id) or (halves[0].strip() if len(halves) == 2 else None)
        away_name = teams.get(away_id) or (halves[1].strip() if len(halves) == 2 else None)
        if not home_name or not away_name:
            continue
        if home_name in DEMO_TEAMS or away_name in DEMO_TEAMS:
            continue

        res = e.get("main_results") or []
        hs = str(res[0]).strip() if len(res) > 0 else ""
        as_ = str(res[1]).strip() if len(res) > 1 else ""
        played = hs.isdigit() and as_.isdigit()

        # A few events carry a corrupt year ("0025-02-06"). The date is unusable
        # but the match itself is real, so it is kept with no kickoff.
        kickoff = e.get("date_gmt")
        if not kickoff or not re.match(r"^(19|20)\d\d-", kickoff):
            kickoff = None

        events, lineups = [], []
        perf = e.get("performance")
        if isinstance(perf, dict):
            for tid, squad in perf.items():
                if not str(tid).isdigit() or int(tid) == 0 or not isinstance(squad, dict):
                    continue
                tid = int(tid)
                side = "home" if tid == home_id else "away" if tid == away_id else None
                if side is None:
                    continue
                for pid, stat in squad.items():
                    if not str(pid).isdigit() or int(pid) == 0 or not isinstance(stat, dict):
                        continue
                    pid = int(pid)
                    # 47 player records were deleted from the site while their
                    # appearances survived. The event is still real, so it is
                    # kept with no player rather than dropped -- the vault
                    # allows an unattributed event, and dropping it would make
                    # the event log disagree with the score.
                    name = players.get(pid)
                    status = stat.get("status")
                    if status in ("lineup", "sub") and name:
                        lineups.append({
                            "side": side, "player_source_id": pid, "player_name": name,
                            "shirt_number": (stat.get("number") or None),
                            "role": "STARTER" if status == "lineup" else "SUB",
                        })
                    n, minutes = parse_goals(stat.get("goals"))
                    for i in range(n):
                        minute, added = minutes[i] if i < len(minutes) else (None, None)
                        events.append({"type": "GOAL", "side": side, "player_source_id": pid,
                                       "player_name": name, "minute": minute, "added_time": added})
                    # An own goal is listed under whichever team's table the
                    # site's editor put the scorer in -- which changed over time.
                    # orient_own_goals() below settles each match on the score.
                    for _ in range(count_only(stat.get("owngoals"))):
                        events.append({"type": "OWN_GOAL", "side": side, "player_source_id": pid,
                                       "player_name": name, "minute": None, "added_time": None})
                    # A bare count, with no minute and no indication of which
                    # goal it created, so it becomes a standalone ASSIST row
                    # rather than a related_player_id on some guessed goal.
                    for _ in range(count_only(stat.get("assists"))):
                        events.append({"type": "ASSIST", "side": side, "player_source_id": pid,
                                       "player_name": name, "minute": None, "added_time": None})
                    for _ in range(count_only(stat.get("yellowcards"))):
                        events.append({"type": "YELLOW_CARD", "side": side, "player_source_id": pid,
                                       "player_name": name, "minute": None, "added_time": None})
                    for _ in range(count_only(stat.get("redcards"))):
                        events.append({"type": "RED_CARD", "side": side, "player_source_id": pid,
                                       "player_name": name, "minute": None, "added_time": None})

        if played:
            events = orient_own_goals(events, int(hs), int(as_))

        out.append({
            "source": "ligikuu",
            "season": TOP_FLIGHT[league],
            "source_match_id": str(e["id"]),
            "source_url": e.get("link"),
            "kickoff_utc": kickoff,
            "home_source_id": home_id, "home_name": home_name,
            "away_source_id": away_id, "away_name": away_name,
            "home_score": int(hs) if played else None,
            "away_score": int(as_) if played else None,
            "status": "FULL_TIME" if played else "SCHEDULED",
            "venue": venues.get((e.get("venues") or [None])[0]),
            "lineups": lineups,
            "events": events,
        })
    return out


if __name__ == "__main__":
    src, dst = sys.argv[1], sys.argv[2]
    rows = normalize(src)
    Path(dst).write_text(json.dumps(rows, indent=1))
    import collections
    per = collections.Counter(r["season"] for r in rows)
    scored = collections.Counter(r["season"] for r in rows if r["home_score"] is not None)
    goals = collections.Counter()
    for r in rows:
        goals[r["season"]] += sum(1 for x in r["events"] if x["type"] in ("GOAL", "OWN_GOAL"))
    print(f"{'season':<12}{'matches':>8}{'scored':>8}{'goal events':>13}")
    for s in sorted(per):
        print(f"{s:<12}{per[s]:>8}{scored[s]:>8}{goals[s]:>13}")
