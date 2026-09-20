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
import { toProviderFixture, type ApiFootballFixture } from './apiFootball.js';
import type { ProviderFixture } from './providerFixture.js';

const TAG = '__synctest__';
const API_LEAGUE = 999001;
const API_SEASON = 2099;
const API_HOME = 999101;
const API_AWAY = 999102;
// A SECOND club pair, used only by the kickoff tests. The sync finds an existing
// match by its (edition, home, away) identity, so two tests sharing one pair
// would collide on the match an earlier test created.
const API_HOME_2 = 999103;
const API_AWAY_2 = 999104;

let editionId = 0;
let homeTeamId = 0;
let awayTeamId = 0;
let homeTeamId2 = 0;
let awayTeamId2 = 0;
let countryId = 0;
let competitionId = 0;
let seasonId = 0;
const createdMatchIds: number[] = [];

/**
 * A fixture with a published score, in the shape API-Football returns.
 *
 * The sync takes the provider-neutral shape, so these go through
 * `toProviderFixture` on the way in — which means these tests also cover that
 * normaliser rather than only the decision table.
 */
function apiFixture(overrides: {
  fixtureId: number;
  home: number | null;
  away: number | null;
  status?: string;
  /** Use the second club pair instead of the default one. */
  secondPair?: boolean;
}): ApiFootballFixture {
  const { fixtureId, home, away, status = 'FT', secondPair = false } = overrides;
  const homeApiId = secondPair ? API_HOME_2 : API_HOME;
  const awayApiId = secondPair ? API_AWAY_2 : API_AWAY;
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
      home: { id: homeApiId, name: `${TAG} Home`, logo: null },
      away: { id: awayApiId, name: `${TAG} Away`, logo: null },
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

/** The same fixture, normalised — what the sync actually consumes. */
function fixture(overrides: {
  fixtureId: number;
  home: number | null;
  away: number | null;
  status?: string;
  secondPair?: boolean;
}): ProviderFixture {
  return toProviderFixture(apiFixture(overrides));
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

  const home2 = await prisma.teams.create({
    data: { name: `${TAG} Home2`, type: 'CLUB', country_id: countryId },
  });
  const away2 = await prisma.teams.create({
    data: { name: `${TAG} Away2`, type: 'CLUB', country_id: countryId },
  });
  homeTeamId2 = home2.id;
  awayTeamId2 = away2.id;

  // Map them to API-Football ids, as `npm run af:map` would.
  await prisma.$transaction(async (tx) => {
    await recordProvenance(tx, 'competition_edition', editionId, 'api_football', editionKey(API_LEAGUE, API_SEASON));
    await recordProvenance(tx, 'team', homeTeamId, 'api_football', String(API_HOME));
    await recordProvenance(tx, 'team', awayTeamId, 'api_football', String(API_AWAY));
    await recordProvenance(tx, 'team', homeTeamId2, 'api_football', String(API_HOME_2));
    await recordProvenance(tx, 'team', awayTeamId2, 'api_football', String(API_AWAY_2));
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
        { entity_type: 'team', entity_id: { in: [homeTeamId, awayTeamId, homeTeamId2, awayTeamId2] } },
        { entity_type: 'competition_edition', entity_id: editionId },
      ],
    },
  });
  await prisma.match_events.deleteMany({ where: { match_id: { in: allMatchIds } } });
  await prisma.matches.deleteMany({ where: { id: { in: allMatchIds } } });
  await prisma.teams.deleteMany({
    where: { id: { in: [homeTeamId, awayTeamId, homeTeamId2, awayTeamId2] } },
  });
  await prisma.competition_editions.delete({ where: { id: editionId } });
  await prisma.competitions.delete({ where: { id: competitionId } });
  await prisma.seasons.delete({ where: { id: seasonId } });
  await prisma.countries.delete({ where: { id: countryId } });
  await prisma.$disconnect();
});

describe('syncFixtures', () => {
  it('creates a match that does not exist yet, with provenance', async () => {
    const s = await syncFixtures([fixture({ fixtureId: 900001, home: 2, away: 1 })], 'api_football');
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
    const s = await syncFixtures([fixture({ fixtureId: 900001, home: 2, away: 1 })], 'api_football');
    assert.equal(s.agreed, 1);
    assert.equal(s.created, 0);
    assert.equal(s.conflicts, 0);
  });

  it('advances its own earlier value as a live score progresses', async () => {
    const s = await syncFixtures([fixture({ fixtureId: 900001, home: 3, away: 1 })], 'api_football');
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

    const s = await syncFixtures([fixture({ fixtureId: 900001, home: 4, away: 0 })], 'api_football');
    assert.equal(s.updated, 1);
    assert.equal(s.conflicts, 0, 'an absent score is not canonical data being overwritten');

    const after = await prisma.matches.findUniqueOrThrow({ where: { id: m.id } });
    assert.equal(after.home_score, 4);
  });

  it('records a conflict WITHOUT overwriting when it disagrees with non-API data', async () => {
    const m = await prisma.matches.findFirstOrThrow({ where: { competition_edition_id: editionId } });
    // Vault holds 4-0 from a human; the API now claims 1-1.
    const s = await syncFixtures([fixture({ fixtureId: 900001, home: 1, away: 1 })], 'api_football');

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

  it('moves the kickoff of an UNPLAYED fixture that has been rescheduled', async () => {
    // A rescheduled future fixture is new information, not a disagreement. A
    // stale scheduled date is a defect this project has already had to fix once.
    const m = await prisma.matches.create({
      data: {
        competition_edition_id: editionId,
        home_team_id: homeTeamId2,
        away_team_id: awayTeamId2,
        kickoff_at: new Date('2099-05-01T15:00:00Z'),
        status: 'SCHEDULED',
      },
    });
    createdMatchIds.push(m.id);
    await prisma.$transaction((tx) =>
      recordProvenance(tx, 'match', m.id, 'legacy_sokafc', `${TAG}-resched`),
    );

    const f = fixture({ fixtureId: 900004, home: null, away: null, status: 'NS', secondPair: true });
    f.kickoff = new Date('2099-05-08T13:00:00Z');

    const s = await syncFixtures([f], 'api_football');
    assert.equal(s.kickoffsMoved, 1);
    const after = await prisma.matches.findUniqueOrThrow({ where: { id: m.id } });
    assert.equal(after.kickoff_at?.toISOString(), '2099-05-08T13:00:00.000Z');
  });

  it('leaves a PLAYED match’s kickoff alone even when the provider differs', async () => {
    // Once a match has a score its kickoff is canonical, so a difference is a
    // question for a human rather than something to overwrite (principle 2).
    const m = await prisma.matches.create({
      data: {
        competition_edition_id: editionId,
        home_team_id: homeTeamId2,
        away_team_id: awayTeamId2,
        kickoff_at: new Date('2099-05-01T15:00:00Z'),
        status: 'FULL_TIME',
        home_score: 2,
        away_score: 1,
      },
    });
    createdMatchIds.push(m.id);
    // Pin the provider's fixture id to THIS match. Without it the sync falls
    // back to (edition, home, away) identity and finds the match the previous
    // test created for the same pair, so the assertion would pass for the wrong
    // reason.
    await prisma.$transaction(async (tx) => {
      await recordProvenance(tx, 'match', m.id, 'legacy_sokafc', `${TAG}-played`);
      await recordProvenance(tx, 'match', m.id, 'api_football', '900005');
    });

    // Scores agree but the status differs, so this reaches the write branch
    // rather than the "agreed, change nothing" one — meaning it is the unplayed
    // guard, not an early return, that protects the kickoff.
    const f = fixture({ fixtureId: 900005, home: 2, away: 1, status: '2H', secondPair: true });
    f.kickoff = new Date('2099-06-01T13:00:00Z');

    const s = await syncFixtures([f], 'api_football');
    assert.equal(s.updated, 1, 'must reach the write branch for this to prove anything');
    assert.equal(s.kickoffsMoved, 0);
    const after = await prisma.matches.findUniqueOrThrow({ where: { id: m.id } });
    assert.equal(after.kickoff_at?.toISOString(), '2099-05-01T15:00:00.000Z');
  });

  it('tracks the clock through a match: sets it, advances it, then clears it', async () => {
    // The clock is the one genuinely transient field in this vault, and it has
    // two ways to go wrong: freezing (the score sits still for an hour while
    // the clock does not, and the sync's "nothing changed" path must still
    // write it) and sticking (a finished match keeping a stale minute, so it
    // renders as though it were still being played).
    const m = await prisma.matches.create({
      data: {
        competition_edition_id: editionId,
        home_team_id: homeTeamId2,
        away_team_id: awayTeamId2,
        kickoff_at: new Date('2099-05-01T15:00:00Z'),
        status: 'SCHEDULED',
      },
    });
    createdMatchIds.push(m.id);
    await prisma.$transaction((tx) =>
      recordProvenance(tx, 'match', m.id, 'api_football', '900006'),
    );

    // Kicks off.
    const first = fixture({ fixtureId: 900006, home: 1, away: 0, status: '2H', secondPair: true });
    first.liveMinute = 67;
    await syncFixtures([first], 'api_football');
    const during = await prisma.matches.findUniqueOrThrow({ where: { id: m.id } });
    assert.equal(during.status, 'LIVE');
    assert.equal(during.live_minute, 67);

    // Same score, later clock — this takes the "agreed" path.
    const later = fixture({ fixtureId: 900006, home: 1, away: 0, status: '2H', secondPair: true });
    later.liveMinute = 81;
    const s2 = await syncFixtures([later], 'api_football');
    assert.equal(s2.agreed, 1, 'score and status unchanged, so this is the agreed path');
    const advanced = await prisma.matches.findUniqueOrThrow({ where: { id: m.id } });
    assert.equal(advanced.live_minute, 81, 'the clock must move even when the score does not');

    // Full time. The provider may still report a minute; it must be ignored.
    const done = fixture({ fixtureId: 900006, home: 2, away: 0, status: 'FT', secondPair: true });
    done.liveMinute = 90;
    await syncFixtures([done], 'api_football');
    const after = await prisma.matches.findUniqueOrThrow({ where: { id: m.id } });
    assert.equal(after.status, 'FULL_TIME');
    assert.equal(after.live_minute, null, 'a finished match must not keep a clock');
  });

  it('skips and reports unmapped teams instead of guessing', async () => {
    const f = fixture({ fixtureId: 900002, home: 1, away: 0 });
    f.away = { id: '424242', name: 'Totally Unknown FC' };

    const s = await syncFixtures([f], 'api_football');
    assert.equal(s.created, 0);
    assert.equal(s.skipped.length, 1);
    assert.match(s.skipped[0]!.reason, /unmapped team/);
    assert.match(s.skipped[0]!.reason, /Totally Unknown FC/);
  });

  it('skips and reports an unmapped competition', async () => {
    const f = fixture({ fixtureId: 900003, home: 1, away: 0 });
    f.competition = { ...f.competition, id: '777777', season: '2099' };

    const s = await syncFixtures([f], 'api_football');
    assert.equal(s.created, 0);
    assert.equal(s.skipped.length, 1);
    assert.match(s.skipped[0]!.reason, /unmapped competition/);
  });
});
