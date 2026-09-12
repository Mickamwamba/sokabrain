import { Router, type Request, type Response } from 'express';
import { Prisma } from '@prisma/client';
import { z } from 'zod';
import { prisma } from '../db.js';
import { hashPassword } from '../auth/password.js';
import { recordManualProvenance, type ProvenanceEntity } from '../services/provenance.js';

/**
 * Create, read, update and delete for the vault's reference entities — players,
 * teams, competitions, seasons, editions, their participants — and for admin
 * accounts.
 *
 * Two rules run through all of it:
 *
 * 1. Every create and update records `manual_admin` provenance in the same
 *    transaction as the write (design principle 1).
 *
 * 2. A delete never cascades through match history. It is refused with a 409
 *    that says what depends on the row ("Azam FC has 528 matches"), because the
 *    only thing worse than a vault with a stray team in it is a vault that lost
 *    528 matches to a misclick. Only rows nothing depends on can go, and their
 *    provenance goes with them.
 */
export const manageRouter = Router();

const idParam = z.object({ id: z.coerce.number().int().positive() });

const pageQuery = z.object({
  q: z.string().trim().max(100).optional(),
  page: z.coerce.number().int().min(1).default(1),
  pageSize: z.coerce.number().int().min(1).max(100).default(25),
});

/** Parse `:id`, answering 400 itself when it is not a positive integer. */
function parseId(req: Request, res: Response): number | null {
  const parsed = idParam.safeParse(req.params);
  if (!parsed.success) {
    res.status(400).json({ error: 'id must be a positive integer' });
    return null;
  }
  return parsed.data.id;
}

function parseBody<T extends z.ZodType>(schema: T, req: Request, res: Response): z.infer<T> | null {
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    // The first issue, phrased for a person — the dashboard shows this verbatim.
    const first = parsed.error.issues[0];
    const where = first?.path.length ? `${first.path.join('.')}: ` : '';
    res.status(400).json({
      error: `${where}${first?.message ?? 'Invalid request body'}`,
      details: z.treeifyError(parsed.error),
    });
    return null;
  }
  return parsed.data;
}

/** Drop undefined keys: absent means "leave unchanged", explicit null means "clear". */
function definedOnly<T extends Record<string, unknown>>(
  obj: T,
): { [K in keyof T]: Exclude<T[K], undefined> } {
  return Object.fromEntries(
    Object.entries(obj).filter(([, v]) => v !== undefined),
  ) as { [K in keyof T]: Exclude<T[K], undefined> };
}

/**
 * Turn a unique-constraint violation into a 409 a person can act on, instead of
 * letting it escape as a 500. Returns true when it handled the error.
 */
function conflict(err: unknown, res: Response, message: string): boolean {
  if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002') {
    res.status(409).json({ error: message });
    return true;
  }
  return false;
}

/**
 * Refuse a delete that would orphan or destroy other records.
 *
 * `blockers` are counted before anything is touched; the message lists every
 * non-zero one so an editor knows what to deal with first.
 */
function refuseIfReferenced(
  res: Response,
  what: string,
  blockers: Record<string, number>,
): boolean {
  const found = Object.entries(blockers).filter(([, n]) => n > 0);
  if (found.length === 0) return false;
  // Labels are written "singular|plural" so one match reads as one match.
  const phrase = ([label, n]: [string, number]) => {
    const [one, many] = label.split('|');
    return `${n.toLocaleString()} ${n === 1 ? one : (many ?? one)}`;
  };
  res.status(409).json({
    error: `${what} can't be deleted: it has ${found.map(phrase).join(', ')}. Remove or reassign those first.`,
    blockers: Object.fromEntries(found.map(([label, n]) => [label.split('|').pop()!, n])),
  });
  return true;
}

/** What depends on a row, for an edit page to show before anyone tries a delete. */
function usageList(blockers: Record<string, number>) {
  return Object.entries(blockers).map(([label, count]) => {
    const [one, many] = label.split('|');
    return { label: count === 1 ? one! : (many ?? one!), count };
  });
}

async function dropProvenance(tx: Prisma.TransactionClient, type: ProvenanceEntity, id: number) {
  await tx.entity_source_map.deleteMany({ where: { entity_type: type, entity_id: id } });
}

const paged = (page: number, pageSize: number) => ({ skip: (page - 1) * pageSize, take: pageSize });

/* ================================================================ players == */

const playerBody = z.object({
  full_name: z.string().trim().min(1, 'A player needs a name').max(150),
  first_name: z.string().trim().max(60).nullish(),
  last_name: z.string().trim().max(60).nullish(),
  dob: z.coerce.date().nullish(),
  nationality_id: z.number().int().positive().nullish(),
  position: z.enum(['GK', 'DF', 'MF', 'FW']).nullish(),
  height_cm: z.number().int().min(100).max(250).nullish(),
  preferred_foot: z.enum(['LEFT', 'RIGHT', 'BOTH']).nullish(),
  photo_url: z.string().max(255).nullish(),
});

manageRouter.get('/players', async (req, res) => {
  const q = pageQuery.extend({ teamId: z.coerce.number().int().positive().optional() }).safeParse(req.query);
  if (!q.success) return res.status(400).json({ error: 'Invalid query' });
  const { q: search, page, pageSize, teamId } = q.data;

  const where: Prisma.playersWhereInput = {
    ...(search && { full_name: { contains: search, mode: 'insensitive' } }),
    ...(teamId && { player_team_stints: { some: { team_id: teamId } } }),
  };

  const [total, rows] = await Promise.all([
    prisma.players.count({ where }),
    prisma.players.findMany({
      where,
      orderBy: [{ full_name: 'asc' }, { id: 'asc' }],
      ...paged(page, pageSize),
      include: {
        countries: { select: { name: true } },
        player_team_stints: {
          select: {
            start_date: true,
            end_date: true,
            transfer_type: true,
            teams: { select: { id: true, name: true, type: true } },
          },
          orderBy: [{ start_date: { sort: 'desc', nulls: 'last' } }, { id: 'desc' }],
        },
        _count: {
          select: {
            match_events_match_events_player_idToplayers: true,
            match_lineups: true,
          },
        },
      },
    }),
  ]);

  res.json({
    total, page, pageSize,
    players: rows.map((p) => ({
      id: p.id,
      fullName: p.full_name,
      position: p.position,
      dob: p.dob,
      nationality: p.countries?.name ?? null,
      // Distinct, most recent first — a player's stints can repeat a club.
      teams: [...new Map(p.player_team_stints.map((s) => [s.teams.id, { id: s.teams.id, name: s.teams.name }])).values()],
      // The club spell running today, if any. With club spells but none
      // running, the player is a free agent; with none at all, unknown.
      currentClub: (() => {
        const now = new Date();
        const clubSpells = p.player_team_stints.filter((s) => s.teams.type === 'CLUB');
        const running = clubSpells.find(
          (s) => s.transfer_type !== 'LOAN' && (!s.start_date || s.start_date <= now) && (!s.end_date || s.end_date > now),
        );
        return running
          ? { id: running.teams.id, name: running.teams.name }
          : clubSpells.length ? 'FREE_AGENT' : null;
      })(),
      events: p._count.match_events_match_events_player_idToplayers,
      appearances: p._count.match_lineups,
    })),
  });
});

manageRouter.get('/players/:id', async (req, res) => {
  const id = parseId(req, res);
  if (id === null) return;
  const player = await prisma.players.findUnique({
    where: { id },
    include: {
      player_team_stints: {
        include: { teams: { select: { id: true, name: true } } },
        orderBy: [{ start_date: { sort: 'desc', nulls: 'last' } }, { id: 'desc' }],
      },
    },
  });
  if (!player) return res.status(404).json({ error: `No player with id ${id}` });
  res.json({ player, usage: usageList(await playerUsage(id)) });
});

async function playerUsage(id: number) {
  const [events, relatedEvents, lineups, stints, ratings] = await Promise.all([
    prisma.match_events.count({ where: { player_id: id } }),
    prisma.match_events.count({ where: { related_player_id: id } }),
    prisma.match_lineups.count({ where: { player_id: id } }),
    prisma.player_team_stints.count({ where: { player_id: id } }),
    prisma.match_player_ratings.count({ where: { player_id: id } }),
  ]);
  return {
    'match event|match events': events + relatedEvents,
    'team-sheet appearance|team-sheet appearances': lineups,
    'club spell|club spells': stints,
    'player rating|player ratings': ratings,
  };
}

/**
 * Registration may name the club the player is at now, and since when. Omit
 * `club` for a free agent: no spell is created, and the career shows none.
 */
const playerCreateBody = playerBody.extend({
  club: z
    .object({
      teamId: z.number().int().positive({ message: 'Pick a club' }),
      startDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Use a YYYY-MM-DD date'),
      type: z.enum(['PERMANENT', 'LOAN', 'FREE', 'YOUTH']).default('PERMANENT'),
      shirtNumber: z.number().int().min(0).max(99).nullish(),
    })
    .nullish(),
});

manageRouter.post('/players', async (req, res) => {
  const body = parseBody(playerCreateBody, req, res);
  if (!body) return;
  const { club, ...fields } = body;

  if (club) {
    const team = await prisma.teams.findUnique({ where: { id: club.teamId }, select: { type: true } });
    if (!team) return res.status(404).json({ error: `No team with id ${club.teamId}` });
    if (team.type !== 'CLUB') return res.status(400).json({ error: 'club.teamId: pick a club, not a national team.' });
  }

  const player = await prisma.$transaction(async (tx) => {
    const created = await tx.players.create({ data: definedOnly(fields) as Prisma.playersUncheckedCreateInput });
    await recordManualProvenance(tx, 'player', created.id);
    if (club) {
      const spell = await tx.player_team_stints.create({
        data: {
          player_id: created.id,
          team_id: club.teamId,
          start_date: new Date(`${club.startDate}T00:00:00Z`),
          transfer_type: club.type,
          shirt_number: club.shirtNumber ?? null,
        },
      });
      await recordManualProvenance(tx, 'player_team_stint', spell.id);
    }
    return created;
  });
  res.status(201).json({ player });
});

manageRouter.patch('/players/:id', async (req, res) => {
  const id = parseId(req, res);
  if (id === null) return;
  const body = parseBody(playerBody.partial(), req, res);
  if (!body) return;
  if (!(await prisma.players.findUnique({ where: { id }, select: { id: true } }))) {
    return res.status(404).json({ error: `No player with id ${id}` });
  }
  const player = await prisma.$transaction(async (tx) => {
    const updated = await tx.players.update({
      where: { id },
      data: definedOnly(body) as Prisma.playersUncheckedUpdateInput,
    });
    await recordManualProvenance(tx, 'player', id);
    return updated;
  });
  res.json({ player });
});

manageRouter.delete('/players/:id', async (req, res) => {
  const id = parseId(req, res);
  if (id === null) return;
  const player = await prisma.players.findUnique({ where: { id }, select: { full_name: true } });
  if (!player) return res.status(404).json({ error: `No player with id ${id}` });

  // Match history blocks a delete; the player's own career spells do not. They
  // are part of the player's record — registering someone by mistake with a
  // club must not leave them undeletable until the spell is removed first.
  const { 'club spell|club spells': _spells, ...history } = await playerUsage(id);
  if (refuseIfReferenced(res, player.full_name, history)) return;

  await prisma.$transaction(async (tx) => {
    const spells = await tx.player_team_stints.findMany({ where: { player_id: id }, select: { id: true } });
    await tx.player_team_stints.deleteMany({ where: { player_id: id } });
    await tx.entity_source_map.deleteMany({
      where: { entity_type: 'player_team_stint', entity_id: { in: spells.map((s) => s.id) } },
    });
    await tx.players.delete({ where: { id } });
    await dropProvenance(tx, 'player', id);
  });
  res.json({ ok: true });
});

/* ================================================================== teams == */

const teamBody = z.object({
  name: z.string().trim().min(1, 'A team needs a name').max(100),
  short_name: z.string().trim().max(10).nullish(),
  type: z.enum(['CLUB', 'NATIONAL']),
  // NOT NULL in the schema — a team always belongs to a country.
  country_id: z.number().int().positive({ message: 'Pick a country' }),
  stadium_id: z.number().int().positive().nullish(),
  founded_year: z.number().int().min(1800).max(2100).nullish(),
  logo_url: z.string().max(255).nullish(),
});

const teamClash = 'A team with that name already exists in that country.';

manageRouter.get('/teams', async (req, res) => {
  const q = pageQuery
    .extend({ type: z.enum(['CLUB', 'NATIONAL']).optional() })
    .safeParse(req.query);
  if (!q.success) return res.status(400).json({ error: 'Invalid query' });
  const { q: search, page, pageSize, type } = q.data;

  const where: Prisma.teamsWhereInput = {
    ...(search && {
      OR: [
        { name: { contains: search, mode: 'insensitive' } },
        { short_name: { contains: search, mode: 'insensitive' } },
      ],
    }),
    ...(type && { type }),
  };

  const [total, rows] = await Promise.all([
    prisma.teams.count({ where }),
    prisma.teams.findMany({
      where,
      orderBy: [{ name: 'asc' }, { id: 'asc' }],
      ...paged(page, pageSize),
      include: {
        countries: { select: { name: true } },
        stadiums: { select: { name: true } },
        _count: {
          select: {
            matches_matches_home_team_idToteams: true,
            matches_matches_away_team_idToteams: true,
            competition_edition_teams: true,
            player_team_stints: true,
          },
        },
      },
    }),
  ]);

  res.json({
    total, page, pageSize,
    teams: rows.map((t) => ({
      id: t.id,
      name: t.name,
      shortName: t.short_name,
      type: t.type,
      country: t.countries.name,
      stadium: t.stadiums?.name ?? null,
      matches: t._count.matches_matches_home_team_idToteams + t._count.matches_matches_away_team_idToteams,
      seasons: t._count.competition_edition_teams,
      players: t._count.player_team_stints,
    })),
  });
});

async function teamUsage(id: number) {
  const [home, away, events, lineups, stints, participations, coachStints, stats] = await Promise.all([
    prisma.matches.count({ where: { home_team_id: id } }),
    prisma.matches.count({ where: { away_team_id: id } }),
    prisma.match_events.count({ where: { team_id: id } }),
    prisma.match_lineups.count({ where: { team_id: id } }),
    prisma.player_team_stints.count({ where: { team_id: id } }),
    prisma.competition_edition_teams.count({ where: { team_id: id } }),
    prisma.coach_team_stints.count({ where: { team_id: id } }),
    prisma.match_team_stats.count({ where: { team_id: id } }),
  ]);
  return {
    'match|matches': home + away,
    'match event|match events': events,
    'team-sheet entry|team-sheet entries': lineups,
    'player spell|player spells': stints,
    'season entry|season entries': participations,
    'coach spell|coach spells': coachStints,
    'match stat row|match stat rows': stats,
  };
}

manageRouter.get('/teams/:id', async (req, res) => {
  const id = parseId(req, res);
  if (id === null) return;
  const team = await prisma.teams.findUnique({ where: { id } });
  if (!team) return res.status(404).json({ error: `No team with id ${id}` });
  res.json({ team, usage: usageList(await teamUsage(id)) });
});

manageRouter.post('/teams', async (req, res) => {
  const body = parseBody(teamBody, req, res);
  if (!body) return;
  try {
    const team = await prisma.$transaction(async (tx) => {
      const created = await tx.teams.create({ data: definedOnly(body) as Prisma.teamsUncheckedCreateInput });
      await recordManualProvenance(tx, 'team', created.id);
      return created;
    });
    res.status(201).json({ team });
  } catch (err) {
    if (!conflict(err, res, teamClash)) throw err;
  }
});

manageRouter.patch('/teams/:id', async (req, res) => {
  const id = parseId(req, res);
  if (id === null) return;
  const body = parseBody(teamBody.partial(), req, res);
  if (!body) return;
  if (!(await prisma.teams.findUnique({ where: { id }, select: { id: true } }))) {
    return res.status(404).json({ error: `No team with id ${id}` });
  }
  try {
    const team = await prisma.$transaction(async (tx) => {
      const updated = await tx.teams.update({
        where: { id },
        data: definedOnly(body) as Prisma.teamsUncheckedUpdateInput,
      });
      await recordManualProvenance(tx, 'team', id);
      return updated;
    });
    res.json({ team });
  } catch (err) {
    if (!conflict(err, res, teamClash)) throw err;
  }
});

manageRouter.delete('/teams/:id', async (req, res) => {
  const id = parseId(req, res);
  if (id === null) return;
  const team = await prisma.teams.findUnique({ where: { id }, select: { name: true } });
  if (!team) return res.status(404).json({ error: `No team with id ${id}` });
  if (refuseIfReferenced(res, team.name, await teamUsage(id))) return;

  await prisma.$transaction(async (tx) => {
    await tx.teams.delete({ where: { id } });
    await dropProvenance(tx, 'team', id);
  });
  res.json({ ok: true });
});

/* =========================================================== competitions == */

const COMPETITION_TYPES = [
  'LEAGUE', 'DOMESTIC_CUP', 'SUPER_CUP', 'CONTINENTAL_CLUB',
  'CONTINENTAL_NATIONAL', 'WORLD_CUP', 'FRIENDLY', 'QUALIFIER',
] as const;

const competitionUpdate = z.object({
  name: z.string().trim().min(1, 'A competition needs a name').max(150),
  type: z.enum(COMPETITION_TYPES),
  countryId: z.number().int().positive().nullable(),
  tier: z.number().int().min(1).max(10).nullable(),
}).partial();

manageRouter.patch('/competitions/:id', async (req, res) => {
  const id = parseId(req, res);
  if (id === null) return;
  const body = parseBody(competitionUpdate, req, res);
  if (!body) return;
  if (!(await prisma.competitions.findUnique({ where: { id }, select: { id: true } }))) {
    return res.status(404).json({ error: `No competition with id ${id}` });
  }
  // The slug is deliberately left alone on rename: it may already be in a URL.
  const competition = await prisma.$transaction(async (tx) => {
    const updated = await tx.competitions.update({
      where: { id },
      data: definedOnly({
        name: body.name,
        type: body.type,
        country_id: body.countryId,
        tier: body.tier,
      }),
    });
    await recordManualProvenance(tx, 'competition', id);
    return updated;
  });
  res.json({ competition });
});

manageRouter.delete('/competitions/:id', async (req, res) => {
  const id = parseId(req, res);
  if (id === null) return;
  const competition = await prisma.competitions.findUnique({ where: { id }, select: { name: true } });
  if (!competition) return res.status(404).json({ error: `No competition with id ${id}` });
  const seasons = await prisma.competition_editions.count({ where: { competition_id: id } });
  if (refuseIfReferenced(res, competition.name, { 'season|seasons': seasons })) return;

  await prisma.$transaction(async (tx) => {
    await tx.competitions.delete({ where: { id } });
    await dropProvenance(tx, 'competition', id);
  });
  res.json({ ok: true });
});

/* =============================================================== editions == */
// An edition is one competition in one season — "Premier League 2018/19". It
// is what gets published, and what participants and matches hang off.

const EDITION_FORMATS = ['ROUND_ROBIN', 'GROUPS_KNOCKOUT', 'KNOCKOUT'] as const;

const editionBody = z.object({
  seasonId: z.number().int().positive({ message: 'Pick a season' }),
  format: z.enum(EDITION_FORMATS).nullish(),
  numTeams: z.number().int().min(2).max(250).nullish(),
  hostCountryId: z.number().int().positive().nullish(),
});

manageRouter.post('/competitions/:id/editions', async (req, res) => {
  const id = parseId(req, res);
  if (id === null) return;
  const body = parseBody(editionBody, req, res);
  if (!body) return;
  if (!(await prisma.competitions.findUnique({ where: { id }, select: { id: true } }))) {
    return res.status(404).json({ error: `No competition with id ${id}` });
  }
  try {
    const edition = await prisma.$transaction(async (tx) => {
      const created = await tx.competition_editions.create({
        // Always unpublished: a new season reaches the public only by an
        // editor's explicit publish, never by being created.
        data: definedOnly({
          competition_id: id,
          season_id: body.seasonId,
          format: body.format,
          num_teams: body.numTeams,
          host_country_id: body.hostCountryId,
          is_published: false,
        }) as Prisma.competition_editionsUncheckedCreateInput,
      });
      await recordManualProvenance(tx, 'competition_edition', created.id);
      return created;
    });
    res.status(201).json({ edition });
  } catch (err) {
    if (!conflict(err, res, 'This competition already has an edition for that season.')) throw err;
  }
});

manageRouter.patch('/editions/:id', async (req, res) => {
  const id = parseId(req, res);
  if (id === null) return;
  // The season is not editable: moving an edition between seasons would carry
  // its matches with it and silently rewrite history. Delete and recreate.
  const body = parseBody(editionBody.omit({ seasonId: true }).partial(), req, res);
  if (!body) return;
  if (!(await prisma.competition_editions.findUnique({ where: { id }, select: { id: true } }))) {
    return res.status(404).json({ error: `No edition with id ${id}` });
  }
  const edition = await prisma.$transaction(async (tx) => {
    const updated = await tx.competition_editions.update({
      where: { id },
      data: definedOnly({
        format: body.format,
        num_teams: body.numTeams,
        host_country_id: body.hostCountryId,
      }) as Prisma.competition_editionsUncheckedUpdateInput,
    });
    await recordManualProvenance(tx, 'competition_edition', id);
    return updated;
  });
  res.json({ edition });
});

manageRouter.delete('/editions/:id', async (req, res) => {
  const id = parseId(req, res);
  if (id === null) return;
  const edition = await prisma.competition_editions.findUnique({
    where: { id },
    select: {
      is_published: true,
      competitions: { select: { name: true } },
      seasons: { select: { label: true } },
    },
  });
  if (!edition) return res.status(404).json({ error: `No edition with id ${id}` });
  const label = `${edition.competitions.name} ${edition.seasons.label}`;

  if (edition.is_published) {
    return res.status(409).json({
      error: `${label} is live on the public site. Unpublish it before deleting it.`,
    });
  }
  const matches = await prisma.matches.count({ where: { competition_edition_id: id } });
  if (refuseIfReferenced(res, label, { 'match|matches': matches })) return;

  // With no matches, its participant list and groups describe nothing that
  // happened, so they go with it.
  await prisma.$transaction(async (tx) => {
    await tx.competition_edition_teams.deleteMany({ where: { competition_edition_id: id } });
    await tx.competition_groups.deleteMany({ where: { competition_edition_id: id } });
    await tx.competition_editions.delete({ where: { id } });
    await dropProvenance(tx, 'competition_edition', id);
  });
  res.json({ ok: true });
});

/* =========================================================== participants == */

manageRouter.get('/editions/:id/participants', async (req, res) => {
  const id = parseId(req, res);
  if (id === null) return;
  const edition = await prisma.competition_editions.findUnique({
    where: { id },
    include: {
      competitions: { select: { id: true, name: true, type: true } },
      seasons: { select: { label: true } },
      competition_groups: { select: { id: true, name: true }, orderBy: { name: 'asc' } },
      competition_edition_teams: {
        include: {
          teams: { select: { id: true, name: true, type: true, countries: { select: { name: true } } } },
          competition_groups: { select: { id: true, name: true } },
        },
      },
    },
  });
  if (!edition) return res.status(404).json({ error: `No edition with id ${id}` });

  // Matches per team in this edition, so the page can say which entries are
  // load-bearing before anyone tries to remove one.
  const played = await prisma.$queryRaw<{ teamId: number; n: number }[]>(Prisma.sql`
    SELECT team_id AS "teamId", count(*)::int AS n FROM (
      SELECT home_team_id AS team_id FROM matches WHERE competition_edition_id = ${id}
      UNION ALL
      SELECT away_team_id FROM matches WHERE competition_edition_id = ${id}
    ) s GROUP BY team_id
  `);
  const matchesBy = new Map(played.map((p) => [p.teamId, p.n]));
  const listed = new Set(edition.competition_edition_teams.map((p) => p.team_id));

  res.json({
    edition: {
      id: edition.id,
      competitionId: edition.competitions.id,
      competition: edition.competitions.name,
      competitionType: edition.competitions.type,
      season: edition.seasons.label,
      numTeams: edition.num_teams,
      isPublished: edition.is_published,
    },
    groups: edition.competition_groups,
    participants: edition.competition_edition_teams
      .map((p) => ({
        teamId: p.teams.id,
        name: p.teams.name,
        type: p.teams.type,
        country: p.teams.countries.name,
        group: p.competition_groups,
        matches: matchesBy.get(p.team_id) ?? 0,
      }))
      .sort((a, b) => a.name.localeCompare(b.name)),
    // Teams with matches in the edition but no participant row — the gap the
    // migrated editions had before the backfill. Offered for one-click adding.
    unlisted: await prisma.teams.findMany({
      where: { id: { in: [...matchesBy.keys()].filter((t) => !listed.has(t)) } },
      select: { id: true, name: true },
      orderBy: { name: 'asc' },
    }),
  });
});

const participantBody = z.object({
  teamId: z.number().int().positive({ message: 'Pick a team' }),
  groupId: z.number().int().positive().nullish(),
});

/** A group must belong to the edition it is being used in. */
async function groupBelongs(groupId: number | null | undefined, editionId: number) {
  if (groupId == null) return true;
  const g = await prisma.competition_groups.findUnique({
    where: { id: groupId },
    select: { competition_edition_id: true },
  });
  return g?.competition_edition_id === editionId;
}

manageRouter.post('/editions/:id/participants', async (req, res) => {
  const id = parseId(req, res);
  if (id === null) return;
  const body = parseBody(participantBody, req, res);
  if (!body) return;
  if (!(await groupBelongs(body.groupId, id))) {
    return res.status(400).json({ error: 'That group is not part of this edition.' });
  }
  try {
    const participant = await prisma.competition_edition_teams.create({
      data: definedOnly({ competition_edition_id: id, team_id: body.teamId, group_id: body.groupId }) as Prisma.competition_edition_teamsUncheckedCreateInput,
    });
    res.status(201).json({ participant });
  } catch (err) {
    if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2003') {
      return res.status(404).json({ error: 'No such edition or team.' });
    }
    if (!conflict(err, res, 'That team is already taking part in this edition.')) throw err;
  }
});

manageRouter.patch('/editions/:id/participants/:teamId', async (req, res) => {
  const params = z
    .object({ id: z.coerce.number().int().positive(), teamId: z.coerce.number().int().positive() })
    .safeParse(req.params);
  if (!params.success) return res.status(400).json({ error: 'ids must be positive integers' });
  const body = parseBody(z.object({ groupId: z.number().int().positive().nullable() }), req, res);
  if (!body) return;
  if (!(await groupBelongs(body.groupId, params.data.id))) {
    return res.status(400).json({ error: 'That group is not part of this edition.' });
  }
  const { count } = await prisma.competition_edition_teams.updateMany({
    where: { competition_edition_id: params.data.id, team_id: params.data.teamId },
    data: { group_id: body.groupId },
  });
  if (count === 0) return res.status(404).json({ error: 'That team is not taking part in this edition.' });
  res.json({ ok: true });
});

manageRouter.delete('/editions/:id/participants/:teamId', async (req, res) => {
  const params = z
    .object({ id: z.coerce.number().int().positive(), teamId: z.coerce.number().int().positive() })
    .safeParse(req.params);
  if (!params.success) return res.status(400).json({ error: 'ids must be positive integers' });
  const { id, teamId } = params.data;

  const matches = await prisma.matches.count({
    where: { competition_edition_id: id, OR: [{ home_team_id: teamId }, { away_team_id: teamId }] },
  });
  const team = await prisma.teams.findUnique({ where: { id: teamId }, select: { name: true } });
  if (refuseIfReferenced(res, `${team?.name ?? 'That team'}'s entry`, { 'match in this edition|matches in this edition': matches })) return;

  const { count } = await prisma.competition_edition_teams.deleteMany({
    where: { competition_edition_id: id, team_id: teamId },
  });
  if (count === 0) return res.status(404).json({ error: 'That team is not taking part in this edition.' });
  res.json({ ok: true });
});

/* ================================================================ seasons == */

const seasonLabel = z
  .string()
  .trim()
  .min(1, 'A season needs a label')
  .max(20)
  // The two shapes the vault already uses: "2018/2019" and "2019".
  .regex(/^\d{4}(\/\d{4})?$/, 'Use 2025/2026 for a split season or 2025 for a calendar year');

const seasonBody = z.object({
  label: seasonLabel,
  start_date: z.coerce.date().nullish(),
  end_date: z.coerce.date().nullish(),
}).refine(
  (s) => !s.start_date || !s.end_date || s.start_date <= s.end_date,
  { message: 'The season cannot end before it starts', path: ['end_date'] },
);

const seasonClash = 'A season with that label already exists.';

manageRouter.get('/seasons', async (_req, res) => {
  const rows = await prisma.seasons.findMany({
    orderBy: { label: 'desc' },
    include: {
      competition_editions: {
        select: { id: true, is_published: true, competitions: { select: { name: true } } },
      },
    },
  });
  res.json({
    seasons: rows.map((s) => ({
      id: s.id,
      label: s.label,
      startDate: s.start_date,
      endDate: s.end_date,
      editions: s.competition_editions.length,
      published: s.competition_editions.filter((e) => e.is_published).length,
      competitions: s.competition_editions.map((e) => e.competitions.name).sort(),
    })),
  });
});

manageRouter.post('/seasons', async (req, res) => {
  const body = parseBody(seasonBody, req, res);
  if (!body) return;
  try {
    const season = await prisma.$transaction(async (tx) => {
      const created = await tx.seasons.create({ data: definedOnly(body) as Prisma.seasonsCreateInput });
      await recordManualProvenance(tx, 'season', created.id);
      return created;
    });
    res.status(201).json({ season });
  } catch (err) {
    if (!conflict(err, res, seasonClash)) throw err;
  }
});

manageRouter.patch('/seasons/:id', async (req, res) => {
  const id = parseId(req, res);
  if (id === null) return;
  // `.refine` does not survive `.partial()`, so the date order is rechecked
  // against the stored row below.
  const body = parseBody(
    z.object({
      label: seasonLabel,
      start_date: z.coerce.date().nullable(),
      end_date: z.coerce.date().nullable(),
    }).partial(),
    req, res,
  );
  if (!body) return;
  const current = await prisma.seasons.findUnique({ where: { id } });
  if (!current) return res.status(404).json({ error: `No season with id ${id}` });

  const start = body.start_date !== undefined ? body.start_date : current.start_date;
  const end = body.end_date !== undefined ? body.end_date : current.end_date;
  if (start && end && start > end) {
    return res.status(400).json({ error: 'end_date: The season cannot end before it starts' });
  }

  try {
    const season = await prisma.$transaction(async (tx) => {
      const updated = await tx.seasons.update({ where: { id }, data: definedOnly(body) });
      await recordManualProvenance(tx, 'season', id);
      return updated;
    });
    res.json({ season });
  } catch (err) {
    if (!conflict(err, res, seasonClash)) throw err;
  }
});

manageRouter.delete('/seasons/:id', async (req, res) => {
  const id = parseId(req, res);
  if (id === null) return;
  const season = await prisma.seasons.findUnique({ where: { id }, select: { label: true } });
  if (!season) return res.status(404).json({ error: `No season with id ${id}` });
  const editions = await prisma.competition_editions.count({ where: { season_id: id } });
  if (refuseIfReferenced(res, `Season ${season.label}`, { 'competition edition|competition editions': editions })) return;

  await prisma.$transaction(async (tx) => {
    await tx.seasons.delete({ where: { id } });
    await dropProvenance(tx, 'season', id);
  });
  res.json({ ok: true });
});

/* ======================================================= access management == */
// There are no roles: every active admin can manage every account, matching the
// single `admins` table the schema defines. Two rails keep that from locking
// everyone out — nobody can deactivate themselves, and the last active admin
// cannot be deactivated at all.
//
// Admins are deactivated, never deleted. `competition_editions.published_by`
// and `data_flags.created_by` point at them, so a deleted admin would either
// fail the delete or erase who published what.

const MIN_PASSWORD = 12;

const adminView = {
  id: true, email: true, display_name: true, is_active: true, created_at: true, last_login_at: true,
} as const;

const toAdmin = (a: {
  id: number; email: string; display_name: string; is_active: boolean;
  created_at: Date; last_login_at: Date | null;
}) => ({
  id: a.id,
  email: a.email,
  displayName: a.display_name,
  isActive: a.is_active,
  createdAt: a.created_at,
  lastLoginAt: a.last_login_at,
});

manageRouter.get('/admins', async (req, res) => {
  const rows = await prisma.admins.findMany({
    select: adminView,
    orderBy: [{ is_active: 'desc' }, { display_name: 'asc' }],
  });
  res.json({ admins: rows.map(toAdmin), currentAdminId: req.admin!.id });
});

manageRouter.post('/admins', async (req, res) => {
  const body = parseBody(
    z.object({
      email: z.string().trim().toLowerCase().email('Enter a valid email address'),
      displayName: z.string().trim().min(1, 'Enter a name').max(100),
      password: z.string().min(MIN_PASSWORD, `The password must be at least ${MIN_PASSWORD} characters`),
    }),
    req, res,
  );
  if (!body) return;
  try {
    const admin = await prisma.admins.create({
      data: {
        email: body.email,
        display_name: body.displayName,
        password_hash: await hashPassword(body.password),
      },
      select: adminView,
    });
    res.status(201).json({ admin: toAdmin(admin) });
  } catch (err) {
    if (!conflict(err, res, `${body.email} already has an admin account.`)) throw err;
  }
});

manageRouter.patch('/admins/:id', async (req, res) => {
  const id = parseId(req, res);
  if (id === null) return;
  const body = parseBody(
    z.object({
      displayName: z.string().trim().min(1, 'Enter a name').max(100),
      isActive: z.boolean(),
    }).partial(),
    req, res,
  );
  if (!body) return;

  const target = await prisma.admins.findUnique({ where: { id }, select: { is_active: true } });
  if (!target) return res.status(404).json({ error: `No admin with id ${id}` });

  if (body.isActive === false && target.is_active) {
    if (id === req.admin!.id) {
      return res.status(409).json({ error: "You can't deactivate your own account." });
    }
    const active = await prisma.admins.count({ where: { is_active: true } });
    if (active <= 1) {
      return res.status(409).json({ error: 'This is the last active admin; deactivating it would lock everyone out.' });
    }
  }

  const admin = await prisma.admins.update({
    where: { id },
    data: definedOnly({ display_name: body.displayName, is_active: body.isActive }),
    select: adminView,
  });
  res.json({ admin: toAdmin(admin) });
});

/**
 * Set another admin's password — for someone locked out. Your own goes through
 * `/me/password`, which asks for the current one first.
 */
manageRouter.post('/admins/:id/password', async (req, res) => {
  const id = parseId(req, res);
  if (id === null) return;
  if (id === req.admin!.id) {
    return res.status(409).json({ error: 'Change your own password from My account, which checks your current one.' });
  }
  const body = parseBody(
    z.object({
      password: z.string().min(MIN_PASSWORD, `The password must be at least ${MIN_PASSWORD} characters`),
    }),
    req, res,
  );
  if (!body) return;
  if (!(await prisma.admins.findUnique({ where: { id }, select: { id: true } }))) {
    return res.status(404).json({ error: `No admin with id ${id}` });
  }
  await prisma.admins.update({
    where: { id },
    data: { password_hash: await hashPassword(body.password) },
  });
  res.json({ ok: true });
});

/* ============================================================== reference == */

/** Lookups for the create/edit forms. */
manageRouter.get('/lookups', async (_req, res) => {
  const [countries, seasons, stadiums, competitions] = await Promise.all([
    prisma.countries.findMany({ select: { id: true, name: true }, orderBy: { name: 'asc' } }),
    prisma.seasons.findMany({ select: { id: true, label: true }, orderBy: { label: 'desc' } }),
    prisma.stadiums.findMany({ select: { id: true, name: true, city: true }, orderBy: { name: 'asc' } }),
    prisma.competitions.findMany({ select: { id: true, name: true }, orderBy: { name: 'asc' } }),
  ]);
  res.json({
    countries, seasons, stadiums, competitions,
    competitionTypes: COMPETITION_TYPES,
    editionFormats: EDITION_FORMATS,
  });
});

/** Every team, name only — for pickers too long to page. */
manageRouter.get('/team-options', async (req, res) => {
  const type = z.enum(['CLUB', 'NATIONAL']).optional().safeParse(req.query.type);
  const teams = await prisma.teams.findMany({
    where: type.success && type.data ? { type: type.data } : {},
    select: { id: true, name: true, type: true },
    orderBy: { name: 'asc' },
  });
  res.json({ teams });
});
