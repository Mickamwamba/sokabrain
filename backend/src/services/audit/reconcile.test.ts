import { test } from 'node:test';
import assert from 'node:assert/strict';
import { fingerprint, planReconciliation, type Detection, type ExistingFinding, type Scope } from './reconcile.js';

const scope: Scope = { editionIds: new Set([10, 11]), includeCareers: false };

const detection = (entityId: number, facts: Record<string, unknown> = { n: 1 }, over: Partial<Detection> = {}): Detection => ({
  checkKey: 'UNNAMED_SCORER', entityType: 'match', entityId, editionId: 10,
  severity: 'WARNING', detail: 'x', facts, ...over,
});

let seq = 100;
const finding = (d: Detection, status: ExistingFinding['status']): ExistingFinding => ({
  id: ++seq, checkKey: d.checkKey, entityType: d.entityType, entityId: d.entityId,
  editionId: d.editionId, status, fingerprint: fingerprint(d.facts),
});

test('fingerprints ignore key order and change with the facts', () => {
  assert.equal(fingerprint({ a: 1, b: [2, { c: 3, d: 4 }] }), fingerprint({ b: [2, { d: 4, c: 3 }], a: 1 }));
  assert.notEqual(fingerprint({ goals: 2 }), fingerprint({ goals: 3 }));
});

test('a new problem opens a finding; a known open one is refreshed, not duplicated', () => {
  const d1 = detection(1);
  const d2 = detection(2);
  const plan = planReconciliation([finding(d1, 'OPEN')], [d1, d2, d2], scope);
  assert.deepEqual(plan.insert.map((i) => i.entityId), [2]);
  assert.deepEqual(plan.update.map((u) => [u.status, u.reopened]), [[null, false]]);
  assert.deepEqual(plan.counts, { detected: 2, opened: 1, reopened: 0, resolved: 0 });
});

test('FIXED that is still detected reopens — the fix did not take', () => {
  const d = detection(1);
  const plan = planReconciliation([finding(d, 'FIXED')], [d], scope);
  assert.deepEqual(plan.update.map((u) => [u.status, u.reopened]), [['OPEN', true]]);
  assert.equal(plan.counts.reopened, 1);
});

test('ACCEPTED stays accepted while unchanged, and reopens when the facts change', () => {
  const accepted = finding(detection(1, { goals: 3 }), 'ACCEPTED');
  const same = planReconciliation([accepted], [detection(1, { goals: 3 })], scope);
  assert.deepEqual(same.update.map((u) => u.status), [null]);
  assert.equal(same.counts.reopened, 0);
  const changed = planReconciliation([accepted], [detection(1, { goals: 5 })], scope);
  assert.deepEqual(changed.update.map((u) => u.status), ['OPEN']);
  assert.equal(changed.counts.reopened, 1);
});

test('a RESOLVED problem that comes back reopens', () => {
  const d = detection(1);
  const plan = planReconciliation([finding(d, 'RESOLVED')], [d], scope);
  assert.deepEqual(plan.update.map((u) => u.status), ['OPEN']);
});

test('anything no longer detected is resolved by the run — whatever an admin said about it', () => {
  const open = finding(detection(1), 'OPEN');
  const fixed = finding(detection(2), 'FIXED');
  const accepted = finding(detection(3), 'ACCEPTED');
  const already = finding(detection(4), 'RESOLVED');
  const plan = planReconciliation([open, fixed, accepted, already], [], scope);
  assert.deepEqual(plan.resolve.sort(), [open.id, fixed.id, accepted.id].sort());
  assert.equal(plan.counts.resolved, 3);
});

test('a scoped run never resolves findings outside its scope', () => {
  const otherSeason = finding(detection(1, {}, { editionId: 99 }), 'OPEN');
  const career = finding(detection(2, {}, { checkKey: 'OVERLAPPING_SPELLS', entityType: 'player', editionId: null }), 'OPEN');
  const plan = planReconciliation([otherSeason, career], [], scope);
  assert.deepEqual(plan.resolve, []);
  const withCareers = planReconciliation([otherSeason, career], [], { ...scope, includeCareers: true });
  assert.deepEqual(withCareers.resolve, [career.id]);
});
