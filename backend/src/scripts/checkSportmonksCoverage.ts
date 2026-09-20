/**
 * Report what the SportMonks subscription actually grants, and how deep it goes.
 *
 * Read-only — it writes nothing. Run it before mapping, and again whenever the
 * plan changes, because a plan covers a fixed set of leagues and a league
 * silently dropping out of it looks exactly like a league with no fixtures.
 *
 *   npm run sm:coverage
 */
import { sportmonks, SportmonksError, normaliseFixture, isAwarded } from '../services/sportmonks.js';
import { VAULT_COMPETITION_BY_PROVIDER_LEAGUE } from '../config/leagues.js';
import { prisma } from '../db.js';

try {
  const leagues = await sportmonks.leagues();
  console.log(`Subscription grants ${leagues.length} league(s).\n`);

  for (const l of leagues) {
    const season = l.currentseason;
    const vaultCompetition = VAULT_COMPETITION_BY_PROVIDER_LEAGUE[String(l.id)];
    const marker = vaultCompetition === undefined ? ' ' : '→';

    console.log(
      `${marker} [${l.id}] ${l.name} — ${l.country?.name ?? 'unknown country'} ` +
        `(${l.type}/${l.sub_type}${l.active ? '' : ', INACTIVE'})`,
    );

    if (!season) {
      console.log('      no current season published\n');
      continue;
    }

    const fixtures = await sportmonks.seasonFixtures(season.id);
    const normalised = fixtures
      .map((f) => normaliseFixture(f, l.name))
      .filter((f): f is NonNullable<typeof f> => f !== null);

    const byStatus = new Map<string, number>();
    for (const f of normalised) byStatus.set(f.status, (byStatus.get(f.status) ?? 0) + 1);

    const withScore = normalised.filter((f) => f.homeScore !== null).length;
    const goals = normalised.reduce((n, f) => n + (f.homeScore ?? 0) + (f.awayScore ?? 0), 0);
    const withRound = normalised.filter((f) => f.round !== null).length;
    const withEvents = fixtures.filter((f) => (f.events ?? []).length > 0).length;
    const awarded = fixtures.filter((f) => isAwarded(f.state_id));
    const unnormalised = fixtures.length - normalised.length;

    console.log(
      `      season ${season.name} (id ${season.id}): ${fixtures.length} fixtures, ` +
        `${withScore} with a score, ${goals} goals`,
    );
    console.log(
      `      ${withEvents} fixtures carry events, ${withRound} carry a round` +
        (unnormalised > 0 ? `, ${unnormalised} have no two participants yet` : ''),
    );
    console.log(
      `      status: ${[...byStatus.entries()].map(([s, n]) => `${s} ${n}`).join(', ')}`,
    );
    if (awarded.length > 0) {
      console.log(
        `      AWARDED (forfeited, will never reconcile from events): ` +
          awarded.map((f) => `${f.name} [${f.id}]`).join('; '),
      );
    }
    console.log(
      vaultCompetition === undefined
        ? '      no vault competition mapped — fixtures would be skipped, not written\n'
        : `      maps to vault competition ${vaultCompetition}\n`,
    );
  }

  const rate = await sportmonks.rateLimit();
  if (rate) {
    console.log(
      `Rate limit: ${rate.remaining} requests remaining for "${rate.requested_entity}", ` +
        `resets in ${rate.resets_in_seconds}s.`,
    );
  }
  console.log('Legend: → marks a league with a vault competition in config/leagues.ts');
} catch (err) {
  if (err instanceof SportmonksError) {
    console.error(`\nSportMonks request failed: ${err.message}`);
    if (err.message.includes('SPORTMONKS_TOKEN')) {
      console.error('Set SPORTMONKS_TOKEN in backend/.env.');
    }
    process.exitCode = 1;
  } else {
    throw err;
  }
} finally {
  await prisma.$disconnect();
}
