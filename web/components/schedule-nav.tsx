import Link from "next/link";
import { type DayCount, type RoundSummary } from "@/lib/api";

function formatDay(iso: string) {
  const d = new Date(`${iso}T12:00:00Z`);
  return {
    dow: d.toLocaleDateString("en-GB", { weekday: "short" }),
    dayNum: d.toLocaleDateString("en-GB", { day: "numeric" }),
    month: d.toLocaleDateString("en-GB", { month: "short" }),
  };
}

export function DateStrip({
  days,
  active,
  hrefFor,
}: {
  days: DayCount[];
  active: string | null;
  hrefFor: (date: string) => string;
}) {
  if (days.length === 0) return null;
  const todayIso = new Date().toLocaleDateString("en-CA", { timeZone: "Africa/Dar_es_Salaam" });

  return (
    <div className="relative">
      <div className="-mx-4 overflow-x-auto px-4 pb-1 pt-0.5 scrollbar-none">
        <div className="flex min-w-max gap-1.5 py-0.5 items-center">
          {days.map((d) => {
            const { dow, dayNum } = formatDay(d.date);
            const isActive = d.date === active;
            const isToday = d.date === todayIso;
            const hasMatches = d.matches > 0;

            return (
              <Link
                key={d.date}
                href={hrefFor(d.date)}
                aria-current={isActive ? "date" : undefined}
                className={`relative flex min-w-[56px] sm:min-w-[62px] flex-col items-center justify-center rounded-xl px-2 py-1.5 transition-all text-center ${
                  isActive
                    ? "bg-ink text-white shadow-sm ring-2 ring-ink/20 font-bold"
                    : isToday
                    ? "border border-brand/50 bg-brand/5 text-ink hover:bg-brand/10"
                    : "border border-line/70 bg-paper text-ink hover:border-ink/40 hover:bg-wash"
                }`}
              >
                {/* Day of week */}
                <span
                  className={`text-[10px] font-bold uppercase tracking-wider leading-none ${
                    isActive
                      ? "text-white/80"
                      : isToday
                      ? "text-brand font-black"
                      : "text-muted"
                  }`}
                >
                  {isToday ? "Today" : dow}
                </span>

                {/* Day number */}
                <span className="nums text-base font-black leading-tight mt-0.5">
                  {dayNum}
                </span>

                {/* Match indicator dot */}
                <div className="mt-0.5 flex items-center justify-center h-2">
                  {hasMatches ? (
                    <span
                      className={`h-1.5 w-1.5 rounded-full ${
                        isActive
                          ? "bg-brand-light"
                          : isToday
                          ? "bg-brand animate-pulse"
                          : "bg-ink/50"
                      }`}
                      title={`${d.matches} ${d.matches === 1 ? "match" : "matches"}`}
                    />
                  ) : (
                    <span className="h-1.5 w-1.5 rounded-full bg-transparent" />
                  )}
                </div>
              </Link>
            );
          })}
        </div>
      </div>
    </div>
  );
}

export function RoundStrip({
  rounds,
  active,
  hrefFor,
}: {
  rounds: RoundSummary[];
  active: string | null;
  hrefFor: (round: string) => string;
}) {
  if (rounds.length === 0) return null;
  return (
    <div className="-mx-4 overflow-x-auto px-4 pb-1 scrollbar-none">
      <div className="flex min-w-max gap-1.5 py-0.5">
        {rounds.map((r) => {
          const isActive = r.round === active;
          const complete = r.played === r.matches;
          return (
            <Link
              key={r.round}
              href={hrefFor(r.round)}
              aria-current={isActive ? "true" : undefined}
              className={`flex min-w-[70px] sm:min-w-[76px] flex-col items-center rounded-xl px-2 py-1.5 transition-all text-center ${
                isActive
                  ? "bg-ink text-white shadow-sm ring-2 ring-ink/20 font-bold"
                  : "border border-line/70 bg-paper text-ink hover:border-ink/40 hover:bg-wash"
              }`}
            >
              <span
                className={`text-[9px] font-bold uppercase tracking-wider leading-none ${
                  isActive ? "text-white/80" : "text-muted"
                }`}
              >
                Round
              </span>
              <span className="nums text-base font-black leading-tight mt-0.5">
                {r.round}
              </span>
              <span
                className={`text-[9px] font-medium leading-none mt-0.5 ${
                  isActive ? "text-white/70" : "text-muted"
                }`}
              >
                {complete ? `${r.matches} pl` : `${r.played}/${r.matches}`}
              </span>
            </Link>
          );
        })}
      </div>
    </div>
  );
}

export function ModeTabs({
  mode,
  byDateHref,
  byRoundHref,
  roundsAvailable,
  todayHref,
}: {
  mode: "date" | "round";
  byDateHref: string;
  byRoundHref: string;
  roundsAvailable: boolean;
  todayHref?: string;
}) {
  return (
    <div className="flex items-center justify-between gap-2">
      <div className="inline-flex rounded-xl border border-line bg-paper p-0.5 text-xs font-semibold shadow-2xs">
        <Link
          href={byDateHref}
          className={`rounded-lg px-3 py-1 transition-all ${
            mode === "date"
              ? "bg-ink text-white shadow-xs"
              : "text-muted hover:text-ink"
          }`}
        >
          By date
        </Link>
        {roundsAvailable ? (
          <Link
            href={byRoundHref}
            className={`rounded-lg px-3 py-1 transition-all ${
              mode === "round"
                ? "bg-ink text-white shadow-xs"
                : "text-muted hover:text-ink"
            }`}
          >
            By round
          </Link>
        ) : (
          <span
            className="rounded-lg px-3 py-1 text-muted/50 cursor-not-allowed"
            title="No source publishes round numbers for this season"
          >
            By round
          </span>
        )}
      </div>

      {todayHref && mode === "date" && (
        <Link
          href={todayHref}
          className="inline-flex items-center gap-1.5 rounded-xl border border-line bg-paper px-2.5 py-1 text-xs font-bold text-ink hover:bg-wash transition-colors shadow-2xs"
        >
          <span className="h-1.5 w-1.5 rounded-full bg-brand" />
          <span>Jump to Today</span>
        </Link>
      )}
    </div>
  );
}
