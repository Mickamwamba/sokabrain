# Deployment guide

How to put Sokabrain on the internet and keep its SportMonks data flowing
without anyone at a laptop. Read `docs/ARCHITECTURE.md` first if you haven't;
this guide assumes you know what the backend, web app and live sync are.

Written 2026-10-01. Nothing has been deployed yet: until now the vault has lived
on one laptop. Every step below is new.

## The shape we recommend

```mermaid
flowchart LR
  F[Fans and admins<br/>browser] -- https://sokabrain.example --> N
  APP[Flutter app] -- https://api.sokabrain.example --> N
  subgraph S[One Linux server]
    N[nginx :443<br/>TLS, X-Forwarded-For]
    W[web: Next.js<br/>127.0.0.1:3100]
    B[backend: Express<br/>127.0.0.1:4010<br/>+ live-score cron]
    C[crontab<br/>nightly catch-up<br/>weekly events report<br/>weekly snapshot]
    N --> W
    N --> B
    W --> B
  end
  B --> DB[(Managed PostgreSQL 16)]
  C --> DB
  B --> SM[SportMonks]
  C --> SM
```

- **One small Linux server** (Ubuntu 24.04, 2 GB RAM is plenty) runs nginx, the
  backend and the web app as systemd services, plus the scheduled data jobs in
  crontab.
- **A managed Postgres 16** holds the vault and gives you automatic backups.
- **Two hostnames.** The site at `sokabrain.example`, and the API at
  `api.sokabrain.example`, which the mobile app needs because it calls the
  backend directly.

Why a server rather than a serverless platform: the backend has to run as
**exactly one long-lived process**. The live-score cron, its overlap guard and
Kijiweni's rate-limit counters all live in memory. The scheduled jobs also need
the repo, Node and the backend's `.env` on a machine that's always on. A single
server gives you all of that most simply. Two alternatives are covered near the end,
and the same rules apply to both: running the same server with Docker
("Alternative: deploying with Docker"), and a platform such as Railway or
Render ("Deploying to a platform instead").

Replace `sokabrain.example` everywhere below with your real domain.

## Before you start

| You need | Notes |
|---|---|
| A domain | With DNS you control, for the two hostnames above. |
| A Linux server | Ubuntu 24.04 LTS, SSH access, ports 80 and 443 open. |
| A Postgres 16 database | Managed. Get the **direct** (non-pooled) connection string. |
| The SportMonks token | Paid plan covering leagues 884, 806, 872, 1423 and 848. The account still belongs to the original author: transfer it or issue a new token first. |
| GitHub access | To clone `Mickamwamba/sokabrain` onto the server. |

## Step 1: the database

**1.1 Create it.** Create a Postgres **16** database named `sokabrain` with your
provider. Copy the direct connection string. Most providers need
`?sslmode=require` on the end:

```
postgresql://USER:PASSWORD@HOST:5432/sokabrain?sslmode=require
```

Use the direct connection, not the pooled one (Neon labels it "pooled
connection", Supabase "transaction pooler"). The backend pins every session to
UTC with a `timezone` startup option, and poolers often reject startup options.
If the timezone pin is lost, every kickoff time shifts silently.

**1.2 Set the database's default timezone to UTC as well,** as a second guard
for anything that connects without the pin:

```sh
psql "$PROD_DATABASE_URL" -c "ALTER DATABASE sokabrain SET timezone TO 'UTC';"
```

**1.3 Load the vault.** From a checkout of the repo with the latest snapshot
(`git pull` first), on any machine with `psql` 16:

```sh
TARGET_URL="$PROD_DATABASE_URL" ./scripts/restore_db.sh
```

It restores in a single transaction and prints row counts at the end. Expect
about 6,984 rows in `matches` and 12,543 in `match_events` (on 2026-10-01; the
numbers grow as data is added).

**1.4 Check the timezone survives.** A kickoff should read the same either way:

```sh
psql "$PROD_DATABASE_URL" -c "SELECT kickoff_at, extract(epoch FROM kickoff_at) FROM matches ORDER BY id DESC LIMIT 3;"
```

Compare with the same query against your local vault. You'll repeat this
through the API in step 3.

## Step 2: the server

As root (or with sudo) on a fresh Ubuntu 24.04 server:

```sh
# Node 22
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

# nginx, TLS certificates, git, and the Postgres 16 client tools (for dump_db.sh)
apt-get install -y nginx certbot python3-certbot-nginx git postgresql-common
/usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y
apt-get install -y postgresql-client-16

# A user to run everything as, and the checkout
useradd --system --create-home --home-dir /srv/sokabrain --shell /bin/bash sokabrain
sudo -u sokabrain git clone git@github.com:Mickamwamba/sokabrain.git /srv/sokabrain/app
```

The clone needs a deploy key or a token with read access to the repo.

Everything from here runs as the `sokabrain` user unless it says otherwise
(`sudo -iu sokabrain`).

## Step 3: the backend

**3.1 Configure it.** Create `/srv/sokabrain/app/backend/.env` and make it
readable only by its owner (`chmod 600`):

```sh
NODE_ENV=production
PORT=4010
DATABASE_URL=postgresql://USER:PASSWORD@HOST:5432/sokabrain?sslmode=require

# openssl rand -hex 32. Admin login is unavailable without it.
JWT_SECRET=<64 hex characters>

# Live-score sync
SPORTMONKS_TOKEN=<token>
LIVE_SYNC_ENABLED=true
LIVE_SYNC_CRON=*/2 * * * *

# nginx runs on this machine and overwrites X-Forwarded-For (step 5),
# so trust exactly the loopback address. Never "true".
TRUST_PROXY=loopback
```

Leave `API_FOOTBALL_KEY` unset. SportMonks wins when both are set anyway, and
API-Football has never been validated.

**3.2 Build it.**

```sh
cd /srv/sokabrain/app/backend
npm ci                # includes dev dependencies, which you need: see below
npm run db:generate   # the Prisma client is generated, not committed
npm run build         # TypeScript -> dist/
```

Install with plain `npm ci`, not `npm ci --omit=dev`. The `sm:*`,
`editions:*` and `admin:*` scripts the scheduled jobs use run through `tsx`, and
`db:generate` needs the `prisma` CLI. Both are dev dependencies.

**3.3 Create the admin accounts.** The snapshot carries no usable credentials.
Create one account per person; never share one:

```sh
ADMIN_PASSWORD='at-least-12-characters' npm run admin:create -- --email them@example.com --name "Their Name"
```

After that, admins can add and remove each other at `/admin/access`.

**3.4 Run it under systemd.** As root, create
`/etc/systemd/system/sokabrain-api.service`:

```ini
[Unit]
Description=Sokabrain API (Express) and live-score sync
After=network-online.target
Wants=network-online.target

[Service]
User=sokabrain
WorkingDirectory=/srv/sokabrain/app/backend
ExecStart=/usr/bin/node dist/index.js
Restart=always
RestartSec=5
# SIGTERM lets the server stop the cron and close the DB cleanly.
KillSignal=SIGTERM
TimeoutStopSec=20

[Install]
WantedBy=multi-user.target
```

The backend loads `.env` from its working directory itself, so the unit doesn't
need an `EnvironmentFile`.

```sh
systemctl daemon-reload
systemctl enable --now sokabrain-api
journalctl -u sokabrain-api -n 20
```

The log should show `sokabrain api listening on http://localhost:4010` and
`[live-sync] scheduled (*/2 * * * *), provider sportmonks`.

**3.5 Check it.**

```sh
curl -s localhost:4010/health                      # {"status":"ok","database":"connected"}
curl -s localhost:4010/api/vault/editions | head -c 300
```

Open a recent match through the API (`/api/vault/matches/<id>`) and check its
kickoff time matches the local vault. This is the real test of the UTC pin.

## Step 4: the web app

**4.1 Configure it.** Create `/srv/sokabrain/app/web/.env.production`:

```sh
NODE_ENV=production
# Where the web server reaches the backend: the same machine, over loopback.
API_URL=http://127.0.0.1:4010
```

**4.2 Build it.**

```sh
cd /srv/sokabrain/app/web
npm ci
npm run build
```

`API_URL` has to be right **at build time**. Next.js bakes the `/api/vault` and
`/api/kijiweni` rewrite destinations into the build, so changing `API_URL`
later means rebuilding the web app, not just restarting it.

**4.3 Run it under systemd.** As root, create
`/etc/systemd/system/sokabrain-web.service`:

```ini
[Unit]
Description=Sokabrain web (Next.js)
After=network-online.target sokabrain-api.service

[Service]
User=sokabrain
WorkingDirectory=/srv/sokabrain/app/web
Environment=NODE_ENV=production
Environment=API_URL=http://127.0.0.1:4010
ExecStart=/usr/bin/npx next start -p 3100 -H 127.0.0.1
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```sh
systemctl daemon-reload
systemctl enable --now sokabrain-web
curl -sI localhost:3100 | head -1                  # HTTP/1.1 200 OK
```

## Step 5: nginx and HTTPS

Point both hostnames' DNS A records at the server. Then, as root, create
`/etc/nginx/sites-available/sokabrain`:

```nginx
# The public site and admin console
server {
    listen 80;
    server_name sokabrain.example;

    location / {
        proxy_pass http://127.0.0.1:3100;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
        # OVERWRITE, never append. Kijiweni's per-client rate limit depends on it.
        proxy_set_header X-Forwarded-For $remote_addr;
        # For Socket.io later
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

# The API, for the mobile app
server {
    listen 80;
    server_name api.sokabrain.example;

    location / {
        proxy_pass http://127.0.0.1:4010;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

```sh
ln -s /etc/nginx/sites-available/sokabrain /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
certbot --nginx -d sokabrain.example -d api.sokabrain.example
```

Certbot adds the HTTPS blocks and the redirect from HTTP, and renews the
certificates itself.

**Why the `X-Forwarded-For` line matters.** nginx replaces whatever the client
sent with the real connecting address. The backend trusts that header only from
loopback (`TRUST_PROXY=loopback`), so each fan gets their own rate-limit budget
and nobody can fake a new address. If you put another proxy or CDN in front of
nginx, `docs/RUNBOOK.md` ("Kijiweni rate limits") explains how to adjust.

**Firewall.** Only 22, 80 and 443 should be reachable. Ports 3100 and 4010 are
bound to 127.0.0.1 or sit behind nginx; `ufw allow OpenSSH && ufw allow 'Nginx
Full' && ufw enable` keeps it that way.

Now check `https://sokabrain.example`, sign in at `https://sokabrain.example/admin`,
and check `https://api.sokabrain.example/health`.

## Step 6: the SportMonks sync jobs

There are four SportMonks jobs. One runs inside the backend; two go in crontab;
one stays manual on purpose.

| Job | What it writes | How it runs | When |
|---|---|---|---|
| Live scores | Scores, status, kickoffs of fixtures in play | Inside the backend (node-cron) | Every 2 minutes, automatically |
| Results catch-up | Scores and status for a whole season, picking up anything the live sync missed | crontab: `sm:sync --league <id>` | Nightly |
| Goal events report | Nothing: a dry run listing what would load | crontab: `sm:events --league <id>` | Weekly |
| Goal events apply | Goal events and new players | A person runs `sm:events --apply` after reading the report | Weekly |

### 6.1 Check the prerequisites

The live sync only touches editions mapped to SportMonks in
`entity_source_map`. On 2026-10-01 all five current seasons are mapped:

| Vault edition | League | SportMonks key (`league:season`) |
|---|---|---|
| 129 | Tanzania Premier League 2026/27 | `884:28598` |
| 404 | Rwanda National Soccer League 2026/27 | `872:28542` |
| 405 | South Africa Premier League 2026/27 | `806:28123` |
| 406 | Uganda Premier League 2026/27 | `1423:28106` |
| 407 | Kenya Premier League 2026/27 | `848:28439` |

To check the list on the production database at any time:

```sql
SELECT esm.external_id, ce.id AS edition, c.name, s.label
FROM entity_source_map esm
JOIN data_sources ds ON ds.id = esm.data_source_id AND ds.name = 'sportmonks'
JOIN competition_editions ce ON ce.id = esm.entity_id
JOIN competitions c ON c.id = ce.competition_id
JOIN seasons s ON s.id = ce.season_id
WHERE esm.entity_type = 'competition_edition'
ORDER BY s.label DESC, ce.id;
```

And check the token and plan from the server:

```sh
cd /srv/sokabrain/app/backend && npm run sm:coverage
```

### 6.2 Job 1: live scores (already running)

Nothing to schedule: the backend started it in step 3 because
`SPORTMONKS_TOKEN` is set. Each tick makes one request to SportMonks' in-play
feed, however many leagues are playing. At every 2 minutes that's 30 requests an
hour against the plan's 2,000-an-hour limit.

To watch it during a matchday:

```sh
journalctl -u sokabrain-api -f | grep live-sync
```

A tick with matches in play logs a line like
`[live-sync:sportmonks] 3 live fixture(s): 0 created, 2 updated, 1 unchanged, 0 conflict(s), …`.
Quiet ticks log nothing. Other lines to know:

| Log line | Meaning | Action |
|---|---|---|
| `N match(es) disagree with existing vault data` | SportMonks contradicts a score from another source. Recorded in `reconciliation_diffs`, not applied. | Settle it in the console. |
| `skipped fixture …: <reason>` | A team or edition isn't mapped. | Usually a new club or season: see "A new season starts" in the runbook. |
| `provider error: …` | Auth, plan or rate-limit problem from SportMonks. | Check the token and the plan. |
| `previous run still in progress` | A tick took over 2 minutes. | Fine once; investigate if it repeats. |

To change the schedule, set `LIVE_SYNC_CRON` in `.env` and restart the service.
To stop the sync without removing the token, set `LIVE_SYNC_ENABLED=false`.

### 6.3 Job 2: nightly results catch-up

The live sync only sees fixtures while they're in play. If the backend was down
or restarting while a match finished, that result never arrives. The catch-up
walks every fixture of each league's current season and fills in what's
missing. It follows the same rules as the live sync: scores and status only, no
events, and a disagreement with another source becomes a `reconciliation_diffs`
row instead of an overwrite. Safe to run every night.

Create `/srv/sokabrain/bin/sm-catchup.sh` as the `sokabrain` user:

```sh
#!/usr/bin/env bash
# Nightly SportMonks results catch-up for every league the live sync covers.
# One league failing doesn't stop the others; the script exits non-zero if any did.
set -uo pipefail
cd /srv/sokabrain/app/backend

status=0
for league in 884 806 872 1423 848; do
  echo "=== $(date -u +%FT%TZ) league $league"
  npm run --silent sm:sync -- --league "$league" || status=1
done
exit $status
```

```sh
chmod +x /srv/sokabrain/bin/sm-catchup.sh
mkdir -p /srv/sokabrain/logs
/srv/sokabrain/bin/sm-catchup.sh          # run it once by hand and read the output
```

Each league prints a JSON summary: `updated`, `agreed`, `conflicts`, `skipped`.
A first run after a long gap may update a lot; after that, most nights should
show almost everything as `agreed`.

Each league costs a few requests (league list plus the season's fixtures), so
the whole run stays well inside the hourly limit.

### 6.4 Job 3: weekly goal-events report

`sm:events` is the only code that writes goal events from SportMonks, and only
for **South Africa (806), Rwanda (872) and Uganda (1423)**. Tanzania's events
come from ligikuu (runbook, "Weekly", step 3), and SportMonks has none for
Kenya.

**Schedule the dry run, not the apply.** The runbook's rule is that a person
reads the dry-run report before anything is written. `sm:events --apply` creates
player records, and a wrongly created player is the identity problem this
project has spent the most time undoing. The script has strong guards (no
abbreviated names, refuses matches whose events don't reproduce the score,
never adds to a match that already has events). But nobody would see a bad name
until a fan did. So cron produces the report, and a person applies it.

Create `/srv/sokabrain/bin/sm-events-report.sh`:

```sh
#!/usr/bin/env bash
# Weekly dry run of the SportMonks goal-event loader. Writes nothing.
set -uo pipefail
cd /srv/sokabrain/app/backend

status=0
for league in 806 872 1423; do
  echo "=== $(date -u +%FT%TZ) league $league (dry run)"
  npm run --silent sm:events -- --league "$league" || status=1
done
exit $status
```

Then, each week, an editor reads the latest report in
`/srv/sokabrain/logs/sm-events-report.log` and, for each league whose report
looks right:

```sh
cd /srv/sokabrain/app/backend
npm run sm:events -- --league 806 --apply
```

If after a few months of reports the apply step has never needed a human
decision, the team can choose to add `--apply` to the script. Make that a
deliberate decision, write it down in `docs/RUNBOOK.md`, and keep reading the
logs.

### 6.5 Job 4: a new season (manual, never scheduled)

When a league starts a new season, SportMonks gives it a new season id. Until it
is ingested and mapped, the live sync skips its fixtures and logs why. Run
`sm:ingest` (and read its near-miss warnings) as described in the runbook, "A new
season starts". The catch-up and events scripts above pick up the new season by
themselves, because they ask SportMonks for each league's current season.

### 6.6 The crontab

As the `sokabrain` user, `crontab -e`:

```cron
# All times UTC. Results are settled by 03:00 UTC (06:00 East Africa).
CRON_TZ=UTC
SHELL=/bin/bash
PATH=/usr/local/bin:/usr/bin:/bin
# Cron mails a job's output when it fails, if the server can send mail.
MAILTO=data-team@sokabrain.example

# Nightly results catch-up. flock stops a slow run overlapping the next.
0 3 * * *   flock -n /tmp/sm-catchup.lock /srv/sokabrain/bin/sm-catchup.sh >> /srv/sokabrain/logs/sm-catchup.log 2>&1 || echo "sm-catchup failed, see /srv/sokabrain/logs/sm-catchup.log"

# Weekly goal-events report, Monday after the weekend's matches.
0 4 * * 1   flock -n /tmp/sm-events.lock /srv/sokabrain/bin/sm-events-report.sh >> /srv/sokabrain/logs/sm-events-report.log 2>&1 || echo "sm-events report failed, see /srv/sokabrain/logs/sm-events-report.log"

# Weekly snapshot of the production vault (see "Backups" below).
30 4 * * 1  flock -n /tmp/dump.lock /srv/sokabrain/bin/snapshot.sh >> /srv/sokabrain/logs/snapshot.log 2>&1 || echo "snapshot failed, see /srv/sokabrain/logs/snapshot.log"
```

The scripts send their output to the log files. The `|| echo` part prints only
when a job fails, and cron mails anything printed. So you get mail on failures
and nothing on success. The npm scripts exit non-zero on a SportMonks error or a
crash, so failures are visible.

Keep the logs from growing forever with
`/etc/logrotate.d/sokabrain`:

```
/srv/sokabrain/logs/*.log {
    weekly
    rotate 12
    compress
    missingok
    notifempty
}
```

### 6.7 What still isn't automated

- **Tanzania's goal events** come from ligikuu through the Python loaders, and
  gaps are filled from a FotMob browser harvest. That stays manual (runbook,
  "Weekly", step 3). Run the loaders from a machine that has the venv, with
  `DATABASE_URL` pointing at production. Always do the dry run first.
- **Publishing** new seasons, settling `reconciliation_diffs`, and the monthly
  data audit stay editorial work in the console.

## Step 7: the mobile app

Before building a release:

1. Set the production API in `mobile/lib/services/api_service.dart`:
   `static String baseUrl = 'https://api.sokabrain.example';`
2. Remove the `NSAllowsArbitraryLoads` exception from `ios/Runner/Info.plist`. It
   exists only so the app can reach `http://localhost` in development.
3. On Android, make sure cleartext traffic isn't enabled for release builds.
4. Build: `flutter build appbundle` (Play Store) and `flutter build ipa` (App
   Store).

Mobile fans reach the backend through nginx at `api.sokabrain.example`, so their
Kijiweni rate limits are per real address, as on the web.

## Backups, and where the truth lives

### The source of truth moves

Until now, the laptop's database was the vault, and the committed snapshot was
its backup. **Once production is live, the production database is the vault.**
The live sync writes to it every 2 minutes, admins edit it in the console, and a
laptop copy goes stale within hours.

That changes three habits:

- **Do data work against production, not a local copy.** Point the Python loaders,
  `sm:*` scripts and fix files at the production `DATABASE_URL`. They all dry-run
  by default, so read the dry run first, as always. For a fix file:
  `psql "$PROD_DATABASE_URL" -v ON_ERROR_STOP=1 -1 -f <file>`.
- **Never restore a snapshot over production.** It would wipe every score the
  live sync wrote and every console edit since the snapshot. To experiment, do
  it the other way round: restore a production dump to your laptop and work on
  that copy.
- **The snapshot in git becomes a weekly record**, taken from production by the
  job below, rather than something you refresh after every change.

### Backups

1. **Your Postgres provider's automatic backups are the real backup.** Turn on
   daily backups with point-in-time recovery if the plan offers it, and practise
   restoring one into a new database once, before you need to.
2. **A weekly snapshot to git** keeps the repo's copy, which CI and new
   contributors use, reasonably current. `dump_db.sh` accepts a connection
   string as `DB_NAME`, because `pg_dump -d` takes either.

Create `/srv/sokabrain/bin/snapshot.sh`:

```sh
#!/usr/bin/env bash
# Weekly: dump the production vault (credentials scrubbed) and commit it.
set -euo pipefail
cd /srv/sokabrain/app
# Read only DATABASE_URL; sourcing the whole .env breaks on LIVE_SYNC_CRON's spaces.
DATABASE_URL="$(grep -E '^DATABASE_URL=' backend/.env | cut -d= -f2-)"

git pull --ff-only
# dump_db.sh echoes its target; mask the password before it reaches the log.
DB_NAME="$DATABASE_URL" ./scripts/dump_db.sh | sed -E 's#://[^@]*@#://***@#'

if ! git diff --quiet docs/migration/sokabrain_vault_snapshot.sql; then
  git add docs/migration/sokabrain_vault_snapshot.sql
  git commit -m "Refresh vault snapshot from production"
  git push
fi
```

This needs the server's deploy key to have **write** access, and `pg_dump` 16
(installed in step 2) to match the server's major version. If you'd rather not
give the server write access to the repo, run the same two lines from a
maintainer's machine weekly instead.

`dump_db.sh` refuses to write a snapshot that still contains a password hash, so
production credentials can't leak into git through it.

## Deploying a new version

```sh
sudo -iu sokabrain
cd /srv/sokabrain/app && git pull --ff-only

cd backend && npm ci && npm run db:generate && npm run build
cd ../web && npm ci && npm run build
exit

sudo systemctl restart sokabrain-api sokabrain-web
curl -s https://api.sokabrain.example/health
```

The backend restart interrupts the live sync for a few seconds. The nightly
catch-up repairs anything it misses.

**If the release changes the schema,** apply the DDL change to production
*before* restarting, inside a transaction, after taking a fresh backup. The
runbook's "Changing the schema" steps apply unchanged.

## Go-live checklist

- [ ] `https://api.sokabrain.example/health` returns `ok`.
- [ ] A recent match's kickoff time matches the old local vault (UTC pin works).
- [ ] The site loads, and a published season's table and matches look right.
- [ ] Every maintainer can sign in to `/admin` with their own account.
- [ ] `journalctl -u sokabrain-api` shows `[live-sync] scheduled … provider sportmonks`.
- [ ] During a match, the live-sync log shows fixtures, and the score updates on the site.
- [ ] `sm-catchup.sh` and `sm-events-report.sh` have each run once by hand without errors.
- [ ] `crontab -l` shows the three jobs. A deliberate failure (e.g. a bad token in a copy of the script) produces mail.
- [ ] Posting two Kijiweni threads from two different networks shows they're limited separately.
- [ ] The Postgres provider's backups are on, and one restore has been rehearsed.
- [ ] Ports 3100 and 4010 aren't reachable from outside the server.
- [ ] The mobile release build points at `https://api.sokabrain.example`.

## Alternative: deploying with Docker

This runs the same system as steps 2–5, but in containers. Choose it if your
team already runs Docker, wants the server set up from files in the repo
rather than by hand, or wants to move between hosts easily. Choose the systemd
route above if nobody on the team knows Docker; it has fewer moving parts.

What changes and what doesn't:

| | systemd route (steps 2–5) | Docker route |
|---|---|---|
| Backend, web | systemd units running Node on the host | Two containers, built from the repo |
| HTTPS and the proxy | nginx + certbot | Caddy in a container, which gets and renews certificates itself |
| Scheduled jobs | crontab runs `npm run …` in the checkout | crontab runs the same commands inside the backend container with `docker compose exec` |
| Database | Managed Postgres | The same managed Postgres. Step 1 applies unchanged. |
| Node on the host | Required | Not needed. Only Docker. |

The files in D.1 were built and run on 2026-10-01 against a copy of the vault,
with the live sync switched off: both images build, the stack starts with the
backend healthy, and the site, Kijiweni, the `/api/vault` and `/api/kijiweni`
rewrites, the admin login page and `/health` all answer through Caddy. Three things weren't tested:
real TLS certificates, the scheduled jobs inside the container, and Kijiweni's
per-client rate limit behind Caddy. Cover those with the go-live checklist.

### D.1 The files

All six are committed in the repo:

| File | What it does |
|---|---|
| `backend/Dockerfile` | One image runs the API, the live-score cron and the npm scripts the scheduled jobs use. Dev dependencies are installed on purpose: those scripts run through tsx. |
| `backend/.dockerignore` | Keeps `.env`, `node_modules` and local builds out of the image. |
| `web/Dockerfile` | Two-stage build of the public site and admin console. `API_URL` is a build argument because Next.js bakes the `/api/vault` and `/api/kijiweni` rewrite targets into the build. |
| `web/.dockerignore` | The same for the web app. |
| `compose.yml` | Backend, web and Caddy on one host, with exactly one backend replica. The database is managed and outside it. |
| `Caddyfile` | Routes `SITE_DOMAIN` to the web app and `API_DOMAIN` to the backend, and gets the TLS certificates. |

Only Caddy publishes ports. The backend and web are reachable only on the
compose network, under the names `backend` and `web`.

### D.2 Set up the server

On Ubuntu 24.04, install Docker Engine and the compose plugin by following
Docker's own instructions (docs.docker.com/engine/install/ubuntu), then:

```sh
useradd --system --create-home --home-dir /srv/sokabrain --shell /bin/bash --groups docker sokabrain
sudo -u sokabrain git clone git@github.com:Mickamwamba/sokabrain.git /srv/sokabrain/app
```

Point both hostnames' DNS at the server, and open ports 22, 80 and 443.
**Docker bypasses `ufw`** for published ports, so the firewall doesn't protect a
container port you publish by mistake. That's why `compose.yml` publishes only
Caddy's.

Do step 1 (the database) if you haven't. If the server has no `psql`, restore
from a container instead, from the checkout:

```sh
docker run --rm -v "$PWD":/repo:ro -w /repo -e TARGET_URL="$PROD_DATABASE_URL" \
  postgres:16 ./scripts/restore_db.sh
```

### D.3 Configure

**`backend/.env`**: the same contents as in step 3.1, with one change:

```sh
TRUST_PROXY=uniquelocal
```

Traffic reaches the backend from the Caddy and web containers, whose addresses
are on Docker's private network, not loopback. `uniquelocal` trusts exactly the
private ranges (10/8, 172.16/12, 192.168/16), and Caddy has already overwritten
`X-Forwarded-For` with the real client address.

**`.env`** at the repo root, read by compose for the hostnames:

```sh
SITE_DOMAIN=sokabrain.example
API_DOMAIN=api.sokabrain.example
```

Both `.env` files are already ignored by git, and the `.dockerignore` files keep
them out of the images. Secrets reach the backend only at run time, through
`env_file`.

### D.4 Build and start

```sh
cd /srv/sokabrain/app
docker compose up -d --build
docker compose ps                           # backend should say (healthy)
docker compose logs backend | tail -5       # listening…, [live-sync] scheduled…
```

Caddy requests the certificates on first start, which takes a few seconds once
DNS points at the server. Then:

```sh
curl -s https://api.sokabrain.example/health
```

**Create the admin accounts** inside the backend container:

```sh
docker compose exec -e ADMIN_PASSWORD='at-least-12-characters' backend \
  npm run admin:create -- --email them@example.com --name "Their Name"
```

### D.5 Scheduled jobs

The live sync runs inside the backend container, exactly as in 6.2. Watch it
with `docker compose logs -f backend | grep live-sync`.

For the crontab jobs, use the scripts from 6.3 and 6.4, but run each npm
command inside the running backend container, so it uses the container's
environment. `/srv/sokabrain/bin/sm-catchup.sh`:

```sh
#!/usr/bin/env bash
# Nightly SportMonks results catch-up, run inside the backend container.
set -uo pipefail
cd /srv/sokabrain/app

status=0
for league in 884 806 872 1423 848; do
  echo "=== $(date -u +%FT%TZ) league $league"
  docker compose exec -T backend npm run --silent sm:sync -- --league "$league" || status=1
done
exit $status
```

`sm-events-report.sh` changes the same way: `docker compose exec -T backend npm
run --silent sm:events -- --league "$league"`, for 806, 872 and 1423. `-T`
stops compose from asking for a terminal, which cron doesn't have.

The crontab in 6.6 is unchanged, installed for the `sokabrain` user, who can
run `docker` because they're in the `docker` group.

The weekly snapshot (`snapshot.sh`) still runs on the host, because
`dump_db.sh` needs `pg_dump` 16 and `python3`. Install `postgresql-client-16`
as in step 2, or run it from a maintainer's machine.

The editor's weekly apply runs in the container as well:

```sh
docker compose exec backend npm run sm:events -- --league 806 --apply
```

### D.6 Logs

Docker keeps container logs in JSON files that grow without limit by default.
Cap them in `/etc/docker/daemon.json` and restart Docker:

```json
{ "log-driver": "json-file", "log-opts": { "max-size": "20m", "max-file": "5" } }
```

The cron scripts' own logs in `/srv/sokabrain/logs` still need the logrotate rule
from 6.6.

### D.7 Deploying a new version

```sh
cd /srv/sokabrain/app
git pull --ff-only
docker compose up -d --build
docker image prune -f
```

Compose rebuilds and restarts only the services whose files changed. A
backend restart pauses the live sync for a few seconds, and the nightly
catch-up repairs anything missed. Schema changes go to the database first, as
in "Deploying a new version" above.

If `API_DOMAIN` or the backend's internal address ever changes, rebuild the web
image (`docker compose build --no-cache web`). The rewrite targets are baked in
at build time.

### D.8 Running Postgres in compose too (not recommended)

You can add a `postgres:16` service with a named volume and point
`DATABASE_URL` at `postgres://…@db:5432/sokabrain`. The official image already
runs in UTC. But then backups, upgrades and disk space are yours to manage, and
losing the server loses the vault. A managed database costs little at this size
and handles all of that, so keep the database outside compose unless there's a
reason not to.

## Deploying to a platform instead

On Railway, Render, Fly.io or similar, the same pieces map like this:

| Piece | Platform equivalent | Must be true |
|---|---|---|
| Backend | A web service: build `npm ci && npm run db:generate && npm run build`, start `node dist/index.js`, root `backend/` | **Exactly one instance**, with autoscaling off. Health check on `/health`. |
| Web | A web service: build `npm ci && npm run build`, start `npx next start -p $PORT`, root `web/` | `API_URL` set as a **build** variable and a runtime one, pointing at the backend's private address. |
| Catch-up and events report | The platform's cron jobs, running the two scripts' `npm run` commands with the backend's environment | Same environment variables as the backend. They run in a separate container, which is fine: they're separate processes anyway. |
| Weekly snapshot | A cron job on a maintainer's machine, or a CI schedule with a database secret | Needs `pg_dump` 16 and push access. |
| `TRUST_PROXY` | Set to the platform's proxy hop count (often `1`) | Only if the platform's proxy overwrites `X-Forwarded-For`. Check its docs; if unsure, leave it `false` and accept that web fans share a budget. |

Serverless hosting (Vercel and the like) suits the web app but **not the
backend**, which has to stay running for its cron and in-memory counters. If
you put the web app on Vercel, run the backend somewhere long-lived and point
`API_URL` at it.

## Deploying to a shared server (Apache and PM2)

This is the path for the actual staging target: a server that already hosts
other projects, running Apache (not nginx) and PM2 (not systemd), with
PostgreSQL going on the same machine rather than a managed provider. Nothing
below has been run on the real server yet — every command says so as it
goes, and the section ends with a full list of what's untested.

### What differs from the main guide, and why

| Main guide assumes | This server actually has | Why it matters |
|---|---|---|
| A fresh server, ours alone | Five other projects already running | Every step has to avoid touching anything that isn't ours |
| nginx | Apache 2.4 (`prefork` MPM, `mod_proxy`, `mod_proxy_http`, `mod_headers`, `mod_ssl`, `mod_rewrite`, `mod_alias` all already enabled) | Proxying and the `X-Forwarded-For` rule are written in Apache directives, not nginx's |
| systemd units | PM2 7.0.1, running as `root`, started at boot by a `pm2-root.service` systemd unit that runs `pm2 resurrect` | We join the existing PM2 daemon rather than installing our own process manager |
| A managed Postgres 16 | No PostgreSQL at all yet (confirmed: `apt-cache policy postgresql postgresql-16` showed "Installed: (none)") | We install and own Postgres 16 ourselves — see the note on shared-server rules below |
| "2 GB RAM is plenty" | ~1.9 GB total, ~1.08 GB "available" at last check, **0 swap** | The web build alone can plausibly use more than that; it has to run under a hard memory cap (see below) or it can take the whole box down, including other projects |

These facts are from the Task 1.2 server inspection (Apache modules,
`apache2ctl -S`, `pm2 ls`/`describe`, `apt-cache policy`, `free -m`) and are a
point-in-time snapshot — re-check anything load-bearing (free memory
especially) immediately before acting on it, since five other projects share
this box and their memory use moves independently of ours.

### Rules for working on a shared server

These apply to every step below, not just the ones that spell them out
again:

- Touch only `/opt/sokabrain`, our two Apache site files, and our own PM2
  apps (`sokabrain-api`, `sokabrain-web`), addressed by name.
- Always `apache2ctl configtest` before `systemctl reload apache2`. Never
  `systemctl restart apache2` — a restart drops every other site's
  connections, not just ours; a reload does not.
- Never `pm2 kill`, `pm2 delete all`, or `pm2 restart all`. Always name our
  two apps explicitly.
- Never change the firewall.
- **Installing PostgreSQL 16 is the one apparent exception**, and it isn't
  really one: Task 1.2 found no Postgres on this server at all (the other
  project there runs MySQL), so there is no existing Postgres role, database,
  or config belonging to anyone else to disturb. We're the only tenant it
  will ever have. The rule's intent — don't touch what isn't ours — is
  honoured; its letter (which names `/opt/sokabrain` and Apache files
  specifically, because those are the categories of thing the fresh-server
  guide above already works with) doesn't anticipate installing a database
  engine, because the fresh-server guide never has to.

### Upgrading Node from 20 to 22, if it's still needed

The main guide (Step 2) installs Node 22 from NodeSource. This server already
runs Node 20.20.2, also from NodeSource (`dpkg -l` shows
`nodejs 20.20.2-1nodesource1`; no nvm directory exists) — installed for the
other app that runs under the same PM2 daemon. `backend/package.json` doesn't
set an `engines` field, so Node 20 likely runs it fine; upgrade to 22 only if
you hit a real incompatibility, because *this upgrade affects the other app
too*, not just ours.

If an upgrade turns out to be necessary, in this order (**all untested —
this is a procedure, not something run yet**):

1. `pm2 save` — snapshots the current process list (both apps) so
   `pm2 resurrect` has a known-good fallback if anything below goes wrong.
2. `curl -fsSL https://deb.nodesource.com/setup_22.x | bash -` then
   `apt-get install -y nodejs` — the same two commands the main guide uses
   for a fresh install; on an existing Node install this upgrades in place.
3. `npm ls -g --depth=0` — confirm `pm2` is still listed. NodeSource's Node
   package swap does not remove separately-installed global npm packages,
   but confirm rather than assume.
4. **Rebuild the other app's native modules, if it has any.** Check its
   `package.json` for anything with a native build step (common ones:
   `bcrypt`, `sharp`, anything with a `binding.gyp`). If it has none, this
   step is a no-op. If it does, `cd` to its directory and run `npm rebuild`
   there — a native module built against Node 20's ABI will not load under
   Node 22 without this.
5. `pm2 update` — PM2's own documented step after the underlying Node
   version changes; it re-forks PM2's in-memory process manager against the
   new binary without dropping the apps it's tracking.
6. Verify **every** existing PM2 app, not just ours: `pm2 ls` (all should
   read `online`), then a request against each app's own surface (for the
   other app, whatever health or home endpoint it exposes; for ours, once
   deployed, `curl http://127.0.0.1:4010/health` and
   `curl -I http://127.0.0.1:3100/`).
7. **Rollback, if step 6 fails for the other app:** NodeSource keeps old
   package versions available —
   `apt-get install -y nodejs=20.20.2-1nodesource1`, then repeat steps 3–6
   against Node 20. Keep the exact version string step 2 reports before
   upgrading, so the rollback target is precise rather than "the last 20.x."

### PostgreSQL 16, local, listening on localhost only

Ubuntu 24.04's own `postgresql-16` package (Task 1.2 found candidate
`16.15-0ubuntu0.24.04.1`, matching the version the vault requires) rather
than a managed provider:

```sh
apt-get install -y postgresql-16
```

Ubuntu's package ships `listen_addresses = 'localhost'` by default — **confirm
this rather than assume it**, since it's the one setting that decides whether
this database is reachable from outside the box at all:

```sh
grep -E '^\s*listen_addresses' /etc/postgresql/16/main/postgresql.conf
```

If it already reads `localhost` (expected), leave it. If it doesn't, set it
and reload — but that's a hypothetical for now; **untested**, because
Postgres isn't installed on the server yet.

A dedicated role and database, not the migration-script default of "a
database named after the OS user":

```sh
sudo -u postgres psql -c "CREATE ROLE sokabrain WITH LOGIN PASSWORD '<generate one — do not write it in this file or commit it anywhere>';"
sudo -u postgres psql -c "CREATE DATABASE sokabrain OWNER sokabrain;"
sudo -u postgres psql -c "ALTER DATABASE sokabrain SET timezone TO 'UTC';"
```

This mirrors Step 1.1/1.2 of the main guide (a dedicated role in place of a
managed provider's credentials, the same UTC pin). Then Step 1.3's own
script, unchanged, pointed at the new local role:

```sh
TARGET_URL="postgresql://sokabrain:<password>@127.0.0.1:5432/sokabrain" ./scripts/restore_db.sh
```

It prints row counts on completion — expect **6,984** in `matches` and
**12,543** in `match_events`, the same numbers Task 1.1 got restoring this
exact snapshot locally (the numbers grow as data is added; these are current
as of this snapshot).

Then Step 1.4's kickoff check, unchanged:

```sh
psql "$TARGET_URL" -c "SELECT kickoff_at, extract(epoch FROM kickoff_at) FROM matches ORDER BY id DESC LIMIT 3;"
```

Compare against the same query against the local vault, as the main guide
describes.

**Nothing in this subsection has been run on the real server.**

### The checkout

```sh
mkdir -p /opt/sokabrain
git clone git@github.com:Mickamwamba/sokabrain.git /opt/sokabrain
```

Needs a **read-only** deploy key — staging does not get write access to the
repo. (This is also why the weekly snapshot-to-git job from the main guide's
Step 6.6/Backups section is not part of this one: it needs a server with
*write* access, and staging, being a copy rather than the vault of record,
has no business pushing to the repo. See "Nightly backups" below for what
this server does instead.) Everything from here runs as `root`, because
that's the user the existing PM2 daemon (`pm2-root.service`) already runs
as — there's no separate `sokabrain` system user on this box the way the
main guide creates one.

### The backend

`.env` at `/opt/sokabrain/backend/.env`, `chmod 600`:

```sh
NODE_ENV=production
PORT=4010
DATABASE_URL=postgresql://sokabrain:<password>@127.0.0.1:5432/sokabrain
JWT_SECRET=<openssl rand -hex 32>

# No SportMonks account/token exists yet for this deployment. Leave both
# unset and the sync off until one does — see "Scheduled jobs" below for
# what changes once it exists.
LIVE_SYNC_ENABLED=false

# Apache runs on this machine and will overwrite X-Forwarded-For with the
# real connecting address (see "Apache and TLS" below), so trust exactly
# the loopback address — same reasoning as the main guide's Step 3.1, same
# value, different proxy software.
TRUST_PROXY=loopback
```

**The backend listens on all interfaces, not loopback, and this deployment
accepts that rather than fixing it.** `backend/src/index.ts` calls
`app.listen(env.PORT, callback)` with no host argument, and Node binds that
to every interface by default; there is no `HOST` variable in
`backend/src/env.ts` to restrict it. On a fresh server (the main guide) this
is sealed off by `ufw`. On this shared server we were told never to touch
the firewall — but the firewall already in place is what's relied on here to
keep port 4010 off the public interface; nothing in this deployment changes
that firewall, and nothing in this deployment opens it further. Fixing this
properly needs a small code change (an optional `HOST` env var, honoured
only if set) — out of scope for this docs-only task; flagged below as a
recommendation.

Build, same as Step 3.2:

```sh
cd /opt/sokabrain/backend
npm ci
npm run db:generate
npm run build
```

Admin accounts, same as Step 3.3:

```sh
ADMIN_PASSWORD='at-least-12-characters' npm run admin:create -- --email them@example.com --name "Their Name"
```

Start it — just this one app for now, so we can check it in isolation
before the web app and Apache are in the picture:

```sh
cd /opt/sokabrain
pm2 start ecosystem.config.cjs --only sokabrain-api
curl -s http://127.0.0.1:4010/health      # {"status":"ok","database":"connected"}
```

**Nothing in this subsection has been run on the real server.**

### The web app, built under a memory limit

`npm run build` on a 2 GB box with four other things already running (an
`mysqld` alone was using ~435 MB at last check) is a real risk of taking
*everything* down, not just failing our own build. Run it inside a cgroup
with a hard cap instead of bare:

```sh
cd /opt/sokabrain/web
systemd-run --scope -p MemoryMax=<limit> -p MemorySwapMax=0 npm run build
```

`MemorySwapMax=0` matters less than it would elsewhere, since Task 1.2 found
**no swap configured on this box at all** (`free -m`: `Swap: 0 0 0`) — but it
guards against someone adding swap later and the OOM killer trading a fast,
visible failure for slow, box-wide thrashing instead.

**Choosing `<limit>`:** read `free -m`'s `available` column *immediately
before* running the build, not from this document — Task 1.2's numbers
(≈1,085 MB available, 0 swap) are already stale by the time anyone acts on
them, since four unrelated projects' memory use moves independently of ours.
As a starting point and nothing more: subtract a few hundred MB of margin for
everything that has to keep running through the build (Apache, the database
server if colocated, the other PM2 app, our own backend once it's started),
and don't use more than roughly two-thirds of total RAM regardless of what
"available" claims, since page cache reported as available isn't all
instantly reclaimable under pressure. Against Task 1.2's own numbers that
worked out to roughly `MemoryMax=600M` as an illustrative figure — **not a
value to copy mechanically**; re-derive it.

**What a killed build looks like:** the cgroup's OOM killer sends `SIGKILL`
to the build process once it crosses the cap. There's no Next.js error, no
stack trace — the process simply stops, and the shell's exit code is `137`
(128 + `SIGKILL`). `journalctl -k | grep -i "out of memory"` (or `dmesg`)
around that timestamp will show the kernel's own OOM line naming the killed
process, which is how you tell "killed by the memory cap" apart from "the
build genuinely failed."

**Fallback: build elsewhere, copy the output.** Build on any other machine
with the same `API_URL` set (see the single-source note just below), then
copy `/opt/sokabrain/web/.next/`, `public/`, `package.json`,
`package-lock.json`, `next.config.ts`, and `.env.production` to the server,
and run `npm ci` **on the server** (not copied) before starting — not a full
build, just package installation, which is far lighter than compiling the
app.

**Is the build output portable from macOS arm64 to Linux x64 for this app?**
Split answer, stated plainly rather than guessed at:

- This app uses Next.js's **default** build output, not `output: 'standalone'`
  (`next.config.ts` sets neither) — confirmed by reading the file.
- The compiled `.next/` folder itself (JS bundles, `routes-manifest.json`,
  and friends) is not CPU-architecture-specific, because Next's default
  build transpiles to plain JavaScript run by Node rather than compiling to
  native machine code. **This specific claim is an inference about how the
  toolchain works, not a sentence quoted from Next.js's own documentation —
  treat it as unverified by documentation, even though it follows from
  documented behavior.**
- What *is* directly confirmed (from the `package-lock.json` diff in Task
  1.2a): `next` ships per-platform optional dependencies —
  `@next/swc-darwin-arm64` is what gets installed on this Mac,
  `@next/swc-linux-x64-gnu` is what the server needs. **`node_modules` is
  not portable between the two and must never be copied** — this is why the
  fallback above says `npm ci` on the server, never `cp -r node_modules`.

### `API_URL`: one place, same value at build and run time

The main guide's own Step 4.1 already puts it in `web/.env.production`; this
deployment doesn't add a second place. Next.js's documented environment
variable load order is `.env.$(NODE_ENV)` before `.env`, and "`NODE_ENV`...
production for all other commands" besides `next dev` — meaning
`web/.env.production` is loaded automatically by **both** `npm run build`
and `npm run start`, with no extra wiring:

```sh
# web/.env.production — the only place this value is set, for both build and run
NODE_ENV=production
API_URL=http://127.0.0.1:4010
```

`ecosystem.config.cjs` deliberately does **not** set `API_URL` — doing so
would create a second source of truth that could silently drift from the
one `.env.production` carries, exactly the failure mode
`docs/ARCHITECTURE.md`'s "Constraints that shape deployment" warns about
("`API_URL` has to be right at build time... Next.js bakes the rewrite
destinations into the build").

Once the build (or the copy, if the fallback was used) is in place, start
the second app:

```sh
cd /opt/sokabrain
pm2 start ecosystem.config.cjs --only sokabrain-web
curl -I http://127.0.0.1:3100/            # HTTP/1.1 200 OK
```

**Nothing in this subsection has been run on the real server.**

### Apache and TLS

Two site files, modelled directly on the other app's
(`/etc/apache2/sites-available/brakad-api.conf`, read during Task 1.2 as
"another app under the same PM2"): a port-80 block, and a port-443 block
proxying to a loopback port. The only real differences from that file: two
separate hostnames instead of one, the backend is at `:4010` instead of
`:3000`, and the `X-Forwarded-For` and `noindex` directives below, which
that file doesn't carry.

**Certificates come from `certbot certonly`, not the Apache plugin** — the
plugin rewrites vhost files to insert its own SSL block, and we want the SSL
block written by us, with explicit paths, the same way the other app's file
does it. That means getting the certificate *before* the files reference it,
in an order where `apache2ctl configtest` passes at every step, including
before any certificate exists:

**1. A webroot for ACME challenges**, shared by both hostnames since it only
ever holds challenge files:

```sh
mkdir -p /var/www/certbot
```

**2. Port-80-only site files first** — no SSL block yet, so nothing
references a certificate that doesn't exist:

`/etc/apache2/sites-available/sokabrain-web.conf`:
```apache
<VirtualHost *:80>
    ServerName staging.soka.co

    Alias /.well-known/acme-challenge/ /var/www/certbot/.well-known/acme-challenge/
    <Directory /var/www/certbot/.well-known/acme-challenge/>
        Require all granted
    </Directory>

    RewriteEngine On
    RewriteCond %{REQUEST_URI} !^/\.well-known/acme-challenge/
    RewriteRule ^(.*)$ https://staging.soka.co$1 [R=301,L]
</VirtualHost>
```

`/etc/apache2/sites-available/sokabrain-api.conf`, same shape with
`api.staging.soka.co`.

```sh
apache2ctl configtest                                 # passes: no cert referenced yet
ln -s /etc/apache2/sites-available/sokabrain-web.conf /etc/apache2/sites-enabled/
ln -s /etc/apache2/sites-available/sokabrain-api.conf /etc/apache2/sites-enabled/
apache2ctl configtest
systemctl reload apache2                              # reload, never restart
```

**3. Get the certificates**, one domain at a time, matching the other app's
one-cert-per-hostname layout:

```sh
certbot certonly --webroot -w /var/www/certbot -d staging.soka.co \
  --deploy-hook "apache2ctl configtest && systemctl reload apache2"
certbot certonly --webroot -w /var/www/certbot -d api.staging.soka.co \
  --deploy-hook "apache2ctl configtest && systemctl reload apache2"
```

The `--deploy-hook` matters because `certonly` (unlike the Apache plugin)
doesn't manage its own reload on renewal — without it, a renewed certificate
sits on disk unused until something else reloads Apache. The hook itself
follows the same configtest-then-reload rule as every other change here.

**4. Now append the port-443 block** to each file, referencing the
certificates that exist as of step 3:

`/etc/apache2/sites-available/sokabrain-web.conf`, appended:
```apache
<VirtualHost *:443>
    ServerName staging.soka.co

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/staging.soka.co/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/staging.soka.co/privkey.pem

    # Staging is not for search engines.
    Header set X-Robots-Tag "noindex"

    # Discard whatever X-Forwarded-For the client sent; let mod_proxy add a
    # fresh one from the real connecting address. See the note below for
    # why this is "unset", not "set ... %{REMOTE_ADDR}s".
    RequestHeader unset X-Forwarded-For

    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:3100/
    ProxyPassReverse / http://127.0.0.1:3100/

    ErrorLog ${APACHE_LOG_DIR}/sokabrain-web-error.log
    CustomLog ${APACHE_LOG_DIR}/sokabrain-web-access.log combined
</VirtualHost>
```

`/etc/apache2/sites-available/sokabrain-api.conf`, appended, same shape:
`ServerName api.staging.soka.co`, proxying to `http://127.0.0.1:4010/`.

```sh
apache2ctl configtest                                 # passes: certs now exist
systemctl reload apache2
```

**Why `RequestHeader unset X-Forwarded-For` alone, with no accompanying
`RequestHeader set`:** Apache's own `mod_proxy` documentation states that
`ProxyAddHeaders` — on by default — governs whether proxy information,
including `X-Forwarded-For`, is added to the request before it reaches the
backend, and warns that the header "will contain more than one
(comma-separated) value **if the original request already contained one of
these headers**." Read the other way round: if the incoming request does
*not* already carry the header — which `unset` guarantees, discarding
anything the client sent — `mod_proxy` adds a single fresh value: the real
connecting address. That's the documented mechanism; it is not, by itself,
proof that it works as described on *this* server's configuration. **The
test that actually settles it** is below.

**The test:** run a packet capture on loopback (where Apache's proxied
request to the backend actually travels, in plaintext, regardless of the
public side being HTTPS) while sending a forged header from outside:

```sh
# On the server, in one terminal:
tcpdump -i lo -A 'tcp port 4010'

# From anywhere, in another terminal, with a forged X-Forwarded-For:
curl -H "X-Forwarded-For: 1.2.3.4" https://api.staging.soka.co/health
```

**Pass** means the `tcpdump` output shows an `X-Forwarded-For` header
carrying only the real connecting address — never `1.2.3.4`, and never
`1.2.3.4` followed by the real address. Either of those would mean the
forged header survived, and `TRUST_PROXY=loopback` would then be trusting an
address the client controls.

**Nothing in this subsection has been run on the real server.**

### Making PM2 survive a reboot

```sh
pm2 save
```

This is the same command already relied on for the other app (Task 1.2's
`pm2-root.service status` showed it restores from exactly this file on
boot: "Restoring processes located in `/root/.pm2/dump.pm2`"). Running
`pm2 save` after our two apps are started rewrites that one shared dump file
to include both apps alongside whatever was already in it — it does not
touch the other app's process definition, only adds ours to the same list.
`pm2-root.service` itself needs no changes; it already runs `pm2 resurrect`
on boot, which will now bring back three apps instead of one.

**Untested** — confirming this actually survives a reboot means rebooting a
server that hosts five other projects, which is explicitly out of scope for
a verification step in this task.

### Scheduled jobs

The main guide's Step 6 crontab jobs, paths adjusted from `/srv/sokabrain` to
`/opt/sokabrain`, otherwise unchanged — crontab doesn't care whether the
backend it calls into is managed by systemd or PM2, so nothing about these
three jobs is actually PM2-specific:

```cron
CRON_TZ=UTC
SHELL=/bin/bash
PATH=/usr/local/bin:/usr/bin:/bin

# Nightly results catch-up
0 3 * * *   flock -n /tmp/sm-catchup.lock /opt/sokabrain/bin/sm-catchup.sh >> /opt/sokabrain/logs/sm-catchup.log 2>&1

# Weekly goal-events report (dry run only — see below)
0 4 * * 1   flock -n /tmp/sm-events.lock /opt/sokabrain/bin/sm-events-report.sh >> /opt/sokabrain/logs/sm-events-report.log 2>&1
```

Both scripts are copied from the main guide's Step 6.3/6.4 verbatim, with
`/srv/sokabrain/app` changed to `/opt/sokabrain`.

**Leave both lines commented out in `crontab -e` until a SportMonks token
exists.** There is no token for this deployment yet (`backend/.env` above
leaves `SPORTMONKS_TOKEN` unset and `LIVE_SYNC_ENABLED=false`); a catch-up or
events job run against an account with no token just fails loudly, and the
live-score sync itself (the main guide's Job 1) only starts automatically
the moment `SPORTMONKS_TOKEN` is set and `LIVE_SYNC_ENABLED=true` in
`backend/.env`, followed by `pm2 restart sokabrain-api`. The weekly
snapshot-to-git job (the main guide's third cron line) is intentionally
**not** reproduced here at all — see "The checkout" above: this server's
deploy key is read-only, and staging is a copy, not the vault of record.

**Untested** — no token exists yet to test either job against.

### Nightly backups

A complete local `pg_dump`, kept on the server, in a directory only `root`
can read — **not** `scripts/dump_db.sh`, which exists to produce a
git-committable snapshot and scrubs admin credentials for that reason; a
local operational backup should keep everything, including real admin
password hashes, so a restore is actually complete.

```sh
mkdir -p /opt/sokabrain/backups
chmod 700 /opt/sokabrain/backups
```

`/opt/sokabrain/bin/pg-backup.sh`:

```sh
#!/usr/bin/env bash
# Nightly: a complete custom-format dump of the staging database, kept
# locally. Retention: 14 days. Off-server destination not yet decided —
# see the note below.
set -euo pipefail
BACKUP_DIR=/opt/sokabrain/backups
STAMP="$(date -u +%FT%H%M%SZ)"

pg_dump -Fc -d postgresql://sokabrain:<password>@127.0.0.1:5432/sokabrain \
  -f "$BACKUP_DIR/sokabrain-$STAMP.dump"

find "$BACKUP_DIR" -name 'sokabrain-*.dump' -mtime +14 -delete
```

```sh
chmod +x /opt/sokabrain/bin/pg-backup.sh
chmod 600 /opt/sokabrain/backups/*.dump 2>/dev/null || true
```

Crontab line, same file as above:

```cron
30 3 * * *  flock -n /tmp/pg-backup.lock /opt/sokabrain/bin/pg-backup.sh >> /opt/sokabrain/logs/pg-backup.log 2>&1
```

A `pg_dump -Fc` file restores with `pg_restore -d <target> <file>.dump` — no
shared-server-specific step there, it's the standard tool for this format.

**The off-server destination for this backup is not yet decided.** Right
now, a backup living only on the same box it protects is a real gap — it
survives a bad migration or an admin mistake, not a lost server. This is
flagged as a recommendation below, not solved in this task.

**Untested.**

### Deploying a new version

```sh
cd /opt/sokabrain && git pull --ff-only

cd backend && npm ci && npm run db:generate && npm run build
cd ../web && npm ci && systemd-run --scope -p MemoryMax=<limit> -p MemorySwapMax=0 npm run build

pm2 restart sokabrain-api sokabrain-web
curl -s https://api.staging.soka.co/health
```

`pm2 restart`, named explicitly — never `pm2 restart all`, which would also
bounce the other app for no reason connected to our deploy. If the release
changes the schema, apply the DDL change first, inside a transaction, after
a fresh `pg-backup.sh` run — the main guide's "Changing the schema" steps in
`docs/RUNBOOK.md` apply unchanged.

**Untested.**

### Staging go-live checklist

- [ ] `https://api.staging.soka.co/health` returns `ok`.
- [ ] A recent match's kickoff time matches the local vault (the UTC pin
      survived the local-Postgres setup, not just a managed one).
- [ ] The site loads at `https://staging.soka.co`, and a published season's
      table and matches look right.
- [ ] `/admin` sign-in works with an account created via `admin:create`.
- [ ] The `tcpdump` test above shows a forged `X-Forwarded-For` does **not**
      reach the backend.
- [ ] `curl -I https://staging.soka.co/` shows `X-Robots-Tag: noindex`.
- [ ] `pm2 ls` shows `sokabrain-api` and `sokabrain-web` online, and the
      pre-existing app on this server is still online too.
- [ ] `pg-backup.sh` has run once by hand and produced a `.dump` file
      `pg_restore --list` can read.
- [ ] A reboot (scheduled deliberately, with the other project's owner
      informed in advance) brings back all three PM2 apps via
      `pm2-root.service`.
- [ ] Ports 3100 and 4010 are confirmed not reachable from outside the
      server (the firewall already in place is what this relies on — see
      "The backend" above).

### Not tested

Everything in this section is new procedure, written without connecting to
the server, per this task's constraints. Nothing on this list has been run
against the real box:

- The Node 20→22 upgrade sequence, and its rollback.
- Installing `postgresql-16`, creating the role/database, confirming
  `listen_addresses`, restoring the snapshot, and the kickoff check.
- The `/opt/sokabrain` checkout with a read-only deploy key.
- Building and starting the backend via `ecosystem.config.cjs`, and its
  `/health` check.
- The memory-limited web build, at any value of `MemoryMax`, including
  whether the illustrative figure given is anywhere close to right on the
  server as it actually is when this runs.
- The build-elsewhere fallback, and the `npm ci`-not-`cp`-for-`node_modules`
  claim about macOS→Linux portability.
- Every Apache directive: the two site files, the webroot ACME challenge,
  `certbot certonly` with `--deploy-hook`, and the `X-Forwarded-For`
  `tcpdump` test.
- `pm2 save` persisting both apps correctly alongside the existing one, and
  a reboot actually bringing all three back.
- The two cron jobs (not scheduled until a SportMonks token exists) and the
  nightly `pg_dump` script.
- The full "deploying a new version" sequence.
- The entire staging go-live checklist above.

### Recommended, not implemented here

- **Add an optional `HOST` env var to the backend** (`backend/src/env.ts`,
  `backend/src/index.ts`), honoured only if set, so it can bind to
  `127.0.0.1` explicitly instead of relying on the shared server's firewall
  to keep port 4010 off the public interface. Out of scope for this
  docs-only task.
- **Decide the off-server destination for the nightly `pg_dump`** before
  this server holds any data worth not losing twice.
