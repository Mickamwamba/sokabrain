-- Kenya: "Mathare Utd." and "Mathare United" are one club, now one record.
--
-- Found 2026-09-19 by the near-miss check in ingestSportmonksLeague.ts, while
-- standing up the Kenyan Premier League's 2026/27 season. SportMonks calls the
-- club "Mathare United", which matched the vault's team #178 exactly -- and #178
-- is an EMPTY record:
--
--   #171 "Mathare Utd."    17 matches, 15 events, 8 player stints
--   #178 "Mathare United"   0 matches,  0 events, 0 stints, 0 participations
--
-- Both came from the legacy SokaFC dump, which held the club under two spellings.
-- Left alone, the 2026/27 season would have attached to #178 and the club's
-- history would have been split in two -- 2019/20 under one record and 2026/27
-- under another. That is the defect this project has spent the most time undoing.
--
-- "Mathare Utd." is an abbreviation of "Mathare United" (Mathare United FC,
-- Nairobi). Nothing whatsoever depends on #178, so it is deleted rather than
-- merged, and #171 takes the full name. No match, event, lineup or stint moves,
-- because #178 has none.
--
-- Its legacy provenance row is deleted with it: it records that the legacy dump
-- held a row with that id, and #171 already carries its own legacy provenance.

BEGIN;

-- Guard: refuse to run if #178 has gained any dependency since this was written.
DO $$
DECLARE n integer;
BEGIN
  SELECT (SELECT count(*) FROM matches WHERE home_team_id=178 OR away_team_id=178)
       + (SELECT count(*) FROM match_events WHERE team_id=178)
       + (SELECT count(*) FROM match_lineups WHERE team_id=178)
       + (SELECT count(*) FROM player_team_stints WHERE team_id=178)
       + (SELECT count(*) FROM competition_edition_teams WHERE team_id=178)
    INTO n;
  IF n <> 0 THEN
    RAISE EXCEPTION 'team 178 now has % dependent row(s); do not delete it, merge instead', n;
  END IF;
END $$;

DELETE FROM entity_source_map WHERE entity_type='team' AND entity_id=178;
DELETE FROM teams WHERE id=178;

-- Now the name is free.
UPDATE teams SET name='Mathare United' WHERE id=171 AND name='Mathare Utd.';

COMMIT;
