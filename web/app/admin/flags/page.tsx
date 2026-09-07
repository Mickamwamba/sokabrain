import Link from 'next/link';
import { redirect } from 'next/navigation';
import { adminFetch, AdminApiError, type AdminEdition, type Flag } from '@/lib/adminApi';
import { ActionForm, SeverityTag } from '@/components/admin-ui';
import { resolveFlagAction } from '../actions';

export const dynamic = 'force-dynamic';

export default async function AdminFlagsPage(props: PageProps<'/admin/flags'>) {
  const sp = await props.searchParams;
  const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);
  const editionId = one(sp.editionId);
  const status = one(sp.status) === 'RESOLVED' ? 'RESOLVED' : 'OPEN';

  const qs = new URLSearchParams({ status });
  if (editionId) qs.set('editionId', editionId);

  let flags: Flag[];
  let editions: AdminEdition[];
  try {
    [flags, editions] = await Promise.all([
      adminFetch<{ flags: Flag[] }>(`/api/admin/flags?${qs}`).then((r) => r.flags),
      adminFetch<{ editions: AdminEdition[] }>('/api/admin/editions').then((r) => r.editions),
    ]);
  } catch (err) {
    if (err instanceof AdminApiError && err.status === 401) redirect('/admin/login');
    if (err instanceof AdminApiError) {
      return <p className="text-sm text-red-600 dark:text-red-400">{err.message}</p>;
    }
    throw err;
  }

  const active = editions.find((e) => String(e.editionId) === editionId);
  const tab = (s: string, label: string) => {
    const q = new URLSearchParams();
    if (editionId) q.set('editionId', editionId);
    if (s !== 'OPEN') q.set('status', s);
    return (
      <Link
        href={`/admin/flags${q.toString() ? `?${q}` : ''}`}
        className={`rounded border px-2 py-1 ${
          status === s ? 'border-accent text-accent' : 'border-border text-muted hover:text-foreground'
        }`}
      >
        {label}
      </Link>
    );
  };

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-xl font-semibold tracking-tight">Flags</h1>
        <p className="mt-1 text-sm text-muted">
          {flags.length} {status.toLowerCase()} flag{flags.length === 1 ? '' : 's'}
          {active ? ` in ${active.competition} ${active.season}` : ''}
        </p>
      </div>

      <div className="flex flex-wrap items-center gap-1.5 text-xs">
        {tab('OPEN', 'Open')}
        {tab('RESOLVED', 'Resolved')}
        {editionId ? (
          <Link href={`/admin/flags${status === 'RESOLVED' ? '?status=RESOLVED' : ''}`} className="rounded border border-border px-2 py-1 text-muted hover:text-foreground">
            Clear edition filter
          </Link>
        ) : null}
      </div>

      {flags.length === 0 ? (
        <p className="rounded-md border border-dashed border-border px-4 py-10 text-center text-sm text-muted">
          {status === 'OPEN' ? 'Nothing flagged. ' : 'No resolved flags. '}
          {status === 'OPEN' ? 'Raise flags from a competition or match to track what needs fixing.' : null}
        </p>
      ) : (
        <ul className="divide-y divide-border rounded-lg border border-border">
          {flags.map((f) => (
            <li key={f.id} className="flex flex-wrap items-start gap-3 px-4 py-3 text-sm">
              <SeverityTag severity={f.severity} />
              <span className="min-w-0 flex-1">
                <span className="block">{f.reason}</span>
                <span className="mt-0.5 block text-xs text-muted">
                  {f.entityType.replaceAll('_', ' ')} #{f.entityId}
                  {f.createdBy ? ` · raised by ${f.createdBy}` : ''}
                  {' · '}
                  {new Date(f.createdAt).toLocaleDateString('en-GB')}
                  {f.resolvedAt ? ` · resolved by ${f.resolvedBy ?? 'unknown'}` : ''}
                </span>
                {f.resolutionNote ? (
                  <span className="mt-0.5 block text-xs text-muted">“{f.resolutionNote}”</span>
                ) : null}
              </span>
              {f.entityType === 'match' ? (
                <Link href={`/admin/matches/${f.entityId}`} className="shrink-0 rounded border border-border px-3 py-1.5 text-xs hover:border-accent">
                  Open match
                </Link>
              ) : null}
              {f.status === 'OPEN' ? (
                <ActionForm action={resolveFlagAction} submitLabel="Resolve" className="flex shrink-0 items-center gap-2">
                  <input type="hidden" name="flagId" value={f.id} />
                  <input name="note" placeholder="Note (optional)" className="rounded border border-border bg-transparent px-2 py-1.5 text-xs w-44" />
                </ActionForm>
              ) : null}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
