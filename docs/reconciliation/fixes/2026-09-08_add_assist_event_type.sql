-- Allow ASSIST as a match_events type.
--
-- The schema already reserves `match_events.related_player_id` for "assist
-- provider" on a GOAL row, which is the better representation -- it ties the
-- assist to the goal it created. It needs a source that says WHICH goal each
-- assist belongs to, and ours does not: ligikuu.co.tz records assists as a bare
-- per-player, per-match count, with no minute and no link to a goal.
--
-- Filling related_player_id would therefore mean guessing which goal each
-- assist set up, which is fabrication whenever a team scored more than once.
-- A standalone ASSIST row claims exactly what the source supports: this player
-- assisted, in this match, once per row.
--
-- Both representations stay valid. A future source that links assists to goals
-- should use related_player_id; the counting query in services/stats.ts unions
-- the two so neither is missed and no assist is counted twice.

BEGIN;

ALTER TABLE match_events DROP CONSTRAINT match_events_type_check;
ALTER TABLE match_events ADD CONSTRAINT match_events_type_check CHECK (type IN
    ('GOAL','OWN_GOAL','PENALTY_GOAL','PENALTY_MISS',
     'YELLOW_CARD','SECOND_YELLOW','RED_CARD','SUBSTITUTION','VAR_REVIEW','ASSIST'));

\echo 'constraint now reads:'
SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conname = 'match_events_type_check';

COMMIT;
