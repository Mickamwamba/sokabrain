import Link from 'next/link';
import { Plus, Trophy } from 'lucide-react';
import { adminFetch, type AdminCompetition } from '@/lib/adminApi';
import { load, one } from '@/lib/admin-page';
import {
  Badge,
  EmptyState,
  ErrorState,
  FilterTabs,
  PageHeader,
  Panel,
  SearchBar,
  humanise,
} from '@/components/admin/kit';
import { btn, td, th } from '@/components/admin/styles';

export const dynamic = 'force-dynamic';

export default async function AdminCompetitionsPage(props: PageProps<'/admin/competitions'>) {
  const sp = await props.searchParams;
  const q = one(sp.q) ?? '';
  const status = one(sp.status) ?? 'ALL'; // ALL | PUBLIC | HIDDEN

  const res = await load(() =>
    adminFetch<{ competitions: AdminCompetition[] }>(
      `/api/admin/competitions${q ? `?q=${encodeURIComponent(q)}` : ''}`,
    ).then((r) => r.competitions),
  );
  if (!res.ok) return <ErrorState message={res.error} />;
  const allCompetitions = res.data;

  // Ensure published competitions always appear first, then sorted alphabetically
  const sorted = [...allCompetitions].sort((a, b) => {
    const aPub = a.publishedCount > 0 ? 1 : 0;
    const bPub = b.publishedCount > 0 ? 1 : 0;
    if (aPub !== bPub) return bPub - aPub;
    return a.displayName.localeCompare(b.displayName);
  });

  const publicCount = sorted.filter((c) => c.publishedCount > 0).length;
  const hiddenCount = sorted.filter((c) => c.publishedCount === 0).length;

  const filtered = sorted.filter((c) => {
    if (status === 'PUBLIC') return c.publishedCount > 0;
    if (status === 'HIDDEN') return c.publishedCount === 0;
    return true;
  });

  const queryParams = new URLSearchParams();
  if (q) queryParams.set('q', q);

  const hrefForStatus = (val: string) => {
    const u = new URLSearchParams(queryParams);
    if (val === 'ALL') u.delete('status');
    else u.set('status', val);
    const s = u.toString();
    return `/admin/competitions${s ? `?${s}` : ''}`;
  };

  const statusTabs = [
    {
      href: hrefForStatus('ALL'),
      label: 'All',
      active: status === 'ALL',
      count: sorted.length,
    },
    {
      href: hrefForStatus('PUBLIC'),
      label: 'Public / Live',
      active: status === 'PUBLIC',
      count: publicCount,
    },
    {
      href: hrefForStatus('HIDDEN'),
      label: 'Hidden',
      active: status === 'HIDDEN',
      count: hiddenCount,
    },
  ];

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<Trophy />}
        title="Competitions"
        description="Leagues, cups and tournaments. Public competitions appear at the top. Open one to manage its seasons."
        actions={
          <Link href="/admin/competitions/new" className={btn('primary')}>
            <Plus /> New competition
          </Link>
        }
      />

      <FilterTabs items={statusTabs} />

      <Panel
        title={`${filtered.length} competition${filtered.length === 1 ? '' : 's'}`}
        actions={<SearchBar action="/admin/competitions" q={q} placeholder="Search by name or country…" keep={{ status: status === 'ALL' ? '' : status }} />}
      >
        {filtered.length === 0 ? (
          <EmptyState
            icon={<Trophy />}
            title={q ? `Nothing matches "${q}"` : 'No competitions found'}
            action={
              <Link href="/admin/competitions/new" className={btn('primary', 'sm')}>
                <Plus /> New competition
              </Link>
            }
          />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[720px] text-sm">
              <thead className="border-b border-line bg-wash/60">
                <tr>
                  <th className={th}>Competition</th>
                  <th className={th}>Country</th>
                  <th className={th}>Type</th>
                  <th className={`${th} text-right`}>Seasons</th>
                  <th className={`${th} text-right`}>Matches</th>
                  <th className={th}>Public</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-line">
                {filtered.map((c) => (
                  <tr key={c.id} className="hover:bg-wash/60">
                    <td className={td}>
                      <Link href={`/admin/competitions/${c.id}`} className="font-semibold hover:text-brand">
                        {c.displayName}
                      </Link>
                      {c.tier ? <span className="ml-2 text-xs text-muted">Tier {c.tier}</span> : null}
                    </td>
                    <td className={`${td} text-muted`}>
                      {c.country?.replace(', United Republic of', '') ?? 'International'}
                    </td>
                    <td className={`${td} text-muted`}>{humanise(c.type)}</td>
                    <td className={`${td} text-right nums`}>{c.seasonCount}</td>
                    <td className={`${td} text-right nums`}>{c.matchCount.toLocaleString()}</td>
                    <td className={td}>
                      {c.publishedCount > 0 ? (
                        <Badge tone="green" dot>
                          {c.publishedCount} live
                        </Badge>
                      ) : (
                        <Badge>Hidden</Badge>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Panel>
    </div>
  );
}
