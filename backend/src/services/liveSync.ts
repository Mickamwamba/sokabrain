import { prisma } from '../db.js';
import { editionKey, resolveVaultIds } from './entityResolution.js';
import type { ProviderFixture } from './providerFixture.js';
import { getSourceId, recordProvenance, type SourceName } from './provenance.js';

export type SyncSummary = {
  fixturesSeen: number;
  created: number;
  /** Score/status advanced using this provider's own earlier value. */
  updated: number;
  /** Provider agreed with what the vault already held. */
  agreed: number;
  /** Provider disagreed with non-provider data; recorded, not applied. */
  conflicts: number;
  /** Unplayed fixtures whose kickoff the provider had moved. */
  kickoffsMoved: number;
  skipped: { fixtureId: string; reason: string }[];
  reconciliationRunId: number | null;
};

/** Which sources produced or confirmed a match, by data source name. */
async function sourcesForMatch(matchId: number): Promise<Set<string>> {
  const rows = await prisma.entity_source_map.findMany({
    where: { entity_type: 'match', entity_id: matchId },
    select: { data_sources: { select: { name: true } } },
  });
  return new Set(rows.map((r) => r.data_sources.name));
}

/**
 * Sync a batch of a provider's fixtures into the vault.
 *
 * The provider is a parameter, not a constant: two providers number the same
 * club differently and each needs its own `entity_source_map` rows, but the
 * rules below must exist in exactly one place.
 *
 * The rules this implements, and why:
 *
 * **Score comes from the provider's published score, never from aggregating
 * events.** The provider publishes the authoritative score directly, so there is
 * no need to re-derive it — which also means own-goal attribution (design
 * principle 5) cannot be got wrong on this path. Each provider's normaliser
 * carries its own own-goal convention, and `reconstructScore` exists to test
 * that convention against real fixtures rather than trust it.
 *
 * **Events are deliberately NOT written here.** For the Tanzanian Premier League
 * the vault's own event log is better than the provider's: comparing the two
 * across the current season, scores agreed on all 49 played matches and rounds on
 * all 240, but the scorer NAMES differed on 38 of 108 pairable goals — mostly
 * spelling ("Anuary Jabiri" / "Anuary Jabir"), sometimes a different man
 * entirely. Writing those would rebuild the identity problem this project has
 * spent days undoing. Scores and status are what this sync is for.
 *
 * **A conflict is only a conflict across sources.** Design principle 2 forbids
 * silently overwriting canonical data *with a new source*. A provider updating a
 * value it itself wrote a minute ago is not that — it is a live score doing its
 * job, and blocking it would make the feature pointless. So:
 *
 *   - vault has no score yet                → fill it (absent is not canonical)
 *   - vault value came only from this provider → update it freely
 *   - values agree                          → touch provenance, change nothing
 *   - values disagree and the vault's came   → write a `reconciliation_diffs` row
 *     from legacy, another source or a human    and leave the vault untouched
 *
 * Unmapped teams or competitions are skipped and reported, never guessed at.
 */
export async function syncFixtures(
  fixtures: ProviderFixture[],
  source: SourceName,
): Promise<SyncSummary> {
  const summary: SyncSummary = {
    fixturesSeen: fixtures.length,
    created: 0,
    updated: 0,
    agreed: 0,
    conflicts: 0,
    kickoffsMoved: 0,
    skipped: [],
    reconciliationRunId: null,
  };
  if (fixtures.length === 0) return summary;

  const providerSourceId = await getSourceId(source);

  const teamMap = await resolveVaultIds(
    'team',
    fixtures.flatMap((f) => [f.home.id, f.away.id]),
    source,
  );
  const editionMap = await resolveVaultIds(
    'competition_edition',
    fixtures.map((f) => editionKey(f.competition.id, f.competition.season)),
    source,
  );
  const matchMap = await resolveVaultIds('match', fixtures.map((f) => f.id), source);

  /** Created lazily — a run row is only meaningful if a diff is recorded. */
  let runId: number | null = null;
  const ensureRun = async (): Promise<number> => {
    if (runId !== null) return runId;
    // `reconciliation_runs` models a comparison between exactly two sources,
    // but the vault side of a diff can come from the migration, an earlier
    // ingestion or a human edit. legacy_sokafc stands for "what the vault
    // already held"; the notes say so, and each diff row carries the actual
    // values regardless.
    const vaultSourceId = await getSourceId('legacy_sokafc');
    const run = await prisma.reconciliation_runs.create({
      data: {
        entity_type: 'match',
        data_source_a_id: providerSourceId,
        data_source_b_id: vaultSourceId,
        notes:
          `Automatic live-score sync. Source A = ${source}; source B = the value already ` +
          'in the vault (an earlier ingestion, the legacy migration, or a manual admin edit).',
      },
      select: { id: true },
    });
    runId = run.id;
    summary.reconciliationRunId = run.id;
    return run.id;
  };

  for (const f of fixtures) {
    const homeId = teamMap.get(f.home.id);
    const awayId = teamMap.get(f.away.id);
    const editionId = editionMap.get(editionKey(f.competition.id, f.competition.season));

    if (homeId === undefined || awayId === undefined) {
      summary.skipped.push({
        fixtureId: f.id,
        reason: `unmapped team(s): ${[
          homeId === undefined ? f.home.name : null,
          awayId === undefined ? f.away.name : null,
        ]
          .filter(Boolean)
          .join(', ')}`,
      });
      continue;
    }
    if (editionId === undefined) {
      summary.skipped.push({
        fixtureId: f.id,
        reason: `unmapped competition: ${f.competition.name} ${f.competition.season}`,
      });
      continue;
    }

    const existingId = matchMap.get(f.id);

    // Fall back to structural identity: the same two teams in the same edition.
    // A vault match carries no provider id until this sync gives it one, so this
    // is how a provider fixture first meets its existing vault row. The ordered
    // club pair meets once in a double round-robin, which makes it a safer key
    // than a kickoff date the two sources may disagree on.
    const existing = existingId
      ? await prisma.matches.findUnique({ where: { id: existingId } })
      : await prisma.matches.findFirst({
          where: {
            competition_edition_id: editionId,
            home_team_id: homeId,
            away_team_id: awayId,
          },
        });

    if (!existing) {
      const created = await prisma.$transaction(async (tx) => {
        const m = await tx.matches.create({
          data: {
            competition_edition_id: editionId,
            home_team_id: homeId,
            away_team_id: awayId,
            kickoff_at: f.kickoff,
            status: f.status,
            home_score: f.homeScore,
            away_score: f.awayScore,
            home_score_et: f.homeScoreEt,
            away_score_et: f.awayScoreEt,
            home_score_pens: f.homeScorePens,
            away_score_pens: f.awayScorePens,
            round: f.round,
            live_minute: f.status === 'LIVE' ? f.liveMinute : null,
            live_minute_at: f.status === 'LIVE' && f.liveClockRunning ? new Date() : null,
          },
        });
        await recordProvenance(tx, 'match', m.id, source, f.id);
        return m;
      });
      summary.created += 1;
      matchMap.set(f.id, created.id);
      continue;
    }

    const sources = await sourcesForMatch(existing.id);
    const providerOnly = sources.size === 0 || (sources.size === 1 && sources.has(source));
    const vaultHasScore = existing.home_score !== null && existing.away_score !== null;
    const scoresAgree =
      existing.home_score === f.homeScore && existing.away_score === f.awayScore;

    if (vaultHasScore && !scoresAgree && !providerOnly) {
      // Cross-source disagreement. Record it; do not touch the vault.
      const reconciliationRunId = await ensureRun();
      await prisma.reconciliation_diffs.createMany({
        data: [
          {
            reconciliation_run_id: reconciliationRunId,
            entity_id_a: existing.id,
            entity_id_b: existing.id,
            field_name: 'home_score',
            value_a: String(f.homeScore),
            value_b: String(existing.home_score),
            resolution: 'PENDING',
          },
          {
            reconciliation_run_id: reconciliationRunId,
            entity_id_a: existing.id,
            entity_id_b: existing.id,
            field_name: 'away_score',
            value_a: String(f.awayScore),
            value_b: String(existing.away_score),
            resolution: 'PENDING',
          },
        ],
      });
      summary.conflicts += 1;
      // Still record that the provider saw this match, so the mapping survives.
      await prisma.$transaction((tx) =>
        recordProvenance(tx, 'match', existing.id, source, f.id),
      );
      continue;
    }

    if (vaultHasScore && scoresAgree && existing.status === f.status) {
      // The score can sit still for an hour while the clock does not, so a
      // live match's minute is written even on the "nothing changed" path.
      // Without this a 0-0 would freeze at whatever minute it was first seen.
      // At a break the provider publishes no ticking period, so `liveMinute`
      // arrives null — keep the last known value rather than blanking the clock
      // exactly when a viewer most wants to see 45'.
      const minute =
        f.status === 'LIVE' ? (f.liveMinute ?? existing.live_minute) : null;
      const at = f.status === 'LIVE' && f.liveClockRunning ? new Date() : null;
      await prisma.$transaction(async (tx) => {
        await tx.matches.update({
          where: { id: existing.id },
          data: { live_minute: minute, live_minute_at: at },
        });
        await recordProvenance(tx, 'match', existing.id, source, f.id);
      });
      summary.agreed += 1;
      continue;
    }

    // Safe to write: the vault had no score, or the only prior source is this one.
    //
    // The kickoff moves only for a fixture that has NOT been played — neither
    // side has a score. A rescheduled future fixture is new information, not a
    // disagreement, and a stale scheduled date is a defect this project has
    // already had to fix once (82 fixtures left inside a COVID suspension). For
    // a played match the kickoff is canonical and a difference is a question for
    // a human, so it is left alone (principle 2).
    const unplayed = !vaultHasScore && f.homeScore === null && f.awayScore === null;
    const kickoffMoved =
      unplayed &&
      existing.kickoff_at !== null &&
      existing.kickoff_at.getTime() !== f.kickoff.getTime();

    await prisma.$transaction(async (tx) => {
      await tx.matches.update({
        where: { id: existing.id },
        data: {
          status: f.status,
          home_score: f.homeScore,
          away_score: f.awayScore,
          home_score_et: f.homeScoreEt,
          away_score_et: f.awayScoreEt,
          home_score_pens: f.homeScorePens,
          away_score_pens: f.awayScorePens,
          // Cleared the moment a match stops being live, so a finished match
          // never carries a stale clock. While live the last known minute is
          // kept through a break, when the provider reports none.
          live_minute: f.status === 'LIVE' ? (f.liveMinute ?? existing.live_minute) : null,
          live_minute_at: f.status === 'LIVE' && f.liveClockRunning ? new Date() : null,
          ...(kickoffMoved ? { kickoff_at: f.kickoff } : {}),
        },
      });
      await recordProvenance(tx, 'match', existing.id, source, f.id);
    });
    summary.updated += 1;
    if (kickoffMoved) summary.kickoffsMoved += 1;
  }

  return summary;
}
