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
- **Build priority 5 is done AND validated against a live API** — see the
  SportMonks entry below, which superseded API-Football as the provider. The notes
  in this bullet are the original API-Football work and still describe that path. The sync job, client, entity mapping,
  coverage checker and reconciliation logic are written and covered by
  `npm test` (7 integration tests against the real schema, synthetic fixtures).
  Everything else works without a key; the scheduler warns and no-ops.

  **That question is now settled the other way: SportMonks is the provider** (see
  its entry below). API-Football was never bought, so whether it covers the
  Tanzanian league at all remains unknown — `npm run af:coverage` would answer it
  on a free key if anyone ever needs to.

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
  complete; round browsing appears only where real rounds exist — now **4,035 of
  4,380 matches**, from RSSSF and FotMob together.
- **Fixed: every kickoff the API served was shifted by the server's UTC offset.**
  `@prisma/adapter-pg` decodes a TIMESTAMPTZ by taking the wall-clock Postgres
  renders and dropping the offset, so on a machine in America/Chicago a 13:00Z
  kickoff came back as a Date at 08:00Z. `backend/src/db.ts` now pins the
  session with `options: '-c timezone=UTC'`. **Any new DB connection must do the
  same** — a late kickoff otherwise lands on the wrong day.
- **The public site now covers SIX competitions across five countries** — 59
  published editions (2026-09-19). Tanzania's Premier League (19 seasons) and
  the Africa Cup of Nations (35) were joined by the Kenyan, Rwandan, Ugandan and
  South African top tiers; `npm run editions:publish -- --ids <list> --apply`
  publishes or unpublishes in bulk, through the same BLOCKER-flag gate the admin
  console uses. **Kenya is published as two seasons**: 2026/27 (eight fixtures,
  all postponed — thin on purpose, it is what the source has) and **2019/20,
  which carries 151 fixtures, 151 rounds and 318 events, every one of its 107
  scored matches reconciling.** That older season is what gives Kenya real depth
  while its current one is empty.
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
  - Early seasons have no event log because **neither of those two sources** has
    one — not because anything was dropped. But see the next entry: a third
    source does have them, back to 2010/11.
- **FotMob is the best league source for the seasons it covers**
  (`docs/ingestion/FOTMOB_TPL.md`, league id 9066). Full scorer names where
  Flashscore abbreviates, a whole season's fixture list in one call, and it
  settled a match Flashscore could not — Namungo 3-2 TRA United, where
  Flashscore's own log reads 2-2 and so had no name to give. Three traps, each
  of which gave a wrong answer first:
  - **On a match page the embedded `__NEXT_DATA__` is a DIFFERENT match.** The
    fragment in `/matches/{slug}/{code}#{matchId}` selects the game client-side;
    the server renders the most recent meeting of those two clubs. On Azam v
    Polisi `#3999832` the DOM showed the 8-0 while the JSON held `matchId
    5998275`. **Read the DOM on a match page**; the embedded JSON is only
    trustworthy on a LEAGUE page, where `fixtures.allMatches` is the full season.
  - **Away events are mirrored**, time first, so testing only the first
    `.sr-only` label reads "Minute 84" instead of "Goal." and silently drops
    every away goal. Search all the labels.
  - **Take the minute from the accessible label**, not the visible text:
    collapsing whitespace runs "Minute 15" into the clock "15’" and yields 1515.
    And take the SIDE from the running score's movement, which survives the
    mirroring and puts an own goal on the side it counts for.
  - It does not reach further back than the others: 2017/18 is absent from its
    season list entirely, and 2016/17 and earlier have fixture lists but every
    match page 404s. **Three independent sources now agree 2011/12 to 2016/17
    cannot be filled.**
- **2024/25 is complete: 240 of 240 matches reconcile, every goal has an event
  and every event a scorer** (2026-09-17). Flashscore filled 19 goals across 7
  matches that ligikuu had no record of; `docs/ingestion/load_flashscore_tpl.py`
  and `match_flashscore_players.py` (both doctested) are the reusable pair.
  - **The loader completes a log, it never replaces one.** The vault's ligikuu
    events carry full names and Flashscore's timeline does not, so overwriting
    would be a downgrade. Only the per-side shortfall is written, and 7 of the
    17 scorers resolved to players the vault already held.
  - **Flashscore lists a goal on the side it COUNTS FOR, own goals included**,
    while the vault stores an own goal under the scorer's own team. Applying the
    flip to both readings made two matches look unreconcilable; the harvest's
    side needs no flip, only the storage team does.
  - **Tanzania Prisons 3-2 JKT Tanzania (17991) read 4-1, and ligikuu was the
    cause**: it recorded the 41st-minute goal twice, once as an ordinary goal by
    Kichuya and once as Elfadhil's own goal, and three events landed on the
    wrong team. Fixed by re-siding three events and giving them their minutes
    (`2026-09-17_prisons_jkt_2025_sides.sql`) — nothing deleted, no name changed.
    This was one of the two matches long listed here as holding more goal events
    than the score allows.
  - **A same-count, wrong-sides match is only re-sided when the minutes line
    up.** 17991's vault events had no minutes at all, so they sorted last while
    Flashscore's were chronological; pairing by position would have scrambled
    the scorers. The loader reports that case instead of guessing.
- **2025/26 is the first Premier League season worked to completion**
  (2026-09-17). All 522 goals in its scores are accounted for: 518 have a named
  scorer, 239 of 240 matches reconcile, and the 240th is explained rather than
  missing. Done season-by-season from three sources, which is the pattern to
  repeat.
  - **Dodoma Jiji 0-3 Pamba Jiji (match 18059) was never a gap.** Flashscore
    marks it **AWARDED** -- forfeited, with only a 6th-minute Dodoma goal that
    the award annulled. Its empty event log is correct and its 0-3 will never
    reconcile. It carries an INFO `data_flags` row saying so, because every
    audit and coverage report would otherwise keep reporting three missing
    goals forever. **Check for an awarded result before hunting for goals.**
  - **The one goal both ligikuu and Flashscore omitted was an own goal** --
    Himid Mkami's, for Pamba against Azam. ligikuu keeps own goals in a separate
    field it had left empty, and the vault's other three events all named a
    scorer, so nothing pointed at it. An own goal is the shape a missing goal
    most often takes.
  - **Flashscore's season results page stops paging back** after a few "Show
    more matches" clicks. Its **head-to-head tab reaches any older fixture**: a
    match's H2H lists every previous meeting of the two clubs with a link to
    each, so the reverse fixture is a reliable way in.
  - **Take scorer names from Flashscore's player links, never its timeline.**
    The timeline abbreviates ("Nassor M."); the link carries the whole name
    (`/player/nassor-mudathir/`). Planting abbreviations would rebuild the
    identity problem this project spent days undoing.
  - One goal in the season has no scorer anywhere: KMC FC's 82nd minute against
    Namungo, which Flashscore records without attributing.
- **RSSSF supplies Premier League scorers, and the league is now 41.5%
  attributed** (2026-09-16, `docs/ingestion/TPL_RSSSF_SCORERS.md`). RSSSF has a
  page per Tanzanian season with round-by-round results and, for some matches,
  scorers with minutes and **full names** — the one thing ligikuu (nothing before
  2023/24) and WhoScored (nothing ever) do not have. 435 events across 198
  matches; **six seasons went from flat zero to real data** (2008/09 22%,
  2009/10 35%, 2010/11 20%, 2020/21 24%, 2021/22 3%, 2022/23 5%). No match's log
  contradicts its score; the nine that already did were untouched.
  - **RSSSF beat Flashscore on every axis**: plain HTTP against a 403, 19 pages
    against ~2,400, full names against "Dube P.", and it reaches 2007/08 where
    Flashscore starts at 2010/11.
  - **2011/12 to 2016/17 and 2025/26 have results but no scorers at all** —
    2,496 goals with nothing in the page to parse. **2,410 of the remaining
    5,134 unnamed goals have no known source anywhere**, so the league cannot
    reach AFCON's 100%.
  - **Only matches whose scorers account for the whole score are loaded.** 8 were
    refused for naming just some goals — padding the rest with invented events
    would break the one invariant this league's data still holds. 63 were refused
    on a score that disagrees with the vault (principle 2).
  - **Two parser bugs worth not repeating**, both caught by reconciliation rather
    than by reading the code: `[Sep 6]` date headers were read as scorer lines,
    inventing a player called "Oct" and over-counting 434 matches; and every
    semicolon-less bracket went to the home team, when
    `Toto African 0-1 Mtibwa Sugar [Mecky Mexime 2]` is the away goal. Together
    they inflated the apparent haul from 503 to 1,944, which is why the estimate
    given before the parser existed was over twice the truth. **Date headers and
    scorer brackets cannot be separated by indentation** — most pages put both
    flush left; a date header is exactly `[Mon D]`.
- **How the Premier League's ceiling was established** (2026-09-16), before RSSSF was found. 5,568 of 8,778 goals name no scorer.
  What was established, in order of usefulness:
  - **The vault is already at ligikuu's ceiling.** `topup_ligikuu_scorers.py`
    re-harvested the official site and tried to repair every Premier League
    match whose goal log is short of, contradicts, or is unnamed against its
    stored score. Of 475 such matches it could fix **one**. The rest break down
    as: 456 where **ligikuu holds no goals at all** (including the whole of
    2020/21-2022/23, 1,687 goals — the site has results but no scorers for those
    three seasons, so CLAUDE.md's old "complete" for them meant fixtures), 10
    where ligikuu names a player **it has since deleted**, which is exactly why
    those events are unnamed, and 9 where **ligikuu's own log does not
    reconcile** either. Re-running the harvest will not help; the source does
    not have it.
  - **Flashscore does have per-match scorers with minutes, back to 2010/11.**
    Verified in a browser: Azam 8-0 Polisi Tanzania (9 June 2023) lists all
    eight with minutes. Its archive is `football/tanzania/ligi-kuu-bara/archive/`
    and runs 2010/11 to date, so **4,944 of the missing goals are reachable** and
    **624 are not** — 2008/09 and 2009/10 predate the archive. The league
    therefore cannot reach AFCON's 100%, whatever effort goes in.
  - **What that harvest would cost, before anyone starts it:** roughly 2,400
    match pages, which needs a real browser (plain HTTP gets 403, as does
    Sofascore's API and worldfootball.net). Flashscore abbreviates scorers
    ("Dube P."), so every name needs resolving against the vault — the identity
    problem this project has already been bitten by twice, at a scale of
    thousands rather than dozens. Do not start it as a side quest; it is its own
    piece of work, and the volume is worth agreeing with the site's terms first.
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
  - **Data audit (`/admin/audit`) replaced the Issues page.** 26 checks
    (`services/audit/checks.ts`) over scores, events, fixtures, seasons,
    careers and identity, run on demand over the vault or a union of
    competitions and seasons; a full run takes well under a second.
    The three **Identity** checks catch one person recorded as two — the defect
    that made André Ayew read 9 goals instead of 10 — and are gated by the same
    `includeCareers` flag, both being player-scoped rather than per-season.
    They report candidates and never merge. Findings persist in the new
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
  judgement calls. **All 35 editions are published** (2026-09-15,
  `docs/reconciliation/fixes/2026-09-15_publish_afcon_pre2002.sql`, which also
  carries the statement that reverses it). The public AFCON scorer list is 90%
  attributed. After the identity merges described below, its top eleven matches
  the published all-time record exactly: Eto'o 18, Pokou 14, Yekini 13,
  El-Shazly 12, then Drogba, Salah, Mboma and Mané on 11.
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
  - **Scorer markers hang off the minute** in these pages: `5pen`, `3og`,
    `(pen)`, and one line prefixes the running score. The first load missed
    them, recording five penalties as ordinary goals and one own goal for the
    wrong side, and left 22 junk names (`Emmanuel Kundé 55pen`, `Assad ( )`).
    Fixed in `parse_side`, and the load was reverted and redone rather than
    patched. Player provenance is keyed on name **and team**: keyed on the name
    alone, two players called Diallo shared one key and the second had no
    provenance at all.
- **Every AFCON goal but two now names its scorer** (2026-09-16). RSSSF leaves
  four tournaments short of scorers -- all of 1996 and 1998, and gaps in 1980
  and 1994 -- and Wikipedia names them. Pipeline and judgement calls in
  `docs/ingestion/AFCON_WIKIPEDIA_SCORERS.md`. **Coverage went from 91% to
  99.90%: 2,005 of 2,007 goals**, and the public top fourteen now matches the
  published all-time list exactly. Hossam Hassan 11, Kalusha Bwalya 10, Joel
  Tiéhi 10 and Benni McCarthy 7 were all short only because of this gap.
  - **Every AFCON goal now names a scorer: 2,007 of 2,007, and all 787 matches
    with events reproduce their own score.** The last two holes were closed on
    2026-09-16 (`2026-09-16_two_missing_afcon_goals.sql`): Tunisia 1-1 Angola
    (2019) and Zambia 1-1 Tanzania (2023) were each missing the goal *event*
    itself, not just its name. Wikipedia's group-stage articles have both, and
    each agrees with the goal the vault already held -- Msakni's 34th-minute
    penalty exactly, Msuva within a minute -- which is what made them usable for
    the goal it did not. Angola gained Djalma Campos 73', Zambia gained Patson
    Daka 88'. **Daka already existed** (player 2510) and the event attached to
    him; a second Patson Daka is the defect this session spent its time undoing.
  - **The modern articles keep match reports on group subpages**, so
    `fetch_wikipedia_afcon.py` also takes an exact title
    (`"2023 Africa Cup of Nations Group F"`), not just a year. A bare year is
    still a whole tournament.
  - **A match that already has goal events is never added to**, so the 1980/94
    pass wrote only 5 events, for the one match that had none. The single
    remaining unnamed event, Ghana's in the 1994 quarter-final, was named as a
    fix (`2026-09-16_akonnor_1994_quarter_final.sql`) rather than loaded --
    inserting an event would have given that match four goals for a 1-2.
  - **Wikitext, not the rendered page**: the data is in `{{football box}}`
    templates whose arguments are the fields wanted. `?action=raw` returns it.
  - **Two subtleties that each cost a goal.** A goal template preceded by only
    punctuation belongs to the *previous* scorer (McCarthy's golden goal), and
    names come from the link target, not the display text — which is the whole
    value of this source, since the vault holds these men as surnames.
  - **18 of the 61 fixtures are oriented the other way round** from the vault.
    The score agrees once flipped, so the goals are mapped onto the vault's
    sides; the fixture is never rewritten.
  - **`playermatch.py` (doctested) decides identity, and is deliberately
    reluctant.** Refusing a true match costs a duplicate the audit will raise;
    accepting a false one silently moves goals onto the wrong man. Matching on
    surname alone immediately produced two wrong answers — Johnson Bwalya onto
    Kalusha Bwalya, and both Malitolis onto one record. A bare surname now
    needs to be the vault's only such record *and* the only incoming player
    with it. 24 of 107 names attached to existing players; 82 were created.
  - **Both finals already had their scorers and were left alone**, which makes
    them a cross-source check: Wikipedia names the same men.
- **Samuel Eto'o was two players, and is now one.** The legacy data spells him
  "Etoo" (one goal, 2002 v Togo); everything else was under "Samuel Eto'o". His
  AFCON record read 17 when the vault in fact held all 18. Merged 2026-09-15
  (`docs/reconciliation/fixes/2026-09-15_merge_duplicate_etoo.sql`); the legacy
  provenance row moved with the events. The public list now reads Eto'o 18,
  Pokou 14, Yekini 13, Drogba 11 — each matching the real record.
  Eto'o was not the only one — see the next entry, which settled the rest.
- **The Africa Cup of Nations held 45 player records for 39 people, and one
  match had all four goals on the wrong side.** Found 2026-09-15 by comparing
  the vault against Wikipedia's all-time AFCON scoring list, after André Ayew
  read 9 goals against an official 10. Applied in
  `docs/reconciliation/fixes/2026-09-15_afcon_scorer_identities.sql`, then
  `2026-09-16_taifa_stars_and_remaining_duplicates.sql`. **No goal was missing
  in any of it**; the goals were filed under second copies of the scorer.
  - Two mechanisms, both worth knowing before trusting any scorer total.
    WhoScored editions loaded before the source exposed player ids were keyed
    `name:{team}:{name}`, so "Mboma" and "Patrick Mboma" became two men. And
    AFCON 2019 came from the legacy dump, which prints names in full
    ("André Morgan Rami Ayew Dede Ayew"), while 2021 onward came from WhoScored
    ("André Ayew") — one career, two rows, in **any** competition the two
    sources share.
  - **Ten merges were confirmed arithmetically**, the merged total equalling the
    published all-time figure exactly: Mboma 11, Kanouté 7, Francileudo Santos
    10, Flávio 7, Okocha 7, Abouzeid 7, El-Shazly 12, Mané 11, Ayew 10 and
    Abdoulaye Traoré 9 — that last one four records, including a "Troaré" typo.
    The public top eleven now matches the real record from Eto'o's 18 down.
  - **Zambia 2-2 Senegal, AFCON 2000, had its scorers swapped**: RSSSF wrote
    that one line's brackets in the opposite order to the fixture. It survived
    the load because the loader checks each side's goals against that side's
    score, which a swap cannot break when the scores are level — so **only a
    drawn match can hide one**. All 61 pre-2002 score draws were re-checked
    against the source and their scorers' nationalities; this was the only one.
  - **"Taifa Stars" and "Tanzania" were two records for one national side**, now
    merged into Tanzania (91). Simon Msuva was the giveaway: the only player in
    the vault scoring for two different countries, both his own.
  - **What is still short is absent source data, not a defect.** 1996 and 1998
    name a scorer for 4 of their 171 goals, which is the whole of Hossam
    Hassan's missing 7, Benni McCarthy's 7, Kalusha Bwalya's 6, Joel Tiéhi's 5
    and Abedi Pele's 4. Mengistu Worku (8 against an official 10) and Ali
    Abugreisha (4 against 7) fall in fully-attributed tournaments — RSSSF simply
    credits those goals to other named players. Do not "fix" these by inventing
    goals.
  - **Surname pairs are left unmerged until a source names the scorer.** A
    surname alone never merges two players — Luciano and Italo Vassalo were
    brothers who both scored for Ethiopia, and Kwame Ayew, André Ayew and Abedi
    Pele (Abedi Ayew) are three different people. The audit raises them as
    `SCORER_NAME_ABBREVIATED` candidates (48 open) and a human decides.
    **Nigeria's four Lawal records were settled this way** on 2026-09-16
    (`2026-09-16_nigeria_lawal_records.sql`): Wikipedia's 1976, 1980 and 2002
    match reports name the scorer of every one of those goals, with the minutes
    agreeing, so they are two men — **Mudashiru "Muda" Lawal** (5 goals,
    1976-1984, renamed from the nickname that made the record ambiguous) and
    **Garba Lawal** (3 goals, 2002-2006), born a generation apart. Egypt's
    Khalil turned out the opposite way: Wikipedia names the 1976 goal for
    *Osama* Khalil, so the 1974 "A.Khalil" is someone else and the pair stays
    split. **Nigeria's Odegbami went the same way as Lawal** on 2026-09-16
    (`2026-09-16_segun_odegbami_records.sql`): the 1978 and 1980 reports name
    Segun Odegbami for all six goals, no other Odegbami appears in either
    article, and the 1980 page's own top-scorer line of 3 goals is reproduced
    only once the two records are merged — separately they give a false 1 and a
    false 2. **That arithmetic check is the pattern to look for**: a source that
    states a per-tournament or all-time total lets a merge be proved rather than
    argued. **Ivory Coast's Guel, Ghana's Polley and Cameroon's Ebongué went
    the same way** on 2026-09-16 (`2026-09-16_guel_polley_ebongue_records.sql`),
    all six goals named in the source. Ebongué had looked the least safe, eight
    years separating his two goals, and the source is what closed it — which is
    the argument for holding these back rather than guessing. Polley's 1994 goal
    also showed the limit of the method: the two sources agree it is his and
    disagree by 46 minutes on when, so the identity merged and the vault's
    minute stood. **44 candidates remain open**, now mostly modern Senegalese
    and Malian surnames (Gueye, Diallo, Diarra, Camara, Touré) where several
    real players share one, so a bare record cannot be assigned without a source
    naming that specific goal.
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
- **Every played AFCON match's event log reproduces its own score**, across all
  35 tournaments. The two long-standing exceptions -- Zambia 1-1 Tanzania (2023)
  and Tunisia 1-1 Angola (2019), each a goal event short in its source -- were
  filled from Wikipedia on 2026-09-16. Do not go looking for them again.
- **28 legacy events sat on matches their team never played in, and are now
  resolved** (2026-09-16,
  `docs/reconciliation/fixes/2026-09-16_orphan_events_afcon_2019.sql`). These
  were the audit's 14 open `ORPHAN_EVENT` findings, and the reason ten AFCON
  2019 matches held more goal events than their score allowed. **No match in
  the vault does any more.** Three separate things, treated differently:
  - **Four goals gained the scorer we already had.** For two ties the legacy
    data holds the event set twice — once on the right match with no scorer,
    once on a wrong match *with* the scorer named, minutes agreeing. So
    DR Congo 0-2 Uganda is now Kaddu 14' and Okwi 48', and Guinea 2-2
    Madagascar is Sory Kaba 34' and Kamano 66' (a penalty; the type was wrong
    too). **Before assuming an unnamed goal is unknowable, check whether a
    misfiled copy names it.**
  - **Two goals wore the wrong team**, each the only goal event on a match
    needing exactly one, so the score itself settled it: Simba SC's winner at
    UD Songo, and South Sudan's equaliser against Malawi.
  - **26 surplus events were deleted**: 12 exact duplicates of events already
    on the right match, and 14 fragments credited to twelve Tanzanian clubs
    that play no match anywhere in the vault. The clubs are **not** deleted —
    three hold player registrations, so they are real clubs whose matches the
    migration never brought over.
  - Removing the junk made the audit newly report Tunisia 1-1 Angola as a goal
    short. That is correct: the stray event had been padding the count over a
    gap that was always there.
- **South Africa has a real scorer list: 123 of its 125 goals name a scorer**
  (2026-09-19, `npm run sm:events -- --league 806 --apply`,
  `backend/src/scripts/loadSportmonksEvents.ts`). All 45 matches with goals
  reconcile with their stored score; edition 405 reads 117 attributed goals
  against 2 unattributed. Ngwenya leads on 8.
  - **This is the ONLY place this codebase writes SportMonks events**, and it is
    narrow on purpose. The live sync still writes scores and never events,
    because for the Tanzanian Premier League the vault's own goal log is better.
    For a league the vault holds nothing for, something beats nothing — but only
    if the names are real.
  - **The event feed's `player_name` is a DISPLAY name and is often an
    abbreviation.** 18 of Rwanda's 28 scorer names are initials plus a surname,
    13 of Uganda's 50, 8 of South Africa's 84. Writing those straight in would
    seed a new player table with "K. Nsanzimfura", and with no second source for
    these leagues nothing would ever catch it.
  - **So every scorer is resolved through `/players/{id}`**, which carries the
    real name: "S. Kammies" is Sergio Kammies, "B. Grobler" is Bradley Grobler.
    Same technique as taking a Flashscore name from its player link rather than
    its timeline. **A scorer that cannot be resolved is written UNATTRIBUTED,
    never abbreviated** — 2 goals ended that way, and 0 abbreviated names exist
    in the player table as a result.
  - **Neither source is reliably fuller than the other.** The players endpoint
    gives "Sergio Kammies" where the event says "S. Kammies", but also
    "P. Kumalo" where the event says "Philani Kumalo", and "S. Junior Dion" for
    the event's "Junior Dion". Always trusting one throws the other away; taking
    whichever is not abbreviated moved the result from 121 to 123 of 125.
  - **Which is why this is worth running for South Africa and not for Rwanda.**
    120 of South Africa's 125 goals carry a provider player id, against 8 of
    Rwanda's 29 and 15 of Uganda's 64. Run `sm:events` as a dry run against a
    league before assuming it is worth it.
  - **A scorer is keyed by the provider's player id, or by the resolved name when
    the feed gives no id.** Keying on the id alone silently dropped five goals
    that carried a full name and no id: they were resolved, reported as named,
    and then written unattributed. The load was reverted and redone rather than
    patched, which is the same call the pre-2002 AFCON load made.
  - Refusals, both inherited: **a match whose event log does not account for its
    score is not loaded**, and **a match that already has goal events is never
    added to**. Cards and substitutions are available from this source and are
    deliberately not loaded.
- **Four more leagues are in the vault: Kenya, Rwanda, Uganda and South Africa**
  (2026-09-19), their 2026/27 seasons pulled from SportMonks with
  `npm run sm:ingest -- --league <id> [--apply]`
  (`backend/src/scripts/ingestSportmonksLeague.ts`). **All four editions are
  UNPUBLISHED** — nothing reaches the public site until someone publishes it.

  | Country | Competition | Edition | Clubs | Fixtures | Results | Rounds |
  |---|---|---|---|---|---|---|
  | Rwanda | National Soccer League (#126) | 404 | 18 | 305 | 22 | all |
  | South Africa | Premier League (#127) | 405 | 16 | 240 | 53 | **none** |
  | Uganda | Premier League (#128) | 406 | 18 | 153 | 34 | all |
  | Kenya | Kenya premier league (#17) | 407 | 16 | **8** | 4 | none |

  - **No events were loaded for any of them by the ingest** — fixtures, scores,
    clubs and participants only, so a top-scorer list is empty by construction
    rather than by accident. South Africa's were loaded separately and carefully
    afterwards (see the entry above); **Rwanda's and Uganda's remain empty on
    purpose**, because too few of their goals carry a resolvable scorer name.
  - **Kenya reuses competition 17**, the record the legacy SokaFC dump already
    held, rather than a second one beside it — creating a duplicate is how a
    league's history gets split in two. Its 2019/20 edition (21) is untouched.
  - **Kenya's 2026/27 is barely a season**: eight fixtures, every one POSTPONED,
    no rounds, no events. SportMonks' squad endpoint returns nothing for it, so
    the 16 clubs were derived from the fixtures' own participants. **Do not
    publish it** — there is nothing to serve yet.
  - **South Africa has no round numbers at all** from this source, so round
    browsing will not work for it. Date is the axis there.
  - **A club's country comes from the provider's own `country` include, never
    from the league.** That is what keeps **Al Hilal Omdurman and Al Merreikh**
    — two Sudanese clubs playing in the Rwandan league while the war continues —
    filed under Sudan rather than Rwanda.
  - **Club matching is scoped to the club's country.** Kenya and Uganda both
    field a club called simply "Police", and Tanzania has "Polisi Tanzania"; an
    unscoped name match would have merged them into one record.
  - **`normalizeName` dropped dots instead of spacing them, and it mattered.**
    "Bandari F.C." reduced to `bandari f c` rather than `bandari`, so Kenya's
    Bandari came one dry run away from being created a second time. Dots and
    apostrophes are now removed before the affix rule runs; the change creates
    zero new same-country collisions across the whole vault.
  - **The ingest reports NEAR MISSES** — a club it is about to create, or one it
    resolved to, that resembles another in the same country. That is what caught
    Bandari, and it surfaced a pre-existing defect: the vault held **"Mathare
    Utd." (17 matches) and "Mathare United" (0 matches) as two records for one
    club**. Merged in `2026-09-19_merge_mathare_united.sql` — the empty record
    was deleted and the survivor took the full name, so the club's 2019/20 and
    2026/27 seasons stay on one record.
  - **SportMonks' Rwandan list is one fixture short and duplicates another.** It
    has 306 entries but only 305 distinct ordered club pairs: Police Rwanda v
    Al Merreikh appears in round 2 *and* round 19, and the reverse fixture
    appears nowhere. The first load silently collapsed the two;
    `2026-09-19_rwanda_duplicate_fixture.sql` corrects the match to the round-2
    entry, drops the spurious provenance row, and carries an INFO
    `data_flags` row so 305-of-306 reads as absent source data rather than a
    dropped row. **The loader now refuses to merge a duplicated pair silently.**
  - Round-tripped with `npm run sm:compare` after loading: every fixture matched,
    **every score agreed, zero conflicts** in all four leagues.
- **The live-score provider is SportMonks, and it is wired up and validated**
  (2026-09-19). `SPORTMONKS_TOKEN` in `backend/.env`; league #884 "Ligi kuu Bara"
  is mapped to vault competition 1. Full detail in `backend/README.md`.
  Commands: `npm run sm:coverage`, `sm:map`, `sm:compare`, `sm:sync`.
  - **It was chosen because its Tanzanian event coverage could be VERIFIED before
    paying** — its published per-league table ticks "Livescores and Events" for
    #884. API-Football's coverage page is behind Cloudflare and its flags behind a
    key, so its Tanzanian depth is still unknown. It stays wired as a fallback and
    only runs when SportMonks has no token.
  - **`syncFixtures(fixtures, source)` is provider-neutral.** Each provider
    normalises its own payload into `ProviderFixture` (`services/providerFixture.ts`)
    and the reconciliation rules live in exactly one place. `entityResolution` takes
    the source as a parameter too — it used to hardcode `api_football`, which would
    have resolved SportMonks ids to nothing.
  - **SportMonks files an own goal under the side it counts FOR**, so
    `normaliseEvents` flips it to the scorer's own team. Established against the
    vault, not assumed: Kagera Sugar 1-1 Fountain Gate (13 Sep 2026) has it on
    Fountain Gate with the score moving 1-0 to 1-1, while the vault holds the same
    scorer at the same 34th minute under Kagera Sugar. That is the **fifth** source
    needing this flip — ligikuu, RSSSF, WhoScored (pre-2013) and FotMob were the
    others. A unit test asserts `reconstructScore` FAILS when the flip is removed.
  - **`npm run sm:compare` diffs the provider against the vault and writes
    nothing.** Run it before trusting anything. Against 2026/27: 240 of 240
    fixtures matched, **49 of 49 scores agree, 240 of 240 rounds agree**, every
    event log rebuilds its own score — and **scorer names agree on only 70 of 108
    pairable goals.**
  - **So the sync writes scores, status and kickoffs, and deliberately does NOT
    write events.** For this league the vault's goal log is the better one; the 38
    name differences are mostly spelling ("Anuary Jabiri" / "Anuary Jabir") but
    some are a different man, and writing them would rebuild the identity problem.
  - **A kickoff moves only for an UNPLAYED fixture.** A reschedule is news, not a
    disagreement; for a played match the kickoff is canonical and stays put. The
    first catch-up run moved 27 dates and reclassified **25 fixtures from SCHEDULED
    to POSTPONED**, which no other source had told the vault.
  - **SportMonks publishes AWARDED as a fixture state (17).** The vault has two
    forfeited results and both were found by hand after an event log refused to
    reconcile forever; from here they are recognised on sight.
  - **The edition mapping key is `"<leagueId>:<seasonId>"`, with the numeric season
    id, not its label.** Getting that wrong makes every fixture read as an unmapped
    competition — it was caught before the first sync ran.
  - **The plan's five leagues are not equally deep.** Tanzania is the only one where
    every finished fixture carries events (49/49) and rounds (240/240). South Africa
    has events but no rounds; Rwanda and Uganda have gaps; **Kenya is effectively
    empty** (8 fixtures, all postponed). **All five are now mapped** in
    `VAULT_COMPETITION_BY_PROVIDER_LEAGUE`, so the live sync covers all of them —
    see the entry above for how the other four were stood up.
  - **Neither provider covers lineups or player stats for these leagues**, so the
    suppressed `appearances`/`yellowCards`/`redCards` on the public site stay
    suppressed. Do not expect this to fill them.
  - `backend/src/config/teamAliases.ts` maps "Young Africans" to the vault's
    "Yanga SC" — two names sharing no token, so no matcher could infer it.
    `docs/ingestion/teamnames.py` remains the source of truth for club naming.
- **The Premier League's fixtures now know their round: 4,035 of 4,380, up from
  3,437** (2026-09-19). Thirteen seasons had gaps; ten are now complete. Loaded
  from FotMob's fixture list, whose every entry carries a `round` the official
  site's export does not — `docs/ingestion/load_rounds_fotmob.py`, written up in
  `FOTMOB_TPL.md`. A season's rounds travel out of the browser as two ~950-char
  chunks (clubs indexed once, then `round|hIdx>aIdx` pairs), each verified by
  SHA-1 before loading.
  - **`check_source` refuses a whole season rather than writing part of one**,
    and two of its three checks fired. A duplicated fixture refused **2016/17**
    (FotMob lists Kagera Sugar v Stand United in rounds 2 *and* 17; the reverse
    fixture is in neither source, which is why that season holds 239 fixtures).
    A new check — **no club in two fixtures in one round** — refused **2011/12**.
  - **2011/12's rounds are unrecoverable, not merely unloaded.** Its rounds 19-22
    hold 28 fixtures scrambled across each other, and the decomposition into four
    perfect matchings is **not unique** — a search finds more than one, and even a
    unique one would not say which block is round 19. RSSSF's page for that
    season has only the final table, and WhoScored has no rounds at all. Do not
    reconstruct them; that would be inventing data.
  - **FotMob's rounds agree with the rounds the vault already held on 1,097 of
    1,097 fixtures** across the seven seasons that disagreed nowhere (2010/11,
    2012/13, 2013/14, 2014/15, 2015/16, 2020/21, 2021/22). That is what
    justifies trusting FotMob where the vault was blank, and what makes 2011/12
    read as one season's defect rather than FotMob deriving old rounds generally.
  - **A round the vault already has is never overwritten** — it is kept and the
    disagreement written as a PENDING `reconciliation_diffs` row (principle 2).
    Nine such rows were then resolved by hand:
    **2023/24 had four fixtures under the wrong round and 2022/23 five, every
    one a Singida Black Stars match**, each settled by its own kickoff date and
    proved by the round sizes — before the fixes three rounds a season held nine
    fixtures and three held seven; afterwards all thirty hold eight
    (`2026-09-19_tpl_2023_24_singida_rounds.sql`,
    `2026-09-19_tpl_2022_23_singida_rounds.sql`). 2016/17's single roundless
    fixture was applied the same way
    (`2026-09-19_tpl_2016_17_toto_prisons_round.sql`).
  - **2025/26's rounds 18 and 19 are swapped between the sources and were left
    alone.** Chronology cannot settle it: both sources number out of playing
    order elsewhere in that season, both calling the 30 April set round 22 ahead
    of rounds 20 and 21. Sixteen diffs stay PENDING for a human.
  - **Check round sizes before reading a disagreement as a defect.** In both
    Singida seasons one round held eight all along, because its intruder and its
    absentee cancelled out.
  - Still roundless: **2008/09** (132, before FotMob's season list), **2011/12**
    (182, above) and **31 of 2020/21** — the Ihefu FC and BIGMAN FC surplus that
    FotMob's 306 fixtures do not include.
- **The Premier League's 2022/23 season is complete: 240 of 240 matches
  reconcile with their score, and 97% of its 561 goals name a scorer.** Loaded
  2026-09-18 from FotMob — see `docs/ingestion/FOTMOB_TPL.md` for the harvest,
  the loader and the traps. The vault previously held an event log for 10 of
  those 240 matches.
  - The 17 goals with no scorer are FotMob's own `<TBD>`: it has the goal and
    not the man. They are stored as events with a NULL `player_id`, which is
    the truth. Do not go looking for names FotMob never had.
  - **A club pool alone does not recognise a player, because players transfer.**
    The vault learns a club from the events it holds, so for a season with no
    event log it knows nothing, and a first pass proposed 68 new records for
    players already in the vault. `match_fotmob_players.py` adds a stricter
    vault-wide pass — exact name tokens, exactly one hit — which matched 48 of
    them. The rest are created on purpose: a duplicate is raised by the audit's
    Identity checks, a wrong match silently moves goals onto another man.
  - Fiston Mayele's 18 goals match the published Golden Boot exactly, which is
    the check that the sides and own-goal flips came out right.
  - Two scorers were held twice and were merged first
    (`docs/reconciliation/fixes/2026-09-18_tpl_2022_23_duplicate_scorers.sql`):
    Feisal Salum at Yanga and Erick Mwijage at Kagera Sugar, each one man
    recorded by two sources in seasons that do not overlap. **Seven more names
    the vault still holds twice** were not merged and their 2022/23 goals went
    to new records — Saidi Ntibazonkiza, Vitalis Mayanga, Kelvin Sabato,
    Japhary Kibaya, Tariq Seif, Haruna Shamte, Salum Abubakar. So was a third
    "Feisal Salum" (player 2069, Azam and Tanzania), who may be the same man as
    the Yanga one but has 2018/19 events at a different club, and nothing in the
    vault settles it.
- **2021/22 is complete too: 239 of 240 matches reconcile and 99.6% of its 468
  goals name a scorer** (2026-09-18, FotMob). The vault held an event log for 10
  of those 240 matches before this; 453 goal events were added.
  - **The 240th match is the second awarded result in the vault.** Namungo 3-0
    Mbeya Kwanza (17249, 13 May 2022) was never played out -- FotMob flags it
    `awarded` and its match page has no events at all. It carries an INFO flag
    saying so (`2026-09-18_tpl_2021_22_duplicates_and_awarded.sql`), like Dodoma
    Jiji 0-3 Pamba Jiji in 2025/26. **Check for an awarded result before hunting
    for goals** -- that is now twice.
  - Two more duplicate players were merged first, in the same file and to the
    same pattern: Augustino Nsata at Dodoma Jiji and Haji Ugando at Coastal
    Union, each one man under two records in seasons that do not overlap. The
    loader had refused to name their goals, which is the right refusal.
  - **FotMob's fixture list agreed with the vault on all 471 goals before a
    single match page was opened**, and on all 240 scores. Comparing the season
    total first is a cheap check worth doing before any harvest.
- **The harvest is a browser queue, and it must verify the page it reads.** GO
  navigates, GRAB reads -- and a dropped extension connection left `cur` pointing
  at one match while the page showed another. GRAB now refuses unless the URL
  fragment equals the id it means to store AND the page title names both clubs,
  on top of checking the goal count, the final running score and the per-side
  split against the fixture list. It caught the one mismatched read.
  - Navigating between two matches that share a slug changes only the fragment
    and **does not re-render**, so GO appends a throwaway query parameter to
    force a real load.
  - Goalless draws are skipped: there is nothing to harvest, and 35 of 2021/22's
    240 matches were 0-0.
  - Getting the result out of the browser is the awkward part. A local HTTP sink
    is blocked by the page's CSP, `navigator.clipboard` needs focus the tab does
    not have, and base64 is refused by the tool layer. What works is plain text
    in ~950-character chunks, chunked on row boundaries, then a SHA-1 of the
    whole compared against the browser's own -- both seasons matched exactly.
- **2020/21 went from 159 goal events to 609, and 95.7% of them name a
  scorer** (2026-09-18, FotMob). 269 of its 325 played matches now have an event
  log, against 107 before. **This season's ceiling is the source, not the
  effort**: the 46 goals still without an event are 39 in Ihefu FC and BIGMAN FC
  fixtures that FotMob's 2020/21 does not contain at all, and 7 in five matches
  FotMob has a result for but no timeline.
  - **FotMob's 2020/21 is a clean 18-team league (306 fixtures); the vault's
    edition has 20 clubs and 337.** All 306 matched a vault fixture and **all
    306 scores agreed exactly**, so the overlap is sound. The surplus 31 are
    Ihefu FC and BIGMAN FC, who appear only from February 2021 with 16 matches
    each and 6 unscored each — which is where the 12 long-standing SCHEDULED
    fixtures live. **What those 31 fixtures actually are is still an open
    question** and a data call for an editor; this load did not touch them.
  - **A club's name on a FotMob match page can differ from its name in that
    season's fixture list.** Team 1171766 renders as "Ihefu FC" on match pages
    and as "Singida Black Stars" in the 2020/21 list, which made the harvest's
    page-identity guard reject all 34 of those matches until it was relaxed to
    need only one of the two clubs in the title.
- **An own goal is never attributed to a player of the side it counts for.**
  FotMob credits Azam's third goal against Dodoma Jiji (5 Nov 2020) to an own
  goal by Prince Dube, Azam's own striker. `load_fotmob_tpl.py` now refuses a
  name in that position and loads the event unattributed, because accepting it
  would move a forward's goal onto the opposing club and register him there.
- **Four player records held parser output instead of a name, and are fixed**
  (`docs/reconciliation/fixes/2026-09-18_parser_artifacts_and_2020_21_duplicates.sql`).
  Two were RSSSF minute markers kept as part of the name — "Michael Sarpong
  (pen)" and "Themi Felix (pen)", **the same defect fixed for the pre-2002 AFCON
  load and missed for the Premier League pages**; each merged into the clean
  record and each goal became the PENALTY_GOAL the marker had been saying all
  along. Two were undecoded ligikuu HTML entities ("Ally Ng&#8217;anzi",
  "Richardson Ng&#8217;ondya"). Sweep for more with
  `SELECT id, full_name FROM players WHERE full_name ~ '\(|&#|[0-9]';`
  Four duplicate scorers went in the same fix; **Daniel Lyanga and Kelvin
  Sabato stay ambiguous** (Sabato has five records, two of them legacy junk like
  "Kelvin Sabato Sabato sabato"), so their 2020/21 goals stay unattributed.
- **FotMob's match detail does not reach back past 2020/21, so 2019/20 and
  2018/19 cannot be filled from it** (established 2026-09-18 by probing match
  pages across both seasons, not by assumption — `FOTMOB_TPL.md` has the table).
  Four of six 2019/20 probes render a normal match page with an empty timeline
  and the other two 404; all three 2018/19 probes 404. **The 346 unattributed
  goals in 2019/20 and the 63 in 2018/19 are out of FotMob's reach.**
  The old claim in that doc that it reached ~2018/19 was wrong.
  - The scores are still worth having as a cross-check: FotMob's 2019/20 has all
    380 fixtures and **767 goals, agreeing with the vault exactly**, and 2018/19
    agrees at 746. Zero score conflicts in either.
  - **Flashscore is the remaining candidate** for these two seasons — its
    archive runs 2010/11 to date and it does carry per-match scorers — but
    reaching an old season needs the head-to-head route, since its results page
    stops paging back.
- **A side whose goals are ALL unattributed can be named as a set.** 275 of
  2019/20's 346 unnamed events carry no minute, so the minute rule can never
  reach them. But where every goal event on one side of a match is unnamed those
  events carry nothing that tells them apart, so pairing them with the source's
  goals for that side is a bijection between interchangeable slots and named
  goals, and every bijection gives the same facts. Types must match as a
  multiset and pairing happens within a type; a minute is filled only where the
  vault has none. **This is the exception to "never pair by position"** — 17991
  is the case where position would have scrambled the scorers, and the
  difference is that there the events were distinguishable.
  - It has no season to run against until a source for 2019/20 exists, so
    `docs/ingestion/test_name_whole_side.py` exercises it against real data:
    it strips the scorers from twelve 2022/23 match-sides, re-runs the loader,
    checks the same scorers come back, and rolls back. **The first version of
    that test failed for the right reason** — it included events named by RSSSF,
    where FotMob spells the same man differently ("Dejan Georgejivec" against
    "Dejan Georgijevic"), so it was measuring the sources' disagreement rather
    than the step.
  - That comparison also turned up **"Bakari Nondo" (12531, from FotMob) and
    "Bakari Mwamnyeto" (1444), both Yanga SC** — very likely one man under two
    surnames. Not merged: two different surnames are not something the vault can
    settle, and **the audit's Identity checks will not raise this pair either,
    because they key on a shared name.** That is a gap in those checks.
- **Flashscore reaches 2019/20 where FotMob does not, and named 136 of its
  goals** (2026-09-18). 2019/20 went from 55% attributed to 73%: 346 unnamed
  goals down to 207, with all 380 matches still reconciling. Meddie Kagere's 20
  leads the season.
  - **Flashscore's season results page reaches back only so far.** For 2019/20
    it lists 106 of 380 matches — 14 March to 1 August 2020, the COVID restart
    and the play-offs — with no "show more" button at all. That still covered
    206 of the 346 unattributed goals. **The other 140 need the head-to-head or
    team-page route**, which is the documented way to older fixtures and has not
    been done yet.
  - **102 of the 106 matched a vault fixture with the score agreeing exactly.**
    The 4 refusals are play-off ties whose clubs also met in the league, so the
    ordered pair is no longer unique that season — the score check caught them.
  - 160 of the 169 harvested goals name a scorer; only 136 were written, and the
    gap is the type guard working. **7 sides hold a plain GOAL in the vault where
    Flashscore says OWN_GOAL** — the familiar pattern of legacy data filing an
    own goal as an ordinary goal for the side it counted for. Correcting those
    means changing a type *and* moving the event to the scorer's own team, which
    is a fix file's job, not a loader's. They are still unnamed.
  - 11 of the 86 matches visited were skipped because Flashscore's own timeline
    is short of the score.
  - **`load_fotmob_tpl.py` now takes `--source`**, because provenance must name
    the source the rows came from (principle 1) and it was hardcoded to
    `fotmob`. `normalize_flashscore_names.py` emits the same staged shape, and
    turns Flashscore's player-link slug into a name with the already-doctested
    `name_from`.
- **Six sources were surveyed for the last two unnamed seasons, and only
  Flashscore is usable** (2026-09-18, `docs/ingestion/TPL_SOURCE_SURVEY.md`).
  2018/19 is now **95.4% attributed** (63 unnamed goals down to 34); 2019/20
  stands at 72.6%. **Every claim in that survey was tested by reading the page's
  DOM** — twice a page summariser reported scorers the page does not contain.
  - **Soccerway, Livesport and Flashscore are one platform.** Soccerway
    redirects to a Flashscore-style URL and lists the identical 106 matches.
    Checking it as a separate source is wasted effort.
  - **Flashscore's per-season results page has no "show more" at all** and
    reaches back only about four months: 106 of 380 matches for 2019/20 (from
    14 Mar 2020), 104 of 380 for 2018/19 (from 10 Mar 2019). That still covered
    206 of 2019/20's unattributed goals and 54 of 2018/19's, because they are
    not spread evenly.
  - **footballdatabase.eu has the whole fixture list and virtually no scorers**
    — 19 of 20 sampled match pages say "No key stat for this match". Its value
    was as a check: **all 279 of its fixtures matched a vault fixture with the
    score agreeing exactly**, which also confirmed that its oddly-labelled
    "DT Bank" is the vault's Singida Black Stars.
  - **BeSoccer has the early season and was rejected on accuracy.** It is the
    only source with named scorers for August 2019, but on four matches it also
    covers it disagrees with Flashscore on roughly a third of goals — a
    different scorer in two, and a different own-goal scorer and minutes in a
    third — and nothing available adjudicates. It also abbreviates to an initial
    and surname, in its slugs too. **Use it as a third opinion where two sources
    already disagree, never as a primary source.**
  - Transfermarkt and worldfootball.net have no Tanzanian league at all.
  - **140 of 2019/20's unattributed goals and 9 of 2018/19's are out of reach**
    of every source surveyed.
- **The season in play is kept current with `update_season_results.py`**, not
  `load.py` — which skips a season the vault already has, by design. As of
  2026-09-19 the 2026/27 Premier League holds **49 of 240 fixtures played, all
  49 reconciling with their score and every goal naming a scorer**, and nothing
  is past its kickoff without a result.
  - It writes a score **only where there is none**; a result the vault already
    has is never overwritten, and a disagreement becomes a diff (principle 2).
  - **It corrects a kickoff when the fixture moved.** Three of the eight results
    added were played later than scheduled — Azam v Simba a week late — and a
    stale scheduled date is the defect that once left 82 COVID-restart fixtures
    inside the suspension.
  - **ligikuu's goal list is not always complete, and the score decides.** Three
    of the eight had a list that did not add up (1-1 for an Azam 0-2 Simba); the
    lists were refused, the scores written, and the four affected matches then
    completed from FotMob. **A wrong goal log is worse than none.**
  - **All eight scores and all three date corrections were confirmed against
    FotMob before committing.** One page load, and it is the whole safety net
    for a write that changes what the public site shows.
- **2026/27 has its round numbers: all 240 fixtures, 30 rounds of 8.** The
  official site cannot supply them — SportsPress's `day` field is empty on all
  215 of its events — so they come from FotMob's fixture list via
  `load_rounds_fotmob.py`, which writes a round only where the vault has none.
  - It refuses the whole load rather than writing part of it unless the source
    is a coherent fixture list (every round the same size, no club pair twice,
    the total matching a double round-robin) and every fixture matches exactly
    one vault fixture. **That check earned its place immediately**: the transfer
    out of the browser dropped two lines at a chunk boundary and left round 17
    with six fixtures, and the shape check named it before anything was written.
  - **A round is not a date.** Azam v Namungo is a round 8 fixture played on
    7 September, five weeks before the rest of round 8. Ordering by round and
    ordering by date are different things and the vault holds both.
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
