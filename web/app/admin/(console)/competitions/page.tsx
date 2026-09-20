import Link from 'next/link';
import { Plus, Trophy } from 'lucide-react';
import { adminFetch, type AdminCompetition } from '@/lib/adminApi';
import { load, one } from '@/lib/admin-page';
import { Badge, EmptyState, ErrorState, PageHeader, Panel, SearchBar, humanise } from '@/components/admin/kit';
import { btn, td, th } from '@/components/admin/styles';

export const dynamic = 'force-dynamic';

export default async function AdminCompetitionsPage(props: PageProps<'/admin/competitions'>) {
  const sp = await props.searchParams;
  const q = one(sp.q) ?? '';

  const res = await load(() =>
    adminFetch<{ competitions: AdminCompetition[] }>(
      `/api/admin/competitions${q ? `?q=${encodeURIComponent(q)}` : ''}`,
    ).then((r) => r.competitions),
  );
  if (!res.ok) return <ErrorState message={res.error} />;
  const competitions = res.data;

  return (
    <div>
      <PageHeader
        icon={<Trophy />}
        title="Competitions"
        description="Leagues, cups and tournaments. Open one to manage its seasons and publish them."
        actions={
          <Link href="/admin/competitions/new" className={btn('primary')}>
            <Plus /> New competition
          </Link>
        }
      />

      <Panel
        title={`${competitions.length} competition${competitions.length === 1 ? '' : 's'}`}
        actions={<SearchBar action="/admin/competitions" q={q} placeholder="Search by name or country…" />}
      >
        {competitions.length === 0 ? (
          <EmptyState
            icon={<Trophy />}
            title={q ? `Nothing matches “${q}”` : 'No competitions yet'}
            action={<Link href="/admin/competitions/new" className={btn('primary', 'sm')}><Plus /> New competition</Link>}
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
                {competitions.map((c) => (
                  <tr key={c.id} className="hover:bg-wash/60">
                    <td className={td}>
                      <Link href={`/admin/competitions/${c.id}`} className="font-semibold hover:text-brand">
                        {c.displayName}
                      </Link>
                      {c.tier ? <span className="ml-2 text-xs text-muted">Tier {c.tier}</span> : null}
                    </td>
                    <td className={`${td} text-muted`}>{c.country?.replace(', United Republic of', '') ?? 'International'}</td>
                    <td className={`${td} text-muted`}>{humanise(c.type)}</td>
                    <td className={`${td} text-right nums`}>{c.seasonCount}</td>
                    <td className={`${td} text-right nums`}>{c.matchCount.toLocaleString()}</td>
                    <td className={td}>
                      {c.publishedCount > 0 ? (
                        <Badge tone="green" dot>{c.publishedCount} live</Badge>
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
