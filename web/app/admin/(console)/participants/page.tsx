import Link from 'next/link';
import { ListChecks, Plus, Save, Trash2, Users } from 'lucide-react';
import { adminFetch, type AdminCompetition, type AuditFindings, type Participants } from '@/lib/adminApi';
import { safeReturn } from '@/lib/audit-targets';
import { EntityFindings } from '@/components/admin/entity-findings';
import { load, one } from '@/lib/admin-page';
import { Badge, EmptyState, ErrorState, Field, PageHeader, Panel } from '@/components/admin/kit';
import { ConfirmForm } from '@/components/admin/confirm-form';
import { ScopePicker } from '@/components/admin/scope-picker';
import { iconBtn, input, td, th } from '@/components/admin/styles';
import {
  addParticipantAction,
  removeParticipantAction,
  setParticipantGroupAction,
} from '../../manage-actions';

export const dynamic = 'force-dynamic';

const NATIONAL_TYPES = new Set(['CONTINENTAL_NATIONAL', 'WORLD_CUP', 'QUALIFIER']);
const PARTICIPANT_CHECKS = new Set(['UNLISTED_PARTICIPANTS', 'PARTICIPANTS_WITHOUT_MATCHES', 'TEAM_COUNT_MISMATCH']);

export default async function AdminParticipantsPage(props: PageProps<'/admin/participants'>) {
  const sp = await props.searchParams;

  const comps = await load(() =>
    adminFetch<{ competitions: AdminCompetition[] }>('/api/admin/competitions').then((r) => r.competitions),
  );
  if (!comps.ok) return <ErrorState message={comps.error} />;
  const selectable = comps.data.filter((c) => c.editions.length > 0);

  // A season wins over a competition when they disagree: links from elsewhere
  // in the console carry only the season.
  const wantEdition = Number(one(sp.editionId));
  const competition =
    selectable.find((c) => c.editions.some((e) => e.editionId === wantEdition)) ??
    selectable.find((c) => c.id === Number(one(sp.competitionId))) ??
    [...selectable].sort((a, b) => b.matchCount - a.matchCount)[0];
  const edition = competition?.editions.find((e) => e.editionId === wantEdition) ?? competition?.editions[0];

  const header = (
    <PageHeader
      icon={<ListChecks />}
      title="Participants"
      description="Which teams take part in each season, and in which group."
    />
  );

  if (!competition || !edition) {
    return (
      <div>
        {header}
        <Panel>
          <EmptyState icon={<ListChecks />} title="No competition has a season yet">
            Add a season to a competition first.
          </EmptyState>
        </Panel>
      </div>
    );
  }

  const res = await load(() =>
    Promise.all([
      adminFetch<Participants>(`/api/admin/editions/${edition.editionId}/participants`),
      adminFetch<{ teams: { id: number; name: string }[] }>(
        `/api/admin/team-options?type=${NATIONAL_TYPES.has(competition.type) ? 'NATIONAL' : 'CLUB'}`,
      ).then((r) => r.teams),
      adminFetch<AuditFindings>(`/api/admin/audit/findings?entityType=competition_edition&entityId=${edition.editionId}&status=ACTIVE`)
        .then((r) => r.findings.filter((f) => PARTICIPANT_CHECKS.has(f.check.key))),
    ]),
  );
  if (!res.ok) return <ErrorState message={res.error} />;
  const [data, teamOptions, findings] = res.data;
  const returnTo = safeReturn(one(sp.from));
  const listed = new Set(data.participants.map((p) => p.teamId));
  const addable = teamOptions.filter((t) => !listed.has(t.id));
  const hasGroups = data.groups.length > 0;
  const label = `${data.edition.competition} ${data.edition.season}`;

  return (
    <div className="space-y-6">
      {header}

      <Panel bodyClassName="p-5">
        <ScopePicker
          basePath="/admin/participants"
          competitions={selectable.map((c) => ({ id: c.id, name: c.name, country: c.country, editions: c.editions }))}
          competitionId={competition.id}
          editionId={edition.editionId}
        />
      </Panel>

      <EntityFindings findings={findings} returnTo={returnTo} auditHref={`/admin/audit?editionId=${edition.editionId}&area=Seasons`} />

      <div className="grid gap-6 xl:grid-cols-3">
        <Panel
          id="participants"
          className="xl:col-span-2"
          title={label}
          description={
            <>
              {data.participants.length} team{data.participants.length === 1 ? '' : 's'} listed
              {data.edition.numTeams ? ` · ${data.edition.numTeams} expected` : ''}
              {hasGroups ? ` · ${data.groups.length} groups` : ''}
            </>
          }
          actions={
            <>
              {data.edition.isPublished ? <Badge tone="green" dot>Live</Badge> : <Badge>Hidden</Badge>}
              {data.edition.numTeams && data.edition.numTeams !== data.participants.length ? (
                <Badge tone="amber">{data.participants.length}/{data.edition.numTeams}</Badge>
              ) : null}
            </>
          }
        >
          {data.participants.length === 0 ? (
            <EmptyState icon={<Users />} title="No teams listed for this season">
              Add them from the panel alongside{data.unlisted.length ? ', or pick up the teams already playing matches' : ''}.
            </EmptyState>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full min-w-[600px] text-sm">
                <thead className="border-b border-line bg-wash/60">
                  <tr>
                    <th className={th}>Team</th>
                    <th className={th}>Country</th>
                    {hasGroups ? <th className={th}>Group</th> : null}
                    <th className={`${th} text-right`}>Matches</th>
                    <th className={th}><span className="sr-only">Actions</span></th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-line">
                  {data.participants.map((p) => (
                    <tr key={p.teamId} className="hover:bg-wash/60">
                      <td className={td}>
                        <Link href={`/admin/teams/${p.teamId}`} className="font-semibold hover:text-brand">{p.name}</Link>
                      </td>
                      <td className={`${td} text-muted`}>{p.country.replace(', United Republic of', '')}</td>
                      {hasGroups ? (
                        <td className={td}>
                          <ConfirmForm
                            action={setParticipantGroupAction}
                            title={`Change ${p.name}’s group?`}
                            confirmLabel="Save group"
                            review="changes"
                            trigger={<Save />}
                            triggerAriaLabel={`Save ${p.name}'s group`}
                            triggerClassName={iconBtn()}
                            className="flex items-center gap-1"
                          >
                            <input type="hidden" name="editionId" value={data.edition.id} />
                            <input type="hidden" name="teamId" value={p.teamId} />
                            <select name="groupId" defaultValue={p.group?.id ?? ''} data-label="Group"
                              className={`${input} w-28 py-1.5`}>
                              <option value="">None</option>
                              {data.groups.map((g) => <option key={g.id} value={g.id}>Group {g.name}</option>)}
                            </select>
                          </ConfirmForm>
                        </td>
                      ) : null}
                      <td className={`${td} text-right nums`}>{p.matches}</td>
                      <td className={`${td} text-right`}>
                        <ConfirmForm
                          action={removeParticipantAction}
                          tone="danger"
                          title={`Remove ${p.name} from ${label}?`}
                          description={
                            p.matches
                              ? `It has ${p.matches} matches in this season, so it cannot be removed.`
                              : 'It has no matches in this season. The team itself is not deleted.'
                          }
                          confirmLabel="Remove team"
                          trigger={<Trash2 />}
                          triggerAriaLabel={`Remove ${p.name}`}
                          triggerClassName={iconBtn('danger')}
                          disabled={p.matches > 0}
                        >
                          <input type="hidden" name="editionId" value={data.edition.id} />
                          <input type="hidden" name="teamId" value={p.teamId} />
                        </ConfirmForm>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Panel>

        <div className="space-y-6">
          <Panel title="Add a team">
            <ConfirmForm
              action={addParticipantAction}
              title={`Add a team to ${label}?`}
              confirmLabel="Add team"
              review="all"
              resetOnSuccess
              trigger={<><Plus /> Add team</>}
              className="space-y-4 p-5"
              disabled={addable.length === 0}
            >
              <input type="hidden" name="editionId" value={data.edition.id} />
              <Field label={NATIONAL_TYPES.has(competition.type) ? 'National team' : 'Club'} required>
                <select name="teamId" required defaultValue="" data-label="Team" className={input}>
                  <option value="" disabled>{addable.length ? 'Choose a team…' : 'Every team is already listed'}</option>
                  {addable.map((t) => <option key={t.id} value={t.id}>{t.name}</option>)}
                </select>
              </Field>
              {hasGroups ? (
                <Field label="Group">
                  <select name="groupId" defaultValue="" data-label="Group" className={input}>
                    <option value="">None</option>
                    {data.groups.map((g) => <option key={g.id} value={g.id}>Group {g.name}</option>)}
                  </select>
                </Field>
              ) : null}
              <p className="text-xs text-muted">
                Missing a team? <Link href="/admin/teams/new" className="font-semibold text-brand">Create it</Link> first.
              </p>
            </ConfirmForm>
          </Panel>

          {data.unlisted.length ? (
            <Panel
              title="Playing, but not listed"
              description="These teams have matches in this season but no participant entry."
            >
              <ul className="divide-y divide-line">
                {data.unlisted.map((t) => (
                  <li key={t.id} className="flex items-center justify-between gap-3 px-5 py-2.5 text-sm">
                    <span className="font-medium">{t.name}</span>
                    <ConfirmForm
                      action={addParticipantAction}
                      title={`List ${t.name} in ${label}?`}
                      description="It already plays matches in this season; this records it as a participant."
                      confirmLabel="Add team"
                      trigger={<><Plus /> Add</>}
                      triggerVariant="secondary"
                      triggerSize="sm"
                    >
                      <input type="hidden" name="editionId" value={data.edition.id} />
                      <input type="hidden" name="teamId" value={t.id} />
                    </ConfirmForm>
                  </li>
                ))}
              </ul>
            </Panel>
          ) : null}
        </div>
      </div>
    </div>
  );
}
