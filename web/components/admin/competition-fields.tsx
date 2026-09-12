import type { Lookups } from '@/lib/adminApi';
import { Field, humanise } from './kit';
import { input } from './styles';

/** Name, type, country and tier — shared by the create and edit forms. */
export function CompetitionFields({
  lookups,
  initial,
}: {
  lookups: Lookups;
  initial?: { name: string; type: string; countryId: number | null; tier: number | null };
}) {
  return (
    <div className="grid gap-4 sm:grid-cols-2">
      <Field label="Name" required className="sm:col-span-2">
        <input name="name" required maxLength={150} defaultValue={initial?.name ?? ''}
          placeholder="e.g. Tanzania Championship League" data-label="Name" className={input} />
      </Field>
      <Field label="Type" required>
        <select name="type" defaultValue={initial?.type ?? 'LEAGUE'} data-label="Type" className={input}>
          {lookups.competitionTypes.map((t) => (
            <option key={t} value={t}>{humanise(t)}</option>
          ))}
        </select>
      </Field>
      <Field label="Tier" hint="Leagues only: 1 is the top flight.">
        <input name="tier" type="number" min={1} max={10} defaultValue={initial?.tier ?? ''}
          data-label="Tier" className={input} />
      </Field>
      <Field label="Country" hint="Leave as international for a continental or world competition." className="sm:col-span-2">
        <select name="countryId" defaultValue={initial?.countryId ?? ''} data-label="Country" className={input}>
          <option value="">International — no single country</option>
          {lookups.countries.map((c) => (
            <option key={c.id} value={c.id}>{c.name}</option>
          ))}
        </select>
      </Field>
    </div>
  );
}
