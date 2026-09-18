-- Two Premier League scorers held twice, merged before the 2022/23 FotMob load.
--
-- The FotMob loader refuses to name a goal when two vault players from the same
-- club both match the name, and these are the only two it refused in 2022/23.
-- Neither is a coincidence of names: each pair is one man recorded twice, by two
-- different sources, in seasons that do not overlap. It is the same legacy-
-- versus-new-source duplication as Edward Songo (2026-09-17), and it is settled
-- here so the load can name the goals itself rather than have them patched in
-- afterwards.
--
-- 1. **Feisal Salum at Yanga SC**
--      1450  "Feisal Salum Abdallah"  legacy SokaFC, Yanga, 2018/19, 4 events
--     11761  "Feisal Salum"           RSSSF,         Yanga, 2020/21-2021/22, 4 events
--    One club between them, no match in common, disjoint seasons, and one name
--    is the other with a third element. Merged into 1450, which carries the
--    fuller name and the legacy provenance.
--
--    **Not merged, and worth a look by an editor:** player 2069, also "Feisal
--    Salum", holds 71 events for Azam FC and Tanzania across 2018/19 and
--    2023/24 onward. He may well be the same man -- the career reads as Azam,
--    Yanga, Azam -- but 2069 and 1450 both have 2018/19 events at *different*
--    clubs, and nothing in the vault settles whether that is one mid-season
--    transfer or two players. Merging on a hunch would move 71 events onto the
--    wrong man, so it stays open; the audit's Identity checks raise it.
--
-- 2. **Erick Mwijage at Kagera Sugar**
--      4878  "Erick Mwijage"  ligikuu, Kagera Sugar then KMC FC, 2024/25-2025/26
--     11715  "Erick Mwijage"  RSSSF,   Kagera Sugar, 2020/21, 1 event
--    Same name, both at Kagera Sugar, no match in common, disjoint seasons. The
--    two clubs on 4878's record are a transfer of his, not a contradiction.
--    Merged into 4878, which has the fuller record and his registered spells.
--
-- After this, "Feisal Salum" and "Erick Mwijage" each resolve to exactly one
-- player at their club, and the 2022/23 load names their goals.

BEGIN;

INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
VALUES ('player',
        (SELECT id FROM data_sources WHERE name = 'rsssf'),
        (SELECT id FROM data_sources WHERE name = 'fotmob'),
        'Feisal Salum (Yanga) and Erick Mwijage (Kagera Sugar) were each held as two player records by two sources in non-overlapping seasons; merged so the 2022/23 FotMob load can attribute their goals.');

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM players WHERE id IN (1450, 11761, 4878, 11715);
  IF n <> 4 THEN RAISE EXCEPTION 'the four player records are not all present'; END IF;

  SELECT count(*) INTO n FROM (
    SELECT match_id FROM match_events WHERE player_id = 1450
    INTERSECT SELECT match_id FROM match_events WHERE player_id = 11761) x;
  IF n <> 0 THEN RAISE EXCEPTION 'the two Feisal Salum records share a match, so they are two men'; END IF;
  SELECT count(DISTINCT team_id) INTO n FROM match_events WHERE player_id IN (1450, 11761);
  IF n <> 1 THEN RAISE EXCEPTION 'the two Feisal Salum records span more than one club'; END IF;

  SELECT count(*) INTO n FROM (
    SELECT match_id FROM match_events WHERE player_id = 4878
    INTERSECT SELECT match_id FROM match_events WHERE player_id = 11715) x;
  IF n <> 0 THEN RAISE EXCEPTION 'the two Erick Mwijage records share a match, so they are two men'; END IF;
  SELECT count(*) INTO n FROM match_events
   WHERE player_id = 11715 AND team_id <> (SELECT id FROM teams WHERE name = 'Kagera Sugar');
  IF n <> 0 THEN RAISE EXCEPTION 'the RSSSF Erick Mwijage played for a club other than Kagera Sugar'; END IF;
END $$;

INSERT INTO reconciliation_diffs (reconciliation_run_id, entity_id_a, entity_id_b, field_name, value_a, value_b, resolution, resolved_value, resolved_at)
SELECT currval('reconciliation_runs_id_seq'), 11761, 1450, 'players.id',
       'Feisal Salum (11761), ' || (SELECT count(*) FROM match_events WHERE player_id = 11761) || ' events at Yanga SC',
       'Feisal Salum Abdallah (1450)', 'MANUAL', '1450', now()
UNION ALL
SELECT currval('reconciliation_runs_id_seq'), 11715, 4878, 'players.id',
       'Erick Mwijage (11715), ' || (SELECT count(*) FROM match_events WHERE player_id = 11715) || ' events at Kagera Sugar',
       'Erick Mwijage (4878)', 'MANUAL', '4878', now();

/* -- the merges ------------------------------------------------------------ */
UPDATE match_events         SET player_id         = 1450 WHERE player_id         = 11761;
UPDATE match_events         SET related_player_id = 1450 WHERE related_player_id = 11761;
UPDATE match_lineups        SET player_id         = 1450 WHERE player_id         = 11761;
UPDATE player_team_stints   SET player_id         = 1450 WHERE player_id         = 11761;
UPDATE match_player_ratings SET player_id         = 1450 WHERE player_id         = 11761;
UPDATE entity_source_map    SET entity_id         = 1450
 WHERE entity_type = 'player' AND entity_id = 11761;
DELETE FROM players WHERE id = 11761;

UPDATE match_events         SET player_id         = 4878 WHERE player_id         = 11715;
UPDATE match_events         SET related_player_id = 4878 WHERE related_player_id = 11715;
UPDATE match_lineups        SET player_id         = 4878 WHERE player_id         = 11715;
UPDATE player_team_stints   SET player_id         = 4878 WHERE player_id         = 11715;
UPDATE match_player_ratings SET player_id         = 4878 WHERE player_id         = 11715;
UPDATE entity_source_map    SET entity_id         = 4878
 WHERE entity_type = 'player' AND entity_id = 11715;
DELETE FROM players WHERE id = 11715;

\echo ''
\echo 'The two survivors, and what they now hold:'
SELECT p.id, p.full_name,
       (SELECT count(*) FROM match_events e WHERE e.player_id = p.id) AS events,
       (SELECT string_agg(DISTINCT t.name, ', ') FROM match_events e
          JOIN teams t ON t.id = e.team_id WHERE e.player_id = p.id) AS clubs
  FROM players p WHERE p.id IN (1450, 4878) ORDER BY p.id;

COMMIT;
