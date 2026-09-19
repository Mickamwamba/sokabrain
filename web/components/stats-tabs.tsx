"use client";

import Link from "next/link";
import { usePathname, useSearchParams } from "next/navigation";
import { competitionFromParams, type EditionRef } from "@/lib/scope-params";

export type StatsTabsData = {
  editions: EditionRef[];
  nationalCompetitionIds: number[];
  fallbackCompetitionId: number | undefined;
};

const TABS = [
  { href: "/stats", label: "Overview" },
  { href: "/stats/players", label: "Players & Top Scorers" },
  { href: "/stats/clubs", label: "Clubs", teams: "CLUB" },
  { href: "/stats/nations", label: "Nations", teams: "NATIONAL" },
  { href: "/stats/head-to-head", label: "Head to Head" },
] as const;

export function StatsTabs({ data }: { data: StatsTabsData }) {
  const pathname = usePathname();
  const search = useSearchParams();

  const competitionParam = search.get("competitionId") ?? undefined;
  const editionParam = search.get("editionId") ?? undefined;

  const competitionId =
    competitionFromParams(competitionParam, editionParam, data.editions) ??
    data.fallbackCompetitionId;

  const known = competitionId !== undefined;
  const national = known && data.nationalCompetitionIds.includes(competitionId);

  const tabs = TABS.filter(
    (t) =>
      !("teams" in t) ||
      !known ||
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
    <nav className="mb-6 -mx-4 overflow-x-auto px-4 pb-1 scrollbar-none">
      <div className="inline-flex min-w-max items-center gap-1 rounded-xl border border-line bg-paper p-1 shadow-2xs">
        {tabs.map((t) => {
          const isActive = pathname === t.href;
          return (
            <Link
              key={t.href}
              href={scoped(t.href)}
              aria-current={isActive ? "page" : undefined}
              className={`rounded-lg px-3.5 py-1.5 text-xs font-bold transition-all ${
                isActive
                  ? "bg-ink text-white shadow-xs"
                  : "text-muted hover:text-ink hover:bg-wash"
              }`}
            >
              {t.label}
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
