import Link from "next/link";
import { api, ApiError, type ClubStat, type Edition } from "@/lib/api";
import { Card, ChipRow, Crest, DataNote, Empty, Rank, StatTile } from "@/components/ui";

export const dynamic = "force-dynamic";

type SortKey = "points" | "goalsFor" | "cleanSheets" | "winRate";

const SORTS: { value: string | undefined; label: string; key: SortKey }[] = [
  { value: undefined, label: "Points", key: "points" },
  { value: "goalsFor", label: "Goals scored", key: "goalsFor" },
  { value: "cleanSheets", label: "Clean sheets", key: "cleanSheets" },
  { value: "winRate", label: "Win %", key: "winRate" },
];

export default async function ClubsPage(props: PageProps<"/stats/clubs">) {
  const sp = await props.searchParams;
  const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);
  const sort = one(sp.sort);
  const editionId = one(sp.editionId);

  let clubs: ClubStat[];
  let editions: Edition[];
  try {
    [clubs, editions] = await Promise.all([
      api.clubs(editionId).then((r) => r.clubs),
      api.editions().then((r) => r.editions),
    ]);
  } catch (err) {
    if (err instanceof ApiError) return <Empty>{err.message}</Empty>;
    throw err;
  }

  const key: SortKey = SORTS.find((s) => s.value === sort)?.key ?? "points";
  // Sorting client-side: the whole club list is small enough that a round trip
  // per sort would be wasted work.
  const sorted = [...clubs].sort((a, b) => b[key] - a[key] || b.points - a.points);

  const href = (patch: Record<string, string | undefined>) => {
    const q = new URLSearchParams();
    for (const [k, v] of Object.entries({ sort, editionId, ...patch })) {
      if (v !== undefined && v !== "") q.set(k, v);
    }
    const s = q.toString();
    return s ? `/clubs?${s}` : "/stats/clubs";
  };

  const activeEdition = editions.find((e) => String(e.editionId) === editionId);
  const leader = sorted[0];
  const mostGoals = [...clubs].sort((a, b) => b.goalsFor - a.goalsFor)[0];
  const bestDefence = [...clubs].sort((a, b) => b.cleanSheets - a.cleanSheets)[0];

  return (
    <div>
      <p className="mb-4 text-sm text-muted">
        {activeEdition
          ? `${activeEdition.competition} ${activeEdition.season}`
          : "Combined across every published competition"}
      </p>

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
        <ChipRow
          label="Season"
          options={[
            { value: undefined, label: "All time" },
            ...editions
              .filter((e) => e.matchCount >= 19)
              .slice(0, 6)
              .map((e) => ({ value: String(e.editionId), label: `${e.competition} ${e.season.slice(0, 4)}` })),
          ]}
          activeValue={editionId}
          hrefFor={(v) => href({ editionId: v })}
        />
      </div>

      {sorted.length === 0 ? (
        <Empty>No clubs to show for this selection.</Empty>
      ) : (
        <Card className="overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full min-w-[680px] border-collapse text-sm">
              <thead>
                <tr className="border-b border-line bg-wash text-left text-[11px] font-semibold uppercase tracking-wide text-muted">
                  <th className="py-2.5 pl-5 pr-2">#</th>
                  <th className="px-2 py-2.5">Club</th>
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
                        href={`/head-to-head?teamA=${c.teamId}`}
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
          source data have none, so clubs can show different numbers of games played.
          Clean sheets are counted from the final score, not from the event log.
        </DataNote>
      </div>
    </div>
  );
}
