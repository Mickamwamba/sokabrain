-- Publish the sixteen newly ingested Premier League editions.
--
-- Mirrors what the admin publish endpoint does (is_published, published_at,
-- published_by) rather than just flipping the boolean, so the record of who
-- published and when is the same as if it had been done in the dashboard.
--
-- Checked first: no edition carries an open BLOCKER flag, on itself or on any
-- of its matches. The four open flags are WARNING, which is advisory.

BEGIN;

UPDATE competition_editions ce
   SET is_published = TRUE,
       published_at = now(),
       published_by = 1
 WHERE ce.competition_id = 1
   AND ce.is_published = FALSE
   AND NOT EXISTS (
        SELECT 1 FROM data_flags f
         WHERE f.status = 'OPEN' AND f.severity = 'BLOCKER'
           AND ((f.entity_type = 'competition_edition' AND f.entity_id = ce.id)
             OR (f.entity_type = 'match'
                 AND f.entity_id IN (SELECT id FROM matches
                                      WHERE competition_edition_id = ce.id))));

\echo 'Premier League editions still unpublished (must be 0):'
SELECT count(*) FROM competition_editions WHERE competition_id = 1 AND is_published = FALSE;

COMMIT;
