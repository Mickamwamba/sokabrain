import type { Edition } from "@/lib/api";

/**
 * Editions rolled up into the competitions they belong to.
 *
 * A browsing page is a list of competitions, not of seasons. Listing editions
 * meant the Premier League appeared nineteen times and AFCON thirteen, so the
 * first screenful was the same competition over and over and a fan looking for
 * "what is in here?" got an answer to a question they had not asked. The
 * season is a choice made *after* picking a competition, from the dropdown
 * every page carries.
 */

export type CompetitionSummary = {
  id: number;
  name: string;
  country: string | null;
  type: string;
  tier: number | null;
  /** How many seasons of it the vault has published. */
  seasons: number;
  /** "2008/09 to 2026/27", or a single season where there is only one. */
  span: string;
  matches: number;
};

/** The short form the season dropdown uses: 2008/2009 → 2008/09. */
export const shortSeason = (s: string) => s.replace("/20", "/");

export function summariseCompetitions(editions: Edition[]): CompetitionSummary[] {
  const byId = new Map<number, Edition[]>();
  for (const e of editions) {
    const list = byId.get(e.competitionId);
    if (list) list.push(e);
    else byId.set(e.competitionId, [e]);
  }

  return [...byId.values()]
    .map((list) => {
      const seasons = list.map((e) => e.season).sort();
      const first = shortSeason(seasons[0]);
      const last = shortSeason(seasons[seasons.length - 1]);
      const [head] = list;
      return {
        id: head.competitionId,
        name: head.competition,
        country: head.country,
        type: head.competitionType,
        tier: head.tier,
        seasons: list.length,
        span: first === last ? first : `${first} to ${last}`,
        matches: list.reduce((n, e) => n + e.matchCount, 0),
      };
    })
    .sort((a, b) => b.matches - a.matches);
}

/**
 * Where a competition card goes: the table, with no season named.
 *
 * Leaving `editionId` off is deliberate — `resolveScope` then lands on the
 * season in play, and the dropdown is there to move off it.
 */
export const competitionHref = (id: number) => `/table?competitionId=${id}`;
