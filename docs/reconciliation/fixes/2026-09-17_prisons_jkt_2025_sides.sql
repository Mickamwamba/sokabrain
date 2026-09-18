-- Tanzania Prisons 3-2 JKT Tanzania, 18 April 2025: three goals on the wrong
-- side, and a double-counted own goal behind it.
--
-- The match has read 4-1 against a 3-2 since it was loaded, and it is one of the
-- two Premier League matches CLAUDE.md has long listed as holding more goal
-- events than the score allows. The cause is now clear, and it is ligikuu's
-- record rather than the loader:
--
--   ligikuu lists SIX goals for a five-goal match --
--     Prisons:  Oscar Mwajanga 50', 89'; Jeremiah Juma 77'
--     JKT:      Mohamed Bakari 11'; Shiza Kichuya 41';
--               Jumanne Elfadhil, own goal, no minute
--
--   Flashscore lists five, and they add up --
--     11' Bakari (JKT) · 42' Elifadhili, OWN GOAL counting for JKT ·
--     50' Mwansanga (Prisons) · 77' Juma (Prisons) · 89' Mkomola (Prisons)
--
-- So ligikuu recorded the same 41st-minute goal twice: once as an ordinary goal
-- by Kichuya and once as Elfadhil's own goal. The vault kept five of the six,
-- but three of them ended up on the wrong team.
--
-- Note ligikuu files the own goal under **JKT**, the side it counts for. That is
-- the pre-2026 convention the ligikuu normaliser already knows about, and the
-- vault's rule is the opposite: an own goal is stored under the scorer's OWN
-- team (design principle 5). Elfadhil plays for Prisons.
--
-- Nothing is deleted and no player is created. The three events keep ligikuu's
-- full names -- better than Flashscore's "Bakari M." -- and gain the minute and
-- the side Flashscore supplies. Where the two sources disagree on a surname
-- (ligikuu's "Oscar Mwajanga" twice against Flashscore's Mwansanga and Mkomola)
-- the vault's names stand: this fix is about sides and minutes, and that
-- disagreement is not settled by either source being tidier.

BEGIN;

INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
VALUES ('match_event',
        (SELECT id FROM data_sources WHERE name = 'ligikuu'),
        (SELECT id FROM data_sources WHERE name = 'flashscore'),
        'Tanzania Prisons 3-2 JKT Tanzania (17991) read 4-1: ligikuu double-counted the 41st-minute goal as both an ordinary goal and an own goal, and three events sat on the wrong team. Re-sided and given their minutes from Flashscore; no event deleted and no name changed.');

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM matches
   WHERE id = 17991 AND home_team_id = 13 AND away_team_id = 3
     AND home_score = 3 AND away_score = 2;
  IF n <> 1 THEN RAISE EXCEPTION 'match 17991 is not Prisons 3-2 JKT'; END IF;
  SELECT count(*) INTO n FROM match_events
   WHERE match_id = 17991 AND type IN ('GOAL','PENALTY_GOAL','OWN_GOAL');
  IF n <> 5 THEN RAISE EXCEPTION 'expected 5 goal events on 17991, found %', n; END IF;
  SELECT count(*) INTO n FROM match_events WHERE id IN (20706, 20708, 20709) AND minute IS NULL;
  IF n <> 3 THEN RAISE EXCEPTION 'the three events to correct no longer lack their minutes'; END IF;
END $$;

INSERT INTO reconciliation_diffs (reconciliation_run_id, entity_id_a, entity_id_b, field_name, value_a, value_b, resolution, resolved_value, resolved_at)
VALUES
  (currval('reconciliation_runs_id_seq'), 20706, 17991, 'match_events.team_id',
   'Jeremiah Juma under JKT Tanzania, no minute', 'Tanzania Prisons, 77'' (Flashscore)', 'ACCEPT_B', '13', now()),
  (currval('reconciliation_runs_id_seq'), 20708, 17991, 'match_events.team_id',
   'Mohamed Bakari under Tanzania Prisons, no minute', 'JKT Tanzania, 11'' (Flashscore)', 'ACCEPT_B', '3', now()),
  (currval('reconciliation_runs_id_seq'), 20709, 17991, 'match_events.team_id',
   'Jumanne Elfadhil own goal under JKT Tanzania, no minute',
   'Tanzania Prisons, 42'' -- the scorer''s own team, counting for JKT (Flashscore)', 'ACCEPT_B', '13', now());

UPDATE match_events SET team_id = 13, minute = 77 WHERE id = 20706;   -- Juma, for Prisons
UPDATE match_events SET team_id =  3, minute = 11 WHERE id = 20708;   -- Bakari, for JKT
UPDATE match_events SET team_id = 13, minute = 42 WHERE id = 20709;   -- own goal, scorer is Prisons

SET timezone = 'UTC';

\echo ''
\echo 'Tanzania Prisons 3-2 JKT Tanzania, corrected:'
SELECT p.full_name AS scorer, t.name AS recorded_under, e.minute, e.type,
       CASE WHEN e.type = 'OWN_GOAL'
            THEN CASE WHEN e.team_id = 13 THEN 'JKT Tanzania' ELSE 'Tanzania Prisons' END
            ELSE t.name END AS counts_for
  FROM match_events e JOIN players p ON p.id = e.player_id JOIN teams t ON t.id = e.team_id
 WHERE e.match_id = 17991 AND e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL')
 ORDER BY e.minute;

\echo ''
\echo '2024/25: matches reconciling, goals with no event, events with no scorer:'
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
  FROM matches m
  JOIN competition_editions ce ON ce.id = m.competition_edition_id
  JOIN seasons s ON s.id = ce.season_id
  LEFT JOIN match_events e ON e.match_id = m.id
 WHERE ce.competition_id = 1 AND s.label = '2024/2025' AND m.home_score IS NOT NULL
 GROUP BY m.id, 2, 3)
SELECT count(*) AS matches, count(*) FILTER (WHERE h = hs AND a = as_) AS reconciling,
       sum(greatest((hs + as_) - (h + a), 0)) AS goals_with_no_event,
       sum(unnamed) AS events_with_no_scorer
  FROM x;

COMMIT;
