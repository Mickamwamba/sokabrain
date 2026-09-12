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
/** One group's mini-table, for a tournament played in groups. */
export type GroupTable = {
  groupId: number;
  name: string;
  standings: StandingsRow[];
};

/** A knockout tie, as it should be read: the shootout decides a level game. */
export type KnockoutMatch = {
  matchId: number;
  kickoffAt: Date | null;
  status: string;
  homeTeamId: number;
  homeTeamName: string;
  awayTeamId: number;
  awayTeamName: string;
  homeScore: number | null;
  awayScore: number | null;
  homeScoreEt: number | null;
  awayScoreEt: number | null;
  homeScorePens: number | null;
  awayScorePens: number | null;
  /** Team that advanced, or null while the tie is undecided. */
  winnerTeamId: number | null;
};

export type KnockoutRound = {
  round: string;
  matches: KnockoutMatch[];
};

export type StandingsResult = {
  standings: StandingsRow[];
  /**
   * Why a table may not be what it looks like. Two different problems live
   * here, and they need telling apart:
   *
   *  - `matchesMissingScore`: the fixture exists but has no result, so it is
   *    left out of the tally.
   *  - `missingFixtures`: the fixture is not in the vault at all. Counting
   *    scores cannot detect this — TPL 2020/21 reports zero missing scores
   *    while 43 of its fixtures are simply absent from every source, leaving
   *    two clubs on 10 games and the rest on 36.
   *
   * `isProvisional` is the single flag a caller should branch on: true means
   * the table is built on an incomplete fixture list and must not be presented
   * as a final league table.
   */
  coverage: {
    matchesFullTime: number;
    matchesCounted: number;
    matchesMissingScore: number;
    fixturesPresent: number;
    fixturesExpected: number | null;
    missingFixtures: number;
    minPlayed: number;
    maxPlayed: number;
    isProvisional: boolean;
  };
  /**
   * One mini-table per group, for a tournament played in groups. Empty for a
   * league, which has no `competition_groups` rows.
   *
   * A tournament's overall `standings` is a summary, not a table -- AFCON 2019
   * put Algeria top on 19 points from seven matches while a team eliminated in
   * the group had three. The group tables are the part that IS a table, so
   * they are computed separately over each group's own matches.
   */
  groups: GroupTable[];
  /**
   * The knockout rounds, in the order they are played. Empty for a league.
   * These are ties, not table rows: they are returned as matches so the caller
   * can render a bracket rather than trying to rank them.
   */
  knockout: KnockoutRound[];
};

/** Bracket order, so rounds sort by stage rather than alphabetically. */
const ROUND_ORDER = [
  'ROUND OF 16', 'QUARTER FINAL', 'SEMI FINAL', 'THIRD PLACE', 'FINAL',
];

function roundRank(round: string): number {
  const i = ROUND_ORDER.indexOf(round.toUpperCase());
  // An unrecognised round sorts before the known ones rather than being
  // dropped: a competition we have not seen the shape of still has to render.
  return i === -1 ? -1 : i;
}

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

  const [raw] = await prisma.$queryRaw<Array<{
    matchesFullTime: number;
    matchesCounted: number;
    matchesMissingScore: number;
    fixturesPresent: number;
    numTeams: number | null;
    isRoundRobin: boolean | null;
  }>>(Prisma.sql`
    SELECT
      count(*) FILTER (WHERE m.status = 'FULL_TIME')::int AS "matchesFullTime",
      count(*) FILTER (
        WHERE m.status = 'FULL_TIME' AND m.home_score IS NOT NULL AND m.away_score IS NOT NULL
      )::int AS "matchesCounted",
      count(*) FILTER (
        WHERE m.status = 'FULL_TIME' AND (m.home_score IS NULL OR m.away_score IS NULL)
      )::int AS "matchesMissingScore",
      count(*)::int AS "fixturesPresent",
      max(ce.num_teams)::int AS "numTeams",
      bool_or(c.type = 'LEAGUE') AS "isRoundRobin"
    FROM matches m
    JOIN competition_editions ce ON ce.id = m.competition_edition_id
    JOIN competitions c ON c.id = ce.competition_id
    WHERE m.competition_edition_id = ${editionId}
  `);

  // A league has neither groups nor a knockout, and must be asked about
  // neither: its rounds are numbered and carry no group_id, so the knockout
  // query would otherwise read every league fixture as a knockout tie and
  // render a "Knockout stage" containing the whole season.
  const isLeague = await prisma.competition_editions
    .findFirst({
      where: { id: editionId },
      select: { competitions: { select: { type: true } } },
    })
    .then((e) => e?.competitions.type === 'LEAGUE');

  const [groups, knockout] = isLeague
    ? [[], []]
    : await Promise.all([groupTables(editionId), knockoutRounds(editionId)]);

  const played = rows.map((r) => r.played);
  // n*(n-1) is the fixture count a complete season implies -- but only for a
  // double round robin, where every team plays every other twice. It says
  // nothing about a cup: AFCON 2019 has all 52 of its fixtures, yet 24 teams
  // would imply 552 and the page would claim 500 were missing. So this is only
  // computed for a LEAGUE. Editions with no recorded team count cannot be
  // judged this way either, and neither kind is called provisional on this
  // basis alone.
  const fixturesExpected =
    raw?.isRoundRobin && raw.numTeams && raw.numTeams > 1
      ? raw.numTeams * (raw.numTeams - 1)
      : null;
  const missingFixtures =
    fixturesExpected === null ? 0 : Math.max(0, fixturesExpected - (raw?.fixturesPresent ?? 0));

  return {
    standings: rows.map((row, i) => ({ position: i + 1, ...row })),
    coverage: {
      matchesFullTime: raw?.matchesFullTime ?? 0,
      matchesCounted: raw?.matchesCounted ?? 0,
      matchesMissingScore: raw?.matchesMissingScore ?? 0,
      fixturesPresent: raw?.fixturesPresent ?? 0,
      fixturesExpected,
      missingFixtures,
      minPlayed: played.length ? Math.min(...played) : 0,
      maxPlayed: played.length ? Math.max(...played) : 0,
      // An unfinished season in progress is not provisional in this sense --
      // it is simply not over. What makes a table untrustworthy is clubs having
      // played materially different numbers of games, which is what a hole in
      // the fixture list produces.
      isProvisional:
        missingFixtures > 0 &&
        played.length > 0 &&
        Math.max(...played) - Math.min(...played) > 2,
    },
    groups,
    knockout,
  };
}

/**
 * A mini-table per group, tallied over that group's own matches only.
 *
 * Same points and tiebreak chain as the main table. Knockout matches carry no
 * `group_id`, so they cannot leak in and inflate a group row -- which is the
 * whole reason a tournament needs this rather than one combined table.
 */
async function groupTables(editionId: number): Promise<GroupTable[]> {
  const rows = await prisma.$queryRaw<Array<Omit<StandingsRow, 'position'> & {
    groupId: number; groupName: string;
  }>>(Prisma.sql`
    WITH sides AS (
      SELECT m.group_id, m.home_team_id AS team_id, m.home_score AS gf, m.away_score AS ga
      FROM matches m
      WHERE m.competition_edition_id = ${editionId}
        AND m.group_id IS NOT NULL
        AND m.status = 'FULL_TIME'
        AND m.home_score IS NOT NULL AND m.away_score IS NOT NULL
      UNION ALL
      SELECT m.group_id, m.away_team_id, m.away_score, m.home_score
      FROM matches m
      WHERE m.competition_edition_id = ${editionId}
        AND m.group_id IS NOT NULL
        AND m.status = 'FULL_TIME'
        AND m.home_score IS NOT NULL AND m.away_score IS NOT NULL
    ),
    tallied AS (
      SELECT
        group_id, team_id,
        count(*)::int                            AS played,
        count(*) FILTER (WHERE gf > ga)::int     AS won,
        count(*) FILTER (WHERE gf = ga)::int     AS drawn,
        count(*) FILTER (WHERE gf < ga)::int     AS lost,
        COALESCE(sum(gf), 0)::int                AS "goalsFor",
        COALESCE(sum(ga), 0)::int                AS "goalsAgainst",
        COALESCE(sum(gf - ga), 0)::int           AS "goalDifference",
        (count(*) FILTER (WHERE gf > ga) * 3
         + count(*) FILTER (WHERE gf = ga))::int AS points
      FROM sides GROUP BY group_id, team_id
    )
    SELECT
      g.id AS "groupId", g.name AS "groupName",
      t.id AS "teamId", t.name AS "teamName",
      t.short_name AS "shortName", t.logo_url AS "logoUrl",
      x.played, x.won, x.drawn, x.lost,
      x."goalsFor", x."goalsAgainst", x."goalDifference", x.points
    FROM tallied x
    JOIN teams t ON t.id = x.team_id
    JOIN competition_groups g ON g.id = x.group_id
    ORDER BY g.name ASC, x.points DESC, x."goalDifference" DESC, x."goalsFor" DESC, t.name ASC
  `);

  const out: GroupTable[] = [];
  for (const r of rows) {
    const { groupId, groupName, ...row } = r;
    let group = out.find((g) => g.groupId === groupId);
    if (!group) {
      group = { groupId, name: groupName, standings: [] };
      out.push(group);
    }
    group.standings.push({ position: group.standings.length + 1, ...row });
  }
  return out;
}

/**
 * The knockout ties, grouped by round and ordered by stage.
 *
 * `winnerTeamId` is resolved here rather than left to the caller, because
 * getting it right means knowing that a shootout settles a level tie and that
 * the stored score is already after extra time.
 */
async function knockoutRounds(editionId: number): Promise<KnockoutRound[]> {
  const rows = await prisma.$queryRaw<Array<Omit<KnockoutMatch, 'winnerTeamId'> & {
    round: string;
  }>>(Prisma.sql`
    SELECT
      m.round,
      m.id AS "matchId", m.kickoff_at AS "kickoffAt", m.status,
      h.id AS "homeTeamId", h.name AS "homeTeamName",
      a.id AS "awayTeamId", a.name AS "awayTeamName",
      m.home_score AS "homeScore", m.away_score AS "awayScore",
      m.home_score_et AS "homeScoreEt", m.away_score_et AS "awayScoreEt",
      m.home_score_pens AS "homeScorePens", m.away_score_pens AS "awayScorePens"
    FROM matches m
    JOIN teams h ON h.id = m.home_team_id
    JOIN teams a ON a.id = m.away_team_id
    WHERE m.competition_edition_id = ${editionId}
      AND m.group_id IS NULL
      AND m.round IS NOT NULL
      AND upper(m.round) <> 'GROUP'
    ORDER BY m.kickoff_at ASC, m.id ASC
  `);

  const byRound = new Map<string, KnockoutMatch[]>();
  for (const r of rows) {
    const { round, ...m } = r;
    // The result score is after extra time where it was played; a level tie is
    // then settled on penalties, never on the goal total.
    const h = m.homeScoreEt ?? m.homeScore;
    const a = m.awayScoreEt ?? m.awayScore;
    let winnerTeamId: number | null = null;
    if (h !== null && a !== null) {
      if (h !== a) winnerTeamId = h > a ? m.homeTeamId : m.awayTeamId;
      else if (m.homeScorePens !== null && m.awayScorePens !== null
               && m.homeScorePens !== m.awayScorePens) {
        winnerTeamId = m.homeScorePens > m.awayScorePens ? m.homeTeamId : m.awayTeamId;
      }
    }
    const list = byRound.get(round) ?? [];
    list.push({ ...m, winnerTeamId });
    byRound.set(round, list);
  }

  return [...byRound.entries()]
    .map(([round, matches]) => ({ round, matches }))
    .sort((x, y) => roundRank(x.round) - roundRank(y.round));
}
