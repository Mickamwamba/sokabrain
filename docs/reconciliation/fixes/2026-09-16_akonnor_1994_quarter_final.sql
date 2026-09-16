-- Ghana's goal in the 1994 quarter-final gets its scorer.
--
-- Ghana 1-2 Ivory Coast, 3 April 1994 (match 22274). RSSSF records the Ivorian
-- pair -- Tiéhi 30' and Abdoulaye Traoré 82' -- but gives Ghana's goal no scorer
-- and no minute. Wikipedia's article on the tournament names it: Charles
-- Akonnor, 77 minutes.
--
-- The rest of that match corroborates the source. Wikipedia agrees with the
-- vault on Tiéhi's 30th minute exactly and on Traoré's to within a minute (81
-- against 82), so it is describing the same match, and its third goal is the one
-- the vault is missing.
--
-- Akonnor is already in the vault as "Akonnor" (player 11087), a surname from
-- RSSSF's 1992 reports. The existing event is named rather than a new one
-- inserted, so the match keeps exactly three goal events for its 1-2.
--
-- Traoré's minute is left at 82. This fix is about who scored, not when, and
-- overwriting a minute on one source's word is a different decision.
--
-- This was the last unnamed goal outside three matches whose sources give no
-- scorer for them at all. It takes the Africa Cup of Nations to 2,002 of 2,007
-- goals with a named scorer.

BEGIN;

INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
VALUES ('match_event', 6, 5,
  'Ghana 1-2 Ivory Coast, AFCON 1994 quarter-final (match 22274): RSSSF leaves Ghana''s goal with no scorer and no minute; Wikipedia names Charles Akonnor at 77 minutes, and agrees with the vault on the other two goals. The existing event is named rather than a second one inserted.');

INSERT INTO reconciliation_diffs (reconciliation_run_id, entity_id_a, entity_id_b, field_name, value_a, value_b, resolution, resolved_value, resolved_at)
VALUES (currval('reconciliation_runs_id_seq'), 25760, 22274, 'match_events.player_id',
        'no scorer, no minute', 'Charles Akonnor, 77'', from Wikipedia', 'MANUAL', '11087', now());

-- Refuse to run unless the row is still the unnamed Ghana goal this describes.
DO $$
DECLARE ok int;
BEGIN
  SELECT count(*) INTO ok FROM match_events e JOIN teams t ON t.id = e.team_id
   WHERE e.id = 25760 AND e.match_id = 22274 AND e.player_id IS NULL
     AND e.type = 'GOAL' AND t.name = 'Ghana';
  IF ok <> 1 THEN RAISE EXCEPTION 'event 25760 is not the unnamed Ghana goal in match 22274'; END IF;
  SELECT count(*) INTO ok FROM players WHERE id = 11087 AND full_name = 'Akonnor';
  IF ok <> 1 THEN RAISE EXCEPTION 'player 11087 is not Akonnor'; END IF;
END $$;

UPDATE match_events SET player_id = 11087, minute = 77 WHERE id = 25760;

-- Wikipedia named him, so it gets a provenance row alongside RSSSF's.
INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
VALUES ('match_event', 25760, 5, 'wikipedia-afcon-22274-g1', 1.0)
ON CONFLICT (entity_type, data_source_id, external_id) DO UPDATE SET last_synced_at = now();
INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
VALUES ('player', 11087, 5, 'wikipedia-afcon-20-Charles Akonnor', 1.0)
ON CONFLICT (entity_type, data_source_id, external_id) DO UPDATE SET last_synced_at = now();

SET timezone = 'UTC';

\echo ''
\echo 'Ghana 1-2 Ivory Coast, 1994 quarter-final:'
SELECT coalesce(p.full_name, '(none)') AS scorer, t.name AS team, e.minute, e.type
  FROM match_events e LEFT JOIN players p ON p.id = e.player_id JOIN teams t ON t.id = e.team_id
 WHERE e.match_id = 22274 ORDER BY e.minute;

\echo ''
\echo 'Africa Cup of Nations goals with a named scorer:'
WITH m AS (
  SELECT m.id, coalesce(m.home_score_et, m.home_score) + coalesce(m.away_score_et, m.away_score) AS goals
    FROM matches m JOIN competition_editions ce ON ce.id = m.competition_edition_id
   WHERE ce.competition_id = 16 AND m.home_score IS NOT NULL),
ev AS (
  SELECT e.match_id, count(*) FILTER (
           WHERE e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL')
             AND (e.player_id IS NOT NULL OR e.type = 'OWN_GOAL')) AS named
    FROM match_events e GROUP BY 1)
SELECT sum(m.goals) AS goals,
       sum(coalesce(ev.named, 0)) AS named,
       sum(greatest(m.goals - coalesce(ev.named, 0), 0)) AS unnamed,
       round(100.0 * sum(coalesce(ev.named, 0)) / sum(m.goals), 2) AS pct
  FROM m LEFT JOIN ev ON ev.match_id = m.id;

COMMIT;
