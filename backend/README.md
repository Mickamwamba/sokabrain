# sokabrain backend

Read API over the migrated vault. Build priority 2: Express + Prisma and the
three endpoints that prove the schema supports the product.

## Setup

```bash
cp .env.example .env      # set DATABASE_URL (and PORT if 4010 is taken)
npm install
npm run db:pull           # re-introspect if the database schema changes
npm run db:generate
npm run dev
```

The database must exist first — see `../scripts/restore_db.sh`.

## Endpoints

| Method | Path | Notes |
|---|---|---|
| GET | `/health` | liveness + database reachability |
| GET | `/api/vault/editions` | edition index; needed to discover `editionId` |
| GET | `/api/vault/editions/:editionId/standings` | league table |
| GET | `/api/vault/editions/:editionId/top-scorers?limit=` | limit 1–100, default 20 |
| GET | `/api/vault/matches` | `editionId`, `teamId`, `status`, `from`, `to`, `limit`, `offset` |

```bash
curl localhost:4010/api/vault/editions/6/standings       # TPL 2018/19
curl localhost:4010/api/vault/editions/6/top-scorers
curl 'localhost:4010/api/vault/matches?teamId=11&limit=5'
```

## Admin API (priority 3)

Accounts are provisioned from the CLI — there is no self-signup endpoint:

```bash
ADMIN_PASSWORD='at-least-12-chars' npm run admin:create -- \
  --email you@example.com --name "Your Name"
```

Requires `JWT_SECRET` in `.env` (`openssl rand -hex 32`). Tokens last 12 hours.

| Method | Path | Notes |
|---|---|---|
| POST | `/api/admin/auth/login` | → `{ token, admin }` |
| GET | `/api/admin/me` | current admin |
| POST | `/api/admin/me/password` | `currentPassword`, `newPassword` (min 12) |
| POST/PATCH | `/api/admin/matches[/:id]` | PATCH is how you fill a missing score |
| POST | `/api/admin/matches/:id/events` | `team_id` must be one of the two teams |
| DELETE | `/api/admin/matches/:id/events/:eventId` | also removes the provenance row |

```bash
TOKEN=$(curl -s -X POST localhost:4010/api/admin/auth/login \
  -H 'content-type: application/json' \
  -d '{"email":"you@example.com","password":"..."}' | jq -r .token)

curl -X PATCH localhost:4010/api/admin/matches/300 \
  -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' \
  -d '{"home_score":2,"away_score":1}'
```

## Things worth knowing before changing these

- **Standings read the stored score**, never the event log (design principle 3).
  That is both cheaper and more correct — 61 of edition 6's 380 matches have no
  score, and ~27% of goal events have no `player_id`.
- **Own goals are excluded from top scorers** (design principle 5). An own goal
  is credited to the opposing team and is never a goal *scored by* the player.
  Six players in edition 6 alone would be wrongly credited otherwise.
- **Both endpoints return a `coverage` block** reporting what the underlying data
  does and does not contain, so the UI can caveat a thin table instead of
  presenting it as authoritative (design principle 6).
- **Participating teams come from `matches`**, because `competition_edition_teams`
  is empty for every migrated edition.
- Standings and top scorers are raw SQL in `services/` (the aggregate-query
  carve-out in the repo conventions); the match list goes through Prisma.

- **Passwords use scrypt from `node:crypto`** — memory-hard, built in, so the
  auth path has no native module and no third-party hashing dependency.
- **Auth re-reads the account on every request** rather than trusting the token
  alone, so deactivating an admin takes effect immediately.
- **Login is deliberately uniform**: unknown email, wrong password and
  deactivated account all return the same 401, and the unknown-email path still
  spends the hashing time so it is not detectably faster.
- **Every admin write records `manual_admin` provenance in the same
  transaction** as the write (principle 1). It records which *source*, not which
  *admin* — per-admin attribution needs an audit table that doesn't exist yet.
- **Adding an event never changes the stored score**, and vice versa. The legacy
  event log is too partial to derive from safely.
- **`.default()` belongs on create schemas only.** A zod `.default()` survives
  `.partial()` and will silently reset a field on any PATCH that omits it —
  that bug reset match statuses to SCHEDULED before it was caught.

## Live-score sync (priority 5)

Not usable until `API_FOOTBALL_KEY` is set — everything else works without it.

```bash
npm run seed:sources          # one-off: ensure data_sources rows exist
npm run af:coverage           # what does API-Football actually cover?
npm run af:map -- --league <apiLeagueId> --season 2025 --edition <vaultEditionId>
npm run af:map -- ... --apply # write the mappings
npm run af:sync               # one sync pass, prints a summary
```

Once editions are mapped, the server runs the sync on `LIVE_SYNC_CRON`
(default every 2 minutes), asking only for fixtures currently in play.

### The rules the sync implements, and why

Design principle 2 forbids silently overwriting canonical data **with a new
source**. That is not the same as forbidding the API from updating a value it
wrote itself a minute ago — which is the entire point of a live score. So:

| Vault state | API says | Result |
|---|---|---|
| no match | anything | create it, with provenance |
| no score yet | 2–1 | fill it — absent is not canonical |
| 2–1, only source is the API | 3–1 | update it — same source advancing |
| 2–1 from any source | 2–1 | agree; touch `last_synced_at` only |
| 2–1 from legacy or a human | 1–1 | **`reconciliation_diffs` row; vault untouched** |
| unmapped team or competition | anything | skip and report — never guess |

`npm test` covers every row of that table against the real schema, using
synthetic fixtures, so no API key is needed to verify the logic.

### Own goals

The score is read from the API's published `fixture.goals`, never reconstructed
from the event log — so own-goal attribution (principle 5) cannot be got wrong
on the sync path. `verifyEventsAgainstScore()` exists to *test* the assumption
that an `Own Goal` event's `team` is the scoring player's own team; it is not
wired into the sync. **Run it against real fixtures before building any event
ingestion on top of that assumption** — it is unverified, and it is the exact
bug that bit the legacy migration.

### Mapping is a prerequisite

The migrated vault knows nothing about API-Football, so nothing syncs until
`af:map` links vault teams and editions to API ids (stored in
`entity_source_map`, so the mapping doubles as provenance). Team matching only
ever proposes exact post-normalisation name matches; ambiguous ones are listed
for a human rather than guessed, because a wrong team mapping corrupts scores on
every subsequent sync.

## Management API (admin dashboard)

Create/read/update/delete for the vault's reference entities and for admin
accounts, in `src/routes/adminManage.ts`. Every create and update records
`manual_admin` provenance in the same transaction.

| Method | Path | Notes |
|---|---|---|
| GET/POST | `/api/admin/players` | `?q=`, `?teamId=`, `?page=`, `?pageSize=` |
| GET/PATCH/DELETE | `/api/admin/players/:id` | GET includes `usage` — what depends on the player |
| GET/POST | `/api/admin/teams` | `?q=`, `?type=CLUB\|NATIONAL`, paging |
| GET/PATCH/DELETE | `/api/admin/teams/:id` | GET includes `usage` |
| PATCH/DELETE | `/api/admin/competitions/:id` | create stays `POST /api/admin/competitions` |
| POST | `/api/admin/competitions/:id/editions` | `seasonId`, `format`, `numTeams`; always created unpublished |
| PATCH/DELETE | `/api/admin/editions/:id` | the season itself is not editable — delete and recreate |
| GET/POST | `/api/admin/editions/:id/participants` | GET also lists teams with matches but no participant row |
| PATCH/DELETE | `/api/admin/editions/:id/participants/:teamId` | PATCH sets `groupId` |
| GET/POST | `/api/admin/seasons` | label `2025/2026` or `2025` |
| PATCH/DELETE | `/api/admin/seasons/:id` | |
| GET/POST | `/api/admin/admins` | GET also returns `currentAdminId` |
| PATCH | `/api/admin/admins/:id` | `displayName`, `isActive` |
| POST | `/api/admin/admins/:id/password` | set someone else's password; your own goes through `/me/password` |
| GET | `/api/admin/players/:id/career` | club status, club and international spells, overlaps and stale open spells flagged |
| POST | `/api/admin/players/:id/transfers` | `toTeamId` (null = release), `date`, `type`, `loanUntil`, `fee`, `shirtNumber` |
| POST | `/api/admin/players/:id/spells` | add a past spell directly; refused if it overlaps another club contract |
| PATCH/DELETE | `/api/admin/spells/:id` | correct or remove a spell |
| GET | `/api/admin/transfers` | every move read off the spells: `?kind=MOVES\|ALL\|TRANSFER\|LOAN\|RELEASE\|FIRST_CLUB`, `teamId`, `q`, `from`, `to`, paging; plus counts and a summary |
| PATCH | `/api/admin/transfers` | `kind`, `spellId`, and `date`/`type`/`fee`/`shirtNumber`; a transfer's date moves the old spell's end with it when they touch |
| POST | `/api/admin/transfers/undo` | `kind`, `spellId`; removes the arrival and reopens the old spell when nothing later depends on it |
| GET | `/api/admin/teams/:id/squad` | spells running today, newest signing first, plus former players |
| POST | `/api/admin/audit/runs` | `competitionIds`, `editionIds` (a union; neither = whole vault), `includeCareers`; runs synchronously, 409 if one is running |
| GET | `/api/admin/audit/runs` | recent runs with named scope and new/reopened/resolved counts |
| GET | `/api/admin/audit/findings` | `status=ACTIVE\|OPEN\|FIXED\|ACCEPTED\|RESOLVED\|ALL`, `severity`, `checkKey`, `area`, `competitionId`, `editionId`, paging; counts per status, severity and check |
| POST | `/api/admin/audit/findings/:id/review` | `decision` FIXED / ACCEPTED (note required) / OPEN |
| POST | `/api/admin/audit/findings/review-bulk` | same filter + `decision` + `expectedCount`; open findings only, 409 if the count moved |
| POST | `/api/admin/audit/findings/:id/escalate` | raises a BLOCKER `data_flags` row for the finding's record |
| GET | `/api/admin/audit/checks` | the 23 checks, with area, severity and description |
| GET | `/api/admin/lookups` | countries, seasons, stadiums, competitions, types, formats |
| GET | `/api/admin/team-options` | every team, name only, `?type=` |

Rules worth knowing before calling these:

- **A delete never cascades through match history.** It answers 409 and names
  what depends on the row ("Azam FC can't be deleted: it has 562 matches, …").
  Only a row nothing references can be deleted, and its provenance goes with it.
  An edition must also be unpublished first; deleting one removes its groups
  and participant list, which describe nothing once it has no matches.
- **Admins are deactivated, never deleted.** `competition_editions.published_by`
  and `data_flags.created_by` point at them. Nobody can deactivate themselves,
  and the last active admin cannot be deactivated at all.
- **There are no roles.** Every active admin can manage every account, matching
  the single `admins` table. Roles would need a schema change.
- **Careers follow the vault's own conventions** (`services/careers.ts`, unit
  tested): a move ends the old spell on the day the new one starts, so touching
  spells don't overlap; national-team spells are a separate career that no
  transfer ever ends; a loan runs inside its parent spell and can't outlive it.
  A permanent move or release ends every club spell running on the date.
  There is no transfers table: `movesOf` reads moves off the spells — an
  arrival from the spell that ended most recently before it (TRANSFER), from
  nowhere on record (FIRST_CLUB), on loan from a running parent (LOAN), or a
  contract that ended with nothing after it (RELEASE). The
  API refuses a move the recorded history contradicts rather than guessing.
  `POST /players` takes an optional `club` (`teamId`, `startDate`, `type`,
  `shirtNumber`) — omit it for a free agent. Deleting a player takes their
  spells with them; only match history blocks it.
- Unique-constraint clashes (a duplicate season label, a team already in an
  edition, an email already registered) come back as 409 with a readable
  message, not a 500.

## Editorial API (admin dashboard)

| Method | Path | Notes |
|---|---|---|
| GET | `/api/admin/editions` | every edition with flags, issues and publish state |
| POST | `/api/admin/editions/:id/publish` | 409 if open BLOCKER flags exist |
| POST | `/api/admin/editions/:id/unpublish` | |
| GET | `/api/admin/matches` | `needsAttention=true` filters to completed-with-no-score |
| GET | `/api/admin/matches/:id` | match with full event log and open flags |
| GET/POST | `/api/admin/flags` | `?status=`, `?editionId=` scopes to an edition and its contents |
| POST | `/api/admin/flags/:id/resolve` | optional resolution note |

The public `/api/vault/*` routes now return **only published editions**; an
unpublished one is a 404, not a 403. `is_published` defaults to false, so
migrating new data never exposes it before review.

`npm test` covers the gating rules — a blocker refusing publication, a blocker on
a match blocking its edition, warnings staying advisory.

## Not done yet

Priority 6 (Socket.io). `src/sockets/` is an empty placeholder. No team or
player editor screens (the endpoints exist, the UI doesn't).
