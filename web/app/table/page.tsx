import Link from "next/link";
import { notFound } from "next/navigation";
import { api, ApiError, type Edition } from "@/lib/api";
import { Card, CardHead, Crest, DataNote, Empty, PageTitle, Rank } from "@/components/ui";
import { ScopeSelect } from "@/components/scope-select";
import { resolveScope, seasonOptionsFor } from "@/lib/scope";
import { GroupTables, KnockoutBracket } from "@/components/group-tables";

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

/**
 * The league table, for whichever season you pick.
 *
 * Defaults to the season in play rather than to an archive index: a fan opening
 * "Table" wants this year's table, and only sometimes 2011/12's.
 */
export default async function TablePage(props: PageProps<"/table">) {
  const sp = await props.searchParams;
  const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);

  let editions: Edition[];
  try {
    editions = await api.editions().then((r) => r.editions);
  } catch (err) {
    if (err instanceof ApiError) return <Empty>{err.message}</Empty>;
    throw err;
  }

  const scope = await resolveScope(one(sp.competitionId), one(sp.editionId), editions);
  const editionId = scope.editionId;
  if (!editionId) {
    return <Empty>No published season to show yet.</Empty>;
  }

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

  const { edition, coverage, isLeagueTable, groups, knockout } = standings;
  const table = standings.standings;
  const champion = isLeagueTable && !coverage.isProvisional ? table[0] : undefined;
  // A tournament played in groups is shown as its groups and its bracket. The
  // combined ranking is still available below, but as a summary, not a table.
  const isTournament = groups.length > 0 || knockout.length > 0;
  // A national-team competition belongs on the nations board; sending it to
  // "Club stats" was what made Egypt look like a club in the first place.
  const isNationalTeam = ["CONTINENTAL_NATIONAL", "WORLD_CUP", "QUALIFIER"].includes(
    edition.competitionType,
  );
  const teamStatsPath = isNationalTeam ? "/stats/nations" : "/stats/clubs";
  const teamStatsLabel = isNationalTeam ? "Nation stats" : "Club stats";
  const finalTie = knockout.find((r) => r.round.toUpperCase() === "FINAL")?.matches[0];
  const winnerName =
    finalTie?.winnerTeamId === finalTie?.homeTeamId
      ? finalTie?.homeTeamName
      : finalTie?.winnerTeamId
        ? finalTie?.awayTeamName
        : undefined;

  // Used by both layouts: a league shows it beside the table, a tournament
  // beside the bracket.
  const scorersCard = (
      <Card className="overflow-hidden self-start">
        <CardHead
          title="Top scorers"
          action={{ href: `/stats/players?editionId=${editionId}`, label: "Full list" }}
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
  );

  return (
    <div>
      <PageTitle
        title={isTournament ? "Tournament" : "Table"}
        sub={edition.competition}
        right={
          <ScopeSelect
            competitions={scope.competitions}
            competitionId={scope.competitionId}
            seasons={seasonOptionsFor(scope)}
            value={String(editionId)}
          />
        }
      />

      <div className="mb-5 flex flex-wrap gap-2 text-sm">
        <Link
          href={`/?editionId=${editionId}`}
          className="rounded-full border border-line bg-paper px-4 py-1.5 font-medium hover:border-ink"
        >
          All matches
        </Link>
        <Link
          href={`${teamStatsPath}?editionId=${editionId}`}
          className="rounded-full border border-line bg-paper px-4 py-1.5 font-medium hover:border-ink"
        >
          {teamStatsLabel}
        </Link>
        <Link
          href={`/stats/players?editionId=${editionId}`}
          className="rounded-full border border-line bg-paper px-4 py-1.5 font-medium hover:border-ink"
        >
          Player stats
        </Link>
      </div>

      {/* Deliberately not a <Card>: Card hard-codes bg-paper, and a bg-ink
          passed through className loses to it in the generated CSS, which
          rendered this banner as white text on a white background. */}
      {champion || winnerName ? (
        <div className="mb-5 flex items-center gap-4 rounded-xl bg-ink px-6 py-5 text-white">
          <Crest name={champion?.teamName ?? winnerName!} size={44} />
          <div className="min-w-0">
            <p className="text-[11px] font-semibold uppercase tracking-wider text-white/50">
              {champion ? "Top of the table" : "Winner"}
            </p>
            <p className="display truncate text-xl font-extrabold">
              {champion?.teamName ?? winnerName}
            </p>
          </div>
          {champion ? (
            <div className="ml-auto shrink-0 text-right">
              <p className="stat-figure text-3xl">{champion.points}</p>
              <p className="text-[11px] font-semibold uppercase tracking-wider text-white/50">
                Points
              </p>
            </div>
          ) : null}
        </div>
      ) : null}

      {isTournament ? (
        <div className="space-y-5">
          {groups.length > 0 ? (
            <div>
              <h2 className="display mb-3 text-lg font-extrabold">Group stage</h2>
              <GroupTables groups={groups} />
            </div>
          ) : null}
          <div className="grid gap-5 lg:grid-cols-[1.6fr_1fr]">
            <div>
              {knockout.length > 0 ? (
                <>
                  <h2 className="display mb-3 text-lg font-extrabold">Knockout stage</h2>
                  <KnockoutBracket rounds={knockout} />
                </>
              ) : null}
            </div>
            {scorersCard}
          </div>
        </div>
      ) : (
        <div className="grid gap-5 lg:grid-cols-[1.6fr_1fr]">
        <Card className="overflow-hidden">
          <CardHead
            title={
              isLeagueTable
                ? coverage.isProvisional
                  ? "Table (incomplete season)"
                  : "Table"
                : "Results summary"
            }
          />
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
          {scorersCard}
        </div>
      )}

      <div className="mt-5 space-y-2">
        {!isLeagueTable ? (
          <DataNote>
            {isTournament
              ? `This is ${KIND[edition.competitionType] ?? "not a league"}. Each group is its own round robin, so those are shown as tables; the knockout rounds are ties, decided on the day and by penalties where level.`
              : `This is ${KIND[edition.competitionType] ?? "not a league"}, not a round-robin league — the standings above summarise results across the edition but are not an official table.`}
          </DataNote>
        ) : null}
        {coverage.isProvisional ? (
          <DataNote>
            <strong>This table is not a final standing.</strong>{" "}
            {coverage.missingFixtures} of the {coverage.fixturesExpected} fixtures this
            season implies are missing from every source we have, not merely unscored, so
            clubs here have played between {coverage.minPlayed} and {coverage.maxPlayed}{" "}
            matches. The individual results shown are correct; their sum is not a league
            table, and the order should not be read as final positions.
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
