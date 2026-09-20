import { env } from '../env.js';
import type { ProviderEvent, ProviderFixture, ProviderTeam } from './providerFixture.js';

/**
 * Minimal typed client for the SportMonks Football API v3.
 *
 * Only the endpoints the sync needs are modelled, and each type describes the
 * subset of the payload actually read — the API returns a great deal more.
 *
 * Why SportMonks: it is the only provider whose Tanzanian Premier League
 * coverage could be verified before paying. Its published per-league coverage
 * table ticks "Livescores and Events" for Ligi kuu Bara (#884), and the plan in
 * use covers the top tier of Tanzania, Kenya, Uganda, Rwanda and South Africa.
 * What it does NOT cover for these leagues is lineups or player stats, so team
 * sheets stay as thin as they were — do not expect this to fill them.
 */

const BASE_URL = 'https://api.sportmonks.com/v3/football';

/** Pagination cap the API enforces on these endpoints. */
const PER_PAGE = 50;
/** Refuse to walk forever if `has_more` never goes false. */
const MAX_PAGES = 100;

export type SportmonksCountry = { id: number; name: string; iso2: string | null };

export type SportmonksSeason = {
  id: number;
  name: string;
  league_id: number;
  is_current?: boolean;
};

export type SportmonksLeague = {
  id: number;
  name: string;
  active: boolean;
  type: string;
  sub_type: string;
  country_id: number;
  country?: SportmonksCountry;
  /** Present when `include=currentSeason`; the API lowercases the key. */
  currentseason?: SportmonksSeason;
};

export type SportmonksParticipant = {
  id: number;
  name: string;
  meta: { location: 'home' | 'away'; winner: boolean | null; position?: number };
};

export type SportmonksScore = {
  id: number;
  description: string;
  score: { goals: number; participant: 'home' | 'away' };
};

export type SportmonksEvent = {
  id: number;
  type_id: number;
  participant_id: number;
  player_id: number | null;
  player_name: string | null;
  related_player_name: string | null;
  minute: number | null;
  extra_minute: number | null;
  result: string | null;
  type?: { id: number; name: string };
};

export type SportmonksFixture = {
  id: number;
  league_id: number;
  season_id: number;
  round_id: number | null;
  state_id: number;
  name: string;
  starting_at: string;
  result_info: string | null;
  participants?: SportmonksParticipant[];
  scores?: SportmonksScore[];
  events?: SportmonksEvent[];
  round?: { id: number; name: string };
};

export class SportmonksError extends Error {
  constructor(
    readonly status: number,
    message: string,
  ) {
    super(message);
    this.name = 'SportmonksError';
  }
}

type Envelope<T> = {
  data?: T;
  message?: string;
  pagination?: { count: number; per_page: number; current_page: number; has_more: boolean };
  rate_limit?: { resets_in_seconds: number; remaining: number; requested_entity: string };
};

async function get<T>(path: string, params: Record<string, string | number> = {}): Promise<Envelope<T>> {
  if (!env.SPORTMONKS_TOKEN) {
    throw new SportmonksError(0, 'SPORTMONKS_TOKEN is not set');
  }

  const qs = new URLSearchParams(Object.entries(params).map(([k, v]) => [k, String(v)]));
  const url = `${BASE_URL}${path}${qs.toString() ? `?${qs}` : ''}`;

  // The token goes in the Authorization header, not the query string, so it
  // does not end up in logs or proxy access records.
  const res = await fetch(url, { headers: { Authorization: env.SPORTMONKS_TOKEN } });
  const body = (await res.json().catch(() => ({}))) as Envelope<T>;

  if (!res.ok) {
    // The API explains auth, plan and rate problems in `message`; surface it
    // rather than a bare status, because "your plan does not include this
    // league" and "your token is wrong" are very different problems.
    throw new SportmonksError(res.status, body.message ?? `GET ${path} returned HTTP ${res.status}`);
  }
  return body;
}

/** Walk a paginated collection to the end. */
async function getAll<T>(path: string, params: Record<string, string | number> = {}): Promise<T[]> {
  const out: T[] = [];
  for (let page = 1; page <= MAX_PAGES; page += 1) {
    const body = await get<T[]>(path, { ...params, per_page: PER_PAGE, page });
    out.push(...(body.data ?? []));
    if (!body.pagination?.has_more) return out;
  }
  throw new SportmonksError(0, `${path}: pagination did not terminate after ${MAX_PAGES} pages`);
}

export const sportmonks = {
  /** Every league the plan grants, with its country and current season. */
  leagues: () =>
    getAll<SportmonksLeague>('/leagues', { include: 'country;currentSeason' }),

  /** All seasons of one league — used to find the season to sync. */
  seasons: (leagueId: number) =>
    getAll<SportmonksSeason>('/seasons', { filters: `seasonLeagues:${leagueId}` }),

  /** Teams in a season — used to build the vault id mapping. */
  teams: (seasonId: number) =>
    getAll<{ id: number; name: string; short_code: string | null }>(
      `/teams/seasons/${seasonId}`,
    ),

  /**
   * The same list with each club's own country.
   *
   * A club's country is NOT the league's: Al Hilal Omdurman and Al Merreikh are
   * Sudanese clubs playing in the Rwandan league while the war continues, and
   * filing them under Rwanda would be wrong.
   */
  teamsWithCountry: (seasonId: number) =>
    getAll<{
      id: number;
      name: string;
      short_code: string | null;
      founded: number | null;
      country?: SportmonksCountry;
    }>(`/teams/seasons/${seasonId}`, { include: 'country' }),

  /** Every fixture of a season, with the detail the sync and comparison need. */
  seasonFixtures: (seasonId: number) =>
    getAll<SportmonksFixture>('/fixtures', {
      filters: `fixtureSeasons:${seasonId}`,
      include: 'participants;scores;events.type;round',
    }),

  /**
   * Fixtures currently in play.
   *
   * This endpoint is the whole point of the subscription: it returns only what
   * is live, so a polling job costs one request per cycle regardless of how many
   * leagues are covered.
   */
  liveFixtures: () =>
    getAll<SportmonksFixture>('/livescores/inplay', {
      include: 'participants;scores;events.type;round',
    }),

  /**
   * One player, with their real name.
   *
   * The event feed carries a DISPLAY name that is often an abbreviation
   * ("S. Kammies"); this endpoint carries "Sergio Kammies". Resolving through it
   * is what keeps abbreviations out of the vault's player table. Returns null
   * when the provider does not know the id.
   */
  player: async (playerId: number) => {
    try {
      const body = await get<{
        id: number;
        name: string | null;
        display_name: string | null;
        firstname: string | null;
        lastname: string | null;
        date_of_birth: string | null;
        country?: SportmonksCountry;
      }>(`/players/${playerId}`, { include: 'country' });
      return body.data ?? null;
    } catch (err) {
      if (err instanceof SportmonksError && err.status === 404) return null;
      throw err;
    }
  },

  /** Remaining quota for the last entity queried, for a job to log. */
  rateLimit: async () => (await get<unknown>('/leagues', { per_page: 1 })).rate_limit ?? null,
};

/* -------------------------------------------------------------------------- */
/*  Normalising into the provider-neutral shape                               */
/* -------------------------------------------------------------------------- */

/** State ids that mean the match finished and its score is final. */
const FINISHED = new Set([5, 7, 8]); // FT, AET, FT_PEN
/** In play, including the breaks, where a score is still moving. */
const IN_PLAY = new Set([2, 3, 4, 6, 9, 21, 22, 23, 25]);
const POSTPONED = new Set([10, 11, 16, 18, 19]); // postponed, suspended, delayed, interrupted, awaiting
const CANCELLED = new Set([12, 14, 20]); // cancelled, walk over, deleted
const ABANDONED = new Set([15]);
/**
 * A forfeited result. The vault has met this twice -- Dodoma Jiji 0-3 Pamba
 * Jiji (2025/26) and Namungo 3-0 Mbeya Kwanza (2021/22) -- and both times it
 * was found by hand after an event log refused to reconcile forever. SportMonks
 * publishes it as a state, so it can be recognised on sight from here on.
 */
const AWARDED = new Set([17]);

/** Map a SportMonks `state_id` onto the vault's `matches.status` values. */
export function mapState(stateId: number): string {
  if (FINISHED.has(stateId)) return 'FULL_TIME';
  if (IN_PLAY.has(stateId)) return 'LIVE';
  if (POSTPONED.has(stateId)) return 'POSTPONED';
  if (CANCELLED.has(stateId)) return 'CANCELLED';
  if (ABANDONED.has(stateId)) return 'ABANDONED';
  if (AWARDED.has(stateId)) return 'FULL_TIME';
  return 'SCHEDULED'; // NS (1), TBA (13), PENDING (26)
}

/** True where the result was awarded rather than played out. */
export function isAwarded(stateId: number): boolean {
  return AWARDED.has(stateId);
}

/**
 * SportMonks event type ids, mapped onto the vault's `match_events.type` values.
 *
 * Ids are stable and `include=events.type` also returns the name, so the name is
 * used as the fallback when an unseen id turns up. Anything unrecognised returns
 * null and the event is skipped rather than guessed at.
 */
const EVENT_TYPE_BY_NAME: Record<string, string> = {
  Goal: 'GOAL',
  'Own Goal': 'OWN_GOAL',
  Penalty: 'PENALTY_GOAL',
  'Yellowcard': 'YELLOW_CARD',
  'Redcard': 'RED_CARD',
  'Yellowred Card': 'RED_CARD',
  Substitution: 'SUBSTITUTION',
};

export function mapEventType(name: string | undefined): string | null {
  if (!name) return null;
  return EVENT_TYPE_BY_NAME[name] ?? null;
}

function pickScore(
  scores: SportmonksScore[] | undefined,
  description: string,
  participant: 'home' | 'away',
): number | null {
  const row = scores?.find(
    (s) => s.description === description && s.score.participant === participant,
  );
  return row ? row.score.goals : null;
}

function team(p: SportmonksParticipant): ProviderTeam {
  return { id: String(p.id), name: p.name };
}

/**
 * Turn a SportMonks fixture into the neutral shape.
 *
 * `leagueName` is only for log messages; the fixture's own `name` is
 * "Home vs Away", not the competition.
 *
 * Returns null when the payload lacks the two participants, which happens on
 * placeholder fixtures in a draw that has not been made. Guessing a side is
 * exactly how goals end up on the wrong team.
 */
export function normaliseFixture(
  f: SportmonksFixture,
  leagueName = 'unknown league',
): ProviderFixture | null {
  const home = f.participants?.find((p) => p.meta.location === 'home');
  const away = f.participants?.find((p) => p.meta.location === 'away');
  if (!home || !away) return null;

  return {
    id: String(f.id),
    // `starting_at` is UTC without a zone marker, so say so explicitly rather
    // than let the runtime read it as local time. A kickoff read three hours out
    // is a defect this project has already fixed once.
    kickoff: new Date(`${f.starting_at.replace(' ', 'T')}Z`),
    status: mapState(f.state_id),
    home: team(home),
    away: team(away),
    // CURRENT is the final score; 2ND_HALF is the running total at full time and
    // agrees with it, while 2ND_HALF_ONLY counts only that half. Take CURRENT.
    homeScore: pickScore(f.scores, 'CURRENT', 'home'),
    awayScore: pickScore(f.scores, 'CURRENT', 'away'),
    homeScoreEt: pickScore(f.scores, 'ET', 'home'),
    awayScoreEt: pickScore(f.scores, 'ET', 'away'),
    homeScorePens: pickScore(f.scores, 'PENALTY_SHOOTOUT', 'home'),
    awayScorePens: pickScore(f.scores, 'PENALTY_SHOOTOUT', 'away'),
    round: f.round?.name ?? null,
    // The season is the numeric season id, NOT its label. It has to be the same
    // value `mapSportmonks` used to build the edition mapping key, or every
    // fixture reads as an unmapped competition. SportMonks gives a league many
    // seasons and numbers each one, so the id is the stable half.
    competition: { id: String(f.league_id), name: leagueName, season: String(f.season_id) },
  };
}

/**
 * Normalise a fixture's events, applying the own-goal flip.
 *
 * **SportMonks files an own goal under the side the goal counts FOR.** This was
 * established against the vault, not assumed: Kagera Sugar 1-1 Fountain Gate
 * (13 Sep 2026) carries the own goal on Fountain Gate, the away side, with the
 * running score moving 1-0 to 1-1 -- while the vault holds the same scorer, at
 * the same 34th minute, under Kagera Sugar. So the scorer is a Kagera player and
 * the flip is needed, exactly as it was for ligikuu, RSSSF and FotMob.
 *
 * The flip is applied ONCE, to the team the event is stored under, and never to
 * the score — which comes from the provider's published value and so cannot be
 * got wrong this way.
 */
export function normaliseEvents(f: SportmonksFixture): ProviderEvent[] {
  const home = f.participants?.find((p) => p.meta.location === 'home');
  const away = f.participants?.find((p) => p.meta.location === 'away');
  if (!home || !away) return [];

  const out: ProviderEvent[] = [];
  for (const e of f.events ?? []) {
    const type = mapEventType(e.type?.name);
    if (type === null) continue;

    const credited = e.participant_id === home.id ? home : away;
    const scorer = type === 'OWN_GOAL' ? (credited.id === home.id ? away : home) : credited;

    out.push({
      minute: e.minute,
      extraMinute: e.extra_minute,
      type,
      team: team(scorer),
      playerName: e.player_name,
      playerId: e.player_id === null ? null : String(e.player_id),
    });
  }
  return out;
}

/**
 * True when a name is an abbreviation rather than a person's name.
 *
 * The event feed carries a DISPLAY name, and this provider abbreviates in both
 * orders: "S. Kammies" and "Chukwuma O.". A single-letter token, with or without
 * its dot, is an initial. This is the guard that keeps initials out of the
 * vault's player table -- planting them is the identity defect this project has
 * spent the most time undoing.
 */
export function isAbbreviated(name: string): boolean {
  return name
    .split(/\s+/)
    .filter(Boolean)
    .some((tok) => /^[A-Za-z]\.?$/.test(tok));
}

/**
 * Rebuild a fixture's score from its events under the vault's own-goal rule.
 *
 * The sync never needs this — the score comes from the provider's published
 * value. It exists to test the claim made in `normaliseEvents` against real
 * fixtures, which is the check design principle 5 says to run before trusting
 * any new source's event log. A disagreement means the flip is wrong for that
 * fixture and its events must not be written.
 */
export function reconstructScore(f: SportmonksFixture): {
  published: string;
  reconstructed: string;
  ownGoals: number;
  agrees: boolean;
} {
  const home = f.participants?.find((p) => p.meta.location === 'home');
  const events = normaliseEvents(f);

  let h = 0;
  let a = 0;
  let ownGoals = 0;
  for (const e of events) {
    if (e.type !== 'GOAL' && e.type !== 'OWN_GOAL' && e.type !== 'PENALTY_GOAL') continue;
    const scoredByHome = home !== undefined && e.team.id === String(home.id);
    if (e.type === 'OWN_GOAL') ownGoals += 1;
    // `e.team` is already the scorer's own team, so an own goal counts against it.
    const countsForHome = e.type === 'OWN_GOAL' ? !scoredByHome : scoredByHome;
    if (countsForHome) h += 1;
    else a += 1;
  }

  const published = `${pickScore(f.scores, 'CURRENT', 'home') ?? '-'}-${
    pickScore(f.scores, 'CURRENT', 'away') ?? '-'
  }`;
  const reconstructed = `${h}-${a}`;
  return { published, reconstructed, ownGoals, agrees: published === reconstructed };
}
