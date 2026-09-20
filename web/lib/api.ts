/**
 * Typed client for the sokabrain read API (backend priorities 2–3).
 *
 * Types mirror the backend's response shapes by hand. They are not generated,
 * so if a route's payload changes, change it here too.
 */
const API_URL = process.env.API_URL ?? 'http://localhost:4010';

export type Edition = {
  editionId: number;
  competitionId: number;
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
  /**
   * One mini-table per group, for a tournament played in groups; empty for a
   * league. Prefer these over `standings`, which for a cup sums group and
   * knockout results into a ranking that means nothing.
   */
  groups: GroupTable[];
  /** The knockout ties by round, in the order they are played. */
  knockout: KnockoutRound[];
};

export type GroupTable = {
  groupId: number;
  name: string;
  standings: StandingsRow[];
};

export type KnockoutMatch = {
  matchId: number;
  kickoffAt: string | null;
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
  /** Who advanced. Null while the tie is undecided. */
  winnerTeamId: number | null;
};

export type KnockoutRound = {
  round: string;
  matches: KnockoutMatch[];
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

/** Clubs and national teams are ranked separately; `teams.type` separates them. */
export type TeamType = 'CLUB' | 'NATIONAL';

export type Match = {
  id: number;
  kickoffAt: string | null;
  status: string;
  round: string | null;
  /** Set for a group-stage fixture; null for a league match or a knockout tie. */
  group: { id: number; name: string } | null;
  attendance: number | null;
  competition: {
    editionId: number | null;
    /** The competition itself, so a mixed list can be grouped and linked. */
    id: number | null;
    /** Country-prefixed: three competitions here are called "Premier League". */
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
  // Null for a player with no record in a season that logs assists at all.
  assists: number | null;
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
  seasonsWithAssists: number;
  assistsRecorded: number;
  matchesInScope: number;
  matchesWithLineups: number;
  appearancesReliable: boolean;
  cardsReliable: boolean;
};

export type TeamRefLite = {
  /** 'CLUB' or 'NATIONAL' — the list mixes both, so the picker can label them. */
  type?: string;
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

export type MatchEventRow = {
  id: number;
  type: string;
  minute: number | null;
  addedTime: number | null;
  side: "home" | "away" | null;
  playerId: number | null;
  playerName: string | null;
  countsForOtherSide: boolean;
};

export type MatchDetail = {
  id: number;
  kickoffAt: string | null;
  status: string;
  round: string | null;
  venue: string | null;
  competition: { editionId: number; name: string; season: string };
  home: { id: number; name: string; shortName: string | null; score: number | null };
  away: { id: number; name: string; shortName: string | null; score: number | null };
  events: MatchEventRow[];
  coverage: {
    goalsInScore: number;
    goalEventsRecorded: number;
    eventLogComplete: boolean;
    noEventLog: boolean;
    unnamedScorers: number;
    hasAssists: boolean;
  };
  headToHead: { played: number; homeWins: number; awayWins: number; draws: number };
  form: {
    home: { matchId: number; result: "W" | "D" | "L"; opponent: string; score: string }[];
    away: { matchId: number; result: "W" | "D" | "L"; opponent: string; score: string }[];
  };
};

export type DayCount = { date: string; matches: number; played: number };

export type RoundSummary = {
  round: string;
  sortKey: number;
  matches: number;
  played: number;
  firstDate: string | null;
  lastDate: string | null;
};

export type ScheduleContext = {
  editionId: number | null;
  season: string | null;
  competition: string | null;
  nextMatchDate: string | null;
  lastMatchDate: string | null;
  inSeason: boolean;
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


/* ------------------------------------------------------------ team pages -- */

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
  /** League only — a cup's combined ranking is not a standing. */
  position: number | null;
  teamsInEdition: number | null;
  /** Tournament only — how far they got. */
  furthestRound: string | null;
  /** False while the edition still has fixtures to play. */
  finished: boolean;
  /** False when fixtures are missing from every source (TPL 2020/21). */
  settled: boolean;
  /** Won it that season. Null when that cannot be said yet, or at all. */
  champion: boolean | null;
};

export type TeamCompetitionRecord = TeamRecord & {
  competitionId: number;
  competition: string;
  competitionType: string;
  seasons: number;
  firstSeason: string;
  lastSeason: string;
  /** Only seasons where `champion` is known count toward this. */
  titles: number;
};

export type TeamFormMatch = {
  matchId: number;
  kickoffAt: string | null;
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
    type: TeamType;
    country: string | null;
    logoUrl: string | null;
    stadium: { name: string; city: string | null; capacity: number | null } | null;
  };
  record: TeamRecord;
  competitions: TeamCompetitionRecord[];
  seasons: TeamSeason[];
  form: TeamFormMatch[];
  biggestWin: TeamFormMatch | null;
  heaviestDefeat: TeamFormMatch | null;
  players: { players: PlayerStat[]; coverage: PlayerStatsCoverage };
  coverage: {
    goalAttributionRate: number;
    goalsScored: number;
    goalsAttributed: number;
    seasonsWithScorers: number;
    seasonsPlayed: number;
  };
};

export const api = {
  editions: () => get<{ editions: Edition[] }>('/api/vault/editions'),
  match: (id: number | string) => get<MatchDetail>(`/api/vault/matches/${id}`),
  context: () => get<ScheduleContext>('/api/vault/schedule/context'),
  days: (params: Record<string, string | number | undefined>) => {
    const qs = new URLSearchParams();
    for (const [k, v] of Object.entries(params)) {
      if (v !== undefined && v !== '') qs.set(k, String(v));
    }
    return get<{ days: DayCount[]; nearest: string | null }>(`/api/vault/schedule/days?${qs}`);
  },
  rounds: (editionId: number | string) =>
    get<{ rounds: RoundSummary[]; currentRound: string | null; hasRounds: boolean; withoutRound: number }>(
      `/api/vault/schedule/rounds/${editionId}`,
    ),
  standings: (id: number) => get<StandingsResponse>(`/api/vault/editions/${id}/standings`),
  topScorers: (id: number, limit = 20) =>
    get<TopScorersResponse>(`/api/vault/editions/${id}/top-scorers?limit=${limit}`),
  overview: (scope: { competitionId?: number; editionId?: number } = {}) => {
    const qs = new URLSearchParams();
    if (scope.competitionId) qs.set('competitionId', String(scope.competitionId));
    if (scope.editionId) qs.set('editionId', String(scope.editionId));
    const q = qs.toString();
    return get<Overview>(`/api/vault/stats/overview${q ? `?${q}` : ''}`);
  },
  team: (id: number | string) => get<TeamProfile>(`/api/vault/teams/${id}`),
  teams: (type?: TeamType) =>
    get<{ teams: TeamRefLite[] }>(`/api/vault/teams${type ? `?type=${type}` : ''}`),
  clubs: (scope: { competitionId?: number; editionId?: number; type?: TeamType } = {}) => {
    const qs = new URLSearchParams();
    if (scope.competitionId) qs.set('competitionId', String(scope.competitionId));
    if (scope.editionId) qs.set('editionId', String(scope.editionId));
    if (scope.type) qs.set('type', scope.type);
    const q = qs.toString();
    return get<{ clubs: ClubStat[] }>(`/api/vault/stats/clubs${q ? `?${q}` : ''}`);
  },
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
