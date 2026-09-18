-- Four junk player names left by two parsers, and four duplicate scorers.
--
-- Found while loading 2020/21 from FotMob, which refused to name seven goals
-- because two players at the same club matched each name. Chasing those down
-- turned up a second thing: **four player records whose names are parser
-- output, not names.** Both kinds are settled here.
--
-- == The artifacts ==
--
-- `(pen)` is a MINUTE marker in RSSSF's Tanzanian pages, and two scorers kept
-- it as part of their name. This is the same defect CLAUDE.md records for the
-- pre-2002 AFCON load ("Emmanuel Kundé 55pen"); it was fixed there in
-- `parse_side` and went unnoticed in the Premier League pages.
--
--   11701  "Michael Sarpong (pen)"  Yanga SC, 2020/21 -- 11707 is the same man
--   11646  "Themi Felix (pen)"      Kagera Sugar, 2009/10 -- 11634 likewise
--
-- Each pair is one club, one season, and one source, split only by the suffix.
-- Each merges into the record with the clean name, and **the goal becomes a
-- PENALTY_GOAL**, which is what the marker said in the first place. That is a
-- fact recovered, not guessed: the suffix is the evidence.
--
-- `&#8217;` is an HTML right quote that ligikuu serves and the loader never
-- decoded, so two current players carry it in their names:
--
--   5003  "Ally Ng&#8217;anzi"        -> Ally Ng'anzi        (TRA United, 2025/26)
--   5095  "Richardson Ng&#8217;ondya" -> Richardson Ng'ondya (Geita Gold, 2026/27)
--
-- These are renames, not merges: no second record exists for either man. They
-- are the only two such names in the vault.
--
-- == The duplicates ==
--
-- Each is the pattern this vault has hit many times -- one club, no match in
-- common, seasons that do not overlap, two sources:
--
--   11695 "Lamine Moro"     RSSSF, Yanga 2020/21      -> 2571  (legacy, Yanga 2019/20)
--   11700 "Luis Miquissone" RSSSF, Simba 2020/21      -> 4627  (ligikuu, Simba 2023/24)
--   1701  "Derick Derick Musa" legacy, no events      -> 1700  (the same legacy name, twice)
--   11759 "Emmanuel Martin" RSSSF, Ruvu Shooting 2020/21 -> 975
--
-- Emmanuel Martin is the one with positive evidence rather than just absence
-- of conflict: **975 holds a Ruvu Shooting spell open since January 2019**, so
-- he was at that club in 2020/21, which is the only season and club 11759 has.
--
-- **Three more names stay ambiguous and their 2020/21 goals stay unattributed**:
-- Daniel Lyanga (two records at two clubs), Kelvin Sabato (five records, two of
-- them legacy junk like "Kelvin Sabato Sabato sabato"), and the Michael Sarpong
-- question is only settled because both records are one club in one season.
-- Guessing at the other two would move goals onto the wrong man.

BEGIN;

INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
VALUES ('player',
        (SELECT id FROM data_sources WHERE name = 'rsssf'),
        (SELECT id FROM data_sources WHERE name = 'fotmob'),
        'Four player names that were parser output rather than names -- two RSSSF "(pen)" minute markers and two undecoded ligikuu HTML entities -- plus four duplicate scorers blocking the 2020/21 FotMob load.');

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM players
   WHERE id IN (11701, 11707, 11646, 11634, 5003, 5095, 11695, 2571, 11700, 4627, 1701, 1700, 11759, 975);
  IF n <> 14 THEN RAISE EXCEPTION 'expected all 14 player records, found %', n; END IF;

  SELECT count(*) INTO n FROM players
   WHERE (id = 11701 AND full_name = 'Michael Sarpong (pen)')
      OR (id = 11646 AND full_name = 'Themi Felix (pen)')
      OR (id = 5003  AND full_name = 'Ally Ng&#8217;anzi')
      OR (id = 5095  AND full_name = 'Richardson Ng&#8217;ondya');
  IF n <> 4 THEN RAISE EXCEPTION 'the four artifact names are not in the expected state'; END IF;

  SELECT count(*) INTO n FROM match_events
   WHERE (id = 26914 AND player_id = 11701 AND type = 'GOAL')
      OR (id = 26803 AND player_id = 11646 AND type = 'GOAL');
  IF n <> 2 THEN RAISE EXCEPTION 'the two penalty events are not in the expected state'; END IF;

  -- No merged pair may share a match, or they are two people.
  SELECT count(*) INTO n FROM (
    SELECT match_id FROM match_events WHERE player_id = 11695
    INTERSECT SELECT match_id FROM match_events WHERE player_id = 2571
    UNION ALL
    SELECT match_id FROM match_events WHERE player_id = 11700
    INTERSECT SELECT match_id FROM match_events WHERE player_id = 4627
    UNION ALL
    SELECT match_id FROM match_events WHERE player_id = 11759
    INTERSECT SELECT match_id FROM match_events WHERE player_id = 975) x;
  IF n <> 0 THEN RAISE EXCEPTION 'a merged pair shares a match, so they are two people'; END IF;

  SELECT count(*) INTO n FROM player_team_stints s
    JOIN teams t ON t.id = s.team_id
   WHERE s.player_id = 975 AND t.name = 'Ruvu Shooting' AND s.end_date IS NULL;
  IF n <> 1 THEN RAISE EXCEPTION 'Emmanuel Martin (975) has no open Ruvu Shooting spell, which is the evidence for this merge'; END IF;
END $$;

/* -- 1. the two RSSSF "(pen)" artifacts ------------------------------------ */
INSERT INTO reconciliation_diffs (reconciliation_run_id, entity_id_a, entity_id_b, field_name, value_a, value_b, resolution, resolved_value, resolved_at)
VALUES (currval('reconciliation_runs_id_seq'), 26914, 16818, 'match_events.type',
        'GOAL by "Michael Sarpong (pen)"',
        'PENALTY_GOAL by Michael Sarpong -- "(pen)" is RSSSF''s minute marker, not part of the name',
        'MANUAL', 'PENALTY_GOAL', now()),
       (currval('reconciliation_runs_id_seq'), 26803, 15344, 'match_events.type',
        'GOAL by "Themi Felix (pen)"',
        'PENALTY_GOAL by Themi Felix -- same marker',
        'MANUAL', 'PENALTY_GOAL', now());

UPDATE match_events SET type = 'PENALTY_GOAL' WHERE id IN (26914, 26803);

/* -- 2. the two undecoded HTML entities ------------------------------------ */
INSERT INTO reconciliation_diffs (reconciliation_run_id, entity_id_a, entity_id_b, field_name, value_a, value_b, resolution, resolved_value, resolved_at)
VALUES (currval('reconciliation_runs_id_seq'), 5003, NULL, 'players.full_name',
        'Ally Ng&#8217;anzi', 'Ally Ng''anzi', 'MANUAL', 'Ally Ng''anzi', now()),
       (currval('reconciliation_runs_id_seq'), 5095, NULL, 'players.full_name',
        'Richardson Ng&#8217;ondya', 'Richardson Ng''ondya', 'MANUAL', 'Richardson Ng''ondya', now());

UPDATE players SET full_name = 'Ally Ng''anzi'        WHERE id = 5003;
UPDATE players SET full_name = 'Richardson Ng''ondya' WHERE id = 5095;

/* -- 3. the merges ---------------------------------------------------------- */
INSERT INTO reconciliation_diffs (reconciliation_run_id, entity_id_a, entity_id_b, field_name, value_a, value_b, resolution, resolved_value, resolved_at)
VALUES (currval('reconciliation_runs_id_seq'), 11701, 11707, 'players.id',
        'Michael Sarpong (pen) (11701)', 'Michael Sarpong (11707)', 'MANUAL', '11707', now()),
       (currval('reconciliation_runs_id_seq'), 11646, 11634, 'players.id',
        'Themi Felix (pen) (11646)', 'Themi Felix (11634)', 'MANUAL', '11634', now()),
       (currval('reconciliation_runs_id_seq'), 11695, 2571, 'players.id',
        'Lamine Moro (11695), Yanga 2020/21', 'Lamine Moro (2571), Yanga 2019/20', 'MANUAL', '2571', now()),
       (currval('reconciliation_runs_id_seq'), 11700, 4627, 'players.id',
        'Luis Miquissone (11700), Simba 2020/21', 'Luis Miquissone (4627), Simba 2023/24', 'MANUAL', '4627', now()),
       (currval('reconciliation_runs_id_seq'), 1701, 1700, 'players.id',
        'Derick Derick Musa (1701), no events', 'Derick Derick Musa (1700)', 'MANUAL', '1700', now()),
       (currval('reconciliation_runs_id_seq'), 11759, 975, 'players.id',
        'Emmanuel Martin (11759), Ruvu Shooting 2020/21',
        'Emmanuel Martin (975), whose Ruvu Shooting spell has been open since 2019-01-01',
        'MANUAL', '975', now());

DO $$
DECLARE pair record;
BEGIN
  FOR pair IN SELECT * FROM (VALUES
      (11701, 11707), (11646, 11634), (11695, 2571),
      (11700, 4627), (1701, 1700), (11759, 975)
  ) AS v(dead, keep) LOOP
    UPDATE match_events         SET player_id         = pair.keep WHERE player_id         = pair.dead;
    UPDATE match_events         SET related_player_id = pair.keep WHERE related_player_id = pair.dead;
    UPDATE match_lineups        SET player_id         = pair.keep WHERE player_id         = pair.dead;
    UPDATE player_team_stints   SET player_id         = pair.keep WHERE player_id         = pair.dead;
    UPDATE match_player_ratings SET player_id         = pair.keep WHERE player_id         = pair.dead;
    UPDATE entity_source_map    SET entity_id         = pair.keep
     WHERE entity_type = 'player' AND entity_id = pair.dead;
    DELETE FROM players WHERE id = pair.dead;
  END LOOP;
END $$;

\echo ''
\echo 'No player name is parser output any more:'
SELECT id, full_name FROM players
 WHERE full_name LIKE '%&#%' OR full_name LIKE '%(pen)%' OR full_name LIKE '%(og)%'
 ORDER BY id;

\echo ''
\echo 'The survivors:'
SELECT p.id, p.full_name,
       (SELECT count(*) FROM match_events e WHERE e.player_id = p.id) AS events,
       (SELECT string_agg(DISTINCT t.name, ', ') FROM match_events e
          JOIN teams t ON t.id = e.team_id WHERE e.player_id = p.id) AS clubs
  FROM players p WHERE p.id IN (11707, 11634, 2571, 4627, 1700, 975, 5003, 5095)
 ORDER BY p.id;

COMMIT;
