'use client';

import { useMemo, useState } from 'react';
import { Play } from 'lucide-react';
import type { ActionState } from '@/lib/admin-actions';
import { ConfirmForm } from './confirm-form';

type Action = (prev: ActionState, formData: FormData) => Promise<ActionState>;

export type ScopeCompetition = {
  id: number;
  name: string;
  editions: { editionId: number; season: string; isPublished: boolean }[];
};

/**
 * Choose what an audit covers: the whole vault, or competitions and seasons.
 * Ticking a competition covers every season of it; opening it lets you pick
 * seasons instead. The confirmation states the scope in words.
 */
export function AuditScopeForm({ competitions, action }: { competitions: ScopeCompetition[]; action: Action }) {
  const [whole, setWhole] = useState(true);
  const [comps, setComps] = useState<Set<number>>(new Set());
  const [eds, setEds] = useState<Set<number>>(new Set());
  const [careers, setCareers] = useState(true);

  const toggle = (set: Set<number>, id: number, on: boolean) => {
    const next = new Set(set);
    if (on) next.add(id);
    else next.delete(id);
    return next;
  };

  const summary = useMemo(() => {
    if (whole) return `every competition and season${careers ? ', plus player careers' : ''}`;
    const parts: string[] = [];
    for (const c of competitions) {
      if (comps.has(c.id)) parts.push(`${c.name} (all ${c.editions.length} seasons)`);
      else {
        const picked = c.editions.filter((e) => eds.has(e.editionId));
        if (picked.length) parts.push(`${c.name} ${picked.map((e) => e.season).join(', ')}`);
      }
    }
    if (careers) parts.push('player careers');
    return parts.length ? parts.join('; ') : 'nothing yet';
  }, [whole, careers, comps, eds, competitions]);

  const nothing = !whole && comps.size === 0 && eds.size === 0 && !careers;

  const radio = (value: boolean, title: string, hint: string) => (
    <label className={`flex cursor-pointer items-start gap-3 rounded-lg border p-3 text-sm ${whole === value ? 'border-ink bg-wash' : 'border-line hover:border-ink/40'}`}>
      <input type="radio" name="scope" value={value ? 'all' : 'selected'} checked={whole === value}
        onChange={() => setWhole(value)} className="mt-0.5 h-4 w-4 accent-[var(--ink)]" />
      <span>
        <span className="block font-semibold">{title}</span>
        <span className="block text-xs text-muted">{hint}</span>
      </span>
    </label>
  );

  return (
    <ConfirmForm
      action={action}
      title="Run a data audit?"
      description={
        <>
          Checks <strong className="text-ink">{summary}</strong>. New problems open findings; problems no longer found are
          marked resolved; anything marked fixed that is still wrong reopens. The data itself is not changed.
        </>
      }
      confirmLabel="Run audit"
      trigger={<><Play /> Run audit</>}
      disabled={nothing}
      className="space-y-4 p-5"
    >
      <div className="grid gap-2">
        {radio(true, 'Whole vault', 'Every competition and season.')}
        {radio(false, 'Selected competitions or seasons', 'Only what you tick below.')}
      </div>

      {!whole ? (
        <div className="max-h-72 space-y-1 overflow-y-auto rounded-lg border border-line p-2">
          {competitions.map((c) => {
            const allOn = comps.has(c.id);
            return (
              <details key={c.id} className="group rounded-md">
                <summary className="flex cursor-pointer list-none items-center gap-2 rounded-md px-2 py-1.5 text-sm hover:bg-wash">
                  <input
                    type="checkbox"
                    name="competitionIds"
                    value={c.id}
                    checked={allOn}
                    onClick={(e) => e.stopPropagation()}
                    onChange={(e) => {
                      setComps(toggle(comps, c.id, e.target.checked));
                      // Picking the whole competition supersedes any single seasons.
                      if (e.target.checked) setEds(new Set([...eds].filter((id) => !c.editions.some((x) => x.editionId === id))));
                    }}
                    className="h-4 w-4 accent-[var(--ink)]"
                  />
                  <span className="min-w-0 flex-1 truncate font-medium">{c.name}</span>
                  <span className="text-xs text-muted">{c.editions.length} seasons ▾</span>
                </summary>
                <div className="grid grid-cols-2 gap-1 px-8 pb-2 pt-1 sm:grid-cols-3">
                  {c.editions.map((e) => (
                    <label key={e.editionId} className={`flex items-center gap-1.5 text-xs ${allOn ? 'opacity-50' : ''}`}>
                      <input
                        type="checkbox"
                        name="editionIds"
                        value={e.editionId}
                        disabled={allOn}
                        checked={allOn || eds.has(e.editionId)}
                        onChange={(ev) => setEds(toggle(eds, e.editionId, ev.target.checked))}
                        className="h-3.5 w-3.5 accent-[var(--ink)]"
                      />
                      {e.season}
                    </label>
                  ))}
                </div>
              </details>
            );
          })}
        </div>
      ) : null}

      <label className="flex items-start gap-2 text-sm">
        <input type="checkbox" name="includeCareers" checked={careers} onChange={(e) => setCareers(e.target.checked)}
          className="mt-0.5 h-4 w-4 accent-[var(--ink)]" />
        <span>
          <span className="font-medium">Include player careers</span>
          <span className="block text-xs text-muted">Overlapping and contradicted club spells. Not tied to a season.</span>
        </span>
      </label>
    </ConfirmForm>
  );
}
