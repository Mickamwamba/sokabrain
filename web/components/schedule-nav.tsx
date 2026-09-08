import Link from "next/link";
import { type DayCount, type RoundSummary } from "@/lib/api";

/**
 * The two ways into a fixture list: by day, or by round.
 *
 * Both are plain links rather than a client-side control, so a chosen day or
 * round is a real URL a fan can share or bookmark, and the page still works
 * with no JavaScript.
 *
 * The date strip lists only days that actually have football. This league plays
 * in bursts across a weekend, so a literal calendar would be mostly empty cells
 * and the fan would have to hunt for the next fixture.
 */

function shortDay(iso: string) {
  const d = new Date(`${iso}T12:00:00Z`);
  return {
    dow: d.toLocaleDateString("en-GB", { weekday: "short" }),
    day: d.toLocaleDateString("en-GB", { day: "numeric", month: "short" }),
  };
}

export function DateStrip({ days, active, hrefFor }: {
  days: DayCount[];
  active: string | null;
  hrefFor: (date: string) => string;
}) {
  if (days.length === 0) return null;
  const todayIso = new Date().toLocaleDateString("en-CA", { timeZone: "Africa/Dar_es_Salaam" });
  return (
    <div className="-mx-4 overflow-x-auto px-4 pb-1">
      <div className="flex min-w-max gap-1.5">
        {days.map((d) => {
          const { dow, day } = shortDay(d.date);
          const isActive = d.date === active;
          const isToday = d.date === todayIso;
          return (
            <Link
              key={d.date}
              href={hrefFor(d.date)}
              aria-current={isActive ? "date" : undefined}
              className={[
                "flex w-[74px] shrink-0 flex-col items-center rounded-xl border px-2 py-2 transition-colors",
                isActive
                  ? "border-ink bg-ink text-white"
                  : "border-line bg-paper hover:border-ink",
              ].join(" ")}
            >
              <span className={`text-[10px] font-semibold uppercase tracking-wide ${isActive ? "text-white/70" : "text-muted"}`}>
                {isToday ? "Today" : dow}
              </span>
              <span className="nums text-sm font-semibold">{day}</span>
              <span className={`text-[10px] ${isActive ? "text-white/70" : "text-muted"}`}>
                {d.matches} {d.matches === 1 ? "match" : "matches"}
              </span>
            </Link>
          );
        })}
      </div>
    </div>
  );
}

export function RoundStrip({ rounds, active, hrefFor }: {
  rounds: RoundSummary[];
  active: string | null;
  hrefFor: (round: string) => string;
}) {
  if (rounds.length === 0) return null;
  return (
    <div className="-mx-4 overflow-x-auto px-4 pb-1">
      <div className="flex min-w-max gap-1.5">
        {rounds.map((r) => {
          const isActive = r.round === active;
          const complete = r.played === r.matches;
          return (
            <Link
              key={r.round}
              href={hrefFor(r.round)}
              aria-current={isActive ? "true" : undefined}
              className={[
                "flex w-[86px] shrink-0 flex-col items-center rounded-xl border px-2 py-2 transition-colors",
                isActive ? "border-ink bg-ink text-white" : "border-line bg-paper hover:border-ink",
              ].join(" ")}
            >
              <span className={`text-[10px] font-semibold uppercase tracking-wide ${isActive ? "text-white/70" : "text-muted"}`}>
                Round
              </span>
              <span className="nums text-sm font-semibold">{r.round}</span>
              <span className={`text-[10px] ${isActive ? "text-white/70" : "text-muted"}`}>
                {complete ? `${r.matches} played` : `${r.played}/${r.matches}`}
              </span>
            </Link>
          );
        })}
      </div>
    </div>
  );
}

/** Switches the fixture list between day and round browsing. */
export function ModeTabs({ mode, byDateHref, byRoundHref, roundsAvailable }: {
  mode: "date" | "round";
  byDateHref: string;
  byRoundHref: string;
  roundsAvailable: boolean;
}) {
  const base = "rounded-full px-3.5 py-1.5 text-xs font-semibold transition-colors";
  return (
    <div className="flex items-center gap-1.5">
      <Link href={byDateHref} className={`${base} ${mode === "date" ? "bg-ink text-white" : "border border-line bg-paper hover:border-ink"}`}>
        By date
      </Link>
      {roundsAvailable ? (
        <Link href={byRoundHref} className={`${base} ${mode === "round" ? "bg-ink text-white" : "border border-line bg-paper hover:border-ink"}`}>
          By round
        </Link>
      ) : (
        <span
          className={`${base} cursor-not-allowed border border-line bg-wash text-muted`}
          title="No source publishes round numbers for this season, so nothing is invented"
        >
          By round
        </span>
      )}
    </div>
  );
}
