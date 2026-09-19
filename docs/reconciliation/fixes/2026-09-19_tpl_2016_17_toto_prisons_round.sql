-- TPL 2016/17: the season's one roundless fixture gets its round.
--
-- Toto Africa 1-1 Tanzania Prisons (15 Jan 2017) was the only fixture in the
-- season without a round. It is applied by hand rather than by
-- load_rounds_fotmob.py, because that loader refuses FotMob's whole 2016/17
-- list: FotMob has 240 entries but only 239 distinct fixtures. It lists
-- Kagera Sugar v Stand United twice -- in round 2, where the vault also has it,
-- and again in round 17, where the reverse fixture Stand United v Kagera Sugar
-- should be. That reverse fixture exists in neither source, which is why the
-- vault holds 239 fixtures and why its round 17 holds seven. A source list with
-- a fixture in it twice cannot be trusted wholesale, so it is not loaded.
--
-- The round is nevertheless certain. FotMob puts this match in round 19, and
-- all seven of its other round-19 fixtures are already the vault's round 19,
-- played 13-18 Jan 2017 -- this match sits inside that window on 15 Jan, and
-- the vault's round 19 holds seven where it should hold eight.

BEGIN;

UPDATE matches SET round = '19' WHERE id = 16637 AND round IS NULL;

INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
VALUES ('match',
        (SELECT id FROM data_sources WHERE name='ligikuu'),
        (SELECT id FROM data_sources WHERE name='fotmob'),
        'Premier League 2016/17: the one fixture with no round. FotMob''s list '
        'duplicates one fixture and so is refused wholesale; this round is taken '
        'from it by hand, corroborated by the round''s own date window.');

INSERT INTO reconciliation_diffs
  (reconciliation_run_id, entity_id_a, entity_id_b, field_name,
   value_a, value_b, resolution, resolved_value, resolved_at)
VALUES ((SELECT max(id) FROM reconciliation_runs), 16637, NULL, 'matches.round',
        'no round', 'round 19 (fotmob)', 'ACCEPT_B', '19', now());

COMMIT;
