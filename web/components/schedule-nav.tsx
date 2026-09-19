"use client";

import { useEffect, useRef } from "react";
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

export type DayItem = DayCount & { href: string };

export function DateStrip({
  days,
  active,
}: {
  days: DayItem[];
  active: string | null;
}) {
  const containerRef = useRef<HTMLDivElement>(null);
  const isFirstRender = useRef(true);

  // Smoothly center the active date in the strip
  useEffect(() => {
    if (!active || !containerRef.current) return;
    const target = containerRef.current.querySelector(
      `[data-date="${active}"]`
    ) as HTMLElement | null;

    if (target) {
      target.scrollIntoView({
        behavior: isFirstRender.current ? "auto" : "smooth",
        inline: "center",
        block: "nearest",
      });
      isFirstRender.current = false;
    }
  }, [active]);

  const handlePillClick = (e: React.MouseEvent<HTMLAnchorElement>) => {
    e.currentTarget.scrollIntoView({
      behavior: "smooth",
      inline: "center",
      block: "nearest",
    });
  };

  const scrollSide = (direction: "left" | "right") => {
    if (!containerRef.current) return;
    const offset = direction === "left" ? -220 : 220;
    containerRef.current.scrollBy({ left: offset, behavior: "smooth" });
  };

  if (days.length === 0) return null;
  const todayIso = new Date().toLocaleDateString("en-CA", { timeZone: "Africa/Dar_es_Salaam" });

  return (
    <div className="relative group/strip">
      {/* Left Scroll Button (visible on hover / desktop) */}
      <button
        onClick={() => scrollSide("left")}
        aria-label="Scroll dates left"
        className="hidden sm:flex absolute left-0 top-1/2 -translate-y-1/2 -translate-x-2 z-10 h-7 w-7 items-center justify-center rounded-full bg-paper/90 border border-line shadow-md text-ink hover:bg-wash transition-all opacity-0 group-hover/strip:opacity-100 cursor-pointer"
      >
        ‹
      </button>

      {/* Date Strip Container */}
      <div
        ref={containerRef}
        className="-mx-4 overflow-x-auto px-4 pb-1 pt-0.5 scrollbar-none scroll-smooth"
      >
        <div className="flex min-w-max gap-1.5 py-0.5 items-center">
          {days.map((d) => {
            const { dow, dayNum } = formatDay(d.date);
            const isActive = d.date === active;
            const isToday = d.date === todayIso;
            const hasMatches = d.matches > 0;

            return (
              <Link
                key={d.date}
                href={d.href}
                scroll={false}
                data-date={d.date}
                onClick={handlePillClick}
                aria-current={isActive ? "date" : undefined}
                className={`relative flex min-w-[56px] sm:min-w-[62px] flex-col items-center justify-center rounded-xl px-2 py-1.5 transition-all duration-200 text-center select-none ${
                  isActive
                    ? "bg-ink text-white shadow-sm ring-2 ring-ink/20 font-bold scale-[1.02]"
                    : isToday
                    ? "border border-brand/50 bg-brand/5 text-ink hover:bg-brand/10 hover:border-brand"
                    : "border border-line/70 bg-paper text-ink hover:border-ink/40 hover:bg-wash"
                }`}
              >
                {/* Day of week */}
                <span
                  className={`text-[10px] font-bold uppercase tracking-wider leading-none transition-colors ${
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
                      className={`h-1.5 w-1.5 rounded-full transition-colors ${
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

      {/* Right Scroll Button (visible on hover / desktop) */}
      <button
        onClick={() => scrollSide("right")}
        aria-label="Scroll dates right"
        className="hidden sm:flex absolute right-0 top-1/2 -translate-y-1/2 translate-x-2 z-10 h-7 w-7 items-center justify-center rounded-full bg-paper/90 border border-line shadow-md text-ink hover:bg-wash transition-all opacity-0 group-hover/strip:opacity-100 cursor-pointer"
      >
        ›
      </button>
    </div>
  );
}

export type RoundItem = RoundSummary & { href: string };

export function RoundStrip({
  rounds,
  active,
}: {
  rounds: RoundItem[];
  active: string | null;
}) {
  const containerRef = useRef<HTMLDivElement>(null);
  const isFirstRender = useRef(true);

  useEffect(() => {
    if (!active || !containerRef.current) return;
    const target = containerRef.current.querySelector(
      `[data-round="${active}"]`
    ) as HTMLElement | null;

    if (target) {
      target.scrollIntoView({
        behavior: isFirstRender.current ? "auto" : "smooth",
        inline: "center",
        block: "nearest",
      });
      isFirstRender.current = false;
    }
  }, [active]);

  const handlePillClick = (e: React.MouseEvent<HTMLAnchorElement>) => {
    e.currentTarget.scrollIntoView({
      behavior: "smooth",
      inline: "center",
      block: "nearest",
    });
  };

  const scrollSide = (direction: "left" | "right") => {
    if (!containerRef.current) return;
    const offset = direction === "left" ? -220 : 220;
    containerRef.current.scrollBy({ left: offset, behavior: "smooth" });
  };

  if (rounds.length === 0) return null;

  return (
    <div className="relative group/round-strip">
      {/* Left Scroll Button (desktop) */}
      <button
        onClick={() => scrollSide("left")}
        aria-label="Scroll rounds left"
        className="hidden sm:flex absolute left-0 top-1/2 -translate-y-1/2 -translate-x-2 z-10 h-7 w-7 items-center justify-center rounded-full bg-paper/90 border border-line shadow-md text-ink hover:bg-wash transition-all opacity-0 group-hover/round-strip:opacity-100 cursor-pointer"
      >
        ‹
      </button>

      {/* Round Strip Container */}
      <div
        ref={containerRef}
        className="-mx-4 overflow-x-auto px-4 pb-1 scrollbar-none scroll-smooth"
      >
        <div className="flex min-w-max gap-1.5 py-0.5 items-center">
          {rounds.map((r) => {
            const isActive = r.round === active;
            return (
              <Link
                key={r.round}
                href={r.href}
                scroll={false}
                data-round={r.round}
                onClick={handlePillClick}
                aria-current={isActive ? "true" : undefined}
                className={`relative inline-flex items-center gap-1.5 whitespace-nowrap rounded-xl px-3 py-1.5 transition-all duration-200 select-none text-xs ${
                  isActive
                    ? "bg-ink text-white shadow-sm ring-2 ring-ink/20 font-bold scale-[1.02]"
                    : "border border-line/70 bg-paper text-ink hover:border-ink/40 hover:bg-wash font-semibold"
                }`}
              >
                <span
                  className={`text-[11px] font-medium tracking-wide transition-colors ${
                    isActive ? "text-white/80" : "text-muted"
                  }`}
                >
                  Round
                </span>
                <span className="nums text-xs font-black">
                  {r.round}
                </span>
              </Link>
            );
          })}
        </div>
      </div>

      {/* Right Scroll Button (desktop) */}
      <button
        onClick={() => scrollSide("right")}
        aria-label="Scroll rounds right"
        className="hidden sm:flex absolute right-0 top-1/2 -translate-y-1/2 translate-x-2 z-10 h-7 w-7 items-center justify-center rounded-full bg-paper/90 border border-line shadow-md text-ink hover:bg-wash transition-all opacity-0 group-hover/round-strip:opacity-100 cursor-pointer"
      >
        ›
      </button>
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
          scroll={false}
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
            scroll={false}
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
          scroll={false}
          className="inline-flex items-center gap-1.5 rounded-xl border border-line bg-paper px-2.5 py-1 text-xs font-bold text-ink hover:bg-wash transition-colors shadow-2xs"
        >
          <span className="h-1.5 w-1.5 rounded-full bg-brand" />
          <span>Jump to Today</span>
        </Link>
      )}
    </div>
  );
}
