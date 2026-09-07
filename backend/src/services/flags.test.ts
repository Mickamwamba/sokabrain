/**
 * Tests for the editorial rules: publication gating and blocker flags.
 * Runs against the real database with a throwaway edition.
 */
import { after, before, describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { prisma } from '../db.js';
import { editionFlagSummary, publishEdition, unpublishEdition, suggestedIssues } from './flags.js';

const TAG = '__flagtest__';
let editionId = 0;
let competitionId = 0;
let seasonId = 0;
let countryId = 0;
let homeId = 0;
let awayId = 0;
let matchId = 0;
let adminId = 0;

before(async () => {
  const admin = await prisma.admins.findFirstOrThrow({ select: { id: true } });
  adminId = admin.id;

  const country = await prisma.countries.create({ data: { name: `${TAG} Country`, iso_code: 'ZZY' } });
  countryId = country.id;
  const comp = await prisma.competitions.create({
    data: { name: `${TAG} Comp`, slug: `${TAG}-comp`, type: 'LEAGUE', country_id: countryId },
  });
  competitionId = comp.id;
  const season = await prisma.seasons.create({ data: { label: `${TAG}-2099` } });
  seasonId = season.id;
  const edition = await prisma.competition_editions.create({
    data: { competition_id: competitionId, season_id: seasonId },
  });
  editionId = edition.id;

  const h = await prisma.teams.create({ data: { name: `${TAG} H`, type: 'CLUB', country_id: countryId } });
  const a = await prisma.teams.create({ data: { name: `${TAG} A`, type: 'CLUB', country_id: countryId } });
  homeId = h.id;
  awayId = a.id;
  // A finished match with no score — the exact shape `suggestedIssues` looks for.
  const match = await prisma.matches.create({
    data: {
      competition_edition_id: editionId,
      home_team_id: homeId,
      away_team_id: awayId,
      status: 'FULL_TIME',
    },
  });
  matchId = match.id;
});

after(async () => {
  await prisma.data_flags.deleteMany({
    where: {
      OR: [
        { entity_type: 'competition_edition', entity_id: editionId },
        { entity_type: 'match', entity_id: matchId },
      ],
    },
  });
  await prisma.matches.deleteMany({ where: { id: matchId } });
  await prisma.teams.deleteMany({ where: { id: { in: [homeId, awayId] } } });
  await prisma.competition_editions.delete({ where: { id: editionId } });
  await prisma.competitions.delete({ where: { id: competitionId } });
  await prisma.seasons.delete({ where: { id: seasonId } });
  await prisma.countries.delete({ where: { id: countryId } });
  await prisma.$disconnect();
});

describe('publication gating', () => {
  it('starts unpublished — nothing is public until someone says so', async () => {
    const e = await prisma.competition_editions.findUniqueOrThrow({ where: { id: editionId } });
    assert.equal(e.is_published, false);
  });

  it('publishes when there are no blocker flags, recording who and when', async () => {
    const result = await publishEdition(editionId, adminId);
    assert.equal(result.ok, true);

    const e = await prisma.competition_editions.findUniqueOrThrow({ where: { id: editionId } });
    assert.equal(e.is_published, true);
    assert.equal(e.published_by, adminId);
    assert.ok(e.published_at);
  });

  it('refuses to publish over an open BLOCKER flag', async () => {
    await unpublishEdition(editionId);
    const flag = await prisma.data_flags.create({
      data: {
        entity_type: 'competition_edition',
        entity_id: editionId,
        severity: 'BLOCKER',
        reason: 'scores missing',
        created_by: adminId,
      },
    });

    const result = await publishEdition(editionId, adminId);
    assert.equal(result.ok, false);
    if (result.ok) return;
    assert.equal(result.blockers.length, 1);

    const e = await prisma.competition_editions.findUniqueOrThrow({ where: { id: editionId } });
    assert.equal(e.is_published, false, 'a refused publish must not flip the flag');

    // Resolving it clears the way.
    await prisma.data_flags.update({
      where: { id: flag.id },
      data: { status: 'RESOLVED', resolved_by: adminId, resolved_at: new Date() },
    });
    assert.equal((await publishEdition(editionId, adminId)).ok, true);
  });

  it('treats WARNING and INFO as advisory, not blocking', async () => {
    await unpublishEdition(editionId);
    await prisma.data_flags.create({
      data: {
        entity_type: 'competition_edition',
        entity_id: editionId,
        severity: 'WARNING',
        reason: 'thin event log',
        created_by: adminId,
      },
    });
    assert.equal((await publishEdition(editionId, adminId)).ok, true);
  });

  it('counts flags on matches inside the edition, not just the edition row', async () => {
    await prisma.data_flags.create({
      data: {
        entity_type: 'match',
        entity_id: matchId,
        severity: 'BLOCKER',
        reason: 'no score recorded',
        created_by: adminId,
      },
    });
    const summary = await editionFlagSummary(editionId);
    assert.equal(summary.bySeverity.BLOCKER, 1);

    await unpublishEdition(editionId);
    assert.equal(
      (await publishEdition(editionId, adminId)).ok,
      false,
      'a blocker on a match must block its edition',
    );
  });

  it('detects the real data issues an editor should act on', async () => {
    const issues = await suggestedIssues(editionId);
    const missing = issues.find((i) => i.key === 'missing_scores');
    assert.ok(missing, 'a FULL_TIME match with no score must be reported');
    assert.equal(missing.count, 1);
    assert.equal(missing.severity, 'BLOCKER');
  });
});
