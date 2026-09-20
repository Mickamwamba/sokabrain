import cron from 'node-cron';
import { apiFootball, ApiFootballError, toProviderFixture } from '../services/apiFootball.js';
import { sportmonks, SportmonksError, normaliseFixture } from '../services/sportmonks.js';
import { syncFixtures, type SyncSummary } from '../services/liveSync.js';
import { getSourceId, type SourceName } from '../services/provenance.js';
import type { ProviderFixture } from '../services/providerFixture.js';
import { prisma } from '../db.js';
import { env } from '../env.js';

/**
 * Periodic live-score sync.
 *
 * Runs on a cron schedule while the server is up, and only ever asks for
 * fixtures that are currently in play — which keeps request usage proportional
 * to how much football is actually happening rather than to how many leagues we
 * track. SportMonks answers that in a single request no matter how many leagues
 * the plan covers.
 *
 * SportMonks is the provider when its token is set, because it is the one whose
 * Tanzanian Premier League coverage was verified. API-Football remains wired as
 * a fallback so the earlier work is not lost, but it has never been validated
 * against live data.
 */

/** Editions mapped to a provider, keyed by `"<leagueId>:<season>"`. */
async function mappedEditionKeys(source: SourceName): Promise<Set<string>> {
  const rows = await prisma.entity_source_map.findMany({
    where: {
      entity_type: 'competition_edition',
      data_source_id: await getSourceId(source),
    },
    select: { external_id: true },
  });
  return new Set(rows.map((r) => r.external_id).filter((v): v is string => v !== null));
}

/** Which provider this process should use, and whether it can run at all. */
export function activeProvider(): SourceName | null {
  if (env.SPORTMONKS_TOKEN) return 'sportmonks';
  if (env.API_FOOTBALL_KEY) return 'api_football';
  return null;
}

async function collectSportmonks(): Promise<ProviderFixture[]> {
  const mapped = await mappedEditionKeys('sportmonks');
  if (mapped.size === 0) return [];

  const leagues = await sportmonks.leagues();
  const leagueName = new Map(leagues.map((l) => [l.id, l.name]));

  const live = await sportmonks.liveFixtures();
  // The in-play feed returns every league in the plan. Four of the five have no
  // vault competition yet, so filtering here keeps the job from logging a skip
  // for every Kenyan or South African fixture on every single tick.
  return live
    .map((f) => normaliseFixture(f, leagueName.get(f.league_id) ?? 'unknown league'))
    .filter((f): f is ProviderFixture => f !== null)
    .filter((f) => mapped.has(`${f.competition.id}:${f.competition.season}`));
}

async function collectApiFootball(): Promise<ProviderFixture[]> {
  const mapped = await mappedEditionKeys('api_football');
  // external_id is "<leagueId>:<season>"; the API's ?live= filter takes bare
  // league ids, and the same league across seasons dedupes to one.
  const leagueIds = [
    ...new Set([...mapped].map((k) => Number(k.split(':')[0])).filter(Number.isInteger)),
  ];
  if (leagueIds.length === 0) return [];
  return (await apiFootball.liveFixtures(leagueIds)).map(toProviderFixture);
}

export async function runLiveSyncOnce(): Promise<SyncSummary | null> {
  const source = activeProvider();
  if (source === null) {
    console.warn('[live-sync] no provider credential set — live-score sync disabled.');
    return null;
  }

  const fixtures =
    source === 'sportmonks' ? await collectSportmonks() : await collectApiFootball();

  if (fixtures.length === 0) {
    const mapped = await mappedEditionKeys(source);
    if (mapped.size === 0) {
      console.warn(
        `[live-sync] no competition editions mapped to ${source} yet — ` +
          `run \`npm run ${source === 'sportmonks' ? 'sm' : 'af'}:map\` first. Skipping.`,
      );
      return null;
    }
  }

  const summary = await syncFixtures(fixtures, source);

  if (summary.fixturesSeen > 0) {
    console.log(
      `[live-sync:${source}] ${summary.fixturesSeen} live fixture(s): ` +
        `${summary.created} created, ${summary.updated} updated, ${summary.agreed} unchanged, ` +
        `${summary.conflicts} conflict(s), ${summary.kickoffsMoved} rescheduled, ` +
        `${summary.skipped.length} skipped`,
    );
  }
  if (summary.conflicts > 0) {
    console.warn(
      `[live-sync:${source}] ${summary.conflicts} match(es) disagree with existing vault data — ` +
        `recorded in reconciliation_diffs (run #${summary.reconciliationRunId}), not applied.`,
    );
  }
  for (const s of summary.skipped) {
    console.warn(`[live-sync:${source}] skipped fixture ${s.fixtureId}: ${s.reason}`);
  }
  return summary;
}

/**
 * Start the scheduled job. Returns a stop function, or null when the job is
 * not startable — a missing credential is a normal state here (the read API and
 * admin API both work fine without one), so it warns rather than throwing.
 */
export function startLiveScoreSync(): (() => void) | null {
  const source = activeProvider();
  if (source === null) {
    console.warn(
      '[live-sync] neither SPORTMONKS_TOKEN nor API_FOOTBALL_KEY is set — live-score sync disabled.',
    );
    return null;
  }
  if (env.LIVE_SYNC_ENABLED === 'false') {
    console.warn('[live-sync] LIVE_SYNC_ENABLED=false — scheduler not started.');
    return null;
  }

  let running = false;
  const task = cron.schedule(env.LIVE_SYNC_CRON, () => {
    // Overlap guard: a slow sync must not stack up behind the next tick.
    if (running) {
      console.warn('[live-sync] previous run still in progress, skipping this tick');
      return;
    }
    running = true;
    void runLiveSyncOnce()
      .catch((err: unknown) => {
        if (err instanceof SportmonksError || err instanceof ApiFootballError) {
          console.error(`[live-sync] provider error: ${err.message}`);
        } else {
          console.error('[live-sync] unexpected failure:', err);
        }
      })
      .finally(() => {
        running = false;
      });
  });

  console.log(`[live-sync] scheduled (${env.LIVE_SYNC_CRON}), provider ${source}`);
  return () => task.stop();
}
