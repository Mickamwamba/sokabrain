import { Prisma } from '@prisma/client';
import { prisma } from '../db.js';

export type StandingsRow = {
  position: number;
  teamId: number;
  teamName: string;
  shortName: string | null;
  logoUrl: string | null;
  played: number;
  won: number;
  drawn: number;
  lost: number;
  goalsFor: number;
  goalsAgainst: number;
  goalDifference: number;
  points: number;
};

/**
 * League table for one competition edition.
 *
 * Computes, per team, from FULL_TIME matches only: played, W/D/L, goals for /
 * against, goal difference and points (3 for a win, 1 for a draw).
 *
 * Two schema realities drive the shape of this query:
 *
 *  1. It reads the STORED `matches.home_score` / `away_score` rather than
 *     aggregating `match_events` (design principle 3). Besides being far
 *     cheaper, this is also what makes the table correct for the 12 legacy
 *     matches whose event log is known to be incomplete, and it means own-goal
 *     attribution (principle 5) is already baked into the stored score.
 *
 *  2. Participating teams are derived from the matches themselves, because
 *     `competition_edition_teams` is empty for every migrated edition. A team
 *     that played zero matches therefore does not appear at all.
 *
 * Ordering is the standard football tiebreak chain: points, then goal
 * difference, then goals scored, then name for a stable deterministic result.
 */
export type StandingsResult = {
  standings: StandingsRow[];
  /**
   * Many migrated matches are marked FULL_TIME but carry no score, so teams can
   * legitimately show different `played` counts and the table will not sum to
   * the edition's full fixture list. Callers should surface this rather than
   * let the table read as broken.
   */
  coverage: {
    matchesFullTime: number;
    matchesCounted: number;
    matchesMissingScore: number;
  };
};

export async function getStandings(editionId: number): Promise<StandingsResult> {
  const rows = await prisma.$queryRaw<Array<Omit<StandingsRow, 'position'>>>(Prisma.sql`
    WITH sides AS (
      -- One row per team per match: the match seen from that team's point of view.
      SELECT m.home_team_id AS team_id, m.home_score AS gf, m.away_score AS ga
      FROM matches m
      WHERE m.competition_edition_id = ${editionId}
        AND m.status = 'FULL_TIME'
        AND m.home_score IS NOT NULL AND m.away_score IS NOT NULL
      UNION ALL
      SELECT m.away_team_id, m.away_score, m.home_score
      FROM matches m
      WHERE m.competition_edition_id = ${editionId}
        AND m.status = 'FULL_TIME'
        AND m.home_score IS NOT NULL AND m.away_score IS NOT NULL
    ),
    tallied AS (
      SELECT
        team_id,
        count(*)::int                                   AS played,
        count(*) FILTER (WHERE gf > ga)::int            AS won,
        count(*) FILTER (WHERE gf = ga)::int            AS drawn,
        count(*) FILTER (WHERE gf < ga)::int            AS lost,
        COALESCE(sum(gf), 0)::int                       AS "goalsFor",
        COALESCE(sum(ga), 0)::int                       AS "goalsAgainst",
        COALESCE(sum(gf - ga), 0)::int                  AS "goalDifference",
        (count(*) FILTER (WHERE gf > ga) * 3
         + count(*) FILTER (WHERE gf = ga))::int        AS points
      FROM sides
      GROUP BY team_id
    )
    SELECT
      t.id AS "teamId", t.name AS "teamName",
      t.short_name AS "shortName", t.logo_url AS "logoUrl",
      x.played, x.won, x.drawn, x.lost,
      x."goalsFor", x."goalsAgainst", x."goalDifference", x.points
    FROM tallied x
    JOIN teams t ON t.id = x.team_id
    ORDER BY x.points DESC, x."goalDifference" DESC, x."goalsFor" DESC, t.name ASC
  `);

  const [coverage] = await prisma.$queryRaw<Array<StandingsResult['coverage']>>(Prisma.sql`
    SELECT
      count(*) FILTER (WHERE status = 'FULL_TIME')::int AS "matchesFullTime",
      count(*) FILTER (
        WHERE status = 'FULL_TIME' AND home_score IS NOT NULL AND away_score IS NOT NULL
      )::int AS "matchesCounted",
      count(*) FILTER (
        WHERE status = 'FULL_TIME' AND (home_score IS NULL OR away_score IS NULL)
      )::int AS "matchesMissingScore"
    FROM matches
    WHERE competition_edition_id = ${editionId}
  `);

  return {
    standings: rows.map((row, i) => ({ position: i + 1, ...row })),
    coverage: coverage ?? {
      matchesFullTime: 0,
      matchesCounted: 0,
      matchesMissingScore: 0,
    },
  };
}
