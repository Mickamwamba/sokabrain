import Link from 'next/link';
import { BadgeCheck, CheckCheck, ChevronDown, CircleCheck, History, ScanSearch, Wrench } from 'lucide-react';
import {
  adminFetch, type AdminCompetition, type AuditCheck, type AuditFindings, type AuditRun,
} from '@/lib/adminApi';
import { load, one } from '@/lib/admin-page';
import {
  Badge, EmptyState, ErrorState, Field, FilterTabs, PageHeader, Pagination, Panel, StatCard, fmtDate, fmtDateTime, type Tone,
} from '@/components/admin/kit';
import { ConfirmForm } from '@/components/admin/confirm-form';
import { AuditScopeForm } from '@/components/admin/audit-scope-form';
import { btn, input, td, th } from '@/components/admin/styles';
import { bulkReviewAction, runAuditAction } from '../../actions';
import { FindingActions } from '@/components/admin/finding-actions';
import { fixTarget } from '@/lib/audit-targets';

export const dynamic = 'force-dynamic';

const STATUS_TABS = [
  { value: 'ACTIVE', label: 'Needs attention' },
  { value: 'OPEN', label: 'Open' },
  { value: 'FIXED', label: 'Awaiting check' },
  { value: 'ACCEPTED', label: 'Accepted' },
  { value: 'RESOLVED', label: 'Resolved' },
  { value: 'ALL', label: 'All' },
] as const;

const SEVERITY_TONE: Record<string, Tone> = { CRITICAL: 'red', WARNING: 'amber', INFO: 'gray' };
const STATUS_BADGE: Record<string, { label: string; tone: Tone }> = {
  OPEN: { label: 'Open', tone: 'red' },
  FIXED: { label: 'Fixed — awaiting check', tone: 'blue' },
  ACCEPTED: { label: 'Accepted', tone: 'gray' },
  RESOLVED: { label: 'Resolved', tone: 'green' },
};

const AREAS = ['Scores', 'Events', 'Fixtures', 'Seasons', 'Careers'] as const;

function CheckItem({ check: c, count, href }: { check: AuditCheck; count: number | undefined; href: string }) {
  return (
    <li className="flex items-start gap-2 px-5 py-2.5 text-xs" title={c.describes}>
      <Badge tone={SEVERITY_TONE[c.severity]}>{c.severity.charAt(0)}</Badge>
      <span className="min-w-0 flex-1">
        <Link href={href} className="font-medium hover:text-brand">{c.label}</Link>
        <span className="block text-muted">{c.describes}</span>
      </span>
      {count ? <span className="shrink-0 font-semibold nums">{count}</span> : null}
    </li>
  );
}

export default async function DataAuditPage(props: PageProps<'/admin/audit'>) {
  const sp = await props.searchParams;
  const status = STATUS_TABS.some((t) => t.value === one(sp.status)) ? one(sp.status)! : 'ACTIVE';
  const severity = one(sp.severity) ?? '';
  const area = one(sp.area) ?? '';
  const checkKey = one(sp.checkKey) ?? '';
  const competitionId = one(sp.competitionId) ?? '';
  const editionId = one(sp.editionId) ?? '';
  const page = Math.max(1, Number(one(sp.page)) || 1);

  const q = new URLSearchParams({ status, page: String(page), pageSize: '40' });
  for (const [k, v] of Object.entries({ severity, area, checkKey, competitionId, editionId })) if (v) q.set(k, v);

  const res = await load(() =>
    Promise.all([
      adminFetch<AuditFindings>(`/api/admin/audit/findings?${q}`),
      adminFetch<{ runs: AuditRun[] }>('/api/admin/audit/runs?limit=8').then((r) => r.runs),
      adminFetch<{ checks: AuditCheck[] }>('/api/admin/audit/checks').then((r) => r.checks),
      adminFetch<{ competitions: AdminCompetition[] }>('/api/admin/competitions').then((r) => r.competitions),
      // The headline numbers ignore the filters: they describe the vault.
      // status=ACTIVE: status counts ignore it, severity counts respect it.
      adminFetch<AuditFindings>('/api/admin/audit/findings?status=ACTIVE&pageSize=1'),
    ]),
  );
  if (!res.ok) return <ErrorState message={res.error} />;
  const [data, runs, checks, competitions, overall] = res.data;
  const withSeasons = competitions.filter((c) => c.editions.length > 0);
  const SEVERITY_RANK: Record<string, number> = { CRITICAL: 0, WARNING: 1, INFO: 2 };
  const topChecks = [...checks]
    .sort((a, b) => SEVERITY_RANK[a.severity]! - SEVERITY_RANK[b.severity]! || (data.counts.check[b.key] ?? 0) - (data.counts.check[a.key] ?? 0))
    .slice(0, 5);
  const lastRun = runs[0];
  // A link carrying only a season (from the dashboard, a flag) still shows its
  // competition selected, so the season picker appears with it chosen.
  const selectedComp =
    withSeasons.find((c) => String(c.id) === competitionId) ??
    withSeasons.find((c) => c.editions.some((e) => String(e.editionId) === editionId));

  const href = (patch: Record<string, string | null>) => {
    const u = new URLSearchParams();
    const base: Record<string, string | null> = {
      status: status === 'ACTIVE' ? null : status, severity: severity || null, area: area || null,
      checkKey: checkKey || null, competitionId: competitionId || null, editionId: editionId || null, page: null, ...patch,
    };
    for (const [k, v] of Object.entries(base)) if (v) u.set(k, v);
    const s = u.toString();
    return `/admin/audit${s ? `?${s}` : ''}`;
  };
  // This exact list, page included, so "back to the audit" lands where the editor left.
  const returnTo = href({ page: page > 1 ? String(page) : null });
  const countFor = (v: string) =>
    v === 'ACTIVE' ? (data.counts.status.OPEN ?? 0) + (data.counts.status.FIXED ?? 0)
      : v === 'ALL' ? Object.values(data.counts.status).reduce((n, x) => n + (x ?? 0), 0)
        : data.counts.status[v as keyof typeof data.counts.status] ?? 0;
  const filtered = Boolean(severity || area || checkKey || competitionId || editionId);
  const openInFilter = data.counts.status.OPEN ?? 0;
  const filterFields = (
    <>
      {severity ? <input type="hidden" name="severity" value={severity} /> : null}
      {area ? <input type="hidden" name="area" value={area} /> : null}
      {checkKey ? <input type="hidden" name="checkKey" value={checkKey} /> : null}
      {competitionId ? <input type="hidden" name="competitionId" value={competitionId} /> : null}
      {editionId ? <input type="hidden" name="editionId" value={editionId} /> : null}
      <input type="hidden" name="expectedCount" value={openInFilter} />
    </>
  );

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<ScanSearch />}
        title="Data audit"
        description="Re-check the vault for problems in scores, events, fixtures, seasons and careers. Findings resolve themselves when a run no longer detects them."
      />

      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <StatCard label="Open" value={overall.counts.status.OPEN ?? 0} tone={(overall.counts.status.OPEN ?? 0) ? 'red' : 'green'} icon={<ScanSearch />} />
        <StatCard label="Critical, needing attention" value={overall.counts.severity.CRITICAL ?? 0} tone={(overall.counts.severity.CRITICAL ?? 0) ? 'red' : 'green'} hint="Open or awaiting a check" />
        <StatCard label="Fixed, awaiting a run" value={overall.counts.status.FIXED ?? 0} tone="blue" icon={<Wrench />} />
        <StatCard label="Resolved by audits" value={overall.counts.status.RESOLVED ?? 0} tone="green" icon={<BadgeCheck />}
          hint={lastRun ? `Last run #${lastRun.id}, ${fmtDateTime(lastRun.startedAt)}` : 'No audit has run yet'} />
      </div>

      <div className="grid gap-6 xl:grid-cols-3">
        <div className="space-y-6 xl:col-span-2">
          <Panel
            title={<FilterTabs items={STATUS_TABS.map((t) => ({ href: href({ status: t.value === 'ACTIVE' ? null : t.value }), label: t.label, active: status === t.value, count: countFor(t.value) }))} />}
          >
            <form method="get" action="/admin/audit" className="flex flex-wrap items-end gap-3 border-b border-line bg-wash/40 px-5 py-4">
              {status !== 'ACTIVE' ? <input type="hidden" name="status" value={status} /> : null}
              <Field label="Severity">
                <select name="severity" defaultValue={severity} className={input}>
                  <option value="">Any</option>
                  {['CRITICAL', 'WARNING', 'INFO'].map((s) => <option key={s} value={s}>{s.charAt(0) + s.slice(1).toLowerCase()}</option>)}
                </select>
              </Field>
              <Field label="Check" className="min-w-52 flex-1">
                <select name="checkKey" defaultValue={checkKey} className={input}>
                  <option value="">Any check</option>
                  {(['Scores', 'Events', 'Fixtures', 'Seasons', 'Careers'] as const).map((a) => (
                    <optgroup key={a} label={a}>
                      {checks.filter((c) => c.area === a).map((c) => (
                        <option key={c.key} value={c.key}>{c.label}{data.counts.check[c.key] ? ` (${data.counts.check[c.key]})` : ''}</option>
                      ))}
                    </optgroup>
                  ))}
                </select>
              </Field>
              <Field label="Competition" className="min-w-44 flex-1">
                <select name="competitionId" defaultValue={selectedComp ? String(selectedComp.id) : ''} className={input}>
                  <option value="">Any</option>
                  {withSeasons.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
                </select>
              </Field>
              {selectedComp ? (
                <Field label="Season">
                  <select name="editionId" defaultValue={editionId} className={input}>
                    <option value="">All seasons</option>
                    {selectedComp.editions.map((e) => <option key={e.editionId} value={e.editionId}>{e.season}</option>)}
                  </select>
                </Field>
              ) : null}
              <button type="submit" className={btn('secondary')}>Apply</button>
              {filtered ? <Link href={href({ severity: null, area: null, checkKey: null, competitionId: null, editionId: null })} className={btn('ghost')}>Clear</Link> : null}
            </form>

            {openInFilter > 0 && (status === 'ACTIVE' || status === 'OPEN') ? (
              <div className="flex flex-wrap items-center justify-between gap-3 border-b border-line px-5 py-3 text-sm">
                <span className="text-muted">
                  <strong className="text-ink">{openInFilter.toLocaleString()}</strong> open finding{openInFilter === 1 ? '' : 's'} match{openInFilter === 1 ? 'es' : ''} these filters.
                </span>
                <div className="flex gap-2">
                  <ConfirmForm
                    action={bulkReviewAction}
                    title={`Accept ${openInFilter.toLocaleString()} findings?`}
                    description="Each stays closed while its problem is unchanged, and reopens if the data changes. Findings someone already reviewed are left as they are."
                    confirmLabel={`Accept ${openInFilter.toLocaleString()}`}
                    trigger={<><CheckCheck /> Accept all</>}
                    triggerVariant="secondary"
                    triggerSize="sm"
                    fields={
                      <Field label="Why are these acceptable?" required hint="Recorded on every finding.">
                        <input name="note" required maxLength={1000} placeholder="e.g. no source names scorers before 2023/24" className={input} />
                      </Field>
                    }
                  >
                    <input type="hidden" name="decision" value="ACCEPTED" />
                    {filterFields}
                  </ConfirmForm>
                  <ConfirmForm
                    action={bulkReviewAction}
                    title={`Mark ${openInFilter.toLocaleString()} findings fixed?`}
                    description="The next audit run over them confirms each fix, or reopens the ones still wrong."
                    confirmLabel={`Mark ${openInFilter.toLocaleString()} fixed`}
                    trigger={<><Wrench /> Mark all fixed</>}
                    triggerVariant="secondary"
                    triggerSize="sm"
                    fields={
                      <Field label="Note" hint="Optional.">
                        <input name="note" maxLength={1000} className={input} />
                      </Field>
                    }
                  >
                    <input type="hidden" name="decision" value="FIXED" />
                    {filterFields}
                  </ConfirmForm>
                </div>
              </div>
            ) : null}

            {data.findings.length === 0 ? (
              <EmptyState icon={<CircleCheck />} title={runs.length ? 'Nothing here' : 'No audit has run yet'}>
                {runs.length ? (filtered ? 'No findings match these filters.' : 'No findings in this state.') : 'Run the first audit from the panel alongside.'}
              </EmptyState>
            ) : (
              <>
                <div className="overflow-x-auto">
                  <table className="w-full min-w-[820px] text-sm">
                    <thead className="border-b border-line bg-wash/60">
                      <tr>
                        <th className={th}>Severity</th>
                        <th className={th}>Problem</th>
                        <th className={th}>Where</th>
                        <th className={th}>Status</th>
                        <th className={th}><span className="sr-only">Actions</span></th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-line">
                      {data.findings.map((f) => {
                        const st = STATUS_BADGE[f.status]!;
                        const target = fixTarget(f, returnTo);
                        return (
                          <tr key={f.id} className="align-top hover:bg-wash/60">
                            <td className={td}><Badge tone={SEVERITY_TONE[f.severity]}>{f.severity.charAt(0) + f.severity.slice(1).toLowerCase()}</Badge></td>
                            <td className={td}>
                              <p className="font-semibold">{f.check.label}</p>
                              <p className="text-xs text-muted">{f.detail}</p>
                            </td>
                            <td className={td}>
                              <Link href={target.href} className="font-medium hover:text-brand">{f.entity.label}</Link>
                              <p className="text-xs text-muted">
                                {f.entity.type === 'match' ? [f.edition?.label, f.entity.date ? fmtDate(f.entity.date) : null].filter(Boolean).join(' · ') : f.entity.type === 'player' ? 'Player career' : 'Whole season'}
                              </p>
                            </td>
                            <td className={td}>
                              <Badge tone={st.tone}>{st.label}</Badge>
                              <p className="mt-1 max-w-56 text-xs text-muted">
                                {f.status === 'RESOLVED' && f.resolvedRunId ? `No longer found by run #${f.resolvedRunId}` : `Last seen in run #${f.lastSeenRunId}`}
                                {f.timesReopened ? ` · reopened ${f.timesReopened}×` : ''}
                              </p>
                              {f.reviewedBy && f.status !== 'OPEN' ? (
                                <p className="mt-0.5 max-w-56 text-xs text-muted">{f.reviewedBy}{f.reviewNote ? `: “${f.reviewNote}”` : ''}</p>
                              ) : null}
                            </td>
                            <td className={td}>
                              <div className="flex items-center justify-end gap-1.5">
                                {f.status !== 'RESOLVED' ? (
                                  <Link href={target.href} className={btn('primary', 'sm')}>
                                    <Wrench /> {target.label}
                                  </Link>
                                ) : null}
                                <FindingActions finding={f} />
                              </div>
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
                <Pagination page={page} pageSize={data.pageSize} total={data.total} href={(p) => href({ page: p > 1 ? String(p) : null })} />
              </>
            )}
          </Panel>
        </div>

        <div className="space-y-6">
          <Panel title="Run an audit" description="Reading only — no data is changed by a run.">
            <AuditScopeForm
              action={runAuditAction}
              competitions={withSeasons.map((c) => ({ id: c.id, name: c.name, editions: c.editions }))}
            />
          </Panel>

          <Panel title="Recent runs" actions={<History className="h-4 w-4 text-muted" />}>
            {runs.length === 0 ? (
              <EmptyState title="No runs yet" />
            ) : (
              <ul className="divide-y divide-line">
                {runs.map((r) => (
                  <li key={r.id} className="px-5 py-3 text-sm">
                    <div className="flex items-center justify-between gap-2">
                      <span className="font-semibold">Run #{r.id}</span>
                      {r.status === 'COMPLETED' ? <Badge tone="green">Completed</Badge> : r.status === 'FAILED' ? <Badge tone="red">Failed</Badge> : <Badge tone="blue">Running</Badge>}
                    </div>
                    <p className="mt-0.5 text-xs text-muted">
                      {fmtDateTime(r.startedAt)}{r.startedBy ? ` · ${r.startedBy}` : ''}
                    </p>
                    <p className="mt-0.5 text-xs text-muted">
                      {r.scope.competitions.length || r.scope.editions.length
                        ? [...r.scope.competitions, ...r.scope.editions].join(', ')
                        : 'Whole vault'}
                      {r.scope.includeCareers ? ' + careers' : ''}
                    </p>
                    {r.status === 'COMPLETED' ? (
                      <p className="mt-1 flex flex-wrap gap-x-3 text-xs">
                        <span><strong className="nums">{r.detected}</strong> detected</span>
                        <span className="text-loss"><strong className="nums">{r.opened}</strong> new</span>
                        <span className="text-[#8a5a00]"><strong className="nums">{r.reopened}</strong> reopened</span>
                        <span className="text-brand-dark"><strong className="nums">{r.resolved}</strong> resolved</span>
                      </p>
                    ) : r.error ? <p className="mt-1 text-xs text-loss">{r.error}</p> : null}
                  </li>
                ))}
              </ul>
            )}
          </Panel>

          <Panel title="What is checked" description={`${checks.length} checks across ${AREAS.length} areas`}>
            {/* The most serious checks, and whatever is finding the most right
                now, stay in view; the full list is one click away. */}
            <ul className="divide-y divide-line">
              {topChecks.map((c) => <CheckItem key={c.key} check={c} count={data.counts.check[c.key]} href={href({ checkKey: c.key, area: null, status: 'ALL' })} />)}
            </ul>
            <details className="group border-t border-line">
              <summary className="flex cursor-pointer list-none items-center justify-between px-5 py-3 text-sm font-semibold text-muted hover:text-ink">
                <span className="group-open:hidden">Show all {checks.length} checks</span>
                <span className="hidden group-open:inline">Hide the full list</span>
                <ChevronDown className="h-4 w-4 transition-transform group-open:rotate-180" />
              </summary>
              <div className="divide-y divide-line border-t border-line">
                {AREAS.map((a) => (
                  <div key={a}>
                    <p className="bg-wash/60 px-5 py-2 text-[11px] font-bold uppercase tracking-wide text-muted">{a}</p>
                    <ul className="divide-y divide-line">
                      {checks.filter((c) => c.area === a).map((c) => (
                        <CheckItem key={c.key} check={c} count={data.counts.check[c.key]} href={href({ checkKey: c.key, area: null, status: 'ALL' })} />
                      ))}
                    </ul>
                  </div>
                ))}
              </div>
            </details>
          </Panel>
        </div>
      </div>
    </div>
  );
}
