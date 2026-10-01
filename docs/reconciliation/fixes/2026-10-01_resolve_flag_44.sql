-- Resolve data flag 44: Tanzania Prisons 3-2 JKT Tanzania (match 17991).
--
-- The flag (2026-09-08) said the event log held six goals for a 3-2. The match
-- was corrected on 2026-09-17 (2026-09-17_prisons_jkt_2025_sides.sql), which
-- re-sided three events from Flashscore and recorded why in
-- reconciliation_diffs. It now holds five goal events that reproduce 3-2:
-- Prisons 50', 77', 89'; JKT 11', plus Elfadhil's 42' own goal, stored under his
-- own club (Prisons) and counting for JKT. The flag was never closed.
--
-- Guarded: it closes the flag only if the log still reproduces the score.

BEGIN;

DO $$
DECLARE h int; a int;
BEGIN
  SELECT
    count(*) FILTER (WHERE (CASE WHEN e.type = 'OWN_GOAL'
                                 THEN CASE WHEN e.team_id = m.home_team_id THEN m.away_team_id ELSE m.home_team_id END
                                 ELSE e.team_id END) = m.home_team_id),
    count(*) FILTER (WHERE (CASE WHEN e.type = 'OWN_GOAL'
                                 THEN CASE WHEN e.team_id = m.home_team_id THEN m.away_team_id ELSE m.home_team_id END
                                 ELSE e.team_id END) = m.away_team_id)
    INTO h, a
    FROM matches m
    JOIN match_events e ON e.match_id = m.id AND e.type IN ('GOAL', 'PENALTY_GOAL', 'OWN_GOAL')
   WHERE m.id = 17991 AND m.home_score = 3 AND m.away_score = 2;
  IF (h, a) IS DISTINCT FROM (3, 2) THEN
    RAISE EXCEPTION 'match 17991 events give %-%, not 3-2; leaving flag 44 open', h, a;
  END IF;
END $$;

UPDATE data_flags
   SET status = 'RESOLVED',
       resolved_at = now(),
       resolved_by = 1,
       resolution_note = 'Corrected on 2026-09-17 (2026-09-17_prisons_jkt_2025_sides.sql): '
                       || 'ligikuu double-counted the 41st-minute goal, and three events were '
                       || 're-sided from Flashscore. Five goal events now reproduce 3-2.'
 WHERE id = 44 AND entity_type = 'match' AND entity_id = 17991 AND status = 'OPEN';

\echo 'flag 44 (expected RESOLVED):'
SELECT id, status, resolved_at FROM data_flags WHERE id = 44;

COMMIT;
