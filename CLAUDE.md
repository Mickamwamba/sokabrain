# Sokabrain — Project Context for Claude Code

## What this is

A digital vault for historical football/soccer data, starting with a wedge in
East African leagues (Tanzania, Kenya) that global apps (Sofascore, FotMob)
don't cover well, layered with mainstream leagues via a licensed API. The
long-term vision includes a paid tier, an AI Q&A layer, and a fan forum —
**none of that is in scope yet**. Current scope is: get the Vault + Live
Scores MVP working end to end, web first.

**Problem statement**: African football fans have deep daily conversations
about their local leagues but no platform gives those leagues the
statistical depth and "encyclopedia" treatment that global apps give the
EPL. This project's differentiation is *local-league depth*, not competing
with FotMob on mainstream-league richness (xG, tracking data, etc. are
explicitly out of scope — see "Non-goals" below).

## Current status (read this first)

- The legacy dataset (a real production app called SokaFC, MySQL dump from
  2020) has already been **audited and migrated** into a new standardized
  Postgres schema. See `docs/schema/sokabrain_vault_schema_v1.md` for full
  rationale and `docs/schema/sokabrain_schema_ddl.sql` for the tested DDL.
- The migrated data lives in `docs/migration/sokabrain_vault_migrated.sql`
  (a pg_dump — restore this into a fresh Postgres instance to get real data
  immediately instead of building against an empty schema).
- The migration script (`docs/migration/migrate.py`) is rerunnable if a
  fresher legacy dump ever needs re-migrating.
- **Build priority 1 is done.** The dump is restored into a local Postgres 16
  database `sokabrain` (Postgres.app, 127.0.0.1:5432). Connection string:
  `postgresql://<user>@127.0.0.1:5432/sokabrain`. Re-create it any time with
  `./scripts/restore_db.sh` (`FORCE=1` to replace, `TARGET_URL=...` to restore
  to Neon/Railway instead). Verified after restore: schema is identical to
  `sokabrain_schema_ddl.sql`, 100% `entity_source_map` provenance coverage, and
  stored scores agree with the corrected own-goal rule.
- **Build priority 2 is done.** `backend/` runs Express 5 + Prisma 7 (schema
  introspected via `prisma db pull`, never hand-written) on port 4010 — 4000 is
  taken by an unrelated local project. Endpoints live under `/api/vault`:
  editions index, standings, top scorers, match list. See `backend/README.md`.
  Next up is priority 3 (JWT admin auth + write endpoints).

  Two data realities the endpoints had to handle, worth knowing before building
  on them: `competition_edition_teams` is empty for every migrated edition (so
  participating teams are derived from `matches`), and the legacy event log is
  partial — 61 of edition 6's 380 matches have no score, ~27% of goal events
  have no `player_id`. Standings and top scorers each return a `coverage` block
  reporting this rather than presenting thin data as complete.
- **Build priority 3 is done.** JWT admin auth (`jose`, 12h tokens) + write
  endpoints under `/api/admin`: login, me, password change, and create/update
  for teams, players, matches and match events. Passwords are scrypt-hashed via
  `node:crypto`. Accounts are provisioned with `npm run admin:create` — there is
  no self-signup endpoint. Next up is priority 4 (Next.js web app).

  This added the **first new table since the migration**: `admins`. It is NOT a
  revival of the legacy `administrators` table (still deliberately unmigrated).
  `docs/schema/sokabrain_schema_ddl.sql` and the schema rationale doc were both
  updated in step, and the DDL round-trips against the live database.

  A `manual_admin` row was added to `data_sources`, and every admin write
  records its `entity_source_map` provenance in the same transaction as the
  write (principle 1). Caveat worth knowing: that records which *source* touched
  a row, not which *admin* — per-admin attribution needs an audit table the
  schema does not have.
- **Build priority 4 is done.** `web/` is a Next.js 16 App Router app (React 19,
  Tailwind 4) consuming the read API: competitions index, edition page with
  table + top scorers, and a filterable match list. Runs on port 3100 (`npm run
  dev` in `web/`); needs the backend up. See `web/README.md`. Next up is
  priority 5 (API-Football live-score sync job).

  Next.js 16 notes that bit during the build: `params`/`searchParams` are now
  Promises and must be awaited, and pages are typed with the global
  `PageProps<'/route/[param]'>` helper that only exists after route typegen — a
  fresh clone will not typecheck until `next typegen` (or dev/build) has run.
  `create-next-app` also initialises a nested git repo and writes an
  `AGENTS.md`; the nested `web/.git` was removed since the project root is not
  itself a repo yet.
- **Build priority 5 is done, but NOT yet validated against the live API** —
  there is no `API_FOOTBALL_KEY` yet. The sync job, client, entity mapping,
  coverage checker and reconciliation logic are written and covered by
  `npm test` (7 integration tests against the real schema, synthetic fixtures).
  Everything else works without a key; the scheduler warns and no-ops.

  **Before paying for API-Football, run `npm run af:coverage`** — whether it
  covers the Tanzanian and Kenyan leagues at all is still an open question, and
  answering it is the stated reason for starting on the free tier.

  Two things to know: (a) nothing syncs until `npm run af:map` links vault teams
  and editions to API ids — the migrated vault knows nothing about the provider;
  (b) the sync reads the API's published score and never reconstructs it from
  events, so own-goal attribution can't go wrong on that path.
  `verifyEventsAgainstScore()` tests that assumption but is deliberately NOT
  wired in — **run it against real fixtures before building event ingestion**.

  Next up is priority 6 (Socket.io push).
- **Admin dashboard is done** (unplanned work, requested after priority 5). Web
  routes under `/admin`: sign in, competitions with publish toggles, match
  editor with event management, and a flags queue. Session is a JWT in an
  httpOnly cookie; all admin calls are server-side, so the token never reaches
  page JavaScript.

  **This changed a public default: `competition_editions.is_published` defaults
  to FALSE, so the public API and web app now show only published editions.**
  Right now only edition 6 (TPL 2018/19) is published — everything else is
  hidden until someone reviews it in the dashboard.

  A BLOCKER flag prevents its edition from being published; a flag on a match
  blocks that match's edition. WARNING/INFO are advisory. The dashboard derives
  a worklist from the data (missing scores, absent event logs, unattributed
  goals) so editors start from real problems rather than a blank page.
- **Public site redesigned as a fan-facing stats platform.** New IA modelled on
  a stats hub: dashboard (`/`), Players, Clubs, Head to head, Competitions,
  Matches. Backend gained `/api/vault/stats/*` (overview, clubs, players,
  head-to-head) plus `/api/vault/teams`, all scoped to published editions.

  **Light theme only — no dark mode, by request.** One fixed palette in
  `globals.css`, Archivo for display + Inter for body. No `dark:` variants
  remain anywhere, admin included.

  Eleven editions are now published (was one) so the cross-season views have
  real depth: 1,179 matches, 2,909 goals, 115 clubs, 3 seasons. Publication is
  still per-edition in the dashboard.

  Stats deliberately absent because the vault has no data for them: attendance,
  stadium capacity, possession, xG, shots. Goals-per-appearance is suppressed
  unless a player has at least as many recorded appearances as goals — lineups
  cover ~600 of 1,639 players, so the raw ratio measured missing data, not form
  (it read "4.6 goals per game" for the top scorer before the fix).
- **Public scope is Tanzania Premier League only.** Its three original seasons
  (2017/18, 2018/19, 2019/20) are published; everything else is hidden.
- **The full league history is now in the vault: 19 seasons, 2008/09 to
  2026/27, 4,380 matches.** Ingested 2026-09-08 from two new sources — see
  `docs/ingestion/README.md` for the pipeline and the judgement calls.
  - `ligikuu.co.tz` (official) runs SportsPress, whose **REST API is open** at
    `/wp-json/sportspress/v2/`. It has goalscorers with minutes, and covers
    2020/21 onward (a season earlier than expected).
  - `whoscored.com` covers 2008/09–2026/27 but **skips 2017/18**, and has
    fixtures and scores only, no scorers. It needs a real browser: Cloudflare
    403s plain HTTP. The fixture feed is `/tournaments/{stageId}/data/?d=YYYYMM`.
  - **Zero score conflicts in 1,742 cross-checked matches** (both sources vs the
    vault, and against each other). That is what justified accepting WhoScored
    alone for 2008/09–2016/17, where there is no second source.
  - **The 16 new editions are all unpublished.** Nothing reaches the public site
    until someone publishes it in the dashboard.
  - Early seasons have no event log because neither source has one — not
    because anything was dropped.
- **The public site suppresses stats it cannot support, rather than showing 0.**
  `appearances`, `yellowCards` and `redCards` come back as **null** whenever
  team-sheet coverage for the scope is under 50% — which is everywhere, at 80 of
  4,169 matches. Goal totals are kept but labelled a minimum: only 36% of goals
  across all seasons have a named scorer (96% within 2023/24). The players page
  also drops the sort options that would rank on suppressed numbers. Details in
  the schema doc's "what the public site is allowed to state" addendum.
- **A league table now knows the difference between a missing score and a
  missing fixture.** Standings coverage carries `isProvisional`; TPL 2020/21
  trips it (43 fixtures absent from every source, clubs on 10 to 36 games) and
  is shown as "Table (incomplete season)" with no champion named. A season
  merely in progress does not trip it.
- **Assists are ingested** — 1,078 across 547 matches, **2023/24 onward only**,
  which is six seasons later than scorers begin. This added `ASSIST` to the
  `match_events.type` constraint (the first change to it since the migration;
  the DDL was updated in step). `related_player_id` is NOT used for these:
  the source gives a bare per-match count with no link to a goal, so filling it
  would be guesswork. Both shapes stay valid and `playerStats` unions them.
- **Two clubs were merged, being renames**: `JKT Ruvu Stars` → `JKT Tanzania`,
  `Singida United` → `Singida Black Stars`. Their former names live in
  `docs/ingestion/teamnames.py`; check it before adding a club, or a rename will
  silently split a club's history in two again.
- **Admin restructured around competitions.** Left sidebar nav; a searchable
  competitions list with "add competition"; and a competition page where you
  pick a season and get its completeness stats, detected issues, publish
  toggle and full match list. New endpoints: `GET/POST /api/admin/competitions`,
  `GET /api/admin/competitions/:id`, `GET /api/admin/editions/:id/summary`,
  `GET /api/admin/reference`.
- Known, already-fixed data issues (do not "fix" these again): an own-goal
  attribution bug, a Kenya Premier League country miscoding, a handful of
  duplicate lineup rows, kickoff times stored three hours late (legacy local
  time written as UTC), and 86 wrong kickoff dates — 82 of them in 2019/20,
  where the COVID-restart fixtures had been left on their legacy dates, inside
  the suspension. Full detail is in the schema doc's audit section.
- `competition_edition_teams` **is now populated for every Premier League
  edition**, including the three migrated ones (backfilled from their
  fixtures). The old note that it is always empty no longer holds.
- **The legacy source is exhausted for goalscorers.** Four earlier SokaFC
  snapshots (Jul-Dec 2018) were diffed against the migrated one: no match,
  lineup or event was ever lost, and **not one event ever lost its scorer**.
  The unattributed goals were entered without a scorer and always were. Filling
  them needs a source outside SokaFC, and none has been found. Re-run the check
  with `docs/reconciliation/compare_legacy_snapshots.py` rather than redoing it
  by hand.

## Tech stack (do not deviate without discussion)

| Layer | Choice |
|---|---|
| Database | PostgreSQL |
| Backend | Node.js + TypeScript, Express (or Fastify) |
| ORM | Prisma — introspect the existing schema with `prisma db pull`, do not hand-write a schema that diverges from `sokabrain_schema_ddl.sql` |
| Auth | JWT-based, single `admins` table, hashed passwords. No third-party auth service yet. |
| Realtime | Socket.io on the Node server, broadcasting match/event updates |
| Web frontend | React (Next.js) |
| Mobile frontend | Flutter — **Phase 2, not now**. Web ships first. |
| Live-score provider | API-Football (start on free tier to validate league coverage before paying) |

## Repository structure

```
soka-brain/
├── CLAUDE.md                          # this file
├── scripts/
│   └── restore_db.sh                  # recreate the vault DB from the dump
├── docs/
│   ├── schema/
│   │   ├── sokabrain_vault_schema_v1.md
│   │   └── sokabrain_schema_ddl.sql
│   └── migration/
│       ├── migrate.py
│       └── sokabrain_vault_migrated.sql
├── backend/
│   ├── src/
│   │   ├── routes/                    # vault (read), admin (write), live (sync)
│   │   ├── auth/                      # scrypt hashing, JWT sign/verify, middleware
│   │   ├── scripts/                   # createAdmin.ts (account provisioning)
│   │   ├── services/
│   │   ├── sockets/                   # Socket.io setup + event emitters
│   │   ├── jobs/                      # node-cron live-score sync job
│   │   └── config/leagues.ts          # target leagues (API ids discovered, not hardcoded)
│   ├── prisma/
│   │   └── schema.prisma              # generated via `prisma db pull`
│   ├── prisma.config.ts               # Prisma 7 keeps DATABASE_URL here, not in schema.prisma
│   ├── .env.example
│   └── package.json
├── web/                                # Next.js 16 App Router app
│   ├── app/                            # /, /editions/[id], /matches
│   ├── components/ui.tsx               # coverage notes, crests, empty states
│   └── lib/api.ts                      # hand-written types for the read API
└── mobile/                             # Flutter app — placeholder until Phase 2
```

## Critical design principles (non-negotiable)

1. **Provenance is mandatory, not optional.** Every row that comes from an
   external source (legacy migration, API-Football sync, manual admin
   entry) must have a corresponding `entity_source_map` row. Never write
   ingestion code that skips this — it's what makes future reconciliation
   between sources possible.
2. **Never silently overwrite canonical data with a new source.** If
   API-Football and the existing vault disagree on a fact (e.g. a score, a
   date), that's a `reconciliation_diffs` row, not an automatic overwrite.
   Auto-resolve only when sources agree.
3. **Score is a stored field on `matches`, not purely derived.** Compute it
   from events when migrating/ingesting, but the app should never need to
   aggregate the full event log just to show a score.
4. **Country/competition-agnostic schema.** Don't write code (or add
   columns) that assumes Tanzania or any single country — the whole point
   of this schema is that Uganda, Nigeria, or the EPL slot in identically.
5. **Own-goal attribution**: when computing scores from event data, an
   OWN_GOAL event's `team_id` is the *scoring player's own team*, not who
   the goal counts for. Always credit the opposing team. This bit the
   legacy migration once already — don't reintroduce it in new ingestion
   code (e.g. the API-Football sync job).
6. **Optional richness stays optional.** `match_team_stats` and
   `match_player_ratings` should be NULL, not fabricated, when the
   underlying league doesn't have that data (true for most niche leagues).
   Never backfill fake stats to make niche-league rows look complete.

## Non-goals (explicitly out of scope right now)

- xG, shot-coordinate data, heatmaps, tactical/formation tracking — real
  tracking-data infrastructure, not worth building until there's a funded
  mainstream-league push.
- AI Q&A layer — needs a stable schema and real data volume first.
- Native forum / Fan Zone — start as external Discord/Telegram groups per
  league before building anything custom.
- Flutter mobile app — after the web MVP is validated, not concurrently.
- Paid tier / billing — after there's something worth paying for.

## Immediate build priorities, in order

1. Stand up Postgres (Neon/Railway free tier is fine), restore
   `docs/migration/sokabrain_vault_migrated.sql` into it.
2. Scaffold `backend/`: Express + Prisma pointed at that database. First
   three endpoints: league standings, top scorers, match list — these
   alone prove the schema supports the product.
3. Add JWT admin auth + write endpoints for manual vault edits.
4. Scaffold `web/`: Next.js app consuming those read endpoints. Vault
   browsing pages first — this is demoable before any live-score work.
5. Build the live-score sync job (`backend/src/jobs/`) against
   API-Football for the initial league set, tagged
   `data_source = 'api_football'` per the provenance rule above.
6. Wire Socket.io so live match updates push to the web client without
   polling.
7. Flutter app — not before the above is working and validated.

## Environment variables backend/.env will need

```
DATABASE_URL=
JWT_SECRET=
API_FOOTBALL_KEY=
```

## Conventions

- TypeScript strict mode on for the backend.
- Prisma is the only way the backend touches the database — no raw SQL
  scattered through route handlers except for genuinely complex aggregate
  queries (e.g. standings), which should live in `services/` and be
  commented with what they compute.
- Keep `docs/schema/sokabrain_vault_schema_v1.md` as the source of truth
  for schema rationale — if the schema changes, update that doc in the
  same commit, don't let it drift.
