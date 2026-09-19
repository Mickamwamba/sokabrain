import Link from "next/link";
import { api, ApiError, type ClubStat, type Edition, type Overview, type PlayerStat } from "@/lib/api";
import { Card, CardHead, Crest, Empty, Rank, TeamLink } from "@/components/ui";
import { AllTimeBadge, ScopeSelect } from "@/components/scope-select";
import { resolveScope, seasonOptionsFor } from "@/lib/scope";
import { competitionHref, shortSeason, summariseCompetitions } from "@/lib/competitions";

export const dynamic = "force-dynamic";

function fmtDate(iso: string | null) {
  if (!iso) return "—";
  return new Date(iso).toLocaleDateString("en-GB", { day: "2-digit", month: "short" });
}

export default async function StatsHome(props: PageProps<"/stats">) {
  const sp = await props.searchParams;
  const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);
  let overview: Overview;
  let scorers: PlayerStat[];
  let clubs: ClubStat[];
  let editions: Edition[];
  let recent: Awaited<ReturnType<typeof api.matches>>;

  let scope: Awaited<ReturnType<typeof resolveScope>>;
  try {
    editions = await api.editions().then((r) => r.editions);
    scope = await resolveScope(one(sp.competitionId), one(sp.editionId), editions);
    const q = { competitionId: scope.competitionId, editionId: scope.editionId };
    [overview, scorers, clubs, recent] = await Promise.all([
      api.overview(q),
      api.players({ ...q, limit: 6 }).then((r) => r.players),
      api.clubs(q).then((r) => r.clubs),
      api.matches({ ...q, status: "FULL_TIME", limit: 6 }),
    ]);
  } catch (err) {
    if (err instanceof ApiError) {
      return (
        <Empty>
          <p className="font-semibold text-ink">Can’t reach the stats service.</p>
          <p className="mt-1">{err.message}</p>
        </Empty>
      );
    }
    throw err;
  }

  if (overview.matches === 0) {
    return (
      <Empty>
        <p className="font-semibold text-ink">Nothing published yet.</p>
        <p className="mt-1">
          Competitions appear here once an editor releases them in the admin area.
        </p>
      </Empty>
    );
  }

  const topClubs = clubs.slice(0, 6);
  const competitions = summariseCompetitions(editions);

  const season = scope.editions.find((e) => e.editionId === scope.editionId)?.season;
  const scopeLabel = scope.allTime
    ? `${scope.competitionName}, all seasons`
    : [scope.competitionName, season && shortSeason(season)].filter(Boolean).join(" ");

  const maxGoals = scorers.length > 0 ? scorers[0].goals : 1;

  return (
    <div className="space-y-6">
      {/* Scope Controls */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <span className="text-xs font-bold uppercase tracking-wider text-muted">
            Statistics Scope
          </span>
          <p className="text-sm font-semibold text-ink">{scopeLabel}</p>
        </div>
        <div className="flex items-center gap-3">
          {scope.allTime ? <AllTimeBadge competition={scope.competitionName} /> : null}
          <ScopeSelect
            competitions={scope.competitions}
            competitionId={scope.competitionId}
            seasons={seasonOptionsFor(scope)}
            value={scope.value}
            allowAllTime
          />
        </div>
      </div>

      {/* Hero: Sports-editorial banner */}
      <section className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-[#091522] via-[#0f273f] to-[#091522] p-6 sm:p-8 text-white shadow-lg border border-white/10">
        <div className="relative z-10">
          <div className="inline-flex items-center gap-2 rounded-full bg-brand/20 border border-brand/30 px-3 py-0.5 text-[10px] font-black uppercase tracking-wider text-emerald-400 mb-3">
            <span className="h-1.5 w-1.5 rounded-full bg-emerald-400" />
            East African Football Vault
          </div>
          <h1 className="display max-w-2xl text-3xl font-black leading-tight sm:text-4xl text-white">
            East African football, counted properly.
          </h1>
          <p className="mt-2 max-w-xl text-sm text-white/70 leading-relaxed">
            Every goal, table and derby from the Tanzanian and Kenyan leagues — the
            statistical depth global platforms keep for Europe.
          </p>

          <div className="mt-8 grid grid-cols-2 gap-x-6 gap-y-4 sm:grid-cols-3 lg:grid-cols-6 border-t border-white/10 pt-6">
            {[
              { n: overview.matches, l: "Matches" },
              { n: overview.goals, l: "Goals" },
              { n: overview.clubs, l: "Clubs" },
              { n: overview.players, l: "Players" },
              { n: overview.competitions, l: "Competitions" },
              { n: overview.seasons, l: "Seasons" },
            ].map((s) => (
              <div key={s.l}>
                <p className="stat-figure text-2xl text-white font-black sm:text-3xl">
                  {s.n.toLocaleString()}
                </p>
                <p className="mt-0.5 text-[11px] font-bold uppercase tracking-wider text-white/60">
                  {s.l}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Leaderboards Grid */}
      <div className="grid gap-6 lg:grid-cols-2">
        {/* Top Scorers */}
        <Card className="overflow-hidden">
          <CardHead
            title="Top Scorers"
            hint={scopeLabel}
            action={{ href: `/stats/players?competitionId=${scope.competitionId}&editionId=${scope.editionId}`, label: "Full Leaderboard" }}
          />
          <ol className="divide-y divide-line/60">
            {scorers.map((p, i) => {
              const pct = Math.round((p.goals / maxGoals) * 100);
              return (
                <li
                  key={p.playerId}
                  className="relative flex items-center gap-3 px-5 py-3 hover:bg-wash/60 transition-colors"
                >
                  <div
                    className="absolute inset-y-0 right-0 bg-brand/5 pointer-events-none"
                    style={{ width: `${pct}%` }}
                  />
                  <Rank n={i + 1} />
                  <span className="min-w-0 flex-1 relative z-10">
                    <span className="block truncate text-sm font-bold text-ink">{p.playerName}</span>
                    <span className="block truncate text-xs text-muted">
                      {p.teamName ? <TeamLink id={p.teamId} name={p.teamName} /> : "—"}
                    </span>
                  </span>
                  <span className="stat-figure text-xl text-ink font-black relative z-10">
                    {p.goals}
                  </span>
                </li>
              );
            })}
          </ol>
        </Card>

        {/* Clubs by points */}
        <Card className="overflow-hidden">
          <CardHead
            title="Clubs by Points"
            hint={scopeLabel}
            action={{ href: `/stats/clubs?competitionId=${scope.competitionId}&editionId=${scope.editionId}`, label: "Full Standings" }}
          />
          <ol className="divide-y divide-line/60">
            {topClubs.map((c, i) => (
              <li
                key={c.teamId}
                className="flex items-center gap-3 px-5 py-3 hover:bg-wash/60 transition-colors"
              >
                <Rank n={i + 1} />
                <Crest name={c.teamName} size={28} />
                <span className="min-w-0 flex-1">
                  <TeamLink
                    id={c.teamId}
                    name={c.teamName}
                    className="block truncate text-sm font-bold text-ink hover:text-brand"
                  />
                  <span className="block text-xs text-muted nums">
                    {c.played} played · {c.won}W {c.drawn}D {c.lost}L · {Math.round(c.winRate)}% win rate
                  </span>
                </span>
                <span className="stat-figure text-xl text-ink font-black">{c.points}</span>
              </li>
            ))}
          </ol>
        </Card>
      </div>

      {/* Latest Results Section */}
      <Card className="overflow-hidden">
        <CardHead
          title="Recent Full-Time Results"
          action={{ href: "/matches", label: "Full archive" }}
        />
        <ul className="divide-y divide-line/60">
          {recent.matches.map((m) => (
            <li key={m.id}>
              <Link
                href={`/matches/${m.id}`}
                className="flex items-center gap-3 px-5 py-3 text-sm hover:bg-wash/60 transition-colors group"
              >
                <span className="w-14 shrink-0 text-xs text-muted font-medium">
                  {fmtDate(m.kickoffAt)}
                </span>
                <span className="min-w-0 flex-1 flex items-center justify-end gap-2 text-right">
                  <span className="truncate font-semibold text-ink group-hover:text-brand transition-colors">
                    {m.homeTeam.name}
                  </span>
                  <Crest name={m.homeTeam.name} size={24} />
                </span>
                <span className="w-20 shrink-0 text-center">
                  <span className="stat-figure rounded bg-ink px-2.5 py-0.5 text-xs font-black text-white">
                    {m.score.home}‑{m.score.away}
                  </span>
                </span>
                <span className="min-w-0 flex-1 flex items-center gap-2 text-left">
                  <Crest name={m.awayTeam.name} size={24} />
                  <span className="truncate font-semibold text-ink group-hover:text-brand transition-colors">
                    {m.awayTeam.name}
                  </span>
                </span>
              </Link>
            </li>
          ))}
        </ul>
      </Card>

      {/* Competitions in Archive */}
      <div>
        <h2 className="display mb-3 text-lg font-black text-ink">Competitions in Archive</h2>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {competitions.map((c) => (
            <Link key={c.id} href={competitionHref(c.id)} className="block group">
              <Card className="p-5 hover:border-brand/50 hover:shadow-sm transition-all">
                <p className="display text-base font-black text-ink group-hover:text-brand transition-colors">
                  {c.name}
                </p>
                <p className="mt-1 text-xs text-muted font-medium">
                  {c.seasons} {c.seasons === 1 ? "season" : "seasons"} · {c.matches.toLocaleString()} matches recorded
                </p>
                <p className="mt-2 text-[11px] text-muted/70 font-semibold">
                  {c.span}
                </p>
              </Card>
            </Link>
          ))}
        </div>
      </div>
    </div>
  );
}
