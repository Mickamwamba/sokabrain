/**
 * Typed client for the sokabrain read API (backend priorities 2–3).
 *
 * Types mirror the backend's response shapes by hand. They are not generated,
 * so if a route's payload changes, change it here too.
 */
const API_URL = process.env.API_URL ?? 'http://localhost:4010';

export type Edition = {
  editionId: number;
  competition: string;
  competitionType: string;
  tier: number | null;
  country: string | null;
  season: string;
  format: string | null;
  matchCount: number;
};

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

export type StandingsResponse = {
  edition: {
    editionId: number;
    competition: string;
    competitionType: string;
    season: string;
  };
  isLeagueTable: boolean;
  coverage: {
    matchesFullTime: number;
    matchesCounted: number;
    matchesMissingScore: number;
    fixturesPresent: number;
    fixturesExpected: number | null;
    missingFixtures: number;
    minPlayed: number;
    maxPlayed: number;
    // True when the fixture list itself has holes, so clubs have played
    // materially different numbers of games and the table is not a final one.
    isProvisional: boolean;
  };
  standings: StandingsRow[];
};

export type TopScorersResponse = {
  scorers: {
    rank: number;
    playerId: number;
    playerName: string;
    teamId: number | null;
    teamName: string | null;
    goals: number;
    penalties: number;
    matchesScoredIn: number;
  }[];
  coverage: {
    attributedGoals: number;
    unattributedGoals: number;
    matchesPlayed: number;
    matchesWithEvents: number;
  };
};

export type TeamRef = {
  id: number;
  name: string;
  short_name: string | null;
  logo_url: string | null;
};

export type Match = {
  id: number;
  kickoffAt: string | null;
  status: string;
  round: string | null;
  attendance: number | null;
  competition: {
    editionId: number | null;
    name: string | null;
    type: string | null;
    season: string | null;
  };
  homeTeam: TeamRef;
  awayTeam: TeamRef;
  score: {
    home: number | null;
    away: number | null;
    homeExtraTime: number | null;
    awayExtraTime: number | null;
    homePenalties: number | null;
    awayPenalties: number | null;
  };
  stadium: { id: number; name: string; city: string | null } | null;
};

export type MatchesResponse = {
  total: number;
  limit: number;
  offset: number;
  matches: Match[];
};

export type Overview = {
  matches: number;
  goals: number;
  clubs: number;
  players: number;
  seasons: number;
  competitions: number;
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

export type PlayerStat = {
  playerId: number;
  playerName: string;
  position: string | null;
  teamId: number | null;
  teamName: string | null;
  goals: number;
  penalties: number;
  // Null means the record is too thin to state a number, not zero.
  appearances: number | null;
  yellowCards: number | null;
  redCards: number | null;
  goalsPerApp: number | null;
};

export type PlayerStatsCoverage = {
  goalsInScope: number;
  goalsAttributed: number;
  goalAttributionRate: number;
  seasonsInScope: number;
  seasonsWithScorers: number;
  matchesInScope: number;
  matchesWithLineups: number;
  appearancesReliable: boolean;
  cardsReliable: boolean;
};

export type TeamRefLite = {
  id: number;
  name: string;
  shortName: string | null;
  country: string | null;
};

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
    kickoffAt: string | null;
    competition: string;
    season: string;
    homeTeamId: number;
    homeTeam: string;
    awayTeam: string;
    homeScore: number | null;
    awayScore: number | null;
  }[];
};

/** Thrown so pages can distinguish "backend is down" from "no such edition". */
export class ApiError extends Error {
  constructor(
    readonly status: number,
    message: string,
    options?: { cause?: unknown },
  ) {
    super(message, options);
    this.name = 'ApiError';
  }
}

async function get<T>(path: string): Promise<T> {
  let res: Response;
  try {
    // The vault is editable through the admin API, so a stale page would show
    // corrections that have already been made. Always read through.
    res = await fetch(`${API_URL}${path}`, { cache: 'no-store' });
  } catch (cause) {
    throw new ApiError(0, `Cannot reach the API at ${API_URL} — is the backend running?`, {
      cause,
    });
  }
  if (!res.ok) {
    throw new ApiError(res.status, `GET ${path} failed with ${res.status}`);
  }
  return res.json() as Promise<T>;
}

export const api = {
  editions: () => get<{ editions: Edition[] }>('/api/vault/editions'),
  standings: (id: number) => get<StandingsResponse>(`/api/vault/editions/${id}/standings`),
  topScorers: (id: number, limit = 20) =>
    get<TopScorersResponse>(`/api/vault/editions/${id}/top-scorers?limit=${limit}`),
  overview: () => get<Overview>('/api/vault/stats/overview'),
  teams: () => get<{ teams: TeamRefLite[] }>('/api/vault/teams'),
  clubs: (editionId?: string | number) =>
    get<{ clubs: ClubStat[] }>(
      `/api/vault/stats/clubs${editionId ? `?editionId=${editionId}` : ''}`,
    ),
  players: (params: Record<string, string | number | undefined>) => {
    const qs = new URLSearchParams();
    for (const [k, v] of Object.entries(params)) {
      if (v !== undefined && v !== '') qs.set(k, String(v));
    }
    return get<{ players: PlayerStat[]; coverage: PlayerStatsCoverage }>(
      `/api/vault/stats/players?${qs}`,
    );
  },
  headToHead: (a: number | string, b: number | string) =>
    get<HeadToHead>(`/api/vault/stats/head-to-head?teamA=${a}&teamB=${b}`),
  matches: (params: Record<string, string | number | undefined>) => {
    const qs = new URLSearchParams();
    for (const [k, v] of Object.entries(params)) {
      if (v !== undefined && v !== '') qs.set(k, String(v));
    }
    return get<MatchesResponse>(`/api/vault/matches?${qs}`);
  },
};
