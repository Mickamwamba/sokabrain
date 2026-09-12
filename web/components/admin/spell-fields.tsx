import type { CareerSpell, TeamOption } from '@/lib/adminApi';
import { Field } from './kit';
import { input } from './styles';

/**
 * The fields of one spell, for adding past history or correcting a spell.
 * Offers clubs and national teams: a call-up is recorded as a spell too.
 */
export function SpellFields({ teams, initial }: { teams: TeamOption[]; initial?: CareerSpell }) {
  const clubs = teams.filter((t) => t.type === 'CLUB');
  const nations = teams.filter((t) => t.type === 'NATIONAL');
  return (
    <div className="grid gap-4 sm:grid-cols-2">
      <Field label="Team" required className="sm:col-span-2">
        <select name="teamId" required defaultValue={initial?.team.id ?? ''} data-label="Team" className={input}>
          <option value="" disabled>Choose a team…</option>
          <optgroup label="Clubs">{clubs.map((t) => <option key={t.id} value={t.id}>{t.name}</option>)}</optgroup>
          <optgroup label="National teams">{nations.map((t) => <option key={t.id} value={t.id}>{t.name}</option>)}</optgroup>
        </select>
      </Field>
      <Field label="From" required>
        <input name="startDate" type="date" required defaultValue={initial?.start ?? ''} data-label="From" className={input} />
      </Field>
      <Field label="Until" hint="Blank if still there.">
        <input name="endDate" type="date" defaultValue={initial?.end ?? ''} data-label="Until" className={input} />
      </Field>
      <Field label="Type">
        <select name="type" defaultValue={initial?.type ?? ''} data-label="Type" className={input}>
          <option value="">Not recorded</option>
          <option value="PERMANENT">Permanent</option>
          <option value="LOAN">Loan</option>
          <option value="FREE">Free transfer</option>
          <option value="YOUTH">Youth</option>
        </select>
      </Field>
      <Field label="Shirt number">
        <input name="shirtNumber" type="number" min={0} max={99} defaultValue={initial?.shirtNumber ?? ''} data-label="Shirt number" className={input} />
      </Field>
      <Field label="Fee" hint="Amount only — no currency is recorded." className="sm:col-span-2">
        <input name="fee" inputMode="decimal" defaultValue={initial?.fee ?? ''} data-label="Fee" className={input} />
      </Field>
    </div>
  );
}
