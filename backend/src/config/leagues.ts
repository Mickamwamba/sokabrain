/**
 * The league set the live-score job syncs.
 *
 * API-Football league ids are NOT hardcoded here — they are discovered by
 * `npm run af:coverage` and stored as `entity_source_map` rows, because the
 * whole point of starting on the free tier is to find out what is actually
 * covered before committing. This file only names what we *want*, in the
 * country-agnostic terms the schema uses (design principle 4).
 */
export type TargetLeague = {
  /** Country name as API-Football spells it. */
  country: string;
  /** Substring matched case-insensitively against the API's league name. */
  nameContains: string;
  /** Season to sync, as API-Football numbers them (start year). */
  season: number;
};

export const TARGET_LEAGUES: TargetLeague[] = [
  { country: 'Tanzania', nameContains: 'Premier', season: 2025 },
  { country: 'Kenya', nameContains: 'Premier', season: 2025 },
];
