-- Kenya's top tier is renamed "Premier League", matching every other league.
--
-- The competition came out of the legacy SokaFC dump as "Kenya premier league"
-- -- carrying its own country, and in casing nothing else uses. Now that the API
-- prefixes every competition with its country for display
-- (backend/src/services/competitionName.ts), that name is the one record that
-- cannot be displayed consistently: the prefix rule skips it to avoid
-- "Kenya Kenya premier league", so it alone reads lowercase beside
-- "Tanzania Premier League" and "Uganda Premier League".
--
-- Storing the country in the name also duplicates competitions.country_id, which
-- is what the display rule exists to avoid.
--
-- **The slug is deliberately left alone** ('kenya-premier-league'): the codebase
-- already treats a slug as something that may be in a URL, and renaming does not
-- change it (see routes/adminManage.ts).
--
-- Nothing else changes: the competition keeps its id (17), its two editions and
-- all 159 of their matches. It now displays as "Kenya Premier League".

BEGIN;

UPDATE competitions
   SET name = 'Premier League'
 WHERE id = 17
   AND name = 'Kenya premier league';

COMMIT;
