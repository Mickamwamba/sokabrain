/**
 * A player's career: which clubs they were at, when, and how they moved.
 *
 * Pure functions over spells (`player_team_stints` rows), so the rules can be
 * tested without a database. Dates are ISO `YYYY-MM-DD` strings throughout —
 * they compare correctly as strings and cannot drift across a timezone the way
 * a Date at midnight can.
 *
 * Conventions, taken from the data already in the vault rather than invented:
 *
 * - **A move is recorded with the old spell ending on the day the new one
 *   starts.** The legacy rows do exactly that (Singida until 2018-08-01, Yanga
 *   from 2018-08-01), so two spells that merely touch do not overlap.
 * - **Clubs and national teams are separate careers.** The AFCON ingest recorded
 *   call-ups as spells, and a player at Simba is still in Tanzania's squad. A
 *   transfer only ever closes club spells, and only club spells can clash.
 * - **A loan may overlap its parent club.** The parent spell stays open while
 *   the loan runs; two non-loan club spells at once is the contradiction.
 */

export type SpellType = 'PERMANENT' | 'LOAN' | 'FREE' | 'YOUTH';

export type Spell = {
  id: number;
  teamId: number;
  teamName: string;
  teamType: 'CLUB' | 'NATIONAL';
  start: string;
  /** Null while the spell is ongoing. */
  end: string | null;
  type: SpellType | null;
};

const isLoan = (s: Pick<Spell, 'type'>) => s.type === 'LOAN';

/** Strict overlap: spells that only touch (one ends as the next starts) don't. */
export function overlaps(a: Pick<Spell, 'start' | 'end'>, b: Pick<Spell, 'start' | 'end'>): boolean {
  return a.start < (b.end ?? '9999-12-31') && b.start < (a.end ?? '9999-12-31');
}

/**
 * The spells a candidate would contradict. Only club spells clash, and a loan
 * never clashes, because it runs alongside its parent club.
 */
export function conflictsFor(
  candidate: Pick<Spell, 'start' | 'end' | 'type' | 'teamType'> & { id?: number },
  others: Spell[],
): Spell[] {
  if (candidate.teamType !== 'CLUB' || isLoan(candidate)) return [];
  return others.filter(
    (o) => o.id !== candidate.id && o.teamType === 'CLUB' && !isLoan(o) && overlaps(candidate, o),
  );
}

/** Ongoing on a given day: started by then, and not ended before it. */
const ongoingOn = (s: Spell, day: string) => s.start <= day && (s.end === null || s.end > day);

export type CareerStatus =
  | { kind: 'AT_CLUB'; club: Spell; loan: Spell | null }
  | { kind: 'ON_LOAN_ONLY'; loan: Spell }
  | { kind: 'FREE_AGENT'; lastClub: Spell }
  | { kind: 'NO_CLUB_HISTORY' };

/**
 * Where the player is on `today`, club-wise.
 *
 * FREE_AGENT is distinct from NO_CLUB_HISTORY: the first has club spells, all
 * finished; the second has none on record at all — usually a gap in the
 * source, not a player without a club.
 */
export function clubStatus(spells: Spell[], today: string): CareerStatus {
  const clubs = spells.filter((s) => s.teamType === 'CLUB');
  if (clubs.length === 0) return { kind: 'NO_CLUB_HISTORY' };

  const latestFirst = (a: Spell, b: Spell) => b.start.localeCompare(a.start);
  const current = clubs.filter((s) => ongoingOn(s, today)).sort(latestFirst);
  const club = current.find((s) => !isLoan(s)) ?? null;
  const loan = current.find(isLoan) ?? null;

  if (club) return { kind: 'AT_CLUB', club, loan };
  if (loan) return { kind: 'ON_LOAN_ONLY', loan };

  const lastClub = [...clubs].sort((a, b) => (b.end ?? b.start).localeCompare(a.end ?? a.start))[0]!;
  return { kind: 'FREE_AGENT', lastClub };
}

/**
 * An open club spell that a later club spell contradicts — Yanga "since 2018,
 * still ongoing" next to spells at two other clubs in 2023 and 2025. The fix it
 * suggests is to end the open spell when the next one began.
 */
export function staleOpenSpells(spells: Spell[]): Map<number, string> {
  const clubs = spells.filter((s) => s.teamType === 'CLUB' && !isLoan(s));
  const stale = new Map<number, string>();
  for (const open of clubs.filter((s) => s.end === null)) {
    const next = clubs
      .filter((s) => s.id !== open.id && s.start > open.start)
      .sort((a, b) => a.start.localeCompare(b.start))[0];
    if (next) stale.set(open.id, next.start);
  }
  return stale;
}

export type TransferRequest = {
  /** Null releases the player: every current club spell ends, none begins. */
  toTeam: { id: number; name: string; type: 'CLUB' | 'NATIONAL' } | null;
  date: string;
  type: SpellType;
  /** A loan's agreed end, if known. */
  loanUntil: string | null;
};

export type TransferPlan = {
  close: { spell: Spell; end: string }[];
  create: { teamId: number; start: string; end: string | null; type: SpellType } | null;
};

/**
 * Work out what a transfer changes, or say why it cannot happen.
 *
 * A permanent, free or youth move ends every club spell running on the date —
 * including a loan, since the player has left for good. A loan ends only other
 * loans: the parent club spell carries on underneath it. A release ends
 * everything and starts nothing.
 */
export function planTransfer(spells: Spell[], req: TransferRequest): TransferPlan | { error: string } {
  const { toTeam, date, type, loanUntil } = req;
  if (toTeam && toTeam.type !== 'CLUB') {
    return { error: `${toTeam.name} is a national team. Transfers are between clubs; a call-up is recorded as a spell.` };
  }
  const clubs = spells.filter((s) => s.teamType === 'CLUB');

  // A club spell starting after the move would sit in the new spell's future:
  // the history needs untangling by hand before this move makes sense. A loan
  // is exempt because it is held inside its parent spell's dates (checked below).
  const later = clubs.find((s) => s.start > date && !isLoan(s));
  if (later && (type !== 'LOAN' || !toTeam)) {
    return {
      error: `There is already a spell at ${later.teamName} starting ${later.start}, after this move. Correct the history first.`,
    };
  }

  const running = clubs.filter((s) => ongoingOn(s, date));
  const parent = running.find((s) => !isLoan(s));

  if (type === 'LOAN' && toTeam) {
    if (!parent) {
      return { error: 'A loan needs a parent club. Record the move to that club first, or make this a permanent transfer.' };
    }
    if (parent.teamId === toTeam.id) return { error: `${toTeam.name} is the parent club; a player can’t be loaned to it.` };
    if (loanUntil !== null && loanUntil <= date) return { error: 'The loan must end after it starts.' };
    // A loan belongs to the parent contract and cannot outlive it: a player who
    // has since left the parent club is no longer theirs to lend.
    if (parent.end !== null && (loanUntil === null || loanUntil > parent.end)) {
      return {
        error: `The spell at ${parent.teamName} ends on ${parent.end}, so the loan must end by then. Give it an end date on or before ${parent.end}.`,
      };
    }
  } else if (toTeam && parent?.teamId === toTeam.id) {
    return { error: `The player is already at ${toTeam.name}.` };
  }
  if (!toTeam && running.length === 0) {
    return { error: 'The player has no club on that date, so there is nothing to release them from.' };
  }

  const toClose = type === 'LOAN' && toTeam ? running.filter(isLoan) : running;
  const sameDay = toClose.find((s) => s.start === date);
  if (sameDay) {
    return { error: `The spell at ${sameDay.teamName} only starts on ${date}. Edit or delete that spell instead.` };
  }

  return {
    close: toClose.map((spell) => ({ spell, end: date })),
    create: toTeam
      ? { teamId: toTeam.id, start: date, end: type === 'LOAN' ? loanUntil : null, type }
      : null,
  };
}
