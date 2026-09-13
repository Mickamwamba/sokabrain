'use client';

import { useEffect, useRef, useState, useTransition } from 'react';
import { usePathname, useRouter, useSearchParams } from 'next/navigation';
import { Search, UserRound } from 'lucide-react';
import type { PlayerHit } from '@/lib/adminApi';
import { input } from './styles';

/**
 * Find a player by name and make them the subject of the page, by putting
 * `playerId` in the URL — the page then loads their career server-side, so a
 * selection survives a reload and can be shared.
 */
export function PlayerPicker({
  search,
  placeholder = 'Search for a player…',
}: {
  search: (q: string) => Promise<PlayerHit[]>;
  placeholder?: string;
}) {
  const [q, setQ] = useState('');
  const [hits, setHits] = useState<PlayerHit[]>([]);
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState(0);
  const [loading, startSearch] = useTransition();
  const router = useRouter();
  const pathname = usePathname();
  const params = useSearchParams();
  const box = useRef<HTMLDivElement>(null);
  const seq = useRef(0);

  // Debounced search; a slower earlier response never overwrites a later one.
  useEffect(() => {
    const term = q.trim();
    const mine = ++seq.current;
    const t = window.setTimeout(() => {
      if (term.length < 2) {
        if (mine === seq.current) setHits([]);
        return;
      }
      startSearch(async () => {
        const found = await search(term);
        if (mine === seq.current) {
          setHits(found);
          setActive(0);
        }
      });
    }, 200);
    return () => window.clearTimeout(t);
  }, [q, search]);

  useEffect(() => {
    const close = (e: MouseEvent) => {
      if (box.current && !box.current.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener('mousedown', close);
    return () => document.removeEventListener('mousedown', close);
  }, []);

  const choose = (hit: PlayerHit) => {
    const next = new URLSearchParams(params.toString());
    next.set('playerId', String(hit.id));
    setOpen(false);
    setQ('');
    router.push(`${pathname}?${next}`, { scroll: false });
  };

  return (
    <div ref={box} className="relative">
      <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted" />
      <input
        role="combobox"
        aria-expanded={open && hits.length > 0}
        aria-controls="player-picker-list"
        aria-autocomplete="list"
        value={q}
        placeholder={placeholder}
        onChange={(e) => { setQ(e.target.value); setOpen(true); }}
        onFocus={() => setOpen(true)}
        onKeyDown={(e) => {
          if (!hits.length) return;
          if (e.key === 'ArrowDown') { e.preventDefault(); setActive((i) => Math.min(i + 1, hits.length - 1)); }
          if (e.key === 'ArrowUp') { e.preventDefault(); setActive((i) => Math.max(i - 1, 0)); }
          if (e.key === 'Enter') { e.preventDefault(); const h = hits[active]; if (h) choose(h); }
          if (e.key === 'Escape') setOpen(false);
        }}
        className={`${input} pl-9`}
      />
      {open && q.trim().length >= 2 ? (
        <ul
          id="player-picker-list"
          role="listbox"
          className="absolute inset-x-0 top-full z-20 mt-1 max-h-72 overflow-y-auto rounded-xl border border-line bg-paper py-1 shadow-lg"
        >
          {hits.length === 0 ? (
            <li className="px-3 py-2.5 text-sm text-muted">{loading ? 'Searching…' : 'No player matches that name.'}</li>
          ) : (
            hits.map((h, i) => (
              <li key={h.id} role="option" aria-selected={i === active}>
                <button
                  type="button"
                  onMouseEnter={() => setActive(i)}
                  onClick={() => choose(h)}
                  className={`flex w-full items-center gap-3 px-3 py-2 text-left text-sm ${i === active ? 'bg-wash' : ''}`}
                >
                  <UserRound className="h-4 w-4 shrink-0 text-muted" />
                  <span className="min-w-0 flex-1 truncate font-medium">{h.name}</span>
                  <span className="shrink-0 text-xs text-muted">{h.club}</span>
                </button>
              </li>
            ))
          )}
        </ul>
      ) : null}
    </div>
  );
}
