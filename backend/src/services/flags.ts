import { prisma } from '../db.js';

export const FLAG_ENTITIES = [
  'competition_edition',
  'match',
  'match_event',
  'team',
  'player',
] as const;
export type FlagEntity = (typeof FLAG_ENTITIES)[number];

export const SEVERITIES = ['INFO', 'WARNING', 'BLOCKER'] as const;
export type Severity = (typeof SEVERITIES)[number];

/**
 * Open flags for an edition and everything inside it.
 *
 * "Inside it" means the edition row itself, its matches, and the events on
 * those matches — which is the unit an editor actually reviews before deciding
 * an edition is fit to publish.
 */
export async function editionFlagSummary(editionId: number) {
  const matchIds = (
    await prisma.matches.findMany({
      where: { competition_edition_id: editionId },
      select: { id: true },
    })
  ).map((m) => m.id);

  const eventIds =
    matchIds.length === 0
      ? []
      : (
          await prisma.match_events.findMany({
            where: { match_id: { in: matchIds } },
            select: { id: true },
          })
        ).map((e) => e.id);

  const flags = await prisma.data_flags.findMany({
    where: {
      status: 'OPEN',
      OR: [
        { entity_type: 'competition_edition', entity_id: editionId },
        { entity_type: 'match', entity_id: { in: matchIds } },
        { entity_type: 'match_event', entity_id: { in: eventIds } },
      ],
    },
    select: { id: true, severity: true, entity_type: true, entity_id: true, reason: true },
  });

  const bySeverity = { INFO: 0, WARNING: 0, BLOCKER: 0 };
  for (const f of flags) {
    if (f.severity in bySeverity) bySeverity[f.severity as Severity] += 1;
  }

  return { total: flags.length, bySeverity, blockers: flags.filter((f) => f.severity === 'BLOCKER') };
}

export type PublishRefusal = { ok: false; reason: string; blockers: { id: number; reason: string }[] };
export type PublishOk = { ok: true };

/**
 * Publish an edition, refusing while it still carries open BLOCKER flags.
 *
 * This is the rule that makes flagging worth doing: an edition cannot be shown
 * to the public over a problem someone has explicitly marked as blocking. INFO
 * and WARNING flags are advisory and do not stop publication.
 */
export async function publishEdition(
  editionId: number,
  adminId: number,
): Promise<PublishOk | PublishRefusal> {
  const { blockers } = await editionFlagSummary(editionId);
  if (blockers.length > 0) {
    return {
      ok: false,
      reason: `${blockers.length} unresolved blocker flag(s) must be cleared first`,
      blockers: blockers.map((b) => ({ id: b.id, reason: b.reason })),
    };
  }

  await prisma.competition_editions.update({
    where: { id: editionId },
    data: { is_published: true, published_at: new Date(), published_by: adminId },
  });
  return { ok: true };
}

export async function unpublishEdition(editionId: number): Promise<void> {
  await prisma.competition_editions.update({
    where: { id: editionId },
    // published_at/by are kept as the record of the last publication.
    data: { is_published: false },
  });
}

/**
 * Suggest flags from the data itself.
 *
 * These are the problems already known to exist in the migrated vault — missing
 * scores, goals with no scorer, matches marked complete with no events. Offering
 * them as suggestions means an editor starts from a real worklist instead of a
 * blank page. Nothing is written until they choose to raise one.
 */
export async function suggestedIssues(editionId: number) {
  const [missingScores, noEvents, unattributedGoals] = await Promise.all([
    prisma.matches.count({
      where: {
        competition_edition_id: editionId,
        status: 'FULL_TIME',
        OR: [{ home_score: null }, { away_score: null }],
      },
    }),
    prisma.matches.count({
      where: {
        competition_edition_id: editionId,
        status: 'FULL_TIME',
        match_events: { none: {} },
      },
    }),
    prisma.match_events.count({
      where: {
        matches: { competition_edition_id: editionId },
        type: { in: ['GOAL', 'PENALTY_GOAL'] },
        player_id: null,
      },
    }),
  ]);

  return [
    {
      key: 'missing_scores',
      count: missingScores,
      label: 'completed matches with no score recorded',
      severity: 'BLOCKER' as Severity,
    },
    {
      key: 'no_events',
      count: noEvents,
      label: 'completed matches with no event log at all',
      severity: 'WARNING' as Severity,
    },
    {
      key: 'unattributed_goals',
      count: unattributedGoals,
      label: 'goals with no scorer attributed',
      severity: 'WARNING' as Severity,
    },
  ].filter((i) => i.count > 0);
}
