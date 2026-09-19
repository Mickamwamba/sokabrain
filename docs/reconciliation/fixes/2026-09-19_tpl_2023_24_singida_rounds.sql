-- TPL 2023/24: four Singida Black Stars fixtures were filed under the wrong round.
--
-- The vault's 2023/24 rounds came from the official site; FotMob's fixture list
-- disagreed on exactly four fixtures, every one of them a Singida Black Stars
-- match. The kickoff dates settle all four in FotMob's favour, and the round
-- sizes prove it arithmetically: before this fix rounds 1, 17 and 27 hold nine
-- fixtures and rounds 5, 11 and 12 hold seven. Afterwards all thirty hold eight.
--
--   17583 KMC FC v Singida Black Stars        7 Oct 2023 -- round 28 is 20-22 May 2024, round 5 is 3-8 Oct 2023
--   17624 JKT Tanzania v Singida Black Stars 26 Nov 2023 -- round 27 is 12-14 May 2024, round 11 is 26 Nov-2 Dec 2023
--   17632 Singida Black Stars v Tanzania Prisons 4 Dec 2023 -- round 1 is 15-23 Aug 2023, round 12 is 30 Nov-16 Dec 2023
--   17769 TRA United v Singida Black Stars   22 May 2024 -- round 17 is Feb 2024, round 28 is 20-22 May 2024
--
-- The load recorded these as PENDING reconciliation_diffs; they are resolved
-- ACCEPT_B here rather than by the loader, which never overwrites (principle 2).

BEGIN;

UPDATE matches SET round = '5'  WHERE id = 17583 AND round = '28';
UPDATE matches SET round = '11' WHERE id = 17624 AND round = '27';
UPDATE matches SET round = '12' WHERE id = 17632 AND round = '1';
UPDATE matches SET round = '28' WHERE id = 17769 AND round = '17';

UPDATE reconciliation_diffs
   SET resolution = 'ACCEPT_B',
       resolved_value = split_part(trim(leading 'round ' from value_b), ' ', 1),
       resolved_at = now()
 WHERE field_name = 'matches.round'
   AND resolution = 'PENDING'
   AND entity_id_a IN (17583, 17624, 17632, 17769);

COMMIT;
