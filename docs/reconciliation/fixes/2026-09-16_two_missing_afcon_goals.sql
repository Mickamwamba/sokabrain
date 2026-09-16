-- The last two Africa Cup of Nations goals nobody had recorded.
--
-- Two matches have stood at a 1-1 with only one goal in their event log since
-- their tournaments were ingested. This is not a naming gap -- the goal event
-- itself was never there, so there was nothing to attribute -- and both are
-- long-standing known holes:
--
--   936    Tunisia 1-1 Angola,   24 June 2019   (legacy SokaFC)
--   19807  Zambia 1-1 Tanzania,  21 Jan 2024    (WhoScored)
--
-- Wikipedia's group-stage articles have both, and in each case they corroborate
-- the goal the vault DOES hold, which is what makes them usable for the goal it
-- does not:
--
--   Tunisia vs Angola:  Msakni 34' pen -- the vault has exactly that, as a
--                       PENALTY_GOAL at 34. Missing: Djalma Campos 73' (Angola).
--   Zambia vs Tanzania: Msuva 11' -- the vault has Msuva at 10, a minute out.
--                       Missing: Patson Daka 88' (Zambia).
--
-- Msuva's minute is left at 10. This adds a goal that was absent; it does not
-- relitigate one that is present on another source's word.
--
-- **Patson Daka is already in the vault** (player 2510, Zambia, with both legacy
-- and WhoScored provenance), so the event attaches to him. Creating a second
-- Patson Daka is exactly the defect this session spent its time undoing.
-- Djalma Campos is genuinely absent and is created, keyed on Angola.
--
-- Afterwards every played AFCON match's event log reproduces its own score, and
-- all 2,007 goals across 35 tournaments name a scorer.

BEGIN;

INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
VALUES ('match_event', 1, 5,
  'The two AFCON matches whose event log was a goal short of a 1-1: Tunisia v Angola 2019 (match 936) gains Djalma Campos 73'', Zambia v Tanzania 2024 (match 19807) gains Patson Daka 88''. Both from Wikipedia group-stage articles, which agree with the vault on each match''s other goal. Patson Daka already existed (2510) and is reused; Djalma Campos is created.');

-- Refuse unless both matches are still exactly one goal short of their 1-1.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM matches m
   WHERE m.id IN (936, 19807) AND m.home_score = 1 AND m.away_score = 1
     AND m.status = 'FULL_TIME';
  IF n <> 2 THEN RAISE EXCEPTION 'the two matches are not both a full-time 1-1'; END IF;

  SELECT count(*) INTO n FROM match_events e
   WHERE e.match_id IN (936, 19807) AND e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL');
  IF n <> 2 THEN RAISE EXCEPTION 'expected one goal event in each match, found % in total', n; END IF;

  -- The goal each match already holds, as the source describes it.
  PERFORM 1 FROM match_events e JOIN players p ON p.id = e.player_id
   WHERE e.match_id = 936 AND e.type = 'PENALTY_GOAL' AND e.minute = 34
     AND p.full_name = 'Youssef Msakni' AND e.team_id = 105;
  IF NOT FOUND THEN RAISE EXCEPTION 'match 936 does not hold Msakni''s 34th-minute penalty for Tunisia'; END IF;
  PERFORM 1 FROM match_events e JOIN players p ON p.id = e.player_id
   WHERE e.match_id = 19807 AND e.type = 'GOAL' AND p.full_name = 'Simon Msuva' AND e.team_id = 91;
  IF NOT FOUND THEN RAISE EXCEPTION 'match 19807 does not hold Msuva''s goal for Tanzania'; END IF;

  -- Patson Daka must be the one record, and Zambian.
  SELECT count(*) INTO n FROM players WHERE full_name = 'Patson Daka';
  IF n <> 1 THEN RAISE EXCEPTION 'expected exactly one Patson Daka, found %', n; END IF;
  PERFORM 1 FROM match_events e WHERE e.player_id = 2510 AND e.team_id = 37;
  IF NOT FOUND THEN RAISE EXCEPTION 'player 2510 has no Zambia goal, so may not be Patson Daka'; END IF;

  -- And Djalma Campos must not already exist under any spelling we can see.
  SELECT count(*) INTO n FROM players
   WHERE full_name ILIKE '%djalma%' OR full_name ILIKE '%campos%';
  IF n <> 0 THEN RAISE EXCEPTION 'a Djalma or Campos record already exists; resolve by hand'; END IF;
END $$;

/* -- Angola's goal: a player the vault does not have ---------------------- */

WITH new_player AS (
  INSERT INTO players (full_name) VALUES ('Djalma Campos') RETURNING id
), prov AS (
  -- Keyed on the country as well as the name, the lesson of the 1957-2000 load.
  INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
  SELECT 'player', id, 5, 'wikipedia-afcon-43-Djalma Campos', 1.0 FROM new_player
  RETURNING entity_id
), ev AS (
  INSERT INTO match_events (match_id, team_id, player_id, minute, type)
  SELECT 936, 43, id, 73, 'GOAL' FROM new_player
  RETURNING id
)
INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
SELECT 'match_event', id, 5, 'wikipedia-afcon-936-g2', 1.0 FROM ev;

/* -- Zambia's goal: a player the vault already has ------------------------ */

WITH ev AS (
  INSERT INTO match_events (match_id, team_id, player_id, minute, type)
  VALUES (19807, 37, 2510, 88, 'GOAL')
  RETURNING id
)
INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
SELECT 'match_event', id, 5, 'wikipedia-afcon-19807-g2', 1.0 FROM ev;

INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
VALUES ('player', 2510, 5, 'wikipedia-afcon-37-Patson Daka', 1.0)
ON CONFLICT (entity_type, data_source_id, external_id) DO UPDATE SET last_synced_at = now();

INSERT INTO reconciliation_diffs (reconciliation_run_id, entity_id_a, entity_id_b, field_name, value_a, value_b, resolution, resolved_value, resolved_at)
VALUES (currval('reconciliation_runs_id_seq'), 936, 43, 'match_events.missing_goal',
        'Angola score 1, no goal event', 'Djalma Campos 73'', from Wikipedia', 'MANUAL', 'added', now()),
       (currval('reconciliation_runs_id_seq'), 19807, 37, 'match_events.missing_goal',
        'Zambia score 1, no goal event', 'Patson Daka 88'', from Wikipedia', 'MANUAL', 'added', now());

/* -- verification --------------------------------------------------------- */
SET timezone = 'UTC';

\echo ''
\echo 'The two matches, now complete:'
SELECT e.match_id, ht.name || ' ' || m.home_score || '-' || m.away_score || ' ' || at.name AS fixture,
       p.full_name AS scorer, t.name AS team, e.minute, e.type
  FROM match_events e JOIN matches m ON m.id = e.match_id
  JOIN teams ht ON ht.id = m.home_team_id JOIN teams at ON at.id = m.away_team_id
  JOIN teams t ON t.id = e.team_id JOIN players p ON p.id = e.player_id
 WHERE e.match_id IN (936, 19807) AND e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL')
 ORDER BY e.match_id, e.minute;

\echo ''
\echo 'Every played AFCON match must now have an event log that reproduces its score:'
WITH ev AS (
  SELECT m.id,
    count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL') AND
      (CASE WHEN e.type = 'OWN_GOAL'
            THEN CASE WHEN e.team_id = m.home_team_id THEN m.away_team_id ELSE m.home_team_id END
            ELSE e.team_id END) = m.home_team_id) AS h,
    count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL') AND
      (CASE WHEN e.type = 'OWN_GOAL'
            THEN CASE WHEN e.team_id = m.home_team_id THEN m.away_team_id ELSE m.home_team_id END
            ELSE e.team_id END) = m.away_team_id) AS a
    FROM matches m JOIN match_events e ON e.match_id = m.id
    JOIN competition_editions ce ON ce.id = m.competition_edition_id
   WHERE ce.competition_id = 16
   GROUP BY m.id)
SELECT count(*) AS with_events,
       count(*) FILTER (WHERE ev.h = coalesce(m.home_score_et, m.home_score)
                          AND ev.a = coalesce(m.away_score_et, m.away_score)) AS reproduce_score
  FROM ev JOIN matches m ON m.id = ev.id;

\echo ''
\echo 'Africa Cup of Nations goals with a named scorer (should be all of them):'
WITH m AS (
  SELECT m.id, coalesce(m.home_score_et, m.home_score) + coalesce(m.away_score_et, m.away_score) AS goals
    FROM matches m JOIN competition_editions ce ON ce.id = m.competition_edition_id
   WHERE ce.competition_id = 16 AND m.home_score IS NOT NULL),
ev AS (
  SELECT e.match_id, count(*) FILTER (
           WHERE e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL')
             AND (e.player_id IS NOT NULL OR e.type = 'OWN_GOAL')) AS named
    FROM match_events e GROUP BY 1)
SELECT sum(m.goals) AS goals, sum(coalesce(ev.named, 0)) AS named,
       sum(greatest(m.goals - coalesce(ev.named, 0), 0)) AS unnamed,
       round(100.0 * sum(coalesce(ev.named, 0)) / sum(m.goals), 2) AS pct
  FROM m LEFT JOIN ev ON ev.match_id = m.id;

COMMIT;
