import Link from "next/link";
import { api, ApiError, type Edition } from "@/lib/api";
import { Badge, Empty } from "@/components/ui";

export const dynamic = "force-dynamic";

function groupByCountry(editions: Edition[]) {
  const groups = new Map<string, Edition[]>();
  for (const e of editions) {
    // Continental and national-team competitions have no country of their own.
    const key = e.country ?? "International";
    const list = groups.get(key);
    if (list) list.push(e);
    else groups.set(key, [e]);
  }
  // Countries first (alphabetically), International last — it's the least
  // relevant grouping for a product whose wedge is domestic league depth.
  return [...groups.entries()].sort(([a], [b]) => {
    if (a === "International") return 1;
    if (b === "International") return -1;
    return a.localeCompare(b);
  });
}

export default async function HomePage() {
  let editions: Edition[];
  try {
    editions = (await api.editions()).editions;
  } catch (err) {
    if (err instanceof ApiError) {
      return (
        <Empty>
          <p className="font-medium text-foreground">Can’t reach the vault API.</p>
          <p className="mt-1">{err.message}</p>
          <p className="mt-3 font-mono text-xs">cd backend &amp;&amp; npm run dev</p>
        </Empty>
      );
    }
    throw err;
  }

  const withData = editions.filter((e) => e.matchCount > 0);

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">Competitions</h1>
        <p className="mt-1 text-sm text-muted">
          {withData.length} editions with match data, {" "}
          {withData.reduce((n, e) => n + e.matchCount, 0).toLocaleString()} matches in the vault.
        </p>
      </div>

      {withData.length === 0 ? (
        <Empty>No competition editions carry any matches yet.</Empty>
      ) : (
        groupByCountry(withData).map(([country, list]) => (
          <section key={country} className="space-y-3">
            <h2 className="text-sm font-semibold uppercase tracking-wide text-muted">
              {country}
            </h2>
            <ul className="grid gap-2 sm:grid-cols-2">
              {list.map((e) => (
                <li key={e.editionId}>
                  <Link
                    href={`/editions/${e.editionId}`}
                    className="flex items-center justify-between gap-3 rounded-lg border border-border px-4 py-3 transition-colors hover:border-accent"
                  >
                    <span className="min-w-0">
                      <span className="block truncate font-medium">{e.competition}</span>
                      <span className="mt-0.5 flex items-center gap-2 text-xs text-muted">
                        {e.season}
                        {e.tier ? <Badge>Tier {e.tier}</Badge> : null}
                        {e.competitionType !== "LEAGUE" ? (
                          <Badge>{e.competitionType.replaceAll("_", " ")}</Badge>
                        ) : null}
                      </span>
                    </span>
                    <span className="shrink-0 text-right text-xs text-muted">
                      {e.matchCount}
                      <span className="block">matches</span>
                    </span>
                  </Link>
                </li>
              ))}
            </ul>
          </section>
        ))
      )}
    </div>
  );
}
