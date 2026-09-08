# Sokabrain Vault — Standard Schema v1

Target engine: **PostgreSQL** (recommended over staying on MySQL — better JSONB support for flexible event detail, better fit with modern backends like Supabase, and cleaner support for the provenance/reconciliation layer below). If you have a strong reason to stay on MySQL, everything here ports with minor syntax changes (mainly `JSONB`→`JSON`, `GENERATED ALWAYS`, and enum handling).

## Design principles

1. **Country/competition-agnostic** — nothing in this schema assumes Tanzania, or assumes only domestic leagues. Continental and international competitions (AFCON, CAF Champions League, World Cup) are first-class, not a special case.
2. **Score is stored, not just derived** — the event log stays (it's valuable), but every match carries its own denormalized score so basic queries never depend on complete event logging.
3. **Provenance is built in** — every entity can be traced to the data source(s) that produced or confirmed it. This is what makes your Step 4/5 plan (independent re-collection + comparison) actually workable instead of a one-off script.
4. **Names are matchable** — a single `full_name` plus normalized parts, so fuzzy-matching against external sources (different name orderings, diacritics, nicknames) is tractable.
5. **History is explicit** — player/coach team stints, not just current state, so "who played for Simba in 2018" is a query, not a guess.

---

## Core reference tables

```sql
CREATE TABLE confederations (
    id          SMALLSERIAL PRIMARY KEY,
    code        VARCHAR(10) UNIQUE NOT NULL,   -- CAF, UEFA, CONMEBOL, CONCACAF, AFC, OFC, FIFA
    name        VARCHAR(100) NOT NULL
);

CREATE TABLE countries (
    id              SERIAL PRIMARY KEY,
    iso_code        CHAR(3) UNIQUE,             -- ISO 3166-1 alpha-3, e.g. TZA, KEN
    name            VARCHAR(100) NOT NULL,
    full_name       VARCHAR(150),
    confederation_id SMALLINT REFERENCES confederations(id),
    flag_url        VARCHAR(255)
);

CREATE TABLE stadiums (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(150) NOT NULL,
    city        VARCHAR(100),
    country_id  INT REFERENCES countries(id),
    capacity    INT,
    latitude    NUMERIC(9,6),
    longitude   NUMERIC(9,6)
);

CREATE TABLE seasons (
    id          SERIAL PRIMARY KEY,
    label       VARCHAR(20) NOT NULL UNIQUE,   -- '2019/2020' or '2019' for calendar-year leagues
    start_date  DATE,
    end_date    DATE
);
```

## Competitions

```sql
CREATE TABLE competitions (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(150) NOT NULL,
    slug            VARCHAR(160) UNIQUE NOT NULL,
    type            VARCHAR(30) NOT NULL CHECK (type IN
                        ('LEAGUE','DOMESTIC_CUP','SUPER_CUP','CONTINENTAL_CLUB',
                         'CONTINENTAL_NATIONAL','WORLD_CUP','FRIENDLY','QUALIFIER')),
    country_id      INT REFERENCES countries(id),      -- NULL for continental/international
    confederation_id SMALLINT REFERENCES confederations(id), -- set for continental/international
    tier            SMALLINT,                          -- 1 = top flight, 2 = second division, etc.
    logo_url        VARCHAR(255)
);

-- One row per (competition, season) occurrence — this is where format/host/participants live
CREATE TABLE competition_editions (
    id              SERIAL PRIMARY KEY,
    competition_id  INT NOT NULL REFERENCES competitions(id),
    season_id       INT NOT NULL REFERENCES seasons(id),
    host_country_id INT REFERENCES countries(id),      -- for AFCON/World Cup style hosted events
    format          VARCHAR(30) CHECK (format IN ('ROUND_ROBIN','GROUPS_KNOCKOUT','KNOCKOUT')),
    num_teams       SMALLINT,
    UNIQUE (competition_id, season_id)
);

CREATE TABLE competition_groups (
    id                      SERIAL PRIMARY KEY,
    competition_edition_id  INT NOT NULL REFERENCES competition_editions(id),
    name                    VARCHAR(10) NOT NULL        -- 'A', 'B', ...
);
```

## Teams, players, coaches

```sql
CREATE TABLE teams (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    short_name  VARCHAR(10),
    type        VARCHAR(10) NOT NULL CHECK (type IN ('CLUB','NATIONAL')),
    country_id  INT NOT NULL REFERENCES countries(id),
    stadium_id  INT REFERENCES stadiums(id),
    founded_year SMALLINT,
    logo_url    VARCHAR(255),
    UNIQUE (name, country_id)          -- was globally unique before; broke for common club names across countries
);

CREATE TABLE competition_edition_teams (
    id                      SERIAL PRIMARY KEY,
    competition_edition_id  INT NOT NULL REFERENCES competition_editions(id),
    team_id                 INT NOT NULL REFERENCES teams(id),
    group_id                INT REFERENCES competition_groups(id),
    UNIQUE (competition_edition_id, team_id)
);

CREATE TABLE players (
    id                  SERIAL PRIMARY KEY,
    full_name           VARCHAR(150) NOT NULL,
    first_name          VARCHAR(60),
    last_name           VARCHAR(60),
    dob                 DATE,
    nationality_id      INT REFERENCES countries(id),
    position            VARCHAR(3) CHECK (position IN ('GK','DF','MF','FW')),
    height_cm           SMALLINT,
    preferred_foot      VARCHAR(10) CHECK (preferred_foot IN ('LEFT','RIGHT','BOTH')),
    photo_url           VARCHAR(255)
);

CREATE TABLE player_team_stints (
    id              SERIAL PRIMARY KEY,
    player_id       INT NOT NULL REFERENCES players(id),
    team_id         INT NOT NULL REFERENCES teams(id),
    start_date      DATE,
    end_date        DATE,               -- NULL = current
    shirt_number    SMALLINT,
    transfer_fee    NUMERIC(12,2),
    transfer_type   VARCHAR(20) CHECK (transfer_type IN ('PERMANENT','LOAN','FREE','YOUTH'))
);

CREATE TABLE coaches (
    id              SERIAL PRIMARY KEY,
    full_name       VARCHAR(150) NOT NULL,
    dob             DATE,
    nationality_id  INT REFERENCES countries(id),
    photo_url       VARCHAR(255)
);

CREATE TABLE coach_team_stints (
    id          SERIAL PRIMARY KEY,
    coach_id    INT NOT NULL REFERENCES coaches(id),
    team_id     INT NOT NULL REFERENCES teams(id),
    role        VARCHAR(20) DEFAULT 'HEAD_COACH',
    start_date  DATE,
    end_date    DATE
);
```

## Matches — score is now a first-class field

```sql
CREATE TABLE matches (
    id                      SERIAL PRIMARY KEY,
    competition_edition_id  INT NOT NULL REFERENCES competition_editions(id),
    group_id                INT REFERENCES competition_groups(id),
    round                   VARCHAR(30),        -- 'Round 12', 'Quarter-final', 'Matchday 3'
    home_team_id            INT NOT NULL REFERENCES teams(id),
    away_team_id            INT NOT NULL REFERENCES teams(id),
    stadium_id              INT REFERENCES stadiums(id),
    kickoff_at              TIMESTAMPTZ,
    status                  VARCHAR(15) NOT NULL DEFAULT 'SCHEDULED'
                                CHECK (status IN ('SCHEDULED','LIVE','FULL_TIME','POSTPONED','ABANDONED','CANCELLED')),
    home_score              SMALLINT,
    away_score              SMALLINT,
    home_score_et           SMALLINT,           -- extra time, if applicable
    away_score_et           SMALLINT,
    home_score_pens         SMALLINT,           -- penalty shootout
    away_score_pens         SMALLINT,
    attendance              INT,
    referee_id              INT REFERENCES coaches(id)  -- reuse coaches-style people table, or split to a `people` table if scope grows
);

CREATE TABLE match_lineups (
    id          SERIAL PRIMARY KEY,
    match_id    INT NOT NULL REFERENCES matches(id),
    team_id     INT NOT NULL REFERENCES teams(id),
    player_id   INT NOT NULL REFERENCES players(id),
    role        VARCHAR(10) NOT NULL CHECK (role IN ('STARTER','SUB')),
    position    VARCHAR(3),
    shirt_number SMALLINT,
    minute_on   SMALLINT,
    minute_off  SMALLINT,
    UNIQUE (match_id, player_id)
);

CREATE TABLE match_events (
    id              SERIAL PRIMARY KEY,
    match_id        INT NOT NULL REFERENCES matches(id),
    team_id         INT REFERENCES teams(id),
    player_id       INT REFERENCES players(id),
    related_player_id INT REFERENCES players(id),   -- assist provider, or player subbed in/out
    minute          SMALLINT,
    added_time      SMALLINT,
    type            VARCHAR(20) NOT NULL CHECK (type IN
                        ('GOAL','OWN_GOAL','PENALTY_GOAL','PENALTY_MISS',
                         'YELLOW_CARD','SECOND_YELLOW','RED_CARD','SUBSTITUTION','VAR_REVIEW')),
    detail          JSONB               -- flexible extra data without schema churn
);
```

## Optional richness tables (populate only where source data supports it)

These stay NULL for niche leagues where the underlying stats simply aren't captured by local match reports, and get populated for mainstream leagues where your API source provides them.

```sql
CREATE TABLE match_team_stats (
    match_id        INT REFERENCES matches(id),
    team_id         INT REFERENCES teams(id),
    possession_pct  NUMERIC(4,1),
    shots           SMALLINT,
    shots_on_target SMALLINT,
    corners         SMALLINT,
    fouls           SMALLINT,
    offsides        SMALLINT,
    PRIMARY KEY (match_id, team_id)
);

CREATE TABLE match_player_ratings (
    match_id    INT REFERENCES matches(id),
    player_id   INT REFERENCES players(id),
    rating      NUMERIC(3,1),
    is_motm     BOOLEAN DEFAULT false,
    PRIMARY KEY (match_id, player_id)
);
```

## Provenance & reconciliation — this is what makes your plan work

```sql
CREATE TABLE data_sources (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(50) UNIQUE NOT NULL,   -- 'legacy_sokafc', 'wikipedia', 'api_football', 'manual_qa'
    type        VARCHAR(20) CHECK (type IN ('INTERNAL_LEGACY','SCRAPED','API','MANUAL')),
    base_url    VARCHAR(255)
);

-- Every record in the vault can be traced to whoever produced/confirmed it
CREATE TABLE entity_source_map (
    id              SERIAL PRIMARY KEY,
    entity_type     VARCHAR(30) NOT NULL,      -- 'match','player','team','coach', etc.
    entity_id       INT NOT NULL,
    data_source_id  INT NOT NULL REFERENCES data_sources(id),
    external_id     VARCHAR(100),              -- the ID/slug on that source's own system
    external_url    VARCHAR(255),
    confidence      NUMERIC(3,2) DEFAULT 1.0,
    last_synced_at  TIMESTAMPTZ DEFAULT now(),
    UNIQUE (entity_type, data_source_id, external_id)
);

-- A reconciliation pass between two sources for a given entity type
CREATE TABLE reconciliation_runs (
    id                  SERIAL PRIMARY KEY,
    entity_type         VARCHAR(30) NOT NULL,
    data_source_a_id    INT NOT NULL REFERENCES data_sources(id),
    data_source_b_id    INT NOT NULL REFERENCES data_sources(id),
    run_at              TIMESTAMPTZ DEFAULT now(),
    notes               TEXT
);

CREATE TABLE reconciliation_diffs (
    id                      SERIAL PRIMARY KEY,
    reconciliation_run_id  INT NOT NULL REFERENCES reconciliation_runs(id),
    entity_id_a             INT,
    entity_id_b             INT,
    field_name              VARCHAR(50) NOT NULL,
    value_a                 TEXT,
    value_b                 TEXT,
    resolution              VARCHAR(15) DEFAULT 'PENDING'
                                CHECK (resolution IN ('PENDING','ACCEPT_A','ACCEPT_B','BOTH_AGREE','MANUAL')),
    resolved_value          TEXT,
    resolved_at             TIMESTAMPTZ
);
```

**How this gets used in practice (your Steps 3–5):**
1. Import the legacy MySQL data → new schema. Every row gets an `entity_source_map` entry with `data_source = 'legacy_sokafc'`.
2. Independently re-collect the same matches/players from external sources (Wikipedia, RSSSF, league sites, an API) into the *same* tables, but as new rows — don't overwrite. Each gets its own `entity_source_map` entry (`data_source = 'wikipedia'`, etc.).
3. Run a reconciliation script that matches candidate pairs (same teams + same date, or fuzzy player-name + team + season) and logs every field disagreement into `reconciliation_diffs`.
4. Work through `PENDING` diffs — auto-accept where sources agree, flag disagreements for manual review. The `resolved_value` becomes what actually lands in your canonical `matches`/`players` row.

This gives you a permanent audit trail — you'll always know *why* a stat says what it says, which matters a lot once fans start using this to settle arguments.

---

## Migration mapping: legacy → new schema (key tables)

| Legacy table | New table(s) | Notes |
|---|---|---|
| `countries` / `countries2` | `countries` | Consolidate the two (a legacy cleanup during your import); add `iso_code` |
| `competitions` + `leagues` + `cups` | `competitions` | Merge into one typed table; **fix the Kenya PL country bug during migration** |
| `divisions` | `competitions.tier` | Collapse into an integer field |
| `seasons` | `seasons` | Add `label` field (e.g. derive `'2018/2019'` from start/end year) |
| `league_groups` + `cup_groups` | `competition_groups` | Merge |
| `competition_participants` | `competition_edition_teams` | Renamed, tied to `competition_editions` instead of raw competition+season |
| `matches` | `matches` | **Add computed home_score/away_score** by aggregating legacy `match_team_events` GOAL-type events per match during migration |
| `league_matches` / `cup_matches` | `matches.round` | Collapse the `round` (int) and `stage` (varchar) into a single `round` text field, or keep both if you want strict typing |
| `match_events` + `events` + `match_player_events` + `match_team_events` | `match_events` | Flatten the four-table EAV structure into one row per event with `type` enum |
| `match_lineups` | `match_lineups` | Same shape, minor renames |
| `players` | `players` | Merge `fname`/`mname`/`sname`/`other_name` into `full_name` + `first_name`/`last_name`; **flag all rows for DOB backfill** — none currently have it |
| `player_teams` | `player_team_stints` | Same shape |
| `coaches` / `coach_teams` | `coaches` / `coach_team_stints` | Same shape |
| `transfers` | Merge into `player_team_stints` (`transfer_fee`, `transfer_type`) | Avoids a redundant parallel table |
| `stadiums` | `stadiums` | Add lat/lng for future map features |
| `users`, `news*`, `comments`, `notifications`, `administrators` | *(not migrated — out of scope for the Vault)* | These belong to the old app's social/CMS layer, not historical football data |


---

## Addendum: `admins` (added in build priority 3)

The migration table above records that the legacy `administrators` table was
deliberately **not** migrated — it belonged to the old app's CMS layer, and its
password hashes and user records are not football data.

Build priority 3 (JWT admin auth + manual vault edits) still needs somewhere to
authenticate the small number of people allowed to write to the vault, so a
fresh `admins` table was added to `sokabrain_schema_ddl.sql`. It is a new table,
not a revival of `administrators`: no legacy rows were imported into it.

| Column | Notes |
|---|---|
| `email` | unique; the login identifier |
| `password_hash` | scrypt, stored as `<salt-hex>:<derived-key-hex>` — see `backend/src/auth/password.ts` |
| `display_name` | shown in the admin UI |
| `is_active` | re-read on every authenticated request, so deactivating an account takes effect immediately rather than when its token expires |
| `created_at`, `last_login_at` | |

Deliberately absent: any role or permission column. There is exactly one
privilege level until there is a concrete reason for more.

### How manual edits carry provenance

Design principle 1 requires every row entering the vault to have an
`entity_source_map` row, and that applies to hand-entered data as much as to
migrated or API-sourced data. A `data_sources` row `manual_admin`
(`type = 'MANUAL'`) was added for this, and every admin write records its
provenance in the same transaction as the write itself — so a provenance
failure rolls the write back rather than leaving an untracked row.

`external_id` holds the vault's own entity id, mirroring the convention the
legacy migration used. The unique key
`(entity_type, data_source_id, external_id)` means re-editing an entity
refreshes `last_synced_at` instead of accumulating duplicate rows.

**Known gap:** this records *which source* touched a row, not *which admin*.
Per-admin attribution ("who changed this score, and when") would need an audit
table the schema does not currently have. Worth adding before more than one or
two people have write access.

### Scores are not recomputed from events

`matches.home_score` / `away_score` stay authoritative (principle 3). Adding a
`match_events` row through the admin API does **not** change the stored score,
and editing the score does not touch the event log; the two are edited
deliberately and separately. This matters because the legacy event log is
partial — roughly a quarter of goal events have no scorer, and 61 of the 380
matches in the 2018/19 Premier League edition have no score at all — so deriving
one from the other would quietly corrupt known-correct data.


---

## Addendum: editorial layer (admin dashboard)

Two columns' worth of new behaviour, added so that partial data can be worked on
without being shown to the public.

### `competition_editions.is_published`

Defaults to **FALSE**. The public read API returns only published editions, and
an unpublished edition is a 404 rather than a 403 — the public API should not
confirm that a hidden edition exists. Publication records `published_at` and
`published_by`, so "who released this" is answerable.

This inverts the previous default: before, everything in the vault was public
the moment it was migrated. Given that 61 of the 380 matches in the 2018/19
Premier League have no score, that was showing a table that reads as broken.

### `data_flags`

A flag records that something needs attention, on an edition, match, event, team
or player. Severity is INFO, WARNING or BLOCKER.

**A BLOCKER flag prevents its edition from being published.** That is the rule
that makes flagging worth the effort — an edition cannot go live over a problem
someone has explicitly marked as blocking. A flag on a *match* blocks that
match's edition, so the review unit is the edition and everything inside it.
WARNING and INFO are advisory and never block.

Flags carry `created_by`/`resolved_by` against `admins`, which is the first
per-person attribution in the schema. It is not a general audit log — it records
who raised and cleared a flag, not who edited a score. That gap still stands.

### Suggested issues

`suggestedIssues()` derives a worklist from the data itself rather than requiring
someone to find problems by hand: completed matches with no score (BLOCKER),
completed matches with no event log (WARNING), goals with no scorer (WARNING).
These are surfaced in the dashboard as one-click flags, so an editor starts from
a real list instead of a blank page. Nothing is written until they choose to
raise one.


---

## Addendum: derived goal events

`match_events.detail` — a JSONB column the migration never used — now carries a
marker on goal rows that were **derived from the stored score rather than
observed**:

```json
{ "derived": "score", "scorer": "unknown" }
```

### Why they exist

Many matches carry a correct, source-verified score but no event log at all,
because the legacy data captured results without match detail. A goal row can
still be created for each of those goals: the score tells us how many each side
scored, so the **team is a fact**, even though the scorer, minute and exact type
are not. This makes the event log structurally complete — every goal has a row —
and turns "no event log" into the single, tractable problem of "scorer unknown".

### Why they are marked

Without the marker they would be indistinguishable from observed events, and
importing a real scorer feed later would **double every goal**. The marker makes
them identifiable and removable in one statement:

```sql
DELETE FROM match_events WHERE detail->>'derived' = 'score';
```

Do exactly that before importing any real event source for these seasons.

### What they assert, and what they do not

They assert only *which team scored*. They record `type = 'GOAL'` because the
type is unknown, so a small number are really penalties or own goals — roughly
3% based on the observed mix. **This does not affect any table**: an own goal is
credited to the opposing team on the read side, and a derived GOAL is already
attributed to that same credited team, so standings are identical either way.
What is lost is the narrative, not the arithmetic.

### One consequence to keep in mind

Because these rows are generated from the score, the event-log-versus-score
cross-check can no longer fail for the matches that have them. That check keeps
its value only for matches with genuinely observed events.


---

## Addendum: `matches.kickoff_at` was three hours late

Corrected 2026-09-08, across all 1,549 migrated matches that carry a real time.

The legacy SokaFC database stored kickoffs in MySQL `datetime` columns, which
carry no zone. The app was operated from Tanzania, so those columns hold **local
wall-clock (EAT, UTC+3)** as typed by the operator. The migration wrote those
hours into `TIMESTAMPTZ` as if they were UTC, which put every kickoff three
hours late.

The defect was invisible in the product — the web app renders `kickoff_at` with
`toLocaleDateString`, never a time — but the data was wrong, and it said the
Tanzanian Premier League's standard kickoff was 19:00 and that 35 of its matches
kicked off at 23:00. Corrected, 797 of the league's matches sit on its actual
16:00 kickoff.

Five rows were deliberately **not** shifted: matches 733, 747, 750, 925 and 926,
whose legacy time is 00:00 or 01:00. Those are "time unknown" placeholders
rather than kickoffs, and shifting them back would have moved them to the
previous day, destroying a date that *is* known. They keep a time that should be
read as absent.

No kickoff date moved, which was checked as part of applying the fix — every
reconciliation against Wikipedia and RSSSF was made on the date, so all of them
still hold. The statement is in `docs/reconciliation/fixes/`.

Ingestion code must not reintroduce this: a provider that publishes UTC (as
API-Football does) is already correct and needs no shift, whereas a scraped
local fixture list needs its zone applied explicitly.
