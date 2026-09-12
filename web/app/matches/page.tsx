import Link from "next/link";
import { api, ApiError } from "@/lib/api";
import { ChipRow, Empty, PageTitle } from "@/components/ui";
import { ScopeSelect } from "@/components/scope-select";
import { resolveScope, seasonOptionsFor } from "@/lib/scope";
import { MatchDays, MatchStages } from "@/components/match-list";

export const dynamic = "force-dynamic";

const PAGE_SIZE = 25;
// A tournament is shown whole rather than paged: the largest here is 52
// matches, and splitting a bracket across pages makes it unreadable.
const TOURNAMENT_PAGE = 100;
const STATUSES = [
  { value: undefined, label: "Any" },
  { value: "FULL_TIME", label: "Finished" },
  { value: "SCHEDULED", label: "Scheduled" },
  { value: "POSTPONED", label: "Postponed" },
];

export default async function MatchesPage(props: PageProps<"/matches">) {
  const sp = await props.searchParams;
  const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);
  const seasonParam = one(sp.editionId);
  const status = one(sp.status);
  const offset = Math.max(0, Number(one(sp.offset) ?? 0) || 0);

  let data: Awaited<ReturnType<typeof api.matches>>;
  let editions: Awaited<ReturnType<typeof api.editions>>["editions"];
  let scope: Awaited<ReturnType<typeof resolveScope>>;
  let editionId: string | undefined;
  try {
    // Editions first, because whether this is a tournament decides how the
    // matches are asked for: a cup is read as a whole, in playing order.
    editions = await api.editions().then((r) => r.editions);
    scope = await resolveScope(one(sp.competitionId), seasonParam, editions);
    editionId = scope.editionId === undefined ? undefined : String(scope.editionId);
    const selected = editions.find((e) => String(e.editionId) === editionId);
    const tournament = Boolean(selected && selected.competitionType !== "LEAGUE");
    data = await api.matches({
      editionId,
      competitionId: scope.competitionId,
      status,
      limit: tournament ? TOURNAMENT_PAGE : PAGE_SIZE,
      offset: tournament ? 0 : offset,
      ...(tournament ? { order: "asc" } : {}),
    });
  } catch (err) {
    if (err instanceof ApiError) return <Empty>{err.message}</Empty>;
    throw err;
  }

  const href = (patch: Record<string, string | number | undefined>) => {
    const q = new URLSearchParams();
    for (const [k, v] of Object.entries({
      competitionId: String(scope.competitionId), editionId, status, offset, ...patch,
    })) {
      if (v !== undefined && v !== "" && !(k === "offset" && Number(v) === 0)) q.set(k, String(v));
    }
    const s = q.toString();
    return s ? `/matches?${s}` : "/matches";
  };

  const active = editions.find((e) => String(e.editionId) === editionId);
  // A cup is read by stage — which group, then how far a side got — so when one
  // tournament is selected the list groups by stage instead of by date. Across
  // all seasons, or for a league, the date is still the axis that makes sense.
  const byStage = Boolean(active && active.competitionType !== "LEAGUE");

  return (
    <div>
      <PageTitle
        title="All matches"
        sub={`${data.total.toLocaleString()} results${active ? ` · ${active.competition} ${active.season}` : ""} · newest first`}
        right={
          <ScopeSelect
            competitions={scope.competitions}
            competitionId={scope.competitionId}
            seasons={seasonOptionsFor(scope)}
            value={scope.value}
            allowAllTime
            clears={["offset"]}
          />
        }
      />

      <p className="mb-5 text-sm text-muted">
        The full archive, across every published season.{" "}
        <Link href="/" className="font-medium text-brand hover:text-brand-dark">
          Browse by date or round
        </Link>{" "}
        for what is on now.
      </p>

      <div className="mb-5 space-y-2.5">
        <ChipRow
          label="Status"
          options={STATUSES}
          activeValue={status}
          hrefFor={(v) => href({ status: v, offset: 0 })}
        />
      </div>

      {data.matches.length === 0 ? (
        <Empty>No matches match these filters.</Empty>
      ) : (
        byStage ? (
          <MatchStages matches={data.matches} showCompetition={false} />
        ) : (
          <MatchDays matches={data.matches} showCompetition />
        )
      )}

      <div className="mt-6 flex items-center justify-between text-sm">
        <span className="text-xs text-muted">
          {data.total === 0
            ? "0"
            : `${offset + 1}–${Math.min(offset + PAGE_SIZE, data.total)} of ${data.total.toLocaleString()}`}
        </span>
        <span className="flex gap-2">
          {offset > 0 ? (
            <Link href={href({ offset: Math.max(0, offset - PAGE_SIZE) })} className="rounded-full border border-line bg-paper px-4 py-1.5 text-xs font-semibold hover:border-ink">
              Previous
            </Link>
          ) : null}
          {offset + PAGE_SIZE < data.total ? (
            <Link href={href({ offset: offset + PAGE_SIZE })} className="rounded-full border border-line bg-paper px-4 py-1.5 text-xs font-semibold hover:border-ink">
              Next
            </Link>
          ) : null}
        </span>
      </div>
    </div>
  );
}
