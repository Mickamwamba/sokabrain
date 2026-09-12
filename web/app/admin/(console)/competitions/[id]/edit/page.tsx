import { Pencil, Save, Trash2 } from 'lucide-react';
import { adminFetch, type AdminEditionRow, type Lookups } from '@/lib/adminApi';
import { load } from '@/lib/admin-page';
import { ErrorState, PageHeader, Panel } from '@/components/admin/kit';
import { ConfirmForm } from '@/components/admin/confirm-form';
import { CompetitionFields } from '@/components/admin/competition-fields';
import { deleteCompetitionAction, updateCompetitionAction } from '../../../../actions';

export const dynamic = 'force-dynamic';

type Detail = {
  competition: { id: number; name: string; type: string; tier: number | null; countryId: number | null };
  editions: AdminEditionRow[];
};

export default async function EditCompetitionPage(props: PageProps<'/admin/competitions/[id]/edit'>) {
  const { id } = await props.params;
  const res = await load(() =>
    Promise.all([
      adminFetch<Detail>(`/api/admin/competitions/${Number(id)}`),
      adminFetch<Lookups>('/api/admin/lookups'),
    ]),
  );
  if (!res.ok) return <ErrorState message={res.error} />;
  const [{ competition, editions }, lookups] = res.data;

  return (
    <div className="max-w-3xl space-y-6">
      <PageHeader
        icon={<Pencil />}
        title={`Edit ${competition.name}`}
        back={{ href: `/admin/competitions/${competition.id}`, label: competition.name }}
      />

      <Panel title="Details" bodyClassName="p-5">
        <ConfirmForm
          action={updateCompetitionAction}
          title={`Save changes to ${competition.name}?`}
          description="Renaming changes how it appears everywhere on the public site."
          confirmLabel="Save changes"
          review="changes"
          trigger={<><Save /> Save changes</>}
          className="space-y-5"
        >
          <input type="hidden" name="competitionId" value={competition.id} />
          <CompetitionFields lookups={lookups} initial={competition} />
        </ConfirmForm>
      </Panel>

      <Panel title="Delete competition" tone="danger" bodyClassName="space-y-3 p-5 text-sm">
        <p className="text-muted">
          {editions.length
            ? `It has ${editions.length} season${editions.length === 1 ? '' : 's'}. Delete those from the competition page first — a competition is never removed along with its history.`
            : 'It has no seasons, so it can be deleted.'}
        </p>
        <ConfirmForm
          action={deleteCompetitionAction}
          tone="danger"
          title={`Delete ${competition.name}?`}
          description="This cannot be undone."
          confirmLabel="Delete competition"
          trigger={<><Trash2 /> Delete competition</>}
          triggerVariant="danger"
          disabled={editions.length > 0}
        >
          <input type="hidden" name="competitionId" value={competition.id} />
        </ConfirmForm>
      </Panel>
    </div>
  );
}
