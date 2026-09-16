-- Samuel Eto'o was two players in the vault.
--
-- The legacy SokaFC data spells him "Etoo" (player 7174) and holds one goal --
-- the 82nd minute against Togo on 2002-01-29 -- plus a yellow card in the 2002
-- final. Everything else, 2000 and 2004-2010, sits under "Samuel Eto'o"
-- (7263). So the vault held all 18 of his Africa Cup of Nations goals but
-- showed 17, because one career was filed under two names.
--
-- Confirmed before merging: both records are Cameroonian, 7174 has no lineups,
-- club spells or ratings, and Wikipedia's 2002 report names Samuel Eto'o as the
-- scorer in Cameroon 3-0 Togo (80'; the vault's legacy row says 82', a minute
-- discrepancy left as it is -- this fix is about identity, not timing).
--
-- The legacy provenance row moves with the events rather than being deleted, so
-- a future re-read of the SokaFC dump still lands on the surviving player.

BEGIN;

INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
VALUES ('player', 1, 6,
  'Samuel Eto''o held as two players: legacy "Etoo" (7174) and "Samuel Eto''o" (7263). Merged into 7263, which the RSSSF 1957-2000 load also matched on. 2 events and 1 provenance row moved.');

INSERT INTO reconciliation_diffs (reconciliation_run_id, entity_id_a, entity_id_b, field_name, value_a, value_b, resolution, resolved_value, resolved_at)
SELECT currval('reconciliation_runs_id_seq'), 7174, 7263, 'player_id', '7174 (Etoo)', '7263 (Samuel Eto''o)', 'MANUAL', '7263', now()
  FROM match_events WHERE player_id = 7174;

UPDATE match_events SET player_id = 7263 WHERE player_id = 7174;
UPDATE match_events SET related_player_id = 7263 WHERE related_player_id = 7174;
UPDATE match_lineups SET player_id = 7263 WHERE player_id = 7174;
UPDATE player_team_stints SET player_id = 7263 WHERE player_id = 7174;
UPDATE match_player_ratings SET player_id = 7263 WHERE player_id = 7174;
UPDATE entity_source_map SET entity_id = 7263 WHERE entity_type = 'player' AND entity_id = 7174;

DELETE FROM players WHERE id = 7174;

\echo 'Samuel Eto''o, Africa Cup of Nations goals by tournament:'
SET timezone = 'UTC';
SELECT s.label, count(*) AS goals
  FROM match_events e
  JOIN matches m ON m.id = e.match_id
  JOIN competition_editions ce ON ce.id = m.competition_edition_id
  JOIN seasons s ON s.id = ce.season_id
 WHERE e.player_id = 7263 AND ce.competition_id = 16 AND e.type IN ('GOAL', 'PENALTY_GOAL')
 GROUP BY s.label ORDER BY s.label;

\echo 'Total (must be 18):'
SELECT count(*) FROM match_events e
  JOIN matches m ON m.id = e.match_id
  JOIN competition_editions ce ON ce.id = m.competition_edition_id
 WHERE e.player_id = 7263 AND ce.competition_id = 16 AND e.type IN ('GOAL', 'PENALTY_GOAL');

COMMIT;
