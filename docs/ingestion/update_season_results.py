#!/usr/bin/env python3
"""Fill in results for a season already in the vault, as it is played.

    python3 fetch_ligikuu.py raw/ligikuu
    python3 normalize_ligikuu.py raw/ligikuu canon_ligikuu.json
    python3 update_season_results.py canon_ligikuu.json 2026/2027            # dry run
    python3 update_season_results.py canon_ligikuu.json 2026/2027 --commit

`load.py` is for ingesting a season the vault does not have: it **skips a
season already present**, deliberately, so a bulk re-run can never trample
existing data. That makes it the wrong tool for the season in play, whose
fixtures are already loaded and are waiting for their results. This fills those
in, and nothing else.

What it will touch, and what it will not:

* **Only a match with no score.** A match the vault already has a result for is
  left exactly as it is, even if the source disagrees -- that is a
  `reconciliation_diffs` row, not an overwrite (principle 2). The disagreement
  is reported so a human can look.
* **Only a match with no goal events.** Events are added to a match that has
  none; a match that already has some is left alone rather than merged, because
  merging is what `load_fotmob_tpl.py` exists for and it needs a harvest shaped
  for it.
* **The kickoff is corrected when the source has a different date**, because a
  fixture that moved is a fact and a stale scheduled date is a defect -- the
  vault has been bitten by exactly that before, with 82 COVID-restart fixtures
  left on their original dates. Every change is recorded as a diff.

A fixture is identified by its two clubs: an ordered pair meets once in a
double round-robin, which is safer than a date the two sides may disagree on.
"""
import json
import sys
from collections import defaultdict

import psycopg2
import psycopg2.extras

sys.path.insert(0, __file__.rsplit("/", 1)[0])

from load import TANZANIA, norm_person, team_key  # noqa: E402

DSN = "host=127.0.0.1 port=5432 dbname=sokabrain"
GOALS = ("GOAL", "PENALTY_GOAL", "OWN_GOAL")


class Updater:
    def __init__(self, conn, source):
        self.conn = conn
        self.c = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        self.stats = defaultdict(int)
        self.notes = []
        self.source = source
        self.c.execute("SELECT id FROM data_sources WHERE name=%s", (source,))
        row = self.c.fetchone()
        if not row:
            raise SystemExit(f"no data_sources row for {source}")
        self.source_id = row["id"]

        self.c.execute("SELECT id, full_name FROM players")
        self.by_name = {}
        for r in self.c.fetchall():
            self.by_name.setdefault(norm_person(r["full_name"]), r["id"])

        # The source's own player ids, which are a better key than a name.
        self.c.execute("""
            SELECT external_id, entity_id FROM entity_source_map
             WHERE entity_type='player' AND data_source_id=%s
        """, (self.source_id,))
        self.by_ext = {r["external_id"]: r["entity_id"] for r in self.c.fetchall()}

    def one(self, sql, args):
        self.c.execute(sql, args)
        row = self.c.fetchone()
        return list(row.values())[0] if row else None

    def provenance(self, kind, eid, external_id, url=None):
        if external_id is None:
            return
        self.c.execute("""
            INSERT INTO entity_source_map
                (entity_type, entity_id, data_source_id, external_id, external_url)
            VALUES (%s,%s,%s,%s,%s)
            ON CONFLICT (entity_type, data_source_id, external_id) DO NOTHING
        """, (kind, eid, self.source_id, str(external_id), url))

    def player(self, name, external_id):
        """The source's id first, then the name, then a new record."""
        if external_id is not None and str(external_id) in self.by_ext:
            return self.by_ext[str(external_id)]
        if not name:
            return None
        k = norm_person(name)
        if not k:
            return None
        pid = self.by_name.get(k)
        if pid is None:
            parts = str(name).split()
            pid = self.one(
                """INSERT INTO players (full_name, first_name, last_name, nationality_id)
                   VALUES (%s,%s,%s,%s) RETURNING id""",
                (name.strip(), parts[0] if parts else None,
                 parts[-1] if len(parts) > 1 else None, TANZANIA))
            self.by_name[k] = pid
            self.stats["players created"] += 1
            self.notes.append(f"created player: {name.strip()}")
        if external_id is not None:
            self.by_ext[str(external_id)] = pid
        self.provenance("player", pid, external_id)
        return pid

    def run(self, records, season, run_id):
        self.c.execute("""
            SELECT m.id, m.home_team_id, m.away_team_id, m.home_score, m.away_score,
                   m.status, m.kickoff_at, ht.name AS home, at.name AS away,
                   (SELECT count(*) FROM match_events e
                     WHERE e.match_id=m.id AND e.type = ANY(%s)) AS ev
              FROM matches m
              JOIN competition_editions ce ON ce.id = m.competition_edition_id
              JOIN seasons s ON s.id = ce.season_id
              JOIN teams ht ON ht.id = m.home_team_id
              JOIN teams at ON at.id = m.away_team_id
             WHERE ce.competition_id = 1 AND s.label = %s
        """, (list(GOALS), season))
        by_pair = defaultdict(list)
        for r in self.c.fetchall():
            by_pair[(team_key(r["home"]), team_key(r["away"]))].append(r)

        for rec in records:
            if rec.get("home_score") is None:
                continue
            pair = (team_key(rec["home_name"]), team_key(rec["away_name"]))
            cands = by_pair.get(pair, [])
            if len(cands) != 1:
                self.stats["source fixtures with no unique vault match"] += 1
                self.notes.append(
                    f"no unique fixture: {rec['home_name']} v {rec['away_name']} "
                    f"({len(cands)} candidates)")
                continue
            m = cands[0]
            self.apply(m, rec, run_id)

    def apply(self, m, rec, run_id):
        mid = m["id"]
        hs, as_ = rec["home_score"], rec["away_score"]

        if m["home_score"] is not None:
            if (m["home_score"], m["away_score"]) != (hs, as_):
                self.stats["scores the vault and source disagree on"] += 1
                self.notes.append(
                    f"match {mid} {m['home']} v {m['away']}: vault "
                    f"{m['home_score']}-{m['away_score']}, {self.source} {hs}-{as_} "
                    f"-- left alone, recorded as a diff")
                self.c.execute("""
                    INSERT INTO reconciliation_diffs
                      (reconciliation_run_id, entity_id_a, entity_id_b, field_name,
                       value_a, value_b, resolution)
                    VALUES (%s,%s,%s,'matches.score',%s,%s,'PENDING')
                """, (run_id, mid, None, f"{m['home_score']}-{m['away_score']}",
                      f"{hs}-{as_} ({self.source})"))
            else:
                self.stats["already had this result"] += 1
            return

        # -- the score ------------------------------------------------------
        self.c.execute("""
            INSERT INTO reconciliation_diffs
              (reconciliation_run_id, entity_id_a, entity_id_b, field_name,
               value_a, value_b, resolution, resolved_value, resolved_at)
            VALUES (%s,%s,%s,'matches.score','no result',%s,'ACCEPT_B',%s,now())
        """, (run_id, mid, None, f"{hs}-{as_} ({self.source})", f"{hs}-{as_}"))
        self.c.execute("""
            UPDATE matches SET home_score=%s, away_score=%s, status=%s WHERE id=%s
        """, (hs, as_, rec.get("status") or "FULL_TIME", mid))
        self.stats["results filled in"] += 1
        self.provenance("match", mid, rec.get("source_match_id"), rec.get("source_url"))

        # -- the date, if the fixture moved ----------------------------------
        played = (rec.get("kickoff_utc") or "")[:10]
        had = m["kickoff_at"].date().isoformat() if m["kickoff_at"] else None
        if played and had and played != had:
            self.c.execute("""
                INSERT INTO reconciliation_diffs
                  (reconciliation_run_id, entity_id_a, entity_id_b, field_name,
                   value_a, value_b, resolution, resolved_value, resolved_at)
                VALUES (%s,%s,%s,'matches.kickoff_at',%s,%s,'ACCEPT_B',%s,now())
            """, (run_id, mid, None, had, f"{played} ({self.source})", played))
            self.c.execute("UPDATE matches SET kickoff_at=%s WHERE id=%s",
                           (rec["kickoff_utc"], mid))
            self.stats["fixtures that had moved, date corrected"] += 1
            self.notes.append(f"match {mid} {m['home']} v {m['away']}: {had} -> {played}")

        # -- the goals -------------------------------------------------------
        if m["ev"]:
            self.stats["results filled in, goal log already present"] += 1
            return
        evs = [e for e in (rec.get("events") or []) if e.get("type") in GOALS]
        if not evs:
            if hs + as_ > 0:
                self.stats["results filled in, source has no goal log"] += 1
            return
        want_home = sum(1 for e in evs if e["side"] == "home")
        if want_home != hs or len(evs) - want_home != as_:
            self.stats["goal logs refused, they do not add up to the score"] += 1
            self.notes.append(
                f"match {mid} {m['home']} v {m['away']}: {self.source} lists "
                f"{want_home}-{len(evs)-want_home} for a {hs}-{as_} -- goals not loaded")
            return
        for e in evs:
            # normalize_ligikuu.orient_own_goals has already put an own goal on
            # the scorer's own team, so `side` is the team to store it under.
            tid = m["home_team_id"] if e["side"] == "home" else m["away_team_id"]
            pid = self.player(e.get("player_name"), e.get("player_source_id"))
            ev_id = self.one("""
                INSERT INTO match_events (match_id, team_id, player_id, minute, added_time, type)
                VALUES (%s,%s,%s,%s,%s,%s) RETURNING id
            """, (mid, tid, pid, e.get("minute"), e.get("added_time"), e["type"]))
            self.provenance("match_event", ev_id,
                            f"{rec.get('source_match_id')}-{e['side']}-{e.get('minute')}-{e['type']}")
            self.stats[f"goals added ({e['type']})"] += 1
            if pid is None:
                self.stats["goals added with no scorer named"] += 1


def verify(cur, season):
    cur.execute("""
        WITH x AS (
          SELECT m.id, m.status,
            coalesce(m.home_score,0)+coalesce(m.away_score,0) AS goals,
            (SELECT count(*) FROM match_events e WHERE e.match_id=m.id
               AND e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL')) AS ev,
            m.home_score IS NOT NULL AS scored,
            m.kickoff_at < now() AND m.home_score IS NULL AS overdue
          FROM matches m
          JOIN competition_editions ce ON ce.id=m.competition_edition_id
          JOIN seasons s ON s.id=ce.season_id
         WHERE ce.competition_id=1 AND s.label=%s)
        SELECT count(*) AS fixtures,
               count(*) FILTER (WHERE scored) AS scored,
               count(*) FILTER (WHERE overdue) AS played_but_unscored,
               sum(goals) FILTER (WHERE scored) AS goals,
               sum(ev) AS events,
               count(*) FILTER (WHERE scored AND goals <> ev) AS not_reconciling
          FROM x
    """, (season,))
    r = cur.fetchone()
    print(f"\n{season}: {r['scored']} of {r['fixtures']} fixtures have a result; "
          f"{r['played_but_unscored']} are past their kickoff and still have none.")
    print(f"  {r['goals']} goals in those scores, {r['events']} goal events, "
          f"{r['not_reconciling']} matches whose log does not match their score")


def main():
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    path, season = sys.argv[1], sys.argv[2]
    commit = "--commit" in sys.argv
    source = "ligikuu"
    for a in sys.argv[3:]:
        if a.startswith("--source="):
            source = a.split("=", 1)[1]

    records = [r for r in json.load(open(path)) if r.get("season") == season]
    conn = psycopg2.connect(DSN)
    conn.autocommit = False
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("SET timezone='UTC'")
    cur.execute("""
        INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
        VALUES ('match',
                (SELECT id FROM data_sources WHERE name=%s),
                (SELECT id FROM data_sources WHERE name=%s), %s) RETURNING id
    """, (source, source,
          f"Premier League {season}: results filled in for fixtures played since the last "
          f"update. Both sides are {source} -- the vault's earlier snapshot against today's."))
    run_id = cur.fetchone()["id"]

    up = Updater(conn, source)
    up.run(records, season, run_id)

    print(f"{len(records)} {source} records for {season}")
    for k in sorted(up.stats):
        print(f"  {k}: {up.stats[k]}")
    if up.notes:
        print("\nnotes:")
        for n in up.notes:
            print(f"  {n}")
    verify(cur, season)

    if commit:
        conn.commit()
        print("\nCOMMITTED")
    else:
        conn.rollback()
        print("\nrolled back (dry run) -- pass --commit to apply")
    conn.close()


if __name__ == "__main__":
    main()
