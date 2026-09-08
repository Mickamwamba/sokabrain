import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../db.js';
import { getStandings } from '../services/standings.js';
import { getTopScorers } from '../services/topScorers.js';
import { listMatches } from '../services/matches.js';
import {
  clubStats,
  headToHead,
  overview,
  playerStats,
  publishedTeams,
  type PlayerSort,
} from '../services/stats.js';

export const vaultRouter = Router();

const editionParams = z.object({ editionId: z.coerce.number().int().positive() });

/**
 * Editions index. Not one of the three headline endpoints, but standings and
 * top scorers are both keyed by edition id, so without a way to list editions
 * the API is not navigable.
 *
 * Only PUBLISHED editions are ever returned. Publication is an editorial
 * decision made in the admin dashboard — an edition stays invisible until
 * someone has reviewed its data quality and released it.
 */
vaultRouter.get('/editions', async (_req, res) => {
  const editions = await prisma.competition_editions.findMany({
    where: { is_published: true },
    include: {
      competitions: {
        select: {
          id: true,
          name: true,
          type: true,
          tier: true,
          countries: { select: { id: true, name: true, iso_code: true } },
        },
      },
      seasons: { select: { id: true, label: true } },
      _count: { select: { matches: true } },
    },
  });

  res.json({
    editions: editions
      .map((e) => ({
        editionId: e.id,
        competition: e.competitions.name,
        competitionType: e.competitions.type,
        tier: e.competitions.tier,
        country: e.competitions.countries?.name ?? null,
        season: e.seasons.label,
        format: e.format,
        matchCount: e._count.matches,
      }))
      .sort((a, b) => b.matchCount - a.matchCount),
  });
});

/** League table for an edition. */
vaultRouter.get('/editions/:editionId/standings', async (req, res) => {
  const params = editionParams.safeParse(req.params);
  if (!params.success) {
    return res.status(400).json({ error: 'editionId must be a positive integer' });
  }
  const { editionId } = params.data;

  const edition = await prisma.competition_editions.findFirst({
    // Unpublished editions are 404 to the public, not 403 — their existence is
    // not something the public API should confirm.
    where: { id: editionId, is_published: true },
    include: {
      competitions: { select: { name: true, type: true } },
      seasons: { select: { label: true } },
    },
  });
  if (!edition) return res.status(404).json({ error: `No edition with id ${editionId}` });

  const { standings, coverage } = await getStandings(editionId);

  res.json({
    edition: {
      editionId,
      competition: edition.competitions.name,
      competitionType: edition.competitions.type,
      season: edition.seasons.label,
    },
    // A table only really means something for a round-robin league; for a cup
    // this is still a valid summary of results, so we return it but say so.
    isLeagueTable: edition.competitions.type === 'LEAGUE',
    coverage,
    standings,
  });
});

/** Top scorers for an edition. */
const topScorersQuery = z.object({
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

vaultRouter.get('/editions/:editionId/top-scorers', async (req, res) => {
  const params = editionParams.safeParse(req.params);
  if (!params.success) {
    return res.status(400).json({ error: 'editionId must be a positive integer' });
  }
  const query = topScorersQuery.safeParse(req.query);
  if (!query.success) {
    return res.status(400).json({ error: 'limit must be an integer between 1 and 100' });
  }
  const { editionId } = params.data;

  const exists = await prisma.competition_editions.findFirst({
    where: { id: editionId, is_published: true },
    select: { id: true },
  });
  if (!exists) return res.status(404).json({ error: `No edition with id ${editionId}` });

  res.json(await getTopScorers(editionId, query.data.limit));
});

/** Match list, filterable and paginated. */
const matchesQuery = z.object({
  editionId: z.coerce.number().int().positive().optional(),
  teamId: z.coerce.number().int().positive().optional(),
  status: z
    .enum(['SCHEDULED', 'LIVE', 'FULL_TIME', 'POSTPONED', 'ABANDONED', 'CANCELLED'])
    .optional(),
  from: z.coerce.date().optional(),
  to: z.coerce.date().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(25),
  offset: z.coerce.number().int().min(0).default(0),
});

vaultRouter.get('/matches', async (req, res) => {
  const query = matchesQuery.safeParse(req.query);
  if (!query.success) {
    return res.status(400).json({
      error: 'Invalid query parameters',
      details: z.treeifyError(query.error),
    });
  }
  res.json(await listMatches(query.data));
});


/* ------------------------------------------------------------------ stats -- */
// Fan-facing aggregates. All scoped to published editions by the service layer.

vaultRouter.get('/stats/overview', async (_req, res) => {
  res.json(await overview());
});

vaultRouter.get('/teams', async (_req, res) => {
  res.json({ teams: await publishedTeams() });
});

const clubQuery = z.object({ editionId: z.coerce.number().int().positive().optional() });

vaultRouter.get('/stats/clubs', async (req, res) => {
  const q = clubQuery.safeParse(req.query);
  if (!q.success) return res.status(400).json({ error: 'editionId must be a positive integer' });
  res.json({ clubs: await clubStats(q.data.editionId) });
});

const playerQuery = z.object({
  editionId: z.coerce.number().int().positive().optional(),
  teamId: z.coerce.number().int().positive().optional(),
  position: z.enum(['GK', 'DF', 'MF', 'FW']).optional(),
  sort: z.enum(['goals', 'assists', 'appearances', 'yellowCards', 'redCards']).default('goals'),
  limit: z.coerce.number().int().min(1).max(100).default(25),
});

vaultRouter.get('/stats/players', async (req, res) => {
  const q = playerQuery.safeParse(req.query);
  if (!q.success) {
    return res.status(400).json({ error: 'Invalid query', details: z.treeifyError(q.error) });
  }
  const { editionId, teamId, position, sort, limit } = q.data;
  res.json(
    await playerStats({
      ...(editionId !== undefined && { editionId }),
      ...(teamId !== undefined && { teamId }),
      ...(position !== undefined && { position }),
      sort: sort as PlayerSort,
      limit,
    }),
  );
});

const h2hQuery = z.object({
  teamA: z.coerce.number().int().positive(),
  teamB: z.coerce.number().int().positive(),
});

vaultRouter.get('/stats/head-to-head', async (req, res) => {
  const q = h2hQuery.safeParse(req.query);
  if (!q.success) return res.status(400).json({ error: 'teamA and teamB are required team ids' });
  if (q.data.teamA === q.data.teamB) {
    return res.status(400).json({ error: 'Pick two different clubs' });
  }
  const result = await headToHead(q.data.teamA, q.data.teamB);
  if (!result) return res.status(404).json({ error: 'One or both clubs not found' });
  res.json(result);
});
