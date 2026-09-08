import Link from "next/link";
import { type Match } from "@/lib/api";
import { Card, Crest } from "@/components/ui";

/**
 * The fixture list, grouped the way a fan reads one: by day, in playing order.
 *
 * The row is a link to the match page, so the whole strip is a target rather
 * than a small "details" affordance — the match is the thing people want.
 */

export function dayLabel(iso: string) {
  const d = new Date(`${iso}T12:00:00Z`);
  const today = new Date();
  const todayIso = today.toISOString().slice(0, 10);
  const tomorrow = new Date(today.getTime() + 86_400_000).toISOString().slice(0, 10);
  const yesterday = new Date(today.getTime() - 86_400_000).toISOString().slice(0, 10);
  const long = d.toLocaleDateString("en-GB", {
    weekday: "short", day: "numeric", month: "long", year: "numeric",
  });
  if (iso === todayIso) return `Today · ${long}`;
  if (iso === tomorrow) return `Tomorrow · ${long}`;
  if (iso === yesterday) return `Yesterday · ${long}`;
  return long;
}

/** Kickoffs are stored UTC; fans read them in Tanzanian time. */
export function kickoffTime(iso: string | null) {
  if (!iso) return null;
  return new Date(iso).toLocaleTimeString("en-GB", {
    hour: "2-digit", minute: "2-digit", timeZone: "Africa/Dar_es_Salaam",
  });
}

function dayKeyOf(m: Match) {
  if (!m.kickoffAt) return "unknown";
  // Group by the Tanzanian calendar day, not the viewer's.
  return new Date(m.kickoffAt).toLocaleDateString("en-CA", { timeZone: "Africa/Dar_es_Salaam" });
}

function Score({ match }: { match: Match }) {
  const { home, away, homePenalties, awayPenalties } = match.score;
  if (home === null || away === null) {
    const time = kickoffTime(match.kickoffAt);
    if (match.status === "SCHEDULED" && time) {
      return <span className="nums rounded bg-wash px-2.5 py-1 text-xs font-semibold text-muted">{time}</span>;
    }
    return (
      <span className="rounded bg-wash px-2.5 py-1 text-xs font-medium text-muted">
        {match.status === "FULL_TIME" ? "No score" : match.status.replace("_", " ").toLowerCase()}
      </span>
    );
  }
  return (
    <span className="stat-figure whitespace-nowrap rounded bg-ink px-2.5 py-1 text-sm text-white">
      {home}‑{away}
      {homePenalties !== null && awayPenalties !== null ? (
        <span className="ml-1 text-[10px] font-normal text-white/70">
          ({homePenalties}‑{awayPenalties}p)
        </span>
      ) : null}
    </span>
  );
}

export function MatchRows({ matches, showCompetition = false }: {
  matches: Match[];
  showCompetition?: boolean;
}) {
  return (
    <Card className="overflow-hidden">
      <ul>
        {matches.map((m) => (
          <li key={m.id}>
            <Link
              href={`/matches/${m.id}`}
              className="flex items-center gap-3 border-b border-line px-4 py-3 text-sm transition-colors last:border-0 hover:bg-wash"
            >
              <span className="flex min-w-0 flex-1 items-center justify-end gap-2">
                <span className="truncate font-medium">{m.homeTeam.name}</span>
                <Crest name={m.homeTeam.name} size={24} />
              </span>
              <span className="w-24 shrink-0 text-center">
                <Score match={m} />
              </span>
              <span className="flex min-w-0 flex-1 items-center gap-2">
                <Crest name={m.awayTeam.name} size={24} />
                <span className="truncate font-medium">{m.awayTeam.name}</span>
              </span>
              <span className="hidden w-40 shrink-0 truncate text-right text-xs text-muted lg:block">
                {showCompetition ? m.competition.name : m.stadium?.name ?? ""}
              </span>
            </Link>
          </li>
        ))}
      </ul>
    </Card>
  );
}

export function MatchDays({ matches, showCompetition = false }: {
  matches: Match[];
  showCompetition?: boolean;
}) {
  const days = new Map<string, Match[]>();
  for (const m of matches) {
    const k = dayKeyOf(m);
    const list = days.get(k);
    if (list) list.push(m);
    else days.set(k, [m]);
  }
  return (
    <div className="space-y-5">
      {[...days.entries()].map(([key, list]) => (
        <div key={key}>
          <h2 className="display mb-2 text-xs font-bold uppercase tracking-wider text-muted">
            {key === "unknown" ? "Date unknown" : dayLabel(key)}
          </h2>
          <MatchRows matches={list} showCompetition={showCompetition} />
        </div>
      ))}
    </div>
  );
}
