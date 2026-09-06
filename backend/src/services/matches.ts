import { prisma } from '../db.js';

export type MatchListFilters = {
  // Explicit `| undefined` so callers can pass a parsed query object straight
  // through under exactOptionalPropertyTypes.
  editionId?: number | undefined;
  teamId?: number | undefined;
  status?: string | undefined;
  from?: Date | undefined;
  to?: Date | undefined;
  limit: number;
  offset: number;
};

/**
 * Paginated match list. Unlike standings and top scorers this is a plain
 * relational read with no aggregation, so it goes through Prisma rather than
 * raw SQL, per the repo conventions.
 */
export async function listMatches(filters: MatchListFilters) {
  const { editionId, teamId, status, from, to, limit, offset } = filters;

  const where = {
    ...(editionId !== undefined && { competition_edition_id: editionId }),
    ...(status !== undefined && { status }),
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
      orderBy: [{ kickoff_at: 'desc' }, { id: 'desc' }],
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
        competition_editions: {
          select: {
            id: true,
            competitions: { select: { id: true, name: true, type: true } },
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
      attendance: m.attendance,
      competition: {
        editionId: m.competition_editions?.id ?? null,
        name: m.competition_editions?.competitions?.name ?? null,
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
