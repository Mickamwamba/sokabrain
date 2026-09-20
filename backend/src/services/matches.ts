import { prisma } from '../db.js';
import { competitionDisplayName } from './competitionName.js';

export type MatchListFilters = {
  // Explicit `| undefined` so callers can pass a parsed query object straight
  // through under exactOptionalPropertyTypes.
  editionId?: number | undefined;
  teamId?: number | undefined;
  status?: string | undefined;
  round?: string | undefined;
  from?: Date | undefined;
  to?: Date | undefined;
  /** 'asc' when browsing a round or a day forwards; 'desc' for the archive. */
  order?: 'asc' | 'desc' | undefined;
  limit: number;
  offset: number;
};

/**
 * Paginated match list. Unlike standings and top scorers this is a plain
 * relational read with no aggregation, so it goes through Prisma rather than
 * raw SQL, per the repo conventions.
 */
export async function listMatches(filters: MatchListFilters) {
  const { editionId, teamId, status, round, from, to, order, limit, offset } = filters;

  const where = {
    // Public match list never leaks matches from unpublished editions.
    competition_editions: { is_published: true },
    ...(editionId !== undefined && { competition_edition_id: editionId }),
    ...(status !== undefined && { status }),
    ...(round !== undefined && { round }),
    ...(teamId !== undefined && {
      OR: [{ home_team_id: teamId }, { away_team_id: teamId }],
    }),
    ...((from ?? to) && {
      kickoff_at: {
        ...(from && { gte: from }),
        ...(to && { lte: to }),
      },
    }),
  };

  const [total, rows] = await Promise.all([
    prisma.matches.count({ where }),
    prisma.matches.findMany({
      where,
      // Newest first, with a stable id tiebreak so pagination can't repeat or
      // skip rows when many matches share a kickoff time (common in this data).
      orderBy: order === 'asc'
        ? [{ kickoff_at: 'asc' as const }, { id: 'asc' as const }]
        : [{ kickoff_at: 'desc' as const }, { id: 'desc' as const }],
      take: limit,
      skip: offset,
      include: {
        teams_matches_home_team_idToteams: {
          select: { id: true, name: true, short_name: true, logo_url: true },
        },
        teams_matches_away_team_idToteams: {
          select: { id: true, name: true, short_name: true, logo_url: true },
        },
        stadiums: { select: { id: true, name: true, city: true } },
        competition_groups: { select: { id: true, name: true } },
        competition_editions: {
          select: {
            id: true,
            competitions: {
              select: {
                id: true,
                name: true,
                type: true,
                countries: { select: { name: true } },
              },
            },
            seasons: { select: { id: true, label: true } },
          },
        },
      },
    }),
  ]);

  return {
    total,
    limit,
    offset,
    matches: rows.map((m) => ({
      id: m.id,
      kickoffAt: m.kickoff_at,
      status: m.status,
      round: m.round,
      // The group a match belongs to, for a tournament played in groups. Null
      // for a league fixture and for every knockout tie, which is what lets a
      // caller lay a cup out by stage.
      group: m.competition_groups ? { id: m.competition_groups.id, name: m.competition_groups.name } : null,
      attendance: m.attendance,
      /** Clock in minutes while LIVE; null otherwise. */
      liveMinute: m.live_minute,
      /** When that clock was captured RUNNING — the anchor a client ticks from. */
      liveMinuteAt: m.live_minute_at,
      competition: {
        editionId: m.competition_editions?.id ?? null,
        // The competition id, so a caller can group a mixed list by competition
        // and link to it. A cross-competition fixture list needs both: the
        // edition identifies the season, the competition identifies the league.
        id: m.competition_editions?.competitions?.id ?? null,
        // Country-prefixed, because three of the competitions in this vault are
        // called plainly "Premier League". In a list scoped to one edition the
        // bare name was merely redundant; in a mixed list it is wrong.
        name: m.competition_editions?.competitions
          ? competitionDisplayName(
              m.competition_editions.competitions.name,
              m.competition_editions.competitions.countries?.name,
            )
          : null,
        type: m.competition_editions?.competitions?.type ?? null,
        season: m.competition_editions?.seasons?.label ?? null,
      },
      homeTeam: m.teams_matches_home_team_idToteams,
      awayTeam: m.teams_matches_away_team_idToteams,
      // Null until played — deliberately not coerced to 0, which would render
      // an unplayed fixture as a goalless draw.
      score: {
        home: m.home_score,
        away: m.away_score,
        homeExtraTime: m.home_score_et,
        awayExtraTime: m.away_score_et,
        homePenalties: m.home_score_pens,
        awayPenalties: m.away_score_pens,
      },
      stadium: m.stadiums,
    })),
  };
}
