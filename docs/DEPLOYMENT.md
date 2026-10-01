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

The files below were built and run on 2026-10-01 against a copy of the vault:
both images build, the stack starts, and the site, `/api/vault` rewrite, admin
login page and `/health` all answer through Caddy. Three things weren't tested:
real TLS certificates, the scheduled jobs inside the container, and Kijiweni's
per-client rate limit behind Caddy. Cover those with the go-live checklist.

### D.1 The files

Add these six files to the repo (they aren't committed yet).

**`backend/Dockerfile`**. One image runs the API, the live-score cron and the
npm scripts the scheduled jobs use:

```dockerfile
# Sokabrain backend: the API, the live-score cron, and the npm scripts the
# scheduled jobs run. One image does all three.
FROM node:22-bookworm-slim

WORKDIR /app
ENV NODE_ENV=production

# Dev dependencies are installed on purpose: the sm:*, editions:* and admin:*
# scripts run through tsx, and `prisma generate` needs the prisma CLI.
COPY package.json package-lock.json ./
RUN npm ci --include=dev

COPY . .
# prisma.config.ts reads DATABASE_URL; generate doesn't connect, so a
# placeholder is enough at build time. The real one comes from the environment.
RUN DATABASE_URL=postgresql://build@localhost/build npx prisma generate \
 && npm run build

USER node
EXPOSE 4010
CMD ["node", "dist/index.js"]
```

**`backend/.dockerignore`**. Keeps secrets and local builds out of the image:

```
node_modules
dist
.env
*.log
```

**`web/Dockerfile`**:

```dockerfile
# Sokabrain web: public site and admin console.
FROM node:22-bookworm-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
# Next.js bakes the /api/vault and /api/kijiweni rewrite targets into the build,
# so the backend's address has to be known here, not only at run time.
ARG API_URL=http://backend:4010
ENV API_URL=$API_URL NEXT_TELEMETRY_DISABLED=1
RUN npm run build

FROM node:22-bookworm-slim
WORKDIR /app
ARG API_URL=http://backend:4010
ENV NODE_ENV=production API_URL=$API_URL NEXT_TELEMETRY_DISABLED=1
COPY --from=build /app/package.json /app/package-lock.json ./
RUN npm ci --omit=dev
COPY --from=build /app/.next ./.next
COPY --from=build /app/public ./public
COPY --from=build /app/next.config.ts ./
USER node
EXPOSE 3100
CMD ["npx", "next", "start", "-H", "0.0.0.0", "-p", "3100"]
```

**`web/.dockerignore`**:

```
node_modules
.next
.env*
*.log
tsconfig.tsbuildinfo
```

**`compose.yml`** at the repo root:

```yaml
# Sokabrain on Docker: backend, web and Caddy (HTTPS) on one host.
# The database is managed and outside this file.
name: sokabrain

services:
  backend:
    build: ./backend
    image: sokabrain-backend
    env_file: ./backend/.env
    environment:
      PORT: "4010"
    restart: unless-stopped
    # Exactly one replica: the live-score cron and the rate-limit counters live in memory.
    deploy:
      replicas: 1
    healthcheck:
      test: ["CMD", "node", "-e", "fetch('http://127.0.0.1:4010/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 15s

  web:
    build:
      context: ./web
      args:
        API_URL: http://backend:4010
    image: sokabrain-web
    environment:
      API_URL: http://backend:4010
    restart: unless-stopped
    depends_on:
      backend:
        condition: service_healthy

  caddy:
    image: caddy:2
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"
    environment:
      SITE_DOMAIN: ${SITE_DOMAIN:?set SITE_DOMAIN in .env}
      API_DOMAIN: ${API_DOMAIN:?set API_DOMAIN in .env}
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
    restart: unless-stopped
    depends_on:
      - web
      - backend

volumes:
  caddy_data:
  caddy_config:
```

Only Caddy publishes ports. The backend and web are reachable only on the
compose network, under the names `backend` and `web`.

**`Caddyfile`** at the repo root:

```
# Caddy gets and renews the TLS certificates itself. By default it ignores any
# X-Forwarded-For a client sends and sets it to the real connecting address,
# which is what Kijiweni's per-client rate limits need.
{$SITE_DOMAIN} {
	reverse_proxy web:3100
}

{$API_DOMAIN} {
	reverse_proxy backend:4010
}
```

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
