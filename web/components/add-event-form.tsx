'use client';

import { useState } from 'react';
import type { ActionState } from '@/app/admin/actions';
import type { SquadPlayer } from '@/lib/adminApi';
import { ConfirmForm } from './confirm-form';

type Action = (prev: ActionState, formData: FormData) => Promise<ActionState>;

const EVENT_TYPES = [
  'GOAL', 'OWN_GOAL', 'PENALTY_GOAL', 'PENALTY_MISS', 'YELLOW_CARD',
  'SECOND_YELLOW', 'RED_CARD', 'SUBSTITUTION', 'VAR_REVIEW', 'ASSIST',
];
const field = 'rounded-lg border border-line bg-paper px-2.5 py-1.5 text-sm';

/**
 * Adds an event to a match, behind a confirmation that spells out what will be
 * written — including, for an own goal, which side the goal actually counts for,
 * since that is the rule most easily got backwards.
 */
export function AddEventForm({
  matchId,
  homeTeam,
  awayTeam,
  squad,
  action,
}: {
  matchId: number;
  homeTeam: { id: number; name: string };
  awayTeam: { id: number; name: string };
  squad: SquadPlayer[];
  action: Action;
}) {
  const [type, setType] = useState('GOAL');
  const [teamId, setTeamId] = useState(String(homeTeam.id));
  const [playerId, setPlayerId] = useState('');
  const [minute, setMinute] = useState('');

  const team = String(homeTeam.id) === teamId ? homeTeam : awayTeam;
  const opponent = team.id === homeTeam.id ? awayTeam : homeTeam;
  const player = squad.find((p) => String(p.id) === playerId);
  const forTeam = squad.filter((p) => p.teamIds.includes(team.id));
  const others = squad.filter((p) => !forTeam.includes(p));

  return (
    <ConfirmForm
      action={action}
      title="Add this event?"
      confirmLabel="Add event"
      triggerLabel="Add event"
      triggerClassName="rounded-lg bg-ink px-4 py-2 text-sm font-semibold text-white hover:bg-ink-soft disabled:opacity-50"
      message={
        <>
          Recording a <strong className="text-ink">{type.replaceAll('_', ' ').toLowerCase()}</strong>
          {minute ? ` in the ${minute}' ` : ' '}
          for <strong className="text-ink">{team.name}</strong>
          {player ? (
            <> by <strong className="text-ink">{player.name}</strong></>
          ) : (
            ' with no player named'
          )}
          .
          {type === 'OWN_GOAL' ? (
            <span className="mt-2 block">
              As an own goal, this will be credited to{' '}
              <strong className="text-ink">{opponent.name}</strong> when scores are read.
            </span>
          ) : null}
          <span className="mt-2 block">The stored match score will not change.</span>
        </>
      }
    >
      <input type="hidden" name="matchId" value={matchId} />
      <div className="mb-3 flex flex-wrap items-end gap-2">
        <label className="block">
          <span className="text-[11px] text-muted">Minute</span>
          <input
            name="minute" type="number" min="0" max="130" value={minute}
            onChange={(e) => setMinute(e.target.value)}
            className={`mt-1 block w-16 ${field}`}
          />
        </label>
        <label className="block">
          <span className="text-[11px] text-muted">Type</span>
          <select name="type" value={type} onChange={(e) => setType(e.target.value)}
            className={`mt-1 block ${field}`}>
            {EVENT_TYPES.map((t) => <option key={t} value={t}>{t.replaceAll('_', ' ')}</option>)}
          </select>
        </label>
        <label className="block">
          <span className="text-[11px] text-muted">Team</span>
          <select name="teamId" value={teamId}
            onChange={(e) => { setTeamId(e.target.value); setPlayerId(''); }}
            className={`mt-1 block ${field}`}>
            <option value={homeTeam.id}>{homeTeam.name}</option>
            <option value={awayTeam.id}>{awayTeam.name}</option>
          </select>
        </label>
        <label className="block min-w-40 flex-1">
          <span className="text-[11px] text-muted">Player</span>
          <select name="playerId" value={playerId} onChange={(e) => setPlayerId(e.target.value)}
            className={`mt-1 block w-full ${field}`}>
            <option value="">Unknown</option>
            {forTeam.length > 0 ? (
              <optgroup label={team.name}>
                {forTeam.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
              </optgroup>
            ) : null}
            <optgroup label="Other players">
              {others.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
            </optgroup>
          </select>
        </label>
      </div>
      <p className="mb-2 text-xs text-muted">
        For an own goal pick the scoring player’s own team — the vault credits it to
        their opponent.
      </p>
    </ConfirmForm>
  );
}
