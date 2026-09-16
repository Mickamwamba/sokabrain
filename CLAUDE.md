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
- **To get a working database, restore
  `docs/migration/sokabrain_vault_snapshot.sql`** — a pg_dump of the whole
  current vault, which is what `./scripts/restore_db.sh` uses by default.
  Refresh it with `./scripts/dump_db.sh` after any ingestion, or a rebuild
  silently rolls the vault back. Admin credentials are scrubbed on the way out,
  so provision an account with `npm run admin:create` after restoring.
- `docs/migration/sokabrain_vault_migrated.sql` is the *original* legacy
  migration alone (`migrate.py`'s output, Sep 2026) and predates every
  ingestion since. It is a historical artifact, not a baseline to develop
  against — `SOURCE=migration ./scripts/restore_db.sh` if you ever want it.
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
- **Season is picked from one dropdown, top right, on every page.** Nineteen
  seasons as chips filled three lines and pushed the content below the fold.
  `components/season-select.tsx` is the single control; `lib/season.ts`
  resolves the `editionId` param — **absent means the season in play**, and
  `editionId=all` is an explicit all-time value. Statistics pages offer All
  time and show `<AllTimeBadge/>` when it is active; Matches and Table do not,
  because a fixture list and a table are per-season by nature. Head to head is
  all-time only, badged, since two clubs meet twice a season.
- **The public site is organised around three things, not six.** Nav is
  **Matches · Table · Statistics**. `/` is the fixture hub (season picker, date
  strip, round browsing, next-match card); `/matches/[id]` is a full match page
  with its event timeline, head-to-head and form; `/table` is the league table
  with a season picker; `/stats` holds Overview / Players / Clubs / Head to head
  as tabs. Date is the primary axis everywhere because kickoff dates are
  complete; round browsing appears only where real rounds exist (2,577 of 4,380
  matches, from RSSSF).
- **Fixed: every kickoff the API served was shifted by the server's UTC offset.**
  `@prisma/adapter-pg` decodes a TIMESTAMPTZ by taking the wall-clock Postgres
  renders and dropping the offset, so on a machine in America/Chicago a 13:00Z
  kickoff came back as a Date at 08:00Z. `backend/src/db.ts` now pins the
  session with `options: '-c timezone=UTC'`. **Any new DB connection must do the
  same** — a late kickoff otherwise lands on the wrong day.
- **The public site covers two competitions and is competition-aware.** All 19
  Tanzania Premier League editions and all 13 Africa Cup of Nations editions
  are published (2026-09-12). Revert the AFCON half with
  `UPDATE competition_editions SET is_published = FALSE WHERE competition_id = 16;`
  - **A tournament is shown as its groups and its bracket, never as one table.**
    `/editions/:id/standings` returns `groups[]` and `knockout[]` alongside the
    combined `standings`; `/table` renders those and hides the combined ranking,
    which for a cup sums group and knockout results into a meaningless order.
    Both are empty for a LEAGUE — and must stay that way, because league rounds
    are numbered and carry no `group_id`, so an ungated knockout query reads a
    whole league season as knockout ties.
  - **Matches are laid out by stage for a tournament**, by date otherwise. A
    selected tournament loads whole and in playing order rather than paged.
  - **Clubs and nations are ranked separately** — `/stats/clubs` and
    `/stats/nations`, both `teams.type`-filtered via `?type=`. They are not
    comparable: a club plays a 30-match league season, a nation three group
    matches every other year.
  - **Every public page is scoped by competition AND season, together.** The
    URL carries `competitionId` and `editionId`; the header has two dropdowns.
    `lib/scope.ts` (`resolveScope`) is the single resolver and
    `components/scope-select.tsx` the single control — `lib/season.ts` and
    `season-select.tsx` are gone. Picking a competition clears the season, so a
    page never keeps a season belonging to the competition just left. A bare
    `?editionId=` still works: an edition implies its competition.
  - **`editionId=all` means all time WITHIN the chosen competition**, not across
    all of them. Every stats query is scoped through one SQL fragment,
    `publishedEditionsIn(competitionId)` in `services/stats.ts`, so the whole
    stats layer is competition-aware in one place. Kagere's 42 league goals and
    Eto'o's 13 at AFCON never share a leaderboard.
  - The Clubs and Nations pages only offer competitions their kind of team
    plays in, so the picker cannot select a combination that is empty. The
    competition dropdown hides itself when only one competition qualifies.
- **A league table's "expected fixtures" is only computed for a LEAGUE.**
  `standings.ts` derives it as n*(n-1), which is meaningless for a cup: AFCON
  2019 holds all 52 of its fixtures but 24 teams imply 552, and the page
  claimed 500 were missing from every source. It is NULL for a non-league, so
  `isProvisional` cannot fire on that basis. TPL 2020/21 still reports its 43
  genuinely absent fixtures.
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
- **Every team has a page: `/teams/[id]`**, backed by `GET /api/vault/teams/:id`
  (`services/teamProfile.ts`). All-time across published competitions, broken
  down per competition and per season; team names link to it site-wide.
  - **Titles are only counted where they can be stated.** A league title needs a
    finished season that is not provisional — the same test as `/table`'s
    `isProvisional` (duplicated in SQL; keep the two in step) — so neither the
    season in play nor TPL 2020/21 names a champion. A tournament title comes
    from the final's result: penalties, then extra time, then 90 minutes.
    Verified against all 13 AFCON winners and every TPL champion `/table` names.
  - **Postgres `LEAST`/`GREATEST` ignore NULL.** `LEAST(NULL, 3)` is 3, which
    once made Azam's scorer coverage read 99% instead of 34%. Wrap a
    possibly-null argument in a CASE before using either.
  - 12 fixtures from 2021 (TPL 2020/21) are still `SCHEDULED` five years on.
    Not fixed — a data call for an editor.
- **The admin is a full console, with CRUD for everything and a confirmation
  dialog on every change** (2026-09-12). Grouped left sidebar with icons
  (`lucide-react`); pages for competitions, seasons, participants, matches,
  teams, players, issues, flags, access management and your own account.
  Backend: `routes/adminManage.ts`; web: `app/admin/(console)/` and
  `components/admin/`. Details in both READMEs.
  - **`components/admin/confirm-form.tsx` is the only way the console submits
    a change.** Build anything new on it. It reads `data-label` fields back into
    the dialog (old → new for an edit), blocks Enter from bypassing it, and keeps
    typed input when a save is rejected.
  - **Deletes never cascade through history**: the API answers 409 naming what
    depends on the row. **Admins are deactivated, never deleted** (FKs from
    `published_by` and `data_flags`); you can't deactivate yourself or the last
    active admin. **There are no roles** — any active admin manages access.
  - **Player careers and transfers are managed in the console.** Register a
    player at a club (with join date) or as a free agent; record a transfer,
    loan or release, which ends the right spells itself; edit past spells; see
    each team's current squad. Rules in `services/careers.ts` (unit tested):
    touching spells don't overlap (the legacy convention), national-team spells
    are never ended by a transfer, and a loan can't outlive its parent spell.
    **The existing spells are not clean** — 46 club spells were left open after
    the player moved on and 69 club pairs overlap (53 players). They are flagged
    on each player's page with a one-click fix, never auto-corrected.
    Manual spells record provenance as `player_team_stint`, a new entity type.
  - **The transfer centre (`/admin/transfers`) lists every move and manages
    them** — edit (a date change moves both touching spells), undo (reopens the
    old spell only when nothing later depends on it), and record a move for any
    player. Moves are not stored: `movesOf` in `services/careers.ts` reads
    them off the spells, so the centre and each player's page share one rule.
    Of the vault's moves, 351 are transfers and 835 are departures with no
    recorded destination; there are no loans on record yet.
  - **Data audit (`/admin/audit`) replaced the Issues page.** 23 checks
    (`services/audit/checks.ts`) over scores, events, fixtures, seasons and
    careers, run on demand over the vault or a union of competitions and
    seasons; a full run takes well under a second. Findings persist in the new
    `audit_runs`/`audit_findings` tables and reconcile on every run
    (`services/audit/reconcile.ts`, unit tested): undetected → RESOLVED by the
    run; FIXED but still detected → reopened; ACCEPTED stays closed until its
    fingerprint (the facts, never "N days ago") changes. Findings are advisory;
    escalate one to a BLOCKER flag to gate publishing. A first full run found
    680 problems, including club-credited goals in legacy AFCON 2019.
    **Extra-time matches store 90 minutes in `*_score` and the after-ET running
    total in `*_score_et`** — compare event logs with the latter.
    `npm test` now quotes its glob; before, nested test folders silently never ran.
    Each finding's **Fix** button deep-links to the section that fixes it
    (`web/lib/audit-targets.ts`), and those pages list the record's open
    findings with a way back to the filtered audit. The match result form now
    edits the kickoff too, in Tanzanian time (UTC+3).
  - **The public site and the console no longer share a layout.** Public pages
    live in `app/(site)/` (header/footer there); the root layout is only the
    document. URLs are unchanged. Run `next typegen` after moving routes, or
    `tsc` fails on stale `.next/types`.
- **ligikuu own goals were filed under the wrong team until early 2026, now
  corrected** (2026-09-12, `docs/reconciliation/fixes/2026-09-12_ligikuu_own_goal_sides.sql`,
  reconciliation run 67). The official site listed an own-goal scorer in the
  team the goal *counts for* until January 2026, and under the scorer's own team
  from April 2026 (and in two late-2024 matches); the loader assumed the latter
  throughout. 20 own goals (TPL 2023/24-2025/26) were moved to the scorer's own
  team, and 20 one-day player spells the mistake had created at the benefiting
  club were deleted. `normalize_ligikuu.py` now decides each match on its score
  (`orient_own_goals`, doctested). The Data Audit caught it — TRA United 3-0
  KMC FC read "Events read 2-1" — and run #2 then resolved all 19 contradictions
  on its own. **The counting rule (principle 5) was never wrong; the data was.**
- Known, already-fixed data issues (do not "fix" these again): an own-goal
  attribution bug, a Kenya Premier League country miscoding, a handful of
  duplicate lineup rows, kickoff times stored three hours late (legacy local
  time written as UTC), and 86 wrong kickoff dates — 82 of them in 2019/20,
  where the COVID-restart fixtures had been left on their legacy dates, inside
  the suspension. Full detail is in the schema doc's audit section.
- `competition_edition_teams` **is now populated for every Premier League
  edition**, including the three migrated ones (backfilled from their
  fixtures). The old note that it is always empty no longer holds.
- **The Africa Cup of Nations is in the vault: 13 tournaments, 2002-2025,
  496 matches, 1,121 goals.** Ingested 2026-09-12 from whoscored.com — see
  `docs/ingestion/AFCON.md` for the pipeline and the judgement calls. This is
  the first national-team competition in the vault; no schema change was needed
  (`CONTINENTAL_NATIONAL`, `teams.type='NATIONAL'`, `competition_groups`,
  `matches.round` and the ET/pens columns were all already there).
  - **98.2% of goals name a scorer** — far better than the TPL's 36%. Group,
    round of 16, quarter final, semi final, third place and final are each
    labelled, and every match is in its group.
  - **The 12 new editions are all unpublished**, as is the pre-existing 2019.
  - **WhoScored files own goals under opposite teams either side of 2013.** The
    modern pages use the scoring player's own team (our convention); the older
    ones use the team the goal counts for. `normalize_afcon.py` flips the older
    ones — do not "simplify" that away.
  - Two more source traps, both handled: `homeScore` already includes extra
    time, and `etScore` is *not* the after-extra-time score (it zeroes the
    loser, so Tunisia 1-2 Equatorial Guinea reads `0 : 2`).
  - Substitutions were deliberately not loaded, though 2,666 are in the raw
    harvest at `docs/ingestion/raw/afcon/events.json`.
- **The Africa Cup of Nations now runs 1957-2025: 35 editions, 850 matches.**
  The 22 tournaments before 2002 were loaded 2026-09-15 from RSSSF — see
  `docs/ingestion/AFCON_PRE2002.md` for the pipeline, the checks and the
  judgement calls. **All 22 are unpublished.**
  - RSSSF, not Flashscore: it carries dates, scorers with minutes, attendances
    and the final group tables as plain text, and every printed group table
    recomputes exactly from the parsed fixtures. Wikipedia independently
    confirms 1974, 1988, 1996 and 2000.
  - **Scorers were loaded only where they add up to the score** (264 of 352
    played matches, 735 goals). The rest are results only: 31 goalless draws
    and 57 matches RSSSF gives no scorers for, nearly all in 1996 and 1998.
  - **RSSSF lists an own goal under the side it counts FOR**, so the loader
    flips it to the scorer's own team (principle 5) — the same trap as ligikuu.
  - Extra time (28 matches): RSSSF gives only the after-extra-time score, so it
    is stored in both the score and the `*_score_et` columns; the 90 minutes
    are unknown. Two matches were never played (1957 apartheid disqualification,
    1978 walk-off) and are CANCELLED with no score. 1959 and 1976 were decided
    by a final round-robin, loaded as a group named "Final".
  - **A surname alone never merges two players**: "Touré" in 1992 and in 2006
    is as likely two careers as one.
- **AFCON 2019 (edition 14) had three score defects; all are now fixed.**
  Reconciliation run 38 recorded 24 diffs across 19 matches and they were
  applied via `docs/reconciliation/fixes/2026-09-12_afcon_2019_corrections.sql`
  (all diffs now `ACCEPT_B`). Do not "re-fix" these: 10 group matches had an
  inflated away score (Ghana v Benin stored 2-6, actually 2-2), 4 knockout ties
  credited the shootout winner an extra goal as a phantom `PENALTY_GOAL` in
  minute 120 with no player (deleted; the shootout now lives in `*_score_pens`),
  and 5 matches left NULL were 0-0 — the same lost-goalless-draw bug as TPL
  2017/18. The evidence was internal: for 16 of them the stored score
  disagreed with the edition's *own* `match_events`.
  The same change gave edition 14 its six groups, its 24 participants, and
  `ROUND OF 16`/`THIRD PLACE` split out of the old catch-all `KNOCKOUT` label,
  so all 13 AFCON editions now have the same shape.
- **Across all 13 AFCON tournaments, 491 of 493 played matches have a score
  reproduced exactly by their own event log.** The 2 exceptions are a missing
  *event*, not a wrong score: Zambia 1-1 Tanzania (2023) and Tunisia 1-1 Angola
  (2019) are each one goal event short in their source.
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
│   ├── restore_db.sh                  # recreate the vault DB from a dump
│   └── dump_db.sh                     # write that dump, credentials scrubbed
├── docs/
│   ├── schema/
│   │   ├── sokabrain_vault_schema_v1.md
│   │   └── sokabrain_schema_ddl.sql
│   └── migration/
│       ├── migrate.py
│       ├── sokabrain_vault_migrated.sql   # legacy migration only (historical)
│       └── sokabrain_vault_snapshot.sql   # the whole current vault
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
│   ├── app/(site)/                     # public pages + their header/footer
│   ├── app/admin/(console)/            # admin console pages (sidebar shell)
│   ├── app/admin/login/                # sign-in, outside the console shell
│   ├── components/ui.tsx               # public: coverage notes, crests, empty states
│   ├── components/admin/               # console kit, confirm dialog, shell, toaster
│   └── lib/api.ts, lib/adminApi.ts     # hand-written types for the read and admin APIs
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
