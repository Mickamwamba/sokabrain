import Link from "next/link";
import { notFound } from "next/navigation";
import { api, ApiError, type Edition } from "@/lib/api";
import { Card, CardHead, Crest, DataNote, Empty, PageTitle, Rank, TeamLink } from "@/components/ui";
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

function getZoneClass(pos: number, total: number, isLeague: boolean) {
  if (!isLeague) return "border-l-4 border-l-transparent";
  if (pos <= 2) return "border-l-4 border-l-emerald-600 bg-emerald-50/20";
  if (pos === 3) return "border-l-4 border-l-sky-500 bg-sky-50/20";
  if (total >= 14) {
    if (pos >= total - 1) return "border-l-4 border-l-rose-500 bg-rose-50/20";
    if (pos >= total - 3) return "border-l-4 border-l-amber-500 bg-amber-50/20";
  }
  return "border-l-4 border-l-transparent";
}

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
  const isTournament = groups.length > 0 || knockout.length > 0;
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

  const maxGoals = scorers.scorers.length > 0 ? scorers.scorers[0].goals : 1;

  const scorersCard = (
    <Card className="overflow-hidden self-start">
      <CardHead
        title="Top scorers"
        action={{ href: `/stats/players?editionId=${editionId}`, label: "Full list" }}
      />
      {scorers.scorers.length === 0 ? (
        <p className="px-5 py-10 text-center text-sm text-muted">
          No goalscorer data recorded for this season.
        </p>
      ) : (
        <ol className="divide-y divide-line/60">
          {scorers.scorers.map((s) => {
            const pct = Math.round((s.goals / maxGoals) * 100);
            return (
              <li
                key={s.playerId}
                className="relative flex items-center gap-3 px-5 py-3 hover:bg-wash/60 transition-colors"
              >
                {/* Visual bar fill behind scorer */}
                <div
                  className="absolute inset-y-0 right-0 bg-brand/5 pointer-events-none transition-all"
                  style={{ width: `${pct}%` }}
                />
                <Rank n={s.rank} />
                <span className="min-w-0 flex-1 relative z-10">
                  <span className="block truncate text-sm font-bold text-ink">{s.playerName}</span>
                  <span className="block truncate text-xs text-muted">
                    {s.teamName ?? "—"}
                    {s.penalties > 0 ? ` · ${s.penalties} pens` : ""}
                  </span>
                </span>
                <span className="stat-figure text-xl text-ink font-black relative z-10">
                  {s.goals}
                </span>
              </li>
            );
          })}
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

      {/* Quick Navigation Pills */}
      <div className="mb-5 flex flex-wrap gap-2 text-sm">
        <Link
          href={`/?editionId=${editionId}`}
          className="rounded-full border border-line bg-paper px-4 py-1.5 font-medium text-ink hover:border-ink hover:bg-wash transition-all shadow-2xs"
        >
          Fixtures & Results
        </Link>
        <Link
          href={`${teamStatsPath}?editionId=${editionId}`}
          className="rounded-full border border-line bg-paper px-4 py-1.5 font-medium text-ink hover:border-ink hover:bg-wash transition-all shadow-2xs"
        >
          {teamStatsLabel}
        </Link>
        <Link
          href={`/stats/players?editionId=${editionId}`}
          className="rounded-full border border-line bg-paper px-4 py-1.5 font-medium text-ink hover:border-ink hover:bg-wash transition-all shadow-2xs"
        >
          Player Leaderboard
        </Link>
      </div>

      {/* Top of the Table / Winner Spotlight */}
      {(champion || winnerName) && (
        <div className="mb-6 flex flex-wrap items-center justify-between gap-4 rounded-2xl bg-gradient-to-r from-ink via-ink-soft to-ink p-5 sm:p-6 text-white shadow-md border border-white/10">
          <div className="flex items-center gap-4 min-w-0">
            <Crest name={champion?.teamName ?? winnerName!} size={52} className="shadow-md ring-2 ring-white/20" />
            <div className="min-w-0">
              <span className="inline-block rounded bg-gold/20 px-2 py-0.5 text-[10px] font-black uppercase tracking-wider text-gold">
                {champion ? "Current Leader" : "Tournament Winner"}
              </span>
              <p className="display truncate text-2xl font-black tracking-tight mt-0.5">
                <TeamLink
                  id={champion?.teamId}
                  name={champion?.teamName ?? winnerName!}
                  className="hover:text-gold transition-colors text-white"
                />
              </p>
              {champion ? (
                <p className="text-xs text-white/70 mt-0.5">
                  {champion.played} matches · {champion.won}W {champion.drawn}D {champion.lost}L · {champion.goalDifference > 0 ? `+${champion.goalDifference}` : champion.goalDifference} GD
                </p>
              ) : null}
            </div>
          </div>
          {champion ? (
            <div className="text-right pl-4 sm:border-l sm:border-white/15">
              <p className="stat-figure text-4xl text-gold font-black">{champion.points}</p>
              <p className="text-[10px] font-bold uppercase tracking-wider text-white/60">Points</p>
            </div>
          ) : null}
        </div>
      )}

      {/* Main Standings Grid */}
      {isTournament ? (
        <div className="space-y-6">
          {groups.length > 0 ? (
            <div>
              <h2 className="display mb-3 text-lg font-extrabold text-ink">Group stage</h2>
              <GroupTables groups={groups} />
            </div>
          ) : null}
          <div className="grid gap-6 lg:grid-cols-[1.6fr_1fr]">
            <div>
              {knockout.length > 0 ? (
                <>
                  <h2 className="display mb-3 text-lg font-extrabold text-ink">Knockout stage</h2>
                  <KnockoutBracket rounds={knockout} />
                </>
              ) : null}
            </div>
            {scorersCard}
          </div>
        </div>
      ) : (
        <div className="grid gap-6 lg:grid-cols-[1.6fr_1fr]">
          <div className="space-y-3">
            <Card className="overflow-hidden">
              <CardHead
                title={
                  isLeagueTable
                    ? coverage.isProvisional
                      ? "Standings (incomplete season)"
                      : "Standings"
                    : "Results summary"
                }
              />
              {table.length === 0 ? (
                <p className="px-5 py-10 text-center text-sm text-muted">
                  No completed matches with a score yet.
                </p>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full min-w-[540px] border-collapse text-sm">
                    <thead>
                      <tr className="border-b border-line bg-wash/80 text-left text-[11px] font-bold uppercase tracking-wider text-muted">
                        <th className="py-3 pl-4 pr-1 text-center w-10">#</th>
                        <th className="px-3 py-3">Team</th>
                        <th className="px-2 py-3 text-right" title="Played">P</th>
                        <th className="px-2 py-3 text-right" title="Won">W</th>
                        <th className="px-2 py-3 text-right" title="Drawn">D</th>
                        <th className="px-2 py-3 text-right" title="Lost">L</th>
                        <th className="px-2 py-3 text-right" title="Goals For">GF</th>
                        <th className="px-2 py-3 text-right" title="Goals Against">GA</th>
                        <th className="px-2 py-3 text-right" title="Goal Difference">GD</th>
                        <th className="py-3 pl-2 pr-5 text-right font-black" title="Points">Pts</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-line/60">
                      {table.map((r) => {
                        const zoneClass = getZoneClass(r.position, table.length, isLeagueTable);
                        return (
                          <tr
                            key={r.teamId}
                            className={`transition-colors hover:bg-wash/70 ${zoneClass}`}
                          >
                            <td className="py-3 pl-3 pr-1 text-center">
                              <Rank n={r.position} />
                            </td>
                            <td className="px-3 py-3">
                              <TeamLink
                                id={r.teamId}
                                name={r.teamName}
                                className="flex items-center gap-2.5 font-bold text-ink hover:text-brand transition-colors"
                              >
                                <Crest name={r.teamName} size={26} />
                                <span className="truncate">{r.teamName}</span>
                              </TeamLink>
                            </td>
                            <td className="px-2 py-3 text-right nums text-muted font-medium">{r.played}</td>
                            <td className="px-2 py-3 text-right nums text-muted font-medium">{r.won}</td>
                            <td className="px-2 py-3 text-right nums text-muted font-medium">{r.drawn}</td>
                            <td className="px-2 py-3 text-right nums text-muted font-medium">{r.lost}</td>
                            <td className="px-2 py-3 text-right nums text-muted font-medium">{r.goalsFor}</td>
                            <td className="px-2 py-3 text-right nums text-muted font-medium">{r.goalsAgainst}</td>
                            <td className="px-2 py-3 text-right nums font-semibold text-ink">
                              {r.goalDifference > 0 ? `+${r.goalDifference}` : r.goalDifference}
                            </td>
                            <td className="stat-figure py-3 pl-2 pr-5 text-right text-base text-ink font-black">
                              {r.points}
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              )}
            </Card>

            {/* Table Qualification / Relegation Legend */}
            {isLeagueTable && table.length >= 6 && (
              <div className="flex flex-wrap items-center gap-x-5 gap-y-2 rounded-xl border border-line bg-paper/60 px-4 py-2.5 text-xs text-muted">
                <div className="flex items-center gap-1.5">
                  <span className="h-3 w-1 rounded-sm bg-emerald-600" />
                  <span>CAF Champions League (1st & 2nd)</span>
                </div>
                <div className="flex items-center gap-1.5">
                  <span className="h-3 w-1 rounded-sm bg-sky-500" />
                  <span>CAF Confederation Cup (3rd)</span>
                </div>
                {table.length >= 14 && (
                  <>
                    <div className="flex items-center gap-1.5">
                      <span className="h-3 w-1 rounded-sm bg-amber-500" />
                      <span>Relegation Play-offs</span>
                    </div>
                    <div className="flex items-center gap-1.5">
                      <span className="h-3 w-1 rounded-sm bg-rose-500" />
                      <span>Relegation Zone</span>
                    </div>
                  </>
                )}
              </div>
            )}
          </div>

          {scorersCard}
        </div>
      )}

      {/* Data Fidelity Notes */}
      <div className="mt-6 space-y-2.5">
        {!isLeagueTable ? (
          <DataNote>
            {isTournament
              ? `This is ${KIND[edition.competitionType] ?? "not a league"}. Each group is its own round robin, so those are shown as tables; the knockout rounds are ties, decided on the day and by penalties where level.`
              : `This is ${KIND[edition.competitionType] ?? "not a league"}, not a round-robin league — the standings above summarise results across the edition but are not an official table.`}
          </DataNote>
        ) : null}
        {coverage.isProvisional ? (
          <DataNote>
            <strong>This table is not a final standing.</strong> {coverage.missingFixtures} of the {coverage.fixturesExpected} fixtures this
            season implies are missing from every source we have, not merely unscored, so
            clubs here have played between {coverage.minPlayed} and {coverage.maxPlayed} matches.
          </DataNote>
        ) : null}
        {coverage.matchesMissingScore > 0 ? (
          <DataNote>
            Built from {coverage.matchesCounted} of {coverage.matchesFullTime} completed matches. {coverage.matchesMissingScore}{" "}
            {coverage.matchesMissingScore === 1 ? "match has" : "matches have"} no score in
            the source data.
          </DataNote>
        ) : null}
        {scorers.coverage.unattributedGoals > 0 ? (
          <DataNote>
            {scorers.coverage.attributedGoals} goals have a verified named scorer; {scorers.coverage.unattributedGoals} do not.
          </DataNote>
        ) : null}
      </div>
    </div>
  );
}
