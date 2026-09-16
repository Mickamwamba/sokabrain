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
  format: string | null;
  numTeams: number | null;
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

/* ------------------------------------------------ reference-entity management -- */

export type Lookups = {
  countries: { id: number; name: string }[];
  seasons: { id: number; label: string }[];
  stadiums: { id: number; name: string; city: string | null }[];
  competitions: { id: number; name: string }[];
  competitionTypes: string[];
  editionFormats: string[];
};

export type Paged<K extends string, T> = { total: number; page: number; pageSize: number } & Record<K, T[]>;

export type Usage = { label: string; count: number }[];

export type PlayerRow = {
  id: number;
  fullName: string;
  position: string | null;
  dob: string | null;
  nationality: string | null;
  teams: { id: number; name: string }[];
  /** The club spell running today; 'FREE_AGENT' with only past club spells; null with none recorded. */
  currentClub: { id: number; name: string } | 'FREE_AGENT' | null;
  events: number;
  appearances: number;
};

export type PlayerRecord = {
  id: number;
  full_name: string;
  first_name: string | null;
  last_name: string | null;
  dob: string | null;
  nationality_id: number | null;
  position: string | null;
  height_cm: number | null;
  preferred_foot: string | null;
  player_team_stints: {
    id: number;
    start_date: string | null;
    end_date: string | null;
    shirt_number: number | null;
    teams: { id: number; name: string };
  }[];
};

export type TeamRow = {
  id: number;
  name: string;
  shortName: string | null;
  type: 'CLUB' | 'NATIONAL';
  country: string;
  stadium: string | null;
  matches: number;
  seasons: number;
  players: number;
};

export type TeamRecord = {
  id: number;
  name: string;
  short_name: string | null;
  type: 'CLUB' | 'NATIONAL';
  country_id: number;
  stadium_id: number | null;
};

export type SeasonRow = {
  id: number;
  label: string;
  startDate: string | null;
  endDate: string | null;
  editions: number;
  published: number;
  competitions: string[];
};

export type Participants = {
  edition: {
    id: number;
    competitionId: number;
    competition: string;
    competitionType: string;
    season: string;
    numTeams: number | null;
    isPublished: boolean;
  };
  groups: { id: number; name: string }[];
  participants: {
    teamId: number;
    name: string;
    type: string;
    country: string;
    group: { id: number; name: string } | null;
    matches: number;
  }[];
  unlisted: { id: number; name: string }[];
};

export type AdminAccount = {
  id: number;
  email: string;
  displayName: string;
  isActive: boolean;
  createdAt: string;
  lastLoginAt: string | null;
};

/* ---------------------------------------------------------------- careers -- */

export type SpellType = 'PERMANENT' | 'LOAN' | 'FREE' | 'YOUTH';

export type CareerSpell = {
  id: number;
  team: { id: number; name: string; type: 'CLUB' | 'NATIONAL' };
  start: string;
  end: string | null;
  type: SpellType | null;
  shirtNumber: number | null;
  fee: string | null;
  /** Other spells this one contradicts. */
  conflictsWith: number[];
  /** Set on an open spell a later one contradicts: the end date that fixes it. */
  staleSuggestedEnd: string | null;
};

export type CareerStatus =
  | { kind: 'AT_CLUB'; club: CareerSpell; loan: CareerSpell | null }
  | { kind: 'ON_LOAN_ONLY'; loan: CareerSpell }
  | { kind: 'FREE_AGENT'; lastClub: CareerSpell }
  | { kind: 'NO_CLUB_HISTORY' };

export type Career = {
  player: { id: number; name: string };
  today: string;
  status: CareerStatus;
  clubSpells: CareerSpell[];
  nationalSpells: CareerSpell[];
};

export type SquadEntry = {
  spellId: number;
  player: { id: number; name: string; position: string | null };
  start: string | null;
  end: string | null;
  type: SpellType | null;
  shirtNumber: number | null;
};

export type Squad = { today: string; current: SquadEntry[]; former: SquadEntry[] };

export type TeamOption = { id: number; name: string; type: 'CLUB' | 'NATIONAL' };

export type MoveKind = 'TRANSFER' | 'LOAN' | 'FIRST_CLUB' | 'RELEASE';

export type MoveSide = {
  spellId: number;
  team: { id: number; name: string };
  start: string;
  end: string | null;
  type: SpellType | null;
  shirtNumber: number | null;
  fee: string | null;
};

export type MoveRow = {
  key: string;
  kind: MoveKind;
  date: string;
  player: { id: number; name: string };
  from: MoveSide | null;
  to: MoveSide | null;
  /** The spell an undo would carry on again, if any. */
  reopens: { spellId: number; team: { id: number; name: string } } | null;
};

export type TransferFeed = {
  today: string;
  total: number;
  page: number;
  pageSize: number;
  counts: Record<MoveKind, number>;
  summary: { movesLast30Days: number; activeLoans: number; freeAgents: number };
  moves: MoveRow[];
};

export type PlayerHit = { id: number; name: string; club: string };

/* ------------------------------------------------------------ data audit -- */

export type AuditSeverity = 'INFO' | 'WARNING' | 'CRITICAL';
export type FindingStatus = 'OPEN' | 'FIXED' | 'ACCEPTED' | 'RESOLVED';
export type AuditArea = 'Scores' | 'Events' | 'Fixtures' | 'Seasons' | 'Careers' | 'Identity';

export type AuditCheck = { key: string; label: string; area: AuditArea; severity: AuditSeverity; describes: string };

export type AuditRun = {
  id: number;
  status: 'RUNNING' | 'COMPLETED' | 'FAILED';
  startedAt: string;
  finishedAt: string | null;
  startedBy: string | null;
  scope: { competitions: string[]; editions: string[]; includeCareers: boolean };
  checksRun: number | null;
  detected: number | null;
  opened: number | null;
  reopened: number | null;
  resolved: number | null;
  error: string | null;
};

export type AuditFinding = {
  id: number;
  check: { key: string; label: string; area: AuditArea | null };
  severity: AuditSeverity;
  status: FindingStatus;
  detail: string;
  entity: { type: 'match' | 'player' | 'competition_edition'; id: number; label: string; date: string | null };
  edition: { id: number; competitionId: number; label: string } | null;
  firstSeenRunId: number;
  lastSeenRunId: number;
  resolvedRunId: number | null;
  reviewedBy: string | null;
  reviewedAt: string | null;
  reviewNote: string | null;
  timesReopened: number;
  updatedAt: string;
};

export type AuditFindings = {
  total: number;
  page: number;
  pageSize: number;
  counts: {
    status: Partial<Record<FindingStatus, number>>;
    severity: Partial<Record<AuditSeverity, number>>;
    check: Record<string, number>;
  };
  findings: AuditFinding[];
};
