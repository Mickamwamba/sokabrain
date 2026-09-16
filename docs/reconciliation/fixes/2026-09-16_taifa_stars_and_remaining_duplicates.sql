-- Tanzania was two national teams, and five more players were two people.
--
-- Found by the audit's new Identity checks, run straight after the Africa Cup
-- of Nations merges of 2026-09-15. They are the same defect one level up: the
-- legacy SokaFC dump and WhoScored describe the same entity differently, and
-- nothing had ever compared them.
--
--   * "Taifa Stars" (team 23) is the nickname of Tanzania (team 91). Both are
--     NATIONAL teams of country 56. They have never played each other and never
--     appear in the same edition -- Taifa Stars holds only 11 matches, from the
--     2017/18 Kagame Cup and the 2019 qualifiers, while Tanzania holds the rest.
--     Simon Msuva was the giveaway: he was the one player in the vault credited
--     with goals for two different countries, both of them his own.
--
--   * Famara Diédhiou, Franck Kessié and Aristide Bancé each have a legacy row
--     and a WhoScored row covering different seasons, the accent being the only
--     difference in the name.
--
--   * Simon Msuva (1400) and Enosh Ochieng' (2303) are second legacy rows for
--     players the legacy dump already held. These two share seasons with their
--     twin, so they were checked further: neither pair ever appears in the same
--     match, in the event log or in a team sheet, and their club spells agree.
--
-- Left alone, and reported by the audit instead: Mali's bare "Touré" and
-- "Coulibaly" and Nigeria's "Lawal". A surname alone never merges two players.

BEGIN;

-- ---------------------------------------------------------------------------
-- Part 1: Taifa Stars into Tanzania.
-- ---------------------------------------------------------------------------

INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
VALUES ('team', 1, 16,
  'Taifa Stars (team 23) and Tanzania (team 91) are one national side under two records: same country, never opponents, never in the same edition. Merged into 91. 11 matches, 13 events and 4 spells moved. Detected by the audit check SCORER_TWO_NATIONS, which found Simon Msuva scoring for both.');

INSERT INTO reconciliation_diffs (reconciliation_run_id, entity_id_a, entity_id_b, field_name, value_a, value_b, resolution, resolved_value, resolved_at)
VALUES (currval('reconciliation_runs_id_seq'), 23, 91, 'teams.id',
        'Taifa Stars (23), 11 matches', 'Tanzania (91), 20 matches', 'MANUAL', '91', now());

-- Guard the one thing that would make this merge wrong.
DO $$
DECLARE clash int;
BEGIN
  SELECT count(*) INTO clash FROM matches
   WHERE (home_team_id = 23 AND away_team_id = 91) OR (home_team_id = 91 AND away_team_id = 23);
  IF clash > 0 THEN RAISE EXCEPTION 'Taifa Stars and Tanzania play each other in % matches', clash; END IF;
END $$;

UPDATE matches                   SET home_team_id = 91 WHERE home_team_id = 23;
UPDATE matches                   SET away_team_id = 91 WHERE away_team_id = 23;
UPDATE match_events              SET team_id = 91 WHERE team_id = 23;
UPDATE match_lineups             SET team_id = 91 WHERE team_id = 23;
UPDATE match_team_stats          SET team_id = 91 WHERE team_id = 23;
UPDATE coach_team_stints         SET team_id = 91 WHERE team_id = 23;
UPDATE player_team_stints        SET team_id = 91 WHERE team_id = 23;
UPDATE competition_edition_teams SET team_id = 91 WHERE team_id = 23;
UPDATE entity_source_map         SET entity_id = 91 WHERE entity_type = 'team' AND entity_id = 23;

DELETE FROM teams WHERE id = 23;

-- ---------------------------------------------------------------------------
-- Part 2: the five players.
-- ---------------------------------------------------------------------------

INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
VALUES ('player', 1, 16,
  'Five players held twice: Famara Diedhiou, Franck Kessie and Aristide Bance as a legacy row against a WhoScored row over different seasons, and Simon Msuva and Enosh Ochieng as two legacy rows. Neither same-season pair ever appears in one match or team sheet.');

CREATE TEMP TABLE merges (survivor int, dead int, note text) ON COMMIT DROP;
INSERT INTO merges VALUES
  (7723, 2480, 'Famara Diedhiou: legacy 2019/20, WhoScored 2021'),
  (7859, 2164, 'Franck Kessie: legacy 2018/19-2019/20, WhoScored 2021-2025'),
  (7603, 2476, 'Aristide Bance: legacy 2019/20, WhoScored 2013-2017'),
  (1225, 1400, 'Simon Msuva: two legacy rows, no shared match or team sheet'),
  (2393, 2303, 'Enosh Ochieng: apostrophe variant, same club and start date');

DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM merges m WHERE m.survivor IN (SELECT dead FROM merges);
  IF bad > 0 THEN RAISE EXCEPTION 'a survivor is also being merged away'; END IF;
  -- Two records that shared a pitch are two people, whatever the name says.
  SELECT count(*) INTO bad
    FROM merges m
   WHERE EXISTS (SELECT 1 FROM match_events a JOIN match_events b ON a.match_id = b.match_id
                  WHERE a.player_id = m.survivor AND b.player_id = m.dead)
      OR EXISTS (SELECT 1 FROM match_lineups a JOIN match_lineups b ON a.match_id = b.match_id
                  WHERE a.player_id = m.survivor AND b.player_id = m.dead);
  IF bad > 0 THEN RAISE EXCEPTION '% pair(s) appear in the same match', bad; END IF;
END $$;

INSERT INTO reconciliation_diffs (reconciliation_run_id, entity_id_a, entity_id_b, field_name, value_a, value_b, resolution, resolved_value, resolved_at)
SELECT currval('reconciliation_runs_id_seq'), m.dead, m.survivor, 'players.id',
       d.full_name || ' (' || m.dead || '), ' ||
         (SELECT count(*) FROM match_events e WHERE e.player_id = m.dead) || ' events',
       s.full_name || ' (' || m.survivor || ')', 'MANUAL', m.survivor::text, now()
  FROM merges m JOIN players d ON d.id = m.dead JOIN players s ON s.id = m.survivor;

UPDATE players s SET
  dob            = coalesce(s.dob, x.dob),
  position       = coalesce(s.position, x.position),
  nationality_id = coalesce(s.nationality_id, x.nationality_id),
  height_cm      = coalesce(s.height_cm, x.height_cm),
  preferred_foot = coalesce(s.preferred_foot, x.preferred_foot),
  first_name     = coalesce(s.first_name, x.first_name),
  last_name      = coalesce(s.last_name, x.last_name)
 FROM (SELECT m.survivor, min(d.dob) dob, min(d.position) position, min(d.nationality_id) nationality_id,
              min(d.height_cm) height_cm, min(d.preferred_foot) preferred_foot,
              min(d.first_name) first_name, min(d.last_name) last_name
         FROM merges m JOIN players d ON d.id = m.dead GROUP BY m.survivor) x
WHERE s.id = x.survivor;

UPDATE match_events         e SET player_id         = m.survivor FROM merges m WHERE e.player_id         = m.dead;
UPDATE match_events         e SET related_player_id = m.survivor FROM merges m WHERE e.related_player_id = m.dead;
UPDATE match_lineups        l SET player_id         = m.survivor FROM merges m WHERE l.player_id         = m.dead;
UPDATE player_team_stints   t SET player_id         = m.survivor FROM merges m WHERE t.player_id         = m.dead;
UPDATE match_player_ratings r SET player_id         = m.survivor FROM merges m WHERE r.player_id         = m.dead;

DELETE FROM entity_source_map dup
 USING merges m, entity_source_map keep
 WHERE dup.entity_type = 'player' AND dup.entity_id = m.dead
   AND keep.entity_type = 'player' AND keep.entity_id = m.survivor
   AND keep.data_source_id = dup.data_source_id
   AND coalesce(keep.external_id, '') = coalesce(dup.external_id, '');
UPDATE entity_source_map esm SET entity_id = m.survivor
  FROM merges m WHERE esm.entity_type = 'player' AND esm.entity_id = m.dead;

-- The Taifa Stars merge above can leave a player with the same spell twice,
-- one recorded under each name for the national side.
DELETE FROM player_team_stints a
 USING player_team_stints b
 WHERE a.player_id = b.player_id AND a.team_id = b.team_id
   AND coalesce(a.start_date, '-infinity') = coalesce(b.start_date, '-infinity')
   AND coalesce(a.end_date, 'infinity')    = coalesce(b.end_date, 'infinity')
   AND a.id > b.id;

DELETE FROM players WHERE id IN (SELECT dead FROM merges);

-- ---------------------------------------------------------------------------
-- Verification.
-- ---------------------------------------------------------------------------
SET timezone = 'UTC';

\echo ''
\echo 'No team named Taifa Stars, and Tanzania holds both records'' matches:'
SELECT (SELECT count(*) FROM teams WHERE name = 'Taifa Stars') AS taifa_stars_left,
       (SELECT count(*) FROM matches WHERE home_team_id = 91 OR away_team_id = 91) AS tanzania_matches,
       (SELECT count(*) FROM match_events WHERE team_id = 91) AS tanzania_events;

\echo ''
\echo 'Nobody scores for two nations any more (expect no rows):'
SELECT p.full_name, string_agg(DISTINCT t.name, ' / ') AS nations
  FROM match_events e JOIN players p ON p.id = e.player_id JOIN teams t ON t.id = e.team_id
 WHERE e.type IN ('GOAL','PENALTY_GOAL') AND t.type = 'NATIONAL'
 GROUP BY p.id, p.full_name HAVING count(DISTINCT t.id) > 1;

\echo ''
\echo 'The merged players, with their goals now in one place:'
SELECT p.id, p.full_name,
       count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL')) AS goals
  FROM players p JOIN match_events e ON e.player_id = p.id
 WHERE p.id IN (7723, 7859, 7603, 1225, 2393)
 GROUP BY p.id, p.full_name ORDER BY p.full_name;

\echo ''
\echo 'Merged-away records gone, nothing referencing them (expect zeros):'
SELECT (SELECT count(*) FROM players WHERE id IN (SELECT dead FROM merges)) AS players_left,
       (SELECT count(*) FROM match_events WHERE player_id IN (SELECT dead FROM merges)) AS events_left,
       (SELECT count(*) FROM match_events WHERE team_id = 23) AS events_on_old_team;

COMMIT;
