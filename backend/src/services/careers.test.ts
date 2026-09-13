import { test } from 'node:test';
import assert from 'node:assert/strict';
import { clubStatus, conflictsFor, movesOf, overlaps, planTransfer, staleOpenSpells, type Spell } from './careers.js';

let seq = 0;
const spell = (p: Partial<Spell> & Pick<Spell, 'teamId' | 'start'>): Spell => ({
  id: ++seq,
  teamName: `Team ${p.teamId}`,
  teamType: 'CLUB',
  end: null,
  type: 'PERMANENT',
  ...p,
});
const club = (id: number) => ({ id, name: `Team ${id}`, type: 'CLUB' as const });

test('spells that only touch do not overlap — the legacy convention', () => {
  assert.equal(overlaps({ start: '2017-08-01', end: '2018-08-01' }, { start: '2018-08-01', end: null }), false);
  assert.equal(overlaps({ start: '2017-08-01', end: '2018-08-02' }, { start: '2018-08-01', end: null }), true);
  assert.equal(overlaps({ start: '2017-08-01', end: null }, { start: '2030-01-01', end: null }), true);
});

test('loans and national teams never clash; two club contracts do', () => {
  const yanga = spell({ teamId: 76, start: '2018-08-01' });
  const tanzania = spell({ teamId: 900, teamType: 'NATIONAL', start: '2019-01-01' });
  const others = [yanga, tanzania];
  assert.equal(conflictsFor({ start: '2020-01-01', end: null, type: 'LOAN', teamType: 'CLUB' }, others).length, 0);
  assert.equal(conflictsFor({ start: '2020-01-01', end: null, type: 'PERMANENT', teamType: 'NATIONAL' }, others).length, 0);
  assert.deepEqual(conflictsFor({ start: '2020-01-01', end: null, type: 'PERMANENT', teamType: 'CLUB' }, others), [yanga]);
});

test('status distinguishes a free agent from a player with no club history', () => {
  assert.equal(clubStatus([], '2026-09-12').kind, 'NO_CLUB_HISTORY');
  const done = spell({ teamId: 1, start: '2020-01-01', end: '2024-06-30' });
  const s = clubStatus([done], '2026-09-12');
  assert.equal(s.kind, 'FREE_AGENT');
  assert.equal(s.kind === 'FREE_AGENT' && s.lastClub.id, done.id);
});

test('status reports a loan alongside the parent club', () => {
  const parent = spell({ teamId: 1, start: '2024-07-01' });
  const loan = spell({ teamId: 2, start: '2026-01-15', end: '2026-06-30', type: 'LOAN' });
  const s = clubStatus([parent, loan], '2026-03-01');
  assert.equal(s.kind, 'AT_CLUB');
  assert.equal(s.kind === 'AT_CLUB' && s.club.teamId, 1);
  assert.equal(s.kind === 'AT_CLUB' && s.loan?.teamId, 2);
  // Once the loan's end date passes, the player is simply back at the parent.
  const after = clubStatus([parent, loan], '2026-07-01');
  assert.equal(after.kind === 'AT_CLUB' && after.loan, null);
});

test('an open spell contradicted by a later one is flagged, with the fix', () => {
  const yanga = spell({ teamId: 76, start: '2018-08-01' });
  const fountain = spell({ teamId: 350, start: '2023-10-08', end: '2024-05-28' });
  assert.equal(staleOpenSpells([yanga, fountain]).get(yanga.id), '2023-10-08');
});

test('a permanent move ends every club spell running that day, loan included, but not the national team', () => {
  const parent = spell({ teamId: 1, start: '2022-07-01' });
  const loan = spell({ teamId: 2, start: '2026-01-01', type: 'LOAN' });
  const nation = spell({ teamId: 900, teamType: 'NATIONAL', start: '2021-01-01' });
  const plan = planTransfer([parent, loan, nation], { toTeam: club(3), date: '2026-08-01', type: 'PERMANENT', loanUntil: null });
  assert.ok(!('error' in plan));
  assert.deepEqual(plan.close.map((c) => [c.spell.id, c.end]).sort(), [[parent.id, '2026-08-01'], [loan.id, '2026-08-01']].sort());
  assert.deepEqual(plan.create, { teamId: 3, start: '2026-08-01', end: null, type: 'PERMANENT' });
});

test('a loan keeps the parent spell open and needs a parent at all', () => {
  const parent = spell({ teamId: 1, start: '2022-07-01' });
  const plan = planTransfer([parent], { toTeam: club(2), date: '2026-08-01', type: 'LOAN', loanUntil: '2027-05-31' });
  assert.ok(!('error' in plan));
  assert.equal(plan.close.length, 0);
  assert.deepEqual(plan.create, { teamId: 2, start: '2026-08-01', end: '2027-05-31', type: 'LOAN' });

  const orphan = planTransfer([], { toTeam: club(2), date: '2026-08-01', type: 'LOAN', loanUntil: null });
  assert.ok('error' in orphan);
  const toParent = planTransfer([parent], { toTeam: club(1), date: '2026-08-01', type: 'LOAN', loanUntil: null });
  assert.ok('error' in toParent);
  const backwards = planTransfer([parent], { toTeam: club(2), date: '2026-08-01', type: 'LOAN', loanUntil: '2026-07-01' });
  assert.ok('error' in backwards);
});

test('release ends current club spells and starts nothing', () => {
  const parent = spell({ teamId: 1, start: '2022-07-01' });
  const plan = planTransfer([parent], { toTeam: null, date: '2026-08-01', type: 'PERMANENT', loanUntil: null });
  assert.ok(!('error' in plan));
  assert.equal(plan.create, null);
  assert.deepEqual(plan.close.map((c) => c.spell.id), [parent.id]);
  assert.ok('error' in planTransfer([], { toTeam: null, date: '2026-08-01', type: 'PERMANENT', loanUntil: null }));
});

test('moves that contradict the recorded history are refused, not guessed at', () => {
  const at1 = spell({ teamId: 1, start: '2022-07-01' });
  assert.ok('error' in planTransfer([at1], { toTeam: club(1), date: '2026-08-01', type: 'PERMANENT', loanUntil: null }), 'already there');
  const future = spell({ teamId: 5, start: '2027-01-01' });
  assert.ok('error' in planTransfer([at1, future], { toTeam: club(3), date: '2026-08-01', type: 'PERMANENT', loanUntil: null }), 'later spell exists');
  const startsToday = spell({ teamId: 4, start: '2026-08-01' });
  assert.ok('error' in planTransfer([startsToday], { toTeam: club(3), date: '2026-08-01', type: 'PERMANENT', loanUntil: null }), 'zero-length spell');
  assert.ok('error' in planTransfer([at1], { toTeam: { id: 900, name: 'Tanzania', type: 'NATIONAL' }, date: '2026-08-01', type: 'PERMANENT', loanUntil: null }), 'national team');
});

test('a loan cannot outlive the parent spell it belongs to', () => {
  const parent = spell({ teamId: 1, start: '2024-07-01', end: '2026-08-01' });
  const later = spell({ teamId: 3, start: '2026-08-01' });
  const open = planTransfer([parent, later], { toTeam: club(2), date: '2026-07-01', type: 'LOAN', loanUntil: null });
  assert.ok('error' in open, 'open-ended loan past the parent’s end');
  const tooLong = planTransfer([parent, later], { toTeam: club(2), date: '2026-07-01', type: 'LOAN', loanUntil: '2026-12-31' });
  assert.ok('error' in tooLong, 'loan ending after the parent');
  const fits = planTransfer([parent, later], { toTeam: club(2), date: '2026-07-01', type: 'LOAN', loanUntil: '2026-08-01' });
  assert.ok(!('error' in fits), 'loan ending with the parent is fine');
});

test('moves are read off spells: first club, transfer, loan, release', () => {
  const singida = spell({ teamId: 347, teamName: 'Singida', start: '2017-08-01', end: '2018-08-01' });
  const yanga = spell({ teamId: 76, teamName: 'Yanga', start: '2018-08-01', end: '2023-07-01' });
  const loan = spell({ teamId: 9, teamName: 'Loan FC', start: '2020-01-10', end: '2020-06-30', type: 'LOAN' });
  const nation = spell({ teamId: 900, teamType: 'NATIONAL', start: '2019-01-01' });
  const moves = movesOf([singida, yanga, loan, nation]);
  const pick = (k: string) => moves.filter((m) => m.kind === k);

  assert.deepEqual(pick('FIRST_CLUB').map((m) => m.to?.id), [singida.id]);
  assert.deepEqual(pick('TRANSFER').map((m) => [m.from?.id, m.to?.id, m.date]), [[singida.id, yanga.id, '2018-08-01']]);
  assert.deepEqual(pick('LOAN').map((m) => [m.from?.id, m.to?.id]), [[yanga.id, loan.id]], 'loan names the parent');
  assert.deepEqual(pick('RELEASE').map((m) => [m.from?.id, m.date]), [[yanga.id, '2023-07-01']]);
  assert.ok(moves.every((m) => m.to?.teamType !== 'NATIONAL'), 'call-ups are not moves');
  assert.deepEqual(moves.map((m) => m.date), [...moves.map((m) => m.date)].sort().reverse(), 'newest first');
});

test('undoing a transfer reopens the old spell only when nothing else depends on it', () => {
  const azam = spell({ teamId: 1, start: '2022-07-01', end: '2026-08-01' });
  const simba = spell({ teamId: 2, start: '2026-08-01' });
  const [move] = movesOf([azam, simba]).filter((m) => m.kind === 'TRANSFER');
  assert.equal(move?.reopens?.id, azam.id, 'the latest move, touching: reopen the old club');

  // A gap between spells: the old spell ended for its own reasons.
  const gap = movesOf([spell({ teamId: 1, start: '2020-01-01', end: '2021-01-01' }), spell({ teamId: 2, start: '2021-06-01' })])
    .find((m) => m.kind === 'TRANSFER');
  assert.equal(gap?.reopens, null);

  // A move in the middle of a career: reopening would collide with later spells.
  const a = spell({ teamId: 1, start: '2015-01-01', end: '2018-01-01' });
  const b = spell({ teamId: 2, start: '2018-01-01', end: '2020-01-01' });
  const c = spell({ teamId: 3, start: '2020-01-01' });
  const middle = movesOf([a, b, c]).find((m) => m.to?.id === b.id);
  assert.equal(middle?.reopens, null);
});
