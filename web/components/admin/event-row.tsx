'use client';

import { useState } from 'react';
import { Trash2 } from 'lucide-react';
import type { ActionState } from '@/lib/admin-actions';
import type { SquadPlayer } from '@/lib/adminApi';
import { ConfirmForm } from './confirm-form';
import { btn, iconBtn, input } from './styles';

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
  GOAL: '⚽', PENALTY_GOAL: '⚽', OWN_GOAL: '⚽',
  YELLOW_CARD: '🟨', SECOND_YELLOW: '🟨', RED_CARD: '🟥',
  SUBSTITUTION: '↔', PENALTY_MISS: '✗', VAR_REVIEW: '⌾', ASSIST: '➜',
};

/** "the 23' goal" / "the goal (minute unknown)" — used in confirmation copy. */
function describe(e: MatchEvent) {
  const kind = e.type.replaceAll('_', ' ').toLowerCase();
  const when = e.minute !== null ? `the ${e.minute}' ${kind}` : `the ${kind} (minute unknown)`;
  return e.playerName ? `${when} by ${e.playerName}` : when;
}

export function EventRow({
  event,
  matchId,
  teamName,
  squad,
  align,
  setScorer,
  deleteEvent,
}: {
  event: MatchEvent;
  matchId: number;
  teamName: string;
  squad: SquadPlayer[];
  align: 'left' | 'right';
  setScorer: Action;
  deleteEvent: Action;
}) {
  const isGoal = GOAL_TYPES.has(event.type);
  const missingScorer = isGoal && event.playerId === null;
  const right = align === 'right';

  // Held in state so the confirmation can name the player being credited.
  const [pick, setPick] = useState('');
  const picked = squad.find((p) => String(p.id) === pick);

  // Prefer players attached to this event's team, but keep the rest available —
  // stint data is incomplete and would otherwise hide the right name.
  const own = squad.filter((p) => event.teamId !== null && p.teamIds.includes(event.teamId));
  const others = squad.filter((p) => !own.includes(p));

  return (
    <li className={`border-b border-line px-4 py-2.5 last:border-0 ${missingScorer ? 'bg-loss/5' : ''}`}>
      <div className={`flex items-center gap-2 ${right ? 'flex-row-reverse text-right' : ''}`}>
        <span aria-hidden className="w-5 shrink-0 text-center text-sm">{ICON[event.type] ?? '•'}</span>
        <span className="w-9 shrink-0 text-xs nums text-muted">
          {event.minute !== null ? `${event.minute}'` : '—'}
        </span>
        <span className="min-w-0 flex-1">
          <span className="block truncate text-sm font-medium">
            {event.playerName ?? <span className="text-loss">Scorer not recorded</span>}
          </span>
          <span className="block text-[10px] uppercase tracking-wide text-muted">
            {event.type.replaceAll('_', ' ')}
          </span>
        </span>

        <ConfirmForm
          action={deleteEvent}
          className="shrink-0"
          title="Delete this event?"
          tone="danger"
          confirmLabel="Delete event"
          trigger={<Trash2 />}
          triggerAriaLabel="Delete event"
          triggerClassName={iconBtn('danger')}
          description={
            <>
              Removing {describe(event)} for <strong className="text-ink">{teamName}</strong>.
              This cannot be undone, and the match score will not change.
            </>
          }
        >
          <input type="hidden" name="matchId" value={matchId} />
          <input type="hidden" name="eventId" value={event.id} />
        </ConfirmForm>
      </div>

      {missingScorer ? (
        <ConfirmForm
          action={setScorer}
          className={`mt-2 flex items-center gap-1.5 ${right ? 'flex-row-reverse' : ''}`}
          title="Record this scorer?"
          confirmLabel="Save scorer"
          trigger="Save"
          triggerClassName={btn('primary', 'sm', 'shrink-0')}
          disabled={pick === ''}
          description={
            picked ? (
              <>
                Crediting {describe(event)} to{' '}
                <strong className="text-ink">{picked.name}</strong> for{' '}
                <strong className="text-ink">{teamName}</strong>.
              </>
            ) : (
              'Pick a player first.'
            )
          }
        >
          <input type="hidden" name="matchId" value={matchId} />
          <input type="hidden" name="eventId" value={event.id} />
          <select
            name="playerId"
            value={pick}
            onChange={(e) => setPick(e.target.value)}
            className={`${input} min-w-0 flex-1 py-1.5 text-xs`}
          >
            <option value="">Who scored?</option>
            {own.length > 0 ? (
              <optgroup label={teamName}>
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
        </ConfirmForm>
      ) : null}
    </li>
  );
}
