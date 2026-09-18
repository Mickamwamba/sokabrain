-- The last two 2025/26 Premier League matches, and one of them was never a gap.
--
-- Both were reached through Flashscore's head-to-head tab rather than its season
-- results list, which stops paging back after a few loads. A match's H2H page
-- lists every previous meeting of the two clubs with a link to each, so the
-- reverse fixture is a reliable way to reach an older one. Worth remembering.
--
-- 18138  Pamba Jiji 2-2 Azam FC, 2 March 2026. The log held three of the four
--        goals; ligikuu has the same three. The missing one is an OWN GOAL by
--        Azam's Himid Mkami in the 45th minute, which is why neither source's
--        scorer list had it -- ligikuu records own goals in a separate field it
--        left empty here, and the vault's three events all name a scorer.
--        Stored under Azam FC, the scorer's own team (design principle 5), and
--        credited to Pamba Jiji by the read side.
--
-- 18059  Dodoma Jiji 0-3 Pamba Jiji, 25 October 2025. **There are no three
--        goals to find.** Flashscore marks this AWARDED: the match was forfeited,
--        and the only thing that happened on the pitch was a Dodoma Jiji goal in
--        the 6th minute that the award annulled. The 0-3 is an administrative
--        result, so an empty event log is correct and complete.
--
--        This is recorded as an INFO flag rather than left as an apparent hole,
--        because every future audit run, coverage report and ingestion attempt
--        would otherwise keep pointing at it as three missing goals. It is the
--        only match in the season whose log will never reconcile with its score,
--        and it should not.
--
-- With these, 2025/26 has an event for every goal that was actually scored. One
-- goal remains unattributed -- KMC FC's 82nd minute against Namungo -- because no
-- source names its scorer.

BEGIN;

INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
VALUES ('match_event',
        (SELECT id FROM data_sources WHERE name = 'ligikuu'),
        (SELECT id FROM data_sources WHERE name = 'flashscore'),
        '2025/26 Premier League, the last two unreconciled matches: Pamba Jiji v Azam gains the own goal by Himid Mkami that both sources omitted, and Dodoma Jiji v Pamba Jiji is recorded as an awarded 0-3 with no goals to find.');

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM matches
   WHERE id = 18138 AND home_team_id = 353 AND away_team_id = 1
     AND home_score = 2 AND away_score = 2;
  IF n <> 1 THEN RAISE EXCEPTION 'match 18138 is not Pamba Jiji 2-2 Azam FC'; END IF;
  SELECT count(*) INTO n FROM match_events
   WHERE match_id = 18138 AND type IN ('GOAL','PENALTY_GOAL','OWN_GOAL');
  IF n <> 3 THEN RAISE EXCEPTION 'match 18138 should hold 3 goal events, holds %', n; END IF;
  SELECT count(*) INTO n FROM matches
   WHERE id = 18059 AND home_score = 0 AND away_score = 3;
  IF n <> 1 THEN RAISE EXCEPTION 'match 18059 is not a 0-3'; END IF;
  SELECT count(*) INTO n FROM match_events WHERE match_id = 18059;
  IF n <> 0 THEN RAISE EXCEPTION 'match 18059 already has events'; END IF;
  SELECT count(*) INTO n FROM players WHERE full_name = 'Himid Mkami';
  IF n <> 0 THEN RAISE EXCEPTION 'a player called Himid Mkami already exists'; END IF;
END $$;

/* -- the own goal nobody listed ------------------------------------------- */
WITH p AS (
  INSERT INTO players (full_name) VALUES ('Himid Mkami') RETURNING id
), prov AS (
  INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
  SELECT 'player', id, (SELECT id FROM data_sources WHERE name='flashscore'),
         'flashscore-player-tGQdXENC', 1.0 FROM p
), ev AS (
  -- team_id is Azam FC: an own goal belongs to the scorer's own side, and the
  -- read side credits it to Pamba Jiji.
  INSERT INTO match_events (match_id, team_id, player_id, minute, type)
  SELECT 18138, 1, id, 45, 'OWN_GOAL' FROM p RETURNING id
)
INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
SELECT 'match_event', id, (SELECT id FROM data_sources WHERE name='flashscore'),
       'flashscore-zNzjKxRO-og45', 1.0 FROM ev;

/* -- the awarded match, which is complete as it stands --------------------- */
INSERT INTO data_flags (entity_type, entity_id, severity, reason, status)
VALUES ('match', 18059, 'INFO',
        'Awarded 0-3 to Pamba Jiji, not played out: Flashscore marks it AWARDED and records only a 6th-minute Dodoma Jiji goal that the award annulled. The empty event log is correct -- do not read the 3-0 as three missing goals.',
        'OPEN');

INSERT INTO reconciliation_diffs (reconciliation_run_id, entity_id_a, entity_id_b, field_name, value_a, value_b, resolution, resolved_value, resolved_at)
VALUES (currval('reconciliation_runs_id_seq'), 18138, 1, 'match_events.missing_goal',
        'Pamba Jiji score 2, one goal event', 'own goal by Himid Mkami (Azam FC) 45'', from Flashscore',
        'MANUAL', 'added', now()),
       (currval('reconciliation_runs_id_seq'), 18059, NULL, 'matches.awarded',
        'stored 0-3 with no event log, read as 3 missing goals',
        'awarded result, never played out; no goals exist to record',
        'MANUAL', 'flagged INFO', now());

SET timezone = 'UTC';

\echo ''
\echo 'Pamba Jiji 2-2 Azam FC, now complete:'
SELECT coalesce(p.full_name, '(none)') AS scorer, t.name AS recorded_under, e.minute, e.type
  FROM match_events e LEFT JOIN players p ON p.id = e.player_id JOIN teams t ON t.id = e.team_id
 WHERE e.match_id = 18138 ORDER BY e.minute;

\echo ''
\echo '2025/26 overall: every goal actually scored now has an event.'
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
 WHERE ce.competition_id = 1 AND s.label = '2025/2026' AND m.home_score IS NOT NULL
 GROUP BY m.id, 2, 3)
SELECT count(*) AS matches,
       count(*) FILTER (WHERE h = hs AND a = as_) AS reconciling,
       count(*) FILTER (WHERE (h <> hs OR a <> as_) AND id <> 18059) AS unexplained_gaps,
       sum(unnamed) AS goals_with_no_scorer
  FROM x;

COMMIT;
