"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

/**
 * The clock on a live match, ticking in the browser.
 *
 * The server renders a minute the sync captured up to two minutes ago, so left
 * alone it sits frozen on the page. This advances it from `at` — the moment the
 * clock was last seen RUNNING — so the displayed minute stays true between
 * syncs without polling for it.
 *
 * Three rules it follows, each of which would otherwise show a lie:
 *
 * * **`at` is null means the clock is stopped**, which for a live match means a
 *   break. It shows HT rather than advancing through half time.
 * * **A stale anchor is not extrapolated.** If the sync has not been heard from
 *   in a while the minute stops rather than running away — a page left open
 *   overnight must not claim the 400th minute.
 * * **The first client render matches the server's**, so hydration is clean:
 *   the interpolated value is only applied from an effect.
 */

/** Beyond this, the anchor is too old to trust and the clock holds still. */
const STALE_AFTER_MIN = 15;

export function LiveMinute({
  minute,
  at,
  className = "",
}: {
  minute: number | null;
  /** ISO timestamp the minute was captured with the clock running, or null. */
  at: string | null;
  className?: string;
}) {
  const [shown, setShown] = useState<number | null>(minute);

  useEffect(() => {
    if (at == null || minute == null) {
      setShown(minute);
      return;
    }
    const anchor = new Date(at).getTime();
    const tick = () => {
      const elapsed = Math.floor((Date.now() - anchor) / 60_000);
      setShown(minute + Math.min(Math.max(elapsed, 0), STALE_AFTER_MIN));
    };
    tick();
    // Ten seconds: fine-grained enough that the minute turns over within ten
    // seconds of the truth, cheap enough to leave running on a matchday.
    const id = setInterval(tick, 10_000);
    return () => clearInterval(id);
  }, [minute, at]);

  if (minute == null) return <span className={className}>Live</span>;
  if (at == null) return <span className={className}>HT</span>;
  return (
    <span className={className}>
      {shown}
      <span aria-hidden>&apos;</span>
    </span>
  );
}

/**
 * Pulls fresh data while a live match is on the page.
 *
 * `LiveMinute` keeps the clock honest on its own, but the score, the status and
 * the goal list all come from the server. Without this a goal would not appear
 * until someone reloaded.
 *
 * Render it only when the page actually holds a live match — an idle tab should
 * not be refetching a fixture list from last March.
 */
export function LiveRefresher({ everyMs = 60_000 }: { everyMs?: number }) {
  const router = useRouter();
  useEffect(() => {
    const id = setInterval(() => router.refresh(), everyMs);
    return () => clearInterval(id);
  }, [router, everyMs]);
  return null;
}
