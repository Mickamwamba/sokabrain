/**
 * Ensure the `data_sources` rows this codebase writes provenance for exist.
 * Rerunnable — does nothing if they are already present.
 *
 *   npm run seed:sources
 */
import { prisma } from '../db.js';

const SOURCES = [
  { name: 'manual_admin', type: 'MANUAL', base_url: null },
  { name: 'api_football', type: 'API', base_url: 'https://v3.football.api-sports.io' },
] as const;

for (const s of SOURCES) {
  const row = await prisma.data_sources.upsert({
    where: { name: s.name },
    create: { name: s.name, type: s.type, base_url: s.base_url },
    update: { type: s.type, base_url: s.base_url },
    select: { id: true, name: true, type: true },
  });
  console.log(`  #${row.id} ${row.name} (${row.type})`);
}

await prisma.$disconnect();
