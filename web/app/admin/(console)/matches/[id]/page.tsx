import Link from 'next/link';
import { ExternalLink, Flag as FlagIcon, Save, CircleCheck } from 'lucide-react';
import { adminFetch, type AdminMatchDetail, type SquadPlayer } from '@/lib/adminApi';
import { load } from '@/lib/admin-page';
import { Badge, ErrorState, Field, PageHeader, Panel, SeverityBadge, humanise } from '@/components/admin/kit';
import { ConfirmForm } from '@/components/admin/confirm-form';
import { EventRow } from '@/components/admin/event-row';
import { AddEventForm } from '@/components/admin/add-event-form';
import { btn, input } from '@/components/admin/styles';
import { Crest } from '@/components/ui';
import {
  addEventAction,
  createFlagAction,
  deleteEventAction,
  resolveFlagAction,
  saveMatchAction,
  setScorerAction,
} from '../../../actions';

export const dynamic = 'force-dynamic';

const STATUSES = ['SCHEDULED', 'LIVE', 'FULL_TIME', 'POSTPONED', 'ABANDONED', 'CANCELLED'];

export default async function AdminMatchPage(props: PageProps<'/admin/matches/[id]'>) {
  const { id } = await props.params;
  const res = await load(() =>
    Promise.all([
      adminFetch<{ match: AdminMatchDetail }>(`/api/admin/matches/${Number(id)}`).then((r) => r.match),
      adminFetch<{ squad: SquadPlayer[] }>(`/api/admin/matches/${Number(id)}/squad`).then((r) => r.squad),
    ]),
  );
  if (!res.ok) return <ErrorState message={res.error} />;
  const [match, squad] = res.data;

  // Each event belongs to one side. Anything without a team (the schema allows
  // it) goes in a third bucket rather than being silently dropped.
  const homeEvents = match.events.filter((e) => e.teamId === match.homeTeam.id);
  const awayEvents = match.events.filter((e) => e.teamId === match.awayTeam.id);
  const orphanEvents = match.events.filter((e) => e.teamId !== match.homeTeam.id && e.teamId !== match.awayTeam.id);
  const missingScorers = match.events.filter(
    (e) => ['GOAL', 'PENALTY_GOAL', 'OWN_GOAL'].includes(e.type) && e.playerId === null,
  ).length;
  const label = `${match.homeTeam.name} v ${match.awayTeam.name}`;

  const side = (team: { id: number; name: string }, events: typeof match.events, align: 'left' | 'right') => (
    <Panel title={team.name} description={`${events.length} event${events.length === 1 ? '' : 's'}`}>
      {events.length === 0 ? (
        <p className="px-5 py-8 text-center text-sm text-muted">No events recorded.</p>
      ) : (
        <ul>
          {events.map((e) => (
            <EventRow key={e.id} event={e} matchId={match.id} teamName={team.name} squad={squad} align={align}
              setScorer={setScorerAction} deleteEvent={deleteEventAction} />
          ))}
        </ul>
      )}
    </Panel>
  );

  return (
    <div className="space-y-6">
      <PageHeader
        back={{ href: `/admin/matches?editionId=${match.edition.id}`, label: `${match.edition.name} ${match.edition.season}` }}
        title={label}
        description={[
          match.kickoffAt ? new Date(match.kickoffAt).toLocaleDateString('en-GB', { dateStyle: 'full' }) : 'Date unknown',
          match.round ? (/^\d+$/.test(match.round) ? `Round ${match.round}` : humanise(match.round)) : null,
        ].filter(Boolean).join(' · ')}
        actions={
          match.edition.isPublished ? (
            <Link href={`/matches/${match.id}`} target="_blank" className={btn('secondary')}>
              <ExternalLink /> Public page
            </Link>
          ) : null
        }
      />

      <div className="rounded-xl border border-line bg-paper px-5 py-6 shadow-sm">
        <div className="flex items-center gap-4">
          <div className="flex min-w-0 flex-1 items-center gap-3">
            <Crest name={match.homeTeam.name} size={44} />
            <span className="display min-w-0 truncate text-lg font-bold">{match.homeTeam.name}</span>
          </div>
          <div className="shrink-0 text-center">
            <p className="stat-figure text-4xl">
              {match.homeScore ?? '–'}<span className="mx-2 text-muted">–</span>{match.awayScore ?? '–'}
            </p>
            <div className="mt-1.5 flex justify-center">
              <Badge tone={match.status === 'FULL_TIME' ? 'gray' : match.status === 'LIVE' ? 'red' : 'blue'}>
                {humanise(match.status)}
              </Badge>
            </div>
          </div>
          <div className="flex min-w-0 flex-1 items-center justify-end gap-3 text-right">
            <span className="display min-w-0 truncate text-lg font-bold">{match.awayTeam.name}</span>
            <Crest name={match.awayTeam.name} size={44} />
          </div>
        </div>
        {missingScorers ? (
          <p className="mt-4 border-t border-line pt-3 text-center text-xs font-semibold text-loss">
            {missingScorers} goal{missingScorers === 1 ? '' : 's'} with no scorer recorded
          </p>
        ) : null}
      </div>

      {match.openFlags.length ? (
        <Panel title="Open flags" tone="danger">
          <ul className="divide-y divide-line">
            {match.openFlags.map((f) => (
              <li key={f.id} className="flex flex-wrap items-center gap-3 px-5 py-3 text-sm">
                <SeverityBadge severity={f.severity} />
                <span className="min-w-0 flex-1">{f.reason}</span>
                <ConfirmForm
                  action={resolveFlagAction}
                  title="Resolve this flag?"
                  description={<>“{f.reason}” will be marked resolved.{f.severity === 'BLOCKER' ? ' It will no longer block publication.' : ''}</>}
                  confirmLabel="Resolve flag"
                  trigger={<><CircleCheck /> Resolve</>}
                  triggerVariant="secondary"
                  triggerSize="sm"
                  fields={
                    <Field label="Resolution note" hint="Optional — what was done about it.">
                      <input name="note" maxLength={500} className={input} />
                    </Field>
                  }
                >
                  <input type="hidden" name="flagId" value={f.id} />
                </ConfirmForm>
              </li>
            ))}
          </ul>
        </Panel>
      ) : null}

      <div className="grid gap-6 md:grid-cols-2">
        {side(match.homeTeam, homeEvents, 'left')}
        {side(match.awayTeam, awayEvents, 'right')}
      </div>

      {orphanEvents.length ? (
        <Panel title="Events with no team" description="These cannot be shown on either side">
          <ul>
            {orphanEvents.map((e) => (
              <EventRow key={e.id} event={e} matchId={match.id} teamName={e.teamName ?? 'Unknown team'} squad={squad}
                align="left" setScorer={setScorerAction} deleteEvent={deleteEventAction} />
            ))}
          </ul>
        </Panel>
      ) : null}

      <div className="grid gap-6 lg:grid-cols-2">
        <Panel title="Result" description="Blank means unknown — not zero.">
          <ConfirmForm
            action={saveMatchAction}
            title={`Save the result of ${label}?`}
            description={match.edition.isPublished ? 'This season is live, so the change is public straight away.' : undefined}
            confirmLabel="Save result"
            review="changes"
            trigger={<><Save /> Save result</>}
            className="space-y-4 p-5"
          >
            <input type="hidden" name="matchId" value={match.id} />
            <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
              <Field label={`${match.homeTeam.name.split(' ')[0]} score`}>
                <input name="homeScore" type="number" min={0} max={99} defaultValue={match.homeScore ?? ''}
                  data-label={`${match.homeTeam.name} score`} className={input} />
              </Field>
              <Field label={`${match.awayTeam.name.split(' ')[0]} score`}>
                <input name="awayScore" type="number" min={0} max={99} defaultValue={match.awayScore ?? ''}
                  data-label={`${match.awayTeam.name} score`} className={input} />
              </Field>
              <Field label="Status">
                <select name="status" defaultValue={match.status} data-label="Status" className={input}>
                  {STATUSES.map((s) => <option key={s} value={s}>{humanise(s)}</option>)}
                </select>
              </Field>
              <Field label="Attendance">
                <input name="attendance" type="number" min={0} defaultValue={match.attendance ?? ''}
                  data-label="Attendance" className={input} />
              </Field>
            </div>
          </ConfirmForm>
        </Panel>

        <Panel title="Add event">
          <div className="p-5">
            <AddEventForm matchId={match.id} homeTeam={match.homeTeam} awayTeam={match.awayTeam} squad={squad} action={addEventAction} />
          </div>
        </Panel>
      </div>

      <Panel title="Flag this match" description="Track a problem you can’t fix right now. A blocker stops the season being published.">
        <ConfirmForm
          action={createFlagAction}
          title="Raise a flag on this match?"
          confirmLabel="Raise flag"
          review="all"
          resetOnSuccess
          trigger={<><FlagIcon /> Raise flag</>}
          triggerVariant="secondary"
          className="flex flex-wrap items-end gap-3 p-5"
        >
          <input type="hidden" name="entityType" value="match" />
          <input type="hidden" name="entityId" value={match.id} />
          <Field label="Severity">
            <select name="severity" defaultValue="WARNING" data-label="Severity" className={input}>
              <option value="INFO">Info</option>
              <option value="WARNING">Warning</option>
              <option value="BLOCKER">Blocker — stops publication</option>
            </select>
          </Field>
          <Field label="What needs fixing?" required className="min-w-64 flex-1">
            <input name="reason" required maxLength={500} placeholder="e.g. score contradicts the match report"
              data-label="Reason" className={input} />
          </Field>
        </ConfirmForm>
      </Panel>
    </div>
  );
}
