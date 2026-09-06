import Link from "next/link";
import { notFound } from "next/navigation";
import { api, ApiError } from "@/lib/api";
import { Badge, BackLink, CoverageNote, Empty, TeamCrest } from "@/components/ui";

export const dynamic = "force-dynamic";

/** Readable labels; the raw enum values make for awkward prose. */
const COMPETITION_KIND: Record<string, string> = {
  DOMESTIC_CUP: "a knockout cup",
  SUPER_CUP: "a one-off super cup",
  CONTINENTAL_CLUB: "a continental club competition",
  CONTINENTAL_NATIONAL: "a continental national-team tournament",
  WORLD_CUP: "a World Cup tournament",
  QUALIFIER: "a qualifying campaign",
  FRIENDLY: "a set of friendlies",
};

export default async function EditionPage(props: PageProps<"/editions/[id]">) {
  // Next 16: params is a Promise and must be awaited.
  const { id } = await props.params;
  const editionId = Number(id);
  if (!Number.isInteger(editionId) || editionId <= 0) notFound();

  let standings: Awaited<ReturnType<typeof api.standings>>;
  let scorers: Awaited<ReturnType<typeof api.topScorers>>;
  try {
    [standings, scorers] = await Promise.all([
      api.standings(editionId),
      api.topScorers(editionId, 15),
    ]);
  } catch (err) {
    if (err instanceof ApiError && err.status === 404) notFound();
    if (err instanceof ApiError) {
      return <Empty>{err.message}</Empty>;
    }
    throw err;
  }

  const { edition, coverage, isLeagueTable } = standings;
  const missing = coverage.matchesMissingScore;

  return (
    <div className="space-y-8">
      <div className="space-y-2">
        <BackLink href="/">All competitions</BackLink>
        <h1 className="text-2xl font-semibold tracking-tight">{edition.competition}</h1>
        <p className="flex items-center gap-2 text-sm text-muted">
          {edition.season}
          {!isLeagueTable ? <Badge>{edition.competitionType.replaceAll("_", " ")}</Badge> : null}
          <Link
            href={`/matches?editionId=${editionId}`}
            className="text-muted underline underline-offset-2 hover:text-foreground"
          >
            View matches
          </Link>
        </p>
      </div>

      <section className="space-y-3">
        <h2 className="text-sm font-semibold uppercase tracking-wide text-muted">
          {isLeagueTable ? "Table" : "Results summary"}
        </h2>

        {!isLeagueTable ? (
          <CoverageNote>
            {`This is ${COMPETITION_KIND[edition.competitionType] ?? "not a league"}, not a round-robin league — the standings below summarise results across the whole edition but are not an official table.`}
          </CoverageNote>
        ) : null}

        {missing > 0 ? (
          <CoverageNote>
            Built from {coverage.matchesCounted} of {coverage.matchesFullTime} completed
            matches. {missing} {missing === 1 ? "match has" : "matches have"} no score
            recorded in the source data, so teams show different numbers of games played.
          </CoverageNote>
        ) : null}

        {standings.standings.length === 0 ? (
          <Empty>No completed matches with scores in this edition yet.</Empty>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[560px] border-collapse text-sm">
              <thead>
                <tr className="border-b border-border text-left text-xs uppercase tracking-wide text-muted">
                  <th className="py-2 pr-2 font-medium">#</th>
                  <th className="py-2 pr-2 font-medium">Team</th>
                  {["P", "W", "D", "L", "GF", "GA", "GD"].map((h) => (
                    <th key={h} className="px-2 py-2 text-right font-medium">{h}</th>
                  ))}
                  <th className="py-2 pl-2 text-right font-medium">Pts</th>
                </tr>
              </thead>
              <tbody>
                {standings.standings.map((r) => (
                  <tr key={r.teamId} className="border-b border-border/60">
                    <td className="py-2 pr-2 tabular-nums text-muted">{r.position}</td>
                    <td className="py-2 pr-2">
                      <span className="flex items-center gap-2">
                        <TeamCrest name={r.teamName} />
                        <span className="truncate">{r.teamName}</span>
                      </span>
                    </td>
                    {[r.played, r.won, r.drawn, r.lost, r.goalsFor, r.goalsAgainst].map(
                      (v, i) => (
                        <td key={i} className="px-2 py-2 text-right tabular-nums text-muted">
                          {v}
                        </td>
                      ),
                    )}
                    <td className="px-2 py-2 text-right tabular-nums text-muted">
                      {r.goalDifference > 0 ? `+${r.goalDifference}` : r.goalDifference}
                    </td>
                    <td className="py-2 pl-2 text-right font-semibold tabular-nums">
                      {r.points}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      <section className="space-y-3">
        <h2 className="text-sm font-semibold uppercase tracking-wide text-muted">
          Top scorers
        </h2>

        {scorers.coverage.unattributedGoals > 0 ? (
          <CoverageNote>
            {scorers.coverage.attributedGoals} goals have a named scorer;{" "}
            {scorers.coverage.unattributedGoals} do not, and events are recorded for only{" "}
            {scorers.coverage.matchesWithEvents} of {scorers.coverage.matchesPlayed}{" "}
            matches. Treat these totals as a minimum, not a final record.
          </CoverageNote>
        ) : null}

        {scorers.scorers.length === 0 ? (
          <Empty>No goalscorer data recorded for this edition.</Empty>
        ) : (
          <ol className="divide-y divide-border rounded-lg border border-border">
            {scorers.scorers.map((s) => (
              <li key={s.playerId} className="flex items-center gap-3 px-4 py-2.5 text-sm">
                <span className="w-5 shrink-0 tabular-nums text-xs text-muted">{s.rank}</span>
                <span className="min-w-0 flex-1">
                  <span className="block truncate">{s.playerName}</span>
                  {s.teamName ? (
                    <span className="block truncate text-xs text-muted">{s.teamName}</span>
                  ) : null}
                </span>
                <span className="shrink-0 text-right">
                  <span className="font-semibold tabular-nums">{s.goals}</span>
                  {s.penalties > 0 ? (
                    <span className="block text-xs text-muted">{s.penalties} pen</span>
                  ) : null}
                </span>
              </li>
            ))}
          </ol>
        )}
      </section>
    </div>
  );
}
