/**
 * Validate what API-Football actually covers for our target leagues.
 *
 * This is the free-tier question CLAUDE.md says to answer before paying: does
 * the provider carry the East African leagues this product is built around, and
 * with what depth? Read-only — it writes nothing.
 *
 *   npm run af:coverage
 */
import { apiFootball, ApiFootballError } from '../services/apiFootball.js';
import { TARGET_LEAGUES } from '../config/leagues.js';
import { prisma } from '../db.js';

const countries = [...new Set(TARGET_LEAGUES.map((l) => l.country))];

console.log('Checking API-Football coverage for:', countries.join(', '));
console.log();

try {
  for (const country of countries) {
    const leagues = await apiFootball.leagues({ country });

    if (leagues.length === 0) {
      console.log(`${country}: NO LEAGUES RETURNED — provider does not cover this country.`);
      console.log();
      continue;
    }

    console.log(`${country}: ${leagues.length} competition(s)`);
    for (const l of leagues) {
      const wanted = TARGET_LEAGUES.some(
        (t) =>
          t.country === country &&
          l.league.name.toLowerCase().includes(t.nameContains.toLowerCase()),
      );
      const seasons = l.seasons.map((s) => s.year);
      const current = l.seasons.find((s) => s.current);
      const fixtureCoverage = current?.coverage?.fixtures ?? {};
      const depth = Object.entries(fixtureCoverage)
        .filter(([, v]) => v)
        .map(([k]) => k);

      console.log(
        `  ${wanted ? '→' : ' '} [${l.league.id}] ${l.league.name} (${l.league.type})`,
      );
      console.log(
        `      seasons ${Math.min(...seasons)}–${Math.max(...seasons)}` +
          (current ? `, current ${current.year}` : ', no current season') +
          (depth.length > 0 ? `, fixture data: ${depth.join(', ')}` : ', no fixture detail flags'),
      );
    }
    console.log();
  }

  console.log('Legend: → marks a league matching TARGET_LEAGUES in src/config/leagues.ts');
  console.log('Use the [id] values with `npm run af:map` to build vault mappings.');
} catch (err) {
  if (err instanceof ApiFootballError) {
    console.error(`\nAPI-Football request failed: ${err.message}`);
    if (err.message.includes('API_FOOTBALL_KEY')) {
      console.error('Set API_FOOTBALL_KEY in backend/.env — a free key works for this check.');
    }
    process.exitCode = 1;
  } else {
    throw err;
  }
} finally {
  await prisma.$disconnect();
}
