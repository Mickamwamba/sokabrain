import { api, ApiError, type Edition, type PlayerStat, type TeamRefLite } from "@/lib/api";
import { Card, ChipRow, Crest, DataNote, Empty, PageTitle, Rank } from "@/components/ui";

export const dynamic = "force-dynamic";

const SORTS = [
  { value: undefined, label: "Goals" },
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
  let editions: Edition[];
  let teams: TeamRefLite[];
  try {
    [players, editions, teams] = await Promise.all([
      api.players({ sort, position, editionId, teamId, limit: 50 }).then((r) => r.players),
      api.editions().then((r) => r.editions),
      api.teams().then((r) => r.teams),
    ]);
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
  const sortLabel = SORTS.find((s) => s.value === sort)?.label ?? "Goals";

  return (
    <div>
      <PageTitle
        title="Players"
        sub={`Ranked by ${sortLabel.toLowerCase()}${activeEdition ? ` · ${activeEdition.competition} ${activeEdition.season}` : ""}${activeTeam ? ` · ${activeTeam.name}` : ""}`}
      />

      <div className="mb-5 space-y-2.5">
        <ChipRow label="Rank by" options={SORTS} activeValue={sort} hrefFor={(v) => href({ sort: v })} />
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
                      {p.appearances > 0 ? p.appearances : "—"}
                    </td>
                    <td className="px-2 py-2.5 text-right nums text-muted">{p.yellowCards}</td>
                    <td className="py-2.5 pl-2 pr-5 text-right nums text-muted">{p.redCards}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      )}

      <div className="mt-4">
        <DataNote>
          Goals come from the recorded event log, which does not name a scorer for every
          goal — treat these totals as a minimum. Appearances are shown only where a team
          sheet survives, so they are missing for many players and are not comparable
          between them. Own goals are never credited to the scorer.
        </DataNote>
      </div>
    </div>
  );
}
