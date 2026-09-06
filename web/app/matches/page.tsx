import Link from "next/link";
import { api, ApiError, type Match } from "@/lib/api";
import { Badge, Empty, TeamCrest } from "@/components/ui";

export const dynamic = "force-dynamic";

const PAGE_SIZE = 25;

const STATUSES = ["FULL_TIME", "SCHEDULED", "POSTPONED", "ABANDONED", "CANCELLED"] as const;

function formatKickoff(iso: string | null) {
  if (!iso) return "Date unknown";
  return new Date(iso).toLocaleDateString("en-GB", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  });
}

/** Score, or a dash when the match has no recorded result. */
function Score({ match }: { match: Match }) {
  const { home, away, homePenalties, awayPenalties } = match.score;
  if (home === null || away === null) {
    return <span className="font-mono text-sm text-muted">–</span>;
  }
  return (
    <span className="whitespace-nowrap font-mono text-sm font-semibold tabular-nums">
      {home}–{away}
      {homePenalties !== null && awayPenalties !== null ? (
        <span className="ml-1 text-xs font-normal text-muted">
          ({homePenalties}–{awayPenalties} pens)
        </span>
      ) : null}
    </span>
  );
}

export default async function MatchesPage(props: PageProps<"/matches">) {
  // Next 16: searchParams is a Promise and must be awaited.
  const sp = await props.searchParams;
  const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);

  const editionId = one(sp.editionId);
  const status = one(sp.status);
  const offset = Math.max(0, Number(one(sp.offset) ?? 0) || 0);

  let data: Awaited<ReturnType<typeof api.matches>>;
  let editions: Awaited<ReturnType<typeof api.editions>>["editions"];
  try {
    [data, editions] = await Promise.all([
      api.matches({ editionId, status, limit: PAGE_SIZE, offset }),
      api.editions().then((r) => r.editions),
    ]);
  } catch (err) {
    if (err instanceof ApiError) return <Empty>{err.message}</Empty>;
    throw err;
  }

  const buildHref = (patch: Record<string, string | number | undefined>) => {
    const qs = new URLSearchParams();
    const merged = { editionId, status, offset, ...patch };
    for (const [k, v] of Object.entries(merged)) {
      if (v !== undefined && v !== "" && !(k === "offset" && Number(v) === 0)) {
        qs.set(k, String(v));
      }
    }
    const s = qs.toString();
    return s ? `/matches?${s}` : "/matches";
  };

  const activeEdition = editions.find((e) => String(e.editionId) === editionId);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">Matches</h1>
        <p className="mt-1 text-sm text-muted">
          {data.total.toLocaleString()} matches
          {activeEdition ? ` in ${activeEdition.competition} ${activeEdition.season}` : ""}
          {status ? ` · ${status.replaceAll("_", " ").toLowerCase()}` : ""}
        </p>
      </div>

      {/* Filters are plain links, so the page stays a server component and every
          filtered view is a shareable URL. */}
      <div className="space-y-2 text-xs">
        <div className="flex flex-wrap items-center gap-1.5">
          <span className="mr-1 text-muted">Competition</span>
          <Link
            href={buildHref({ editionId: undefined, offset: 0 })}
            className={`rounded border px-2 py-1 ${!editionId ? "border-accent text-accent" : "border-border text-muted hover:text-foreground"}`}
          >
            All
          </Link>
          {editions
            .filter((e) => e.matchCount >= 19)
            .map((e) => (
              <Link
                key={e.editionId}
                href={buildHref({ editionId: e.editionId, offset: 0 })}
                className={`rounded border px-2 py-1 ${
                  String(e.editionId) === editionId
                    ? "border-accent text-accent"
                    : "border-border text-muted hover:text-foreground"
                }`}
              >
                {e.competition} {e.season.slice(0, 4)}
              </Link>
            ))}
        </div>
        <div className="flex flex-wrap items-center gap-1.5">
          <span className="mr-1 text-muted">Status</span>
          <Link
            href={buildHref({ status: undefined, offset: 0 })}
            className={`rounded border px-2 py-1 ${!status ? "border-accent text-accent" : "border-border text-muted hover:text-foreground"}`}
          >
            Any
          </Link>
          {STATUSES.map((s) => (
            <Link
              key={s}
              href={buildHref({ status: s, offset: 0 })}
              className={`rounded border px-2 py-1 ${
                s === status ? "border-accent text-accent" : "border-border text-muted hover:text-foreground"
              }`}
            >
              {s.replaceAll("_", " ").toLowerCase()}
            </Link>
          ))}
        </div>
      </div>

      {data.matches.length === 0 ? (
        <Empty>No matches match these filters.</Empty>
      ) : (
        <ul className="divide-y divide-border rounded-lg border border-border">
          {data.matches.map((m) => (
            <li key={m.id} className="flex items-center gap-3 px-4 py-3 text-sm">
              <span className="w-24 shrink-0 text-xs text-muted">
                {formatKickoff(m.kickoffAt)}
              </span>
              <span className="flex min-w-0 flex-1 items-center justify-end gap-2">
                <span className="truncate">{m.homeTeam.name}</span>
                <TeamCrest name={m.homeTeam.name} size={18} />
              </span>
              <span className="w-20 shrink-0 text-center">
                <Score match={m} />
              </span>
              <span className="flex min-w-0 flex-1 items-center gap-2">
                <TeamCrest name={m.awayTeam.name} size={18} />
                <span className="truncate">{m.awayTeam.name}</span>
              </span>
              <span className="hidden w-28 shrink-0 justify-end sm:flex">
                {m.status !== "FULL_TIME" ? (
                  <Badge>{m.status.replaceAll("_", " ")}</Badge>
                ) : null}
              </span>
            </li>
          ))}
        </ul>
      )}

      <div className="flex items-center justify-between text-sm">
        <span className="text-xs text-muted">
          {data.total === 0
            ? "0"
            : `${offset + 1}–${Math.min(offset + PAGE_SIZE, data.total)} of ${data.total.toLocaleString()}`}
        </span>
        <span className="flex gap-2">
          {offset > 0 ? (
            <Link
              href={buildHref({ offset: Math.max(0, offset - PAGE_SIZE) })}
              className="rounded border border-border px-3 py-1.5 text-xs hover:border-accent"
            >
              Previous
            </Link>
          ) : null}
          {offset + PAGE_SIZE < data.total ? (
            <Link
              href={buildHref({ offset: offset + PAGE_SIZE })}
              className="rounded border border-border px-3 py-1.5 text-xs hover:border-accent"
            >
              Next
            </Link>
          ) : null}
        </span>
      </div>
    </div>
  );
}
