import type { Lookups, PlayerRecord } from '@/lib/adminApi';
import { Field } from './kit';
import { input } from './styles';

export function PlayerFields({ lookups, initial }: { lookups: Lookups; initial?: PlayerRecord }) {
  return (
    <div className="grid gap-4 sm:grid-cols-2">
      <Field label="Full name" required className="sm:col-span-2" hint="As it should appear on the public site.">
        <input name="full_name" required maxLength={150} defaultValue={initial?.full_name ?? ''} data-label="Full name" className={input} />
      </Field>
      <Field label="First name">
        <input name="first_name" maxLength={60} defaultValue={initial?.first_name ?? ''} data-label="First name" className={input} />
      </Field>
      <Field label="Last name">
        <input name="last_name" maxLength={60} defaultValue={initial?.last_name ?? ''} data-label="Last name" className={input} />
      </Field>
      <Field label="Date of birth">
        <input name="dob" type="date" defaultValue={initial?.dob?.slice(0, 10) ?? ''} data-label="Date of birth" className={input} />
      </Field>
      <Field label="Nationality">
        <select name="nationality_id" defaultValue={initial?.nationality_id ?? ''} data-label="Nationality" className={input}>
          <option value="">Not recorded</option>
          {lookups.countries.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
        </select>
      </Field>
      <Field label="Position">
        <select name="position" defaultValue={initial?.position ?? ''} data-label="Position" className={input}>
          <option value="">Not recorded</option>
          <option value="GK">Goalkeeper</option>
          <option value="DF">Defender</option>
          <option value="MF">Midfielder</option>
          <option value="FW">Forward</option>
        </select>
      </Field>
      <Field label="Preferred foot">
        <select name="preferred_foot" defaultValue={initial?.preferred_foot ?? ''} data-label="Preferred foot" className={input}>
          <option value="">Not recorded</option>
          <option value="LEFT">Left</option>
          <option value="RIGHT">Right</option>
          <option value="BOTH">Both</option>
        </select>
      </Field>
      <Field label="Height (cm)">
        <input name="height_cm" type="number" min={100} max={250} defaultValue={initial?.height_cm ?? ''} data-label="Height (cm)" className={input} />
      </Field>
    </div>
  );
}
