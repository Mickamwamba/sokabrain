#!/usr/bin/env python3
"""Compare the earlier SokaFC MySQL snapshots against the one that was migrated.

The migration read a single dump, `sokafc_02_APRIL_2020.sql`. Four earlier
snapshots of the same production database exist alongside it (July, August,
November and December 2018). If production ever lost a row -- a deleted event, a
goalscorer overwritten to NULL -- an earlier snapshot would still hold it, and
the vault could recover it without an external source.

This script answers that question. It parses each dump directly (no MySQL
server needed) and diffs matches, events, event-to-player links and lineups
against the April 2020 baseline, keyed on primary key, which is stable across
all five snapshots.

Usage:
    python3 compare_legacy_snapshots.py /path/to/SokaDatabase
"""
import re
import sys
from pathlib import Path

# Oldest to newest. The last is the dump the migration actually read.
SNAPSHOTS = [
    ("jul2018", "sokafc 2017:2018.sql"),
    ("aug2018", "sokafc-Aug 2018.sql"),
    ("nov2018", "sokafc - Nov18 2018.sql"),
    ("dec2018", "sokafc - Dec 2018.sql"),
    ("apr2020", "sokafc_02_APRIL_2020.sql"),
]

GOAL_EVENT_IDS = {"10", "11", "12"}  # GOAL, OWN GOAL, PENALT GOAL


def columns_of(sql_text, table):
    m = re.search(r"CREATE TABLE `%s` \((.*?)\n\) ENGINE" % re.escape(table), sql_text, re.S)
    if not m:
        return None
    return [c.group(1) for c in
            (re.match(r"`([^`]+)`\s", line.strip()) for line in m.group(1).split("\n")) if c]


def parse_tuples(body):
    """Yield one list of values per `(...)` group in a mysqldump VALUES body.

    Written as a scanner rather than a regex because the data contains commas,
    parentheses and escaped quotes inside quoted strings.
    """
    i, n = 0, len(body)
    while i < n:
        while i < n and body[i] != "(":
            i += 1
        if i >= n:
            return
        i += 1
        vals, cur, in_str = [], [], False
        while i < n:
            c = body[i]
            if in_str:
                if c == "\\":
                    cur.append({"n": "\n", "t": "\t", "r": "\r", "0": "\0"}.get(body[i + 1], body[i + 1]))
                    i += 2
                    continue
                if c == "'":
                    in_str = False
                    i += 1
                    continue
                cur.append(c)
                i += 1
                continue
            if c == "'":
                in_str = True
                cur.append("\x00")
                i += 1
                continue
            if c in ",)":
                vals.append("".join(cur).strip())
                cur = []
                i += 1
                if c == ")":
                    break
                continue
            cur.append(c)
            i += 1
        yield [None if v == "NULL" else (v[1:] if v.startswith("\x00") else v) for v in vals]


def table(sql_text, name):
    """Every row of `name` as a dict, or None if the dump has no such table."""
    cols = columns_of(sql_text, name)
    if cols is None:
        return None
    rows = []
    for m in re.finditer(r"INSERT INTO `%s` \([^)]*\) VALUES\s*(.*?);\n" % re.escape(name), sql_text, re.S):
        rows.extend(dict(zip(cols, v)) for v in parse_tuples(m.group(1)) if len(v) == len(cols))
    return rows


def read(path):
    sql_text = Path(path).read_text(encoding="utf8", errors="replace")
    snap = {t: table(sql_text, t) or []
            for t in ("matches", "match_events", "match_player_events", "match_lineups")}
    snap["events_by_id"] = {r["id"]: r for r in snap["match_events"]}
    snap["player_of_event"] = {r["match_event_id"]: r["player_id"] for r in snap["match_player_events"]}
    snap["matches_by_id"] = {r["id"]: r for r in snap["matches"]}
    snap["lineup_ids"] = {r["id"] for r in snap["match_lineups"]}
    return snap


def main(root):
    loaded = []
    for label, filename in SNAPSHOTS:
        print(f"reading {label} ...", flush=True)
        loaded.append((label, read(Path(root) / filename)))
    *earlier, (base_label, base) = loaded

    print(f"\nbaseline: {base_label} -- {len(base['matches'])} matches, "
          f"{len(base['match_events'])} events, {len(base['match_player_events'])} of them naming a player, "
          f"{len(base['match_lineups'])} lineup rows\n")

    for label, snap in earlier:
        lost_matches = [i for i in snap["matches_by_id"] if i not in base["matches_by_id"]]
        lost_events = [i for i in snap["events_by_id"] if i not in base["events_by_id"]]
        lost_lineups = snap["lineup_ids"] - base["lineup_ids"]
        # The question the whole exercise exists to answer: did any event that
        # once named a scorer stop naming one?
        lost_scorer = [i for i, p in snap["player_of_event"].items()
                       if i in base["events_by_id"] and i not in base["player_of_event"]]
        changed_scorer = [i for i, p in snap["player_of_event"].items()
                          if base["player_of_event"].get(i) not in (None, p)]

        print(f"{label}: {len(snap['matches'])} matches, {len(snap['match_events'])} events, "
              f"{len(snap['match_lineups'])} lineup rows")
        print(f"  matches absent from {base_label}: {len(lost_matches)}")
        print(f"  lineup rows absent from {base_label}: {len(lost_lineups)}")
        print(f"  events absent from {base_label}: {len(lost_events)}"
              + (f"  -> {sorted(lost_events)}" if lost_events else ""))
        for i in sorted(lost_events):
            e = snap["events_by_id"][i]
            print(f"      event {i}: match {e['match_id']}, type {e['event_id']}, minute {e['minute']}, "
                  f"player {snap['player_of_event'].get(i)}")
        print(f"  events that LOST their scorer: {len(lost_scorer)}"
              + (f"  -> {sorted(lost_scorer)}" if lost_scorer else ""))
        print(f"  events whose scorer CHANGED: {len(changed_scorer)}"
              + (f"  -> {sorted(changed_scorer)}" if changed_scorer else ""))
        goals_no_scorer = sum(1 for i, e in snap["events_by_id"].items()
                              if e["event_id"] in GOAL_EVENT_IDS and i not in snap["player_of_event"])
        print(f"  goals with no scorer, already, in this snapshot: {goals_no_scorer}\n")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else ".")
