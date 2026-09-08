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
                         'YELLOW_CARD','SECOND_YELLOW','RED_CARD','SUBSTITUTION','VAR_REVIEW',
                         'ASSIST')),   -- ASSIST: one row per assist, for sources that
                                       -- do not say which goal it created
    detail          JSONB               -- flexible extra data without schema churn
);


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

-- ---------------------------------------------------------------------------
-- Admin accounts (added for build priority 3: JWT auth + manual vault edits).
--
-- Deliberately NOT the legacy `administrators` table, which was excluded from
-- the migration as part of the old app's CMS layer. This is a fresh, minimal
-- table serving one purpose: authenticating the handful of people allowed to
-- write to the vault. No roles/permissions column yet — there is exactly one
-- privilege level until there's a reason for more.
-- ---------------------------------------------------------------------------
CREATE TABLE admins (
    id              SERIAL PRIMARY KEY,
    email           VARCHAR(255) UNIQUE NOT NULL,
    -- scrypt, stored as '<salt-hex>:<derived-key-hex>'. Never a plaintext or
    -- reversible value; see backend/src/auth/password.ts.
    password_hash   VARCHAR(255) NOT NULL,
    display_name    VARCHAR(100) NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_login_at   TIMESTAMPTZ
);

-- ---------------------------------------------------------------------------
-- Editorial layer (added for the admin dashboard).
--
-- Two related concerns:
--   * `competition_editions.is_published` gates what the public API returns.
--     Defaults to FALSE: an edition is invisible until someone has looked at it
--     and said it is clean enough to show.
--   * `data_flags` records what still needs attention, on any entity. A flag at
--     severity BLOCKER prevents its edition from being published, which is what
--     ties the two together — you cannot publish over a known problem.
-- ---------------------------------------------------------------------------
ALTER TABLE competition_editions
    ADD COLUMN is_published  BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN published_at  TIMESTAMPTZ,
    ADD COLUMN published_by  INT REFERENCES admins(id);

CREATE TABLE data_flags (
    id              SERIAL PRIMARY KEY,
    entity_type     VARCHAR(30) NOT NULL
                        CHECK (entity_type IN ('competition_edition','match','match_event','team','player')),
    entity_id       INT NOT NULL,
    -- BLOCKER stops publication; WARNING and INFO are advisory.
    severity        VARCHAR(10) NOT NULL DEFAULT 'WARNING'
                        CHECK (severity IN ('INFO','WARNING','BLOCKER')),
    reason          TEXT NOT NULL,
    status          VARCHAR(10) NOT NULL DEFAULT 'OPEN'
                        CHECK (status IN ('OPEN','RESOLVED')),
    created_by      INT REFERENCES admins(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_by     INT REFERENCES admins(id),
    resolved_at     TIMESTAMPTZ,
    resolution_note TEXT
);

-- The dashboard's hot path: open flags for a given entity.
CREATE INDEX data_flags_open_idx ON data_flags (entity_type, entity_id) WHERE status = 'OPEN';
CREATE INDEX data_flags_status_idx ON data_flags (status, severity);
