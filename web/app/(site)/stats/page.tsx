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

  // Both leaderboards below are scoped like everything else on the page. They
  // used to be captioned as covering every published competition, which
  // stopped being true the day the query started carrying a competitionId.
  const season = scope.editions.find((e) => e.editionId === scope.editionId)?.season;
  const scopeLabel = scope.allTime
    ? `${scope.competitionName}, every season`
    : [scope.competitionName, season && shortSeason(season)].filter(Boolean).join(" ");

  return (
    <div className="space-y-5">
      {/* Hero: what the vault holds, stated in one line and six numbers.
          Scoped like every other tab — a figure that mixes a league season with
          a continental tournament is not a figure anyone asked for. The badge
          says when the whole of a competition's history is on screen. */}
      <div className="flex flex-wrap items-center justify-end gap-3">
        {scope.allTime ? <AllTimeBadge competition={scope.competitionName} /> : null}
        <ScopeSelect
          competitions={scope.competitions}
          competitionId={scope.competitionId}
          seasons={seasonOptionsFor(scope)}
          value={scope.value}
          allowAllTime
        />
      </div>
      <section className="overflow-hidden rounded-xl bg-ink px-6 py-8 text-white">
        <h1 className="display max-w-2xl text-3xl font-extrabold leading-tight sm:text-4xl">
          East African football, counted properly.
        </h1>
        <p className="mt-2 max-w-xl text-sm text-white/70">
          Every goal, table and derby from the Tanzanian and Kenyan leagues — the
          statistical depth global apps keep for Europe.
        </p>
        <div className="mt-6 grid grid-cols-2 gap-x-6 gap-y-4 sm:grid-cols-3 lg:grid-cols-6">
          {[
            { n: overview.matches, l: "Matches" },
            { n: overview.goals, l: "Goals" },
            { n: overview.clubs, l: "Clubs" },
            { n: overview.players, l: "Players" },
            { n: overview.competitions, l: "Competitions" },
            { n: overview.seasons, l: "Seasons" },
          ].map((s) => (
            <div key={s.l}>
              <p className="stat-figure text-2xl text-white sm:text-3xl">
                {s.n.toLocaleString()}
              </p>
              <p className="mt-0.5 text-[11px] font-semibold uppercase tracking-wide text-white/50">
                {s.l}
              </p>
            </div>
          ))}
        </div>
      </section>

      <div className="grid gap-5 lg:grid-cols-2">
        <Card>
          <CardHead
            title="Top scorers"
            hint={scopeLabel}
            action={{ href: "/stats/players", label: "All players" }}
          />
          <ol>
            {scorers.map((p, i) => (
              <li
                key={p.playerId}
                className="flex items-center gap-3 border-b border-line px-5 py-3 last:border-0"
              >
                <Rank n={i + 1} />
                <span className="min-w-0 flex-1">
                  <span className="block truncate text-sm font-semibold">{p.playerName}</span>
                  <span className="block truncate text-xs text-muted">
                    {p.teamName ? <TeamLink id={p.teamId} name={p.teamName} /> : "—"}
                  </span>
                </span>
                <span className="stat-figure text-xl">{p.goals}</span>
              </li>
            ))}
          </ol>
        </Card>

        <Card>
          <CardHead
            title="Clubs by points"
            hint={scopeLabel}
            action={{ href: "/stats/clubs", label: "All clubs" }}
          />
          <ol>
            {topClubs.map((c, i) => (
              <li
                key={c.teamId}
                className="flex items-center gap-3 border-b border-line px-5 py-3 last:border-0"
              >
                <Rank n={i + 1} />
                <Crest name={c.teamName} size={26} />
                <span className="min-w-0 flex-1">
                  <TeamLink id={c.teamId} name={c.teamName} className="block truncate text-sm font-semibold" />
                  <span className="block text-xs text-muted nums">
                    {c.played} played · {c.won}W {c.drawn}D {c.lost}L
                  </span>
                </span>
                <span className="stat-figure text-xl">{c.points}</span>
              </li>
            ))}
          </ol>
        </Card>
      </div>

      <div className="grid gap-5 lg:grid-cols-2">
        <Card>
          <CardHead
            title="Latest results"
            action={{ href: "/matches", label: "Full archive" }}
          />
          <ul>
            {recent.matches.map((m) => (
              <li
                key={m.id}
                className="flex items-center gap-3 border-b border-line px-5 py-3 text-sm last:border-0"
              >
                <span className="w-12 shrink-0 text-xs text-muted">{fmtDate(m.kickoffAt)}</span>
                <span className="min-w-0 flex-1 truncate text-right">{m.homeTeam.name}</span>
                <span className="stat-figure shrink-0 rounded bg-wash px-2 py-1 text-sm">
                  {m.score.home ?? "–"}‑{m.score.away ?? "–"}
                </span>
                <span className="min-w-0 flex-1 truncate">{m.awayTeam.name}</span>
              </li>
            ))}
          </ul>
        </Card>

        <Card>
          <CardHead
            title="Competitions"
            action={{ href: "/competitions", label: "Browse all" }}
          />
          {/* Competitions, not seasons. Listing editions meant the first six
              tiles were six Premier League seasons and AFCON never appeared —
              a fan picks the competition here and the season from its own
              dropdown, so these links name no season. */}
          <ul className="grid gap-px bg-line sm:grid-cols-2">
            {competitions.map((c) => (
              <li key={c.id} className="bg-paper">
                <Link
                  href={competitionHref(c.id)}
                  className="block px-5 py-3.5 transition-colors hover:bg-wash"
                >
                  <span className="block truncate text-sm font-semibold">{c.name}</span>
                  <span className="mt-0.5 block text-xs text-muted">
                    {c.span} · {c.seasons} {c.seasons === 1 ? "season" : "seasons"}
                  </span>
                </Link>
              </li>
            ))}
          </ul>
        </Card>
      </div>

      <Card className="px-5 py-4">
        <p className="text-sm">
          <span className="font-semibold">Compare any two clubs.</span>{" "}
          <span className="text-muted">
            Every meeting, the running record and the goals between them.
          </span>{" "}
          <Link href="/stats/head-to-head" className="font-semibold text-brand hover:text-brand-dark">
            Head to head →
          </Link>
        </p>
      </Card>
    </div>
  );
}
