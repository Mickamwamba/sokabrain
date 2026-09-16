-- Nigeria's four Lawal records are two men.
--
-- The audit reported them as a SCORER_NAME_ABBREVIATED candidate and they were
-- deliberately left unmerged twice, because a surname is not evidence and
-- Nigeria really did field more than one Lawal. Wikipedia's match reports for
-- 1976, 1980 and 2002 settle it, naming the scorer of every one of these goals
-- with the minutes agreeing:
--
--   10904 "Lawal"        1976 Guinea 1-1 Nigeria      55'  -> Mudashiru Lawal
--                        1976 Nigeria 3-2 Egypt       82'  -> Mudashiru Lawal
--                        1980 Nigeria 3-1 Tanzania    11'  -> Muda Lawal
--   10960 "Muda Lawal"   1980 Nigeria 3-0 Algeria     50'  -> Muda Lawal
--                        1984 Cameroon 3-1 Nigeria    10'  (RSSSF, already named)
--
--   7189  "Lawal"        2002 Nigeria 1-0 Ghana       79'  -> Garba Lawal (80')
--   7252  "Garba Lawal"  2004, 2006                        (WhoScored, named)
--
-- "Muda" is the short form of Mudashiru, so 10904 and 10960 are one player with
-- five Africa Cup of Nations goals across 1976, 1980 and 1984. He is renamed to
-- Mudashiru Lawal, the name the source that identified him uses; the nickname
-- alone is what made the record ambiguous in the first place.
--
-- Garba Lawal is a different man entirely -- born 1974, a generation later --
-- and his own two records merge separately. Nothing joins the two careers.
--
-- The remaining vault "Lawal" spellings after this are none: all four records
-- become two, each with a full name.

BEGIN;

INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
VALUES ('player', 6, 5,
  'Nigeria''s four Lawal player records resolved into two people using Wikipedia match reports for 1976, 1980 and 2002: Mudashiru "Muda" Lawal (10904 merged into 10960, renamed to his full name, 5 AFCON goals 1976-1984) and Garba Lawal (7189 merged into 7252, 3 goals 2002-2006). Raised by the audit check SCORER_NAME_ABBREVIATED and twice left alone for want of evidence.');

CREATE TEMP TABLE merges (survivor int, dead int, note text) ON COMMIT DROP;
INSERT INTO merges VALUES
  (10960, 10904, 'Mudashiru Lawal: Wikipedia names all three of 10904''s goals as his'),
  ( 7252,  7189, 'Garba Lawal: Wikipedia names the 2002 Ghana goal as his');

-- The guards that made this worth waiting for evidence on.
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
  IF bad > 0 THEN RAISE EXCEPTION '% pair(s) appear in the same match', bad; END IF;
  -- The two careers must not touch: Muda's end and Garba's start are 17 years apart.
  SELECT count(*) INTO bad FROM match_events e
    JOIN matches m2 ON m2.id = e.match_id
    JOIN competition_editions ce ON ce.id = m2.competition_edition_id
    JOIN seasons s ON s.id = ce.season_id
   WHERE e.player_id IN (10904, 10960) AND s.label ~ '^[0-9]{4}$' AND s.label::int > 1990;
  IF bad > 0 THEN RAISE EXCEPTION 'a Muda Lawal goal sits after 1990'; END IF;
  SELECT count(*) INTO bad FROM match_events e
    JOIN matches m2 ON m2.id = e.match_id
    JOIN competition_editions ce ON ce.id = m2.competition_edition_id
    JOIN seasons s ON s.id = ce.season_id
   WHERE e.player_id IN (7189, 7252) AND s.label ~ '^[0-9]{4}$' AND s.label::int < 1990;
  IF bad > 0 THEN RAISE EXCEPTION 'a Garba Lawal goal sits before 1990'; END IF;
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

-- Provenance moves with the events, so a re-read of either source still lands
-- on the surviving player.
UPDATE entity_source_map esm SET entity_id = m.survivor
  FROM merges m WHERE esm.entity_type = 'player' AND esm.entity_id = m.dead;

DELETE FROM players WHERE id IN (SELECT dead FROM merges);

-- "Muda" is a nickname. Record the name the identifying source gives, and its
-- provenance, so the record no longer reads as an abbreviation of itself.
INSERT INTO reconciliation_diffs (reconciliation_run_id, entity_id_a, entity_id_b, field_name, value_a, value_b, resolution, resolved_value, resolved_at)
VALUES (currval('reconciliation_runs_id_seq'), 10960, 10960, 'players.full_name',
        'Muda Lawal', 'Mudashiru Lawal', 'MANUAL', 'Mudashiru Lawal', now());

UPDATE players SET full_name = 'Mudashiru Lawal' WHERE id = 10960;

INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
VALUES ('player', 10960, 5, 'wikipedia-afcon-39-Mudashiru Lawal', 1.0)
ON CONFLICT (entity_type, data_source_id, external_id) DO UPDATE SET last_synced_at = now();

SET timezone = 'UTC';

\echo ''
\echo 'Every Nigeria Lawal record that remains, and its goals:'
SELECT p.id, p.full_name, count(*) AS goals,
       string_agg(DISTINCT s.label, ', ' ORDER BY s.label) AS tournaments
  FROM match_events e JOIN players p ON p.id = e.player_id
  JOIN matches m ON m.id = e.match_id
  JOIN competition_editions ce ON ce.id = m.competition_edition_id
  JOIN seasons s ON s.id = ce.season_id
 WHERE p.full_name ILIKE '%lawal%' AND e.type IN ('GOAL','PENALTY_GOAL')
 GROUP BY p.id, p.full_name ORDER BY p.id;

\echo ''
\echo 'Merged-away records gone, nothing referencing them (expect zeros):'
SELECT (SELECT count(*) FROM players WHERE id IN (SELECT dead FROM merges)) AS players_left,
       (SELECT count(*) FROM match_events WHERE player_id IN (SELECT dead FROM merges)) AS events_left,
       (SELECT count(*) FROM entity_source_map WHERE entity_type = 'player'
          AND entity_id IN (SELECT dead FROM merges)) AS provenance_left;

COMMIT;
