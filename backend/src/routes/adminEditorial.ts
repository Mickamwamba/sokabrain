import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../db.js';
import {
  FLAG_ENTITIES,
  SEVERITIES,
  editionFlagSummary,
  publishEdition,
  suggestedIssues,
  unpublishEdition,
} from '../services/flags.js';

/**
 * Editorial routes: what the public can see, and what still needs attention.
 * Mounted under /api/admin, behind the same auth as the other write routes.
 */
export const editorialRouter = Router();

const idParam = z.object({ id: z.coerce.number().int().positive() });

/** Every edition with its publication state, flag counts and data-quality stats. */
editorialRouter.get('/editions', async (_req, res) => {
  const editions = await prisma.competition_editions.findMany({
    include: {
      competitions: {
        select: { name: true, type: true, tier: true, countries: { select: { name: true } } },
      },
      seasons: { select: { label: true } },
      _count: { select: { matches: true } },
    },
  });

  const rows = await Promise.all(
    editions.map(async (e) => {
      const [flags, issues] = await Promise.all([
        editionFlagSummary(e.id),
        suggestedIssues(e.id),
      ]);
      return {
        editionId: e.id,
        competition: e.competitions.name,
        competitionType: e.competitions.type,
        country: e.competitions.countries?.name ?? null,
        season: e.seasons.label,
        matchCount: e._count.matches,
        isPublished: e.is_published,
        publishedAt: e.published_at,
        flags: flags.bySeverity,
        openFlags: flags.total,
        canPublish: flags.bySeverity.BLOCKER === 0,
        issues,
      };
    }),
  );

  rows.sort((a, b) => b.matchCount - a.matchCount);
  res.json({ editions: rows });
});

editorialRouter.post('/editions/:id/publish', async (req, res) => {
  const params = idParam.safeParse(req.params);
  if (!params.success) return res.status(400).json({ error: 'id must be a positive integer' });

  const exists = await prisma.competition_editions.findUnique({
    where: { id: params.data.id },
    select: { id: true },
  });
  if (!exists) return res.status(404).json({ error: `No edition with id ${params.data.id}` });

  const result = await publishEdition(params.data.id, req.admin!.id);
  if (!result.ok) {
    // 409: the request is valid, the edition's state forbids it.
    return res.status(409).json({ error: result.reason, blockers: result.blockers });
  }
  res.json({ ok: true, isPublished: true });
});

editorialRouter.post('/editions/:id/unpublish', async (req, res) => {
  const params = idParam.safeParse(req.params);
  if (!params.success) return res.status(400).json({ error: 'id must be a positive integer' });

  const exists = await prisma.competition_editions.findUnique({
    where: { id: params.data.id },
    select: { id: true },
  });
  if (!exists) return res.status(404).json({ error: `No edition with id ${params.data.id}` });

  await unpublishEdition(params.data.id);
  res.json({ ok: true, isPublished: false });
});

/* ----------------------------------------------------------------- flags -- */

const flagQuery = z.object({
  status: z.enum(['OPEN', 'RESOLVED']).default('OPEN'),
  entityType: z.enum(FLAG_ENTITIES).optional(),
  entityId: z.coerce.number().int().positive().optional(),
  editionId: z.coerce.number().int().positive().optional(),
  limit: z.coerce.number().int().min(1).max(200).default(100),
});

editorialRouter.get('/flags', async (req, res) => {
  const q = flagQuery.safeParse(req.query);
  if (!q.success) return res.status(400).json({ error: 'Invalid query', details: z.treeifyError(q.error) });
  const { status, entityType, entityId, editionId, limit } = q.data;

  // Scoping by edition means "this edition and everything in it".
  let scope: object = {};
  if (editionId !== undefined) {
    const matchIds = (
      await prisma.matches.findMany({
        where: { competition_edition_id: editionId },
        select: { id: true },
      })
    ).map((m) => m.id);
    const eventIds =
      matchIds.length === 0
        ? []
        : (
            await prisma.match_events.findMany({
              where: { match_id: { in: matchIds } },
              select: { id: true },
            })
          ).map((e) => e.id);
    scope = {
      OR: [
        { entity_type: 'competition_edition', entity_id: editionId },
        { entity_type: 'match', entity_id: { in: matchIds } },
        { entity_type: 'match_event', entity_id: { in: eventIds } },
      ],
    };
  }

  const flags = await prisma.data_flags.findMany({
    where: {
      status,
      ...(entityType !== undefined && { entity_type: entityType }),
      ...(entityId !== undefined && { entity_id: entityId }),
      ...scope,
    },
    include: {
      admins_data_flags_created_byToadmins: { select: { display_name: true } },
      admins_data_flags_resolved_byToadmins: { select: { display_name: true } },
    },
    orderBy: [{ severity: 'asc' }, { created_at: 'desc' }],
    take: limit,
  });

  res.json({
    flags: flags.map((f) => ({
      id: f.id,
      entityType: f.entity_type,
      entityId: f.entity_id,
      severity: f.severity,
      reason: f.reason,
      status: f.status,
      createdAt: f.created_at,
      createdBy: f.admins_data_flags_created_byToadmins?.display_name ?? null,
      resolvedAt: f.resolved_at,
      resolvedBy: f.admins_data_flags_resolved_byToadmins?.display_name ?? null,
      resolutionNote: f.resolution_note,
    })),
  });
});

const createFlagBody = z.object({
  entityType: z.enum(FLAG_ENTITIES),
  entityId: z.number().int().positive(),
  severity: z.enum(SEVERITIES).default('WARNING'),
  reason: z.string().min(1).max(2000),
});

editorialRouter.post('/flags', async (req, res) => {
  const body = createFlagBody.safeParse(req.body);
  if (!body.success) {
    return res.status(400).json({ error: 'Invalid request body', details: z.treeifyError(body.error) });
  }
  const { entityType, entityId, severity, reason } = body.data;

  // Refuse to flag something that doesn't exist — a dangling flag is noise
  // nobody can act on.
  const exists = await entityExists(entityType, entityId);
  if (!exists) {
    return res.status(404).json({ error: `No ${entityType} with id ${entityId}` });
  }

  const flag = await prisma.data_flags.create({
    data: {
      entity_type: entityType,
      entity_id: entityId,
      severity,
      reason,
      created_by: req.admin!.id,
    },
  });
  res.status(201).json({ flag });
});

const resolveBody = z.object({ note: z.string().max(2000).optional() });

editorialRouter.post('/flags/:id/resolve', async (req, res) => {
  const params = idParam.safeParse(req.params);
  if (!params.success) return res.status(400).json({ error: 'id must be a positive integer' });
  const body = resolveBody.safeParse(req.body ?? {});
  if (!body.success) return res.status(400).json({ error: 'Invalid request body' });

  const flag = await prisma.data_flags.findUnique({ where: { id: params.data.id } });
  if (!flag) return res.status(404).json({ error: `No flag with id ${params.data.id}` });
  if (flag.status === 'RESOLVED') {
    return res.status(409).json({ error: 'Flag is already resolved' });
  }

  const updated = await prisma.data_flags.update({
    where: { id: flag.id },
    data: {
      status: 'RESOLVED',
      resolved_by: req.admin!.id,
      resolved_at: new Date(),
      ...(body.data.note !== undefined && { resolution_note: body.data.note }),
    },
  });
  res.json({ flag: updated });
});

editorialRouter.get('/editions/:id/issues', async (req, res) => {
  const params = idParam.safeParse(req.params);
  if (!params.success) return res.status(400).json({ error: 'id must be a positive integer' });
  res.json({
    issues: await suggestedIssues(params.data.id),
    flags: await editionFlagSummary(params.data.id),
  });
});

async function entityExists(entityType: string, id: number): Promise<boolean> {
  switch (entityType) {
    case 'competition_edition':
      return !!(await prisma.competition_editions.findUnique({ where: { id }, select: { id: true } }));
    case 'match':
      return !!(await prisma.matches.findUnique({ where: { id }, select: { id: true } }));
    case 'match_event':
      return !!(await prisma.match_events.findUnique({ where: { id }, select: { id: true } }));
    case 'team':
      return !!(await prisma.teams.findUnique({ where: { id }, select: { id: true } }));
    case 'player':
      return !!(await prisma.players.findUnique({ where: { id }, select: { id: true } }));
    default:
      return false;
  }
}
