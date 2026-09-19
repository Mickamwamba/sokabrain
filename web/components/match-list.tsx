import Link from "next/link";
import { type Match } from "@/lib/api";
import { Card, Crest } from "@/components/ui";

export function dayLabel(iso: string) {
  const d = new Date(`${iso}T12:00:00Z`);
  const today = new Date();
  const todayIso = today.toISOString().slice(0, 10);
  const tomorrow = new Date(today.getTime() + 86_400_000).toISOString().slice(0, 10);
  const yesterday = new Date(today.getTime() - 86_400_000).toISOString().slice(0, 10);
  const long = d.toLocaleDateString("en-GB", {
    weekday: "short",
    day: "numeric",
    month: "long",
    year: "numeric",
  });
  if (iso === todayIso) return `Today · ${long}`;
  if (iso === tomorrow) return `Tomorrow · ${long}`;
  if (iso === yesterday) return `Yesterday · ${long}`;
  return long;
}

export function kickoffTime(iso: string | null) {
  if (!iso) return null;
  return new Date(iso).toLocaleTimeString("en-GB", {
    hour: "2-digit",
    minute: "2-digit",
    timeZone: "Africa/Dar_es_Salaam",
  });
}

function dayKeyOf(m: Match) {
  if (!m.kickoffAt) return "unknown";
  return new Date(m.kickoffAt).toLocaleDateString("en-CA", { timeZone: "Africa/Dar_es_Salaam" });
}

function Score({ match }: { match: Match }) {
  const { home, away, homePenalties, awayPenalties } = match.score;
  if (home === null || away === null) {
    const time = kickoffTime(match.kickoffAt);
    if (match.status === "SCHEDULED" && time) {
      return (
        <span className="nums inline-flex items-center gap-1 rounded-full border border-line bg-wash/90 px-3 py-1 text-xs font-bold text-ink shadow-2xs">
          <span className="h-1.5 w-1.5 rounded-full bg-brand" />
          {time}
        </span>
      );
    }
    return (
      <span className="rounded-full bg-wash px-2.5 py-1 text-xs font-medium text-muted">
        {match.status === "FULL_TIME" ? "No score" : match.status.replace("_", " ").toLowerCase()}
      </span>
    );
  }

  const homeWon = home > away;
  const awayWon = away > home;

  return (
    <span className="stat-figure inline-flex items-center whitespace-nowrap rounded-lg bg-ink px-3 py-1 text-sm font-black text-white shadow-xs">
      <span className={homeWon ? "text-gold font-extrabold" : home < away ? "text-white/60" : "text-white"}>
        {home}
      </span>
      <span className="mx-1 text-white/40">‑</span>
      <span className={awayWon ? "text-gold font-extrabold" : away < home ? "text-white/60" : "text-white"}>
        {away}
      </span>
      {homePenalties !== null && awayPenalties !== null ? (
        <span className="ml-1.5 text-[10px] font-medium text-white/70">
          ({homePenalties}‑{awayPenalties}p)
        </span>
      ) : null}
    </span>
  );
}

export function MatchRows({
  matches,
  showCompetition = false,
}: {
  matches: Match[];
  showCompetition?: boolean;
}) {
  return (
    <Card className="overflow-hidden">
      <ul className="divide-y divide-line/60">
        {matches.map((m) => (
          <li key={m.id}>
            <Link
              href={`/matches/${m.id}`}
              className="group flex items-center gap-3 px-4 py-3.5 text-sm transition-all hover:bg-wash/70"
            >
              {/* Home Team */}
              <span className="flex min-w-0 flex-1 items-center justify-end gap-2.5">
                <span className="truncate font-bold text-ink group-hover:text-brand transition-colors text-right">
                  {m.homeTeam.name}
                </span>
                <Crest name={m.homeTeam.name} size={28} />
              </span>

              {/* Score / Time Centerpiece */}
              <span className="w-28 shrink-0 text-center">
                <Score match={m} />
              </span>

              {/* Away Team */}
              <span className="flex min-w-0 flex-1 items-center gap-2.5">
                <Crest name={m.awayTeam.name} size={28} />
                <span className="truncate font-bold text-ink group-hover:text-brand transition-colors text-left">
                  {m.awayTeam.name}
                </span>
              </span>

              {/* Stadium or Competition Note */}
              <span className="hidden w-44 shrink-0 truncate text-right text-xs text-muted lg:block">
                {showCompetition ? m.competition.name : m.stadium?.name ?? ""}
              </span>

              <span className="text-muted/40 group-hover:text-ink/70 transition-colors shrink-0 text-xs">
                →
              </span>
            </Link>
          </li>
        ))}
      </ul>
    </Card>
  );
}

export function MatchDays({
  matches,
  showCompetition = false,
}: {
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
    <div className="space-y-6">
      {[...days.entries()].map(([key, list]) => (
        <div key={key}>
          <div className="flex items-center gap-2 mb-2 px-1">
            <h2 className="display text-xs font-bold uppercase tracking-wider text-muted">
              {key === "unknown" ? "Date unknown" : dayLabel(key)}
            </h2>
            <span className="h-px flex-1 bg-line/60" />
            <span className="text-[11px] font-semibold text-muted">
              {list.length} {list.length === 1 ? "match" : "matches"}
            </span>
          </div>
          <MatchRows matches={list} showCompetition={showCompetition} />
        </div>
      ))}
    </div>
  );
}

const STAGE_ORDER = ["ROUND OF 16", "QUARTER FINAL", "SEMI FINAL", "THIRD PLACE", "FINAL"];

function stageOf(m: Match) {
  if (m.group) return { key: `G:${m.group.name}`, label: `Group ${m.group.name}`, rank: -1 };
  const round = (m.round ?? "").toUpperCase();
  if (!round) return { key: "none", label: "Stage unknown", rank: 99 };
  const rank = STAGE_ORDER.indexOf(round);
  const label = round
    .toLowerCase()
    .split(" ")
    .map((w, i) => (i > 0 && (w === "of" || w === "the") ? w : w.charAt(0).toUpperCase() + w.slice(1)))
    .join(" ");
  return { key: round, label, rank: rank === -1 ? 98 : rank };
}

export function MatchStages({
  matches,
  showCompetition = false,
}: {
  matches: Match[];
  showCompetition?: boolean;
}) {
  const stages = new Map<string, { label: string; rank: number; list: Match[] }>();
  for (const m of matches) {
    const s = stageOf(m);
    const hit = stages.get(s.key);
    if (hit) hit.list.push(m);
    else stages.set(s.key, { label: s.label, rank: s.rank, list: [m] });
  }
  const ordered = [...stages.values()].sort(
    (a, b) => a.rank - b.rank || a.label.localeCompare(b.label),
  );
  return (
    <div className="space-y-6">
      {ordered.map((s) => (
        <div key={s.label}>
          <div className="flex items-center gap-2 mb-2 px-1">
            <h2 className="display text-xs font-bold uppercase tracking-wider text-muted">
              {s.label}
            </h2>
            <span className="h-px flex-1 bg-line/60" />
          </div>
          <MatchRows matches={s.list} showCompetition={showCompetition} />
        </div>
      ))}
    </div>
  );
}
