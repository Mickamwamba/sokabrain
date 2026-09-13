import { createHash } from 'node:crypto';

/**
 * How an audit run's detections become findings. Pure, so the rules — which
 * are the whole point of the audit — are tested without a database.
 *
 *   detected, no finding yet            → OPEN (opened)
 *   detected, finding OPEN              → stays OPEN, detail refreshed
 *   detected, finding FIXED             → OPEN (reopened): the fix did not take
 *   detected, finding ACCEPTED, same    → stays ACCEPTED
 *   detected, finding ACCEPTED, changed → OPEN (reopened): what was accepted
 *                                         is no longer what the data says
 *   detected, finding RESOLVED          → OPEN (reopened): it came back
 *   not detected, finding not RESOLVED  → RESOLVED by this run (resolved)
 *
 * Only findings inside the run's scope are resolved for going undetected. A
 * run over one season must not close findings in every other season.
 */

export type Severity = 'INFO' | 'WARNING' | 'CRITICAL';
export type FindingStatus = 'OPEN' | 'FIXED' | 'ACCEPTED' | 'RESOLVED';
export type EntityType = 'competition_edition' | 'match' | 'player';

export type Detection = {
  checkKey: string;
  entityType: EntityType;
  entityId: number;
  editionId: number | null;
  severity: Severity;
  detail: string;
  /** The facts that make this problem this problem — counts, scores, ids. */
  facts: Record<string, unknown>;
};

export type ExistingFinding = {
  id: number;
  checkKey: string;
  entityType: EntityType;
  entityId: number;
  editionId: number | null;
  status: FindingStatus;
  fingerprint: string;
};

export type Scope = {
  /** Every season the run covered. */
  editionIds: ReadonlySet<number>;
  includeCareers: boolean;
};

export type Plan = {
  insert: (Detection & { fingerprint: string })[];
  update: {
    id: number;
    detection: Detection & { fingerprint: string };
    /** Null keeps the status as it is. */
    status: FindingStatus | null;
    reopened: boolean;
  }[];
  resolve: number[];
  counts: { detected: number; opened: number; reopened: number; resolved: number };
};

/** Stable across key order, so the same facts always hash the same. */
export function fingerprint(facts: Record<string, unknown>): string {
  const canonical = (v: unknown): unknown =>
    Array.isArray(v)
      ? v.map(canonical)
      : v && typeof v === 'object'
        ? Object.fromEntries(Object.keys(v as object).sort().map((k) => [k, canonical((v as Record<string, unknown>)[k])]))
        : v;
  return createHash('sha256').update(JSON.stringify(canonical(facts))).digest('hex');
}

export const identity = (f: { checkKey: string; entityType: string; entityId: number }) =>
  `${f.checkKey}|${f.entityType}|${f.entityId}`;

export function inScope(f: { entityType: EntityType; editionId: number | null }, scope: Scope): boolean {
  if (f.entityType === 'player') return scope.includeCareers;
  return f.editionId !== null && scope.editionIds.has(f.editionId);
}

export function planReconciliation(existing: ExistingFinding[], detected: Detection[], scope: Scope): Plan {
  const byIdentity = new Map(existing.map((f) => [identity(f), f]));
  const seen = new Set<string>();
  const plan: Plan = { insert: [], update: [], resolve: [], counts: { detected: 0, opened: 0, reopened: 0, resolved: 0 } };

  for (const d of detected) {
    const key = identity(d);
    if (seen.has(key)) continue; // a check must not report the same record twice
    seen.add(key);
    plan.counts.detected++;

    const withPrint = { ...d, fingerprint: fingerprint(d.facts) };
    const prior = byIdentity.get(key);
    if (!prior) {
      plan.insert.push(withPrint);
      plan.counts.opened++;
      continue;
    }

    const reopen =
      prior.status === 'FIXED' ||
      prior.status === 'RESOLVED' ||
      (prior.status === 'ACCEPTED' && prior.fingerprint !== withPrint.fingerprint);
    plan.update.push({ id: prior.id, detection: withPrint, status: reopen ? 'OPEN' : null, reopened: reopen });
    if (reopen) plan.counts.reopened++;
  }

  for (const f of existing) {
    if (f.status === 'RESOLVED' || seen.has(identity(f)) || !inScope(f, scope)) continue;
    plan.resolve.push(f.id);
    plan.counts.resolved++;
  }
  return plan;
}
