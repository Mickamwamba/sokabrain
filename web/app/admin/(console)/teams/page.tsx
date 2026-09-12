import Link from 'next/link';
import { Plus, Shield } from 'lucide-react';
import { adminFetch, type Paged, type TeamRow } from '@/lib/adminApi';
import { load, one } from '@/lib/admin-page';
import { Badge, EmptyState, ErrorState, FilterTabs, PageHeader, Pagination, Panel, SearchBar } from '@/components/admin/kit';
import { btn, td, th } from '@/components/admin/styles';
import { Crest } from '@/components/ui';

export const dynamic = 'force-dynamic';

export default async function AdminTeamsPage(props: PageProps<'/admin/teams'>) {
  const sp = await props.searchParams;
  const q = one(sp.q) ?? '';
  const type = one(sp.type) === 'NATIONAL' ? 'NATIONAL' : one(sp.type) === 'CLUB' ? 'CLUB' : undefined;
  const page = Math.max(1, Number(one(sp.page)) || 1);

  const params = new URLSearchParams({ page: String(page), pageSize: '25' });
  if (q) params.set('q', q);
  if (type) params.set('type', type);

  const res = await load(() => adminFetch<Paged<'teams', TeamRow>>(`/api/admin/teams?${params}`));
  if (!res.ok) return <ErrorState message={res.error} />;
  const { teams, total, pageSize } = res.data;

  const href = (p: Record<string, string | undefined>) => {
    const u = new URLSearchParams();
    for (const [k, v] of Object.entries({ q: q || undefined, type, ...p })) if (v) u.set(k, v);
    const s = u.toString();
    return `/admin/teams${s ? `?${s}` : ''}`;
  };

  return (
    <div>
      <PageHeader
        icon={<Shield />}
        title="Teams"
        description="Clubs and national teams. A team with match history can be edited but never deleted."
        actions={<Link href="/admin/teams/new" className={btn('primary')}><Plus /> New team</Link>}
      />

      <Panel
        title={
          <FilterTabs
            items={[
              { href: href({ type: undefined, page: undefined }), label: 'All', active: !type },
              { href: href({ type: 'CLUB', page: undefined }), label: 'Clubs', active: type === 'CLUB' },
              { href: href({ type: 'NATIONAL', page: undefined }), label: 'National teams', active: type === 'NATIONAL' },
            ]}
          />
        }
        actions={<SearchBar action="/admin/teams" q={q} placeholder="Search teams…" keep={{ type }} />}
      >
        {teams.length === 0 ? (
          <EmptyState icon={<Shield />} title={q ? `No team matches “${q}”` : 'No teams'} />
        ) : (
          <>
            <div className="overflow-x-auto">
              <table className="w-full min-w-[720px] text-sm">
                <thead className="border-b border-line bg-wash/60">
                  <tr>
                    <th className={th}>Team</th>
                    <th className={th}>Type</th>
                    <th className={th}>Country</th>
                    <th className={th}>Home ground</th>
                    <th className={`${th} text-right`}>Seasons</th>
                    <th className={`${th} text-right`}>Matches</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-line">
                  {teams.map((t) => (
                    <tr key={t.id} className="hover:bg-wash/60">
                      <td className={td}>
                        <Link href={`/admin/teams/${t.id}`} className="flex items-center gap-2.5 font-semibold hover:text-brand">
                          <Crest name={t.name} size={26} />
                          <span>
                            {t.name}
                            {t.shortName ? <span className="ml-1.5 text-xs font-normal text-muted">{t.shortName}</span> : null}
                          </span>
                        </Link>
                      </td>
                      <td className={td}>
                        {t.type === 'NATIONAL' ? <Badge tone="blue">National</Badge> : <Badge>Club</Badge>}
                      </td>
                      <td className={`${td} text-muted`}>{t.country.replace(', United Republic of', '')}</td>
                      <td className={`${td} text-muted`}>{t.stadium ?? '—'}</td>
                      <td className={`${td} text-right nums`}>{t.seasons}</td>
                      <td className={`${td} text-right nums`}>{t.matches.toLocaleString()}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <Pagination page={page} pageSize={pageSize} total={total} href={(p) => href({ page: String(p) })} />
          </>
        )}
      </Panel>
    </div>
  );
}
