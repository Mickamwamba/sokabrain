import 'dotenv/config';
import { z } from 'zod';

// Fail fast and loudly at boot rather than at the first query.
const schema = z.object({
  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),
  PORT: z.coerce.number().int().positive().default(4000),
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
});

const parsed = schema.safeParse(process.env);
if (!parsed.success) {
  console.error('Invalid environment:', z.treeifyError(parsed.error));
  process.exit(1);
}

export const env = parsed.data;
