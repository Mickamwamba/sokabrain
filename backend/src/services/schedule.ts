import { Prisma } from '@prisma/client';
import { prisma } from '../db.js';

/**
 * What a fan needs to navigate fixtures: which dates have football on them,
 * which rounds exist, and where "now" sits in the season.
 *
 * Date is the primary axis here on purpose. Kickoff dates are complete for all
 * 4,380 matches and were verified against two independent sources; round
 * numbers exist for 2,577 of them, because the sources do not publish a round
 * for every season. Anything round-shaped is therefore optional, and the caller
 * is told when it is unavailable rather than being handed invented matchdays.
 */

export type DayCount = { date: string; matches: number; played: number };

/**
 * Match days around an anchor date, for a date strip.
 *
 * Returns days that actually have football, not a plain calendar run -- this
 * league plays in bursts, so a strip of empty Tuesdays would waste the control.
 */
export async function matchDays(opts: {
  editionId?: number | undefined;
  around: string;
  before?: number | undefined;
  after?: number | undefined;
}): Promise<{ days: DayCount[]; nearest: string | null }> {
  const { editionId, around, before = 8, after = 8 } = opts;
  const scope = editionId
    ? Prisma.sql`AND m.competition_edition_id = ${editionId}`
    : Prisma.empty;

  const all = await prisma.$queryRaw<DayCount[]>(Prisma.sql`
    SELECT to_char((m.kickoff_at AT TIME ZONE 'Africa/Dar_es_Salaam')::date, 'YYYY-MM-DD') AS date,
           count(*)::int AS matches,
           count(*) FILTER (WHERE m.home_score IS NOT NULL)::int AS played
      FROM matches m
      JOIN competition_editions ce ON ce.id = m.competition_edition_id AND ce.is_published = TRUE
     WHERE m.kickoff_at IS NOT NULL ${scope}
     GROUP BY 1
     ORDER BY 1
  `);

  // Window the list in JS rather than SQL: the set of distinct match days is
  // small (about 1,400 rows) and the windowing logic is far easier to read.
  let i = all.findIndex((d) => d.date >= around);
  if (i === -1) i = all.length - 1;
  const nearest = all[i]?.date ?? null;
  return {
    days: all.slice(Math.max(0, i - before), i + after + 1),
    nearest,
  };
}

export type RoundSummary = {
  round: string;
  sortKey: number;
  matches: number;
  played: number;
  firstDate: string | null;
  lastDate: string | null;
};

/**
 * The rounds of one edition, in playing order, plus the one to open on.
 *
 * `rounds` is empty for a season whose sources publish no round numbers. That is
 * a real state, not an error: the caller falls back to date navigation rather
 * than inventing matchdays, because deriving them from the fixture sequence is
 * only 72-98% accurate and puts every postponed fixture in the wrong one.
 */
export async function editionRounds(editionId: number): Promise<{
  rounds: RoundSummary[];
  currentRound: string | null;
  hasRounds: boolean;
  /** Matches in this edition that no source gives a round for. */
  withoutRound: number;
}> {
  const rounds = await prisma.$queryRaw<RoundSummary[]>(Prisma.sql`
    SELECT m.round,
           -- Rounds are stored as text; order numerically where they are
           -- numeric, so "9" does not sort after "10".
           COALESCE(NULLIF(regexp_replace(m.round, '\D', '', 'g'), ''), '0')::int AS "sortKey",
           count(*)::int AS matches,
           count(*) FILTER (WHERE m.home_score IS NOT NULL)::int AS played,
           to_char(min(m.kickoff_at AT TIME ZONE 'Africa/Dar_es_Salaam'), 'YYYY-MM-DD') AS "firstDate",
           to_char(max(m.kickoff_at AT TIME ZONE 'Africa/Dar_es_Salaam'), 'YYYY-MM-DD') AS "lastDate"
      FROM matches m
      JOIN competition_editions ce ON ce.id = m.competition_edition_id AND ce.is_published = TRUE
     WHERE m.competition_edition_id = ${editionId} AND m.round IS NOT NULL
     GROUP BY m.round
     ORDER BY "sortKey", m.round
  `);

  // Round coverage is partial for most seasons, so a round can be missing some
  // of its fixtures. Saying how many are unplaceable is better than letting a
  // round of eight quietly render as a round of six.
  const [gap] = await prisma.$queryRaw<Array<{ n: number }>>(Prisma.sql`
    SELECT count(*)::int AS n FROM matches
     WHERE competition_edition_id = ${editionId} AND round IS NULL
  `);

  const inProgress = rounds.find((r) => r.played < r.matches);
  const currentRound = inProgress?.round ?? rounds[rounds.length - 1]?.round ?? null;
  return {
    rounds,
    currentRound,
    hasRounds: rounds.length > 0,
    withoutRound: gap?.n ?? 0,
  };
}

/**
 * Where the competition is "now": the season in play, and its next fixture.
 *
 * The current season is the published edition whose fixtures span today. Out of
 * season -- or once the archive ends -- it falls back to the most recent, so the
 * site always opens on something rather than on an empty state.
 */
export async function currentContext(): Promise<{
  editionId: number | null;
  season: string | null;
  competition: string | null;
  nextMatchDate: string | null;
  lastMatchDate: string | null;
  inSeason: boolean;
}> {
  const [row] = await prisma.$queryRaw<Array<{
    editionId: number; season: string; competition: string;
    nextDate: string | null; lastDate: string | null; inSeason: boolean;
  }>>(Prisma.sql`
    WITH spans AS (
      SELECT ce.id AS edition_id, s.label AS season, c.name AS competition,
             min(m.kickoff_at) AS starts, max(m.kickoff_at) AS ends
        FROM competition_editions ce
        JOIN competitions c ON c.id = ce.competition_id
        JOIN seasons s ON s.id = ce.season_id
        JOIN matches m ON m.competition_edition_id = ce.id
       WHERE ce.is_published = TRUE
       GROUP BY ce.id, s.label, c.name
    )
    SELECT edition_id AS "editionId", season, competition,
           (SELECT to_char(min(m.kickoff_at AT TIME ZONE 'Africa/Dar_es_Salaam'), 'YYYY-MM-DD')
              FROM matches m
             WHERE m.competition_edition_id = spans.edition_id
               AND m.home_score IS NULL AND m.kickoff_at >= now()) AS "nextDate",
           (SELECT to_char(max(m.kickoff_at AT TIME ZONE 'Africa/Dar_es_Salaam'), 'YYYY-MM-DD')
              FROM matches m
             WHERE m.competition_edition_id = spans.edition_id
               AND m.home_score IS NOT NULL) AS "lastDate",
           (now() BETWEEN starts AND ends) AS "inSeason"
      FROM spans
     ORDER BY (now() BETWEEN starts AND ends) DESC, ends DESC
     LIMIT 1
  `);
  if (!row) {
    return { editionId: null, season: null, competition: null,
             nextMatchDate: null, lastMatchDate: null, inSeason: false };
  }
  return {
    editionId: row.editionId,
    season: row.season,
    competition: row.competition,
    nextMatchDate: row.nextDate,
    lastMatchDate: row.lastDate,
    inSeason: row.inSeason,
  };
}
