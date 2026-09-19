import {
  api,
  ApiError,
  type Edition,
  type PlayerStat,
  type PlayerStatsCoverage,
  type TeamRefLite,
} from "@/lib/api";
import { resolveScope, seasonOptionsFor } from "@/lib/scope";
import { AllTimeBadge, ScopeSelect } from "@/components/scope-select";
import { Card, ChipRow, Crest, Empty, Rank, TeamLink } from "@/components/ui";

export const dynamic = "force-dynamic";

const SORTS = [
  { value: undefined, label: "Goals" },
  { value: "assists", label: "Assists" },
  { value: "appearances", label: "Appearances" },
  { value: "yellowCards", label: "Yellow cards" },
  { value: "redCards", label: "Red cards" },
];

export default async function PlayersPage(props: PageProps<"/stats/players">) {
  const sp = await props.searchParams;
  const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);
  const sort = one(sp.sort);
  const teamId = one(sp.teamId);
  const scope = await resolveScope(one(sp.competitionId), one(sp.editionId));
  const editionId = scope.editionId === undefined ? undefined : String(scope.editionId);

  let players: PlayerStat[];
  let coverage: PlayerStatsCoverage;
  let editions: Edition[];
  let teams: TeamRefLite[];
  try {
    const [playerData, editionData, teamData] = await Promise.all([
      api.players({
        sort,
        editionId,
        teamId,
        limit: 50,
        competitionId: scope.competitionId,
      }),
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
    for (const [k, v] of Object.entries({
      sort,
      teamId,
      competitionId: String(scope.competitionId),
      editionId: scope.value,
      ...patch,
    })) {
      if (v !== undefined && v !== "") q.set(k, v);
    }
    const s = q.toString();
    return s ? `/stats/players?${s}` : "/stats/players";
  };

  const seasonChoices = seasonOptionsFor(scope);
  const activeTeam = teams.find((t) => String(t.id) === teamId);
  const activeEdition = editions.find((e) => String(e.editionId) === editionId);

  const availableSorts = SORTS.filter(
    (s) =>
      (s.value !== "assists" || coverage.assistsRecorded > 0) &&
      (s.value !== "appearances" || coverage.appearancesReliable) &&
      (s.value !== "yellowCards" || coverage.cardsReliable) &&
      (s.value !== "redCards" || coverage.cardsReliable),
  );
  const sortLabel = availableSorts.find((s) => s.value === sort)?.label ?? "Goals";

  return (
    <div>
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <div>
          <h2 className="display text-xl font-black text-ink">Player Leaderboard</h2>
          <p className="text-xs text-muted mt-0.5">
            Ranked by {sortLabel.toLowerCase()}
            {activeEdition ? ` · ${activeEdition.competition} ${activeEdition.season}` : ""}
            {activeTeam ? ` · ${activeTeam.name}` : ""}
          </p>
        </div>
        <div className="flex items-center gap-2">
          {scope.allTime ? <AllTimeBadge competition={scope.competitionName} /> : null}
          <ScopeSelect
            competitions={scope.competitions}
            competitionId={scope.competitionId}
            seasons={seasonChoices}
            value={scope.value}
            allowAllTime
          />
        </div>
      </div>

      <div className="mb-5">
        <ChipRow
          label="Rank by"
          options={availableSorts}
          activeValue={sort}
          hrefFor={(v) => href({ sort: v })}
        />
      </div>

      {players.length === 0 ? (
        <Empty>No players match these filters.</Empty>
      ) : (
        <Card className="overflow-hidden shadow-xs">
          <div className="overflow-x-auto">
            <table className="w-full min-w-[640px] border-collapse text-sm">
              <thead>
                <tr className="border-b border-line bg-wash/80 text-left text-[11px] font-bold uppercase tracking-wider text-muted">
                  <th className="py-3 pl-5 pr-2 w-10 text-center">#</th>
                  <th className="px-3 py-3">Player</th>
                  <th className="px-3 py-3">Club</th>
                  <th className="px-2 py-3 text-right">Goals</th>
                  <th className="px-2 py-3 text-right">Pens</th>
                  <th className="px-2 py-3 text-right">Ast</th>
                  <th className="px-2 py-3 text-right">Apps</th>
                  <th className="px-2 py-3 text-right">Yel</th>
                  <th className="py-3 pl-2 pr-5 text-right">Red</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-line/60">
                {players.map((p, i) => (
                  <tr key={p.playerId} className="hover:bg-wash/70 transition-colors">
                    <td className="py-3 pl-5 pr-2 text-center">
                      <Rank n={i + 1} />
                    </td>
                    <td className="px-3 py-3 font-bold text-ink">{p.playerName}</td>
                    <td className="px-3 py-3">
                      <TeamLink
                        id={p.teamName ? p.teamId : null}
                        name={p.teamName ?? "—"}
                        className="flex items-center gap-2 text-muted hover:text-brand transition-colors font-medium"
                      >
                        {p.teamName ? <Crest name={p.teamName} size={22} /> : null}
                        <span className="truncate">{p.teamName ?? "—"}</span>
                      </TeamLink>
                    </td>
                    <td className="stat-figure px-2 py-3 text-right text-base text-ink font-black">
                      {p.goals}
                    </td>
                    <td className="px-2 py-3 text-right nums text-muted">{p.penalties}</td>
                    <td className="px-2 py-3 text-right nums text-muted">{p.assists ?? "—"}</td>
                    <td className="px-2 py-3 text-right nums text-muted">
                      {p.appearances && p.appearances > 0 ? p.appearances : "—"}
                    </td>
                    <td className="px-2 py-3 text-right nums text-muted">{p.yellowCards ?? "—"}</td>
                    <td className="py-3 pl-2 pr-5 text-right nums text-muted">{p.redCards ?? "—"}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      )}

      <div className="mt-4">
        <p className="text-xs text-muted">
          Official goal and assist totals from verified match records. Own goals are not credited to individual scorers.
        </p>
      </div>
    </div>
  );
}
