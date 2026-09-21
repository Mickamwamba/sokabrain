-- South Africa's last two unattributed goals, named from the provider's own
-- player record.
--
-- Both were loaded UNATTRIBUTED by `npm run sm:events` because the loader read
-- only `/players/{id}`.name, and fell back to firstname+lastname when that was
-- NULL rather than when it was an ABBREVIATION. The same response already
-- carried a real name in another field:
--
--   id 37551650  name "S. Junior Dion"  display_name "Junior Dion"   firstname "Sede"
--   id 37550321  name "G. Philander"    display_name "G. Philander"  firstname "Giovanni"
--
-- `loadSportmonksEvents.ts` now takes whichever of the three is not an
-- abbreviation, so a fresh load resolves both. It will not repair these two on
-- its own: it never adds to a match that already holds goal events, and these
-- matches do. Hence this file.
--
--   * Golden Arrows 1-0 Stellenbosch, 70' (event 33315) -- Junior Dion. The
--     vault ALREADY holds him as player 13184, mapped to this very provider id:
--     the same load named his 76th minute against Sekhukhune, where the event
--     feed happened to spell him out, and left this one blank where it said
--     "S. Dion". No new player record -- that would have split one man in two,
--     which is this project's most expensive recurring defect.
--   * Polokwane City 3-3 Stellenbosch, 16' (event 33362) -- Giovanni Philander,
--     created here; the vault holds no Philander.
--
-- Neither match's score changes and neither event moves team or minute, so
-- reconciliation is unaffected: only a NULL player_id is filled.
--
-- Reverse with:
--   UPDATE match_events SET player_id = NULL WHERE id IN (33315, 33362);
--   DELETE FROM entity_source_map WHERE entity_type = 'match_event'
--     AND entity_id IN (33315, 33362);
--   -- then remove the Giovanni Philander player and its provenance row.

BEGIN;

-- 1. Golden Arrows 70' -> the Junior Dion the vault already holds.
UPDATE match_events
   SET player_id = 13184
 WHERE id = 33315
   AND player_id IS NULL
   AND match_id = 22927 AND minute = 70 AND type = 'GOAL';

-- 2. Giovanni Philander, whom the vault does not hold.
INSERT INTO players (full_name)
SELECT 'Giovanni Philander'
 WHERE NOT EXISTS (SELECT 1 FROM players WHERE full_name = 'Giovanni Philander');

INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
SELECT 'player', p.id, ds.id, 'id:37550321', 1.0
  FROM players p, data_sources ds
 WHERE p.full_name = 'Giovanni Philander' AND ds.name = 'sportmonks'
ON CONFLICT DO NOTHING;

UPDATE match_events
   SET player_id = (SELECT id FROM players WHERE full_name = 'Giovanni Philander')
 WHERE id = 33362
   AND player_id IS NULL
   AND match_id = 22946 AND minute = 16 AND type = 'GOAL';

-- 3. Provenance for both events (principle 1): the name came from SportMonks.
INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
SELECT 'match_event', v.event_id, ds.id, v.external_id, 1.0
  FROM (VALUES (33315, '22927-70-GOAL'), (33362, '22946-16-GOAL')) AS v(event_id, external_id),
       data_sources ds
 WHERE ds.name = 'sportmonks'
ON CONFLICT DO NOTHING;

COMMIT;
