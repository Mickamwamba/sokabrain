'use client';

import { useActionState } from 'react';
import type { ActionState } from '@/app/admin/actions';
import type { SquadPlayer } from '@/lib/adminApi';

type Action = (prev: ActionState, formData: FormData) => Promise<ActionState>;

export type MatchEvent = {
  id: number;
  minute: number | null;
  type: string;
  teamId: number | null;
  playerId: number | null;
  playerName: string | null;
};

const GOAL_TYPES = new Set(['GOAL', 'PENALTY_GOAL', 'OWN_GOAL']);

const ICON: Record<string, string> = {
  GOAL: '⚽',
  PENALTY_GOAL: '⚽',
  OWN_GOAL: '⚽',
  YELLOW_CARD: '🟨',
  SECOND_YELLOW: '🟨',
  RED_CARD: '🟥',
  SUBSTITUTION: '↔',
  PENALTY_MISS: '✗',
  VAR_REVIEW: '⌾',
};

/**
 * One event, rendered on its own team's side of the match sheet.
 *
 * A goal with no scorer shows an inline picker rather than sending the editor
 * elsewhere — naming missing scorers is the single most common repair, so it
 * has to be one click and one choice.
 */
export function EventRow({
  event,
  matchId,
  squad,
  align,
  setScorer,
  deleteEvent,
}: {
  event: MatchEvent;
  matchId: number;
  squad: SquadPlayer[];
  align: 'left' | 'right';
  setScorer: Action;
  deleteEvent: Action;
}) {
  const [scorerState, scorerAction, scorerPending] = useActionState(setScorer, {});
  const [, deleteAction, deletePending] = useActionState(deleteEvent, {});

  const isGoal = GOAL_TYPES.has(event.type);
  const missingScorer = isGoal && event.playerId === null;
  const right = align === 'right';

  // Prefer players attached to this event's team, but keep the rest available —
  // stint data is incomplete and would otherwise hide the right name.
  const own = squad.filter((p) => event.teamId !== null && p.teamIds.includes(event.teamId));
  const others = squad.filter((p) => !own.includes(p));

  return (
    <li
      className={`border-b border-line px-4 py-2.5 last:border-0 ${missingScorer ? 'bg-loss/5' : ''}`}
    >
      <div className={`flex items-center gap-2 ${right ? 'flex-row-reverse text-right' : ''}`}>
        <span aria-hidden className="w-5 shrink-0 text-center text-sm">
          {ICON[event.type] ?? '•'}
        </span>
        <span className="w-9 shrink-0 text-xs nums text-muted">
          {event.minute !== null ? `${event.minute}'` : '—'}
        </span>
        <span className="min-w-0 flex-1">
          <span className="block truncate text-sm font-medium">
            {event.playerName ?? (
              <span className="text-loss">Scorer not recorded</span>
            )}
          </span>
          <span className="block text-[10px] uppercase tracking-wide text-muted">
            {event.type.replaceAll('_', ' ')}
          </span>
        </span>
        <form action={deleteAction} className="shrink-0">
          <input type="hidden" name="matchId" value={matchId} />
          <input type="hidden" name="eventId" value={event.id} />
          <button
            type="submit"
            disabled={deletePending}
            title="Delete event"
            className="rounded px-1.5 py-0.5 text-xs text-muted hover:text-loss disabled:opacity-50"
          >
            ✕
          </button>
        </form>
      </div>

      {missingScorer ? (
        <form action={scorerAction} className={`mt-2 flex gap-1.5 ${right ? 'flex-row-reverse' : ''}`}>
          <input type="hidden" name="matchId" value={matchId} />
          <input type="hidden" name="eventId" value={event.id} />
          <select
            name="playerId"
            defaultValue=""
            disabled={scorerPending}
            className="min-w-0 flex-1 rounded border border-line bg-paper px-2 py-1 text-xs"
          >
            <option value="">Who scored?</option>
            {own.length > 0 ? (
              <optgroup label="This club">
                {own.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.name}{p.position ? ` (${p.position})` : ''}
                  </option>
                ))}
              </optgroup>
            ) : null}
            <optgroup label="Other players">
              {others.map((p) => (
                <option key={p.id} value={p.id}>
                  {p.name}{p.position ? ` (${p.position})` : ''}
                </option>
              ))}
            </optgroup>
          </select>
          <button
            type="submit"
            disabled={scorerPending}
            className="shrink-0 rounded bg-ink px-2.5 py-1 text-xs font-semibold text-white disabled:opacity-50"
          >
            {scorerPending ? 'Saving…' : 'Save'}
          </button>
        </form>
      ) : null}
      {scorerState.error ? (
        <p className="mt-1 text-xs text-loss">{scorerState.error}</p>
      ) : null}
    </li>
  );
}
