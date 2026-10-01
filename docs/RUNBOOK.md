# Runbook

How to keep Sokabrain running and its data current. Every write command here
**dry-runs by default** and needs `--apply` or `--commit` to change anything.
Read the dry-run report before applying it; that report is the safety net.

Python commands run from `docs/ingestion/` with the venv
(`../../.venv/bin/python`, see the root README). npm commands run from
`backend/`.

## Leagues at a glance

| League | SportMonks id | Vault competition | Scores from | Goal events from |
|---|---|---|---|---|
| Tanzania Premier League | 884 | 1 | live sync, plus ligikuu | ligikuu, then FotMob to fill gaps. **Not** SportMonks. |
| South Africa Premier League | 806 | 127 | live sync | `sm:events` |
| Rwanda National Soccer League | 872 | 126 | live sync | `sm:events` |
| Uganda Premier League | 1423 | 128 | live sync | `sm:events` |
| Kenya Premier League | 848 | 17 | live sync | none: the provider has no events for it |
| Africa Cup of Nations | — | 16 | finished history | finished history |

## Weekly: keep current seasons current

**Not automated yet.** Somebody has to do this, or new matches will show a result
with an empty timeline.

### 1. Scores (automatic while the backend runs)

The backend polls SportMonks' in-play feed every 2 minutes (`LIVE_SYNC_CRON`) when
`SPORTMONKS_TOKEN` is set. It writes scores, status and kickoffs, never events.

If the backend was down while matches finished, catch up league by league:

```sh
npm run sm:sync -- --league 884 --dry     # see what would change
npm run sm:sync -- --league 884
```

### 2. Goal events, SportMonks leagues (806, 872, 1423)

```sh
npm run sm:events -- --league 806          # dry run: per-match report
npm run sm:events -- --league 806 --apply
```

It is safe to re-run. It never adds to a match that already has goal events,
refuses a match whose events don't add up to its score, and writes a scorer it
can't resolve to a full name as unattributed. To name abbreviated scorers from
the league's own player directory afterwards, use
`topup_scorers_from_directory.py --source <upl|rwandapremierleague>`. Its
docstring explains how.

### 3. Tanzania: results and events from the official site

```sh
python3 fetch_ligikuu.py raw/ligikuu
python3 normalize_ligikuu.py raw/ligikuu canon_ligikuu.json
python3 update_season_results.py canon_ligikuu.json 2026/2027            # dry run
python3 update_season_results.py canon_ligikuu.json 2026/2027 --commit
```

ligikuu's goal list sometimes doesn't add up to the score. When it doesn't, the
script writes the score and skips the events. Those matches can be completed
from FotMob (`docs/ingestion/FOTMOB_TPL.md`), which needs a browser harvest.
Before committing, cross-check the results against FotMob's fixture list; it
takes one page load.

### 4. Save the snapshot

```sh
./scripts/dump_db.sh
git add docs/migration/sokabrain_vault_snapshot.sql && git commit -m "Refresh vault snapshot"
```

**Skip this and the next restore silently rolls the vault back.** Do it after any
data change, including fixes and publishing.

## Monthly: run the data audit

In the console, go to `/admin/audit`, run it over the vault, and work the open
findings. Each finding's **Fix** button opens the record it is about. Findings
are advisory. To block publishing on one, escalate it to a BLOCKER flag.

## A new season starts

For a SportMonks league:

```sh
npm run sm:ingest -- --league 872                  # dry run: clubs, fixtures, near-miss warnings
npm run sm:ingest -- --league 872 --apply
npm run sm:compare -- --league 872                 # writes nothing; checks scores, rounds, events
```

`sm:ingest` reuses the existing competition and clubs, and writes the mapping
rows the live sync needs. **Read its NEAR MISS lines.** A club it is about to
create that resembles an existing one is usually a duplicate or a rename. Check
`docs/ingestion/teamnames.py`, add an alias in `backend/src/config/teamAliases.ts`
if needed, and run it again.

Tanzania's fixtures have historically come from ligikuu through `load.py` (see
`docs/ingestion/README.md`), with rounds from FotMob through
`load_rounds_fotmob.py`. Then link the provider with
`npm run sm:map -- --league 884 --apply`.

New editions are **unpublished** until someone publishes them.

## Publish or unpublish a season

In the console: Competitions, pick the season, then the publish toggle. Or in
bulk:

```sh
npm run editions:publish -- --ids 404,405          # dry run: prints what each holds
npm run editions:publish -- --ids 404,405 --apply
npm run editions:publish -- --ids 407 --unpublish --apply
```

An edition with an open BLOCKER flag is refused. Don't publish a season that
holds nothing; the dry run shows its contents first.

## Fix a data error

1. Write the change as a dated SQL file in `docs/reconciliation/fixes/`, e.g.
   `2026-10-14_short_description.sql`. Put a comment at the top saying what was
   wrong, what evidence settled it, and the statement that reverses it. Look at
   any existing file there for the pattern.
2. Apply it in a transaction: `psql sokabrain -v ON_ERROR_STOP=1 -1 -f <file>`.
3. Re-run the audit for the affected season, then `./scripts/dump_db.sh`.

Small one-off corrections can go through the console instead, which records
provenance and asks for confirmation.

**Don't delete history to make a number look right**, and don't invent goals,
names or stats. If the source doesn't have it, the vault doesn't either.
`docs/OPEN_DECISIONS.md` lists calls that need an editor.

## Admin accounts

- **Create:** `ADMIN_PASSWORD='12+ chars' npm run admin:create -- --email … --name "…"`.
  Running it again for the same email resets the password.
- **Add, revoke or restore** other admins in the console at `/admin/access`.
  Admins are deactivated, never deleted. Nobody can deactivate themselves or the
  last active admin.
- There are no roles. Every active admin can manage access and publish.

## Kijiweni moderation

The console's Kijiweni section lets you hide or restore threads and comments
(reversible) or delete them (this cascades to comments and likes). Posting is
anonymous, so rate limits (next section) cap how fast spam can arrive. They
don't stop it, so keep an eye on the console.

## Kijiweni rate limits

`backend/src/routes/kijiweniLimits.ts` sets the numbers:

| Action | Per client | Site-wide |
|---|---|---|
| New thread | 5 per hour | 100 per hour |
| Comment | 20 per 10 minutes | 600 per hour |
| Like (threads and comments together) | 60 per minute | none |

A blocked request gets a 429 with a JSON `error` and a `Retry-After` header.
Counts are kept in memory, so they reset when the backend restarts, and each
backend process counts separately.

**Per client means per IP address, and that needs `TRUST_PROXY` set right.**
The website's `/api/kijiweni` requests go through the web server's rewrite
(`web/next.config.ts`), so the backend sees the web server's address on every
web post. The rewrite also passes on any `X-Forwarded-For` the browser sent,
real or fake. That leaves two ways to get it wrong:

- `TRUST_PROXY=false` (the default) while web traffic goes through the rewrite:
  every web fan shares one budget, so 5 threads an hour for the whole website.
  The backend logs a warning the first time a local address is limited.
- Trusting the web server while nothing in front of it overwrites
  `X-Forwarded-For`: anyone can fake a new address on every request and dodge
  the per-client limit. The site-wide limits still hold.

The safe setup puts a proxy (nginx, or the hosting platform's load balancer) in
front of the web server that **overwrites** `X-Forwarded-For` with the
connecting address (nginx: `proxy_set_header X-Forwarded-For $remote_addr;`).
Then set `TRUST_PROXY` on the backend to the addresses its traffic arrives from:
`loopback` when the web server runs on the same machine, or the proxy's
addresses or subnet otherwise. The mobile app calls the backend directly, so its
fans' addresses are read from the connection and can't be faked unless their
traffic also comes through a trusted address. `TRUST_PROXY=true` is refused at
startup.

Mobile carriers put many fans behind one address, so if real fans hit the
per-client limits, raise those numbers before anything else.

## Changing the schema

In the same commit:

1. Apply the change to the database.
2. Update `docs/schema/sokabrain_schema_ddl.sql` and add the reasoning to
   `docs/schema/sokabrain_vault_schema_v1.md`.
3. Run `npm run db:pull && npm run db:generate` in `backend/`. Never hand-edit
   `schema.prisma` to differ from the database.
4. Run `./scripts/dump_db.sh`.

To confirm the DDL still matches, load it into a scratch database and diff
`information_schema.columns` against the live one.

## Secrets and accounts

| Secret | Where | Notes |
|---|---|---|
| `DATABASE_URL` | `backend/.env`, and the environment for Python scripts | |
| `JWT_SECRET` | `backend/.env` | Rotating it signs every admin out (tokens last 12h) |
| `SPORTMONKS_TOKEN` | `backend/.env` | Paid plan covering the five leagues above. Without it, live sync is off and everything else works. |
| `API_FOOTBALL_KEY` | `backend/.env` | Unused fallback; never validated |

Never commit `.env`. `dump_db.sh` scrubs admin password hashes from the snapshot
and fails if any survive.

## Backup and restore

The committed snapshot is the backup. `./scripts/restore_db.sh` rebuilds
from it (`FORCE=1` replaces, `TARGET_URL=…` restores elsewhere). Afterwards,
recreate admin accounts with `admin:create`, because credentials are not in the
snapshot.
