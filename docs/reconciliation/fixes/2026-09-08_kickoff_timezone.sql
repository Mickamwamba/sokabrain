-- Correct the timezone of every migrated kickoff time.
--
-- The legacy SokaFC app was operated from Tanzania and its MySQL `datetime`
-- columns carry no zone: they hold local wall-clock (EAT, UTC+3) as typed by
-- the operator. The migration stored those hours as UTC, which puts every
-- kickoff three hours late -- the league's standard 16:00 kickoff reads as
-- 19:00, and 35 Tanzanian Premier League matches read as kicking off at 23:00.
--
-- Rows at 00:00-01:00 are left alone: those are "time unknown" placeholders
-- rather than kickoffs, and shifting them back would move them to the
-- previous day, destroying a date we do know.
--
-- Safe to re-run only once -- it is a shift, not an idempotent set.

BEGIN;

CREATE TEMP TABLE before_state AS
  SELECT id, kickoff_at, (kickoff_at AT TIME ZONE 'UTC')::date AS d
    FROM matches WHERE kickoff_at IS NOT NULL;

UPDATE matches
   SET kickoff_at = (kickoff_at AT TIME ZONE 'UTC') AT TIME ZONE 'Africa/Dar_es_Salaam'
 WHERE kickoff_at IS NOT NULL
   AND (kickoff_at AT TIME ZONE 'UTC')::time >= '03:00';

-- No kickoff DATE may move. Every reconciliation against Wikipedia and RSSSF
-- was made on the date, so all of them must still hold afterwards.
\echo 'dates that moved (must be 0):'
SELECT count(*) FROM before_state b JOIN matches m ON m.id = b.id
 WHERE b.d <> (m.kickoff_at AT TIME ZONE 'UTC')::date;

\echo 'rows shifted / rows left as placeholders:'
SELECT count(*) FILTER (WHERE m.kickoff_at <> b.kickoff_at) AS shifted,
       count(*) FILTER (WHERE m.kickoff_at = b.kickoff_at)  AS untouched
  FROM before_state b JOIN matches m ON m.id = b.id;

COMMIT;
