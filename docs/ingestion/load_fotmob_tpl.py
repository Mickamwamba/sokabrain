"""Complete a Premier League season's goal log from a FotMob harvest.

    python3 normalize_fotmob_tpl.py raw/fotmob_tpl/2022-2023.tsv > staged.json
    python3 load_fotmob_tpl.py staged.json 2022/2023             # dry run
    python3 load_fotmob_tpl.py staged.json 2022/2023 --commit

This is `load_flashscore_tpl.py` with a different source and a different way of
recognising a player, and it keeps that loader's central rule:

**it does not replace the vault's goal log, it completes it.** Where the vault
already holds a goal, that goal stays -- its name may have come from ligikuu,
which is no worse than FotMob's and sometimes fuller. Only the shortfall on each
side is written, and a match whose FotMob goals do not add up to the score the
vault already holds is reported and left untouched.

Own goals: FotMob's side comes from which half of the running score moved, so it
is the side the goal COUNTS FOR, as in every other source. The vault stores an
own goal under the scorer's own team (design principle 5), so the side is
flipped on the way in -- once, on the player's team, never on the event's.
"""
import json
import sys
from collections import defaultdict

import psycopg2

from match_fotmob_players import display, resolve, resolve_wide

DSN = "host=127.0.0.1 port=5432 dbname=sokabrain"
GOALS = ("GOAL", "PENALTY_GOAL", "OWN_GOAL")


def credited_in_vault(typ, side):
    """Which side a STORED event counts for.

    The vault keeps an own goal under the scorer's own team, so a stored own
    goal counts for the other side.
    """
    if typ == "OWN_GOAL":
        return "away" if side == "home" else "home"
    return side


def scorer_side(g):
    """Which side the SCORER of a harvested goal plays for.

    The harvest's `side` is the crediting side, so the scorer of an own goal
    plays for the other team. This is the only flip the harvest needs.
    """
    if g["type"] == "OWN_GOAL":
        return "away" if g["side"] == "home" else "home"
    return g["side"]


class Loader:
    def __init__(self, conn):
        self.c = conn.cursor()
        self.stats = defaultdict(int)
        self.notes = []
        self.c.execute("SELECT id FROM data_sources WHERE name = 'fotmob'")
        row = self.c.fetchone()
        if not row:
            raise SystemExit("no data_sources row for fotmob -- add one first")
        self.source_id = row[0]

        # A club's candidate pool: everyone who has scored for it, plus its
        # recorded squads. Narrowing by club is what makes a name-based match
        # safe; across the whole vault, "Juma Hassan" is several people.
        self.by_team = defaultdict(list)
        self.c.execute("""
            SELECT DISTINCT p.id, p.full_name, e.team_id
              FROM match_events e JOIN players p ON p.id = e.player_id
        """)
        for pid, nm, tid in self.c.fetchall():
            self.by_team[tid].append((pid, nm))
        self.c.execute("""
            SELECT DISTINCT p.id, p.full_name, s.team_id
              FROM player_team_stints s JOIN players p ON p.id = s.player_id
        """)
        for pid, nm, tid in self.c.fetchall():
            if (pid, nm) not in self.by_team[tid]:
                self.by_team[tid].append((pid, nm))
        # Every player in the vault, for the second pass. A man who scored for
        # one club in this season and another in the season the vault does have
        # an event log for is in nobody's pool for this one.
        self.c.execute("SELECT id, full_name FROM players")
        self.everyone = self.c.fetchall()
        self.resolved = {}

    def player(self, name, team_id):
        if not name:
            return None
        key = (team_id, name)
        if key in self.resolved:
            return self.resolved[key]
        pid, how = resolve(name, self.by_team.get(team_id, []))
        if pid is None and how == "ambiguous":
            # Two players at the SAME club whose names both contain this one.
            # That is the one place a wrong pick is both likely and damaging, so
            # the goal keeps its minute and side and loses only its scorer.
            self.stats["scorers left unnamed (two players at the club match)"] += 1
            self.notes.append(f"ambiguous at the club: {name} for team {team_id}")
            self.resolved[key] = None
            return None
        if pid is None:
            pid, how = resolve_wide(name, self.everyone)
            if pid is not None:
                self.by_team[team_id].append((pid, name))
        if pid is None:
            full = display(name)
            self.c.execute("INSERT INTO players (full_name) VALUES (%s) RETURNING id", (full,))
            pid = self.c.fetchone()[0]
            self.by_team[team_id].append((pid, full))
            self.everyone.append((pid, full))
            self.stats["players created"] += 1
            self.notes.append(
                f"created: {full}  (team {team_id})"
                + ("  -- NOTE the vault already holds this name more than once"
                   if how == "ambiguous" else ""))
        else:
            self.stats[f"players matched to existing ({how})"] += 1
        self.c.execute("""
            INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
            VALUES ('player', %s, %s, %s, 1.0)
            ON CONFLICT (entity_type, data_source_id, external_id) DO UPDATE SET last_synced_at = now()
        """, (pid, self.source_id, f"fotmob-player-{team_id}-{display(name)}"))
        self.resolved[key] = pid
        return pid

    def do_match(self, rec, run_id):
        mid = rec["match"]
        self.c.execute(
            "SELECT home_team_id, away_team_id, home_score, away_score FROM matches WHERE id = %s",
            (mid,))
        row = self.c.fetchone()
        if not row:
            self.stats["skipped, no such match"] += 1
            return
        home_id, away_id, hs, as_ = row

        incoming = [g for g in rec["goals"] if g["type"] in GOALS]
        want_home = sum(1 for g in incoming if g["side"] == "home")
        want_away = len(incoming) - want_home
        if want_home != hs or want_away != as_:
            self.stats["skipped, source does not reconcile"] += 1
            self.notes.append(f"match {mid}: FotMob reads {want_home}-{want_away} for a {hs}-{as_}")
            return

        self.c.execute("""
            SELECT id, team_id, player_id, minute, type FROM match_events
             WHERE match_id = %s AND type = ANY(%s) ORDER BY minute NULLS LAST, id
        """, (mid, list(GOALS)))
        existing = self.c.fetchall()
        have_home = have_away = 0
        for _id, tid, _pid, _min, typ in existing:
            side = "home" if tid == home_id else "away" if tid == away_id else None
            if side is None:
                continue
            if credited_in_vault(typ, side) == "home":
                have_home += 1
            else:
                have_away += 1

        # 1. Name what the vault holds but could not attribute. Done first, so a
        #    match that later proves unalignable still gets its names.
        for ev_id, tid, pid, minute, typ in existing:
            if pid is not None or minute is None:
                continue
            side = "home" if tid == home_id else "away" if tid == away_id else None
            if side is None:
                continue
            want_side = credited_in_vault(typ, side)
            # Sources routinely differ by a minute on the same goal, so an exact
            # match is too strict. The TYPE must agree though: FotMob calling it
            # an own goal where the vault has a plain goal is a different fact,
            # not a missing name.
            hits = [g for g in incoming
                    if g["side"] == want_side and g.get("name") and g["type"] == typ
                    and g.get("minute") is not None and abs(g["minute"] - minute) <= 2]
            if len(hits) != 1:
                self.stats["unnamed events FotMob could not settle"] += 1
                self.notes.append(
                    f"match {mid}: {typ} credited to {want_side} at {minute}' -- "
                    f"{len(hits)} FotMob goals match it")
                continue
            g = hits[0]
            team_for_player = home_id if scorer_side(g) == "home" else away_id
            new_pid = self.player(g["name"], team_for_player)
            if new_pid is None:
                continue
            self.c.execute("""
                INSERT INTO reconciliation_diffs
                  (reconciliation_run_id, entity_id_a, entity_id_b, field_name,
                   value_a, value_b, resolution, resolved_value, resolved_at)
                VALUES (%s, %s, %s, 'match_events.player_id', 'no scorer', %s, 'ACCEPT_B', %s, now())
            """, (run_id, ev_id, mid, f"{g['name']} at {g['minute']}' (FotMob)", str(new_pid)))
            self.c.execute("UPDATE match_events SET player_id = %s WHERE id = %s", (new_pid, ev_id))
            self.stats["unnamed goals given a scorer"] += 1

        # 2. Same number of goals, wrong sides. Re-siding needs the two lists to
        #    line up, and they only do when the vault's events carry minutes to
        #    line up BY. Pairing by position would scramble the scorers, so
        #    report rather than guess.
        if len(existing) == len(incoming) and (have_home, have_away) != (want_home, want_away):
            ok = all(minute is not None for _i, _t, _p, minute, _ty in existing)
            by_minute = {}
            if ok:
                for ev in existing:
                    by_minute.setdefault(ev[3], []).append(ev)
                ok = all(len(by_minute.get(g.get("minute"), [])) == 1 for g in incoming)
            if not ok:
                self.stats["left for review, sides differ and cannot be aligned"] += 1
                self.notes.append(
                    f"match {mid}: {len(existing)} events on the wrong sides, and the vault's "
                    f"minutes do not line up with FotMob's -- not re-sided")
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
                          f"team {right}, {g['type']} (FotMob)", str(right)))
                    self.c.execute("UPDATE match_events SET team_id = %s, type = %s WHERE id = %s",
                                   (right, g["type"], ev_id))
                    self.stats["events re-sided"] += 1
            self.stats["matches corrected"] += 1
            return

        # 3. Fill the shortfall, per side, taking FotMob's goals for that side in
        #    order and skipping as many as the vault already holds.
        added = 0
        for side, want_n, have_n in (("home", want_home, have_home), ("away", want_away, have_away)):
            short = want_n - have_n
            if short <= 0:
                continue
            mine = [g for g in incoming if g["side"] == side]
            for g in mine[len(mine) - short:]:
                team_id = home_id if scorer_side(g) == "home" else away_id
                pid = self.player(g.get("name"), team_id)
                self.c.execute("""
                    INSERT INTO match_events (match_id, team_id, player_id, minute, added_time, type)
                    VALUES (%s, %s, %s, %s, %s, %s) RETURNING id
                """, (mid, team_id, pid, g.get("minute"), g.get("added"), g["type"]))
                ev_id = self.c.fetchone()[0]
                self.c.execute("""
                    INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
                    VALUES ('match_event', %s, %s, %s, 1.0)
                    ON CONFLICT (entity_type, data_source_id, external_id) DO NOTHING
                """, (ev_id, self.source_id,
                      f"fotmob-{rec.get('fotmob', mid)}-{g['side']}-{g.get('minute')}-"
                      f"{g.get('added') or 0}-{g['type']}"))
                self.stats[f"goals added ({g['type']})"] += 1
                if pid is None:
                    self.stats["goals added with no scorer named"] += 1
                added += 1
        self.stats["matches completed" if added else "matches already complete"] += 1


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


def main(path, season, commit):
    staged = json.load(open(path))
    conn = psycopg2.connect(DSN)
    conn.autocommit = False
    cur = conn.cursor()
    cur.execute("SET timezone = 'UTC'")
    cur.execute("""
        INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
        VALUES ('match_event',
                (SELECT id FROM data_sources WHERE name='ligikuu'),
                (SELECT id FROM data_sources WHERE name='fotmob'),
                %s) RETURNING id
    """, (f"Premier League {season}: goal logs completed from FotMob, for matches the vault "
          f"held short of or wrongly against their stored score.",))
    run_id = cur.fetchone()[0]

    loader = Loader(conn)
    for rec in staged:
        loader.do_match(rec, run_id)

    print(f"{len(staged)} matches in the harvest")
    for k in sorted(loader.stats):
        print(f"  {k}: {loader.stats[k]}")
    if loader.notes:
        print(f"\nnotes ({len(loader.notes)}):")
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
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    main(sys.argv[1], sys.argv[2], "--commit" in sys.argv)
