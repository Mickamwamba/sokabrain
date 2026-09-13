import { Router, type Request, type Response } from 'express';
import { Prisma } from '@prisma/client';
import { z } from 'zod';
import { prisma } from '../db.js';
import { recordManualProvenance } from '../services/provenance.js';
import {
  clubStatus,
  conflictsFor,
  movesOf,
  planTransfer,
  staleOpenSpells,
  type Move,
  type MoveKind,
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

/* ------------------------------------------------------- transfer centre -- */
// Every move across the vault, read off the spells by `movesOf` — the same
// rule the player page uses — so the centre and a player's history can never
// describe the same career differently.

const MOVE_KINDS = ['TRANSFER', 'LOAN', 'FIRST_CLUB', 'RELEASE'] as const;

/** All club and national spells, grouped by player, with names. */
async function everyCareer() {
  const rows = await prisma.player_team_stints.findMany({
    include: {
      teams: { select: { id: true, name: true, type: true } },
      players: { select: { id: true, full_name: true } },
    },
  });
  const byPlayer = new Map<number, { name: string; spells: LoadedSpell[] }>();
  for (const r of rows) {
    const entry = byPlayer.get(r.player_id) ?? { name: r.players.full_name, spells: [] };
    entry.spells.push({
      id: r.id,
      teamId: r.team_id,
      teamName: r.teams.name,
      teamType: r.teams.type as 'CLUB' | 'NATIONAL',
      start: r.start_date ? day(r.start_date) : '0001-01-01',
      end: r.end_date ? day(r.end_date) : null,
      type: (r.transfer_type as SpellType | null) ?? null,
      shirtNumber: r.shirt_number,
      fee: r.transfer_fee?.toString() ?? null,
    });
    byPlayer.set(r.player_id, entry);
  }
  return byPlayer;
}

const spellView = (s: Spell | null) =>
  s && {
    spellId: s.id,
    team: { id: s.teamId, name: s.teamName },
    start: s.start,
    end: s.end,
    type: s.type,
    shirtNumber: (s as LoadedSpell).shirtNumber ?? null,
    fee: (s as LoadedSpell).fee ?? null,
  };

const moveKey = (m: Move) => `${m.kind}:${(m.to ?? m.from)!.id}`;

const feedQuery = z.object({
  /** MOVES = transfers and loans together, the default view. */
  kind: z.enum(['MOVES', 'ALL', ...MOVE_KINDS]).default('MOVES'),
  teamId: z.coerce.number().int().positive().optional(),
  q: z.string().trim().max(100).optional(),
  from: isoDate.optional(),
  to: isoDate.optional(),
  page: z.coerce.number().int().min(1).default(1),
  pageSize: z.coerce.number().int().min(1).max(100).default(30),
});

careersRouter.get('/transfers', async (req, res) => {
  const parsed = feedQuery.safeParse(req.query);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid query' });
  const { kind, teamId, q, from, to, page, pageSize } = parsed.data;

  const careers = await everyCareer();
  const now = today();
  const monthAgo = day(new Date(Date.now() - 30 * 86_400_000));

  let activeLoans = 0;
  let freeAgents = 0;
  const all: { move: Move; player: { id: number; name: string } }[] = [];
  for (const [playerId, { name, spells }] of careers) {
    const status = clubStatus(spells, now);
    if (status.kind === 'FREE_AGENT') freeAgents++;
    if ((status.kind === 'AT_CLUB' && status.loan) || status.kind === 'ON_LOAN_ONLY') activeLoans++;
    for (const move of movesOf(spells)) all.push({ move, player: { id: playerId, name } });
  }

  const needle = q?.toLowerCase();
  // Everything but the kind filter, so the tab counts describe the same slice.
  const scoped = all.filter(({ move, player }) =>
    (!teamId || move.from?.teamId === teamId || move.to?.teamId === teamId) &&
    (!needle || player.name.toLowerCase().includes(needle)) &&
    (!from || move.date >= from) &&
    (!to || move.date <= to),
  );
  const counts = Object.fromEntries(MOVE_KINDS.map((k) => [k, scoped.filter((x) => x.move.kind === k).length])) as Record<MoveKind, number>;
  const shown = scoped
    .filter(({ move }) =>
      kind === 'ALL' ? true : kind === 'MOVES' ? move.kind === 'TRANSFER' || move.kind === 'LOAN' : move.kind === kind,
    )
    .sort((a, b) => b.move.date.localeCompare(a.move.date) || a.player.name.localeCompare(b.player.name));

  res.json({
    today: now,
    total: shown.length,
    page,
    pageSize,
    counts,
    summary: {
      movesLast30Days: all.filter((x) => (x.move.kind === 'TRANSFER' || x.move.kind === 'LOAN') && x.move.date >= monthAgo && x.move.date <= now).length,
      activeLoans,
      freeAgents,
    },
    moves: shown.slice((page - 1) * pageSize, page * pageSize).map(({ move, player }) => ({
      key: moveKey(move),
      kind: move.kind,
      date: move.date,
      player,
      from: spellView(move.from),
      to: spellView(move.to),
      reopens: move.reopens ? { spellId: move.reopens.id, team: { id: move.reopens.teamId, name: move.reopens.teamName } } : null,
    })),
  });
});

/** Find one move by kind and the spell it hangs off (the arrival, or the spell a release ended). */
async function findMove(kind: MoveKind, spellId: number) {
  const row = await prisma.player_team_stints.findUnique({ where: { id: spellId }, select: { player_id: true } });
  if (!row) return null;
  const spells = await loadSpells(prisma, row.player_id);
  const move = movesOf(spells).find((m) => m.kind === kind && (kind === 'RELEASE' ? m.from?.id : m.to?.id) === spellId);
  return move ? { move, spells, playerId: row.player_id } : null;
}

const moveRef = z.object({ kind: z.enum(MOVE_KINDS), spellId: z.number().int().positive() });

/**
 * Take a move back. An arrival's spell is deleted, and the spell it ended
 * carries on again when `movesOf` says that is safe; a release's spell simply
 * becomes ongoing again.
 */
careersRouter.post('/transfers/undo', async (req, res) => {
  const b = body(moveRef, req, res);
  if (!b) return;
  const found = await findMove(b.kind, b.spellId);
  if (!found) return res.status(404).json({ error: 'No such move — the history may have changed since the page loaded.' });
  const { move } = found;

  await prisma.$transaction(async (tx) => {
    if (move.kind !== 'RELEASE' && move.to) {
      await tx.player_team_stints.delete({ where: { id: move.to.id } });
      await tx.entity_source_map.deleteMany({ where: { entity_type: 'player_team_stint', entity_id: move.to.id } });
    }
    if (move.reopens) {
      await tx.player_team_stints.update({ where: { id: move.reopens.id }, data: { end_date: null } });
      await recordManualProvenance(tx, 'player_team_stint', move.reopens.id);
    }
  });
  res.json({ ok: true, reopened: move.reopens ? move.reopens.teamName : null });
});

const moveEdit = moveRef.extend({
  date: isoDate.optional(),
  type: z.enum(['PERMANENT', 'FREE', 'YOUTH']).nullish(),
  fee: z.number().min(0).max(9_999_999_999.99).nullish(),
  shirtNumber: z.number().int().min(0).max(99).nullish(),
});

/**
 * Correct a move. Changing a transfer's date moves both sides together — the
 * old spell's end and the new spell's start — when they touch, so correcting a
 * date never opens a gap or an overlap. A move's kind is not editable: turning
 * a transfer into a loan changes which spells end, so undo it and record again.
 */
careersRouter.patch('/transfers', async (req, res) => {
  const b = body(moveEdit, req, res);
  if (!b) return;
  const found = await findMove(b.kind, b.spellId);
  if (!found) return res.status(404).json({ error: 'No such move — the history may have changed since the page loaded.' });
  const { move, spells } = found;
  const date = b.date ?? move.date;

  if (move.kind === 'RELEASE') {
    const left = move.from!;
    if (date <= left.start) return res.status(400).json({ error: `The spell at ${left.teamName} starts ${left.start}; they must leave after that.` });
    await prisma.$transaction(async (tx) => {
      await tx.player_team_stints.update({ where: { id: left.id }, data: { end_date: asDate(date) } });
      await recordManualProvenance(tx, 'player_team_stint', left.id);
    });
    return res.json({ ok: true });
  }

  const arrival = move.to!;
  if (b.type !== undefined && move.kind === 'LOAN') {
    return res.status(400).json({ error: 'A loan stays a loan. Undo it and record a permanent move instead.' });
  }
  if (arrival.end !== null && date >= arrival.end) {
    return res.status(400).json({ error: `The spell at ${arrival.teamName} ends ${arrival.end}; the move must come before that.` });
  }

  // The previous spell moves with the date only when the two touch.
  const linked = move.kind === 'TRANSFER' && move.from && move.from.end === move.date ? move.from : null;
  if (linked && date <= linked.start) {
    return res.status(400).json({ error: `The spell at ${linked.teamName} starts ${linked.start}; the move must come after that.` });
  }
  if (move.kind === 'LOAN' && move.from && (date <= move.from.start || (move.from.end !== null && date >= move.from.end))) {
    return res.status(400).json({ error: `A loan must start within the spell at ${move.from.teamName}.` });
  }

  if (date !== move.date) {
    const after = spells.map((s) =>
      s.id === arrival.id ? { ...s, start: date } : linked && s.id === linked.id ? { ...s, end: date } : s,
    );
    const moved = after.find((s) => s.id === arrival.id)!;
    const before = new Set(conflictsFor(arrival, spells).map((c) => c.id));
    const introduced = conflictsFor(moved, after).filter((c) => !before.has(c.id));
    if (introduced.length) return res.status(409).json({ error: clashMessage(introduced) });
  }

  await prisma.$transaction(async (tx) => {
    const data: Prisma.player_team_stintsUncheckedUpdateInput = {};
    if (date !== move.date) data.start_date = asDate(date);
    if (b.type !== undefined) data.transfer_type = b.type;
    if (b.fee !== undefined) data.transfer_fee = b.fee;
    if (b.shirtNumber !== undefined) data.shirt_number = b.shirtNumber;
    await tx.player_team_stints.update({ where: { id: arrival.id }, data });
    await recordManualProvenance(tx, 'player_team_stint', arrival.id);
    if (linked && date !== move.date) {
      await tx.player_team_stints.update({ where: { id: linked.id }, data: { end_date: asDate(date) } });
      await recordManualProvenance(tx, 'player_team_stint', linked.id);
    }
  });
  res.json({ ok: true });
});
