import { Router } from 'express';
import { z } from 'zod';
import { Prisma } from '@prisma/client';
import { prisma } from '../db.js';
import { editionFlagSummary, suggestedIssues } from '../services/flags.js';
import { recordManualProvenance } from '../services/provenance.js';

/**
 * Competition-first admin routes.
 *
 * The dashboard browses competitions, then a season within one — which matches
 * how an editor actually works ("fix the Premier League, 2017/18 first") rather
 * than presenting 25 flat editions.
 */
export const adminCompetitionsRouter = Router();

const idParam = z.object({ id: z.coerce.number().int().positive() });

const COMPETITION_TYPES = [
  'LEAGUE', 'DOMESTIC_CUP', 'SUPER_CUP', 'CONTINENTAL_CLUB',
  'CONTINENTAL_NATIONAL', 'WORLD_CUP', 'FRIENDLY', 'QUALIFIER',
] as const;

const listQuery = z.object({
  q: z.string().max(100).optional(),
  type: z.enum(COMPETITION_TYPES).optional(),
});

/** All competitions, with season counts and how much of each is published. */
adminCompetitionsRouter.get('/competitions', async (req, res) => {
  const parsed = listQuery.safeParse(req.query);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid query' });
  const { q, type } = parsed.data;

  const competitions = await prisma.competitions.findMany({
    where: {
      ...(type !== undefined && { type }),
      // Case-insensitive substring search across name and country.
      ...(q
        ? {
            OR: [
              { name: { contains: q, mode: 'insensitive' as const } },
              { countries: { name: { contains: q, mode: 'insensitive' as const } } },
            ],
          }
        : {}),
    },
    include: {
      countries: { select: { id: true, name: true } },
      competition_editions: {
        select: { id: true, is_published: true, seasons: { select: { label: true } } },
      },
    },
    orderBy: { name: 'asc' },
  });

  const matchCounts = await prisma.matches.groupBy({
    by: ['competition_edition_id'],
    _count: { _all: true },
  });
  const byEdition = new Map(matchCounts.map((m) => [m.competition_edition_id, m._count._all]));

  res.json({
    competitions: competitions.map((c) => ({
      id: c.id,
      name: c.name,
      type: c.type,
      tier: c.tier,
      country: c.countries?.name ?? null,
      countryId: c.countries?.id ?? null,
      seasonCount: c.competition_editions.length,
      publishedCount: c.competition_editions.filter((e) => e.is_published).length,
      matchCount: c.competition_editions.reduce(
        (n, e) => n + (byEdition.get(e.id) ?? 0),
        0,
      ),
      seasons: c.competition_editions
        .map((e) => e.seasons.label)
        .sort()
        .reverse(),
    })),
  });
});

const createBody = z.object({
  name: z.string().min(1).max(120),
  type: z.enum(COMPETITION_TYPES),
  countryId: z.number().int().positive().nullish(),
  tier: z.number().int().min(1).max(10).nullish(),
});

adminCompetitionsRouter.post('/competitions', async (req, res) => {
  const parsed = createBody.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'Invalid request body', details: z.treeifyError(parsed.error) });
  }
  const { name, type, countryId, tier } = parsed.data;

  // slug is UNIQUE in the schema; derive one and surface a clash as a 409
  // rather than letting a raw constraint error escape as a 500.
  const slug = name
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
    .slice(0, 60);

  try {
    const competition = await prisma.$transaction(async (tx) => {
      const created = await tx.competitions.create({
        data: {
          name,
          slug,
          type,
          ...(countryId != null && { country_id: countryId }),
          ...(tier != null && { tier }),
        },
      });
      await recordManualProvenance(tx, 'competition', created.id);
      return created;
    });
    res.status(201).json({ competition });
  } catch (err) {
    if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002') {
      return res.status(409).json({ error: `A competition named "${name}" already exists.` });
    }
    throw err;
  }
});

/** One competition with each of its seasons, ready for the season picker. */
adminCompetitionsRouter.get('/competitions/:id', async (req, res) => {
  const params = idParam.safeParse(req.params);
  if (!params.success) return res.status(400).json({ error: 'id must be a positive integer' });

  const competition = await prisma.competitions.findUnique({
    where: { id: params.data.id },
    include: {
      countries: { select: { id: true, name: true } },
      competition_editions: {
        include: {
          seasons: { select: { id: true, label: true } },
          _count: { select: { matches: true } },
        },
      },
    },
  });
  if (!competition) return res.status(404).json({ error: `No competition with id ${params.data.id}` });

  const editions = await Promise.all(
    competition.competition_editions.map(async (e) => {
      const [flags, issues] = await Promise.all([
        editionFlagSummary(e.id),
        suggestedIssues(e.id),
      ]);
      return {
        editionId: e.id,
        season: e.seasons.label,
        seasonId: e.seasons.id,
        matchCount: e._count.matches,
        isPublished: e.is_published,
        publishedAt: e.published_at,
        openFlags: flags.total,
        blockers: flags.bySeverity.BLOCKER,
        canPublish: flags.bySeverity.BLOCKER === 0,
        issues,
      };
    }),
  );
  // Newest season first — an editor usually wants the most recent.
  editions.sort((a, b) => b.season.localeCompare(a.season));

  res.json({
    competition: {
      id: competition.id,
      name: competition.name,
      type: competition.type,
      tier: competition.tier,
      country: competition.countries?.name ?? null,
    },
    editions,
  });
});

/**
 * Everything an editor needs about one season: completeness counts, flags, and
 * the running data-quality picture.
 */
adminCompetitionsRouter.get('/editions/:id/summary', async (req, res) => {
  const params = idParam.safeParse(req.params);
  if (!params.success) return res.status(400).json({ error: 'id must be a positive integer' });
  const editionId = params.data.id;

  const edition = await prisma.competition_editions.findUnique({
    where: { id: editionId },
    include: {
      competitions: { select: { id: true, name: true, type: true } },
      seasons: { select: { label: true } },
    },
  });
  if (!edition) return res.status(404).json({ error: `No edition with id ${editionId}` });

  const [counts] = await prisma.$queryRaw<
    {
      total: number;
      fullTime: number;
      scheduled: number;
      missingScore: number;
      withEvents: number;
      goals: number;
      teams: number;
    }[]
  >(Prisma.sql`
    SELECT
      count(*)::int                                                              AS total,
      count(*) FILTER (WHERE status = 'FULL_TIME')::int                          AS "fullTime",
      count(*) FILTER (WHERE status = 'SCHEDULED')::int                          AS scheduled,
      count(*) FILTER (WHERE status = 'FULL_TIME'
                       AND (home_score IS NULL OR away_score IS NULL))::int      AS "missingScore",
      count(*) FILTER (WHERE EXISTS (
        SELECT 1 FROM match_events e WHERE e.match_id = matches.id))::int        AS "withEvents",
      COALESCE(sum(home_score + away_score), 0)::int                             AS goals,
      (SELECT count(DISTINCT t)::int FROM (
        SELECT home_team_id AS t FROM matches WHERE competition_edition_id = ${editionId}
        UNION SELECT away_team_id FROM matches WHERE competition_edition_id = ${editionId}
      ) x)                                                                       AS teams
    FROM matches
    WHERE competition_edition_id = ${editionId}
  `);

  const [eventStats] = await prisma.$queryRaw<
    { goalEvents: number; unattributed: number; cards: number }[]
  >(Prisma.sql`
    SELECT
      count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL'))::int          AS "goalEvents",
      count(*) FILTER (WHERE e.type IN ('GOAL','PENALTY_GOAL')
                       AND e.player_id IS NULL)::int                                     AS unattributed,
      count(*) FILTER (WHERE e.type IN ('YELLOW_CARD','RED_CARD','SECOND_YELLOW'))::int   AS cards
    FROM match_events e
    JOIN matches m ON m.id = e.match_id
    WHERE m.competition_edition_id = ${editionId}
  `);

  const [flags, issues] = await Promise.all([
    editionFlagSummary(editionId),
    suggestedIssues(editionId),
  ]);

  res.json({
    edition: {
      editionId,
      competitionId: edition.competitions.id,
      competition: edition.competitions.name,
      competitionType: edition.competitions.type,
      season: edition.seasons.label,
      isPublished: edition.is_published,
      publishedAt: edition.published_at,
    },
    counts: counts ?? {
      total: 0, fullTime: 0, scheduled: 0, missingScore: 0, withEvents: 0, goals: 0, teams: 0,
    },
    events: eventStats ?? { goalEvents: 0, unattributed: 0, cards: 0 },
    flags: flags.bySeverity,
    openFlags: flags.total,
    canPublish: flags.bySeverity.BLOCKER === 0,
    issues,
  });
});

/** Countries and seasons, for the create-competition form. */
adminCompetitionsRouter.get('/reference', async (_req, res) => {
  const [countries, seasons] = await Promise.all([
    prisma.countries.findMany({ select: { id: true, name: true }, orderBy: { name: 'asc' } }),
    prisma.seasons.findMany({ select: { id: true, label: true }, orderBy: { label: 'desc' } }),
  ]);
  res.json({ countries, seasons, competitionTypes: COMPETITION_TYPES });
});
