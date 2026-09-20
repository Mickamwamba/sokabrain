import { Prisma } from '@prisma/client';
import { competitionDisplayName } from './competitionName.js';
import { prisma } from '../db.js';

/**
 * Everything one match page needs, in one call.
 *
 * Scoped to published editions like the rest of the public read API, so an
 * unpublished season cannot be reached by guessing a match id.
 *
 * The event log is returned with an honest `coverage` block rather than as a
 * bare list. Coverage across this vault is uneven by era -- 2008/09 to 2022/23
 * have complete scores and no events at all -- so a page that simply rendered
 * an empty timeline would read as "nothing happened" instead of "not recorded".
 */

export type MatchEventRow = {
  id: number;
  type: string;
  minute: number | null;
  addedTime: number | null;
  side: 'home' | 'away' | null;
  playerId: number | null;
  playerName: string | null;
  /** True for the OWN_GOAL case: scored by `side`, but it counts for the other. */
  countsForOtherSide: boolean;
};

export type MatchDetail = {
  id: number;
  kickoffAt: Date | null;
  status: string;
  round: string | null;
  venue: string | null;
  competition: { editionId: number; name: string; season: string };
  /** Clock in minutes while LIVE; null otherwise. */
  liveMinute: number | null;
  /** When that clock was captured RUNNING — the anchor a client ticks from. */
  liveMinuteAt: Date | null;
  home: TeamSide;
  away: TeamSide;
  events: MatchEventRow[];
  coverage: {
    goalsInScore: number;
    goalEventsRecorded: number;
    /** The event log accounts for every goal in the score. */
    eventLogComplete: boolean;
    /** Nothing at all was recorded for this match. */
    noEventLog: boolean;
    unnamedScorers: number;
    hasAssists: boolean;
  };
  headToHead: { played: number; homeWins: number; awayWins: number; draws: number };
  form: { home: FormResult[]; away: FormResult[] };
};

type TeamSide = { id: number; name: string; shortName: string | null; score: number | null };
type FormResult = { matchId: number; result: 'W' | 'D' | 'L'; opponent: string; score: string };

const GOAL_TYPES = ['GOAL', 'PENALTY_GOAL', 'OWN_GOAL'];

export async function getMatchDetail(id: number): Promise<MatchDetail | null> {
  const rows = await prisma.$queryRaw<Array<{
    id: number; kickoff_at: Date | null; status: string; round: string | null;
    venue: string | null; live_minute: number | null; live_minute_at: Date | null;
    edition_id: number; competition: string;
    competition_country: string | null; season: string;
    home_team_id: number; home_name: string; home_short: string | null; home_score: number | null;
    away_team_id: number; away_name: string; away_short: string | null; away_score: number | null;
  }>>(Prisma.sql`
    SELECT m.id, m.kickoff_at, m.status, m.round, m.live_minute, m.live_minute_at, st.name AS venue,
           ce.id AS edition_id, c.name AS competition, co.name AS competition_country,
           s.label AS season,
           th.id AS home_team_id, th.name AS home_name, th.short_name AS home_short, m.home_score,
           ta.id AS away_team_id, ta.name AS away_name, ta.short_name AS away_short, m.away_score
      FROM matches m
      JOIN competition_editions ce ON ce.id = m.competition_edition_id
      JOIN competitions c ON c.id = ce.competition_id
      LEFT JOIN countries co ON co.id = c.country_id
      JOIN seasons s ON s.id = ce.season_id
      JOIN teams th ON th.id = m.home_team_id
      JOIN teams ta ON ta.id = m.away_team_id
      LEFT JOIN stadiums st ON st.id = m.stadium_id
     WHERE m.id = ${id} AND ce.is_published = TRUE
  `);
  const m = rows[0];
  if (!m) return null;

  const events = await prisma.$queryRaw<Array<{
    id: number; type: string; minute: number | null; added_time: number | null;
    team_id: number | null; player_id: number | null; player_name: string | null;
  }>>(Prisma.sql`
    SELECT e.id, e.type, e.minute, e.added_time, e.team_id, e.player_id, p.full_name AS player_name
      FROM match_events e
      LEFT JOIN players p ON p.id = e.player_id
     WHERE e.match_id = ${id}
     ORDER BY e.minute NULLS LAST, e.added_time NULLS FIRST, e.id
  `);

  const [h2h] = await prisma.$queryRaw<Array<{
    played: number; home_wins: number; away_wins: number; draws: number;
  }>>(Prisma.sql`
    -- Every meeting between the two clubs, in either direction, counted from
    -- THIS match's home side's point of view.
    WITH met AS (
      SELECT CASE WHEN x.home_team_id = ${m.home_team_id} THEN x.home_score ELSE x.away_score END AS a,
             CASE WHEN x.home_team_id = ${m.home_team_id} THEN x.away_score ELSE x.home_score END AS b
        FROM matches x
        JOIN competition_editions ce ON ce.id = x.competition_edition_id AND ce.is_published = TRUE
       WHERE x.home_score IS NOT NULL
         AND ((x.home_team_id = ${m.home_team_id} AND x.away_team_id = ${m.away_team_id})
           OR (x.home_team_id = ${m.away_team_id} AND x.away_team_id = ${m.home_team_id}))
    )
    SELECT count(*)::int AS played,
           count(*) FILTER (WHERE a > b)::int AS home_wins,
           count(*) FILTER (WHERE a < b)::int AS away_wins,
           count(*) FILTER (WHERE a = b)::int AS draws
      FROM met
  `);

  const form = async (teamId: number): Promise<FormResult[]> => {
    const f = await prisma.$queryRaw<Array<{
      id: number; gf: number; ga: number; opponent: string;
    }>>(Prisma.sql`
      SELECT x.id,
             CASE WHEN x.home_team_id = ${teamId} THEN x.home_score ELSE x.away_score END AS gf,
             CASE WHEN x.home_team_id = ${teamId} THEN x.away_score ELSE x.home_score END AS ga,
             CASE WHEN x.home_team_id = ${teamId} THEN ta.name ELSE th.name END AS opponent
        FROM matches x
        JOIN competition_editions ce ON ce.id = x.competition_edition_id AND ce.is_published = TRUE
        JOIN teams th ON th.id = x.home_team_id
        JOIN teams ta ON ta.id = x.away_team_id
       WHERE x.home_score IS NOT NULL
         AND (x.home_team_id = ${teamId} OR x.away_team_id = ${teamId})
         AND (${m.kickoff_at}::timestamptz IS NULL OR x.kickoff_at < ${m.kickoff_at}::timestamptz)
       ORDER BY x.kickoff_at DESC
       LIMIT 5
    `);
    return f.map((r) => ({
      matchId: r.id,
      result: r.gf > r.ga ? 'W' : r.gf < r.ga ? 'L' : 'D',
      opponent: r.opponent,
      score: `${r.gf}-${r.ga}`,
    }));
  };

  const goalEvents = events.filter((e) => GOAL_TYPES.includes(e.type));
  const goalsInScore = (m.home_score ?? 0) + (m.away_score ?? 0);

  return {
    id: m.id,
    kickoffAt: m.kickoff_at,
    status: m.status,
    round: m.round,
    venue: m.venue,
    liveMinute: m.live_minute,
    liveMinuteAt: m.live_minute_at,
    competition: {
      editionId: m.edition_id,
      name: competitionDisplayName(m.competition, m.competition_country),
      season: m.season,
    },
    home: { id: m.home_team_id, name: m.home_name, shortName: m.home_short, score: m.home_score },
    away: { id: m.away_team_id, name: m.away_name, shortName: m.away_short, score: m.away_score },
    events: events.map((e) => ({
      id: e.id,
      type: e.type,
      minute: e.minute,
      addedTime: e.added_time,
      side: e.team_id === m.home_team_id ? 'home' : e.team_id === m.away_team_id ? 'away' : null,
      playerId: e.player_id,
      playerName: e.player_name,
      // Principle 5: an own goal's team is the scorer's own side; the goal
      // counts for the opposition. The page needs to show it on the right side
      // of the timeline without misattributing the score.
      countsForOtherSide: e.type === 'OWN_GOAL',
    })),
    coverage: {
      goalsInScore,
      goalEventsRecorded: goalEvents.length,
      eventLogComplete: m.home_score !== null && goalEvents.length === goalsInScore,
      noEventLog: events.length === 0,
      unnamedScorers: goalEvents.filter((e) => e.player_id === null).length,
      hasAssists: events.some((e) => e.type === 'ASSIST'),
    },
    headToHead: {
      played: h2h?.played ?? 0,
      homeWins: h2h?.home_wins ?? 0,
      awayWins: h2h?.away_wins ?? 0,
      draws: h2h?.draws ?? 0,
    },
    form: { home: await form(m.home_team_id), away: await form(m.away_team_id) },
  };
}
