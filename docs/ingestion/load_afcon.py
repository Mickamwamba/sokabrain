#!/usr/bin/env python3
"""Load the canonical AFCON records into the vault.

Reads the file `normalize_afcon.py` produces and writes editions, groups,
matches, events, players and stadiums -- each with its `entity_source_map`
provenance, per design principle 1.

Three rules are enforced here rather than assumed:

* **AFCON 2019 is never written.** It is already in the vault as edition 14,
  migrated from the legacy SokaFC dump. WhoScored's copy is compared against
  it and every disagreement is recorded in `reconciliation_diffs` under a
  `reconciliation_runs` row (principle 2). Nothing about edition 14 is
  modified, including its coarser round labels -- that is a separate decision
  for a human to take with the diff in front of them.

* **An OWN_GOAL is stored against the scoring player's own team** (principle
  5), which is the vault's convention. `normalize_afcon.py` has already
  flipped the 2002-2012 pages, which file own goals the other way round.

* **Editions arrive unpublished.** `is_published` defaults to FALSE, so none of
  this reaches the public site until someone reviews it in the dashboard --
  the same gate the 16 new TPL editions went through.

Substitutions are deliberately NOT loaded. The vault has never stored one and
nothing reads them; the 2,666 in the harvest stay in
`raw/afcon/events.json` and can be loaded later if that changes.

Usage:
    python3 load_afcon.py <canon_afcon.json> [--commit]

Without --commit the whole run happens inside a transaction that is rolled
back, printing exactly what it would have done.
"""
import collections
import json
import sys
from datetime import datetime
from pathlib import Path

import psycopg2
import psycopg2.extras

sys.path.insert(0, str(Path(__file__).resolve().parent))

DSN = "postgresql://michaelkimollo@127.0.0.1:5432/sokabrain"

AFCON_COMPETITION = 16          # competitions.id -- 'Africa Cup of Nations'
LEGACY_2019_EDITION = 14        # already migrated; compared, never rewritten
LEGACY_SOURCE = "legacy_sokafc"

# Event types we load. Substitutions are excluded on purpose (see the docstring).
LOADED_EVENT_TYPES = {
    "GOAL", "OWN_GOAL", "PENALTY_GOAL", "PENALTY_MISS",
    "YELLOW_CARD", "SECOND_YELLOW", "RED_CARD", "ASSIST",
}

ROUND_ORDER = ["GROUP", "ROUND OF 16", "QUARTER FINAL", "SEMI FINAL",
               "THIRD PLACE", "FINAL"]


class Loader:
    def __init__(self, conn, commit):
        self.conn = conn
        self.cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        self.commit = commit
        self.stats = collections.Counter()
        self.notes = []
        self.source_id = self.one(
            "SELECT id FROM data_sources WHERE name = 'whoscored'")
        self.legacy_id = self.one(
            "SELECT id FROM data_sources WHERE name = %s", (LEGACY_SOURCE,))
        if not self.source_id:
            raise SystemExit("data_sources has no 'whoscored' row")

    # -- small helpers -----------------------------------------------------
    def one(self, sql, args=()):
        self.cur.execute(sql, args)
        row = self.cur.fetchone()
        return row[0] if row else None

    def provenance(self, entity_type, entity_id, external_id, url=None):
        self.cur.execute(
            """INSERT INTO entity_source_map
                   (entity_type, entity_id, data_source_id, external_id, external_url)
               VALUES (%s, %s, %s, %s, %s)
               ON CONFLICT (entity_type, data_source_id, external_id) DO NOTHING""",
            (entity_type, entity_id, self.source_id, str(external_id), url))

    # -- reference data ----------------------------------------------------
    def load_teams(self):
        self.cur.execute(
            "SELECT id, name, country_id FROM teams WHERE type = 'NATIONAL'")
        self.teams = {r["name"]: (r["id"], r["country_id"]) for r in self.cur.fetchall()}

    def team_id(self, name):
        hit = self.teams.get(name)
        if not hit:
            raise SystemExit(f"national team {name!r} is not in the vault; "
                             "add an alias to nationnames.py rather than guessing")
        return hit

    def season(self, label, start, end):
        sid = self.one("SELECT id FROM seasons WHERE label = %s", (label,))
        if sid:
            return sid
        self.cur.execute(
            "INSERT INTO seasons (label, start_date, end_date) VALUES (%s,%s,%s) RETURNING id",
            (label, start, end))
        sid = self.cur.fetchone()[0]
        self.stats["seasons created"] += 1
        return sid

    def edition(self, season_id, num_teams):
        eid = self.one(
            "SELECT id FROM competition_editions WHERE competition_id=%s AND season_id=%s",
            (AFCON_COMPETITION, season_id))
        if eid:
            return eid, False
        self.cur.execute(
            """INSERT INTO competition_editions
                   (competition_id, season_id, format, num_teams, is_published)
               VALUES (%s,%s,%s,%s,FALSE) RETURNING id""",
            (AFCON_COMPETITION, season_id, "GROUPS_KNOCKOUT", num_teams))
        eid = self.cur.fetchone()[0]
        self.stats["editions created"] += 1
        return eid, True

    def group(self, edition_id, letter):
        key = (edition_id, letter)
        if key in self._groups:
            return self._groups[key]
        gid = self.one(
            "SELECT id FROM competition_groups WHERE competition_edition_id=%s AND name=%s",
            (edition_id, letter))
        if not gid:
            self.cur.execute(
                "INSERT INTO competition_groups (competition_edition_id, name) VALUES (%s,%s) RETURNING id",
                (edition_id, letter))
            gid = self.cur.fetchone()[0]
            self.stats["groups created"] += 1
        self._groups[key] = gid
        return gid

    def stadium(self, name, country_id):
        if not name:
            return None
        if name in self._stadiums:
            return self._stadiums[name]
        sid = self.one("SELECT id FROM stadiums WHERE lower(name) = lower(%s)", (name,))
        if not sid:
            self.cur.execute(
                "INSERT INTO stadiums (name, country_id) VALUES (%s,%s) RETURNING id",
                (name, country_id))
            sid = self.cur.fetchone()[0]
            self.stats["stadiums created"] += 1
        self._stadiums[name] = sid
        return sid

    def player(self, ws_id, name, nationality_id):
        """Resolve or create a player.

        Identity comes from the WhoScored player id where the source gives one
        (2013+ and the four recovered 2013 knockouts). The 2002-2012 and 2017
        pages name a scorer but carry no id, so those are keyed by
        (name, national team) instead -- safe here because a player turns out
        for one country, and checked: across all 13 tournaments only a single
        (name, team) pair spans more than eight years, Asamoah Gyan for Ghana,
        who is genuinely one player.
        """
        if ws_id:
            key = ("ws", str(ws_id))
        else:
            key = ("name", nationality_id, name.lower())
        if key in self._players:
            return self._players[key]

        pid = None
        if ws_id:
            pid = self.one(
                """SELECT entity_id FROM entity_source_map
                    WHERE entity_type='player' AND data_source_id=%s AND external_id=%s""",
                (self.source_id, str(ws_id)))
        if not pid:
            pid = self.one(
                """SELECT id FROM players
                    WHERE lower(full_name)=lower(%s) AND nationality_id IS NOT DISTINCT FROM %s""",
                (name, nationality_id))
        if not pid:
            self.cur.execute(
                "INSERT INTO players (full_name, nationality_id) VALUES (%s,%s) RETURNING id",
                (name, nationality_id))
            pid = self.cur.fetchone()[0]
            self.stats["players created"] += 1
        if ws_id:
            self.provenance("player", pid, ws_id,
                            f"https://www.whoscored.com/players/{ws_id}/show")
        else:
            self.provenance("player", pid, f"name:{nationality_id}:{name}")
        self._players[key] = pid
        return pid

    # -- the load ----------------------------------------------------------
    def run(self, rows):
        self.load_teams()
        self._groups, self._stadiums, self._players = {}, {}, {}

        by_season = collections.defaultdict(list)
        for r in rows:
            by_season[r["season"]].append(r)

        for label in sorted(by_season):
            records = by_season[label]

            # An edition the vault already holds is compared, never rewritten,
            # and gets no new season row. AFCON 2019 is the case that exists:
            # it came in with the legacy migration and hangs off season
            # '2018/2019' rather than a single-year label.
            dates = sorted(r["kickoff_utc"][:10] for r in records if r["kickoff_utc"])
            target = self.existing_edition(label, dates[0], dates[-1])
            if target:
                self.reconcile(label, target, records)
                continue

            sid = self.season(label, min(dates), max(dates))
            sides = {r["home_name"] for r in records} | {r["away_name"] for r in records}
            eid, _ = self.edition(sid, len(sides))
            self.load_edition(eid, label, records)

    def existing_edition(self, label, first_day, last_day):
        """Edition of this AFCON already in the vault, or None.

        Tried in two ways, because the vault holds these editions two ways.
        A tournament this loader has written before hangs off a season labelled
        with its year, so that is an exact lookup. AFCON 2019 came in with the
        legacy migration instead and hangs off '2018/2019', so it is found by
        the dates its matches were actually played -- which is also what keeps
        a re-run from creating a second copy of a tournament played in the
        following calendar year, as 2021, 2023 and 2025 all were.
        """
        exact = self.one(
            """SELECT ce.id FROM competition_editions ce
                 JOIN seasons s ON s.id = ce.season_id
                WHERE ce.competition_id = %s AND s.label = %s""",
            (AFCON_COMPETITION, label))
        if exact:
            return exact
        return self.one(
            """SELECT ce.id
                 FROM competition_editions ce
                 JOIN matches m ON m.competition_edition_id = ce.id
                WHERE ce.competition_id = %s
                GROUP BY ce.id
               HAVING min(m.kickoff_at) >= %s::date - 30
                  AND max(m.kickoff_at) <= %s::date + 30
                LIMIT 1""",
            (AFCON_COMPETITION, first_day, last_day))

    def load_edition(self, edition_id, label, records):
        held = self.one(
            "SELECT count(*) FROM matches WHERE competition_edition_id=%s", (edition_id,))
        if held:
            self.notes.append(f"{label}: edition {edition_id} already holds "
                              f"{held} matches - skipped, nothing overwritten")
            return

        participants = {}
        for r in records:
            self.load_match(edition_id, r, participants)

        for (team_id, group_id) in sorted(set(participants.values())):
            self.cur.execute(
                """INSERT INTO competition_edition_teams
                       (competition_edition_id, team_id, group_id)
                   VALUES (%s,%s,%s)""",
                (edition_id, team_id, group_id))
            self.stats["edition teams"] += 1

    def load_match(self, edition_id, r, participants):
        home_id, home_country = self.team_id(r["home_name"])
        away_id, away_country = self.team_id(r["away_name"])
        group_id = self.group(edition_id, r["group"]) if r["group"] else None
        stadium_id = self.stadium(r["venue"], None)

        if r["group"]:
            participants[(r["home_name"], r["group"])] = (home_id, group_id)
            participants[(r["away_name"], r["group"])] = (away_id, group_id)

        self.cur.execute(
            """INSERT INTO matches
                   (competition_edition_id, group_id, round, home_team_id, away_team_id,
                    stadium_id, kickoff_at, status, home_score, away_score,
                    home_score_et, away_score_et, home_score_pens, away_score_pens,
                    attendance)
               VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s) RETURNING id""",
            (edition_id, group_id, r["round"], home_id, away_id, stadium_id,
             r["kickoff_utc"], r["status"], r["home_score"], r["away_score"],
             r["home_score_et"], r["away_score_et"],
             r["home_score_pens"], r["away_score_pens"], r["attendance"]))
        match_id = self.cur.fetchone()[0]
        self.stats["matches"] += 1
        self.provenance("match", match_id, r["source_match_id"], r["source_url"])

        # The event's provenance key is its position in the match's event list,
        # not (minute, type, team): two players are booked in the same minute
        # often enough that a descriptive key collides and, with ON CONFLICT DO
        # NOTHING, silently leaves the second event with no provenance row at
        # all -- which principle 1 does not allow.
        seq = 0
        for e in r["events"]:
            if e["type"] not in LOADED_EVENT_TYPES:
                self.stats["events skipped (substitution)"] += 1
                continue
            seq += 1
            side_team, side_country = ((home_id, home_country) if e["team"] == "HOME"
                                       else (away_id, away_country))
            name = e.get("player_name") or e.get("scorer_hint")
            player_id = (self.player(e.get("source_player_id"), name, side_country)
                         if name else None)
            self.cur.execute(
                """INSERT INTO match_events
                       (match_id, team_id, player_id, minute, type)
                   VALUES (%s,%s,%s,%s,%s) RETURNING id""",
                (match_id, side_team, player_id, e["minute"], e["type"]))
            event_id = self.cur.fetchone()[0]
            self.stats["events"] += 1
            if player_id is None:
                self.stats["events without a player"] += 1
            self.provenance("match_event", event_id,
                            f"{r['source_match_id']}:e{seq}", r["source_url"])

    # -- reconciliation, for a season the vault already holds ---------------
    def reconcile(self, label, edition_id, records):
        # Compare like with like: the result score, extra time included on both
        # sides. Reading only home_score would flag every tie decided in extra
        # time, because this loader stores the 90-minute score there.
        self.cur.execute(
            """SELECT m.id, m.kickoff_at, m.round,
                      coalesce(m.home_score_et, m.home_score) AS home_score,
                      coalesce(m.away_score_et, m.away_score) AS away_score,
                      h.name AS home, a.name AS away
                 FROM matches m
                 JOIN teams h ON h.id = m.home_team_id
                 JOIN teams a ON a.id = m.away_team_id
                WHERE m.competition_edition_id = %s""", (edition_id,))
        vault = self.cur.fetchall()
        by_pair = {}
        for v in vault:
            by_pair.setdefault(frozenset((v["home"], v["away"])), []).append(v)

        run_id = None
        diffs = matched = unmatched = 0
        for r in records:
            cand = by_pair.get(frozenset((r["home_name"], r["away_name"])), [])
            hit = None
            for v in cand:
                if v["kickoff_at"] and r["kickoff_utc"][:10] == v["kickoff_at"].strftime("%Y-%m-%d"):
                    hit = v
                    break
            if hit is None and len(cand) == 1:
                hit = cand[0]
            if hit is None:
                unmatched += 1
                continue
            matched += 1
            # Compare the result score: after extra time where it was played.
            ours_h = r["home_score_et"] if r["home_score_et"] is not None else r["home_score"]
            ours_a = r["away_score_et"] if r["away_score_et"] is not None else r["away_score"]
            if hit["home"] != r["home_name"]:      # vault holds it the other way round
                ours_h, ours_a = ours_a, ours_h
            for field, theirs, ours in (("home_score", hit["home_score"], ours_h),
                                        ("away_score", hit["away_score"], ours_a)):
                if theirs != ours:
                    if run_id is None:
                        run_id = self.open_run(label, edition_id)
                    self.cur.execute(
                        """INSERT INTO reconciliation_diffs
                               (reconciliation_run_id, entity_id_a, entity_id_b,
                                field_name, value_a, value_b, resolution)
                           VALUES (%s,%s,%s,%s,%s,%s,'PENDING')""",
                        (run_id, hit["id"], None, field,
                         None if theirs is None else str(theirs),
                         None if ours is None else str(ours)))
                    diffs += 1
        self.notes.append(
            f"{label}: compared against existing edition {edition_id} - "
            f"{matched} matched, {unmatched} unmatched, {diffs} score diff(s) recorded"
            + ("" if diffs else "; the two sources agree"))
        self.stats["reconciliation diffs"] += diffs

    def open_run(self, label, edition_id):
        self.cur.execute(
            """INSERT INTO reconciliation_runs
                   (entity_type, data_source_a_id, data_source_b_id, notes)
               VALUES ('match', %s, %s, %s) RETURNING id""",
            (self.legacy_id, self.source_id, self.run_notes(label, edition_id)))
        return self.cur.fetchone()[0]

    def run_notes(self, label, edition_id):
        """Narrative for the run row, including what the vault says about itself.

        A bare list of score diffs would leave the reader to work out which
        side is wrong. The decisive evidence is internal: for most of these
        matches the vault's stored score disagrees with the vault's OWN event
        log, and the event log is what agrees with WhoScored. That is counted
        here so the note carries the argument, not just the numbers.
        """
        self.cur.execute(
            """SELECT count(*) FROM (
                 SELECT m.id,
                   count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL') AND e.team_id=m.home_team_id
                                       OR e.type='OWN_GOAL' AND e.team_id=m.away_team_id) AS eh,
                   count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL') AND e.team_id=m.away_team_id
                                       OR e.type='OWN_GOAL' AND e.team_id=m.home_team_id) AS ea,
                   m.home_score AS sh, m.away_score AS sa
                   FROM matches m LEFT JOIN match_events e ON e.match_id = m.id
                  WHERE m.competition_edition_id = %s
                  GROUP BY m.id) t
               WHERE sh IS DISTINCT FROM eh OR sa IS DISTINCT FROM ea""",
            (edition_id,))
        internal = self.cur.fetchone()[0]
        return (
            f"AFCON {label} (edition {edition_id}), the migrated legacy copy against "
            f"whoscored.com. Joined on date plus unordered team pair. The vault is "
            f"source A and is left untouched; every disagreement is recorded here "
            f"rather than resolved (principle 2). Note for whoever resolves these: "
            f"{internal} of this edition's matches have a stored score that disagrees "
            f"with the edition's own match_events, and in those cases the event log is "
            f"what agrees with WhoScored -- so the stored score, not the event log, is "
            f"the thing in doubt. Three separate defects are mixed together here: group "
            f"matches whose away score is inflated, knockout ties where the shootout "
            f"winner was credited an extra goal, and matches left NULL that were 0-0 "
            f"(the same lost-goalless-draw defect found in TPL 2017/18, run 8).")


def main():
    rows = json.loads(Path(sys.argv[1]).read_text())
    commit = "--commit" in sys.argv
    conn = psycopg2.connect(DSN)
    conn.cursor().execute("SET TIME ZONE 'UTC'")
    loader = Loader(conn, commit)
    try:
        loader.run(rows)
        print(f"{'what':<34}{'count':>8}")
        for k in sorted(loader.stats):
            print(f"{k:<34}{loader.stats[k]:>8}")
        if loader.notes:
            print()
            for n in loader.notes:
                print(" -", n)
        if commit:
            conn.commit()
            print("\nCOMMITTED")
        else:
            conn.rollback()
            print("\nROLLED BACK (dry run -- pass --commit to apply)")
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


if __name__ == "__main__":
    main()
