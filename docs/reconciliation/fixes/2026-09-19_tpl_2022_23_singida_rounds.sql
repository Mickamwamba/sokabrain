-- TPL 2022/23: five Singida Black Stars fixtures were filed under the wrong round.
--
-- The same defect as 2023/24 (see 2026-09-19_tpl_2023_24_singida_rounds.sql),
-- and again every disputed fixture is a Singida Black Stars match. Each one's
-- kickoff falls inside FotMob's round and nowhere near the vault's, and the
-- round sizes prove it: before this fix rounds 6, 13, 16 and 17 hold nine
-- fixtures and rounds 7, 10, 19 and 25 hold seven. Afterwards all thirty hold
-- eight. (Round 21 already holds eight -- it has one intruder and one absentee,
-- which cancel.)
--
--   17350 Mbeya City v Singida Black Stars        8 Oct 2022 -- round 17 is 20-22 Dec, round 7 opens 7 Oct
--   17375 Azam FC v Singida Black Stars          31 Oct 2022 -- round 6 is 1-4 Oct, round 10 opens 29 Oct
--   17457 Singida Black Stars v KMC FC            3 Jan 2023 -- round 13 is 19-23 Nov, round 19 is 30 Dec-2 Jan
--   17467 Tanzania Prisons v Singida Black Stars 21 Jan 2023 -- round 16 is 15-18 Dec, round 21 is 20-24 Jan
--   17504 Singida Black Stars v Azam FC          13 Mar 2023 -- round 21 is 20-24 Jan, round 25 is 9-12 Mar

BEGIN;

UPDATE matches SET round = '7'  WHERE id = 17350 AND round = '17';
UPDATE matches SET round = '10' WHERE id = 17375 AND round = '6';
UPDATE matches SET round = '19' WHERE id = 17457 AND round = '13';
UPDATE matches SET round = '21' WHERE id = 17467 AND round = '16';
UPDATE matches SET round = '25' WHERE id = 17504 AND round = '21';

UPDATE reconciliation_diffs
   SET resolution = 'ACCEPT_B',
       resolved_value = split_part(trim(leading 'round ' from value_b), ' ', 1),
       resolved_at = now()
 WHERE field_name = 'matches.round'
   AND resolution = 'PENDING'
   AND entity_id_a IN (17350, 17375, 17457, 17467, 17504);

COMMIT;
