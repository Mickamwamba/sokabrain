import { prisma } from '../db.js';
import {
  apiFootball,
  mapStatus,
  type ApiFootballFixture,
} from './apiFootball.js';
import { editionKey, resolveVaultIds } from './entityResolution.js';
import { getSourceId, recordProvenance } from './provenance.js';

export type SyncSummary = {
  fixturesSeen: number;
  created: number;
  /** Score/status advanced using api_football's own earlier value. */
  updated: number;
  /** API agreed with what the vault already held. */
  agreed: number;
  /** API disagreed with non-API data; recorded, not applied. */
  conflicts: number;
  skipped: { fixtureId: number; reason: string }[];
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
 * Sync a batch of API-Football fixtures into the vault.
 *
 * The rules this implements, and why:
 *
 * **Score comes from `fixture.goals`, never from aggregating events.** The API
 * publishes the authoritative score directly, so there is no need to re-derive
 * it — which also means own-goal attribution (design principle 5) cannot be got
 * wrong on this path. `verifyEventsAgainstScore` exists separately to check that
 * assumption rather than trust it.
 *
 * **A conflict is only a conflict across sources.** Design principle 2 forbids
 * silently overwriting canonical data *with a new source*. api_football updating
 * a value api_football itself wrote a minute ago is not that — it is a live
 * score doing its job, and blocking it would make the feature pointless. So:
 *
 *   - vault has no score yet            → fill it (absent is not canonical)
 *   - vault value came only from the API → update it freely
 *   - values agree                       → touch provenance, change nothing
 *   - values disagree and the vault's    → write a `reconciliation_diffs` row
 *     came from legacy or a human           and leave the vault untouched
 *
 * Unmapped teams or competitions are skipped and reported, never guessed at.
 */
export async function syncFixtures(fixtures: ApiFootballFixture[]): Promise<SyncSummary> {
  const summary: SyncSummary = {
    fixturesSeen: fixtures.length,
    created: 0,
    updated: 0,
    agreed: 0,
    conflicts: 0,
    skipped: [],
    reconciliationRunId: null,
  };
  if (fixtures.length === 0) return summary;

  const apiSourceId = await getSourceId('api_football');

  const teamMap = await resolveVaultIds(
    'team',
    fixtures.flatMap((f) => [f.teams.home.id, f.teams.away.id]),
  );
  const editionMap = await resolveVaultIds(
    'competition_edition',
    fixtures.map((f) => editionKey(f.league.id, f.league.season)),
  );
  const matchMap = await resolveVaultIds('match', fixtures.map((f) => f.fixture.id));

  /** Created lazily — a run row is only meaningful if a diff is recorded. */
  let runId: number | null = null;
  const ensureRun = async (): Promise<number> => {
    if (runId !== null) return runId;
    // `reconciliation_runs` models a comparison between exactly two sources,
    // but the vault side of a diff can come from either the migration or a
    // human edit. legacy_sokafc stands for "what the vault already held" since
    // it produced nearly all of it; the notes say so, and each diff row carries
    // the actual values regardless.
    const vaultSourceId = await getSourceId('legacy_sokafc');
    const run = await prisma.reconciliation_runs.create({
      data: {
        entity_type: 'match',
        data_source_a_id: apiSourceId,
        data_source_b_id: vaultSourceId,
        notes:
          'Automatic live-score sync. Source A = api_football; source B = the value already ' +
          'in the vault (legacy migration or manual admin edit).',
      },
      select: { id: true },
    });
    runId = run.id;
    summary.reconciliationRunId = run.id;
    return run.id;
  };

  for (const f of fixtures) {
    const homeId = teamMap.get(String(f.teams.home.id));
    const awayId = teamMap.get(String(f.teams.away.id));
    const editionId = editionMap.get(editionKey(f.league.id, f.league.season));

    if (homeId === undefined || awayId === undefined) {
      summary.skipped.push({
        fixtureId: f.fixture.id,
        reason: `unmapped team(s): ${[
          homeId === undefined ? f.teams.home.name : null,
          awayId === undefined ? f.teams.away.name : null,
        ]
          .filter(Boolean)
          .join(', ')}`,
      });
      continue;
    }
    if (editionId === undefined) {
      summary.skipped.push({
        fixtureId: f.fixture.id,
        reason: `unmapped competition: ${f.league.name} ${f.league.season}`,
      });
      continue;
    }

    const status = mapStatus(f.fixture.status.short);
    const apiHome = f.goals.home;
    const apiAway = f.goals.away;
    const existingId = matchMap.get(String(f.fixture.id));

    // Fall back to structural identity: the same two teams in the same edition.
    // Legacy matches carry no API id, so this is how an API fixture first meets
    // its existing vault row.
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
            kickoff_at: new Date(f.fixture.date),
            status,
            home_score: apiHome,
            away_score: apiAway,
            home_score_pens: f.score.penalty.home,
            away_score_pens: f.score.penalty.away,
            round: f.league.round,
          },
        });
        await recordProvenance(tx, 'match', m.id, 'api_football', String(f.fixture.id));
        return m;
      });
      summary.created += 1;
      matchMap.set(String(f.fixture.id), created.id);
      continue;
    }

    const sources = await sourcesForMatch(existing.id);
    const apiOnly = sources.size === 0 || (sources.size === 1 && sources.has('api_football'));
    const vaultHasScore = existing.home_score !== null && existing.away_score !== null;
    const scoresAgree = existing.home_score === apiHome && existing.away_score === apiAway;

    if (vaultHasScore && !scoresAgree && !apiOnly) {
      // Cross-source disagreement. Record it; do not touch the vault.
      const reconciliationRunId = await ensureRun();
      await prisma.reconciliation_diffs.createMany({
        data: [
          {
            reconciliation_run_id: reconciliationRunId,
            entity_id_a: existing.id,
            entity_id_b: existing.id,
            field_name: 'home_score',
            value_a: String(apiHome),
            value_b: String(existing.home_score),
            resolution: 'PENDING',
          },
          {
            reconciliation_run_id: reconciliationRunId,
            entity_id_a: existing.id,
            entity_id_b: existing.id,
            field_name: 'away_score',
            value_a: String(apiAway),
            value_b: String(existing.away_score),
            resolution: 'PENDING',
          },
        ],
      });
      summary.conflicts += 1;
      // Still record that the API saw this match, so the mapping survives.
      await prisma.$transaction((tx) =>
        recordProvenance(tx, 'match', existing.id, 'api_football', String(f.fixture.id)),
      );
      continue;
    }

    if (vaultHasScore && scoresAgree && existing.status === status) {
      await prisma.$transaction((tx) =>
        recordProvenance(tx, 'match', existing.id, 'api_football', String(f.fixture.id)),
      );
      summary.agreed += 1;
      continue;
    }

    // Safe to write: the vault had no score, or the only prior source is the API.
    await prisma.$transaction(async (tx) => {
      await tx.matches.update({
        where: { id: existing.id },
        data: {
          status,
          home_score: apiHome,
          away_score: apiAway,
          home_score_pens: f.score.penalty.home,
          away_score_pens: f.score.penalty.away,
        },
      });
      await recordProvenance(tx, 'match', existing.id, 'api_football', String(f.fixture.id));
    });
    summary.updated += 1;
  }

  return summary;
}

/**
 * Check that a fixture's event log reconstructs its published score under the
 * vault's own own-goal rule.
 *
 * This does not feed the sync — the score always comes from `fixture.goals`.
 * It exists because API-Football's own-goal team attribution is not something
 * this codebase has been able to verify against live data, and design principle
 * 5 says that assumption is exactly the one that has bitten before. A mismatch
 * here means the assumption below is wrong for that fixture, and event ingestion
 * must not be built on it until it's resolved.
 *
 * The assumption under test: an `Own Goal` event's `team` is the team of the
 * player who scored it, so the goal counts for their OPPONENT.
 */
export async function verifyEventsAgainstScore(fixture: ApiFootballFixture): Promise<{
  fixtureId: number;
  publishedScore: string;
  reconstructedScore: string;
  ownGoals: number;
  agrees: boolean;
}> {
  const events = await apiFootball.events(fixture.fixture.id);
  const homeApiId = fixture.teams.home.id;

  let home = 0;
  let away = 0;
  let ownGoals = 0;

  for (const e of events) {
    if (e.type !== 'Goal') continue;
    if (e.detail === 'Missed Penalty') continue;

    const isOwnGoal = e.detail === 'Own Goal';
    if (isOwnGoal) ownGoals += 1;

    const scoredByHome = e.team.id === homeApiId;
    // An own goal counts for the opposing side.
    const countsForHome = isOwnGoal ? !scoredByHome : scoredByHome;
    if (countsForHome) home += 1;
    else away += 1;
  }

  const published = `${fixture.goals.home ?? '-'}-${fixture.goals.away ?? '-'}`;
  const reconstructed = `${home}-${away}`;
  return {
    fixtureId: fixture.fixture.id,
    publishedScore: published,
    reconstructedScore: reconstructed,
    ownGoals,
    agrees: published === reconstructed,
  };
}
