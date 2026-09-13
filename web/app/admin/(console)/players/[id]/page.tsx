import Link from 'next/link';
import { ArrowRightLeft, Save, Trash2, UserRound } from 'lucide-react';
import {
  adminFetch, type AuditFindings, type Career, type CareerSpell, type Lookups, type PlayerRecord, type TeamOption, type Usage,
} from '@/lib/adminApi';
import { load, one } from '@/lib/admin-page';
import { safeReturn } from '@/lib/audit-targets';
import { EntityFindings } from '@/components/admin/entity-findings';
import { Badge, ErrorState, Facts, PageHeader, Panel } from '@/components/admin/kit';
import { ConfirmForm } from '@/components/admin/confirm-form';
import { PlayerFields } from '@/components/admin/player-fields';
import { TransferForm } from '@/components/admin/transfer-form';
import { btn } from '@/components/admin/styles';
import { CareerHistory, CareerStatusLine } from '@/components/admin/career';
import {
  addSpellAction, deletePlayerAction, deleteSpellAction, endSpellAction,
  recordTransferAction, savePlayerAction, updateSpellAction,
} from '../../../manage-actions';

export const dynamic = 'force-dynamic';

export default async function EditPlayerPage(props: PageProps<'/admin/players/[id]'>) {
  const { id } = await props.params;
  const sp = await props.searchParams;
  const returnTo = safeReturn(one(sp.from));
  const pid = Number(id);
  const res = await load(() =>
    Promise.all([
      adminFetch<{ player: PlayerRecord; usage: Usage }>(`/api/admin/players/${pid}`),
      adminFetch<Lookups>('/api/admin/lookups'),
      adminFetch<Career>(`/api/admin/players/${pid}/career`),
      adminFetch<{ teams: TeamOption[] }>('/api/admin/team-options').then((r) => r.teams),
      adminFetch<AuditFindings>(`/api/admin/audit/findings?entityType=player&entityId=${pid}&status=ACTIVE`).then((r) => r.findings),
    ]),
  );
  if (!res.ok) return <ErrorState message={res.error} />;
  const [{ player, usage }, lookups, career, teams, findings] = res.data;
  const clubs = teams.filter((t) => t.type === 'CLUB');
  // Career spells go with the player; only match history blocks a delete.
  const inUse = usage.filter((u) => u.count > 0 && !/club spell/.test(u.label));

  const s = career.status;
  const running: CareerSpell[] =
    s.kind === 'AT_CLUB' ? [s.club, ...(s.loan ? [s.loan] : [])] : s.kind === 'ON_LOAN_ONLY' ? [s.loan] : [];

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<UserRound />}
        title={player.full_name}
        description={<CareerStatusLine career={career} />}
        back={{ href: '/admin/players', label: 'Players' }}
      />

      <div className="grid gap-6 xl:grid-cols-3">
        <div className="space-y-6 xl:col-span-2">
          <EntityFindings findings={findings} returnTo={returnTo} auditHref={`/admin/audit?area=Careers`} />
          <CareerHistory
            career={career}
            teams={teams}
            actions={{ update: updateSpellAction, end: endSpellAction, remove: deleteSpellAction, add: addSpellAction }}
          />

          <Panel title="Details" bodyClassName="p-5">
            <ConfirmForm
              action={savePlayerAction}
              title={`Save changes to ${player.full_name}?`}
              confirmLabel="Save changes"
              review="changes"
              trigger={<><Save /> Save changes</>}
              className="space-y-5"
            >
              <input type="hidden" name="playerId" value={player.id} />
              <PlayerFields lookups={lookups} initial={player} />
            </ConfirmForm>
          </Panel>
        </div>

        <div className="space-y-6">
          <Panel
            title="Record a move"
            description="A transfer, a loan, or a release. The spells it ends are closed for you."
            actions={
              <Link href={`/admin/transfers?playerId=${player.id}`} className={btn('ghost', 'sm')}>
                <ArrowRightLeft /> Transfer centre
              </Link>
            }
          >
            <TransferForm
              playerId={player.id}
              playerName={player.full_name}
              clubs={clubs}
              running={running.filter((r) => r.team.type === 'CLUB')}
              today={career.today}
              action={recordTransferAction}
            />
          </Panel>

          <Panel title="Records that depend on it">
            <Facts
              items={usage.map((u) => ({
                label: u.label.charAt(0).toUpperCase() + u.label.slice(1),
                value: u.count ? u.count.toLocaleString() : <span className="text-muted">0</span>,
              }))}
            />
          </Panel>

          <Panel title="Delete player" tone="danger" bodyClassName="space-y-3 p-5 text-sm">
            {inUse.length ? (
              <p className="text-muted">
                <Badge tone="red">In use</Badge>{' '}
                It has {inUse.map((u) => `${u.count.toLocaleString()} ${u.label}`).join(', ')}, so it cannot be deleted.
              </p>
            ) : (
              <p className="text-muted">
                No match history refers to this player, so it can be deleted.
                {career.clubSpells.length + career.nationalSpells.length ? ' Their career spells are deleted with them.' : ''}
              </p>
            )}
            <ConfirmForm
              action={deletePlayerAction}
              tone="danger"
              title={`Delete ${player.full_name}?`}
              description="This cannot be undone."
              confirmLabel="Delete player"
              trigger={<><Trash2 /> Delete player</>}
              triggerVariant="danger"
              disabled={inUse.length > 0}
            >
              <input type="hidden" name="playerId" value={player.id} />
            </ConfirmForm>
          </Panel>
        </div>
      </div>
    </div>
  );
}
