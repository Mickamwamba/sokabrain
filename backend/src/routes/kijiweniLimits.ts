import type { Request, RequestHandler, Response } from 'express';
import { rateLimit } from 'express-rate-limit';

/**
 * Rate limits for Kijiweni's public write endpoints.
 *
 * Posting needs no account, so without these one script could fill the forum.
 * Two layers, because neither is enough alone:
 *
 * * **Per client**, keyed on `req.ip`. That is only the fan's real address when
 *   `TRUST_PROXY` matches the proxies in front of the backend (see
 *   `docs/RUNBOOK.md`). Misconfigured, every web fan shares one address and one
 *   budget, or a fan can fake an address and dodge the limit.
 * * **Site-wide**, a ceiling on new threads and comments from everyone together.
 *   It holds however the addresses turn out, so a flood stays bounded even when
 *   the per-client layer is fooled. Likes have no site-wide ceiling: a like only
 *   moves a counter, and one would let a single client stop everyone liking.
 *
 * Mobile carriers put many fans behind one address, so the per-client numbers
 * are set well above what one person posts. Counts live in memory: they reset on
 * restart and are per process.
 */

const MINUTE = 60_000;
const HOUR = 60 * MINUTE;

type Window = { limit: number; windowMs: number };

export type KijiweniLimitConfig = {
  thread: { perClient: Window; siteWide: Window };
  comment: { perClient: Window; siteWide: Window };
  like: { perClient: Window };
};

export const KIJIWENI_LIMITS: KijiweniLimitConfig = {
  thread: { perClient: { limit: 5, windowMs: HOUR }, siteWide: { limit: 100, windowMs: HOUR } },
  comment: { perClient: { limit: 20, windowMs: 10 * MINUTE }, siteWide: { limit: 600, windowMs: HOUR } },
  like: { perClient: { limit: 60, windowMs: MINUTE } },
};

let warnedAboutProxy = false;

/**
 * A limited client whose address is this machine is almost certainly the web
 * server's rewrite proxy, which means every web fan is sharing one budget.
 */
function warnIfProxyAddress(req: Request): void {
  const ip = req.ip ?? '';
  if (warnedAboutProxy || !(ip === '::1' || ip.startsWith('127.') || ip.startsWith('::ffff:127.'))) {
    return;
  }
  warnedAboutProxy = true;
  console.warn(
    `Kijiweni rate limit reached for ${ip}, a local address. If that is the web ` +
      'server, all web fans share one limit: set TRUST_PROXY (docs/RUNBOOK.md).',
  );
}

function perClient(window: Window, error: string): RequestHandler {
  return rateLimit({
    ...window,
    standardHeaders: 'draft-8',
    legacyHeaders: false,
    handler: (req: Request, res: Response) => {
      warnIfProxyAddress(req);
      res.status(429).json({ error });
    },
  });
}

function siteWide(window: Window, error: string): RequestHandler {
  return rateLimit({
    ...window,
    standardHeaders: 'draft-8',
    legacyHeaders: false,
    keyGenerator: () => 'site-wide',
    handler: (_req: Request, res: Response) => {
      res.status(429).json({ error });
    },
  });
}

/**
 * Middleware chains for each write route. Per-client runs first, so a client it
 * stops does not use up the site-wide budget for everyone else.
 *
 * One `like` chain serves thread likes and comment likes, so they share a budget.
 */
export function createKijiweniLimits(config: KijiweniLimitConfig = KIJIWENI_LIMITS) {
  const busy = 'Kijiweni is very busy right now. Try again in a few minutes.';
  return {
    thread: [
      perClient(config.thread.perClient, 'You have started too many threads. Try again later.'),
      siteWide(config.thread.siteWide, busy),
    ],
    comment: [
      perClient(config.comment.perClient, 'You are commenting too fast. Wait a few minutes and try again.'),
      siteWide(config.comment.siteWide, busy),
    ],
    like: [perClient(config.like.perClient, 'Too many likes. Wait a minute and try again.')],
  };
}
