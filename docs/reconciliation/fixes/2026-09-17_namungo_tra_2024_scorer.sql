-- The last unattributed goal of 2023/24, from FotMob.
--
-- Namungo 3-2 TRA United, 28 May 2024 (17783). ligikuu recorded TRA's second
-- goal without a scorer and Flashscore cannot help: its own log for this match
-- reads 2-2 against the 3-2 both the vault and FotMob hold, so it is a goal
-- short and has no name to give.
--
-- FotMob has all five, and its account matches the vault's on every other goal
-- to within a few minutes:
--
--   vault                         FotMob
--   Pius Buswita      20'         Pius Buswita      19'
--   Pius Buswita      29'         Pius Buswita      28' (penalty)
--   Hashimu Manyanya  78'         Hashim Manyanya   82'
--   Athuman Abass     85'  TRA    Abbas Athumani    84'  TRA
--   (no scorer)       90'  TRA    Moses Kennedy     90+14' TRA
--
-- So the unattributed one is Moses Kennedy's, and he is new to the vault.
--
-- Two things deliberately NOT changed, to keep this to the one fact it settles:
-- the minutes stay as the vault has them, and Buswita's second stays an
-- ordinary goal though FotMob calls it a penalty. The vault has no systematic
-- penalty pass, and correcting one match's flag would leave the rest wrong
-- while looking right.

BEGIN;

INSERT INTO data_sources (name, type, base_url)
VALUES ('fotmob', 'SCRAPED', 'https://www.fotmob.com')
ON CONFLICT (name) DO NOTHING;

INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
VALUES ('match_event',
        (SELECT id FROM data_sources WHERE name = 'ligikuu'),
        (SELECT id FROM data_sources WHERE name = 'fotmob'),
        'Namungo 3-2 TRA United (17783): the one goal ligikuu left unattributed and Flashscore could not supply, named from FotMob as Moses Kennedy.');

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM match_events
   WHERE id = 10675 AND match_id = 17783 AND player_id IS NULL
     AND team_id = 352 AND type = 'GOAL';
  IF n <> 1 THEN RAISE EXCEPTION 'event 10675 is not the unnamed TRA United goal'; END IF;
  SELECT count(*) INTO n FROM players WHERE full_name = 'Moses Kennedy';
  IF n <> 0 THEN RAISE EXCEPTION 'a player called Moses Kennedy already exists'; END IF;
END $$;

WITH p AS (
  INSERT INTO players (full_name) VALUES ('Moses Kennedy') RETURNING id
), prov AS (
  INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
  SELECT 'player', id, (SELECT id FROM data_sources WHERE name='fotmob'),
         'fotmob-player-moses-kennedy', 1.0 FROM p
), d AS (
  INSERT INTO reconciliation_diffs
    (reconciliation_run_id, entity_id_a, entity_id_b, field_name, value_a, value_b, resolution, resolved_value, resolved_at)
  SELECT currval('reconciliation_runs_id_seq'), 10675, 17783, 'match_events.player_id',
         'no scorer', 'Moses Kennedy, 90+14'' (FotMob)', 'ACCEPT_B', id::text, now() FROM p
)
UPDATE match_events SET player_id = (SELECT id FROM p) WHERE id = 10675;

INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
VALUES ('match_event', 10675, (SELECT id FROM data_sources WHERE name='fotmob'), 'fotmob-17783-away-90', 1.0)
ON CONFLICT (entity_type, data_source_id, external_id) DO UPDATE SET last_synced_at = now();

SET timezone = 'UTC';
\echo ''
\echo '2023/24, final state:'
WITH x AS (
  SELECT m.id, coalesce(m.home_score_et, m.home_score) hs, coalesce(m.away_score_et, m.away_score) as_,
    count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL') AND
      (CASE WHEN e.type='OWN_GOAL'
            THEN CASE WHEN e.team_id=m.home_team_id THEN m.away_team_id ELSE m.home_team_id END
            ELSE e.team_id END) = m.home_team_id) h,
    count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL') AND
      (CASE WHEN e.type='OWN_GOAL'
            THEN CASE WHEN e.team_id=m.home_team_id THEN m.away_team_id ELSE m.home_team_id END
            ELSE e.team_id END) = m.away_team_id) a,
    count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL') AND e.player_id IS NULL) unnamed
  FROM matches m JOIN competition_editions ce ON ce.id = m.competition_edition_id
  JOIN seasons s ON s.id = ce.season_id LEFT JOIN match_events e ON e.match_id = m.id
 WHERE ce.competition_id = 1 AND s.label = '2023/2024' AND m.home_score IS NOT NULL
 GROUP BY m.id, 2, 3)
SELECT count(*) matches, count(*) FILTER (WHERE h = hs AND a = as_) reconciling,
       sum(greatest((hs+as_)-(h+a),0)) goals_with_no_event, sum(unnamed) events_with_no_scorer FROM x;
COMMIT;
