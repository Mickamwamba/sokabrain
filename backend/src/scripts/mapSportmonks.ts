/**
 * Build the SportMonks ↔ vault id mappings the sync depends on.
 *
 *   npm run sm:map -- --league 884                 (dry run, current season)
 *   npm run sm:map -- --league 884 --apply
 *   npm run sm:map -- --league 884 --season 28598 --edition 19 --apply
 *
 * `--league` is SportMonks' league id (from `npm run sm:coverage`). The season
 * defaults to the one SportMonks publishes as current, and the vault edition is
 * resolved from `VAULT_COMPETITION_BY_PROVIDER_LEAGUE` plus the season's label —
 * pass `--season`/`--edition` to override either.
 *
 * Team matching proposes only an exact hit on a single vault team, either on the
 * normalised name or on a written alias in `config/teamAliases.ts`. Anything
 * ambiguous or unmatched is listed for a human — a wrong team mapping silently
 * corrupts scores on every future sync, so this refuses to guess.
 */
import { parseArgs } from 'node:util';
import { prisma } from '../db.js';
import { sportmonks, SportmonksError } from '../services/sportmonks.js';
import { editionKey, proposeTeamMatches } from '../services/entityResolution.js';
import { recordProvenance } from '../services/provenance.js';
import { VAULT_COMPETITION_BY_PROVIDER_LEAGUE } from '../config/leagues.js';

const { values } = parseArgs({
  options: {
    league: { type: 'string' },
    season: { type: 'string' },
    edition: { type: 'string' },
    apply: { type: 'boolean', default: false },
  },
});

const leagueId = Number(values.league);
if (!Number.isInteger(leagueId)) {
  console.error('Usage: npm run sm:map -- --league <sportmonksLeagueId> [--season <id>] [--edition <id>] [--apply]');
  process.exit(1);
}

try {
  const leagues = await sportmonks.leagues();
  const league = leagues.find((l) => l.id === leagueId);
  if (!league) {
    console.error(
      `League ${leagueId} is not in this subscription. Granted: ${leagues
        .map((l) => `${l.id} (${l.name})`)
        .join(', ')}`,
    );
    process.exit(1);
  }

  // Resolve the season: an explicit --season, else the one marked current.
  let seasonId = Number(values.season);
  let seasonName = league.currentseason?.name;
  if (!Number.isInteger(seasonId)) {
    if (!league.currentseason) {
      console.error(`League ${leagueId} has no current season; pass --season explicitly.`);
      process.exit(1);
    }
    seasonId = league.currentseason.id;
    seasonName = league.currentseason.name;
  } else if (seasonName === undefined) {
    const seasons = await sportmonks.seasons(leagueId);
    seasonName = seasons.find((s) => s.id === seasonId)?.name;
  }
  if (seasonName === undefined) {
    console.error(`Could not determine the name of season ${seasonId}.`);
    process.exit(1);
  }

  // Resolve the vault edition: an explicit --edition, else competition + label.
  let editionId = Number(values.edition);
  if (!Number.isInteger(editionId)) {
    const competitionId = VAULT_COMPETITION_BY_PROVIDER_LEAGUE[String(leagueId)];
    if (competitionId === undefined) {
      console.error(
        `No vault competition is mapped to SportMonks league ${leagueId} (${league.name}).\n` +
          'Add it to VAULT_COMPETITION_BY_PROVIDER_LEAGUE in src/config/leagues.ts, or pass --edition.',
      );
      process.exit(1);
    }
    const found = await prisma.competition_editions.findFirst({
      where: { competition_id: competitionId, seasons: { label: seasonName } },
      select: { id: true },
    });
    if (!found) {
      console.error(
        `No vault competition_edition for competition ${competitionId} season "${seasonName}". ` +
          'Create it first, or pass --edition.',
      );
      process.exit(1);
    }
    editionId = found.id;
  }

  const edition = await prisma.competition_editions.findUnique({
    where: { id: editionId },
    include: { competitions: { select: { name: true } }, seasons: { select: { label: true } } },
  });
  if (!edition) {
    console.error(`No vault competition_edition with id ${editionId}`);
    process.exit(1);
  }

  const teams = await sportmonks.teams(seasonId);
  const proposals = await proposeTeamMatches(teams);
  const matched = proposals.filter((p) => p.vaultId !== null);
  const exact = proposals.filter((p) => p.confidence === 'exact');
  const viaAlias = proposals.filter((p) => p.confidence === 'alias');
  const unmatched = proposals.filter((p) => p.vaultId === null);

  console.log(`SportMonks league ${leagueId} "${league.name}" season ${seasonName} (id ${seasonId})`);
  console.log(`Vault edition #${editionId}: ${edition.competitions.name} ${edition.seasons.label}`);
  console.log(`${teams.length} teams in the season\n`);

  console.log(`Exact name matches (${exact.length}):`);
  for (const m of exact) console.log(`  [${m.apiId}] ${m.apiName}  →  #${m.vaultId} ${m.vaultName}`);

  if (viaAlias.length > 0) {
    console.log(`\nMatched via a written alias (${viaAlias.length}) — config/teamAliases.ts:`);
    for (const m of viaAlias) console.log(`  [${m.apiId}] ${m.apiName}  →  #${m.vaultId} ${m.vaultName}`);
  }

  if (unmatched.length > 0) {
    console.log(`\nUnmatched (${unmatched.length}) — map by hand or create the teams:`);
    for (const m of unmatched) console.log(`  [${m.apiId}] ${m.apiName}`);
  }

  if (!values.apply) {
    console.log('\nDry run. Re-run with --apply to write these mappings.');
  } else {
    await prisma.$transaction(async (tx) => {
      await recordProvenance(
        tx,
        'competition_edition',
        editionId,
        'sportmonks',
        editionKey(leagueId, seasonId),
      );
      for (const m of matched) {
        await recordProvenance(tx, 'team', m.vaultId!, 'sportmonks', m.apiId);
      }
    });
    console.log(`\nWrote 1 edition mapping and ${matched.length} team mappings.`);
    if (unmatched.length > 0) {
      console.log(
        `${unmatched.length} team(s) remain unmapped — fixtures involving them will be skipped and reported.`,
      );
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
