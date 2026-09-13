-- Own goals filed under the wrong team, TPL 2023/24 to 2025/26 (ligikuu.co.tz).
--
-- The vault's rule (principle 5): an OWN_GOAL's team is the SCORING PLAYER'S
-- OWN team, and the goal counts for the other side. normalize_ligikuu.py assumed
-- the official site files own goals that way. It does -- but only from April
-- 2026 (and in two matches in late 2024). Before that the site listed the
-- own-goal scorer in the BENEFITING team's player table, so the loader stored
-- these 20 own goals under the team they count for, and the read side then
-- credited them to the wrong team. TRA United 3-0 KMC FC (23 Jan 2026) read
-- 2-1 in the Data Audit: Hance Masoud's own goal was filed under TRA United.
--
-- The stored scores are right -- both sources agree on every one of them
-- (reconciliation run 23). The evidence for each row below:
--   * score  (19 rows): the match's event log is complete, and only the
--            corrected reading reproduces the stored score.
--   * spells (1 row, match 17991): the log is incomplete, so the score can't
--            decide; Jumanne Elfadhil was a Tanzania Prisons player, on a spell
--            that ran from 2023-10-08 to nine days before this match.
--
-- Being listed in the benefiting team's table also gave each scorer a one-day
-- "spell" at that club, dated to the match -- that is how Masoud came to be at
-- TRA United for one day. Those 20 spells describe nothing and are deleted.
-- No team sheet (match_lineups) row was affected, and none of the spells
-- carries a provenance row.
--
-- Recorded as reconciliation run + diffs, so the change is auditable and
-- reversible: each diff holds the old and new team_id.

BEGIN;

INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
VALUES ('match_event', 15, 16,
  'TPL 2023/24-2025/26 own goals from ligikuu.co.tz filed under the benefiting team. 19 corrected on the stored score (agreed by ligikuu and whoscored, run 23), 1 (match 17991) on the scorer''s club spell. Side-effect one-day spells at the benefiting club deleted.');

CREATE TEMP TABLE og_fix (event_id int, match_id int, filed int, corrected int, spell_id int, note text) ON COMMIT DROP;
INSERT INTO og_fix VALUES
  (10496, 17697, 168, 76, 3478, 'Namungo 1-3 Yanga SC (2024-03-08): Ibrahim Abdulla Bacca, Namungo -> Yanga SC [score]'),
  (10569, 17735, 168, 11, 3502, 'Namungo 2-2 Simba SC (2024-04-30): Kennedy Juma, Namungo -> Simba SC [score]'),
  (10610, 17758, 76, 7, 3516, 'Mtibwa Sugar 1-3 Yanga SC (2024-05-13): Nassry Kombo, Yanga SC -> Mtibwa Sugar [score]'),
  (10606, 17757, 3, 350, 3514, 'JKT Tanzania 1-1 Fountain Gate FC (2024-05-13): Nicholas Gyan, JKT Tanzania -> Fountain Gate FC [score]'),
  (10614, 17764, 13, 351, 3517, 'Tanzania Prisons 1-2 Mashujaa FC (2024-05-20): Omari Kindamba, Tanzania Prisons -> Mashujaa FC [score]'),
  (10638, 17771, 7, 351, 3523, 'Mashujaa FC 3-2 Mtibwa Sugar (2024-05-25): Samson Madeleke, Mtibwa Sugar -> Mashujaa FC [score]'),
  (10683, 17787, 351, 336, 3535, 'Mashujaa FC 1-0 Dodoma Jiji FC (2024-08-17): Daniel Mgore, Mashujaa FC -> Dodoma Jiji FC [score]'),
  (10968, 17918, 350, 11, 3676, 'Fountain Gate FC 1-1 Simba SC (2025-02-06): Ladaki Chasambi, Fountain Gate FC -> Simba SC [score]'),
  (10978, 17921, 3, 100, 3681, 'Coastal Union 2-1 JKT Tanzania (2025-02-07): Lameck Lawi, JKT Tanzania -> Coastal Union [score]'),
  (11028, 17945, 13, 352, 3701, 'Tanzania Prisons 1-1 TRA United (2025-02-21): Emmanuel Chigozie, Tanzania Prisons -> TRA United [score]'),
  (11056, 17958, 352, 336, 3709, 'TRA United 1-0 Dodoma Jiji FC (2025-02-28): Dissan Galiwango, TRA United -> Dodoma Jiji FC [score]'),
  (11063, 17961, 354, 351, 3712, 'KenGold 2-2 Mashujaa FC (2025-03-05): Yusuf Dunia, KenGold -> Mashujaa FC [score]'),
  (11104, 17975, 4, 100, 3729, 'Kagera Sugar 2-1 Coastal Union (2025-04-03): Ally Ayubu Msangi, Kagera Sugar -> Coastal Union [score]'),
  (11132, 17988, 100, 347, 3732, 'Coastal Union 2-1 Singida Black Stars (2025-04-10): Josephat Bada, Coastal Union -> Singida Black Stars [score]'),
  (11146, 17991, 3, 13, 3737, 'Tanzania Prisons 3-2 JKT Tanzania (2025-04-18): Jumanne Elfadhil, JKT Tanzania -> Tanzania Prisons [spells]'),
  (11265, 18040, 336, 100, 3780, 'Dodoma Jiji FC 2-0 Coastal Union (2025-09-27): Haroub Abdallah, Dodoma Jiji FC -> Coastal Union [score]'),
  (11267, 18042, 7, 350, 3786, 'Mtibwa Sugar 2-0 Fountain Gate FC (2025-09-28): Lamela Maneno, Mtibwa Sugar -> Fountain Gate FC [score]'),
  (11308, 18065, 3, 102, 3821, 'KMC FC 0-1 JKT Tanzania (2025-11-21): Ibrahim Nindi, JKT Tanzania -> KMC FC [score]'),
  (11335, 18085, 352, 347, 3839, 'Singida Black Stars 1-3 TRA United (2025-12-06): Anthony Tra Bi, TRA United -> Singida Black Stars [score]'),
  (11357, 18096, 352, 102, 3852, 'TRA United 3-0 KMC FC (2026-01-23): Hance Masoud, TRA United -> KMC FC [score]');

-- Guard: every row must still be exactly as diagnosed, or nothing is applied.
DO $$
DECLARE drift int;
BEGIN
  SELECT count(*) INTO drift FROM og_fix f
    LEFT JOIN match_events e ON e.id = f.event_id AND e.match_id = f.match_id AND e.type = 'OWN_GOAL' AND e.team_id = f.filed
    LEFT JOIN player_team_stints s ON s.id = f.spell_id
   WHERE e.id IS NULL OR s.id IS NULL;
  IF drift > 0 THEN RAISE EXCEPTION '% own goal(s) or spell(s) no longer match the diagnosis', drift; END IF;
END $$;

INSERT INTO reconciliation_diffs (reconciliation_run_id, entity_id_a, entity_id_b, field_name, value_a, value_b, resolution, resolved_value, resolved_at)
SELECT currval('reconciliation_runs_id_seq'), f.event_id, f.event_id, 'team_id', f.filed::text, f.corrected::text, 'MANUAL', f.corrected::text, now()
  FROM og_fix f;

UPDATE match_events e SET team_id = f.corrected FROM og_fix f WHERE e.id = f.event_id;

DELETE FROM player_team_stints s USING og_fix f WHERE s.id = f.spell_id;

\echo 'ligikuu own goals whose complete event log still disagrees with the score (must be 0):'
WITH per_match AS (
  SELECT m.id, COALESCE(m.home_score_et, m.home_score) fh, COALESCE(m.away_score_et, m.away_score) fa,
    count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL')) goals,
    count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL')
      AND CASE WHEN e.type = 'OWN_GOAL' THEN e.team_id <> m.home_team_id ELSE e.team_id = m.home_team_id END) credited_home
  FROM matches m JOIN match_events e ON e.match_id = m.id
  WHERE EXISTS (SELECT 1 FROM match_events o WHERE o.match_id = m.id AND o.type = 'OWN_GOAL' AND o.detail->>'source' = 'ligikuu')
  GROUP BY m.id)
SELECT count(*) FROM per_match WHERE goals = fh + fa AND credited_home <> fh;

\echo 'TRA United 3-0 KMC FC now reads:'
SELECT count(*) FILTER (WHERE (e.type <> 'OWN_GOAL' AND e.team_id = m.home_team_id) OR (e.type = 'OWN_GOAL' AND e.team_id = m.away_team_id)) || '-' ||
       count(*) FILTER (WHERE (e.type <> 'OWN_GOAL' AND e.team_id = m.away_team_id) OR (e.type = 'OWN_GOAL' AND e.team_id = m.home_team_id)) AS events_read
  FROM matches m JOIN match_events e ON e.match_id = m.id AND e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL')
 WHERE m.id = 18096 GROUP BY m.id;

COMMIT;
