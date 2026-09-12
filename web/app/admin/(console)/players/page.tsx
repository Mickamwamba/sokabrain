import Link from 'next/link';
import { Plus, UserRound } from 'lucide-react';
import { adminFetch, type Paged, type PlayerRow } from '@/lib/adminApi';
import { load, one } from '@/lib/admin-page';
import { Badge, EmptyState, ErrorState, PageHeader, Pagination, Panel, SearchBar, fmtDate } from '@/components/admin/kit';
import { btn, td, th } from '@/components/admin/styles';

export const dynamic = 'force-dynamic';

const POSITION: Record<string, string> = { GK: 'Goalkeeper', DF: 'Defender', MF: 'Midfielder', FW: 'Forward' };

export default async function AdminPlayersPage(props: PageProps<'/admin/players'>) {
  const sp = await props.searchParams;
  const q = one(sp.q) ?? '';
  const page = Math.max(1, Number(one(sp.page)) || 1);
  const params = new URLSearchParams({ page: String(page), pageSize: '30' });
  if (q) params.set('q', q);

  const res = await load(() => adminFetch<Paged<'players', PlayerRow>>(`/api/admin/players?${params}`));
  if (!res.ok) return <ErrorState message={res.error} />;
  const { players, total, pageSize } = res.data;

  const href = (p: number) => {
    const u = new URLSearchParams();
    if (q) u.set('q', q);
    if (p > 1) u.set('page', String(p));
    const s = u.toString();
    return `/admin/players${s ? `?${s}` : ''}`;
  };

  return (
    <div>
      <PageHeader
        icon={<UserRound />}
        title="Players"
        description="Everyone who appears in an event, a team sheet or a club spell."
        actions={<Link href="/admin/players/new" className={btn('primary')}><Plus /> Register player</Link>}
      />
      <Panel
        title={`${total.toLocaleString()} player${total === 1 ? '' : 's'}${q ? ` matching “${q}”` : ''}`}
        actions={<SearchBar action="/admin/players" q={q} placeholder="Search by name…" />}
      >
        {players.length === 0 ? (
          <EmptyState icon={<UserRound />} title={q ? `No player matches “${q}”` : 'No players'} />
        ) : (
          <>
            <div className="overflow-x-auto">
              <table className="w-full min-w-[760px] text-sm">
                <thead className="border-b border-line bg-wash/60">
                  <tr>
                    <th className={th}>Player</th>
                    <th className={th}>Current club</th>
                    <th className={th}>Position</th>
                    <th className={th}>Nationality</th>
                    <th className={th}>Born</th>
                    <th className={`${th} text-right`}>Events</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-line">
                  {players.map((p) => (
                    <tr key={p.id} className="hover:bg-wash/60">
                      <td className={td}>
                        <Link href={`/admin/players/${p.id}`} className="font-semibold hover:text-brand">{p.fullName}</Link>
                      </td>
                      <td className={`${td} max-w-56 truncate`} title={p.teams.length ? `All teams: ${p.teams.map((t) => t.name).join(', ')}` : undefined}>
                        {p.currentClub === 'FREE_AGENT' ? (
                          <Badge tone="amber">Free agent</Badge>
                        ) : p.currentClub ? (
                          <Link href={`/admin/teams/${p.currentClub.id}`} className="hover:text-brand">{p.currentClub.name}</Link>
                        ) : (
                          <span className="text-muted">—</span>
                        )}
                      </td>
                      <td className={`${td} text-muted`}>{p.position ? POSITION[p.position] : '—'}</td>
                      <td className={`${td} text-muted`}>{p.nationality?.replace(', United Republic of', '') ?? '—'}</td>
                      <td className={`${td} text-muted`}>{p.dob ? fmtDate(p.dob) : '—'}</td>
                      <td className={`${td} text-right nums`}>{p.events}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <Pagination page={page} pageSize={pageSize} total={total} href={href} />
          </>
        )}
      </Panel>
    </div>
  );
}
