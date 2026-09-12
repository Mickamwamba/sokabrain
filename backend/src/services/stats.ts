import { Prisma } from '@prisma/client';
import { prisma } from '../db.js';

/**
 * Fan-facing aggregate stats.
 *
 * Everything here is scoped to PUBLISHED editions only — these power the public
 * site, so an unpublished edition must not leak into a leaderboard.
 *
 * What is deliberately absent: attendance, stadium capacity, possession, xG,
 * shot data. The vault holds none of it (0 rows for attendance and capacity),
 * and inventing plausible-looking numbers to fill a card is exactly what design
 * principle 6 forbids.
 */

/** Reused everywhere: the set of editions the public is allowed to see. */
/**
 * The editions a public query may read, optionally narrowed to one competition.
 *
 * Every stat is scoped through this one fragment, so making it competition-
 * aware makes all of them competition-aware at once. That matters now the site
 * carries more than the league: an all-time top scorer list spanning the TPL
 * and AFCON together answers a question nobody asked.
 */
function publishedEditionsIn(competitionId?: number) {
  return competitionId
    ? Prisma.sql`
        SELECT id FROM competition_editions
         WHERE is_published = TRUE AND competition_id = ${competitionId}`
    : Prisma.sql`SELECT id FROM competition_editions WHERE is_published = TRUE`;
}

/** Shared scope for every stats query: a competition, a season, or neither. */
export type StatsScope = {
  competitionId?: number | undefined;
  editionId?: number | undefined;
};

export type ClubStat = {
  teamId: number;
  teamName: string;
  shortName: string | null;
  played: number;
  won: number;
  drawn: number;
  lost: number;
  goalsFor: number;
  goalsAgainst: number;
  goalDifference: number;
  points: number;
  cleanSheets: number;
  winRate: number;
  goalsPerGame: number;
};

/**
 * Club aggregates, either for one edition or across every published edition.
 *
 * Clean sheets are derived from the stored score (opponent scored zero), not
 * from the event log — the event log is too incomplete to count absences from.
 */
/**
 * Which kind of team a stats page is about.
 *
 * `teams.type` already separates these, and the distinction became load-bearing
 * the day AFCON was published: without it a page headed "Club stats" lists
 * Egypt and Nigeria next to Yanga and Simba, and a club/country comparison is
 * not a comparison at all.
 */
export type TeamType = 'CLUB' | 'NATIONAL';

export async function clubStats(
  scopeIn: StatsScope = {},
  teamType?: TeamType,
): Promise<ClubStat[]> {
  const { competitionId, editionId } = scopeIn;
  const scope = editionId
    ? Prisma.sql`AND m.competition_edition_id = ${editionId}`
    : Prisma.empty;
  const kind = teamType
    ? Prisma.sql`WHERE t.type = ${teamType}`
    : Prisma.empty;

  return prisma.$queryRaw<ClubStat[]>(Prisma.sql`
    WITH sides AS (
      SELECT m.home_team_id AS team_id, m.home_score AS gf, m.away_score AS ga
      FROM matches m
      WHERE m.competition_edition_id IN (${publishedEditionsIn(competitionId)})
        AND m.status = 'FULL_TIME'
        AND m.home_score IS NOT NULL AND m.away_score IS NOT NULL
        ${scope}
      UNION ALL
      SELECT m.away_team_id, m.away_score, m.home_score
      FROM matches m
      WHERE m.competition_edition_id IN (${publishedEditionsIn(competitionId)})
        AND m.status = 'FULL_TIME'
        AND m.home_score IS NOT NULL AND m.away_score IS NOT NULL
        ${scope}
    ),
    tallied AS (
      SELECT
        team_id,
        count(*)::int                                            AS played,
        count(*) FILTER (WHERE gf > ga)::int                     AS won,
        count(*) FILTER (WHERE gf = ga)::int                     AS drawn,
        count(*) FILTER (WHERE gf < ga)::int                     AS lost,
        COALESCE(sum(gf), 0)::int                                AS "goalsFor",
        COALESCE(sum(ga), 0)::int                                AS "goalsAgainst",
        COALESCE(sum(gf - ga), 0)::int                           AS "goalDifference",
        (count(*) FILTER (WHERE gf > ga) * 3
         + count(*) FILTER (WHERE gf = ga))::int                 AS points,
        count(*) FILTER (WHERE ga = 0)::int                      AS "cleanSheets"
      FROM sides GROUP BY team_id
    )
    SELECT
      t.id AS "teamId", t.name AS "teamName", t.short_name AS "shortName",
      x.played, x.won, x.drawn, x.lost,
      x."goalsFor", x."goalsAgainst", x."goalDifference", x.points, x."cleanSheets",
      ROUND(x.won::numeric * 100 / NULLIF(x.played, 0), 1)::float8       AS "winRate",
      ROUND(x."goalsFor"::numeric / NULLIF(x.played, 0), 2)::float8      AS "goalsPerGame"
    FROM tallied x JOIN teams t ON t.id = x.team_id
    ${kind}
    ORDER BY x.points DESC, x."goalDifference" DESC, t.name ASC
  `);
}

export type PlayerStat = {
  playerId: number;
  playerName: string;
  position: string | null;
  teamId: number | null;
  teamName: string | null;
  goals: number;
  penalties: number;
  /**
   * Null for a player with no record in any season that records assists at all.
   * Assists only exist from 2023/24, so a 0 for someone who played 2017-2020
   * would claim they never assisted when nobody was writing assists down.
   */
  assists: number | null;
  /**
   * Null where the underlying record is too thin to state a number. A zero here
   * would be read as "never happened" when the truth is "never recorded".
   */
  appearances: number | null;
  yellowCards: number | null;
  redCards: number | null;
  goalsPerApp: number | null;
};

/**
 * How much of the scope these numbers actually rest on.
 *
 * The vault's coverage is wildly uneven across eras: scores are complete for
 * every season, but goalscorers exist for only 7 of 19 and lineups for almost
 * none. A leaderboard that silently mixes them reads as an all-time ranking
 * while being a ranking of the seasons that happen to have data. The caller is
 * given the numbers to say so.
 */
export type PlayerStatsCoverage = {
  goalsInScope: number;
  goalsAttributed: number;
  /** 0-1. Below 1, a "career goals" figure is a floor, not a total. */
  goalAttributionRate: number;
  seasonsInScope: number;
  seasonsWithScorers: number;
  /** Assists start later than scorers: 2023/24 onward, where scorers start 2017/18. */
  seasonsWithAssists: number;
  assistsRecorded: number;
  matchesInScope: number;
  matchesWithLineups: number;
  /** False when `appearances` is suppressed to null across the board. */
  appearancesReliable: boolean;
  /** False when `yellowCards` / `redCards` are suppressed to null. */
  cardsReliable: boolean;
};

export type PlayerStatsResult = {
  players: PlayerStat[];
  coverage: PlayerStatsCoverage;
};

/**
 * A metric is reported only when the record behind it covers at least this much
 * of the scope. Below it the numbers describe the gaps in the source rather
 * than anything that happened on a pitch, so they are returned as null.
 */
const RELIABLE_AT = 0.5;

export type PlayerSort = 'goals' | 'assists' | 'appearances' | 'yellowCards' | 'redCards';

/**
 * Player aggregates.
 *
 * OWN_GOAL is excluded from `goals` — an own goal is credited to the opposing
 * team and is never a goal scored by the player (design principle 5).
 *
 * `appearances` come from `match_lineups`, which covers only 607 of 1,639
 * players. Goals-per-appearance is therefore returned as null unless a player
 * has at least as many recorded appearances as goals — otherwise the ratio
 * measures how incomplete the lineup data is, not how prolific the player was.
 */
export async function playerStats(opts: {
  competitionId?: number | undefined;
  editionId?: number | undefined;
  teamId?: number | undefined;
  position?: string | undefined;
  sort?: PlayerSort | undefined;
  limit: number;
}): Promise<PlayerStatsResult> {
  const { competitionId, editionId, teamId, position, sort = 'goals', limit } = opts;

  const editionScope = editionId
    ? Prisma.sql`AND m.competition_edition_id = ${editionId}`
    : Prisma.empty;

  const orderBy = {
    goals: Prisma.sql`goals DESC, appearances ASC`,
    assists: Prisma.sql`assists DESC NULLS LAST, goals DESC`,
    appearances: Prisma.sql`appearances DESC, goals DESC`,
    yellowCards: Prisma.sql`"yellowCards" DESC, goals DESC`,
    redCards: Prisma.sql`"redCards" DESC, "yellowCards" DESC`,
  }[sort];

  const rows = await prisma.$queryRaw<PlayerStat[]>(Prisma.sql`
    WITH assist_editions AS (
      -- Editions where assists were recorded at all. A player who never
      -- features in one of these has an unknown assist count, not zero.
      SELECT DISTINCT m.competition_edition_id AS id
      FROM match_events e
      JOIN matches m ON m.id = e.match_id
      WHERE e.type = 'ASSIST'
    ),
    ev AS (
      SELECT e.player_id, e.team_id, e.type, e.match_id,
             m.competition_edition_id AS edition_id
      FROM match_events e
      JOIN matches m ON m.id = e.match_id
      WHERE m.competition_edition_id IN (${publishedEditionsIn(competitionId)})
        AND e.player_id IS NOT NULL
        ${editionScope}
    ),
    apps AS (
      SELECT l.player_id, count(DISTINCT l.match_id)::int AS appearances
      FROM match_lineups l
      JOIN matches m ON m.id = l.match_id
      WHERE m.competition_edition_id IN (${publishedEditionsIn(competitionId)})
        ${editionScope}
      GROUP BY l.player_id
    ),
    assisted AS (
      -- The schema supports two shapes of assist: a standalone ASSIST row
      -- (a source that does not say which goal it created) and
      -- related_player_id on the goal itself (a source that does). Union them
      -- so neither is missed; a given assist is only ever recorded one way.
      SELECT e.related_player_id AS player_id
      FROM match_events e
      JOIN matches m ON m.id = e.match_id
      WHERE m.competition_edition_id IN (${publishedEditionsIn(competitionId)})
        AND e.related_player_id IS NOT NULL
        AND e.type IN ('GOAL','PENALTY_GOAL')
        ${editionScope}
    ),
    agg AS (
      SELECT
        player_id,
        count(*) FILTER (WHERE type IN ('GOAL','PENALTY_GOAL'))::int AS goals,
        count(*) FILTER (WHERE type = 'PENALTY_GOAL')::int           AS penalties,
        count(*) FILTER (WHERE type = 'ASSIST')::int                  AS assists,
        bool_or(edition_id IN (SELECT id FROM assist_editions))       AS "assistsKnown",
        count(*) FILTER (WHERE type = 'YELLOW_CARD')::int            AS "yellowCards",
        count(*) FILTER (WHERE type = 'RED_CARD')::int               AS "redCards",
        mode() WITHIN GROUP (ORDER BY team_id)                       AS team_id
      FROM ev GROUP BY player_id
    )
    SELECT
      p.id AS "playerId", p.full_name AS "playerName", p."position",
      t.id AS "teamId", t.name AS "teamName",
      COALESCE(a.goals, 0) AS goals,
      COALESCE(a.penalties, 0) AS penalties,
      CASE WHEN COALESCE(a."assistsKnown", FALSE) OR COALESCE(la.n, 0) > 0
           THEN COALESCE(a.assists, 0) + COALESCE(la.n, 0)
           ELSE NULL END AS assists,
      COALESCE(ap.appearances, 0) AS appearances,
      COALESCE(a."yellowCards", 0) AS "yellowCards",
      COALESCE(a."redCards", 0) AS "redCards",
      -- Only meaningful when the appearance data is plausibly complete for
      -- this player. Lineups cover ~600 of 1,639 players, so a scorer with 23
      -- goals and 5 recorded appearances would otherwise read as "4.6 goals per
      -- game" — a fabricated-looking number born of missing data, not form.
      CASE WHEN COALESCE(ap.appearances, 0) >= GREATEST(COALESCE(a.goals, 0), 1)
           THEN ROUND(COALESCE(a.goals,0)::numeric / ap.appearances, 2)::float8
           ELSE NULL END AS "goalsPerApp"
    FROM players p
    LEFT JOIN agg a  ON a.player_id = p.id
    LEFT JOIN apps ap ON ap.player_id = p.id
    LEFT JOIN (SELECT player_id, count(*)::int AS n FROM assisted GROUP BY player_id) la
           ON la.player_id = p.id
    LEFT JOIN teams t ON t.id = a.team_id
    WHERE (COALESCE(a.goals,0) > 0 OR COALESCE(ap.appearances,0) > 0
           OR COALESCE(a.assists,0) > 0 OR COALESCE(la.n,0) > 0
           OR COALESCE(a."yellowCards",0) > 0 OR COALESCE(a."redCards",0) > 0)
      ${teamId ? Prisma.sql`AND t.id = ${teamId}` : Prisma.empty}
      ${position ? Prisma.sql`AND p."position" = ${position}` : Prisma.empty}
    ORDER BY ${orderBy}, p.full_name ASC
    LIMIT ${limit}
  `);

  const [cov] = await prisma.$queryRaw<Array<{
    goalsInScope: number;
    goalsAttributed: number;
    seasonsInScope: number;
    seasonsWithScorers: number;
    seasonsWithAssists: number;
    assistsRecorded: number;
    matchesInScope: number;
    matchesWithLineups: number;
  }>>(Prisma.sql`
    WITH scope AS (
      SELECT m.id, m.competition_edition_id,
             coalesce(m.home_score,0) + coalesce(m.away_score,0) AS goals
      FROM matches m
      WHERE m.competition_edition_id IN (${publishedEditionsIn(competitionId)})
        AND m.home_score IS NOT NULL
        ${editionScope}
    )
    SELECT
      COALESCE(sum(s.goals), 0)::int AS "goalsInScope",
      (SELECT count(*) FROM match_events e
        WHERE e.match_id IN (SELECT id FROM scope)
          AND e.type IN ('GOAL','PENALTY_GOAL') AND e.player_id IS NOT NULL)::int
        AS "goalsAttributed",
      count(DISTINCT s.competition_edition_id)::int AS "seasonsInScope",
      (SELECT count(DISTINCT e.competition_edition_id) FROM (
          SELECT s2.competition_edition_id
          FROM scope s2 JOIN match_events me ON me.match_id = s2.id
          WHERE me.type IN ('GOAL','PENALTY_GOAL') AND me.player_id IS NOT NULL
       ) e)::int AS "seasonsWithScorers",
      (SELECT count(DISTINCT e.competition_edition_id) FROM (
          SELECT s3.competition_edition_id
          FROM scope s3 JOIN match_events me ON me.match_id = s3.id
          WHERE me.type = 'ASSIST'
       ) e)::int AS "seasonsWithAssists",
      (SELECT count(*) FROM match_events e
        WHERE e.match_id IN (SELECT id FROM scope) AND e.type = 'ASSIST')::int
        AS "assistsRecorded",
      count(*)::int AS "matchesInScope",
      (SELECT count(DISTINCT l.match_id) FROM match_lineups l
        WHERE l.match_id IN (SELECT id FROM scope))::int AS "matchesWithLineups"
    FROM scope s
  `);

  const goalsInScope = cov?.goalsInScope ?? 0;
  const matchesInScope = cov?.matchesInScope ?? 0;
  const appearanceRate = matchesInScope ? (cov?.matchesWithLineups ?? 0) / matchesInScope : 0;

  // Cards ride on the same record as appearances -- a card is only known if
  // someone logged the match in detail -- so they are gated together.
  const appearancesReliable = appearanceRate >= RELIABLE_AT;
  const cardsReliable = appearancesReliable;

  const coverage: PlayerStatsCoverage = {
    goalsInScope,
    goalsAttributed: cov?.goalsAttributed ?? 0,
    goalAttributionRate: goalsInScope ? (cov?.goalsAttributed ?? 0) / goalsInScope : 0,
    seasonsInScope: cov?.seasonsInScope ?? 0,
    seasonsWithScorers: cov?.seasonsWithScorers ?? 0,
    seasonsWithAssists: cov?.seasonsWithAssists ?? 0,
    assistsRecorded: cov?.assistsRecorded ?? 0,
    matchesInScope,
    matchesWithLineups: cov?.matchesWithLineups ?? 0,
    appearancesReliable,
    cardsReliable,
  };

  return {
    players: rows.map((r) => ({
      ...r,
      appearances: appearancesReliable ? r.appearances : null,
      yellowCards: cardsReliable ? r.yellowCards : null,
      redCards: cardsReliable ? r.redCards : null,
    })),
    coverage,
  };
}

export type HeadToHead = {
  teamA: { id: number; name: string };
  teamB: { id: number; name: string };
  meetings: number;
  aWins: number;
  bWins: number;
  draws: number;
  aGoals: number;
  bGoals: number;
  matches: {
    id: number;
    kickoffAt: Date | null;
    competition: string;
    season: string;
    homeTeamId: number;
    homeTeam: string;
    awayTeam: string;
    homeScore: number | null;
    awayScore: number | null;
  }[];
};

/** Every published meeting between two clubs, with the running record. */
export async function headToHead(
  teamAId: number,
  teamBId: number,
  scopeIn: StatsScope = {},
): Promise<HeadToHead | null> {
  const { competitionId } = scopeIn;
  const [a, b] = await Promise.all([
    prisma.teams.findUnique({ where: { id: teamAId }, select: { id: true, name: true } }),
    prisma.teams.findUnique({ where: { id: teamBId }, select: { id: true, name: true } }),
  ]);
  if (!a || !b) return null;

  const matches = await prisma.$queryRaw<HeadToHead['matches']>(Prisma.sql`
    SELECT m.id, m.kickoff_at AS "kickoffAt",
           c.name AS competition, s.label AS season,
           m.home_team_id AS "homeTeamId",
           th.name AS "homeTeam", ta.name AS "awayTeam",
           m.home_score AS "homeScore", m.away_score AS "awayScore"
    FROM matches m
    JOIN competition_editions ce ON ce.id = m.competition_edition_id
    JOIN competitions c ON c.id = ce.competition_id
    JOIN seasons s ON s.id = ce.season_id
    JOIN teams th ON th.id = m.home_team_id
    JOIN teams ta ON ta.id = m.away_team_id
    WHERE ce.is_published = TRUE
      AND m.home_score IS NOT NULL AND m.away_score IS NOT NULL
      AND ((m.home_team_id = ${teamAId} AND m.away_team_id = ${teamBId})
        OR (m.home_team_id = ${teamBId} AND m.away_team_id = ${teamAId}))
    ORDER BY m.kickoff_at DESC NULLS LAST
  `);

  let aWins = 0;
  let bWins = 0;
  let draws = 0;
  let aGoals = 0;
  let bGoals = 0;
  for (const m of matches) {
    const aIsHome = m.homeTeamId === teamAId;
    const forA = (aIsHome ? m.homeScore : m.awayScore) ?? 0;
    const forB = (aIsHome ? m.awayScore : m.homeScore) ?? 0;
    aGoals += forA;
    bGoals += forB;
    if (forA > forB) aWins += 1;
    else if (forB > forA) bWins += 1;
    else draws += 1;
  }

  return {
    teamA: a,
    teamB: b,
    meetings: matches.length,
    aWins,
    bWins,
    draws,
    aGoals,
    bGoals,
    matches,
  };
}

/** Headline numbers for the stats landing page. */
export async function overview(scopeIn: StatsScope = {}) {
  const { competitionId } = scopeIn;
  const [totals] = await prisma.$queryRaw<
    { matches: number; goals: number; clubs: number; players: number; seasons: number; competitions: number }[]
  >(Prisma.sql`
    SELECT
      (SELECT count(*) FROM matches m
        WHERE m.competition_edition_id IN (${publishedEditionsIn(competitionId)})
          AND m.home_score IS NOT NULL)::int AS matches,
      (SELECT COALESCE(sum(m.home_score + m.away_score), 0) FROM matches m
        WHERE m.competition_edition_id IN (${publishedEditionsIn(competitionId)})
          AND m.home_score IS NOT NULL)::int AS goals,
      (SELECT count(DISTINCT t.id) FROM teams t
        WHERE t.id IN (
          SELECT home_team_id FROM matches WHERE competition_edition_id IN (${publishedEditionsIn(competitionId)})
          UNION SELECT away_team_id FROM matches WHERE competition_edition_id IN (${publishedEditionsIn(competitionId)})
        ))::int AS clubs,
      (SELECT count(DISTINCT e.player_id) FROM match_events e
        JOIN matches m ON m.id = e.match_id
        WHERE m.competition_edition_id IN (${publishedEditionsIn(competitionId)})
          AND e.player_id IS NOT NULL)::int AS players,
      (SELECT count(DISTINCT ce.season_id) FROM competition_editions ce WHERE ce.is_published)::int AS seasons,
      (SELECT count(DISTINCT ce.competition_id) FROM competition_editions ce WHERE ce.is_published)::int AS competitions
  `);

  return totals ?? { matches: 0, goals: 0, clubs: 0, players: 0, seasons: 0, competitions: 0 };
}

/** Clubs that appear in any published edition — for pickers and club pages. */
export async function publishedTeams(teamType?: TeamType, scopeIn: StatsScope = {}) {
  const { competitionId } = scopeIn;
  const kind = teamType ? Prisma.sql`AND t.type = ${teamType}` : Prisma.empty;
  return prisma.$queryRaw<{
    id: number; name: string; shortName: string | null; country: string | null; type: string;
  }[]>(
    Prisma.sql`
      SELECT DISTINCT t.id, t.name, t.short_name AS "shortName", co.name AS country, t.type
      FROM teams t
      LEFT JOIN countries co ON co.id = t.country_id
      WHERE t.id IN (
        SELECT home_team_id FROM matches WHERE competition_edition_id IN (${publishedEditionsIn(competitionId)})
        UNION SELECT away_team_id FROM matches WHERE competition_edition_id IN (${publishedEditionsIn(competitionId)})
      )
      ${kind}
      ORDER BY t.name
    `,
  );
}
