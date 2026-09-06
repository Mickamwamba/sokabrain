import { prisma } from '../db.js';
import { getSourceId, type ProvenanceEntity } from './provenance.js';

/**
 * Translating API-Football ids into vault ids.
 *
 * The legacy vault was migrated with no knowledge of API-Football, so nothing
 * is linked until a mapping is built (see `src/scripts/mapApiFootball.ts`).
 * Every mapping lives in `entity_source_map` as
 * (entity_type, data_source = 'api_football', external_id = the API's id),
 * which is the same mechanism provenance already uses — no parallel lookup
 * table, and the mapping doubles as the provenance record.
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
 * An API-Football league id is stable across seasons, but a vault
 * `competition_edition` is league + season — so the mapping key must carry the
 * season too, or every season of a league would collide on one row.
 */
export const editionKey = (leagueId: number, season: number) => `${leagueId}:${season}`;

/** Vault id for an API-Football entity, or null when it isn't mapped yet. */
export async function resolveVaultId(
  entityType: ProvenanceEntity,
  apiId: number | string,
): Promise<number | null> {
  const row = await prisma.entity_source_map.findUnique({
    where: {
      entity_type_data_source_id_external_id: {
        entity_type: entityType,
        data_source_id: await getSourceId('api_football'),
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
): Promise<Map<string, number>> {
  if (externalIds.length === 0) return new Map();
  const rows = await prisma.entity_source_map.findMany({
    where: {
      entity_type: entityType,
      data_source_id: await getSourceId('api_football'),
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
  apiId: number;
  apiName: string;
  vaultId: number | null;
  vaultName: string | null;
  /** 'exact' after normalisation, or 'none'. Never a guess. */
  confidence: 'exact' | 'none';
};

/**
 * Propose vault teams for a set of API-Football teams, by normalised name.
 *
 * Only exact post-normalisation matches are proposed. Anything ambiguous (a
 * normalised name shared by two vault teams) is reported as unmatched rather
 * than guessed — a wrong team mapping silently corrupts scores for every future
 * sync, so this is a place to under-reach and let a human decide.
 */
export async function proposeTeamMatches(
  apiTeams: { id: number; name: string }[],
): Promise<NameMatch[]> {
  const vaultTeams = await prisma.teams.findMany({ select: { id: true, name: true } });

  const byName = new Map<string, { id: number; name: string }[]>();
  for (const t of vaultTeams) {
    const key = normalizeName(t.name);
    const list = byName.get(key);
    if (list) list.push(t);
    else byName.set(key, [t]);
  }

  return apiTeams.map(({ id, name }) => {
    const candidates = byName.get(normalizeName(name)) ?? [];
    // Exactly one candidate, or it's not a match we're willing to assert.
    const only = candidates.length === 1 ? candidates[0] : undefined;
    return only
      ? { apiId: id, apiName: name, vaultId: only.id, vaultName: only.name, confidence: 'exact' as const }
      : { apiId: id, apiName: name, vaultId: null, vaultName: null, confidence: 'none' as const };
  });
}
