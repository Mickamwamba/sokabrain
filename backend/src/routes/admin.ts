import { Router } from 'express';
import { competitionDisplayName } from '../services/competitionName.js';
import { Prisma } from '@prisma/client';
import { z } from 'zod';
import { prisma } from '../db.js';
import { hashPassword, verifyPassword } from '../auth/password.js';
import { signAdminToken } from '../auth/jwt.js';
import { requireAdmin } from '../auth/middleware.js';
import { recordManualProvenance } from '../services/provenance.js';
import { editorialRouter } from './adminEditorial.js';
import { adminCompetitionsRouter } from './adminCompetitions.js';
import { manageRouter } from './adminManage.js';
import { careersRouter } from './adminCareers.js';
import { auditRouter } from './adminAudit.js';
import { adminKijiweniRouter } from './adminKijiweni.js';

export const adminRouter = Router();

const badRequest = (res: Parameters<typeof requireAdmin>[1], error: z.ZodError) =>
  res.status(400).json({ error: 'Invalid request body', details: z.treeifyError(error) });

const idParam = z.object({ id: z.coerce.number().int().positive() });

/**
 * Drop keys whose value is `undefined`.
 *
 * Zod's `.nullish()` yields `T | null | undefined`, but Prisma's XOR input types
 * treat an explicitly-undefined scalar FK as `never` under
 * exactOptionalPropertyTypes. Omitting the key entirely is also the correct
 * PATCH semantic: absent means "leave unchanged", explicit null means "clear".
 */
function definedOnly<T extends Record<string, unknown>>(
  obj: T,
): { [K in keyof T]: Exclude<T[K], undefined> } {
  return Object.fromEntries(
    Object.entries(obj).filter(([, v]) => v !== undefined),
  ) as { [K in keyof T]: Exclude<T[K], undefined> };
}

/* ------------------------------------------------------------------ auth -- */

const loginBody = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

adminRouter.post('/auth/login', async (req, res) => {
  const parsed = loginBody.safeParse(req.body);
  if (!parsed.success) return badRequest(res, parsed.error);

  const admin = await prisma.admins.findUnique({
    where: { email: parsed.data.email.toLowerCase() },
  });

  // Same response whether the email is unknown, the password is wrong, or the
  // account is deactivated — otherwise this endpoint enumerates valid accounts.
  const deny = () => res.status(401).json({ error: 'Invalid credentials' });
  if (!admin || !admin.is_active) {
    // Still spend the hashing time so a missing account is not detectably faster.
    await verifyPassword(parsed.data.password, `${'0'.repeat(32)}:${'0'.repeat(128)}`);
    return deny();
  }
  if (!(await verifyPassword(parsed.data.password, admin.password_hash))) return deny();

  await prisma.admins.update({
    where: { id: admin.id },
    data: { last_login_at: new Date() },
  });

  res.json({
    token: await signAdminToken({ adminId: admin.id, email: admin.email }),
    admin: { id: admin.id, email: admin.email, displayName: admin.display_name },
  });
});

adminRouter.get('/me', requireAdmin, (req, res) => res.json({ admin: req.admin }));

const passwordBody = z.object({
  currentPassword: z.string().min(1),
  newPassword: z.string().min(12, 'New password must be at least 12 characters'),
});

adminRouter.post('/me/password', requireAdmin, async (req, res) => {
  const parsed = passwordBody.safeParse(req.body);
  if (!parsed.success) return badRequest(res, parsed.error);

  const admin = await prisma.admins.findUnique({ where: { id: req.admin!.id } });
  if (!admin || !(await verifyPassword(parsed.data.currentPassword, admin.password_hash))) {
    return res.status(401).json({ error: 'Current password is incorrect' });
  }

  await prisma.admins.update({
    where: { id: admin.id },
    data: { password_hash: await hashPassword(parsed.data.newPassword) },
  });
  res.json({ ok: true });
});

/* ---------------------------------------------------------------- writes -- */
// Every create below runs in a transaction with its entity_source_map row, so a
// provenance failure rolls the write back rather than leaving an untracked row
// in the vault (design principle 1).

adminRouter.use(requireAdmin);

// Editorial routes (publishing, flags) share the same auth boundary.
adminRouter.use('/', editorialRouter);
adminRouter.use('/', adminCompetitionsRouter);
adminRouter.use('/', manageRouter);
adminRouter.use('/', careersRouter);
adminRouter.use('/', auditRouter);
adminRouter.use('/kijiweni', adminKijiweniRouter);

/**
 * Admin match list. Unlike the public one this ignores publication state —
 * the whole point of the dashboard is working on editions that aren't live yet.
 */
adminRouter.get('/matches', async (req, res) => {
  const q = z
    .object({
      editionId: z.coerce.number().int().positive().optional(),
      status: z.enum(MATCH_STATUSES).optional(),
      needsAttention: z.enum(['true', 'false']).optional(),
      // A full league season must fit in one request — the season view lists
      // every match, and silently truncating would hide the ones needing work.
      limit: z.coerce.number().int().min(1).max(500).default(50),
      offset: z.coerce.number().int().min(0).default(0),
    })
    .safeParse(req.query);
  if (!q.success) return res.status(400).json({ error: 'Invalid query' });
  const { editionId, status, needsAttention, limit, offset } = q.data;

  const where = {
    ...(editionId !== undefined && { competition_edition_id: editionId }),
    ...(status !== undefined && { status }),
    // "Needs attention" = finished but with no score recorded, which is the
    // single biggest gap in the migrated data.
    ...(needsAttention === 'true' && {
      status: 'FULL_TIME',
      OR: [{ home_score: null }, { away_score: null }],
    }),
  };

  const [total, rows] = await Promise.all([
    prisma.matches.count({ where }),
    prisma.matches.findMany({
      where,
      orderBy: [{ kickoff_at: 'desc' }, { id: 'desc' }],
      take: limit,
      skip: offset,
      include: {
        teams_matches_home_team_idToteams: { select: { id: true, name: true } },
        teams_matches_away_team_idToteams: { select: { id: true, name: true } },
        _count: { select: { match_events: true } },
      },
    }),
  ]);

  // Goals with no scorer named — the marker the match list shows so an editor
  // can see incomplete records without opening each match.
  const unattributed = await prisma.match_events.groupBy({
    by: ['match_id'],
    where: {
      match_id: { in: rows.map((r) => r.id) },
      type: { in: ['GOAL', 'PENALTY_GOAL'] },
      player_id: null,
    },
    _count: { _all: true },
  });
  const unattributedByMatch = new Map(unattributed.map((u) => [u.match_id, u._count._all]));

  const flags = await prisma.data_flags.findMany({
    where: { status: 'OPEN', entity_type: 'match', entity_id: { in: rows.map((r) => r.id) } },
    select: { entity_id: true, severity: true },
  });
  const flagsByMatch = new Map<number, string[]>();
  for (const f of flags) {
    const list = flagsByMatch.get(f.entity_id) ?? [];
    list.push(f.severity);
    flagsByMatch.set(f.entity_id, list);
  }

  res.json({
    total,
    limit,
    offset,
    matches: rows.map((m) => ({
      id: m.id,
      kickoffAt: m.kickoff_at,
      status: m.status,
      round: m.round,
      homeTeam: m.teams_matches_home_team_idToteams,
      awayTeam: m.teams_matches_away_team_idToteams,
      homeScore: m.home_score,
      awayScore: m.away_score,
      eventCount: m._count.match_events,
      unattributedGoals: unattributedByMatch.get(m.id) ?? 0,
      openFlags: flagsByMatch.get(m.id) ?? [],
    })),
  });
});

/** One match with its full event log, for the editing screen. */
adminRouter.get('/matches/:id', async (req, res) => {
  const params = idParam.safeParse(req.params);
  if (!params.success) return res.status(400).json({ error: 'id must be a positive integer' });

  const match = await prisma.matches.findUnique({
    where: { id: params.data.id },
    include: {
      teams_matches_home_team_idToteams: { select: { id: true, name: true } },
      teams_matches_away_team_idToteams: { select: { id: true, name: true } },
      competition_editions: {
        select: {
          id: true,
          is_published: true,
          competitions: { select: { name: true, countries: { select: { name: true } } } },
          seasons: { select: { label: true } },
        },
      },
      match_events: {
        orderBy: [{ minute: 'asc' }, { id: 'asc' }],
        include: {
          players_match_events_player_idToplayers: { select: { id: true, full_name: true } },
          teams: { select: { id: true, name: true } },
        },
      },
    },
  });
  if (!match) return res.status(404).json({ error: `No match with id ${params.data.id}` });

  const flags = await prisma.data_flags.findMany({
    where: {
      status: 'OPEN',
      OR: [
        { entity_type: 'match', entity_id: match.id },
        { entity_type: 'match_event', entity_id: { in: match.match_events.map((e) => e.id) } },
      ],
    },
  });

  res.json({
    match: {
      id: match.id,
      kickoffAt: match.kickoff_at,
      status: match.status,
      round: match.round,
      attendance: match.attendance,
      homeTeam: match.teams_matches_home_team_idToteams,
      awayTeam: match.teams_matches_away_team_idToteams,
      homeScore: match.home_score,
      awayScore: match.away_score,
      edition: {
        id: match.competition_editions.id,
        name: competitionDisplayName(
          match.competition_editions.competitions.name,
          match.competition_editions.competitions.countries?.name,
        ),
        season: match.competition_editions.seasons.label,
        isPublished: match.competition_editions.is_published,
      },
      events: match.match_events.map((e) => ({
        id: e.id,
        minute: e.minute,
        addedTime: e.added_time,
        type: e.type,
        teamId: e.team_id,
        teamName: e.teams?.name ?? null,
        playerId: e.player_id,
        playerName: e.players_match_events_player_idToplayers?.full_name ?? null,
      })),
      openFlags: flags.map((f) => ({
        id: f.id,
        entityType: f.entity_type,
        entityId: f.entity_id,
        severity: f.severity,
        reason: f.reason,
      })),
    },
  });
});

// Team and player create/read/update/delete live in adminManage.ts, alongside
// the rest of the reference-entity management.

const MATCH_STATUSES = [
  'SCHEDULED', 'LIVE', 'FULL_TIME', 'POSTPONED', 'ABANDONED', 'CANCELLED',
] as const;
const score = z.number().int().min(0).max(99);

const matchBody = z.object({
  competition_edition_id: z.number().int().positive(),
  group_id: z.number().int().positive().nullish(),
  round: z.string().max(30).nullish(),
  home_team_id: z.number().int().positive(),
  away_team_id: z.number().int().positive(),
  stadium_id: z.number().int().positive().nullish(),
  kickoff_at: z.coerce.date().nullish(),
  status: z.enum(MATCH_STATUSES),
  home_score: score.nullish(),
  away_score: score.nullish(),
  home_score_et: score.nullish(),
  away_score_et: score.nullish(),
  home_score_pens: score.nullish(),
  away_score_pens: score.nullish(),
  attendance: z.number().int().min(0).nullish(),
  referee_id: z.number().int().positive().nullish(),
});

/**
 * Create defaults a missing status to SCHEDULED; update must NOT, because a
 * zod `.default()` still fires under `.partial()` when the key is absent, which
 * would silently reset an existing match's status on any unrelated PATCH.
 */
const matchCreateBody = matchBody.extend({
  status: z.enum(MATCH_STATUSES).default('SCHEDULED'),
});
const matchUpdateBody = matchBody.partial();

/** A team cannot play itself; the DB has no constraint for this. */
const distinctTeams = (home?: number, away?: number) =>
  home === undefined || away === undefined || home !== away;

adminRouter.post('/matches', async (req, res) => {
  const parsed = matchCreateBody.safeParse(req.body);
  if (!parsed.success) return badRequest(res, parsed.error);
  if (!distinctTeams(parsed.data.home_team_id, parsed.data.away_team_id)) {
    return res.status(400).json({ error: 'home_team_id and away_team_id must differ' });
  }

  const match = await prisma.$transaction(async (tx) => {
    const data: Prisma.matchesUncheckedCreateInput = definedOnly(parsed.data);
    const created = await tx.matches.create({ data });
    await recordManualProvenance(tx, 'match', created.id);
    return created;
  });
  res.status(201).json({ match });
});

/**
 * Correct a match, most often to fill in a score the legacy migration lacks.
 *
 * The stored score is authoritative (design principle 3) and is NOT recomputed
 * from the event log here — nor does adding an event silently change it. The two
 * are edited deliberately and separately so a partial event log can never
 * quietly rewrite a known-correct result.
 */
adminRouter.patch('/matches/:id', async (req, res) => {
  const params = idParam.safeParse(req.params);
  if (!params.success) return res.status(400).json({ error: 'id must be a positive integer' });
  const parsed = matchUpdateBody.safeParse(req.body);
  if (!parsed.success) return badRequest(res, parsed.error);

  const existing = await prisma.matches.findUnique({ where: { id: params.data.id } });
  if (!existing) return res.status(404).json({ error: `No match with id ${params.data.id}` });

  const home = parsed.data.home_team_id ?? existing.home_team_id;
  const away = parsed.data.away_team_id ?? existing.away_team_id;
  if (home === away) {
    return res.status(400).json({ error: 'home_team_id and away_team_id must differ' });
  }

  const match = await prisma.$transaction(async (tx) => {
    const data: Prisma.matchesUncheckedUpdateInput = definedOnly(parsed.data);
    const updated = await tx.matches.update({ where: { id: params.data.id }, data });
    await recordManualProvenance(tx, 'match', updated.id);
    return updated;
  });
  res.json({ match });
});

const EVENT_TYPES = [
  'GOAL', 'OWN_GOAL', 'PENALTY_GOAL', 'PENALTY_MISS', 'YELLOW_CARD',
  'SECOND_YELLOW', 'RED_CARD', 'SUBSTITUTION', 'VAR_REVIEW', 'ASSIST',
] as const;

const eventBody = z.object({
  team_id: z.number().int().positive(),
  player_id: z.number().int().positive().nullish(),
  related_player_id: z.number().int().positive().nullish(),
  minute: z.number().int().min(0).max(130).nullish(),
  added_time: z.number().int().min(0).max(30).nullish(),
  type: z.enum(EVENT_TYPES),
  // jsonb in the schema (unused by the migration, NULL on all 3,222 legacy rows).
  detail: z.record(z.string(), z.unknown()).nullish(),
});

/**
 * Add an event to a match — the main tool for filling the gaps in the legacy
 * event log (~27% of goals have no scorer recorded).
 *
 * `team_id` must be one of the two teams in the match. For an OWN_GOAL it is
 * the team the scoring player plays FOR, not the team the goal counts for
 * (design principle 5) — the read side is what applies that inversion.
 */
adminRouter.post('/matches/:id/events', async (req, res) => {
  const params = idParam.safeParse(req.params);
  if (!params.success) return res.status(400).json({ error: 'id must be a positive integer' });
  const parsed = eventBody.safeParse(req.body);
  if (!parsed.success) return badRequest(res, parsed.error);

  const match = await prisma.matches.findUnique({
    where: { id: params.data.id },
    select: { id: true, home_team_id: true, away_team_id: true },
  });
  if (!match) return res.status(404).json({ error: `No match with id ${params.data.id}` });

  if (![match.home_team_id, match.away_team_id].includes(parsed.data.team_id)) {
    return res.status(400).json({
      error: `team_id ${parsed.data.team_id} did not play in match ${match.id}`,
      teamsInMatch: [match.home_team_id, match.away_team_id],
    });
  }

  if (parsed.data.player_id != null) {
    const player = await prisma.players.findUnique({
      where: { id: parsed.data.player_id },
      select: { id: true },
    });
    if (!player) {
      return res.status(400).json({ error: `No player with id ${parsed.data.player_id}` });
    }
  }

  const event = await prisma.$transaction(async (tx) => {
    const { detail, ...rest } = definedOnly(parsed.data);
    const data: Prisma.match_eventsUncheckedCreateInput = {
      ...rest,
      match_id: match.id,
      // `detail` is jsonb: Prisma needs DbNull to write a SQL NULL, not `null`.
      ...(detail !== undefined && {
        detail: detail === null ? Prisma.DbNull : (detail as Prisma.InputJsonValue),
      }),
    };
    const created = await tx.match_events.create({ data });
    await recordManualProvenance(tx, 'match_event', created.id);
    return created;
  });

  res.status(201).json({
    event,
    // Made explicit so a caller is never surprised that the table did not move.
    note: 'Stored match score is unchanged. Update it via PATCH /api/admin/matches/:id.',
  });
});

const eventPatchBody = z.object({
  player_id: z.number().int().positive().nullish(),
  minute: z.number().int().min(0).max(130).nullish(),
  type: z.enum(EVENT_TYPES).optional(),
  team_id: z.number().int().positive().optional(),
});

/**
 * Update one event. The common case is naming a scorer on a goal that was
 * migrated without one — 42 such goals exist in the 2017/18 season alone.
 */
adminRouter.patch('/matches/:id/events/:eventId', async (req, res) => {
  const params = z
    .object({
      id: z.coerce.number().int().positive(),
      eventId: z.coerce.number().int().positive(),
    })
    .safeParse(req.params);
  if (!params.success) return res.status(400).json({ error: 'ids must be positive integers' });
  const parsed = eventPatchBody.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'Invalid request body', details: z.treeifyError(parsed.error) });
  }

  const event = await prisma.match_events.findUnique({
    where: { id: params.data.eventId },
    select: { id: true, match_id: true },
  });
  if (!event || event.match_id !== params.data.id) {
    return res.status(404).json({ error: 'No such event on that match' });
  }

  // Validate the player exists before writing, so an unknown id is a clean 400
  // rather than a foreign-key violation surfacing as a 500.
  if (parsed.data.player_id != null) {
    const player = await prisma.players.findUnique({
      where: { id: parsed.data.player_id },
      select: { id: true },
    });
    if (!player) {
      return res.status(400).json({ error: `No player with id ${parsed.data.player_id}` });
    }
  }

  if (parsed.data.team_id !== undefined) {
    const match = await prisma.matches.findUniqueOrThrow({
      where: { id: event.match_id },
      select: { home_team_id: true, away_team_id: true },
    });
    if (![match.home_team_id, match.away_team_id].includes(parsed.data.team_id)) {
      return res.status(400).json({ error: 'team_id did not play in this match' });
    }
  }

  const updated = await prisma.$transaction(async (tx) => {
    const data: Prisma.match_eventsUncheckedUpdateInput = definedOnly(parsed.data);
    const row = await tx.match_events.update({ where: { id: event.id }, data });
    await recordManualProvenance(tx, 'match_event', row.id);
    return row;
  });
  res.json({ event: updated });
});

/**
 * Players eligible to be named on this match: anyone with a stint at either
 * club, plus anyone already recorded in the match. Keeps the scorer picker to
 * plausible names instead of all 1,639 players.
 */
adminRouter.get('/matches/:id/squad', async (req, res) => {
  const params = idParam.safeParse(req.params);
  if (!params.success) return res.status(400).json({ error: 'id must be a positive integer' });

  const match = await prisma.matches.findUnique({
    where: { id: params.data.id },
    select: { id: true, home_team_id: true, away_team_id: true },
  });
  if (!match) return res.status(404).json({ error: `No match with id ${params.data.id}` });

  const teamIds = [match.home_team_id, match.away_team_id];
  const players = await prisma.players.findMany({
    where: {
      OR: [
        { player_team_stints: { some: { team_id: { in: teamIds } } } },
        { match_lineups: { some: { match_id: match.id } } },
        { match_events_match_events_player_idToplayers: { some: { match_id: match.id } } },
      ],
    },
    select: {
      id: true,
      full_name: true,
      position: true,
      player_team_stints: { select: { team_id: true }, where: { team_id: { in: teamIds } } },
    },
    orderBy: { full_name: 'asc' },
  });

  res.json({
    squad: players.map((p) => ({
      id: p.id,
      name: p.full_name,
      position: p.position,
      teamIds: [...new Set(p.player_team_stints.map((s) => s.team_id))],
    })),
  });
});

adminRouter.delete('/matches/:id/events/:eventId', async (req, res) => {
  const params = z
    .object({
      id: z.coerce.number().int().positive(),
      eventId: z.coerce.number().int().positive(),
    })
    .safeParse(req.params);
  if (!params.success) return res.status(400).json({ error: 'ids must be positive integers' });

  const event = await prisma.match_events.findUnique({
    where: { id: params.data.eventId },
    select: { id: true, match_id: true },
  });
  if (!event || event.match_id !== params.data.id) {
    return res.status(404).json({ error: 'No such event on that match' });
  }

  await prisma.$transaction(async (tx) => {
    await tx.match_events.delete({ where: { id: event.id } });
    await tx.entity_source_map.deleteMany({
      where: { entity_type: 'match_event', entity_id: event.id },
    });
  });
  res.json({ ok: true, deletedEventId: event.id });
});
