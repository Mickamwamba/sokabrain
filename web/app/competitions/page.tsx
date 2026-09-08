import Link from "next/link";
import { api, ApiError, type Edition } from "@/lib/api";
import { Card, Crest, Empty, PageTitle } from "@/components/ui";

export const dynamic = "force-dynamic";

function groupByCountry(editions: Edition[]) {
  const groups = new Map<string, Edition[]>();
  for (const e of editions) {
    const key = e.country ?? "Continental & international";
    const list = groups.get(key);
    if (list) list.push(e);
    else groups.set(key, [e]);
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

  return (
    <div>
      <PageTitle
        title="Competitions"
        sub={`${editions.length} published editions · ${editions
          .reduce((n, e) => n + e.matchCount, 0)
          .toLocaleString()} matches`}
      />

      <div className="space-y-7">
        {groupByCountry(editions).map(([country, list]) => (
          <section key={country}>
            <h2 className="display mb-3 text-xs font-bold uppercase tracking-wider text-muted">
              {country}
            </h2>
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
              {list.map((e) => (
                <Link key={e.editionId} href={`/table?editionId=${e.editionId}`} className="block">
                  <Card className="h-full px-4 py-4 transition-colors hover:border-ink">
                    <div className="flex items-start gap-3">
                      <Crest name={e.competition} size={32} />
                      <div className="min-w-0">
                        <p className="truncate text-sm font-bold">{e.competition}</p>
                        <p className="mt-0.5 text-xs text-muted">{e.season}</p>
                      </div>
                    </div>
                    <div className="mt-3 flex items-baseline gap-1.5 border-t border-line pt-3">
                      <span className="stat-figure text-xl">{e.matchCount}</span>
                      <span className="text-xs text-muted">matches</span>
                      {e.tier ? (
                        <span className="ml-auto rounded bg-wash px-1.5 py-0.5 text-[10px] font-semibold uppercase text-muted">
                          Tier {e.tier}
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
