import { getSessionToken } from './session';

const API_URL = process.env.API_URL ?? 'http://localhost:4010';

export class AdminApiError extends Error {
  constructor(
    readonly status: number,
    message: string,
    readonly body?: unknown,
  ) {
    super(message);
    this.name = 'AdminApiError';
  }
}

/**
 * Authenticated call to the backend admin API.
 *
 * Always server-side: the token never reaches the browser. A 401 here means the
 * session has expired or the account was deactivated, and callers redirect to
 * the login page rather than showing a broken screen.
 */
export async function adminFetch<T>(
  path: string,
  init: { method?: string; body?: unknown } = {},
): Promise<T> {
  const token = await getSessionToken();
  if (!token) throw new AdminApiError(401, 'Not signed in');

  let res: Response;
  try {
    res = await fetch(`${API_URL}${path}`, {
      method: init.method ?? 'GET',
      headers: {
        authorization: `Bearer ${token}`,
        ...(init.body !== undefined && { 'content-type': 'application/json' }),
      },
      ...(init.body !== undefined && { body: JSON.stringify(init.body) }),
      cache: 'no-store',
    });
  } catch (cause) {
    throw new AdminApiError(0, `Cannot reach the API at ${API_URL}`, cause);
  }

  const text = await res.text();
  const body: unknown = text ? JSON.parse(text) : null;

  if (!res.ok) {
    const message =
      body && typeof body === 'object' && 'error' in body
        ? String((body as { error: unknown }).error)
        : `Request failed with ${res.status}`;
    throw new AdminApiError(res.status, message, body);
  }
  return body as T;
}

export type AdminEdition = {
  editionId: number;
  competition: string;
  competitionType: string;
  country: string | null;
  season: string;
  matchCount: number;
  isPublished: boolean;
  publishedAt: string | null;
  flags: { INFO: number; WARNING: number; BLOCKER: number };
  openFlags: number;
  canPublish: boolean;
  issues: { key: string; count: number; label: string; severity: string }[];
};

export type AdminMatchRow = {
  id: number;
  kickoffAt: string | null;
  status: string;
  round: string | null;
  homeTeam: { id: number; name: string };
  awayTeam: { id: number; name: string };
  homeScore: number | null;
  awayScore: number | null;
  eventCount: number;
  unattributedGoals: number;
  openFlags: string[];
};

export type AdminMatchDetail = {
  id: number;
  kickoffAt: string | null;
  status: string;
  round: string | null;
  attendance: number | null;
  homeTeam: { id: number; name: string };
  awayTeam: { id: number; name: string };
  homeScore: number | null;
  awayScore: number | null;
  edition: { id: number; name: string; season: string; isPublished: boolean };
  events: {
    id: number;
    minute: number | null;
    addedTime: number | null;
    type: string;
    teamId: number | null;
    teamName: string | null;
    playerId: number | null;
    playerName: string | null;
  }[];
  openFlags: { id: number; entityType: string; entityId: number; severity: string; reason: string }[];
};

export type SquadPlayer = { id: number; name: string; position: string | null; teamIds: number[] };

export type Flag = {
  id: number;
  entityType: string;
  entityId: number;
  severity: string;
  reason: string;
  status: string;
  createdAt: string;
  createdBy: string | null;
  resolvedAt: string | null;
  resolvedBy: string | null;
  resolutionNote: string | null;
};

export type AdminCompetition = {
  id: number;
  name: string;
  type: string;
  tier: number | null;
  country: string | null;
  countryId: number | null;
  seasonCount: number;
  publishedCount: number;
  matchCount: number;
  editions: { editionId: number; season: string; isPublished: boolean; matchCount: number }[];
};

export type AdminEditionRow = {
  editionId: number;
  season: string;
  seasonId: number;
  matchCount: number;
  isPublished: boolean;
  publishedAt: string | null;
  openFlags: number;
  blockers: number;
  canPublish: boolean;
  issues: { key: string; count: number; label: string; severity: string }[];
};

export type EditionSummary = {
  edition: {
    editionId: number;
    competitionId: number;
    competition: string;
    competitionType: string;
    season: string;
    isPublished: boolean;
    publishedAt: string | null;
  };
  counts: {
    total: number;
    fullTime: number;
    scheduled: number;
    missingScore: number;
    withEvents: number;
    goals: number;
    teams: number;
  };
  events: { goalEvents: number; unattributed: number; cards: number };
  flags: { INFO: number; WARNING: number; BLOCKER: number };
  openFlags: number;
  canPublish: boolean;
  issues: { key: string; count: number; label: string; severity: string }[];
};

export type AdminReference = {
  countries: { id: number; name: string }[];
  seasons: { id: number; label: string }[];
  competitionTypes: string[];
};
