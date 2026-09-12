"use client";

import Link from "next/link";
import { usePathname, useSearchParams } from "next/navigation";
import { competitionFromParams, type EditionRef } from "@/lib/scope-params";

/**
 * The Statistics tabs: scoped links, and only the tabs the scope can answer.
 *
 * Two things a layout cannot do for itself. It never receives `searchParams`,
 * so bare hrefs used to drop `competitionId`/`editionId` on every tab change —
 * and it cannot tell whether the competition in view is played by clubs or by
 * nations, so it offered Clubs under AFCON and Nations under the Premier
 * League. Either one, clicked, silently resolves to some other competition,
 * because those two pages refuse a scope their kind of team does not play in.
 *
 * So the server hands down the facts and this reads the URL, deciding which
 * competition is in view with `competitionFromParams` — the same helper
 * `resolveScope` uses, so the tabs cannot disagree with the page below them.
 */

export type StatsTabsData = {
  /** Enough of every published edition to place it in a competition. */
  editions: EditionRef[];
  /** Competitions whose teams are national sides, not clubs. */
  nationalCompetitionIds: number[];
  /** What `resolveScope` lands on when the URL names no competition. */
  fallbackCompetitionId: number | undefined;
};

const TABS = [
  { href: "/stats", label: "Overview" },
  { href: "/stats/players", label: "Players" },
  { href: "/stats/clubs", label: "Clubs", teams: "CLUB" },
  { href: "/stats/nations", label: "Nations", teams: "NATIONAL" },
  { href: "/stats/head-to-head", label: "Head to head" },
] as const;

export function StatsTabs({ data }: { data: StatsTabsData }) {
  const pathname = usePathname();
  const search = useSearchParams();

  const competitionParam = search.get("competitionId") ?? undefined;
  const editionParam = search.get("editionId") ?? undefined;

  const competitionId =
    competitionFromParams(competitionParam, editionParam, data.editions) ??
    data.fallbackCompetitionId;

  // Unknown competition (an empty vault, or the API down) shows both tabs
  // rather than hiding one on a guess.
  const known = competitionId !== undefined;
  const national = known && data.nationalCompetitionIds.includes(competitionId);

  const tabs = TABS.filter(
    (t) =>
      !("teams" in t) ||
      !known ||
      // Never hide the tab you are standing on. A stale link can put an AFCON
      // edition in the URL of /stats/clubs; that page quietly resolves to a
      // club competition anyway, and dropping its own tab would leave nothing
      // marked current.
      pathname === t.href ||
      (t.teams === "NATIONAL" ? national : !national),
  );

  const scoped = (href: string) => {
    const q = new URLSearchParams();
    if (competitionParam) q.set("competitionId", competitionParam);
    if (editionParam) q.set("editionId", editionParam);
    const qs = q.toString();
    return qs ? `${href}?${qs}` : href;
  };

  return (
    <nav className="mb-5 -mx-4 overflow-x-auto px-4">
      <ul className="flex min-w-max gap-1.5 border-b border-line pb-px">
        {tabs.map((t) => (
          <li key={t.href}>
            <Link
              href={scoped(t.href)}
              aria-current={pathname === t.href ? "page" : undefined}
              className="inline-block rounded-t-lg px-3.5 py-2 text-sm font-semibold text-muted transition-colors hover:bg-wash hover:text-ink aria-[current=page]:text-ink"
            >
              {t.label}
            </Link>
          </li>
        ))}
      </ul>
    </nav>
  );
}
