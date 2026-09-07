import Link from 'next/link';
import { redirect } from 'next/navigation';
import { adminFetch, AdminApiError, type AdminEdition, type Flag } from '@/lib/adminApi';
import { Card, CardHead, StatTile } from '@/components/ui';
import { SeverityTag } from '@/components/admin-ui';

export const dynamic = 'force-dynamic';

export default async function AdminOverviewPage() {
  let editions: AdminEdition[];
  let flags: Flag[];
  try {
    [editions, flags] = await Promise.all([
      adminFetch<{ editions: AdminEdition[] }>('/api/admin/editions').then((r) => r.editions),
      adminFetch<{ flags: Flag[] }>('/api/admin/flags?status=OPEN&limit=5').then((r) => r.flags),
    ]);
  } catch (err) {
    if (err instanceof AdminApiError && err.status === 401) redirect('/admin/login');
    if (err instanceof AdminApiError) return <p className="text-sm text-loss">{err.message}</p>;
    throw err;
  }

  const live = editions.filter((e) => e.isPublished);
  const withIssues = editions
    .filter((e) => e.matchCount > 0 && e.issues.length > 0)
    .sort((a, b) => {
      // Published seasons first: a problem the public can already see matters most.
      if (a.isPublished !== b.isPublished) return a.isPublished ? -1 : 1;
      const sum = (e: AdminEdition) => e.issues.reduce((n, i) => n + i.count, 0);
      return sum(b) - sum(a);
    });

  const totalIssues = editions.reduce(
    (n, e) => n + e.issues.reduce((m, i) => m + i.count, 0),
    0,
  );

  return (
    <div className="space-y-5">
      <div>
        <h1 className="display text-2xl font-extrabold tracking-tight">Overview</h1>
        <p className="mt-1 text-sm text-muted">
          What the public can see, and what still needs fixing.
        </p>
      </div>

      <div className="grid gap-3 sm:grid-cols-4">
        <StatTile figure={live.length} label="Live seasons" sub={`of ${editions.length}`} />
        <StatTile
          figure={live.reduce((n, e) => n + e.matchCount, 0)}
          label="Public matches"
        />
        <StatTile figure={totalIssues} label="Detected issues" sub="across all seasons" />
        <StatTile figure={flags.length} label="Open flags" />
      </div>

      <Card>
        <CardHead
          title="Live on the public site"
          action={{ href: '/admin/competitions', label: 'Manage' }}
        />
        {live.length === 0 ? (
          <p className="px-5 py-8 text-center text-sm text-muted">
            Nothing is published. Fans see an empty site until you release a season.
          </p>
        ) : (
          <ul>
            {live.map((e) => (
              <li
                key={e.editionId}
                className="flex items-center gap-3 border-b border-line px-5 py-3 text-sm last:border-0"
              >
                <span className="min-w-0 flex-1">
                  <span className="block truncate font-semibold">
                    {e.competition} <span className="font-normal text-muted">{e.season}</span>
                  </span>
                  <span className="block text-xs text-muted">
                    {e.matchCount} matches
                    {e.issues.length > 0
                      ? ` · ${e.issues.reduce((n, i) => n + i.count, 0)} detected issues`
                      : ' · no detected issues'}
                  </span>
                </span>
                <Link
                  href={`/admin/matches?editionId=${e.editionId}&needsAttention=true`}
                  className="shrink-0 rounded-lg border border-line px-3 py-1.5 text-xs font-semibold hover:border-ink"
                >
                  Fix data
                </Link>
              </li>
            ))}
          </ul>
        )}
      </Card>

      <div className="grid gap-5 lg:grid-cols-2">
        <Card>
          <CardHead title="Needs attention" hint="Seasons with detected data problems" />
          {withIssues.length === 0 ? (
            <p className="px-5 py-8 text-center text-sm text-muted">Nothing detected.</p>
          ) : (
            <ul>
              {withIssues.slice(0, 6).map((e) => (
                <li key={e.editionId} className="border-b border-line px-5 py-3 last:border-0">
                  <Link
                    href={`/admin/matches?editionId=${e.editionId}&needsAttention=true`}
                    className="block text-sm font-semibold hover:text-brand"
                  >
                    {e.competition} {e.season}
                    {e.isPublished ? (
                      <span className="ml-2 rounded-full bg-brand px-2 py-0.5 text-[10px] font-bold uppercase text-white">
                        live
                      </span>
                    ) : null}
                  </Link>
                  <p className="mt-1 text-xs text-muted">
                    {e.issues.map((i) => `${i.count} ${i.key.replaceAll('_', ' ')}`).join(' · ')}
                  </p>
                </li>
              ))}
            </ul>
          )}
        </Card>

        <Card>
          <CardHead title="Open flags" action={{ href: '/admin/flags', label: 'All flags' }} />
          {flags.length === 0 ? (
            <p className="px-5 py-8 text-center text-sm text-muted">
              Nothing flagged.
            </p>
          ) : (
            <ul>
              {flags.map((f) => (
                <li
                  key={f.id}
                  className="flex items-start gap-2.5 border-b border-line px-5 py-3 text-sm last:border-0"
                >
                  <SeverityTag severity={f.severity} />
                  <span className="min-w-0 flex-1">
                    <span className="block">{f.reason}</span>
                    <span className="mt-0.5 block text-xs text-muted">
                      {f.entityType.replaceAll('_', ' ')} #{f.entityId}
                    </span>
                  </span>
                </li>
              ))}
            </ul>
          )}
        </Card>
      </div>
    </div>
  );
}
