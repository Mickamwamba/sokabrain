import { Prisma } from '@prisma/client';
import { prisma } from '../../db.js';
import { CHECKS, runChecks } from './checks.js';
import { inScope, planReconciliation, type EntityType, type ExistingFinding, type FindingStatus } from './reconcile.js';

export type AuditScope = {
  /** Omit for every competition. */
  competitionIds?: number[] | undefined;
  /** Omit for every season of the chosen competitions. */
  editionIds?: number[] | undefined;
  includeCareers: boolean;
};

/**
 * A run that has been going this long is presumed dead (the process restarted
 * mid-run), so it no longer blocks a new one.
 */
const STALE_RUN_MS = 10 * 60 * 1000;

export class AuditBusyError extends Error {}

/**
 * Resolve a scope to the exact seasons it covers.
 *
 * Competitions and seasons combine as a union: "all of AFCON, plus Premier
 * League 2019/20" is AFCON's seasons and that one league season. Neither given
 * means every season. Treating them as a filter on each other would turn that
 * example into an empty audit that resolves nothing and finds nothing.
 */
async function scopedEditions(scope: AuditScope): Promise<number[]> {
  const comps = scope.competitionIds ?? [];
  const eds = scope.editionIds ?? [];
  const rows = await prisma.competition_editions.findMany({
    where:
      comps.length || eds.length
        ? { OR: [...(comps.length ? [{ competition_id: { in: comps } }] : []), ...(eds.length ? [{ id: { in: eds } }] : [])] }
        : {},
    select: { id: true },
  });
  return rows.map((r) => r.id);
}

/**
 * Run the audit over a scope and reconcile with the findings on record.
 *
 * Detection happens outside the transaction (it only reads); every write —
 * new findings, refreshed ones, reopened, resolved, and the run's totals —
 * lands in one transaction, so a failure leaves the previous state intact and
 * the run marked FAILED.
 */
export async function runAudit(scope: AuditScope, adminId: number) {
  const busy = await prisma.audit_runs.findFirst({
    where: { status: 'RUNNING', started_at: { gt: new Date(Date.now() - STALE_RUN_MS) } },
    select: { id: true },
  });
  if (busy) throw new AuditBusyError(`Audit run #${busy.id} is still in progress.`);

  const editionIds = await scopedEditions(scope);
  const run = await prisma.audit_runs.create({
    data: {
      started_by: adminId,
      scope_competition_ids: scope.competitionIds ?? [],
      scope_edition_ids: scope.editionIds ?? [],
      include_careers: scope.includeCareers,
    },
  });

  try {
    const detected = await runChecks(editionIds, scope.includeCareers);
    const reconcileScope = { editionIds: new Set(editionIds), includeCareers: scope.includeCareers };

    const existing: ExistingFinding[] = (
      await prisma.audit_findings.findMany({
        where: {
          OR: [
            { edition_id: { in: editionIds } },
            ...(scope.includeCareers ? [{ entity_type: 'player' }] : []),
          ],
        },
        select: { id: true, check_key: true, entity_type: true, entity_id: true, edition_id: true, status: true, fingerprint: true },
      })
    )
      .map((f) => ({
        id: f.id,
        checkKey: f.check_key,
        entityType: f.entity_type as EntityType,
        entityId: f.entity_id,
        editionId: f.edition_id,
        status: f.status as FindingStatus,
        fingerprint: f.fingerprint,
      }))
      .filter((f) => inScope(f, reconcileScope));

    const plan = planReconciliation(existing, detected, reconcileScope);
    const now = new Date();

    await prisma.$transaction(async (tx) => {
      if (plan.insert.length) {
        await tx.audit_findings.createMany({
          data: plan.insert.map((d) => ({
            check_key: d.checkKey,
            entity_type: d.entityType,
            entity_id: d.entityId,
            edition_id: d.editionId,
            severity: d.severity,
            detail: d.detail,
            fingerprint: d.fingerprint,
            first_seen_run_id: run.id,
            last_seen_run_id: run.id,
          })),
        });
      }
      for (const u of plan.update) {
        await tx.audit_findings.update({
          where: { id: u.id },
          data: {
            severity: u.detection.severity,
            detail: u.detection.detail,
            fingerprint: u.detection.fingerprint,
            last_seen_run_id: run.id,
            updated_at: now,
            ...(u.status && { status: u.status, resolved_run_id: null }),
            ...(u.reopened && { times_reopened: { increment: 1 } }),
          },
        });
      }
      if (plan.resolve.length) {
        await tx.audit_findings.updateMany({
          where: { id: { in: plan.resolve } },
          data: { status: 'RESOLVED', resolved_run_id: run.id, updated_at: now },
        });
      }
      await tx.audit_runs.update({
        where: { id: run.id },
        data: {
          status: 'COMPLETED',
          finished_at: new Date(),
          checks_run: CHECKS.filter((c) => c.area !== 'Careers' || scope.includeCareers).length,
          ...plan.counts,
        },
      });
    }, { timeout: 120_000 });
  } catch (err) {
    await prisma.audit_runs.update({
      where: { id: run.id },
      data: { status: 'FAILED', finished_at: new Date(), error: err instanceof Error ? err.message : String(err) },
    });
    throw err;
  }

  return prisma.audit_runs.findUniqueOrThrow({ where: { id: run.id } });
}

export type FindingFilter = {
  status?: 'ACTIVE' | 'OPEN' | 'FIXED' | 'ACCEPTED' | 'RESOLVED' | 'ALL' | undefined;
  severity?: string | undefined;
  checkKey?: string | undefined;
  competitionId?: number | undefined;
  editionId?: number | undefined;
  area?: string | undefined;
  /** One record's findings — for showing them on that record's own page. */
  entityType?: string | undefined;
  entityId?: number | undefined;
};

/** The WHERE for a filter — shared by the list, its counts and bulk review. */
export function findingWhere(f: FindingFilter, opts: { ignore?: (keyof FindingFilter)[] } = {}): Prisma.audit_findingsWhereInput {
  const use = (k: keyof FindingFilter) => !opts.ignore?.includes(k) && f[k] !== undefined && f[k] !== '';
  const areaKeys = use('area') ? CHECKS.filter((c) => c.area === f.area).map((c) => c.key) : null;
  return {
    ...(use('status') && f.status !== 'ALL' && {
      status: f.status === 'ACTIVE' ? { in: ['OPEN', 'FIXED'] } : f.status!,
    }),
    ...(use('severity') && { severity: f.severity! }),
    ...(use('checkKey') ? { check_key: f.checkKey! } : areaKeys ? { check_key: { in: areaKeys } } : {}),
    ...(use('editionId') && { edition_id: f.editionId! }),
    ...(use('entityType') && { entity_type: f.entityType! }),
    ...(use('entityId') && { entity_id: f.entityId! }),
    ...(use('competitionId') && !use('editionId') && { competition_editions: { competition_id: f.competitionId! } }),
  };
}
