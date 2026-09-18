-- Three goals missing from the 2025/26 Premier League, filled from Flashscore.
--
-- The season stood at 235 of 240 matches reconciling: five matches held fewer
-- goal events than their score. ligikuu, the official site, cannot close them --
-- it records no goals at all for two of the five and is itself a goal short on
-- the others, which is why `topup_ligikuu_scorers.py` refused them.
--
-- Flashscore has per-match scorers for this season. Three of the five are
-- settled by it:
--
--   18234  KMC FC 1-3 Coastal Union    log 0-3, missing KMC's goal
--          -> Mudathir Nassor, 31', a penalty
--   18243  Fountain Gate 0-1 Mashujaa  log 0-0, missing Mashujaa's goal
--          -> Hussein Juma, 87'
--   18244  KMC FC 2-3 Namungo          log 1-3, missing KMC's second
--          -> a goal at 82' that Flashscore does not attribute either
--
-- The two it cannot settle are left alone: 18059 (Dodoma Jiji 0-3 Pamba Jiji,
-- three goals, which ligikuu does not record and whose Flashscore page could not
-- be reached) and 18138 (Pamba Jiji 2-2 Azam FC, one goal).
--
-- **The scorers' names come from Flashscore's player links, not its timeline.**
-- The timeline abbreviates -- "Nassor M.", "Juma H." -- and planting those in
-- the vault would create half-named records that a fuller source would later
-- duplicate, which is the defect this project has spent days undoing. The link
-- targets carry the whole name: /player/nassor-mudathir/ and /player/juma-hussein/.
-- Neither man is in the vault under any spelling, so both are created.
--
-- Where Flashscore and ligikuu disagree about the goals already recorded --
-- ligikuu has Savila 3' where Flashscore has Mashaka R., and their minutes
-- differ by up to eight -- nothing is touched. This adds the goals that were
-- missing; it does not relitigate the ones that are there.

BEGIN;

-- Flashscore has not been used as a source before.
INSERT INTO data_sources (name, type, base_url)
VALUES ('flashscore', 'SCRAPED', 'https://www.flashscore.com')
ON CONFLICT (name) DO NOTHING;

INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
VALUES ('match_event',
        (SELECT id FROM data_sources WHERE name = 'ligikuu'),
        (SELECT id FROM data_sources WHERE name = 'flashscore'),
        'Three goals missing from 2025/26 Premier League matches, added from Flashscore: KMC v Coastal Union (Mudathir Nassor 31 pen), Fountain Gate v Mashujaa (Hussein Juma 87), and KMC v Namungo (82nd minute, scorer unattributed by the source too). ligikuu records none of the three.');

-- Refuse unless each match is still exactly the shape described above.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM matches m
   WHERE (m.id = 18234 AND m.home_score = 1 AND m.away_score = 3 AND m.home_team_id = 102)
      OR (m.id = 18243 AND m.home_score = 0 AND m.away_score = 1 AND m.away_team_id = 351)
      OR (m.id = 18244 AND m.home_score = 2 AND m.away_score = 3 AND m.home_team_id = 102);
  IF n <> 3 THEN RAISE EXCEPTION 'the three matches are not in the expected shape (% of 3)', n; END IF;

  SELECT count(*) INTO n FROM match_events
   WHERE match_id IN (18234, 18243, 18244) AND type IN ('GOAL','PENALTY_GOAL','OWN_GOAL');
  IF n <> 7 THEN RAISE EXCEPTION 'expected 7 existing goal events across the three, found %', n; END IF;

  SELECT count(*) INTO n FROM players
   WHERE full_name IN ('Mudathir Nassor', 'Hussein Juma');
  IF n <> 0 THEN RAISE EXCEPTION 'a player of that name already exists; resolve by hand'; END IF;
END $$;

/* -- KMC FC's penalty against Coastal Union ------------------------------- */
WITH p AS (
  INSERT INTO players (full_name) VALUES ('Mudathir Nassor') RETURNING id
), prov AS (
  INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
  SELECT 'player', id, (SELECT id FROM data_sources WHERE name='flashscore'),
         'flashscore-player-ngps4mkL', 1.0 FROM p
), ev AS (
  INSERT INTO match_events (match_id, team_id, player_id, minute, type)
  SELECT 18234, 102, id, 31, 'PENALTY_GOAL' FROM p RETURNING id
)
INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
SELECT 'match_event', id, (SELECT id FROM data_sources WHERE name='flashscore'),
       'flashscore-hnHnceH6-g4', 1.0 FROM ev;

/* -- Mashujaa's winner at Fountain Gate ----------------------------------- */
WITH p AS (
  INSERT INTO players (full_name) VALUES ('Hussein Juma') RETURNING id
), prov AS (
  INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
  SELECT 'player', id, (SELECT id FROM data_sources WHERE name='flashscore'),
         'flashscore-player-2eaJqfnn', 1.0 FROM p
), ev AS (
  INSERT INTO match_events (match_id, team_id, player_id, minute, type)
  SELECT 18243, 351, id, 87, 'GOAL' FROM p RETURNING id
)
INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
SELECT 'match_event', id, (SELECT id FROM data_sources WHERE name='flashscore'),
       'flashscore-vwW3MBpI-g1', 1.0 FROM ev;

/* -- KMC FC's second against Namungo, which nobody attributes -------------- */
WITH ev AS (
  INSERT INTO match_events (match_id, team_id, player_id, minute, type)
  VALUES (18244, 102, NULL, 82, 'GOAL') RETURNING id
)
INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
SELECT 'match_event', id, (SELECT id FROM data_sources WHERE name='flashscore'),
       'flashscore-C49pZlUN-g5', 1.0 FROM ev;

INSERT INTO reconciliation_diffs (reconciliation_run_id, entity_id_a, entity_id_b, field_name, value_a, value_b, resolution, resolved_value, resolved_at)
VALUES (currval('reconciliation_runs_id_seq'), 18234, 102, 'match_events.missing_goal',
        'KMC FC score 1, no goal event', 'Mudathir Nassor 31'' penalty, from Flashscore', 'MANUAL', 'added', now()),
       (currval('reconciliation_runs_id_seq'), 18243, 351, 'match_events.missing_goal',
        'Mashujaa FC score 1, no goal event', 'Hussein Juma 87'', from Flashscore', 'MANUAL', 'added', now()),
       (currval('reconciliation_runs_id_seq'), 18244, 102, 'match_events.missing_goal',
        'KMC FC score 2, one goal event', '82nd minute, scorer unattributed by Flashscore too', 'MANUAL', 'added', now());

SET timezone = 'UTC';

\echo ''
\echo 'The three matches, now reconciling:'
SELECT e.match_id, ht.name || ' ' || m.home_score || '-' || m.away_score || ' ' || at.name AS fixture,
       coalesce(p.full_name, '(no scorer named)') AS scorer, t.name AS team, e.minute, e.type
  FROM match_events e JOIN matches m ON m.id = e.match_id
  JOIN teams ht ON ht.id = m.home_team_id JOIN teams at ON at.id = m.away_team_id
  JOIN teams t ON t.id = e.team_id LEFT JOIN players p ON p.id = e.player_id
 WHERE e.match_id IN (18234, 18243, 18244) AND e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL')
 ORDER BY e.match_id, e.minute;

\echo ''
\echo '2025/26: matches whose log still contradicts the score, and goals still unnamed:'
WITH x AS (
  SELECT m.id, coalesce(m.home_score_et, m.home_score) hs, coalesce(m.away_score_et, m.away_score) as_,
    count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL') AND
      (CASE WHEN e.type='OWN_GOAL'
            THEN CASE WHEN e.team_id=m.home_team_id THEN m.away_team_id ELSE m.home_team_id END
            ELSE e.team_id END) = m.home_team_id) h,
    count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL') AND
      (CASE WHEN e.type='OWN_GOAL'
            THEN CASE WHEN e.team_id=m.home_team_id THEN m.away_team_id ELSE m.home_team_id END
            ELSE e.team_id END) = m.away_team_id) a
  FROM matches m
  JOIN competition_editions ce ON ce.id = m.competition_edition_id
  JOIN seasons s ON s.id = ce.season_id
  LEFT JOIN match_events e ON e.match_id = m.id
 WHERE ce.competition_id = 1 AND s.label = '2025/2026' AND m.home_score IS NOT NULL
 GROUP BY m.id, 2, 3)
SELECT count(*) FILTER (WHERE h <> hs OR a <> as_) AS not_reconciling,
       sum(greatest((hs + as_) - (h + a), 0)) AS goals_still_missing
  FROM x;

COMMIT;
