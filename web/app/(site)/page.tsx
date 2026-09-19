import Link from "next/link";
import { resolveScope, seasonOptionsFor } from "@/lib/scope";
import {
  api,
  ApiError,
  type Edition,
  type Match,
  type StandingsRow,
} from "@/lib/api";
import { Crest, Empty, PageTitle } from "@/components/ui";
import { ScopeSelect } from "@/components/scope-select";
import { MatchDays, MatchRows, kickoffTime } from "@/components/match-list";
import { DateStrip, ModeTabs, RoundStrip } from "@/components/schedule-nav";
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
  const isFinished = match.status === "FINISHED" || match.score.home !== null;
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
        <span
          className={`font-bold uppercase tracking-wider text-[10px] px-2 py-0.5 rounded-full ${
            isFinished
              ? "bg-wash text-muted"
              : "bg-emerald-500/10 text-emerald-700 border border-emerald-500/20"
          }`}
        >
          {isFinished ? "Full Time" : time ? `Kickoff ${time}` : "Scheduled"}
        </span>
      </div>

      {/* Teams and Scoreline */}
      <div className="py-5">
        <div className="grid grid-cols-[1fr_auto_1fr] items-center gap-3 sm:gap-6">
          {/* Home Team */}
          <Link
            href={`/teams/${match.homeTeam.id}`}
            className="flex flex-col sm:flex-row items-center sm:justify-end gap-2.5 text-center sm:text-right group"
          >
            <span className="order-2 sm:order-1 font-black text-base sm:text-lg text-ink group-hover:text-brand transition-colors line-clamp-2">
              {match.homeTeam.name}
            </span>
            <div className="order-1 sm:order-2 shrink-0">
              <Crest name={match.homeTeam.name} size={40} />
            </div>
          </Link>

          {/* Score / VS Badge */}
          <div className="flex flex-col items-center justify-center px-2">
            {isFinished ? (
              <div className="flex items-center gap-2 rounded-xl bg-wash px-3.5 py-1.5 border border-line">
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
              <div className="flex flex-col items-center justify-center rounded-xl bg-wash/80 px-3 py-1.5 border border-line/60">
                <span className="text-base font-black text-ink nums">{time ?? "TBD"}</span>
                <span className="text-[10px] font-bold text-muted uppercase">EAT</span>
              </div>
            )}
          </div>

          {/* Away Team */}
          <Link
            href={`/teams/${match.awayTeam.id}`}
            className="flex flex-col sm:flex-row items-center sm:justify-start gap-2.5 text-center sm:text-left group"
          >
            <div className="shrink-0">
              <Crest name={match.awayTeam.name} size={40} />
            </div>
            <span className="font-black text-base sm:text-lg text-ink group-hover:text-brand transition-colors line-clamp-2">
              {match.awayTeam.name}
            </span>
          </Link>
        </div>
      </div>

      {/* Action Footer */}
      <div className="flex flex-wrap items-center justify-between gap-2 border-t border-line/50 pt-3 text-xs">
        <Link
          href={`/stats/head-to-head?teamA=${match.homeTeam.id}&teamB=${match.awayTeam.id}`}
          className="font-bold text-muted hover:text-ink transition-colors flex items-center gap-1.5"
        >
          <span>⚔️ Head to Head</span>
        </Link>
        <Link
          href={`/matches/${match.id}`}
          className="font-bold text-brand hover:underline flex items-center gap-1"
        >
          <span>Match Details & Events →</span>
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
  const mode = one(sp.mode) === "round" ? "round" : "date";
  const dateParam = one(sp.date);
  const roundParam = one(sp.round);
  const editionParam = one(sp.editionId);

  let editions: Edition[];
  let context: Awaited<ReturnType<typeof api.context>>;
  try {
    [editions, context] = await Promise.all([
      api.editions().then((r) => r.editions),
      api.context(),
    ]);
  } catch (err) {
    if (err instanceof ApiError) return <Empty>{err.message}</Empty>;
    throw err;
  }

  const scope = await resolveScope(one(sp.competitionId), editionParam, editions);
  const editionId = scope.editionId ?? context.editionId;
  const edition = editions.find((e) => e.editionId === editionId);
  if (!editionId) return <Empty>No published season to show yet.</Empty>;

  const today = new Date().toLocaleDateString("en-CA", { timeZone: "Africa/Dar_es_Salaam" });

  // Stable date window: anchor around today so clicking adjacent dates does not shift the array
  const anchorDate = (() => {
    if (!dateParam) return today;
    const diffDays = Math.abs(new Date(dateParam).getTime() - new Date(today).getTime()) / (1000 * 3600 * 24);
    return diffDays > 10 ? dateParam : today;
  })();

  // Parallelize data fetching for rounds, days, standings, scorers, and next marquee match
  const [rounds, dayData, standingsData, scorersData, upcoming] = await Promise.all([
    api.rounds(editionId),
    mode === "date"
      ? api.days({ editionId, around: anchorDate, before: 12, after: 12 })
      : Promise.resolve({ days: [], nearest: null }),
    api.standings(editionId).catch(() => null),
    api.topScorers(editionId, 4).catch(() => null),
    context.inSeason && context.nextMatchDate
      ? api.matches({ editionId, from: `${today}T00:00:00Z`, order: "asc", limit: 1 }).catch(() => ({ matches: [] as Match[] }))
      : Promise.resolve({ matches: [] as Match[] }),
  ]);

  const round = mode === "round" ? roundParam ?? rounds.currentRound : null;
  const date = mode === "date" ? dateParam ?? dayData.nearest : null;

  const list = await api.matches(
    mode === "round" && round
      ? { editionId, round, order: "asc", limit: 100 }
      : date
        ? { editionId, from: `${date}T00:00:00Z`, to: `${date}T23:59:59Z`, order: "asc", limit: 100 }
        : { editionId, order: "desc", limit: 20 },
  );

  const seasonChoices = seasonOptionsFor(scope);

  const href = (patch: Record<string, string | undefined>) => {
    const q = new URLSearchParams();
    const merged = {
      mode,
      date,
      round,
      competitionId: String(scope.competitionId),
      editionId: String(editionId),
      ...patch,
    };
    for (const [k, v] of Object.entries(merged)) {
      if (v !== undefined && v !== null && v !== "") q.set(k, String(v));
    }
    const s = q.toString();
    return s ? `/?${s}` : "/";
  };

  const standingsList: StandingsRow[] = standingsData?.standings || [];
  const scorersList = scorersData?.scorers || [];
  const nextMatch = upcoming.matches[0] || null;

  return (
    <div>
      {/* Title & Scope selector */}
      <PageTitle
        title="Matches"
        sub={
          edition
            ? `${edition.competition}${context.inSeason && editionId === context.editionId ? " · in progress" : ""}`
            : undefined
        }
        right={
          <ScopeSelect
            competitions={scope.competitions}
            competitionId={scope.competitionId}
            seasons={seasonChoices}
            value={String(editionId)}
            clears={["date", "round"]}
          />
        }
      />

      {/* Main 2-column layout on Desktop, stacked on Mobile */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        {/* Left Column: Schedule & Matches (8 cols on desktop) */}
        <div className="lg:col-span-8 space-y-4">
          {/* Mode Switcher (By Date / By Round) + Jump to Today */}
          <ModeTabs
            mode={mode}
            byDateHref={`/?editionId=${editionId}&mode=date`}
            byRoundHref={`/?editionId=${editionId}&mode=round`}
            roundsAvailable={rounds.hasRounds}
            todayHref={href({ date: today })}
          />

          {/* Compact 7-day Strip or Round Strip */}
          {mode === "date" ? (
            <DateStrip
              days={dayData.days.map((d) => ({ ...d, href: href({ date: d.date }) }))}
              active={date}
            />
          ) : (
            <RoundStrip
              rounds={rounds.rounds.map((r) => ({ ...r, href: href({ round: r.round }) }))}
              active={round}
            />
          )}

          {/* Matches Container (Adaptive Layout based on match count) */}
          <div className="pt-1">
            {list.matches.length === 0 ? (
              <RestDayNotice upcomingMatch={nextMatch} date={date} />
            ) : mode === "round" ? (
              <MatchDays matches={list.matches} />
            ) : list.matches.length <= 2 ? (
              /* Rich Matchday Card Layout when 1 or 2 games */
              <div className="space-y-4">
                <div className="flex items-center justify-between px-1">
                  <h2 className="text-xs font-black uppercase tracking-wider text-muted">
                    {date ? fmtDateHeading(date) : "Matchday"}
                  </h2>
                  <span className="text-xs font-semibold text-brand">
                    {list.matches.length} {list.matches.length === 1 ? "Fixture" : "Fixtures"}
                  </span>
                </div>
                {list.matches.map((match) => (
                  <RichMatchCard key={match.id} match={match} />
                ))}
              </div>
            ) : (
              /* High-density Match Rows when 3+ games */
              <div>
                <div className="flex items-center justify-between pb-2 px-1">
                  <h2 className="text-xs font-black uppercase tracking-wider text-muted">
                    {date ? fmtDateHeading(date) : "Matchday"}
                  </h2>
                  <span className="text-xs font-semibold text-muted">
                    {list.matches.length} Matches
                  </span>
                </div>
                <MatchRows matches={list.matches} />
              </div>
            )}
          </div>
        </div>

        {/* Right Column (Desktop) / Bottom Section (Mobile): Companion League Pulse */}
        <div className="lg:col-span-4 space-y-4">
          <MiniStandings
            standings={standingsList}
            editionId={editionId}
            competitionName={edition?.competition}
          />
          <MiniTopScorers scorers={scorersList} editionId={editionId} />
        </div>
      </div>
    </div>
  );
}
