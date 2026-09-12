import { Router, type Request, type Response } from 'express';
import { Prisma } from '@prisma/client';
import { z } from 'zod';
import { prisma } from '../db.js';
import { recordManualProvenance } from '../services/provenance.js';
import {
  clubStatus,
  conflictsFor,
  planTransfer,
  staleOpenSpells,
  type Spell,
  type SpellType,
} from '../services/careers.js';

/**
 * Player careers: spells at clubs and national teams, transfers between clubs,
 * and each team's current squad. The rules live in services/careers.ts; this
 * file loads spells, applies a plan in one transaction, and records provenance
 * for every spell it creates or changes.
 */
export const careersRouter = Router();

const SPELL_TYPES = ['PERMANENT', 'LOAN', 'FREE', 'YOUTH'] as const;
const isoDate = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Use a YYYY-MM-DD date');

const day = (d: Date) => d.toISOString().slice(0, 10);
const asDate = (iso: string) => new Date(`${iso}T00:00:00Z`);
/** The vault's "today". UTC is within a few hours of every league it holds. */
const today = () => day(new Date());

type LoadedSpell = Spell & { shirtNumber: number | null; fee: string | null };

async function loadSpells(
  db: Prisma.TransactionClient | typeof prisma,
  playerId: number,
): Promise<LoadedSpell[]> {
  const rows = await db.player_team_stints.findMany({
    where: { player_id: playerId },
    include: { teams: { select: { id: true, name: true, type: true } } },
  });
  return rows.map((r) => ({
    id: r.id,
    teamId: r.team_id,
    teamName: r.teams.name,
    teamType: r.teams.type as 'CLUB' | 'NATIONAL',
    // Every spell in the vault has a start date; a missing one is read as the
    // earliest possible so it can never appear to start after anything.
    start: r.start_date ? day(r.start_date) : '0001-01-01',
    end: r.end_date ? day(r.end_date) : null,
    type: (r.transfer_type as SpellType | null) ?? null,
    shirtNumber: r.shirt_number,
    fee: r.transfer_fee?.toString() ?? null,
  }));
}

function idOf(req: Request, res: Response, key = 'id'): number | null {
  const n = Number(req.params[key]);
  if (!Number.isInteger(n) || n < 1) {
    res.status(400).json({ error: `${key} must be a positive integer` });
    return null;
  }
  return n;
}

function body<T extends z.ZodType>(schema: T, req: Request, res: Response): z.infer<T> | null {
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    const first = parsed.error.issues[0];
    res.status(400).json({
      error: `${first?.path.length ? `${first.path.join('.')}: ` : ''}${first?.message ?? 'Invalid request body'}`,
    });
    return null;
  }
  return parsed.data;
}

const describe = (s: Spell) => `${s.teamName} (${s.start} – ${s.end ?? 'ongoing'})`;

function clashMessage(conflicts: Spell[]) {
  return `That overlaps the spell at ${conflicts.map(describe).join(' and ')}. A player can only be contracted to one club at a time — end that spell first, or record this as a loan.`;
}

/* ---------------------------------------------------------------- career -- */

/** Everything the career panel shows: status, club and national spells, problems. */
careersRouter.get('/players/:id/career', async (req, res) => {
  const playerId = idOf(req, res);
  if (playerId === null) return;
  const player = await prisma.players.findUnique({ where: { id: playerId }, select: { id: true, full_name: true } });
  if (!player) return res.status(404).json({ error: `No player with id ${playerId}` });

  const spells = await loadSpells(prisma, playerId);
  const stale = staleOpenSpells(spells);
  const status = clubStatus(spells, today());

  const view = (s: LoadedSpell) => ({
    id: s.id,
    team: { id: s.teamId, name: s.teamName, type: s.teamType },
    start: s.start,
    end: s.end,
    type: s.type,
    shirtNumber: s.shirtNumber,
    fee: s.fee,
    conflictsWith: conflictsFor(s, spells).map((c) => c.id),
    // An open spell a later one contradicts, and the end date that would fix it.
    staleSuggestedEnd: stale.get(s.id) ?? null,
  });
  const newestFirst = (a: LoadedSpell, b: LoadedSpell) =>
    b.start.localeCompare(a.start) || (b.end ?? '9999').localeCompare(a.end ?? '9999');

  res.json({
    player: { id: player.id, name: player.full_name },
    today: today(),
    status:
      status.kind === 'AT_CLUB'
        ? { kind: status.kind, club: view(status.club as LoadedSpell), loan: status.loan ? view(status.loan as LoadedSpell) : null }
        : status.kind === 'ON_LOAN_ONLY'
          ? { kind: status.kind, loan: view(status.loan as LoadedSpell) }
          : status.kind === 'FREE_AGENT'
            ? { kind: status.kind, lastClub: view(status.lastClub as LoadedSpell) }
            : { kind: status.kind },
    clubSpells: spells.filter((s) => s.teamType === 'CLUB').sort(newestFirst).map(view),
    nationalSpells: spells.filter((s) => s.teamType === 'NATIONAL').sort(newestFirst).map(view),
  });
});

/* ---------------------------------------------------------------- spells -- */

const spellBody = z.object({
  teamId: z.number().int().positive({ message: 'Pick a team' }),
  startDate: isoDate,
  endDate: isoDate.nullish(),
  type: z.enum(SPELL_TYPES).nullish(),
  shirtNumber: z.number().int().min(0).max(99).nullish(),
  fee: z.number().min(0).max(9_999_999_999.99).nullish(),
});

type SpellFields = z.infer<typeof spellBody>;

const spellData = (b: { [K in keyof SpellFields]?: SpellFields[K] | undefined }) => {
  const data: Prisma.player_team_stintsUncheckedUpdateInput = {};
  if (b.teamId !== undefined) data.team_id = b.teamId;
  if (b.startDate !== undefined) data.start_date = asDate(b.startDate);
  if (b.endDate !== undefined) data.end_date = b.endDate ? asDate(b.endDate) : null;
  if (b.type !== undefined) data.transfer_type = b.type;
  if (b.shirtNumber !== undefined) data.shirt_number = b.shirtNumber;
  if (b.fee !== undefined) data.transfer_fee = b.fee;
  return data;
};

async function teamRef(teamId: number) {
  const t = await prisma.teams.findUnique({ where: { id: teamId }, select: { id: true, name: true, type: true } });
  return t ? { id: t.id, name: t.name, type: t.type as 'CLUB' | 'NATIONAL' } : null;
}

/** Add a spell directly — for filling in history, not for a move happening now. */
careersRouter.post('/players/:id/spells', async (req, res) => {
  const playerId = idOf(req, res);
  if (playerId === null) return;
  const b = body(spellBody, req, res);
  if (!b) return;
  if (b.endDate && b.endDate < b.startDate) return res.status(400).json({ error: 'The spell cannot end before it starts.' });
  if (!(await prisma.players.findUnique({ where: { id: playerId }, select: { id: true } }))) {
    return res.status(404).json({ error: `No player with id ${playerId}` });
  }
  const team = await teamRef(b.teamId);
  if (!team) return res.status(404).json({ error: `No team with id ${b.teamId}` });

  const spells = await loadSpells(prisma, playerId);
  const clash = conflictsFor({ start: b.startDate, end: b.endDate ?? null, type: b.type ?? null, teamType: team.type }, spells);
  if (clash.length) return res.status(409).json({ error: clashMessage(clash) });

  const spell = await prisma.$transaction(async (tx) => {
    const created = await tx.player_team_stints.create({
      data: { player_id: playerId, ...spellData(b) } as Prisma.player_team_stintsUncheckedCreateInput,
    });
    await recordManualProvenance(tx, 'player_team_stint', created.id);
    return created;
  });
  res.status(201).json({ spell: { id: spell.id } });
});

careersRouter.patch('/spells/:id', async (req, res) => {
  const spellId = idOf(req, res);
  if (spellId === null) return;
  const b = body(spellBody.partial(), req, res);
  if (!b) return;

  const row = await prisma.player_team_stints.findUnique({ where: { id: spellId }, select: { player_id: true } });
  if (!row) return res.status(404).json({ error: `No spell with id ${spellId}` });

  const spells = await loadSpells(prisma, row.player_id);
  const current = spells.find((s) => s.id === spellId)!;
  const team = b.teamId !== undefined ? await teamRef(b.teamId) : { id: current.teamId, name: current.teamName, type: current.teamType };
  if (!team) return res.status(404).json({ error: `No team with id ${b.teamId}` });

  const next = {
    id: spellId,
    start: b.startDate ?? current.start,
    end: b.endDate !== undefined ? (b.endDate ?? null) : current.end,
    type: b.type !== undefined ? (b.type ?? null) : current.type,
    teamType: team.type,
  };
  if (next.end && next.end < next.start) return res.status(400).json({ error: 'The spell cannot end before it starts.' });

  // Only re-judge overlaps when something that decides them changed. The vault
  // already holds contradictory spells, and correcting a shirt number must not
  // be blocked by a clash the editor didn't touch.
  const shapeChanged =
    next.start !== current.start || next.end !== current.end || next.type !== current.type || team.id !== current.teamId;
  if (shapeChanged) {
    const clash = conflictsFor(next, spells);
    // Allowed when the edit shrinks or keeps the same set of clashes — that is
    // how an editor resolves one, by ending the stale spell.
    const before = new Set(conflictsFor(current, spells).map((c) => c.id));
    const introduced = clash.filter((c) => !before.has(c.id));
    if (introduced.length) return res.status(409).json({ error: clashMessage(introduced) });
  }

  await prisma.$transaction(async (tx) => {
    await tx.player_team_stints.update({ where: { id: spellId }, data: spellData(b) });
    await recordManualProvenance(tx, 'player_team_stint', spellId);
  });
  res.json({ ok: true });
});

careersRouter.delete('/spells/:id', async (req, res) => {
  const spellId = idOf(req, res);
  if (spellId === null) return;
  const row = await prisma.player_team_stints.findUnique({ where: { id: spellId }, select: { id: true } });
  if (!row) return res.status(404).json({ error: `No spell with id ${spellId}` });
  await prisma.$transaction(async (tx) => {
    await tx.player_team_stints.delete({ where: { id: spellId } });
    await tx.entity_source_map.deleteMany({ where: { entity_type: 'player_team_stint', entity_id: spellId } });
  });
  res.json({ ok: true });
});

/* ------------------------------------------------------------- transfers -- */

const transferBody = z.object({
  /** Null releases the player to free agency. */
  toTeamId: z.number().int().positive().nullable(),
  date: isoDate,
  type: z.enum(SPELL_TYPES).default('PERMANENT'),
  loanUntil: isoDate.nullish(),
  shirtNumber: z.number().int().min(0).max(99).nullish(),
  fee: z.number().min(0).max(9_999_999_999.99).nullish(),
});

/**
 * Record a move. Every spell it ends and the one it starts are written in one
 * transaction, so a failure leaves the career exactly as it was.
 */
careersRouter.post('/players/:id/transfers', async (req, res) => {
  const playerId = idOf(req, res);
  if (playerId === null) return;
  const b = body(transferBody, req, res);
  if (!b) return;
  if (!(await prisma.players.findUnique({ where: { id: playerId }, select: { id: true } }))) {
    return res.status(404).json({ error: `No player with id ${playerId}` });
  }
  const toTeam = b.toTeamId === null ? null : await teamRef(b.toTeamId);
  if (b.toTeamId !== null && !toTeam) return res.status(404).json({ error: `No team with id ${b.toTeamId}` });

  const spells = await loadSpells(prisma, playerId);
  const plan = planTransfer(spells, { toTeam, date: b.date, type: b.type, loanUntil: b.loanUntil ?? null });
  if ('error' in plan) return res.status(409).json({ error: plan.error });

  const result = await prisma.$transaction(async (tx) => {
    for (const c of plan.close) {
      await tx.player_team_stints.update({ where: { id: c.spell.id }, data: { end_date: asDate(c.end) } });
      await recordManualProvenance(tx, 'player_team_stint', c.spell.id);
    }
    let createdId: number | null = null;
    if (plan.create) {
      const created = await tx.player_team_stints.create({
        data: {
          player_id: playerId,
          team_id: plan.create.teamId,
          start_date: asDate(plan.create.start),
          end_date: plan.create.end ? asDate(plan.create.end) : null,
          transfer_type: plan.create.type,
          shirt_number: b.shirtNumber ?? null,
          transfer_fee: b.fee ?? null,
        },
      });
      await recordManualProvenance(tx, 'player_team_stint', created.id);
      createdId = created.id;
    }
    return { closed: plan.close.map((c) => ({ id: c.spell.id, team: c.spell.teamName, end: c.end })), createdId };
  });
  res.status(201).json(result);
});

/* ----------------------------------------------------------------- squads -- */

/** A team's players as of today, and everyone who has left, newest departure first. */
careersRouter.get('/teams/:id/squad', async (req, res) => {
  const teamId = idOf(req, res);
  if (teamId === null) return;
  if (!(await prisma.teams.findUnique({ where: { id: teamId }, select: { id: true } }))) {
    return res.status(404).json({ error: `No team with id ${teamId}` });
  }
  const rows = await prisma.player_team_stints.findMany({
    where: { team_id: teamId },
    include: { players: { select: { id: true, full_name: true, position: true } } },
  });
  const now = today();
  const shaped = rows.map((r) => ({
    spellId: r.id,
    player: { id: r.players.id, name: r.players.full_name, position: r.players.position },
    start: r.start_date ? day(r.start_date) : null,
    end: r.end_date ? day(r.end_date) : null,
    type: r.transfer_type,
    shirtNumber: r.shirt_number,
  }));
  const isCurrent = (s: (typeof shaped)[number]) => (s.start ?? '') <= now && (s.end === null || s.end > now);
  res.json({
    today: now,
    current: shaped
      .filter(isCurrent)
      // Newest signing first. Legacy spells were often never closed, so an
      // "open since 2018" spell is as likely stale as current; putting recent
      // moves at the top keeps the real squad in view.
      .sort((a, b) => (b.start ?? '').localeCompare(a.start ?? '') || a.player.name.localeCompare(b.player.name)),
    former: shaped
      .filter((s) => !isCurrent(s))
      .sort((a, b) => (b.end ?? b.start ?? '').localeCompare(a.end ?? a.start ?? '')),
  });
});
