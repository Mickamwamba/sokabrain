-- 2023/24 Premier League: a duplicated player, a name, and two own goals.
--
-- The Flashscore load left five goals unattributed. Three are settled here; the
-- other two are not the vault's fault and are recorded as such at the end.
--
-- 1. **Edward Songo is two records**, which is why the loader refused to name
--    his goal: "songo-edward" matched both and an ambiguous match is no match.
--      1553 "Edward Joseph Songo"  legacy SokaFC, JKT Tanzania, 2018/19-2019/20
--      4650 "Edward Songo"         ligikuu,       JKT Tanzania, 2023/24-2026/27
--    Same club, disjoint seasons, never in the same match: the legacy-versus-
--    ligikuu duplication this vault has hit a dozen times. Merged into 1553,
--    which carries the fuller name, and his JKT goal in Tanzania Prisons 1-1
--    JKT (17590, 42') is then his beyond doubt.
--
-- 2. **Two goals the vault recorded as ordinary were own goals.** ligikuu left
--    both unattributed -- it had no scorer to name, because the scorer was
--    playing for the other side -- and Flashscore names them:
--      17597  KMC FC 1-1 Tanzania Prisons, 53'  -> Wilbol Maseke, a KMC player
--      17622  Dodoma Jiji 1-2 Fountain Gate, 13' -> Augustino Samson, Dodoma
--    Both men are already in the vault. Each event keeps the side it counts for
--    and moves to the scorer's own team, per design principle 5, so both matches
--    still reconcile. **An unattributed goal being an own goal is a pattern**:
--    it is the one kind a scorer-list source has no natural place to record.
--
--    The minutes stay as the vault has them (53' and 13' against Flashscore's
--    54' and 12'). This settles what the goals were and who scored them, not
--    when, which is the same line drawn for every other cross-source fix here.
--
-- Left alone, because no source can settle them:
--   17596  Mtibwa Sugar 3-1 Geita Gold, 82' -- Flashscore lists the goal and
--          does not name its scorer either.
--   17783  Namungo 3-2 TRA United, 90' -- Flashscore's own log reads 2-2 for a
--          3-2, so it is a goal short and cannot supply the name.

BEGIN;

INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
VALUES ('player',
        (SELECT id FROM data_sources WHERE name = 'legacy_sokafc'),
        (SELECT id FROM data_sources WHERE name = 'flashscore'),
        '2023/24 Premier League: Edward Songo held as two records and merged, his 17590 goal then named, and two goals the vault had as ordinary corrected to own goals with the scorers Flashscore names.');

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM players WHERE id IN (1553, 4650);
  IF n <> 2 THEN RAISE EXCEPTION 'the two Songo records are not both present'; END IF;
  SELECT count(*) INTO n FROM (
    SELECT match_id FROM match_events WHERE player_id = 1553
    INTERSECT SELECT match_id FROM match_events WHERE player_id = 4650) x;
  IF n <> 0 THEN RAISE EXCEPTION 'the two Songo records share a match, so they are two people'; END IF;
  SELECT count(DISTINCT team_id) INTO n FROM match_events WHERE player_id IN (1553, 4650);
  IF n <> 1 THEN RAISE EXCEPTION 'the two Songo records span more than one club'; END IF;

  SELECT count(*) INTO n FROM match_events
   WHERE id = 27180 AND match_id = 17590 AND player_id IS NULL AND team_id = 3 AND type = 'GOAL';
  IF n <> 1 THEN RAISE EXCEPTION 'event 27180 is not the unnamed JKT goal in 17590'; END IF;
  SELECT count(*) INTO n FROM match_events
   WHERE (id = 10284 AND match_id = 17597 AND team_id = 13 AND type = 'GOAL' AND player_id IS NULL)
      OR (id = 10342 AND match_id = 17622 AND team_id = 350 AND type = 'GOAL' AND player_id IS NULL);
  IF n <> 2 THEN RAISE EXCEPTION 'the two goals to convert are not in the expected state'; END IF;
  SELECT count(*) INTO n FROM players WHERE id IN (4876, 1417);
  IF n <> 2 THEN RAISE EXCEPTION 'Maseke or Samson is missing from the vault'; END IF;
END $$;

/* -- 1. one Edward Songo ---------------------------------------------------- */
INSERT INTO reconciliation_diffs (reconciliation_run_id, entity_id_a, entity_id_b, field_name, value_a, value_b, resolution, resolved_value, resolved_at)
SELECT currval('reconciliation_runs_id_seq'), 4650, 1553, 'players.id',
       'Edward Songo (4650), ' || (SELECT count(*) FROM match_events WHERE player_id = 4650) || ' events',
       'Edward Joseph Songo (1553)', 'MANUAL', '1553', now();

UPDATE match_events        SET player_id         = 1553 WHERE player_id         = 4650;
UPDATE match_events        SET related_player_id = 1553 WHERE related_player_id = 4650;
UPDATE match_lineups       SET player_id         = 1553 WHERE player_id         = 4650;
UPDATE player_team_stints  SET player_id         = 1553 WHERE player_id         = 4650;
UPDATE match_player_ratings SET player_id        = 1553 WHERE player_id         = 4650;
UPDATE entity_source_map   SET entity_id         = 1553
 WHERE entity_type = 'player' AND entity_id = 4650;
DELETE FROM players WHERE id = 4650;

/* -- 2. his goal in Tanzania Prisons 1-1 JKT Tanzania ----------------------- */
INSERT INTO reconciliation_diffs (reconciliation_run_id, entity_id_a, entity_id_b, field_name, value_a, value_b, resolution, resolved_value, resolved_at)
VALUES (currval('reconciliation_runs_id_seq'), 27180, 17590, 'match_events.player_id',
        'no scorer', 'Edward Songo, 42'' (Flashscore)', 'ACCEPT_B', '1553', now());

UPDATE match_events SET player_id = 1553 WHERE id = 27180;

/* -- 3. the two own goals --------------------------------------------------- */
INSERT INTO reconciliation_diffs (reconciliation_run_id, entity_id_a, entity_id_b, field_name, value_a, value_b, resolution, resolved_value, resolved_at)
VALUES (currval('reconciliation_runs_id_seq'), 10284, 17597, 'match_events.type',
        'GOAL, no scorer, credited to Tanzania Prisons',
        'OWN_GOAL by Wilbol Maseke of KMC FC, still counting for Tanzania Prisons (Flashscore)',
        'ACCEPT_B', 'OWN_GOAL', now()),
       (currval('reconciliation_runs_id_seq'), 10342, 17622, 'match_events.type',
        'GOAL, no scorer, credited to Fountain Gate FC',
        'OWN_GOAL by Augustino Samson of Dodoma Jiji FC, still counting for Fountain Gate (Flashscore)',
        'ACCEPT_B', 'OWN_GOAL', now());

-- The team becomes the scorer's own side; the goal still counts for the other.
UPDATE match_events SET type = 'OWN_GOAL', team_id = 102, player_id = 4876 WHERE id = 10284;
UPDATE match_events SET type = 'OWN_GOAL', team_id = 336, player_id = 1417 WHERE id = 10342;

INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
VALUES ('match_event', 10284, (SELECT id FROM data_sources WHERE name='flashscore'), 'flashscore-17597-og53', 1.0),
       ('match_event', 10342, (SELECT id FROM data_sources WHERE name='flashscore'), 'flashscore-17622-og13', 1.0),
       ('player', 4876, (SELECT id FROM data_sources WHERE name='flashscore'), 'flashscore-player-maseke-wilbol', 1.0),
       ('player', 1417, (SELECT id FROM data_sources WHERE name='flashscore'), 'flashscore-player-samson-augustino', 1.0)
ON CONFLICT (entity_type, data_source_id, external_id) DO UPDATE SET last_synced_at = now();

SET timezone = 'UTC';

\echo ''
\echo 'The two corrected own goals, and who they still count for:'
SELECT e.match_id, p.full_name AS scorer, t.name AS recorded_under, e.minute, e.type,
       CASE WHEN e.team_id = m.home_team_id THEN at.name ELSE ht.name END AS counts_for
  FROM match_events e JOIN matches m ON m.id = e.match_id
  JOIN teams t ON t.id = e.team_id JOIN players p ON p.id = e.player_id
  JOIN teams ht ON ht.id = m.home_team_id JOIN teams at ON at.id = m.away_team_id
 WHERE e.id IN (10284, 10342);

\echo ''
\echo '2023/24: matches reconciling, goals with no event, events with no scorer:'
WITH x AS (
  SELECT m.id, coalesce(m.home_score_et, m.home_score) hs, coalesce(m.away_score_et, m.away_score) as_,
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
 WHERE ce.competition_id = 1 AND s.label = '2023/2024' AND m.home_score IS NOT NULL
 GROUP BY m.id, 2, 3)
SELECT count(*) AS matches, count(*) FILTER (WHERE h = hs AND a = as_) AS reconciling,
       sum(greatest((hs + as_) - (h + a), 0)) AS goals_with_no_event,
       sum(unnamed) AS events_with_no_scorer
  FROM x;

COMMIT;
