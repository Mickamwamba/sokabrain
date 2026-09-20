import { prisma } from '../db.js';
import { TEAM_ALIASES } from '../config/teamAliases.js';
import { getSourceId, type ProvenanceEntity, type SourceName } from './provenance.js';

/**
 * Translating a provider's ids into vault ids.
 *
 * The legacy vault was migrated with no knowledge of any live provider, so
 * nothing is linked until a mapping is built (`src/scripts/mapSportmonks.ts`,
 * or `mapApiFootball.ts`). Every mapping lives in `entity_source_map` as
 * (entity_type, data_source, external_id = the provider's id), which is the
 * same mechanism provenance already uses — no parallel lookup table, and the
 * mapping doubles as the provenance record.
 *
 * The source is a parameter throughout, never a constant: two providers number
 * the same club differently, so a lookup that assumed one of them would quietly
 * resolve the other's ids to nothing (or, worse, to the wrong club).
 */

/**
 * Normalise a club or competition name for comparison.
 *
 * Strips diacritics, punctuation and the common club-type affixes that differ
 * between sources ("Simba SC" vs "Simba"), so name matching survives the
 * cosmetic differences. Deliberately conservative: it does not try to be a
 * fuzzy matcher, it just removes noise before an exact comparison.
 */
export function normalizeName(name: string): string {
  return name
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9 ]/g, ' ')
    .replace(/\b(fc|sc|afc|cf|club|team|the)\b/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

/**
 * External-id key for a competition edition.
 *
 * A provider's league id is stable across seasons, but a vault
 * `competition_edition` is league + season — so the mapping key must carry the
 * season too, or every season of a league would collide on one row. Seasons are
 * stringified because providers label them differently: API-Football uses a
 * start year (2026) and SportMonks a name ("2026/2027").
 */
export const editionKey = (leagueId: number | string, season: number | string) =>
  `${leagueId}:${season}`;

/** Vault id for a provider entity, or null when it isn't mapped yet. */
export async function resolveVaultId(
  entityType: ProvenanceEntity,
  apiId: number | string,
  source: SourceName,
): Promise<number | null> {
  const row = await prisma.entity_source_map.findUnique({
    where: {
      entity_type_data_source_id_external_id: {
        entity_type: entityType,
        data_source_id: await getSourceId(source),
        external_id: String(apiId),
      },
    },
    select: { entity_id: true },
  });
  return row?.entity_id ?? null;
}

/** Bulk form of {@link resolveVaultId}, to avoid a query per fixture. */
export async function resolveVaultIds(
  entityType: ProvenanceEntity,
  externalIds: (number | string)[],
  source: SourceName,
): Promise<Map<string, number>> {
  if (externalIds.length === 0) return new Map();
  const rows = await prisma.entity_source_map.findMany({
    where: {
      entity_type: entityType,
      data_source_id: await getSourceId(source),
      external_id: { in: externalIds.map(String) },
    },
    select: { external_id: true, entity_id: true },
  });
  return new Map(
    rows
      .filter((r): r is typeof r & { external_id: string } => r.external_id !== null)
      .map((r) => [r.external_id, r.entity_id]),
  );
}

export type NameMatch = {
  /** The provider's id, stringified. */
  apiId: string;
  apiName: string;
  vaultId: number | null;
  vaultName: string | null;
  /**
   * 'exact' after normalisation, 'alias' via a human-written equivalence in
   * `config/teamAliases.ts`, or 'none'. Never an inference.
   */
  confidence: 'exact' | 'alias' | 'none';
};

/**
 * Propose vault teams for a set of a provider's teams, by name.
 *
 * Two passes, both requiring an exact hit on a single vault team:
 *
 *   1. the normalised name, which absorbs cosmetic differences;
 *   2. a human-written alias from `config/teamAliases.ts`, for clubs whose two
 *      names share nothing ("Yanga SC" / "Young Africans").
 *
 * Anything ambiguous (a normalised name shared by two vault teams) is reported
 * as unmatched rather than guessed — a wrong team mapping silently corrupts
 * scores for every future sync, so this is a place to under-reach and let a
 * human decide.
 */
export async function proposeTeamMatches(
  apiTeams: { id: number | string; name: string }[],
): Promise<NameMatch[]> {
  const vaultTeams = await prisma.teams.findMany({ select: { id: true, name: true } });

  const byName = new Map<string, { id: number; name: string }[]>();
  const add = (key: string, t: { id: number; name: string }) => {
    const list = byName.get(key);
    if (list) {
      if (!list.some((x) => x.id === t.id)) list.push(t);
    } else byName.set(key, [t]);
  };
  for (const t of vaultTeams) add(normalizeName(t.name), t);

  // A second index for the aliases, kept separate so an alias can never shadow
  // a real name and so the two can be reported apart.
  const byAlias = new Map<string, { id: number; name: string }[]>();
  const vaultByCanonical = new Map(vaultTeams.map((t) => [t.name, t]));
  for (const [canonical, aliases] of Object.entries(TEAM_ALIASES)) {
    const t = vaultByCanonical.get(canonical);
    if (!t) continue; // an alias for a club this vault does not hold is harmless
    for (const a of aliases) {
      const key = normalizeName(a);
      const list = byAlias.get(key);
      if (list) {
        if (!list.some((x) => x.id === t.id)) list.push(t);
      } else byAlias.set(key, [t]);
    }
  }

  return apiTeams.map(({ id, name }) => {
    const key = normalizeName(name);
    const miss = {
      apiId: String(id),
      apiName: name,
      vaultId: null,
      vaultName: null,
      confidence: 'none' as const,
    };

    // Exactly one candidate, or it's not a match we're willing to assert.
    const exact = byName.get(key) ?? [];
    const onlyExact = exact.length === 1 ? exact[0] : undefined;
    if (onlyExact) {
      return {
        apiId: String(id),
        apiName: name,
        vaultId: onlyExact.id,
        vaultName: onlyExact.name,
        confidence: 'exact' as const,
      };
    }
    if (exact.length > 1) return miss; // ambiguous: a human decides

    const alias = byAlias.get(key) ?? [];
    const onlyAlias = alias.length === 1 ? alias[0] : undefined;
    if (onlyAlias) {
      return {
        apiId: String(id),
        apiName: name,
        vaultId: onlyAlias.id,
        vaultName: onlyAlias.name,
        confidence: 'alias' as const,
      };
    }
    return miss;
  });
}
