import 'dotenv/config';
import { z } from 'zod';

// Fail fast and loudly at boot rather than at the first query.
const schema = z.object({
  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),
  PORT: z.coerce.number().int().positive().default(4000),
  // Unset (the default) binds every interface, as it always has. Set it to
  // restrict the server to one, e.g. 127.0.0.1 behind a reverse proxy. An
  // empty value is treated the same as unset, not as an empty hostname.
  HOST: z
    .string()
    .optional()
    .transform((v) => (v ? v : undefined)),
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  // Not needed until build priorities 3 and 5; optional so the read API boots without them.
  JWT_SECRET: z.string().optional(),
  API_FOOTBALL_KEY: z.string().optional(),
  SPORTMONKS_TOKEN: z.string().optional(),
  // Every 2 minutes: frequent enough for a live score to feel live, cheap
  // enough that a free-tier quota survives a full matchday.
  LIVE_SYNC_CRON: z.string().default('*/2 * * * *'),
  /** Set to 'false' to keep the scheduler off even with a key present. */
  LIVE_SYNC_ENABLED: z.enum(['true', 'false']).default('true'),
  /**
   * Which proxies may tell us a client's address through X-Forwarded-For, in
   * Express's 'trust proxy' syntax: a hop count, or addresses and names such as
   * 'loopback' (docs/RUNBOOK.md). Kijiweni's rate limits key on the result.
   * Off by default. 'true' is refused, because it would let any client pick its
   * own address and dodge the limits.
   */
  TRUST_PROXY: z
    .string()
    .default('false')
    .refine((v) => v !== 'true', "TRUST_PROXY=true trusts any client's claimed address")
    .transform((v): boolean | number | string =>
      v === 'false' ? false : /^\d+$/.test(v) ? Number(v) : v,
    ),
});

const parsed = schema.safeParse(process.env);
if (!parsed.success) {
  console.error('Invalid environment:', z.treeifyError(parsed.error));
  process.exit(1);
}

export const env = parsed.data;
