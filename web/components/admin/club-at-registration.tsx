'use client';

import { useState } from 'react';
import type { TeamOption } from '@/lib/adminApi';
import { Field } from './kit';
import { input } from './styles';

/**
 * "Where does this player play?" at registration: a club and the date they
 * joined, or no club at all. The club fields are disabled rather than hidden
 * for a free agent, so they are neither validated as required nor submitted.
 */
export function ClubAtRegistration({ clubs, today }: { clubs: TeamOption[]; today: string }) {
  const [mode, setMode] = useState<'club' | 'free'>('club');
  const off = mode === 'free';

  const option = (value: 'club' | 'free', title: string, hint: string) => (
    <label
      className={`flex cursor-pointer items-start gap-3 rounded-lg border p-3 text-sm transition-colors ${
        mode === value ? 'border-ink bg-wash' : 'border-line hover:border-ink/40'
      }`}
    >
      <input
        type="radio"
        name="club_mode"
        value={value}
        checked={mode === value}
        onChange={() => setMode(value)}
        className="mt-0.5 h-4 w-4 accent-[var(--ink)]"
      />
      <span>
        <span className="block font-semibold">{title}</span>
        <span className="block text-xs text-muted">{hint}</span>
      </span>
    </label>
  );

  return (
    <fieldset className="space-y-4">
      <legend className="mb-2 text-xs font-semibold">Current club</legend>
      <div className="grid gap-2 sm:grid-cols-2">
        {option('club', 'Plays for a club', 'Starts their club history from the date they joined.')}
        {option('free', 'Free agent', 'No club at the moment. Record a move later from their page.')}
      </div>

      <div className={`grid gap-4 sm:grid-cols-2 ${off ? 'opacity-50' : ''}`}>
        <Field label="Club" required={!off}>
          <select name="club_team_id" required={!off} disabled={off} defaultValue="" data-label="Club" className={input}>
            <option value="" disabled>Choose a club…</option>
            {clubs.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
          </select>
        </Field>
        <Field label="Joined on" required={!off}>
          <input name="club_start" type="date" required={!off} disabled={off} max={today} data-label="Joined on" className={input} />
        </Field>
        <Field label="How they joined">
          <select name="club_type" disabled={off} defaultValue="PERMANENT" data-label="How they joined" className={input}>
            <option value="PERMANENT">Permanent transfer</option>
            <option value="FREE">Free transfer</option>
            <option value="YOUTH">From the youth team</option>
            <option value="LOAN">On loan</option>
          </select>
        </Field>
        <Field label="Shirt number">
          <input name="club_shirt" type="number" min={0} max={99} disabled={off} data-label="Shirt number" className={input} />
        </Field>
      </div>
      {/* Reviewed in the confirmation, so a free agent is stated explicitly. */}
      <input type="hidden" value={off ? 'Free agent' : 'At a club'} data-label="Status" readOnly />
    </fieldset>
  );
}
