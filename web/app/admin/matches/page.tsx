import Link from 'next/link';
import { redirect } from 'next/navigation';
import { adminFetch, AdminApiError, type AdminEdition, type AdminMatchRow } from '@/lib/adminApi';
import { SeverityTag } from '@/components/admin-ui';

export const dynamic = 'force-dynamic';

const PAGE = 50;

export default async function AdminMatchesPage(props: PageProps<'/admin/matches'>) {
  const sp = await props.searchParams;
  const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);
  const editionId = one(sp.editionId);
  const needsAttention = one(sp.needsAttention) === 'true';
  const offset = Math.max(0, Number(one(sp.offset) ?? 0) || 0);

  const qs = new URLSearchParams({ limit: String(PAGE), offset: String(offset) });
  if (editionId) qs.set('editionId', editionId);
  if (needsAttention) qs.set('needsAttention', 'true');

  let data: { total: number; matches: AdminMatchRow[] };
  let editions: AdminEdition[];
  try {
    [data, editions] = await Promise.all([
      adminFetch<{ total: number; matches: AdminMatchRow[] }>(`/api/admin/matches?${qs}`),
      adminFetch<{ editions: AdminEdition[] }>('/api/admin/editions').then((r) => r.editions),
    ]);
  } catch (err) {
    if (err instanceof AdminApiError && err.status === 401) redirect('/admin/login');
    if (err instanceof AdminApiError) {
      return <p className="text-sm text-red-600">{err.message}</p>;
    }
    throw err;
  }

  const href = (patch: Record<string, string | number | undefined>) => {
    const q = new URLSearchParams();
    const merged = {
      editionId,
      needsAttention: needsAttention ? 'true' : undefined,
      offset,
      ...patch,
    };
    for (const [k, v] of Object.entries(merged)) {
      if (v !== undefined && v !== '' && !(k === 'offset' && Number(v) === 0)) q.set(k, String(v));
    }
    const s = q.toString();
    return s ? `/admin/matches?${s}` : '/admin/matches';
  };

  const active = editions.find((e) => String(e.editionId) === editionId);

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-xl font-semibold tracking-tight">Matches</h1>
        <p className="mt-1 text-sm text-muted">
          {data.total.toLocaleString()} match{data.total === 1 ? '' : 'es'}
          {active ? ` in ${active.competition} ${active.season}` : ''}
          {needsAttention ? ' needing attention' : ''}
        </p>
      </div>

      <div className="space-y-2 text-xs">
        <div className="flex flex-wrap items-center gap-1.5">
          <span className="mr-1 text-muted">Edition</span>
          <Link
            href={href({ editionId: undefined, offset: 0 })}
            className={`rounded border px-2 py-1 ${!editionId ? 'border-accent text-accent' : 'border-border text-muted hover:text-foreground'}`}
          >
            All
          </Link>
          {editions
            .filter((e) => e.matchCount > 0)
            .slice(0, 10)
            .map((e) => (
              <Link
                key={e.editionId}
                href={href({ editionId: e.editionId, offset: 0 })}
                className={`rounded border px-2 py-1 ${
                  String(e.editionId) === editionId
                    ? 'border-accent text-accent'
                    : 'border-border text-muted hover:text-foreground'
                }`}
              >
                {e.competition} {e.season.slice(0, 4)}
              </Link>
            ))}
        </div>
        <div className="flex items-center gap-1.5">
          <span className="mr-1 text-muted">Filter</span>
          <Link
            href={href({ needsAttention: needsAttention ? undefined : 'true', offset: 0 })}
            className={`rounded border px-2 py-1 ${
              needsAttention ? 'border-accent text-accent' : 'border-border text-muted hover:text-foreground'
            }`}
          >
            Completed with no score
          </Link>
        </div>
      </div>

      {data.matches.length === 0 ? (
        <p className="rounded-md border border-dashed border-border px-4 py-10 text-center text-sm text-muted">
          Nothing matches these filters.
        </p>
      ) : (
        <ul className="divide-y divide-border rounded-lg border border-border">
          {data.matches.map((m) => {
            const noScore = m.homeScore === null || m.awayScore === null;
            return (
              <li key={m.id}>
                <Link
                  href={`/admin/matches/${m.id}`}
                  className="flex items-center gap-3 px-4 py-2.5 text-sm hover:bg-surface"
                >
                  <span className="w-20 shrink-0 text-xs text-muted">
                    {m.kickoffAt ? new Date(m.kickoffAt).toLocaleDateString('en-GB') : '—'}
                  </span>
                  <span className="min-w-0 flex-1 truncate text-right">{m.homeTeam.name}</span>
                  <span
                    className={`w-14 shrink-0 text-center font-mono text-sm ${noScore ? 'text-red-600' : ''}`}
                  >
                    {noScore ? '– –' : `${m.homeScore}–${m.awayScore}`}
                  </span>
                  <span className="min-w-0 flex-1 truncate">{m.awayTeam.name}</span>
                  <span className="flex w-32 shrink-0 items-center justify-end gap-1.5">
                    {m.openFlags.map((s, i) => (
                      <SeverityTag key={i} severity={s} />
                    ))}
                    <span className="text-[10px] text-muted">{m.eventCount} ev</span>
                  </span>
                </Link>
              </li>
            );
          })}
        </ul>
      )}

      <div className="flex items-center justify-between text-xs">
        <span className="text-muted">
          {data.total === 0 ? '0' : `${offset + 1}–${Math.min(offset + PAGE, data.total)} of ${data.total}`}
        </span>
        <span className="flex gap-2">
          {offset > 0 ? (
            <Link href={href({ offset: Math.max(0, offset - PAGE) })} className="rounded border border-border px-3 py-1.5 hover:border-accent">
              Previous
            </Link>
          ) : null}
          {offset + PAGE < data.total ? (
            <Link href={href({ offset: offset + PAGE })} className="rounded border border-border px-3 py-1.5 hover:border-accent">
              Next
            </Link>
          ) : null}
        </span>
      </div>
    </div>
  );
}
