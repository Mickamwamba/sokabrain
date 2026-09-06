import { Prisma } from '@prisma/client';
import { prisma } from '../db.js';

export type TopScorerRow = {
  rank: number;
  playerId: number;
  playerName: string;
  teamId: number | null;
  teamName: string | null;
  goals: number;
  penalties: number;
  matchesScoredIn: number;
};

export type TopScorersResult = {
  scorers: TopScorerRow[];
  /**
   * Legacy event logs are incomplete, so a scorer chart built from them is a
   * lower bound rather than an authoritative record. We surface that instead of
   * hiding it (design principle 6: never dress thin data up as complete).
   */
  coverage: {
    attributedGoals: number;
    unattributedGoals: number;
    matchesPlayed: number;
    matchesWithEvents: number;
  };
};

/**
 * Top scorers for one competition edition, computed from `match_events`.
 *
 * Counting rules:
 *  - GOAL and PENALTY_GOAL count for the player who scored; `penalties` breaks
 *    out the latter.
 *  - OWN_GOAL is deliberately EXCLUDED. Per design principle 5 an own goal is
 *    credited to the opposing team, and it is in no case a goal scored by the
 *    player who put it in — counting it here is the same class of bug that
 *    already bit the legacy migration once.
 *  - Events with a NULL `player_id` cannot be attributed to anyone and are
 *    excluded from the chart, but are counted in `coverage.unattributedGoals`
 *    so callers can tell how complete the picture is.
 *
 * The team shown is the team the player scored for on those events, which is
 * the meaningful one for a season chart even if the player has since moved.
 */
export async function getTopScorers(
  editionId: number,
  limit: number,
): Promise<TopScorersResult> {
  const scorers = await prisma.$queryRaw<Array<Omit<TopScorerRow, 'rank'>>>(Prisma.sql`
    SELECT
      p.id                                                            AS "playerId",
      p.full_name                                                     AS "playerName",
      max(t.id)                                                       AS "teamId",
      max(t.name)                                                     AS "teamName",
      count(*)::int                                                   AS goals,
      count(*) FILTER (WHERE e.type = 'PENALTY_GOAL')::int            AS penalties,
      count(DISTINCT e.match_id)::int                                 AS "matchesScoredIn"
    FROM match_events e
    JOIN matches m  ON m.id = e.match_id
    JOIN players p  ON p.id = e.player_id
    LEFT JOIN teams t ON t.id = e.team_id
    WHERE m.competition_edition_id = ${editionId}
      -- OWN_GOAL is intentionally absent from this list. See the doc comment.
      AND e.type IN ('GOAL', 'PENALTY_GOAL')
      AND e.player_id IS NOT NULL
    GROUP BY p.id, p.full_name
    ORDER BY goals DESC, "matchesScoredIn" ASC, p.full_name ASC
    LIMIT ${limit}
  `);

  const [coverage] = await prisma.$queryRaw<
    Array<TopScorersResult['coverage']>
  >(Prisma.sql`
    SELECT
      count(e.id) FILTER (
        WHERE e.type IN ('GOAL','PENALTY_GOAL') AND e.player_id IS NOT NULL
      )::int AS "attributedGoals",
      count(e.id) FILTER (
        WHERE e.type IN ('GOAL','PENALTY_GOAL') AND e.player_id IS NULL
      )::int AS "unattributedGoals",
      count(DISTINCT m.id)::int AS "matchesPlayed",
      count(DISTINCT m.id) FILTER (WHERE e.id IS NOT NULL)::int AS "matchesWithEvents"
    FROM matches m
    LEFT JOIN match_events e ON e.match_id = m.id
    WHERE m.competition_edition_id = ${editionId}
      AND m.status = 'FULL_TIME'
  `);

  return {
    scorers: scorers.map((row, i) => ({ rank: i + 1, ...row })),
    coverage: coverage ?? {
      attributedGoals: 0,
      unattributedGoals: 0,
      matchesPlayed: 0,
      matchesWithEvents: 0,
    },
  };
}
