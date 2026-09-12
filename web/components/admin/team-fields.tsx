import type { Lookups, TeamRecord } from '@/lib/adminApi';
import { Field } from './kit';
import { input } from './styles';

export function TeamFields({ lookups, initial }: { lookups: Lookups; initial?: TeamRecord }) {
  return (
    <div className="grid gap-4 sm:grid-cols-2">
      <Field label="Name" required>
        <input name="name" required maxLength={100} defaultValue={initial?.name ?? ''} data-label="Name" className={input} />
      </Field>
      <Field label="Short name" hint="Up to 10 characters, e.g. YNG.">
        <input name="short_name" maxLength={10} defaultValue={initial?.short_name ?? ''} data-label="Short name" className={input} />
      </Field>
      <Field label="Type" required>
        <select name="type" defaultValue={initial?.type ?? 'CLUB'} data-label="Type" className={input}>
          <option value="CLUB">Club</option>
          <option value="NATIONAL">National team</option>
        </select>
      </Field>
      <Field label="Country" required>
        <select name="country_id" required defaultValue={initial?.country_id ?? ''} data-label="Country" className={input}>
          <option value="" disabled>Choose a country…</option>
          {lookups.countries.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
        </select>
      </Field>
      <Field label="Home ground" className="sm:col-span-2">
        <select name="stadium_id" defaultValue={initial?.stadium_id ?? ''} data-label="Home ground" className={input}>
          <option value="">Not recorded</option>
          {lookups.stadiums.map((s) => (
            <option key={s.id} value={s.id}>{s.name}{s.city ? `, ${s.city}` : ''}</option>
          ))}
        </select>
      </Field>
    </div>
  );
}
