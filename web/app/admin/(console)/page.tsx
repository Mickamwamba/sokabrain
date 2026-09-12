import Link from 'next/link';
import {
  ArrowRight,
  CalendarRange,
  CircleCheck,
  Eye,
  Flag as FlagIcon,
  LayoutDashboard,
  Shield,
  TriangleAlert,
  Trophy,
  UserRound,
} from 'lucide-react';
import {
  adminFetch,
  type AdminCompetition,
  type AdminEdition,
  type Flag,
  type Paged,
  type PlayerRow,
  type SeasonRow,
  type TeamRow,
} from '@/lib/adminApi';
import { load } from '@/lib/admin-page';
import { Badge, EmptyState, ErrorState, PageHeader, Panel, SeverityBadge, StatCard } from '@/components/admin/kit';
import { btn } from '@/components/admin/styles';

export const dynamic = 'force-dynamic';

export default async function AdminDashboardPage() {
  const res = await load(() =>
    Promise.all([
      adminFetch<{ editions: AdminEdition[] }>('/api/admin/editions').then((r) => r.editions),
      adminFetch<{ flags: Flag[] }>('/api/admin/flags?status=OPEN&limit=6').then((r) => r.flags),
      adminFetch<{ competitions: AdminCompetition[] }>('/api/admin/competitions').then((r) => r.competitions),
      adminFetch<{ seasons: SeasonRow[] }>('/api/admin/seasons').then((r) => r.seasons),
      adminFetch<Paged<'teams', TeamRow>>('/api/admin/teams?pageSize=1').then((r) => r.total),
      adminFetch<Paged<'players', PlayerRow>>('/api/admin/players?pageSize=1').then((r) => r.total),
    ]),
  );
  if (!res.ok) return <ErrorState message={res.error} />;
  const [editions, flags, competitions, seasons, teamCount, playerCount] = res.data;

  const live = editions.filter((e) => e.isPublished);
  const issueCount = (e: AdminEdition) => e.issues.reduce((n, i) => n + i.count, 0);
  const withIssues = editions
    .filter((e) => e.matchCount > 0 && e.issues.length > 0)
    .sort((a, b) =>
      // Published seasons first: a problem the public can already see matters most.
      a.isPublished !== b.isPublished ? (a.isPublished ? -1 : 1) : issueCount(b) - issueCount(a),
    );
  const blocked = editions.filter((e) => !e.canPublish).length;

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<LayoutDashboard />}
        title="Dashboard"
        description="What the public can see, what the vault holds, and what still needs fixing."
        actions={
          <Link href="/" target="_blank" className={btn('secondary')}>
            <Eye /> View public site
          </Link>
        }
      />

      <div className="grid grid-cols-2 gap-4 lg:grid-cols-5">
        <StatCard label="Competitions" value={competitions.length} icon={<Trophy />} tone="blue"
          hint={`${competitions.filter((c) => c.publishedCount > 0).length} with live seasons`} />
        <StatCard label="Seasons live" value={live.length} icon={<CalendarRange />} tone="green"
          hint={`of ${editions.length} editions · ${seasons.length} seasons`} />
        <StatCard label="Teams" value={teamCount} icon={<Shield />} tone="gray" />
        <StatCard label="Players" value={playerCount} icon={<UserRound />} tone="gray" />
        <StatCard label="Open flags" value={flags.length === 6 ? '6+' : flags.length} icon={<FlagIcon />}
          tone={flags.length ? 'amber' : 'green'} hint={blocked ? `${blocked} editions blocked` : 'nothing blocking'} />
      </div>

      <div className="grid gap-6 xl:grid-cols-3">
        <Panel
          className="xl:col-span-2"
          title="Live on the public site"
          description={`${live.reduce((n, e) => n + e.matchCount, 0).toLocaleString()} public matches across ${live.length} seasons`}
          actions={<Link href="/admin/competitions" className={btn('secondary', 'sm')}>Manage <ArrowRight /></Link>}
        >
          {live.length === 0 ? (
            <EmptyState icon={<Eye />} title="Nothing is published">
              Fans see an empty site until you release a season from its competition page.
            </EmptyState>
          ) : (
            <ul className="max-h-[26rem] divide-y divide-line overflow-y-auto">
              {live.map((e) => (
                <li key={e.editionId} className="flex items-center gap-3 px-5 py-3 text-sm">
                  <span className="min-w-0 flex-1">
                    <span className="block truncate font-semibold">
                      {e.competition} <span className="font-normal text-muted">{e.season}</span>
                    </span>
                    <span className="block text-xs text-muted">{e.matchCount} matches</span>
                  </span>
                  {e.issues.length ? (
                    <Badge tone="amber">{issueCount(e)} issues</Badge>
                  ) : (
                    <Badge tone="green"><CircleCheck className="h-3 w-3" /> Clean</Badge>
                  )}
                  <Link href={`/admin/issues?editionId=${e.editionId}`} className={btn('ghost', 'sm')}>
                    Review <ArrowRight />
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </Panel>

        <Panel
          title="Open flags"
          actions={<Link href="/admin/flags" className={btn('secondary', 'sm')}>All flags <ArrowRight /></Link>}
        >
          {flags.length === 0 ? (
            <EmptyState icon={<CircleCheck />} title="Nothing flagged" />
          ) : (
            <ul className="divide-y divide-line">
              {flags.map((f) => (
                <li key={f.id} className="px-5 py-3 text-sm">
                  <div className="flex items-center gap-2">
                    <SeverityBadge severity={f.severity} />
                    <span className="text-xs text-muted">
                      {f.entityType.replaceAll('_', ' ')} #{f.entityId}
                    </span>
                  </div>
                  <p className="mt-1 line-clamp-2">{f.reason}</p>
                </li>
              ))}
            </ul>
          )}
        </Panel>
      </div>

      <Panel title="Needs attention" description="Seasons with problems detected in their data, live seasons first">
        {withIssues.length === 0 ? (
          <EmptyState icon={<CircleCheck />} title="No problems detected" />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[640px] text-sm">
              <tbody className="divide-y divide-line">
                {withIssues.slice(0, 8).map((e) => (
                  <tr key={e.editionId} className="hover:bg-wash/60">
                    <td className="py-3 pl-5 pr-3">
                      <span className="font-semibold">{e.competition}</span>{' '}
                      <span className="text-muted">{e.season}</span>
                    </td>
                    <td className="px-3 py-3">
                      {e.isPublished ? <Badge tone="green" dot>Live</Badge> : <Badge>Hidden</Badge>}
                    </td>
                    <td className="px-3 py-3 text-xs text-muted">
                      {e.issues.map((i) => `${i.count} ${i.label}`).join(' · ')}
                    </td>
                    <td className="py-3 pl-3 pr-5 text-right">
                      <Link href={`/admin/issues?editionId=${e.editionId}`} className={btn('secondary', 'sm')}>
                        <TriangleAlert /> Fix
                      </Link>
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
