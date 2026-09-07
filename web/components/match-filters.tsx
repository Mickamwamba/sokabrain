'use client';

import { useRouter } from 'next/navigation';
import { useTransition } from 'react';

export type FilterCompetition = {
  id: number;
  name: string;
  country: string | null;
  editions: { editionId: number; season: string; matchCount: number; isPublished: boolean }[];
};

const select =
  'rounded-lg border border-line bg-paper px-3 py-2 text-sm font-medium focus:border-ink focus:outline-none disabled:opacity-50';

/**
 * Competition and season dropdowns for the matches screen.
 *
 * Navigates on change rather than needing a submit button. Changing competition
 * jumps straight to that competition's newest season, because the previously
 * selected season belongs to a different competition and carrying it over would
 * produce an empty list.
 */
export function MatchFilters({
  competitions,
  competitionId,
  editionId,
  needsAttention,
}: {
  competitions: FilterCompetition[];
  competitionId: number | undefined;
  editionId: number | undefined;
  needsAttention: boolean;
}) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();

  const active = competitions.find((c) => c.id === competitionId);
  const seasons = active?.editions ?? [];

  const go = (params: { competitionId?: number; editionId?: number; needsAttention?: boolean }) => {
    const q = new URLSearchParams();
    if (params.competitionId !== undefined) q.set('competitionId', String(params.competitionId));
    if (params.editionId !== undefined) q.set('editionId', String(params.editionId));
    if (params.needsAttention) q.set('needsAttention', 'true');
    startTransition(() => router.push(`/admin/matches?${q}`));
  };

  return (
    <div className="flex flex-wrap items-end gap-3">
      <label className="block">
        <span className="block text-xs font-semibold uppercase tracking-wide text-muted">
          Competition
        </span>
        <select
          className={`mt-1 ${select} min-w-56`}
          value={competitionId ?? ''}
          disabled={pending}
          onChange={(e) => {
            const id = Number(e.target.value);
            const next = competitions.find((c) => c.id === id);
            // Land on the newest season of the newly chosen competition.
            const firstEdition = next?.editions[0]?.editionId;
            go({
              competitionId: id,
              ...(firstEdition !== undefined && { editionId: firstEdition }),
              needsAttention,
            });
          }}
        >
          {competitions.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name}
              {c.country ? ` — ${c.country.replace(', United Republic of', '')}` : ''}
            </option>
          ))}
        </select>
      </label>

      <label className="block">
        <span className="block text-xs font-semibold uppercase tracking-wide text-muted">
          Season
        </span>
        <select
          className={`mt-1 ${select} min-w-40`}
          value={editionId ?? ''}
          disabled={pending || seasons.length === 0}
          onChange={(e) =>
            go({
              ...(competitionId !== undefined && { competitionId }),
              editionId: Number(e.target.value),
              needsAttention,
            })
          }
        >
          {seasons.length === 0 ? (
            <option value="">No seasons</option>
          ) : (
            seasons.map((s) => (
              <option key={s.editionId} value={s.editionId}>
                {s.season} ({s.matchCount})
              </option>
            ))
          )}
        </select>
      </label>

      <label className="flex items-center gap-2 pb-2.5 text-sm">
        <input
          type="checkbox"
          checked={needsAttention}
          disabled={pending}
          onChange={(e) =>
            go({
              ...(competitionId !== undefined && { competitionId }),
              ...(editionId !== undefined && { editionId }),
              needsAttention: e.target.checked,
            })
          }
          className="h-4 w-4 rounded border-line"
        />
        <span className="font-medium">Only matches needing a score</span>
      </label>

      {pending ? <span className="pb-3 text-xs text-muted">Loading…</span> : null}
    </div>
  );
}
