import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';
import { env } from './env.js';

// Prisma 7 connects through a driver adapter rather than a `url` in schema.prisma.
//
// `timezone=UTC` is not cosmetic. The adapter decodes a TIMESTAMPTZ by reading
// the wall-clock Postgres renders and discarding the offset, so with a session
// on America/Chicago the vault's 13:00Z kickoff came back as a Date at 08:00Z --
// every kickoff shifted by the server's offset, and a late one moved to the
// wrong day. Pinning the session to UTC makes the rendered wall-clock and the
// instant the same thing, so nothing is lost in the decode.
//
// Verified by comparing against `extract(epoch from kickoff_at)`, which
// Postgres computes server-side and the bug cannot touch.
const adapter = new PrismaPg({
  connectionString: env.DATABASE_URL,
  options: '-c timezone=UTC',
});

export const prisma = new PrismaClient({
  adapter,
  log: env.NODE_ENV === 'development' ? ['warn', 'error'] : ['error'],
});
