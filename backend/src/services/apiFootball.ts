import { env } from '../env.js';
import type { ProviderFixture } from './providerFixture.js';

/**
 * Minimal typed client for API-Football v3.
 *
 * Only the endpoints the sync job needs are modelled. Types describe the subset
 * of each payload we actually read — the API returns considerably more.
 */

const BASE_URL = 'https://v3.football.api-sports.io';

export type ApiFootballTeam = { id: number; name: string; logo: string | null };

export type ApiFootballFixture = {
  fixture: {
    id: number;
    date: string;
    referee: string | null;
    venue: { id: number | null; name: string | null; city: string | null };
    status: { long: string; short: string; elapsed: number | null };
  };
  league: { id: number; name: string; country: string; season: number; round: string | null };
  teams: { home: ApiFootballTeam; away: ApiFootballTeam };
  goals: { home: number | null; away: number | null };
  score: {
    halftime: { home: number | null; away: number | null };
    fulltime: { home: number | null; away: number | null };
    extratime: { home: number | null; away: number | null };
    penalty: { home: number | null; away: number | null };
  };
};

export type ApiFootballEvent = {
  time: { elapsed: number | null; extra: number | null };
  team: { id: number; name: string };
  player: { id: number | null; name: string | null };
  assist: { id: number | null; name: string | null };
  type: string; // 'Goal' | 'Card' | 'subst' | 'Var'
  detail: string; // 'Normal Goal' | 'Own Goal' | 'Penalty' | 'Yellow Card' | ...
};

export type ApiFootballLeague = {
  league: { id: number; name: string; type: string };
  country: { name: string; code: string | null };
  seasons: { year: number; current: boolean; coverage?: { fixtures?: Record<string, boolean> } }[];
};

export class ApiFootballError extends Error {
  constructor(
    readonly status: number,
    message: string,
  ) {
    super(message);
    this.name = 'ApiFootballError';
  }
}

/**
 * API-Football returns HTTP 200 with a populated `errors` object for quota and
 * auth problems, so a naive `res.ok` check silently treats an exhausted quota as
 * an empty result set. Both are checked here.
 */
async function request<T>(path: string, params: Record<string, string | number>): Promise<T[]> {
  if (!env.API_FOOTBALL_KEY) {
    throw new ApiFootballError(0, 'API_FOOTBALL_KEY is not set');
  }

  const qs = new URLSearchParams(
    Object.entries(params).map(([k, v]) => [k, String(v)]),
  );
  const res = await fetch(`${BASE_URL}${path}?${qs}`, {
    headers: { 'x-apisports-key': env.API_FOOTBALL_KEY },
  });

  if (!res.ok) {
    throw new ApiFootballError(res.status, `GET ${path} returned HTTP ${res.status}`);
  }

  const body = (await res.json()) as {
    response?: T[];
    errors?: unknown;
    results?: number;
  };

  // `errors` is [] when fine and a populated object when not.
  if (body.errors && !Array.isArray(body.errors) && Object.keys(body.errors).length > 0) {
    throw new ApiFootballError(200, `API-Football error: ${JSON.stringify(body.errors)}`);
  }

  return body.response ?? [];
}

export const apiFootball = {
  /** Leagues, optionally filtered by country — used to validate coverage. */
  leagues: (params: { country?: string; season?: number } = {}) =>
    request<ApiFootballLeague>('/leagues', params as Record<string, string | number>),

  /** Teams in a league season — used to build the id mapping. */
  teams: (leagueId: number, season: number) =>
    request<{ team: ApiFootballTeam; venue: { id: number | null; name: string | null } }>(
      '/teams',
      { league: leagueId, season },
    ),

  /** Fixtures for a league season, or a single date. */
  fixtures: (params: { league?: number; season?: number; date?: string; from?: string; to?: string }) =>
    request<ApiFootballFixture>('/fixtures', params as Record<string, string | number>),

  /** Every currently in-play fixture the plan covers. */
  liveFixtures: (leagueIds: number[]) =>
    request<ApiFootballFixture>('/fixtures', {
      live: leagueIds.length > 0 ? leagueIds.join('-') : 'all',
    }),

  events: (fixtureId: number) =>
    request<ApiFootballEvent>('/fixtures/events', { fixture: fixtureId }),
};

/**
 * Fixture status codes that mean the match has finished.
 * FT = full time, AET = after extra time, PEN = decided on penalties.
 */
const FINISHED = new Set(['FT', 'AET', 'PEN']);
/** In play, including half-time and break-time. */
const IN_PLAY = new Set(['1H', 'HT', '2H', 'ET', 'BT', 'P', 'LIVE', 'INT']);
const POSTPONED = new Set(['PST', 'SUSP']);
const CANCELLED = new Set(['CANC', 'AWD', 'WO']);
const ABANDONED = new Set(['ABD']);

/** Map an API-Football status code onto the vault's `matches.status` values. */
export function mapStatus(short: string): string {
  if (FINISHED.has(short)) return 'FULL_TIME';
  if (IN_PLAY.has(short)) return 'LIVE';
  if (POSTPONED.has(short)) return 'POSTPONED';
  if (CANCELLED.has(short)) return 'CANCELLED';
  if (ABANDONED.has(short)) return 'ABANDONED';
  return 'SCHEDULED'; // NS, TBD
}

/**
 * Normalise an API-Football fixture into the provider-neutral shape.
 *
 * Kept here rather than in the sync so that each provider owns its own quirks —
 * see `sportmonks.ts` for the other one.
 */
export function toProviderFixture(f: ApiFootballFixture): ProviderFixture {
  return {
    id: String(f.fixture.id),
    kickoff: new Date(f.fixture.date),
    status: mapStatus(f.fixture.status.short),
    home: { id: String(f.teams.home.id), name: f.teams.home.name },
    away: { id: String(f.teams.away.id), name: f.teams.away.name },
    homeScore: f.goals.home,
    awayScore: f.goals.away,
    homeScoreEt: f.score.extratime.home,
    awayScoreEt: f.score.extratime.away,
    homeScorePens: f.score.penalty.home,
    awayScorePens: f.score.penalty.away,
    // API-Football reports elapsed minutes on the fixture status.
    liveMinute: mapStatus(f.fixture.status.short) === 'LIVE' ? f.fixture.status.elapsed : null,
    round: f.league.round,
    competition: { id: String(f.league.id), name: f.league.name, season: String(f.league.season) },
  };
}

/**
 * Check that a fixture's event log reconstructs its published score under the
 * vault's own own-goal rule.
 *
 * This does not feed the sync — the score always comes from `fixture.goals`.
 * It exists because API-Football's own-goal team attribution is not something
 * this codebase has been able to verify against live data (there is no key), and
 * design principle 5 says that assumption is exactly the one that has bitten
 * before. A mismatch here means the assumption below is wrong for that fixture,
 * and event ingestion must not be built on it until it's resolved.
 *
 * The assumption under test: an `Own Goal` event's `team` is the team of the
 * player who scored it, so the goal counts for their OPPONENT. Note that
 * SportMonks turned out to do the OPPOSITE (see `sportmonks.normaliseEvents`),
 * so this really does have to be checked per provider.
 */
export async function verifyEventsAgainstScore(fixture: ApiFootballFixture): Promise<{
  fixtureId: number;
  publishedScore: string;
  reconstructedScore: string;
  ownGoals: number;
  agrees: boolean;
}> {
  const events = await apiFootball.events(fixture.fixture.id);
  const homeApiId = fixture.teams.home.id;

  let home = 0;
  let away = 0;
  let ownGoals = 0;

  for (const e of events) {
    if (e.type !== 'Goal') continue;
    if (e.detail === 'Missed Penalty') continue;

    const isOwnGoal = e.detail === 'Own Goal';
    if (isOwnGoal) ownGoals += 1;

    const scoredByHome = e.team.id === homeApiId;
    // An own goal counts for the opposing side.
    const countsForHome = isOwnGoal ? !scoredByHome : scoredByHome;
    if (countsForHome) home += 1;
    else away += 1;
  }

  const published = `${fixture.goals.home ?? '-'}-${fixture.goals.away ?? '-'}`;
  const reconstructed = `${home}-${away}`;
  return {
    fixtureId: fixture.fixture.id,
    publishedScore: published,
    reconstructedScore: reconstructed,
    ownGoals,
    agrees: published === reconstructed,
  };
}
