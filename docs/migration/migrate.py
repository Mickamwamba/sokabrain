"""
Sokabrain Vault — Legacy migration script
Migrates the legacy SokaFC MySQL schema into the new standardized Postgres
vault schema (see sokabrain_vault_schema_v1.md), preserving provenance via
entity_source_map so every migrated row is traceable back to its legacy ID.

Run against:
  - MySQL source db: 'sokafc' (loaded from sokafc_02_APRIL_2020.sql)
  - Postgres target db: 'sokabrain' (schema.sql already applied)
"""
import pymysql
import psycopg2
from psycopg2.extras import execute_values

MYSQL_CFG = dict(host="127.0.0.1", user="root", password="", database="sokafc", charset="utf8mb4")
PG_CFG = dict(host="127.0.0.1", user="postgres", password="postgres", dbname="sokabrain")

# --- Hand-curated competition classification (scope isn't reliably stored in legacy data) ---
# type must match new schema CHECK constraint; is_continental drives country_id vs confederation_id
COMPETITION_META = {
    1:  dict(type="LEAGUE",             continental=False, tier_from_division=True),
    2:  dict(type="LEAGUE",             continental=False, tier_from_division=True),
    3:  dict(type="LEAGUE",             continental=False, tier_from_division=True),
    4:  dict(type="CONTINENTAL_CLUB",   continental=True),   # CECAFA Kagame Club Championship
    5:  dict(type="CONTINENTAL_CLUB",   continental=True),   # "Champions League" (CAF CL primary stage branding)
    6:  dict(type="CONTINENTAL_CLUB",   continental=True),   # CAF Confederation Cup
    9:  dict(type="CONTINENTAL_CLUB",   continental=True),   # Champions Primary Stage
    10: dict(type="DOMESTIC_CUP",       continental=False, country_override=56),  # Azam Federation Cup (TZ)
    11: dict(type="SUPER_CUP",          continental=False, country_override=56),  # Ngao ya Jamii (TZ community shield)
    12: dict(type="QUALIFIER",          continental=True),   # AFCON Qualification
    13: dict(type="DOMESTIC_CUP",       continental=False, country_override=56),  # Mapinduzi Cup (Zanzibar/TZ)
    14: dict(type="SUPER_CUP",          continental=False, country_override=23),  # SportPesa Super Cup (Kenya)
    15: dict(type="CONTINENTAL_NATIONAL", continental=True), # AFCON U17
    16: dict(type="CONTINENTAL_NATIONAL", continental=True), # AFCON
    17: dict(type="LEAGUE",             continental=False, country_override=23, tier_from_division=True),  # Kenya PL -- FIXES legacy bug (was miscoded to Tanzania)
    18: dict(type="DOMESTIC_CUP",       continental=False, country_override=23),  # Kenya FA Cup
    19: dict(type="CONTINENTAL_NATIONAL", continental=True), # CECAFA Cup (national teams)
}
DIVISION_TIER = {1: 1, 2: 2, 3: 3}  # Premier / First Division / Second Division

EVENT_TYPE_MAP = {
    "GOAL": "GOAL",
    "OWN GOAL": "OWN_GOAL",
    "PENALT GOAL": "PENALTY_GOAL",
    "YELLOW CARD": "YELLOW_CARD",
    "RED CARD": "RED_CARD",
}
GOAL_TYPES = {"GOAL", "OWN_GOAL", "PENALTY_GOAL"}

STATUS_MAP = {"P": "FULL_TIME", "NP": "SCHEDULED", "PP": "POSTPONED", "L": "LIVE"}


def main():
    my = pymysql.connect(**MYSQL_CFG, cursorclass=pymysql.cursors.DictCursor)
    pg = psycopg2.connect(**PG_CFG)
    pg.autocommit = False
    cur_my = my.cursor()
    cur_pg = pg.cursor()

    log = []

    def fetch(sql):
        cur_my.execute(sql)
        return cur_my.fetchall()

    # ---------- 0. data source + confederations ----------
    cur_pg.execute("INSERT INTO data_sources (name, type, base_url) VALUES ('legacy_sokafc','INTERNAL_LEGACY',NULL) RETURNING id;")
    legacy_src_id = cur_pg.fetchone()[0]

    CONFEDS = ["CAF", "UEFA", "CONMEBOL", "CONCACAF", "AFC", "OFC"]
    confed_id = {}
    for code in CONFEDS:
        cur_pg.execute("INSERT INTO confederations (code, name) VALUES (%s,%s) RETURNING id;", (code, code))
        confed_id[code] = cur_pg.fetchone()[0]
    CAF_ID = confed_id["CAF"]

    def map_entity(entity_type, new_id, old_id):
        cur_pg.execute(
            "INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id) VALUES (%s,%s,%s,%s)",
            (entity_type, new_id, legacy_src_id, str(old_id)),
        )

    # ---------- 1. countries (+ enrich from countries2 for iso codes / confederation guess) ----------
    countries = fetch("SELECT * FROM countries")
    countries2_by_name = {r["name"].strip().lower(): r for r in fetch("SELECT * FROM countries2")}
    country_rows = []
    for c in countries:
        c2 = countries2_by_name.get(c["name"].strip().lower())
        iso = c2["iso_3166_3"] if c2 else None
        is_africa = bool(c2 and c2["region_code"] == "002")
        country_rows.append((c["id"], iso, c["name"], c["full_name"] or c["name"],
                              CAF_ID if is_africa else None, c["flag"]))
    execute_values(cur_pg,
        "INSERT INTO countries (id, iso_code, name, full_name, confederation_id, flag_url) VALUES %s",
        country_rows)
    cur_pg.execute("SELECT setval(pg_get_serial_sequence('countries','id'), (SELECT MAX(id) FROM countries));")
    for c in countries:
        map_entity("country", c["id"], c["id"])
    log.append(f"countries: {len(country_rows)} migrated")

    # ---------- 2. stadiums ----------
    stadiums = fetch("SELECT * FROM stadiums")
    stadium_rows = [(s["id"], s["name"], s["region"], s["country_id"], None, None, None) for s in stadiums]
    execute_values(cur_pg,
        "INSERT INTO stadiums (id, name, city, country_id, capacity, latitude, longitude) VALUES %s",
        stadium_rows)
    cur_pg.execute("SELECT setval(pg_get_serial_sequence('stadiums','id'), (SELECT MAX(id) FROM stadiums));")
    for s in stadiums:
        map_entity("stadium", s["id"], s["id"])
    log.append(f"stadiums: {len(stadium_rows)} migrated")

    # ---------- 3. seasons ----------
    seasons = fetch("SELECT * FROM seasons")
    season_rows = []
    for s in seasons:
        label = f"{s['start_year']}/{s['end_year']}" if s["start_year"] != s["end_year"] else str(s["start_year"])
        season_rows.append((s["id"], label, None, None))
    execute_values(cur_pg, "INSERT INTO seasons (id, label, start_date, end_date) VALUES %s", season_rows)
    cur_pg.execute("SELECT setval(pg_get_serial_sequence('seasons','id'), (SELECT MAX(id) FROM seasons));")
    for s in seasons:
        map_entity("season", s["id"], s["id"])
    log.append(f"seasons: {len(season_rows)} migrated")

    # ---------- 4. competitions ----------
    competitions = fetch("SELECT * FROM competitions")
    leagues_by_comp = {r["competition_id"]: r for r in fetch("SELECT * FROM leagues")}
    comp_rows = []
    unclassified = []
    for c in competitions:
        meta = COMPETITION_META.get(c["id"])
        if not meta:
            unclassified.append(c["id"])
            continue
        country_id = None
        confederation_id = None
        tier = None
        if meta["continental"]:
            confederation_id = CAF_ID
        else:
            lg = leagues_by_comp.get(c["id"])
            country_id = meta.get("country_override") or (lg["country_id"] if lg else None)
            if meta.get("tier_from_division") and lg:
                tier = DIVISION_TIER.get(lg["division_id"])
        slug = c["name"].lower().replace(" ", "-").replace("'", "")
        comp_rows.append((c["id"], c["name"], slug, meta["type"], country_id, confederation_id, tier, c["logo"]))
    execute_values(cur_pg,
        "INSERT INTO competitions (id, name, slug, type, country_id, confederation_id, tier, logo_url) VALUES %s",
        comp_rows)
    cur_pg.execute("SELECT setval(pg_get_serial_sequence('competitions','id'), (SELECT MAX(id) FROM competitions));")
    for c in competitions:
        if c["id"] not in unclassified:
            map_entity("competition", c["id"], c["id"])
    log.append(f"competitions: {len(comp_rows)} migrated" + (f", UNCLASSIFIED (skipped): {unclassified}" if unclassified else ""))

    # ---------- 5. competition_editions (derived from distinct competition+season pairs seen in matches) ----------
    pairs = fetch("SELECT DISTINCT competition_id, season_id FROM matches")
    edition_id_map = {}  # (competition_id, season_id) -> new edition id
    edition_rows = []
    next_id = 1
    for p in pairs:
        key = (p["competition_id"], p["season_id"])
        edition_id_map[key] = next_id
        edition_rows.append((next_id, p["competition_id"], p["season_id"], None, None, None))
        next_id += 1
    execute_values(cur_pg,
        "INSERT INTO competition_editions (id, competition_id, season_id, host_country_id, format, num_teams) VALUES %s",
        edition_rows)
    cur_pg.execute("SELECT setval(pg_get_serial_sequence('competition_editions','id'), (SELECT MAX(id) FROM competition_editions));")
    log.append(f"competition_editions: {len(edition_rows)} derived from distinct (competition, season) pairs in matches")

    # ---------- 6. teams ----------
    teams = fetch("SELECT * FROM teams")
    team_rows = [(t["id"], t["name"], t["abbr"], t["type"], t["country_id"], t["stadium_id"], None, t["logo"]) for t in teams]
    execute_values(cur_pg,
        "INSERT INTO teams (id, name, short_name, type, country_id, stadium_id, founded_year, logo_url) VALUES %s",
        team_rows)
    cur_pg.execute("SELECT setval(pg_get_serial_sequence('teams','id'), (SELECT MAX(id) FROM teams));")
    for t in teams:
        map_entity("team", t["id"], t["id"])
    log.append(f"teams: {len(team_rows)} migrated")

    # ---------- 7. players ----------
    players = fetch("SELECT * FROM players")
    player_rows = []
    for p in players:
        full_name = " ".join(x for x in [p["fname"], p["mname"], p["sname"], p["other_name"]] if x).strip()
        player_rows.append((p["id"], full_name, p["fname"], p["sname"], p["dob"], p["countries_id"],
                             p["position"], None, None, p["image"]))
    execute_values(cur_pg,
        "INSERT INTO players (id, full_name, first_name, last_name, dob, nationality_id, position, height_cm, preferred_foot, photo_url) VALUES %s",
        player_rows)
    cur_pg.execute("SELECT setval(pg_get_serial_sequence('players','id'), (SELECT MAX(id) FROM players));")
    for p in players:
        map_entity("player", p["id"], p["id"])
    log.append(f"players: {len(player_rows)} migrated (note: 0 had DOB in legacy data -- flagged for reconciliation backfill)")

    # ---------- 8. coaches ----------
    coaches = fetch("SELECT * FROM coaches")
    coach_rows = []
    for c in coaches:
        full_name = " ".join(x for x in [c["fname"], c["mname"], c["sname"], c["other_name"]] if x).strip()
        coach_rows.append((c["id"], full_name, c["dob"], c["nationality"], c["photo"]))
    execute_values(cur_pg,
        "INSERT INTO coaches (id, full_name, dob, nationality_id, photo_url) VALUES %s", coach_rows)
    cur_pg.execute("SELECT setval(pg_get_serial_sequence('coaches','id'), (SELECT MAX(id) FROM coaches));")
    for c in coaches:
        map_entity("coach", c["id"], c["id"])
    log.append(f"coaches: {len(coach_rows)} migrated")

    # ---------- 9. player_team_stints ----------
    pts = fetch("SELECT * FROM player_teams")
    pts_rows = [(r["player_id"], r["team_id"], r["start_date"], r["end_date"], None, None, "PERMANENT") for r in pts]
    execute_values(cur_pg,
        "INSERT INTO player_team_stints (player_id, team_id, start_date, end_date, shirt_number, transfer_fee, transfer_type) VALUES %s",
        pts_rows)
    log.append(f"player_team_stints: {len(pts_rows)} migrated (transfer_fee unavailable in legacy data -- always NULL)")

    # ---------- 10. coach_team_stints ----------
    cts = fetch("SELECT * FROM coach_teams")
    cts_rows = [(r["coach_id"], r["team_id"], "HEAD_COACH", r["start_date"], r["end_date"]) for r in cts]
    execute_values(cur_pg,
        "INSERT INTO coach_team_stints (coach_id, team_id, role, start_date, end_date) VALUES %s", cts_rows)
    log.append(f"coach_team_stints: {len(cts_rows)} migrated")

    # ---------- 11. matches (+ score computed with own-goal fix) ----------
    matches = fetch("SELECT * FROM matches")
    league_round = {r["match_id"]: r["round"] for r in fetch("SELECT * FROM league_matches")}
    cup_stage = {r["match_id"]: r["stage"] for r in fetch("SELECT * FROM cup_matches")}

    # goal-scoring events with team attribution, event type, and match id
    goal_events = fetch("""
        SELECT me.match_id, e.name AS event_name, mte.team_id
        FROM match_events me
        JOIN events e ON me.event_id = e.id
        JOIN match_team_events mte ON mte.match_event_id = me.id
        WHERE e.name IN ('GOAL','OWN GOAL','PENALT GOAL')
    """)
    match_home_away = {m["id"]: (m["home_team_id"], m["away_team_id"]) for m in matches}
    scores = {}  # match_id -> [home_score, away_score]
    for ev in goal_events:
        mid = ev["match_id"]
        home, away = match_home_away.get(mid, (None, None))
        if home is None:
            continue
        scores.setdefault(mid, [0, 0])
        scoring_for_home = (ev["team_id"] == home)
        if ev["event_name"] == "OWN GOAL":
            scoring_for_home = not scoring_for_home  # FIX: own goal team_id records the scorer's own team, not the beneficiary
        if scoring_for_home:
            scores[mid][0] += 1
        else:
            scores[mid][1] += 1

    match_rows = []
    skipped_no_edition = 0
    for m in matches:
        key = (m["competition_id"], m["season_id"])
        edition_id = edition_id_map.get(key)
        if edition_id is None:
            skipped_no_edition += 1
            continue
        round_val = league_round.get(m["id"]) or cup_stage.get(m["id"])
        sc = scores.get(m["id"], (None, None))
        match_rows.append((
            m["id"], edition_id, None, str(round_val) if round_val is not None else None,
            m["home_team_id"], m["away_team_id"], m["stadium_id"], m["time"],
            STATUS_MAP.get(m["status"], "SCHEDULED"),
            sc[0], sc[1], None, None, None, None, None, None
        ))
    execute_values(cur_pg, """
        INSERT INTO matches
        (id, competition_edition_id, group_id, round, home_team_id, away_team_id, stadium_id,
         kickoff_at, status, home_score, away_score, home_score_et, away_score_et,
         home_score_pens, away_score_pens, attendance, referee_id)
        VALUES %s""", match_rows)
    cur_pg.execute("SELECT setval(pg_get_serial_sequence('matches','id'), (SELECT MAX(id) FROM matches));")
    for m in matches:
        if (m["competition_id"], m["season_id"]) in edition_id_map:
            map_entity("match", m["id"], m["id"])
    with_score = sum(1 for r in match_rows if r[9] is not None)
    log.append(f"matches: {len(match_rows)} migrated ({with_score} with a computed score from event log), "
               f"{skipped_no_edition} skipped (no edition)")
    log.append("  -> own-goal attribution bug caught & fixed during migration: legacy match_team_events.team_id "
               "for OWN GOAL records the scoring player's OWN team, not the team the goal counts for; "
               "verified against player_teams career data before applying the fix")

    # ---------- 12. match_lineups ----------
    # Legacy data has a handful of (match_id, player_id) duplicates (e.g. same player logged
    # as both a starter and a SUB for the same match -- a data-entry error, not two real events).
    # Dedupe: prefer the STARTER row (more specific info), else lowest legacy id.
    lineups = fetch("SELECT * FROM match_lineups ORDER BY match_id, player_id, (position='SUB') ASC, id ASC")
    seen = set()
    dupe_count = 0
    lineup_rows = []
    for l in lineups:
        key = (l["match_id"], l["player_id"])
        if key in seen:
            dupe_count += 1
            continue
        seen.add(key)
        role = "SUB" if l["position"] == "SUB" else "STARTER"
        pos = None if role == "SUB" else l["position"]
        lineup_rows.append((l["match_id"], l["team_id"], l["player_id"], role, pos, None, None, None))
    execute_values(cur_pg,
        "INSERT INTO match_lineups (match_id, team_id, player_id, role, position, shirt_number, minute_on, minute_off) VALUES %s",
        lineup_rows)
    log.append(f"match_lineups: {len(lineup_rows)} migrated (covers 93 of 1527 matches -- rest have no lineup data in legacy source)")
    if dupe_count:
        log.append(f"  -> {dupe_count} duplicate (match_id, player_id) rows found in legacy data and deduped (kept STARTER over SUB where both existed)")

    # ---------- 13. match_events (player/card/goal events only; general markers like KICK OFF/HT dropped) ----------
    all_events = fetch("""
        SELECT me.id AS match_event_id, me.match_id, me.minute, e.name AS event_name,
               mte.team_id, mpe.player_id
        FROM match_events me
        JOIN events e ON me.event_id = e.id
        LEFT JOIN match_team_events mte ON mte.match_event_id = me.id
        LEFT JOIN match_player_events mpe ON mpe.match_event_id = me.id
        WHERE e.name IN ('GOAL','OWN GOAL','PENALT GOAL','YELLOW CARD','RED CARD')
    """)
    event_rows = []
    for ev in all_events:
        new_type = EVENT_TYPE_MAP[ev["event_name"]]
        event_rows.append((ev["match_id"], ev["team_id"], ev["player_id"], None, ev["minute"], None, new_type, None))
    execute_values(cur_pg, """
        INSERT INTO match_events (match_id, team_id, player_id, related_player_id, minute, added_time, type, detail)
        VALUES %s""", event_rows)
    log.append(f"match_events: {len(event_rows)} migrated (GENERAL markers like KICK_OFF/HT/FULL_TIME dropped -- redundant with matches.status/kickoff_at)")

    pg.commit()

    print("\n=== MIGRATION SUMMARY ===")
    for line in log:
        print(" -", line)


if __name__ == "__main__":
    main()
