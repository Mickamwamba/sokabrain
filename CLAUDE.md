# Sokabrain — Project Context for Claude Code

## What this is

A digital vault for historical football/soccer data, starting with a wedge in
East African leagues (Tanzania, Kenya) that global apps (Sofascore, FotMob)
don't cover well, layered with mainstream leagues via a licensed API. The
long-term vision includes a paid tier and an AI Q&A layer — **neither is in
scope yet**. Current scope is the Vault + Live Scores MVP on web and mobile,
plus the Kijiweni fan zone, which was brought forward (see its status entry).

**Problem statement**: African football fans have deep daily conversations
about their local leagues but no platform gives those leagues the
statistical depth and "encyclopedia" treatment that global apps give the
EPL. This project's differentiation is *local-league depth*, not competing
with FotMob on mainstream-league richness (xG, tracking data, etc. are
explicitly out of scope — see "Non-goals" below).


**Where to look:** `README.md` to run it, `docs/ARCHITECTURE.md` for how the
parts fit, `docs/DEPLOYMENT.md` to deploy it, `docs/RUNBOOK.md` for recurring
jobs and how-tos, `docs/OPEN_DECISIONS.md` for data calls waiting on an
editor, and `docs/HISTORY.md` for the full log of why everything is the way it
is. History is long; search it, don't read it.

## Current state (2026-10-01)

Everything in "Immediate build priorities" through 5 is done, plus work that was
not in the original plan (admin console, data audit, mobile app, Kijiweni).

- **Vault**: Postgres 16, schema in `docs/schema/sokabrain_schema_ddl.sql`,
  rationale in `docs/schema/sokabrain_vault_schema_v1.md`. Restore the whole
  current vault with `./scripts/restore_db.sh`; refresh the snapshot with
  `./scripts/dump_db.sh` after any data change.
- **Data**: 6,984 matches and 10,080 goal events across 17 competitions. 61 of
  81 editions are published, covering six competitions: the Tanzania, Kenya,
  Rwanda, Uganda and South Africa top tiers, plus the Africa Cup of Nations
  (1957–2025). The 20 unpublished editions are legacy SokaFC competitions
  (domestic cups, continental club rounds, qualifiers, U17, First Division)
  that have never been reviewed for publication.
- **Backend** (`backend/`, port 4010): Express 5 + Prisma 7. Read API under
  `/api/vault`, admin API under `/api/admin` (JWT), fan zone under
  `/api/kijiweni`. Live-score sync from SportMonks on a cron.
- **Web** (`web/`, port 3100): Next.js 16 public site (Matches · Table ·
  Statistics, team pages, Kijiweni) and the admin console under `/admin`.
- **Mobile** (`mobile/`): Flutter app over the same read API.
- **CI**: `.github/workflows/ci.yml` runs the backend tests against a restored
  snapshot, the web typecheck and lint, Flutter analyze and test against a
  running backend, and the Python doctests.
- **Next up**: Socket.io push (priority 6). The two recurring data jobs in the
  runbook are not scheduled yet.

### Coverage, honestly

- **AFCON**: every goal names a scorer (2,007 of 2,007), and every match's event
  log reproduces its score.
- **Tanzania Premier League**: 19 seasons, 2008/09–2026/27. Scorer coverage
  varies by season, from 100% for recent seasons to near zero for 2011/12–2016/17,
  where no known source has scorers. `docs/HISTORY.md` holds the per-season
  ceiling and which sources were tried.
- **Other leagues**: South Africa and Tanzania's current seasons are fully
  named. Rwanda, Uganda and Kenya are partial, and the gap is the source's, not
  ours.
- **Lineups, cards and appearances are mostly absent** for every league, so the
  public site suppresses them (returns null) instead of showing zeros.

## Rules learned the hard way

Each one cost real time once. The full story is in `docs/HISTORY.md`.

**Database and time**
- **Every DB connection must pin `timezone=UTC`.** `@prisma/adapter-pg` drops the
  offset when decoding TIMESTAMPTZ, so on a non-UTC machine every kickoff shifts.
  `backend/src/db.ts` does it. Most Python loaders run `SET timezone = 'UTC'`;
  any new one that reads or compares a kickoff must too.
- **Postgres `LEAST`/`GREATEST` ignore NULL.** Wrap a possibly-null argument in a
  CASE first.
- **Extra time:** `home_score`/`away_score` hold 90 minutes, and
  `*_score_et` holds the running total after extra time. Compare event logs
  with the latter.

**Own goals** (principle 5 below has the storage and display rule)
- Sources disagree on which team an own goal is listed under. ligikuu (before
  2026), RSSSF, WhoScored before 2013, FotMob and SportMonks list it under the
  side it counts FOR and must be flipped to the scorer's own team. Flashscore
  also lists the counts-for side, so only the storage team flips. The Rwandan
  league site already uses our convention. **Establish a new source's
  convention against a known match before loading it.**
- Never attribute an own goal to a player of the side it counts for. Load it
  unattributed instead.

**Writing data**
- **Never overwrite** (principle 2). Loaders complete a log; they never replace
  one. A match that already has goal events is never added to. A disagreement
  becomes a `reconciliation_diffs` row.
- **Refuse a match whose event log does not reproduce its score.** A wrong goal
  log is worse than none. Load the score and no events.
- **Check for an AWARDED (forfeit) result before hunting for missing goals.** The
  vault has three, each carrying an INFO `data_flags` row.
- **Measure coverage against goals in the SCORES, not against the events that
  exist.** A goal with no event row is invisible to the second measure.
- **A loader refuses a whole season rather than writing part of one** when the
  source fails a shape check (round sizes, duplicate pairs, totals).
- The live sync writes scores, status and kickoffs, **never events**. A kickoff
  moves only for an unplayed fixture.
- After any ingestion, run `./scripts/dump_db.sh`.

**Identity: one person, one record**
- **Never store an abbreviated name** ("K. Nsanzimfura"). Resolve it to a full name
  or write the goal unattributed.
- **A surname alone never merges two players.** Merge only when a source names
  that specific goal, ideally proven by a published total that only the merged
  record reproduces. The audit's Identity checks raise candidates and never merge.
- **Check `docs/ingestion/teamnames.py` before adding a club.** A rename silently
  splits a club's history in two. Club matching is scoped to the club's country,
  because several countries have a club called "Police".
- Take a scorer's name from a source's player link, not its timeline text.

**Public site and API**
- `competition_editions.is_published` defaults to FALSE. Publishing goes through
  `services/flags.ts`, and an open BLOCKER flag blocks it.
- Every public page is scoped by competition AND season (`lib/scope.ts`).
  `editionId=all` means all time within the chosen competition.
- Competitions are displayed with the country in front
  (`services/competitionName.ts`). It is a display rule, not a stored name. The
  admin keeps both `name` and `displayName`; do not collapse them.
- A tournament is shown as groups plus a bracket, never one table. "Expected
  fixtures" is computed only for a LEAGUE.
- Stats the data cannot support come back null, not 0.
- **Next.js 16:** `params`/`searchParams` are Promises. Run `next typegen` after
  adding or moving routes, or `tsc` fails.
- **Admin console:** every change goes through
  `components/admin/confirm-form.tsx`. Deletes never cascade through history (the
  API answers 409). Admins are deactivated, never deleted.

**Scraping**
- Respect `robots.txt`. The Rwandan league's per-match data is under a disallowed
  path and needs their permission.
- In a browser harvest, verify the page you are reading is the match you think
  it is (URL fragment + title + score). On FotMob match pages, read the DOM, not
  `__NEXT_DATA__`, which may hold a different match.

**Open provenance gaps (known, deliberately not auto-fixed)**: 5,911
`match_events` rows have no `entity_source_map` row, and 6 player records are
initials plus a surname. See `docs/OPEN_DECISIONS.md`.

## Tech stack (do not deviate without discussion)

| Layer | Choice |
|---|---|
| Database | PostgreSQL |
| Backend | Node.js + TypeScript, Express (or Fastify) |
| ORM | Prisma — introspect the existing schema with `prisma db pull`, do not hand-write a schema that diverges from `sokabrain_schema_ddl.sql` |
| Auth | JWT-based, single `admins` table, hashed passwords. No third-party auth service yet. |
| Realtime | Socket.io on the Node server, broadcasting match/event updates |
| Web frontend | React (Next.js) |
| Mobile frontend | Flutter (`mobile/`) — built, consuming the same read API as the web |
| Live-score provider | SportMonks (API-Football kept as a fallback; see `backend/README.md`) |

## Repository structure

```
soka-brain/
├── CLAUDE.md                          # this file: rules and current state
├── README.md                          # what it is, how to run it
├── requirements.txt                   # Python deps for docs/ingestion + docs/reconciliation
├── .github/workflows/ci.yml           # CI: backend, web, mobile, Python doctests
├── scripts/
│   ├── restore_db.sh                  # recreate the vault DB from a dump
│   └── dump_db.sh                     # write that dump, credentials scrubbed
├── docs/
│   ├── RUNBOOK.md                     # recurring jobs and how-tos
│   ├── OPEN_DECISIONS.md              # data calls waiting on an editor
│   ├── HISTORY.md                     # the full working log
│   ├── ingestion/                     # Python loaders per source; raw/ holds harvests
│   ├── reconciliation/fixes/          # dated SQL fix files, each one applied once
│   ├── schema/
│   │   ├── sokabrain_vault_schema_v1.md
│   │   └── sokabrain_schema_ddl.sql
│   └── migration/
│       ├── migrate.py
│       ├── sokabrain_vault_migrated.sql   # legacy migration only (historical)
│       └── sokabrain_vault_snapshot.sql   # the whole current vault
├── backend/
│   ├── src/
│   │   ├── routes/                    # vault (read), admin* (write), kijiweni (fan zone)
│   │   ├── auth/                      # scrypt hashing, JWT sign/verify, middleware
│   │   ├── scripts/                   # npm run admin:create, sm:*, editions:publish
│   │   ├── services/
│   │   ├── sockets/                   # Socket.io — not built yet (priority 6)
│   │   ├── jobs/                      # node-cron live-score sync job
│   │   └── config/leagues.ts          # target leagues (API ids discovered, not hardcoded)
│   ├── prisma/
│   │   └── schema.prisma              # generated via `prisma db pull`
│   ├── prisma.config.ts               # Prisma 7 keeps DATABASE_URL here, not in schema.prisma
│   ├── .env.example
│   └── package.json
├── web/                                # Next.js 16 App Router app
│   ├── app/(site)/                     # public pages + their header/footer
│   ├── app/admin/(console)/            # admin console pages (sidebar shell)
│   ├── app/admin/login/                # sign-in, outside the console shell
│   ├── components/ui.tsx               # public: coverage notes, crests, empty states
│   ├── components/admin/               # console kit, confirm dialog, shell, toaster
│   └── lib/api.ts, lib/adminApi.ts     # hand-written types for the read and admin APIs
└── mobile/                             # Flutter app (lib/screens, lib/services, test/)
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
   **The DISPLAY rule is the opposite, and deliberately so.** A match timeline
   tracks the scoreline, so an own goal is shown beside the team it counts FOR,
   marked "(o.g.)" with the scorer named. `matchDetail` sends
   `countsForOtherSide` for exactly this; the timeline read `side` directly for
   a while and put the goal on the scorer's own side, which made a 1-1 read as
   though one team had scored twice. Storage answers "whose player was it",
   display answers "whose goal was it" — do not collapse the two.
6. **Optional richness stays optional.** `match_team_stats` and
   `match_player_ratings` should be NULL, not fabricated, when the
   underlying league doesn't have that data (true for most niche leagues).
   Never backfill fake stats to make niche-league rows look complete.

## Non-goals (explicitly out of scope right now)

- xG, shot-coordinate data, heatmaps, tactical/formation tracking — real
  tracking-data infrastructure, not worth building until there's a funded
  mainstream-league push.
- AI Q&A layer — needs a stable schema and real data volume first.
- Fan accounts, private messaging or anything beyond Kijiweni's anonymous
  threads — Kijiweni was brought forward, but a full community platform was not.
- Paid tier / billing — after there's something worth paying for.

## Immediate build priorities, in order

1. Stand up Postgres (Neon/Railway free tier is fine), restore
   `docs/migration/sokabrain_vault_snapshot.sql` into it.
2. Scaffold `backend/`: Express + Prisma pointed at that database. First
   three endpoints: league standings, top scorers, match list — these
   alone prove the schema supports the product.
3. Add JWT admin auth + write endpoints for manual vault edits.
4. Scaffold `web/`: Next.js app consuming those read endpoints. Vault
   browsing pages first — this is demoable before any live-score work.
5. Build the live-score sync job (`backend/src/jobs/`) against
   API-Football for the initial league set, tagged
   `data_source = 'api_football'` per the provenance rule above.
6. Wire Socket.io so live match updates push to the web **and mobile**
   clients without polling. **This is next.**
7. ~~Flutter app~~ — built ahead of order; see the status entry.

## Environment variables

`backend/.env.example` is the annotated list. The ones that matter:

```
DATABASE_URL=        # also read by the Python scripts in docs/ingestion
JWT_SECRET=          # openssl rand -hex 32
SPORTMONKS_TOKEN=    # live-score provider; without it, sync is off
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
