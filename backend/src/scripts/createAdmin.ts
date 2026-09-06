/**
 * Create (or reset the password of) an admin account.
 *
 * There is no self-signup endpoint by design — accounts are provisioned from
 * the machine that holds the database credentials.
 *
 *   npm run admin:create -- --email you@example.com --name "Your Name"
 *
 * The password is read from the ADMIN_PASSWORD environment variable so it never
 * lands in shell history:
 *
 *   ADMIN_PASSWORD='...' npm run admin:create -- --email ... --name ...
 */
import { parseArgs } from 'node:util';
import { prisma } from '../db.js';
import { hashPassword } from '../auth/password.js';

const { values } = parseArgs({
  options: {
    email: { type: 'string' },
    name: { type: 'string' },
  },
  allowPositionals: false,
});

const email = values.email?.trim().toLowerCase();
const name = values.name?.trim();
const password = process.env.ADMIN_PASSWORD;

if (!email || !name) {
  console.error('Usage: ADMIN_PASSWORD=... npm run admin:create -- --email <email> --name <name>');
  process.exit(1);
}
if (!password || password.length < 12) {
  console.error('ADMIN_PASSWORD must be set and at least 12 characters.');
  process.exit(1);
}

const password_hash = await hashPassword(password);

const admin = await prisma.admins.upsert({
  where: { email },
  create: { email, display_name: name, password_hash },
  update: { password_hash, display_name: name, is_active: true },
  select: { id: true, email: true, display_name: true, created_at: true },
});

console.log(`Admin ready: #${admin.id} ${admin.email} (${admin.display_name})`);
await prisma.$disconnect();
