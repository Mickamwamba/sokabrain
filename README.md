# Sokabrain

A football data vault for leagues the global apps barely cover. It holds
fixtures, results, scorers and tables for the Tanzania, Kenya, Rwanda, Uganda
and South Africa top tiers, plus the Africa Cup of Nations back to 1957, along
with a record of which source every fact came from.

The aim is encyclopedia-level depth on local leagues, not competing with FotMob
on mainstream ones.

| Part | What it is | Stack |
|---|---|---|
| `backend/` | Read API, admin API, fan-zone API, live-score sync | Node, TypeScript, Express 5, Prisma 7 |
| `web/` | Public site and admin console | Next.js 16, React 19, Tailwind 4 |
| `mobile/` | Fan app over the same read API | Flutter |
| `docs/ingestion/` | One-off and recurring loaders, one per data source | Python 3.13 |
| Database | The vault | PostgreSQL 16 |

## Running it locally

You need PostgreSQL 16 (Postgres.app or Homebrew), Node 22+, Python 3.13 and,
for the mobile app, Flutter.

**1. Database.** Restore the committed snapshot of the whole vault:

```sh
./scripts/restore_db.sh                # creates database "sokabrain" as your OS user
```

`FORCE=1` replaces an existing database, and
`TARGET_URL=postgresql://...` restores somewhere else, such as Neon or Railway.

**2. Backend** (http://localhost:4010):

```sh
cd backend
cp .env.example .env                   # set DATABASE_URL and JWT_SECRET
npm install
npm run db:generate                    # Prisma client is generated, not committed
ADMIN_PASSWORD='at-least-12-chars' npm run admin:create -- --email you@example.com --name "You"
npm run dev
```

The snapshot carries no admin credentials, so every person creates their own
account with `admin:create`.

**3. Web** (http://localhost:3100, admin at `/admin`):

```sh
cd web
npm install
npm run dev
```

**4. Mobile:**

```sh
cd mobile
flutter pub get
flutter run
```

See `mobile/README.md` for pointing the app at a device-reachable backend.

**5. Python tooling** (only needed to run ingestion):

```sh
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
```

The scripts read `DATABASE_URL` from the environment and fall back to the local
`sokabrain` database.

## Tests

```sh
cd backend && npm test                 # needs the database (integration tests)
cd web && npx next typegen && npx tsc --noEmit && npm run lint
cd mobile && flutter analyze && flutter test   # needs the backend running
```

CI (`.github/workflows/ci.yml`) runs all of these, plus the Python doctests, on
every pull request.

## How the data works, in five rules

The full list is in `CLAUDE.md`. These five cover most of it:

1. **Every externally sourced row has provenance**, an `entity_source_map` row
   naming its source.
2. **A new source never silently overwrites the vault.** A disagreement becomes a
   `reconciliation_diffs` row for a human to settle.
3. **The score is stored on the match**, and the event log has to reproduce it
   before it is loaded.
4. **An own goal is stored under the scorer's own team** and displayed beside the
   team it counts for. Many sources do it the other way round.
5. **Absent data stays absent.** There are no invented events, abbreviated
   names or fabricated stats.

## Where things are documented

| File | Read it for |
|---|---|
| `CLAUDE.md` | Current state, design principles, and the rules learned the hard way. Start here. |
| `docs/RUNBOOK.md` | Recurring jobs, publishing, adding a league, admin accounts |
| `docs/OPEN_DECISIONS.md` | Data questions waiting on an editor |
| `docs/HISTORY.md` | Why everything is the way it is. Long, so search it rather than reading it end to end. |
| `docs/schema/` | DDL and schema rationale |
| `docs/ingestion/README.md` | The ingestion pipeline |
| `backend/README.md`, `web/README.md`, `mobile/README.md` | Per-app details and endpoints |
