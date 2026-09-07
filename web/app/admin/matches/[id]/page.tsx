import Link from 'next/link';
import { notFound, redirect } from 'next/navigation';
import { adminFetch, AdminApiError, type AdminMatchDetail } from '@/lib/adminApi';
import { ActionForm, SeverityTag } from '@/components/admin-ui';
import {
  addEventAction,
  createFlagAction,
  deleteEventAction,
  resolveFlagAction,
  saveMatchAction,
} from '../../actions';

export const dynamic = 'force-dynamic';

const STATUSES = ['SCHEDULED', 'LIVE', 'FULL_TIME', 'POSTPONED', 'ABANDONED', 'CANCELLED'];
const EVENT_TYPES = [
  'GOAL', 'OWN_GOAL', 'PENALTY_GOAL', 'PENALTY_MISS', 'YELLOW_CARD',
  'SECOND_YELLOW', 'RED_CARD', 'SUBSTITUTION', 'VAR_REVIEW',
];

const field = 'rounded border border-border bg-transparent px-2 py-1.5 text-sm';

export default async function AdminMatchPage(props: PageProps<'/admin/matches/[id]'>) {
  const { id } = await props.params;
  const matchId = Number(id);
  if (!Number.isInteger(matchId) || matchId <= 0) notFound();

  let match: AdminMatchDetail;
  try {
    match = (await adminFetch<{ match: AdminMatchDetail }>(`/api/admin/matches/${matchId}`)).match;
  } catch (err) {
    if (err instanceof AdminApiError && err.status === 401) redirect('/admin/login');
    if (err instanceof AdminApiError && err.status === 404) notFound();
    if (err instanceof AdminApiError) {
      return <p className="text-sm text-red-600 dark:text-red-400">{err.message}</p>;
    }
    throw err;
  }

  return (
    <div className="space-y-6">
      <div>
        <Link href={`/admin/matches?editionId=${match.edition.id}`} className="text-sm text-muted hover:text-foreground">
          ← {match.edition.name} {match.edition.season}
        </Link>
        <h1 className="mt-1 text-xl font-semibold tracking-tight">
          {match.homeTeam.name} v {match.awayTeam.name}
        </h1>
        <p className="mt-1 text-sm text-muted">
          {match.kickoffAt ? new Date(match.kickoffAt).toLocaleDateString('en-GB', { dateStyle: 'medium' }) : 'Date unknown'}
          {match.round ? ` · ${match.round}` : ''}
          {match.edition.isPublished ? ' · edition is live' : ' · edition is hidden'}
        </p>
      </div>

      {match.openFlags.length > 0 ? (
        <section className="space-y-2 rounded-lg border border-amber-500/40 bg-amber-500/5 p-4">
          <h2 className="text-sm font-semibold">Needs attention</h2>
          {match.openFlags.map((f) => (
            <div key={f.id} className="flex flex-wrap items-center gap-2 text-sm">
              <SeverityTag severity={f.severity} />
              <span className="min-w-0 flex-1">{f.reason}</span>
              <ActionForm action={resolveFlagAction} submitLabel="Resolve" className="flex items-center gap-2">
                <input type="hidden" name="flagId" value={f.id} />
                <input name="note" placeholder="What you did (optional)" className={`${field} w-52 text-xs`} />
              </ActionForm>
            </div>
          ))}
        </section>
      ) : null}

      <section className="space-y-3">
        <h2 className="text-sm font-semibold uppercase tracking-wide text-muted">Result</h2>
        <ActionForm action={saveMatchAction} submitLabel="Save match" className="space-y-3">
          <input type="hidden" name="matchId" value={match.id} />
          <div className="flex flex-wrap items-end gap-3">
            <label className="block">
              <span className="text-xs text-muted">{match.homeTeam.name}</span>
              <input
                name="homeScore"
                type="number"
                min="0"
                defaultValue={match.homeScore ?? ''}
                placeholder="—"
                className={`mt-1 block w-20 ${field}`}
              />
            </label>
            <label className="block">
              <span className="text-xs text-muted">{match.awayTeam.name}</span>
              <input
                name="awayScore"
                type="number"
                min="0"
                defaultValue={match.awayScore ?? ''}
                placeholder="—"
                className={`mt-1 block w-20 ${field}`}
              />
            </label>
            <label className="block">
              <span className="text-xs text-muted">Status</span>
              <select name="status" defaultValue={match.status} className={`mt-1 block ${field}`}>
                {STATUSES.map((s) => (
                  <option key={s} value={s}>{s.replaceAll('_', ' ')}</option>
                ))}
              </select>
            </label>
            <label className="block">
              <span className="text-xs text-muted">Attendance</span>
              <input
                name="attendance"
                type="number"
                min="0"
                defaultValue={match.attendance ?? ''}
                placeholder="—"
                className={`mt-1 block w-28 ${field}`}
              />
            </label>
          </div>
          <p className="text-xs text-muted">
            Leave a score blank to record it as still unknown — blank is not the same as 0.
          </p>
        </ActionForm>
      </section>

      <section className="space-y-3">
        <h2 className="text-sm font-semibold uppercase tracking-wide text-muted">
          Events ({match.events.length})
        </h2>

        {match.events.length === 0 ? (
          <p className="rounded-md border border-dashed border-border px-4 py-6 text-center text-sm text-muted">
            No events recorded for this match.
          </p>
        ) : (
          <ul className="divide-y divide-border rounded-lg border border-border">
            {match.events.map((e) => (
              <li key={e.id} className="flex items-center gap-3 px-4 py-2 text-sm">
                <span className="w-10 shrink-0 text-xs tabular-nums text-muted">
                  {e.minute !== null ? `${e.minute}'` : '—'}
                </span>
                <span className="w-32 shrink-0 text-xs">{e.type.replaceAll('_', ' ')}</span>
                <span className="min-w-0 flex-1 truncate">
                  {e.playerName ?? <span className="text-red-600 dark:text-red-400">no player recorded</span>}
                </span>
                <span className="w-36 shrink-0 truncate text-xs text-muted">{e.teamName ?? '—'}</span>
                <ActionForm
                  action={deleteEventAction}
                  submitLabel="Delete"
                  confirm="Delete this event? This cannot be undone."
                  className="shrink-0"
                >
                  <input type="hidden" name="matchId" value={match.id} />
                  <input type="hidden" name="eventId" value={e.id} />
                </ActionForm>
              </li>
            ))}
          </ul>
        )}

        <ActionForm action={addEventAction} submitLabel="Add event" className="space-y-2">
          <input type="hidden" name="matchId" value={match.id} />
          <div className="flex flex-wrap items-end gap-2">
            <label className="block">
              <span className="text-xs text-muted">Minute</span>
              <input name="minute" type="number" min="0" max="130" className={`mt-1 block w-20 ${field}`} />
            </label>
            <label className="block">
              <span className="text-xs text-muted">Type</span>
              <select name="type" defaultValue="GOAL" className={`mt-1 block ${field}`}>
                {EVENT_TYPES.map((t) => (
                  <option key={t} value={t}>{t.replaceAll('_', ' ')}</option>
                ))}
              </select>
            </label>
            <label className="block">
              <span className="text-xs text-muted">Team</span>
              <select name="teamId" defaultValue={match.homeTeam.id} className={`mt-1 block ${field}`}>
                <option value={match.homeTeam.id}>{match.homeTeam.name}</option>
                <option value={match.awayTeam.id}>{match.awayTeam.name}</option>
              </select>
            </label>
            <label className="block">
              <span className="text-xs text-muted">Player ID</span>
              <input name="playerId" type="number" min="1" placeholder="optional" className={`mt-1 block w-28 ${field}`} />
            </label>
          </div>
          <p className="text-xs text-muted">
            For an own goal, pick the team of the player who scored it — the vault credits
            the goal to their opponent when reading. Adding an event never changes the
            stored score; update that above if it should move.
          </p>
        </ActionForm>
      </section>

      <section className="space-y-2">
        <h2 className="text-sm font-semibold uppercase tracking-wide text-muted">Flag this match</h2>
        <ActionForm action={createFlagAction} submitLabel="Raise flag" className="flex flex-wrap items-end gap-2">
          <input type="hidden" name="entityType" value="match" />
          <input type="hidden" name="entityId" value={match.id} />
          <label className="block">
            <span className="text-xs text-muted">Severity</span>
            <select name="severity" defaultValue="WARNING" className={`mt-1 block ${field}`}>
              <option value="INFO">Info</option>
              <option value="WARNING">Warning</option>
              <option value="BLOCKER">Blocker — stops publication</option>
            </select>
          </label>
          <label className="block min-w-64 flex-1">
            <span className="text-xs text-muted">What needs fixing?</span>
            <input name="reason" required placeholder="e.g. score contradicts the match report" className={`mt-1 block w-full ${field}`} />
          </label>
        </ActionForm>
      </section>
    </div>
  );
}
