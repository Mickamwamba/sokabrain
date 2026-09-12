-- Publish the thirteen Africa Cup of Nations editions.
--
-- Mirrors what the admin publish endpoint does (is_published, published_at,
-- published_by) rather than just flipping the boolean, so the record of who
-- published and when is the same as if it had been done in the dashboard.
--
-- Checked first: no AFCON edition or match carries any data_flag at all, so
-- nothing BLOCKER is being overridden. The guard is kept anyway, so re-running
-- this after a flag is raised does the right thing.
--
-- NOTE: this widens the public site beyond the Tanzania Premier League for the
-- first time, and the site is not competition-aware yet. See the AFCON section
-- of CLAUDE.md for what that means; `UPDATE competition_editions SET
-- is_published = FALSE WHERE competition_id = 16;` reverses it.

BEGIN;

UPDATE competition_editions ce
   SET is_published = TRUE,
       published_at = now(),
       published_by = 1
 WHERE ce.competition_id = 16
   AND ce.is_published = FALSE
   AND NOT EXISTS (
        SELECT 1 FROM data_flags f
         WHERE f.status = 'OPEN' AND f.severity = 'BLOCKER'
           AND ((f.entity_type = 'competition_edition' AND f.entity_id = ce.id)
             OR (f.entity_type = 'match'
                 AND f.entity_id IN (SELECT id FROM matches
                                      WHERE competition_edition_id = ce.id))));

\echo 'AFCON editions still unpublished (must be 0):'
SELECT count(*) FROM competition_editions WHERE competition_id = 16 AND is_published = FALSE;

COMMIT;
