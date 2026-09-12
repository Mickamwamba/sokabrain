import Link from 'next/link';
import { CircleCheck, ExternalLink, Flag as FlagIcon } from 'lucide-react';
import { adminFetch, type AdminEdition, type Flag } from '@/lib/adminApi';
import { load, one } from '@/lib/admin-page';
import { EmptyState, ErrorState, Field, FilterTabs, PageHeader, Panel, SeverityBadge, fmtDate } from '@/components/admin/kit';
import { ConfirmForm } from '@/components/admin/confirm-form';
import { btn, input } from '@/components/admin/styles';
import { resolveFlagAction } from '../../actions';

export const dynamic = 'force-dynamic';

export default async function AdminFlagsPage(props: PageProps<'/admin/flags'>) {
  const sp = await props.searchParams;
  const editionId = one(sp.editionId);
  const status = one(sp.status) === 'RESOLVED' ? 'RESOLVED' : 'OPEN';

  const qs = new URLSearchParams({ status });
  if (editionId) qs.set('editionId', editionId);

  const res = await load(() =>
    Promise.all([
      adminFetch<{ flags: Flag[] }>(`/api/admin/flags?${qs}`).then((r) => r.flags),
      adminFetch<{ editions: AdminEdition[] }>('/api/admin/editions').then((r) => r.editions),
    ]),
  );
  if (!res.ok) return <ErrorState message={res.error} />;
  const [flags, editions] = res.data;
  const active = editions.find((e) => String(e.editionId) === editionId);

  const tab = (s: 'OPEN' | 'RESOLVED') => {
    const q = new URLSearchParams();
    if (editionId) q.set('editionId', editionId);
    if (s === 'RESOLVED') q.set('status', s);
    return `/admin/flags${q.toString() ? `?${q}` : ''}`;
  };

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<FlagIcon />}
        title="Flags"
        description="Problems editors have raised to track. A blocker keeps its season off the public site."
      />

      <Panel
        title={<FilterTabs items={[
          { href: tab('OPEN'), label: 'Open', active: status === 'OPEN' },
          { href: tab('RESOLVED'), label: 'Resolved', active: status === 'RESOLVED' },
        ]} />}
        description={active ? `In ${active.competition} ${active.season}` : undefined}
        actions={editionId ? <Link href={status === 'RESOLVED' ? '/admin/flags?status=RESOLVED' : '/admin/flags'} className={btn('ghost', 'sm')}>Clear season filter</Link> : null}
      >
        {flags.length === 0 ? (
          <EmptyState icon={<CircleCheck />} title={status === 'OPEN' ? 'Nothing flagged' : 'No resolved flags'}>
            {status === 'OPEN' ? 'Raise flags from a competition or match page to track what needs fixing.' : null}
          </EmptyState>
        ) : (
          <ul className="divide-y divide-line">
            {flags.map((f) => (
              <li key={f.id} className="flex flex-wrap items-start gap-3 px-5 py-4 text-sm">
                <SeverityBadge severity={f.severity} />
                <div className="min-w-0 flex-1">
                  <p className="font-medium">{f.reason}</p>
                  <p className="mt-0.5 text-xs text-muted">
                    {f.entityType.replaceAll('_', ' ')} #{f.entityId}
                    {f.createdBy ? ` · raised by ${f.createdBy}` : ''} · {fmtDate(f.createdAt)}
                    {f.resolvedAt ? ` · resolved by ${f.resolvedBy ?? 'unknown'} on ${fmtDate(f.resolvedAt)}` : ''}
                  </p>
                  {f.resolutionNote ? <p className="mt-1 text-xs italic text-muted">“{f.resolutionNote}”</p> : null}
                </div>
                <div className="flex items-center gap-2">
                  {f.entityType === 'match' ? (
                    <Link href={`/admin/matches/${f.entityId}`} className={btn('secondary', 'sm')}><ExternalLink /> Open match</Link>
                  ) : f.entityType === 'competition_edition' ? (
                    <Link href={`/admin/issues?editionId=${f.entityId}`} className={btn('secondary', 'sm')}><ExternalLink /> Open season</Link>
                  ) : null}
                  {f.status === 'OPEN' ? (
                    <ConfirmForm
                      action={resolveFlagAction}
                      title="Resolve this flag?"
                      description={<>“{f.reason}” will be marked resolved.{f.severity === 'BLOCKER' ? ' It will no longer block publication.' : ''}</>}
                      confirmLabel="Resolve flag"
                      trigger={<><CircleCheck /> Resolve</>}
                      triggerSize="sm"
                      fields={
                        <Field label="Resolution note" hint="Optional — what was done about it.">
                          <input name="note" maxLength={500} className={input} />
                        </Field>
                      }
                    >
                      <input type="hidden" name="flagId" value={f.id} />
                    </ConfirmForm>
                  ) : null}
                </div>
              </li>
            ))}
          </ul>
        )}
      </Panel>
    </div>
  );
}
