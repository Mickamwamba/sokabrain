/**
 * Tests for Kijiweni's rate limits. No database: the limiters guard stub
 * handlers on a throwaway app, with small limits so the tests run fast.
 */
import { after, before, describe, it } from 'node:test';
import assert from 'node:assert/strict';
import type { AddressInfo } from 'node:net';
import type { Server } from 'node:http';
import express from 'express';
import { createKijiweniLimits } from './kijiweniLimits.js';

const HOUR = 3_600_000;
let server: Server;
let base = '';

before(async () => {
  const limits = createKijiweniLimits({
    thread: { perClient: { limit: 2, windowMs: HOUR }, siteWide: { limit: 3, windowMs: HOUR } },
    comment: { perClient: { limit: 2, windowMs: HOUR }, siteWide: { limit: 100, windowMs: HOUR } },
    like: { perClient: { limit: 3, windowMs: HOUR } },
  });
  const app = express();
  // The test client connects over loopback, so this lets each request name its
  // own client in X-Forwarded-For, as a trusted proxy in front would.
  app.set('trust proxy', 'loopback');
  const ok = (_req: express.Request, res: express.Response) => {
    res.status(201).json({ ok: true });
  };
  app.post('/threads', ...limits.thread, ok);
  app.post('/threads/:id/comments', ...limits.comment, ok);
  app.post('/threads/:id/like', ...limits.like, ok);
  app.post('/comments/:id/like', ...limits.like, ok);
  server = app.listen(0);
  await new Promise<void>((resolve) => server.once('listening', resolve));
  base = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
});

after(() => {
  server.close();
});

function post(path: string, client: string) {
  return fetch(`${base}${path}`, { method: 'POST', headers: { 'X-Forwarded-For': client } });
}

describe('kijiweni rate limits', () => {
  it('stops a client after its thread limit, with a JSON error and Retry-After', async () => {
    assert.equal((await post('/threads', '10.0.0.1')).status, 201);
    assert.equal((await post('/threads', '10.0.0.1')).status, 201);
    const blocked = await post('/threads', '10.0.0.1');
    assert.equal(blocked.status, 429);
    assert.ok(blocked.headers.get('retry-after'), 'Retry-After header is set');
    const body = (await blocked.json()) as { error: string };
    assert.match(body.error, /too many threads/i);
  });

  it('caps threads site-wide, and a blocked client did not use up that budget', async () => {
    // 10.0.0.1 has two threads counted site-wide; its blocked third was not.
    assert.equal((await post('/threads', '10.0.0.2')).status, 201);
    const fourth = await post('/threads', '10.0.0.3');
    assert.equal(fourth.status, 429);
    assert.match(((await fourth.json()) as { error: string }).error, /very busy/i);
  });

  it('counts each client separately', async () => {
    for (const client of ['10.1.0.1', '10.1.0.2']) {
      assert.equal((await post('/threads/1/comments', client)).status, 201);
      assert.equal((await post('/threads/1/comments', client)).status, 201);
    }
    assert.equal((await post('/threads/1/comments', '10.1.0.1')).status, 429);
  });

  it('gives thread and comment likes one shared budget', async () => {
    assert.equal((await post('/threads/1/like', '10.2.0.1')).status, 201);
    assert.equal((await post('/comments/1/like', '10.2.0.1')).status, 201);
    assert.equal((await post('/threads/2/like', '10.2.0.1')).status, 201);
    assert.equal((await post('/comments/2/like', '10.2.0.1')).status, 429);
  });
});
