-- Three more surname pairs settled by asking the source: Guel, Polley, Ebongué.
--
-- Each was an open SCORER_NAME_ABBREVIATED candidate, left unmerged because a
-- surname is not evidence. Wikipedia's match reports name the scorer of all six
-- goals, and in each case the named man is the only candidate anywhere in the
-- articles concerned:
--
--   Ivory Coast
--     11085 "Guel"            1994 Ivory Coast 4-0 Sierra Leone  34'
--            Wikipedia: [[Tchiressoua Guel|Guel]] {{goal|35}} in that 4-0,
--            alongside Tiéhi's three. One minute apart.
--     11106 "Tchiresso Guel"  1998 (x2) and 2000 -- already named.
--
--   Ghana
--     11091 "Polley"          1994 Ghana 1-0 Senegal             88'
--            Wikipedia: [[Prince Polley|Polley]] {{goal|42}}, same fixture and
--            date. The sources disagree about WHEN by 46 minutes, which is a
--            timing question; the minute is left at RSSSF's 88. They agree on
--            who, which is what this fix is about.
--     11073 "Prince Polley"   1992 Ghana 2-1 Nigeria             54'
--            Wikipedia: [[Prince Polley]] {{goal|54}}. Exact.
--
--   Cameroon
--     11071 "Ebongue"         1992 Cameroon 1-0 Senegal          89'
--            Wikipedia: [[Ernest Ebongué|Ebongué]] {{goal|89}}. Exact.
--     11007 "Ernest Ebongué"  1984 Cameroon 3-1 Nigeria          84'
--            Wikipedia: [[Ernest Ebongué|Ebongué]] {{goal|84}}. Exact.
--
-- The Ebongué pair is the one that had looked least safe, because eight years
-- separate the two goals and a career that long is not the way to bet on a
-- surname alone. The source closes it: the same Ernest Ebongué is named in
-- 1984 -- where he also took a penalty in the final's shoot-out -- and in 1992.
-- That is exactly why these were held back rather than guessed at.
--
-- Names are left as they stand. Each survivor already carries a full name, so
-- nothing here reads as an abbreviation of itself the way "Muda Lawal" did.

BEGIN;

INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
VALUES ('player', 6, 5,
  'Three surname pairs merged on Wikipedia match reports: Ivory Coast''s Guel (11085 into 11106), Ghana''s Polley (11091 into 11073) and Cameroon''s Ebongué (11071 into 11007). All six goals are named in the source, five to the exact minute; Polley''s 1994 goal is the same fixture with a 46-minute timing disagreement, and the vault''s minute stands. Raised by the audit check SCORER_NAME_ABBREVIATED.');

CREATE TEMP TABLE merges (survivor int, dead int, note text) ON COMMIT DROP;
INSERT INTO merges VALUES
  (11106, 11085, 'Tchiresso Guel: Wikipedia names Tchiressoua Guel for the 1994 goal'),
  (11073, 11091, 'Prince Polley: Wikipedia names him for the 1994 goal, same fixture'),
  (11007, 11071, 'Ernest Ebongué: Wikipedia names him in both 1984 and 1992');

DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM merges m WHERE m.survivor IN (SELECT dead FROM merges);
  IF bad > 0 THEN RAISE EXCEPTION 'a survivor is also being merged away'; END IF;
  SELECT count(*) INTO bad FROM (SELECT dead FROM merges GROUP BY dead HAVING count(*) > 1) x;
  IF bad > 0 THEN RAISE EXCEPTION 'a record is merged into two survivors'; END IF;
  -- Two records that shared a pitch are two people, whatever the name says.
  SELECT count(*) INTO bad FROM merges m
   WHERE EXISTS (SELECT 1 FROM match_events a JOIN match_events b ON a.match_id = b.match_id
                  WHERE a.player_id = m.survivor AND b.player_id = m.dead)
      OR EXISTS (SELECT 1 FROM match_lineups a JOIN match_lineups b ON a.match_id = b.match_id
                  WHERE a.player_id = m.survivor AND b.player_id = m.dead);
  IF bad > 0 THEN RAISE EXCEPTION '% pair(s) appear in the same match', bad; END IF;
  -- Each pair must belong to one country, or they are not one man.
  SELECT count(*) INTO bad FROM merges m
   WHERE (SELECT count(DISTINCT e.team_id) FROM match_events e
           WHERE e.player_id IN (m.survivor, m.dead)) <> 1;
  IF bad > 0 THEN RAISE EXCEPTION '% pair(s) span more than one team', bad; END IF;
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

UPDATE players s SET
  dob            = coalesce(s.dob, x.dob),
  position       = coalesce(s.position, x.position),
  nationality_id = coalesce(s.nationality_id, x.nationality_id)
 FROM (SELECT m.survivor, min(d.dob) dob, min(d.position) position,
              min(d.nationality_id) nationality_id
         FROM merges m JOIN players d ON d.id = m.dead GROUP BY m.survivor) x
WHERE s.id = x.survivor;

UPDATE entity_source_map esm SET entity_id = m.survivor
  FROM merges m WHERE esm.entity_type = 'player' AND esm.entity_id = m.dead;

DELETE FROM players WHERE id IN (SELECT dead FROM merges);

-- Wikipedia identified all three, so it gets provenance alongside RSSSF's.
INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
VALUES ('player', 11106, 5, 'wikipedia-afcon-22-Tchiressoua Guel', 1.0),
       ('player', 11073, 5, 'wikipedia-afcon-20-Prince Polley', 1.0),
       ('player', 11007, 5, 'wikipedia-afcon-5-Ernest Ebongue', 1.0)
ON CONFLICT (entity_type, data_source_id, external_id) DO UPDATE SET last_synced_at = now();

SET timezone = 'UTC';

\echo ''
\echo 'The three survivors, with every goal now in one place:'
SELECT p.id, p.full_name, t.name AS country, count(*) AS goals,
       string_agg(DISTINCT s.label, ', ' ORDER BY s.label) AS tournaments
  FROM match_events e JOIN players p ON p.id = e.player_id JOIN teams t ON t.id = e.team_id
  JOIN matches m ON m.id = e.match_id
  JOIN competition_editions ce ON ce.id = m.competition_edition_id
  JOIN seasons s ON s.id = ce.season_id
 WHERE p.id IN (11106, 11073, 11007) AND e.type IN ('GOAL','PENALTY_GOAL')
 GROUP BY p.id, p.full_name, t.name ORDER BY p.full_name;

\echo ''
\echo 'No Guel, Polley or Ebongué record may be left over:'
SELECT p.id, p.full_name FROM players p
 WHERE p.full_name ILIKE '%guel%' OR p.full_name ILIKE '%polley%' OR p.full_name ILIKE '%ebongu%'
 ORDER BY p.full_name;

\echo ''
\echo 'Merged-away records gone, nothing referencing them (expect zeros):'
SELECT (SELECT count(*) FROM players WHERE id IN (SELECT dead FROM merges)) AS players_left,
       (SELECT count(*) FROM match_events WHERE player_id IN (SELECT dead FROM merges)) AS events_left,
       (SELECT count(*) FROM entity_source_map WHERE entity_type = 'player'
          AND entity_id IN (SELECT dead FROM merges)) AS provenance_left;

COMMIT;
