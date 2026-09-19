import Link from "next/link";
import { api, ApiError, type HeadToHead, type TeamRefLite } from "@/lib/api";
import { Card, CardHead, Crest, Empty } from "@/components/ui";
import { AllTimeBadge } from "@/components/scope-select";

export const dynamic = "force-dynamic";

function pct(n: number, total: number) {
  return total === 0 ? 0 : Math.round((n / total) * 100);
}

function isKariakooDerby(nameA: string, nameB: string) {
  const normA = nameA.toLowerCase();
  const normB = nameB.toLowerCase();
  return (
    (normA.includes("simba") && normB.includes("yanga")) ||
    (normA.includes("yanga") && normB.includes("simba")) ||
    (normA.includes("young africans") && normB.includes("simba")) ||
    (normA.includes("simba") && normB.includes("young africans"))
  );
}

function Picker({
  side,
  selectedId,
  teams,
  hrefFor,
}: {
  side: "teamA" | "teamB";
  selectedId?: string | undefined;
  teams: TeamRefLite[];
  hrefFor: (side: "teamA" | "teamB", id: number) => string;
}) {
  const clubs = teams.filter((t) => t.type !== "NATIONAL");
  const nations = teams.filter((t) => t.type === "NATIONAL");
  const ordered: [string, TeamRefLite[]][] = [];
  if (clubs.length) ordered.push(["Clubs", clubs]);
  if (nations.length) ordered.push(["National teams", nations]);
  const showHeadings = ordered.length > 1;

  return (
    <Card className="overflow-hidden">
      <CardHead title={side === "teamA" ? "Team One" : "Team Two"} />
      <div className="max-h-80 overflow-y-auto divide-y divide-line/60">
        {ordered.map(([heading, list]) => (
          <div key={heading}>
            {showHeadings ? (
              <p className="sticky top-0 z-10 border-b border-line bg-wash/95 px-4 py-2 text-[10px] font-black uppercase tracking-wider text-muted">
                {heading}
              </p>
            ) : null}
            {list.map((t) => {
              const isSelected = String(t.id) === selectedId;
              return (
                <Link
                  key={t.id}
                  href={hrefFor(side, t.id)}
                  className={`flex items-center gap-3 px-4 py-2.5 text-sm transition-colors hover:bg-wash/70 ${
                    isSelected ? "bg-wash font-bold text-ink" : "text-ink/80"
                  }`}
                >
                  <Crest name={t.name} size={24} />
                  <span className="min-w-0 flex-1 truncate">{t.name}</span>
                  {t.country ? (
                    <span className="shrink-0 text-[11px] text-muted">{t.country}</span>
                  ) : null}
                  {isSelected && (
                    <span className="h-2 w-2 rounded-full bg-brand shrink-0" />
                  )}
                </Link>
              );
            })}
          </div>
        ))}
      </div>
    </Card>
  );
}

export default async function HeadToHeadPage(props: PageProps<"/stats/head-to-head">) {
  const sp = await props.searchParams;
  const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);
  const teamA = one(sp.teamA);
  const teamB = one(sp.teamB);

  let teams: TeamRefLite[];
  try {
    teams = (await api.teams()).teams;
  } catch (err) {
    if (err instanceof ApiError) return <Empty>{err.message}</Empty>;
    throw err;
  }

  // Find IDs for quick derby picks
  const simba = teams.find((t) => t.name.toLowerCase().includes("simba"));
  const yanga = teams.find((t) => t.name.toLowerCase().includes("yanga"));
  const azam = teams.find((t) => t.name.toLowerCase().includes("azam"));

  let h2h: HeadToHead | null = null;
  let error: string | null = null;
  if (teamA && teamB && teamA !== teamB) {
    try {
      h2h = await api.headToHead(teamA, teamB);
    } catch (err) {
      error = err instanceof ApiError ? err.message : "Could not load that comparison.";
    }
  }

  const pickerHref = (side: "teamA" | "teamB", id: number) => {
    const q = new URLSearchParams();
    if (side === "teamA") {
      q.set("teamA", String(id));
      if (teamB) q.set("teamB", teamB);
    } else {
      if (teamA) q.set("teamA", teamA);
      q.set("teamB", String(id));
    }
    return `/stats/head-to-head?${q}`;
  };

  const isDerby = h2h ? isKariakooDerby(h2h.teamA.name, h2h.teamB.name) : false;

  return (
    <div>
      <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
        <div>
          <h2 className="display text-xl font-black text-ink">Head to Head Comparison</h2>
          <p className="text-xs text-muted mt-0.5">
            Every recorded meeting between two clubs across all published seasons.
          </p>
        </div>
        <AllTimeBadge />
      </div>

      {/* Quick Derby Shortcuts */}
      {!h2h && simba && yanga && (
        <div className="mb-6 rounded-xl border border-line bg-paper p-4 shadow-2xs">
          <p className="text-xs font-bold uppercase tracking-wider text-muted mb-2.5">
            Popular Derbies & Matchups
          </p>
          <div className="flex flex-wrap gap-2">
            <Link
              href={`/stats/head-to-head?teamA=${simba.id}&teamB=${yanga.id}`}
              className="inline-flex items-center gap-2 rounded-full border border-line bg-wash/80 px-3.5 py-1.5 text-xs font-bold text-ink hover:border-brand hover:text-brand transition-all shadow-2xs"
            >
              <span>🔥 Kariakoo Derby: Simba vs Yanga</span>
            </Link>
            {azam && (
              <>
                <Link
                  href={`/stats/head-to-head?teamA=${simba.id}&teamB=${azam.id}`}
                  className="inline-flex items-center gap-2 rounded-full border border-line bg-wash/80 px-3.5 py-1.5 text-xs font-bold text-ink hover:border-brand hover:text-brand transition-all shadow-2xs"
                >
                  <span>Simba vs Azam</span>
                </Link>
                <Link
                  href={`/stats/head-to-head?teamA=${yanga.id}&teamB=${azam.id}`}
                  className="inline-flex items-center gap-2 rounded-full border border-line bg-wash/80 px-3.5 py-1.5 text-xs font-bold text-ink hover:border-brand hover:text-brand transition-all shadow-2xs"
                >
                  <span>Yanga vs Azam</span>
                </Link>
              </>
            )}
          </div>
        </div>
      )}

      {h2h ? (
        <div className="mb-6 space-y-6">
          {/* Comparison Scoreboard Card */}
          <Card className="overflow-hidden shadow-sm">
            {isDerby && (
              <div className="bg-gradient-to-r from-rose-600 via-amber-500 to-emerald-600 px-4 py-1.5 text-center text-xs font-black uppercase tracking-widest text-white">
                🔥 Official Kariakoo Derby Record
              </div>
            )}
            <div className="p-6">
              <div className="flex items-center justify-between gap-4">
                <div className="flex min-w-0 flex-1 items-center gap-3">
                  <Crest name={h2h.teamA.name} size={48} className="shadow-md" />
                  <div className="min-w-0">
                    <span className="display block truncate text-xl font-black text-ink">
                      {h2h.teamA.name}
                    </span>
                    <span className="block text-xs font-semibold text-muted">
                      {h2h.aGoals} goals scored
                    </span>
                  </div>
                </div>

                <div className="shrink-0 text-center px-4">
                  <p className="stat-figure text-3xl sm:text-4xl font-black text-ink">
                    <span className="text-brand-dark">{h2h.aWins}</span>
                    <span className="mx-1.5 text-muted/50 font-light">–</span>
                    <span className="text-muted">{h2h.draws}</span>
                    <span className="mx-1.5 text-muted/50 font-light">–</span>
                    <span className="text-brand-dark">{h2h.bWins}</span>
                  </p>
                  <p className="mt-1 text-[11px] font-black uppercase tracking-wider text-muted">
                    Wins · Draws · Wins
                  </p>
                </div>

                <div className="flex min-w-0 flex-1 items-center justify-end gap-3 text-right">
                  <div className="min-w-0">
                    <span className="display block truncate text-xl font-black text-ink">
                      {h2h.teamB.name}
                    </span>
                    <span className="block text-xs font-semibold text-muted">
                      {h2h.bGoals} goals scored
                    </span>
                  </div>
                  <Crest name={h2h.teamB.name} size={48} className="shadow-md" />
                </div>
              </div>

              {/* Dominance percentage bar */}
              <div className="mt-6 flex h-3 overflow-hidden rounded-full bg-wash shadow-inner">
                <div
                  className="bg-brand transition-all"
                  style={{ width: `${pct(h2h.aWins, h2h.meetings)}%` }}
                  title={`${h2h.teamA.name}: ${h2h.aWins} wins (${pct(h2h.aWins, h2h.meetings)}%)`}
                />
                <div
                  className="bg-slate-300 transition-all"
                  style={{ width: `${pct(h2h.draws, h2h.meetings)}%` }}
                  title={`Draws: ${h2h.draws} (${pct(h2h.draws, h2h.meetings)}%)`}
                />
                <div
                  className="bg-ink-soft transition-all"
                  style={{ width: `${pct(h2h.bWins, h2h.meetings)}%` }}
                  title={`${h2h.teamB.name}: ${h2h.bWins} wins (${pct(h2h.bWins, h2h.meetings)}%)`}
                />
              </div>
              <div className="mt-2 flex justify-between text-xs text-muted font-medium">
                <span>{h2h.teamA.name}: {pct(h2h.aWins, h2h.meetings)}%</span>
                <span>{h2h.meetings} total meetings</span>
                <span>{h2h.teamB.name}: {pct(h2h.bWins, h2h.meetings)}%</span>
              </div>
            </div>
          </Card>

          {/* Matches List */}
          <Card className="overflow-hidden">
            <CardHead
              title="All Recorded Encounters"
              hint={`${h2h.matches.length} fixtures in vault`}
            />
            {h2h.matches.length === 0 ? (
              <p className="px-5 py-10 text-center text-sm text-muted">
                These two clubs have no recorded meeting in the published data.
              </p>
            ) : (
              <ul className="divide-y divide-line/60">
                {h2h.matches.map((m) => {
                  const homeScore = m.homeScore ?? 0;
                  const awayScore = m.awayScore ?? 0;
                  const homeWon = m.homeScore !== null && homeScore > awayScore;
                  const awayWon = m.awayScore !== null && awayScore > homeScore;

                  return (
                    <li key={m.id}>
                      <Link
                        href={`/matches/${m.id}`}
                        className="flex items-center gap-3 px-5 py-3 text-sm hover:bg-wash/70 transition-colors group"
                      >
                        <span className="w-20 shrink-0 text-xs text-muted font-medium">
                          {m.kickoffAt
                            ? new Date(m.kickoffAt).toLocaleDateString("en-GB", {
                                day: "2-digit",
                                month: "short",
                                year: "2-digit",
                              })
                            : "—"}
                        </span>
                        <span className="min-w-0 flex-1 truncate text-right font-semibold text-ink group-hover:text-brand transition-colors">
                          {m.homeTeam}
                        </span>
                        <span className="stat-figure shrink-0 rounded-md bg-ink px-2.5 py-1 text-xs font-black text-white">
                          <span className={homeWon ? "text-gold" : ""}>{m.homeScore ?? "—"}</span>
                          <span className="mx-1 text-white/50">‑</span>
                          <span className={awayWon ? "text-gold" : ""}>{m.awayScore ?? "—"}</span>
                        </span>
                        <span className="min-w-0 flex-1 truncate font-semibold text-ink group-hover:text-brand transition-colors">
                          {m.awayTeam}
                        </span>
                        <span className="hidden w-44 shrink-0 truncate text-right text-xs text-muted sm:block">
                          {m.competition} {m.season}
                        </span>
                      </Link>
                    </li>
                  );
                })}
              </ul>
            )}
          </Card>

          <div>
            <Link
              href="/stats/head-to-head"
              className="inline-flex items-center gap-2 rounded-full border border-line bg-paper px-4 py-2 text-xs font-bold text-ink hover:border-ink transition-all shadow-2xs"
            >
              ← Choose different clubs
            </Link>
          </div>
        </div>
      ) : null}

      {error ? (
        <div className="mb-5">
          <Empty>{error}</Empty>
        </div>
      ) : null}

      {!h2h ? (
        <>
          {teamA && teamB && teamA === teamB ? (
            <div className="mb-4">
              <Empty>Please pick two different clubs to compare.</Empty>
            </div>
          ) : null}
          <div className="grid gap-5 sm:grid-cols-2">
            <Picker side="teamA" selectedId={teamA} teams={teams} hrefFor={pickerHref} />
            <Picker side="teamB" selectedId={teamB} teams={teams} hrefFor={pickerHref} />
          </div>
        </>
      ) : null}
    </div>
  );
}
