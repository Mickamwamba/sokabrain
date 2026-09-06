/**
 * Run one live-score sync pass and exit. Useful for testing the pipeline
 * without waiting for the cron tick.
 *
 *   npm run af:sync
 */
import { runLiveSyncOnce } from '../jobs/liveScoreSync.js';
import { ApiFootballError } from '../services/apiFootball.js';
import { prisma } from '../db.js';

try {
  const summary = await runLiveSyncOnce();
  if (summary) console.log(JSON.stringify(summary, null, 2));
} catch (err) {
  if (err instanceof ApiFootballError) {
    console.error(`API-Football request failed: ${err.message}`);
    process.exitCode = 1;
  } else {
    throw err;
  }
} finally {
  await prisma.$disconnect();
}
