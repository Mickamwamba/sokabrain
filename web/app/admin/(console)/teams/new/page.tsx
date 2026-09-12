import { Plus, Shield } from 'lucide-react';
import { adminFetch, type Lookups } from '@/lib/adminApi';
import { load } from '@/lib/admin-page';
import { ErrorState, PageHeader, Panel } from '@/components/admin/kit';
import { ConfirmForm } from '@/components/admin/confirm-form';
import { TeamFields } from '@/components/admin/team-fields';
import { saveTeamAction } from '../../../manage-actions';

export const dynamic = 'force-dynamic';

export default async function NewTeamPage() {
  const res = await load(() => adminFetch<Lookups>('/api/admin/lookups'));
  if (!res.ok) return <ErrorState message={res.error} />;
  return (
    <div className="max-w-3xl">
      <PageHeader icon={<Shield />} title="New team" back={{ href: '/admin/teams', label: 'Teams' }}
        description="Check the team doesn’t already exist under a former name — a rename is an edit, not a new team." />
      <Panel bodyClassName="p-5">
        <ConfirmForm
          action={saveTeamAction}
          title="Create this team?"
          confirmLabel="Create team"
          review="all"
          trigger={<><Plus /> Create team</>}
          className="space-y-5"
        >
          <TeamFields lookups={res.data} />
        </ConfirmForm>
      </Panel>
    </div>
  );
}
