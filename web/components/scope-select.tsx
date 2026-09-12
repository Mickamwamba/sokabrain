"use client";

import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { ALL_TIME, type CompetitionRef } from "@/lib/scope";

/**
 * The competition and season controls, side by side.
 *
 * They are one control in two halves: a season only means something inside a
 * competition, and "2018/19" names both a league season and an AFCON. Picking
 * a competition therefore clears the season, so the page lands on that
 * competition's most recent one rather than keeping a season that belongs to a
 * different competition entirely.
 *
 * Both live in the URL, so a chosen scope stays shareable and the back button
 * still works.
 */
export function ScopeSelect({
  competitions,
  competitionId,
  seasons,
  value,
  allowAllTime = false,
  /** Params that belong to the old scope and would be nonsense under the new. */
  clears = [],
}: {
  competitions: CompetitionRef[];
  competitionId: number;
  seasons: { value: string; label: string }[];
  value: string;
  allowAllTime?: boolean;
  clears?: string[];
}) {
  const router = useRouter();
  const pathname = usePathname();
  const search = useSearchParams();

  function go(patch: Record<string, string | undefined>) {
    const q = new URLSearchParams(search.toString());
    for (const [k, v] of Object.entries(patch)) {
      if (v === undefined) q.delete(k);
      else q.set(k, v);
    }
    for (const c of clears) q.delete(c);
    router.push(`${pathname}?${q.toString()}`);
  }

  const box =
    "cursor-pointer rounded-lg border border-line bg-paper py-1.5 pl-3 pr-8 text-sm font-semibold hover:border-ink focus:border-ink focus:outline-none";

  return (
    <div className="flex shrink-0 flex-wrap items-center gap-3">
      {competitions.length > 1 ? (
        <label className="flex shrink-0 items-center gap-2">
          <span className="display text-[10px] font-bold uppercase tracking-wider text-muted">
            Competition
          </span>
          <select
            value={String(competitionId)}
            // Changing competition drops the season: keeping it would leave the
            // page scoped to a season of the competition just navigated away from.
            onChange={(e) => go({ competitionId: e.target.value, editionId: undefined })}
            className={box}
          >
            {competitions.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
        </label>
      ) : null}

      <label className="flex shrink-0 items-center gap-2">
        <span className="display text-[10px] font-bold uppercase tracking-wider text-muted">
          Season
        </span>
        <select
          value={value}
          onChange={(e) => go({ competitionId: String(competitionId), editionId: e.target.value })}
          className={`nums ${box}`}
        >
          {allowAllTime ? <option value={ALL_TIME}>All time</option> : null}
          {seasons.map((s) => (
            <option key={s.value} value={s.value}>
              {s.label}
            </option>
          ))}
        </select>
      </label>
    </div>
  );
}

/** Says, unmissably, which competition's whole history is on screen. */
export function AllTimeBadge({ competition }: { competition?: string }) {
  return (
    <span className="inline-flex items-center gap-1.5 rounded-full bg-ink px-3 py-1 text-[11px] font-semibold text-white">
      All time
      <span className="font-normal text-white/70">
        · every published {competition ? `${competition} season` : "season"}
      </span>
    </span>
  );
}
