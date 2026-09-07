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
| POST/PATCH | `/api/admin/teams[/:id]` | |
| POST/PATCH | `/api/admin/players[/:id]` | |
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
