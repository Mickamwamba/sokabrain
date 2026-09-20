import Link from "next/link";
import { matchState, showsScore, statusLabel } from "@/lib/match-state";
import { featuredEdition, groupByCompetition } from "@/lib/home-scope";
import {
  api,
  ApiError,
  type Edition,
  type Match,
  type StandingsRow,
} from "@/lib/api";
import { Crest, Empty, PageTitle , LiveBadge } from "@/components/ui";
import { MatchRows, kickoffTime } from "@/components/match-list";
import { DateStrip } from "@/components/schedule-nav";
import { MiniStandings, MiniTopScorers } from "@/components/home-league-pulse";

export const dynamic = "force-dynamic";

function one(v: string | string[] | undefined) {
  return Array.isArray(v) ? v[0] : v;
}

function fmtDateHeading(iso: string) {
  return new Date(`${iso}T12:00:00Z`).toLocaleDateString("en-GB", {
    weekday: "long",
    day: "numeric",
    month: "long",
    year: "numeric",
    timeZone: "Africa/Dar_es_Salaam",
  });
}

function RichMatchCard({ match }: { match: Match }) {
  const time = kickoffTime(match.kickoffAt);
  // "FINISHED" was never a status the API emits — it is FULL_TIME — so this
  // fell through to "has a score", which reads a live match as full time.
  const state = matchState(match.status, match.score.home, match.score.away);
  const isLive = state === "LIVE";
  const isFinished = showsScore(state);
  const homeScore = match.score.home;
  const awayScore = match.score.away;

  return (
    <div className="rounded-2xl border border-line bg-paper p-5 shadow-xs hover:border-ink/40 transition-all">
      {/* Meta header: Round / Stadium / Status */}
      <div className="flex items-center justify-between border-b border-line/50 pb-3 text-xs">
        <div className="flex items-center gap-2">
          {match.round ? (
            <span className="rounded-md bg-wash px-2 py-0.5 font-bold text-ink">
              Round {match.round}
            </span>
          ) : null}
          {match.stadium?.name ? (
            <span className="text-muted truncate max-w-[200px]">
              📍 {match.stadium.name}
              {match.stadium.city ? `, ${match.stadium.city}` : ""}
            </span>
          ) : null}
        </div>
        {isLive ? (
          <LiveBadge />
        ) : (
          <span
            className={`font-bold uppercase tracking-wider text-[10px] px-2 py-0.5 rounded-full ${
              isFinished
                ? "bg-wash text-muted"
                : "bg-emerald-500/10 text-emerald-700 border border-emerald-500/20"
            }`}
          >
            {isFinished
              ? match.status === "FULL_TIME"
                ? "Full Time"
                : statusLabel(match.status)
              : state === "OFF"
                ? statusLabel(match.status)
                : time
                  ? `Kickoff ${time}`
                  : "Scheduled"}
          </span>
        )}
      </div>

      {/* Teams and Scoreline — Click anywhere to view match details & events */}
      <Link
        href={`/matches/${match.id}`}
        className="group/match block py-5 transition-all hover:bg-wash/40 rounded-xl"
      >
        <div className="grid grid-cols-[1fr_auto_1fr] items-center gap-3 sm:gap-6 px-2">
          {/* Home Team */}
          <div className="flex flex-col sm:flex-row items-center sm:justify-end gap-2.5 text-center sm:text-right">
            <span className="order-2 sm:order-1 font-black text-base sm:text-lg text-ink group-hover/match:text-brand transition-colors line-clamp-2">
              {match.homeTeam.name}
            </span>
            <div className="order-1 sm:order-2 shrink-0 group-hover/match:scale-105 transition-transform">
              <Crest name={match.homeTeam.name} size={40} />
            </div>
          </div>

          {/* Score / VS Badge */}
          <div className="flex flex-col items-center justify-center px-2">
            {isFinished ? (
              <div className="flex items-center gap-2 rounded-xl bg-wash px-3.5 py-1.5 border border-line group-hover/match:border-brand/40 group-hover/match:bg-paper transition-all">
                <span
                  className={`text-2xl font-black nums ${
                    homeScore !== null && awayScore !== null && homeScore > awayScore
                      ? "text-ink font-black"
                      : "text-muted"
                  }`}
                >
                  {homeScore ?? 0}
                </span>
                <span className="text-muted/40 font-bold">:</span>
                <span
                  className={`text-2xl font-black nums ${
                    homeScore !== null && awayScore !== null && awayScore > homeScore
                      ? "text-ink font-black"
                      : "text-muted"
                  }`}
                >
                  {awayScore ?? 0}
                </span>
              </div>
            ) : (
              <div className="flex flex-col items-center justify-center rounded-xl bg-wash/80 px-3 py-1.5 border border-line/60 group-hover/match:border-brand/40 group-hover/match:bg-paper transition-all">
                <span className="text-base font-black text-ink nums">{time ?? "TBD"}</span>
                <span className="text-[10px] font-bold text-muted uppercase">EAT</span>
              </div>
            )}
          </div>

          {/* Away Team */}
          <div className="flex flex-col sm:flex-row items-center sm:justify-start gap-2.5 text-center sm:text-left">
            <div className="shrink-0 group-hover/match:scale-105 transition-transform">
              <Crest name={match.awayTeam.name} size={40} />
            </div>
            <span className="font-black text-base sm:text-lg text-ink group-hover/match:text-brand transition-colors line-clamp-2">
              {match.awayTeam.name}
            </span>
          </div>
        </div>
      </Link>

      {/* Action Footer */}
      <div className="flex items-center justify-between border-t border-line/50 pt-3 text-xs">
        <Link
          href={`/stats/head-to-head?teamA=${match.homeTeam.id}&teamB=${match.awayTeam.id}`}
          className="font-bold text-muted hover:text-ink transition-colors flex items-center gap-1.5"
        >
          <span>⚔️ Head to Head</span>
        </Link>
      </div>
    </div>
  );
}

function RestDayNotice({
  upcomingMatch,
  date,
}: {
  upcomingMatch?: Match | null;
  date?: string | null;
}) {
  return (
    <div className="rounded-2xl border border-line bg-gradient-to-br from-paper via-wash/40 to-paper p-6 text-center shadow-xs">
      <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-brand/10 text-brand text-2xl mb-3">
        ⚽
      </div>
      <h3 className="text-base font-black text-ink">
        {date ? `No fixtures on ${fmtDateHeading(date)}` : "No fixtures scheduled today"}
      </h3>
      <p className="text-xs text-muted mt-1 max-w-md mx-auto">
        The league is on a scheduled rest day. Check the calendar strip above for matchdays or explore the next upcoming fixture below.
      </p>

      {upcomingMatch && (
        <div className="mt-5 pt-5 border-t border-line/60 text-left">
          <p className="text-[11px] font-bold uppercase tracking-wider text-brand mb-2">
            Next Marquee Fixture Across the League
          </p>
          <Link
            href={`/matches/${upcomingMatch.id}`}
            className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 p-3.5 rounded-xl bg-paper border border-line hover:border-brand/40 transition-all group"
          >
            <div className="flex items-center gap-3 min-w-0">
              <Crest name={upcomingMatch.homeTeam.name} size={28} />
              <span className="font-bold text-sm text-ink group-hover:text-brand transition-colors truncate">
                {upcomingMatch.homeTeam.name}
              </span>
              <span className="text-xs font-bold text-muted px-1">vs</span>
              <Crest name={upcomingMatch.awayTeam.name} size={28} />
              <span className="font-bold text-sm text-ink group-hover:text-brand transition-colors truncate">
                {upcomingMatch.awayTeam.name}
              </span>
            </div>
            <div className="shrink-0 text-left sm:text-right">
              <span className="text-xs font-bold text-ink">
                {upcomingMatch.kickoffAt
                  ? new Date(upcomingMatch.kickoffAt).toLocaleDateString("en-GB", {
                      weekday: "short",
                      day: "numeric",
                      month: "short",
                      timeZone: "Africa/Dar_es_Salaam",
                    })
                  : "TBD"}
              </span>
              <span className="text-[11px] text-muted ml-2">
                {kickoffTime(upcomingMatch.kickoffAt) ?? ""}
              </span>
            </div>
          </Link>
        </div>
      )}
    </div>
  );
}

export default async function MatchesHub(props: PageProps<"/">) {
  const sp = await props.searchParams;
  const dateParam = one(sp.date);

  let editions: Edition[];
  try {
    editions = await api.editions().then((r) => r.editions);
  } catch (err) {
    if (err instanceof ApiError) return <Empty>{err.message}</Empty>;
    throw err;
  }
  if (editions.length === 0) return <Empty>No published season to show yet.</Empty>;

  const today = new Date().toLocaleDateString("en-CA", { timeZone: "Africa/Dar_es_Salaam" });

  // Stable date window: anchor around today so clicking adjacent dates does not
  // shift the strip under the cursor.
  const anchorDate = (() => {
    if (!dateParam) return today;
    const diffDays =
      Math.abs(new Date(dateParam).getTime() - new Date(today).getTime()) / (1000 * 3600 * 24);
    return diffDays > 10 ? dateParam : today;
  })();

  // The companion column is one competition's; the fixture list is everyone's.
  const featured = featuredEdition(editions);

  const [dayData, standingsData, scorersData] = await Promise.all([
    // No editionId: the day strip counts every published competition at once.
    api.days({ around: anchorDate, before: 12, after: 12 }),
    featured ? api.standings(featured.editionId).catch(() => null) : Promise.resolve(null),
    featured ? api.topScorers(featured.editionId, 4).catch(() => null) : Promise.resolve(null),
  ]);

  const date = dateParam ?? dayData.nearest;

  const list = await api.matches(
    date
      // 100 is the endpoint's cap and comfortably above a full matchday across
      // every competition, which runs to roughly forty fixtures.
      ? { from: `${date}T00:00:00Z`, to: `${date}T23:59:59Z`, order: "asc", limit: 100 }
      : { order: "desc", limit: 20 },
  );

  const groups = groupByCompetition(list.matches);

  // Only looked up on a rest day, and across every competition rather than one.
  const upcoming =
    list.matches.length === 0
      ? await api
          .matches({ from: `${today}T00:00:00Z`, order: "asc", limit: 1 })
          .catch(() => ({ matches: [] as Match[] }))
      : { matches: [] as Match[] };

  const href = (patch: Record<string, string | undefined>) => {
    const q = new URLSearchParams();
    for (const [k, v] of Object.entries({ date, ...patch })) {
      if (v !== undefined && v !== null && v !== "") q.set(k, String(v));
    }
    const qs = q.toString();
    return qs ? `/?${qs}` : "/";
  };

  const standingsList: StandingsRow[] = standingsData?.standings || [];
  const scorersList = scorersData?.scorers || [];
  const nextMatch = upcoming.matches[0] || null;
  const rich = list.matches.length > 0 && list.matches.length <= 2;

  return (
    <div>
      <PageTitle
        title="Matches"
        sub={
          date
            ? `${fmtDateHeading(date)} · ${list.matches.length} ${
                list.matches.length === 1 ? "fixture" : "fixtures"
              } across ${groups.length} ${groups.length === 1 ? "competition" : "competitions"}`
            : "Every competition"
        }
        right={
          <Link
            href={href({ date: today })}
            className="rounded-lg border border-line bg-paper px-3 py-1.5 text-xs font-bold text-ink hover:border-brand/50 hover:text-brand transition-colors"
          >
            Today
          </Link>
        }
      />

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        <div className="lg:col-span-8 space-y-4">
          <DateStrip
            days={dayData.days.map((d) => ({ ...d, href: href({ date: d.date }) }))}
            active={date}
          />

          <div className="pt-1 space-y-6">
            {list.matches.length === 0 ? (
              <RestDayNotice upcomingMatch={nextMatch} date={date} />
            ) : (
              groups.map((g) => (
                <section key={g.id ?? g.name} className="space-y-2">
                  <div className="flex items-center justify-between px-1">
                    {g.editionId ? (
                      <Link
                        href={`/table?competitionId=${g.id}&editionId=${g.editionId}`}
                        className="group inline-flex items-center gap-1.5 text-xs font-black uppercase tracking-wider text-ink hover:text-brand transition-colors"
                      >
                        {g.name}
                        <span className="text-muted/50 group-hover:text-brand transition-colors">
                          →
                        </span>
                      </Link>
                    ) : (
                      <h2 className="text-xs font-black uppercase tracking-wider text-ink">
                        {g.name}
                      </h2>
                    )}
                    <span className="text-xs font-semibold text-muted">
                      {g.matches.length} {g.matches.length === 1 ? "match" : "matches"}
                    </span>
                  </div>

                  {rich ? (
                    <div className="space-y-4">
                      {g.matches.map((m) => (
                        <RichMatchCard key={m.id} match={m} />
                      ))}
                    </div>
                  ) : (
                    <MatchRows matches={g.matches} />
                  )}
                </section>
              ))
            )}
          </div>
        </div>

        {/* The featured competition only: a table and a scorer chart are
            meaningless without naming one, and Tanzania is both the home market
            and much the deepest data here. */}
        {featured ? (
          <div className="lg:col-span-4 space-y-4">
            <MiniStandings
              standings={standingsList}
              editionId={featured.editionId}
              competitionName={featured.competition}
            />
            <MiniTopScorers scorers={scorersList} editionId={featured.editionId} />
          </div>
        ) : null}
      </div>
    </div>
  );
}
