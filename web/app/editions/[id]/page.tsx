import Link from "next/link";
import { notFound } from "next/navigation";
import { api, ApiError } from "@/lib/api";
import { Card, CardHead, Crest, DataNote, Empty, PageTitle, Rank } from "@/components/ui";

export const dynamic = "force-dynamic";

const KIND: Record<string, string> = {
  DOMESTIC_CUP: "a knockout cup",
  SUPER_CUP: "a one-off super cup",
  CONTINENTAL_CLUB: "a continental club competition",
  CONTINENTAL_NATIONAL: "a continental national-team tournament",
  WORLD_CUP: "a World Cup tournament",
  QUALIFIER: "a qualifying campaign",
  FRIENDLY: "a set of friendlies",
};

export default async function EditionPage(props: PageProps<"/editions/[id]">) {
  const { id } = await props.params;
  const editionId = Number(id);
  if (!Number.isInteger(editionId) || editionId <= 0) notFound();

  let standings: Awaited<ReturnType<typeof api.standings>>;
  let scorers: Awaited<ReturnType<typeof api.topScorers>>;
  try {
    [standings, scorers] = await Promise.all([
      api.standings(editionId),
      api.topScorers(editionId, 12),
    ]);
  } catch (err) {
    if (err instanceof ApiError && err.status === 404) notFound();
    if (err instanceof ApiError) return <Empty>{err.message}</Empty>;
    throw err;
  }

  const { edition, coverage, isLeagueTable } = standings;
  const table = standings.standings;
  const champion = isLeagueTable ? table[0] : undefined;

  return (
    <div>
      <PageTitle title={edition.competition} sub={edition.season} />

      <div className="mb-5 flex flex-wrap gap-2 text-sm">
        <Link
          href={`/matches?editionId=${editionId}`}
          className="rounded-full border border-line bg-paper px-4 py-1.5 font-medium hover:border-ink"
        >
          All matches
        </Link>
        <Link
          href={`/clubs?editionId=${editionId}`}
          className="rounded-full border border-line bg-paper px-4 py-1.5 font-medium hover:border-ink"
        >
          Club stats
        </Link>
        <Link
          href={`/players?editionId=${editionId}`}
          className="rounded-full border border-line bg-paper px-4 py-1.5 font-medium hover:border-ink"
        >
          Player stats
        </Link>
      </div>

      {champion ? (
        <Card className="mb-5 flex items-center gap-4 bg-ink px-6 py-5 text-white">
          <Crest name={champion.teamName} size={44} />
          <div className="min-w-0">
            <p className="text-[11px] font-semibold uppercase tracking-wider text-white/50">
              Top of the table
            </p>
            <p className="display truncate text-xl font-extrabold">{champion.teamName}</p>
          </div>
          <div className="ml-auto shrink-0 text-right">
            <p className="stat-figure text-3xl">{champion.points}</p>
            <p className="text-[11px] font-semibold uppercase tracking-wider text-white/50">
              Points
            </p>
          </div>
        </Card>
      ) : null}

      <div className="grid gap-5 lg:grid-cols-[1.6fr_1fr]">
        <Card className="overflow-hidden">
          <CardHead title={isLeagueTable ? "Table" : "Results summary"} />
          {table.length === 0 ? (
            <p className="px-5 py-10 text-center text-sm text-muted">
              No completed matches with a score yet.
            </p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full min-w-[520px] border-collapse text-sm">
                <thead>
                  <tr className="border-b border-line bg-wash text-left text-[11px] font-semibold uppercase tracking-wide text-muted">
                    <th className="py-2.5 pl-5 pr-2">#</th>
                    <th className="px-2 py-2.5">Team</th>
                    {["P", "W", "D", "L", "GF", "GA", "GD"].map((h) => (
                      <th key={h} className="px-2 py-2.5 text-right">{h}</th>
                    ))}
                    <th className="py-2.5 pl-2 pr-5 text-right">Pts</th>
                  </tr>
                </thead>
                <tbody>
                  {table.map((r) => (
                    <tr key={r.teamId} className="border-b border-line last:border-0 hover:bg-wash">
                      <td className="py-2.5 pl-5 pr-2"><Rank n={r.position} /></td>
                      <td className="px-2 py-2.5">
                        <span className="flex items-center gap-2 font-semibold">
                          <Crest name={r.teamName} size={22} />
                          <span className="truncate">{r.teamName}</span>
                        </span>
                      </td>
                      {[r.played, r.won, r.drawn, r.lost, r.goalsFor, r.goalsAgainst].map((v, i) => (
                        <td key={i} className="px-2 py-2.5 text-right nums text-muted">{v}</td>
                      ))}
                      <td className="px-2 py-2.5 text-right nums text-muted">
                        {r.goalDifference > 0 ? `+${r.goalDifference}` : r.goalDifference}
                      </td>
                      <td className="stat-figure py-2.5 pl-2 pr-5 text-right text-base">{r.points}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Card>

        <Card className="overflow-hidden self-start">
          <CardHead
            title="Top scorers"
            action={{ href: `/players?editionId=${editionId}`, label: "Full list" }}
          />
          {scorers.scorers.length === 0 ? (
            <p className="px-5 py-10 text-center text-sm text-muted">
              No goalscorer data recorded.
            </p>
          ) : (
            <ol>
              {scorers.scorers.map((s) => (
                <li
                  key={s.playerId}
                  className="flex items-center gap-3 border-b border-line px-5 py-2.5 last:border-0"
                >
                  <Rank n={s.rank} />
                  <span className="min-w-0 flex-1">
                    <span className="block truncate text-sm font-semibold">{s.playerName}</span>
                    <span className="block truncate text-xs text-muted">{s.teamName ?? "—"}</span>
                  </span>
                  <span className="stat-figure text-lg">{s.goals}</span>
                </li>
              ))}
            </ol>
          )}
        </Card>
      </div>

      <div className="mt-5 space-y-2">
        {!isLeagueTable ? (
          <DataNote>
            {`This is ${KIND[edition.competitionType] ?? "not a league"}, not a round-robin league — the standings above summarise results across the edition but are not an official table.`}
          </DataNote>
        ) : null}
        {coverage.matchesMissingScore > 0 ? (
          <DataNote>
            Built from {coverage.matchesCounted} of {coverage.matchesFullTime} completed
            matches. {coverage.matchesMissingScore}{" "}
            {coverage.matchesMissingScore === 1 ? "match has" : "matches have"} no score in
            the source data, so teams show different numbers of games played.
          </DataNote>
        ) : null}
        {scorers.coverage.unattributedGoals > 0 ? (
          <DataNote>
            {scorers.coverage.attributedGoals} goals have a named scorer;{" "}
            {scorers.coverage.unattributedGoals} do not. Treat the scoring chart as a
            minimum rather than a final record.
          </DataNote>
        ) : null}
      </div>
    </div>
  );
}
