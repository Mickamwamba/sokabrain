-- Two ingested matches whose event log holds more goals than the score allows.
--
-- Both come from ligikuu.co.tz, whose score and event log disagree with each
-- other. The score agrees with whoscored.com in both cases, so the score is
-- sound and the event log has one row too many -- but which row is wrong is a
-- judgement no script should make, so they are flagged for a person.

BEGIN;

INSERT INTO data_flags (entity_type, entity_id, severity, reason) VALUES
 ('match', 17991, 'WARNING',
  'Event log holds 6 goals for a 3-2 result. Tanzania Prisons already has three '
  'GOAL rows matching its score, and an additional JKT Tanzania OWN_GOAL would '
  'credit it a fourth. One of the two is redundant; the source does not say which.'),
 ('match', 18006, 'WARNING',
  'Event log holds 6 Azam FC goals for a 5-0 result. Lusajo Mwaikenda is recorded '
  'twice, once at minute 5 and once with no minute -- almost certainly the same '
  'goal entered twice on ligikuu.co.tz. Deleting the minute-less row would make '
  'the log match the score.');

\echo 'open flags on the ingested editions:'
SELECT f.entity_id, left(f.reason, 60) FROM data_flags f WHERE f.status='OPEN'
  AND f.entity_type='match' AND f.entity_id IN (17991, 18006);

COMMIT;
