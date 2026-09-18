"""Complete a Premier League season's goal log from a Flashscore harvest.

    python3 load_flashscore_tpl.py raw/flashscore_tpl/2024-2025.json            # dry run
    python3 load_flashscore_tpl.py raw/flashscore_tpl/2024-2025.json --commit

The harvest holds, per vault match id, every goal Flashscore lists: side, minute,
stoppage time, type, and the scorer's link slug.

**This does not replace the vault's goal log; it completes it.** The vault's
existing events come from ligikuu and carry full names, which Flashscore's
timeline does not -- overwriting them with "Mwalimu S." would be a downgrade.
So each side's goals are compared by count, and only the shortfall is written.
Where the vault's log has the right number of goals on the wrong side, the
misplaced ones are re-sided rather than deleted and reinserted.

A match is touched only if Flashscore's goals reconcile exactly with the score
the vault already holds. Anything else is reported and left alone.

Own goals: Flashscore lists one under the side it COUNTS FOR, like every other
source. The vault stores it under the scorer's own team (design principle 5),
so the side is flipped on the way in.
"""
import json
import sys
from collections import defaultdict

import psycopg2

from match_flashscore_players import fold, name_from, resolve

DSN = "host=127.0.0.1 port=5432 dbname=sokabrain"
GOALS = ("GOAL", "PENALTY_GOAL", "OWN_GOAL")


def credited_in_vault(typ, side):
    """Which side a STORED event counts for.

    The vault keeps an own goal under the scorer's own team (design principle
    5), so a stored own goal counts for the other side.
    """
    if typ == "OWN_GOAL":
        return "away" if side == "home" else "home"
    return side


def scorer_side(g):
    """Which side the SCORER of a harvested goal plays for.

    Flashscore lists a goal on the side it counts FOR -- an own goal included --
    so the scorer of an own goal plays for the other side. This is the only
    flip the harvest needs; its `side` is already the crediting side.
    """
    if g["type"] == "OWN_GOAL":
        return "away" if g["side"] == "home" else "home"
    return g["side"]


class Loader:
    def __init__(self, conn):
        self.c = conn.cursor()
        self.stats = defaultdict(int)
        self.notes = []
        self.c.execute("SELECT id FROM data_sources WHERE name = 'flashscore'")
        row = self.c.fetchone()
        if not row:
            raise SystemExit("no data_sources row for flashscore")
        self.source_id = row[0]
        self.by_team = defaultdict(list)
        self.c.execute("""
            SELECT DISTINCT p.id, p.full_name, e.team_id
              FROM match_events e JOIN players p ON p.id = e.player_id
        """)
        for pid, nm, tid in self.c.fetchall():
            self.by_team[tid].append((pid, nm))
        # A club's squad is a better candidate pool than its scorers alone.
        self.c.execute("""
            SELECT DISTINCT p.id, p.full_name, s.team_id
              FROM player_team_stints s JOIN players p ON p.id = s.player_id
        """)
        for pid, nm, tid in self.c.fetchall():
            if (pid, nm) not in self.by_team[tid]:
                self.by_team[tid].append((pid, nm))
        self.resolved = {}

    def player(self, slug, display, team_id):
        if not slug:
            return None
        key = (team_id, slug)
        if key in self.resolved:
            return self.resolved[key]
        pid, how = resolve(slug, self.by_team.get(team_id, []))
        if pid is None and how == "ambiguous":
            self.stats["scorers left unnamed (two vault players match)"] += 1
            self.notes.append(f"ambiguous: {slug} for team {team_id}")
            self.resolved[key] = None
            return None
        if pid is None:
            full = name_from(slug, display)
            self.c.execute("INSERT INTO players (full_name) VALUES (%s) RETURNING id", (full,))
            pid = self.c.fetchone()[0]
            self.by_team[team_id].append((pid, full))
            self.stats["players created"] += 1
            self.notes.append(f"created: {full}  (from {slug})")
        else:
            self.stats["players matched to existing"] += 1
        self.c.execute("""
            INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
            VALUES ('player', %s, %s, %s, 1.0)
            ON CONFLICT (entity_type, data_source_id, external_id) DO UPDATE SET last_synced_at = now()
        """, (pid, self.source_id, f"flashscore-player-{slug}"))
        self.resolved[key] = pid
        return pid

    def do_match(self, rec, run_id):
        mid = rec["match"]
        self.c.execute("""
            SELECT m.home_team_id, m.away_team_id, m.home_score, m.away_score
              FROM matches m WHERE m.id = %s
        """, (mid,))
        row = self.c.fetchone()
        if not row:
            self.stats["skipped, no such match"] += 1
            return
        home_id, away_id, hs, as_ = row

        incoming = [g for g in rec["goals"] if g["type"] in GOALS]
        want = defaultdict(int)
        for g in incoming:
            want[g["side"]] += 1        # Flashscore's side is already the crediting one
        if want["home"] != hs or want["away"] != as_:
            self.stats["skipped, source does not reconcile"] += 1
            self.notes.append(
                f"match {mid}: Flashscore reads {want['home']}-{want['away']} for a {hs}-{as_}")
            return

        self.c.execute("""
            SELECT id, team_id, player_id, minute, type FROM match_events
             WHERE match_id = %s AND type = ANY(%s) ORDER BY minute NULLS LAST, id
        """, (mid, list(GOALS)))
        existing = self.c.fetchall()
        have = defaultdict(int)
        for _id, tid, _pid, _min, typ in existing:
            side = "home" if tid == home_id else "away" if tid == away_id else None
            if side:
                have[credited_in_vault(typ, side)] += 1

        # Same number of goals but on the wrong sides. Re-siding them needs the
        # two lists to line up, and they only do when the vault's events carry
        # minutes to line up BY. Where they do not -- match 17991 holds three
        # goals with no minute at all, which sort last while Flashscore's are
        # chronological -- pairing by position would scramble the scorers.
        # Report it for a human rather than guess.
        if len(existing) == len(incoming) and have != want:
            by_minute = {}
            ok = all(minute is not None for _i, _t, _p, minute, _ty in existing)
            if ok:
                for ev in existing:
                    by_minute.setdefault(ev[3], []).append(ev)
                ok = all(len(by_minute.get(g.get("minute"), [])) == 1 for g in incoming)
            if not ok:
                self.stats["left for review, sides differ and cannot be aligned"] += 1
                self.notes.append(
                    f"match {mid}: {len(existing)} events on the wrong sides, and the vault's "
                    f"minutes do not line up with Flashscore's -- not re-sided")
                return
            for g in incoming:
                ev_id, tid, _pid, _minute, typ = by_minute[g["minute"]][0]
                right = home_id if scorer_side(g) == "home" else away_id
                if tid != right or typ != g["type"]:
                    self.c.execute("""
                        INSERT INTO reconciliation_diffs
                          (reconciliation_run_id, entity_id_a, entity_id_b, field_name,
                           value_a, value_b, resolution, resolved_value, resolved_at)
                        VALUES (%s, %s, %s, 'match_events.team_id', %s, %s, 'ACCEPT_B', %s, now())
                    """, (run_id, ev_id, mid, f"team {tid}, {typ}",
                          f"team {right}, {g['type']} (Flashscore)", str(right)))
                    self.c.execute("UPDATE match_events SET team_id = %s, type = %s WHERE id = %s",
                                   (right, g["type"], ev_id))
                    self.stats["events re-sided"] += 1
            self.stats["matches corrected"] += 1
            return

        # Otherwise fill the shortfall, per side, taking Flashscore's goals for
        # that side in order and skipping as many as the vault already holds.
        added = 0
        for side in ("home", "away"):
            short = want[side] - have[side]
            if short <= 0:
                continue
            mine = [g for g in incoming if g["side"] == side]
            for g in mine[len(mine) - short:]:
                team_id = home_id if scorer_side(g) == "home" else away_id
                pid = self.player(g.get("slug"), g.get("display"), team_id)
                self.c.execute("""
                    INSERT INTO match_events (match_id, team_id, player_id, minute, added_time, type)
                    VALUES (%s, %s, %s, %s, %s, %s) RETURNING id
                """, (mid, team_id, pid, g.get("minute"), g.get("added"), g["type"]))
                ev_id = self.c.fetchone()[0]
                self.c.execute("""
                    INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
                    VALUES ('match_event', %s, %s, %s, 1.0)
                    ON CONFLICT (entity_type, data_source_id, external_id) DO NOTHING
                """, (ev_id, self.source_id, f"flashscore-{mid}-{g['side']}-{g.get('minute')}-{g.get('added') or 0}"))
                self.stats[f"goals added ({g['type']})"] += 1
                if pid is None:
                    self.stats["goals added with no scorer named"] += 1
                added += 1
        if added:
            self.stats["matches completed"] += 1
        else:
            self.stats["matches already complete"] += 1


def verify(cur, season):
    cur.execute("""
        WITH x AS (
          SELECT m.id,
            coalesce(m.home_score_et, m.home_score) hs, coalesce(m.away_score_et, m.away_score) as_,
            count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL') AND
              (CASE WHEN e.type='OWN_GOAL'
                    THEN CASE WHEN e.team_id=m.home_team_id THEN m.away_team_id ELSE m.home_team_id END
                    ELSE e.team_id END) = m.home_team_id) h,
            count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL') AND
              (CASE WHEN e.type='OWN_GOAL'
                    THEN CASE WHEN e.team_id=m.home_team_id THEN m.away_team_id ELSE m.home_team_id END
                    ELSE e.team_id END) = m.away_team_id) a,
            count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL') AND e.player_id IS NULL) unnamed
          FROM matches m
          JOIN competition_editions ce ON ce.id = m.competition_edition_id
          JOIN seasons s ON s.id = ce.season_id
          LEFT JOIN match_events e ON e.match_id = m.id
         WHERE ce.competition_id = 1 AND s.label = %s AND m.home_score IS NOT NULL
         GROUP BY m.id, 2, 3)
        SELECT count(*), count(*) FILTER (WHERE h = hs AND a = as_),
               sum(greatest((hs + as_) - (h + a), 0)), sum(unnamed)
          FROM x
    """, (season,))
    total, ok, missing, unnamed = cur.fetchone()
    print(f"\n{season}: {ok} of {total} matches reconcile; "
          f"{missing} goals still have no event; {unnamed} events name no scorer")


def main(path, commit):
    staged = json.load(open(path))
    season = path.split("/")[-1].replace(".json", "").replace("-", "/")
    conn = psycopg2.connect(DSN)
    conn.autocommit = False
    cur = conn.cursor()
    cur.execute("SET timezone = 'UTC'")
    cur.execute("""
        INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
        VALUES ('match_event',
                (SELECT id FROM data_sources WHERE name='ligikuu'),
                (SELECT id FROM data_sources WHERE name='flashscore'),
                %s) RETURNING id
    """, (f"Premier League {season}: goal logs completed from Flashscore, for matches "
          f"the vault held short of or wrongly against their stored score.",))
    run_id = cur.fetchone()[0]

    loader = Loader(conn)
    for rec in staged:
        loader.do_match(rec, run_id)

    print(f"{len(staged)} matches in the harvest")
    for k in sorted(loader.stats):
        print(f"  {k}: {loader.stats[k]}")
    if loader.notes:
        print("\nnotes:")
        for n in loader.notes:
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
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    main(sys.argv[1], "--commit" in sys.argv)
