import Link from "next/link";
import { LiveMinute, LiveRefresher } from "@/components/live-minute";
import { matchState, showsScore, statusLabel } from "@/lib/match-state";
import { notFound } from "next/navigation";
import { api, ApiError, type MatchDetail, type MatchEventRow } from "@/lib/api";
import { Card, CardHead, Crest, Empty, TeamLink , LiveBadge } from "@/components/ui";

export const dynamic = "force-dynamic";

const GOAL_TYPES = ["GOAL", "PENALTY_GOAL", "OWN_GOAL"];

function EventIcon({ type }: { type: string }) {
  if (type === "YELLOW_CARD" || type === "SECOND_YELLOW") {
    return <span className="inline-block h-3.5 w-2.5 rounded-[2px] bg-amber-400 shadow-2xs" title="Yellow Card" />;
  }
  if (type === "RED_CARD") {
    return <span className="inline-block h-3.5 w-2.5 rounded-[2px] bg-rose-600 shadow-2xs" title="Red Card" />;
  }
  if (type === "ASSIST") {
    return <span className="text-muted font-bold text-xs" title="Assist">👟</span>;
  }
  if (GOAL_TYPES.includes(type)) {
    return <span className="text-sm select-none" title="Goal">⚽</span>;
  }
  return <span className="text-muted text-xs select-none">·</span>;
}

function minuteOf(e: MatchEventRow) {
  if (e.minute === null) return null;
  return e.addedTime ? `${e.minute}+${e.addedTime}'` : `${e.minute}'`;
}

function ChronoTimeline({ events }: { events: MatchEventRow[] }) {
  // Sort events by minute (events without minute go at the end)
  const sorted = [...events].sort((a, b) => {
    if (a.minute === null && b.minute === null) return a.id - b.id;
    if (a.minute === null) return 1;
    if (b.minute === null) return -1;
    const minA = a.minute + (a.addedTime ?? 0) * 0.1;
    const minB = b.minute + (b.addedTime ?? 0) * 0.1;
    return minA - minB;
  });

  return (
    <div className="relative py-4 px-4 sm:px-6">
      {/* Central timeline line */}
      <div className="absolute left-1/2 top-4 bottom-4 w-px -translate-x-1/2 bg-line/80" />

      <div className="space-y-4 relative z-10">
        {sorted.map((e) => {
          // A timeline tracks the SCORELINE, so an own goal belongs on the side
          // it counts FOR — beside the team whose lead it just changed — not on
          // the side of the player who put it in. The vault stores the event
          // under the scorer's own team (design principle 5), which is exactly
          // why the API sends `countsForOtherSide`; this is what it is for.
          // The "(o.g.)" marker then says whose mistake it was.
          const creditedSide = e.countsForOtherSide
            ? e.side === "home"
              ? "away"
              : e.side === "away"
                ? "home"
                : null
            : e.side;
          const isHome = creditedSide === "home";
          const min = minuteOf(e);

          return (
            <div key={e.id} className="flex items-center gap-3">
              {/* Left Side (Home) */}
              <div className={`flex-1 flex items-center gap-2 ${isHome ? "justify-end text-right" : "opacity-0 invisible"}`}>
                {isHome && (
                  <>
                    <span className="truncate text-sm font-semibold text-ink">
                      {e.playerName ?? <span className="text-muted italic font-normal">Scorer not recorded</span>}
                      {e.type === "OWN_GOAL" ? <span className="ml-1 whitespace-nowrap text-xs font-bold text-rose-600">(O.G)</span> : null}
                      {e.type === "PENALTY_GOAL" ? <span className="ml-1 text-xs text-brand font-bold">(pen)</span> : null}
                      {e.type === "ASSIST" ? <span className="ml-1 text-xs text-muted font-normal">assist</span> : null}
                    </span>
                    <EventIcon type={e.type} />
                  </>
                )}
              </div>

              {/* Center Minute Pill */}
              <div className="w-14 shrink-0 text-center">
                <span className="nums inline-block rounded-full bg-wash border border-line px-2 py-0.5 text-[11px] font-extrabold text-ink shadow-2xs">
                  {min ?? "—"}
                </span>
              </div>

              {/* Right Side (Away) */}
              <div className={`flex-1 flex items-center gap-2 ${!isHome ? "justify-start text-left" : "opacity-0 invisible"}`}>
                {!isHome && (
                  <>
                    <EventIcon type={e.type} />
                    <span className="truncate text-sm font-semibold text-ink">
                      {e.playerName ?? <span className="text-muted italic font-normal">Scorer not recorded</span>}
                      {e.type === "OWN_GOAL" ? <span className="ml-1 whitespace-nowrap text-xs font-bold text-rose-600">(O.G)</span> : null}
                      {e.type === "PENALTY_GOAL" ? <span className="ml-1 text-xs text-brand font-bold">(pen)</span> : null}
                      {e.type === "ASSIST" ? <span className="ml-1 text-xs text-muted font-normal">assist</span> : null}
                    </span>
                  </>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

function Side({
  team,
  align,
}: {
  team: { id: number; name: string };
  align: "left" | "right";
}) {
  return (
    <div
      className={`flex min-w-0 flex-1 flex-col items-center gap-2.5 ${
        align === "left" ? "sm:items-end sm:text-right" : "sm:items-start sm:text-left"
      }`}
    >
      <TeamLink id={team.id} name={team.name} className="flex flex-col items-center gap-2.5 group">
        <Crest
          name={team.name}
          size={56}
          className="shadow-md ring-4 ring-wash transition-transform group-hover:scale-105"
        />
        <span className="display text-center text-base font-extrabold leading-tight text-ink group-hover:text-brand transition-colors sm:text-lg">
          {team.name}
        </span>
      </TeamLink>
    </div>
  );
}

export default async function MatchPage(props: PageProps<"/matches/[id]">) {
  const { id } = await props.params;

  let match: MatchDetail;
  try {
    match = await api.match(id);
  } catch (err) {
    if (err instanceof ApiError && err.status === 404) notFound();
    if (err instanceof ApiError) return <Empty>{err.message}</Empty>;
    throw err;
  }

  const kickoff = match.kickoffAt
    ? new Date(match.kickoffAt).toLocaleString("en-GB", {
        weekday: "long",
        day: "numeric",
        month: "long",
        year: "numeric",
        hour: "2-digit",
        minute: "2-digit",
        timeZone: "Africa/Dar_es_Salaam",
      })
    : null;

  const state = matchState(match.status, match.home.score, match.away.score);
  // A live match has a score and is NOT played out — the two are separate
  // questions, and conflating them badged a 0-0 first half "Full Time".
  const played = showsScore(state);
  const isLive = state === "LIVE";
  const h = match.headToHead;

  const homeScore = match.home.score ?? 0;
  const awayScore = match.away.score ?? 0;
  const homeWon = played && homeScore > awayScore;
  const awayWon = played && awayScore > homeScore;

  // H2H distribution percentages
  const totalH2H = Math.max(1, h.played);
  const homeWinPct = Math.round((h.homeWins / totalH2H) * 100);
  const drawPct = Math.round((h.draws / totalH2H) * 100);
  const awayWinPct = 100 - homeWinPct - drawPct;

  return (
    <div>
      {isLive ? <LiveRefresher /> : null}
      {/* Breadcrumb Context */}
      <div className="mb-4 flex items-center gap-2 text-xs font-medium text-muted">
        <Link
          href={`/?editionId=${match.competition.editionId}`}
          className="hover:text-brand transition-colors"
        >
          {match.competition.name} {match.competition.season}
        </Link>
        {match.round ? <span>· Round {match.round}</span> : null}
      </div>

      {/* Hero Scoreboard Header */}
      <Card className="overflow-hidden shadow-sm border-line">
        <div className="flex items-center justify-between gap-4 p-6 sm:p-8 bg-gradient-to-b from-paper via-wash/30 to-paper">
          <Side team={match.home} align="left" />

          <div className="shrink-0 text-center px-2">
            {played ? (
              <div>
                <p className="stat-figure text-4xl sm:text-5xl font-black tracking-tight text-ink">
                  <span className={homeWon ? "text-brand-dark" : awayWon ? "text-muted" : "text-ink"}>
                    {match.home.score}
                  </span>
                  <span className="mx-2 text-line text-3xl font-light">–</span>
                  <span className={awayWon ? "text-brand-dark" : homeWon ? "text-muted" : "text-ink"}>
                    {match.away.score}
                  </span>
                </p>
                <div className="mt-2.5">
                  {isLive ? (
                    <LiveBadge
                      minute={<LiveMinute minute={match.liveMinute} at={match.liveMinuteAt} />}
                    />
                  ) : (
                    <span className="inline-block rounded-full bg-ink px-3 py-0.5 text-[10px] font-black uppercase tracking-wider text-white shadow-2xs">
                      {match.status === "FULL_TIME" ? "Full Time" : statusLabel(match.status)}
                    </span>
                  )}
                </div>
              </div>
            ) : (
              <div>
                <span className="inline-block rounded-full bg-brand/10 border border-brand/20 px-3 py-1 text-xs font-black uppercase tracking-wider text-brand">
                  {state === "OFF" ? statusLabel(match.status) : "Upcoming"}
                </span>
                <p className="stat-figure text-2xl mt-2 text-muted font-light">vs</p>
              </div>
            )}
          </div>

          <Side team={match.away} align="right" />
        </div>

        <div className="border-t border-line/80 bg-wash/60 px-5 py-3 text-center text-xs font-medium text-muted flex flex-wrap items-center justify-center gap-x-4 gap-y-1">
          <span>{kickoff ?? "Kickoff time not recorded"}</span>
          {match.venue ? <span>· Venue: {match.venue}</span> : null}
        </div>
      </Card>

      {/* Events & Details Grid */}
      <div className="mt-6 grid gap-6 lg:grid-cols-[1.6fr_1fr]">
        <div>
          <Card className="overflow-hidden">
            <CardHead title="Match Events" />
            {match.events.length === 0 ? (
              <p className="px-5 py-12 text-center text-sm text-muted">
                {isLive
                  ? "No goals yet."
                  : played
                    ? "No event log available for this historical match."
                    : "Match has not been played yet."}
              </p>
            ) : (
              <ChronoTimeline events={match.events} />
            )}
          </Card>
        </div>

        {/* Head-to-Head & Form Sidebars */}
        <div className="space-y-6">
          <Card className="overflow-hidden">
            <CardHead title="Head to Head" />
            {h.played === 0 ? (
              <p className="px-5 py-6 text-center text-sm text-muted">First recorded meeting in vault.</p>
            ) : (
              <div className="p-5">
                <div className="flex items-baseline justify-between text-sm font-bold">
                  <div className="text-left">
                    <span className="stat-figure text-2xl text-ink">{h.homeWins}</span>
                    <p className="text-[11px] text-muted font-normal truncate max-w-[100px]">{match.home.name}</p>
                  </div>
                  <div className="text-center">
                    <span className="stat-figure text-base text-muted">{h.draws}</span>
                    <p className="text-[11px] text-muted font-normal">Drawn</p>
                  </div>
                  <div className="text-right">
                    <span className="stat-figure text-2xl text-ink">{h.awayWins}</span>
                    <p className="text-[11px] text-muted font-normal truncate max-w-[100px]">{match.away.name}</p>
                  </div>
                </div>

                {/* Visual H2H distribution bar */}
                <div className="mt-3 flex h-2 w-full overflow-hidden rounded-full bg-line">
                  <div
                    className="bg-brand transition-all"
                    style={{ width: `${homeWinPct}%` }}
                    title={`${match.home.name}: ${h.homeWins} wins (${homeWinPct}%)`}
                  />
                  <div
                    className="bg-slate-300 transition-all"
                    style={{ width: `${drawPct}%` }}
                    title={`Draws: ${h.draws} (${drawPct}%)`}
                  />
                  <div
                    className="bg-ink-soft transition-all"
                    style={{ width: `${awayWinPct}%` }}
                    title={`${match.away.name}: ${h.awayWins} wins (${awayWinPct}%)`}
                  />
                </div>

                <p className="mt-3 text-center text-xs text-muted">
                  {h.played} total meetings recorded across published seasons.
                </p>
              </div>
            )}
          </Card>

          <Card className="overflow-hidden">
            <CardHead title="Form Before This Match" />
            <div className="space-y-4 p-5">
              {([["home", match.home.name], ["away", match.away.name]] as const).map(([side, name]) => {
                const form = match.form[side];
                return (
                  <div key={side}>
                    <p className="mb-2 truncate text-xs font-bold text-ink">{name}</p>
                    {form.length === 0 ? (
                      <p className="text-xs text-muted">No prior matches this season.</p>
                    ) : (
                      <div className="flex flex-wrap gap-1.5">
                        {form.map((f, i) => (
                          <span
                            key={i}
                            title={`${f.result === "W" ? "Won" : f.result === "D" ? "Drew" : "Lost"} vs ${f.opponent} (${f.score})`}
                            className={`inline-flex items-center gap-1 rounded-md px-2 py-1 text-xs font-bold text-white shadow-2xs ${
                              f.result === "W" ? "bg-emerald-600" : f.result === "D" ? "bg-amber-500 text-ink" : "bg-rose-600"
                            }`}
                          >
                            <span>{f.result}</span>
                            <span className="text-[10px] font-normal opacity-90">{f.score}</span>
                          </span>
                        ))}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
}
