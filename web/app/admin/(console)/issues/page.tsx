import Link from 'next/link';
import { ArrowRight, CircleCheck, TriangleAlert } from 'lucide-react';
import { adminFetch, type AdminCompetition, type IssuesResponse } from '@/lib/adminApi';
import { load, one } from '@/lib/admin-page';
import {
  Badge, EmptyState, ErrorState, Field, PageHeader, Panel, SeverityBadge, StatCard, fmtDate,
} from '@/components/admin/kit';
import { ConfirmForm } from '@/components/admin/confirm-form';
import { IssueFilters } from '@/components/admin/issue-filters';
import { btn, input } from '@/components/admin/styles';
import { resolveFlagAction } from '../../actions';

export const dynamic = 'force-dynamic';

const KIND_LABEL: Record<string, string> = {
  MISSING_SCORE: 'No score recorded',
  GOALS_WITHOUT_EVENTS: 'Goals missing from the event log',
  UNNAMED_SCORER: 'Goal with no scorer',
  EVENTS_CONTRADICT_SCORE: 'Events contradict the score',
  ORPHAN_EVENT: 'Event not attached to a team',
  SELF_FIXTURE: 'Team listed against itself',
};

export default async function AdminIssuesPage(props: PageProps<'/admin/issues'>) {
  const sp = await props.searchParams;
  const kind = one(sp.kind);

  const comps = await load(() =>
    adminFetch<{ competitions: AdminCompetition[] }>('/api/admin/competitions').then((r) => r.competitions),
  );
  if (!comps.ok) return <ErrorState message={comps.error} />;
  const selectable = comps.data.filter((c) => c.editions.length > 0);

  const wantEdition = Number(one(sp.editionId));
  const competition =
    selectable.find((c) => c.editions.some((e) => e.editionId === wantEdition)) ??
    selectable.find((c) => c.id === Number(one(sp.competitionId))) ??
    [...selectable].sort((a, b) => b.matchCount - a.matchCount)[0];
  const edition = competition?.editions.find((e) => e.editionId === wantEdition) ?? competition?.editions[0];

  const res = edition
    ? await load(() => adminFetch<IssuesResponse>(`/api/admin/editions/${edition.editionId}/match-issues`))
    : null;
  if (res && !res.ok) return <ErrorState message={res.error} />;
  const data = res?.ok ? res.data : null;

  const shown = (data?.matches ?? []).filter((m) => !kind || m.issues.some((i) => i.kind === kind));
  const kinds = Object.entries(data?.totals.byKind ?? {}).map(([value, count]) => ({
    value, label: KIND_LABEL[value] ?? value, count,
  }));

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<TriangleAlert />}
        title="Issues"
        description="Every match needing attention in a season. Detected problems clear themselves once fixed; flags stay until resolved."
      />

      {selectable.length ? (
        <Panel bodyClassName="p-5">
          <IssueFilters
            competitions={selectable.map((c) => ({ id: c.id, name: c.name, country: c.country, editions: c.editions }))}
            competitionId={competition?.id}
            editionId={edition?.editionId}
            kind={kind}
            kinds={kinds}
          />
        </Panel>
      ) : null}

      {!data ? (
        <Panel><EmptyState icon={<TriangleAlert />} title="Pick a competition and season" /></Panel>
      ) : (
        <>
          <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
            <StatCard label="Matches affected" value={data.totals.matchesWithIssues} hint={`of ${edition?.matchCount ?? 0}`}
              tone={data.totals.matchesWithIssues ? 'amber' : 'green'} icon={<TriangleAlert />} />
            <StatCard label="Blocking publication" value={data.totals.blockers} tone={data.totals.blockers ? 'red' : 'green'} />
            <StatCard label="Open flags" value={data.totals.openFlags} />
            <StatCard label="Public status" value={data.edition.isPublished ? 'Live' : 'Hidden'}
              tone={data.edition.isPublished ? 'green' : 'gray'} />
          </div>

          <Panel
            title={`${data.edition.competition} ${data.edition.season}`}
            description={`${shown.length} match${shown.length === 1 ? '' : 'es'}${kind ? ` · ${KIND_LABEL[kind] ?? kind}` : ''}`}
          >
            {shown.length === 0 ? (
              <EmptyState icon={<CircleCheck />} title={kind ? 'No matches have that issue' : 'Nothing needs attention'} />
            ) : (
              <ul className="divide-y divide-line">
                {shown.map((m) => (
                  <li key={m.matchId} className="px-5 py-4">
                    <div className="flex flex-wrap items-center gap-x-3 gap-y-1">
                      <Link href={`/admin/matches/${m.matchId}`} className="text-sm font-semibold hover:text-brand">
                        {m.homeTeam}{' '}
                        <span className="mx-1 rounded bg-wash px-1.5 py-0.5 nums text-muted">
                          {m.homeScore === null || m.awayScore === null ? '– –' : `${m.homeScore}–${m.awayScore}`}
                        </span>{' '}
                        {m.awayTeam}
                      </Link>
                      <span className="text-xs text-muted">
                        {fmtDate(m.kickoffAt)}{m.round ? ` · round ${m.round}` : ''}
                      </span>
                      <Link href={`/admin/matches/${m.matchId}`} className={btn('ghost', 'sm', 'ml-auto')}>
                        Fix <ArrowRight />
                      </Link>
                    </div>
                    <ul className="mt-2 space-y-1.5">
                      {m.issues.map((i, idx) => (
                        <li key={idx} className="flex flex-wrap items-center gap-2 text-xs">
                          <SeverityBadge severity={i.severity} />
                          <span className="text-muted">{i.detail}</span>
                        </li>
                      ))}
                      {m.openFlags.map((f) => (
                        <li key={`f${f.id}`} className="flex flex-wrap items-center gap-2 text-xs">
                          <SeverityBadge severity={f.severity} />
                          <Badge tone="blue">Flag</Badge>
                          <span className="min-w-0 flex-1 text-muted">{f.reason}</span>
                          <ConfirmForm
                            action={resolveFlagAction}
                            title="Resolve this flag?"
                            description={<>“{f.reason}” will be marked resolved.</>}
                            confirmLabel="Resolve flag"
                            trigger={<><CircleCheck /> Resolve</>}
                            triggerVariant="secondary"
                            triggerSize="sm"
                            fields={
                              <Field label="Resolution note" hint="Optional.">
                                <input name="note" maxLength={500} className={input} />
                              </Field>
                            }
                          >
                            <input type="hidden" name="flagId" value={f.id} />
                          </ConfirmForm>
                        </li>
                      ))}
                    </ul>
                  </li>
                ))}
              </ul>
            )}
          </Panel>
        </>
      )}
    </div>
  );
}
