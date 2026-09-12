'use client';

import { useRouter } from 'next/navigation';
import { useTransition } from 'react';
import { input } from './styles';

export type PickerCompetition = {
  id: number;
  name: string;
  country: string | null;
  editions: { editionId: number; season: string }[];
};

/**
 * Competition and season dropdowns that navigate on change. Choosing a
 * competition lands on its newest season, since the season previously selected
 * belongs to a different competition.
 */
export function ScopePicker({
  competitions,
  competitionId,
  editionId,
  basePath,
}: {
  competitions: PickerCompetition[];
  competitionId: number | undefined;
  editionId: number | undefined;
  basePath: string;
}) {
  const router = useRouter();
  const [pending, start] = useTransition();
  const seasons = competitions.find((c) => c.id === competitionId)?.editions ?? [];

  const go = (edition: number | undefined, competition: number) =>
    start(() => {
      const q = new URLSearchParams({ competitionId: String(competition) });
      if (edition !== undefined) q.set('editionId', String(edition));
      router.push(`${basePath}?${q}`);
    });

  return (
    <div className="flex flex-wrap items-end gap-3">
      <label className="block min-w-56 flex-1 sm:flex-none">
        <span className="mb-1.5 block text-xs font-semibold">Competition</span>
        <select
          className={input}
          value={competitionId ?? ''}
          disabled={pending}
          onChange={(e) => {
            const id = Number(e.target.value);
            go(competitions.find((c) => c.id === id)?.editions[0]?.editionId, id);
          }}
        >
          {competitions.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name}{c.country ? ` — ${c.country.replace(', United Republic of', '')}` : ''}
            </option>
          ))}
        </select>
      </label>
      <label className="block min-w-40">
        <span className="mb-1.5 block text-xs font-semibold">Season</span>
        <select
          className={input}
          value={editionId ?? ''}
          disabled={pending || seasons.length === 0}
          onChange={(e) => competitionId !== undefined && go(Number(e.target.value), competitionId)}
        >
          {seasons.map((s) => (
            <option key={s.editionId} value={s.editionId}>{s.season}</option>
          ))}
        </select>
      </label>
      {pending ? <span className="pb-2.5 text-xs text-muted">Loading…</span> : null}
    </div>
  );
}
