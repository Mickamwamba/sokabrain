-- Close the four open kickoff-date flags on TPL 2018/19.
--
-- Each was raised because rsssf.org disagreed with the vault and there was no
-- third source to settle it. whoscored.com is now that third source, and on all
-- four it agrees with RSSSF against us. The dates have been corrected.

BEGIN;

UPDATE data_flags
   SET status = 'RESOLVED',
       resolved_at = now(),
       resolved_by = 1,
       resolution_note = 'Settled by whoscored.com/regions/217/tournaments/382, which agrees '
                       || 'with RSSSF against the vault. The kickoff date has been corrected; '
                       || 'the score was never in dispute.'
 WHERE id IN (24, 25, 26, 27) AND status = 'OPEN';

\echo 'flags still open on TPL editions (expected 0):'
SELECT count(*) FROM data_flags f
 WHERE f.status = 'OPEN' AND f.entity_type = 'match'
   AND f.entity_id IN (SELECT id FROM matches WHERE competition_edition_id IN (1,6,17));

COMMIT;
