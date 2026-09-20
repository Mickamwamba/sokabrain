-- matches.live_minute: the clock while a match is in play.
--
-- The site can now show a live score, and a live score without a minute is half
-- the information -- "0-0" says nothing about whether it is the 3rd minute or
-- the 88th. SportMonks publishes it on the fixture's ticking period
-- (`periods.minutes`), so the sync captures it.
--
-- **It is transient, and deliberately so.** The column is only meaningful while
-- `status = 'LIVE'`; the sync clears it the moment a match reaches any other
-- state, so a finished match never carries a stale clock. Nothing historical
-- depends on it and no ingestion writes it -- it is the one genuinely live field
-- in an otherwise historical vault.
--
-- SMALLINT because a minute fits easily, including stoppage time counted past
-- 90 (a period can tick to 90+ and the provider reports 90 there).

BEGIN;

ALTER TABLE matches ADD COLUMN IF NOT EXISTS live_minute SMALLINT;

COMMENT ON COLUMN matches.live_minute IS
  'Clock in minutes while status = LIVE; NULL otherwise. Set and cleared by the live-score sync.';

COMMIT;
