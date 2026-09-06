import type { Prisma } from '@prisma/client';
import { prisma } from '../db.js';

/** Entity types recorded in `entity_source_map`, matching the migrated values. */
export type ProvenanceEntity =
  | 'competition_edition'
  | 'team'
  | 'player'
  | 'match'
  | 'match_event'
  | 'stadium'
  | 'coach'
  | 'competition'
  | 'season'
  | 'country';

/** Names of the `data_sources` rows this codebase writes provenance for. */
export type SourceName = 'legacy_sokafc' | 'manual_admin' | 'api_football';

const sourceIds = new Map<SourceName, number>();

/** Id of a data source, resolved once per process and cached. */
export async function getSourceId(name: SourceName): Promise<number> {
  const cached = sourceIds.get(name);
  if (cached !== undefined) return cached;
  const source = await prisma.data_sources.findUnique({
    where: { name },
    select: { id: true },
  });
  if (!source) {
    throw new Error(
      `data_sources row '${name}' is missing — seed it before writing (npm run seed:sources)`,
    );
  }
  sourceIds.set(name, source.id);
  return source.id;
}

export const getManualSourceId = () => getSourceId('manual_admin');

/**
 * Record that an entity came from, or was confirmed by, an external source.
 *
 * `externalId` is that source's own identifier for the entity (an API-Football
 * fixture or team id), which is what makes the mapping reusable on the next
 * sync. The unique key (entity_type, data_source_id, external_id) means a
 * repeat sync refreshes `last_synced_at` instead of duplicating rows.
 */
export async function recordProvenance(
  tx: Prisma.TransactionClient,
  entityType: ProvenanceEntity,
  entityId: number,
  sourceName: SourceName,
  externalId: string,
  confidence = 1.0,
): Promise<void> {
  const dataSourceId = await getSourceId(sourceName);
  await tx.entity_source_map.upsert({
    where: {
      entity_type_data_source_id_external_id: {
        entity_type: entityType,
        data_source_id: dataSourceId,
        external_id: externalId,
      },
    },
    create: {
      entity_type: entityType,
      entity_id: entityId,
      data_source_id: dataSourceId,
      external_id: externalId,
      confidence,
      last_synced_at: new Date(),
    },
    update: { entity_id: entityId, confidence, last_synced_at: new Date() },
  });
}

/**
 * Record that an entity was created or edited by hand.
 *
 * Design principle 1 makes this mandatory rather than optional: every row that
 * enters the vault from any source carries an `entity_source_map` row, which is
 * what makes later reconciliation between sources possible. Ingestion code must
 * never skip it — so admin writes call this inside the same transaction as the
 * write itself, and a provenance failure rolls the write back.
 *
 * `external_id` is the vault's own entity id, mirroring the convention the
 * legacy migration used. The unique key is
 * (entity_type, data_source_id, external_id), so re-editing an entity updates
 * `last_synced_at` rather than piling up duplicate rows.
 *
 * Note: this records WHICH SOURCE touched the row, not WHICH ADMIN. Per-admin
 * attribution would need an audit table the schema does not currently have.
 */
export async function recordManualProvenance(
  tx: Prisma.TransactionClient,
  entityType: ProvenanceEntity,
  entityId: number,
): Promise<void> {
  const dataSourceId = await getManualSourceId();
  const externalId = String(entityId);

  await tx.entity_source_map.upsert({
    where: {
      entity_type_data_source_id_external_id: {
        entity_type: entityType,
        data_source_id: dataSourceId,
        external_id: externalId,
      },
    },
    create: {
      entity_type: entityType,
      entity_id: entityId,
      data_source_id: dataSourceId,
      external_id: externalId,
      confidence: 1.0,
      last_synced_at: new Date(),
    },
    update: { last_synced_at: new Date() },
  });
}
