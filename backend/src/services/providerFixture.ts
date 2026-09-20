/**
 * The provider-neutral fixture shape the sync consumes.
 *
 * `liveSync` holds this codebase's reconciliation rules (design principle 2) and
 * those rules must not be written twice. So a provider's job is to normalise its
 * own payload into this shape, and the sync never learns which provider it came
 * from beyond the `source` name it records for provenance (principle 1).
 *
 * Every field here is one the sync actually reads. A provider that cannot supply
 * one leaves it null rather than inventing a value (principle 6).
 */
export type ProviderTeam = {
  /** The provider's own id, stringified — this is the `entity_source_map` key. */
  id: string;
  name: string;
};

export type ProviderFixture = {
  /** The provider's fixture id, stringified. */
  id: string;
  /** Kickoff as an absolute instant. Providers publish UTC; keep it that way. */
  kickoff: Date;
  /** Already mapped onto the vault's `matches.status` values. */
  status: string;
  home: ProviderTeam;
  away: ProviderTeam;
  /** The published score. NEVER reconstructed from events — see liveSync. */
  homeScore: number | null;
  awayScore: number | null;
  /** After extra time, where the provider distinguishes it. */
  homeScoreEt: number | null;
  awayScoreEt: number | null;
  /** Shootout, which is not a score and is stored separately. */
  homeScorePens: number | null;
  awayScorePens: number | null;
  /** Round label as the provider states it, or null. */
  round: string | null;
  /** Identifies the competition edition, via `editionKey`. */
  competition: { id: string; name: string; season: string };
};

/**
 * A goal event, normalised.
 *
 * `team` is the team the vault would store the event under, which for an own
 * goal is the SCORING PLAYER'S OWN TEAM (design principle 5). Providers that
 * publish an own goal under the side it counts for must apply the flip while
 * normalising — that is the provider's business, not the sync's, because every
 * source does it differently and each one has had to be established by
 * checking real data rather than reading a doc.
 */
export type ProviderEvent = {
  minute: number | null;
  extraMinute: number | null;
  /** One of the vault's `match_events.type` values. */
  type: string;
  team: ProviderTeam;
  /** Full name where the provider has one; null is the truth when it does not. */
  playerName: string | null;
  /** The provider's player id, where it publishes one. Often absent. */
  playerId: string | null;
};
