# Architecture

How Sokabrain fits together: what each part does, how data moves between them,
and the constraints that shape how it can be run. For running it locally see
the root `README.md`; for deploying it see `docs/DEPLOYMENT.md`; for the rules
the data obeys see `CLAUDE.md`.

Written 2026-10-01. Socket.io push (build priority 6) is not built yet, and the
system has never been deployed: the vault lives on one laptop.

## The system on one page

```mermaid
flowchart LR
  subgraph Clients
    B[Browser]
    M[Flutter app]
    A[Admin in browser]
  end

  subgraph Web["web/ (Next.js 16, :3100)"]
    SITE[Public site<br/>server-rendered pages]
    CONSOLE[Admin console<br/>/admin + server actions]
    RW[Rewrites<br/>/api/vault, /api/kijiweni]
  end

  subgraph API["backend/ (Express 5, :4010)"]
    VAULT[/api/vault<br/>read, public/]
    KIJ[/api/kijiweni<br/>fan zone, rate-limited/]
    ADMIN[/api/admin<br/>JWT/]
    CRON[Live-score sync<br/>node-cron, every 2 min]
    CLI[npm run sm:* / editions:* / admin:*<br/>one-off scripts]
  end

  PG[(PostgreSQL 16<br/>the vault)]
  SM[SportMonks API v3]
  PY[docs/ingestion/<br/>Python loaders]
  SRC[ligikuu, WhoScored, RSSSF,<br/>FotMob, league sites]
  SNAP[[sokabrain_vault_snapshot.sql<br/>committed to git]]

  B --> SITE
  B -- client-side fetches --> RW
  A --> CONSOLE
  M --> VAULT
  M --> KIJ
  SITE --> VAULT
  RW --> VAULT
  RW --> KIJ
  CONSOLE -- token from httpOnly cookie --> ADMIN
  VAULT --> PG
  KIJ --> PG
  ADMIN --> PG
  CRON -- in-play feed --> SM
  CRON --> PG
  CLI --> SM
  CLI --> PG
  PY --> SRC
  PY --> PG
  PG -. dump_db.sh .-> SNAP
  SNAP -. restore_db.sh .-> PG
```

There are three runnable apps (backend, web, mobile), one database, and a
set of scripts that write to that database from outside the apps. The backend
is the only thing that serves data to the apps. Writes come from three places:
the admin console (through the backend), the live-score sync (inside the
backend), and the ingestion scripts (Python and npm, run by a person).

## The database

PostgreSQL 16. The schema is `docs/schema/sokabrain_schema_ddl.sql`, and the
reasoning behind every table is in `docs/schema/sokabrain_vault_schema_v1.md`.
The tables fall into five groups:

| Group | Tables | What they hold |
|---|---|---|
| Football | `confederations`, `countries`, `stadiums`, `seasons`, `competitions`, `competition_editions`, `competition_groups`, `teams`, `competition_edition_teams`, `players`, `player_team_stints`, `coaches`, `coach_team_stints` | Who exists and who played where. A *competition* is "Tanzania Premier League"; an *edition* is one season of it, and is the unit that gets published. |
| Matches | `matches`, `match_events`, `match_lineups`, `match_team_stats`, `match_player_ratings` | Results and what happened in them. The score is stored on `matches`; events have to reproduce it. Lineups, stats and ratings are mostly empty and stay NULL rather than faked. |
| Provenance | `data_sources`, `entity_source_map`, `reconciliation_runs`, `reconciliation_diffs` | Which source every row came from, and every disagreement between sources waiting for a human. `entity_source_map` is also how the live sync finds the vault row for a provider's fixture, team or league. |
| Editorial | `admins`, `data_flags`, `audit_runs`, `audit_findings` | Admin accounts, open data problems (a BLOCKER flag stops an edition being published), and the data audit's results. |
| Fan zone | `kijiwe_spaces`, `kijiwe_threads`, `kijiwe_comments`, `kijiwe_likes` | Kijiweni's anonymous threads. |

Three things about the database matter to anyone writing code against it:

- **Every connection pins `timezone=UTC`.** The Prisma pg adapter drops the offset
  when it decodes a TIMESTAMPTZ, so on a non-UTC session every kickoff shifts.
  `backend/src/db.ts` passes `-c timezone=UTC` as a startup option; the Python
  loaders run `SET timezone = 'UTC'`.
- **The schema is owned by the DDL, not by Prisma.** `backend/prisma/schema.prisma`
  is generated with `prisma db pull` and never hand-edited. Changing the schema
  is a four-step process in `docs/RUNBOOK.md`.
- **The committed snapshot is the backup.** `scripts/dump_db.sh` writes the whole
  vault to `docs/migration/sokabrain_vault_snapshot.sql` with admin credentials
  scrubbed, and `scripts/restore_db.sh` rebuilds a database from it. This works
  while there is one copy of the vault on one machine. Deploying changes that;
  see "The source of truth moves" in `docs/DEPLOYMENT.md`.

## The backend (`backend/`)

Node 22, TypeScript (strict), Express 5, Prisma 7 with the `@prisma/adapter-pg`
driver. Entry point `src/index.ts`. It reads its configuration once at boot in
`src/env.ts` and exits if anything required is missing or malformed.

```
src/
├── index.ts        Express app: /health, three routers, error handler, starts the cron
├── env.ts          zod-validated environment
├── db.ts           the one Prisma client, pinned to UTC
├── routes/         HTTP layer: parse the request, call a service, shape the reply
├── services/       the logic: standings, stats, match detail, live sync, provider clients
├── auth/           scrypt password hashing, JWT sign/verify (jose), requireAdmin middleware
├── jobs/           liveScoreSync.ts, the node-cron job
├── scripts/        command-line tools run with `npm run …`
├── config/         target leagues, team-name aliases for provider matching
└── sockets/        empty; Socket.io goes here (priority 6)
```

### The three APIs

| Mount | Who calls it | Auth | What it does |
|---|---|---|---|
| `/api/vault` | Web pages, web client components, mobile | None | Read-only: editions, standings, top scorers, matches, match detail, schedule, team profiles, club and player stats, head-to-head. Only published editions are visible. |
| `/api/kijiweni` | Web (through its rewrite), mobile | None, anonymous | Spaces and threads to read; posting threads, comments and likes. Each write is rate-limited per client IP and site-wide (`routes/kijiweniLimits.ts`). |
| `/api/admin` | The web admin console's server code only | JWT bearer token, 12-hour lifetime | Login, all vault edits (teams, players, matches, events, seasons, transfers), publishing, data flags, the data audit, Kijiweni moderation, admin access. |

`/health` checks the database and answers 200 or 503, which suits a load
balancer or uptime monitor.

Routes stay thin. Anything that needs a real query lives in `services/`.
Prisma is the only way the backend touches the database, apart from the
aggregate queries (standings, stats), which are raw SQL in `services/` and
commented with what they compute.

### The live-score sync (`src/jobs/liveScoreSync.ts`, `src/services/liveSync.ts`)

When `SPORTMONKS_TOKEN` is set and `LIVE_SYNC_ENABLED` isn't `false`, the
backend schedules a job on `LIVE_SYNC_CRON` (every 2 minutes by default). Each
tick:

1. Lists the competition editions mapped to SportMonks in `entity_source_map`.
   With none mapped, it logs that and does nothing.
2. Asks SportMonks for every fixture in play right now. This is one request
   regardless of how many leagues the plan covers.
3. Drops fixtures from editions the vault doesn't track, normalises the rest,
   and resolves teams and the edition to vault ids through `entity_source_map`.
   Anything unmapped is skipped and logged, never guessed at.
4. Writes scores, status and, for unplayed fixtures only, kickoff times. **It
   never writes goal events.**
5. Only overwrites a value that SportMonks wrote itself. If the vault's value came
   from somewhere else (a loader, a human, the legacy data) and SportMonks
   disagrees, the sync writes a `reconciliation_diffs` row and leaves the vault
   alone.

An overlap guard skips a tick if the previous one is still running. The guard
is in memory, which is one reason the backend has to run as a single process
(see "Constraints" below).

API-Football is still wired in as a fallback provider, used only when there's
no SportMonks token. It has never been validated against live data.

### Command-line scripts (`src/scripts/`, run with `npm run`)

These run outside the server, against the same database and env file. Every
script that writes dry-runs by default.

| Script | What it does |
|---|---|
| `sm:sync` | One sync pass. Bare, it does what the cron does; with `--league <id>` it walks the league's whole current season, which picks up results missed while the backend was down. |
| `sm:events` | Loads goal events for a SportMonks league season. Resolves every scorer to a full name through the provider's player endpoint, writes an unresolvable scorer as unattributed, and refuses any match whose events don't reproduce its score or that already has events. `--apply` to write. |
| `sm:ingest` | Sets up a new season of a SportMonks league: clubs, fixtures, and the mapping rows the live sync needs. Warns about near-duplicate club names. |
| `sm:map`, `sm:compare`, `sm:coverage` | Link an existing vault edition to SportMonks, diff the two without writing, and check what the plan covers. |
| `editions:publish` | Publish or unpublish editions in bulk, subject to BLOCKER flags. |
| `admin:create` | Create an admin account, or reset its password. |
| `af:*`, `seed:sources` | API-Football equivalents and one-time setup. |

### Leagues and providers

| League | SportMonks id | Vault competition | Scores | Goal events |
|---|---|---|---|---|
| Tanzania Premier League | 884 | 1 | live sync, plus ligikuu | ligikuu, then FotMob. Never SportMonks (its names were wrong on 38 of 108 goals). |
| South Africa Premier League | 806 | 127 | live sync | `sm:events` |
| Rwanda National Soccer League | 872 | 126 | live sync | `sm:events` |
| Uganda Premier League | 1423 | 128 | live sync | `sm:events` |
| Kenya Premier League | 848 | 17 | live sync | none (the provider has none) |
| Africa Cup of Nations | — | 16 | historical, finished | historical, finished |

## The web app (`web/`)

Next.js 16 (App Router), React 19, Tailwind 4. Runs on port 3100 in
development.

```
app/
├── (site)/            public site: home, matches, table, stats, teams, competitions, kijiweni
├── admin/login/       sign-in page, outside the console shell
├── admin/(console)/   the console: matches, teams, players, seasons, competitions,
│                      transfers, flags, issues, audit, kijiweni, access, account
├── admin/actions.ts   server actions behind every console form
└── api/search/        the quick-search endpoint, cached for a minute in memory
lib/
├── api.ts             typed client for /api/vault (types written by hand)
├── adminApi.ts        typed client for /api/admin
├── session.ts         the admin token cookie
└── scope.ts           competition + season scoping shared by every public page
components/
├── ui.tsx             coverage notes, crests, empty states
└── admin/             console kit, confirm-form, shell, toaster
```

The web app talks to the backend in three ways:

1. **Server-rendered public pages** call the backend directly from the Next.js
   server, at `API_URL` (default `http://localhost:4010`).
2. **Client components** (live minute, Kijiweni posting, filters) call
   `/api/vault/*` and `/api/kijiweni/*` on the web app's own origin.
   `next.config.ts` rewrites those to the backend, so the browser never needs the
   backend's address and there is no CORS to configure.
3. **The admin console** never calls the backend from the browser. Logging in
   stores the JWT in an httpOnly `sokabrain_admin` cookie. Every console change
   goes through `components/admin/confirm-form.tsx` to a server action, which
   reads the cookie and calls `/api/admin` server-side. The token can't be read
   by page JavaScript.

`/api/admin` isn't in the rewrites, so it's never proxied through the public
site's origin.

Display rules live in the web and backend, not the database. Examples: a
competition is shown with its country in front (`services/competitionName.ts`),
an own goal is shown beside the team it counts for even though it's stored
under the scorer's team, a tournament is shown as groups plus a bracket, and a
stat the data can't support comes back as null, not 0.

## The mobile app (`mobile/`)

Flutter. It reads the same `/api/vault` and `/api/kijiweni` endpoints as the web
app and adds none of its own. Screens: matches by day, league hub (table and
stats), competitions, team profile, Kijiweni, and settings (favourites, theme,
Swahili or English). Favourites and the anonymous fan profile are stored on the
device.

The API base URL is `ApiService.baseUrl` in `lib/services/api_service.dart`,
which defaults to `http://localhost:4010`. The app calls the backend directly,
not through the web server, so in production the backend needs a public HTTPS
address.

## Ingestion (`docs/ingestion/`, `docs/reconciliation/`)

Python 3.13 loaders, one per source, run by hand. They brought the vault from
three seasons of one league to what it holds now. The pipeline shape is the same
for each source:

```
fetch (API or browser harvest)  ->  raw/ files
normalize_<source>.py           ->  canonical match records, one shape for all sources
teamnames.py                    ->  one canonical name per club, so sources join
load.py / update_*.py           ->  vault, with entity_source_map rows
```

Data fixes are dated SQL files in `docs/reconciliation/fixes/`, each applied once
in a transaction, with a header saying what was wrong, what evidence settled it,
and how to reverse it.

The loaders read `DATABASE_URL` and fall back to the local `sokabrain`
database.

## How data moves

**A fan opens a match page.** Browser → web server renders the page, fetching
`/api/vault/matches/:id` from the backend → backend reads `matches`,
`match_events` and players through Prisma → the page shows the stored score and
the event timeline.

**A match is being played.** Every 2 minutes the backend's cron asks SportMonks
what's in play, maps it to vault matches and updates score and status. Pages
show it on their next load. Nothing is pushed yet: Socket.io will add that.

**A match has finished.** The score is already there from the live sync (or from
an `sm:sync --league` catch-up). The goal events come later and separately: from
`sm:events` for South Africa, Rwanda and Uganda, and from the ligikuu loader for
Tanzania. Until then the match shows a result with an empty timeline.

**An editor fixes a record.** Console form → confirmation dialog → server action
→ `/api/admin/...` with the JWT → backend writes it with an `entity_source_map`
row marking it as a manual entry. Deletes that would cascade through history are
refused with 409.

**A new season starts.** Someone runs `sm:ingest` for the league (or the ligikuu
loader for Tanzania), checks the near-miss warnings, and publishes the edition
when it's ready. The live sync picks it up as soon as the mapping rows exist.

**A fan posts in Kijiweni.** Browser → web origin `/api/kijiweni/threads` →
rewrite → backend checks the per-client and site-wide limits → writes the
thread. Mobile posts go straight to the backend.

## Constraints that shape deployment

- **Run exactly one backend process.** The cron, its overlap guard and Kijiweni's
  rate-limit counters all live in memory. Two processes would sync twice per
  tick and give every client twice its posting budget. To scale out later, set
  `LIVE_SYNC_ENABLED=false` on all but one process and move the rate-limit
  counters to a shared store first.
- **The web app needs `API_URL` at build time as well as at run time.** Next.js
  bakes the rewrite destinations into the build.
- **`TRUST_PROXY` has to match the network.** Kijiweni's per-client limits key on
  the client's IP. Get this wrong and either every web fan shares one budget or
  anyone can fake a new address. `docs/RUNBOOK.md` ("Kijiweni rate limits")
  explains the safe setup.
- **The database connection must accept the `timezone` startup option.** Some
  connection poolers reject startup options. Use a direct connection, or set
  the database's default timezone to UTC as well.

## Testing and CI

`.github/workflows/ci.yml` runs on every pull request:

- Backend: `npm test` (node's test runner) against a Postgres 16 service
  restored from the snapshot.
- Web: `next typegen`, `tsc --noEmit`, `eslint`.
- Mobile: `flutter analyze` and `flutter test` against a running backend.
- Python: the doctests in the ingestion and reconciliation code.

## Not built yet

- **Socket.io push** (priority 6). `src/sockets/` is empty. The plan: attach
  Socket.io to the Express server, have the live sync broadcast every score or
  status change it writes, use rooms per match and per edition, and subscribe
  from the web and mobile match screens.
- **Scheduled data jobs.** Catching up results and loading goal events are manual
  (`docs/RUNBOOK.md`, "Weekly"). `docs/DEPLOYMENT.md` shows how to schedule them.
- **A deployment.** See `docs/DEPLOYMENT.md`.
