import Link from 'next/link';
import { notFound, redirect } from 'next/navigation';
import {
  adminFetch,
  AdminApiError,
  type AdminMatchDetail,
  type SquadPlayer,
} from '@/lib/adminApi';
import { Card, CardHead, Crest } from '@/components/ui';
import { ActionForm, SeverityTag } from '@/components/admin-ui';
import { EventRow } from '@/components/event-row';
import {
  addEventAction,
  createFlagAction,
  deleteEventAction,
  resolveFlagAction,
  saveMatchAction,
  setScorerAction,
} from '../../actions';

export const dynamic = 'force-dynamic';

const STATUSES = ['SCHEDULED', 'LIVE', 'FULL_TIME', 'POSTPONED', 'ABANDONED', 'CANCELLED'];
const EVENT_TYPES = [
  'GOAL', 'OWN_GOAL', 'PENALTY_GOAL', 'PENALTY_MISS', 'YELLOW_CARD',
  'SECOND_YELLOW', 'RED_CARD', 'SUBSTITUTION', 'VAR_REVIEW',
];
const field = 'rounded-lg border border-line bg-paper px-2.5 py-1.5 text-sm';

export default async function AdminMatchPage(props: PageProps<'/admin/matches/[id]'>) {
  const { id } = await props.params;
  const matchId = Number(id);
  if (!Number.isInteger(matchId) || matchId <= 0) notFound();

  let match: AdminMatchDetail;
  let squad: SquadPlayer[];
  try {
    [match, squad] = await Promise.all([
      adminFetch<{ match: AdminMatchDetail }>(`/api/admin/matches/${matchId}`).then((r) => r.match),
      adminFetch<{ squad: SquadPlayer[] }>(`/api/admin/matches/${matchId}/squad`).then((r) => r.squad),
    ]);
  } catch (err) {
    if (err instanceof AdminApiError && err.status === 401) redirect('/admin/login');
    if (err instanceof AdminApiError && err.status === 404) notFound();
    if (err instanceof AdminApiError) return <p className="text-sm text-loss">{err.message}</p>;
    throw err;
  }

  // Each event belongs to one side of the sheet. Anything without a team (the
  // schema allows it) goes in a third bucket rather than being silently dropped.
  const homeEvents = match.events.filter((e) => e.teamId === match.homeTeam.id);
  const awayEvents = match.events.filter((e) => e.teamId === match.awayTeam.id);
  const orphanEvents = match.events.filter(
    (e) => e.teamId !== match.homeTeam.id && e.teamId !== match.awayTeam.id,
  );
  const missingScorers = match.events.filter(
    (e) => ['GOAL', 'PENALTY_GOAL', 'OWN_GOAL'].includes(e.type) && e.playerId === null,
  ).length;

  return (
    <div className="space-y-5">
      <div>
        <Link
          href={`/admin/matches?editionId=${match.edition.id}`}
          className="text-sm text-muted hover:text-ink"
        >
          ← {match.edition.name} {match.edition.season}
        </Link>
      </div>

      {/* Scoreboard: the two sides the whole page is organised around. */}
      <Card className="px-5 py-5">
        <div className="flex items-center gap-4">
          <div className="flex min-w-0 flex-1 items-center gap-3">
            <Crest name={match.homeTeam.name} size={38} />
            <span className="display min-w-0 truncate text-lg font-bold">
              {match.homeTeam.name}
            </span>
          </div>
          <div className="shrink-0 text-center">
            <p className="stat-figure text-3xl">
              {match.homeScore ?? '–'}<span className="mx-1.5 text-muted">–</span>{match.awayScore ?? '–'}
            </p>
            <p className="mt-1 text-[10px] font-semibold uppercase tracking-wider text-muted">
              {match.status.replaceAll('_', ' ')}
            </p>
          </div>
          <div className="flex min-w-0 flex-1 items-center justify-end gap-3 text-right">
            <span className="display min-w-0 truncate text-lg font-bold">
              {match.awayTeam.name}
            </span>
            <Crest name={match.awayTeam.name} size={38} />
          </div>
        </div>
        <p className="mt-3 border-t border-line pt-3 text-center text-xs text-muted">
          {match.kickoffAt
            ? new Date(match.kickoffAt).toLocaleDateString('en-GB', { dateStyle: 'full' })
            : 'Date unknown'}
          {match.round ? ` · ${match.round}` : ''}
          {missingScorers > 0 ? (
            <span className="ml-2 font-semibold text-loss">
              · {missingScorers} goal{missingScorers === 1 ? '' : 's'} with no scorer
            </span>
          ) : null}
        </p>
      </Card>

      {match.openFlags.length > 0 ? (
        <Card className="p-4">
          <h2 className="display mb-2 text-sm font-bold uppercase tracking-wide">Needs attention</h2>
          {match.openFlags.map((f) => (
            <div key={f.id} className="flex flex-wrap items-center gap-2 py-1 text-sm">
              <SeverityTag severity={f.severity} />
              <span className="min-w-0 flex-1">{f.reason}</span>
              <ActionForm action={resolveFlagAction} submitLabel="Resolve" className="flex items-center gap-2">
                <input type="hidden" name="flagId" value={f.id} />
                <input name="note" placeholder="Note (optional)" className={`${field} w-44 text-xs`} />
              </ActionForm>
            </div>
          ))}
        </Card>
      ) : null}

      {/* Events, each on its own team's side. */}
      <div className="grid gap-4 md:grid-cols-2">
        <Card className="overflow-hidden">
          <CardHead title={match.homeTeam.name} hint={`${homeEvents.length} events`} />
          {homeEvents.length === 0 ? (
            <p className="px-4 py-8 text-center text-sm text-muted">No events recorded.</p>
          ) : (
            <ul>
              {homeEvents.map((e) => (
                <EventRow
                  key={e.id}
                  event={e}
                  matchId={match.id}
                  squad={squad}
                  align="left"
                  setScorer={setScorerAction}
                  deleteEvent={deleteEventAction}
                />
              ))}
            </ul>
          )}
        </Card>

        <Card className="overflow-hidden">
          <CardHead title={match.awayTeam.name} hint={`${awayEvents.length} events`} />
          {awayEvents.length === 0 ? (
            <p className="px-4 py-8 text-center text-sm text-muted">No events recorded.</p>
          ) : (
            <ul>
              {awayEvents.map((e) => (
                <EventRow
                  key={e.id}
                  event={e}
                  matchId={match.id}
                  squad={squad}
                  align="right"
                  setScorer={setScorerAction}
                  deleteEvent={deleteEventAction}
                />
              ))}
            </ul>
          )}
        </Card>
      </div>

      {orphanEvents.length > 0 ? (
        <Card className="overflow-hidden">
          <CardHead title="Events with no team" hint="These cannot be shown on either side" />
          <ul>
            {orphanEvents.map((e) => (
              <EventRow
                key={e.id}
                event={e}
                matchId={match.id}
                squad={squad}
                align="left"
                setScorer={setScorerAction}
                deleteEvent={deleteEventAction}
              />
            ))}
          </ul>
        </Card>
      ) : null}

      <div className="grid gap-4 md:grid-cols-2">
        <Card className="p-4">
          <h2 className="display mb-3 text-sm font-bold uppercase tracking-wide">Result</h2>
          <ActionForm action={saveMatchAction} submitLabel="Save result">
            <input type="hidden" name="matchId" value={match.id} />
            <div className="mb-3 flex flex-wrap items-end gap-2">
              <label className="block">
                <span className="text-[11px] text-muted">Home</span>
                <input name="homeScore" type="number" min="0" defaultValue={match.homeScore ?? ''}
                  placeholder="—" className={`mt-1 block w-16 ${field}`} />
              </label>
              <label className="block">
                <span className="text-[11px] text-muted">Away</span>
                <input name="awayScore" type="number" min="0" defaultValue={match.awayScore ?? ''}
                  placeholder="—" className={`mt-1 block w-16 ${field}`} />
              </label>
              <label className="block">
                <span className="text-[11px] text-muted">Status</span>
                <select name="status" defaultValue={match.status} className={`mt-1 block ${field}`}>
                  {STATUSES.map((s) => <option key={s} value={s}>{s.replaceAll('_', ' ')}</option>)}
                </select>
              </label>
              <label className="block">
                <span className="text-[11px] text-muted">Attendance</span>
                <input name="attendance" type="number" min="0" defaultValue={match.attendance ?? ''}
                  placeholder="—" className={`mt-1 block w-24 ${field}`} />
              </label>
            </div>
            <p className="mb-2 text-xs text-muted">Blank means unknown — not zero.</p>
          </ActionForm>
        </Card>

        <Card className="p-4">
          <h2 className="display mb-3 text-sm font-bold uppercase tracking-wide">Add event</h2>
          <ActionForm action={addEventAction} submitLabel="Add event">
            <input type="hidden" name="matchId" value={match.id} />
            <div className="mb-3 flex flex-wrap items-end gap-2">
              <label className="block">
                <span className="text-[11px] text-muted">Minute</span>
                <input name="minute" type="number" min="0" max="130" className={`mt-1 block w-16 ${field}`} />
              </label>
              <label className="block">
                <span className="text-[11px] text-muted">Type</span>
                <select name="type" defaultValue="GOAL" className={`mt-1 block ${field}`}>
                  {EVENT_TYPES.map((t) => <option key={t} value={t}>{t.replaceAll('_', ' ')}</option>)}
                </select>
              </label>
              <label className="block">
                <span className="text-[11px] text-muted">Team</span>
                <select name="teamId" defaultValue={match.homeTeam.id} className={`mt-1 block ${field}`}>
                  <option value={match.homeTeam.id}>{match.homeTeam.name}</option>
                  <option value={match.awayTeam.id}>{match.awayTeam.name}</option>
                </select>
              </label>
              <label className="block min-w-40 flex-1">
                <span className="text-[11px] text-muted">Player</span>
                <select name="playerId" defaultValue="" className={`mt-1 block w-full ${field}`}>
                  <option value="">Unknown</option>
                  {squad.map((p) => (
                    <option key={p.id} value={p.id}>{p.name}</option>
                  ))}
                </select>
              </label>
            </div>
            <p className="mb-2 text-xs text-muted">
              For an own goal pick the scoring player’s own team — the vault credits it to
              their opponent. Adding an event never changes the score.
            </p>
          </ActionForm>
        </Card>
      </div>

      <Card className="p-4">
        <h2 className="display mb-2 text-sm font-bold uppercase tracking-wide">Flag this match</h2>
        <ActionForm action={createFlagAction} submitLabel="Raise flag" className="flex flex-wrap items-end gap-2">
          <input type="hidden" name="entityType" value="match" />
          <input type="hidden" name="entityId" value={match.id} />
          <label className="block">
            <span className="text-[11px] text-muted">Severity</span>
            <select name="severity" defaultValue="WARNING" className={`mt-1 block ${field}`}>
              <option value="INFO">Info</option>
              <option value="WARNING">Warning</option>
              <option value="BLOCKER">Blocker — stops publication</option>
            </select>
          </label>
          <label className="block min-w-56 flex-1">
            <span className="text-[11px] text-muted">What needs fixing?</span>
            <input name="reason" required placeholder="e.g. score contradicts the match report"
              className={`mt-1 block w-full ${field}`} />
          </label>
        </ActionForm>
      </Card>
    </div>
  );
}
