-- 28 events sat on matches their team never played in, and four goals were
-- unnamed because the name was on the wrong copy.
--
-- These are the audit's 14 open ORPHAN_EVENT findings, run down one by one.
-- They are also why ten AFCON 2019 matches held more goal events than their
-- score allowed. Every one comes from the legacy SokaFC migration.
--
-- Three distinct things were going on, and they do not get the same treatment.
--
-- 1. FOUR GOALS WHOSE SCORER WE HAD ALL ALONG. For two matches the legacy data
--    holds the event set twice: once on the right match with no scorer, and
--    once on a wrong match WITH the scorer named. The minutes agree, so the
--    pairing is not a guess:
--
--      DR Congo 0-2 Uganda (929)  had Uganda goals at 14' and 48', unnamed.
--      The copy on match 938 names Patrick Kaddu (14') and Emmanuel Okwi (49').
--
--      Guinea 2-2 Madagascar (931) had Guinea goals at 34' and 66', unnamed.
--      The copy on match 945 names Sory Kaba (34') and François Kamano (66',
--      a penalty -- so the goal's type was wrong too).
--
--    Both readings agree with the published reports of those two ties, and with
--    match 931's own Madagascar goals, which are already named. The name is
--    copied onto the real event and the stray copy is then deleted. Okwi's
--    minute is left at 48 rather than moved to 49: this fix is about identity,
--    not timing, the same call made for Eto'o's 2002 goal.
--
-- 2. TWO REAL GOALS WEARING THE WRONG TEAM. Each is the only goal event on a
--    match that needs exactly one, so the score itself says whose it is:
--
--      UD Songo 0-1 Simba SC (987) -- its 24th-minute goal was filed under
--      Power Dinamos, a club that plays no match in the vault. It is Simba's.
--
--      Malawi 1-1 South Sudan (1323) -- Malawi's goal is recorded; the 15th
--      minute goal was filed under Guinea, who are not in the match. Guinea's
--      own qualifiers both hold the right number of events, so nothing of
--      theirs is missing. It is South Sudan's.
--
-- 3. TWENTY-SIX EVENTS THAT ARE SURPLUS, AND DELETED. Twelve are exact
--    duplicates of events already correctly recorded on the right match -- the
--    same player, the same minute, sometimes a minute out. Fourteen are
--    fragments credited to twelve Tanzanian clubs that play no match anywhere
--    in the vault, carrying no minute and, bar one, no player. Every match
--    they sit on already reproduces its score without them (the single
--    exception, Tunisia 1-1 Angola, is a goal genuinely missing from its
--    source and is not touched here). They cannot be attached to any fixture,
--    so they are recorded as diffs and removed.
--
-- The twelve clubs themselves are NOT deleted. Three of them hold player
-- registrations, so they are real clubs whose matches the migration never
-- brought over -- not phantoms.

BEGIN;

INSERT INTO reconciliation_runs (entity_type, data_source_a_id, data_source_b_id, notes)
VALUES ('match_event', 1, 1,
  'Legacy SokaFC orphan events: 28 events attached to matches their team never played in, across 14 matches and chiefly AFCON 2019. Four goals were named from a misfiled duplicate that carried the scorer, two goals re-sided to the only team the score allows, and 26 surplus events deleted (12 exact duplicates, 14 unattributable fragments). Raised by the audit check ORPHAN_EVENT.');

/* -- 1. name the four goals from the copy that carried the scorer ---------- */

CREATE TEMP TABLE naming (event int, player int, player_name text, from_event int, new_type text) ON COMMIT DROP;
INSERT INTO naming VALUES
  (1903, (SELECT player_id FROM match_events WHERE id = 1871), 'Patrick Henry Kaddu',   1871, NULL),
  (1904, (SELECT player_id FROM match_events WHERE id = 1873), 'Emmanuel Arnold Okwi',  1873, NULL),
  (1902, (SELECT player_id FROM match_events WHERE id = 1872), 'Sory Kaba',             1872, NULL),
  (1905, (SELECT player_id FROM match_events WHERE id = 3027), 'Francois Kamano',       3027, 'PENALTY_GOAL');

-- Refuse to run if the vault is not in the state the reasoning above assumes.
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM naming n
    JOIN match_events e ON e.id = n.event
   WHERE e.player_id IS NOT NULL;
  IF bad > 0 THEN RAISE EXCEPTION '% target event(s) already name a player', bad; END IF;

  SELECT count(*) INTO bad FROM naming n WHERE n.player IS NULL;
  IF bad > 0 THEN RAISE EXCEPTION '% source event(s) name no player', bad; END IF;

  -- The two copies must agree on the team, or they are not the same goal.
  SELECT count(*) INTO bad FROM naming n
    JOIN match_events a ON a.id = n.event
    JOIN match_events b ON b.id = n.from_event
   WHERE a.team_id IS DISTINCT FROM b.team_id;
  IF bad > 0 THEN RAISE EXCEPTION '% pair(s) disagree on the team', bad; END IF;
END $$;

INSERT INTO reconciliation_diffs (reconciliation_run_id, entity_id_a, entity_id_b, field_name, value_a, value_b, resolution, resolved_value, resolved_at)
SELECT currval('reconciliation_runs_id_seq'), n.event, n.from_event, 'match_events.player_id',
       'no scorer', n.player_name || ' (event ' || n.from_event || ', match ' || b.match_id || ')',
       'MANUAL', n.player::text, now()
  FROM naming n JOIN match_events b ON b.id = n.from_event;

UPDATE match_events e SET player_id = n.player FROM naming n WHERE e.id = n.event;
UPDATE match_events e SET type = n.new_type FROM naming n WHERE e.id = n.event AND n.new_type IS NOT NULL;

/* -- 2. re-side the two goals the score can only assign one way ------------ */

INSERT INTO reconciliation_diffs (reconciliation_run_id, entity_id_a, entity_id_b, field_name, value_a, value_b, resolution, resolved_value, resolved_at)
SELECT currval('reconciliation_runs_id_seq'), e.id, e.match_id, 'match_events.team_id',
       t.name, want.name, 'MANUAL', want.id::text, now()
  FROM match_events e JOIN teams t ON t.id = e.team_id
  JOIN (VALUES (1969, 'Simba SC'), (2255, 'South Sudan')) AS v(event, team) ON v.event = e.id
  JOIN teams want ON want.name = v.team;

UPDATE match_events e SET team_id = want.id
  FROM (VALUES (1969, 'Simba SC'), (2255, 'South Sudan')) AS v(event, team)
  JOIN teams want ON want.name = v.team
 WHERE e.id = v.event;

/* -- 3. delete the surplus ------------------------------------------------- */

CREATE TEMP TABLE doomed (id int, why text) ON COMMIT DROP;
INSERT INTO doomed VALUES
  -- goals whose name has just been copied onto the real event
  (1871, 'duplicate of event 1903, Uganda 14'''),
  (1873, 'duplicate of event 1904, Uganda 48'''),
  (1872, 'duplicate of event 1902, Guinea 34'''),
  (3027, 'duplicate of event 1905, Guinea 66'' penalty'),
  -- cards already recorded on the right match
  (3143, 'duplicate of event 3147, Jjuuko 35'''),
  (3144, 'duplicate of event 3148, Bolasie 47'''),
  (3145, 'duplicate of event 3149, Bokadi 54'''),
  (2964, 'duplicate of event 2965, Keimuine own goal 89'''),
  (3139, 'duplicate of event 3154, Keimuine 92'''),
  (3140, 'duplicate of event 3155, Feisal Salum 9'''),
  (3141, 'duplicate of event 3157, Himid Mao 36'''),
  (3142, 'duplicate of event 3158, Simon Msuva 63'''),
  -- fragments on clubs that play no match in the vault
  (1771, 'Mabibo FC fragment, no minute'),
  (1772, 'Mabibo FC fragment, no minute'),
  (1773, 'Dili chuma fragment, no minute'),
  (1774, 'Navy Kenzo fragment, no minute'),
  (1775, 'Sifa United fragment, no minute'),
  (1795, 'Friens Rangers fragment, no minute'),
  (1796, 'Goba Ham FC fragment, no minute'),
  (1797, 'Ukwakwani FC fragment, no minute'),
  (1798, 'Stimu Tosha fragment, no minute'),
  (1799, 'Stimu Tosha fragment, no minute'),
  (1800, 'Stimu Tosha fragment, no minute'),
  (1801, 'Sinza United fragment, no minute'),
  (1802, 'Ubungo Kombaini fragment, no minute'),
  (1803, 'Magomeni Kombaini fragment, no minute');

-- Nothing may be deleted that is still attached to a team in its own match:
-- that would be real data, not an orphan.
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM doomed d
    JOIN match_events e ON e.id = d.id
    JOIN matches m ON m.id = e.match_id
   WHERE e.team_id IN (m.home_team_id, m.away_team_id);
  IF bad > 0 THEN RAISE EXCEPTION '% event(s) marked for deletion belong to their match', bad; END IF;
END $$;

INSERT INTO reconciliation_diffs (reconciliation_run_id, entity_id_a, entity_id_b, field_name, value_a, value_b, resolution, resolved_value, resolved_at)
SELECT currval('reconciliation_runs_id_seq'), e.id, e.match_id, 'match_events.deleted',
       e.type || ' for ' || coalesce(t.name, '(no team)') ||
         coalesce(' by ' || p.full_name, '') || coalesce(' at ' || e.minute || '''', ' with no minute'),
       d.why, 'MANUAL', 'deleted', now()
  FROM doomed d JOIN match_events e ON e.id = d.id
  LEFT JOIN teams t ON t.id = e.team_id LEFT JOIN players p ON p.id = e.player_id;

DELETE FROM match_events WHERE id IN (SELECT id FROM doomed);

/* -- verification ---------------------------------------------------------- */
SET timezone = 'UTC';

\echo ''
\echo 'No event may be left on a match its team did not play in (expect 0):'
SELECT count(*) AS orphans_left
  FROM match_events e JOIN matches m ON m.id = e.match_id
 WHERE e.team_id IS NOT NULL AND e.team_id NOT IN (m.home_team_id, m.away_team_id);

\echo ''
\echo 'The four goals that now have a scorer:'
SELECT e.match_id, ht.name || ' v ' || at.name AS fixture, p.full_name AS scorer, e.minute, e.type
  FROM match_events e JOIN matches m ON m.id = e.match_id
  JOIN teams ht ON ht.id = m.home_team_id JOIN teams at ON at.id = m.away_team_id
  JOIN players p ON p.id = e.player_id
 WHERE e.id IN (1902, 1903, 1904, 1905) ORDER BY e.match_id, e.minute;

\echo ''
\echo 'The two re-sided goals now sit with a team that is playing:'
SELECT e.id, ht.name || ' ' || m.home_score || '-' || m.away_score || ' ' || at.name AS fixture,
       t.name AS credited_to, e.minute
  FROM match_events e JOIN matches m ON m.id = e.match_id
  JOIN teams ht ON ht.id = m.home_team_id JOIN teams at ON at.id = m.away_team_id
  JOIN teams t ON t.id = e.team_id
 WHERE e.id IN (1969, 2255);

\echo ''
\echo 'AFCON 2019: goal events against the score, which should now agree:'
SELECT sum(m.home_score + m.away_score) AS goals,
       (SELECT count(*) FROM match_events e JOIN matches m2 ON m2.id = e.match_id
         WHERE m2.competition_edition_id = 14 AND e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL')) AS goal_events
  FROM matches m WHERE m.competition_edition_id = 14 AND m.home_score IS NOT NULL;

\echo ''
\echo 'Matches across the vault still holding more goal events than their score:'
WITH x AS (
  SELECT m.id, coalesce(m.home_score_et, m.home_score) + coalesce(m.away_score_et, m.away_score) AS goals,
         (SELECT count(*) FROM match_events e WHERE e.match_id = m.id
           AND e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL')) AS events
    FROM matches m WHERE m.home_score IS NOT NULL)
SELECT count(*) AS matches_with_excess FROM x WHERE x.events > x.goals;

COMMIT;
