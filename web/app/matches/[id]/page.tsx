import Link from "next/link";
import { notFound } from "next/navigation";
import { api, ApiError, type MatchDetail, type MatchEventRow } from "@/lib/api";
import { Card, CardHead, Crest, DataNote, Empty, FormDots } from "@/components/ui";

export const dynamic = "force-dynamic";

/**
 * One match, in full.
 *
 * The timeline is the point of the page, so it is built to be honest about a
 * vault whose event coverage changes by era: seasons before 2023/24 mostly have
 * a correct score and no event log at all. An empty timeline with no
 * explanation would read as "nothing happened in this match".
 */

const GOAL_TYPES = ["GOAL", "PENALTY_GOAL", "OWN_GOAL"];

const LABEL: Record<string, string> = {
  GOAL: "Goal",
  PENALTY_GOAL: "Penalty",
  OWN_GOAL: "Own goal",
  YELLOW_CARD: "Yellow card",
  SECOND_YELLOW: "Second yellow",
  RED_CARD: "Red card",
  ASSIST: "Assist",
  SUBSTITUTION: "Substitution",
  PENALTY_MISS: "Penalty missed",
  VAR_REVIEW: "VAR review",
};

function Mark({ type }: { type: string }) {
  if (type === "YELLOW_CARD" || type === "SECOND_YELLOW")
    return <span className="inline-block h-3 w-[9px] rounded-[1px] bg-[#e0b400]" aria-hidden />;
  if (type === "RED_CARD")
    return <span className="inline-block h-3 w-[9px] rounded-[1px] bg-[#d33]" aria-hidden />;
  if (type === "ASSIST") return <span className="text-muted" aria-hidden>➜</span>;
  if (GOAL_TYPES.includes(type)) return <span aria-hidden>⚽</span>;
  return <span className="text-muted" aria-hidden>·</span>;
}

function minuteOf(e: MatchEventRow) {
  if (e.minute === null) return null;
  return e.addedTime ? `${e.minute}+${e.addedTime}'` : `${e.minute}'`;
}

function EventLine({ e, align }: { e: MatchEventRow; align: "left" | "right" }) {
  const min = minuteOf(e);
  const body = (
    <>
      <Mark type={e.type} />
      <span className="truncate">
        {e.playerName ?? <span className="text-muted italic">scorer not recorded</span>}
        {e.type === "OWN_GOAL" ? <span className="ml-1 text-xs text-muted">(o.g.)</span> : null}
        {e.type === "PENALTY_GOAL" ? <span className="ml-1 text-xs text-muted">(pen)</span> : null}
        {e.type === "ASSIST" ? <span className="ml-1 text-xs text-muted">assist</span> : null}
      </span>
    </>
  );
  return (
    <li className={`flex items-center gap-2 py-1.5 text-sm ${align === "right" ? "flex-row-reverse text-right" : ""}`}>
      <span className="nums w-10 shrink-0 text-xs text-muted">{min ?? "—"}</span>
      <span className={`flex min-w-0 items-center gap-2 ${align === "right" ? "flex-row-reverse" : ""}`}>
        {body}
      </span>
    </li>
  );
}

function Timeline({ match }: { match: MatchDetail }) {
  // An own goal belongs, visually, to the side that conceded it — that is where
  // a fan looks for it — even though the goal counts for the other side.
  const home = match.events.filter((e) => e.side === "home");
  const away = match.events.filter((e) => e.side === "away");
  return (
    <div className="grid grid-cols-2 gap-x-6 px-5 py-4">
      <ul className="min-w-0">{home.map((e) => <EventLine key={e.id} e={e} align="left" />)}</ul>
      <ul className="min-w-0">{away.map((e) => <EventLine key={e.id} e={e} align="right" />)}</ul>
    </div>
  );
}

function Side({ team, align }: {
  team: { id: number; name: string };
  align: "left" | "right";
}) {
  return (
    <div className={`flex min-w-0 flex-1 flex-col items-center gap-2 ${align === "left" ? "sm:items-end" : "sm:items-start"}`}>
      <Crest name={team.name} size={52} />
      <span className="display text-center text-base font-bold leading-tight sm:text-lg">{team.name}</span>
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
        weekday: "long", day: "numeric", month: "long", year: "numeric",
        hour: "2-digit", minute: "2-digit", timeZone: "Africa/Dar_es_Salaam",
      })
    : null;

  const played = match.home.score !== null;
  const c = match.coverage;
  const h = match.headToHead;

  return (
    <div>
      <p className="mb-3 text-xs text-muted">
        <Link href={`/?editionId=${match.competition.editionId}`} className="hover:text-ink">
          {match.competition.name} {match.competition.season}
        </Link>
        {match.round ? <> · Round {match.round}</> : null}
      </p>

      <Card className="overflow-hidden">
        <div className="flex items-center gap-4 px-5 py-6">
          <Side team={match.home} align="left" />
          <div className="shrink-0 text-center">
            {played ? (
              <p className="stat-figure text-3xl leading-none sm:text-4xl">
                {match.home.score}<span className="mx-1.5 text-muted">–</span>{match.away.score}
              </p>
            ) : (
              <p className="stat-figure text-xl leading-none text-muted">v</p>
            )}
            <p className="mt-2 text-[11px] uppercase tracking-wide text-muted">
              {played ? "Full time" : match.status.replace("_", " ").toLowerCase()}
            </p>
          </div>
          <Side team={match.away} align="right" />
        </div>
        <div className="border-t border-line px-5 py-2.5 text-center text-xs text-muted">
          {kickoff ?? "Kickoff time not recorded"}
          {match.venue ? <> · {match.venue}</> : null}
        </div>
      </Card>

      <div className="mt-5 grid gap-5 lg:grid-cols-[1.5fr_1fr]">
        <div>
          <Card className="overflow-hidden">
            <CardHead title="Match events" />
            {match.events.length === 0 ? (
              <p className="px-5 py-8 text-center text-sm text-muted">
                {played
                  ? "No event log for this match."
                  : "This match has not been played yet."}
              </p>
            ) : (
              <Timeline match={match} />
            )}
          </Card>

          <div className="mt-3 space-y-2">
            {played && c.noEventLog ? (
              <DataNote>
                The score is recorded and verified, but no event log exists for this match.
                Goalscorers were not published for {match.competition.season} by any source we
                have — so this is missing data, not a goalless account of a {c.goalsInScore}-goal
                game.
              </DataNote>
            ) : null}
            {played && !c.noEventLog && !c.eventLogComplete ? (
              <DataNote>
                The event log names {c.goalEventsRecorded} of the {c.goalsInScore} goals in the
                score. The score is the authority here; the timeline is incomplete.
              </DataNote>
            ) : null}
            {c.unnamedScorers > 0 ? (
              <DataNote>
                {c.unnamedScorers} {c.unnamedScorers === 1 ? "goal is" : "goals are"} recorded
                without a scorer — the goal and the team are known, the player is not.
              </DataNote>
            ) : null}
          </div>
        </div>

        <div className="space-y-5">
          <Card className="overflow-hidden">
            <CardHead title="Head to head" />
            {h.played === 0 ? (
              <p className="px-5 py-6 text-center text-sm text-muted">First recorded meeting.</p>
            ) : (
              <div className="px-5 py-4">
                <div className="flex items-baseline justify-between text-sm">
                  <span className="stat-figure text-xl">{h.homeWins}</span>
                  <span className="text-xs text-muted">{h.draws} drawn</span>
                  <span className="stat-figure text-xl">{h.awayWins}</span>
                </div>
                <div className="mt-1 flex items-baseline justify-between text-xs text-muted">
                  <span className="truncate">{match.home.name}</span>
                  <span className="truncate">{match.away.name}</span>
                </div>
                <p className="mt-3 text-xs text-muted">
                  {h.played} meetings across every published season.
                </p>
              </div>
            )}
          </Card>

          <Card className="overflow-hidden">
            <CardHead title="Form before this match" />
            <div className="space-y-3 px-5 py-4">
              {([["home", match.home.name], ["away", match.away.name]] as const).map(([side, name]) => {
                const form = match.form[side];
                return (
                  <div key={side}>
                    <p className="mb-1.5 truncate text-xs font-medium">{name}</p>
                    {form.length === 0 ? (
                      <p className="text-xs text-muted">No earlier matches recorded.</p>
                    ) : (
                      <FormDots results={form.map((f) => f.result)} />
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
