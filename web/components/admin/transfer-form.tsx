'use client';

import { useState } from 'react';
import { ArrowRightLeft } from 'lucide-react';
import type { ActionState } from '@/lib/admin-actions';
import type { CareerSpell, TeamOption } from '@/lib/adminApi';
import { ConfirmForm } from './confirm-form';
import { Field } from './kit';
import { input } from './styles';

type Action = (prev: ActionState, formData: FormData) => Promise<ActionState>;

const fmt = (iso: string) =>
  new Date(`${iso}T12:00:00Z`).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });

/**
 * Record a move, with a confirmation that says in words what will happen to
 * the history — which spells end, on what date, and what begins. The server
 * applies the same rules (services/careers.ts) and refuses anything the
 * history contradicts; this only previews the ordinary case.
 */
export function TransferForm({
  playerId,
  playerName,
  clubs,
  running,
  today,
  action,
}: {
  playerId: number;
  playerName: string;
  clubs: TeamOption[];
  /** Club spells running today. */
  running: CareerSpell[];
  today: string;
  action: Action;
}) {
  const [to, setTo] = useState('');
  const [type, setType] = useState('PERMANENT');
  const [date, setDate] = useState(today);
  const [loanUntil, setLoanUntil] = useState('');

  const release = to === 'RELEASE';
  const loan = type === 'LOAN' && !release;
  const dest = clubs.find((c) => String(c.id) === to);
  const parent = running.find((s) => s.type !== 'LOAN');
  const ending = loan ? running.filter((s) => s.type === 'LOAN') : running;

  const description = !to ? (
    'Pick where the player is going.'
  ) : (
    <ul className="list-disc space-y-1 pl-4">
      {ending.map((s) => (
        <li key={s.id}>Their spell at <strong className="text-ink">{s.team.name}</strong> ends on {date ? fmt(date) : '—'}.</li>
      ))}
      {release ? (
        <li><strong className="text-ink">{playerName}</strong> becomes a free agent.</li>
      ) : loan ? (
        <li>
          A loan at <strong className="text-ink">{dest?.name}</strong> starts {date ? fmt(date) : '—'}
          {loanUntil ? ` and runs until ${fmt(loanUntil)}` : ', with no agreed end'}
          {parent ? <>, while they stay contracted to <strong className="text-ink">{parent.team.name}</strong></> : null}.
        </li>
      ) : (
        <li>A {type === 'FREE' ? 'free' : type === 'YOUTH' ? 'youth' : 'permanent'} spell at <strong className="text-ink">{dest?.name}</strong> starts {date ? fmt(date) : '—'}.</li>
      )}
      {ending.length === 0 && !release && !loan ? <li>No current club spell to end.</li> : null}
    </ul>
  );

  return (
    <ConfirmForm
      action={action}
      title={release ? `Release ${playerName}?` : loan ? `Loan ${playerName} out?` : `Transfer ${playerName}?`}
      description={description}
      confirmLabel={release ? 'Release player' : loan ? 'Record loan' : 'Record transfer'}
      tone={release ? 'danger' : 'primary'}
      review="all"
      resetOnSuccess
      trigger={<><ArrowRightLeft /> Record move</>}
      className="space-y-4 p-5"
    >
      <input type="hidden" name="playerId" value={playerId} />
      <Field label="Moving to" required>
        <select name="toTeamId" required value={to} onChange={(e) => setTo(e.target.value)} data-label="Moving to" className={input}>
          <option value="" disabled>Choose a club…</option>
          <option value="RELEASE">Released — becomes a free agent</option>
          <optgroup label="Clubs">
            {clubs.filter((c) => c.id !== parent?.team.id).map((c) => (
              <option key={c.id} value={c.id}>{c.name}</option>
            ))}
          </optgroup>
        </select>
      </Field>

      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Date" required hint={release ? 'Their last day at the club.' : 'First day at the new club.'}>
          <input name="date" type="date" required value={date} onChange={(e) => setDate(e.target.value)} data-label="Date" className={input} />
        </Field>
        {!release ? (
          <Field label="Type">
            <select name="type" value={type} onChange={(e) => setType(e.target.value)} data-label="Type" className={input}>
              <option value="PERMANENT">Permanent</option>
              <option value="LOAN" disabled={!parent}>Loan{parent ? '' : ' (needs a current club)'}</option>
              <option value="FREE">Free transfer</option>
              <option value="YOUTH">Youth promotion</option>
            </select>
          </Field>
        ) : null}
      </div>

      {!release ? (
        <div className="grid gap-4 sm:grid-cols-3">
          {loan ? (
            <Field label="Loan until" hint={parent?.end ? `By ${fmt(parent.end)} at the latest.` : 'Leave blank if open.'}>
              <input name="loanUntil" type="date" min={date || undefined} value={loanUntil}
                onChange={(e) => setLoanUntil(e.target.value)} data-label="Loan until" className={input} />
            </Field>
          ) : null}
          <Field label="Shirt number">
            <input name="shirtNumber" type="number" min={0} max={99} data-label="Shirt number" className={input} />
          </Field>
          <Field label="Fee" hint="Amount only — no currency is recorded.">
            <input name="fee" inputMode="decimal" data-label="Fee" className={input} />
          </Field>
        </div>
      ) : null}
    </ConfirmForm>
  );
}
