import Link from "next/link";
import { api, ApiError, type Edition } from "@/lib/api";
import {
  competitionHref,
  summariseCompetitions,
  type CompetitionSummary,
} from "@/lib/competitions";
import { Card, Crest, Empty, PageTitle } from "@/components/ui";

export const dynamic = "force-dynamic";

/**
 * What the vault holds, one card per competition.
 *
 * This used to be one card per *edition*, so the page opened with nineteen
 * near-identical Premier League tiles before AFCON got a look in. A fan picks
 * the competition here and the season afterwards, from the dropdown the table
 * carries — which is also why these cards name no season in their link.
 */

function groupByCountry(competitions: CompetitionSummary[]) {
  const groups = new Map<string, CompetitionSummary[]>();
  for (const c of competitions) {
    const key = c.country ?? "Continental & international";
    const list = groups.get(key);
    if (list) list.push(c);
    else groups.set(key, [c]);
  }
  // Domestic leagues first — local depth is the point of this product.
  return [...groups.entries()].sort(([a], [b]) => {
    if (a.startsWith("Continental")) return 1;
    if (b.startsWith("Continental")) return -1;
    return a.localeCompare(b);
  });
}

export default async function CompetitionsPage() {
  let editions: Edition[];
  try {
    editions = (await api.editions()).editions;
  } catch (err) {
    if (err instanceof ApiError) return <Empty>{err.message}</Empty>;
    throw err;
  }

  if (editions.length === 0) {
    return <Empty>No competitions have been published yet.</Empty>;
  }

  const competitions = summariseCompetitions(editions);
  const matches = competitions.reduce((n, c) => n + c.matches, 0);

  return (
    <div>
      <PageTitle
        title="Competitions"
        sub={`${competitions.length} ${
          competitions.length === 1 ? "competition" : "competitions"
        } · ${editions.length} published seasons · ${matches.toLocaleString()} matches`}
      />

      <div className="space-y-7">
        {groupByCountry(competitions).map(([country, list]) => (
          <section key={country}>
            <h2 className="display mb-3 text-xs font-bold uppercase tracking-wider text-muted">
              {country}
            </h2>
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
              {list.map((c) => (
                <Link key={c.id} href={competitionHref(c.id)} className="block">
                  <Card className="h-full px-4 py-4 transition-colors hover:border-ink">
                    <div className="flex items-start gap-3">
                      <Crest name={c.name} size={32} />
                      <div className="min-w-0">
                        <p className="truncate text-sm font-bold">{c.name}</p>
                        <p className="mt-0.5 text-xs text-muted">{c.span}</p>
                      </div>
                    </div>
                    <div className="mt-3 flex items-baseline gap-1.5 border-t border-line pt-3">
                      <span className="stat-figure text-xl">{c.seasons}</span>
                      <span className="text-xs text-muted">
                        {c.seasons === 1 ? "season" : "seasons"} ·{" "}
                        {c.matches.toLocaleString()} matches
                      </span>
                      {c.tier ? (
                        <span className="ml-auto rounded bg-wash px-1.5 py-0.5 text-[10px] font-semibold uppercase text-muted">
                          Tier {c.tier}
                        </span>
                      ) : null}
                    </div>
                  </Card>
                </Link>
              ))}
            </div>
          </section>
        ))}
      </div>
    </div>
  );
}
