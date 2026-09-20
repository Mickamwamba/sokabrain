-- Rwanda 2026/27: SportMonks lists one fixture twice and omits its reverse.
--
-- Found 2026-09-19 while standing up the league (edition 404). SportMonks' list
-- holds 306 entries but only **305 distinct ordered club pairs** for 18 clubs,
-- where a double round-robin needs 306:
--
--   Police Rwanda v Al Merreikh  appears TWICE -- round 2 (28 Oct 2026, fixture
--                                19862919) and round 19 (5 Feb 2027, 19862747)
--   Al Merreikh v Police Rwanda  appears NOWHERE
--
-- So the round-19 entry has its sides the wrong way round: that slot belongs to
-- the reverse fixture, which the source simply does not carry. The round-2 entry
-- is the legitimate one -- round 2 otherwise holds eight fixtures where every
-- other round holds nine, and 28 October fits its window.
--
-- The first load had no duplicate-pair check, so the second entry collapsed onto
-- the first: match 22461 was created with the round-19 date and then gained a
-- second provenance row. This corrects it to the round-2 entry, drops the
-- spurious mapping, and flags the gap so 305-of-306 is explained rather than
-- read as a missing fixture forever. ingestSportmonksLeague.ts now refuses to
-- merge a duplicated pair silently.
--
-- Nothing is lost: both entries are unplayed, so no score or event is involved.

BEGIN;

-- The legitimate round-2 fixture.
UPDATE matches
   SET round = '2',
       kickoff_at = '2026-10-28 13:00:00+00'
 WHERE id = 22461
   AND competition_edition_id = 404;

-- One vault match, one provider fixture.
DELETE FROM entity_source_map
 WHERE entity_type = 'match'
   AND entity_id = 22461
   AND external_id = '19862747';

INSERT INTO data_flags (entity_type, entity_id, severity, reason)
VALUES ('competition_edition', 404, 'INFO',
        'Holds 305 of the 306 fixtures a double round-robin of 18 clubs needs. '
        'SportMonks omits Al Merreikh v Police Rwanda (round 19) and lists the '
        'reverse fixture, Police Rwanda v Al Merreikh, twice instead. The round-2 '
        'entry is kept; the round-19 duplicate is not loaded. Round 19 therefore '
        'holds eight fixtures. This is absent source data, not a dropped row -- '
        'do not go looking for the missing fixture again.');

COMMIT;
