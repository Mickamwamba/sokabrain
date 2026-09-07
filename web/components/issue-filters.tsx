'use client';

import { useRouter } from 'next/navigation';
import { useTransition } from 'react';
import type { FilterCompetition } from './match-filters';

const select =
  'rounded-lg border border-line bg-paper px-3 py-2 text-sm font-medium focus:border-ink focus:outline-none disabled:opacity-50';

/** Competition and season dropdowns for the issues worklist. */
export function IssueFilters({
  competitions,
  competitionId,
  editionId,
  kind,
  kinds,
}: {
  competitions: FilterCompetition[];
  competitionId: number | undefined;
  editionId: number | undefined;
  kind: string | undefined;
  kinds: { value: string; label: string; count: number }[];
}) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const active = competitions.find((c) => c.id === competitionId);

  const go = (p: { competitionId?: number; editionId?: number; kind?: string }) => {
    const q = new URLSearchParams();
    if (p.competitionId !== undefined) q.set('competitionId', String(p.competitionId));
    if (p.editionId !== undefined) q.set('editionId', String(p.editionId));
    if (p.kind) q.set('kind', p.kind);
    startTransition(() => router.push(`/admin/issues?${q}`));
  };

  return (
    <div className="flex flex-wrap items-end gap-3">
      <label className="block">
        <span className="block text-xs font-semibold uppercase tracking-wide text-muted">
          Competition
        </span>
        <select
          className={`mt-1 ${select} min-w-56`} value={competitionId ?? ''} disabled={pending}
          onChange={(e) => {
            const id = Number(e.target.value);
            const first = competitions.find((c) => c.id === id)?.editions[0]?.editionId;
            go({ competitionId: id, ...(first !== undefined && { editionId: first }) });
          }}
        >
          {competitions.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name}{c.country ? ` — ${c.country.replace(', United Republic of', '')}` : ''}
            </option>
          ))}
        </select>
      </label>

      <label className="block">
        <span className="block text-xs font-semibold uppercase tracking-wide text-muted">Season</span>
        <select
          className={`mt-1 ${select} min-w-36`} value={editionId ?? ''}
          disabled={pending || !active?.editions.length}
          onChange={(e) =>
            go({ ...(competitionId !== undefined && { competitionId }), editionId: Number(e.target.value) })
          }
        >
          {(active?.editions ?? []).map((s) => (
            <option key={s.editionId} value={s.editionId}>{s.season}</option>
          ))}
        </select>
      </label>

      <label className="block">
        <span className="block text-xs font-semibold uppercase tracking-wide text-muted">Issue type</span>
        <select
          className={`mt-1 ${select} min-w-52`} value={kind ?? ''} disabled={pending}
          onChange={(e) =>
            go({
              ...(competitionId !== undefined && { competitionId }),
              ...(editionId !== undefined && { editionId }),
              ...(e.target.value && { kind: e.target.value }),
            })
          }
        >
          <option value="">All issue types</option>
          {kinds.map((k) => (
            <option key={k.value} value={k.value}>{k.label} ({k.count})</option>
          ))}
        </select>
      </label>

      {pending ? <span className="pb-3 text-xs text-muted">Loading…</span> : null}
    </div>
  );
}
