import { Plus, Trophy } from 'lucide-react';
import { adminFetch, type Lookups } from '@/lib/adminApi';
import { load } from '@/lib/admin-page';
import { ErrorState, PageHeader, Panel } from '@/components/admin/kit';
import { ConfirmForm } from '@/components/admin/confirm-form';
import { CompetitionFields } from '@/components/admin/competition-fields';
import { createCompetitionAction } from '../../../actions';

export const dynamic = 'force-dynamic';

export default async function NewCompetitionPage() {
  const res = await load(() => adminFetch<Lookups>('/api/admin/lookups'));
  if (!res.ok) return <ErrorState message={res.error} />;

  return (
    <div className="max-w-3xl">
      <PageHeader
        icon={<Trophy />}
        title="New competition"
        description="Seasons are added from the competition’s page once it exists."
        back={{ href: '/admin/competitions', label: 'Competitions' }}
      />
      <Panel bodyClassName="p-5">
        <ConfirmForm
          action={createCompetitionAction}
          title="Create this competition?"
          description="It will have no seasons and nothing will appear on the public site yet."
          confirmLabel="Create competition"
          review="all"
          trigger={<><Plus /> Create competition</>}
          className="space-y-5"
        >
          <CompetitionFields lookups={res.data} />
        </ConfirmForm>
      </Panel>
    </div>
  );
}
