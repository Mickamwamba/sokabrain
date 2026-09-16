-- Publish the twenty-two Africa Cup of Nations editions from 1957 to 2000.
--
-- Mirrors what the admin publish endpoint does (is_published, published_at,
-- published_by) rather than just flipping the boolean, so the record of who
-- published and when reads the same as if it had been done in the dashboard.
--
-- Checked first: no AFCON edition or match carries an open BLOCKER flag, so
-- nothing is being overridden. The guard is kept anyway, so re-running this
-- after a flag is raised does the right thing.
--
-- The competition's 11 open CRITICAL audit findings all sit in the legacy 2019
-- edition, which has been public since 2026-09-12; none is in these 22. What
-- these editions do carry is thin event logs: 57 scored matches have no goal
-- events, nearly all in 1996 and 1998, because RSSSF lists no scorers for them.
-- The public site states that itself — a top-scorer list says what share of
-- goals name a scorer — so it is published rather than hidden.
--
-- Reverse with:
--   UPDATE competition_editions ce SET is_published = FALSE
--     FROM seasons s WHERE s.id = ce.season_id AND ce.competition_id = 16
--       AND s.label ~ '^[0-9]{4}$' AND s.label::int < 2002;

BEGIN;

UPDATE competition_editions ce
   SET is_published = TRUE,
       published_at = now(),
       published_by = 1
  FROM seasons s
 WHERE s.id = ce.season_id
   AND ce.competition_id = 16
   AND s.label ~ '^[0-9]{4}$'
   AND s.label::int < 2002
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

\echo 'AFCON editions now public, earliest and latest:'
SELECT count(*) AS editions, min(s.label) AS earliest, max(s.label) AS latest,
       (SELECT count(*) FROM matches m JOIN competition_editions ce2 ON ce2.id = m.competition_edition_id
         WHERE ce2.competition_id = 16 AND ce2.is_published) AS public_matches
  FROM competition_editions ce JOIN seasons s ON s.id = ce.season_id
 WHERE ce.competition_id = 16 AND ce.is_published;

COMMIT;
