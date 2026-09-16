-- Africa Cup of Nations: one side-swapped match, and 45 duplicate records.
--
-- 45 player records turned out to be 39 people. Nothing below creates or
-- deletes a goal; only which player a goal belongs to changes.
--
-- Prompted by a real discrepancy: André Ayew had 9 goals in the vault and 10 in
-- the official records. He had 10 all along -- one of them was filed under a
-- second copy of him.
--
-- Cross-checking the 31 players on Wikipedia's all-time Africa Cup of Nations
-- scoring list against the vault found two mechanisms, both identity, neither a
-- missing goal:
--
--   1. WhoScored short names. The editions loaded before the source exposed
--      player ids were keyed on `name:{team}:{name}`, so a man who appeared once
--      as "Mboma" and once as "Patrick Mboma" became two players.
--   2. Legacy SokaFC versus WhoScored. AFCON 2019 came from the legacy dump,
--      which spells players in full ("André Morgan Rami Ayew Dede Ayew"), while
--      2021 onward came from WhoScored ("André Ayew"). One career, two rows.
--
-- Ten of the merges are confirmed arithmetically: the merged total equals the
-- published all-time figure exactly -- Mboma 11, Kanouté 7, Francileudo Santos
-- 10, Flávio 7, Okocha 7, Abouzeid 7, El-Shazly 12, Mané 11, Ayew 10, Abdoulaye
-- Traoré 9. That last one was four records, including a "Troaré" typo.
--
-- What is NOT fixed here, and why: Hossam Hassan (4 of 11), Benni McCarthy (0 of
-- 7), Joel Tiéhi (5 of 10), Kalusha Bwalya (4 of 10) and Abedi Pele (3 of 7) are
-- short because the 1996 and 1998 tournaments name a scorer for 4 of their 171
-- goals. That is absent source data, not a vault defect, and no merge invents
-- it. Mengistu Worku is 8 against an official 10 with no duplicate and no gap in
-- coverage -- RSSSF's own match reports account for 8, so it is left alone.
--
-- Seven further same-surname pairs are deliberately left unmerged, because the
-- evidence does not settle them: Egypt's Khalil (1974/1976), Abdou (1974/1976)
-- and Abdelhamid (1986/1988), Cameroon's Ebongué (1984/1992), and Nigeria's
-- Odegbami and Lawal, where two brothers and two namesakes really did play.
-- Those are for a human to judge, and the audit now raises them.

BEGIN;

-- ---------------------------------------------------------------------------
-- Part 1: Zambia 2-2 Senegal, 1 February 2000 in Lagos -- all four scorers were
-- credited to the wrong side.
--
-- RSSSF writes scorers as [home; away], which the loader followed and which the
-- rest of the 2000 file obeys. This one line is written the other way round:
--
--   Zambia 2-2 Senegal [Henri Camara 47, Abdoulaye Mbaye 80;
--                       Laughter Chilembi 52, Kalusha Bwalya 87pen]
--
-- Camara and Mbaye are Senegalese; Chilembi and Bwalya are Zambian. The score is
-- right and is not touched -- only which side each goal belongs to.
--
-- This survived the load because the loader verifies each side's goal count
-- against that side's score, which a swap cannot break when the scores are
-- equal. All 61 pre-2002 score draws were re-checked by hand against the source
-- and their scorers' nationalities; this is the only one that was wrong.
-- ---------------------------------------------------------------------------

INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
VALUES ('match_event', 6, 6,
  'Zambia 2-2 Senegal, AFCON 2000 (match 22357): RSSSF wrote the scorer brackets in the opposite order to the fixture, so all four goals were credited to the wrong team. Re-sided by the scorers'' nationalities. Score unchanged. Found by auditing every pre-2002 score draw, the only shape in which a side-swap survives the loader''s per-side check.');

INSERT INTO reconciliation_diffs (reconciliation_run_id, entity_id_a, entity_id_b, field_name, value_a, value_b, resolution, resolved_value, resolved_at)
SELECT currval('reconciliation_runs_id_seq'), e.id, 22357, 'match_events.team_id',
       t.name, CASE WHEN e.team_id = 37 THEN 'Senegal' ELSE 'Zambia' END,
       'MANUAL', CASE WHEN e.team_id = 37 THEN '52' ELSE '37' END, now()
  FROM match_events e JOIN teams t ON t.id = e.team_id
 WHERE e.match_id = 22357;

-- 37 is Zambia, 52 is Senegal.
UPDATE match_events SET team_id = CASE WHEN team_id = 37 THEN 52 ELSE 37 END
 WHERE match_id = 22357;

-- The loader keyed these players' provenance on the team it believed they played
-- for, so the keys carry the same error.
UPDATE entity_source_map SET external_id = replace(external_id, 'afcon-37-', 'afcon-52-')
 WHERE entity_type = 'player' AND entity_id IN (11132, 11133);
UPDATE entity_source_map SET external_id = replace(external_id, 'afcon-52-', 'afcon-37-')
 WHERE entity_type = 'player' AND entity_id IN (11134, 11135);

-- ---------------------------------------------------------------------------
-- Part 2: the merges.
-- ---------------------------------------------------------------------------

INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
VALUES ('player', 1, 16,
  'Africa Cup of Nations scorer identities: 45 duplicate player records merged into 39 survivors. Two causes -- WhoScored short names keyed as name:{team}:{name} before player ids were available, and legacy SokaFC full names against WhoScored common names for AFCON 2019. Ten merges are confirmed by matching the published all-time total exactly. No goal event is created or deleted; only player_id changes.');

CREATE TEMP TABLE merges (survivor int, dead int, note text) ON COMMIT DROP;
INSERT INTO merges VALUES
  -- confirmed by the published all-time total
  ( 7190,  7165, 'Patrick Mboma = 11, official 11'),
  ( 7331,  7221, 'Frederic Kanoute = 7, official 7'),
  ( 7289,  7215, 'Francileudo Santos = 10, official 10'),
  ( 7289,  7208, 'Francileudo Santos = 10, official 10'),
  ( 7281,  7278, 'Flavio Amado = 7, official 7'),
  ( 7257, 11136, 'Jay-Jay Okocha = 7, official 7'),
  ( 7257, 11042, 'Jay-Jay Okocha = 7, official 7'),
  (10982, 10987, 'Taher Abouzeid = 7, official 7'),
  (10756, 10868, 'Hassan El-Shazly = 12, official 12'),
  ( 7693,  2057, 'Sadio Mane = 11, official 11'),
  ( 7400,  2199, 'Andre Ayew = 10, official 10'),
  (11009, 11027, 'Abdoulaye Traore = 9, official 9 (this row was the Troare typo)'),
  (11009, 11043, 'Abdoulaye Traore = 9, official 9'),
  (11009, 11065, 'Abdoulaye Traore = 9, official 9'),
  -- legacy SokaFC row against WhoScored row: one name expands the other, and
  -- their editions do not overlap
  ( 7679,  2198, 'Jordan Ayew / Jordan Pierre Ayew'),
  ( 7762,  2173, 'Trezeguet / Mahmoud Hassan Trezeguet'),
  ( 7840,  2236, 'William Troost-Ekong / William Paul Troost-Ekong'),
  ( 7661,  2166, 'Max Gradel / Max Alain Gradel'),
  ( 7768,  2051, 'Ismaila Sarr, accents only'),
  ( 7653,  2161, 'Serey Die / Geoffrey Serey Die'),
  ( 7594,  2119, 'Sofiane Feghouli, accents only'),
  ( 7695,  2209, 'Taha Khenissi / Taha Yassine Khenissi'),
  ( 7905,  2187, 'Chancel Mbemba / Chancel Mangulu Mbemba'),
  ( 1398,  2115, 'Baghdad Bounedjah, identical name'),
  ( 1225,  2080, 'Simon Msuva, identical name'),
  -- short name against full name, same nation, career-consistent, and no third
  -- player of that surname in the squads concerned
  (11142,  7149, 'Julius Aghahowa / Aghahowa'),
  ( 7422,  7258, 'Peter Osaze Odemwingie, three spellings'),
  ( 7422,  7248, 'Peter Osaze Odemwingie, three spellings'),
  ( 7264,  7253, 'John Utaka / Utaka, Nigeria 2004'),
  ( 7245,  7161, 'Siyabonga Nomvete / Nomvete'),
  ( 7205,  7261, 'Ziad Jaziri / Jaziri, Tunisia 2004'),
  ( 7294,  7212, 'Pascal Feindouno / Feindouno'),
  (11105,  7182, 'Marc-Vivien Foe / Foe'),
  (11006, 10984, 'Theophile Abega / Abega, Cameroon 1984'),
  (11012, 11056, 'Jules Bocande, accents only'),
  (10939, 10915, 'Opoku Afriye / Afriye, Ghana 1978'),
  (10828, 10853, 'Fantamady Keita / F.Keita, Mali 1972'),
  (10799, 10878, 'Raoul Kidumu / Kidumu, DR Congo 1968-1974'),
  (10807, 10824, 'Jean-Baptiste Ndoga / N''Doga, Cameroon 1970-1972'),
  (10817, 10875, 'Soriba Soumah Edente / Edente, Guinea 1970-1974'),
  (10819, 10889, 'Ibrahim Sory Keita Petit Sory / Petit Sory, Guinea'),
  (10957, 10911, 'Mahmoud El-Khatib: El Khatib / Al-Khatib, Egypt 1976-1980'),
  -- identities the side-swap above had split in two
  ( 7299, 11132, 'Henri Camara, Senegal: the swap created a second, Zambian copy'),
  (11135, 11017, 'Kalusha Bwalya: K.Bwalya, and the copy the swap made Senegalese'),
  (11135, 11068, 'Kalusha Bwalya: bare Bwalya, Zambia 1992');

-- Nothing may be merged into a record that is itself being merged away, or the
-- events would land on a deleted player.
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM merges m WHERE m.survivor IN (SELECT dead FROM merges);
  IF bad > 0 THEN RAISE EXCEPTION 'a survivor is also being merged away (% rows)', bad; END IF;
  SELECT count(*) INTO bad FROM (SELECT dead FROM merges GROUP BY dead HAVING count(*) > 1) x;
  IF bad > 0 THEN RAISE EXCEPTION 'a record is merged into two survivors (% rows)', bad; END IF;
END $$;

INSERT INTO reconciliation_diffs (reconciliation_run_id, entity_id_a, entity_id_b, field_name, value_a, value_b, resolution, resolved_value, resolved_at)
SELECT currval('reconciliation_runs_id_seq'), m.dead, m.survivor, 'players.id',
       d.full_name || ' (' || m.dead || '), ' ||
         (SELECT count(*) FROM match_events e WHERE e.player_id = m.dead) || ' events',
       s.full_name || ' (' || m.survivor || ')',
       'MANUAL', m.survivor::text, now()
  FROM merges m JOIN players d ON d.id = m.dead JOIN players s ON s.id = m.survivor;

-- A duplicate sometimes carries a detail the survivor lacks, because the two
-- sources described the same man differently. Keep it.
UPDATE players s SET
  dob             = coalesce(s.dob, x.dob),
  position        = coalesce(s.position, x.position),
  nationality_id  = coalesce(s.nationality_id, x.nationality_id),
  height_cm       = coalesce(s.height_cm, x.height_cm),
  preferred_foot  = coalesce(s.preferred_foot, x.preferred_foot),
  first_name      = coalesce(s.first_name, x.first_name),
  last_name       = coalesce(s.last_name, x.last_name)
 FROM (SELECT m.survivor,
              min(d.dob) dob, min(d.position) position, min(d.nationality_id) nationality_id,
              min(d.height_cm) height_cm, min(d.preferred_foot) preferred_foot,
              min(d.first_name) first_name, min(d.last_name) last_name
         FROM merges m JOIN players d ON d.id = m.dead GROUP BY m.survivor) x
WHERE s.id = x.survivor;

UPDATE match_events        e SET player_id         = m.survivor FROM merges m WHERE e.player_id         = m.dead;
UPDATE match_events        e SET related_player_id = m.survivor FROM merges m WHERE e.related_player_id = m.dead;
UPDATE match_lineups       l SET player_id         = m.survivor FROM merges m WHERE l.player_id         = m.dead;
UPDATE player_team_stints  t SET player_id         = m.survivor FROM merges m WHERE t.player_id         = m.dead;
UPDATE match_player_ratings r SET player_id        = m.survivor FROM merges m WHERE r.player_id         = m.dead;

-- Provenance moves with the events rather than being dropped, so a future
-- re-read of either source still lands on the surviving player. Where both
-- records were keyed identically by the same source, one key is enough.
DELETE FROM entity_source_map dup
 USING merges m, entity_source_map keep
 WHERE dup.entity_type = 'player' AND dup.entity_id = m.dead
   AND keep.entity_type = 'player' AND keep.entity_id = m.survivor
   AND keep.data_source_id = dup.data_source_id
   AND coalesce(keep.external_id, '') = coalesce(dup.external_id, '');
UPDATE entity_source_map esm SET entity_id = m.survivor
  FROM merges m WHERE esm.entity_type = 'player' AND esm.entity_id = m.dead;

-- An identical spell recorded under both names collapses to one.
DELETE FROM player_team_stints a
 USING player_team_stints b
 WHERE a.player_id IN (SELECT survivor FROM merges)
   AND a.player_id = b.player_id AND a.team_id = b.team_id
   AND coalesce(a.start_date, '-infinity') = coalesce(b.start_date, '-infinity')
   AND coalesce(a.end_date, 'infinity')    = coalesce(b.end_date, 'infinity')
   AND a.id > b.id;

DELETE FROM players WHERE id IN (SELECT dead FROM merges);

-- ---------------------------------------------------------------------------
-- Verification, inside the transaction.
-- ---------------------------------------------------------------------------
SET timezone = 'UTC';

\echo ''
\echo 'Zambia 2-2 Senegal (match 22357) -- each goal against the scorer''s own nation:'
SELECT coalesce(p.full_name, '(own goal)') AS scorer, t.name AS credited_to, e.minute, e.type
  FROM match_events e LEFT JOIN players p ON p.id = e.player_id JOIN teams t ON t.id = e.team_id
 WHERE e.match_id = 22357 ORDER BY e.minute;

\echo ''
\echo 'Every pre-2002 event log must still reproduce its score (expect equal counts):'
WITH ev AS (
  SELECT m.id,
    count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL') AND
      (CASE WHEN e.type = 'OWN_GOAL'
            THEN CASE WHEN e.team_id = m.home_team_id THEN m.away_team_id ELSE m.home_team_id END
            ELSE e.team_id END) = m.home_team_id) AS h,
    count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL') AND
      (CASE WHEN e.type = 'OWN_GOAL'
            THEN CASE WHEN e.team_id = m.home_team_id THEN m.away_team_id ELSE m.home_team_id END
            ELSE e.team_id END) = m.away_team_id) AS a
    FROM matches m JOIN match_events e ON e.match_id = m.id
    JOIN competition_editions ce ON ce.id = m.competition_edition_id
    JOIN seasons s ON s.id = ce.season_id
   WHERE ce.competition_id = 16 AND s.label ~ '^[0-9]{4}$' AND s.label::int < 2002
   GROUP BY m.id)
SELECT count(*) AS with_events,
       count(*) FILTER (WHERE ev.h = m.home_score AND ev.a = m.away_score) AS reproduce_score
  FROM ev JOIN matches m ON m.id = ev.id;

\echo ''
\echo 'The ten totals that must now equal the published figures:'
WITH want(pid, who, official) AS (VALUES
  ( 7190, 'Patrick Mboma',       11), ( 7331, 'Frederic Kanoute',    7),
  ( 7289, 'Francileudo Santos',  10), ( 7281, 'Flavio Amado',        7),
  ( 7257, 'Jay-Jay Okocha',       7), (10982, 'Taher Abouzeid',      7),
  (10756, 'Hassan El-Shazly',    12), ( 7693, 'Sadio Mane',         11),
  ( 7400, 'Andre Ayew',          10), (11009, 'Abdoulaye Traore',    9))
SELECT w.who, w.official, v.vault,
       CASE WHEN v.vault = w.official THEN 'ok' ELSE 'MISMATCH' END AS verdict
  FROM want w
  CROSS JOIN LATERAL (
    SELECT count(*) AS vault
      FROM match_events e
      JOIN matches m ON m.id = e.match_id
      JOIN competition_editions ce ON ce.id = m.competition_edition_id
     WHERE e.player_id = w.pid AND ce.competition_id = 16
       AND e.type IN ('GOAL','PENALTY_GOAL')) v
 ORDER BY w.official DESC, w.who;

\echo ''
\echo 'Players still scoring for two nations -- expect only Simon Msuva, because'
\echo '"Taifa Stars" and "Tanzania" are two team records for one national side.'
\echo 'That is a separate defect and is not fixed here.'
SELECT p.full_name, string_agg(DISTINCT t.name, ' / ') AS nations
  FROM match_events e JOIN players p ON p.id = e.player_id JOIN teams t ON t.id = e.team_id
 WHERE e.type IN ('GOAL','PENALTY_GOAL') AND t.type = 'NATIONAL'
 GROUP BY p.id, p.full_name HAVING count(DISTINCT t.id) > 1;

\echo ''
\echo 'Merged-away records must be gone (expect 0), and nothing may reference them:'
SELECT (SELECT count(*) FROM players WHERE id IN (SELECT dead FROM merges)) AS players_left,
       (SELECT count(*) FROM match_events WHERE player_id IN (SELECT dead FROM merges)) AS events_left,
       (SELECT count(*) FROM entity_source_map WHERE entity_type = 'player'
          AND entity_id IN (SELECT dead FROM merges)) AS provenance_left;

COMMIT;
