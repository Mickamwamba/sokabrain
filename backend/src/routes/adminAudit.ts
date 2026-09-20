import { Router } from 'express';
import { competitionDisplayName } from '../services/competitionName.js';
import { z } from 'zod';
import { prisma } from '../db.js';
import { CHECKS } from '../services/audit/checks.js';
import { AuditBusyError, findingWhere, runAudit } from '../services/audit/run.js';

/**
 * Data audit: run the checks over a scope, list what they found, and review it.
 * The rules live in services/audit; this file is the HTTP surface.
 */
export const auditRouter = Router();

const ids = z.array(z.number().int().positive()).max(500).optional();

auditRouter.get('/audit/checks', (_req, res) => res.json({ checks: CHECKS }));

auditRouter.post('/audit/runs', async (req, res) => {
  const parsed = z.object({ competitionIds: ids, editionIds: ids, includeCareers: z.boolean().default(false) }).safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid audit scope' });
  try {
    const run = await runAudit(parsed.data, req.admin!.id);
    res.status(201).json({ run });
  } catch (err) {
    if (err instanceof AuditBusyError) return res.status(409).json({ error: err.message });
    throw err;
  }
});

auditRouter.get('/audit/runs', async (req, res) => {
  const limit = Math.min(50, Math.max(1, Number(req.query.limit) || 15));
  const runs = await prisma.audit_runs.findMany({
    orderBy: { id: 'desc' },
    take: limit,
    include: { admins: { select: { display_name: true } } },
  });
  // Name the scope, so history reads "Premier League 2018/19" and not "[6]".
  const compIds = [...new Set(runs.flatMap((r) => r.scope_competition_ids))];
  const edIds = [...new Set(runs.flatMap((r) => r.scope_edition_ids))];
  const [comps, eds] = await Promise.all([
    prisma.competitions.findMany({
      where: { id: { in: compIds } },
      select: { id: true, name: true, countries: { select: { name: true } } },
    }),
    prisma.competition_editions.findMany({
      where: { id: { in: edIds } },
      select: {
        id: true,
        competitions: { select: { name: true, countries: { select: { name: true } } } },
        seasons: { select: { label: true } },
      },
    }),
  ]);
  const compName = new Map(
    comps.map((c) => [c.id, competitionDisplayName(c.name, c.countries?.name)]),
  );
  const edName = new Map(
    eds.map((e) => [
      e.id,
      `${competitionDisplayName(e.competitions.name, e.competitions.countries?.name)} ${e.seasons.label}`,
    ]),
  );
  res.json({
    runs: runs.map((r) => ({
      id: r.id,
      status: r.status,
      startedAt: r.started_at,
      finishedAt: r.finished_at,
      startedBy: r.admins?.display_name ?? null,
      scope: {
        competitions: r.scope_competition_ids.map((i) => compName.get(i) ?? `#${i}`),
        editions: r.scope_edition_ids.map((i) => edName.get(i) ?? `#${i}`),
        includeCareers: r.include_careers,
      },
      checksRun: r.checks_run,
      detected: r.detected,
      opened: r.opened,
      reopened: r.reopened,
      resolved: r.resolved,
      error: r.error,
    })),
  });
});

const filterQuery = z.object({
  status: z.enum(['ACTIVE', 'OPEN', 'FIXED', 'ACCEPTED', 'RESOLVED', 'ALL']).default('ACTIVE'),
  severity: z.enum(['INFO', 'WARNING', 'CRITICAL']).optional(),
  checkKey: z.string().max(40).optional(),
  area: z.enum(['Scores', 'Events', 'Fixtures', 'Seasons', 'Careers']).optional(),
  competitionId: z.coerce.number().int().positive().optional(),
  editionId: z.coerce.number().int().positive().optional(),
  entityType: z.enum(['match', 'player', 'competition_edition']).optional(),
  entityId: z.coerce.number().int().positive().optional(),
});

auditRouter.get('/audit/findings', async (req, res) => {
  const parsed = filterQuery
    .extend({
      page: z.coerce.number().int().min(1).default(1),
      pageSize: z.coerce.number().int().min(1).max(100).default(40),
    })
    .safeParse(req.query);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid filter' });
  const { page, pageSize, ...filter } = parsed.data;
  const where = findingWhere(filter);

  const [total, rows, byStatus, bySeverity, byCheck] = await Promise.all([
    prisma.audit_findings.count({ where }),
    prisma.audit_findings.findMany({
      where,
      orderBy: [{ updated_at: 'desc' }, { id: 'desc' }],
      skip: (page - 1) * pageSize,
      take: pageSize,
      include: {
        competition_editions: {
          select: {
            id: true,
            competition_id: true,
            competitions: { select: { name: true, countries: { select: { name: true } } } },
            seasons: { select: { label: true } },
          },
        },
        admins: { select: { display_name: true } },
      },
    }),
    // Each count ignores its own dimension, so a tab always shows what
    // choosing it would give.
    prisma.audit_findings.groupBy({ by: ['status'], where: findingWhere(filter, { ignore: ['status'] }), _count: true }),
    prisma.audit_findings.groupBy({ by: ['severity'], where: findingWhere(filter, { ignore: ['severity'] }), _count: true }),
    prisma.audit_findings.groupBy({ by: ['check_key'], where: findingWhere(filter, { ignore: ['checkKey', 'area'] }), _count: true }),
  ]);

  // Label what each finding is about.
  const matchIds = rows.filter((r) => r.entity_type === 'match').map((r) => r.entity_id);
  const playerIds = rows.filter((r) => r.entity_type === 'player').map((r) => r.entity_id);
  const [matches, players] = await Promise.all([
    prisma.matches.findMany({
      where: { id: { in: matchIds } },
      select: {
        id: true, kickoff_at: true, home_score: true, away_score: true,
        teams_matches_home_team_idToteams: { select: { name: true } },
        teams_matches_away_team_idToteams: { select: { name: true } },
      },
    }),
    prisma.players.findMany({ where: { id: { in: playerIds } }, select: { id: true, full_name: true } }),
  ]);
  const matchLabel = new Map(matches.map((m) => [m.id, {
    label: `${m.teams_matches_home_team_idToteams.name} v ${m.teams_matches_away_team_idToteams.name}`,
    date: m.kickoff_at,
  }]));
  const playerName = new Map(players.map((p) => [p.id, p.full_name]));
  const checkByKey = new Map(CHECKS.map((c) => [c.key, c]));

  res.json({
    total, page, pageSize,
    counts: {
      status: Object.fromEntries(byStatus.map((s) => [s.status, s._count])),
      severity: Object.fromEntries(bySeverity.map((s) => [s.severity, s._count])),
      check: Object.fromEntries(byCheck.map((s) => [s.check_key, s._count])),
    },
    findings: rows.map((r) => {
      const ed = r.competition_editions;
      const edition = ed
        ? {
            id: ed.id,
            competitionId: ed.competition_id,
            label:
              `${competitionDisplayName(ed.competitions.name, ed.competitions.countries?.name)} ` +
              `${ed.seasons.label}`,
          }
        : null;
      const entity =
        r.entity_type === 'match'
          ? { type: 'match', id: r.entity_id, label: matchLabel.get(r.entity_id)?.label ?? `Match #${r.entity_id} (deleted)`, date: matchLabel.get(r.entity_id)?.date ?? null }
          : r.entity_type === 'player'
            ? { type: 'player', id: r.entity_id, label: playerName.get(r.entity_id) ?? `Player #${r.entity_id} (deleted)`, date: null }
            : { type: 'competition_edition', id: r.entity_id, label: edition?.label ?? `Season #${r.entity_id}`, date: null };
      return {
        id: r.id,
        check: { key: r.check_key, label: checkByKey.get(r.check_key)?.label ?? r.check_key, area: checkByKey.get(r.check_key)?.area ?? null },
        severity: r.severity,
        status: r.status,
        detail: r.detail,
        entity,
        edition,
        firstSeenRunId: r.first_seen_run_id,
        lastSeenRunId: r.last_seen_run_id,
        resolvedRunId: r.resolved_run_id,
        reviewedBy: r.admins?.display_name ?? null,
        reviewedAt: r.reviewed_at,
        reviewNote: r.review_note,
        timesReopened: r.times_reopened,
        updatedAt: r.updated_at,
      };
    }),
  });
});

/**
 * An admin's decision on a finding. FIXED says "I corrected the data" — the
 * next run confirms it or reopens it. ACCEPTED says "this is as good as the
 * sources get" — it stays closed while the problem is unchanged. OPEN takes a
 * decision back.
 */
const review = z.object({
  decision: z.enum(['FIXED', 'ACCEPTED', 'OPEN']),
  note: z.string().trim().max(1000).optional(),
});

auditRouter.post('/audit/findings/:id/review', async (req, res) => {
  const id = Number(req.params.id);
  const parsed = review.safeParse(req.body);
  if (!Number.isInteger(id) || id < 1 || !parsed.success) return res.status(400).json({ error: 'Invalid review' });
  const finding = await prisma.audit_findings.findUnique({ where: { id }, select: { status: true } });
  if (!finding) return res.status(404).json({ error: `No finding with id ${id}` });
  if (finding.status === 'RESOLVED' && parsed.data.decision !== 'OPEN') {
    return res.status(409).json({ error: 'The last audit run already found this resolved.' });
  }
  if (parsed.data.decision === 'ACCEPTED' && !parsed.data.note) {
    return res.status(400).json({ error: 'Say why it is being accepted — the next editor will want to know.' });
  }
  await prisma.audit_findings.update({
    where: { id },
    data: {
      status: parsed.data.decision,
      reviewed_by: req.admin!.id,
      reviewed_at: new Date(),
      review_note: parsed.data.note ?? null,
      updated_at: new Date(),
      ...(parsed.data.decision === 'OPEN' && { resolved_run_id: null }),
    },
  });
  res.json({ ok: true });
});

/** The same decision for every active finding matching a filter. */
auditRouter.post('/audit/findings/review-bulk', async (req, res) => {
  const parsed = filterQuery.extend(review.shape).extend({ expectedCount: z.number().int().min(1) }).safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid bulk review' });
  const { decision, note, expectedCount, ...filter } = parsed.data;
  if (decision === 'OPEN') return res.status(400).json({ error: 'Reopen findings one at a time.' });
  if (decision === 'ACCEPTED' && !note) return res.status(400).json({ error: 'Say why these are being accepted.' });

  // Only undecided findings; never overwrite another admin's decision in bulk.
  const where = { ...findingWhere({ ...filter, status: 'OPEN' }) };
  const count = await prisma.audit_findings.count({ where });
  // The editor confirmed a number; if the data moved since, make them look again.
  if (count !== expectedCount) {
    return res.status(409).json({ error: `The filter now matches ${count} open findings, not ${expectedCount}. Reload and review again.` });
  }
  const { count: updated } = await prisma.audit_findings.updateMany({
    where,
    data: { status: decision, reviewed_by: req.admin!.id, reviewed_at: new Date(), review_note: note ?? null, updated_at: new Date() },
  });
  res.json({ ok: true, updated });
});

/** Raise a BLOCKER flag from a finding, so its season can't be published over it. */
auditRouter.post('/audit/findings/:id/escalate', async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id < 1) return res.status(400).json({ error: 'Invalid finding id' });
  const f = await prisma.audit_findings.findUnique({ where: { id } });
  if (!f) return res.status(404).json({ error: `No finding with id ${id}` });
  const check = CHECKS.find((c) => c.key === f.check_key);
  const reason = `[Audit: ${check?.label ?? f.check_key}] ${f.detail}`;

  const existing = await prisma.data_flags.findFirst({
    where: { entity_type: f.entity_type, entity_id: f.entity_id, status: 'OPEN', reason },
    select: { id: true },
  });
  if (existing) return res.status(409).json({ error: `Already escalated: flag #${existing.id} is open for this.` });

  const flag = await prisma.data_flags.create({
    data: { entity_type: f.entity_type, entity_id: f.entity_id, severity: 'BLOCKER', reason, created_by: req.admin!.id },
  });
  res.status(201).json({ flag: { id: flag.id } });
});
