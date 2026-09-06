import cron from 'node-cron';
import { apiFootball, ApiFootballError } from '../services/apiFootball.js';
import { syncFixtures, type SyncSummary } from '../services/liveSync.js';
import { getSourceId } from '../services/provenance.js';
import { prisma } from '../db.js';
import { env } from '../env.js';

/**
 * Periodic live-score sync.
 *
 * Runs on a cron schedule while the server is up. It only ever asks for
 * fixtures that are currently in play, which keeps free-tier request usage
 * proportional to how much football is actually happening rather than to how
 * many leagues we track.
 */

/** Every mapped API-Football league id, so `?live=` is scoped to our leagues. */
async function mappedLeagueIds(): Promise<number[]> {
  const rows = await prisma.entity_source_map.findMany({
    where: {
      entity_type: 'competition_edition',
      data_source_id: await getSourceId('api_football'),
    },
    select: { external_id: true },
  });
  // external_id is "<leagueId>:<season>" for editions; the API's ?live= filter
  // takes bare league ids, and the same league across seasons dedupes to one.
  return [
    ...new Set(
      rows
        .map((r) => Number(r.external_id?.split(':')[0]))
        .filter((n) => Number.isInteger(n)),
    ),
  ];
}

export async function runLiveSyncOnce(): Promise<SyncSummary | null> {
  const leagueIds = await mappedLeagueIds();
  if (leagueIds.length === 0) {
    console.warn(
      '[live-sync] no competition editions mapped to API-Football yet — run `npm run af:map` first. Skipping.',
    );
    return null;
  }

  const fixtures = await apiFootball.liveFixtures(leagueIds);
  const summary = await syncFixtures(fixtures);

  if (summary.fixturesSeen > 0) {
    console.log(
      `[live-sync] ${summary.fixturesSeen} live fixture(s): ` +
        `${summary.created} created, ${summary.updated} updated, ${summary.agreed} unchanged, ` +
        `${summary.conflicts} conflict(s), ${summary.skipped.length} skipped`,
    );
  }
  if (summary.conflicts > 0) {
    console.warn(
      `[live-sync] ${summary.conflicts} match(es) disagree with existing vault data — ` +
        `recorded in reconciliation_diffs (run #${summary.reconciliationRunId}), not applied.`,
    );
  }
  for (const s of summary.skipped) {
    console.warn(`[live-sync] skipped fixture ${s.fixtureId}: ${s.reason}`);
  }
  return summary;
}

/**
 * Start the scheduled job. Returns a stop function, or null when the job is
 * not startable — a missing API key is a normal state here (the read API and
 * admin API both work fine without one), so it warns rather than throwing.
 */
export function startLiveScoreSync(): (() => void) | null {
  if (!env.API_FOOTBALL_KEY) {
    console.warn('[live-sync] API_FOOTBALL_KEY not set — live-score sync disabled.');
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
        if (err instanceof ApiFootballError) {
          console.error(`[live-sync] API error: ${err.message}`);
        } else {
          console.error('[live-sync] unexpected failure:', err);
        }
      })
      .finally(() => {
        running = false;
      });
  });

  console.log(`[live-sync] scheduled (${env.LIVE_SYNC_CRON})`);
  return () => task.stop();
}
