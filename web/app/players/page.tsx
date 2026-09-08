import {
  api,
  ApiError,
  type Edition,
  type PlayerStat,
  type PlayerStatsCoverage,
  type TeamRefLite,
} from "@/lib/api";
import { Card, ChipRow, Crest, DataNote, Empty, PageTitle, Rank } from "@/components/ui";

export const dynamic = "force-dynamic";

const SORTS = [
  { value: undefined, label: "Goals" },
  { value: "assists", label: "Assists" },
  { value: "appearances", label: "Appearances" },
  { value: "yellowCards", label: "Yellow cards" },
  { value: "redCards", label: "Red cards" },
];
const POSITIONS = [
  { value: undefined, label: "All" },
  { value: "GK", label: "Goalkeepers" },
  { value: "DF", label: "Defenders" },
  { value: "MF", label: "Midfielders" },
  { value: "FW", label: "Forwards" },
];

export default async function PlayersPage(props: PageProps<"/players">) {
  const sp = await props.searchParams;
  const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);
  const sort = one(sp.sort);
  const position = one(sp.position);
  const editionId = one(sp.editionId);
  const teamId = one(sp.teamId);

  let players: PlayerStat[];
  let coverage: PlayerStatsCoverage;
  let editions: Edition[];
  let teams: TeamRefLite[];
  try {
    const [playerData, editionData, teamData] = await Promise.all([
      api.players({ sort, position, editionId, teamId, limit: 50 }),
      api.editions(),
      api.teams(),
    ]);
    players = playerData.players;
    coverage = playerData.coverage;
    editions = editionData.editions;
    teams = teamData.teams;
  } catch (err) {
    if (err instanceof ApiError) return <Empty>{err.message}</Empty>;
    throw err;
  }

  const href = (patch: Record<string, string | undefined>) => {
    const q = new URLSearchParams();
    for (const [k, v] of Object.entries({ sort, position, editionId, teamId, ...patch })) {
      if (v !== undefined && v !== "") q.set(k, v);
    }
    const s = q.toString();
    return s ? `/players?${s}` : "/players";
  };

  const activeTeam = teams.find((t) => String(t.id) === teamId);
  const activeEdition = editions.find((e) => String(e.editionId) === editionId);
  // Offering "sort by appearances" while appearances are suppressed would rank
  // the table on numbers the page declines to print.
  const availableSorts = SORTS.filter(
    (s) =>
      (s.value !== "assists" || coverage.assistsRecorded > 0) &&
      (s.value !== "appearances" || coverage.appearancesReliable) &&
      (s.value !== "yellowCards" || coverage.cardsReliable) &&
      (s.value !== "redCards" || coverage.cardsReliable),
  );
  const sortLabel = availableSorts.find((s) => s.value === sort)?.label ?? "Goals";

  const pct = (n: number) => Math.round(n * 100);
  const goalsAreAFloor = coverage.goalAttributionRate < 0.995;

  return (
    <div>
      <PageTitle
        title="Players"
        sub={`Ranked by ${sortLabel.toLowerCase()}${activeEdition ? ` · ${activeEdition.competition} ${activeEdition.season}` : ""}${activeTeam ? ` · ${activeTeam.name}` : ""}`}
      />

      <div className="mb-5 space-y-2.5">
        <ChipRow
          label="Rank by"
          options={availableSorts}
          activeValue={sort}
          hrefFor={(v) => href({ sort: v })}
        />
        <ChipRow label="Position" options={POSITIONS} activeValue={position} hrefFor={(v) => href({ position: v })} />
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

      {players.length === 0 ? (
        <Empty>No players match these filters.</Empty>
      ) : (
        <Card className="overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full min-w-[640px] border-collapse text-sm">
              <thead>
                <tr className="border-b border-line bg-wash text-left text-[11px] font-semibold uppercase tracking-wide text-muted">
                  <th className="py-2.5 pl-5 pr-2">#</th>
                  <th className="px-2 py-2.5">Player</th>
                  <th className="px-2 py-2.5">Club</th>
                  <th className="px-2 py-2.5 text-center">Pos</th>
                  <th className="px-2 py-2.5 text-right">Goals</th>
                  <th className="px-2 py-2.5 text-right">Pens</th>
                  <th className="px-2 py-2.5 text-right">Ast</th>
                  <th className="px-2 py-2.5 text-right">Apps</th>
                  <th className="px-2 py-2.5 text-right">Yel</th>
                  <th className="py-2.5 pl-2 pr-5 text-right">Red</th>
                </tr>
              </thead>
              <tbody>
                {players.map((p, i) => (
                  <tr key={p.playerId} className="border-b border-line last:border-0 hover:bg-wash">
                    <td className="py-2.5 pl-5 pr-2"><Rank n={i + 1} /></td>
                    <td className="px-2 py-2.5 font-semibold">{p.playerName}</td>
                    <td className="px-2 py-2.5">
                      <span className="flex items-center gap-2 text-muted">
                        {p.teamName ? <Crest name={p.teamName} size={20} /> : null}
                        <span className="truncate">{p.teamName ?? "—"}</span>
                      </span>
                    </td>
                    <td className="px-2 py-2.5 text-center text-xs text-muted">{p.position ?? "—"}</td>
                    <td className="stat-figure px-2 py-2.5 text-right text-base">{p.goals}</td>
                    <td className="px-2 py-2.5 text-right nums text-muted">{p.penalties}</td>
                    <td className="px-2 py-2.5 text-right nums text-muted">
                      {p.assists ?? "—"}
                    </td>
                    <td className="px-2 py-2.5 text-right nums text-muted">
                      {p.appearances && p.appearances > 0 ? p.appearances : "—"}
                    </td>
                    <td className="px-2 py-2.5 text-right nums text-muted">
                      {p.yellowCards ?? "—"}
                    </td>
                    <td className="py-2.5 pl-2 pr-5 text-right nums text-muted">
                      {p.redCards ?? "—"}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      )}

      <div className="mt-4">
        <DataNote>
          {goalsAreAFloor ? (
            <>
              These are <strong>minimum</strong> totals, not career totals. A scorer is
              recorded for {pct(coverage.goalAttributionRate)}% of the{" "}
              {coverage.goalsInScope.toLocaleString()} goals in view —{" "}
              {coverage.seasonsWithScorers} of {coverage.seasonsInScope} seasons name
              scorers at all, so goals from the other seasons are credited to nobody and a
              player who scored in them will look worse than they were.{" "}
            </>
          ) : (
            <>A scorer is recorded for every goal in view. </>
          )}
          {coverage.assistsRecorded > 0 ? (
            <>
              Assists are recorded from {coverage.seasonsWithAssists} of{" "}
              {coverage.seasonsInScope} seasons in view — the source only began naming
              them in 2023/24 — and the record does not say which goal each one created. A player who never
              featured in one of those seasons shows “—”, not zero.{" "}
            </>
          ) : (
            <>No season in view has assists recorded, so that column reads “—”. </>
          )}
          {!coverage.appearancesReliable && (
            <>
              Appearances and cards are shown as “—” rather than as numbers: a team sheet
              survives for only {coverage.matchesWithLineups.toLocaleString()} of{" "}
              {coverage.matchesInScope.toLocaleString()} matches here, so any count would
              measure what was written down rather than who played.{" "}
            </>
          )}
          Own goals are never credited to the scorer.
        </DataNote>
      </div>
    </div>
  );
}
