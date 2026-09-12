import Link from "next/link";
import { api, ApiError, type ClubStat, type Edition, type TeamType } from "@/lib/api";
import { Card, ChipRow, Crest, DataNote, Empty, Rank, StatTile } from "@/components/ui";
import { resolveScope, seasonOptionsFor, type ResolvedScope } from "@/lib/scope";
import { AllTimeBadge, ScopeSelect } from "@/components/scope-select";

type SortKey = "points" | "goalsFor" | "cleanSheets" | "winRate";

const SORTS: { value: string | undefined; label: string; key: SortKey }[] = [
  { value: undefined, label: "Points", key: "points" },
  { value: "goalsFor", label: "Goals scored", key: "goalsFor" },
  { value: "cleanSheets", label: "Clean sheets", key: "cleanSheets" },
  { value: "winRate", label: "Win %", key: "winRate" },
];

/**
 * The team leaderboard, for clubs or for national teams.
 *
 * The two are ranked separately because they are not comparable: a club plays a
 * 30-match league season, a nation three group matches every other year, and a
 * single table of both would rank Simba against Egypt on games neither could
 * have played. `teams.type` already draws the line, so the page just asks for
 * one side of it.
 */
export async function TeamStatsPage({
  searchParams,
  teamType,
  basePath,
  noun,
  nounPlural,
  only,
}: {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
  teamType: TeamType;
  /** Restricts the competition picker to ones this kind of team plays in. */
  only?: (e: Edition) => boolean;
  basePath: string;
  /** Column heading, e.g. "Club" or "Nation". */
  noun: string;
  nounPlural: string;
}) {
  const sp = await searchParams;
  const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);
  const sort = one(sp.sort);

  let scope: ResolvedScope;
  let clubs: ClubStat[];
  try {
    scope = await resolveScope(one(sp.competitionId), one(sp.editionId), undefined, only);
    clubs = await api
      .clubs({ competitionId: scope.competitionId, editionId: scope.editionId, type: teamType })
      .then((r) => r.clubs);
  } catch (err) {
    if (err instanceof ApiError) return <Empty>{err.message}</Empty>;
    throw err;
  }
  const editionId = scope.editionId === undefined ? undefined : String(scope.editionId);

  const key: SortKey = SORTS.find((s) => s.value === sort)?.key ?? "points";
  // Sorting client-side: the whole club list is small enough that a round trip
  // per sort would be wasted work.
  const sorted = [...clubs].sort((a, b) => b[key] - a[key] || b.points - a.points);

  const href = (patch: Record<string, string | undefined>) => {
    const q = new URLSearchParams();
    for (const [k, v] of Object.entries({
      sort,
      competitionId: String(scope.competitionId),
      editionId: scope.value,
      ...patch,
    })) {
      if (v !== undefined && v !== "") q.set(k, v);
    }
    const s = q.toString();
    return s ? `${basePath}?${s}` : basePath;
  };

  const activeEdition = scope.editions.find((e) => String(e.editionId) === editionId);
  const leader = sorted[0];
  const mostGoals = [...clubs].sort((a, b) => b.goalsFor - a.goalsFor)[0];
  const bestDefence = [...clubs].sort((a, b) => b.cleanSheets - a.cleanSheets)[0];

  return (
    <div>
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <p className="text-sm text-muted">
          {activeEdition
            ? `${activeEdition.competition} ${activeEdition.season}`
            : `${scope.competitionName} — every published season`}
        </p>
        <ScopeSelect
          competitions={scope.competitions}
          competitionId={scope.competitionId}
          seasons={seasonOptionsFor(scope)}
          value={scope.value}
          allowAllTime
        />
      </div>
      {scope.allTime ? (
        <div className="mb-4"><AllTimeBadge competition={scope.competitionName} /></div>
      ) : null}

      {leader && mostGoals && bestDefence ? (
        <div className="mb-5 grid gap-3 sm:grid-cols-3">
          <StatTile figure={leader.points} label="Most points" sub={leader.teamName} />
          <StatTile figure={mostGoals.goalsFor} label="Most goals" sub={mostGoals.teamName} />
          <StatTile
            figure={bestDefence.cleanSheets}
            label="Most clean sheets"
            sub={bestDefence.teamName}
          />
        </div>
      ) : null}

      <div className="mb-5 space-y-2.5">
        <ChipRow label="Rank by" options={SORTS} activeValue={sort} hrefFor={(v) => href({ sort: v })} />
      </div>

      {sorted.length === 0 ? (
        <Empty>No {nounPlural.toLowerCase()} to show for this selection.</Empty>
      ) : (
        <Card className="overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full min-w-[680px] border-collapse text-sm">
              <thead>
                <tr className="border-b border-line bg-wash text-left text-[11px] font-semibold uppercase tracking-wide text-muted">
                  <th className="py-2.5 pl-5 pr-2">#</th>
                  <th className="px-2 py-2.5">{noun}</th>
                  {["P", "W", "D", "L", "GF", "GA", "GD", "CS", "Win %"].map((h) => (
                    <th key={h} className="px-2 py-2.5 text-right">{h}</th>
                  ))}
                  <th className="py-2.5 pl-2 pr-5 text-right">Pts</th>
                </tr>
              </thead>
              <tbody>
                {sorted.map((c, i) => (
                  <tr key={c.teamId} className="border-b border-line last:border-0 hover:bg-wash">
                    <td className="py-2.5 pl-5 pr-2"><Rank n={i + 1} /></td>
                    <td className="px-2 py-2.5">
                      <Link
                        href={`/stats/head-to-head?teamA=${c.teamId}`}
                        className="flex items-center gap-2 font-semibold hover:text-brand"
                      >
                        <Crest name={c.teamName} size={22} />
                        <span className="truncate">{c.teamName}</span>
                      </Link>
                    </td>
                    {[c.played, c.won, c.drawn, c.lost, c.goalsFor, c.goalsAgainst].map((v, j) => (
                      <td key={j} className="px-2 py-2.5 text-right nums text-muted">{v}</td>
                    ))}
                    <td className="px-2 py-2.5 text-right nums text-muted">
                      {c.goalDifference > 0 ? `+${c.goalDifference}` : c.goalDifference}
                    </td>
                    <td className="px-2 py-2.5 text-right nums text-muted">{c.cleanSheets}</td>
                    <td className="px-2 py-2.5 text-right nums text-muted">{c.winRate}%</td>
                    <td className="stat-figure py-2.5 pl-2 pr-5 text-right text-base">{c.points}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      )}

      <div className="mt-4">
        <DataNote>
          Built from completed matches that have a recorded score. Some matches in the
          source data have none, so {nounPlural.toLowerCase()} can show different numbers
          of games played. Clean sheets are counted from the final score, not from the
          event log.
        </DataNote>
      </div>
    </div>
  );
}
