-- Fill competition_edition_teams and num_teams for the three migrated editions.
--
-- The legacy source never populated participants, so these were left empty at
-- migration and the read API derives participants from `matches` instead. The
-- newly ingested seasons do record them, and leaving the original three blank
-- would make the same column mean different things depending on the season.
--
-- Derived from the fixtures themselves, which is the only evidence there is.

BEGIN;

INSERT INTO competition_edition_teams (competition_edition_id, team_id)
SELECT DISTINCT m.competition_edition_id, t.team_id
  FROM matches m
  CROSS JOIN LATERAL (VALUES (m.home_team_id), (m.away_team_id)) AS t(team_id)
 WHERE m.competition_edition_id IN (1, 6, 17)
ON CONFLICT (competition_edition_id, team_id) DO NOTHING;

UPDATE competition_editions ce
   SET num_teams = sub.n,
       format = coalesce(ce.format, 'ROUND_ROBIN')
  FROM (SELECT competition_edition_id, count(*) AS n
          FROM competition_edition_teams
         WHERE competition_edition_id IN (1, 6, 17)
         GROUP BY competition_edition_id) sub
 WHERE ce.id = sub.competition_edition_id;

\echo 'participants per migrated edition:'
SELECT competition_edition_id, count(*) FROM competition_edition_teams
 WHERE competition_edition_id IN (1,6,17) GROUP BY 1 ORDER BY 1;

\echo 'editions of the Premier League with no participants (must be 0):'
SELECT count(*) FROM competition_editions ce
 WHERE ce.competition_id = 1
   AND NOT EXISTS (SELECT 1 FROM competition_edition_teams t WHERE t.competition_edition_id = ce.id);

COMMIT;
