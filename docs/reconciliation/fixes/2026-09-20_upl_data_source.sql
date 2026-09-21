-- The Uganda Premier League's official site as a data source.
--
-- upl.co.ug runs SportsPress on WordPress, the same stack as Tanzania's
-- ligikuu.co.tz, and publishes a directory of 1,716 registered players with
-- FULL names at /wp-json/sportspress/v2/players. Its robots.txt is a bare
-- `Disallow:` -- everything permitted.
--
-- It is needed because SportMonks gives this league's scorers as a display
-- string that is often an abbreviation ("S. Achidi") with no player id behind
-- it, and this project never writes an abbreviation into the player table. The
-- directory turns those initials into people; see
-- docs/ingestion/topup_scorers_from_directory.py.
--
-- Classed SCRAPED rather than API to sit beside ligikuu, which is the same
-- stack reached the same way. Reverse with:
--   DELETE FROM data_sources WHERE name = 'upl';
-- (which will fail while any entity_source_map row still references it -- that
-- is the point, and those rows must be removed first).

INSERT INTO data_sources (name, type, base_url)
VALUES ('upl', 'SCRAPED', 'https://upl.co.ug')
ON CONFLICT (name) DO NOTHING;
