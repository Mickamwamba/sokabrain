-- Merge two clubs that the sources record under two names each.
--
--   JKT Ruvu Stars (338), 2008/09-2016/17  ->  JKT Tanzania (3),        2018/19-
--   Singida United (88),  2017/18-2019/20  ->  Singida Black Stars (347), 2020/21-
--
-- Both are renames, confirmed by the project owner. Their season ranges do not
-- overlap and neither pair ever shares an edition, so nothing collides and no
-- club is credited with playing itself.
--
-- Left as two rows, each club's history was split in half: the all-time record,
-- head-to-head and club page each showed part of a club and called it the whole.
--
-- The surviving row keeps the club's CURRENT name. The former name is not lost:
-- it is registered in docs/ingestion/teamnames.py so that a future ingest of an
-- old season resolves it to the same club rather than recreating the split.

BEGIN;

CREATE TEMP TABLE club_merge (old_id INT PRIMARY KEY, new_id INT) ;
INSERT INTO club_merge VALUES (338, 3), (88, 347);

UPDATE matches m SET home_team_id = c.new_id FROM club_merge c WHERE m.home_team_id = c.old_id;
UPDATE matches m SET away_team_id = c.new_id FROM club_merge c WHERE m.away_team_id = c.old_id;
UPDATE match_events e      SET team_id = c.new_id FROM club_merge c WHERE e.team_id = c.old_id;
UPDATE match_lineups l     SET team_id = c.new_id FROM club_merge c WHERE l.team_id = c.old_id;
UPDATE match_team_stats s  SET team_id = c.new_id FROM club_merge c WHERE s.team_id = c.old_id;
UPDATE player_team_stints p SET team_id = c.new_id FROM club_merge c WHERE p.team_id = c.old_id;
UPDATE coach_team_stints k SET team_id = c.new_id FROM club_merge c WHERE k.team_id = c.old_id;

-- Provenance follows the club, so the old source ids still resolve to it.
UPDATE entity_source_map m SET entity_id = c.new_id
  FROM club_merge c WHERE m.entity_type = 'team' AND m.entity_id = c.old_id;

-- Participation rows move; the unique (edition, team) constraint cannot bite
-- because the pairs never share an edition, but say so explicitly anyway.
UPDATE competition_edition_teams t SET team_id = c.new_id
  FROM club_merge c WHERE t.team_id = c.old_id
    AND NOT EXISTS (SELECT 1 FROM competition_edition_teams x
                     WHERE x.competition_edition_id = t.competition_edition_id
                       AND x.team_id = c.new_id);
DELETE FROM competition_edition_teams t USING club_merge c WHERE t.team_id = c.old_id;

\echo 'anything still pointing at the merged clubs (must all be 0):'
SELECT (SELECT count(*) FROM matches WHERE home_team_id IN (338,88) OR away_team_id IN (338,88)) AS matches,
       (SELECT count(*) FROM match_events WHERE team_id IN (338,88)) AS events,
       (SELECT count(*) FROM match_lineups WHERE team_id IN (338,88)) AS lineups,
       (SELECT count(*) FROM competition_edition_teams WHERE team_id IN (338,88)) AS editions,
       (SELECT count(*) FROM player_team_stints WHERE team_id IN (338,88)) AS stints,
       (SELECT count(*) FROM coach_team_stints WHERE team_id IN (338,88)) AS coaches,
       (SELECT count(*) FROM entity_source_map WHERE entity_type='team' AND entity_id IN (338,88)) AS provenance;

DELETE FROM teams WHERE id IN (338, 88);

\echo 'no club now plays itself (must be 0):';
SELECT count(*) FROM matches WHERE home_team_id = away_team_id;

\echo 'merged club histories:';
SELECT t.id, t.name, min(s.label) AS first_season, max(s.label) AS last_season,
       count(DISTINCT ce.id) AS seasons, count(*) AS games
  FROM teams t
  JOIN matches m ON m.home_team_id = t.id OR m.away_team_id = t.id
  JOIN competition_editions ce ON ce.id = m.competition_edition_id AND ce.competition_id = 1
  JOIN seasons s ON s.id = ce.season_id
 WHERE t.id IN (3, 347)
 GROUP BY t.id, t.name;

COMMIT;
