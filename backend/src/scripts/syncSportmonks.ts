/**
 * Run one sync pass and exit, without waiting for a cron tick.
 *
 *   npm run sm:sync                      # whatever is in play right now
 *   npm run sm:sync -- --league 884      # every fixture of that league's season
 *   npm run sm:sync -- --league 884 --dry
 *
 * With no `--league` this is exactly what the scheduled job does: the in-play
 * feed only. `--league` is the catch-up form — it walks a whole season, which is
 * how a result that finished while the server was down gets picked up.
 *
 * Either way only SCORES, STATUS and (on a fixture the vault does not yet hold)
 * the round are written. Events are not: for this league the vault's own goal log
 * is the better one. See `services/liveSync.ts`.
 */
import { parseArgs } from 'node:util';
import { prisma } from '../db.js';
import { sportmonks, SportmonksError, normaliseFixture } from '../services/sportmonks.js';
import { syncFixtures } from '../services/liveSync.js';
import { runLiveSyncOnce } from '../jobs/liveScoreSync.js';
import { resolveVaultIds, editionKey } from '../services/entityResolution.js';
import type { ProviderFixture } from '../services/providerFixture.js';

const { values } = parseArgs({
  options: {
    league: { type: 'string' },
    season: { type: 'string' },
    dry: { type: 'boolean', default: false },
  },
});

try {
  if (values.league === undefined) {
    const summary = await runLiveSyncOnce();
    if (summary) console.log(JSON.stringify(summary, null, 2));
    else console.log('Nothing to sync.');
  } else {
    const leagueId = Number(values.league);
    const leagues = await sportmonks.leagues();
    const league = leagues.find((l) => l.id === leagueId);
    if (!league?.currentseason) {
      console.error(`League ${leagueId} is not in the plan, or has no current season.`);
      process.exit(1);
    }
    const seasonId = Number.isInteger(Number(values.season))
      ? Number(values.season)
      : league.currentseason.id;

    const mapped = await resolveVaultIds(
      'competition_edition',
      [editionKey(leagueId, seasonId)],
      'sportmonks',
    );
    if (mapped.size === 0) {
      console.error(
        `Edition not mapped. Run: npm run sm:map -- --league ${leagueId} --apply`,
      );
      process.exit(1);
    }

    const fixtures = (await sportmonks.seasonFixtures(seasonId))
      .map((f) => normaliseFixture(f, league.name))
      .filter((f): f is ProviderFixture => f !== null);

    console.log(
      `${league.name} ${league.currentseason.name}: ${fixtures.length} fixtures from SportMonks`,
    );

    if (values.dry) {
      // A dry run must not leave rows behind, so it runs inside a transaction
      // that is always rolled back. The sync opens its own transactions, so this
      // reports what it *would* see rather than pretending to run it.
      const withScore = fixtures.filter((f) => f.homeScore !== null).length;
      console.log(
        `  ${withScore} carry a score; ${fixtures.length - withScore} do not.\n` +
          '  Dry run: nothing written. Use `npm run sm:compare` for a full diff against the vault.',
      );
    } else {
      const summary = await syncFixtures(fixtures, 'sportmonks');
      console.log(JSON.stringify(summary, null, 2));
    }
  }
} catch (err) {
  if (err instanceof SportmonksError) {
    console.error(`SportMonks request failed: ${err.message}`);
    process.exitCode = 1;
  } else {
    throw err;
  }
} finally {
  await prisma.$disconnect();
}
