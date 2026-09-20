/**
 * Publish (or unpublish) competition editions from the command line.
 *
 *   npm run editions:publish -- --ids 404,405,406       # dry run
 *   npm run editions:publish -- --ids 404,405,406 --apply
 *   npm run editions:publish -- --ids 407 --unpublish --apply
 *
 * Publishing is what makes an edition public, so this goes through
 * `services/flags.ts` rather than writing `is_published` directly: an edition
 * carrying an open BLOCKER flag is refused, and `published_at`/`published_by`
 * are recorded. The admin console does the same thing through the UI; this is
 * for doing several at once.
 *
 * It prints what each edition actually holds first, because publishing a thin
 * season is the mistake worth catching before it is public, not after.
 */
import { parseArgs } from 'node:util';
import { prisma } from '../db.js';
import { publishEdition, unpublishEdition, editionFlagSummary } from '../services/flags.js';

const { values } = parseArgs({
  options: {
    ids: { type: 'string' },
    admin: { type: 'string' },
    unpublish: { type: 'boolean', default: false },
    apply: { type: 'boolean', default: false },
  },
});

const ids = (values.ids ?? '')
  .split(',')
  .map((s) => Number(s.trim()))
  .filter(Number.isInteger);

if (ids.length === 0) {
  console.error('Usage: npm run editions:publish -- --ids 404,405 [--unpublish] [--admin <id>] [--apply]');
  process.exit(1);
}

try {
  let adminId = Number(values.admin);
  if (!Number.isInteger(adminId)) {
    const first = await prisma.admins.findFirst({
      where: { is_active: true },
      orderBy: { id: 'asc' },
      select: { id: true, email: true },
    });
    if (!first) {
      console.error('No active admin to attribute the publication to. Run `npm run admin:create`.');
      process.exit(1);
    }
    adminId = first.id;
    console.log(`Attributing to admin #${first.id} (${first.email})\n`);
  }

  for (const id of ids) {
    const edition = await prisma.competition_editions.findUnique({
      where: { id },
      include: {
        competitions: { select: { name: true, countries: { select: { name: true } } } },
        seasons: { select: { label: true } },
      },
    });
    if (!edition) {
      console.log(`#${id}  NOT FOUND`);
      continue;
    }

    const [fixtures, scored, rounded, events] = await Promise.all([
      prisma.matches.count({ where: { competition_edition_id: id } }),
      prisma.matches.count({ where: { competition_edition_id: id, home_score: { not: null } } }),
      prisma.matches.count({ where: { competition_edition_id: id, round: { not: null } } }),
      prisma.match_events.count({ where: { matches: { competition_edition_id: id } } }),
    ]);
    const flags = await editionFlagSummary(id);

    console.log(
      `#${id}  ${edition.competitions.countries?.name ?? '?'} — ` +
        `${edition.competitions.name} ${edition.seasons.label}`,
    );
    console.log(
      `      ${fixtures} fixtures, ${scored} with a score, ${rounded} with a round, ${events} events` +
        `  |  flags: ${flags.bySeverity.BLOCKER} blocker, ${flags.bySeverity.WARNING} warning, ${flags.bySeverity.INFO} info`,
    );
    console.log(`      currently ${edition.is_published ? 'PUBLISHED' : 'unpublished'}`);

    if (!values.apply) {
      console.log(`      would ${values.unpublish ? 'UNPUBLISH' : 'PUBLISH'} (dry run)\n`);
      continue;
    }

    if (values.unpublish) {
      await unpublishEdition(id);
      console.log('      UNPUBLISHED\n');
    } else {
      const result = await publishEdition(id, adminId);
      if (result.ok) console.log('      PUBLISHED\n');
      else {
        console.log(`      REFUSED: ${result.reason}`);
        for (const b of result.blockers) console.log(`        blocker #${b.id}: ${b.reason}`);
        console.log();
      }
    }
  }

  if (!values.apply) console.log('Dry run. Nothing changed. Re-run with --apply.');
} finally {
  await prisma.$disconnect();
}
