"use client";

import { useRouter, useSearchParams } from "next/navigation";
import { usePathname } from "next/navigation";

/**
 * The one season control, used on every page that has seasons.
 *
 * Nineteen seasons as chips filled three lines and pushed the actual content
 * below the fold, so this is a dropdown sitting beside the page title. Being a
 * single control everywhere also means a fan learns it once.
 *
 * The value lives in the URL, so a chosen season is still shareable and the
 * back button still works — the select just navigates.
 *
 * `all` is a real value, not the absence of one: a page that supports all-time
 * figures must be able to say it is showing them, and "no parameter" cannot be
 * told apart from "not chosen yet".
 */

export const ALL_TIME = "all";

export function SeasonSelect({
  seasons,
  value,
  allowAllTime = false,
  /** Params that belong to the old season and would be nonsense under the new one. */
  clears = [],
  param = "editionId",
}: {
  seasons: { value: string; label: string }[];
  value: string;
  allowAllTime?: boolean;
  clears?: string[];
  param?: string;
}) {
  const router = useRouter();
  const pathname = usePathname();
  const search = useSearchParams();

  function go(next: string) {
    const q = new URLSearchParams(search.toString());
    q.set(param, next);
    for (const c of clears) q.delete(c);
    router.push(`${pathname}?${q.toString()}`);
  }

  return (
    <label className="flex shrink-0 items-center gap-2">
      <span className="display text-[10px] font-bold uppercase tracking-wider text-muted">
        Season
      </span>
      <select
        value={value}
        onChange={(e) => go(e.target.value)}
        className="nums cursor-pointer rounded-lg border border-line bg-paper py-1.5 pl-3 pr-8 text-sm font-semibold hover:border-ink focus:border-ink focus:outline-none"
      >
        {allowAllTime ? <option value={ALL_TIME}>All time</option> : null}
        {seasons.map((s) => (
          <option key={s.value} value={s.value}>
            {s.label}
          </option>
        ))}
      </select>
    </label>
  );
}

/** Says, unmissably, that the figures below are not one season's. */
export function AllTimeBadge() {
  return (
    <span className="inline-flex items-center gap-1.5 rounded-full bg-ink px-3 py-1 text-[11px] font-semibold text-white">
      All time
      <span className="font-normal text-white/70">· every published season</span>
    </span>
  );
}
