import { Prisma } from '@prisma/client';
import { prisma } from '../db.js';
import { playerStats, type PlayerStatsResult } from './stats.js';

/**
 * Everything one team's page needs, across every published competition.
 *
 * A team page is all-time by nature — a club is not a season — so unlike the
 * stats pages this takes no scope. The breakdown by competition and by season
 * is what carries the detail instead, and it keeps the league and the
 * continental record apart rather than summing them into one meaningless
 * total (the same reason `/table` refuses to rank a cup as one table).
 *
 * Nothing here reads the event log to establish a result: the stored score is
 * canonical (design principle 3), and the event log is too thin across the
 * early seasons to count absences from.
 */

/** Reused everywhere public: the editions the public is allowed to see. */
const PUBLISHED = Prisma.sql`SELECT id FROM competition_editions WHERE is_published = TRUE`;

export type TeamRecord = {
  played: number;
  won: number;
  drawn: number;
  lost: number;
  goalsFor: number;
  goalsAgainst: number;
  goalDifference: number;
  points: number;
  cleanSheets: number;
  /** Matches in which the team failed to score. */
  blanks: number;
  winRate: number;
  goalsPerGame: number;
};

export type TeamSeason = TeamRecord & {
  editionId: number;
  season: string;
  competitionId: number;
  competition: string;
  competitionType: string;
  /**
   * Where the team finished, for a LEAGUE only. A cup's combined ranking sums
   * group and knockout results into an order nobody plays for, so it is null
   * there and `furthestRound` says what actually happened instead.
   */
  position: number | null;
  /** How many teams that ranking is out of. Null for the same reason. */
  teamsInEdition: number | null;
  /** "FINAL", "SEMI FINAL" … for a tournament; null for a league. */
  furthestRound: string | null;
  /**
   * False while the edition still has fixtures to play. A position in an
   * unfinished season is where the team sits, not where it finished.
   */
  finished: boolean;
  /**
   * False when fixtures are absent from every source and teams have played
   * materially different numbers of games — the same test as `/table`'s
   * `isProvisional`. Distinct from `finished`: TPL 2020/21 is over, but its
   * table cannot be trusted to say who won it.
   */
  settled: boolean;
  /**
   * Won the competition that season: top of a finished, complete league, or
   * the winner of a tournament final. Null when it cannot be said — a league
   * season still in progress, or one with fixtures missing from every source
   * (TPL 2020/21), which `/table` likewise refuses to name a champion for.
   */
  champion: boolean | null;
};

export type TeamCompetitionRecord = TeamRecord & {
  competitionId: number;
  competition: string;
  competitionType: string;
  seasons: number;
  firstSeason: string;
  lastSeason: string;
  /**
   * Seasons won: finished-and-complete leagues topped, or finals won. Only
   * seasons where `champion` is known count, so it is never inflated by a
   * season in progress.
   */
  titles: number;
};

export type TeamFormMatch = {
  matchId: number;
  kickoffAt: Date | null;
  competition: string;
  season: string;
  home: boolean;
  opponentId: number;
  opponent: string;
  goalsFor: number;
  goalsAgainst: number;
  result: 'W' | 'D' | 'L';
};

export type TeamProfile = {
  team: {
    id: number;
    name: string;
    shortName: string | null;
    type: string;
    country: string | null;
    logoUrl: string | null;
    stadium: { name: string; city: string | null; capacity: number | null } | null;
  };
  record: TeamRecord;
  competitions: TeamCompetitionRecord[];
  seasons: TeamSeason[];
  /** Most recent first — the fan's "last six". */
  form: TeamFormMatch[];
  biggestWin: TeamFormMatch | null;
  heaviestDefeat: TeamFormMatch | null;
  players: PlayerStatsResult;
  /** What the squad list rests on, so the page can say when it is thin. */
  coverage: {
    /** 0-1 across this team's matches. Below 1 a goal total is a floor. */
    goalAttributionRate: number;
    goalsScored: number;
    goalsAttributed: number;
    seasonsWithScorers: number;
    seasonsPlayed: number;
  };
};

/** Empty rather than zeroed-out: a team with no played match has no record. */
const EMPTY_RECORD: TeamRecord = {
  played: 0, won: 0, drawn: 0, lost: 0, goalsFor: 0, goalsAgainst: 0,
  goalDifference: 0, points: 0, cleanSheets: 0, blanks: 0,
  winRate: 0, goalsPerGame: 0,
};

/**
 * Every played match this team appears in, as one row per team per edition,
 * ranked within its edition.
 *
 * The ranking is computed over *all* teams in the edition, not just this one,
 * which is why the query tallies the whole edition before filtering — a
 * position means nothing without the field it was won against.
 */
async function seasonRows(teamId: number): Promise<TeamSeason[]> {
  type Row = Omit<TeamSeason, 'furthestRound' | 'champion'>;

  const rows = await prisma.$queryRaw<Row[]>(Prisma.sql`
    WITH sides AS (
      SELECT m.competition_edition_id AS edition_id, m.home_team_id AS team_id,
             m.home_score AS gf, m.away_score AS ga
        FROM matches m
       WHERE m.competition_edition_id IN (${PUBLISHED})
         AND m.status = 'FULL_TIME'
         AND m.home_score IS NOT NULL AND m.away_score IS NOT NULL
      UNION ALL
      SELECT m.competition_edition_id, m.away_team_id, m.away_score, m.home_score
        FROM matches m
       WHERE m.competition_edition_id IN (${PUBLISHED})
         AND m.status = 'FULL_TIME'
         AND m.home_score IS NOT NULL AND m.away_score IS NOT NULL
    ),
    mine AS (
      SELECT DISTINCT edition_id FROM sides WHERE team_id = ${teamId}
    ),
    tallied AS (
      SELECT
        s.edition_id,
        s.team_id,
        count(*)::int                                        AS played,
        count(*) FILTER (WHERE s.gf > s.ga)::int             AS won,
        count(*) FILTER (WHERE s.gf = s.ga)::int             AS drawn,
        count(*) FILTER (WHERE s.gf < s.ga)::int             AS lost,
        COALESCE(sum(s.gf), 0)::int                          AS "goalsFor",
        COALESCE(sum(s.ga), 0)::int                          AS "goalsAgainst",
        COALESCE(sum(s.gf - s.ga), 0)::int                   AS "goalDifference",
        (count(*) FILTER (WHERE s.gf > s.ga) * 3
         + count(*) FILTER (WHERE s.gf = s.ga))::int         AS points,
        count(*) FILTER (WHERE s.ga = 0)::int                AS "cleanSheets",
        count(*) FILTER (WHERE s.gf = 0)::int                AS blanks
        FROM sides s
        JOIN mine ON mine.edition_id = s.edition_id
       GROUP BY s.edition_id, s.team_id
    ),
    ranked AS (
      SELECT t.*,
             rank() OVER (
               PARTITION BY t.edition_id
               ORDER BY t.points DESC, t."goalDifference" DESC, t."goalsFor" DESC
             )::int AS position,
             count(*) OVER (PARTITION BY t.edition_id)::int AS "teamsInEdition",
             max(t.played) OVER (PARTITION BY t.edition_id)
               - min(t.played) OVER (PARTITION BY t.edition_id) AS spread
        FROM tallied t
    ),
    -- Whether each edition can have a champion named. Mirrors the rule in
    -- standings.ts: a table is provisional when fixtures are absent from the
    -- vault AND teams have played materially different numbers of games. Keep
    -- the two in step, or the team page and /table will disagree about who won.
    edition_facts AS (
      SELECT m.competition_edition_id AS edition_id,
             count(*)::int AS fixtures_present,
             count(*) FILTER (
               WHERE m.status IN ('SCHEDULED', 'LIVE', 'POSTPONED')
             )::int AS remaining,
             max(ce.num_teams)::int AS num_teams
        FROM matches m
        JOIN competition_editions ce ON ce.id = m.competition_edition_id
        JOIN mine ON mine.edition_id = m.competition_edition_id
       GROUP BY m.competition_edition_id
    )
    SELECT
      r.edition_id AS "editionId",
      se.label     AS season,
      c.id         AS "competitionId",
      c.name       AS competition,
      c.type       AS "competitionType",
      r.played, r.won, r.drawn, r.lost,
      r."goalsFor", r."goalsAgainst", r."goalDifference", r.points,
      r."cleanSheets", r.blanks,
      -- A cup's combined ranking is not a standing; the caller nulls it out.
      CASE WHEN c.type = 'LEAGUE' THEN r.position       END AS position,
      CASE WHEN c.type = 'LEAGUE' THEN r."teamsInEdition" END AS "teamsInEdition",
      (f.remaining = 0) AS finished,
      NOT (
        COALESCE(f.num_teams * (f.num_teams - 1) - f.fixtures_present, 0) > 0
        AND r.spread > 2
      ) AS settled,
      ROUND(r.won::numeric * 100 / NULLIF(r.played, 0), 1)::float8  AS "winRate",
      ROUND(r."goalsFor"::numeric / NULLIF(r.played, 0), 2)::float8 AS "goalsPerGame"
      FROM ranked r
      JOIN competition_editions ce ON ce.id = r.edition_id
      JOIN seasons se              ON se.id = ce.season_id
      JOIN competitions c          ON c.id  = ce.competition_id
      JOIN edition_facts f         ON f.edition_id = r.edition_id
     WHERE r.team_id = ${teamId}
     ORDER BY se.label DESC
  `);

  const knockouts = await knockoutRuns(teamId);
  return rows.map((r) => {
    const run = knockouts.get(r.editionId);
    const champion =
      r.competitionType === 'LEAGUE'
        ? r.finished && r.settled ? r.position === 1 : null
        // A tournament is won in its final, so the final's result is the whole
        // answer — no table, and no need to wait for anything else to finish.
        : run?.wonFinal ?? (r.finished ? false : null);
    return { ...r, furthestRound: run?.round ?? null, champion };
  });
}

/**
 * How far the team got in each tournament it played, and whether it won.
 *
 * Only knockout labels count. A league's `round` column holds a number, and a
 * group stage is where everyone starts, so neither answers "how did they do?".
 */
const ROUND_ORDER = ['ROUND OF 16', 'QUARTER FINAL', 'SEMI FINAL', 'THIRD PLACE', 'FINAL'];

type KnockoutRun = { round: string; wonFinal: boolean | null };

/**
 * Who won a knockout tie, from the stored scores.
 *
 * Penalties decide it if there were any, then extra time, then the ninety
 * minutes. Extra time is compared only against itself: WhoScored's ET figure
 * zeroes the loser rather than giving the after-extra-time score (see
 * docs/ingestion/AFCON.md), so it says who won the period but cannot be
 * added to or compared with the regular score. Checked against all 13 AFCON
 * finals in the vault, including 2025's 1-0 decided in extra time.
 */
function homeWon(m: {
  hs: number | null; as: number | null;
  het: number | null; aet: number | null;
  hp: number | null; ap: number | null;
}): boolean | null {
  if (m.hp !== null && m.ap !== null && m.hp !== m.ap) return m.hp > m.ap;
  if (m.het !== null && m.aet !== null && m.het !== m.aet) return m.het > m.aet;
  if (m.hs !== null && m.as !== null && m.hs !== m.as) return m.hs > m.as;
  return null;
}

async function knockoutRuns(teamId: number): Promise<Map<number, KnockoutRun>> {
  const rows = await prisma.$queryRaw<{
    editionId: number; round: string; status: string; home: boolean;
    hs: number | null; as: number | null;
    het: number | null; aet: number | null;
    hp: number | null; ap: number | null;
  }[]>(Prisma.sql`
    SELECT m.competition_edition_id AS "editionId", m.round, m.status,
           (m.home_team_id = ${teamId}) AS home,
           m.home_score AS hs, m.away_score AS as,
           m.home_score_et AS het, m.away_score_et AS aet,
           m.home_score_pens AS hp, m.away_score_pens AS ap
      FROM matches m
     WHERE m.competition_edition_id IN (${PUBLISHED})
       AND (m.home_team_id = ${teamId} OR m.away_team_id = ${teamId})
       AND m.round = ANY(${ROUND_ORDER})
  `);

  const runs = new Map<number, KnockoutRun>();
  for (const r of rows) {
    const seen = runs.get(r.editionId);
    if (seen && ROUND_ORDER.indexOf(r.round) <= ROUND_ORDER.indexOf(seen.round)) continue;

    let wonFinal: boolean | null = null;
    if (r.round === 'FINAL' && r.status === 'FULL_TIME') {
      const h = homeWon(r);
      wonFinal = h === null ? null : h === r.home;
    }
    runs.set(r.editionId, { round: r.round, wonFinal });
  }
  return runs;
}

/** Played matches, newest first, as seen from this team's side. */
async function teamMatches(teamId: number, limit: number, order: 'recent' | 'best' | 'worst') {
  // These order the *subquery's* output, so they name its aliases — the
  // underlying columns are out of scope by the time this is applied.
  const sort =
    order === 'recent'
      ? Prisma.sql`ORDER BY "kickoffAt" DESC NULLS LAST, "matchId" DESC`
      : order === 'best'
        ? Prisma.sql`ORDER BY (gf - ga) DESC, gf DESC, "kickoffAt" DESC NULLS LAST`
        : Prisma.sql`ORDER BY (gf - ga) ASC, ga DESC, "kickoffAt" DESC NULLS LAST`;

  return prisma.$queryRaw<TeamFormMatch[]>(Prisma.sql`
    SELECT * FROM (
      SELECT
        m.id AS "matchId",
        m.kickoff_at AS "kickoffAt",
        c.name  AS competition,
        se.label AS season,
        (m.home_team_id = ${teamId}) AS home,
        CASE WHEN m.home_team_id = ${teamId} THEN m.away_team_id ELSE m.home_team_id END AS "opponentId",
        CASE WHEN m.home_team_id = ${teamId} THEN away.name ELSE home.name END AS opponent,
        CASE WHEN m.home_team_id = ${teamId} THEN m.home_score ELSE m.away_score END AS gf,
        CASE WHEN m.home_team_id = ${teamId} THEN m.away_score ELSE m.home_score END AS ga
        FROM matches m
        JOIN competition_editions ce ON ce.id = m.competition_edition_id
        JOIN seasons se              ON se.id = ce.season_id
        JOIN competitions c          ON c.id  = ce.competition_id
        JOIN teams home              ON home.id = m.home_team_id
        JOIN teams away              ON away.id = m.away_team_id
       WHERE m.competition_edition_id IN (${PUBLISHED})
         AND m.status = 'FULL_TIME'
         AND m.home_score IS NOT NULL AND m.away_score IS NOT NULL
         AND (m.home_team_id = ${teamId} OR m.away_team_id = ${teamId})
    ) m
    ${sort}
    LIMIT ${limit}
  `).then((rows) =>
    rows.map((r) => {
      const { gf, ga } = r as unknown as { gf: number; ga: number };
      return {
        matchId: r.matchId,
        kickoffAt: r.kickoffAt,
        competition: r.competition,
        season: r.season,
        home: r.home,
        opponentId: r.opponentId,
        opponent: r.opponent,
        goalsFor: gf,
        goalsAgainst: ga,
        result: (gf > ga ? 'W' : gf === ga ? 'D' : 'L') as 'W' | 'D' | 'L',
      };
    }),
  );
}

/**
 * How many of this team's goals have a named scorer.
 *
 * Stated because it is dire for the early seasons — 36% across the league as a
 * whole — and a squad list built on the other 64% would read as a complete
 * record of who scored for this club. It is not.
 */
async function scorerCoverage(teamId: number) {
  const [row] = await prisma.$queryRaw<{
    goalsScored: number; goalsAttributed: number;
    seasonsWithScorers: number; seasonsPlayed: number;
  }[]>(Prisma.sql`
    WITH played AS (
      SELECT m.id, m.competition_edition_id AS edition_id,
             CASE WHEN m.home_team_id = ${teamId} THEN m.home_score ELSE m.away_score END AS gf
        FROM matches m
       WHERE m.competition_edition_id IN (${PUBLISHED})
         AND m.status = 'FULL_TIME'
         AND m.home_score IS NOT NULL AND m.away_score IS NOT NULL
         AND (m.home_team_id = ${teamId} OR m.away_team_id = ${teamId})
    ),
    -- Goals credited to this team by the event log. An OWN_GOAL carries the
    -- scoring player's own team, so it is never one of ours (principle 5).
    attributed AS (
      SELECT e.match_id, count(*)::int AS n
        FROM match_events e
        JOIN played p ON p.id = e.match_id
       WHERE e.team_id = ${teamId}
         AND e.type IN ('GOAL', 'PENALTY_GOAL')
         AND e.player_id IS NOT NULL
       GROUP BY e.match_id
    )
    SELECT
      COALESCE(sum(p.gf), 0)::int                                   AS "goalsScored",
      -- Not LEAST(a.n, p.gf): Postgres's LEAST *ignores* NULL rather than
      -- propagating it, so a match with no event log would count its goals as
      -- fully attributed and the rate would read ~99% where it is really ~20%.
      COALESCE(sum(CASE WHEN a.n IS NULL THEN 0
                        ELSE LEAST(a.n, p.gf) END), 0)::int         AS "goalsAttributed",
      count(DISTINCT p.edition_id) FILTER (WHERE a.n > 0)::int      AS "seasonsWithScorers",
      count(DISTINCT p.edition_id)::int                             AS "seasonsPlayed"
      FROM played p LEFT JOIN attributed a ON a.match_id = p.id
  `);

  const goalsScored = row?.goalsScored ?? 0;
  return {
    goalsScored,
    goalsAttributed: row?.goalsAttributed ?? 0,
    goalAttributionRate: goalsScored ? (row!.goalsAttributed / goalsScored) : 0,
    seasonsWithScorers: row?.seasonsWithScorers ?? 0,
    seasonsPlayed: row?.seasonsPlayed ?? 0,
  };
}

/** Sum season rows into one record — the all-time line at the top of the page. */
function totalise(seasons: TeamSeason[]): TeamRecord {
  const t = seasons.reduce<TeamRecord>((acc, s) => ({
    played: acc.played + s.played,
    won: acc.won + s.won,
    drawn: acc.drawn + s.drawn,
    lost: acc.lost + s.lost,
    goalsFor: acc.goalsFor + s.goalsFor,
    goalsAgainst: acc.goalsAgainst + s.goalsAgainst,
    goalDifference: acc.goalDifference + s.goalDifference,
    points: acc.points + s.points,
    cleanSheets: acc.cleanSheets + s.cleanSheets,
    blanks: acc.blanks + s.blanks,
    winRate: 0,
    goalsPerGame: 0,
  }), { ...EMPTY_RECORD });

  return {
    ...t,
    winRate: t.played ? Math.round((t.won * 1000) / t.played) / 10 : 0,
    goalsPerGame: t.played ? Math.round((t.goalsFor * 100) / t.played) / 100 : 0,
  };
}

/** The same sum, per competition — a league record and a cup record apart. */
function byCompetition(seasons: TeamSeason[]): TeamCompetitionRecord[] {
  // Keyed on the competition, and carrying one row from it so the group's
  // identity never has to be read back out of a possibly-empty array.
  const groups = new Map<number, { head: TeamSeason; list: TeamSeason[] }>();
  for (const s of seasons) {
    const group = groups.get(s.competitionId);
    if (group) group.list.push(s);
    else groups.set(s.competitionId, { head: s, list: [s] });
  }

  return [...groups.values()]
    .map(({ head, list }) => {
      const labels = list.map((s) => s.season).sort();
      return {
        ...totalise(list),
        competitionId: head.competitionId,
        competition: head.competition,
        competitionType: head.competitionType,
        seasons: list.length,
        firstSeason: labels[0] ?? head.season,
        lastSeason: labels[labels.length - 1] ?? head.season,
        titles: list.filter((s) => s.champion === true).length,
      };
    })
    .sort((a, b) => b.played - a.played);
}

export async function teamProfile(teamId: number): Promise<TeamProfile | null> {
  const team = await prisma.teams.findUnique({
    where: { id: teamId },
    include: {
      countries: { select: { name: true } },
      stadiums: { select: { name: true, city: true, capacity: true } },
    },
  });
  if (!team) return null;

  const [seasons, form, best, worst, players, coverage] = await Promise.all([
    seasonRows(teamId),
    teamMatches(teamId, 6, 'recent'),
    teamMatches(teamId, 1, 'best'),
    teamMatches(teamId, 1, 'worst'),
    playerStats({ teamId, limit: 12 }),
    scorerCoverage(teamId),
  ]);

  return {
    team: {
      id: team.id,
      name: team.name,
      shortName: team.short_name,
      type: team.type,
      country: team.countries?.name ?? null,
      logoUrl: team.logo_url,
      stadium: team.stadiums
        ? { name: team.stadiums.name, city: team.stadiums.city, capacity: team.stadiums.capacity }
        : null,
    },
    record: totalise(seasons),
    competitions: byCompetition(seasons),
    seasons,
    form,
    // A team that has never won has no biggest win; an unbeaten one no defeat.
    biggestWin: best[0]?.result === 'W' ? best[0] : null,
    heaviestDefeat: worst[0]?.result === 'L' ? worst[0] : null,
    players,
    coverage,
  };
}
