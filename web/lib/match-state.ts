/**
 * What state a match is in, for display.
 *
 * Every renderer here used to decide this the same wrong way — "does it have a
 * score?" — which was fine while nothing in the vault was ever in play. The
 * live-score sync changed that, and the first genuinely LIVE match to reach the
 * site rendered with a **Full Time** badge at 0-0 in the first half, and sat in
 * the fixture list looking identical to a finished game.
 *
 * A score is not evidence a match has ended. Status is.
 */
export type MatchState =
  /** Not kicked off yet. */
  | "UPCOMING"
  /** In play, including half time — the score is real but not final. */
  | "LIVE"
  /** Played out; the score is final. */
  | "FINISHED"
  /** Postponed, cancelled or abandoned: there is no result to show. */
  | "OFF";

const NOT_PLAYED = new Set(["POSTPONED", "CANCELLED", "ABANDONED"]);

export function matchState(
  status: string,
  homeScore: number | null,
  awayScore: number | null,
): MatchState {
  if (status === "LIVE") return "LIVE";
  if (NOT_PLAYED.has(status)) return "OFF";
  // A score is what separates a finished match from a fixture. Status alone is
  // not enough: the vault holds FULL_TIME matches whose score no source has.
  return homeScore !== null && awayScore !== null ? "FINISHED" : "UPCOMING";
}

/**
 * Whether a score should be shown at all.
 *
 * True while live as well as after, because a live score is the whole point —
 * it just must not be labelled final.
 */
export const showsScore = (s: MatchState) => s === "LIVE" || s === "FINISHED";

/** A human label for a status the site has no richer treatment for. */
export function statusLabel(status: string): string {
  return status.replace(/_/g, " ").toLowerCase();
}
