import Link from 'next/link';
import { ExternalLink, Save, Trash2, Users } from 'lucide-react';
import { adminFetch, type Lookups, type Squad, type TeamRecord, type Usage } from '@/lib/adminApi';
import { load } from '@/lib/admin-page';
import { Badge, EmptyState, ErrorState, Facts, PageHeader, Panel } from '@/components/admin/kit';
import { fmtDay } from '@/components/admin/career';
import { ConfirmForm } from '@/components/admin/confirm-form';
import { TeamFields } from '@/components/admin/team-fields';
import { btn } from '@/components/admin/styles';
import { Crest } from '@/components/ui';
import { deleteTeamAction, saveTeamAction } from '../../../manage-actions';

export const dynamic = 'force-dynamic';

export default async function EditTeamPage(props: PageProps<'/admin/teams/[id]'>) {
  const { id } = await props.params;
  const res = await load(() =>
    Promise.all([
      adminFetch<{ team: TeamRecord; usage: Usage }>(`/api/admin/teams/${Number(id)}`),
      adminFetch<Lookups>('/api/admin/lookups'),
      adminFetch<Squad>(`/api/admin/teams/${Number(id)}/squad`),
    ]),
  );
  if (!res.ok) return <ErrorState message={res.error} />;
  const [{ team, usage }, lookups, squad] = res.data;
  const POS: Record<string, string> = { GK: 'GK', DF: 'DF', MF: 'MF', FW: 'FW' };
  const inUse = usage.filter((u) => u.count > 0);

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<Crest name={team.name} size={40} />}
        title={team.name}
        description={team.type === 'NATIONAL' ? 'National team' : 'Club'}
        back={{ href: '/admin/teams', label: 'Teams' }}
        actions={
          <Link href={`/teams/${team.id}`} target="_blank" className={btn('secondary')}>
            <ExternalLink /> Public page
          </Link>
        }
      />

      <div className="grid gap-6 xl:grid-cols-3">
        <div className="space-y-6 xl:col-span-2">
        <Panel
          title={team.type === 'NATIONAL' ? 'Current squad' : 'Current players'}
          description={`Spells running today · ${squad.former.length} former player${squad.former.length === 1 ? '' : 's'}`}
        >
          {squad.current.length === 0 ? (
            <EmptyState icon={<Users />} title="Nobody recorded at this team today">
              Register a player with this club, or record a move to it from a player’s page.
            </EmptyState>
          ) : (
            <ul className="grid divide-y divide-line sm:grid-cols-2 sm:divide-y-0">
              {squad.current.map((e) => (
                <li key={e.spellId} className="flex items-center gap-3 border-line px-5 py-2.5 text-sm sm:border-b">
                  <span className="w-7 shrink-0 text-center font-semibold text-muted nums">{e.shirtNumber ?? '—'}</span>
                  <span className="min-w-0 flex-1">
                    <Link href={`/admin/players/${e.player.id}`} className="block truncate font-semibold hover:text-brand">{e.player.name}</Link>
                    <span className="block text-xs text-muted">since {fmtDay(e.start)}{e.type === 'LOAN' ? ' · on loan' : ''}</span>
                  </span>
                  {e.player.position ? <Badge>{POS[e.player.position]}</Badge> : null}
                </li>
              ))}
            </ul>
          )}
          {squad.former.length ? (
            <details className="border-t border-line">
              <summary className="cursor-pointer px-5 py-3 text-sm font-semibold text-muted hover:text-ink">
                Former players ({squad.former.length})
              </summary>
              <ul className="max-h-80 divide-y divide-line overflow-y-auto border-t border-line">
                {squad.former.map((e) => (
                  <li key={e.spellId} className="flex items-center justify-between gap-3 px-5 py-2 text-sm">
                    <Link href={`/admin/players/${e.player.id}`} className="truncate hover:text-brand">{e.player.name}</Link>
                    <span className="shrink-0 text-xs text-muted">{fmtDay(e.start)} – {fmtDay(e.end)}</span>
                  </li>
                ))}
              </ul>
            </details>
          ) : null}
        </Panel>

        <Panel title="Details" bodyClassName="p-5">
          <ConfirmForm
            action={saveTeamAction}
            title={`Save changes to ${team.name}?`}
            description="Changes show on the public site straight away, everywhere the team appears."
            confirmLabel="Save changes"
            review="changes"
            trigger={<><Save /> Save changes</>}
            className="space-y-5"
          >
            <input type="hidden" name="teamId" value={team.id} />
            <TeamFields lookups={lookups} initial={team} />
          </ConfirmForm>
        </Panel>
        </div>

        <div className="space-y-6">
          <Panel title="Records that depend on it">
            <Facts
              items={usage.map((u) => ({
                label: u.label.charAt(0).toUpperCase() + u.label.slice(1),
                value: u.count ? u.count.toLocaleString() : <span className="text-muted">0</span>,
              }))}
            />
          </Panel>

          <Panel title="Delete team" tone="danger" bodyClassName="space-y-3 p-5 text-sm">
            {inUse.length ? (
              <p className="text-muted">
                <Badge tone="red">In use</Badge>{' '}
                It has {inUse.map((u) => `${u.count.toLocaleString()} ${u.label}`).join(', ')}. A team with history is
                never deleted — rename it instead if it has changed name.
              </p>
            ) : (
              <p className="text-muted">Nothing refers to this team, so it can be deleted.</p>
            )}
            <ConfirmForm
              action={deleteTeamAction}
              tone="danger"
              title={`Delete ${team.name}?`}
              description="This cannot be undone."
              confirmLabel="Delete team"
              trigger={<><Trash2 /> Delete team</>}
              triggerVariant="danger"
              disabled={inUse.length > 0}
            >
              <input type="hidden" name="teamId" value={team.id} />
            </ConfirmForm>
          </Panel>
        </div>
      </div>
    </div>
  );
}
