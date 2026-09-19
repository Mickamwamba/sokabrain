import Link from "next/link";
import { resolveScope, seasonOptionsFor } from "@/lib/scope";
import { api, ApiError, type Edition } from "@/lib/api";
import { Card, Crest, DataNote, Empty, PageTitle } from "@/components/ui";
import { ScopeSelect } from "@/components/scope-select";
import { MatchDays, MatchRows, kickoffTime } from "@/components/match-list";
import { DateStrip, ModeTabs, RoundStrip } from "@/components/schedule-nav";

export const dynamic = "force-dynamic";

function one(v: string | string[] | undefined) {
  return Array.isArray(v) ? v[0] : v;
}

function NextUp({ match }: { match: NonNullable<Awaited<ReturnType<typeof api.matches>>["matches"][number]> }) {
  const time = kickoffTime(match.kickoffAt);
  const day = match.kickoffAt
    ? new Date(match.kickoffAt).toLocaleDateString("en-GB", {
        weekday: "long",
        day: "numeric",
        month: "long",
        timeZone: "Africa/Dar_es_Salaam",
      })
    : null;

  return (
    <Link href={`/matches/${match.id}`} className="block group">
      <Card className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 p-5 bg-gradient-to-r from-paper via-wash/40 to-paper hover:border-ink/40 transition-all shadow-xs">
        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-2">
            <span className="inline-flex items-center gap-1.5 rounded-full bg-brand/10 border border-brand/20 px-2.5 py-0.5 text-[10px] font-black uppercase tracking-wider text-brand">
              <span className="h-1.5 w-1.5 rounded-full bg-brand animate-pulse" />
              Featured Next Match
            </span>
            {match.stadium?.name && (
              <span className="text-xs text-muted truncate">· {match.stadium.name}</span>
            )}
          </div>
          <div className="mt-2.5 flex items-center gap-3">
            <Crest name={match.homeTeam.name} size={32} />
            <span className="truncate font-black text-lg text-ink group-hover:text-brand transition-colors">
              {match.homeTeam.name}
            </span>
            <span className="text-sm font-bold text-muted/50 px-1">vs</span>
            <Crest name={match.awayTeam.name} size={32} />
            <span className="truncate font-black text-lg text-ink group-hover:text-brand transition-colors">
              {match.awayTeam.name}
            </span>
          </div>
        </div>
        <div className="shrink-0 text-left sm:text-right border-t sm:border-t-0 pt-2 sm:pt-0 border-line/60">
          <p className="stat-figure text-2xl text-ink font-black">{time ?? "—"}</p>
          <p className="mt-0.5 text-xs font-semibold text-muted">{day}</p>
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

  const scope = await resolveScope(one(sp.competitionId), editionParam, editions);
  const editionId = scope.editionId ?? context.editionId;
  const edition = editions.find((e) => e.editionId === editionId);
  if (!editionId) return <Empty>No published season to show yet.</Empty>;

  const rounds = await api.rounds(editionId);
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

  const upcoming =
    context.inSeason && context.nextMatchDate
      ? await api.matches({ editionId, from: `${today}T00:00:00Z`, order: "asc", limit: 1 })
      : { matches: [] as (typeof list)["matches"] };

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
          <ScopeSelect
            competitions={scope.competitions}
            competitionId={scope.competitionId}
            seasons={seasonChoices}
            value={String(editionId)}
            clears={["date", "round"]}
          />
        }
      />

      {upcoming.matches[0] ? (
        <div className="mb-6">
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

      <div className="mt-6 space-y-2">
        {mode === "round" && rounds.withoutRound > 0 ? (
          <DataNote>
            {rounds.withoutRound} of this season&rsquo;s matches carry no round number in any
            source, so the rounds above are missing some fixtures. Every match is reachable by date.
          </DataNote>
        ) : null}
        {!rounds.hasRounds ? (
          <DataNote>
            No source publishes round numbers for {edition?.season}, so this season is browsed by
            date.
          </DataNote>
        ) : null}
      </div>
    </div>
  );
}
