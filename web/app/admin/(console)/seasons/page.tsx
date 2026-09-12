import Link from 'next/link';
import { CalendarRange, Pencil, Plus } from 'lucide-react';
import { adminFetch, type SeasonRow } from '@/lib/adminApi';
import { load } from '@/lib/admin-page';
import { Badge, EmptyState, ErrorState, PageHeader, Panel, fmtDate } from '@/components/admin/kit';
import { ConfirmForm } from '@/components/admin/confirm-form';
import { SeasonFields } from '@/components/admin/season-fields';
import { iconBtn, td, th } from '@/components/admin/styles';
import { saveSeasonAction } from '../../manage-actions';

export const dynamic = 'force-dynamic';

export default async function AdminSeasonsPage() {
  const res = await load(() => adminFetch<{ seasons: SeasonRow[] }>('/api/admin/seasons').then((r) => r.seasons));
  if (!res.ok) return <ErrorState message={res.error} />;
  const seasons = res.data;

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<CalendarRange />}
        title="Seasons"
        description="The calendar every competition’s editions hang off. A season on its own shows nothing publicly."
      />

      <div className="grid gap-6 xl:grid-cols-3">
        <Panel className="xl:col-span-2" title={`${seasons.length} seasons`}>
          {seasons.length === 0 ? (
            <EmptyState icon={<CalendarRange />} title="No seasons yet" />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full min-w-[640px] text-sm">
                <thead className="border-b border-line bg-wash/60">
                  <tr>
                    <th className={th}>Season</th>
                    <th className={th}>Dates</th>
                    <th className={th}>Competitions</th>
                    <th className={th}>Public</th>
                    <th className={th}><span className="sr-only">Actions</span></th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-line">
                  {seasons.map((s) => (
                    <tr key={s.id} className="hover:bg-wash/60">
                      <td className={td}>
                        <Link href={`/admin/seasons/${s.id}`} className="font-semibold hover:text-brand">{s.label}</Link>
                      </td>
                      <td className={`${td} text-xs text-muted`}>
                        {s.startDate || s.endDate ? `${fmtDate(s.startDate)} – ${fmtDate(s.endDate)}` : '—'}
                      </td>
                      <td className={`${td} text-xs text-muted`}>
                        {s.competitions.length ? s.competitions.join(', ') : <span className="italic">None</span>}
                      </td>
                      <td className={td}>
                        {s.published ? <Badge tone="green" dot>{s.published} live</Badge> : <Badge>—</Badge>}
                      </td>
                      <td className={`${td} text-right`}>
                        <Link href={`/admin/seasons/${s.id}`} aria-label={`Edit ${s.label}`} className={iconBtn()}>
                          <Pencil />
                        </Link>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Panel>

        <Panel title="Add a season" description="Then add it to a competition from that competition’s page." className="self-start">
          <ConfirmForm
            action={saveSeasonAction}
            title="Create this season?"
            description="No competition will use it until you add an edition for it."
            confirmLabel="Create season"
            review="all"
            resetOnSuccess
            trigger={<><Plus /> Add season</>}
            className="space-y-4 p-5 [&_.grid]:sm:grid-cols-1"
          >
            <SeasonFields />
          </ConfirmForm>
        </Panel>
      </div>
    </div>
  );
}
