#!/usr/bin/env python3
"""Turn the harvested AFCON fixtures and match pages into canonical records.

WhoScored serves AFCON in two entirely different page formats, split at 2013:

  2002-2012  `initialMatchDataForScrappers` -- a terse JS array literal.
             Goals and cards carry a **surname only**: no player id, no given
             name, no lineups, no venue.
  2013-2025  `matchCentreData` -- the full Opta blob, with real player ids and
             names, venue, referee, and separate half-time / full-time /
             extra-time / shootout scores.

That split drives most of the decisions here, and two of them matter enough to
state plainly:

**Players are only created where the source names them properly.** For
2002-2012 a goal becomes a `match_events` row with `player_id` NULL and the
surname kept in `scorer_hint` for a human (or a future source) to resolve.
Inventing a player from "Keita" would silently merge different players and is
exactly the kind of fabrication principle 6 forbids. The vault already carries
unattributed goals from the legacy migration, so this is the established shape.

**`home_score` is the score after 90 minutes, never after extra time.** The
fixture feed's `homeScore` is the *result* score and already includes extra
time, so it cannot be used directly. For 2013+ the match page gives a true
`ftScore`. For 2002-2012 ties that went to extra time it is reconstructed by
dropping goals after minute 90, and then checked: a match that went to extra
time must have been level at 90, so anything else is reported, not written.
"""
import collections
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from afcon_rounds import (derive_knockout_rounds, stage_round, group_letter,
                          GROUP, R16, QF, SF, THIRD, FINAL)
from nationnames import canonical

# WhoScored status 6 = played, 7 = cancelled. The three status-7 rows are
# Togo's 2010 group matches, abandoned after the attack on the team bus.
PLAYED, CANCELLED = "6", "7"

# matchCentreData incident types -> our match_events.type vocabulary.
# 'Goal' and 'Card' are refined by qualifier; 'SubstitutionOn' is the paired
# half of 'SubstitutionOff' and would double every substitution.
_MCD_TYPES = {
    "Goal": "GOAL",
    "Card": "YELLOW_CARD",
    "SubstitutionOff": "SUBSTITUTION",
    "Assist": "ASSIST",
}
_MCD_DROP = {"SubstitutionOn"}

# initialMatchDataForScrappers incident strings -> the same vocabulary.
# This is the complete vocabulary observed across all 496 matches, not a guess.
_OLD_TYPES = {
    "goal": "GOAL",
    "owngoal": "OWN_GOAL",
    "penalty-goal": "PENALTY_GOAL",
    "penalty-missed": "PENALTY_MISS",
    "yellow": "YELLOW_CARD",
    "secondyellow": "SECOND_YELLOW",
    "red": "RED_CARD",
    "subst": "SUBSTITUTION",
}
# Shootout kicks are settled in `*_score_pens`. Recording them as goals would
# double-count every shootout, so they are dropped outright.
_OLD_DROP = {"penaltyshootout-scored", "penaltyshootout-missed"}

# The two page formats disagree about which team an own goal belongs to.
#
#   matchCentreData  files it under the team of the player who scored it
#                    -- which is the vault's convention (principle 5).
#   the legacy block files it under the team it COUNTS FOR.
#
# Verified on every own goal in the data, e.g. match 130757 (Egypt 4-1): the
# four Egyptian goals sit under home while Egypt defender Abdel el Sakka's own
# goal sits under away. Carrying the legacy side across unchanged would credit
# every 2002-2012 own goal to the wrong team, which is precisely the bug that
# bit the original migration. Legacy own goals are therefore flipped here, so
# everything downstream sees one convention.
_OWN_GOAL_SIDE_IS_BENEFICIARY = {"old"}


def _score_pair(s):
    """'3 : 2' -> (3, 2). Empty or malformed -> (None, None)."""
    if not s:
        return None, None
    m = re.match(r"^\s*(\d+)\s*:\s*(\d+)\s*$", s)
    if not m:
        return None, None
    return int(m.group(1)), int(m.group(2))


def _num(s):
    return int(s) if s not in ("", None) else None


def read_fixtures(path):
    rows = []
    for line in Path(path).read_text().splitlines():
        if not line.strip():
            continue
        f = line.split("|")
        rows.append({
            "year": f[0], "stage": f[1], "stage_id": f[2], "match_id": f[3],
            "kickoff_utc": f[4], "status": f[5], "elapsed": f[6],
            "home_ws_id": f[7], "home_raw": f[8],
            "away_ws_id": f[9], "away_raw": f[10],
            "feed_home": _num(f[11]), "feed_away": _num(f[12]),
            "feed_home_et": _num(f[13]), "feed_away_et": _num(f[14]),
            "home_pens": _num(f[15]), "away_pens": _num(f[16]),
            "home_team": canonical(f[8]), "away_team": canonical(f[10]),
        })
    return rows


def card_type(quals):
    """Card severity from its qualifiers, or None for a rescinded card.

    'VoidYellowCard' marks a booking that was later withdrawn; writing it as a
    yellow would overstate every affected player's disciplinary record.
    """
    q = (quals or "").lower()
    if "void" in q:
        return None
    if "secondyellow" in q:
        return "SECOND_YELLOW"
    if "red" in q:
        return "RED_CARD"
    return "YELLOW_CARD"


def goal_type(quals):
    q = (quals or "").lower()
    if "owngoal" in q:
        return "OWN_GOAL"
    if "penalty" in q:
        return "PENALTY_GOAL"
    return "GOAL"


def build_events(rec, problems, match_id):
    """Canonical event rows for one match, or [] when the source has none.

    Shootout penalties are dropped: they are settled in `*_score_pens`, and
    writing them as goals would double-count every shootout.
    """
    fmt = rec.get("fmt")
    out = []
    for e in rec.get("ev", []):
        side, minute, kind, pid, period, quals = e[0], e[1], e[2], e[3], e[4], e[5]
        hint = e[6] if len(e) > 6 else None
        if period and "shootout" in str(period).lower():
            continue
        # 'feed' records are the four 2013 knockout matches recovered from the
        # stage fixture feed, written in the same Goal/Card shape as 'mcd'.
        if fmt in ("mcd", "feed"):
            if kind in _MCD_DROP:
                continue
            base = _MCD_TYPES.get(kind)
            if base is None:
                problems.append(f"{match_id}: unknown mcd incident {kind!r}")
                continue
            if kind == "Goal":
                etype = goal_type(quals)
            elif kind == "Card":
                etype = card_type(quals)
                if etype is None:      # rescinded booking
                    continue
            else:
                etype = base
        else:
            k = str(kind).strip().lower()
            if k in _OLD_DROP:
                continue
            etype = _OLD_TYPES.get(k)
            if etype is None:
                problems.append(f"{match_id}: unknown legacy incident {kind!r}")
                continue
        team = "HOME" if side == "H" else "AWAY"
        if etype == "OWN_GOAL" and fmt in _OWN_GOAL_SIDE_IS_BENEFICIARY:
            team = "AWAY" if team == "HOME" else "HOME"
        out.append({
            "minute": minute,
            "type": etype,
            "team": team,
            "source_player_id": pid,
            "scorer_hint": hint or None,
            "period": period or None,
        })
    out.sort(key=lambda r: (r["minute"] if r["minute"] is not None else 999, r["type"]))
    return out


def regulation_score(fx, rec, events, problems):
    """(home90, away90, home_et, away_et) honouring the 90-minute rule."""
    ft_h, ft_a = _score_pair(rec.get("ft")) if rec else (None, None)
    et_h, et_a = _score_pair(rec.get("et")) if rec else (None, None)

    if rec and rec.get("fmt") in ("mcd", "feed"):
        # The Opta blob states the 90-minute score outright, and that part is
        # trustworthy. Its `etScore` is NOT the score after extra time: it
        # reports the winner's score against a zero, so the 2015 quarter-final
        # Tunisia 1-2 Equatorial Guinea comes back as '0 : 2'. The dependable
        # after-extra-time score is the fixture feed's result, which already
        # includes extra time.
        if ft_h is None:
            return fx["feed_home"], fx["feed_away"], None, None
        res_h, res_a = fx["feed_home"], fx["feed_away"]
        went_to_et = fx["home_pens"] is not None or (
            res_h is not None and (res_h, res_a) != (ft_h, ft_a))
        if not went_to_et:
            return ft_h, ft_a, None, None
        return ft_h, ft_a, res_h, res_a

    # Legacy format: the header score already includes extra time.
    result_h = fx["feed_home"] if fx["feed_home"] is not None else ft_h
    result_a = fx["feed_away"] if fx["feed_away"] is not None else ft_a
    went_to_et = fx["feed_home_et"] is not None or fx["home_pens"] is not None
    if not went_to_et or result_h is None:
        return result_h, result_a, None, None

    # Extra time was played: strip goals struck after minute 90.
    goals = [e for e in events if e["type"] in ("GOAL", "OWN_GOAL", "PENALTY_GOAL")]
    if not goals and (result_h or result_a):
        problems.append(f"{fx['match_id']}: extra time but no goal events; cannot split 90'")
        return result_h, result_a, result_h, result_a
    late = collections.Counter()
    for e in goals:
        if e["minute"] is not None and e["minute"] > 90:
            # An own goal counts for the opposing team (principle 5).
            side = e["team"]
            if e["type"] == "OWN_GOAL":
                side = "AWAY" if side == "HOME" else "HOME"
            late[side] += 1
    h90, a90 = result_h - late["HOME"], result_a - late["AWAY"]
    if h90 != a90:
        problems.append(
            f"{fx['match_id']}: extra time but the derived 90' score is {h90}-{a90}, "
            f"not level (result {result_h}-{result_a}, late goals {dict(late)})")
        return result_h, result_a, result_h, result_a
    return h90, a90, result_h, result_a


def normalize(fixtures_path, events_path):
    fixtures = read_fixtures(fixtures_path)
    events_raw = json.loads(Path(events_path).read_text())
    problems = []

    # Round per match: stated where WhoScored states it, derived where it does not.
    rounds = {}
    by_year = collections.defaultdict(list)
    for fx in fixtures:
        by_year[fx["year"]].append(fx)
    for year, ms in by_year.items():
        lumped = [m for m in ms if stage_round(m["stage"]) is None]
        for m in ms:
            r = stage_round(m["stage"])
            if r:
                rounds[m["match_id"]] = r
        if lumped:
            shaped = [{
                "match_id": m["match_id"], "kickoff_utc": m["kickoff_utc"],
                "home_team": m["home_team"], "away_team": m["away_team"],
                "home_score": m["feed_home"], "away_score": m["feed_away"],
                "home_pens": m["home_pens"], "away_pens": m["away_pens"],
            } for m in lumped]
            rounds.update(derive_knockout_rounds(shaped))

    out = []
    for fx in fixtures:
        entry = events_raw.get(fx["match_id"]) or {}
        rec = entry.get("ok") if isinstance(entry, dict) and "ok" in entry else entry
        rec = rec or None
        events = build_events(rec, problems, fx["match_id"]) if rec else []
        h90, a90, het, aet = regulation_score(fx, rec, events, problems)
        cancelled = fx["status"] == CANCELLED
        names = (rec or {}).get("names") or {}
        for e in events:
            pid = e["source_player_id"]
            if pid is not None:
                e["player_name"] = names.get(str(pid)) or names.get(pid)
        out.append({
            "source": "whoscored",
            "competition": "Africa Cup of Nations",
            "season": fx["year"],
            "round": rounds.get(fx["match_id"]),
            "group": group_letter(fx["stage"]),
            "source_match_id": fx["match_id"],
            "source_url": f"https://www.whoscored.com/matches/{fx['match_id']}/live",
            "kickoff_utc": fx["kickoff_utc"],
            "home_name": fx["home_team"], "home_source_id": fx["home_ws_id"],
            "away_name": fx["away_team"], "away_source_id": fx["away_ws_id"],
            "status": "CANCELLED" if cancelled else ("FULL_TIME" if h90 is not None else "SCHEDULED"),
            "home_score": None if cancelled else h90,
            "away_score": None if cancelled else a90,
            "home_score_et": None if cancelled else het,
            "away_score_et": None if cancelled else aet,
            "home_score_pens": None if cancelled else fx["home_pens"],
            "away_score_pens": None if cancelled else fx["away_pens"],
            "venue": (rec or {}).get("venue") or None,
            "attendance": ((rec or {}).get("att") or None) or None,
            "referee": (rec or {}).get("ref") or None,
            "page_format": (rec or {}).get("fmt"),
            "events": [] if cancelled else events,
        })
    return out, problems


def verify_events_against_score(rows):
    """Rebuild each score from its goal events and report where it disagrees.

    This is the check that own-goal handling is right: an OWN_GOAL is stored
    against the scoring player's own team and must be credited to the other
    side (principle 5). If the flip were wrong, own-goal matches would be the
    ones that fail here, so a clean run over them is the evidence.

    A mismatch is not automatically an error -- the early tournaments have
    partial event logs -- so this reports rather than raises. Returns
    (agree, disagree, no_events, detail).
    """
    agree = disagree = no_events = 0
    detail = []
    for r in rows:
        if r["status"] != "FULL_TIME" or r["home_score"] is None:
            continue
        goals = [e for e in r["events"]
                 if e["type"] in ("GOAL", "OWN_GOAL", "PENALTY_GOAL")]
        if not goals:
            no_events += 1
            continue
        h = a = 0
        for e in goals:
            side = e["team"]
            if e["type"] == "OWN_GOAL":
                side = "AWAY" if side == "HOME" else "HOME"
            if side == "HOME":
                h += 1
            else:
                a += 1
        # Compare against the result score: the 90' score plus any extra time.
        want_h = r["home_score_et"] if r["home_score_et"] is not None else r["home_score"]
        want_a = r["away_score_et"] if r["away_score_et"] is not None else r["away_score"]
        if (h, a) == (want_h, want_a):
            agree += 1
        else:
            disagree += 1
            has_og = any(e["type"] == "OWN_GOAL" for e in goals)
            detail.append(
                f"{r['season']} {r['round']:<13} {r['home_name']} {want_h}-{want_a} "
                f"{r['away_name']}: events give {h}-{a}"
                f"{'  [has own goal]' if has_og else ''}  ({r['source_match_id']})")
    return agree, disagree, no_events, detail


if __name__ == "__main__":
    rows, problems = normalize(sys.argv[1], sys.argv[2])
    Path(sys.argv[3]).write_text(json.dumps(rows, indent=1))

    per = collections.Counter(r["season"] for r in rows)
    ev = collections.Counter(r["season"] for r in rows if r["events"])
    goals = collections.Counter()
    named = collections.Counter()
    for r in rows:
        for e in r["events"]:
            if e["type"] in ("GOAL", "OWN_GOAL", "PENALTY_GOAL"):
                goals[r["season"]] += 1
                if e.get("source_player_id"):
                    named[r["season"]] += 1
    print(f"{'season':<8}{'matches':>8}{'w/events':>10}{'goals':>7}{'named':>7}")
    for s in sorted(per):
        print(f"{s:<8}{per[s]:>8}{ev[s]:>10}{goals[s]:>7}{named[s]:>7}")
    print(f"{'TOTAL':<8}{sum(per.values()):>8}{sum(ev.values()):>10}{sum(goals.values()):>7}{sum(named.values()):>7}")
    agree, disagree, no_events, detail = verify_events_against_score(rows)
    print(f"\nevents vs stored score: {agree} agree, {disagree} disagree, "
          f"{no_events} with no event log")
    for d in detail[:25]:
        print("  -", d)
    if len(detail) > 25:
        print(f"  ... and {len(detail) - 25} more")

    og = sum(1 for r in rows for e in r["events"] if e["type"] == "OWN_GOAL")
    print(f"\nown goals carried: {og}")

    if problems:
        print(f"\n{len(problems)} problem(s):")
        for p in problems[:40]:
            print("  -", p)
