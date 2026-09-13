#!/usr/bin/env python3
"""Load canonical match records into the vault.

Reads the canonical files produced by `normalize_ligikuu.py` and
`normalize_whoscored.py`, merges them into one record per fixture, and writes
matches, events, lineups, teams, players, stadiums and edition participants --
each with its `entity_source_map` provenance, per design principle 1.

Two rules from the schema doc are enforced here rather than assumed:

* **Nothing canonical is overwritten silently** (principle 2). A season already
  in the vault is skipped entirely; within a new season, where the two sources
  disagree the record is written from the preferred source and the
  disagreement is recorded in `reconciliation_diffs`.
* **An OWN_GOAL's team is the scoring player's own team** (principle 5). The
  official site only sometimes files them that way, so normalize_ligikuu.py's
  orient_own_goals() settles each match on its score before anything reaches
  here; own goals then load unchanged and are credited on the read side.

Usage:
    python3 load.py <canon_ligikuu.json> <canon_whoscored.json> [--commit]

Without --commit it runs the whole thing in a transaction and rolls back,
printing exactly what it would have done.
"""
import json
import re
import sys
import unicodedata
from collections import defaultdict

import psycopg2
import psycopg2.extras

sys.path.insert(0, __file__.rsplit("/", 1)[0])
from teamnames import canonical, key as team_key  # noqa: E402

DSN = "postgresql://michaelkimollo@127.0.0.1:5432/sokabrain"

TANZANIA = 56          # countries.id
TPL_COMPETITION = 1    # competitions.id -- 'Premier League', tier 1, Tanzania

# Seasons already reconciled from the legacy migration; never touched here.
ALREADY_IN_VAULT = {"2017/2018", "2018/2019", "2019/2020"}

# SportsPress position taxonomy ids -> the vault's position codes.
POSITION = {"3": "GK", "4": "DF", "5": "MF", "6": "FW"}

# Which source wins when both describe the same fixture. The official league
# site is authoritative for the seasons it covers; WhoScored is the only source
# for the early ones.
PREFERRED = "ligikuu"


def norm_person(name):
    s = unicodedata.normalize("NFKD", str(name or ""))
    s = "".join(c for c in s if not unicodedata.combining(c))
    s = re.sub(r"[^a-z ]+", " ", s.lower())
    return re.sub(r"\s+", " ", s).strip()


def season_label(s):
    """'2023/24' and '2023/2024' both become '2023/2024', the vault's form."""
    m = re.match(r"^(\d{4})/(\d{2,4})$", s.strip())
    if not m:
        return s.strip()
    a, b = m.group(1), m.group(2)
    return f"{a}/{b if len(b) == 4 else a[:2] + b}"


class Loader:
    def __init__(self, conn, commit):
        self.c = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        self.commit = commit
        self.stats = defaultdict(int)
        self.diffs = []

    # ---------- small helpers -------------------------------------------------

    def one(self, sql, args=()):
        self.c.execute(sql, args)
        r = self.c.fetchone()
        return r[0] if r else None

    def source_id(self, name, type_, url):
        got = self.one("SELECT id FROM data_sources WHERE name=%s", (name,))
        if got:
            return got
        self.stats["data_sources created"] += 1
        return self.one(
            "INSERT INTO data_sources (name, type, base_url) VALUES (%s,%s,%s) RETURNING id",
            (name, type_, url))

    def provenance(self, entity_type, entity_id, source_id, external_id, url=None):
        """Principle 1: every externally-sourced row is traceable to its source."""
        self.c.execute(
            """INSERT INTO entity_source_map
                   (entity_type, entity_id, data_source_id, external_id, external_url)
               VALUES (%s,%s,%s,%s,%s)
               ON CONFLICT (entity_type, data_source_id, external_id) DO NOTHING""",
            (entity_type, entity_id, source_id, str(external_id), url))

    # ---------- reference data ------------------------------------------------

    def load_existing_teams(self):
        self.c.execute("SELECT id, name FROM teams WHERE country_id=%s", (TANZANIA,))
        self.teams = {}
        for r in self.c.fetchall():
            self.teams.setdefault(team_key(r["name"]), r["id"])

    def team(self, name, source_id, external_id):
        k = team_key(name)
        if k not in self.teams:
            canon = canonical(name)
            tid = self.one(
                """INSERT INTO teams (name, type, country_id) VALUES (%s,'CLUB',%s)
                   ON CONFLICT (name, country_id) DO UPDATE SET name=EXCLUDED.name
                   RETURNING id""", (canon, TANZANIA))
            self.teams[k] = tid
            self.stats["teams created"] += 1
            self.created_teams.append(canon)
        tid = self.teams[k]
        if external_id is not None:
            self.provenance("team", tid, source_id, external_id)
        return tid

    def load_existing_players(self):
        self.c.execute("SELECT id, full_name FROM players")
        self.players = {}
        for r in self.c.fetchall():
            self.players.setdefault(norm_person(r["full_name"]), r["id"])

    def player(self, name, source_id, external_id, position=None):
        if not name:
            return None
        k = norm_person(name)
        if not k:
            return None
        if k not in self.players:
            parts = str(name).split()
            pid = self.one(
                """INSERT INTO players (full_name, first_name, last_name, nationality_id, position)
                   VALUES (%s,%s,%s,%s,%s) RETURNING id""",
                (name.strip(), parts[0] if parts else None,
                 parts[-1] if len(parts) > 1 else None, TANZANIA, position))
            self.players[k] = pid
            self.stats["players created"] += 1
        pid = self.players[k]
        if external_id is not None:
            self.provenance("player", pid, source_id, external_id)
        return pid

    def stadium(self, name):
        if not name:
            return None
        if name in self.stadiums:
            return self.stadiums[name]
        sid = self.one("SELECT id FROM stadiums WHERE lower(name)=lower(%s)", (name,))
        if not sid:
            sid = self.one(
                "INSERT INTO stadiums (name, country_id) VALUES (%s,%s) RETURNING id",
                (name, TANZANIA))
            self.stats["stadiums created"] += 1
        self.stadiums[name] = sid
        return sid

    def season(self, label):
        sid = self.one("SELECT id FROM seasons WHERE label=%s", (label,))
        if not sid:
            sid = self.one("INSERT INTO seasons (label) VALUES (%s) RETURNING id", (label,))
            self.stats["seasons created"] += 1
        return sid

    def edition(self, season_id, num_teams):
        eid = self.one(
            "SELECT id FROM competition_editions WHERE competition_id=%s AND season_id=%s",
            (TPL_COMPETITION, season_id))
        if not eid:
            eid = self.one(
                """INSERT INTO competition_editions
                       (competition_id, season_id, host_country_id, format, num_teams, is_published)
                   VALUES (%s,%s,%s,'ROUND_ROBIN',%s,FALSE) RETURNING id""",
                (TPL_COMPETITION, season_id, TANZANIA, num_teams))
            self.stats["editions created"] += 1
        return eid

    # ---------- the load ------------------------------------------------------

    def run(self, ligikuu_rows, whoscored_rows):
        self.src = {
            "ligikuu": self.source_id("ligikuu", "SCRAPED", "https://ligikuu.co.tz"),
            "whoscored": self.source_id("whoscored", "SCRAPED", "https://www.whoscored.com"),
        }
        self.load_existing_teams()
        self.load_existing_players()
        self.stadiums = {}
        self.created_teams = []
        self.match_of_fixture = {}
        self.stints = {}

        merged = self.merge(ligikuu_rows, whoscored_rows)

        by_season = defaultdict(list)
        for rec in merged:
            by_season[rec["season"]].append(rec)

        for label in sorted(by_season):
            if label in ALREADY_IN_VAULT:
                self.stats["seasons skipped (already reconciled)"] += 1
                continue
            self.load_season(label, by_season[label])

        self.write_stints()
        self.record_reconciliation()

    def merge(self, ligikuu_rows, whoscored_rows):
        """One record per fixture, with the preferred source's values.

        Fixtures are keyed on (season, home, away) after canonicalising club
        names, so the two sources join even though they spell clubs
        differently. Disagreements are collected, never silently resolved.
        """
        buckets = defaultdict(dict)
        for rows in (whoscored_rows, ligikuu_rows):
            for r in rows:
                label = season_label(r["season"])
                k = (label, team_key(r["home_name"]), team_key(r["away_name"]))
                # A source can list the same fixture twice; keep the one that
                # has a score, else the first seen.
                cur = buckets[k].get(r["source"])
                if cur is None or (cur["home_score"] is None and r["home_score"] is not None):
                    buckets[k][r["source"]] = dict(r, season=label)

        out = []
        for (label, hk, ak), bysrc in buckets.items():
            pref = bysrc.get(PREFERRED) or next(iter(bysrc.values()))
            other = next((v for s, v in bysrc.items() if v is not pref), None)

            rec = dict(pref)
            rec["season"] = label
            rec["sources"] = {s: v["source_match_id"] for s, v in bysrc.items()}
            rec["source_urls"] = {s: v.get("source_url") for s, v in bysrc.items()}

            # Fall back to the other source for anything the preferred one lacks.
            if other:
                if rec["home_score"] is None and other["home_score"] is not None:
                    rec["home_score"], rec["away_score"] = other["home_score"], other["away_score"]
                    rec["status"] = other["status"]
                if not rec.get("kickoff_utc"):
                    rec["kickoff_utc"] = other.get("kickoff_utc")
                if not rec.get("lineups"):
                    rec["lineups"] = other.get("lineups") or []
                if not rec.get("events"):
                    rec["events"] = other.get("events") or []

                # Principle 2: disagreements are recorded, not resolved away.
                if (other["home_score"] is not None and pref["home_score"] is not None
                        and (other["home_score"], other["away_score"])
                        != (pref["home_score"], pref["away_score"])):
                    self.diffs.append(((label, hk, ak), "score",
                                       f'{pref["home_score"]}-{pref["away_score"]}',
                                       f'{other["home_score"]}-{other["away_score"]}'))
                if pref.get("kickoff_utc") and other.get("kickoff_utc"):
                    if pref["kickoff_utc"][:10] != other["kickoff_utc"][:10]:
                        self.diffs.append(((label, hk, ak), "kickoff_date",
                                           pref["kickoff_utc"][:10], other["kickoff_utc"][:10]))
            out.append(rec)
        return out

    def load_season(self, label, records):
        clubs = {team_key(r["home_name"]) for r in records} | {team_key(r["away_name"]) for r in records}
        season_id = self.season(label)
        edition_id = self.edition(season_id, len(clubs))

        dates = sorted(r["kickoff_utc"][:10] for r in records if r.get("kickoff_utc"))
        if dates:
            self.c.execute(
                """UPDATE seasons SET start_date = coalesce(start_date, %s),
                                      end_date   = coalesce(end_date, %s)
                    WHERE id = %s""", (dates[0], dates[-1], season_id))

        # Never write a second copy of a season that already has matches.
        existing = self.one("SELECT count(*) FROM matches WHERE competition_edition_id=%s", (edition_id,))
        if existing:
            self.stats["seasons skipped (edition already populated)"] += 1
            return

        team_ids = {}
        for r in records:
            for side in ("home", "away"):
                nm = r[f"{side}_name"]
                k = team_key(nm)
                if k not in team_ids:
                    ext = r.get(f"{side}_source_id") if r["source"] == "ligikuu" else None
                    team_ids[k] = self.team(nm, self.src[r["source"]], ext)

        for k, tid in team_ids.items():
            self.c.execute(
                """INSERT INTO competition_edition_teams (competition_edition_id, team_id)
                   VALUES (%s,%s) ON CONFLICT DO NOTHING""", (edition_id, tid))
            self.stats["edition participants"] += 1

        for r in records:
            self.load_match(edition_id, r, team_ids)
        self.stats[f"season {label}"] += len(records)

        # Every season of this league is a double round robin, so a shortfall
        # against that is missing data rather than a shorter season. Say so, in
        # the place an editor will look, instead of leaving a quietly thin table.
        expected = len(clubs) * (len(clubs) - 1)
        if len(records) < expected:
            self.c.execute(
                """INSERT INTO data_flags (entity_type, entity_id, severity, reason)
                   VALUES ('competition_edition', %s, 'WARNING', %s)""",
                (edition_id,
                 f"Only {len(records)} of the {expected} fixtures a {len(clubs)}-team double "
                 f"round robin implies. Neither ligikuu.co.tz nor whoscored.com lists the "
                 f"other {expected - len(records)}; the season is incomplete in both sources, "
                 f"not merely unscored."))
            self.stats["incomplete-season flags"] += 1

    def load_match(self, edition_id, r, team_ids):
        home = team_ids[team_key(r["home_name"])]
        away = team_ids[team_key(r["away_name"])]
        match_id = self.one(
            """INSERT INTO matches
                   (competition_edition_id, home_team_id, away_team_id, stadium_id,
                    kickoff_at, status, home_score, away_score)
               VALUES (%s,%s,%s,%s,%s,%s,%s,%s) RETURNING id""",
            (edition_id, home, away, self.stadium(r.get("venue")),
             (r["kickoff_utc"] + "+00") if r.get("kickoff_utc") else None,
             r["status"], r["home_score"], r["away_score"]))
        self.stats["matches created"] += 1
        self.match_of_fixture[(r["season"], team_key(r["home_name"]), team_key(r["away_name"]))] = match_id

        for src, ext in r["sources"].items():
            self.provenance("match", match_id, self.src[src], ext, r["source_urls"].get(src))

        side_team = {"home": home, "away": away}

        # NOT written as match_lineups. The official site records a performance
        # row only for players who did something -- about four a match, never a
        # full eleven -- so these are not lineups, and storing them as such
        # would invent appearances that never happened and corrupt every
        # per-appearance statistic (principle 6). What they do establish is
        # which club a player turned out for, which is a stint.
        for ln in r.get("lineups") or []:
            pid = self.player(ln["player_name"], self.src["ligikuu"], ln.get("player_source_id"))
            if not pid or not r.get("kickoff_utc"):
                continue
            self.note_stint(pid, side_team[ln["side"]], r["kickoff_utc"][:10],
                            ln.get("shirt_number"))

        for ev in r.get("events") or []:
            pid = self.player(ev.get("player_name"), self.src["ligikuu"], ev.get("player_source_id"))
            self.c.execute(
                """INSERT INTO match_events
                       (match_id, team_id, player_id, minute, added_time, type, detail)
                   VALUES (%s,%s,%s,%s,%s,%s,%s)""",
                (match_id, side_team[ev["side"]], pid, ev.get("minute"), ev.get("added_time"),
                 ev["type"], psycopg2.extras.Json({"source": "ligikuu"})))
            self.stats["match events"] += 1
            if pid and r.get("kickoff_utc"):
                self.note_stint(pid, side_team[ev["side"]], r["kickoff_utc"][:10], None)

    def note_stint(self, player_id, team_id, date, shirt_number):
        """Remember that this player turned out for this club on this date.

        Written up at the end as one `player_team_stints` row per player/club,
        spanning the first and last date we saw them play. That is a floor on
        the real spell, not a transfer record -- the sources carry no transfer
        dates -- so it is only ever as wide as the evidence.
        """
        k = (player_id, team_id)
        cur = self.stints.get(k)
        number = int(shirt_number) if str(shirt_number or "").isdigit() else None
        if cur is None:
            self.stints[k] = [date, date, number]
        else:
            cur[0] = min(cur[0], date)
            cur[1] = max(cur[1], date)
            cur[2] = cur[2] or number

    def write_stints(self):
        for (player_id, team_id), (start, end, number) in self.stints.items():
            existing = self.one(
                """SELECT id FROM player_team_stints
                    WHERE player_id=%s AND team_id=%s
                      AND coalesce(start_date, %s) <= %s AND coalesce(end_date, %s) >= %s""",
                (player_id, team_id, start, end, end, start))
            if existing:
                self.stats["stints already recorded"] += 1
                continue
            self.c.execute(
                """INSERT INTO player_team_stints
                       (player_id, team_id, start_date, end_date, shirt_number)
                   VALUES (%s,%s,%s,%s,%s)""",
                (player_id, team_id, start, end, number))
            self.stats["player-club stints"] += 1

    def record_reconciliation(self):
        if not self.diffs:
            self.stats["source disagreements"] = 0
            return
        run_id = self.one(
            """INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
               VALUES ('match', %s, %s, %s) RETURNING id""",
            (self.src["ligikuu"], self.src["whoscored"],
             "TPL 2020/21-2026/27, ligikuu.co.tz (official, SportsPress REST API) against "
             "whoscored.com. Fixtures joined on (season, canonical home, canonical away). "
             "The official site wins where both carry a value; every disagreement is recorded "
             "here rather than resolved silently."))
        written = 0
        for fixture, field, a, b in self.diffs:
            # A diff on a season that was skipped has no match row to hang off;
            # it is still recorded, just without the link.
            self.c.execute(
                """INSERT INTO reconciliation_diffs
                       (reconciliation_run_id, entity_id_a, field_name, value_a, value_b, resolution)
                   VALUES (%s,%s,%s,%s,%s,'ACCEPT_A')""",
                (run_id, self.match_of_fixture.get(fixture), field, a, b))
            written += 1
        self.stats["source disagreements recorded"] = written


def main():
    lig = json.load(open(sys.argv[1]))
    who = json.load(open(sys.argv[2]))
    commit = "--commit" in sys.argv

    conn = psycopg2.connect(DSN)
    loader = Loader(conn, commit)
    try:
        loader.run(lig, who)
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
        for k in sorted(loader.stats):
            print(f"  {k:<45} {loader.stats[k]}")
        if loader.created_teams:
            print("\n  new clubs: " + ", ".join(sorted(loader.created_teams)))
        conn.close()


if __name__ == "__main__":
    main()
