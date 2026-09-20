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
 * Only Tanzania's Premier League exists in the vault today (competition 1); the
 * other four are covered by the subscription but have no vault competition yet,
 * so their fixtures are reported and skipped rather than written into the wrong
 * competition. Add a row here when a competition is created for one.
 */
export const VAULT_COMPETITION_BY_PROVIDER_LEAGUE: Record<string, number> = {
  '884': 1, // SportMonks "Ligi kuu Bara" -> vault Premier League (Tanzania)
};
