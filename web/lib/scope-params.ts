/**
 * The part of scope resolution that needs nothing but the URL.
 *
 * It lives apart from `lib/scope.ts` because that module imports the API
 * client, and the Statistics tabs run on the client, where `process.env.API_URL`
 * does not exist. Splitting the pure part out lets both use one implementation
 * instead of each keeping its own idea of which competition is in view.
 */

/** The least an edition has to say for this to place it in a competition. */
export type EditionRef = { editionId: number; competitionId: number };

/**
 * Which competition the URL names: an explicit `competitionId`, else the
 * competition the named edition belongs to. Undefined when it names neither —
 * `resolveScope` then falls back to the season in play, which needs the API.
 */
export function competitionFromParams(
  competitionParam: string | undefined,
  editionParam: string | undefined,
  editions: readonly EditionRef[],
): number | undefined {
  const named = Number(competitionParam);
  if (competitionParam && editions.some((e) => e.competitionId === named)) return named;
  return editions.find((e) => String(e.editionId) === editionParam)?.competitionId;
}
