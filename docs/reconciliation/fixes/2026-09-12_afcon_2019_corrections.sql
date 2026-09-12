-- AFCON 2019 (edition 14): apply reconciliation run 38.
--
-- Edition 14 came in with the legacy SokaFC migration. Comparing it against
-- whoscored.com (run 38) surfaced three separate defects, and the decisive
-- evidence was internal: for 16 of the 19 disagreeing matches the stored score
-- disagreed with this edition's OWN match_events, and the event log is what
-- agreed with WhoScored. So the stored score was what was wrong.
--
--   1. Ten group matches carried an inflated away score. Ghana v Benin was
--      stored 2-6 and was actually 2-2; Mali v Mauritania 4-3, actually 4-1.
--   2. Four knockout ties credited the shootout winner an extra goal, modelled
--      as a PENALTY_GOAL in minute 120 with no player. Those four phantom
--      events are deleted and the shootout moved to *_score_pens, where it
--      belongs -- a shootout is not a goal.
--   3. Five matches were left NULL that were 0-0: the same lost-goalless-draw
--      defect found in TPL 2017/18 (reconciliation run 8).
--
-- This also brings edition 14 into line with the twelve editions loaded from
-- WhoScored on the same day: home_score is the score after 90 minutes with the
-- result in *_score_et, the round of 16 and third-place playoff are no longer
-- both labelled 'KNOCKOUT', and the group matches get their groups.
--
-- Verified after applying: all 52 matches agree with WhoScored, and every
-- score is reproduced by the edition's own event log except Tunisia v Angola,
-- whose log is missing a goal (a gap in the legacy data, not a score error).

BEGIN;

-- 1. The four phantom shootout "goals". They carry no provenance rows.
DELETE FROM match_events
 WHERE id IN (3031, 3032, 3035, 3036);
-- 2. Scores. home/away = after 90 minutes; *_et = the result where extra
--    time was played; *_pens = the shootout. Only rows that change are
--    touched; the other 32 matches already agree with WhoScored.
UPDATE matches SET home_score=1, away_score=0, home_score_et=NULL, away_score_et=NULL, home_score_pens=NULL, away_score_pens=NULL WHERE id=928;  -- Egypt v Zimbabwe: 1-2 -> 1-0
UPDATE matches SET home_score=0, away_score=2, home_score_et=NULL, away_score_et=NULL, home_score_pens=NULL, away_score_pens=NULL WHERE id=929;  -- DR Congo v Uganda: 0-3 -> 0-2
UPDATE matches SET home_score=1, away_score=0, home_score_et=NULL, away_score_et=NULL, home_score_pens=NULL, away_score_pens=NULL WHERE id=930;  -- Nigeria v Burundi: 1-2 -> 1-0
UPDATE matches SET home_score=1, away_score=0, home_score_et=NULL, away_score_et=NULL, home_score_pens=NULL, away_score_pens=NULL WHERE id=932;  -- Morroco v Namibia: 1-1 -> 1-0
UPDATE matches SET home_score=2, away_score=0, home_score_et=NULL, away_score_et=NULL, home_score_pens=NULL, away_score_pens=NULL WHERE id=933;  -- Senegal v Tanzania: 2-1 -> 2-0
UPDATE matches SET home_score=4, away_score=1, home_score_et=NULL, away_score_et=NULL, home_score_pens=NULL, away_score_pens=NULL WHERE id=937;  -- Mali v Mauritania: 4-3 -> 4-1
UPDATE matches SET home_score=2, away_score=0, home_score_et=NULL, away_score_et=NULL, home_score_pens=NULL, away_score_pens=NULL WHERE id=938;  -- Cameroon v Guinea-Bissau: 2-2 -> 2-0
UPDATE matches SET home_score=2, away_score=2, home_score_et=NULL, away_score_et=NULL, home_score_pens=NULL, away_score_pens=NULL WHERE id=939;  -- Ghana v Benin: 2-6 -> 2-2
UPDATE matches SET home_score=2, away_score=0, home_score_et=NULL, away_score_et=NULL, home_score_pens=NULL, away_score_pens=NULL WHERE id=944;  -- Egypt v DR Congo: 3-0 -> 2-0
UPDATE matches SET home_score=1, away_score=0, home_score_et=NULL, away_score_et=NULL, home_score_pens=NULL, away_score_pens=NULL WHERE id=945;  -- Madagascar v Burundi: 1-2 -> 1-0
UPDATE matches SET home_score=0, away_score=0, home_score_et=NULL, away_score_et=NULL, home_score_pens=NULL, away_score_pens=NULL WHERE id=951;  -- Mauritania v Angola: None-None -> 0-0
UPDATE matches SET home_score=0, away_score=0, home_score_et=NULL, away_score_et=NULL, home_score_pens=NULL, away_score_pens=NULL WHERE id=952;  -- Cameroon v Ghana: None-None -> 0-0
UPDATE matches SET home_score=0, away_score=0, home_score_et=NULL, away_score_et=NULL, home_score_pens=NULL, away_score_pens=NULL WHERE id=953;  -- Benin v Guinea-Bissau: None-None -> 0-0
UPDATE matches SET home_score=0, away_score=0, home_score_et=NULL, away_score_et=NULL, home_score_pens=NULL, away_score_pens=NULL WHERE id=962;  -- Benin v Cameroon: None-None -> 0-0
UPDATE matches SET home_score=0, away_score=0, home_score_et=NULL, away_score_et=NULL, home_score_pens=NULL, away_score_pens=NULL WHERE id=965;  -- Mauritania v Tunisia: None-None -> 0-0
UPDATE matches SET home_score=1, away_score=1, home_score_et=1, away_score_et=1, home_score_pens=1, away_score_pens=4 WHERE id=966;  -- Morroco v Benin: 1-2 -> 1-1, et 1-1, pens 1-4
UPDATE matches SET home_score=2, away_score=2, home_score_et=2, away_score_et=2, home_score_pens=4, away_score_pens=2 WHERE id=970;  -- Madagascar v DR Congo: 3-2 -> 2-2, et 2-2, pens 4-2
UPDATE matches SET home_score=1, away_score=1, home_score_et=1, away_score_et=1, home_score_pens=4, away_score_pens=5 WHERE id=973;  -- Ghana v Tunisia: 1-2 -> 1-1, et 1-1, pens 4-5
UPDATE matches SET home_score=1, away_score=1, home_score_et=1, away_score_et=1, home_score_pens=3, away_score_pens=4 WHERE id=976;  -- Ivory Coast v Algeria: 1-2 -> 1-1, et 1-1, pens 3-4
UPDATE matches SET home_score=0, away_score=0, home_score_et=1, away_score_et=0, home_score_pens=NULL, away_score_pens=NULL WHERE id=980;  -- Senegal v Tunisia: 1-0 -> 0-0, et 1-0

-- 3. Rounds. 'KNOCKOUT' lumped the round of 16 together with the
--    third-place playoff; WhoScored distinguishes them.
UPDATE matches SET round = 'ROUND OF 16' WHERE id IN (966, 967, 968, 969, 970, 971, 972, 973);
UPDATE matches SET round = 'THIRD PLACE' WHERE id IN (983);

-- 4. Groups. Edition 14 had none; the other twelve editions all do.
INSERT INTO competition_groups (competition_edition_id, name) VALUES (14, 'A');
INSERT INTO competition_groups (competition_edition_id, name) VALUES (14, 'B');
INSERT INTO competition_groups (competition_edition_id, name) VALUES (14, 'C');
INSERT INTO competition_groups (competition_edition_id, name) VALUES (14, 'D');
INSERT INTO competition_groups (competition_edition_id, name) VALUES (14, 'E');
INSERT INTO competition_groups (competition_edition_id, name) VALUES (14, 'F');
UPDATE matches SET group_id = (SELECT id FROM competition_groups WHERE competition_edition_id=14 AND name='A')
 WHERE id IN (928, 929, 943, 944, 957, 956);
UPDATE matches SET group_id = (SELECT id FROM competition_groups WHERE competition_edition_id=14 AND name='B')
 WHERE id IN (930, 931, 940, 945, 955, 954);
UPDATE matches SET group_id = (SELECT id FROM competition_groups WHERE competition_edition_id=14 AND name='C')
 WHERE id IN (933, 934, 946, 947, 961, 960);
UPDATE matches SET group_id = (SELECT id FROM competition_groups WHERE competition_edition_id=14 AND name='D')
 WHERE id IN (932, 935, 949, 950, 959, 958);
UPDATE matches SET group_id = (SELECT id FROM competition_groups WHERE competition_edition_id=14 AND name='E')
 WHERE id IN (936, 937, 948, 951, 965, 964);
UPDATE matches SET group_id = (SELECT id FROM competition_groups WHERE competition_edition_id=14 AND name='F')
 WHERE id IN (938, 939, 952, 953, 962, 963);

-- 5. Participants, derived from the group fixtures.
INSERT INTO competition_edition_teams (competition_edition_id, team_id, group_id)
SELECT DISTINCT 14, t.team_id, m.group_id
  FROM matches m
  CROSS JOIN LATERAL (VALUES (m.home_team_id), (m.away_team_id)) AS t(team_id)
 WHERE m.competition_edition_id = 14 AND m.group_id IS NOT NULL;

UPDATE competition_editions
   SET num_teams = (SELECT count(*) FROM competition_edition_teams WHERE competition_edition_id = 14),
       format = 'GROUPS_KNOCKOUT'
 WHERE id = 14;

-- 6. Close out the run-38 diffs: WhoScored (source B) is accepted.
UPDATE reconciliation_diffs
   SET resolution = 'ACCEPT_B', resolved_value = value_b, resolved_at = now()
 WHERE reconciliation_run_id = 38 AND resolution = 'PENDING';

COMMIT;

