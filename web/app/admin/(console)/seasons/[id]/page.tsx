import Link from 'next/link';
import { CalendarRange, Save, Trash2 } from 'lucide-react';
import { adminFetch, type SeasonRow } from '@/lib/adminApi';
import { load } from '@/lib/admin-page';
import { ErrorState, PageHeader, Panel } from '@/components/admin/kit';
import { notFound } from 'next/navigation';
import { ConfirmForm } from '@/components/admin/confirm-form';
import { SeasonFields } from '@/components/admin/season-fields';
import { deleteSeasonAction, saveSeasonAction } from '../../../manage-actions';

export const dynamic = 'force-dynamic';

export default async function EditSeasonPage(props: PageProps<'/admin/seasons/[id]'>) {
  const { id } = await props.params;
  const res = await load(() => adminFetch<{ seasons: SeasonRow[] }>('/api/admin/seasons').then((r) => r.seasons));
  if (!res.ok) return <ErrorState message={res.error} />;
  const season = res.data.find((s) => String(s.id) === id);
  if (!season) notFound();

  return (
    <div className="max-w-3xl space-y-6">
      <PageHeader
        icon={<CalendarRange />}
        title={`Season ${season.label}`}
        description={
          season.editions
            ? `Used by ${season.editions} competition edition${season.editions === 1 ? '' : 's'}: ${season.competitions.join(', ')}.`
            : 'Not used by any competition yet.'
        }
        back={{ href: '/admin/seasons', label: 'Seasons' }}
      />

      <Panel title="Details" bodyClassName="p-5">
        <ConfirmForm
          action={saveSeasonAction}
          title={`Save changes to ${season.label}?`}
          description={season.editions ? 'A new label shows on every competition that uses this season.' : undefined}
          confirmLabel="Save changes"
          review="changes"
          trigger={<><Save /> Save changes</>}
          className="space-y-5"
        >
          <input type="hidden" name="seasonId" value={season.id} />
          <SeasonFields initial={season} />
        </ConfirmForm>
      </Panel>

      <Panel title="Delete season" tone="danger" bodyClassName="space-y-3 p-5 text-sm">
        <p className="text-muted">
          {season.editions ? (
            <>
              It is used by {season.editions} edition{season.editions === 1 ? '' : 's'}. Remove those from their{' '}
              <Link href="/admin/competitions" className="font-semibold text-ink underline">competitions</Link> first.
            </>
          ) : (
            'Nothing uses it, so it can be deleted.'
          )}
        </p>
        <ConfirmForm
          action={deleteSeasonAction}
          tone="danger"
          title={`Delete season ${season.label}?`}
          description="This cannot be undone."
          confirmLabel="Delete season"
          trigger={<><Trash2 /> Delete season</>}
          triggerVariant="danger"
          disabled={season.editions > 0}
        >
          <input type="hidden" name="seasonId" value={season.id} />
        </ConfirmForm>
      </Panel>
    </div>
  );
}
