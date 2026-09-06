/**
 * Build the API-Football ↔ vault id mappings the sync job depends on.
 *
 *   npm run af:map -- --league 123 --season 2025 --edition 17          (dry run)
 *   npm run af:map -- --league 123 --season 2025 --edition 17 --apply
 *
 * `--league`/`--season` are API-Football's ids (from `npm run af:coverage`);
 * `--edition` is the vault `competition_editions.id` they correspond to.
 *
 * Team matching is by normalised name and only ever proposes EXACT matches.
 * Anything ambiguous or unmatched is listed for a human to map by hand — a
 * wrong team mapping would silently corrupt scores on every future sync, so
 * this deliberately refuses to guess.
 */
import { parseArgs } from 'node:util';
import { prisma } from '../db.js';
import { apiFootball, ApiFootballError } from '../services/apiFootball.js';
import { editionKey, proposeTeamMatches } from '../services/entityResolution.js';
import { recordProvenance } from '../services/provenance.js';

const { values } = parseArgs({
  options: {
    league: { type: 'string' },
    season: { type: 'string' },
    edition: { type: 'string' },
    apply: { type: 'boolean', default: false },
  },
});

const leagueId = Number(values.league);
const season = Number(values.season);
const editionId = Number(values.edition);

if (![leagueId, season, editionId].every(Number.isInteger)) {
  console.error(
    'Usage: npm run af:map -- --league <apiLeagueId> --season <year> --edition <vaultEditionId> [--apply]',
  );
  process.exit(1);
}

try {
  const edition = await prisma.competition_editions.findUnique({
    where: { id: editionId },
    include: { competitions: { select: { name: true } }, seasons: { select: { label: true } } },
  });
  if (!edition) {
    console.error(`No vault competition_edition with id ${editionId}`);
    process.exit(1);
  }

  const apiTeams = (await apiFootball.teams(leagueId, season)).map((t) => t.team);
  const proposals = await proposeTeamMatches(apiTeams);
  const matched = proposals.filter((p) => p.vaultId !== null);
  const unmatched = proposals.filter((p) => p.vaultId === null);

  console.log(
    `Edition #${editionId}: ${edition.competitions.name} ${edition.seasons.label}`,
  );
  console.log(`API league ${leagueId}, season ${season}: ${apiTeams.length} teams`);
  console.log();
  console.log(`Exact name matches (${matched.length}):`);
  for (const m of matched) console.log(`  ${m.apiName}  →  #${m.vaultId} ${m.vaultName}`);

  if (unmatched.length > 0) {
    console.log();
    console.log(`Unmatched (${unmatched.length}) — map these by hand or create the teams:`);
    for (const m of unmatched) console.log(`  [${m.apiId}] ${m.apiName}`);
  }

  if (!values.apply) {
    console.log();
    console.log('Dry run. Re-run with --apply to write these mappings.');
  } else {
    await prisma.$transaction(async (tx) => {
      await recordProvenance(
        tx,
        'competition_edition',
        editionId,
        'api_football',
        editionKey(leagueId, season),
      );
      for (const m of matched) {
        await recordProvenance(tx, 'team', m.vaultId!, 'api_football', String(m.apiId));
      }
    });
    console.log();
    console.log(`Wrote 1 edition mapping and ${matched.length} team mappings.`);
    if (unmatched.length > 0) {
      console.log(
        `${unmatched.length} team(s) remain unmapped — fixtures involving them will be skipped and reported.`,
      );
    }
  }
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
