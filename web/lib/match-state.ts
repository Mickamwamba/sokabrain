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

/**
 * The short badge under a finished match's score.
 *
 * A bare score does not say whether a game has been played. In a list mixing a
 * kickoff time, a live score and a final one, "2-1" alone reads the same
 * whether it is final or still moving, so a finished match says so.
 *
 * It distinguishes how the result was reached, because the vault stores that
 * and a cup tie decided in a shootout is not the same result as one won in
 * ninety minutes:
 *
 * * **PENS** — a shootout settled it. Checked first: a tie that went to
 *   penalties also has extra time, and the shootout is the more specific fact.
 * * **AET** — extra time was played and settled it.
 * * **FT** — the ordinary case.
 *
 * Only ever call this for a FINISHED match. A postponed or abandoned fixture
 * can carry a score too, and badging that "FT" would state it was played out.
 */
export function fullTimeLabel(score: {
  homeExtraTime?: number | null;
  awayExtraTime?: number | null;
  homePenalties?: number | null;
  awayPenalties?: number | null;
}): "FT" | "AET" | "PENS" {
  if (score.homePenalties != null && score.awayPenalties != null) return "PENS";
  if (score.homeExtraTime != null && score.awayExtraTime != null) return "AET";
  return "FT";
}
