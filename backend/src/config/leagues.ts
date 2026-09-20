/**
 * The league set the live-score job syncs.
 *
 * Provider league ids are NOT hardcoded here — they are discovered (`npm run
 * sm:coverage`) and stored as `entity_source_map` rows, because what a provider
 * actually covers has to be established rather than assumed. This file only
 * names what we *want*, in the country-agnostic terms the schema uses (design
 * principle 4).
 *
 * SportMonks is the live provider: it is the only one whose Tanzanian Premier
 * League event coverage could be verified before paying. The subscription grants
 * the top tier of these five countries and nothing else, so a league absent from
 * this list is absent from the plan too, not merely unwanted.
 */
export type TargetLeague = {
  /** Country name as the provider spells it. */
  country: string;
  /** Substring matched case-insensitively against the provider's league name. */
  nameContains: string;
  /**
   * Season to sync, as API-Football numbers them (start year).
   * SportMonks names seasons ("2026/2027") and publishes which is current, so it
   * reads that instead of this.
   */
  season: number;
};

export const TARGET_LEAGUES: TargetLeague[] = [
  { country: 'Tanzania', nameContains: 'Ligi kuu', season: 2026 },
  { country: 'Kenya', nameContains: 'Premier', season: 2026 },
  { country: 'Uganda', nameContains: 'Premier', season: 2026 },
  { country: 'Rwanda', nameContains: 'National Soccer', season: 2026 },
  { country: 'South Africa', nameContains: 'Premier', season: 2026 },
];

/**
 * The vault competition each target league belongs to, by provider league id.
 *
 * A league absent from this map is fetched and reported but never written, so
 * that a fixture cannot land in the wrong competition. All five of the plan's
 * leagues are now mapped (`npm run sm:ingest` stood the last four up on
 * 2026-09-19); Kenya reuses the competition the legacy SokaFC dump already held
 * rather than a second one beside it.
 */
export const VAULT_COMPETITION_BY_PROVIDER_LEAGUE: Record<string, number> = {
  '884': 1, //   "Ligi kuu Bara"          -> Premier League, Tanzania
  '848': 17, //  Kenya "Premier League"   -> "Kenya premier league" (legacy record)
  '872': 126, // Rwanda "National Soccer League"
  '806': 127, // South Africa "Premier League"
  '1423': 128, // Uganda "Premier League"
};
