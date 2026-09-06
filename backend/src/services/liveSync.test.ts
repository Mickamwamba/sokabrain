/**
 * Integration tests for the live-score sync decision table.
 *
 * These run against the real database and the real schema (no mocking of
 * Prisma), because what is being tested is precisely the interaction between
 * the sync rules and the vault's provenance/reconciliation tables. Fixtures are
 * synthetic, so no API key is needed.
 *
 *   npm test
 *
 * Everything created here is namespaced and removed in teardown; the test
 * refuses to touch pre-existing vault rows.
 */
import { after, before, describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { prisma } from '../db.js';
import { syncFixtures } from './liveSync.js';
import { editionKey } from './entityResolution.js';
import { recordProvenance, getSourceId } from './provenance.js';
import type { ApiFootballFixture } from './apiFootball.js';

const TAG = '__synctest__';
const API_LEAGUE = 999001;
const API_SEASON = 2099;
const API_HOME = 999101;
const API_AWAY = 999102;

let editionId = 0;
let homeTeamId = 0;
let awayTeamId = 0;
let countryId = 0;
let competitionId = 0;
let seasonId = 0;
const createdMatchIds: number[] = [];

/** A fixture with a published score, in the shape the API returns. */
function fixture(overrides: {
  fixtureId: number;
  home: number | null;
  away: number | null;
  status?: string;
}): ApiFootballFixture {
  const { fixtureId, home, away, status = 'FT' } = overrides;
  return {
    fixture: {
      id: fixtureId,
      date: '2099-05-01T15:00:00+00:00',
      referee: null,
      venue: { id: null, name: null, city: null },
      status: { long: 'Match Finished', short: status, elapsed: 90 },
    },
    league: {
      id: API_LEAGUE,
      name: `${TAG} League`,
      country: 'Testland',
      season: API_SEASON,
      round: 'Regular Season - 1',
    },
    teams: {
      home: { id: API_HOME, name: `${TAG} Home`, logo: null },
      away: { id: API_AWAY, name: `${TAG} Away`, logo: null },
    },
    goals: { home, away },
    score: {
      halftime: { home: null, away: null },
      fulltime: { home, away },
      extratime: { home: null, away: null },
      penalty: { home: null, away: null },
    },
  };
}

before(async () => {
  const country = await prisma.countries.create({
    data: { name: `${TAG} Country`, iso_code: 'ZZZ' },
  });
  countryId = country.id;
  const competition = await prisma.competitions.create({
    data: { name: `${TAG} Competition`, slug: `${TAG}-comp`, type: 'LEAGUE', country_id: countryId },
  });
  competitionId = competition.id;
  const season = await prisma.seasons.create({ data: { label: `${TAG}-2099` } });
  seasonId = season.id;
  const edition = await prisma.competition_editions.create({
    data: { competition_id: competitionId, season_id: seasonId, format: 'ROUND_ROBIN' },
  });
  editionId = edition.id;

  const home = await prisma.teams.create({
    data: { name: `${TAG} Home`, type: 'CLUB', country_id: countryId },
  });
  const away = await prisma.teams.create({
    data: { name: `${TAG} Away`, type: 'CLUB', country_id: countryId },
  });
  homeTeamId = home.id;
  awayTeamId = away.id;

  // Map them to API-Football ids, as `npm run af:map` would.
  await prisma.$transaction(async (tx) => {
    await recordProvenance(tx, 'competition_edition', editionId, 'api_football', editionKey(API_LEAGUE, API_SEASON));
    await recordProvenance(tx, 'team', homeTeamId, 'api_football', String(API_HOME));
    await recordProvenance(tx, 'team', awayTeamId, 'api_football', String(API_AWAY));
  });
});

after(async () => {
  const matchIds = (
    await prisma.matches.findMany({ where: { competition_edition_id: editionId }, select: { id: true } })
  ).map((m) => m.id);
  const allMatchIds = [...new Set([...matchIds, ...createdMatchIds])];

  await prisma.reconciliation_diffs.deleteMany({ where: { entity_id_a: { in: allMatchIds } } });
  await prisma.reconciliation_runs.deleteMany({
    where: { notes: { contains: 'Automatic live-score sync' } },
  });
  await prisma.entity_source_map.deleteMany({
    where: {
      OR: [
        { entity_type: 'match', entity_id: { in: allMatchIds } },
        { entity_type: 'team', entity_id: { in: [homeTeamId, awayTeamId] } },
        { entity_type: 'competition_edition', entity_id: editionId },
      ],
    },
  });
  await prisma.match_events.deleteMany({ where: { match_id: { in: allMatchIds } } });
  await prisma.matches.deleteMany({ where: { id: { in: allMatchIds } } });
  await prisma.teams.deleteMany({ where: { id: { in: [homeTeamId, awayTeamId] } } });
  await prisma.competition_editions.delete({ where: { id: editionId } });
  await prisma.competitions.delete({ where: { id: competitionId } });
  await prisma.seasons.delete({ where: { id: seasonId } });
  await prisma.countries.delete({ where: { id: countryId } });
  await prisma.$disconnect();
});

describe('syncFixtures', () => {
  it('creates a match that does not exist yet, with provenance', async () => {
    const s = await syncFixtures([fixture({ fixtureId: 900001, home: 2, away: 1 })]);
    assert.equal(s.created, 1);
    assert.equal(s.conflicts, 0);

    const m = await prisma.matches.findFirst({ where: { competition_edition_id: editionId } });
    assert.ok(m);
    createdMatchIds.push(m.id);
    assert.equal(m.home_score, 2);
    assert.equal(m.away_score, 1);
    assert.equal(m.status, 'FULL_TIME');

    const apiSourceId = await getSourceId('api_football');
    const prov = await prisma.entity_source_map.findFirst({
      where: { entity_type: 'match', entity_id: m.id, data_source_id: apiSourceId },
    });
    assert.ok(prov, 'every synced match must carry api_football provenance');
    assert.equal(prov.external_id, '900001');
  });

  it('reports agreement without rewriting anything', async () => {
    const s = await syncFixtures([fixture({ fixtureId: 900001, home: 2, away: 1 })]);
    assert.equal(s.agreed, 1);
    assert.equal(s.created, 0);
    assert.equal(s.conflicts, 0);
  });

  it('advances its own earlier value as a live score progresses', async () => {
    const s = await syncFixtures([fixture({ fixtureId: 900001, home: 3, away: 1 })]);
    assert.equal(s.updated, 1);
    assert.equal(s.conflicts, 0, 'the API updating its own value is not a cross-source conflict');

    const m = await prisma.matches.findFirst({ where: { competition_edition_id: editionId } });
    assert.equal(m?.home_score, 3);
  });

  it('fills a score the vault does not have, rather than calling it a conflict', async () => {
    const m = await prisma.matches.findFirstOrThrow({ where: { competition_edition_id: editionId } });
    await prisma.matches.update({
      where: { id: m.id },
      data: { home_score: null, away_score: null },
    });
    // Give it legacy provenance so it is no longer API-only.
    await prisma.$transaction((tx) =>
      recordProvenance(tx, 'match', m.id, 'manual_admin', String(m.id)),
    );

    const s = await syncFixtures([fixture({ fixtureId: 900001, home: 4, away: 0 })]);
    assert.equal(s.updated, 1);
    assert.equal(s.conflicts, 0, 'an absent score is not canonical data being overwritten');

    const after = await prisma.matches.findUniqueOrThrow({ where: { id: m.id } });
    assert.equal(after.home_score, 4);
  });

  it('records a conflict WITHOUT overwriting when it disagrees with non-API data', async () => {
    const m = await prisma.matches.findFirstOrThrow({ where: { competition_edition_id: editionId } });
    // Vault holds 4-0 from a human; the API now claims 1-1.
    const s = await syncFixtures([fixture({ fixtureId: 900001, home: 1, away: 1 })]);

    assert.equal(s.conflicts, 1);
    assert.equal(s.updated, 0);
    assert.ok(s.reconciliationRunId, 'a conflict must open a reconciliation run');

    const after = await prisma.matches.findUniqueOrThrow({ where: { id: m.id } });
    assert.equal(after.home_score, 4, 'vault score must be left alone');
    assert.equal(after.away_score, 0, 'vault score must be left alone');

    const diffs = await prisma.reconciliation_diffs.findMany({
      where: { reconciliation_run_id: s.reconciliationRunId! },
      orderBy: { field_name: 'asc' },
    });
    assert.equal(diffs.length, 2, 'one diff row per disagreeing field');
    assert.deepEqual(
      diffs.map((d) => [d.field_name, d.value_a, d.value_b, d.resolution]),
      [
        ['away_score', '1', '0', 'PENDING'],
        ['home_score', '1', '4', 'PENDING'],
      ],
    );
  });

  it('skips and reports unmapped teams instead of guessing', async () => {
    const f = fixture({ fixtureId: 900002, home: 1, away: 0 });
    f.teams.away = { id: 424242, name: 'Totally Unknown FC', logo: null };

    const s = await syncFixtures([f]);
    assert.equal(s.created, 0);
    assert.equal(s.skipped.length, 1);
    assert.match(s.skipped[0]!.reason, /unmapped team/);
    assert.match(s.skipped[0]!.reason, /Totally Unknown FC/);
  });

  it('skips and reports an unmapped competition', async () => {
    const f = fixture({ fixtureId: 900003, home: 1, away: 0 });
    f.league = { ...f.league, id: 777777, season: 2099 };

    const s = await syncFixtures([f]);
    assert.equal(s.created, 0);
    assert.equal(s.skipped.length, 1);
    assert.match(s.skipped[0]!.reason, /unmapped competition/);
  });
});
