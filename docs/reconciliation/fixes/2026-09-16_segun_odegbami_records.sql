-- Nigeria's two Odegbami records are one man: Segun Odegbami.
--
-- The audit reported them as a SCORER_NAME_ABBREVIATED candidate and they were
-- left alone twice, because Nigeria could have fielded two Odegbamis and a
-- surname is not evidence. Wikipedia's 1978 and 1980 match reports name the
-- scorer of all six goals, and the minutes agree with the vault exactly:
--
--   10919 "Odegbami"        1978 Nigeria 4-2 Upper Volta  44'  -> Segun Odegbami
--                           1978 Nigeria 4-2 Upper Volta  82'  -> Segun Odegbami
--                           1978 Nigeria 1-1 Ghana        33'  -> Segun Odegbami
--                           1980 Nigeria 3-1 Tanzania     85'  -> Segun Odegbami
--   10959 "Segun Odegbami"  1980 Nigeria 3-0 Algeria       2'  -> Segun Odegbami
--                           1980 Nigeria 3-0 Algeria      42'  -> Segun Odegbami
--
-- Wikipedia writes the first pair as a single template, `{{goal|44||82}}`, so
-- both minutes belong to the one name it carries. No other Odegbami appears
-- anywhere in either article -- not in a match report, not in a squad, not in
-- the scoring lists -- so there is no second man to confuse him with.
--
-- The arithmetic confirms it independently, the way the published all-time
-- totals confirmed the merges of 2026-09-15. The 1980 article names its top
-- scorers as "Khalid Labied / Segun Odegbami (3 goals each)". The vault splits
-- Odegbami's three 1980 goals across these two records, 1 and 2; merging them
-- gives exactly the 3 the source claims. Separately they give a false 1 and a
-- false 2, and neither matches anything.
--
-- He keeps the full name already on the surviving record. Six Africa Cup of
-- Nations goals, 1978 and 1980.

BEGIN;

INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
VALUES ('player', 6, 5,
  'Nigeria''s "Odegbami" (10919, 4 goals) and "Segun Odegbami" (10959, 2 goals) are one player. Wikipedia''s 1978 and 1980 match reports name Segun Odegbami for all six, with minutes agreeing, and the 1980 article''s own top-scorer line of 3 goals is only reproduced once they are merged. Raised by the audit check SCORER_NAME_ABBREVIATED and twice left alone for want of evidence.');

CREATE TEMP TABLE merges (survivor int, dead int, note text) ON COMMIT DROP;
INSERT INTO merges VALUES
  (10959, 10919, 'Segun Odegbami: Wikipedia names all four of 10919''s goals as his');

DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM merges m WHERE m.survivor IN (SELECT dead FROM merges);
  IF bad > 0 THEN RAISE EXCEPTION 'a survivor is also being merged away'; END IF;
  -- Two records that shared a pitch are two people, whatever the name says.
  SELECT count(*) INTO bad FROM merges m
   WHERE EXISTS (SELECT 1 FROM match_events a JOIN match_events b ON a.match_id = b.match_id
                  WHERE a.player_id = m.survivor AND b.player_id = m.dead)
      OR EXISTS (SELECT 1 FROM match_lineups a JOIN match_lineups b ON a.match_id = b.match_id
                  WHERE a.player_id = m.survivor AND b.player_id = m.dead);
  IF bad > 0 THEN RAISE EXCEPTION 'the two records appear in the same match'; END IF;
  -- Both records must be Nigerian, and confined to the years Wikipedia covers here.
  SELECT count(*) INTO bad FROM match_events e JOIN teams t ON t.id = e.team_id
   WHERE e.player_id IN (10919, 10959) AND t.name <> 'Nigeria';
  IF bad > 0 THEN RAISE EXCEPTION 'an Odegbami goal is credited to another country'; END IF;
  SELECT count(*) INTO bad FROM match_events e
    JOIN matches m2 ON m2.id = e.match_id
    JOIN competition_editions ce ON ce.id = m2.competition_edition_id
    JOIN seasons s ON s.id = ce.season_id
   WHERE e.player_id IN (10919, 10959)
     AND (s.label !~ '^[0-9]{4}$' OR s.label::int NOT IN (1978, 1980));
  IF bad > 0 THEN RAISE EXCEPTION 'an Odegbami goal falls outside 1978 and 1980'; END IF;
END $$;

INSERT INTO reconciliation_diffs (reconciliation_run_id, entity_id_a, entity_id_b, field_name, value_a, value_b, resolution, resolved_value, resolved_at)
SELECT currval('reconciliation_runs_id_seq'), m.dead, m.survivor, 'players.id',
       d.full_name || ' (' || m.dead || '), ' ||
         (SELECT count(*) FROM match_events e WHERE e.player_id = m.dead) || ' events',
       s.full_name || ' (' || m.survivor || ')', 'MANUAL', m.survivor::text, now()
  FROM merges m JOIN players d ON d.id = m.dead JOIN players s ON s.id = m.survivor;

UPDATE match_events        e SET player_id         = m.survivor FROM merges m WHERE e.player_id         = m.dead;
UPDATE match_events        e SET related_player_id = m.survivor FROM merges m WHERE e.related_player_id = m.dead;
UPDATE match_lineups       l SET player_id         = m.survivor FROM merges m WHERE l.player_id         = m.dead;
UPDATE player_team_stints  t SET player_id         = m.survivor FROM merges m WHERE t.player_id         = m.dead;
UPDATE match_player_ratings r SET player_id        = m.survivor FROM merges m WHERE r.player_id         = m.dead;

UPDATE players s SET nationality_id = coalesce(s.nationality_id, x.nationality_id)
  FROM (SELECT m.survivor, min(d.nationality_id) AS nationality_id
          FROM merges m JOIN players d ON d.id = m.dead GROUP BY m.survivor) x
 WHERE s.id = x.survivor;

UPDATE entity_source_map esm SET entity_id = m.survivor
  FROM merges m WHERE esm.entity_type = 'player' AND esm.entity_id = m.dead;

DELETE FROM players WHERE id IN (SELECT dead FROM merges);

-- Wikipedia identified him, so it gets a provenance row alongside RSSSF's.
INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
VALUES ('player', 10959, 5, 'wikipedia-afcon-39-Segun Odegbami', 1.0)
ON CONFLICT (entity_type, data_source_id, external_id) DO UPDATE SET last_synced_at = now();

SET timezone = 'UTC';

\echo ''
\echo 'Segun Odegbami, by tournament (1978 must be 3 and 1980 must be 3):'
SELECT s.label, count(*) AS goals
  FROM match_events e JOIN matches m ON m.id = e.match_id
  JOIN competition_editions ce ON ce.id = m.competition_edition_id
  JOIN seasons s ON s.id = ce.season_id
 WHERE e.player_id = 10959 AND e.type IN ('GOAL','PENALTY_GOAL')
 GROUP BY s.label ORDER BY s.label;

\echo ''
\echo 'Every Odegbami record that remains:'
SELECT p.id, p.full_name,
       (SELECT count(*) FROM match_events e WHERE e.player_id = p.id) AS events
  FROM players p WHERE p.full_name ILIKE '%odegbami%' ORDER BY p.id;

\echo ''
\echo 'Merged-away record gone, nothing referencing it (expect zeros):'
SELECT (SELECT count(*) FROM players WHERE id IN (SELECT dead FROM merges)) AS players_left,
       (SELECT count(*) FROM match_events WHERE player_id IN (SELECT dead FROM merges)) AS events_left,
       (SELECT count(*) FROM entity_source_map WHERE entity_type = 'player'
          AND entity_id IN (SELECT dead FROM merges)) AS provenance_left;

COMMIT;
