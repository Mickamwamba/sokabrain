import { UserPlus, UserRound } from 'lucide-react';
import { adminFetch, type Lookups, type TeamOption } from '@/lib/adminApi';
import { load } from '@/lib/admin-page';
import { ErrorState, PageHeader, Panel } from '@/components/admin/kit';
import { ConfirmForm } from '@/components/admin/confirm-form';
import { PlayerFields } from '@/components/admin/player-fields';
import { ClubAtRegistration } from '@/components/admin/club-at-registration';
import { savePlayerAction } from '../../../manage-actions';

export const dynamic = 'force-dynamic';

export default async function NewPlayerPage() {
  const res = await load(() =>
    Promise.all([
      adminFetch<Lookups>('/api/admin/lookups'),
      adminFetch<{ teams: TeamOption[] }>('/api/admin/team-options?type=CLUB').then((r) => r.teams),
    ]),
  );
  if (!res.ok) return <ErrorState message={res.error} />;
  const [lookups, clubs] = res.data;

  return (
    <div className="max-w-3xl">
      <PageHeader icon={<UserRound />} title="Register a player" back={{ href: '/admin/players', label: 'Players' }}
        description="Search first — the same player under a different spelling splits their record in two." />
      <ConfirmForm
        action={savePlayerAction}
        title="Register this player?"
        confirmLabel="Register player"
        review="all"
        trigger={<><UserPlus /> Register player</>}
        className="space-y-6"
      >
        <Panel title="Player" bodyClassName="p-5">
          <PlayerFields lookups={lookups} />
        </Panel>
        <Panel title="Club" description="Moves after today are recorded from the player’s page." bodyClassName="p-5">
          <ClubAtRegistration clubs={clubs} today={new Date().toISOString().slice(0, 10)} />
        </Panel>
      </ConfirmForm>
    </div>
  );
}
