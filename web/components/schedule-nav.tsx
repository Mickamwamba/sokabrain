import Link from "next/link";
import { type DayCount, type RoundSummary } from "@/lib/api";

function shortDay(iso: string) {
  const d = new Date(`${iso}T12:00:00Z`);
  return {
    dow: d.toLocaleDateString("en-GB", { weekday: "short" }),
    day: d.toLocaleDateString("en-GB", { day: "numeric", month: "short" }),
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
    <div className="-mx-4 overflow-x-auto px-4 pb-2 scrollbar-none">
      <div className="flex min-w-max gap-2 py-0.5">
        {days.map((d) => {
          const { dow, day } = shortDay(d.date);
          const isActive = d.date === active;
          const isToday = d.date === todayIso;
          return (
            <Link
              key={d.date}
              href={hrefFor(d.date)}
              aria-current={isActive ? "date" : undefined}
              className={`flex w-[82px] shrink-0 flex-col items-center rounded-xl border px-2 py-2.5 transition-all ${
                isActive
                  ? "border-ink bg-ink text-white shadow-md scale-[1.02]"
                  : isToday
                  ? "border-brand bg-brand/5 text-ink hover:border-brand-dark hover:bg-brand/10"
                  : "border-line bg-paper text-ink hover:border-ink/50 hover:bg-wash"
              }`}
            >
              <div className="flex items-center gap-1">
                {isToday && (
                  <span className="h-1.5 w-1.5 rounded-full bg-brand animate-pulse" />
                )}
                <span
                  className={`text-[10px] font-bold uppercase tracking-wider ${
                    isActive ? "text-white/75" : isToday ? "text-brand font-black" : "text-muted"
                  }`}
                >
                  {isToday ? "Today" : dow}
                </span>
              </div>
              <span className="nums text-sm font-extrabold mt-0.5">{day}</span>
              <span
                className={`text-[10px] font-medium mt-0.5 ${
                  isActive ? "text-white/70" : "text-muted"
                }`}
              >
                {d.matches} {d.matches === 1 ? "match" : "matches"}
              </span>
            </Link>
          );
        })}
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
    <div className="-mx-4 overflow-x-auto px-4 pb-2 scrollbar-none">
      <div className="flex min-w-max gap-2 py-0.5">
        {rounds.map((r) => {
          const isActive = r.round === active;
          const complete = r.played === r.matches;
          return (
            <Link
              key={r.round}
              href={hrefFor(r.round)}
              aria-current={isActive ? "true" : undefined}
              className={`flex w-[92px] shrink-0 flex-col items-center rounded-xl border px-2 py-2.5 transition-all ${
                isActive
                  ? "border-ink bg-ink text-white shadow-md scale-[1.02]"
                  : "border-line bg-paper text-ink hover:border-ink/50 hover:bg-wash"
              }`}
            >
              <span
                className={`text-[10px] font-bold uppercase tracking-wider ${
                  isActive ? "text-white/75" : "text-muted"
                }`}
              >
                Round
              </span>
              <span className="nums text-sm font-extrabold mt-0.5">{r.round}</span>
              <span
                className={`text-[10px] font-medium mt-0.5 ${
                  isActive ? "text-white/70" : "text-muted"
                }`}
              >
                {complete ? `${r.matches} played` : `${r.played}/${r.matches}`}
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
}: {
  mode: "date" | "round";
  byDateHref: string;
  byRoundHref: string;
  roundsAvailable: boolean;
}) {
  return (
    <div className="mb-3 inline-flex rounded-lg border border-line bg-paper p-0.5 text-xs font-semibold shadow-2xs">
      <Link
        href={byDateHref}
        className={`rounded-md px-3.5 py-1.5 transition-all ${
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
          className={`rounded-md px-3.5 py-1.5 transition-all ${
            mode === "round"
              ? "bg-ink text-white shadow-xs"
              : "text-muted hover:text-ink"
          }`}
        >
          By round
        </Link>
      ) : (
        <span
          className="rounded-md px-3.5 py-1.5 text-muted/50 cursor-not-allowed"
          title="No source publishes round numbers for this season"
        >
          By round
        </span>
      )}
    </div>
  );
}
