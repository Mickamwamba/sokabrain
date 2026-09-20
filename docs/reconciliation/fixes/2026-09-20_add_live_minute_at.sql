-- matches.live_minute_at: when the clock was last seen RUNNING.
--
-- `live_minute` alone is a number the server captured up to two minutes ago, so
-- a page renders it and it then sits frozen. This column is the anchor that lets
-- a browser tick it: the minute plus the wall-clock time since it was captured.
--
-- **It is set only while the clock is actually ticking**, and NULL otherwise.
-- That is what stops a browser advancing the clock through half time. A live
-- match whose clock is not running is, by definition, at a break -- which is how
-- the UI knows to show "HT" rather than a minute that would be a lie by the time
-- anyone read it.
--
-- Paired with a change in the sync: `live_minute` now KEEPS its last value for
-- as long as the match is live, instead of being nulled the moment the clock
-- pauses. At half time the provider publishes no ticking period at all, so the
-- naive reading blanked the minute exactly when a viewer most wants to see 45'.

BEGIN;

ALTER TABLE matches ADD COLUMN IF NOT EXISTS live_minute_at TIMESTAMPTZ;

COMMENT ON COLUMN matches.live_minute_at IS
  'When live_minute was captured with the clock RUNNING; NULL at a break or when not live.';

COMMIT;
