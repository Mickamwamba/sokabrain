import Link from "next/link";
import { seasonOptions } from "@/lib/season";
import { api, ApiError, type Edition } from "@/lib/api";
import { Card, Crest, Empty, PageTitle } from "@/components/ui";
import { SeasonSelect } from "@/components/season-select";
import { MatchDays, MatchRows, kickoffTime } from "@/components/match-list";
import { DateStrip, ModeTabs, RoundStrip } from "@/components/schedule-nav";

export const dynamic = "force-dynamic";

/**
 * The fixture hub, and the site's front door.
 *
 * A fan arrives wanting one of two things: what is on now, or what is on next.
 * So the page opens on the current season and the nearest day with football,
 * rather than on an archive index.
 *
 * Date is the primary axis because kickoff dates are complete for every match
 * in the vault. Round browsing is offered only for seasons whose sources
 * actually publish round numbers — see the note under the list.
 */

function one(v: string | string[] | undefined) {
  return Array.isArray(v) ? v[0] : v;
}

function NextUp({ match }: { match: NonNullable<Awaited<ReturnType<typeof api.matches>>["matches"][number]> }) {
  const time = kickoffTime(match.kickoffAt);
  const day = match.kickoffAt
    ? new Date(match.kickoffAt).toLocaleDateString("en-GB", {
        weekday: "long", day: "numeric", month: "long", timeZone: "Africa/Dar_es_Salaam",
      })
    : null;
  return (
    <Link href={`/matches/${match.id}`} className="block">
      <Card className="flex items-center gap-4 px-5 py-4 transition-colors hover:bg-wash">
        <div className="min-w-0 flex-1">
          <p className="display text-[10px] font-bold uppercase tracking-wider text-muted">Next match</p>
          <div className="mt-1.5 flex items-center gap-2.5">
            <Crest name={match.homeTeam.name} size={26} />
            <span className="truncate font-semibold">{match.homeTeam.name}</span>
            <span className="text-muted">v</span>
            <Crest name={match.awayTeam.name} size={26} />
            <span className="truncate font-semibold">{match.awayTeam.name}</span>
          </div>
        </div>
        <div className="shrink-0 text-right">
          <p className="stat-figure text-lg leading-none">{time ?? "—"}</p>
          <p className="mt-1 text-xs text-muted">{day}</p>
        </div>
      </Card>
    </Link>
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

  const editionId = editionParam ? Number(editionParam) : context.editionId;
  const edition = editions.find((e) => e.editionId === editionId);
  if (!editionId) return <Empty>No published season to show yet.</Empty>;

  const rounds = await api.rounds(editionId);
  // Opening on the round in play is what a fan wants; opening on round 1 of a
  // finished season is not.
  const round = mode === "round" ? roundParam ?? rounds.currentRound : null;

  const today = new Date().toLocaleDateString("en-CA", { timeZone: "Africa/Dar_es_Salaam" });
  const dayData =
    mode === "date"
      ? await api.days({ editionId, around: dateParam ?? today, before: 8, after: 8 })
      : { days: [], nearest: null };
  const date = mode === "date" ? dateParam ?? dayData.nearest : null;

  const list = await api.matches(
    mode === "round" && round
      ? { editionId, round, order: "asc", limit: 100 }
      : date
        ? { editionId, from: `${date}T00:00:00Z`, to: `${date}T23:59:59Z`, order: "asc", limit: 100 }
        : { editionId, order: "desc", limit: 20 },
  );

  // Shown only when the current season still has fixtures ahead of it.
  const upcoming =
    context.inSeason && context.nextMatchDate
      ? await api.matches({ editionId, from: `${today}T00:00:00Z`, order: "asc", limit: 1 })
      : { matches: [] as (typeof list)["matches"] };

  const seasonChoices = seasonOptions(editions);

  const href = (patch: Record<string, string | undefined>) => {
    const q = new URLSearchParams();
    const merged = { mode, date, round, editionId: String(editionId), ...patch };
    for (const [k, v] of Object.entries(merged)) {
      if (v !== undefined && v !== null && v !== "") q.set(k, String(v));
    }
    const s = q.toString();
    return s ? `/?${s}` : "/";
  };

  return (
    <div>
      <PageTitle
        title="Matches"
        sub={
          edition
            ? `${edition.competition}${context.inSeason && editionId === context.editionId ? " · season in progress" : ""}`
            : undefined
        }
        right={
          <SeasonSelect
            seasons={seasonChoices}
            value={String(editionId)}
            // A day or a round belongs to the season it came from.
            clears={["date", "round"]}
          />
        }
      />

      {upcoming.matches[0] ? (
        <div className="mb-5">
          <NextUp match={upcoming.matches[0]} />
        </div>
      ) : null}

      <div className="mb-4 space-y-3">
        <ModeTabs
          mode={mode}
          byDateHref={`/?editionId=${editionId}&mode=date`}
          byRoundHref={`/?editionId=${editionId}&mode=round`}
          roundsAvailable={rounds.hasRounds}
        />
        {mode === "date" ? (
          <DateStrip days={dayData.days} active={date} hrefFor={(d) => href({ date: d })} />
        ) : (
          <RoundStrip rounds={rounds.rounds} active={round} hrefFor={(r) => href({ round: r })} />
        )}
      </div>

      {list.matches.length === 0 ? (
        <Empty>No matches on this {mode === "round" ? "round" : "day"}.</Empty>
      ) : mode === "round" ? (
        <MatchDays matches={list.matches} />
      ) : (
        <MatchRows matches={list.matches} />
      )}

      {mode === "round" && rounds.withoutRound > 0 ? (
        <p className="mt-4 text-xs text-muted">
          {rounds.withoutRound} of this season&rsquo;s matches carry no round number in any
          source, so the rounds above are missing some fixtures. Every match is reachable by
          date.
        </p>
      ) : null}
      {!rounds.hasRounds ? (
        <p className="mt-4 text-xs text-muted">
          No source publishes round numbers for {edition?.season}, so this season is browsed by
          date. Nothing is guessed — deriving matchdays from the fixture list gets one in four
          wrong whenever a match was postponed.
        </p>
      ) : null}
    </div>
  );
}
