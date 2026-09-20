import type { Edition, Match } from "@/lib/api";

/**
 * What the home page shows, now that the site carries six competitions.
 *
 * The home page is the ONLY public page with no competition or season picker.
 * Its axis is the date: whatever is being played today, across every published
 * competition. Scoping lives on Table and Statistics, where a question like
 * "who is top scorer" is meaningless without naming a competition.
 *
 * That is also why round browsing is gone from here. A round number identifies
 * a matchday within one league; across six of them at once it identifies
 * nothing.
 */

/**
 * The competition whose table and scorers appear beside the fixtures.
 *
 * Tanzania's Premier League: the home market, and by a distance the deepest
 * data in the vault — nineteen seasons against one to three for the rest. If it
 * ever has no published edition the companion column is simply omitted rather
 * than falling back to an arbitrary league.
 */
export const FEATURED_COMPETITION_ID = 1;

/**
 * Competition order within a single day's fixtures.
 *
 * Alphabetical would open the page on Kenya and bury Tanzania in the middle,
 * which is the wrong first impression for this audience. Listed competitions
 * come first in this order; everything else follows alphabetically, so a
 * competition added later still appears without anyone editing this list.
 */
const PRIORITY: number[] = [FEATURED_COMPETITION_ID];

export function competitionRank(id: number | null): number {
  if (id === null) return PRIORITY.length;
  const i = PRIORITY.indexOf(id);
  return i === -1 ? PRIORITY.length : i;
}

export type CompetitionGroup = {
  id: number | null;
  name: string;
  editionId: number | null;
  matches: Match[];
};

/**
 * Group one day's fixtures by competition, in display order.
 *
 * Matches arrive sorted by kickoff. Grouping preserves that within a
 * competition, so each block still reads earliest-first.
 */
export function groupByCompetition(matches: Match[]): CompetitionGroup[] {
  const groups = new Map<string, CompetitionGroup>();
  for (const m of matches) {
    const id = m.competition.id ?? null;
    const key = String(id ?? `edition:${m.competition.editionId}`);
    const existing = groups.get(key);
    if (existing) existing.matches.push(m);
    else
      groups.set(key, {
        id,
        name: m.competition.name ?? "Other",
        editionId: m.competition.editionId,
        matches: [m],
      });
  }
  return [...groups.values()].sort(
    (a, b) => competitionRank(a.id) - competitionRank(b.id) || a.name.localeCompare(b.name),
  );
}

/** The featured competition's most recent published season, if it has one. */
export function featuredEdition(editions: Edition[]): Edition | undefined {
  return editions
    .filter((e) => e.competitionId === FEATURED_COMPETITION_ID)
    .sort((a, b) => b.season.localeCompare(a.season))[0];
}
