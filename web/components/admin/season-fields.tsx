import { Field } from './kit';
import { input } from './styles';

const day = (iso: string | null | undefined) => (iso ? iso.slice(0, 10) : '');

export function SeasonFields({
  initial,
}: {
  initial?: { label: string; startDate: string | null; endDate: string | null };
}) {
  return (
    <div className="grid gap-4 sm:grid-cols-3">
      <Field label="Label" required hint="2025/2026 for a split season, 2025 for a calendar year.">
        <input
          name="label"
          required
          pattern="\d{4}(/\d{4})?"
          title="Use 2025/2026 or 2025"
          defaultValue={initial?.label ?? ''}
          placeholder="2027/2028"
          data-label="Label"
          className={input}
        />
      </Field>
      <Field label="Starts">
        <input name="start_date" type="date" defaultValue={day(initial?.startDate)} data-label="Starts" className={input} />
      </Field>
      <Field label="Ends">
        <input name="end_date" type="date" defaultValue={day(initial?.endDate)} data-label="Ends" className={input} />
      </Field>
    </div>
  );
}
