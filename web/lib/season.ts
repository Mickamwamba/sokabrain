import { api } from "@/lib/api";

/** The URL value that means "not one season — the whole archive". */
export const ALL_TIME = "all";

export type ResolvedSeason = {
  /** Undefined when showing all time, so it can be passed straight to the API. */
  editionId: number | undefined;
  /** What the selector should show as chosen. */
  value: string;
  allTime: boolean;
};

/**
 * Turn the `editionId` query param into the season a page should show.
 *
 * Absent means "the season in play", not "everything": a fan opening a stats
 * page wants this year first. All time is reachable, but only by asking for it,
 * so the page always knows which of the two it is showing and can say so.
 */
export async function resolveSeason(param: string | undefined): Promise<ResolvedSeason> {
  if (param === ALL_TIME) return { editionId: undefined, value: ALL_TIME, allTime: true };
  if (param && Number.isFinite(Number(param))) {
    return { editionId: Number(param), value: param, allTime: false };
  }
  const ctx = await api.context();
  if (ctx.editionId === null) return { editionId: undefined, value: ALL_TIME, allTime: true };
  return { editionId: ctx.editionId, value: String(ctx.editionId), allTime: false };
}
