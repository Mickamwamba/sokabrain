import 'dotenv/config';
import { defineConfig, env } from 'prisma/config';

// Prisma 7 moved the connection URL out of schema.prisma and into this file.
// It is used by CLI commands (db pull, generate); the runtime client gets its
// connection separately via the pg driver adapter in src/db.ts.
export default defineConfig({
  schema: 'prisma/schema.prisma',
  datasource: {
    url: env('DATABASE_URL'),
  },
});
