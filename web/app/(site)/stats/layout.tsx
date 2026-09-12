import { api } from "@/lib/api";
import { isNationalTeamEdition, resolveScope } from "@/lib/scope";
import { PageTitle } from "@/components/ui";
import { StatsTabs, type StatsTabsData } from "@/components/stats-tabs";

/**
 * One home for every aggregate the vault can support.
 *
 * The old navigation had Stats, Players, Clubs and Head to head side by side at
 * the top level, which asked a fan to know the difference before clicking. They
 * are all the same thing — statistics — so they are tabs under one heading, and
 * the top-level navigation is left with the three things a fan actually
 * distinguishes: what's on, the table, and the numbers.
 *
 * The heading names no competition. It used to read "Tanzania Premier League,
 * 2008/09 to 2026/27", written when the league was the only thing in the vault,
 * and it went on claiming that over an AFCON scope. A layout cannot see
 * `searchParams`, so it cannot know the scope — and each page already states it,
 * both in its own summary line and in the two dropdowns.
 */

export const dynamic = "force-dynamic";

/**
 * Everything the tabs need that only the server can fetch: which competitions
 * nations play in, which competition each edition belongs to, and where an
 * unscoped URL lands. The tabs pair this with the query string.
 */
async function tabData(): Promise<StatsTabsData> {
  try {
    const { editions } = await api.editions();
    const fallback = await resolveScope(undefined, undefined, editions);
    return {
      editions: editions.map((e) => ({
        editionId: e.editionId,
        competitionId: e.competitionId,
      })),
      nationalCompetitionIds: [
        ...new Set(
          editions.filter(isNationalTeamEdition).map((e) => e.competitionId),
        ),
      ],
      fallbackCompetitionId: fallback.competitionId,
    };
  } catch {
    // The page below will report the API being down; the tabs just stay whole.
    return { editions: [], nationalCompetitionIds: [], fallbackCompetitionId: undefined };
  }
}

export default async function StatsLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div>
      <PageTitle title="Statistics" />
      <StatsTabs data={await tabData()} />
      {children}
    </div>
  );
}
