-- 2021/22 Premier League: two scorers held twice, and one match with no goals
-- to find.
--
-- Both parts clear the way for the FotMob load of the season, which otherwise
-- leaves seven goals unattributed and one match looking three goals short.
--
-- 1. **Two duplicate player records**, the same shape as every one before them:
--    one club, no match in common, seasons that do not overlap, and one name is
--    the other with a part added. The loader refuses to name a goal when two
--    players at the same club both match, which is the right refusal and why
--    these are settled here rather than guessed at.
--
--      1417  "Augustino Samson Nsata"  legacy + Flashscore, Dodoma Jiji, 2023/24
--      4918  "Augustino Nsata"         ligikuu,             Dodoma Jiji, 2024/25-2025/26
--
--      1455  "Haji Mohamed Ugando"     legacy,  Coastal Union, 2018/19-2019/20
--      4610  "Haji Ugando"             ligikuu + RSSSF, Coastal Union then KenGold,
--                                      2020/21, 2023/24-2024/25
--
--    Each merges into the record carrying the fuller name, as Edward Songo and
--    Feisal Salum did. Ugando's two clubs are a transfer of his, not a
--    contradiction: both records play for Coastal Union, and only the later one
--    goes on to KenGold.
--
-- 2. **Namungo 3-0 Mbeya Kwanza (17249), 13 May 2022, was awarded.** FotMob
--    flags it `awarded` in its fixture list and its match page carries no goal
--    events at all, because none were scored -- the 3-0 is an administrative
--    result. This is the second such match in the vault, after Dodoma Jiji 0-3
--    Pamba Jiji in 2025/26, and it is recorded the same way: an INFO flag, so
--    that every future audit run and coverage report stops reading it as three
--    missing goals. **Check for an awarded result before hunting for goals.**
--
-- With these, 2021/22 has an event for every goal that was actually scored.

BEGIN;

INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
VALUES ('player',
        (SELECT id FROM data_sources WHERE name = 'ligikuu'),
        (SELECT id FROM data_sources WHERE name = 'fotmob'),
        '2021/22 Premier League: Augustino Nsata (Dodoma Jiji) and Haji Ugando (Coastal Union) were each held as two player records in non-overlapping seasons and are merged; Namungo 3-0 Mbeya Kwanza is flagged as an awarded result with no goals to find.');

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM players WHERE id IN (1417, 4918, 1455, 4610);
  IF n <> 4 THEN RAISE EXCEPTION 'the four player records are not all present'; END IF;

  SELECT count(*) INTO n FROM (
    SELECT match_id FROM match_events WHERE player_id = 1417
    INTERSECT SELECT match_id FROM match_events WHERE player_id = 4918) x;
  IF n <> 0 THEN RAISE EXCEPTION 'the two Nsata records share a match, so they are two men'; END IF;
  SELECT count(DISTINCT team_id) INTO n FROM match_events WHERE player_id IN (1417, 4918);
  IF n <> 1 THEN RAISE EXCEPTION 'the two Nsata records span more than one club'; END IF;

  SELECT count(*) INTO n FROM (
    SELECT match_id FROM match_events WHERE player_id = 1455
    INTERSECT SELECT match_id FROM match_events WHERE player_id = 4610) x;
  IF n <> 0 THEN RAISE EXCEPTION 'the two Ugando records share a match, so they are two men'; END IF;
  SELECT count(*) INTO n FROM match_events
   WHERE player_id = 1455 AND team_id <> (SELECT id FROM teams WHERE name = 'Coastal Union');
  IF n <> 0 THEN RAISE EXCEPTION 'the legacy Haji Ugando played for a club other than Coastal Union'; END IF;

  SELECT count(*) INTO n FROM matches
   WHERE id = 17249 AND home_score = 3 AND away_score = 0;
  IF n <> 1 THEN RAISE EXCEPTION 'match 17249 is not a 3-0'; END IF;
  SELECT count(*) INTO n FROM match_events WHERE match_id = 17249;
  IF n <> 0 THEN RAISE EXCEPTION 'match 17249 already has events'; END IF;
END $$;

INSERT INTO reconciliation_diffs (reconciliation_run_id, entity_id_a, entity_id_b, field_name, value_a, value_b, resolution, resolved_value, resolved_at)
SELECT currval('reconciliation_runs_id_seq'), 4918, 1417, 'players.id',
       'Augustino Nsata (4918), ' || (SELECT count(*) FROM match_events WHERE player_id = 4918) || ' events at Dodoma Jiji',
       'Augustino Samson Nsata (1417)', 'MANUAL', '1417', now()
UNION ALL
SELECT currval('reconciliation_runs_id_seq'), 4610, 1455, 'players.id',
       'Haji Ugando (4610), ' || (SELECT count(*) FROM match_events WHERE player_id = 4610) || ' events at Coastal Union and KenGold',
       'Haji Mohamed Ugando (1455)', 'MANUAL', '1455', now();

/* -- 1. the merges ---------------------------------------------------------- */
UPDATE match_events         SET player_id         = 1417 WHERE player_id         = 4918;
UPDATE match_events         SET related_player_id = 1417 WHERE related_player_id = 4918;
UPDATE match_lineups        SET player_id         = 1417 WHERE player_id         = 4918;
UPDATE player_team_stints   SET player_id         = 1417 WHERE player_id         = 4918;
UPDATE match_player_ratings SET player_id         = 1417 WHERE player_id         = 4918;
UPDATE entity_source_map    SET entity_id         = 1417
 WHERE entity_type = 'player' AND entity_id = 4918;
DELETE FROM players WHERE id = 4918;

UPDATE match_events         SET player_id         = 1455 WHERE player_id         = 4610;
UPDATE match_events         SET related_player_id = 1455 WHERE related_player_id = 4610;
UPDATE match_lineups        SET player_id         = 1455 WHERE player_id         = 4610;
UPDATE player_team_stints   SET player_id         = 1455 WHERE player_id         = 4610;
UPDATE match_player_ratings SET player_id         = 1455 WHERE player_id         = 4610;
UPDATE entity_source_map    SET entity_id         = 1455
 WHERE entity_type = 'player' AND entity_id = 4610;
DELETE FROM players WHERE id = 4610;

/* -- 2. the awarded match, which is complete as it stands ------------------- */
INSERT INTO data_flags (entity_type, entity_id, severity, reason, status)
VALUES ('match', 17249, 'INFO',
        'Awarded 3-0 to Namungo, not played out: FotMob marks it AWARDED and its match page carries no goal events. The empty event log is correct -- do not read the 3-0 as three missing goals.',
        'OPEN');

INSERT INTO reconciliation_diffs (reconciliation_run_id, entity_id_a, entity_id_b, field_name, value_a, value_b, resolution, resolved_value, resolved_at)
VALUES (currval('reconciliation_runs_id_seq'), 17249, NULL, 'matches.awarded',
        'stored 3-0 with no event log, read as 3 missing goals',
        'awarded result, never played out; no goals exist to record',
        'MANUAL', 'flagged INFO', now());

\echo ''
\echo 'The two survivors, and what they now hold:'
SELECT p.id, p.full_name,
       (SELECT count(*) FROM match_events e WHERE e.player_id = p.id) AS events,
       (SELECT string_agg(DISTINCT t.name, ', ') FROM match_events e
          JOIN teams t ON t.id = e.team_id WHERE e.player_id = p.id) AS clubs
  FROM players p WHERE p.id IN (1417, 1455) ORDER BY p.id;

COMMIT;
