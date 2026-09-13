import { Prisma } from '@prisma/client';
import { prisma } from '../../db.js';
import { conflictsFor, staleOpenSpells, type Spell, type SpellType } from '../careers.js';
import type { Detection, Severity } from './reconcile.js';

/**
 * Every data-audit check. Each one reads the vault and reports problems as
 * Detections; it never writes. Reconciliation with past findings happens in
 * reconcile.ts.
 *
 * Checks are grouped by what they inspect so one query serves many: all match
 * checks share a single pass over the matches in scope.
 *
 * A check's `facts` decide its fingerprint, so they hold what identifies the
 * problem — the score, the counts — and never something that drifts on its
 * own, like "3 days ago". Otherwise an ACCEPTED finding would reopen daily.
 */

export type CheckDef = {
  key: string;
  label: string;
  area: 'Scores' | 'Events' | 'Fixtures' | 'Seasons' | 'Careers';
  severity: Severity;
  describes: string;
};

export const CHECKS: CheckDef[] = [
  { key: 'MISSING_SCORE', area: 'Scores', severity: 'CRITICAL', label: 'Completed with no score', describes: 'A match marked full time has no score recorded.' },
  { key: 'EVENTS_CONTRADICT_SCORE', area: 'Scores', severity: 'CRITICAL', label: 'Events contradict the score', describes: 'The goal events, with own goals credited to the other side, add up to a different result than the stored score.' },
  { key: 'EVENTS_EXCEED_SCORE', area: 'Scores', severity: 'CRITICAL', label: 'More goal events than goals', describes: 'The event log holds more goals than the score allows — a duplicate event or a wrong score.' },
  { key: 'SCORE_ON_UNPLAYED', area: 'Scores', severity: 'WARNING', label: 'Score on an unplayed match', describes: 'A scheduled, postponed or cancelled match carries a score.' },
  { key: 'SHOOTOUT_ON_UNLEVEL_SCORE', area: 'Scores', severity: 'WARNING', label: 'Shootout after a decisive score', describes: 'Penalties are recorded but the score is not level.' },
  { key: 'MISSING_GOAL_EVENTS', area: 'Events', severity: 'WARNING', label: 'Goals missing from the event log', describes: 'Some, but not all, of the goals in the score have an event.' },
  { key: 'UNNAMED_SCORER', area: 'Events', severity: 'WARNING', label: 'Goal with no scorer', describes: 'An observed goal event names no player.' },
  { key: 'ORPHAN_EVENT', area: 'Events', severity: 'WARNING', label: 'Event for neither team', describes: 'An event is attached to no team, or to a team not playing in the match.' },
  { key: 'EVENT_MINUTE_OUT_OF_RANGE', area: 'Events', severity: 'WARNING', label: 'Impossible minute', describes: 'An event minute is negative or beyond 130.' },
  { key: 'STALE_SCHEDULED', area: 'Fixtures', severity: 'WARNING', label: 'Kickoff passed, no result', describes: 'Still scheduled or live more than a day after kickoff.' },
  { key: 'SELF_FIXTURE', area: 'Fixtures', severity: 'CRITICAL', label: 'Team playing itself', describes: 'The home and away team are the same.' },
  { key: 'DUPLICATE_FIXTURE', area: 'Fixtures', severity: 'WARNING', label: 'Duplicate league fixture', describes: 'The same home-and-away pairing appears more than once in a league season.' },
  { key: 'KICKOFF_OUTSIDE_SEASON', area: 'Fixtures', severity: 'WARNING', label: 'Kickoff outside the season', describes: 'The kickoff date falls outside the season’s start and end dates.' },
  { key: 'MISSING_KICKOFF', area: 'Fixtures', severity: 'INFO', label: 'No kickoff date', describes: 'A match has no date at all.' },
  { key: 'MISSING_FIXTURES', area: 'Seasons', severity: 'WARNING', label: 'League fixtures missing', describes: 'A league season holds fewer fixtures than its teams imply (n × (n − 1)).' },
  { key: 'UNEVEN_GAMES_PLAYED', area: 'Seasons', severity: 'WARNING', label: 'Uneven games played', describes: 'A finished league season has teams more than two games apart.' },
  { key: 'NO_EVENT_LOG', area: 'Seasons', severity: 'INFO', label: 'Scored matches with no event log', describes: 'Matches with goals in the score and no goal events at all.' },
  { key: 'DERIVED_SCORERS_UNKNOWN', area: 'Seasons', severity: 'INFO', label: 'Goals derived from scores', describes: 'Goal events generated from the score, so their scorers are unknown.' },
  { key: 'UNLISTED_PARTICIPANTS', area: 'Seasons', severity: 'INFO', label: 'Playing but not listed', describes: 'Teams with matches in the season but no participant entry.' },
  { key: 'PARTICIPANTS_WITHOUT_MATCHES', area: 'Seasons', severity: 'INFO', label: 'Listed but never playing', describes: 'Participants with no match in a season that has matches.' },
  { key: 'TEAM_COUNT_MISMATCH', area: 'Seasons', severity: 'INFO', label: 'Team count mismatch', describes: 'The season’s declared number of teams differs from the teams actually playing.' },
  { key: 'OVERLAPPING_SPELLS', area: 'Careers', severity: 'WARNING', label: 'Overlapping club spells', describes: 'A player is contracted to two clubs at once (loans excepted).' },
  { key: 'STALE_OPEN_SPELL', area: 'Careers', severity: 'WARNING', label: 'Open spell contradicted', describes: 'A spell still running although a later club spell began.' },
];

const SEVERITY = Object.fromEntries(CHECKS.map((c) => [c.key, c.severity])) as Record<string, Severity>;
const plural = (n: number, one: string, many = `${one}s`) => `${n} ${n === 1 ? one : many}`;

const detect = (
  checkKey: string,
  entityType: Detection['entityType'],
  entityId: number,
  editionId: number | null,
  detail: string,
  facts: Record<string, unknown>,
  severity: Severity = SEVERITY[checkKey]!,
): Detection => ({ checkKey, entityType, entityId, editionId, severity, detail, facts });

/* --------------------------------------------------------------- matches -- */

type MatchRow = {
  id: number;
  edition_id: number;
  competition_type: string;
  status: string;
  kickoff: string | null;
  kickoff_past_day: boolean;
  home_id: number;
  away_id: number;
  home: string;
  away: string;
  hs: number | null;
  as: number | null;
  het: number | null;
  aet: number | null;
  hp: number | null;
  ap: number | null;
  season_start: string | null;
  season_end: string | null;
  goal_events: number;
  unnamed_observed: number;
  derived: number;
  orphans: number;
  bad_minutes: number;
  credited_home: number;
  credited_away: number;
};

async function matchChecks(editionIds: number[]): Promise<Detection[]> {
  if (editionIds.length === 0) return [];
  const rows = await prisma.$queryRaw<MatchRow[]>(Prisma.sql`
    WITH ev AS (
      SELECT e.match_id,
        count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL'))::int AS goal_events,
        count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL') AND e.player_id IS NULL
                           AND (e.detail->>'derived') IS DISTINCT FROM 'score')::int AS unnamed_observed,
        count(*) FILTER (WHERE e.detail->>'derived' = 'score')::int AS derived,
        count(*) FILTER (WHERE e.team_id IS NULL OR e.team_id NOT IN (m.home_team_id, m.away_team_id))::int AS orphans,
        count(*) FILTER (WHERE e.minute < 0 OR e.minute > 130)::int AS bad_minutes,
        -- An OWN_GOAL's team is the scorer's own side; it counts for the other
        -- one (design principle 5).
        count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL') AND
          (CASE WHEN e.type = 'OWN_GOAL'
                THEN CASE WHEN e.team_id = m.home_team_id THEN m.away_team_id ELSE m.home_team_id END
                ELSE e.team_id END) = m.home_team_id)::int AS credited_home,
        count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL') AND
          (CASE WHEN e.type = 'OWN_GOAL'
                THEN CASE WHEN e.team_id = m.home_team_id THEN m.away_team_id ELSE m.home_team_id END
                ELSE e.team_id END) = m.away_team_id)::int AS credited_away
      FROM match_events e JOIN matches m ON m.id = e.match_id
      WHERE m.competition_edition_id = ANY(${editionIds})
      GROUP BY e.match_id
    )
    SELECT m.id, m.competition_edition_id AS edition_id, c.type AS competition_type, m.status,
           to_char(m.kickoff_at, 'YYYY-MM-DD') AS kickoff,
           (m.kickoff_at < now() - interval '1 day') AS kickoff_past_day,
           m.home_team_id AS home_id, m.away_team_id AS away_id, th.name AS home, ta.name AS away,
           m.home_score AS hs, m.away_score AS "as",
           m.home_score_et AS het, m.away_score_et AS aet, m.home_score_pens AS hp, m.away_score_pens AS ap,
           to_char(se.start_date, 'YYYY-MM-DD') AS season_start, to_char(se.end_date, 'YYYY-MM-DD') AS season_end,
           COALESCE(ev.goal_events, 0) AS goal_events, COALESCE(ev.unnamed_observed, 0) AS unnamed_observed,
           COALESCE(ev.derived, 0) AS derived, COALESCE(ev.orphans, 0) AS orphans,
           COALESCE(ev.bad_minutes, 0) AS bad_minutes,
           COALESCE(ev.credited_home, 0) AS credited_home, COALESCE(ev.credited_away, 0) AS credited_away
      FROM matches m
      JOIN competition_editions ce ON ce.id = m.competition_edition_id
      JOIN competitions c ON c.id = ce.competition_id
      JOIN seasons se ON se.id = ce.season_id
      JOIN teams th ON th.id = m.home_team_id
      JOIN teams ta ON ta.id = m.away_team_id
      LEFT JOIN ev ON ev.match_id = m.id
     WHERE m.competition_edition_id = ANY(${editionIds})
  `);

  const out: Detection[] = [];
  const pairs = new Map<string, number[]>();

  for (const r of rows) {
    const d = (key: string, detail: string, facts: Record<string, unknown>, sev?: Severity) =>
      out.push(detect(key, 'match', r.id, r.edition_id, detail, facts, sev));
    const hasScore = r.hs !== null && r.as !== null;
    // The event log runs to the final whistle, so it is compared with the
    // result after extra time where there was any. The vault stores the ET
    // columns as a running total (all 46 such matches), so they are the final
    // score; the regular columns hold the 90 minutes.
    const aet = r.het !== null && r.aet !== null;
    const fh = aet ? r.het! : (r.hs ?? 0);
    const fa = aet ? r.aet! : (r.as ?? 0);
    const scored = fh + fa;
    const score = hasScore ? (aet ? `${fh}-${fa} after extra time` : `${r.hs}-${r.as}`) : null;

    if (r.status === 'FULL_TIME' && !hasScore) d('MISSING_SCORE', 'Marked full time with no score recorded', {});
    if (r.home_id === r.away_id) d('SELF_FIXTURE', `${r.home} is listed against itself`, {});
    if (['SCHEDULED', 'POSTPONED', 'CANCELLED'].includes(r.status) && hasScore) {
      d('SCORE_ON_UNPLAYED', `${r.status.toLowerCase()} but carries a ${score} score`, { status: r.status, score });
    }
    if (r.hp !== null && r.ap !== null && hasScore && r.hs !== r.as) {
      d('SHOOTOUT_ON_UNLEVEL_SCORE', `Penalties ${r.hp}-${r.ap} recorded after a ${score} score`, { score, pens: `${r.hp}-${r.ap}` });
    }
    if (hasScore && r.goal_events > scored) {
      d('EVENTS_EXCEED_SCORE', `${plural(r.goal_events, 'goal event')} for a ${score} score`, { score, goalEvents: r.goal_events });
    } else if (hasScore && r.goal_events === scored && scored > 0 && (r.credited_home !== fh || r.credited_away !== fa)) {
      d('EVENTS_CONTRADICT_SCORE', `Events read ${r.credited_home}-${r.credited_away}, the score says ${score}`,
        { score, events: `${r.credited_home}-${r.credited_away}` });
    } else if (hasScore && r.goal_events > 0 && r.goal_events < scored) {
      d('MISSING_GOAL_EVENTS', `${plural(scored - r.goal_events, 'goal')} of ${scored} missing from the event log`,
        { score, goalEvents: r.goal_events });
    }
    if (r.unnamed_observed > 0) d('UNNAMED_SCORER', `${plural(r.unnamed_observed, 'goal')} with no scorer named`, { count: r.unnamed_observed });
    if (r.orphans > 0) d('ORPHAN_EVENT', `${plural(r.orphans, 'event')} not attached to either team`, { count: r.orphans });
    if (r.bad_minutes > 0) d('EVENT_MINUTE_OUT_OF_RANGE', `${plural(r.bad_minutes, 'event')} with an impossible minute`, { count: r.bad_minutes });
    if ((r.status === 'SCHEDULED' || r.status === 'LIVE') && r.kickoff_past_day) {
      // The kickoff date is in the facts; "N days ago" is not, or an accepted
      // finding would reopen every day.
      d('STALE_SCHEDULED', `Still ${r.status.toLowerCase()}, kickoff was ${r.kickoff}`, { status: r.status, kickoff: r.kickoff });
    }
    if (r.kickoff === null) d('MISSING_KICKOFF', 'No kickoff date recorded', {});
    if (r.kickoff && r.season_start && r.season_end && (r.kickoff < r.season_start || r.kickoff > r.season_end)) {
      d('KICKOFF_OUTSIDE_SEASON', `Kickoff ${r.kickoff} is outside the season (${r.season_start} to ${r.season_end})`,
        { kickoff: r.kickoff, seasonStart: r.season_start, seasonEnd: r.season_end });
    }
    if (r.competition_type === 'LEAGUE') {
      const key = `${r.edition_id}:${r.home_id}:${r.away_id}`;
      pairs.set(key, [...(pairs.get(key) ?? []), r.id]);
    }
  }

  // A double round robin plays each home-and-away pairing once. Every copy
  // after the first is flagged, pointing at the one it duplicates.
  const byId = new Map(rows.map((r) => [r.id, r]));
  for (const ids of pairs.values()) {
    if (ids.length < 2) continue;
    const [first, ...rest] = [...ids].sort((a, b) => a - b);
    for (const id of rest) {
      const r = byId.get(id)!;
      out.push(detect('DUPLICATE_FIXTURE', 'match', id, r.edition_id,
        `${r.home} v ${r.away} is also match #${first}`, { duplicateOf: first }));
    }
  }
  return out;
}

/* --------------------------------------------------------------- seasons -- */

type EditionRow = {
  id: number;
  competition_type: string;
  num_teams: number | null;
  fixtures: number;
  remaining: number;
  teams_playing: number[];
  listed: number[];
  no_event_log: number;
  derived: number;
  min_played: number | null;
  max_played: number | null;
};

async function editionChecks(editionIds: number[]): Promise<Detection[]> {
  if (editionIds.length === 0) return [];
  const rows = await prisma.$queryRaw<EditionRow[]>(Prisma.sql`
    SELECT ce.id, c.type AS competition_type, ce.num_teams,
      (SELECT count(*) FROM matches m WHERE m.competition_edition_id = ce.id)::int AS fixtures,
      (SELECT count(*) FROM matches m WHERE m.competition_edition_id = ce.id
          AND m.status IN ('SCHEDULED','LIVE','POSTPONED'))::int AS remaining,
      COALESCE((SELECT array_agg(DISTINCT t ORDER BY t) FROM (
          SELECT home_team_id AS t FROM matches WHERE competition_edition_id = ce.id
          UNION SELECT away_team_id FROM matches WHERE competition_edition_id = ce.id) x), '{}') AS teams_playing,
      COALESCE((SELECT array_agg(team_id ORDER BY team_id) FROM competition_edition_teams
          WHERE competition_edition_id = ce.id), '{}') AS listed,
      (SELECT count(*) FROM matches m WHERE m.competition_edition_id = ce.id
          AND COALESCE(m.home_score, 0) + COALESCE(m.away_score, 0) > 0
          AND NOT EXISTS (SELECT 1 FROM match_events e WHERE e.match_id = m.id
                          AND e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL')))::int AS no_event_log,
      (SELECT count(*) FROM match_events e JOIN matches m ON m.id = e.match_id
          WHERE m.competition_edition_id = ce.id AND e.detail->>'derived' = 'score')::int AS derived,
      p.min_played, p.max_played
    FROM competition_editions ce
    JOIN competitions c ON c.id = ce.competition_id
    LEFT JOIN LATERAL (
      SELECT min(n)::int AS min_played, max(n)::int AS max_played FROM (
        SELECT t, count(*) AS n FROM (
          SELECT home_team_id AS t FROM matches WHERE competition_edition_id = ce.id
             AND status = 'FULL_TIME' AND home_score IS NOT NULL AND away_score IS NOT NULL
          UNION ALL
          SELECT away_team_id FROM matches WHERE competition_edition_id = ce.id
             AND status = 'FULL_TIME' AND home_score IS NOT NULL AND away_score IS NOT NULL
        ) s GROUP BY t) g
    ) p ON TRUE
    WHERE ce.id = ANY(${editionIds})
  `);

  const out: Detection[] = [];
  const names = new Map(
    (await prisma.teams.findMany({
      where: { id: { in: [...new Set(rows.flatMap((r) => [...r.teams_playing, ...r.listed]))] } },
      select: { id: true, name: true },
    })).map((t) => [t.id, t.name]),
  );
  const list = (ids: number[]) => {
    const shown = ids.slice(0, 5).map((i) => names.get(i) ?? `#${i}`).join(', ');
    return ids.length > 5 ? `${shown} and ${ids.length - 5} more` : shown;
  };

  for (const r of rows) {
    const d = (key: string, detail: string, facts: Record<string, unknown>) =>
      out.push(detect(key, 'competition_edition', r.id, r.id, detail, facts));
    const league = r.competition_type === 'LEAGUE';

    // The same n*(n-1) the league table uses to call a season provisional.
    if (league && r.num_teams && r.num_teams > 1) {
      const expected = r.num_teams * (r.num_teams - 1);
      if (r.fixtures < expected) {
        d('MISSING_FIXTURES', `${plural(expected - r.fixtures, 'fixture')} missing: ${r.fixtures} of ${expected} for ${r.num_teams} teams`,
          { fixtures: r.fixtures, expected });
      }
    }
    if (league && r.remaining === 0 && r.min_played !== null && r.max_played !== null && r.max_played - r.min_played > 2) {
      d('UNEVEN_GAMES_PLAYED', `Finished, but teams played between ${r.min_played} and ${r.max_played} games`,
        { min: r.min_played, max: r.max_played });
    }
    if (r.no_event_log > 0) d('NO_EVENT_LOG', `${plural(r.no_event_log, 'scored match', 'scored matches')} with no goal events`, { count: r.no_event_log });
    if (r.derived > 0) d('DERIVED_SCORERS_UNKNOWN', `${plural(r.derived, 'goal')} derived from scores, scorer unknown`, { count: r.derived });

    if (r.fixtures > 0) {
      const listed = new Set(r.listed);
      const playing = new Set(r.teams_playing);
      const unlisted = r.teams_playing.filter((t) => !listed.has(t));
      const idle = r.listed.filter((t) => !playing.has(t));
      if (unlisted.length) d('UNLISTED_PARTICIPANTS', `${plural(unlisted.length, 'team')} playing but not listed: ${list(unlisted)}`, { teams: unlisted });
      if (idle.length) d('PARTICIPANTS_WITHOUT_MATCHES', `${plural(idle.length, 'listed team')} with no matches: ${list(idle)}`, { teams: idle });
      if (r.num_teams && r.num_teams !== r.teams_playing.length) {
        d('TEAM_COUNT_MISMATCH', `Declared ${r.num_teams} teams, ${r.teams_playing.length} actually playing`,
          { declared: r.num_teams, playing: r.teams_playing.length });
      }
    }
  }
  return out;
}

/* --------------------------------------------------------------- careers -- */

async function careerChecks(): Promise<Detection[]> {
  const rows = await prisma.player_team_stints.findMany({
    include: { teams: { select: { name: true, type: true } } },
  });
  const byPlayer = new Map<number, Spell[]>();
  for (const r of rows) {
    const list = byPlayer.get(r.player_id) ?? [];
    list.push({
      id: r.id,
      teamId: r.team_id,
      teamName: r.teams.name,
      teamType: r.teams.type as 'CLUB' | 'NATIONAL',
      start: r.start_date ? r.start_date.toISOString().slice(0, 10) : '0001-01-01',
      end: r.end_date ? r.end_date.toISOString().slice(0, 10) : null,
      type: (r.transfer_type as SpellType | null) ?? null,
    });
    byPlayer.set(r.player_id, list);
  }

  const out: Detection[] = [];
  for (const [playerId, spells] of byPlayer) {
    // Each clashing pair once, lower id first, so the facts are stable.
    const pairs = new Set<string>();
    const names = new Set<string>();
    for (const s of spells) {
      for (const c of conflictsFor(s, spells)) {
        pairs.add([s.id, c.id].sort((a, b) => a - b).join('-'));
        names.add(s.teamName).add(c.teamName);
      }
    }
    if (pairs.size) {
      out.push(detect('OVERLAPPING_SPELLS', 'player', playerId, null,
        `${plural(pairs.size, 'overlapping pair')} of club spells (${[...names].join(', ')})`, { pairs: [...pairs].sort() }));
    }
    const stale = staleOpenSpells(spells);
    if (stale.size) {
      const facts = [...stale].map(([id, end]) => `${id}:${end}`).sort();
      const teams = spells.filter((s) => stale.has(s.id)).map((s) => s.teamName);
      out.push(detect('STALE_OPEN_SPELL', 'player', playerId, null,
        `Spell at ${teams.join(', ')} still open although a later club spell began`, { spells: facts }));
    }
  }
  return out;
}

export async function runChecks(editionIds: number[], includeCareers: boolean): Promise<Detection[]> {
  const [matches, editions, careers] = await Promise.all([
    matchChecks(editionIds),
    editionChecks(editionIds),
    includeCareers ? careerChecks() : Promise.resolve([]),
  ]);
  return [...matches, ...editions, ...careers];
}
