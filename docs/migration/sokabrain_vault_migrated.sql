--
-- PostgreSQL database dump
--

\restrict SgLtMaQEQHBPcF9EZVgfFP9UzqduC13GyeQOoq4dJW3E4q9GisCVhbmWf5h1wvP

-- Dumped from database version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS '';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: coach_team_stints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.coach_team_stints (
    id integer NOT NULL,
    coach_id integer NOT NULL,
    team_id integer NOT NULL,
    role character varying(20) DEFAULT 'HEAD_COACH'::character varying,
    start_date date,
    end_date date
);


--
-- Name: coach_team_stints_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.coach_team_stints_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: coach_team_stints_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.coach_team_stints_id_seq OWNED BY public.coach_team_stints.id;


--
-- Name: coaches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.coaches (
    id integer NOT NULL,
    full_name character varying(150) NOT NULL,
    dob date,
    nationality_id integer,
    photo_url character varying(255)
);


--
-- Name: coaches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.coaches_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: coaches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.coaches_id_seq OWNED BY public.coaches.id;


--
-- Name: competition_edition_teams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.competition_edition_teams (
    id integer NOT NULL,
    competition_edition_id integer NOT NULL,
    team_id integer NOT NULL,
    group_id integer
);


--
-- Name: competition_edition_teams_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.competition_edition_teams_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: competition_edition_teams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.competition_edition_teams_id_seq OWNED BY public.competition_edition_teams.id;


--
-- Name: competition_editions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.competition_editions (
    id integer NOT NULL,
    competition_id integer NOT NULL,
    season_id integer NOT NULL,
    host_country_id integer,
    format character varying(30),
    num_teams smallint,
    CONSTRAINT competition_editions_format_check CHECK (((format)::text = ANY ((ARRAY['ROUND_ROBIN'::character varying, 'GROUPS_KNOCKOUT'::character varying, 'KNOCKOUT'::character varying])::text[])))
);


--
-- Name: competition_editions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.competition_editions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: competition_editions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.competition_editions_id_seq OWNED BY public.competition_editions.id;


--
-- Name: competition_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.competition_groups (
    id integer NOT NULL,
    competition_edition_id integer NOT NULL,
    name character varying(10) NOT NULL
);


--
-- Name: competition_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.competition_groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: competition_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.competition_groups_id_seq OWNED BY public.competition_groups.id;


--
-- Name: competitions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.competitions (
    id integer NOT NULL,
    name character varying(150) NOT NULL,
    slug character varying(160) NOT NULL,
    type character varying(30) NOT NULL,
    country_id integer,
    confederation_id smallint,
    tier smallint,
    logo_url character varying(255),
    CONSTRAINT competitions_type_check CHECK (((type)::text = ANY ((ARRAY['LEAGUE'::character varying, 'DOMESTIC_CUP'::character varying, 'SUPER_CUP'::character varying, 'CONTINENTAL_CLUB'::character varying, 'CONTINENTAL_NATIONAL'::character varying, 'WORLD_CUP'::character varying, 'FRIENDLY'::character varying, 'QUALIFIER'::character varying])::text[])))
);


--
-- Name: competitions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.competitions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: competitions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.competitions_id_seq OWNED BY public.competitions.id;


--
-- Name: confederations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.confederations (
    id smallint NOT NULL,
    code character varying(10) NOT NULL,
    name character varying(100) NOT NULL
);


--
-- Name: confederations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.confederations_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: confederations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.confederations_id_seq OWNED BY public.confederations.id;


--
-- Name: countries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.countries (
    id integer NOT NULL,
    iso_code character(3),
    name character varying(100) NOT NULL,
    full_name character varying(150),
    confederation_id smallint,
    flag_url character varying(255)
);


--
-- Name: countries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.countries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: countries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.countries_id_seq OWNED BY public.countries.id;


--
-- Name: data_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_sources (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    type character varying(20),
    base_url character varying(255),
    CONSTRAINT data_sources_type_check CHECK (((type)::text = ANY ((ARRAY['INTERNAL_LEGACY'::character varying, 'SCRAPED'::character varying, 'API'::character varying, 'MANUAL'::character varying])::text[])))
);


--
-- Name: data_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.data_sources_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.data_sources_id_seq OWNED BY public.data_sources.id;


--
-- Name: entity_source_map; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.entity_source_map (
    id integer NOT NULL,
    entity_type character varying(30) NOT NULL,
    entity_id integer NOT NULL,
    data_source_id integer NOT NULL,
    external_id character varying(100),
    external_url character varying(255),
    confidence numeric(3,2) DEFAULT 1.0,
    last_synced_at timestamp with time zone DEFAULT now()
);


--
-- Name: entity_source_map_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.entity_source_map_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: entity_source_map_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.entity_source_map_id_seq OWNED BY public.entity_source_map.id;


--
-- Name: match_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.match_events (
    id integer NOT NULL,
    match_id integer NOT NULL,
    team_id integer,
    player_id integer,
    related_player_id integer,
    minute smallint,
    added_time smallint,
    type character varying(20) NOT NULL,
    detail jsonb,
    CONSTRAINT match_events_type_check CHECK (((type)::text = ANY ((ARRAY['GOAL'::character varying, 'OWN_GOAL'::character varying, 'PENALTY_GOAL'::character varying, 'PENALTY_MISS'::character varying, 'YELLOW_CARD'::character varying, 'SECOND_YELLOW'::character varying, 'RED_CARD'::character varying, 'SUBSTITUTION'::character varying, 'VAR_REVIEW'::character varying])::text[])))
);


--
-- Name: match_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.match_events_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: match_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.match_events_id_seq OWNED BY public.match_events.id;


--
-- Name: match_lineups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.match_lineups (
    id integer NOT NULL,
    match_id integer NOT NULL,
    team_id integer NOT NULL,
    player_id integer NOT NULL,
    role character varying(10) NOT NULL,
    "position" character varying(3),
    shirt_number smallint,
    minute_on smallint,
    minute_off smallint,
    CONSTRAINT match_lineups_role_check CHECK (((role)::text = ANY ((ARRAY['STARTER'::character varying, 'SUB'::character varying])::text[])))
);


--
-- Name: match_lineups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.match_lineups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: match_lineups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.match_lineups_id_seq OWNED BY public.match_lineups.id;


--
-- Name: match_player_ratings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.match_player_ratings (
    match_id integer NOT NULL,
    player_id integer NOT NULL,
    rating numeric(3,1),
    is_motm boolean DEFAULT false
);


--
-- Name: match_team_stats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.match_team_stats (
    match_id integer NOT NULL,
    team_id integer NOT NULL,
    possession_pct numeric(4,1),
    shots smallint,
    shots_on_target smallint,
    corners smallint,
    fouls smallint,
    offsides smallint
);


--
-- Name: matches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.matches (
    id integer NOT NULL,
    competition_edition_id integer NOT NULL,
    group_id integer,
    round character varying(30),
    home_team_id integer NOT NULL,
    away_team_id integer NOT NULL,
    stadium_id integer,
    kickoff_at timestamp with time zone,
    status character varying(15) DEFAULT 'SCHEDULED'::character varying NOT NULL,
    home_score smallint,
    away_score smallint,
    home_score_et smallint,
    away_score_et smallint,
    home_score_pens smallint,
    away_score_pens smallint,
    attendance integer,
    referee_id integer,
    CONSTRAINT matches_status_check CHECK (((status)::text = ANY ((ARRAY['SCHEDULED'::character varying, 'LIVE'::character varying, 'FULL_TIME'::character varying, 'POSTPONED'::character varying, 'ABANDONED'::character varying, 'CANCELLED'::character varying])::text[])))
);


--
-- Name: matches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.matches_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: matches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.matches_id_seq OWNED BY public.matches.id;


--
-- Name: player_team_stints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.player_team_stints (
    id integer NOT NULL,
    player_id integer NOT NULL,
    team_id integer NOT NULL,
    start_date date,
    end_date date,
    shirt_number smallint,
    transfer_fee numeric(12,2),
    transfer_type character varying(20),
    CONSTRAINT player_team_stints_transfer_type_check CHECK (((transfer_type)::text = ANY ((ARRAY['PERMANENT'::character varying, 'LOAN'::character varying, 'FREE'::character varying, 'YOUTH'::character varying])::text[])))
);


--
-- Name: player_team_stints_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.player_team_stints_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: player_team_stints_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.player_team_stints_id_seq OWNED BY public.player_team_stints.id;


--
-- Name: players; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.players (
    id integer NOT NULL,
    full_name character varying(150) NOT NULL,
    first_name character varying(60),
    last_name character varying(60),
    dob date,
    nationality_id integer,
    "position" character varying(3),
    height_cm smallint,
    preferred_foot character varying(10),
    photo_url character varying(255),
    CONSTRAINT players_position_check CHECK ((("position")::text = ANY ((ARRAY['GK'::character varying, 'DF'::character varying, 'MF'::character varying, 'FW'::character varying])::text[]))),
    CONSTRAINT players_preferred_foot_check CHECK (((preferred_foot)::text = ANY ((ARRAY['LEFT'::character varying, 'RIGHT'::character varying, 'BOTH'::character varying])::text[])))
);


--
-- Name: players_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.players_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: players_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.players_id_seq OWNED BY public.players.id;


--
-- Name: reconciliation_diffs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reconciliation_diffs (
    id integer NOT NULL,
    reconciliation_run_id integer NOT NULL,
    entity_id_a integer,
    entity_id_b integer,
    field_name character varying(50) NOT NULL,
    value_a text,
    value_b text,
    resolution character varying(15) DEFAULT 'PENDING'::character varying,
    resolved_value text,
    resolved_at timestamp with time zone,
    CONSTRAINT reconciliation_diffs_resolution_check CHECK (((resolution)::text = ANY ((ARRAY['PENDING'::character varying, 'ACCEPT_A'::character varying, 'ACCEPT_B'::character varying, 'BOTH_AGREE'::character varying, 'MANUAL'::character varying])::text[])))
);


--
-- Name: reconciliation_diffs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reconciliation_diffs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reconciliation_diffs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reconciliation_diffs_id_seq OWNED BY public.reconciliation_diffs.id;


--
-- Name: reconciliation_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reconciliation_runs (
    id integer NOT NULL,
    entity_type character varying(30) NOT NULL,
    data_source_a_id integer NOT NULL,
    data_source_b_id integer NOT NULL,
    run_at timestamp with time zone DEFAULT now(),
    notes text
);


--
-- Name: reconciliation_runs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reconciliation_runs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reconciliation_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reconciliation_runs_id_seq OWNED BY public.reconciliation_runs.id;


--
-- Name: seasons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.seasons (
    id integer NOT NULL,
    label character varying(20) NOT NULL,
    start_date date,
    end_date date
);


--
-- Name: seasons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.seasons_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: seasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.seasons_id_seq OWNED BY public.seasons.id;


--
-- Name: stadiums; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stadiums (
    id integer NOT NULL,
    name character varying(150) NOT NULL,
    city character varying(100),
    country_id integer,
    capacity integer,
    latitude numeric(9,6),
    longitude numeric(9,6)
);


--
-- Name: stadiums_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stadiums_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stadiums_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stadiums_id_seq OWNED BY public.stadiums.id;


--
-- Name: teams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.teams (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    short_name character varying(10),
    type character varying(10) NOT NULL,
    country_id integer NOT NULL,
    stadium_id integer,
    founded_year smallint,
    logo_url character varying(255),
    CONSTRAINT teams_type_check CHECK (((type)::text = ANY ((ARRAY['CLUB'::character varying, 'NATIONAL'::character varying])::text[])))
);


--
-- Name: teams_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.teams_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: teams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.teams_id_seq OWNED BY public.teams.id;


--
-- Name: coach_team_stints id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coach_team_stints ALTER COLUMN id SET DEFAULT nextval('public.coach_team_stints_id_seq'::regclass);


--
-- Name: coaches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coaches ALTER COLUMN id SET DEFAULT nextval('public.coaches_id_seq'::regclass);


--
-- Name: competition_edition_teams id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competition_edition_teams ALTER COLUMN id SET DEFAULT nextval('public.competition_edition_teams_id_seq'::regclass);


--
-- Name: competition_editions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competition_editions ALTER COLUMN id SET DEFAULT nextval('public.competition_editions_id_seq'::regclass);


--
-- Name: competition_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competition_groups ALTER COLUMN id SET DEFAULT nextval('public.competition_groups_id_seq'::regclass);


--
-- Name: competitions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competitions ALTER COLUMN id SET DEFAULT nextval('public.competitions_id_seq'::regclass);


--
-- Name: confederations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.confederations ALTER COLUMN id SET DEFAULT nextval('public.confederations_id_seq'::regclass);


--
-- Name: countries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.countries ALTER COLUMN id SET DEFAULT nextval('public.countries_id_seq'::regclass);


--
-- Name: data_sources id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_sources ALTER COLUMN id SET DEFAULT nextval('public.data_sources_id_seq'::regclass);


--
-- Name: entity_source_map id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entity_source_map ALTER COLUMN id SET DEFAULT nextval('public.entity_source_map_id_seq'::regclass);


--
-- Name: match_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.match_events ALTER COLUMN id SET DEFAULT nextval('public.match_events_id_seq'::regclass);


--
-- Name: match_lineups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.match_lineups ALTER COLUMN id SET DEFAULT nextval('public.match_lineups_id_seq'::regclass);


--
-- Name: matches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.matches ALTER COLUMN id SET DEFAULT nextval('public.matches_id_seq'::regclass);


--
-- Name: player_team_stints id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_team_stints ALTER COLUMN id SET DEFAULT nextval('public.player_team_stints_id_seq'::regclass);


--
-- Name: players id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.players ALTER COLUMN id SET DEFAULT nextval('public.players_id_seq'::regclass);


--
-- Name: reconciliation_diffs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reconciliation_diffs ALTER COLUMN id SET DEFAULT nextval('public.reconciliation_diffs_id_seq'::regclass);


--
-- Name: reconciliation_runs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reconciliation_runs ALTER COLUMN id SET DEFAULT nextval('public.reconciliation_runs_id_seq'::regclass);


--
-- Name: seasons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.seasons ALTER COLUMN id SET DEFAULT nextval('public.seasons_id_seq'::regclass);


--
-- Name: stadiums id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stadiums ALTER COLUMN id SET DEFAULT nextval('public.stadiums_id_seq'::regclass);


--
-- Name: teams id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams ALTER COLUMN id SET DEFAULT nextval('public.teams_id_seq'::regclass);


--
-- Data for Name: coach_team_stints; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.coach_team_stints (id, coach_id, team_id, role, start_date, end_date) FROM stdin;
1	1	76	HEAD_COACH	2016-08-01	\N
2	2	1	HEAD_COACH	2016-08-01	\N
3	3	2	HEAD_COACH	2016-08-01	\N
4	4	4	HEAD_COACH	2015-08-01	\N
5	5	5	HEAD_COACH	2016-08-01	\N
6	6	7	HEAD_COACH	2016-08-01	\N
7	7	8	HEAD_COACH	2016-08-01	\N
8	8	11	HEAD_COACH	2015-08-01	\N
9	9	12	HEAD_COACH	2016-08-01	\N
10	10	13	HEAD_COACH	2016-08-01	\N
11	11	15	HEAD_COACH	2016-08-01	\N
12	12	16	HEAD_COACH	2016-08-01	\N
13	13	17	HEAD_COACH	2016-08-01	\N
14	14	88	HEAD_COACH	2017-08-01	\N
15	15	87	HEAD_COACH	2017-08-01	\N
16	16	86	HEAD_COACH	2017-08-01	\N
17	17	11	HEAD_COACH	2018-08-01	\N
18	18	76	HEAD_COACH	2018-08-01	\N
19	19	99	HEAD_COACH	2018-08-01	\N
20	20	100	HEAD_COACH	2018-08-01	\N
21	21	1	HEAD_COACH	2018-08-01	\N
22	22	13	HEAD_COACH	2018-08-01	\N
\.


--
-- Data for Name: coaches; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.coaches (id, full_name, dob, nationality_id, photo_url) FROM stdin;
1	George Lwandamina	\N	58	\N
2	Aristica Cioaba	\N	56	\N
3	Etienne Ndairagije	\N	4	\N
4	Mecky Mexime	\N	56	\N
5	Patric Phiri	\N	58	\N
6	Zuberi Katwila	\N	56	\N
7	Ramadhan Msanzurwino	\N	56	\N
8	Joseph Omog	\N	5	\N
9	Patrick Liewig	\N	56	\N
10	Abdul Mingange	\N	56	\N
11	Abdulmutic Hadji	\N	56	\N
12	Kally Ongalla	\N	56	\N
13	Ali Bushir Mahmoud	\N	56	\N
14	Hans Pluijm	\N	56	\N
15	Seleman Matola	\N	56	\N
16	Hassan Mustapha	\N	56	\N
17	Patrick Aussems	\N	56	\N
18	Mwinyi Zahera	\N	58	\N
19	Mbwana Makata	\N	56	\N
20	Juma Mgunda	\N	56	\N
21	Hemed Morroco	\N	56	\N
22	Abdallah Mohamed	\N	56	\N
\.


--
-- Data for Name: competition_edition_teams; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.competition_edition_teams (id, competition_edition_id, team_id, group_id) FROM stdin;
\.


--
-- Data for Name: competition_editions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.competition_editions (id, competition_id, season_id, host_country_id, format, num_teams) FROM stdin;
1	1	1	\N	\N	\N
2	9	1	\N	\N	\N
3	4	1	\N	\N	\N
4	5	1	\N	\N	\N
5	6	1	\N	\N	\N
6	1	3	\N	\N	\N
7	10	3	\N	\N	\N
8	11	3	\N	\N	\N
9	12	3	\N	\N	\N
10	13	3	\N	\N	\N
11	5	3	\N	\N	\N
12	14	3	\N	\N	\N
13	15	3	\N	\N	\N
14	16	3	\N	\N	\N
15	9	3	\N	\N	\N
16	6	3	\N	\N	\N
17	1	4	\N	\N	\N
18	4	3	\N	\N	\N
19	9	4	\N	\N	\N
20	11	4	\N	\N	\N
21	17	4	\N	\N	\N
22	6	4	\N	\N	\N
23	15	4	\N	\N	\N
24	12	4	\N	\N	\N
25	2	4	\N	\N	\N
\.


--
-- Data for Name: competition_groups; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.competition_groups (id, competition_edition_id, name) FROM stdin;
\.


--
-- Data for Name: competitions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.competitions (id, name, slug, type, country_id, confederation_id, tier, logo_url) FROM stdin;
1	Premier League	premier-league	LEAGUE	56	\N	1	/images/logo-competitions/VPL.png
2	First Division League	first-division-league	LEAGUE	56	\N	2	/images/logo-competitions/FDL.jpg
3	Second Division League	second-division-league	LEAGUE	56	\N	3	/images/logo-competitions/SDL.jpg
4	CECAFA KAGAME CHAMPIONSHIP	cecafa-kagame-championship	CONTINENTAL_CLUB	\N	1	\N	/images/logo-competitions/CECAFA.jpg
5	CHAMPIONS LEAGUE	champions-league	CONTINENTAL_CLUB	\N	1	\N	/images/logo-competitions/MABINGWA.jpeg
6	CAF CONFEDERATION	caf-confederation	CONTINENTAL_CLUB	\N	1	\N	/images/logo-competitions/CAF.png
9	CHAMPIONS PRIMARY STAGE	champions-primary-stage	CONTINENTAL_CLUB	\N	1	\N	/images/logo-competitions/Friendly.jpeg
10	Azam Federation cup	azam-federation-cup	DOMESTIC_CUP	56	\N	\N	/images/logo-competitions/AF CUP.jpeg
11	Ngao ya jamii	ngao-ya-jamii	SUPER_CUP	56	\N	\N	/images/logo-competitions/NGA.png
12	African Cup of Nations Qualification	african-cup-of-nations-qualification	QUALIFIER	\N	1	\N	/images/logo-competitions/AFCON.png
13	Mapinduzi Cup	mapinduzi-cup	DOMESTIC_CUP	56	\N	\N	\N
14	SportPesa Super Cup	sportpesa-super-cup	SUPER_CUP	23	\N	\N	/images/logo-competitions/SportPesa.jpeg
15	Afcon-U17	afcon-u17	CONTINENTAL_NATIONAL	\N	1	\N	/images/logo-competitions/AFCON-U17.jpeg
16	Africa Cup of Nations	africa-cup-of-nations	CONTINENTAL_NATIONAL	\N	1	\N	/images/logo-competitions/AFCON2019.png
17	Kenya premier league	kenya-premier-league	LEAGUE	23	\N	1	/images/logo-competitions/KE.png
18	KENYA FA CUP	kenya-fa-cup	DOMESTIC_CUP	23	\N	\N	/images/logo-competitions/KFA.png
19	CECAFA	cecafa	CONTINENTAL_NATIONAL	\N	1	\N	\N
\.


--
-- Data for Name: confederations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.confederations (id, code, name) FROM stdin;
1	CAF	CAF
2	UEFA	UEFA
3	CONMEBOL	CONMEBOL
4	CONCACAF	CONCACAF
5	AFC	AFC
6	OFC	OFC
\.


--
-- Data for Name: countries; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.countries (id, iso_code, name, full_name, confederation_id, flag_url) FROM stdin;
1	DZA	Algeria	People’s Democratic Republic of Algeria	1	\N
2	AGO	Angola	Republic of Angola	1	\N
3	BWA	Botswana	Republic of Botswana	1	\N
4	BDI	Burundi	Republic of Burundi	1	\N
5	CMR	Cameroon	Republic of Cameroon	1	\N
6	CPV	Cape Verde	Republic of Cape Verde	1	\N
7	CAF	Central African Republic	Central African Republic	1	\N
8	TCD	Chad	Republic of Chad	1	\N
9	COM	Comoros	Union of the Comoros	1	\N
10	MYT	Mayotte	Departmental Collectivity of Mayotte	1	\N
11	COG	Congo	Republic of the Congo	1	\N
12	COD	Congo, the Democratic Republic of the	Democratic Republic of the Congo	1	\N
13	BEN	Benin	Republic of Benin	1	\N
14	GNQ	Equatorial Guinea	Republic of Equatorial Guinea	1	\N
15	ETH	Ethiopia	Federal Democratic Republic of Ethiopia	1	\N
16	ERI	Eritrea	State of Eritrea	1	\N
17	DJI	Djibouti	Republic of Djibouti	1	\N
18	GAB	Gabon	Gabonese Republic	1	\N
19	GMB	Gambia	Republic of the Gambia	1	\N
20	GHA	Ghana	Republic of Ghana	1	\N
21	GIN	Guinea	Republic of Guinea	1	\N
22	CIV	Côte d'Ivoire	Republic of Côte d’Ivoire	1	\N
23	KEN	Kenya	Republic of Kenya	1	\N
24	LSO	Lesotho	Kingdom of Lesotho	1	\N
25	LBR	Liberia	Republic of Liberia	1	\N
26	LBY	Libya	Socialist People’s Libyan Arab Jamahiriya	1	\N
27	MDG	Madagascar	Republic of Madagascar	1	\N
28	MWI	Malawi	Republic of Malawi	1	\N
29	MLI	Mali	Republic of Mali	1	\N
30	MRT	Mauritania	Islamic Republic of Mauritania	1	\N
31	MUS	Mauritius	Republic of Mauritius	1	\N
32	MAR	Morocco	Kingdom of Morocco	1	\N
33	MOZ	Mozambique	Republic of Mozambique	1	\N
34	NAM	Namibia	Republic of Namibia	1	\N
35	NER	Niger	Republic of Niger	1	\N
36	NGA	Nigeria	Federal Republic of Nigeria	1	\N
37	GNB	Guinea-Bissau	Republic of Guinea-Bissau	1	\N
38	REU	Réunion	Réunion	1	\N
39	RWA	Rwanda	Republic of Rwanda	1	\N
40	SHN	Saint Helena, Ascension and Tristan da Cunha	Saint Helena, Ascension and Tristan da Cunha	1	\N
41	STP	Sao Tome and Principe	Democratic Republic of São Tomé and Príncipe	1	\N
42	SEN	Senegal	Republic of Senegal	1	\N
43	SYC	Seychelles	Republic of Seychelles	1	\N
44	SLE	Sierra Leone	Republic of Sierra Leone	1	\N
45	SOM	Somalia	Somali Republic	1	\N
46	ZAF	South Africa	Republic of South Africa	1	\N
47	ZWE	Zimbabwe	Republic of Zimbabwe	1	\N
48	SSD	South Sudan	Republic of South Sudan	1	\N
49	SDN	Sudan	Republic of the Sudan	1	\N
50	ESH	Western Sahara	Western Sahara	1	\N
51	SWZ	Swaziland	Kingdom of Swaziland	1	\N
52	TGO	Togo	Togolese Republic	1	\N
53	TUN	Tunisia	Republic of Tunisia	1	\N
54	UGA	Uganda	Republic of Uganda	1	\N
55	EGY	Egypt	Arab Republic of Egypt	1	\N
56	TZA	Tanzania, United Republic of	United Republic of Tanzania	1	\N
57	BFA	Burkina Faso	Burkina Faso	1	\N
58	ZMB	Zambia	Republic of Zambia	1	\N
59	\N	Zanzibar	Zanzibar	\N	\N
\.


--
-- Data for Name: data_sources; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.data_sources (id, name, type, base_url) FROM stdin;
1	legacy_sokafc	INTERNAL_LEGACY	\N
\.


--
-- Data for Name: entity_source_map; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.entity_source_map (id, entity_type, entity_id, data_source_id, external_id, external_url, confidence, last_synced_at) FROM stdin;
1	country	1	1	1	\N	1.00	2026-09-06 22:42:06.816471+00
2	country	2	1	2	\N	1.00	2026-09-06 22:42:06.816471+00
3	country	3	1	3	\N	1.00	2026-09-06 22:42:06.816471+00
4	country	4	1	4	\N	1.00	2026-09-06 22:42:06.816471+00
5	country	5	1	5	\N	1.00	2026-09-06 22:42:06.816471+00
6	country	6	1	6	\N	1.00	2026-09-06 22:42:06.816471+00
7	country	7	1	7	\N	1.00	2026-09-06 22:42:06.816471+00
8	country	8	1	8	\N	1.00	2026-09-06 22:42:06.816471+00
9	country	9	1	9	\N	1.00	2026-09-06 22:42:06.816471+00
10	country	10	1	10	\N	1.00	2026-09-06 22:42:06.816471+00
11	country	11	1	11	\N	1.00	2026-09-06 22:42:06.816471+00
12	country	12	1	12	\N	1.00	2026-09-06 22:42:06.816471+00
13	country	13	1	13	\N	1.00	2026-09-06 22:42:06.816471+00
14	country	14	1	14	\N	1.00	2026-09-06 22:42:06.816471+00
15	country	15	1	15	\N	1.00	2026-09-06 22:42:06.816471+00
16	country	16	1	16	\N	1.00	2026-09-06 22:42:06.816471+00
17	country	17	1	17	\N	1.00	2026-09-06 22:42:06.816471+00
18	country	18	1	18	\N	1.00	2026-09-06 22:42:06.816471+00
19	country	19	1	19	\N	1.00	2026-09-06 22:42:06.816471+00
20	country	20	1	20	\N	1.00	2026-09-06 22:42:06.816471+00
21	country	21	1	21	\N	1.00	2026-09-06 22:42:06.816471+00
22	country	22	1	22	\N	1.00	2026-09-06 22:42:06.816471+00
23	country	23	1	23	\N	1.00	2026-09-06 22:42:06.816471+00
24	country	24	1	24	\N	1.00	2026-09-06 22:42:06.816471+00
25	country	25	1	25	\N	1.00	2026-09-06 22:42:06.816471+00
26	country	26	1	26	\N	1.00	2026-09-06 22:42:06.816471+00
27	country	27	1	27	\N	1.00	2026-09-06 22:42:06.816471+00
28	country	28	1	28	\N	1.00	2026-09-06 22:42:06.816471+00
29	country	29	1	29	\N	1.00	2026-09-06 22:42:06.816471+00
30	country	30	1	30	\N	1.00	2026-09-06 22:42:06.816471+00
31	country	31	1	31	\N	1.00	2026-09-06 22:42:06.816471+00
32	country	32	1	32	\N	1.00	2026-09-06 22:42:06.816471+00
33	country	33	1	33	\N	1.00	2026-09-06 22:42:06.816471+00
34	country	34	1	34	\N	1.00	2026-09-06 22:42:06.816471+00
35	country	35	1	35	\N	1.00	2026-09-06 22:42:06.816471+00
36	country	36	1	36	\N	1.00	2026-09-06 22:42:06.816471+00
37	country	37	1	37	\N	1.00	2026-09-06 22:42:06.816471+00
38	country	38	1	38	\N	1.00	2026-09-06 22:42:06.816471+00
39	country	39	1	39	\N	1.00	2026-09-06 22:42:06.816471+00
40	country	40	1	40	\N	1.00	2026-09-06 22:42:06.816471+00
41	country	41	1	41	\N	1.00	2026-09-06 22:42:06.816471+00
42	country	42	1	42	\N	1.00	2026-09-06 22:42:06.816471+00
43	country	43	1	43	\N	1.00	2026-09-06 22:42:06.816471+00
44	country	44	1	44	\N	1.00	2026-09-06 22:42:06.816471+00
45	country	45	1	45	\N	1.00	2026-09-06 22:42:06.816471+00
46	country	46	1	46	\N	1.00	2026-09-06 22:42:06.816471+00
47	country	47	1	47	\N	1.00	2026-09-06 22:42:06.816471+00
48	country	48	1	48	\N	1.00	2026-09-06 22:42:06.816471+00
49	country	49	1	49	\N	1.00	2026-09-06 22:42:06.816471+00
50	country	50	1	50	\N	1.00	2026-09-06 22:42:06.816471+00
51	country	51	1	51	\N	1.00	2026-09-06 22:42:06.816471+00
52	country	52	1	52	\N	1.00	2026-09-06 22:42:06.816471+00
53	country	53	1	53	\N	1.00	2026-09-06 22:42:06.816471+00
54	country	54	1	54	\N	1.00	2026-09-06 22:42:06.816471+00
55	country	55	1	55	\N	1.00	2026-09-06 22:42:06.816471+00
56	country	56	1	56	\N	1.00	2026-09-06 22:42:06.816471+00
57	country	57	1	57	\N	1.00	2026-09-06 22:42:06.816471+00
58	country	58	1	58	\N	1.00	2026-09-06 22:42:06.816471+00
59	country	59	1	59	\N	1.00	2026-09-06 22:42:06.816471+00
60	stadium	1	1	1	\N	1.00	2026-09-06 22:42:06.816471+00
61	stadium	2	1	2	\N	1.00	2026-09-06 22:42:06.816471+00
62	stadium	3	1	3	\N	1.00	2026-09-06 22:42:06.816471+00
63	stadium	4	1	4	\N	1.00	2026-09-06 22:42:06.816471+00
64	stadium	5	1	5	\N	1.00	2026-09-06 22:42:06.816471+00
65	stadium	6	1	6	\N	1.00	2026-09-06 22:42:06.816471+00
66	stadium	7	1	7	\N	1.00	2026-09-06 22:42:06.816471+00
67	stadium	8	1	8	\N	1.00	2026-09-06 22:42:06.816471+00
68	stadium	9	1	9	\N	1.00	2026-09-06 22:42:06.816471+00
69	stadium	10	1	10	\N	1.00	2026-09-06 22:42:06.816471+00
70	stadium	11	1	11	\N	1.00	2026-09-06 22:42:06.816471+00
71	stadium	12	1	12	\N	1.00	2026-09-06 22:42:06.816471+00
72	stadium	13	1	13	\N	1.00	2026-09-06 22:42:06.816471+00
73	stadium	14	1	14	\N	1.00	2026-09-06 22:42:06.816471+00
74	stadium	16	1	16	\N	1.00	2026-09-06 22:42:06.816471+00
75	stadium	17	1	17	\N	1.00	2026-09-06 22:42:06.816471+00
76	stadium	18	1	18	\N	1.00	2026-09-06 22:42:06.816471+00
77	stadium	19	1	19	\N	1.00	2026-09-06 22:42:06.816471+00
78	stadium	20	1	20	\N	1.00	2026-09-06 22:42:06.816471+00
79	stadium	21	1	21	\N	1.00	2026-09-06 22:42:06.816471+00
80	stadium	22	1	22	\N	1.00	2026-09-06 22:42:06.816471+00
81	stadium	23	1	23	\N	1.00	2026-09-06 22:42:06.816471+00
82	stadium	24	1	24	\N	1.00	2026-09-06 22:42:06.816471+00
83	stadium	25	1	25	\N	1.00	2026-09-06 22:42:06.816471+00
84	stadium	26	1	26	\N	1.00	2026-09-06 22:42:06.816471+00
85	stadium	27	1	27	\N	1.00	2026-09-06 22:42:06.816471+00
86	stadium	28	1	28	\N	1.00	2026-09-06 22:42:06.816471+00
87	stadium	29	1	29	\N	1.00	2026-09-06 22:42:06.816471+00
88	stadium	30	1	30	\N	1.00	2026-09-06 22:42:06.816471+00
89	stadium	32	1	32	\N	1.00	2026-09-06 22:42:06.816471+00
90	stadium	33	1	33	\N	1.00	2026-09-06 22:42:06.816471+00
91	stadium	34	1	34	\N	1.00	2026-09-06 22:42:06.816471+00
92	stadium	35	1	35	\N	1.00	2026-09-06 22:42:06.816471+00
93	stadium	36	1	36	\N	1.00	2026-09-06 22:42:06.816471+00
94	stadium	37	1	37	\N	1.00	2026-09-06 22:42:06.816471+00
95	stadium	38	1	38	\N	1.00	2026-09-06 22:42:06.816471+00
96	stadium	39	1	39	\N	1.00	2026-09-06 22:42:06.816471+00
97	stadium	40	1	40	\N	1.00	2026-09-06 22:42:06.816471+00
98	stadium	41	1	41	\N	1.00	2026-09-06 22:42:06.816471+00
99	stadium	42	1	42	\N	1.00	2026-09-06 22:42:06.816471+00
100	stadium	43	1	43	\N	1.00	2026-09-06 22:42:06.816471+00
101	stadium	44	1	44	\N	1.00	2026-09-06 22:42:06.816471+00
102	stadium	45	1	45	\N	1.00	2026-09-06 22:42:06.816471+00
103	stadium	46	1	46	\N	1.00	2026-09-06 22:42:06.816471+00
104	stadium	47	1	47	\N	1.00	2026-09-06 22:42:06.816471+00
105	stadium	48	1	48	\N	1.00	2026-09-06 22:42:06.816471+00
106	stadium	49	1	49	\N	1.00	2026-09-06 22:42:06.816471+00
107	stadium	50	1	50	\N	1.00	2026-09-06 22:42:06.816471+00
108	stadium	51	1	51	\N	1.00	2026-09-06 22:42:06.816471+00
109	stadium	52	1	52	\N	1.00	2026-09-06 22:42:06.816471+00
110	season	1	1	1	\N	1.00	2026-09-06 22:42:06.816471+00
111	season	2	1	2	\N	1.00	2026-09-06 22:42:06.816471+00
112	season	3	1	3	\N	1.00	2026-09-06 22:42:06.816471+00
113	season	4	1	4	\N	1.00	2026-09-06 22:42:06.816471+00
114	competition	1	1	1	\N	1.00	2026-09-06 22:42:06.816471+00
115	competition	2	1	2	\N	1.00	2026-09-06 22:42:06.816471+00
116	competition	3	1	3	\N	1.00	2026-09-06 22:42:06.816471+00
117	competition	4	1	4	\N	1.00	2026-09-06 22:42:06.816471+00
118	competition	5	1	5	\N	1.00	2026-09-06 22:42:06.816471+00
119	competition	6	1	6	\N	1.00	2026-09-06 22:42:06.816471+00
120	competition	9	1	9	\N	1.00	2026-09-06 22:42:06.816471+00
121	competition	10	1	10	\N	1.00	2026-09-06 22:42:06.816471+00
122	competition	11	1	11	\N	1.00	2026-09-06 22:42:06.816471+00
123	competition	12	1	12	\N	1.00	2026-09-06 22:42:06.816471+00
124	competition	13	1	13	\N	1.00	2026-09-06 22:42:06.816471+00
125	competition	14	1	14	\N	1.00	2026-09-06 22:42:06.816471+00
126	competition	15	1	15	\N	1.00	2026-09-06 22:42:06.816471+00
127	competition	16	1	16	\N	1.00	2026-09-06 22:42:06.816471+00
128	competition	17	1	17	\N	1.00	2026-09-06 22:42:06.816471+00
129	competition	18	1	18	\N	1.00	2026-09-06 22:42:06.816471+00
130	competition	19	1	19	\N	1.00	2026-09-06 22:42:06.816471+00
131	team	1	1	1	\N	1.00	2026-09-06 22:42:06.816471+00
132	team	2	1	2	\N	1.00	2026-09-06 22:42:06.816471+00
133	team	3	1	3	\N	1.00	2026-09-06 22:42:06.816471+00
134	team	4	1	4	\N	1.00	2026-09-06 22:42:06.816471+00
135	team	5	1	5	\N	1.00	2026-09-06 22:42:06.816471+00
136	team	6	1	6	\N	1.00	2026-09-06 22:42:06.816471+00
137	team	7	1	7	\N	1.00	2026-09-06 22:42:06.816471+00
138	team	8	1	8	\N	1.00	2026-09-06 22:42:06.816471+00
139	team	9	1	9	\N	1.00	2026-09-06 22:42:06.816471+00
140	team	11	1	11	\N	1.00	2026-09-06 22:42:06.816471+00
141	team	12	1	12	\N	1.00	2026-09-06 22:42:06.816471+00
142	team	13	1	13	\N	1.00	2026-09-06 22:42:06.816471+00
143	team	15	1	15	\N	1.00	2026-09-06 22:42:06.816471+00
144	team	16	1	16	\N	1.00	2026-09-06 22:42:06.816471+00
145	team	17	1	17	\N	1.00	2026-09-06 22:42:06.816471+00
146	team	18	1	18	\N	1.00	2026-09-06 22:42:06.816471+00
147	team	23	1	23	\N	1.00	2026-09-06 22:42:06.816471+00
148	team	24	1	24	\N	1.00	2026-09-06 22:42:06.816471+00
149	team	25	1	25	\N	1.00	2026-09-06 22:42:06.816471+00
150	team	26	1	26	\N	1.00	2026-09-06 22:42:06.816471+00
151	team	27	1	27	\N	1.00	2026-09-06 22:42:06.816471+00
152	team	28	1	28	\N	1.00	2026-09-06 22:42:06.816471+00
153	team	29	1	29	\N	1.00	2026-09-06 22:42:06.816471+00
154	team	30	1	30	\N	1.00	2026-09-06 22:42:06.816471+00
155	team	31	1	31	\N	1.00	2026-09-06 22:42:06.816471+00
156	team	32	1	32	\N	1.00	2026-09-06 22:42:06.816471+00
157	team	33	1	33	\N	1.00	2026-09-06 22:42:06.816471+00
158	team	34	1	34	\N	1.00	2026-09-06 22:42:06.816471+00
159	team	35	1	35	\N	1.00	2026-09-06 22:42:06.816471+00
160	team	36	1	36	\N	1.00	2026-09-06 22:42:06.816471+00
161	team	37	1	37	\N	1.00	2026-09-06 22:42:06.816471+00
162	team	38	1	38	\N	1.00	2026-09-06 22:42:06.816471+00
163	team	39	1	39	\N	1.00	2026-09-06 22:42:06.816471+00
164	team	40	1	40	\N	1.00	2026-09-06 22:42:06.816471+00
165	team	41	1	41	\N	1.00	2026-09-06 22:42:06.816471+00
166	team	42	1	42	\N	1.00	2026-09-06 22:42:06.816471+00
167	team	43	1	43	\N	1.00	2026-09-06 22:42:06.816471+00
168	team	44	1	44	\N	1.00	2026-09-06 22:42:06.816471+00
169	team	45	1	45	\N	1.00	2026-09-06 22:42:06.816471+00
170	team	46	1	46	\N	1.00	2026-09-06 22:42:06.816471+00
171	team	47	1	47	\N	1.00	2026-09-06 22:42:06.816471+00
172	team	48	1	48	\N	1.00	2026-09-06 22:42:06.816471+00
173	team	49	1	49	\N	1.00	2026-09-06 22:42:06.816471+00
174	team	50	1	50	\N	1.00	2026-09-06 22:42:06.816471+00
175	team	51	1	51	\N	1.00	2026-09-06 22:42:06.816471+00
176	team	52	1	52	\N	1.00	2026-09-06 22:42:06.816471+00
177	team	53	1	53	\N	1.00	2026-09-06 22:42:06.816471+00
178	team	54	1	54	\N	1.00	2026-09-06 22:42:06.816471+00
179	team	55	1	55	\N	1.00	2026-09-06 22:42:06.816471+00
180	team	56	1	56	\N	1.00	2026-09-06 22:42:06.816471+00
181	team	57	1	57	\N	1.00	2026-09-06 22:42:06.816471+00
182	team	58	1	58	\N	1.00	2026-09-06 22:42:06.816471+00
183	team	59	1	59	\N	1.00	2026-09-06 22:42:06.816471+00
184	team	60	1	60	\N	1.00	2026-09-06 22:42:06.816471+00
185	team	61	1	61	\N	1.00	2026-09-06 22:42:06.816471+00
186	team	62	1	62	\N	1.00	2026-09-06 22:42:06.816471+00
187	team	63	1	63	\N	1.00	2026-09-06 22:42:06.816471+00
188	team	64	1	64	\N	1.00	2026-09-06 22:42:06.816471+00
189	team	65	1	65	\N	1.00	2026-09-06 22:42:06.816471+00
190	team	66	1	66	\N	1.00	2026-09-06 22:42:06.816471+00
191	team	69	1	69	\N	1.00	2026-09-06 22:42:06.816471+00
192	team	70	1	70	\N	1.00	2026-09-06 22:42:06.816471+00
193	team	71	1	71	\N	1.00	2026-09-06 22:42:06.816471+00
194	team	72	1	72	\N	1.00	2026-09-06 22:42:06.816471+00
195	team	73	1	73	\N	1.00	2026-09-06 22:42:06.816471+00
196	team	74	1	74	\N	1.00	2026-09-06 22:42:06.816471+00
197	team	75	1	75	\N	1.00	2026-09-06 22:42:06.816471+00
198	team	76	1	76	\N	1.00	2026-09-06 22:42:06.816471+00
199	team	77	1	77	\N	1.00	2026-09-06 22:42:06.816471+00
200	team	78	1	78	\N	1.00	2026-09-06 22:42:06.816471+00
201	team	80	1	80	\N	1.00	2026-09-06 22:42:06.816471+00
202	team	81	1	81	\N	1.00	2026-09-06 22:42:06.816471+00
203	team	82	1	82	\N	1.00	2026-09-06 22:42:06.816471+00
204	team	83	1	83	\N	1.00	2026-09-06 22:42:06.816471+00
205	team	84	1	84	\N	1.00	2026-09-06 22:42:06.816471+00
206	team	85	1	85	\N	1.00	2026-09-06 22:42:06.816471+00
207	team	86	1	86	\N	1.00	2026-09-06 22:42:06.816471+00
208	team	87	1	87	\N	1.00	2026-09-06 22:42:06.816471+00
209	team	88	1	88	\N	1.00	2026-09-06 22:42:06.816471+00
210	team	89	1	89	\N	1.00	2026-09-06 22:42:06.816471+00
211	team	90	1	90	\N	1.00	2026-09-06 22:42:06.816471+00
212	team	91	1	91	\N	1.00	2026-09-06 22:42:06.816471+00
213	team	92	1	92	\N	1.00	2026-09-06 22:42:06.816471+00
214	team	93	1	93	\N	1.00	2026-09-06 22:42:06.816471+00
215	team	94	1	94	\N	1.00	2026-09-06 22:42:06.816471+00
216	team	95	1	95	\N	1.00	2026-09-06 22:42:06.816471+00
217	team	96	1	96	\N	1.00	2026-09-06 22:42:06.816471+00
218	team	97	1	97	\N	1.00	2026-09-06 22:42:06.816471+00
219	team	98	1	98	\N	1.00	2026-09-06 22:42:06.816471+00
220	team	99	1	99	\N	1.00	2026-09-06 22:42:06.816471+00
221	team	100	1	100	\N	1.00	2026-09-06 22:42:06.816471+00
222	team	101	1	101	\N	1.00	2026-09-06 22:42:06.816471+00
223	team	102	1	102	\N	1.00	2026-09-06 22:42:06.816471+00
224	team	103	1	103	\N	1.00	2026-09-06 22:42:06.816471+00
225	team	104	1	104	\N	1.00	2026-09-06 22:42:06.816471+00
226	team	105	1	105	\N	1.00	2026-09-06 22:42:06.816471+00
227	team	106	1	106	\N	1.00	2026-09-06 22:42:06.816471+00
228	team	107	1	107	\N	1.00	2026-09-06 22:42:06.816471+00
229	team	108	1	108	\N	1.00	2026-09-06 22:42:06.816471+00
230	team	109	1	109	\N	1.00	2026-09-06 22:42:06.816471+00
231	team	110	1	110	\N	1.00	2026-09-06 22:42:06.816471+00
232	team	111	1	111	\N	1.00	2026-09-06 22:42:06.816471+00
233	team	112	1	112	\N	1.00	2026-09-06 22:42:06.816471+00
234	team	113	1	113	\N	1.00	2026-09-06 22:42:06.816471+00
235	team	114	1	114	\N	1.00	2026-09-06 22:42:06.816471+00
236	team	115	1	115	\N	1.00	2026-09-06 22:42:06.816471+00
237	team	116	1	116	\N	1.00	2026-09-06 22:42:06.816471+00
238	team	117	1	117	\N	1.00	2026-09-06 22:42:06.816471+00
239	team	118	1	118	\N	1.00	2026-09-06 22:42:06.816471+00
240	team	119	1	119	\N	1.00	2026-09-06 22:42:06.816471+00
241	team	120	1	120	\N	1.00	2026-09-06 22:42:06.816471+00
242	team	121	1	121	\N	1.00	2026-09-06 22:42:06.816471+00
243	team	122	1	122	\N	1.00	2026-09-06 22:42:06.816471+00
244	team	123	1	123	\N	1.00	2026-09-06 22:42:06.816471+00
245	team	124	1	124	\N	1.00	2026-09-06 22:42:06.816471+00
246	team	125	1	125	\N	1.00	2026-09-06 22:42:06.816471+00
247	team	126	1	126	\N	1.00	2026-09-06 22:42:06.816471+00
248	team	127	1	127	\N	1.00	2026-09-06 22:42:06.816471+00
249	team	128	1	128	\N	1.00	2026-09-06 22:42:06.816471+00
250	team	129	1	129	\N	1.00	2026-09-06 22:42:06.816471+00
251	team	130	1	130	\N	1.00	2026-09-06 22:42:06.816471+00
252	team	131	1	131	\N	1.00	2026-09-06 22:42:06.816471+00
253	team	132	1	132	\N	1.00	2026-09-06 22:42:06.816471+00
254	team	133	1	133	\N	1.00	2026-09-06 22:42:06.816471+00
255	team	134	1	134	\N	1.00	2026-09-06 22:42:06.816471+00
256	team	135	1	135	\N	1.00	2026-09-06 22:42:06.816471+00
257	team	136	1	136	\N	1.00	2026-09-06 22:42:06.816471+00
258	team	137	1	137	\N	1.00	2026-09-06 22:42:06.816471+00
259	team	138	1	138	\N	1.00	2026-09-06 22:42:06.816471+00
260	team	139	1	139	\N	1.00	2026-09-06 22:42:06.816471+00
261	team	140	1	140	\N	1.00	2026-09-06 22:42:06.816471+00
262	team	141	1	141	\N	1.00	2026-09-06 22:42:06.816471+00
263	team	142	1	142	\N	1.00	2026-09-06 22:42:06.816471+00
264	team	143	1	143	\N	1.00	2026-09-06 22:42:06.816471+00
265	team	144	1	144	\N	1.00	2026-09-06 22:42:06.816471+00
266	team	145	1	145	\N	1.00	2026-09-06 22:42:06.816471+00
267	team	146	1	146	\N	1.00	2026-09-06 22:42:06.816471+00
268	team	147	1	147	\N	1.00	2026-09-06 22:42:06.816471+00
269	team	148	1	148	\N	1.00	2026-09-06 22:42:06.816471+00
270	team	149	1	149	\N	1.00	2026-09-06 22:42:06.816471+00
271	team	150	1	150	\N	1.00	2026-09-06 22:42:06.816471+00
272	team	151	1	151	\N	1.00	2026-09-06 22:42:06.816471+00
273	team	152	1	152	\N	1.00	2026-09-06 22:42:06.816471+00
274	team	153	1	153	\N	1.00	2026-09-06 22:42:06.816471+00
275	team	154	1	154	\N	1.00	2026-09-06 22:42:06.816471+00
276	team	155	1	155	\N	1.00	2026-09-06 22:42:06.816471+00
277	team	156	1	156	\N	1.00	2026-09-06 22:42:06.816471+00
278	team	157	1	157	\N	1.00	2026-09-06 22:42:06.816471+00
279	team	158	1	158	\N	1.00	2026-09-06 22:42:06.816471+00
280	team	159	1	159	\N	1.00	2026-09-06 22:42:06.816471+00
281	team	160	1	160	\N	1.00	2026-09-06 22:42:06.816471+00
282	team	161	1	161	\N	1.00	2026-09-06 22:42:06.816471+00
283	team	162	1	162	\N	1.00	2026-09-06 22:42:06.816471+00
284	team	163	1	163	\N	1.00	2026-09-06 22:42:06.816471+00
285	team	164	1	164	\N	1.00	2026-09-06 22:42:06.816471+00
286	team	165	1	165	\N	1.00	2026-09-06 22:42:06.816471+00
287	team	166	1	166	\N	1.00	2026-09-06 22:42:06.816471+00
288	team	167	1	167	\N	1.00	2026-09-06 22:42:06.816471+00
289	team	168	1	168	\N	1.00	2026-09-06 22:42:06.816471+00
290	team	169	1	169	\N	1.00	2026-09-06 22:42:06.816471+00
291	team	170	1	170	\N	1.00	2026-09-06 22:42:06.816471+00
292	team	171	1	171	\N	1.00	2026-09-06 22:42:06.816471+00
293	team	172	1	172	\N	1.00	2026-09-06 22:42:06.816471+00
294	team	173	1	173	\N	1.00	2026-09-06 22:42:06.816471+00
295	team	174	1	174	\N	1.00	2026-09-06 22:42:06.816471+00
296	team	175	1	175	\N	1.00	2026-09-06 22:42:06.816471+00
297	team	176	1	176	\N	1.00	2026-09-06 22:42:06.816471+00
298	team	177	1	177	\N	1.00	2026-09-06 22:42:06.816471+00
299	team	178	1	178	\N	1.00	2026-09-06 22:42:06.816471+00
300	team	179	1	179	\N	1.00	2026-09-06 22:42:06.816471+00
301	team	180	1	180	\N	1.00	2026-09-06 22:42:06.816471+00
302	team	181	1	181	\N	1.00	2026-09-06 22:42:06.816471+00
303	team	182	1	182	\N	1.00	2026-09-06 22:42:06.816471+00
304	team	183	1	183	\N	1.00	2026-09-06 22:42:06.816471+00
305	team	184	1	184	\N	1.00	2026-09-06 22:42:06.816471+00
306	team	185	1	185	\N	1.00	2026-09-06 22:42:06.816471+00
307	team	186	1	186	\N	1.00	2026-09-06 22:42:06.816471+00
308	team	187	1	187	\N	1.00	2026-09-06 22:42:06.816471+00
309	team	188	1	188	\N	1.00	2026-09-06 22:42:06.816471+00
310	team	189	1	189	\N	1.00	2026-09-06 22:42:06.816471+00
311	team	190	1	190	\N	1.00	2026-09-06 22:42:06.816471+00
312	team	191	1	191	\N	1.00	2026-09-06 22:42:06.816471+00
313	team	192	1	192	\N	1.00	2026-09-06 22:42:06.816471+00
314	team	193	1	193	\N	1.00	2026-09-06 22:42:06.816471+00
315	team	194	1	194	\N	1.00	2026-09-06 22:42:06.816471+00
316	team	195	1	195	\N	1.00	2026-09-06 22:42:06.816471+00
317	team	196	1	196	\N	1.00	2026-09-06 22:42:06.816471+00
318	team	197	1	197	\N	1.00	2026-09-06 22:42:06.816471+00
319	team	198	1	198	\N	1.00	2026-09-06 22:42:06.816471+00
320	team	199	1	199	\N	1.00	2026-09-06 22:42:06.816471+00
321	team	200	1	200	\N	1.00	2026-09-06 22:42:06.816471+00
322	team	201	1	201	\N	1.00	2026-09-06 22:42:06.816471+00
323	team	202	1	202	\N	1.00	2026-09-06 22:42:06.816471+00
324	team	203	1	203	\N	1.00	2026-09-06 22:42:06.816471+00
325	team	204	1	204	\N	1.00	2026-09-06 22:42:06.816471+00
326	team	205	1	205	\N	1.00	2026-09-06 22:42:06.816471+00
327	player	955	1	955	\N	1.00	2026-09-06 22:42:06.816471+00
328	player	956	1	956	\N	1.00	2026-09-06 22:42:06.816471+00
329	player	957	1	957	\N	1.00	2026-09-06 22:42:06.816471+00
330	player	958	1	958	\N	1.00	2026-09-06 22:42:06.816471+00
331	player	959	1	959	\N	1.00	2026-09-06 22:42:06.816471+00
332	player	960	1	960	\N	1.00	2026-09-06 22:42:06.816471+00
333	player	961	1	961	\N	1.00	2026-09-06 22:42:06.816471+00
334	player	962	1	962	\N	1.00	2026-09-06 22:42:06.816471+00
335	player	963	1	963	\N	1.00	2026-09-06 22:42:06.816471+00
336	player	964	1	964	\N	1.00	2026-09-06 22:42:06.816471+00
337	player	965	1	965	\N	1.00	2026-09-06 22:42:06.816471+00
338	player	966	1	966	\N	1.00	2026-09-06 22:42:06.816471+00
339	player	967	1	967	\N	1.00	2026-09-06 22:42:06.816471+00
340	player	968	1	968	\N	1.00	2026-09-06 22:42:06.816471+00
341	player	969	1	969	\N	1.00	2026-09-06 22:42:06.816471+00
342	player	970	1	970	\N	1.00	2026-09-06 22:42:06.816471+00
343	player	971	1	971	\N	1.00	2026-09-06 22:42:06.816471+00
344	player	972	1	972	\N	1.00	2026-09-06 22:42:06.816471+00
345	player	973	1	973	\N	1.00	2026-09-06 22:42:06.816471+00
346	player	974	1	974	\N	1.00	2026-09-06 22:42:06.816471+00
347	player	975	1	975	\N	1.00	2026-09-06 22:42:06.816471+00
348	player	976	1	976	\N	1.00	2026-09-06 22:42:06.816471+00
349	player	977	1	977	\N	1.00	2026-09-06 22:42:06.816471+00
350	player	978	1	978	\N	1.00	2026-09-06 22:42:06.816471+00
351	player	979	1	979	\N	1.00	2026-09-06 22:42:06.816471+00
352	player	980	1	980	\N	1.00	2026-09-06 22:42:06.816471+00
353	player	981	1	981	\N	1.00	2026-09-06 22:42:06.816471+00
354	player	982	1	982	\N	1.00	2026-09-06 22:42:06.816471+00
355	player	983	1	983	\N	1.00	2026-09-06 22:42:06.816471+00
356	player	984	1	984	\N	1.00	2026-09-06 22:42:06.816471+00
357	player	985	1	985	\N	1.00	2026-09-06 22:42:06.816471+00
358	player	986	1	986	\N	1.00	2026-09-06 22:42:06.816471+00
359	player	987	1	987	\N	1.00	2026-09-06 22:42:06.816471+00
360	player	988	1	988	\N	1.00	2026-09-06 22:42:06.816471+00
361	player	989	1	989	\N	1.00	2026-09-06 22:42:06.816471+00
362	player	990	1	990	\N	1.00	2026-09-06 22:42:06.816471+00
363	player	991	1	991	\N	1.00	2026-09-06 22:42:06.816471+00
364	player	992	1	992	\N	1.00	2026-09-06 22:42:06.816471+00
365	player	993	1	993	\N	1.00	2026-09-06 22:42:06.816471+00
366	player	994	1	994	\N	1.00	2026-09-06 22:42:06.816471+00
367	player	995	1	995	\N	1.00	2026-09-06 22:42:06.816471+00
368	player	996	1	996	\N	1.00	2026-09-06 22:42:06.816471+00
369	player	997	1	997	\N	1.00	2026-09-06 22:42:06.816471+00
370	player	998	1	998	\N	1.00	2026-09-06 22:42:06.816471+00
371	player	999	1	999	\N	1.00	2026-09-06 22:42:06.816471+00
372	player	1000	1	1000	\N	1.00	2026-09-06 22:42:06.816471+00
373	player	1001	1	1001	\N	1.00	2026-09-06 22:42:06.816471+00
374	player	1002	1	1002	\N	1.00	2026-09-06 22:42:06.816471+00
375	player	1003	1	1003	\N	1.00	2026-09-06 22:42:06.816471+00
376	player	1004	1	1004	\N	1.00	2026-09-06 22:42:06.816471+00
377	player	1005	1	1005	\N	1.00	2026-09-06 22:42:06.816471+00
378	player	1006	1	1006	\N	1.00	2026-09-06 22:42:06.816471+00
379	player	1007	1	1007	\N	1.00	2026-09-06 22:42:06.816471+00
380	player	1008	1	1008	\N	1.00	2026-09-06 22:42:06.816471+00
381	player	1009	1	1009	\N	1.00	2026-09-06 22:42:06.816471+00
382	player	1010	1	1010	\N	1.00	2026-09-06 22:42:06.816471+00
383	player	1011	1	1011	\N	1.00	2026-09-06 22:42:06.816471+00
384	player	1012	1	1012	\N	1.00	2026-09-06 22:42:06.816471+00
385	player	1013	1	1013	\N	1.00	2026-09-06 22:42:06.816471+00
386	player	1014	1	1014	\N	1.00	2026-09-06 22:42:06.816471+00
387	player	1015	1	1015	\N	1.00	2026-09-06 22:42:06.816471+00
388	player	1016	1	1016	\N	1.00	2026-09-06 22:42:06.816471+00
389	player	1017	1	1017	\N	1.00	2026-09-06 22:42:06.816471+00
390	player	1018	1	1018	\N	1.00	2026-09-06 22:42:06.816471+00
391	player	1019	1	1019	\N	1.00	2026-09-06 22:42:06.816471+00
392	player	1020	1	1020	\N	1.00	2026-09-06 22:42:06.816471+00
393	player	1021	1	1021	\N	1.00	2026-09-06 22:42:06.816471+00
394	player	1022	1	1022	\N	1.00	2026-09-06 22:42:06.816471+00
395	player	1023	1	1023	\N	1.00	2026-09-06 22:42:06.816471+00
396	player	1024	1	1024	\N	1.00	2026-09-06 22:42:06.816471+00
397	player	1025	1	1025	\N	1.00	2026-09-06 22:42:06.816471+00
398	player	1026	1	1026	\N	1.00	2026-09-06 22:42:06.816471+00
399	player	1027	1	1027	\N	1.00	2026-09-06 22:42:06.816471+00
400	player	1028	1	1028	\N	1.00	2026-09-06 22:42:06.816471+00
401	player	1029	1	1029	\N	1.00	2026-09-06 22:42:06.816471+00
402	player	1030	1	1030	\N	1.00	2026-09-06 22:42:06.816471+00
403	player	1031	1	1031	\N	1.00	2026-09-06 22:42:06.816471+00
404	player	1032	1	1032	\N	1.00	2026-09-06 22:42:06.816471+00
405	player	1033	1	1033	\N	1.00	2026-09-06 22:42:06.816471+00
406	player	1034	1	1034	\N	1.00	2026-09-06 22:42:06.816471+00
407	player	1035	1	1035	\N	1.00	2026-09-06 22:42:06.816471+00
408	player	1036	1	1036	\N	1.00	2026-09-06 22:42:06.816471+00
409	player	1037	1	1037	\N	1.00	2026-09-06 22:42:06.816471+00
410	player	1038	1	1038	\N	1.00	2026-09-06 22:42:06.816471+00
411	player	1039	1	1039	\N	1.00	2026-09-06 22:42:06.816471+00
412	player	1040	1	1040	\N	1.00	2026-09-06 22:42:06.816471+00
413	player	1041	1	1041	\N	1.00	2026-09-06 22:42:06.816471+00
414	player	1042	1	1042	\N	1.00	2026-09-06 22:42:06.816471+00
415	player	1043	1	1043	\N	1.00	2026-09-06 22:42:06.816471+00
416	player	1044	1	1044	\N	1.00	2026-09-06 22:42:06.816471+00
417	player	1045	1	1045	\N	1.00	2026-09-06 22:42:06.816471+00
418	player	1046	1	1046	\N	1.00	2026-09-06 22:42:06.816471+00
419	player	1047	1	1047	\N	1.00	2026-09-06 22:42:06.816471+00
420	player	1048	1	1048	\N	1.00	2026-09-06 22:42:06.816471+00
421	player	1049	1	1049	\N	1.00	2026-09-06 22:42:06.816471+00
422	player	1050	1	1050	\N	1.00	2026-09-06 22:42:06.816471+00
423	player	1051	1	1051	\N	1.00	2026-09-06 22:42:06.816471+00
424	player	1052	1	1052	\N	1.00	2026-09-06 22:42:06.816471+00
425	player	1053	1	1053	\N	1.00	2026-09-06 22:42:06.816471+00
426	player	1054	1	1054	\N	1.00	2026-09-06 22:42:06.816471+00
427	player	1055	1	1055	\N	1.00	2026-09-06 22:42:06.816471+00
428	player	1056	1	1056	\N	1.00	2026-09-06 22:42:06.816471+00
429	player	1057	1	1057	\N	1.00	2026-09-06 22:42:06.816471+00
430	player	1058	1	1058	\N	1.00	2026-09-06 22:42:06.816471+00
431	player	1059	1	1059	\N	1.00	2026-09-06 22:42:06.816471+00
432	player	1060	1	1060	\N	1.00	2026-09-06 22:42:06.816471+00
433	player	1061	1	1061	\N	1.00	2026-09-06 22:42:06.816471+00
434	player	1062	1	1062	\N	1.00	2026-09-06 22:42:06.816471+00
435	player	1063	1	1063	\N	1.00	2026-09-06 22:42:06.816471+00
436	player	1064	1	1064	\N	1.00	2026-09-06 22:42:06.816471+00
437	player	1065	1	1065	\N	1.00	2026-09-06 22:42:06.816471+00
438	player	1066	1	1066	\N	1.00	2026-09-06 22:42:06.816471+00
439	player	1067	1	1067	\N	1.00	2026-09-06 22:42:06.816471+00
440	player	1068	1	1068	\N	1.00	2026-09-06 22:42:06.816471+00
441	player	1069	1	1069	\N	1.00	2026-09-06 22:42:06.816471+00
442	player	1070	1	1070	\N	1.00	2026-09-06 22:42:06.816471+00
443	player	1071	1	1071	\N	1.00	2026-09-06 22:42:06.816471+00
444	player	1072	1	1072	\N	1.00	2026-09-06 22:42:06.816471+00
445	player	1073	1	1073	\N	1.00	2026-09-06 22:42:06.816471+00
446	player	1074	1	1074	\N	1.00	2026-09-06 22:42:06.816471+00
447	player	1075	1	1075	\N	1.00	2026-09-06 22:42:06.816471+00
448	player	1076	1	1076	\N	1.00	2026-09-06 22:42:06.816471+00
449	player	1077	1	1077	\N	1.00	2026-09-06 22:42:06.816471+00
450	player	1078	1	1078	\N	1.00	2026-09-06 22:42:06.816471+00
451	player	1079	1	1079	\N	1.00	2026-09-06 22:42:06.816471+00
452	player	1080	1	1080	\N	1.00	2026-09-06 22:42:06.816471+00
453	player	1081	1	1081	\N	1.00	2026-09-06 22:42:06.816471+00
454	player	1082	1	1082	\N	1.00	2026-09-06 22:42:06.816471+00
455	player	1083	1	1083	\N	1.00	2026-09-06 22:42:06.816471+00
456	player	1084	1	1084	\N	1.00	2026-09-06 22:42:06.816471+00
457	player	1085	1	1085	\N	1.00	2026-09-06 22:42:06.816471+00
458	player	1086	1	1086	\N	1.00	2026-09-06 22:42:06.816471+00
459	player	1087	1	1087	\N	1.00	2026-09-06 22:42:06.816471+00
460	player	1088	1	1088	\N	1.00	2026-09-06 22:42:06.816471+00
461	player	1089	1	1089	\N	1.00	2026-09-06 22:42:06.816471+00
462	player	1090	1	1090	\N	1.00	2026-09-06 22:42:06.816471+00
463	player	1091	1	1091	\N	1.00	2026-09-06 22:42:06.816471+00
464	player	1092	1	1092	\N	1.00	2026-09-06 22:42:06.816471+00
465	player	1093	1	1093	\N	1.00	2026-09-06 22:42:06.816471+00
466	player	1094	1	1094	\N	1.00	2026-09-06 22:42:06.816471+00
467	player	1095	1	1095	\N	1.00	2026-09-06 22:42:06.816471+00
468	player	1096	1	1096	\N	1.00	2026-09-06 22:42:06.816471+00
469	player	1097	1	1097	\N	1.00	2026-09-06 22:42:06.816471+00
470	player	1098	1	1098	\N	1.00	2026-09-06 22:42:06.816471+00
471	player	1099	1	1099	\N	1.00	2026-09-06 22:42:06.816471+00
472	player	1100	1	1100	\N	1.00	2026-09-06 22:42:06.816471+00
473	player	1101	1	1101	\N	1.00	2026-09-06 22:42:06.816471+00
474	player	1102	1	1102	\N	1.00	2026-09-06 22:42:06.816471+00
475	player	1103	1	1103	\N	1.00	2026-09-06 22:42:06.816471+00
476	player	1104	1	1104	\N	1.00	2026-09-06 22:42:06.816471+00
477	player	1105	1	1105	\N	1.00	2026-09-06 22:42:06.816471+00
478	player	1106	1	1106	\N	1.00	2026-09-06 22:42:06.816471+00
479	player	1107	1	1107	\N	1.00	2026-09-06 22:42:06.816471+00
480	player	1108	1	1108	\N	1.00	2026-09-06 22:42:06.816471+00
481	player	1109	1	1109	\N	1.00	2026-09-06 22:42:06.816471+00
482	player	1110	1	1110	\N	1.00	2026-09-06 22:42:06.816471+00
483	player	1111	1	1111	\N	1.00	2026-09-06 22:42:06.816471+00
484	player	1112	1	1112	\N	1.00	2026-09-06 22:42:06.816471+00
485	player	1113	1	1113	\N	1.00	2026-09-06 22:42:06.816471+00
486	player	1114	1	1114	\N	1.00	2026-09-06 22:42:06.816471+00
487	player	1115	1	1115	\N	1.00	2026-09-06 22:42:06.816471+00
488	player	1116	1	1116	\N	1.00	2026-09-06 22:42:06.816471+00
489	player	1117	1	1117	\N	1.00	2026-09-06 22:42:06.816471+00
490	player	1118	1	1118	\N	1.00	2026-09-06 22:42:06.816471+00
491	player	1119	1	1119	\N	1.00	2026-09-06 22:42:06.816471+00
492	player	1120	1	1120	\N	1.00	2026-09-06 22:42:06.816471+00
493	player	1121	1	1121	\N	1.00	2026-09-06 22:42:06.816471+00
494	player	1122	1	1122	\N	1.00	2026-09-06 22:42:06.816471+00
495	player	1123	1	1123	\N	1.00	2026-09-06 22:42:06.816471+00
496	player	1124	1	1124	\N	1.00	2026-09-06 22:42:06.816471+00
497	player	1125	1	1125	\N	1.00	2026-09-06 22:42:06.816471+00
498	player	1126	1	1126	\N	1.00	2026-09-06 22:42:06.816471+00
499	player	1127	1	1127	\N	1.00	2026-09-06 22:42:06.816471+00
500	player	1128	1	1128	\N	1.00	2026-09-06 22:42:06.816471+00
501	player	1129	1	1129	\N	1.00	2026-09-06 22:42:06.816471+00
502	player	1130	1	1130	\N	1.00	2026-09-06 22:42:06.816471+00
503	player	1131	1	1131	\N	1.00	2026-09-06 22:42:06.816471+00
504	player	1132	1	1132	\N	1.00	2026-09-06 22:42:06.816471+00
505	player	1133	1	1133	\N	1.00	2026-09-06 22:42:06.816471+00
506	player	1134	1	1134	\N	1.00	2026-09-06 22:42:06.816471+00
507	player	1135	1	1135	\N	1.00	2026-09-06 22:42:06.816471+00
508	player	1136	1	1136	\N	1.00	2026-09-06 22:42:06.816471+00
509	player	1137	1	1137	\N	1.00	2026-09-06 22:42:06.816471+00
510	player	1138	1	1138	\N	1.00	2026-09-06 22:42:06.816471+00
511	player	1139	1	1139	\N	1.00	2026-09-06 22:42:06.816471+00
512	player	1140	1	1140	\N	1.00	2026-09-06 22:42:06.816471+00
513	player	1141	1	1141	\N	1.00	2026-09-06 22:42:06.816471+00
514	player	1142	1	1142	\N	1.00	2026-09-06 22:42:06.816471+00
515	player	1143	1	1143	\N	1.00	2026-09-06 22:42:06.816471+00
516	player	1144	1	1144	\N	1.00	2026-09-06 22:42:06.816471+00
517	player	1145	1	1145	\N	1.00	2026-09-06 22:42:06.816471+00
518	player	1146	1	1146	\N	1.00	2026-09-06 22:42:06.816471+00
519	player	1147	1	1147	\N	1.00	2026-09-06 22:42:06.816471+00
520	player	1148	1	1148	\N	1.00	2026-09-06 22:42:06.816471+00
521	player	1149	1	1149	\N	1.00	2026-09-06 22:42:06.816471+00
522	player	1150	1	1150	\N	1.00	2026-09-06 22:42:06.816471+00
523	player	1151	1	1151	\N	1.00	2026-09-06 22:42:06.816471+00
524	player	1152	1	1152	\N	1.00	2026-09-06 22:42:06.816471+00
525	player	1153	1	1153	\N	1.00	2026-09-06 22:42:06.816471+00
526	player	1154	1	1154	\N	1.00	2026-09-06 22:42:06.816471+00
527	player	1155	1	1155	\N	1.00	2026-09-06 22:42:06.816471+00
528	player	1156	1	1156	\N	1.00	2026-09-06 22:42:06.816471+00
529	player	1157	1	1157	\N	1.00	2026-09-06 22:42:06.816471+00
530	player	1158	1	1158	\N	1.00	2026-09-06 22:42:06.816471+00
531	player	1159	1	1159	\N	1.00	2026-09-06 22:42:06.816471+00
532	player	1160	1	1160	\N	1.00	2026-09-06 22:42:06.816471+00
533	player	1161	1	1161	\N	1.00	2026-09-06 22:42:06.816471+00
534	player	1162	1	1162	\N	1.00	2026-09-06 22:42:06.816471+00
535	player	1163	1	1163	\N	1.00	2026-09-06 22:42:06.816471+00
536	player	1164	1	1164	\N	1.00	2026-09-06 22:42:06.816471+00
537	player	1165	1	1165	\N	1.00	2026-09-06 22:42:06.816471+00
538	player	1166	1	1166	\N	1.00	2026-09-06 22:42:06.816471+00
539	player	1167	1	1167	\N	1.00	2026-09-06 22:42:06.816471+00
540	player	1168	1	1168	\N	1.00	2026-09-06 22:42:06.816471+00
541	player	1169	1	1169	\N	1.00	2026-09-06 22:42:06.816471+00
542	player	1170	1	1170	\N	1.00	2026-09-06 22:42:06.816471+00
543	player	1171	1	1171	\N	1.00	2026-09-06 22:42:06.816471+00
544	player	1172	1	1172	\N	1.00	2026-09-06 22:42:06.816471+00
545	player	1173	1	1173	\N	1.00	2026-09-06 22:42:06.816471+00
546	player	1174	1	1174	\N	1.00	2026-09-06 22:42:06.816471+00
547	player	1175	1	1175	\N	1.00	2026-09-06 22:42:06.816471+00
548	player	1176	1	1176	\N	1.00	2026-09-06 22:42:06.816471+00
549	player	1177	1	1177	\N	1.00	2026-09-06 22:42:06.816471+00
550	player	1178	1	1178	\N	1.00	2026-09-06 22:42:06.816471+00
551	player	1179	1	1179	\N	1.00	2026-09-06 22:42:06.816471+00
552	player	1180	1	1180	\N	1.00	2026-09-06 22:42:06.816471+00
553	player	1181	1	1181	\N	1.00	2026-09-06 22:42:06.816471+00
554	player	1182	1	1182	\N	1.00	2026-09-06 22:42:06.816471+00
555	player	1183	1	1183	\N	1.00	2026-09-06 22:42:06.816471+00
556	player	1184	1	1184	\N	1.00	2026-09-06 22:42:06.816471+00
557	player	1185	1	1185	\N	1.00	2026-09-06 22:42:06.816471+00
558	player	1186	1	1186	\N	1.00	2026-09-06 22:42:06.816471+00
559	player	1187	1	1187	\N	1.00	2026-09-06 22:42:06.816471+00
560	player	1188	1	1188	\N	1.00	2026-09-06 22:42:06.816471+00
561	player	1189	1	1189	\N	1.00	2026-09-06 22:42:06.816471+00
562	player	1190	1	1190	\N	1.00	2026-09-06 22:42:06.816471+00
563	player	1191	1	1191	\N	1.00	2026-09-06 22:42:06.816471+00
564	player	1192	1	1192	\N	1.00	2026-09-06 22:42:06.816471+00
565	player	1193	1	1193	\N	1.00	2026-09-06 22:42:06.816471+00
566	player	1194	1	1194	\N	1.00	2026-09-06 22:42:06.816471+00
567	player	1195	1	1195	\N	1.00	2026-09-06 22:42:06.816471+00
568	player	1196	1	1196	\N	1.00	2026-09-06 22:42:06.816471+00
569	player	1197	1	1197	\N	1.00	2026-09-06 22:42:06.816471+00
570	player	1198	1	1198	\N	1.00	2026-09-06 22:42:06.816471+00
571	player	1199	1	1199	\N	1.00	2026-09-06 22:42:06.816471+00
572	player	1200	1	1200	\N	1.00	2026-09-06 22:42:06.816471+00
573	player	1201	1	1201	\N	1.00	2026-09-06 22:42:06.816471+00
574	player	1202	1	1202	\N	1.00	2026-09-06 22:42:06.816471+00
575	player	1203	1	1203	\N	1.00	2026-09-06 22:42:06.816471+00
576	player	1204	1	1204	\N	1.00	2026-09-06 22:42:06.816471+00
577	player	1205	1	1205	\N	1.00	2026-09-06 22:42:06.816471+00
578	player	1206	1	1206	\N	1.00	2026-09-06 22:42:06.816471+00
579	player	1207	1	1207	\N	1.00	2026-09-06 22:42:06.816471+00
580	player	1208	1	1208	\N	1.00	2026-09-06 22:42:06.816471+00
581	player	1209	1	1209	\N	1.00	2026-09-06 22:42:06.816471+00
582	player	1210	1	1210	\N	1.00	2026-09-06 22:42:06.816471+00
583	player	1211	1	1211	\N	1.00	2026-09-06 22:42:06.816471+00
584	player	1212	1	1212	\N	1.00	2026-09-06 22:42:06.816471+00
585	player	1213	1	1213	\N	1.00	2026-09-06 22:42:06.816471+00
586	player	1214	1	1214	\N	1.00	2026-09-06 22:42:06.816471+00
587	player	1215	1	1215	\N	1.00	2026-09-06 22:42:06.816471+00
588	player	1216	1	1216	\N	1.00	2026-09-06 22:42:06.816471+00
589	player	1217	1	1217	\N	1.00	2026-09-06 22:42:06.816471+00
590	player	1218	1	1218	\N	1.00	2026-09-06 22:42:06.816471+00
591	player	1219	1	1219	\N	1.00	2026-09-06 22:42:06.816471+00
592	player	1220	1	1220	\N	1.00	2026-09-06 22:42:06.816471+00
593	player	1221	1	1221	\N	1.00	2026-09-06 22:42:06.816471+00
594	player	1222	1	1222	\N	1.00	2026-09-06 22:42:06.816471+00
595	player	1223	1	1223	\N	1.00	2026-09-06 22:42:06.816471+00
596	player	1224	1	1224	\N	1.00	2026-09-06 22:42:06.816471+00
597	player	1225	1	1225	\N	1.00	2026-09-06 22:42:06.816471+00
598	player	1226	1	1226	\N	1.00	2026-09-06 22:42:06.816471+00
599	player	1227	1	1227	\N	1.00	2026-09-06 22:42:06.816471+00
600	player	1228	1	1228	\N	1.00	2026-09-06 22:42:06.816471+00
601	player	1229	1	1229	\N	1.00	2026-09-06 22:42:06.816471+00
602	player	1230	1	1230	\N	1.00	2026-09-06 22:42:06.816471+00
603	player	1231	1	1231	\N	1.00	2026-09-06 22:42:06.816471+00
604	player	1232	1	1232	\N	1.00	2026-09-06 22:42:06.816471+00
605	player	1233	1	1233	\N	1.00	2026-09-06 22:42:06.816471+00
606	player	1234	1	1234	\N	1.00	2026-09-06 22:42:06.816471+00
607	player	1235	1	1235	\N	1.00	2026-09-06 22:42:06.816471+00
608	player	1236	1	1236	\N	1.00	2026-09-06 22:42:06.816471+00
609	player	1237	1	1237	\N	1.00	2026-09-06 22:42:06.816471+00
610	player	1238	1	1238	\N	1.00	2026-09-06 22:42:06.816471+00
611	player	1239	1	1239	\N	1.00	2026-09-06 22:42:06.816471+00
612	player	1240	1	1240	\N	1.00	2026-09-06 22:42:06.816471+00
613	player	1241	1	1241	\N	1.00	2026-09-06 22:42:06.816471+00
614	player	1242	1	1242	\N	1.00	2026-09-06 22:42:06.816471+00
615	player	1243	1	1243	\N	1.00	2026-09-06 22:42:06.816471+00
616	player	1244	1	1244	\N	1.00	2026-09-06 22:42:06.816471+00
617	player	1245	1	1245	\N	1.00	2026-09-06 22:42:06.816471+00
618	player	1246	1	1246	\N	1.00	2026-09-06 22:42:06.816471+00
619	player	1247	1	1247	\N	1.00	2026-09-06 22:42:06.816471+00
620	player	1248	1	1248	\N	1.00	2026-09-06 22:42:06.816471+00
621	player	1249	1	1249	\N	1.00	2026-09-06 22:42:06.816471+00
622	player	1250	1	1250	\N	1.00	2026-09-06 22:42:06.816471+00
623	player	1251	1	1251	\N	1.00	2026-09-06 22:42:06.816471+00
624	player	1252	1	1252	\N	1.00	2026-09-06 22:42:06.816471+00
625	player	1253	1	1253	\N	1.00	2026-09-06 22:42:06.816471+00
626	player	1254	1	1254	\N	1.00	2026-09-06 22:42:06.816471+00
627	player	1255	1	1255	\N	1.00	2026-09-06 22:42:06.816471+00
628	player	1256	1	1256	\N	1.00	2026-09-06 22:42:06.816471+00
629	player	1257	1	1257	\N	1.00	2026-09-06 22:42:06.816471+00
630	player	1258	1	1258	\N	1.00	2026-09-06 22:42:06.816471+00
631	player	1259	1	1259	\N	1.00	2026-09-06 22:42:06.816471+00
632	player	1260	1	1260	\N	1.00	2026-09-06 22:42:06.816471+00
633	player	1261	1	1261	\N	1.00	2026-09-06 22:42:06.816471+00
634	player	1262	1	1262	\N	1.00	2026-09-06 22:42:06.816471+00
635	player	1263	1	1263	\N	1.00	2026-09-06 22:42:06.816471+00
636	player	1264	1	1264	\N	1.00	2026-09-06 22:42:06.816471+00
637	player	1265	1	1265	\N	1.00	2026-09-06 22:42:06.816471+00
638	player	1266	1	1266	\N	1.00	2026-09-06 22:42:06.816471+00
639	player	1267	1	1267	\N	1.00	2026-09-06 22:42:06.816471+00
640	player	1268	1	1268	\N	1.00	2026-09-06 22:42:06.816471+00
641	player	1269	1	1269	\N	1.00	2026-09-06 22:42:06.816471+00
642	player	1270	1	1270	\N	1.00	2026-09-06 22:42:06.816471+00
643	player	1271	1	1271	\N	1.00	2026-09-06 22:42:06.816471+00
644	player	1272	1	1272	\N	1.00	2026-09-06 22:42:06.816471+00
645	player	1273	1	1273	\N	1.00	2026-09-06 22:42:06.816471+00
646	player	1274	1	1274	\N	1.00	2026-09-06 22:42:06.816471+00
647	player	1275	1	1275	\N	1.00	2026-09-06 22:42:06.816471+00
648	player	1276	1	1276	\N	1.00	2026-09-06 22:42:06.816471+00
649	player	1277	1	1277	\N	1.00	2026-09-06 22:42:06.816471+00
650	player	1278	1	1278	\N	1.00	2026-09-06 22:42:06.816471+00
651	player	1279	1	1279	\N	1.00	2026-09-06 22:42:06.816471+00
652	player	1280	1	1280	\N	1.00	2026-09-06 22:42:06.816471+00
653	player	1281	1	1281	\N	1.00	2026-09-06 22:42:06.816471+00
654	player	1282	1	1282	\N	1.00	2026-09-06 22:42:06.816471+00
655	player	1283	1	1283	\N	1.00	2026-09-06 22:42:06.816471+00
656	player	1284	1	1284	\N	1.00	2026-09-06 22:42:06.816471+00
657	player	1285	1	1285	\N	1.00	2026-09-06 22:42:06.816471+00
658	player	1286	1	1286	\N	1.00	2026-09-06 22:42:06.816471+00
659	player	1287	1	1287	\N	1.00	2026-09-06 22:42:06.816471+00
660	player	1288	1	1288	\N	1.00	2026-09-06 22:42:06.816471+00
661	player	1289	1	1289	\N	1.00	2026-09-06 22:42:06.816471+00
662	player	1290	1	1290	\N	1.00	2026-09-06 22:42:06.816471+00
663	player	1291	1	1291	\N	1.00	2026-09-06 22:42:06.816471+00
664	player	1292	1	1292	\N	1.00	2026-09-06 22:42:06.816471+00
665	player	1293	1	1293	\N	1.00	2026-09-06 22:42:06.816471+00
666	player	1294	1	1294	\N	1.00	2026-09-06 22:42:06.816471+00
667	player	1295	1	1295	\N	1.00	2026-09-06 22:42:06.816471+00
668	player	1296	1	1296	\N	1.00	2026-09-06 22:42:06.816471+00
669	player	1297	1	1297	\N	1.00	2026-09-06 22:42:06.816471+00
670	player	1298	1	1298	\N	1.00	2026-09-06 22:42:06.816471+00
671	player	1299	1	1299	\N	1.00	2026-09-06 22:42:06.816471+00
672	player	1300	1	1300	\N	1.00	2026-09-06 22:42:06.816471+00
673	player	1301	1	1301	\N	1.00	2026-09-06 22:42:06.816471+00
674	player	1302	1	1302	\N	1.00	2026-09-06 22:42:06.816471+00
675	player	1303	1	1303	\N	1.00	2026-09-06 22:42:06.816471+00
676	player	1304	1	1304	\N	1.00	2026-09-06 22:42:06.816471+00
677	player	1305	1	1305	\N	1.00	2026-09-06 22:42:06.816471+00
678	player	1306	1	1306	\N	1.00	2026-09-06 22:42:06.816471+00
679	player	1307	1	1307	\N	1.00	2026-09-06 22:42:06.816471+00
680	player	1308	1	1308	\N	1.00	2026-09-06 22:42:06.816471+00
681	player	1309	1	1309	\N	1.00	2026-09-06 22:42:06.816471+00
682	player	1310	1	1310	\N	1.00	2026-09-06 22:42:06.816471+00
683	player	1311	1	1311	\N	1.00	2026-09-06 22:42:06.816471+00
684	player	1312	1	1312	\N	1.00	2026-09-06 22:42:06.816471+00
685	player	1313	1	1313	\N	1.00	2026-09-06 22:42:06.816471+00
686	player	1314	1	1314	\N	1.00	2026-09-06 22:42:06.816471+00
687	player	1315	1	1315	\N	1.00	2026-09-06 22:42:06.816471+00
688	player	1316	1	1316	\N	1.00	2026-09-06 22:42:06.816471+00
689	player	1317	1	1317	\N	1.00	2026-09-06 22:42:06.816471+00
690	player	1318	1	1318	\N	1.00	2026-09-06 22:42:06.816471+00
691	player	1319	1	1319	\N	1.00	2026-09-06 22:42:06.816471+00
692	player	1320	1	1320	\N	1.00	2026-09-06 22:42:06.816471+00
693	player	1321	1	1321	\N	1.00	2026-09-06 22:42:06.816471+00
694	player	1322	1	1322	\N	1.00	2026-09-06 22:42:06.816471+00
695	player	1323	1	1323	\N	1.00	2026-09-06 22:42:06.816471+00
696	player	1324	1	1324	\N	1.00	2026-09-06 22:42:06.816471+00
697	player	1325	1	1325	\N	1.00	2026-09-06 22:42:06.816471+00
698	player	1326	1	1326	\N	1.00	2026-09-06 22:42:06.816471+00
699	player	1327	1	1327	\N	1.00	2026-09-06 22:42:06.816471+00
700	player	1328	1	1328	\N	1.00	2026-09-06 22:42:06.816471+00
701	player	1329	1	1329	\N	1.00	2026-09-06 22:42:06.816471+00
702	player	1330	1	1330	\N	1.00	2026-09-06 22:42:06.816471+00
703	player	1331	1	1331	\N	1.00	2026-09-06 22:42:06.816471+00
704	player	1332	1	1332	\N	1.00	2026-09-06 22:42:06.816471+00
705	player	1333	1	1333	\N	1.00	2026-09-06 22:42:06.816471+00
706	player	1334	1	1334	\N	1.00	2026-09-06 22:42:06.816471+00
707	player	1335	1	1335	\N	1.00	2026-09-06 22:42:06.816471+00
708	player	1336	1	1336	\N	1.00	2026-09-06 22:42:06.816471+00
709	player	1337	1	1337	\N	1.00	2026-09-06 22:42:06.816471+00
710	player	1338	1	1338	\N	1.00	2026-09-06 22:42:06.816471+00
711	player	1339	1	1339	\N	1.00	2026-09-06 22:42:06.816471+00
712	player	1340	1	1340	\N	1.00	2026-09-06 22:42:06.816471+00
713	player	1341	1	1341	\N	1.00	2026-09-06 22:42:06.816471+00
714	player	1342	1	1342	\N	1.00	2026-09-06 22:42:06.816471+00
715	player	1343	1	1343	\N	1.00	2026-09-06 22:42:06.816471+00
716	player	1344	1	1344	\N	1.00	2026-09-06 22:42:06.816471+00
717	player	1345	1	1345	\N	1.00	2026-09-06 22:42:06.816471+00
718	player	1346	1	1346	\N	1.00	2026-09-06 22:42:06.816471+00
719	player	1347	1	1347	\N	1.00	2026-09-06 22:42:06.816471+00
720	player	1348	1	1348	\N	1.00	2026-09-06 22:42:06.816471+00
721	player	1349	1	1349	\N	1.00	2026-09-06 22:42:06.816471+00
722	player	1350	1	1350	\N	1.00	2026-09-06 22:42:06.816471+00
723	player	1351	1	1351	\N	1.00	2026-09-06 22:42:06.816471+00
724	player	1352	1	1352	\N	1.00	2026-09-06 22:42:06.816471+00
725	player	1353	1	1353	\N	1.00	2026-09-06 22:42:06.816471+00
726	player	1354	1	1354	\N	1.00	2026-09-06 22:42:06.816471+00
727	player	1355	1	1355	\N	1.00	2026-09-06 22:42:06.816471+00
728	player	1356	1	1356	\N	1.00	2026-09-06 22:42:06.816471+00
729	player	1357	1	1357	\N	1.00	2026-09-06 22:42:06.816471+00
730	player	1358	1	1358	\N	1.00	2026-09-06 22:42:06.816471+00
731	player	1359	1	1359	\N	1.00	2026-09-06 22:42:06.816471+00
732	player	1360	1	1360	\N	1.00	2026-09-06 22:42:06.816471+00
733	player	1361	1	1361	\N	1.00	2026-09-06 22:42:06.816471+00
734	player	1362	1	1362	\N	1.00	2026-09-06 22:42:06.816471+00
735	player	1363	1	1363	\N	1.00	2026-09-06 22:42:06.816471+00
736	player	1364	1	1364	\N	1.00	2026-09-06 22:42:06.816471+00
737	player	1365	1	1365	\N	1.00	2026-09-06 22:42:06.816471+00
738	player	1366	1	1366	\N	1.00	2026-09-06 22:42:06.816471+00
739	player	1367	1	1367	\N	1.00	2026-09-06 22:42:06.816471+00
740	player	1368	1	1368	\N	1.00	2026-09-06 22:42:06.816471+00
741	player	1369	1	1369	\N	1.00	2026-09-06 22:42:06.816471+00
742	player	1370	1	1370	\N	1.00	2026-09-06 22:42:06.816471+00
743	player	1371	1	1371	\N	1.00	2026-09-06 22:42:06.816471+00
744	player	1372	1	1372	\N	1.00	2026-09-06 22:42:06.816471+00
745	player	1373	1	1373	\N	1.00	2026-09-06 22:42:06.816471+00
746	player	1374	1	1374	\N	1.00	2026-09-06 22:42:06.816471+00
747	player	1375	1	1375	\N	1.00	2026-09-06 22:42:06.816471+00
748	player	1376	1	1376	\N	1.00	2026-09-06 22:42:06.816471+00
749	player	1377	1	1377	\N	1.00	2026-09-06 22:42:06.816471+00
750	player	1378	1	1378	\N	1.00	2026-09-06 22:42:06.816471+00
751	player	1379	1	1379	\N	1.00	2026-09-06 22:42:06.816471+00
752	player	1380	1	1380	\N	1.00	2026-09-06 22:42:06.816471+00
753	player	1381	1	1381	\N	1.00	2026-09-06 22:42:06.816471+00
754	player	1382	1	1382	\N	1.00	2026-09-06 22:42:06.816471+00
755	player	1383	1	1383	\N	1.00	2026-09-06 22:42:06.816471+00
756	player	1384	1	1384	\N	1.00	2026-09-06 22:42:06.816471+00
757	player	1385	1	1385	\N	1.00	2026-09-06 22:42:06.816471+00
758	player	1386	1	1386	\N	1.00	2026-09-06 22:42:06.816471+00
759	player	1387	1	1387	\N	1.00	2026-09-06 22:42:06.816471+00
760	player	1388	1	1388	\N	1.00	2026-09-06 22:42:06.816471+00
761	player	1389	1	1389	\N	1.00	2026-09-06 22:42:06.816471+00
762	player	1390	1	1390	\N	1.00	2026-09-06 22:42:06.816471+00
763	player	1391	1	1391	\N	1.00	2026-09-06 22:42:06.816471+00
764	player	1392	1	1392	\N	1.00	2026-09-06 22:42:06.816471+00
765	player	1393	1	1393	\N	1.00	2026-09-06 22:42:06.816471+00
766	player	1394	1	1394	\N	1.00	2026-09-06 22:42:06.816471+00
767	player	1395	1	1395	\N	1.00	2026-09-06 22:42:06.816471+00
768	player	1396	1	1396	\N	1.00	2026-09-06 22:42:06.816471+00
769	player	1397	1	1397	\N	1.00	2026-09-06 22:42:06.816471+00
770	player	1398	1	1398	\N	1.00	2026-09-06 22:42:06.816471+00
771	player	1399	1	1399	\N	1.00	2026-09-06 22:42:06.816471+00
772	player	1400	1	1400	\N	1.00	2026-09-06 22:42:06.816471+00
773	player	1401	1	1401	\N	1.00	2026-09-06 22:42:06.816471+00
774	player	1402	1	1402	\N	1.00	2026-09-06 22:42:06.816471+00
775	player	1403	1	1403	\N	1.00	2026-09-06 22:42:06.816471+00
776	player	1404	1	1404	\N	1.00	2026-09-06 22:42:06.816471+00
777	player	1405	1	1405	\N	1.00	2026-09-06 22:42:06.816471+00
778	player	1406	1	1406	\N	1.00	2026-09-06 22:42:06.816471+00
779	player	1407	1	1407	\N	1.00	2026-09-06 22:42:06.816471+00
780	player	1408	1	1408	\N	1.00	2026-09-06 22:42:06.816471+00
781	player	1409	1	1409	\N	1.00	2026-09-06 22:42:06.816471+00
782	player	1410	1	1410	\N	1.00	2026-09-06 22:42:06.816471+00
783	player	1411	1	1411	\N	1.00	2026-09-06 22:42:06.816471+00
784	player	1412	1	1412	\N	1.00	2026-09-06 22:42:06.816471+00
785	player	1413	1	1413	\N	1.00	2026-09-06 22:42:06.816471+00
786	player	1414	1	1414	\N	1.00	2026-09-06 22:42:06.816471+00
787	player	1415	1	1415	\N	1.00	2026-09-06 22:42:06.816471+00
788	player	1416	1	1416	\N	1.00	2026-09-06 22:42:06.816471+00
789	player	1417	1	1417	\N	1.00	2026-09-06 22:42:06.816471+00
790	player	1418	1	1418	\N	1.00	2026-09-06 22:42:06.816471+00
791	player	1419	1	1419	\N	1.00	2026-09-06 22:42:06.816471+00
792	player	1420	1	1420	\N	1.00	2026-09-06 22:42:06.816471+00
793	player	1421	1	1421	\N	1.00	2026-09-06 22:42:06.816471+00
794	player	1422	1	1422	\N	1.00	2026-09-06 22:42:06.816471+00
795	player	1423	1	1423	\N	1.00	2026-09-06 22:42:06.816471+00
796	player	1424	1	1424	\N	1.00	2026-09-06 22:42:06.816471+00
797	player	1425	1	1425	\N	1.00	2026-09-06 22:42:06.816471+00
798	player	1426	1	1426	\N	1.00	2026-09-06 22:42:06.816471+00
799	player	1427	1	1427	\N	1.00	2026-09-06 22:42:06.816471+00
800	player	1428	1	1428	\N	1.00	2026-09-06 22:42:06.816471+00
801	player	1429	1	1429	\N	1.00	2026-09-06 22:42:06.816471+00
802	player	1430	1	1430	\N	1.00	2026-09-06 22:42:06.816471+00
803	player	1431	1	1431	\N	1.00	2026-09-06 22:42:06.816471+00
804	player	1432	1	1432	\N	1.00	2026-09-06 22:42:06.816471+00
805	player	1433	1	1433	\N	1.00	2026-09-06 22:42:06.816471+00
806	player	1434	1	1434	\N	1.00	2026-09-06 22:42:06.816471+00
807	player	1435	1	1435	\N	1.00	2026-09-06 22:42:06.816471+00
808	player	1436	1	1436	\N	1.00	2026-09-06 22:42:06.816471+00
809	player	1437	1	1437	\N	1.00	2026-09-06 22:42:06.816471+00
810	player	1438	1	1438	\N	1.00	2026-09-06 22:42:06.816471+00
811	player	1439	1	1439	\N	1.00	2026-09-06 22:42:06.816471+00
812	player	1440	1	1440	\N	1.00	2026-09-06 22:42:06.816471+00
813	player	1441	1	1441	\N	1.00	2026-09-06 22:42:06.816471+00
814	player	1442	1	1442	\N	1.00	2026-09-06 22:42:06.816471+00
815	player	1443	1	1443	\N	1.00	2026-09-06 22:42:06.816471+00
816	player	1444	1	1444	\N	1.00	2026-09-06 22:42:06.816471+00
817	player	1445	1	1445	\N	1.00	2026-09-06 22:42:06.816471+00
818	player	1446	1	1446	\N	1.00	2026-09-06 22:42:06.816471+00
819	player	1447	1	1447	\N	1.00	2026-09-06 22:42:06.816471+00
820	player	1448	1	1448	\N	1.00	2026-09-06 22:42:06.816471+00
821	player	1449	1	1449	\N	1.00	2026-09-06 22:42:06.816471+00
822	player	1450	1	1450	\N	1.00	2026-09-06 22:42:06.816471+00
823	player	1451	1	1451	\N	1.00	2026-09-06 22:42:06.816471+00
824	player	1452	1	1452	\N	1.00	2026-09-06 22:42:06.816471+00
825	player	1453	1	1453	\N	1.00	2026-09-06 22:42:06.816471+00
826	player	1454	1	1454	\N	1.00	2026-09-06 22:42:06.816471+00
827	player	1455	1	1455	\N	1.00	2026-09-06 22:42:06.816471+00
828	player	1456	1	1456	\N	1.00	2026-09-06 22:42:06.816471+00
829	player	1457	1	1457	\N	1.00	2026-09-06 22:42:06.816471+00
830	player	1458	1	1458	\N	1.00	2026-09-06 22:42:06.816471+00
831	player	1459	1	1459	\N	1.00	2026-09-06 22:42:06.816471+00
832	player	1460	1	1460	\N	1.00	2026-09-06 22:42:06.816471+00
833	player	1461	1	1461	\N	1.00	2026-09-06 22:42:06.816471+00
834	player	1462	1	1462	\N	1.00	2026-09-06 22:42:06.816471+00
835	player	1463	1	1463	\N	1.00	2026-09-06 22:42:06.816471+00
836	player	1464	1	1464	\N	1.00	2026-09-06 22:42:06.816471+00
837	player	1465	1	1465	\N	1.00	2026-09-06 22:42:06.816471+00
838	player	1466	1	1466	\N	1.00	2026-09-06 22:42:06.816471+00
839	player	1467	1	1467	\N	1.00	2026-09-06 22:42:06.816471+00
840	player	1468	1	1468	\N	1.00	2026-09-06 22:42:06.816471+00
841	player	1469	1	1469	\N	1.00	2026-09-06 22:42:06.816471+00
842	player	1470	1	1470	\N	1.00	2026-09-06 22:42:06.816471+00
843	player	1471	1	1471	\N	1.00	2026-09-06 22:42:06.816471+00
844	player	1472	1	1472	\N	1.00	2026-09-06 22:42:06.816471+00
845	player	1473	1	1473	\N	1.00	2026-09-06 22:42:06.816471+00
846	player	1474	1	1474	\N	1.00	2026-09-06 22:42:06.816471+00
847	player	1475	1	1475	\N	1.00	2026-09-06 22:42:06.816471+00
848	player	1476	1	1476	\N	1.00	2026-09-06 22:42:06.816471+00
849	player	1477	1	1477	\N	1.00	2026-09-06 22:42:06.816471+00
850	player	1478	1	1478	\N	1.00	2026-09-06 22:42:06.816471+00
851	player	1479	1	1479	\N	1.00	2026-09-06 22:42:06.816471+00
852	player	1480	1	1480	\N	1.00	2026-09-06 22:42:06.816471+00
853	player	1481	1	1481	\N	1.00	2026-09-06 22:42:06.816471+00
854	player	1482	1	1482	\N	1.00	2026-09-06 22:42:06.816471+00
855	player	1483	1	1483	\N	1.00	2026-09-06 22:42:06.816471+00
856	player	1484	1	1484	\N	1.00	2026-09-06 22:42:06.816471+00
857	player	1485	1	1485	\N	1.00	2026-09-06 22:42:06.816471+00
858	player	1486	1	1486	\N	1.00	2026-09-06 22:42:06.816471+00
859	player	1487	1	1487	\N	1.00	2026-09-06 22:42:06.816471+00
860	player	1488	1	1488	\N	1.00	2026-09-06 22:42:06.816471+00
861	player	1489	1	1489	\N	1.00	2026-09-06 22:42:06.816471+00
862	player	1490	1	1490	\N	1.00	2026-09-06 22:42:06.816471+00
863	player	1491	1	1491	\N	1.00	2026-09-06 22:42:06.816471+00
864	player	1492	1	1492	\N	1.00	2026-09-06 22:42:06.816471+00
865	player	1493	1	1493	\N	1.00	2026-09-06 22:42:06.816471+00
866	player	1494	1	1494	\N	1.00	2026-09-06 22:42:06.816471+00
867	player	1495	1	1495	\N	1.00	2026-09-06 22:42:06.816471+00
868	player	1496	1	1496	\N	1.00	2026-09-06 22:42:06.816471+00
869	player	1497	1	1497	\N	1.00	2026-09-06 22:42:06.816471+00
870	player	1498	1	1498	\N	1.00	2026-09-06 22:42:06.816471+00
871	player	1499	1	1499	\N	1.00	2026-09-06 22:42:06.816471+00
872	player	1500	1	1500	\N	1.00	2026-09-06 22:42:06.816471+00
873	player	1501	1	1501	\N	1.00	2026-09-06 22:42:06.816471+00
874	player	1502	1	1502	\N	1.00	2026-09-06 22:42:06.816471+00
875	player	1503	1	1503	\N	1.00	2026-09-06 22:42:06.816471+00
876	player	1504	1	1504	\N	1.00	2026-09-06 22:42:06.816471+00
877	player	1505	1	1505	\N	1.00	2026-09-06 22:42:06.816471+00
878	player	1506	1	1506	\N	1.00	2026-09-06 22:42:06.816471+00
879	player	1507	1	1507	\N	1.00	2026-09-06 22:42:06.816471+00
880	player	1508	1	1508	\N	1.00	2026-09-06 22:42:06.816471+00
881	player	1509	1	1509	\N	1.00	2026-09-06 22:42:06.816471+00
882	player	1510	1	1510	\N	1.00	2026-09-06 22:42:06.816471+00
883	player	1511	1	1511	\N	1.00	2026-09-06 22:42:06.816471+00
884	player	1512	1	1512	\N	1.00	2026-09-06 22:42:06.816471+00
885	player	1513	1	1513	\N	1.00	2026-09-06 22:42:06.816471+00
886	player	1514	1	1514	\N	1.00	2026-09-06 22:42:06.816471+00
887	player	1515	1	1515	\N	1.00	2026-09-06 22:42:06.816471+00
888	player	1516	1	1516	\N	1.00	2026-09-06 22:42:06.816471+00
889	player	1517	1	1517	\N	1.00	2026-09-06 22:42:06.816471+00
890	player	1518	1	1518	\N	1.00	2026-09-06 22:42:06.816471+00
891	player	1519	1	1519	\N	1.00	2026-09-06 22:42:06.816471+00
892	player	1520	1	1520	\N	1.00	2026-09-06 22:42:06.816471+00
893	player	1521	1	1521	\N	1.00	2026-09-06 22:42:06.816471+00
894	player	1522	1	1522	\N	1.00	2026-09-06 22:42:06.816471+00
895	player	1523	1	1523	\N	1.00	2026-09-06 22:42:06.816471+00
896	player	1524	1	1524	\N	1.00	2026-09-06 22:42:06.816471+00
897	player	1525	1	1525	\N	1.00	2026-09-06 22:42:06.816471+00
898	player	1526	1	1526	\N	1.00	2026-09-06 22:42:06.816471+00
899	player	1527	1	1527	\N	1.00	2026-09-06 22:42:06.816471+00
900	player	1528	1	1528	\N	1.00	2026-09-06 22:42:06.816471+00
901	player	1529	1	1529	\N	1.00	2026-09-06 22:42:06.816471+00
902	player	1530	1	1530	\N	1.00	2026-09-06 22:42:06.816471+00
903	player	1531	1	1531	\N	1.00	2026-09-06 22:42:06.816471+00
904	player	1532	1	1532	\N	1.00	2026-09-06 22:42:06.816471+00
905	player	1533	1	1533	\N	1.00	2026-09-06 22:42:06.816471+00
906	player	1534	1	1534	\N	1.00	2026-09-06 22:42:06.816471+00
907	player	1535	1	1535	\N	1.00	2026-09-06 22:42:06.816471+00
908	player	1536	1	1536	\N	1.00	2026-09-06 22:42:06.816471+00
909	player	1537	1	1537	\N	1.00	2026-09-06 22:42:06.816471+00
910	player	1538	1	1538	\N	1.00	2026-09-06 22:42:06.816471+00
911	player	1539	1	1539	\N	1.00	2026-09-06 22:42:06.816471+00
912	player	1540	1	1540	\N	1.00	2026-09-06 22:42:06.816471+00
913	player	1541	1	1541	\N	1.00	2026-09-06 22:42:06.816471+00
914	player	1542	1	1542	\N	1.00	2026-09-06 22:42:06.816471+00
915	player	1543	1	1543	\N	1.00	2026-09-06 22:42:06.816471+00
916	player	1544	1	1544	\N	1.00	2026-09-06 22:42:06.816471+00
917	player	1545	1	1545	\N	1.00	2026-09-06 22:42:06.816471+00
918	player	1546	1	1546	\N	1.00	2026-09-06 22:42:06.816471+00
919	player	1547	1	1547	\N	1.00	2026-09-06 22:42:06.816471+00
920	player	1548	1	1548	\N	1.00	2026-09-06 22:42:06.816471+00
921	player	1549	1	1549	\N	1.00	2026-09-06 22:42:06.816471+00
922	player	1550	1	1550	\N	1.00	2026-09-06 22:42:06.816471+00
923	player	1551	1	1551	\N	1.00	2026-09-06 22:42:06.816471+00
924	player	1552	1	1552	\N	1.00	2026-09-06 22:42:06.816471+00
925	player	1553	1	1553	\N	1.00	2026-09-06 22:42:06.816471+00
926	player	1554	1	1554	\N	1.00	2026-09-06 22:42:06.816471+00
927	player	1555	1	1555	\N	1.00	2026-09-06 22:42:06.816471+00
928	player	1556	1	1556	\N	1.00	2026-09-06 22:42:06.816471+00
929	player	1557	1	1557	\N	1.00	2026-09-06 22:42:06.816471+00
930	player	1558	1	1558	\N	1.00	2026-09-06 22:42:06.816471+00
931	player	1559	1	1559	\N	1.00	2026-09-06 22:42:06.816471+00
932	player	1560	1	1560	\N	1.00	2026-09-06 22:42:06.816471+00
933	player	1561	1	1561	\N	1.00	2026-09-06 22:42:06.816471+00
934	player	1562	1	1562	\N	1.00	2026-09-06 22:42:06.816471+00
935	player	1563	1	1563	\N	1.00	2026-09-06 22:42:06.816471+00
936	player	1564	1	1564	\N	1.00	2026-09-06 22:42:06.816471+00
937	player	1565	1	1565	\N	1.00	2026-09-06 22:42:06.816471+00
938	player	1566	1	1566	\N	1.00	2026-09-06 22:42:06.816471+00
939	player	1567	1	1567	\N	1.00	2026-09-06 22:42:06.816471+00
940	player	1568	1	1568	\N	1.00	2026-09-06 22:42:06.816471+00
941	player	1569	1	1569	\N	1.00	2026-09-06 22:42:06.816471+00
942	player	1570	1	1570	\N	1.00	2026-09-06 22:42:06.816471+00
943	player	1571	1	1571	\N	1.00	2026-09-06 22:42:06.816471+00
944	player	1572	1	1572	\N	1.00	2026-09-06 22:42:06.816471+00
945	player	1573	1	1573	\N	1.00	2026-09-06 22:42:06.816471+00
946	player	1574	1	1574	\N	1.00	2026-09-06 22:42:06.816471+00
947	player	1575	1	1575	\N	1.00	2026-09-06 22:42:06.816471+00
948	player	1576	1	1576	\N	1.00	2026-09-06 22:42:06.816471+00
949	player	1577	1	1577	\N	1.00	2026-09-06 22:42:06.816471+00
950	player	1578	1	1578	\N	1.00	2026-09-06 22:42:06.816471+00
951	player	1579	1	1579	\N	1.00	2026-09-06 22:42:06.816471+00
952	player	1580	1	1580	\N	1.00	2026-09-06 22:42:06.816471+00
953	player	1581	1	1581	\N	1.00	2026-09-06 22:42:06.816471+00
954	player	1582	1	1582	\N	1.00	2026-09-06 22:42:06.816471+00
955	player	1583	1	1583	\N	1.00	2026-09-06 22:42:06.816471+00
956	player	1584	1	1584	\N	1.00	2026-09-06 22:42:06.816471+00
957	player	1585	1	1585	\N	1.00	2026-09-06 22:42:06.816471+00
958	player	1586	1	1586	\N	1.00	2026-09-06 22:42:06.816471+00
959	player	1587	1	1587	\N	1.00	2026-09-06 22:42:06.816471+00
960	player	1588	1	1588	\N	1.00	2026-09-06 22:42:06.816471+00
961	player	1589	1	1589	\N	1.00	2026-09-06 22:42:06.816471+00
962	player	1590	1	1590	\N	1.00	2026-09-06 22:42:06.816471+00
963	player	1591	1	1591	\N	1.00	2026-09-06 22:42:06.816471+00
964	player	1592	1	1592	\N	1.00	2026-09-06 22:42:06.816471+00
965	player	1593	1	1593	\N	1.00	2026-09-06 22:42:06.816471+00
966	player	1594	1	1594	\N	1.00	2026-09-06 22:42:06.816471+00
967	player	1595	1	1595	\N	1.00	2026-09-06 22:42:06.816471+00
968	player	1596	1	1596	\N	1.00	2026-09-06 22:42:06.816471+00
969	player	1597	1	1597	\N	1.00	2026-09-06 22:42:06.816471+00
970	player	1598	1	1598	\N	1.00	2026-09-06 22:42:06.816471+00
971	player	1599	1	1599	\N	1.00	2026-09-06 22:42:06.816471+00
972	player	1600	1	1600	\N	1.00	2026-09-06 22:42:06.816471+00
973	player	1601	1	1601	\N	1.00	2026-09-06 22:42:06.816471+00
974	player	1602	1	1602	\N	1.00	2026-09-06 22:42:06.816471+00
975	player	1603	1	1603	\N	1.00	2026-09-06 22:42:06.816471+00
976	player	1604	1	1604	\N	1.00	2026-09-06 22:42:06.816471+00
977	player	1605	1	1605	\N	1.00	2026-09-06 22:42:06.816471+00
978	player	1606	1	1606	\N	1.00	2026-09-06 22:42:06.816471+00
979	player	1607	1	1607	\N	1.00	2026-09-06 22:42:06.816471+00
980	player	1608	1	1608	\N	1.00	2026-09-06 22:42:06.816471+00
981	player	1609	1	1609	\N	1.00	2026-09-06 22:42:06.816471+00
982	player	1610	1	1610	\N	1.00	2026-09-06 22:42:06.816471+00
983	player	1611	1	1611	\N	1.00	2026-09-06 22:42:06.816471+00
984	player	1612	1	1612	\N	1.00	2026-09-06 22:42:06.816471+00
985	player	1613	1	1613	\N	1.00	2026-09-06 22:42:06.816471+00
986	player	1614	1	1614	\N	1.00	2026-09-06 22:42:06.816471+00
987	player	1615	1	1615	\N	1.00	2026-09-06 22:42:06.816471+00
988	player	1616	1	1616	\N	1.00	2026-09-06 22:42:06.816471+00
989	player	1617	1	1617	\N	1.00	2026-09-06 22:42:06.816471+00
990	player	1618	1	1618	\N	1.00	2026-09-06 22:42:06.816471+00
991	player	1619	1	1619	\N	1.00	2026-09-06 22:42:06.816471+00
992	player	1620	1	1620	\N	1.00	2026-09-06 22:42:06.816471+00
993	player	1621	1	1621	\N	1.00	2026-09-06 22:42:06.816471+00
994	player	1622	1	1622	\N	1.00	2026-09-06 22:42:06.816471+00
995	player	1623	1	1623	\N	1.00	2026-09-06 22:42:06.816471+00
996	player	1624	1	1624	\N	1.00	2026-09-06 22:42:06.816471+00
997	player	1625	1	1625	\N	1.00	2026-09-06 22:42:06.816471+00
998	player	1626	1	1626	\N	1.00	2026-09-06 22:42:06.816471+00
999	player	1627	1	1627	\N	1.00	2026-09-06 22:42:06.816471+00
1000	player	1628	1	1628	\N	1.00	2026-09-06 22:42:06.816471+00
1001	player	1629	1	1629	\N	1.00	2026-09-06 22:42:06.816471+00
1002	player	1630	1	1630	\N	1.00	2026-09-06 22:42:06.816471+00
1003	player	1631	1	1631	\N	1.00	2026-09-06 22:42:06.816471+00
1004	player	1632	1	1632	\N	1.00	2026-09-06 22:42:06.816471+00
1005	player	1633	1	1633	\N	1.00	2026-09-06 22:42:06.816471+00
1006	player	1634	1	1634	\N	1.00	2026-09-06 22:42:06.816471+00
1007	player	1635	1	1635	\N	1.00	2026-09-06 22:42:06.816471+00
1008	player	1636	1	1636	\N	1.00	2026-09-06 22:42:06.816471+00
1009	player	1637	1	1637	\N	1.00	2026-09-06 22:42:06.816471+00
1010	player	1638	1	1638	\N	1.00	2026-09-06 22:42:06.816471+00
1011	player	1639	1	1639	\N	1.00	2026-09-06 22:42:06.816471+00
1012	player	1640	1	1640	\N	1.00	2026-09-06 22:42:06.816471+00
1013	player	1641	1	1641	\N	1.00	2026-09-06 22:42:06.816471+00
1014	player	1642	1	1642	\N	1.00	2026-09-06 22:42:06.816471+00
1015	player	1643	1	1643	\N	1.00	2026-09-06 22:42:06.816471+00
1016	player	1644	1	1644	\N	1.00	2026-09-06 22:42:06.816471+00
1017	player	1645	1	1645	\N	1.00	2026-09-06 22:42:06.816471+00
1018	player	1646	1	1646	\N	1.00	2026-09-06 22:42:06.816471+00
1019	player	1647	1	1647	\N	1.00	2026-09-06 22:42:06.816471+00
1020	player	1648	1	1648	\N	1.00	2026-09-06 22:42:06.816471+00
1021	player	1649	1	1649	\N	1.00	2026-09-06 22:42:06.816471+00
1022	player	1650	1	1650	\N	1.00	2026-09-06 22:42:06.816471+00
1023	player	1651	1	1651	\N	1.00	2026-09-06 22:42:06.816471+00
1024	player	1652	1	1652	\N	1.00	2026-09-06 22:42:06.816471+00
1025	player	1653	1	1653	\N	1.00	2026-09-06 22:42:06.816471+00
1026	player	1654	1	1654	\N	1.00	2026-09-06 22:42:06.816471+00
1027	player	1655	1	1655	\N	1.00	2026-09-06 22:42:06.816471+00
1028	player	1656	1	1656	\N	1.00	2026-09-06 22:42:06.816471+00
1029	player	1657	1	1657	\N	1.00	2026-09-06 22:42:06.816471+00
1030	player	1658	1	1658	\N	1.00	2026-09-06 22:42:06.816471+00
1031	player	1659	1	1659	\N	1.00	2026-09-06 22:42:06.816471+00
1032	player	1660	1	1660	\N	1.00	2026-09-06 22:42:06.816471+00
1033	player	1661	1	1661	\N	1.00	2026-09-06 22:42:06.816471+00
1034	player	1662	1	1662	\N	1.00	2026-09-06 22:42:06.816471+00
1035	player	1663	1	1663	\N	1.00	2026-09-06 22:42:06.816471+00
1036	player	1664	1	1664	\N	1.00	2026-09-06 22:42:06.816471+00
1037	player	1665	1	1665	\N	1.00	2026-09-06 22:42:06.816471+00
1038	player	1666	1	1666	\N	1.00	2026-09-06 22:42:06.816471+00
1039	player	1667	1	1667	\N	1.00	2026-09-06 22:42:06.816471+00
1040	player	1668	1	1668	\N	1.00	2026-09-06 22:42:06.816471+00
1041	player	1669	1	1669	\N	1.00	2026-09-06 22:42:06.816471+00
1042	player	1670	1	1670	\N	1.00	2026-09-06 22:42:06.816471+00
1043	player	1671	1	1671	\N	1.00	2026-09-06 22:42:06.816471+00
1044	player	1672	1	1672	\N	1.00	2026-09-06 22:42:06.816471+00
1045	player	1673	1	1673	\N	1.00	2026-09-06 22:42:06.816471+00
1046	player	1674	1	1674	\N	1.00	2026-09-06 22:42:06.816471+00
1047	player	1675	1	1675	\N	1.00	2026-09-06 22:42:06.816471+00
1048	player	1676	1	1676	\N	1.00	2026-09-06 22:42:06.816471+00
1049	player	1677	1	1677	\N	1.00	2026-09-06 22:42:06.816471+00
1050	player	1678	1	1678	\N	1.00	2026-09-06 22:42:06.816471+00
1051	player	1679	1	1679	\N	1.00	2026-09-06 22:42:06.816471+00
1052	player	1680	1	1680	\N	1.00	2026-09-06 22:42:06.816471+00
1053	player	1681	1	1681	\N	1.00	2026-09-06 22:42:06.816471+00
1054	player	1682	1	1682	\N	1.00	2026-09-06 22:42:06.816471+00
1055	player	1683	1	1683	\N	1.00	2026-09-06 22:42:06.816471+00
1056	player	1684	1	1684	\N	1.00	2026-09-06 22:42:06.816471+00
1057	player	1685	1	1685	\N	1.00	2026-09-06 22:42:06.816471+00
1058	player	1686	1	1686	\N	1.00	2026-09-06 22:42:06.816471+00
1059	player	1687	1	1687	\N	1.00	2026-09-06 22:42:06.816471+00
1060	player	1688	1	1688	\N	1.00	2026-09-06 22:42:06.816471+00
1061	player	1689	1	1689	\N	1.00	2026-09-06 22:42:06.816471+00
1062	player	1690	1	1690	\N	1.00	2026-09-06 22:42:06.816471+00
1063	player	1691	1	1691	\N	1.00	2026-09-06 22:42:06.816471+00
1064	player	1692	1	1692	\N	1.00	2026-09-06 22:42:06.816471+00
1065	player	1693	1	1693	\N	1.00	2026-09-06 22:42:06.816471+00
1066	player	1694	1	1694	\N	1.00	2026-09-06 22:42:06.816471+00
1067	player	1695	1	1695	\N	1.00	2026-09-06 22:42:06.816471+00
1068	player	1696	1	1696	\N	1.00	2026-09-06 22:42:06.816471+00
1069	player	1697	1	1697	\N	1.00	2026-09-06 22:42:06.816471+00
1070	player	1698	1	1698	\N	1.00	2026-09-06 22:42:06.816471+00
1071	player	1699	1	1699	\N	1.00	2026-09-06 22:42:06.816471+00
1072	player	1700	1	1700	\N	1.00	2026-09-06 22:42:06.816471+00
1073	player	1701	1	1701	\N	1.00	2026-09-06 22:42:06.816471+00
1074	player	1702	1	1702	\N	1.00	2026-09-06 22:42:06.816471+00
1075	player	1703	1	1703	\N	1.00	2026-09-06 22:42:06.816471+00
1076	player	1704	1	1704	\N	1.00	2026-09-06 22:42:06.816471+00
1077	player	1705	1	1705	\N	1.00	2026-09-06 22:42:06.816471+00
1078	player	1706	1	1706	\N	1.00	2026-09-06 22:42:06.816471+00
1079	player	1707	1	1707	\N	1.00	2026-09-06 22:42:06.816471+00
1080	player	1708	1	1708	\N	1.00	2026-09-06 22:42:06.816471+00
1081	player	1709	1	1709	\N	1.00	2026-09-06 22:42:06.816471+00
1082	player	1710	1	1710	\N	1.00	2026-09-06 22:42:06.816471+00
1083	player	1711	1	1711	\N	1.00	2026-09-06 22:42:06.816471+00
1084	player	1712	1	1712	\N	1.00	2026-09-06 22:42:06.816471+00
1085	player	1713	1	1713	\N	1.00	2026-09-06 22:42:06.816471+00
1086	player	1714	1	1714	\N	1.00	2026-09-06 22:42:06.816471+00
1087	player	1715	1	1715	\N	1.00	2026-09-06 22:42:06.816471+00
1088	player	1716	1	1716	\N	1.00	2026-09-06 22:42:06.816471+00
1089	player	1717	1	1717	\N	1.00	2026-09-06 22:42:06.816471+00
1090	player	1718	1	1718	\N	1.00	2026-09-06 22:42:06.816471+00
1091	player	1719	1	1719	\N	1.00	2026-09-06 22:42:06.816471+00
1092	player	1720	1	1720	\N	1.00	2026-09-06 22:42:06.816471+00
1093	player	1721	1	1721	\N	1.00	2026-09-06 22:42:06.816471+00
1094	player	1722	1	1722	\N	1.00	2026-09-06 22:42:06.816471+00
1095	player	1723	1	1723	\N	1.00	2026-09-06 22:42:06.816471+00
1096	player	1724	1	1724	\N	1.00	2026-09-06 22:42:06.816471+00
1097	player	1725	1	1725	\N	1.00	2026-09-06 22:42:06.816471+00
1098	player	1726	1	1726	\N	1.00	2026-09-06 22:42:06.816471+00
1099	player	1727	1	1727	\N	1.00	2026-09-06 22:42:06.816471+00
1100	player	1728	1	1728	\N	1.00	2026-09-06 22:42:06.816471+00
1101	player	1729	1	1729	\N	1.00	2026-09-06 22:42:06.816471+00
1102	player	1730	1	1730	\N	1.00	2026-09-06 22:42:06.816471+00
1103	player	1731	1	1731	\N	1.00	2026-09-06 22:42:06.816471+00
1104	player	1732	1	1732	\N	1.00	2026-09-06 22:42:06.816471+00
1105	player	1733	1	1733	\N	1.00	2026-09-06 22:42:06.816471+00
1106	player	1734	1	1734	\N	1.00	2026-09-06 22:42:06.816471+00
1107	player	1735	1	1735	\N	1.00	2026-09-06 22:42:06.816471+00
1108	player	1736	1	1736	\N	1.00	2026-09-06 22:42:06.816471+00
1109	player	1737	1	1737	\N	1.00	2026-09-06 22:42:06.816471+00
1110	player	1738	1	1738	\N	1.00	2026-09-06 22:42:06.816471+00
1111	player	1739	1	1739	\N	1.00	2026-09-06 22:42:06.816471+00
1112	player	1740	1	1740	\N	1.00	2026-09-06 22:42:06.816471+00
1113	player	1741	1	1741	\N	1.00	2026-09-06 22:42:06.816471+00
1114	player	1742	1	1742	\N	1.00	2026-09-06 22:42:06.816471+00
1115	player	1743	1	1743	\N	1.00	2026-09-06 22:42:06.816471+00
1116	player	1744	1	1744	\N	1.00	2026-09-06 22:42:06.816471+00
1117	player	1745	1	1745	\N	1.00	2026-09-06 22:42:06.816471+00
1118	player	1746	1	1746	\N	1.00	2026-09-06 22:42:06.816471+00
1119	player	1747	1	1747	\N	1.00	2026-09-06 22:42:06.816471+00
1120	player	1748	1	1748	\N	1.00	2026-09-06 22:42:06.816471+00
1121	player	1749	1	1749	\N	1.00	2026-09-06 22:42:06.816471+00
1122	player	1750	1	1750	\N	1.00	2026-09-06 22:42:06.816471+00
1123	player	1751	1	1751	\N	1.00	2026-09-06 22:42:06.816471+00
1124	player	1752	1	1752	\N	1.00	2026-09-06 22:42:06.816471+00
1125	player	1753	1	1753	\N	1.00	2026-09-06 22:42:06.816471+00
1126	player	1754	1	1754	\N	1.00	2026-09-06 22:42:06.816471+00
1127	player	1755	1	1755	\N	1.00	2026-09-06 22:42:06.816471+00
1128	player	1756	1	1756	\N	1.00	2026-09-06 22:42:06.816471+00
1129	player	1757	1	1757	\N	1.00	2026-09-06 22:42:06.816471+00
1130	player	1758	1	1758	\N	1.00	2026-09-06 22:42:06.816471+00
1131	player	1759	1	1759	\N	1.00	2026-09-06 22:42:06.816471+00
1132	player	1760	1	1760	\N	1.00	2026-09-06 22:42:06.816471+00
1133	player	1761	1	1761	\N	1.00	2026-09-06 22:42:06.816471+00
1134	player	1762	1	1762	\N	1.00	2026-09-06 22:42:06.816471+00
1135	player	1763	1	1763	\N	1.00	2026-09-06 22:42:06.816471+00
1136	player	1764	1	1764	\N	1.00	2026-09-06 22:42:06.816471+00
1137	player	1765	1	1765	\N	1.00	2026-09-06 22:42:06.816471+00
1138	player	1766	1	1766	\N	1.00	2026-09-06 22:42:06.816471+00
1139	player	1767	1	1767	\N	1.00	2026-09-06 22:42:06.816471+00
1140	player	1768	1	1768	\N	1.00	2026-09-06 22:42:06.816471+00
1141	player	1769	1	1769	\N	1.00	2026-09-06 22:42:06.816471+00
1142	player	1770	1	1770	\N	1.00	2026-09-06 22:42:06.816471+00
1143	player	1771	1	1771	\N	1.00	2026-09-06 22:42:06.816471+00
1144	player	1772	1	1772	\N	1.00	2026-09-06 22:42:06.816471+00
1145	player	1773	1	1773	\N	1.00	2026-09-06 22:42:06.816471+00
1146	player	1774	1	1774	\N	1.00	2026-09-06 22:42:06.816471+00
1147	player	1775	1	1775	\N	1.00	2026-09-06 22:42:06.816471+00
1148	player	1776	1	1776	\N	1.00	2026-09-06 22:42:06.816471+00
1149	player	1777	1	1777	\N	1.00	2026-09-06 22:42:06.816471+00
1150	player	1778	1	1778	\N	1.00	2026-09-06 22:42:06.816471+00
1151	player	1779	1	1779	\N	1.00	2026-09-06 22:42:06.816471+00
1152	player	1780	1	1780	\N	1.00	2026-09-06 22:42:06.816471+00
1153	player	1781	1	1781	\N	1.00	2026-09-06 22:42:06.816471+00
1154	player	1782	1	1782	\N	1.00	2026-09-06 22:42:06.816471+00
1155	player	1783	1	1783	\N	1.00	2026-09-06 22:42:06.816471+00
1156	player	1784	1	1784	\N	1.00	2026-09-06 22:42:06.816471+00
1157	player	1785	1	1785	\N	1.00	2026-09-06 22:42:06.816471+00
1158	player	1786	1	1786	\N	1.00	2026-09-06 22:42:06.816471+00
1159	player	1787	1	1787	\N	1.00	2026-09-06 22:42:06.816471+00
1160	player	1788	1	1788	\N	1.00	2026-09-06 22:42:06.816471+00
1161	player	1789	1	1789	\N	1.00	2026-09-06 22:42:06.816471+00
1162	player	1790	1	1790	\N	1.00	2026-09-06 22:42:06.816471+00
1163	player	1791	1	1791	\N	1.00	2026-09-06 22:42:06.816471+00
1164	player	1792	1	1792	\N	1.00	2026-09-06 22:42:06.816471+00
1165	player	1793	1	1793	\N	1.00	2026-09-06 22:42:06.816471+00
1166	player	1794	1	1794	\N	1.00	2026-09-06 22:42:06.816471+00
1167	player	1795	1	1795	\N	1.00	2026-09-06 22:42:06.816471+00
1168	player	1796	1	1796	\N	1.00	2026-09-06 22:42:06.816471+00
1169	player	1797	1	1797	\N	1.00	2026-09-06 22:42:06.816471+00
1170	player	1798	1	1798	\N	1.00	2026-09-06 22:42:06.816471+00
1171	player	1799	1	1799	\N	1.00	2026-09-06 22:42:06.816471+00
1172	player	1800	1	1800	\N	1.00	2026-09-06 22:42:06.816471+00
1173	player	1801	1	1801	\N	1.00	2026-09-06 22:42:06.816471+00
1174	player	1802	1	1802	\N	1.00	2026-09-06 22:42:06.816471+00
1175	player	1803	1	1803	\N	1.00	2026-09-06 22:42:06.816471+00
1176	player	1804	1	1804	\N	1.00	2026-09-06 22:42:06.816471+00
1177	player	1805	1	1805	\N	1.00	2026-09-06 22:42:06.816471+00
1178	player	1806	1	1806	\N	1.00	2026-09-06 22:42:06.816471+00
1179	player	1807	1	1807	\N	1.00	2026-09-06 22:42:06.816471+00
1180	player	1808	1	1808	\N	1.00	2026-09-06 22:42:06.816471+00
1181	player	1809	1	1809	\N	1.00	2026-09-06 22:42:06.816471+00
1182	player	1810	1	1810	\N	1.00	2026-09-06 22:42:06.816471+00
1183	player	1811	1	1811	\N	1.00	2026-09-06 22:42:06.816471+00
1184	player	1812	1	1812	\N	1.00	2026-09-06 22:42:06.816471+00
1185	player	1813	1	1813	\N	1.00	2026-09-06 22:42:06.816471+00
1186	player	1814	1	1814	\N	1.00	2026-09-06 22:42:06.816471+00
1187	player	1815	1	1815	\N	1.00	2026-09-06 22:42:06.816471+00
1188	player	1816	1	1816	\N	1.00	2026-09-06 22:42:06.816471+00
1189	player	1817	1	1817	\N	1.00	2026-09-06 22:42:06.816471+00
1190	player	1818	1	1818	\N	1.00	2026-09-06 22:42:06.816471+00
1191	player	1819	1	1819	\N	1.00	2026-09-06 22:42:06.816471+00
1192	player	1820	1	1820	\N	1.00	2026-09-06 22:42:06.816471+00
1193	player	1821	1	1821	\N	1.00	2026-09-06 22:42:06.816471+00
1194	player	1822	1	1822	\N	1.00	2026-09-06 22:42:06.816471+00
1195	player	1823	1	1823	\N	1.00	2026-09-06 22:42:06.816471+00
1196	player	1824	1	1824	\N	1.00	2026-09-06 22:42:06.816471+00
1197	player	1825	1	1825	\N	1.00	2026-09-06 22:42:06.816471+00
1198	player	1826	1	1826	\N	1.00	2026-09-06 22:42:06.816471+00
1199	player	1827	1	1827	\N	1.00	2026-09-06 22:42:06.816471+00
1200	player	1828	1	1828	\N	1.00	2026-09-06 22:42:06.816471+00
1201	player	1829	1	1829	\N	1.00	2026-09-06 22:42:06.816471+00
1202	player	1830	1	1830	\N	1.00	2026-09-06 22:42:06.816471+00
1203	player	1831	1	1831	\N	1.00	2026-09-06 22:42:06.816471+00
1204	player	1832	1	1832	\N	1.00	2026-09-06 22:42:06.816471+00
1205	player	1833	1	1833	\N	1.00	2026-09-06 22:42:06.816471+00
1206	player	1834	1	1834	\N	1.00	2026-09-06 22:42:06.816471+00
1207	player	1835	1	1835	\N	1.00	2026-09-06 22:42:06.816471+00
1208	player	1836	1	1836	\N	1.00	2026-09-06 22:42:06.816471+00
1209	player	1837	1	1837	\N	1.00	2026-09-06 22:42:06.816471+00
1210	player	1838	1	1838	\N	1.00	2026-09-06 22:42:06.816471+00
1211	player	1839	1	1839	\N	1.00	2026-09-06 22:42:06.816471+00
1212	player	1840	1	1840	\N	1.00	2026-09-06 22:42:06.816471+00
1213	player	1841	1	1841	\N	1.00	2026-09-06 22:42:06.816471+00
1214	player	1842	1	1842	\N	1.00	2026-09-06 22:42:06.816471+00
1215	player	1843	1	1843	\N	1.00	2026-09-06 22:42:06.816471+00
1216	player	1844	1	1844	\N	1.00	2026-09-06 22:42:06.816471+00
1217	player	1845	1	1845	\N	1.00	2026-09-06 22:42:06.816471+00
1218	player	1846	1	1846	\N	1.00	2026-09-06 22:42:06.816471+00
1219	player	1847	1	1847	\N	1.00	2026-09-06 22:42:06.816471+00
1220	player	1848	1	1848	\N	1.00	2026-09-06 22:42:06.816471+00
1221	player	1849	1	1849	\N	1.00	2026-09-06 22:42:06.816471+00
1222	player	1850	1	1850	\N	1.00	2026-09-06 22:42:06.816471+00
1223	player	1851	1	1851	\N	1.00	2026-09-06 22:42:06.816471+00
1224	player	1852	1	1852	\N	1.00	2026-09-06 22:42:06.816471+00
1225	player	1853	1	1853	\N	1.00	2026-09-06 22:42:06.816471+00
1226	player	1854	1	1854	\N	1.00	2026-09-06 22:42:06.816471+00
1227	player	1855	1	1855	\N	1.00	2026-09-06 22:42:06.816471+00
1228	player	1856	1	1856	\N	1.00	2026-09-06 22:42:06.816471+00
1229	player	1857	1	1857	\N	1.00	2026-09-06 22:42:06.816471+00
1230	player	1858	1	1858	\N	1.00	2026-09-06 22:42:06.816471+00
1231	player	1859	1	1859	\N	1.00	2026-09-06 22:42:06.816471+00
1232	player	1860	1	1860	\N	1.00	2026-09-06 22:42:06.816471+00
1233	player	1861	1	1861	\N	1.00	2026-09-06 22:42:06.816471+00
1234	player	1862	1	1862	\N	1.00	2026-09-06 22:42:06.816471+00
1235	player	1863	1	1863	\N	1.00	2026-09-06 22:42:06.816471+00
1236	player	1864	1	1864	\N	1.00	2026-09-06 22:42:06.816471+00
1237	player	1865	1	1865	\N	1.00	2026-09-06 22:42:06.816471+00
1238	player	1866	1	1866	\N	1.00	2026-09-06 22:42:06.816471+00
1239	player	1867	1	1867	\N	1.00	2026-09-06 22:42:06.816471+00
1240	player	1868	1	1868	\N	1.00	2026-09-06 22:42:06.816471+00
1241	player	1869	1	1869	\N	1.00	2026-09-06 22:42:06.816471+00
1242	player	1870	1	1870	\N	1.00	2026-09-06 22:42:06.816471+00
1243	player	1871	1	1871	\N	1.00	2026-09-06 22:42:06.816471+00
1244	player	1872	1	1872	\N	1.00	2026-09-06 22:42:06.816471+00
1245	player	1873	1	1873	\N	1.00	2026-09-06 22:42:06.816471+00
1246	player	1874	1	1874	\N	1.00	2026-09-06 22:42:06.816471+00
1247	player	1875	1	1875	\N	1.00	2026-09-06 22:42:06.816471+00
1248	player	1876	1	1876	\N	1.00	2026-09-06 22:42:06.816471+00
1249	player	1877	1	1877	\N	1.00	2026-09-06 22:42:06.816471+00
1250	player	1878	1	1878	\N	1.00	2026-09-06 22:42:06.816471+00
1251	player	1879	1	1879	\N	1.00	2026-09-06 22:42:06.816471+00
1252	player	1880	1	1880	\N	1.00	2026-09-06 22:42:06.816471+00
1253	player	1881	1	1881	\N	1.00	2026-09-06 22:42:06.816471+00
1254	player	1882	1	1882	\N	1.00	2026-09-06 22:42:06.816471+00
1255	player	1883	1	1883	\N	1.00	2026-09-06 22:42:06.816471+00
1256	player	1884	1	1884	\N	1.00	2026-09-06 22:42:06.816471+00
1257	player	1885	1	1885	\N	1.00	2026-09-06 22:42:06.816471+00
1258	player	1886	1	1886	\N	1.00	2026-09-06 22:42:06.816471+00
1259	player	1887	1	1887	\N	1.00	2026-09-06 22:42:06.816471+00
1260	player	1888	1	1888	\N	1.00	2026-09-06 22:42:06.816471+00
1261	player	1889	1	1889	\N	1.00	2026-09-06 22:42:06.816471+00
1262	player	1890	1	1890	\N	1.00	2026-09-06 22:42:06.816471+00
1263	player	1891	1	1891	\N	1.00	2026-09-06 22:42:06.816471+00
1264	player	1892	1	1892	\N	1.00	2026-09-06 22:42:06.816471+00
1265	player	1893	1	1893	\N	1.00	2026-09-06 22:42:06.816471+00
1266	player	1894	1	1894	\N	1.00	2026-09-06 22:42:06.816471+00
1267	player	1895	1	1895	\N	1.00	2026-09-06 22:42:06.816471+00
1268	player	1896	1	1896	\N	1.00	2026-09-06 22:42:06.816471+00
1269	player	1897	1	1897	\N	1.00	2026-09-06 22:42:06.816471+00
1270	player	1898	1	1898	\N	1.00	2026-09-06 22:42:06.816471+00
1271	player	1899	1	1899	\N	1.00	2026-09-06 22:42:06.816471+00
1272	player	1900	1	1900	\N	1.00	2026-09-06 22:42:06.816471+00
1273	player	1901	1	1901	\N	1.00	2026-09-06 22:42:06.816471+00
1274	player	1902	1	1902	\N	1.00	2026-09-06 22:42:06.816471+00
1275	player	1903	1	1903	\N	1.00	2026-09-06 22:42:06.816471+00
1276	player	1904	1	1904	\N	1.00	2026-09-06 22:42:06.816471+00
1277	player	1905	1	1905	\N	1.00	2026-09-06 22:42:06.816471+00
1278	player	1906	1	1906	\N	1.00	2026-09-06 22:42:06.816471+00
1279	player	1907	1	1907	\N	1.00	2026-09-06 22:42:06.816471+00
1280	player	1908	1	1908	\N	1.00	2026-09-06 22:42:06.816471+00
1281	player	1909	1	1909	\N	1.00	2026-09-06 22:42:06.816471+00
1282	player	1910	1	1910	\N	1.00	2026-09-06 22:42:06.816471+00
1283	player	1911	1	1911	\N	1.00	2026-09-06 22:42:06.816471+00
1284	player	1912	1	1912	\N	1.00	2026-09-06 22:42:06.816471+00
1285	player	1913	1	1913	\N	1.00	2026-09-06 22:42:06.816471+00
1286	player	1914	1	1914	\N	1.00	2026-09-06 22:42:06.816471+00
1287	player	1915	1	1915	\N	1.00	2026-09-06 22:42:06.816471+00
1288	player	1916	1	1916	\N	1.00	2026-09-06 22:42:06.816471+00
1289	player	1917	1	1917	\N	1.00	2026-09-06 22:42:06.816471+00
1290	player	1918	1	1918	\N	1.00	2026-09-06 22:42:06.816471+00
1291	player	1919	1	1919	\N	1.00	2026-09-06 22:42:06.816471+00
1292	player	1920	1	1920	\N	1.00	2026-09-06 22:42:06.816471+00
1293	player	1921	1	1921	\N	1.00	2026-09-06 22:42:06.816471+00
1294	player	1922	1	1922	\N	1.00	2026-09-06 22:42:06.816471+00
1295	player	1923	1	1923	\N	1.00	2026-09-06 22:42:06.816471+00
1296	player	1924	1	1924	\N	1.00	2026-09-06 22:42:06.816471+00
1297	player	1925	1	1925	\N	1.00	2026-09-06 22:42:06.816471+00
1298	player	1926	1	1926	\N	1.00	2026-09-06 22:42:06.816471+00
1299	player	1927	1	1927	\N	1.00	2026-09-06 22:42:06.816471+00
1300	player	1928	1	1928	\N	1.00	2026-09-06 22:42:06.816471+00
1301	player	1929	1	1929	\N	1.00	2026-09-06 22:42:06.816471+00
1302	player	1930	1	1930	\N	1.00	2026-09-06 22:42:06.816471+00
1303	player	1931	1	1931	\N	1.00	2026-09-06 22:42:06.816471+00
1304	player	1932	1	1932	\N	1.00	2026-09-06 22:42:06.816471+00
1305	player	1933	1	1933	\N	1.00	2026-09-06 22:42:06.816471+00
1306	player	1934	1	1934	\N	1.00	2026-09-06 22:42:06.816471+00
1307	player	1935	1	1935	\N	1.00	2026-09-06 22:42:06.816471+00
1308	player	1936	1	1936	\N	1.00	2026-09-06 22:42:06.816471+00
1309	player	1937	1	1937	\N	1.00	2026-09-06 22:42:06.816471+00
1310	player	1938	1	1938	\N	1.00	2026-09-06 22:42:06.816471+00
1311	player	1939	1	1939	\N	1.00	2026-09-06 22:42:06.816471+00
1312	player	1940	1	1940	\N	1.00	2026-09-06 22:42:06.816471+00
1313	player	1941	1	1941	\N	1.00	2026-09-06 22:42:06.816471+00
1314	player	1942	1	1942	\N	1.00	2026-09-06 22:42:06.816471+00
1315	player	1943	1	1943	\N	1.00	2026-09-06 22:42:06.816471+00
1316	player	1944	1	1944	\N	1.00	2026-09-06 22:42:06.816471+00
1317	player	1945	1	1945	\N	1.00	2026-09-06 22:42:06.816471+00
1318	player	1946	1	1946	\N	1.00	2026-09-06 22:42:06.816471+00
1319	player	1947	1	1947	\N	1.00	2026-09-06 22:42:06.816471+00
1320	player	1948	1	1948	\N	1.00	2026-09-06 22:42:06.816471+00
1321	player	1949	1	1949	\N	1.00	2026-09-06 22:42:06.816471+00
1322	player	1950	1	1950	\N	1.00	2026-09-06 22:42:06.816471+00
1323	player	1951	1	1951	\N	1.00	2026-09-06 22:42:06.816471+00
1324	player	1952	1	1952	\N	1.00	2026-09-06 22:42:06.816471+00
1325	player	1953	1	1953	\N	1.00	2026-09-06 22:42:06.816471+00
1326	player	1954	1	1954	\N	1.00	2026-09-06 22:42:06.816471+00
1327	player	1955	1	1955	\N	1.00	2026-09-06 22:42:06.816471+00
1328	player	1956	1	1956	\N	1.00	2026-09-06 22:42:06.816471+00
1329	player	1957	1	1957	\N	1.00	2026-09-06 22:42:06.816471+00
1330	player	1958	1	1958	\N	1.00	2026-09-06 22:42:06.816471+00
1331	player	1959	1	1959	\N	1.00	2026-09-06 22:42:06.816471+00
1332	player	1960	1	1960	\N	1.00	2026-09-06 22:42:06.816471+00
1333	player	1961	1	1961	\N	1.00	2026-09-06 22:42:06.816471+00
1334	player	1962	1	1962	\N	1.00	2026-09-06 22:42:06.816471+00
1335	player	1963	1	1963	\N	1.00	2026-09-06 22:42:06.816471+00
1336	player	1964	1	1964	\N	1.00	2026-09-06 22:42:06.816471+00
1337	player	1965	1	1965	\N	1.00	2026-09-06 22:42:06.816471+00
1338	player	1966	1	1966	\N	1.00	2026-09-06 22:42:06.816471+00
1339	player	1967	1	1967	\N	1.00	2026-09-06 22:42:06.816471+00
1340	player	1968	1	1968	\N	1.00	2026-09-06 22:42:06.816471+00
1341	player	1969	1	1969	\N	1.00	2026-09-06 22:42:06.816471+00
1342	player	1970	1	1970	\N	1.00	2026-09-06 22:42:06.816471+00
1343	player	1971	1	1971	\N	1.00	2026-09-06 22:42:06.816471+00
1344	player	1972	1	1972	\N	1.00	2026-09-06 22:42:06.816471+00
1345	player	1973	1	1973	\N	1.00	2026-09-06 22:42:06.816471+00
1346	player	1974	1	1974	\N	1.00	2026-09-06 22:42:06.816471+00
1347	player	1975	1	1975	\N	1.00	2026-09-06 22:42:06.816471+00
1348	player	1976	1	1976	\N	1.00	2026-09-06 22:42:06.816471+00
1349	player	1977	1	1977	\N	1.00	2026-09-06 22:42:06.816471+00
1350	player	1978	1	1978	\N	1.00	2026-09-06 22:42:06.816471+00
1351	player	1979	1	1979	\N	1.00	2026-09-06 22:42:06.816471+00
1352	player	1980	1	1980	\N	1.00	2026-09-06 22:42:06.816471+00
1353	player	1981	1	1981	\N	1.00	2026-09-06 22:42:06.816471+00
1354	player	1982	1	1982	\N	1.00	2026-09-06 22:42:06.816471+00
1355	player	1983	1	1983	\N	1.00	2026-09-06 22:42:06.816471+00
1356	player	1984	1	1984	\N	1.00	2026-09-06 22:42:06.816471+00
1357	player	1985	1	1985	\N	1.00	2026-09-06 22:42:06.816471+00
1358	player	1986	1	1986	\N	1.00	2026-09-06 22:42:06.816471+00
1359	player	1987	1	1987	\N	1.00	2026-09-06 22:42:06.816471+00
1360	player	1988	1	1988	\N	1.00	2026-09-06 22:42:06.816471+00
1361	player	1989	1	1989	\N	1.00	2026-09-06 22:42:06.816471+00
1362	player	1990	1	1990	\N	1.00	2026-09-06 22:42:06.816471+00
1363	player	1991	1	1991	\N	1.00	2026-09-06 22:42:06.816471+00
1364	player	1992	1	1992	\N	1.00	2026-09-06 22:42:06.816471+00
1365	player	1993	1	1993	\N	1.00	2026-09-06 22:42:06.816471+00
1366	player	1994	1	1994	\N	1.00	2026-09-06 22:42:06.816471+00
1367	player	1995	1	1995	\N	1.00	2026-09-06 22:42:06.816471+00
1368	player	1996	1	1996	\N	1.00	2026-09-06 22:42:06.816471+00
1369	player	1997	1	1997	\N	1.00	2026-09-06 22:42:06.816471+00
1370	player	1998	1	1998	\N	1.00	2026-09-06 22:42:06.816471+00
1371	player	1999	1	1999	\N	1.00	2026-09-06 22:42:06.816471+00
1372	player	2000	1	2000	\N	1.00	2026-09-06 22:42:06.816471+00
1373	player	2001	1	2001	\N	1.00	2026-09-06 22:42:06.816471+00
1374	player	2002	1	2002	\N	1.00	2026-09-06 22:42:06.816471+00
1375	player	2003	1	2003	\N	1.00	2026-09-06 22:42:06.816471+00
1376	player	2004	1	2004	\N	1.00	2026-09-06 22:42:06.816471+00
1377	player	2005	1	2005	\N	1.00	2026-09-06 22:42:06.816471+00
1378	player	2006	1	2006	\N	1.00	2026-09-06 22:42:06.816471+00
1379	player	2007	1	2007	\N	1.00	2026-09-06 22:42:06.816471+00
1380	player	2008	1	2008	\N	1.00	2026-09-06 22:42:06.816471+00
1381	player	2009	1	2009	\N	1.00	2026-09-06 22:42:06.816471+00
1382	player	2010	1	2010	\N	1.00	2026-09-06 22:42:06.816471+00
1383	player	2011	1	2011	\N	1.00	2026-09-06 22:42:06.816471+00
1384	player	2012	1	2012	\N	1.00	2026-09-06 22:42:06.816471+00
1385	player	2013	1	2013	\N	1.00	2026-09-06 22:42:06.816471+00
1386	player	2014	1	2014	\N	1.00	2026-09-06 22:42:06.816471+00
1387	player	2015	1	2015	\N	1.00	2026-09-06 22:42:06.816471+00
1388	player	2016	1	2016	\N	1.00	2026-09-06 22:42:06.816471+00
1389	player	2017	1	2017	\N	1.00	2026-09-06 22:42:06.816471+00
1390	player	2018	1	2018	\N	1.00	2026-09-06 22:42:06.816471+00
1391	player	2019	1	2019	\N	1.00	2026-09-06 22:42:06.816471+00
1392	player	2020	1	2020	\N	1.00	2026-09-06 22:42:06.816471+00
1393	player	2021	1	2021	\N	1.00	2026-09-06 22:42:06.816471+00
1394	player	2022	1	2022	\N	1.00	2026-09-06 22:42:06.816471+00
1395	player	2023	1	2023	\N	1.00	2026-09-06 22:42:06.816471+00
1396	player	2024	1	2024	\N	1.00	2026-09-06 22:42:06.816471+00
1397	player	2025	1	2025	\N	1.00	2026-09-06 22:42:06.816471+00
1398	player	2026	1	2026	\N	1.00	2026-09-06 22:42:06.816471+00
1399	player	2027	1	2027	\N	1.00	2026-09-06 22:42:06.816471+00
1400	player	2028	1	2028	\N	1.00	2026-09-06 22:42:06.816471+00
1401	player	2029	1	2029	\N	1.00	2026-09-06 22:42:06.816471+00
1402	player	2030	1	2030	\N	1.00	2026-09-06 22:42:06.816471+00
1403	player	2031	1	2031	\N	1.00	2026-09-06 22:42:06.816471+00
1404	player	2032	1	2032	\N	1.00	2026-09-06 22:42:06.816471+00
1405	player	2033	1	2033	\N	1.00	2026-09-06 22:42:06.816471+00
1406	player	2034	1	2034	\N	1.00	2026-09-06 22:42:06.816471+00
1407	player	2035	1	2035	\N	1.00	2026-09-06 22:42:06.816471+00
1408	player	2036	1	2036	\N	1.00	2026-09-06 22:42:06.816471+00
1409	player	2037	1	2037	\N	1.00	2026-09-06 22:42:06.816471+00
1410	player	2038	1	2038	\N	1.00	2026-09-06 22:42:06.816471+00
1411	player	2039	1	2039	\N	1.00	2026-09-06 22:42:06.816471+00
1412	player	2040	1	2040	\N	1.00	2026-09-06 22:42:06.816471+00
1413	player	2041	1	2041	\N	1.00	2026-09-06 22:42:06.816471+00
1414	player	2042	1	2042	\N	1.00	2026-09-06 22:42:06.816471+00
1415	player	2043	1	2043	\N	1.00	2026-09-06 22:42:06.816471+00
1416	player	2044	1	2044	\N	1.00	2026-09-06 22:42:06.816471+00
1417	player	2045	1	2045	\N	1.00	2026-09-06 22:42:06.816471+00
1418	player	2046	1	2046	\N	1.00	2026-09-06 22:42:06.816471+00
1419	player	2047	1	2047	\N	1.00	2026-09-06 22:42:06.816471+00
1420	player	2048	1	2048	\N	1.00	2026-09-06 22:42:06.816471+00
1421	player	2049	1	2049	\N	1.00	2026-09-06 22:42:06.816471+00
1422	player	2050	1	2050	\N	1.00	2026-09-06 22:42:06.816471+00
1423	player	2051	1	2051	\N	1.00	2026-09-06 22:42:06.816471+00
1424	player	2052	1	2052	\N	1.00	2026-09-06 22:42:06.816471+00
1425	player	2053	1	2053	\N	1.00	2026-09-06 22:42:06.816471+00
1426	player	2054	1	2054	\N	1.00	2026-09-06 22:42:06.816471+00
1427	player	2055	1	2055	\N	1.00	2026-09-06 22:42:06.816471+00
1428	player	2056	1	2056	\N	1.00	2026-09-06 22:42:06.816471+00
1429	player	2057	1	2057	\N	1.00	2026-09-06 22:42:06.816471+00
1430	player	2058	1	2058	\N	1.00	2026-09-06 22:42:06.816471+00
1431	player	2059	1	2059	\N	1.00	2026-09-06 22:42:06.816471+00
1432	player	2060	1	2060	\N	1.00	2026-09-06 22:42:06.816471+00
1433	player	2061	1	2061	\N	1.00	2026-09-06 22:42:06.816471+00
1434	player	2062	1	2062	\N	1.00	2026-09-06 22:42:06.816471+00
1435	player	2063	1	2063	\N	1.00	2026-09-06 22:42:06.816471+00
1436	player	2064	1	2064	\N	1.00	2026-09-06 22:42:06.816471+00
1437	player	2065	1	2065	\N	1.00	2026-09-06 22:42:06.816471+00
1438	player	2066	1	2066	\N	1.00	2026-09-06 22:42:06.816471+00
1439	player	2067	1	2067	\N	1.00	2026-09-06 22:42:06.816471+00
1440	player	2068	1	2068	\N	1.00	2026-09-06 22:42:06.816471+00
1441	player	2069	1	2069	\N	1.00	2026-09-06 22:42:06.816471+00
1442	player	2070	1	2070	\N	1.00	2026-09-06 22:42:06.816471+00
1443	player	2071	1	2071	\N	1.00	2026-09-06 22:42:06.816471+00
1444	player	2072	1	2072	\N	1.00	2026-09-06 22:42:06.816471+00
1445	player	2073	1	2073	\N	1.00	2026-09-06 22:42:06.816471+00
1446	player	2074	1	2074	\N	1.00	2026-09-06 22:42:06.816471+00
1447	player	2075	1	2075	\N	1.00	2026-09-06 22:42:06.816471+00
1448	player	2076	1	2076	\N	1.00	2026-09-06 22:42:06.816471+00
1449	player	2077	1	2077	\N	1.00	2026-09-06 22:42:06.816471+00
1450	player	2078	1	2078	\N	1.00	2026-09-06 22:42:06.816471+00
1451	player	2079	1	2079	\N	1.00	2026-09-06 22:42:06.816471+00
1452	player	2080	1	2080	\N	1.00	2026-09-06 22:42:06.816471+00
1453	player	2081	1	2081	\N	1.00	2026-09-06 22:42:06.816471+00
1454	player	2082	1	2082	\N	1.00	2026-09-06 22:42:06.816471+00
1455	player	2083	1	2083	\N	1.00	2026-09-06 22:42:06.816471+00
1456	player	2084	1	2084	\N	1.00	2026-09-06 22:42:06.816471+00
1457	player	2085	1	2085	\N	1.00	2026-09-06 22:42:06.816471+00
1458	player	2086	1	2086	\N	1.00	2026-09-06 22:42:06.816471+00
1459	player	2087	1	2087	\N	1.00	2026-09-06 22:42:06.816471+00
1460	player	2088	1	2088	\N	1.00	2026-09-06 22:42:06.816471+00
1461	player	2089	1	2089	\N	1.00	2026-09-06 22:42:06.816471+00
1462	player	2090	1	2090	\N	1.00	2026-09-06 22:42:06.816471+00
1463	player	2091	1	2091	\N	1.00	2026-09-06 22:42:06.816471+00
1464	player	2092	1	2092	\N	1.00	2026-09-06 22:42:06.816471+00
1465	player	2093	1	2093	\N	1.00	2026-09-06 22:42:06.816471+00
1466	player	2094	1	2094	\N	1.00	2026-09-06 22:42:06.816471+00
1467	player	2095	1	2095	\N	1.00	2026-09-06 22:42:06.816471+00
1468	player	2096	1	2096	\N	1.00	2026-09-06 22:42:06.816471+00
1469	player	2097	1	2097	\N	1.00	2026-09-06 22:42:06.816471+00
1470	player	2098	1	2098	\N	1.00	2026-09-06 22:42:06.816471+00
1471	player	2099	1	2099	\N	1.00	2026-09-06 22:42:06.816471+00
1472	player	2100	1	2100	\N	1.00	2026-09-06 22:42:06.816471+00
1473	player	2101	1	2101	\N	1.00	2026-09-06 22:42:06.816471+00
1474	player	2102	1	2102	\N	1.00	2026-09-06 22:42:06.816471+00
1475	player	2103	1	2103	\N	1.00	2026-09-06 22:42:06.816471+00
1476	player	2104	1	2104	\N	1.00	2026-09-06 22:42:06.816471+00
1477	player	2105	1	2105	\N	1.00	2026-09-06 22:42:06.816471+00
1478	player	2106	1	2106	\N	1.00	2026-09-06 22:42:06.816471+00
1479	player	2107	1	2107	\N	1.00	2026-09-06 22:42:06.816471+00
1480	player	2108	1	2108	\N	1.00	2026-09-06 22:42:06.816471+00
1481	player	2109	1	2109	\N	1.00	2026-09-06 22:42:06.816471+00
1482	player	2110	1	2110	\N	1.00	2026-09-06 22:42:06.816471+00
1483	player	2111	1	2111	\N	1.00	2026-09-06 22:42:06.816471+00
1484	player	2112	1	2112	\N	1.00	2026-09-06 22:42:06.816471+00
1485	player	2113	1	2113	\N	1.00	2026-09-06 22:42:06.816471+00
1486	player	2114	1	2114	\N	1.00	2026-09-06 22:42:06.816471+00
1487	player	2115	1	2115	\N	1.00	2026-09-06 22:42:06.816471+00
1488	player	2116	1	2116	\N	1.00	2026-09-06 22:42:06.816471+00
1489	player	2117	1	2117	\N	1.00	2026-09-06 22:42:06.816471+00
1490	player	2118	1	2118	\N	1.00	2026-09-06 22:42:06.816471+00
1491	player	2119	1	2119	\N	1.00	2026-09-06 22:42:06.816471+00
1492	player	2120	1	2120	\N	1.00	2026-09-06 22:42:06.816471+00
1493	player	2121	1	2121	\N	1.00	2026-09-06 22:42:06.816471+00
1494	player	2122	1	2122	\N	1.00	2026-09-06 22:42:06.816471+00
1495	player	2123	1	2123	\N	1.00	2026-09-06 22:42:06.816471+00
1496	player	2124	1	2124	\N	1.00	2026-09-06 22:42:06.816471+00
1497	player	2125	1	2125	\N	1.00	2026-09-06 22:42:06.816471+00
1498	player	2126	1	2126	\N	1.00	2026-09-06 22:42:06.816471+00
1499	player	2127	1	2127	\N	1.00	2026-09-06 22:42:06.816471+00
1500	player	2128	1	2128	\N	1.00	2026-09-06 22:42:06.816471+00
1501	player	2129	1	2129	\N	1.00	2026-09-06 22:42:06.816471+00
1502	player	2130	1	2130	\N	1.00	2026-09-06 22:42:06.816471+00
1503	player	2131	1	2131	\N	1.00	2026-09-06 22:42:06.816471+00
1504	player	2132	1	2132	\N	1.00	2026-09-06 22:42:06.816471+00
1505	player	2133	1	2133	\N	1.00	2026-09-06 22:42:06.816471+00
1506	player	2134	1	2134	\N	1.00	2026-09-06 22:42:06.816471+00
1507	player	2135	1	2135	\N	1.00	2026-09-06 22:42:06.816471+00
1508	player	2136	1	2136	\N	1.00	2026-09-06 22:42:06.816471+00
1509	player	2137	1	2137	\N	1.00	2026-09-06 22:42:06.816471+00
1510	player	2138	1	2138	\N	1.00	2026-09-06 22:42:06.816471+00
1511	player	2139	1	2139	\N	1.00	2026-09-06 22:42:06.816471+00
1512	player	2140	1	2140	\N	1.00	2026-09-06 22:42:06.816471+00
1513	player	2141	1	2141	\N	1.00	2026-09-06 22:42:06.816471+00
1514	player	2142	1	2142	\N	1.00	2026-09-06 22:42:06.816471+00
1515	player	2143	1	2143	\N	1.00	2026-09-06 22:42:06.816471+00
1516	player	2144	1	2144	\N	1.00	2026-09-06 22:42:06.816471+00
1517	player	2145	1	2145	\N	1.00	2026-09-06 22:42:06.816471+00
1518	player	2146	1	2146	\N	1.00	2026-09-06 22:42:06.816471+00
1519	player	2147	1	2147	\N	1.00	2026-09-06 22:42:06.816471+00
1520	player	2148	1	2148	\N	1.00	2026-09-06 22:42:06.816471+00
1521	player	2149	1	2149	\N	1.00	2026-09-06 22:42:06.816471+00
1522	player	2150	1	2150	\N	1.00	2026-09-06 22:42:06.816471+00
1523	player	2151	1	2151	\N	1.00	2026-09-06 22:42:06.816471+00
1524	player	2152	1	2152	\N	1.00	2026-09-06 22:42:06.816471+00
1525	player	2153	1	2153	\N	1.00	2026-09-06 22:42:06.816471+00
1526	player	2154	1	2154	\N	1.00	2026-09-06 22:42:06.816471+00
1527	player	2155	1	2155	\N	1.00	2026-09-06 22:42:06.816471+00
1528	player	2156	1	2156	\N	1.00	2026-09-06 22:42:06.816471+00
1529	player	2157	1	2157	\N	1.00	2026-09-06 22:42:06.816471+00
1530	player	2158	1	2158	\N	1.00	2026-09-06 22:42:06.816471+00
1531	player	2159	1	2159	\N	1.00	2026-09-06 22:42:06.816471+00
1532	player	2160	1	2160	\N	1.00	2026-09-06 22:42:06.816471+00
1533	player	2161	1	2161	\N	1.00	2026-09-06 22:42:06.816471+00
1534	player	2162	1	2162	\N	1.00	2026-09-06 22:42:06.816471+00
1535	player	2163	1	2163	\N	1.00	2026-09-06 22:42:06.816471+00
1536	player	2164	1	2164	\N	1.00	2026-09-06 22:42:06.816471+00
1537	player	2165	1	2165	\N	1.00	2026-09-06 22:42:06.816471+00
1538	player	2166	1	2166	\N	1.00	2026-09-06 22:42:06.816471+00
1539	player	2167	1	2167	\N	1.00	2026-09-06 22:42:06.816471+00
1540	player	2168	1	2168	\N	1.00	2026-09-06 22:42:06.816471+00
1541	player	2169	1	2169	\N	1.00	2026-09-06 22:42:06.816471+00
1542	player	2170	1	2170	\N	1.00	2026-09-06 22:42:06.816471+00
1543	player	2171	1	2171	\N	1.00	2026-09-06 22:42:06.816471+00
1544	player	2172	1	2172	\N	1.00	2026-09-06 22:42:06.816471+00
1545	player	2173	1	2173	\N	1.00	2026-09-06 22:42:06.816471+00
1546	player	2174	1	2174	\N	1.00	2026-09-06 22:42:06.816471+00
1547	player	2175	1	2175	\N	1.00	2026-09-06 22:42:06.816471+00
1548	player	2176	1	2176	\N	1.00	2026-09-06 22:42:06.816471+00
1549	player	2177	1	2177	\N	1.00	2026-09-06 22:42:06.816471+00
1550	player	2178	1	2178	\N	1.00	2026-09-06 22:42:06.816471+00
1551	player	2179	1	2179	\N	1.00	2026-09-06 22:42:06.816471+00
1552	player	2180	1	2180	\N	1.00	2026-09-06 22:42:06.816471+00
1553	player	2181	1	2181	\N	1.00	2026-09-06 22:42:06.816471+00
1554	player	2182	1	2182	\N	1.00	2026-09-06 22:42:06.816471+00
1555	player	2183	1	2183	\N	1.00	2026-09-06 22:42:06.816471+00
1556	player	2184	1	2184	\N	1.00	2026-09-06 22:42:06.816471+00
1557	player	2185	1	2185	\N	1.00	2026-09-06 22:42:06.816471+00
1558	player	2186	1	2186	\N	1.00	2026-09-06 22:42:06.816471+00
1559	player	2187	1	2187	\N	1.00	2026-09-06 22:42:06.816471+00
1560	player	2188	1	2188	\N	1.00	2026-09-06 22:42:06.816471+00
1561	player	2189	1	2189	\N	1.00	2026-09-06 22:42:06.816471+00
1562	player	2190	1	2190	\N	1.00	2026-09-06 22:42:06.816471+00
1563	player	2191	1	2191	\N	1.00	2026-09-06 22:42:06.816471+00
1564	player	2192	1	2192	\N	1.00	2026-09-06 22:42:06.816471+00
1565	player	2193	1	2193	\N	1.00	2026-09-06 22:42:06.816471+00
1566	player	2194	1	2194	\N	1.00	2026-09-06 22:42:06.816471+00
1567	player	2195	1	2195	\N	1.00	2026-09-06 22:42:06.816471+00
1568	player	2196	1	2196	\N	1.00	2026-09-06 22:42:06.816471+00
1569	player	2197	1	2197	\N	1.00	2026-09-06 22:42:06.816471+00
1570	player	2198	1	2198	\N	1.00	2026-09-06 22:42:06.816471+00
1571	player	2199	1	2199	\N	1.00	2026-09-06 22:42:06.816471+00
1572	player	2200	1	2200	\N	1.00	2026-09-06 22:42:06.816471+00
1573	player	2201	1	2201	\N	1.00	2026-09-06 22:42:06.816471+00
1574	player	2202	1	2202	\N	1.00	2026-09-06 22:42:06.816471+00
1575	player	2203	1	2203	\N	1.00	2026-09-06 22:42:06.816471+00
1576	player	2204	1	2204	\N	1.00	2026-09-06 22:42:06.816471+00
1577	player	2205	1	2205	\N	1.00	2026-09-06 22:42:06.816471+00
1578	player	2206	1	2206	\N	1.00	2026-09-06 22:42:06.816471+00
1579	player	2207	1	2207	\N	1.00	2026-09-06 22:42:06.816471+00
1580	player	2208	1	2208	\N	1.00	2026-09-06 22:42:06.816471+00
1581	player	2209	1	2209	\N	1.00	2026-09-06 22:42:06.816471+00
1582	player	2210	1	2210	\N	1.00	2026-09-06 22:42:06.816471+00
1583	player	2211	1	2211	\N	1.00	2026-09-06 22:42:06.816471+00
1584	player	2212	1	2212	\N	1.00	2026-09-06 22:42:06.816471+00
1585	player	2213	1	2213	\N	1.00	2026-09-06 22:42:06.816471+00
1586	player	2214	1	2214	\N	1.00	2026-09-06 22:42:06.816471+00
1587	player	2215	1	2215	\N	1.00	2026-09-06 22:42:06.816471+00
1588	player	2216	1	2216	\N	1.00	2026-09-06 22:42:06.816471+00
1589	player	2217	1	2217	\N	1.00	2026-09-06 22:42:06.816471+00
1590	player	2218	1	2218	\N	1.00	2026-09-06 22:42:06.816471+00
1591	player	2219	1	2219	\N	1.00	2026-09-06 22:42:06.816471+00
1592	player	2220	1	2220	\N	1.00	2026-09-06 22:42:06.816471+00
1593	player	2221	1	2221	\N	1.00	2026-09-06 22:42:06.816471+00
1594	player	2222	1	2222	\N	1.00	2026-09-06 22:42:06.816471+00
1595	player	2223	1	2223	\N	1.00	2026-09-06 22:42:06.816471+00
1596	player	2224	1	2224	\N	1.00	2026-09-06 22:42:06.816471+00
1597	player	2225	1	2225	\N	1.00	2026-09-06 22:42:06.816471+00
1598	player	2226	1	2226	\N	1.00	2026-09-06 22:42:06.816471+00
1599	player	2227	1	2227	\N	1.00	2026-09-06 22:42:06.816471+00
1600	player	2228	1	2228	\N	1.00	2026-09-06 22:42:06.816471+00
1601	player	2229	1	2229	\N	1.00	2026-09-06 22:42:06.816471+00
1602	player	2230	1	2230	\N	1.00	2026-09-06 22:42:06.816471+00
1603	player	2231	1	2231	\N	1.00	2026-09-06 22:42:06.816471+00
1604	player	2232	1	2232	\N	1.00	2026-09-06 22:42:06.816471+00
1605	player	2233	1	2233	\N	1.00	2026-09-06 22:42:06.816471+00
1606	player	2234	1	2234	\N	1.00	2026-09-06 22:42:06.816471+00
1607	player	2235	1	2235	\N	1.00	2026-09-06 22:42:06.816471+00
1608	player	2236	1	2236	\N	1.00	2026-09-06 22:42:06.816471+00
1609	player	2237	1	2237	\N	1.00	2026-09-06 22:42:06.816471+00
1610	player	2238	1	2238	\N	1.00	2026-09-06 22:42:06.816471+00
1611	player	2239	1	2239	\N	1.00	2026-09-06 22:42:06.816471+00
1612	player	2240	1	2240	\N	1.00	2026-09-06 22:42:06.816471+00
1613	player	2241	1	2241	\N	1.00	2026-09-06 22:42:06.816471+00
1614	player	2242	1	2242	\N	1.00	2026-09-06 22:42:06.816471+00
1615	player	2243	1	2243	\N	1.00	2026-09-06 22:42:06.816471+00
1616	player	2244	1	2244	\N	1.00	2026-09-06 22:42:06.816471+00
1617	player	2245	1	2245	\N	1.00	2026-09-06 22:42:06.816471+00
1618	player	2246	1	2246	\N	1.00	2026-09-06 22:42:06.816471+00
1619	player	2247	1	2247	\N	1.00	2026-09-06 22:42:06.816471+00
1620	player	2248	1	2248	\N	1.00	2026-09-06 22:42:06.816471+00
1621	player	2249	1	2249	\N	1.00	2026-09-06 22:42:06.816471+00
1622	player	2250	1	2250	\N	1.00	2026-09-06 22:42:06.816471+00
1623	player	2251	1	2251	\N	1.00	2026-09-06 22:42:06.816471+00
1624	player	2252	1	2252	\N	1.00	2026-09-06 22:42:06.816471+00
1625	player	2253	1	2253	\N	1.00	2026-09-06 22:42:06.816471+00
1626	player	2254	1	2254	\N	1.00	2026-09-06 22:42:06.816471+00
1627	player	2255	1	2255	\N	1.00	2026-09-06 22:42:06.816471+00
1628	player	2256	1	2256	\N	1.00	2026-09-06 22:42:06.816471+00
1629	player	2257	1	2257	\N	1.00	2026-09-06 22:42:06.816471+00
1630	player	2258	1	2258	\N	1.00	2026-09-06 22:42:06.816471+00
1631	player	2259	1	2259	\N	1.00	2026-09-06 22:42:06.816471+00
1632	player	2260	1	2260	\N	1.00	2026-09-06 22:42:06.816471+00
1633	player	2261	1	2261	\N	1.00	2026-09-06 22:42:06.816471+00
1634	player	2262	1	2262	\N	1.00	2026-09-06 22:42:06.816471+00
1635	player	2263	1	2263	\N	1.00	2026-09-06 22:42:06.816471+00
1636	player	2264	1	2264	\N	1.00	2026-09-06 22:42:06.816471+00
1637	player	2265	1	2265	\N	1.00	2026-09-06 22:42:06.816471+00
1638	player	2266	1	2266	\N	1.00	2026-09-06 22:42:06.816471+00
1639	player	2267	1	2267	\N	1.00	2026-09-06 22:42:06.816471+00
1640	player	2268	1	2268	\N	1.00	2026-09-06 22:42:06.816471+00
1641	player	2269	1	2269	\N	1.00	2026-09-06 22:42:06.816471+00
1642	player	2270	1	2270	\N	1.00	2026-09-06 22:42:06.816471+00
1643	player	2271	1	2271	\N	1.00	2026-09-06 22:42:06.816471+00
1644	player	2272	1	2272	\N	1.00	2026-09-06 22:42:06.816471+00
1645	player	2273	1	2273	\N	1.00	2026-09-06 22:42:06.816471+00
1646	player	2274	1	2274	\N	1.00	2026-09-06 22:42:06.816471+00
1647	player	2275	1	2275	\N	1.00	2026-09-06 22:42:06.816471+00
1648	player	2276	1	2276	\N	1.00	2026-09-06 22:42:06.816471+00
1649	player	2277	1	2277	\N	1.00	2026-09-06 22:42:06.816471+00
1650	player	2278	1	2278	\N	1.00	2026-09-06 22:42:06.816471+00
1651	player	2279	1	2279	\N	1.00	2026-09-06 22:42:06.816471+00
1652	player	2280	1	2280	\N	1.00	2026-09-06 22:42:06.816471+00
1653	player	2281	1	2281	\N	1.00	2026-09-06 22:42:06.816471+00
1654	player	2284	1	2284	\N	1.00	2026-09-06 22:42:06.816471+00
1655	player	2285	1	2285	\N	1.00	2026-09-06 22:42:06.816471+00
1656	player	2286	1	2286	\N	1.00	2026-09-06 22:42:06.816471+00
1657	player	2287	1	2287	\N	1.00	2026-09-06 22:42:06.816471+00
1658	player	2288	1	2288	\N	1.00	2026-09-06 22:42:06.816471+00
1659	player	2289	1	2289	\N	1.00	2026-09-06 22:42:06.816471+00
1660	player	2290	1	2290	\N	1.00	2026-09-06 22:42:06.816471+00
1661	player	2291	1	2291	\N	1.00	2026-09-06 22:42:06.816471+00
1662	player	2292	1	2292	\N	1.00	2026-09-06 22:42:06.816471+00
1663	player	2293	1	2293	\N	1.00	2026-09-06 22:42:06.816471+00
1664	player	2294	1	2294	\N	1.00	2026-09-06 22:42:06.816471+00
1665	player	2295	1	2295	\N	1.00	2026-09-06 22:42:06.816471+00
1666	player	2296	1	2296	\N	1.00	2026-09-06 22:42:06.816471+00
1667	player	2297	1	2297	\N	1.00	2026-09-06 22:42:06.816471+00
1668	player	2298	1	2298	\N	1.00	2026-09-06 22:42:06.816471+00
1669	player	2299	1	2299	\N	1.00	2026-09-06 22:42:06.816471+00
1670	player	2300	1	2300	\N	1.00	2026-09-06 22:42:06.816471+00
1671	player	2301	1	2301	\N	1.00	2026-09-06 22:42:06.816471+00
1672	player	2302	1	2302	\N	1.00	2026-09-06 22:42:06.816471+00
1673	player	2303	1	2303	\N	1.00	2026-09-06 22:42:06.816471+00
1674	player	2304	1	2304	\N	1.00	2026-09-06 22:42:06.816471+00
1675	player	2305	1	2305	\N	1.00	2026-09-06 22:42:06.816471+00
1676	player	2306	1	2306	\N	1.00	2026-09-06 22:42:06.816471+00
1677	player	2307	1	2307	\N	1.00	2026-09-06 22:42:06.816471+00
1678	player	2308	1	2308	\N	1.00	2026-09-06 22:42:06.816471+00
1679	player	2309	1	2309	\N	1.00	2026-09-06 22:42:06.816471+00
1680	player	2310	1	2310	\N	1.00	2026-09-06 22:42:06.816471+00
1681	player	2311	1	2311	\N	1.00	2026-09-06 22:42:06.816471+00
1682	player	2312	1	2312	\N	1.00	2026-09-06 22:42:06.816471+00
1683	player	2313	1	2313	\N	1.00	2026-09-06 22:42:06.816471+00
1684	player	2314	1	2314	\N	1.00	2026-09-06 22:42:06.816471+00
1685	player	2315	1	2315	\N	1.00	2026-09-06 22:42:06.816471+00
1686	player	2316	1	2316	\N	1.00	2026-09-06 22:42:06.816471+00
1687	player	2317	1	2317	\N	1.00	2026-09-06 22:42:06.816471+00
1688	player	2318	1	2318	\N	1.00	2026-09-06 22:42:06.816471+00
1689	player	2319	1	2319	\N	1.00	2026-09-06 22:42:06.816471+00
1690	player	2320	1	2320	\N	1.00	2026-09-06 22:42:06.816471+00
1691	player	2321	1	2321	\N	1.00	2026-09-06 22:42:06.816471+00
1692	player	2322	1	2322	\N	1.00	2026-09-06 22:42:06.816471+00
1693	player	2323	1	2323	\N	1.00	2026-09-06 22:42:06.816471+00
1694	player	2324	1	2324	\N	1.00	2026-09-06 22:42:06.816471+00
1695	player	2325	1	2325	\N	1.00	2026-09-06 22:42:06.816471+00
1696	player	2326	1	2326	\N	1.00	2026-09-06 22:42:06.816471+00
1697	player	2327	1	2327	\N	1.00	2026-09-06 22:42:06.816471+00
1698	player	2328	1	2328	\N	1.00	2026-09-06 22:42:06.816471+00
1699	player	2329	1	2329	\N	1.00	2026-09-06 22:42:06.816471+00
1700	player	2330	1	2330	\N	1.00	2026-09-06 22:42:06.816471+00
1701	player	2331	1	2331	\N	1.00	2026-09-06 22:42:06.816471+00
1702	player	2332	1	2332	\N	1.00	2026-09-06 22:42:06.816471+00
1703	player	2333	1	2333	\N	1.00	2026-09-06 22:42:06.816471+00
1704	player	2334	1	2334	\N	1.00	2026-09-06 22:42:06.816471+00
1705	player	2335	1	2335	\N	1.00	2026-09-06 22:42:06.816471+00
1706	player	2336	1	2336	\N	1.00	2026-09-06 22:42:06.816471+00
1707	player	2337	1	2337	\N	1.00	2026-09-06 22:42:06.816471+00
1708	player	2338	1	2338	\N	1.00	2026-09-06 22:42:06.816471+00
1709	player	2339	1	2339	\N	1.00	2026-09-06 22:42:06.816471+00
1710	player	2340	1	2340	\N	1.00	2026-09-06 22:42:06.816471+00
1711	player	2341	1	2341	\N	1.00	2026-09-06 22:42:06.816471+00
1712	player	2342	1	2342	\N	1.00	2026-09-06 22:42:06.816471+00
1713	player	2343	1	2343	\N	1.00	2026-09-06 22:42:06.816471+00
1714	player	2344	1	2344	\N	1.00	2026-09-06 22:42:06.816471+00
1715	player	2345	1	2345	\N	1.00	2026-09-06 22:42:06.816471+00
1716	player	2346	1	2346	\N	1.00	2026-09-06 22:42:06.816471+00
1717	player	2347	1	2347	\N	1.00	2026-09-06 22:42:06.816471+00
1718	player	2348	1	2348	\N	1.00	2026-09-06 22:42:06.816471+00
1719	player	2349	1	2349	\N	1.00	2026-09-06 22:42:06.816471+00
1720	player	2350	1	2350	\N	1.00	2026-09-06 22:42:06.816471+00
1721	player	2351	1	2351	\N	1.00	2026-09-06 22:42:06.816471+00
1722	player	2352	1	2352	\N	1.00	2026-09-06 22:42:06.816471+00
1723	player	2353	1	2353	\N	1.00	2026-09-06 22:42:06.816471+00
1724	player	2354	1	2354	\N	1.00	2026-09-06 22:42:06.816471+00
1725	player	2355	1	2355	\N	1.00	2026-09-06 22:42:06.816471+00
1726	player	2356	1	2356	\N	1.00	2026-09-06 22:42:06.816471+00
1727	player	2357	1	2357	\N	1.00	2026-09-06 22:42:06.816471+00
1728	player	2358	1	2358	\N	1.00	2026-09-06 22:42:06.816471+00
1729	player	2359	1	2359	\N	1.00	2026-09-06 22:42:06.816471+00
1730	player	2360	1	2360	\N	1.00	2026-09-06 22:42:06.816471+00
1731	player	2361	1	2361	\N	1.00	2026-09-06 22:42:06.816471+00
1732	player	2362	1	2362	\N	1.00	2026-09-06 22:42:06.816471+00
1733	player	2363	1	2363	\N	1.00	2026-09-06 22:42:06.816471+00
1734	player	2364	1	2364	\N	1.00	2026-09-06 22:42:06.816471+00
1735	player	2365	1	2365	\N	1.00	2026-09-06 22:42:06.816471+00
1736	player	2366	1	2366	\N	1.00	2026-09-06 22:42:06.816471+00
1737	player	2367	1	2367	\N	1.00	2026-09-06 22:42:06.816471+00
1738	player	2368	1	2368	\N	1.00	2026-09-06 22:42:06.816471+00
1739	player	2369	1	2369	\N	1.00	2026-09-06 22:42:06.816471+00
1740	player	2370	1	2370	\N	1.00	2026-09-06 22:42:06.816471+00
1741	player	2371	1	2371	\N	1.00	2026-09-06 22:42:06.816471+00
1742	player	2372	1	2372	\N	1.00	2026-09-06 22:42:06.816471+00
1743	player	2373	1	2373	\N	1.00	2026-09-06 22:42:06.816471+00
1744	player	2374	1	2374	\N	1.00	2026-09-06 22:42:06.816471+00
1745	player	2375	1	2375	\N	1.00	2026-09-06 22:42:06.816471+00
1746	player	2376	1	2376	\N	1.00	2026-09-06 22:42:06.816471+00
1747	player	2377	1	2377	\N	1.00	2026-09-06 22:42:06.816471+00
1748	player	2378	1	2378	\N	1.00	2026-09-06 22:42:06.816471+00
1749	player	2379	1	2379	\N	1.00	2026-09-06 22:42:06.816471+00
1750	player	2380	1	2380	\N	1.00	2026-09-06 22:42:06.816471+00
1751	player	2381	1	2381	\N	1.00	2026-09-06 22:42:06.816471+00
1752	player	2382	1	2382	\N	1.00	2026-09-06 22:42:06.816471+00
1753	player	2383	1	2383	\N	1.00	2026-09-06 22:42:06.816471+00
1754	player	2384	1	2384	\N	1.00	2026-09-06 22:42:06.816471+00
1755	player	2385	1	2385	\N	1.00	2026-09-06 22:42:06.816471+00
1756	player	2386	1	2386	\N	1.00	2026-09-06 22:42:06.816471+00
1757	player	2387	1	2387	\N	1.00	2026-09-06 22:42:06.816471+00
1758	player	2388	1	2388	\N	1.00	2026-09-06 22:42:06.816471+00
1759	player	2389	1	2389	\N	1.00	2026-09-06 22:42:06.816471+00
1760	player	2390	1	2390	\N	1.00	2026-09-06 22:42:06.816471+00
1761	player	2391	1	2391	\N	1.00	2026-09-06 22:42:06.816471+00
1762	player	2392	1	2392	\N	1.00	2026-09-06 22:42:06.816471+00
1763	player	2393	1	2393	\N	1.00	2026-09-06 22:42:06.816471+00
1764	player	2394	1	2394	\N	1.00	2026-09-06 22:42:06.816471+00
1765	player	2395	1	2395	\N	1.00	2026-09-06 22:42:06.816471+00
1766	player	2396	1	2396	\N	1.00	2026-09-06 22:42:06.816471+00
1767	player	2397	1	2397	\N	1.00	2026-09-06 22:42:06.816471+00
1768	player	2398	1	2398	\N	1.00	2026-09-06 22:42:06.816471+00
1769	player	2399	1	2399	\N	1.00	2026-09-06 22:42:06.816471+00
1770	player	2400	1	2400	\N	1.00	2026-09-06 22:42:06.816471+00
1771	player	2401	1	2401	\N	1.00	2026-09-06 22:42:06.816471+00
1772	player	2402	1	2402	\N	1.00	2026-09-06 22:42:06.816471+00
1773	player	2403	1	2403	\N	1.00	2026-09-06 22:42:06.816471+00
1774	player	2404	1	2404	\N	1.00	2026-09-06 22:42:06.816471+00
1775	player	2405	1	2405	\N	1.00	2026-09-06 22:42:06.816471+00
1776	player	2406	1	2406	\N	1.00	2026-09-06 22:42:06.816471+00
1777	player	2407	1	2407	\N	1.00	2026-09-06 22:42:06.816471+00
1778	player	2408	1	2408	\N	1.00	2026-09-06 22:42:06.816471+00
1779	player	2409	1	2409	\N	1.00	2026-09-06 22:42:06.816471+00
1780	player	2410	1	2410	\N	1.00	2026-09-06 22:42:06.816471+00
1781	player	2411	1	2411	\N	1.00	2026-09-06 22:42:06.816471+00
1782	player	2412	1	2412	\N	1.00	2026-09-06 22:42:06.816471+00
1783	player	2413	1	2413	\N	1.00	2026-09-06 22:42:06.816471+00
1784	player	2414	1	2414	\N	1.00	2026-09-06 22:42:06.816471+00
1785	player	2415	1	2415	\N	1.00	2026-09-06 22:42:06.816471+00
1786	player	2416	1	2416	\N	1.00	2026-09-06 22:42:06.816471+00
1787	player	2417	1	2417	\N	1.00	2026-09-06 22:42:06.816471+00
1788	player	2418	1	2418	\N	1.00	2026-09-06 22:42:06.816471+00
1789	player	2419	1	2419	\N	1.00	2026-09-06 22:42:06.816471+00
1790	player	2420	1	2420	\N	1.00	2026-09-06 22:42:06.816471+00
1791	player	2421	1	2421	\N	1.00	2026-09-06 22:42:06.816471+00
1792	player	2422	1	2422	\N	1.00	2026-09-06 22:42:06.816471+00
1793	player	2423	1	2423	\N	1.00	2026-09-06 22:42:06.816471+00
1794	player	2424	1	2424	\N	1.00	2026-09-06 22:42:06.816471+00
1795	player	2425	1	2425	\N	1.00	2026-09-06 22:42:06.816471+00
1796	player	2426	1	2426	\N	1.00	2026-09-06 22:42:06.816471+00
1797	player	2427	1	2427	\N	1.00	2026-09-06 22:42:06.816471+00
1798	player	2428	1	2428	\N	1.00	2026-09-06 22:42:06.816471+00
1799	player	2429	1	2429	\N	1.00	2026-09-06 22:42:06.816471+00
1800	player	2430	1	2430	\N	1.00	2026-09-06 22:42:06.816471+00
1801	player	2431	1	2431	\N	1.00	2026-09-06 22:42:06.816471+00
1802	player	2432	1	2432	\N	1.00	2026-09-06 22:42:06.816471+00
1803	player	2433	1	2433	\N	1.00	2026-09-06 22:42:06.816471+00
1804	player	2434	1	2434	\N	1.00	2026-09-06 22:42:06.816471+00
1805	player	2435	1	2435	\N	1.00	2026-09-06 22:42:06.816471+00
1806	player	2436	1	2436	\N	1.00	2026-09-06 22:42:06.816471+00
1807	player	2437	1	2437	\N	1.00	2026-09-06 22:42:06.816471+00
1808	player	2438	1	2438	\N	1.00	2026-09-06 22:42:06.816471+00
1809	player	2439	1	2439	\N	1.00	2026-09-06 22:42:06.816471+00
1810	player	2440	1	2440	\N	1.00	2026-09-06 22:42:06.816471+00
1811	player	2441	1	2441	\N	1.00	2026-09-06 22:42:06.816471+00
1812	player	2442	1	2442	\N	1.00	2026-09-06 22:42:06.816471+00
1813	player	2443	1	2443	\N	1.00	2026-09-06 22:42:06.816471+00
1814	player	2444	1	2444	\N	1.00	2026-09-06 22:42:06.816471+00
1815	player	2445	1	2445	\N	1.00	2026-09-06 22:42:06.816471+00
1816	player	2446	1	2446	\N	1.00	2026-09-06 22:42:06.816471+00
1817	player	2447	1	2447	\N	1.00	2026-09-06 22:42:06.816471+00
1818	player	2448	1	2448	\N	1.00	2026-09-06 22:42:06.816471+00
1819	player	2449	1	2449	\N	1.00	2026-09-06 22:42:06.816471+00
1820	player	2450	1	2450	\N	1.00	2026-09-06 22:42:06.816471+00
1821	player	2451	1	2451	\N	1.00	2026-09-06 22:42:06.816471+00
1822	player	2452	1	2452	\N	1.00	2026-09-06 22:42:06.816471+00
1823	player	2453	1	2453	\N	1.00	2026-09-06 22:42:06.816471+00
1824	player	2454	1	2454	\N	1.00	2026-09-06 22:42:06.816471+00
1825	player	2455	1	2455	\N	1.00	2026-09-06 22:42:06.816471+00
1826	player	2456	1	2456	\N	1.00	2026-09-06 22:42:06.816471+00
1827	player	2457	1	2457	\N	1.00	2026-09-06 22:42:06.816471+00
1828	player	2458	1	2458	\N	1.00	2026-09-06 22:42:06.816471+00
1829	player	2459	1	2459	\N	1.00	2026-09-06 22:42:06.816471+00
1830	player	2460	1	2460	\N	1.00	2026-09-06 22:42:06.816471+00
1831	player	2461	1	2461	\N	1.00	2026-09-06 22:42:06.816471+00
1832	player	2462	1	2462	\N	1.00	2026-09-06 22:42:06.816471+00
1833	player	2463	1	2463	\N	1.00	2026-09-06 22:42:06.816471+00
1834	player	2464	1	2464	\N	1.00	2026-09-06 22:42:06.816471+00
1835	player	2465	1	2465	\N	1.00	2026-09-06 22:42:06.816471+00
1836	player	2466	1	2466	\N	1.00	2026-09-06 22:42:06.816471+00
1837	player	2467	1	2467	\N	1.00	2026-09-06 22:42:06.816471+00
1838	player	2468	1	2468	\N	1.00	2026-09-06 22:42:06.816471+00
1839	player	2469	1	2469	\N	1.00	2026-09-06 22:42:06.816471+00
1840	player	2470	1	2470	\N	1.00	2026-09-06 22:42:06.816471+00
1841	player	2471	1	2471	\N	1.00	2026-09-06 22:42:06.816471+00
1842	player	2472	1	2472	\N	1.00	2026-09-06 22:42:06.816471+00
1843	player	2473	1	2473	\N	1.00	2026-09-06 22:42:06.816471+00
1844	player	2474	1	2474	\N	1.00	2026-09-06 22:42:06.816471+00
1845	player	2475	1	2475	\N	1.00	2026-09-06 22:42:06.816471+00
1846	player	2476	1	2476	\N	1.00	2026-09-06 22:42:06.816471+00
1847	player	2477	1	2477	\N	1.00	2026-09-06 22:42:06.816471+00
1848	player	2478	1	2478	\N	1.00	2026-09-06 22:42:06.816471+00
1849	player	2479	1	2479	\N	1.00	2026-09-06 22:42:06.816471+00
1850	player	2480	1	2480	\N	1.00	2026-09-06 22:42:06.816471+00
1851	player	2481	1	2481	\N	1.00	2026-09-06 22:42:06.816471+00
1852	player	2482	1	2482	\N	1.00	2026-09-06 22:42:06.816471+00
1853	player	2483	1	2483	\N	1.00	2026-09-06 22:42:06.816471+00
1854	player	2484	1	2484	\N	1.00	2026-09-06 22:42:06.816471+00
1855	player	2485	1	2485	\N	1.00	2026-09-06 22:42:06.816471+00
1856	player	2486	1	2486	\N	1.00	2026-09-06 22:42:06.816471+00
1857	player	2487	1	2487	\N	1.00	2026-09-06 22:42:06.816471+00
1858	player	2488	1	2488	\N	1.00	2026-09-06 22:42:06.816471+00
1859	player	2489	1	2489	\N	1.00	2026-09-06 22:42:06.816471+00
1860	player	2490	1	2490	\N	1.00	2026-09-06 22:42:06.816471+00
1861	player	2491	1	2491	\N	1.00	2026-09-06 22:42:06.816471+00
1862	player	2492	1	2492	\N	1.00	2026-09-06 22:42:06.816471+00
1863	player	2493	1	2493	\N	1.00	2026-09-06 22:42:06.816471+00
1864	player	2494	1	2494	\N	1.00	2026-09-06 22:42:06.816471+00
1865	player	2495	1	2495	\N	1.00	2026-09-06 22:42:06.816471+00
1866	player	2496	1	2496	\N	1.00	2026-09-06 22:42:06.816471+00
1867	player	2497	1	2497	\N	1.00	2026-09-06 22:42:06.816471+00
1868	player	2498	1	2498	\N	1.00	2026-09-06 22:42:06.816471+00
1869	player	2499	1	2499	\N	1.00	2026-09-06 22:42:06.816471+00
1870	player	2500	1	2500	\N	1.00	2026-09-06 22:42:06.816471+00
1871	player	2501	1	2501	\N	1.00	2026-09-06 22:42:06.816471+00
1872	player	2502	1	2502	\N	1.00	2026-09-06 22:42:06.816471+00
1873	player	2503	1	2503	\N	1.00	2026-09-06 22:42:06.816471+00
1874	player	2504	1	2504	\N	1.00	2026-09-06 22:42:06.816471+00
1875	player	2505	1	2505	\N	1.00	2026-09-06 22:42:06.816471+00
1876	player	2506	1	2506	\N	1.00	2026-09-06 22:42:06.816471+00
1877	player	2507	1	2507	\N	1.00	2026-09-06 22:42:06.816471+00
1878	player	2508	1	2508	\N	1.00	2026-09-06 22:42:06.816471+00
1879	player	2509	1	2509	\N	1.00	2026-09-06 22:42:06.816471+00
1880	player	2510	1	2510	\N	1.00	2026-09-06 22:42:06.816471+00
1881	player	2511	1	2511	\N	1.00	2026-09-06 22:42:06.816471+00
1882	player	2512	1	2512	\N	1.00	2026-09-06 22:42:06.816471+00
1883	player	2513	1	2513	\N	1.00	2026-09-06 22:42:06.816471+00
1884	player	2514	1	2514	\N	1.00	2026-09-06 22:42:06.816471+00
1885	player	2515	1	2515	\N	1.00	2026-09-06 22:42:06.816471+00
1886	player	2516	1	2516	\N	1.00	2026-09-06 22:42:06.816471+00
1887	player	2517	1	2517	\N	1.00	2026-09-06 22:42:06.816471+00
1888	player	2518	1	2518	\N	1.00	2026-09-06 22:42:06.816471+00
1889	player	2519	1	2519	\N	1.00	2026-09-06 22:42:06.816471+00
1890	player	2520	1	2520	\N	1.00	2026-09-06 22:42:06.816471+00
1891	player	2521	1	2521	\N	1.00	2026-09-06 22:42:06.816471+00
1892	player	2522	1	2522	\N	1.00	2026-09-06 22:42:06.816471+00
1893	player	2523	1	2523	\N	1.00	2026-09-06 22:42:06.816471+00
1894	player	2524	1	2524	\N	1.00	2026-09-06 22:42:06.816471+00
1895	player	2525	1	2525	\N	1.00	2026-09-06 22:42:06.816471+00
1896	player	2526	1	2526	\N	1.00	2026-09-06 22:42:06.816471+00
1897	player	2527	1	2527	\N	1.00	2026-09-06 22:42:06.816471+00
1898	player	2528	1	2528	\N	1.00	2026-09-06 22:42:06.816471+00
1899	player	2529	1	2529	\N	1.00	2026-09-06 22:42:06.816471+00
1900	player	2530	1	2530	\N	1.00	2026-09-06 22:42:06.816471+00
1901	player	2531	1	2531	\N	1.00	2026-09-06 22:42:06.816471+00
1902	player	2532	1	2532	\N	1.00	2026-09-06 22:42:06.816471+00
1903	player	2533	1	2533	\N	1.00	2026-09-06 22:42:06.816471+00
1904	player	2534	1	2534	\N	1.00	2026-09-06 22:42:06.816471+00
1905	player	2535	1	2535	\N	1.00	2026-09-06 22:42:06.816471+00
1906	player	2536	1	2536	\N	1.00	2026-09-06 22:42:06.816471+00
1907	player	2537	1	2537	\N	1.00	2026-09-06 22:42:06.816471+00
1908	player	2538	1	2538	\N	1.00	2026-09-06 22:42:06.816471+00
1909	player	2539	1	2539	\N	1.00	2026-09-06 22:42:06.816471+00
1910	player	2540	1	2540	\N	1.00	2026-09-06 22:42:06.816471+00
1911	player	2541	1	2541	\N	1.00	2026-09-06 22:42:06.816471+00
1912	player	2542	1	2542	\N	1.00	2026-09-06 22:42:06.816471+00
1913	player	2543	1	2543	\N	1.00	2026-09-06 22:42:06.816471+00
1914	player	2544	1	2544	\N	1.00	2026-09-06 22:42:06.816471+00
1915	player	2545	1	2545	\N	1.00	2026-09-06 22:42:06.816471+00
1916	player	2546	1	2546	\N	1.00	2026-09-06 22:42:06.816471+00
1917	player	2547	1	2547	\N	1.00	2026-09-06 22:42:06.816471+00
1918	player	2548	1	2548	\N	1.00	2026-09-06 22:42:06.816471+00
1919	player	2549	1	2549	\N	1.00	2026-09-06 22:42:06.816471+00
1920	player	2550	1	2550	\N	1.00	2026-09-06 22:42:06.816471+00
1921	player	2551	1	2551	\N	1.00	2026-09-06 22:42:06.816471+00
1922	player	2552	1	2552	\N	1.00	2026-09-06 22:42:06.816471+00
1923	player	2553	1	2553	\N	1.00	2026-09-06 22:42:06.816471+00
1924	player	2554	1	2554	\N	1.00	2026-09-06 22:42:06.816471+00
1925	player	2555	1	2555	\N	1.00	2026-09-06 22:42:06.816471+00
1926	player	2556	1	2556	\N	1.00	2026-09-06 22:42:06.816471+00
1927	player	2557	1	2557	\N	1.00	2026-09-06 22:42:06.816471+00
1928	player	2558	1	2558	\N	1.00	2026-09-06 22:42:06.816471+00
1929	player	2559	1	2559	\N	1.00	2026-09-06 22:42:06.816471+00
1930	player	2560	1	2560	\N	1.00	2026-09-06 22:42:06.816471+00
1931	player	2561	1	2561	\N	1.00	2026-09-06 22:42:06.816471+00
1932	player	2562	1	2562	\N	1.00	2026-09-06 22:42:06.816471+00
1933	player	2563	1	2563	\N	1.00	2026-09-06 22:42:06.816471+00
1934	player	2564	1	2564	\N	1.00	2026-09-06 22:42:06.816471+00
1935	player	2565	1	2565	\N	1.00	2026-09-06 22:42:06.816471+00
1936	player	2566	1	2566	\N	1.00	2026-09-06 22:42:06.816471+00
1937	player	2567	1	2567	\N	1.00	2026-09-06 22:42:06.816471+00
1938	player	2568	1	2568	\N	1.00	2026-09-06 22:42:06.816471+00
1939	player	2569	1	2569	\N	1.00	2026-09-06 22:42:06.816471+00
1940	player	2570	1	2570	\N	1.00	2026-09-06 22:42:06.816471+00
1941	player	2571	1	2571	\N	1.00	2026-09-06 22:42:06.816471+00
1942	player	2572	1	2572	\N	1.00	2026-09-06 22:42:06.816471+00
1943	player	2573	1	2573	\N	1.00	2026-09-06 22:42:06.816471+00
1944	player	2574	1	2574	\N	1.00	2026-09-06 22:42:06.816471+00
1945	player	2575	1	2575	\N	1.00	2026-09-06 22:42:06.816471+00
1946	player	2576	1	2576	\N	1.00	2026-09-06 22:42:06.816471+00
1947	player	2577	1	2577	\N	1.00	2026-09-06 22:42:06.816471+00
1948	player	2578	1	2578	\N	1.00	2026-09-06 22:42:06.816471+00
1949	player	2579	1	2579	\N	1.00	2026-09-06 22:42:06.816471+00
1950	player	2580	1	2580	\N	1.00	2026-09-06 22:42:06.816471+00
1951	player	2581	1	2581	\N	1.00	2026-09-06 22:42:06.816471+00
1952	player	2582	1	2582	\N	1.00	2026-09-06 22:42:06.816471+00
1953	player	2583	1	2583	\N	1.00	2026-09-06 22:42:06.816471+00
1954	player	2584	1	2584	\N	1.00	2026-09-06 22:42:06.816471+00
1955	player	2585	1	2585	\N	1.00	2026-09-06 22:42:06.816471+00
1956	player	2586	1	2586	\N	1.00	2026-09-06 22:42:06.816471+00
1957	player	2587	1	2587	\N	1.00	2026-09-06 22:42:06.816471+00
1958	player	2588	1	2588	\N	1.00	2026-09-06 22:42:06.816471+00
1959	player	2589	1	2589	\N	1.00	2026-09-06 22:42:06.816471+00
1960	player	2590	1	2590	\N	1.00	2026-09-06 22:42:06.816471+00
1961	player	2591	1	2591	\N	1.00	2026-09-06 22:42:06.816471+00
1962	player	2592	1	2592	\N	1.00	2026-09-06 22:42:06.816471+00
1963	player	2593	1	2593	\N	1.00	2026-09-06 22:42:06.816471+00
1964	player	2594	1	2594	\N	1.00	2026-09-06 22:42:06.816471+00
1965	player	2595	1	2595	\N	1.00	2026-09-06 22:42:06.816471+00
1966	coach	1	1	1	\N	1.00	2026-09-06 22:42:06.816471+00
1967	coach	2	1	2	\N	1.00	2026-09-06 22:42:06.816471+00
1968	coach	3	1	3	\N	1.00	2026-09-06 22:42:06.816471+00
1969	coach	4	1	4	\N	1.00	2026-09-06 22:42:06.816471+00
1970	coach	5	1	5	\N	1.00	2026-09-06 22:42:06.816471+00
1971	coach	6	1	6	\N	1.00	2026-09-06 22:42:06.816471+00
1972	coach	7	1	7	\N	1.00	2026-09-06 22:42:06.816471+00
1973	coach	8	1	8	\N	1.00	2026-09-06 22:42:06.816471+00
1974	coach	9	1	9	\N	1.00	2026-09-06 22:42:06.816471+00
1975	coach	10	1	10	\N	1.00	2026-09-06 22:42:06.816471+00
1976	coach	11	1	11	\N	1.00	2026-09-06 22:42:06.816471+00
1977	coach	12	1	12	\N	1.00	2026-09-06 22:42:06.816471+00
1978	coach	13	1	13	\N	1.00	2026-09-06 22:42:06.816471+00
1979	coach	14	1	14	\N	1.00	2026-09-06 22:42:06.816471+00
1980	coach	15	1	15	\N	1.00	2026-09-06 22:42:06.816471+00
1981	coach	16	1	16	\N	1.00	2026-09-06 22:42:06.816471+00
1982	coach	17	1	17	\N	1.00	2026-09-06 22:42:06.816471+00
1983	coach	18	1	18	\N	1.00	2026-09-06 22:42:06.816471+00
1984	coach	19	1	19	\N	1.00	2026-09-06 22:42:06.816471+00
1985	coach	20	1	20	\N	1.00	2026-09-06 22:42:06.816471+00
1986	coach	21	1	21	\N	1.00	2026-09-06 22:42:06.816471+00
1987	coach	22	1	22	\N	1.00	2026-09-06 22:42:06.816471+00
1988	match	13	1	13	\N	1.00	2026-09-06 22:42:06.816471+00
1989	match	14	1	14	\N	1.00	2026-09-06 22:42:06.816471+00
1990	match	16	1	16	\N	1.00	2026-09-06 22:42:06.816471+00
1991	match	17	1	17	\N	1.00	2026-09-06 22:42:06.816471+00
1992	match	18	1	18	\N	1.00	2026-09-06 22:42:06.816471+00
1993	match	19	1	19	\N	1.00	2026-09-06 22:42:06.816471+00
1994	match	20	1	20	\N	1.00	2026-09-06 22:42:06.816471+00
1995	match	21	1	21	\N	1.00	2026-09-06 22:42:06.816471+00
1996	match	22	1	22	\N	1.00	2026-09-06 22:42:06.816471+00
1997	match	23	1	23	\N	1.00	2026-09-06 22:42:06.816471+00
1998	match	24	1	24	\N	1.00	2026-09-06 22:42:06.816471+00
1999	match	25	1	25	\N	1.00	2026-09-06 22:42:06.816471+00
2000	match	26	1	26	\N	1.00	2026-09-06 22:42:06.816471+00
2001	match	27	1	27	\N	1.00	2026-09-06 22:42:06.816471+00
2002	match	28	1	28	\N	1.00	2026-09-06 22:42:06.816471+00
2003	match	29	1	29	\N	1.00	2026-09-06 22:42:06.816471+00
2004	match	30	1	30	\N	1.00	2026-09-06 22:42:06.816471+00
2005	match	31	1	31	\N	1.00	2026-09-06 22:42:06.816471+00
2006	match	32	1	32	\N	1.00	2026-09-06 22:42:06.816471+00
2007	match	33	1	33	\N	1.00	2026-09-06 22:42:06.816471+00
2008	match	34	1	34	\N	1.00	2026-09-06 22:42:06.816471+00
2009	match	35	1	35	\N	1.00	2026-09-06 22:42:06.816471+00
2010	match	36	1	36	\N	1.00	2026-09-06 22:42:06.816471+00
2011	match	37	1	37	\N	1.00	2026-09-06 22:42:06.816471+00
2012	match	38	1	38	\N	1.00	2026-09-06 22:42:06.816471+00
2013	match	39	1	39	\N	1.00	2026-09-06 22:42:06.816471+00
2014	match	40	1	40	\N	1.00	2026-09-06 22:42:06.816471+00
2015	match	41	1	41	\N	1.00	2026-09-06 22:42:06.816471+00
2016	match	42	1	42	\N	1.00	2026-09-06 22:42:06.816471+00
2017	match	43	1	43	\N	1.00	2026-09-06 22:42:06.816471+00
2018	match	44	1	44	\N	1.00	2026-09-06 22:42:06.816471+00
2019	match	45	1	45	\N	1.00	2026-09-06 22:42:06.816471+00
2020	match	46	1	46	\N	1.00	2026-09-06 22:42:06.816471+00
2021	match	47	1	47	\N	1.00	2026-09-06 22:42:06.816471+00
2022	match	48	1	48	\N	1.00	2026-09-06 22:42:06.816471+00
2023	match	49	1	49	\N	1.00	2026-09-06 22:42:06.816471+00
2024	match	50	1	50	\N	1.00	2026-09-06 22:42:06.816471+00
2025	match	51	1	51	\N	1.00	2026-09-06 22:42:06.816471+00
2026	match	52	1	52	\N	1.00	2026-09-06 22:42:06.816471+00
2027	match	53	1	53	\N	1.00	2026-09-06 22:42:06.816471+00
2028	match	55	1	55	\N	1.00	2026-09-06 22:42:06.816471+00
2029	match	56	1	56	\N	1.00	2026-09-06 22:42:06.816471+00
2030	match	57	1	57	\N	1.00	2026-09-06 22:42:06.816471+00
2031	match	58	1	58	\N	1.00	2026-09-06 22:42:06.816471+00
2032	match	59	1	59	\N	1.00	2026-09-06 22:42:06.816471+00
2033	match	60	1	60	\N	1.00	2026-09-06 22:42:06.816471+00
2034	match	61	1	61	\N	1.00	2026-09-06 22:42:06.816471+00
2035	match	62	1	62	\N	1.00	2026-09-06 22:42:06.816471+00
2036	match	63	1	63	\N	1.00	2026-09-06 22:42:06.816471+00
2037	match	64	1	64	\N	1.00	2026-09-06 22:42:06.816471+00
2038	match	65	1	65	\N	1.00	2026-09-06 22:42:06.816471+00
2039	match	66	1	66	\N	1.00	2026-09-06 22:42:06.816471+00
2040	match	67	1	67	\N	1.00	2026-09-06 22:42:06.816471+00
2041	match	68	1	68	\N	1.00	2026-09-06 22:42:06.816471+00
2042	match	69	1	69	\N	1.00	2026-09-06 22:42:06.816471+00
2043	match	70	1	70	\N	1.00	2026-09-06 22:42:06.816471+00
2044	match	71	1	71	\N	1.00	2026-09-06 22:42:06.816471+00
2045	match	72	1	72	\N	1.00	2026-09-06 22:42:06.816471+00
2046	match	73	1	73	\N	1.00	2026-09-06 22:42:06.816471+00
2047	match	74	1	74	\N	1.00	2026-09-06 22:42:06.816471+00
2048	match	75	1	75	\N	1.00	2026-09-06 22:42:06.816471+00
2049	match	76	1	76	\N	1.00	2026-09-06 22:42:06.816471+00
2050	match	77	1	77	\N	1.00	2026-09-06 22:42:06.816471+00
2051	match	78	1	78	\N	1.00	2026-09-06 22:42:06.816471+00
2052	match	79	1	79	\N	1.00	2026-09-06 22:42:06.816471+00
2053	match	80	1	80	\N	1.00	2026-09-06 22:42:06.816471+00
2054	match	81	1	81	\N	1.00	2026-09-06 22:42:06.816471+00
2055	match	82	1	82	\N	1.00	2026-09-06 22:42:06.816471+00
2056	match	83	1	83	\N	1.00	2026-09-06 22:42:06.816471+00
2057	match	84	1	84	\N	1.00	2026-09-06 22:42:06.816471+00
2058	match	85	1	85	\N	1.00	2026-09-06 22:42:06.816471+00
2059	match	86	1	86	\N	1.00	2026-09-06 22:42:06.816471+00
2060	match	87	1	87	\N	1.00	2026-09-06 22:42:06.816471+00
2061	match	88	1	88	\N	1.00	2026-09-06 22:42:06.816471+00
2062	match	89	1	89	\N	1.00	2026-09-06 22:42:06.816471+00
2063	match	90	1	90	\N	1.00	2026-09-06 22:42:06.816471+00
2064	match	91	1	91	\N	1.00	2026-09-06 22:42:06.816471+00
2065	match	92	1	92	\N	1.00	2026-09-06 22:42:06.816471+00
2066	match	93	1	93	\N	1.00	2026-09-06 22:42:06.816471+00
2067	match	94	1	94	\N	1.00	2026-09-06 22:42:06.816471+00
2068	match	95	1	95	\N	1.00	2026-09-06 22:42:06.816471+00
2069	match	96	1	96	\N	1.00	2026-09-06 22:42:06.816471+00
2070	match	97	1	97	\N	1.00	2026-09-06 22:42:06.816471+00
2071	match	98	1	98	\N	1.00	2026-09-06 22:42:06.816471+00
2072	match	99	1	99	\N	1.00	2026-09-06 22:42:06.816471+00
2073	match	100	1	100	\N	1.00	2026-09-06 22:42:06.816471+00
2074	match	101	1	101	\N	1.00	2026-09-06 22:42:06.816471+00
2075	match	102	1	102	\N	1.00	2026-09-06 22:42:06.816471+00
2076	match	103	1	103	\N	1.00	2026-09-06 22:42:06.816471+00
2077	match	104	1	104	\N	1.00	2026-09-06 22:42:06.816471+00
2078	match	105	1	105	\N	1.00	2026-09-06 22:42:06.816471+00
2079	match	106	1	106	\N	1.00	2026-09-06 22:42:06.816471+00
2080	match	107	1	107	\N	1.00	2026-09-06 22:42:06.816471+00
2081	match	108	1	108	\N	1.00	2026-09-06 22:42:06.816471+00
2082	match	109	1	109	\N	1.00	2026-09-06 22:42:06.816471+00
2083	match	110	1	110	\N	1.00	2026-09-06 22:42:06.816471+00
2084	match	111	1	111	\N	1.00	2026-09-06 22:42:06.816471+00
2085	match	112	1	112	\N	1.00	2026-09-06 22:42:06.816471+00
2086	match	113	1	113	\N	1.00	2026-09-06 22:42:06.816471+00
2087	match	114	1	114	\N	1.00	2026-09-06 22:42:06.816471+00
2088	match	115	1	115	\N	1.00	2026-09-06 22:42:06.816471+00
2089	match	116	1	116	\N	1.00	2026-09-06 22:42:06.816471+00
2090	match	117	1	117	\N	1.00	2026-09-06 22:42:06.816471+00
2091	match	118	1	118	\N	1.00	2026-09-06 22:42:06.816471+00
2092	match	119	1	119	\N	1.00	2026-09-06 22:42:06.816471+00
2093	match	120	1	120	\N	1.00	2026-09-06 22:42:06.816471+00
2094	match	121	1	121	\N	1.00	2026-09-06 22:42:06.816471+00
2095	match	122	1	122	\N	1.00	2026-09-06 22:42:06.816471+00
2096	match	123	1	123	\N	1.00	2026-09-06 22:42:06.816471+00
2097	match	124	1	124	\N	1.00	2026-09-06 22:42:06.816471+00
2098	match	125	1	125	\N	1.00	2026-09-06 22:42:06.816471+00
2099	match	126	1	126	\N	1.00	2026-09-06 22:42:06.816471+00
2100	match	127	1	127	\N	1.00	2026-09-06 22:42:06.816471+00
2101	match	128	1	128	\N	1.00	2026-09-06 22:42:06.816471+00
2102	match	129	1	129	\N	1.00	2026-09-06 22:42:06.816471+00
2103	match	130	1	130	\N	1.00	2026-09-06 22:42:06.816471+00
2104	match	131	1	131	\N	1.00	2026-09-06 22:42:06.816471+00
2105	match	132	1	132	\N	1.00	2026-09-06 22:42:06.816471+00
2106	match	133	1	133	\N	1.00	2026-09-06 22:42:06.816471+00
2107	match	134	1	134	\N	1.00	2026-09-06 22:42:06.816471+00
2108	match	135	1	135	\N	1.00	2026-09-06 22:42:06.816471+00
2109	match	136	1	136	\N	1.00	2026-09-06 22:42:06.816471+00
2110	match	137	1	137	\N	1.00	2026-09-06 22:42:06.816471+00
2111	match	138	1	138	\N	1.00	2026-09-06 22:42:06.816471+00
2112	match	139	1	139	\N	1.00	2026-09-06 22:42:06.816471+00
2113	match	140	1	140	\N	1.00	2026-09-06 22:42:06.816471+00
2114	match	141	1	141	\N	1.00	2026-09-06 22:42:06.816471+00
2115	match	142	1	142	\N	1.00	2026-09-06 22:42:06.816471+00
2116	match	143	1	143	\N	1.00	2026-09-06 22:42:06.816471+00
2117	match	144	1	144	\N	1.00	2026-09-06 22:42:06.816471+00
2118	match	145	1	145	\N	1.00	2026-09-06 22:42:06.816471+00
2119	match	146	1	146	\N	1.00	2026-09-06 22:42:06.816471+00
2120	match	147	1	147	\N	1.00	2026-09-06 22:42:06.816471+00
2121	match	148	1	148	\N	1.00	2026-09-06 22:42:06.816471+00
2122	match	149	1	149	\N	1.00	2026-09-06 22:42:06.816471+00
2123	match	150	1	150	\N	1.00	2026-09-06 22:42:06.816471+00
2124	match	151	1	151	\N	1.00	2026-09-06 22:42:06.816471+00
2125	match	152	1	152	\N	1.00	2026-09-06 22:42:06.816471+00
2126	match	153	1	153	\N	1.00	2026-09-06 22:42:06.816471+00
2127	match	154	1	154	\N	1.00	2026-09-06 22:42:06.816471+00
2128	match	155	1	155	\N	1.00	2026-09-06 22:42:06.816471+00
2129	match	156	1	156	\N	1.00	2026-09-06 22:42:06.816471+00
2130	match	157	1	157	\N	1.00	2026-09-06 22:42:06.816471+00
2131	match	158	1	158	\N	1.00	2026-09-06 22:42:06.816471+00
2132	match	159	1	159	\N	1.00	2026-09-06 22:42:06.816471+00
2133	match	160	1	160	\N	1.00	2026-09-06 22:42:06.816471+00
2134	match	161	1	161	\N	1.00	2026-09-06 22:42:06.816471+00
2135	match	162	1	162	\N	1.00	2026-09-06 22:42:06.816471+00
2136	match	163	1	163	\N	1.00	2026-09-06 22:42:06.816471+00
2137	match	164	1	164	\N	1.00	2026-09-06 22:42:06.816471+00
2138	match	165	1	165	\N	1.00	2026-09-06 22:42:06.816471+00
2139	match	166	1	166	\N	1.00	2026-09-06 22:42:06.816471+00
2140	match	168	1	168	\N	1.00	2026-09-06 22:42:06.816471+00
2141	match	169	1	169	\N	1.00	2026-09-06 22:42:06.816471+00
2142	match	170	1	170	\N	1.00	2026-09-06 22:42:06.816471+00
2143	match	171	1	171	\N	1.00	2026-09-06 22:42:06.816471+00
2144	match	172	1	172	\N	1.00	2026-09-06 22:42:06.816471+00
2145	match	173	1	173	\N	1.00	2026-09-06 22:42:06.816471+00
2146	match	174	1	174	\N	1.00	2026-09-06 22:42:06.816471+00
2147	match	175	1	175	\N	1.00	2026-09-06 22:42:06.816471+00
2148	match	176	1	176	\N	1.00	2026-09-06 22:42:06.816471+00
2149	match	177	1	177	\N	1.00	2026-09-06 22:42:06.816471+00
2150	match	178	1	178	\N	1.00	2026-09-06 22:42:06.816471+00
2151	match	179	1	179	\N	1.00	2026-09-06 22:42:06.816471+00
2152	match	180	1	180	\N	1.00	2026-09-06 22:42:06.816471+00
2153	match	181	1	181	\N	1.00	2026-09-06 22:42:06.816471+00
2154	match	182	1	182	\N	1.00	2026-09-06 22:42:06.816471+00
2155	match	183	1	183	\N	1.00	2026-09-06 22:42:06.816471+00
2156	match	184	1	184	\N	1.00	2026-09-06 22:42:06.816471+00
2157	match	185	1	185	\N	1.00	2026-09-06 22:42:06.816471+00
2158	match	186	1	186	\N	1.00	2026-09-06 22:42:06.816471+00
2159	match	187	1	187	\N	1.00	2026-09-06 22:42:06.816471+00
2160	match	188	1	188	\N	1.00	2026-09-06 22:42:06.816471+00
2161	match	189	1	189	\N	1.00	2026-09-06 22:42:06.816471+00
2162	match	190	1	190	\N	1.00	2026-09-06 22:42:06.816471+00
2163	match	191	1	191	\N	1.00	2026-09-06 22:42:06.816471+00
2164	match	192	1	192	\N	1.00	2026-09-06 22:42:06.816471+00
2165	match	193	1	193	\N	1.00	2026-09-06 22:42:06.816471+00
2166	match	194	1	194	\N	1.00	2026-09-06 22:42:06.816471+00
2167	match	195	1	195	\N	1.00	2026-09-06 22:42:06.816471+00
2168	match	196	1	196	\N	1.00	2026-09-06 22:42:06.816471+00
2169	match	197	1	197	\N	1.00	2026-09-06 22:42:06.816471+00
2170	match	198	1	198	\N	1.00	2026-09-06 22:42:06.816471+00
2171	match	199	1	199	\N	1.00	2026-09-06 22:42:06.816471+00
2172	match	200	1	200	\N	1.00	2026-09-06 22:42:06.816471+00
2173	match	201	1	201	\N	1.00	2026-09-06 22:42:06.816471+00
2174	match	202	1	202	\N	1.00	2026-09-06 22:42:06.816471+00
2175	match	203	1	203	\N	1.00	2026-09-06 22:42:06.816471+00
2176	match	204	1	204	\N	1.00	2026-09-06 22:42:06.816471+00
2177	match	205	1	205	\N	1.00	2026-09-06 22:42:06.816471+00
2178	match	206	1	206	\N	1.00	2026-09-06 22:42:06.816471+00
2179	match	207	1	207	\N	1.00	2026-09-06 22:42:06.816471+00
2180	match	208	1	208	\N	1.00	2026-09-06 22:42:06.816471+00
2181	match	209	1	209	\N	1.00	2026-09-06 22:42:06.816471+00
2182	match	210	1	210	\N	1.00	2026-09-06 22:42:06.816471+00
2183	match	211	1	211	\N	1.00	2026-09-06 22:42:06.816471+00
2184	match	212	1	212	\N	1.00	2026-09-06 22:42:06.816471+00
2185	match	213	1	213	\N	1.00	2026-09-06 22:42:06.816471+00
2186	match	214	1	214	\N	1.00	2026-09-06 22:42:06.816471+00
2187	match	215	1	215	\N	1.00	2026-09-06 22:42:06.816471+00
2188	match	216	1	216	\N	1.00	2026-09-06 22:42:06.816471+00
2189	match	217	1	217	\N	1.00	2026-09-06 22:42:06.816471+00
2190	match	218	1	218	\N	1.00	2026-09-06 22:42:06.816471+00
2191	match	219	1	219	\N	1.00	2026-09-06 22:42:06.816471+00
2192	match	220	1	220	\N	1.00	2026-09-06 22:42:06.816471+00
2193	match	221	1	221	\N	1.00	2026-09-06 22:42:06.816471+00
2194	match	222	1	222	\N	1.00	2026-09-06 22:42:06.816471+00
2195	match	223	1	223	\N	1.00	2026-09-06 22:42:06.816471+00
2196	match	224	1	224	\N	1.00	2026-09-06 22:42:06.816471+00
2197	match	225	1	225	\N	1.00	2026-09-06 22:42:06.816471+00
2198	match	226	1	226	\N	1.00	2026-09-06 22:42:06.816471+00
2199	match	227	1	227	\N	1.00	2026-09-06 22:42:06.816471+00
2200	match	228	1	228	\N	1.00	2026-09-06 22:42:06.816471+00
2201	match	229	1	229	\N	1.00	2026-09-06 22:42:06.816471+00
2202	match	230	1	230	\N	1.00	2026-09-06 22:42:06.816471+00
2203	match	231	1	231	\N	1.00	2026-09-06 22:42:06.816471+00
2204	match	232	1	232	\N	1.00	2026-09-06 22:42:06.816471+00
2205	match	233	1	233	\N	1.00	2026-09-06 22:42:06.816471+00
2206	match	234	1	234	\N	1.00	2026-09-06 22:42:06.816471+00
2207	match	235	1	235	\N	1.00	2026-09-06 22:42:06.816471+00
2208	match	236	1	236	\N	1.00	2026-09-06 22:42:06.816471+00
2209	match	237	1	237	\N	1.00	2026-09-06 22:42:06.816471+00
2210	match	238	1	238	\N	1.00	2026-09-06 22:42:06.816471+00
2211	match	239	1	239	\N	1.00	2026-09-06 22:42:06.816471+00
2212	match	240	1	240	\N	1.00	2026-09-06 22:42:06.816471+00
2213	match	241	1	241	\N	1.00	2026-09-06 22:42:06.816471+00
2214	match	242	1	242	\N	1.00	2026-09-06 22:42:06.816471+00
2215	match	243	1	243	\N	1.00	2026-09-06 22:42:06.816471+00
2216	match	244	1	244	\N	1.00	2026-09-06 22:42:06.816471+00
2217	match	245	1	245	\N	1.00	2026-09-06 22:42:06.816471+00
2218	match	246	1	246	\N	1.00	2026-09-06 22:42:06.816471+00
2219	match	247	1	247	\N	1.00	2026-09-06 22:42:06.816471+00
2220	match	248	1	248	\N	1.00	2026-09-06 22:42:06.816471+00
2221	match	249	1	249	\N	1.00	2026-09-06 22:42:06.816471+00
2222	match	250	1	250	\N	1.00	2026-09-06 22:42:06.816471+00
2223	match	251	1	251	\N	1.00	2026-09-06 22:42:06.816471+00
2224	match	252	1	252	\N	1.00	2026-09-06 22:42:06.816471+00
2225	match	253	1	253	\N	1.00	2026-09-06 22:42:06.816471+00
2226	match	254	1	254	\N	1.00	2026-09-06 22:42:06.816471+00
2227	match	255	1	255	\N	1.00	2026-09-06 22:42:06.816471+00
2228	match	256	1	256	\N	1.00	2026-09-06 22:42:06.816471+00
2229	match	258	1	258	\N	1.00	2026-09-06 22:42:06.816471+00
2230	match	259	1	259	\N	1.00	2026-09-06 22:42:06.816471+00
2231	match	260	1	260	\N	1.00	2026-09-06 22:42:06.816471+00
2232	match	261	1	261	\N	1.00	2026-09-06 22:42:06.816471+00
2233	match	262	1	262	\N	1.00	2026-09-06 22:42:06.816471+00
2234	match	263	1	263	\N	1.00	2026-09-06 22:42:06.816471+00
2235	match	264	1	264	\N	1.00	2026-09-06 22:42:06.816471+00
2236	match	265	1	265	\N	1.00	2026-09-06 22:42:06.816471+00
2237	match	266	1	266	\N	1.00	2026-09-06 22:42:06.816471+00
2238	match	267	1	267	\N	1.00	2026-09-06 22:42:06.816471+00
2239	match	268	1	268	\N	1.00	2026-09-06 22:42:06.816471+00
2240	match	269	1	269	\N	1.00	2026-09-06 22:42:06.816471+00
2241	match	270	1	270	\N	1.00	2026-09-06 22:42:06.816471+00
2242	match	271	1	271	\N	1.00	2026-09-06 22:42:06.816471+00
2243	match	272	1	272	\N	1.00	2026-09-06 22:42:06.816471+00
2244	match	273	1	273	\N	1.00	2026-09-06 22:42:06.816471+00
2245	match	274	1	274	\N	1.00	2026-09-06 22:42:06.816471+00
2246	match	275	1	275	\N	1.00	2026-09-06 22:42:06.816471+00
2247	match	276	1	276	\N	1.00	2026-09-06 22:42:06.816471+00
2248	match	277	1	277	\N	1.00	2026-09-06 22:42:06.816471+00
2249	match	278	1	278	\N	1.00	2026-09-06 22:42:06.816471+00
2250	match	279	1	279	\N	1.00	2026-09-06 22:42:06.816471+00
2251	match	280	1	280	\N	1.00	2026-09-06 22:42:06.816471+00
2252	match	281	1	281	\N	1.00	2026-09-06 22:42:06.816471+00
2253	match	282	1	282	\N	1.00	2026-09-06 22:42:06.816471+00
2254	match	283	1	283	\N	1.00	2026-09-06 22:42:06.816471+00
2255	match	284	1	284	\N	1.00	2026-09-06 22:42:06.816471+00
2256	match	285	1	285	\N	1.00	2026-09-06 22:42:06.816471+00
2257	match	286	1	286	\N	1.00	2026-09-06 22:42:06.816471+00
2258	match	287	1	287	\N	1.00	2026-09-06 22:42:06.816471+00
2259	match	288	1	288	\N	1.00	2026-09-06 22:42:06.816471+00
2260	match	289	1	289	\N	1.00	2026-09-06 22:42:06.816471+00
2261	match	290	1	290	\N	1.00	2026-09-06 22:42:06.816471+00
2262	match	291	1	291	\N	1.00	2026-09-06 22:42:06.816471+00
2263	match	292	1	292	\N	1.00	2026-09-06 22:42:06.816471+00
2264	match	293	1	293	\N	1.00	2026-09-06 22:42:06.816471+00
2265	match	294	1	294	\N	1.00	2026-09-06 22:42:06.816471+00
2266	match	295	1	295	\N	1.00	2026-09-06 22:42:06.816471+00
2267	match	296	1	296	\N	1.00	2026-09-06 22:42:06.816471+00
2268	match	297	1	297	\N	1.00	2026-09-06 22:42:06.816471+00
2269	match	298	1	298	\N	1.00	2026-09-06 22:42:06.816471+00
2270	match	299	1	299	\N	1.00	2026-09-06 22:42:06.816471+00
2271	match	300	1	300	\N	1.00	2026-09-06 22:42:06.816471+00
2272	match	301	1	301	\N	1.00	2026-09-06 22:42:06.816471+00
2273	match	302	1	302	\N	1.00	2026-09-06 22:42:06.816471+00
2274	match	304	1	304	\N	1.00	2026-09-06 22:42:06.816471+00
2275	match	305	1	305	\N	1.00	2026-09-06 22:42:06.816471+00
2276	match	306	1	306	\N	1.00	2026-09-06 22:42:06.816471+00
2277	match	307	1	307	\N	1.00	2026-09-06 22:42:06.816471+00
2278	match	308	1	308	\N	1.00	2026-09-06 22:42:06.816471+00
2279	match	309	1	309	\N	1.00	2026-09-06 22:42:06.816471+00
2280	match	310	1	310	\N	1.00	2026-09-06 22:42:06.816471+00
2281	match	311	1	311	\N	1.00	2026-09-06 22:42:06.816471+00
2282	match	312	1	312	\N	1.00	2026-09-06 22:42:06.816471+00
2283	match	313	1	313	\N	1.00	2026-09-06 22:42:06.816471+00
2284	match	314	1	314	\N	1.00	2026-09-06 22:42:06.816471+00
2285	match	315	1	315	\N	1.00	2026-09-06 22:42:06.816471+00
2286	match	316	1	316	\N	1.00	2026-09-06 22:42:06.816471+00
2287	match	317	1	317	\N	1.00	2026-09-06 22:42:06.816471+00
2288	match	318	1	318	\N	1.00	2026-09-06 22:42:06.816471+00
2289	match	319	1	319	\N	1.00	2026-09-06 22:42:06.816471+00
2290	match	320	1	320	\N	1.00	2026-09-06 22:42:06.816471+00
2291	match	321	1	321	\N	1.00	2026-09-06 22:42:06.816471+00
2292	match	322	1	322	\N	1.00	2026-09-06 22:42:06.816471+00
2293	match	323	1	323	\N	1.00	2026-09-06 22:42:06.816471+00
2294	match	324	1	324	\N	1.00	2026-09-06 22:42:06.816471+00
2295	match	325	1	325	\N	1.00	2026-09-06 22:42:06.816471+00
2296	match	326	1	326	\N	1.00	2026-09-06 22:42:06.816471+00
2297	match	327	1	327	\N	1.00	2026-09-06 22:42:06.816471+00
2298	match	328	1	328	\N	1.00	2026-09-06 22:42:06.816471+00
2299	match	329	1	329	\N	1.00	2026-09-06 22:42:06.816471+00
2300	match	330	1	330	\N	1.00	2026-09-06 22:42:06.816471+00
2301	match	331	1	331	\N	1.00	2026-09-06 22:42:06.816471+00
2302	match	332	1	332	\N	1.00	2026-09-06 22:42:06.816471+00
2303	match	333	1	333	\N	1.00	2026-09-06 22:42:06.816471+00
2304	match	334	1	334	\N	1.00	2026-09-06 22:42:06.816471+00
2305	match	335	1	335	\N	1.00	2026-09-06 22:42:06.816471+00
2306	match	336	1	336	\N	1.00	2026-09-06 22:42:06.816471+00
2307	match	337	1	337	\N	1.00	2026-09-06 22:42:06.816471+00
2308	match	338	1	338	\N	1.00	2026-09-06 22:42:06.816471+00
2309	match	339	1	339	\N	1.00	2026-09-06 22:42:06.816471+00
2310	match	340	1	340	\N	1.00	2026-09-06 22:42:06.816471+00
2311	match	341	1	341	\N	1.00	2026-09-06 22:42:06.816471+00
2312	match	342	1	342	\N	1.00	2026-09-06 22:42:06.816471+00
2313	match	343	1	343	\N	1.00	2026-09-06 22:42:06.816471+00
2314	match	344	1	344	\N	1.00	2026-09-06 22:42:06.816471+00
2315	match	345	1	345	\N	1.00	2026-09-06 22:42:06.816471+00
2316	match	346	1	346	\N	1.00	2026-09-06 22:42:06.816471+00
2317	match	347	1	347	\N	1.00	2026-09-06 22:42:06.816471+00
2318	match	348	1	348	\N	1.00	2026-09-06 22:42:06.816471+00
2319	match	349	1	349	\N	1.00	2026-09-06 22:42:06.816471+00
2320	match	350	1	350	\N	1.00	2026-09-06 22:42:06.816471+00
2321	match	351	1	351	\N	1.00	2026-09-06 22:42:06.816471+00
2322	match	352	1	352	\N	1.00	2026-09-06 22:42:06.816471+00
2323	match	353	1	353	\N	1.00	2026-09-06 22:42:06.816471+00
2324	match	354	1	354	\N	1.00	2026-09-06 22:42:06.816471+00
2325	match	355	1	355	\N	1.00	2026-09-06 22:42:06.816471+00
2326	match	356	1	356	\N	1.00	2026-09-06 22:42:06.816471+00
2327	match	357	1	357	\N	1.00	2026-09-06 22:42:06.816471+00
2328	match	358	1	358	\N	1.00	2026-09-06 22:42:06.816471+00
2329	match	359	1	359	\N	1.00	2026-09-06 22:42:06.816471+00
2330	match	360	1	360	\N	1.00	2026-09-06 22:42:06.816471+00
2331	match	361	1	361	\N	1.00	2026-09-06 22:42:06.816471+00
2332	match	362	1	362	\N	1.00	2026-09-06 22:42:06.816471+00
2333	match	363	1	363	\N	1.00	2026-09-06 22:42:06.816471+00
2334	match	364	1	364	\N	1.00	2026-09-06 22:42:06.816471+00
2335	match	365	1	365	\N	1.00	2026-09-06 22:42:06.816471+00
2336	match	366	1	366	\N	1.00	2026-09-06 22:42:06.816471+00
2337	match	367	1	367	\N	1.00	2026-09-06 22:42:06.816471+00
2338	match	368	1	368	\N	1.00	2026-09-06 22:42:06.816471+00
2339	match	369	1	369	\N	1.00	2026-09-06 22:42:06.816471+00
2340	match	370	1	370	\N	1.00	2026-09-06 22:42:06.816471+00
2341	match	371	1	371	\N	1.00	2026-09-06 22:42:06.816471+00
2342	match	372	1	372	\N	1.00	2026-09-06 22:42:06.816471+00
2343	match	373	1	373	\N	1.00	2026-09-06 22:42:06.816471+00
2344	match	374	1	374	\N	1.00	2026-09-06 22:42:06.816471+00
2345	match	375	1	375	\N	1.00	2026-09-06 22:42:06.816471+00
2346	match	376	1	376	\N	1.00	2026-09-06 22:42:06.816471+00
2347	match	377	1	377	\N	1.00	2026-09-06 22:42:06.816471+00
2348	match	378	1	378	\N	1.00	2026-09-06 22:42:06.816471+00
2349	match	379	1	379	\N	1.00	2026-09-06 22:42:06.816471+00
2350	match	380	1	380	\N	1.00	2026-09-06 22:42:06.816471+00
2351	match	381	1	381	\N	1.00	2026-09-06 22:42:06.816471+00
2352	match	382	1	382	\N	1.00	2026-09-06 22:42:06.816471+00
2353	match	383	1	383	\N	1.00	2026-09-06 22:42:06.816471+00
2354	match	384	1	384	\N	1.00	2026-09-06 22:42:06.816471+00
2355	match	385	1	385	\N	1.00	2026-09-06 22:42:06.816471+00
2356	match	386	1	386	\N	1.00	2026-09-06 22:42:06.816471+00
2357	match	387	1	387	\N	1.00	2026-09-06 22:42:06.816471+00
2358	match	388	1	388	\N	1.00	2026-09-06 22:42:06.816471+00
2359	match	389	1	389	\N	1.00	2026-09-06 22:42:06.816471+00
2360	match	390	1	390	\N	1.00	2026-09-06 22:42:06.816471+00
2361	match	391	1	391	\N	1.00	2026-09-06 22:42:06.816471+00
2362	match	392	1	392	\N	1.00	2026-09-06 22:42:06.816471+00
2363	match	393	1	393	\N	1.00	2026-09-06 22:42:06.816471+00
2364	match	394	1	394	\N	1.00	2026-09-06 22:42:06.816471+00
2365	match	395	1	395	\N	1.00	2026-09-06 22:42:06.816471+00
2366	match	396	1	396	\N	1.00	2026-09-06 22:42:06.816471+00
2367	match	397	1	397	\N	1.00	2026-09-06 22:42:06.816471+00
2368	match	398	1	398	\N	1.00	2026-09-06 22:42:06.816471+00
2369	match	399	1	399	\N	1.00	2026-09-06 22:42:06.816471+00
2370	match	400	1	400	\N	1.00	2026-09-06 22:42:06.816471+00
2371	match	401	1	401	\N	1.00	2026-09-06 22:42:06.816471+00
2372	match	402	1	402	\N	1.00	2026-09-06 22:42:06.816471+00
2373	match	403	1	403	\N	1.00	2026-09-06 22:42:06.816471+00
2374	match	404	1	404	\N	1.00	2026-09-06 22:42:06.816471+00
2375	match	405	1	405	\N	1.00	2026-09-06 22:42:06.816471+00
2376	match	406	1	406	\N	1.00	2026-09-06 22:42:06.816471+00
2377	match	407	1	407	\N	1.00	2026-09-06 22:42:06.816471+00
2378	match	408	1	408	\N	1.00	2026-09-06 22:42:06.816471+00
2379	match	409	1	409	\N	1.00	2026-09-06 22:42:06.816471+00
2380	match	410	1	410	\N	1.00	2026-09-06 22:42:06.816471+00
2381	match	411	1	411	\N	1.00	2026-09-06 22:42:06.816471+00
2382	match	412	1	412	\N	1.00	2026-09-06 22:42:06.816471+00
2383	match	413	1	413	\N	1.00	2026-09-06 22:42:06.816471+00
2384	match	414	1	414	\N	1.00	2026-09-06 22:42:06.816471+00
2385	match	415	1	415	\N	1.00	2026-09-06 22:42:06.816471+00
2386	match	416	1	416	\N	1.00	2026-09-06 22:42:06.816471+00
2387	match	417	1	417	\N	1.00	2026-09-06 22:42:06.816471+00
2388	match	418	1	418	\N	1.00	2026-09-06 22:42:06.816471+00
2389	match	419	1	419	\N	1.00	2026-09-06 22:42:06.816471+00
2390	match	420	1	420	\N	1.00	2026-09-06 22:42:06.816471+00
2391	match	421	1	421	\N	1.00	2026-09-06 22:42:06.816471+00
2392	match	422	1	422	\N	1.00	2026-09-06 22:42:06.816471+00
2393	match	423	1	423	\N	1.00	2026-09-06 22:42:06.816471+00
2394	match	424	1	424	\N	1.00	2026-09-06 22:42:06.816471+00
2395	match	425	1	425	\N	1.00	2026-09-06 22:42:06.816471+00
2396	match	426	1	426	\N	1.00	2026-09-06 22:42:06.816471+00
2397	match	427	1	427	\N	1.00	2026-09-06 22:42:06.816471+00
2398	match	428	1	428	\N	1.00	2026-09-06 22:42:06.816471+00
2399	match	429	1	429	\N	1.00	2026-09-06 22:42:06.816471+00
2400	match	430	1	430	\N	1.00	2026-09-06 22:42:06.816471+00
2401	match	431	1	431	\N	1.00	2026-09-06 22:42:06.816471+00
2402	match	432	1	432	\N	1.00	2026-09-06 22:42:06.816471+00
2403	match	433	1	433	\N	1.00	2026-09-06 22:42:06.816471+00
2404	match	434	1	434	\N	1.00	2026-09-06 22:42:06.816471+00
2405	match	435	1	435	\N	1.00	2026-09-06 22:42:06.816471+00
2406	match	436	1	436	\N	1.00	2026-09-06 22:42:06.816471+00
2407	match	437	1	437	\N	1.00	2026-09-06 22:42:06.816471+00
2408	match	438	1	438	\N	1.00	2026-09-06 22:42:06.816471+00
2409	match	439	1	439	\N	1.00	2026-09-06 22:42:06.816471+00
2410	match	440	1	440	\N	1.00	2026-09-06 22:42:06.816471+00
2411	match	441	1	441	\N	1.00	2026-09-06 22:42:06.816471+00
2412	match	442	1	442	\N	1.00	2026-09-06 22:42:06.816471+00
2413	match	443	1	443	\N	1.00	2026-09-06 22:42:06.816471+00
2414	match	444	1	444	\N	1.00	2026-09-06 22:42:06.816471+00
2415	match	445	1	445	\N	1.00	2026-09-06 22:42:06.816471+00
2416	match	446	1	446	\N	1.00	2026-09-06 22:42:06.816471+00
2417	match	447	1	447	\N	1.00	2026-09-06 22:42:06.816471+00
2418	match	448	1	448	\N	1.00	2026-09-06 22:42:06.816471+00
2419	match	449	1	449	\N	1.00	2026-09-06 22:42:06.816471+00
2420	match	450	1	450	\N	1.00	2026-09-06 22:42:06.816471+00
2421	match	451	1	451	\N	1.00	2026-09-06 22:42:06.816471+00
2422	match	452	1	452	\N	1.00	2026-09-06 22:42:06.816471+00
2423	match	453	1	453	\N	1.00	2026-09-06 22:42:06.816471+00
2424	match	454	1	454	\N	1.00	2026-09-06 22:42:06.816471+00
2425	match	455	1	455	\N	1.00	2026-09-06 22:42:06.816471+00
2426	match	456	1	456	\N	1.00	2026-09-06 22:42:06.816471+00
2427	match	457	1	457	\N	1.00	2026-09-06 22:42:06.816471+00
2428	match	458	1	458	\N	1.00	2026-09-06 22:42:06.816471+00
2429	match	459	1	459	\N	1.00	2026-09-06 22:42:06.816471+00
2430	match	460	1	460	\N	1.00	2026-09-06 22:42:06.816471+00
2431	match	461	1	461	\N	1.00	2026-09-06 22:42:06.816471+00
2432	match	462	1	462	\N	1.00	2026-09-06 22:42:06.816471+00
2433	match	463	1	463	\N	1.00	2026-09-06 22:42:06.816471+00
2434	match	464	1	464	\N	1.00	2026-09-06 22:42:06.816471+00
2435	match	465	1	465	\N	1.00	2026-09-06 22:42:06.816471+00
2436	match	466	1	466	\N	1.00	2026-09-06 22:42:06.816471+00
2437	match	467	1	467	\N	1.00	2026-09-06 22:42:06.816471+00
2438	match	468	1	468	\N	1.00	2026-09-06 22:42:06.816471+00
2439	match	469	1	469	\N	1.00	2026-09-06 22:42:06.816471+00
2440	match	470	1	470	\N	1.00	2026-09-06 22:42:06.816471+00
2441	match	471	1	471	\N	1.00	2026-09-06 22:42:06.816471+00
2442	match	472	1	472	\N	1.00	2026-09-06 22:42:06.816471+00
2443	match	473	1	473	\N	1.00	2026-09-06 22:42:06.816471+00
2444	match	474	1	474	\N	1.00	2026-09-06 22:42:06.816471+00
2445	match	475	1	475	\N	1.00	2026-09-06 22:42:06.816471+00
2446	match	476	1	476	\N	1.00	2026-09-06 22:42:06.816471+00
2447	match	477	1	477	\N	1.00	2026-09-06 22:42:06.816471+00
2448	match	478	1	478	\N	1.00	2026-09-06 22:42:06.816471+00
2449	match	479	1	479	\N	1.00	2026-09-06 22:42:06.816471+00
2450	match	480	1	480	\N	1.00	2026-09-06 22:42:06.816471+00
2451	match	481	1	481	\N	1.00	2026-09-06 22:42:06.816471+00
2452	match	482	1	482	\N	1.00	2026-09-06 22:42:06.816471+00
2453	match	483	1	483	\N	1.00	2026-09-06 22:42:06.816471+00
2454	match	484	1	484	\N	1.00	2026-09-06 22:42:06.816471+00
2455	match	485	1	485	\N	1.00	2026-09-06 22:42:06.816471+00
2456	match	486	1	486	\N	1.00	2026-09-06 22:42:06.816471+00
2457	match	487	1	487	\N	1.00	2026-09-06 22:42:06.816471+00
2458	match	488	1	488	\N	1.00	2026-09-06 22:42:06.816471+00
2459	match	489	1	489	\N	1.00	2026-09-06 22:42:06.816471+00
2460	match	490	1	490	\N	1.00	2026-09-06 22:42:06.816471+00
2461	match	491	1	491	\N	1.00	2026-09-06 22:42:06.816471+00
2462	match	492	1	492	\N	1.00	2026-09-06 22:42:06.816471+00
2463	match	493	1	493	\N	1.00	2026-09-06 22:42:06.816471+00
2464	match	494	1	494	\N	1.00	2026-09-06 22:42:06.816471+00
2465	match	495	1	495	\N	1.00	2026-09-06 22:42:06.816471+00
2466	match	496	1	496	\N	1.00	2026-09-06 22:42:06.816471+00
2467	match	497	1	497	\N	1.00	2026-09-06 22:42:06.816471+00
2468	match	498	1	498	\N	1.00	2026-09-06 22:42:06.816471+00
2469	match	499	1	499	\N	1.00	2026-09-06 22:42:06.816471+00
2470	match	500	1	500	\N	1.00	2026-09-06 22:42:06.816471+00
2471	match	501	1	501	\N	1.00	2026-09-06 22:42:06.816471+00
2472	match	502	1	502	\N	1.00	2026-09-06 22:42:06.816471+00
2473	match	503	1	503	\N	1.00	2026-09-06 22:42:06.816471+00
2474	match	504	1	504	\N	1.00	2026-09-06 22:42:06.816471+00
2475	match	505	1	505	\N	1.00	2026-09-06 22:42:06.816471+00
2476	match	506	1	506	\N	1.00	2026-09-06 22:42:06.816471+00
2477	match	507	1	507	\N	1.00	2026-09-06 22:42:06.816471+00
2478	match	508	1	508	\N	1.00	2026-09-06 22:42:06.816471+00
2479	match	509	1	509	\N	1.00	2026-09-06 22:42:06.816471+00
2480	match	510	1	510	\N	1.00	2026-09-06 22:42:06.816471+00
2481	match	511	1	511	\N	1.00	2026-09-06 22:42:06.816471+00
2482	match	512	1	512	\N	1.00	2026-09-06 22:42:06.816471+00
2483	match	513	1	513	\N	1.00	2026-09-06 22:42:06.816471+00
2484	match	514	1	514	\N	1.00	2026-09-06 22:42:06.816471+00
2485	match	515	1	515	\N	1.00	2026-09-06 22:42:06.816471+00
2486	match	516	1	516	\N	1.00	2026-09-06 22:42:06.816471+00
2487	match	517	1	517	\N	1.00	2026-09-06 22:42:06.816471+00
2488	match	518	1	518	\N	1.00	2026-09-06 22:42:06.816471+00
2489	match	519	1	519	\N	1.00	2026-09-06 22:42:06.816471+00
2490	match	520	1	520	\N	1.00	2026-09-06 22:42:06.816471+00
2491	match	521	1	521	\N	1.00	2026-09-06 22:42:06.816471+00
2492	match	522	1	522	\N	1.00	2026-09-06 22:42:06.816471+00
2493	match	523	1	523	\N	1.00	2026-09-06 22:42:06.816471+00
2494	match	524	1	524	\N	1.00	2026-09-06 22:42:06.816471+00
2495	match	525	1	525	\N	1.00	2026-09-06 22:42:06.816471+00
2496	match	526	1	526	\N	1.00	2026-09-06 22:42:06.816471+00
2497	match	527	1	527	\N	1.00	2026-09-06 22:42:06.816471+00
2498	match	528	1	528	\N	1.00	2026-09-06 22:42:06.816471+00
2499	match	529	1	529	\N	1.00	2026-09-06 22:42:06.816471+00
2500	match	530	1	530	\N	1.00	2026-09-06 22:42:06.816471+00
2501	match	531	1	531	\N	1.00	2026-09-06 22:42:06.816471+00
2502	match	532	1	532	\N	1.00	2026-09-06 22:42:06.816471+00
2503	match	533	1	533	\N	1.00	2026-09-06 22:42:06.816471+00
2504	match	534	1	534	\N	1.00	2026-09-06 22:42:06.816471+00
2505	match	535	1	535	\N	1.00	2026-09-06 22:42:06.816471+00
2506	match	536	1	536	\N	1.00	2026-09-06 22:42:06.816471+00
2507	match	537	1	537	\N	1.00	2026-09-06 22:42:06.816471+00
2508	match	538	1	538	\N	1.00	2026-09-06 22:42:06.816471+00
2509	match	539	1	539	\N	1.00	2026-09-06 22:42:06.816471+00
2510	match	540	1	540	\N	1.00	2026-09-06 22:42:06.816471+00
2511	match	541	1	541	\N	1.00	2026-09-06 22:42:06.816471+00
2512	match	542	1	542	\N	1.00	2026-09-06 22:42:06.816471+00
2513	match	543	1	543	\N	1.00	2026-09-06 22:42:06.816471+00
2514	match	544	1	544	\N	1.00	2026-09-06 22:42:06.816471+00
2515	match	545	1	545	\N	1.00	2026-09-06 22:42:06.816471+00
2516	match	546	1	546	\N	1.00	2026-09-06 22:42:06.816471+00
2517	match	547	1	547	\N	1.00	2026-09-06 22:42:06.816471+00
2518	match	548	1	548	\N	1.00	2026-09-06 22:42:06.816471+00
2519	match	549	1	549	\N	1.00	2026-09-06 22:42:06.816471+00
2520	match	550	1	550	\N	1.00	2026-09-06 22:42:06.816471+00
2521	match	551	1	551	\N	1.00	2026-09-06 22:42:06.816471+00
2522	match	552	1	552	\N	1.00	2026-09-06 22:42:06.816471+00
2523	match	553	1	553	\N	1.00	2026-09-06 22:42:06.816471+00
2524	match	554	1	554	\N	1.00	2026-09-06 22:42:06.816471+00
2525	match	555	1	555	\N	1.00	2026-09-06 22:42:06.816471+00
2526	match	556	1	556	\N	1.00	2026-09-06 22:42:06.816471+00
2527	match	557	1	557	\N	1.00	2026-09-06 22:42:06.816471+00
2528	match	558	1	558	\N	1.00	2026-09-06 22:42:06.816471+00
2529	match	559	1	559	\N	1.00	2026-09-06 22:42:06.816471+00
2530	match	560	1	560	\N	1.00	2026-09-06 22:42:06.816471+00
2531	match	561	1	561	\N	1.00	2026-09-06 22:42:06.816471+00
2532	match	562	1	562	\N	1.00	2026-09-06 22:42:06.816471+00
2533	match	563	1	563	\N	1.00	2026-09-06 22:42:06.816471+00
2534	match	564	1	564	\N	1.00	2026-09-06 22:42:06.816471+00
2535	match	565	1	565	\N	1.00	2026-09-06 22:42:06.816471+00
2536	match	566	1	566	\N	1.00	2026-09-06 22:42:06.816471+00
2537	match	567	1	567	\N	1.00	2026-09-06 22:42:06.816471+00
2538	match	568	1	568	\N	1.00	2026-09-06 22:42:06.816471+00
2539	match	569	1	569	\N	1.00	2026-09-06 22:42:06.816471+00
2540	match	570	1	570	\N	1.00	2026-09-06 22:42:06.816471+00
2541	match	571	1	571	\N	1.00	2026-09-06 22:42:06.816471+00
2542	match	572	1	572	\N	1.00	2026-09-06 22:42:06.816471+00
2543	match	573	1	573	\N	1.00	2026-09-06 22:42:06.816471+00
2544	match	574	1	574	\N	1.00	2026-09-06 22:42:06.816471+00
2545	match	575	1	575	\N	1.00	2026-09-06 22:42:06.816471+00
2546	match	576	1	576	\N	1.00	2026-09-06 22:42:06.816471+00
2547	match	577	1	577	\N	1.00	2026-09-06 22:42:06.816471+00
2548	match	578	1	578	\N	1.00	2026-09-06 22:42:06.816471+00
2549	match	579	1	579	\N	1.00	2026-09-06 22:42:06.816471+00
2550	match	580	1	580	\N	1.00	2026-09-06 22:42:06.816471+00
2551	match	581	1	581	\N	1.00	2026-09-06 22:42:06.816471+00
2552	match	582	1	582	\N	1.00	2026-09-06 22:42:06.816471+00
2553	match	583	1	583	\N	1.00	2026-09-06 22:42:06.816471+00
2554	match	584	1	584	\N	1.00	2026-09-06 22:42:06.816471+00
2555	match	585	1	585	\N	1.00	2026-09-06 22:42:06.816471+00
2556	match	586	1	586	\N	1.00	2026-09-06 22:42:06.816471+00
2557	match	587	1	587	\N	1.00	2026-09-06 22:42:06.816471+00
2558	match	588	1	588	\N	1.00	2026-09-06 22:42:06.816471+00
2559	match	589	1	589	\N	1.00	2026-09-06 22:42:06.816471+00
2560	match	590	1	590	\N	1.00	2026-09-06 22:42:06.816471+00
2561	match	591	1	591	\N	1.00	2026-09-06 22:42:06.816471+00
2562	match	592	1	592	\N	1.00	2026-09-06 22:42:06.816471+00
2563	match	593	1	593	\N	1.00	2026-09-06 22:42:06.816471+00
2564	match	594	1	594	\N	1.00	2026-09-06 22:42:06.816471+00
2565	match	595	1	595	\N	1.00	2026-09-06 22:42:06.816471+00
2566	match	596	1	596	\N	1.00	2026-09-06 22:42:06.816471+00
2567	match	597	1	597	\N	1.00	2026-09-06 22:42:06.816471+00
2568	match	598	1	598	\N	1.00	2026-09-06 22:42:06.816471+00
2569	match	599	1	599	\N	1.00	2026-09-06 22:42:06.816471+00
2570	match	600	1	600	\N	1.00	2026-09-06 22:42:06.816471+00
2571	match	601	1	601	\N	1.00	2026-09-06 22:42:06.816471+00
2572	match	602	1	602	\N	1.00	2026-09-06 22:42:06.816471+00
2573	match	603	1	603	\N	1.00	2026-09-06 22:42:06.816471+00
2574	match	604	1	604	\N	1.00	2026-09-06 22:42:06.816471+00
2575	match	605	1	605	\N	1.00	2026-09-06 22:42:06.816471+00
2576	match	606	1	606	\N	1.00	2026-09-06 22:42:06.816471+00
2577	match	607	1	607	\N	1.00	2026-09-06 22:42:06.816471+00
2578	match	608	1	608	\N	1.00	2026-09-06 22:42:06.816471+00
2579	match	609	1	609	\N	1.00	2026-09-06 22:42:06.816471+00
2580	match	610	1	610	\N	1.00	2026-09-06 22:42:06.816471+00
2581	match	611	1	611	\N	1.00	2026-09-06 22:42:06.816471+00
2582	match	612	1	612	\N	1.00	2026-09-06 22:42:06.816471+00
2583	match	613	1	613	\N	1.00	2026-09-06 22:42:06.816471+00
2584	match	614	1	614	\N	1.00	2026-09-06 22:42:06.816471+00
2585	match	615	1	615	\N	1.00	2026-09-06 22:42:06.816471+00
2586	match	616	1	616	\N	1.00	2026-09-06 22:42:06.816471+00
2587	match	617	1	617	\N	1.00	2026-09-06 22:42:06.816471+00
2588	match	618	1	618	\N	1.00	2026-09-06 22:42:06.816471+00
2589	match	619	1	619	\N	1.00	2026-09-06 22:42:06.816471+00
2590	match	620	1	620	\N	1.00	2026-09-06 22:42:06.816471+00
2591	match	621	1	621	\N	1.00	2026-09-06 22:42:06.816471+00
2592	match	622	1	622	\N	1.00	2026-09-06 22:42:06.816471+00
2593	match	623	1	623	\N	1.00	2026-09-06 22:42:06.816471+00
2594	match	624	1	624	\N	1.00	2026-09-06 22:42:06.816471+00
2595	match	625	1	625	\N	1.00	2026-09-06 22:42:06.816471+00
2596	match	626	1	626	\N	1.00	2026-09-06 22:42:06.816471+00
2597	match	627	1	627	\N	1.00	2026-09-06 22:42:06.816471+00
2598	match	628	1	628	\N	1.00	2026-09-06 22:42:06.816471+00
2599	match	629	1	629	\N	1.00	2026-09-06 22:42:06.816471+00
2600	match	630	1	630	\N	1.00	2026-09-06 22:42:06.816471+00
2601	match	631	1	631	\N	1.00	2026-09-06 22:42:06.816471+00
2602	match	632	1	632	\N	1.00	2026-09-06 22:42:06.816471+00
2603	match	633	1	633	\N	1.00	2026-09-06 22:42:06.816471+00
2604	match	634	1	634	\N	1.00	2026-09-06 22:42:06.816471+00
2605	match	635	1	635	\N	1.00	2026-09-06 22:42:06.816471+00
2606	match	636	1	636	\N	1.00	2026-09-06 22:42:06.816471+00
2607	match	637	1	637	\N	1.00	2026-09-06 22:42:06.816471+00
2608	match	638	1	638	\N	1.00	2026-09-06 22:42:06.816471+00
2609	match	639	1	639	\N	1.00	2026-09-06 22:42:06.816471+00
2610	match	640	1	640	\N	1.00	2026-09-06 22:42:06.816471+00
2611	match	641	1	641	\N	1.00	2026-09-06 22:42:06.816471+00
2612	match	642	1	642	\N	1.00	2026-09-06 22:42:06.816471+00
2613	match	643	1	643	\N	1.00	2026-09-06 22:42:06.816471+00
2614	match	644	1	644	\N	1.00	2026-09-06 22:42:06.816471+00
2615	match	645	1	645	\N	1.00	2026-09-06 22:42:06.816471+00
2616	match	646	1	646	\N	1.00	2026-09-06 22:42:06.816471+00
2617	match	647	1	647	\N	1.00	2026-09-06 22:42:06.816471+00
2618	match	648	1	648	\N	1.00	2026-09-06 22:42:06.816471+00
2619	match	649	1	649	\N	1.00	2026-09-06 22:42:06.816471+00
2620	match	650	1	650	\N	1.00	2026-09-06 22:42:06.816471+00
2621	match	651	1	651	\N	1.00	2026-09-06 22:42:06.816471+00
2622	match	652	1	652	\N	1.00	2026-09-06 22:42:06.816471+00
2623	match	653	1	653	\N	1.00	2026-09-06 22:42:06.816471+00
2624	match	654	1	654	\N	1.00	2026-09-06 22:42:06.816471+00
2625	match	655	1	655	\N	1.00	2026-09-06 22:42:06.816471+00
2626	match	656	1	656	\N	1.00	2026-09-06 22:42:06.816471+00
2627	match	657	1	657	\N	1.00	2026-09-06 22:42:06.816471+00
2628	match	658	1	658	\N	1.00	2026-09-06 22:42:06.816471+00
2629	match	659	1	659	\N	1.00	2026-09-06 22:42:06.816471+00
2630	match	660	1	660	\N	1.00	2026-09-06 22:42:06.816471+00
2631	match	661	1	661	\N	1.00	2026-09-06 22:42:06.816471+00
2632	match	662	1	662	\N	1.00	2026-09-06 22:42:06.816471+00
2633	match	663	1	663	\N	1.00	2026-09-06 22:42:06.816471+00
2634	match	664	1	664	\N	1.00	2026-09-06 22:42:06.816471+00
2635	match	665	1	665	\N	1.00	2026-09-06 22:42:06.816471+00
2636	match	666	1	666	\N	1.00	2026-09-06 22:42:06.816471+00
2637	match	667	1	667	\N	1.00	2026-09-06 22:42:06.816471+00
2638	match	668	1	668	\N	1.00	2026-09-06 22:42:06.816471+00
2639	match	669	1	669	\N	1.00	2026-09-06 22:42:06.816471+00
2640	match	670	1	670	\N	1.00	2026-09-06 22:42:06.816471+00
2641	match	671	1	671	\N	1.00	2026-09-06 22:42:06.816471+00
2642	match	672	1	672	\N	1.00	2026-09-06 22:42:06.816471+00
2643	match	673	1	673	\N	1.00	2026-09-06 22:42:06.816471+00
2644	match	674	1	674	\N	1.00	2026-09-06 22:42:06.816471+00
2645	match	675	1	675	\N	1.00	2026-09-06 22:42:06.816471+00
2646	match	676	1	676	\N	1.00	2026-09-06 22:42:06.816471+00
2647	match	677	1	677	\N	1.00	2026-09-06 22:42:06.816471+00
2648	match	678	1	678	\N	1.00	2026-09-06 22:42:06.816471+00
2649	match	679	1	679	\N	1.00	2026-09-06 22:42:06.816471+00
2650	match	680	1	680	\N	1.00	2026-09-06 22:42:06.816471+00
2651	match	681	1	681	\N	1.00	2026-09-06 22:42:06.816471+00
2652	match	682	1	682	\N	1.00	2026-09-06 22:42:06.816471+00
2653	match	683	1	683	\N	1.00	2026-09-06 22:42:06.816471+00
2654	match	684	1	684	\N	1.00	2026-09-06 22:42:06.816471+00
2655	match	685	1	685	\N	1.00	2026-09-06 22:42:06.816471+00
2656	match	686	1	686	\N	1.00	2026-09-06 22:42:06.816471+00
2657	match	687	1	687	\N	1.00	2026-09-06 22:42:06.816471+00
2658	match	688	1	688	\N	1.00	2026-09-06 22:42:06.816471+00
2659	match	689	1	689	\N	1.00	2026-09-06 22:42:06.816471+00
2660	match	690	1	690	\N	1.00	2026-09-06 22:42:06.816471+00
2661	match	691	1	691	\N	1.00	2026-09-06 22:42:06.816471+00
2662	match	692	1	692	\N	1.00	2026-09-06 22:42:06.816471+00
2663	match	693	1	693	\N	1.00	2026-09-06 22:42:06.816471+00
2664	match	694	1	694	\N	1.00	2026-09-06 22:42:06.816471+00
2665	match	695	1	695	\N	1.00	2026-09-06 22:42:06.816471+00
2666	match	696	1	696	\N	1.00	2026-09-06 22:42:06.816471+00
2667	match	697	1	697	\N	1.00	2026-09-06 22:42:06.816471+00
2668	match	698	1	698	\N	1.00	2026-09-06 22:42:06.816471+00
2669	match	699	1	699	\N	1.00	2026-09-06 22:42:06.816471+00
2670	match	700	1	700	\N	1.00	2026-09-06 22:42:06.816471+00
2671	match	701	1	701	\N	1.00	2026-09-06 22:42:06.816471+00
2672	match	702	1	702	\N	1.00	2026-09-06 22:42:06.816471+00
2673	match	703	1	703	\N	1.00	2026-09-06 22:42:06.816471+00
2674	match	704	1	704	\N	1.00	2026-09-06 22:42:06.816471+00
2675	match	705	1	705	\N	1.00	2026-09-06 22:42:06.816471+00
2676	match	706	1	706	\N	1.00	2026-09-06 22:42:06.816471+00
2677	match	707	1	707	\N	1.00	2026-09-06 22:42:06.816471+00
2678	match	708	1	708	\N	1.00	2026-09-06 22:42:06.816471+00
2679	match	709	1	709	\N	1.00	2026-09-06 22:42:06.816471+00
2680	match	710	1	710	\N	1.00	2026-09-06 22:42:06.816471+00
2681	match	711	1	711	\N	1.00	2026-09-06 22:42:06.816471+00
2682	match	712	1	712	\N	1.00	2026-09-06 22:42:06.816471+00
2683	match	713	1	713	\N	1.00	2026-09-06 22:42:06.816471+00
2684	match	714	1	714	\N	1.00	2026-09-06 22:42:06.816471+00
2685	match	715	1	715	\N	1.00	2026-09-06 22:42:06.816471+00
2686	match	716	1	716	\N	1.00	2026-09-06 22:42:06.816471+00
2687	match	717	1	717	\N	1.00	2026-09-06 22:42:06.816471+00
2688	match	718	1	718	\N	1.00	2026-09-06 22:42:06.816471+00
2689	match	719	1	719	\N	1.00	2026-09-06 22:42:06.816471+00
2690	match	720	1	720	\N	1.00	2026-09-06 22:42:06.816471+00
2691	match	721	1	721	\N	1.00	2026-09-06 22:42:06.816471+00
2692	match	722	1	722	\N	1.00	2026-09-06 22:42:06.816471+00
2693	match	723	1	723	\N	1.00	2026-09-06 22:42:06.816471+00
2694	match	724	1	724	\N	1.00	2026-09-06 22:42:06.816471+00
2695	match	725	1	725	\N	1.00	2026-09-06 22:42:06.816471+00
2696	match	726	1	726	\N	1.00	2026-09-06 22:42:06.816471+00
2697	match	727	1	727	\N	1.00	2026-09-06 22:42:06.816471+00
2698	match	728	1	728	\N	1.00	2026-09-06 22:42:06.816471+00
2699	match	729	1	729	\N	1.00	2026-09-06 22:42:06.816471+00
2700	match	730	1	730	\N	1.00	2026-09-06 22:42:06.816471+00
2701	match	731	1	731	\N	1.00	2026-09-06 22:42:06.816471+00
2702	match	732	1	732	\N	1.00	2026-09-06 22:42:06.816471+00
2703	match	733	1	733	\N	1.00	2026-09-06 22:42:06.816471+00
2704	match	734	1	734	\N	1.00	2026-09-06 22:42:06.816471+00
2705	match	735	1	735	\N	1.00	2026-09-06 22:42:06.816471+00
2706	match	736	1	736	\N	1.00	2026-09-06 22:42:06.816471+00
2707	match	737	1	737	\N	1.00	2026-09-06 22:42:06.816471+00
2708	match	738	1	738	\N	1.00	2026-09-06 22:42:06.816471+00
2709	match	739	1	739	\N	1.00	2026-09-06 22:42:06.816471+00
2710	match	740	1	740	\N	1.00	2026-09-06 22:42:06.816471+00
2711	match	741	1	741	\N	1.00	2026-09-06 22:42:06.816471+00
2712	match	743	1	743	\N	1.00	2026-09-06 22:42:06.816471+00
2713	match	744	1	744	\N	1.00	2026-09-06 22:42:06.816471+00
2714	match	746	1	746	\N	1.00	2026-09-06 22:42:06.816471+00
2715	match	747	1	747	\N	1.00	2026-09-06 22:42:06.816471+00
2716	match	748	1	748	\N	1.00	2026-09-06 22:42:06.816471+00
2717	match	749	1	749	\N	1.00	2026-09-06 22:42:06.816471+00
2718	match	750	1	750	\N	1.00	2026-09-06 22:42:06.816471+00
2719	match	751	1	751	\N	1.00	2026-09-06 22:42:06.816471+00
2720	match	752	1	752	\N	1.00	2026-09-06 22:42:06.816471+00
2721	match	753	1	753	\N	1.00	2026-09-06 22:42:06.816471+00
2722	match	754	1	754	\N	1.00	2026-09-06 22:42:06.816471+00
2723	match	755	1	755	\N	1.00	2026-09-06 22:42:06.816471+00
2724	match	756	1	756	\N	1.00	2026-09-06 22:42:06.816471+00
2725	match	757	1	757	\N	1.00	2026-09-06 22:42:06.816471+00
2726	match	758	1	758	\N	1.00	2026-09-06 22:42:06.816471+00
2727	match	760	1	760	\N	1.00	2026-09-06 22:42:06.816471+00
2728	match	761	1	761	\N	1.00	2026-09-06 22:42:06.816471+00
2729	match	762	1	762	\N	1.00	2026-09-06 22:42:06.816471+00
2730	match	763	1	763	\N	1.00	2026-09-06 22:42:06.816471+00
2731	match	764	1	764	\N	1.00	2026-09-06 22:42:06.816471+00
2732	match	765	1	765	\N	1.00	2026-09-06 22:42:06.816471+00
2733	match	766	1	766	\N	1.00	2026-09-06 22:42:06.816471+00
2734	match	768	1	768	\N	1.00	2026-09-06 22:42:06.816471+00
2735	match	769	1	769	\N	1.00	2026-09-06 22:42:06.816471+00
2736	match	771	1	771	\N	1.00	2026-09-06 22:42:06.816471+00
2737	match	772	1	772	\N	1.00	2026-09-06 22:42:06.816471+00
2738	match	773	1	773	\N	1.00	2026-09-06 22:42:06.816471+00
2739	match	774	1	774	\N	1.00	2026-09-06 22:42:06.816471+00
2740	match	775	1	775	\N	1.00	2026-09-06 22:42:06.816471+00
2741	match	776	1	776	\N	1.00	2026-09-06 22:42:06.816471+00
2742	match	777	1	777	\N	1.00	2026-09-06 22:42:06.816471+00
2743	match	778	1	778	\N	1.00	2026-09-06 22:42:06.816471+00
2744	match	779	1	779	\N	1.00	2026-09-06 22:42:06.816471+00
2745	match	780	1	780	\N	1.00	2026-09-06 22:42:06.816471+00
2746	match	781	1	781	\N	1.00	2026-09-06 22:42:06.816471+00
2747	match	782	1	782	\N	1.00	2026-09-06 22:42:06.816471+00
2748	match	783	1	783	\N	1.00	2026-09-06 22:42:06.816471+00
2749	match	784	1	784	\N	1.00	2026-09-06 22:42:06.816471+00
2750	match	785	1	785	\N	1.00	2026-09-06 22:42:06.816471+00
2751	match	786	1	786	\N	1.00	2026-09-06 22:42:06.816471+00
2752	match	787	1	787	\N	1.00	2026-09-06 22:42:06.816471+00
2753	match	788	1	788	\N	1.00	2026-09-06 22:42:06.816471+00
2754	match	789	1	789	\N	1.00	2026-09-06 22:42:06.816471+00
2755	match	790	1	790	\N	1.00	2026-09-06 22:42:06.816471+00
2756	match	791	1	791	\N	1.00	2026-09-06 22:42:06.816471+00
2757	match	792	1	792	\N	1.00	2026-09-06 22:42:06.816471+00
2758	match	793	1	793	\N	1.00	2026-09-06 22:42:06.816471+00
2759	match	794	1	794	\N	1.00	2026-09-06 22:42:06.816471+00
2760	match	795	1	795	\N	1.00	2026-09-06 22:42:06.816471+00
2761	match	796	1	796	\N	1.00	2026-09-06 22:42:06.816471+00
2762	match	797	1	797	\N	1.00	2026-09-06 22:42:06.816471+00
2763	match	798	1	798	\N	1.00	2026-09-06 22:42:06.816471+00
2764	match	799	1	799	\N	1.00	2026-09-06 22:42:06.816471+00
2765	match	800	1	800	\N	1.00	2026-09-06 22:42:06.816471+00
2766	match	801	1	801	\N	1.00	2026-09-06 22:42:06.816471+00
2767	match	802	1	802	\N	1.00	2026-09-06 22:42:06.816471+00
2768	match	803	1	803	\N	1.00	2026-09-06 22:42:06.816471+00
2769	match	804	1	804	\N	1.00	2026-09-06 22:42:06.816471+00
2770	match	805	1	805	\N	1.00	2026-09-06 22:42:06.816471+00
2771	match	806	1	806	\N	1.00	2026-09-06 22:42:06.816471+00
2772	match	807	1	807	\N	1.00	2026-09-06 22:42:06.816471+00
2773	match	808	1	808	\N	1.00	2026-09-06 22:42:06.816471+00
2774	match	809	1	809	\N	1.00	2026-09-06 22:42:06.816471+00
2775	match	810	1	810	\N	1.00	2026-09-06 22:42:06.816471+00
2776	match	811	1	811	\N	1.00	2026-09-06 22:42:06.816471+00
2777	match	812	1	812	\N	1.00	2026-09-06 22:42:06.816471+00
2778	match	813	1	813	\N	1.00	2026-09-06 22:42:06.816471+00
2779	match	814	1	814	\N	1.00	2026-09-06 22:42:06.816471+00
2780	match	815	1	815	\N	1.00	2026-09-06 22:42:06.816471+00
2781	match	816	1	816	\N	1.00	2026-09-06 22:42:06.816471+00
2782	match	817	1	817	\N	1.00	2026-09-06 22:42:06.816471+00
2783	match	818	1	818	\N	1.00	2026-09-06 22:42:06.816471+00
2784	match	819	1	819	\N	1.00	2026-09-06 22:42:06.816471+00
2785	match	820	1	820	\N	1.00	2026-09-06 22:42:06.816471+00
2786	match	821	1	821	\N	1.00	2026-09-06 22:42:06.816471+00
2787	match	822	1	822	\N	1.00	2026-09-06 22:42:06.816471+00
2788	match	823	1	823	\N	1.00	2026-09-06 22:42:06.816471+00
2789	match	824	1	824	\N	1.00	2026-09-06 22:42:06.816471+00
2790	match	825	1	825	\N	1.00	2026-09-06 22:42:06.816471+00
2791	match	826	1	826	\N	1.00	2026-09-06 22:42:06.816471+00
2792	match	827	1	827	\N	1.00	2026-09-06 22:42:06.816471+00
2793	match	828	1	828	\N	1.00	2026-09-06 22:42:06.816471+00
2794	match	829	1	829	\N	1.00	2026-09-06 22:42:06.816471+00
2795	match	830	1	830	\N	1.00	2026-09-06 22:42:06.816471+00
2796	match	831	1	831	\N	1.00	2026-09-06 22:42:06.816471+00
2797	match	832	1	832	\N	1.00	2026-09-06 22:42:06.816471+00
2798	match	833	1	833	\N	1.00	2026-09-06 22:42:06.816471+00
2799	match	834	1	834	\N	1.00	2026-09-06 22:42:06.816471+00
2800	match	835	1	835	\N	1.00	2026-09-06 22:42:06.816471+00
2801	match	836	1	836	\N	1.00	2026-09-06 22:42:06.816471+00
2802	match	837	1	837	\N	1.00	2026-09-06 22:42:06.816471+00
2803	match	838	1	838	\N	1.00	2026-09-06 22:42:06.816471+00
2804	match	839	1	839	\N	1.00	2026-09-06 22:42:06.816471+00
2805	match	840	1	840	\N	1.00	2026-09-06 22:42:06.816471+00
2806	match	841	1	841	\N	1.00	2026-09-06 22:42:06.816471+00
2807	match	842	1	842	\N	1.00	2026-09-06 22:42:06.816471+00
2808	match	843	1	843	\N	1.00	2026-09-06 22:42:06.816471+00
2809	match	844	1	844	\N	1.00	2026-09-06 22:42:06.816471+00
2810	match	845	1	845	\N	1.00	2026-09-06 22:42:06.816471+00
2811	match	846	1	846	\N	1.00	2026-09-06 22:42:06.816471+00
2812	match	847	1	847	\N	1.00	2026-09-06 22:42:06.816471+00
2813	match	848	1	848	\N	1.00	2026-09-06 22:42:06.816471+00
2814	match	849	1	849	\N	1.00	2026-09-06 22:42:06.816471+00
2815	match	850	1	850	\N	1.00	2026-09-06 22:42:06.816471+00
2816	match	851	1	851	\N	1.00	2026-09-06 22:42:06.816471+00
2817	match	852	1	852	\N	1.00	2026-09-06 22:42:06.816471+00
2818	match	853	1	853	\N	1.00	2026-09-06 22:42:06.816471+00
2819	match	854	1	854	\N	1.00	2026-09-06 22:42:06.816471+00
2820	match	855	1	855	\N	1.00	2026-09-06 22:42:06.816471+00
2821	match	856	1	856	\N	1.00	2026-09-06 22:42:06.816471+00
2822	match	857	1	857	\N	1.00	2026-09-06 22:42:06.816471+00
2823	match	858	1	858	\N	1.00	2026-09-06 22:42:06.816471+00
2824	match	859	1	859	\N	1.00	2026-09-06 22:42:06.816471+00
2825	match	860	1	860	\N	1.00	2026-09-06 22:42:06.816471+00
2826	match	861	1	861	\N	1.00	2026-09-06 22:42:06.816471+00
2827	match	862	1	862	\N	1.00	2026-09-06 22:42:06.816471+00
2828	match	863	1	863	\N	1.00	2026-09-06 22:42:06.816471+00
2829	match	864	1	864	\N	1.00	2026-09-06 22:42:06.816471+00
2830	match	865	1	865	\N	1.00	2026-09-06 22:42:06.816471+00
2831	match	866	1	866	\N	1.00	2026-09-06 22:42:06.816471+00
2832	match	867	1	867	\N	1.00	2026-09-06 22:42:06.816471+00
2833	match	868	1	868	\N	1.00	2026-09-06 22:42:06.816471+00
2834	match	869	1	869	\N	1.00	2026-09-06 22:42:06.816471+00
2835	match	870	1	870	\N	1.00	2026-09-06 22:42:06.816471+00
2836	match	871	1	871	\N	1.00	2026-09-06 22:42:06.816471+00
2837	match	872	1	872	\N	1.00	2026-09-06 22:42:06.816471+00
2838	match	873	1	873	\N	1.00	2026-09-06 22:42:06.816471+00
2839	match	874	1	874	\N	1.00	2026-09-06 22:42:06.816471+00
2840	match	875	1	875	\N	1.00	2026-09-06 22:42:06.816471+00
2841	match	876	1	876	\N	1.00	2026-09-06 22:42:06.816471+00
2842	match	877	1	877	\N	1.00	2026-09-06 22:42:06.816471+00
2843	match	878	1	878	\N	1.00	2026-09-06 22:42:06.816471+00
2844	match	879	1	879	\N	1.00	2026-09-06 22:42:06.816471+00
2845	match	880	1	880	\N	1.00	2026-09-06 22:42:06.816471+00
2846	match	881	1	881	\N	1.00	2026-09-06 22:42:06.816471+00
2847	match	882	1	882	\N	1.00	2026-09-06 22:42:06.816471+00
2848	match	883	1	883	\N	1.00	2026-09-06 22:42:06.816471+00
2849	match	884	1	884	\N	1.00	2026-09-06 22:42:06.816471+00
2850	match	885	1	885	\N	1.00	2026-09-06 22:42:06.816471+00
2851	match	886	1	886	\N	1.00	2026-09-06 22:42:06.816471+00
2852	match	887	1	887	\N	1.00	2026-09-06 22:42:06.816471+00
2853	match	888	1	888	\N	1.00	2026-09-06 22:42:06.816471+00
2854	match	889	1	889	\N	1.00	2026-09-06 22:42:06.816471+00
2855	match	890	1	890	\N	1.00	2026-09-06 22:42:06.816471+00
2856	match	891	1	891	\N	1.00	2026-09-06 22:42:06.816471+00
2857	match	892	1	892	\N	1.00	2026-09-06 22:42:06.816471+00
2858	match	893	1	893	\N	1.00	2026-09-06 22:42:06.816471+00
2859	match	894	1	894	\N	1.00	2026-09-06 22:42:06.816471+00
2860	match	895	1	895	\N	1.00	2026-09-06 22:42:06.816471+00
2861	match	896	1	896	\N	1.00	2026-09-06 22:42:06.816471+00
2862	match	897	1	897	\N	1.00	2026-09-06 22:42:06.816471+00
2863	match	898	1	898	\N	1.00	2026-09-06 22:42:06.816471+00
2864	match	899	1	899	\N	1.00	2026-09-06 22:42:06.816471+00
2865	match	900	1	900	\N	1.00	2026-09-06 22:42:06.816471+00
2866	match	901	1	901	\N	1.00	2026-09-06 22:42:06.816471+00
2867	match	902	1	902	\N	1.00	2026-09-06 22:42:06.816471+00
2868	match	903	1	903	\N	1.00	2026-09-06 22:42:06.816471+00
2869	match	904	1	904	\N	1.00	2026-09-06 22:42:06.816471+00
2870	match	905	1	905	\N	1.00	2026-09-06 22:42:06.816471+00
2871	match	906	1	906	\N	1.00	2026-09-06 22:42:06.816471+00
2872	match	907	1	907	\N	1.00	2026-09-06 22:42:06.816471+00
2873	match	908	1	908	\N	1.00	2026-09-06 22:42:06.816471+00
2874	match	909	1	909	\N	1.00	2026-09-06 22:42:06.816471+00
2875	match	910	1	910	\N	1.00	2026-09-06 22:42:06.816471+00
2876	match	911	1	911	\N	1.00	2026-09-06 22:42:06.816471+00
2877	match	912	1	912	\N	1.00	2026-09-06 22:42:06.816471+00
2878	match	913	1	913	\N	1.00	2026-09-06 22:42:06.816471+00
2879	match	914	1	914	\N	1.00	2026-09-06 22:42:06.816471+00
2880	match	915	1	915	\N	1.00	2026-09-06 22:42:06.816471+00
2881	match	916	1	916	\N	1.00	2026-09-06 22:42:06.816471+00
2882	match	917	1	917	\N	1.00	2026-09-06 22:42:06.816471+00
2883	match	918	1	918	\N	1.00	2026-09-06 22:42:06.816471+00
2884	match	919	1	919	\N	1.00	2026-09-06 22:42:06.816471+00
2885	match	920	1	920	\N	1.00	2026-09-06 22:42:06.816471+00
2886	match	921	1	921	\N	1.00	2026-09-06 22:42:06.816471+00
2887	match	922	1	922	\N	1.00	2026-09-06 22:42:06.816471+00
2888	match	923	1	923	\N	1.00	2026-09-06 22:42:06.816471+00
2889	match	924	1	924	\N	1.00	2026-09-06 22:42:06.816471+00
2890	match	925	1	925	\N	1.00	2026-09-06 22:42:06.816471+00
2891	match	926	1	926	\N	1.00	2026-09-06 22:42:06.816471+00
2892	match	927	1	927	\N	1.00	2026-09-06 22:42:06.816471+00
2893	match	928	1	928	\N	1.00	2026-09-06 22:42:06.816471+00
2894	match	929	1	929	\N	1.00	2026-09-06 22:42:06.816471+00
2895	match	930	1	930	\N	1.00	2026-09-06 22:42:06.816471+00
2896	match	931	1	931	\N	1.00	2026-09-06 22:42:06.816471+00
2897	match	932	1	932	\N	1.00	2026-09-06 22:42:06.816471+00
2898	match	933	1	933	\N	1.00	2026-09-06 22:42:06.816471+00
2899	match	934	1	934	\N	1.00	2026-09-06 22:42:06.816471+00
2900	match	935	1	935	\N	1.00	2026-09-06 22:42:06.816471+00
2901	match	936	1	936	\N	1.00	2026-09-06 22:42:06.816471+00
2902	match	937	1	937	\N	1.00	2026-09-06 22:42:06.816471+00
2903	match	938	1	938	\N	1.00	2026-09-06 22:42:06.816471+00
2904	match	939	1	939	\N	1.00	2026-09-06 22:42:06.816471+00
2905	match	940	1	940	\N	1.00	2026-09-06 22:42:06.816471+00
2906	match	941	1	941	\N	1.00	2026-09-06 22:42:06.816471+00
2907	match	942	1	942	\N	1.00	2026-09-06 22:42:06.816471+00
2908	match	943	1	943	\N	1.00	2026-09-06 22:42:06.816471+00
2909	match	944	1	944	\N	1.00	2026-09-06 22:42:06.816471+00
2910	match	945	1	945	\N	1.00	2026-09-06 22:42:06.816471+00
2911	match	946	1	946	\N	1.00	2026-09-06 22:42:06.816471+00
2912	match	947	1	947	\N	1.00	2026-09-06 22:42:06.816471+00
2913	match	948	1	948	\N	1.00	2026-09-06 22:42:06.816471+00
2914	match	949	1	949	\N	1.00	2026-09-06 22:42:06.816471+00
2915	match	950	1	950	\N	1.00	2026-09-06 22:42:06.816471+00
2916	match	951	1	951	\N	1.00	2026-09-06 22:42:06.816471+00
2917	match	952	1	952	\N	1.00	2026-09-06 22:42:06.816471+00
2918	match	953	1	953	\N	1.00	2026-09-06 22:42:06.816471+00
2919	match	954	1	954	\N	1.00	2026-09-06 22:42:06.816471+00
2920	match	955	1	955	\N	1.00	2026-09-06 22:42:06.816471+00
2921	match	956	1	956	\N	1.00	2026-09-06 22:42:06.816471+00
2922	match	957	1	957	\N	1.00	2026-09-06 22:42:06.816471+00
2923	match	958	1	958	\N	1.00	2026-09-06 22:42:06.816471+00
2924	match	959	1	959	\N	1.00	2026-09-06 22:42:06.816471+00
2925	match	960	1	960	\N	1.00	2026-09-06 22:42:06.816471+00
2926	match	961	1	961	\N	1.00	2026-09-06 22:42:06.816471+00
2927	match	962	1	962	\N	1.00	2026-09-06 22:42:06.816471+00
2928	match	963	1	963	\N	1.00	2026-09-06 22:42:06.816471+00
2929	match	964	1	964	\N	1.00	2026-09-06 22:42:06.816471+00
2930	match	965	1	965	\N	1.00	2026-09-06 22:42:06.816471+00
2931	match	966	1	966	\N	1.00	2026-09-06 22:42:06.816471+00
2932	match	967	1	967	\N	1.00	2026-09-06 22:42:06.816471+00
2933	match	968	1	968	\N	1.00	2026-09-06 22:42:06.816471+00
2934	match	969	1	969	\N	1.00	2026-09-06 22:42:06.816471+00
2935	match	970	1	970	\N	1.00	2026-09-06 22:42:06.816471+00
2936	match	971	1	971	\N	1.00	2026-09-06 22:42:06.816471+00
2937	match	972	1	972	\N	1.00	2026-09-06 22:42:06.816471+00
2938	match	973	1	973	\N	1.00	2026-09-06 22:42:06.816471+00
2939	match	974	1	974	\N	1.00	2026-09-06 22:42:06.816471+00
2940	match	975	1	975	\N	1.00	2026-09-06 22:42:06.816471+00
2941	match	976	1	976	\N	1.00	2026-09-06 22:42:06.816471+00
2942	match	977	1	977	\N	1.00	2026-09-06 22:42:06.816471+00
2943	match	978	1	978	\N	1.00	2026-09-06 22:42:06.816471+00
2944	match	979	1	979	\N	1.00	2026-09-06 22:42:06.816471+00
2945	match	980	1	980	\N	1.00	2026-09-06 22:42:06.816471+00
2946	match	981	1	981	\N	1.00	2026-09-06 22:42:06.816471+00
2947	match	982	1	982	\N	1.00	2026-09-06 22:42:06.816471+00
2948	match	983	1	983	\N	1.00	2026-09-06 22:42:06.816471+00
2949	match	984	1	984	\N	1.00	2026-09-06 22:42:06.816471+00
2950	match	985	1	985	\N	1.00	2026-09-06 22:42:06.816471+00
2951	match	986	1	986	\N	1.00	2026-09-06 22:42:06.816471+00
2952	match	987	1	987	\N	1.00	2026-09-06 22:42:06.816471+00
2953	match	988	1	988	\N	1.00	2026-09-06 22:42:06.816471+00
2954	match	989	1	989	\N	1.00	2026-09-06 22:42:06.816471+00
2955	match	990	1	990	\N	1.00	2026-09-06 22:42:06.816471+00
2956	match	991	1	991	\N	1.00	2026-09-06 22:42:06.816471+00
2957	match	992	1	992	\N	1.00	2026-09-06 22:42:06.816471+00
2958	match	993	1	993	\N	1.00	2026-09-06 22:42:06.816471+00
2959	match	994	1	994	\N	1.00	2026-09-06 22:42:06.816471+00
2960	match	995	1	995	\N	1.00	2026-09-06 22:42:06.816471+00
2961	match	996	1	996	\N	1.00	2026-09-06 22:42:06.816471+00
2962	match	997	1	997	\N	1.00	2026-09-06 22:42:06.816471+00
2963	match	998	1	998	\N	1.00	2026-09-06 22:42:06.816471+00
2964	match	999	1	999	\N	1.00	2026-09-06 22:42:06.816471+00
2965	match	1000	1	1000	\N	1.00	2026-09-06 22:42:06.816471+00
2966	match	1001	1	1001	\N	1.00	2026-09-06 22:42:06.816471+00
2967	match	1002	1	1002	\N	1.00	2026-09-06 22:42:06.816471+00
2968	match	1003	1	1003	\N	1.00	2026-09-06 22:42:06.816471+00
2969	match	1004	1	1004	\N	1.00	2026-09-06 22:42:06.816471+00
2970	match	1005	1	1005	\N	1.00	2026-09-06 22:42:06.816471+00
2971	match	1006	1	1006	\N	1.00	2026-09-06 22:42:06.816471+00
2972	match	1007	1	1007	\N	1.00	2026-09-06 22:42:06.816471+00
2973	match	1008	1	1008	\N	1.00	2026-09-06 22:42:06.816471+00
2974	match	1009	1	1009	\N	1.00	2026-09-06 22:42:06.816471+00
2975	match	1010	1	1010	\N	1.00	2026-09-06 22:42:06.816471+00
2976	match	1011	1	1011	\N	1.00	2026-09-06 22:42:06.816471+00
2977	match	1012	1	1012	\N	1.00	2026-09-06 22:42:06.816471+00
2978	match	1013	1	1013	\N	1.00	2026-09-06 22:42:06.816471+00
2979	match	1014	1	1014	\N	1.00	2026-09-06 22:42:06.816471+00
2980	match	1015	1	1015	\N	1.00	2026-09-06 22:42:06.816471+00
2981	match	1016	1	1016	\N	1.00	2026-09-06 22:42:06.816471+00
2982	match	1017	1	1017	\N	1.00	2026-09-06 22:42:06.816471+00
2983	match	1018	1	1018	\N	1.00	2026-09-06 22:42:06.816471+00
2984	match	1019	1	1019	\N	1.00	2026-09-06 22:42:06.816471+00
2985	match	1020	1	1020	\N	1.00	2026-09-06 22:42:06.816471+00
2986	match	1021	1	1021	\N	1.00	2026-09-06 22:42:06.816471+00
2987	match	1022	1	1022	\N	1.00	2026-09-06 22:42:06.816471+00
2988	match	1023	1	1023	\N	1.00	2026-09-06 22:42:06.816471+00
2989	match	1024	1	1024	\N	1.00	2026-09-06 22:42:06.816471+00
2990	match	1025	1	1025	\N	1.00	2026-09-06 22:42:06.816471+00
2991	match	1026	1	1026	\N	1.00	2026-09-06 22:42:06.816471+00
2992	match	1027	1	1027	\N	1.00	2026-09-06 22:42:06.816471+00
2993	match	1028	1	1028	\N	1.00	2026-09-06 22:42:06.816471+00
2994	match	1029	1	1029	\N	1.00	2026-09-06 22:42:06.816471+00
2995	match	1030	1	1030	\N	1.00	2026-09-06 22:42:06.816471+00
2996	match	1031	1	1031	\N	1.00	2026-09-06 22:42:06.816471+00
2997	match	1032	1	1032	\N	1.00	2026-09-06 22:42:06.816471+00
2998	match	1033	1	1033	\N	1.00	2026-09-06 22:42:06.816471+00
2999	match	1034	1	1034	\N	1.00	2026-09-06 22:42:06.816471+00
3000	match	1035	1	1035	\N	1.00	2026-09-06 22:42:06.816471+00
3001	match	1036	1	1036	\N	1.00	2026-09-06 22:42:06.816471+00
3002	match	1037	1	1037	\N	1.00	2026-09-06 22:42:06.816471+00
3003	match	1038	1	1038	\N	1.00	2026-09-06 22:42:06.816471+00
3004	match	1039	1	1039	\N	1.00	2026-09-06 22:42:06.816471+00
3005	match	1040	1	1040	\N	1.00	2026-09-06 22:42:06.816471+00
3006	match	1041	1	1041	\N	1.00	2026-09-06 22:42:06.816471+00
3007	match	1042	1	1042	\N	1.00	2026-09-06 22:42:06.816471+00
3008	match	1043	1	1043	\N	1.00	2026-09-06 22:42:06.816471+00
3009	match	1044	1	1044	\N	1.00	2026-09-06 22:42:06.816471+00
3010	match	1045	1	1045	\N	1.00	2026-09-06 22:42:06.816471+00
3011	match	1046	1	1046	\N	1.00	2026-09-06 22:42:06.816471+00
3012	match	1047	1	1047	\N	1.00	2026-09-06 22:42:06.816471+00
3013	match	1048	1	1048	\N	1.00	2026-09-06 22:42:06.816471+00
3014	match	1049	1	1049	\N	1.00	2026-09-06 22:42:06.816471+00
3015	match	1050	1	1050	\N	1.00	2026-09-06 22:42:06.816471+00
3016	match	1051	1	1051	\N	1.00	2026-09-06 22:42:06.816471+00
3017	match	1052	1	1052	\N	1.00	2026-09-06 22:42:06.816471+00
3018	match	1053	1	1053	\N	1.00	2026-09-06 22:42:06.816471+00
3019	match	1054	1	1054	\N	1.00	2026-09-06 22:42:06.816471+00
3020	match	1055	1	1055	\N	1.00	2026-09-06 22:42:06.816471+00
3021	match	1056	1	1056	\N	1.00	2026-09-06 22:42:06.816471+00
3022	match	1057	1	1057	\N	1.00	2026-09-06 22:42:06.816471+00
3023	match	1058	1	1058	\N	1.00	2026-09-06 22:42:06.816471+00
3024	match	1059	1	1059	\N	1.00	2026-09-06 22:42:06.816471+00
3025	match	1060	1	1060	\N	1.00	2026-09-06 22:42:06.816471+00
3026	match	1061	1	1061	\N	1.00	2026-09-06 22:42:06.816471+00
3027	match	1062	1	1062	\N	1.00	2026-09-06 22:42:06.816471+00
3028	match	1063	1	1063	\N	1.00	2026-09-06 22:42:06.816471+00
3029	match	1064	1	1064	\N	1.00	2026-09-06 22:42:06.816471+00
3030	match	1065	1	1065	\N	1.00	2026-09-06 22:42:06.816471+00
3031	match	1066	1	1066	\N	1.00	2026-09-06 22:42:06.816471+00
3032	match	1067	1	1067	\N	1.00	2026-09-06 22:42:06.816471+00
3033	match	1068	1	1068	\N	1.00	2026-09-06 22:42:06.816471+00
3034	match	1069	1	1069	\N	1.00	2026-09-06 22:42:06.816471+00
3035	match	1070	1	1070	\N	1.00	2026-09-06 22:42:06.816471+00
3036	match	1071	1	1071	\N	1.00	2026-09-06 22:42:06.816471+00
3037	match	1072	1	1072	\N	1.00	2026-09-06 22:42:06.816471+00
3038	match	1073	1	1073	\N	1.00	2026-09-06 22:42:06.816471+00
3039	match	1074	1	1074	\N	1.00	2026-09-06 22:42:06.816471+00
3040	match	1075	1	1075	\N	1.00	2026-09-06 22:42:06.816471+00
3041	match	1076	1	1076	\N	1.00	2026-09-06 22:42:06.816471+00
3042	match	1077	1	1077	\N	1.00	2026-09-06 22:42:06.816471+00
3043	match	1078	1	1078	\N	1.00	2026-09-06 22:42:06.816471+00
3044	match	1079	1	1079	\N	1.00	2026-09-06 22:42:06.816471+00
3045	match	1080	1	1080	\N	1.00	2026-09-06 22:42:06.816471+00
3046	match	1081	1	1081	\N	1.00	2026-09-06 22:42:06.816471+00
3047	match	1082	1	1082	\N	1.00	2026-09-06 22:42:06.816471+00
3048	match	1083	1	1083	\N	1.00	2026-09-06 22:42:06.816471+00
3049	match	1084	1	1084	\N	1.00	2026-09-06 22:42:06.816471+00
3050	match	1085	1	1085	\N	1.00	2026-09-06 22:42:06.816471+00
3051	match	1086	1	1086	\N	1.00	2026-09-06 22:42:06.816471+00
3052	match	1087	1	1087	\N	1.00	2026-09-06 22:42:06.816471+00
3053	match	1088	1	1088	\N	1.00	2026-09-06 22:42:06.816471+00
3054	match	1089	1	1089	\N	1.00	2026-09-06 22:42:06.816471+00
3055	match	1090	1	1090	\N	1.00	2026-09-06 22:42:06.816471+00
3056	match	1091	1	1091	\N	1.00	2026-09-06 22:42:06.816471+00
3057	match	1092	1	1092	\N	1.00	2026-09-06 22:42:06.816471+00
3058	match	1093	1	1093	\N	1.00	2026-09-06 22:42:06.816471+00
3059	match	1094	1	1094	\N	1.00	2026-09-06 22:42:06.816471+00
3060	match	1095	1	1095	\N	1.00	2026-09-06 22:42:06.816471+00
3061	match	1096	1	1096	\N	1.00	2026-09-06 22:42:06.816471+00
3062	match	1097	1	1097	\N	1.00	2026-09-06 22:42:06.816471+00
3063	match	1098	1	1098	\N	1.00	2026-09-06 22:42:06.816471+00
3064	match	1099	1	1099	\N	1.00	2026-09-06 22:42:06.816471+00
3065	match	1100	1	1100	\N	1.00	2026-09-06 22:42:06.816471+00
3066	match	1101	1	1101	\N	1.00	2026-09-06 22:42:06.816471+00
3067	match	1102	1	1102	\N	1.00	2026-09-06 22:42:06.816471+00
3068	match	1103	1	1103	\N	1.00	2026-09-06 22:42:06.816471+00
3069	match	1104	1	1104	\N	1.00	2026-09-06 22:42:06.816471+00
3070	match	1105	1	1105	\N	1.00	2026-09-06 22:42:06.816471+00
3071	match	1106	1	1106	\N	1.00	2026-09-06 22:42:06.816471+00
3072	match	1107	1	1107	\N	1.00	2026-09-06 22:42:06.816471+00
3073	match	1108	1	1108	\N	1.00	2026-09-06 22:42:06.816471+00
3074	match	1109	1	1109	\N	1.00	2026-09-06 22:42:06.816471+00
3075	match	1110	1	1110	\N	1.00	2026-09-06 22:42:06.816471+00
3076	match	1111	1	1111	\N	1.00	2026-09-06 22:42:06.816471+00
3077	match	1112	1	1112	\N	1.00	2026-09-06 22:42:06.816471+00
3078	match	1113	1	1113	\N	1.00	2026-09-06 22:42:06.816471+00
3079	match	1114	1	1114	\N	1.00	2026-09-06 22:42:06.816471+00
3080	match	1115	1	1115	\N	1.00	2026-09-06 22:42:06.816471+00
3081	match	1116	1	1116	\N	1.00	2026-09-06 22:42:06.816471+00
3082	match	1117	1	1117	\N	1.00	2026-09-06 22:42:06.816471+00
3083	match	1118	1	1118	\N	1.00	2026-09-06 22:42:06.816471+00
3084	match	1119	1	1119	\N	1.00	2026-09-06 22:42:06.816471+00
3085	match	1120	1	1120	\N	1.00	2026-09-06 22:42:06.816471+00
3086	match	1121	1	1121	\N	1.00	2026-09-06 22:42:06.816471+00
3087	match	1122	1	1122	\N	1.00	2026-09-06 22:42:06.816471+00
3088	match	1123	1	1123	\N	1.00	2026-09-06 22:42:06.816471+00
3089	match	1124	1	1124	\N	1.00	2026-09-06 22:42:06.816471+00
3090	match	1125	1	1125	\N	1.00	2026-09-06 22:42:06.816471+00
3091	match	1126	1	1126	\N	1.00	2026-09-06 22:42:06.816471+00
3092	match	1127	1	1127	\N	1.00	2026-09-06 22:42:06.816471+00
3093	match	1128	1	1128	\N	1.00	2026-09-06 22:42:06.816471+00
3094	match	1129	1	1129	\N	1.00	2026-09-06 22:42:06.816471+00
3095	match	1130	1	1130	\N	1.00	2026-09-06 22:42:06.816471+00
3096	match	1131	1	1131	\N	1.00	2026-09-06 22:42:06.816471+00
3097	match	1132	1	1132	\N	1.00	2026-09-06 22:42:06.816471+00
3098	match	1133	1	1133	\N	1.00	2026-09-06 22:42:06.816471+00
3099	match	1134	1	1134	\N	1.00	2026-09-06 22:42:06.816471+00
3100	match	1135	1	1135	\N	1.00	2026-09-06 22:42:06.816471+00
3101	match	1136	1	1136	\N	1.00	2026-09-06 22:42:06.816471+00
3102	match	1137	1	1137	\N	1.00	2026-09-06 22:42:06.816471+00
3103	match	1138	1	1138	\N	1.00	2026-09-06 22:42:06.816471+00
3104	match	1139	1	1139	\N	1.00	2026-09-06 22:42:06.816471+00
3105	match	1140	1	1140	\N	1.00	2026-09-06 22:42:06.816471+00
3106	match	1141	1	1141	\N	1.00	2026-09-06 22:42:06.816471+00
3107	match	1142	1	1142	\N	1.00	2026-09-06 22:42:06.816471+00
3108	match	1143	1	1143	\N	1.00	2026-09-06 22:42:06.816471+00
3109	match	1144	1	1144	\N	1.00	2026-09-06 22:42:06.816471+00
3110	match	1145	1	1145	\N	1.00	2026-09-06 22:42:06.816471+00
3111	match	1146	1	1146	\N	1.00	2026-09-06 22:42:06.816471+00
3112	match	1147	1	1147	\N	1.00	2026-09-06 22:42:06.816471+00
3113	match	1148	1	1148	\N	1.00	2026-09-06 22:42:06.816471+00
3114	match	1149	1	1149	\N	1.00	2026-09-06 22:42:06.816471+00
3115	match	1150	1	1150	\N	1.00	2026-09-06 22:42:06.816471+00
3116	match	1151	1	1151	\N	1.00	2026-09-06 22:42:06.816471+00
3117	match	1152	1	1152	\N	1.00	2026-09-06 22:42:06.816471+00
3118	match	1153	1	1153	\N	1.00	2026-09-06 22:42:06.816471+00
3119	match	1154	1	1154	\N	1.00	2026-09-06 22:42:06.816471+00
3120	match	1155	1	1155	\N	1.00	2026-09-06 22:42:06.816471+00
3121	match	1156	1	1156	\N	1.00	2026-09-06 22:42:06.816471+00
3122	match	1157	1	1157	\N	1.00	2026-09-06 22:42:06.816471+00
3123	match	1158	1	1158	\N	1.00	2026-09-06 22:42:06.816471+00
3124	match	1159	1	1159	\N	1.00	2026-09-06 22:42:06.816471+00
3125	match	1160	1	1160	\N	1.00	2026-09-06 22:42:06.816471+00
3126	match	1161	1	1161	\N	1.00	2026-09-06 22:42:06.816471+00
3127	match	1162	1	1162	\N	1.00	2026-09-06 22:42:06.816471+00
3128	match	1163	1	1163	\N	1.00	2026-09-06 22:42:06.816471+00
3129	match	1164	1	1164	\N	1.00	2026-09-06 22:42:06.816471+00
3130	match	1165	1	1165	\N	1.00	2026-09-06 22:42:06.816471+00
3131	match	1166	1	1166	\N	1.00	2026-09-06 22:42:06.816471+00
3132	match	1167	1	1167	\N	1.00	2026-09-06 22:42:06.816471+00
3133	match	1168	1	1168	\N	1.00	2026-09-06 22:42:06.816471+00
3134	match	1169	1	1169	\N	1.00	2026-09-06 22:42:06.816471+00
3135	match	1170	1	1170	\N	1.00	2026-09-06 22:42:06.816471+00
3136	match	1171	1	1171	\N	1.00	2026-09-06 22:42:06.816471+00
3137	match	1172	1	1172	\N	1.00	2026-09-06 22:42:06.816471+00
3138	match	1173	1	1173	\N	1.00	2026-09-06 22:42:06.816471+00
3139	match	1174	1	1174	\N	1.00	2026-09-06 22:42:06.816471+00
3140	match	1175	1	1175	\N	1.00	2026-09-06 22:42:06.816471+00
3141	match	1176	1	1176	\N	1.00	2026-09-06 22:42:06.816471+00
3142	match	1177	1	1177	\N	1.00	2026-09-06 22:42:06.816471+00
3143	match	1178	1	1178	\N	1.00	2026-09-06 22:42:06.816471+00
3144	match	1179	1	1179	\N	1.00	2026-09-06 22:42:06.816471+00
3145	match	1180	1	1180	\N	1.00	2026-09-06 22:42:06.816471+00
3146	match	1181	1	1181	\N	1.00	2026-09-06 22:42:06.816471+00
3147	match	1182	1	1182	\N	1.00	2026-09-06 22:42:06.816471+00
3148	match	1183	1	1183	\N	1.00	2026-09-06 22:42:06.816471+00
3149	match	1184	1	1184	\N	1.00	2026-09-06 22:42:06.816471+00
3150	match	1185	1	1185	\N	1.00	2026-09-06 22:42:06.816471+00
3151	match	1186	1	1186	\N	1.00	2026-09-06 22:42:06.816471+00
3152	match	1187	1	1187	\N	1.00	2026-09-06 22:42:06.816471+00
3153	match	1188	1	1188	\N	1.00	2026-09-06 22:42:06.816471+00
3154	match	1189	1	1189	\N	1.00	2026-09-06 22:42:06.816471+00
3155	match	1190	1	1190	\N	1.00	2026-09-06 22:42:06.816471+00
3156	match	1191	1	1191	\N	1.00	2026-09-06 22:42:06.816471+00
3157	match	1192	1	1192	\N	1.00	2026-09-06 22:42:06.816471+00
3158	match	1193	1	1193	\N	1.00	2026-09-06 22:42:06.816471+00
3159	match	1194	1	1194	\N	1.00	2026-09-06 22:42:06.816471+00
3160	match	1195	1	1195	\N	1.00	2026-09-06 22:42:06.816471+00
3161	match	1196	1	1196	\N	1.00	2026-09-06 22:42:06.816471+00
3162	match	1197	1	1197	\N	1.00	2026-09-06 22:42:06.816471+00
3163	match	1198	1	1198	\N	1.00	2026-09-06 22:42:06.816471+00
3164	match	1199	1	1199	\N	1.00	2026-09-06 22:42:06.816471+00
3165	match	1200	1	1200	\N	1.00	2026-09-06 22:42:06.816471+00
3166	match	1201	1	1201	\N	1.00	2026-09-06 22:42:06.816471+00
3167	match	1202	1	1202	\N	1.00	2026-09-06 22:42:06.816471+00
3168	match	1203	1	1203	\N	1.00	2026-09-06 22:42:06.816471+00
3169	match	1204	1	1204	\N	1.00	2026-09-06 22:42:06.816471+00
3170	match	1205	1	1205	\N	1.00	2026-09-06 22:42:06.816471+00
3171	match	1206	1	1206	\N	1.00	2026-09-06 22:42:06.816471+00
3172	match	1207	1	1207	\N	1.00	2026-09-06 22:42:06.816471+00
3173	match	1208	1	1208	\N	1.00	2026-09-06 22:42:06.816471+00
3174	match	1209	1	1209	\N	1.00	2026-09-06 22:42:06.816471+00
3175	match	1210	1	1210	\N	1.00	2026-09-06 22:42:06.816471+00
3176	match	1211	1	1211	\N	1.00	2026-09-06 22:42:06.816471+00
3177	match	1212	1	1212	\N	1.00	2026-09-06 22:42:06.816471+00
3178	match	1213	1	1213	\N	1.00	2026-09-06 22:42:06.816471+00
3179	match	1214	1	1214	\N	1.00	2026-09-06 22:42:06.816471+00
3180	match	1215	1	1215	\N	1.00	2026-09-06 22:42:06.816471+00
3181	match	1216	1	1216	\N	1.00	2026-09-06 22:42:06.816471+00
3182	match	1217	1	1217	\N	1.00	2026-09-06 22:42:06.816471+00
3183	match	1218	1	1218	\N	1.00	2026-09-06 22:42:06.816471+00
3184	match	1219	1	1219	\N	1.00	2026-09-06 22:42:06.816471+00
3185	match	1220	1	1220	\N	1.00	2026-09-06 22:42:06.816471+00
3186	match	1221	1	1221	\N	1.00	2026-09-06 22:42:06.816471+00
3187	match	1222	1	1222	\N	1.00	2026-09-06 22:42:06.816471+00
3188	match	1223	1	1223	\N	1.00	2026-09-06 22:42:06.816471+00
3189	match	1224	1	1224	\N	1.00	2026-09-06 22:42:06.816471+00
3190	match	1225	1	1225	\N	1.00	2026-09-06 22:42:06.816471+00
3191	match	1226	1	1226	\N	1.00	2026-09-06 22:42:06.816471+00
3192	match	1227	1	1227	\N	1.00	2026-09-06 22:42:06.816471+00
3193	match	1228	1	1228	\N	1.00	2026-09-06 22:42:06.816471+00
3194	match	1229	1	1229	\N	1.00	2026-09-06 22:42:06.816471+00
3195	match	1230	1	1230	\N	1.00	2026-09-06 22:42:06.816471+00
3196	match	1231	1	1231	\N	1.00	2026-09-06 22:42:06.816471+00
3197	match	1232	1	1232	\N	1.00	2026-09-06 22:42:06.816471+00
3198	match	1233	1	1233	\N	1.00	2026-09-06 22:42:06.816471+00
3199	match	1234	1	1234	\N	1.00	2026-09-06 22:42:06.816471+00
3200	match	1235	1	1235	\N	1.00	2026-09-06 22:42:06.816471+00
3201	match	1236	1	1236	\N	1.00	2026-09-06 22:42:06.816471+00
3202	match	1237	1	1237	\N	1.00	2026-09-06 22:42:06.816471+00
3203	match	1238	1	1238	\N	1.00	2026-09-06 22:42:06.816471+00
3204	match	1239	1	1239	\N	1.00	2026-09-06 22:42:06.816471+00
3205	match	1240	1	1240	\N	1.00	2026-09-06 22:42:06.816471+00
3206	match	1241	1	1241	\N	1.00	2026-09-06 22:42:06.816471+00
3207	match	1242	1	1242	\N	1.00	2026-09-06 22:42:06.816471+00
3208	match	1243	1	1243	\N	1.00	2026-09-06 22:42:06.816471+00
3209	match	1244	1	1244	\N	1.00	2026-09-06 22:42:06.816471+00
3210	match	1245	1	1245	\N	1.00	2026-09-06 22:42:06.816471+00
3211	match	1246	1	1246	\N	1.00	2026-09-06 22:42:06.816471+00
3212	match	1247	1	1247	\N	1.00	2026-09-06 22:42:06.816471+00
3213	match	1248	1	1248	\N	1.00	2026-09-06 22:42:06.816471+00
3214	match	1249	1	1249	\N	1.00	2026-09-06 22:42:06.816471+00
3215	match	1250	1	1250	\N	1.00	2026-09-06 22:42:06.816471+00
3216	match	1251	1	1251	\N	1.00	2026-09-06 22:42:06.816471+00
3217	match	1252	1	1252	\N	1.00	2026-09-06 22:42:06.816471+00
3218	match	1253	1	1253	\N	1.00	2026-09-06 22:42:06.816471+00
3219	match	1254	1	1254	\N	1.00	2026-09-06 22:42:06.816471+00
3220	match	1255	1	1255	\N	1.00	2026-09-06 22:42:06.816471+00
3221	match	1256	1	1256	\N	1.00	2026-09-06 22:42:06.816471+00
3222	match	1257	1	1257	\N	1.00	2026-09-06 22:42:06.816471+00
3223	match	1258	1	1258	\N	1.00	2026-09-06 22:42:06.816471+00
3224	match	1259	1	1259	\N	1.00	2026-09-06 22:42:06.816471+00
3225	match	1260	1	1260	\N	1.00	2026-09-06 22:42:06.816471+00
3226	match	1261	1	1261	\N	1.00	2026-09-06 22:42:06.816471+00
3227	match	1262	1	1262	\N	1.00	2026-09-06 22:42:06.816471+00
3228	match	1263	1	1263	\N	1.00	2026-09-06 22:42:06.816471+00
3229	match	1264	1	1264	\N	1.00	2026-09-06 22:42:06.816471+00
3230	match	1265	1	1265	\N	1.00	2026-09-06 22:42:06.816471+00
3231	match	1266	1	1266	\N	1.00	2026-09-06 22:42:06.816471+00
3232	match	1267	1	1267	\N	1.00	2026-09-06 22:42:06.816471+00
3233	match	1268	1	1268	\N	1.00	2026-09-06 22:42:06.816471+00
3234	match	1269	1	1269	\N	1.00	2026-09-06 22:42:06.816471+00
3235	match	1270	1	1270	\N	1.00	2026-09-06 22:42:06.816471+00
3236	match	1271	1	1271	\N	1.00	2026-09-06 22:42:06.816471+00
3237	match	1272	1	1272	\N	1.00	2026-09-06 22:42:06.816471+00
3238	match	1273	1	1273	\N	1.00	2026-09-06 22:42:06.816471+00
3239	match	1274	1	1274	\N	1.00	2026-09-06 22:42:06.816471+00
3240	match	1275	1	1275	\N	1.00	2026-09-06 22:42:06.816471+00
3241	match	1276	1	1276	\N	1.00	2026-09-06 22:42:06.816471+00
3242	match	1277	1	1277	\N	1.00	2026-09-06 22:42:06.816471+00
3243	match	1278	1	1278	\N	1.00	2026-09-06 22:42:06.816471+00
3244	match	1279	1	1279	\N	1.00	2026-09-06 22:42:06.816471+00
3245	match	1280	1	1280	\N	1.00	2026-09-06 22:42:06.816471+00
3246	match	1281	1	1281	\N	1.00	2026-09-06 22:42:06.816471+00
3247	match	1282	1	1282	\N	1.00	2026-09-06 22:42:06.816471+00
3248	match	1283	1	1283	\N	1.00	2026-09-06 22:42:06.816471+00
3249	match	1284	1	1284	\N	1.00	2026-09-06 22:42:06.816471+00
3250	match	1285	1	1285	\N	1.00	2026-09-06 22:42:06.816471+00
3251	match	1286	1	1286	\N	1.00	2026-09-06 22:42:06.816471+00
3252	match	1287	1	1287	\N	1.00	2026-09-06 22:42:06.816471+00
3253	match	1288	1	1288	\N	1.00	2026-09-06 22:42:06.816471+00
3254	match	1289	1	1289	\N	1.00	2026-09-06 22:42:06.816471+00
3255	match	1290	1	1290	\N	1.00	2026-09-06 22:42:06.816471+00
3256	match	1291	1	1291	\N	1.00	2026-09-06 22:42:06.816471+00
3257	match	1292	1	1292	\N	1.00	2026-09-06 22:42:06.816471+00
3258	match	1293	1	1293	\N	1.00	2026-09-06 22:42:06.816471+00
3259	match	1294	1	1294	\N	1.00	2026-09-06 22:42:06.816471+00
3260	match	1295	1	1295	\N	1.00	2026-09-06 22:42:06.816471+00
3261	match	1296	1	1296	\N	1.00	2026-09-06 22:42:06.816471+00
3262	match	1297	1	1297	\N	1.00	2026-09-06 22:42:06.816471+00
3263	match	1298	1	1298	\N	1.00	2026-09-06 22:42:06.816471+00
3264	match	1299	1	1299	\N	1.00	2026-09-06 22:42:06.816471+00
3265	match	1300	1	1300	\N	1.00	2026-09-06 22:42:06.816471+00
3266	match	1301	1	1301	\N	1.00	2026-09-06 22:42:06.816471+00
3267	match	1302	1	1302	\N	1.00	2026-09-06 22:42:06.816471+00
3268	match	1303	1	1303	\N	1.00	2026-09-06 22:42:06.816471+00
3269	match	1304	1	1304	\N	1.00	2026-09-06 22:42:06.816471+00
3270	match	1305	1	1305	\N	1.00	2026-09-06 22:42:06.816471+00
3271	match	1306	1	1306	\N	1.00	2026-09-06 22:42:06.816471+00
3272	match	1307	1	1307	\N	1.00	2026-09-06 22:42:06.816471+00
3273	match	1308	1	1308	\N	1.00	2026-09-06 22:42:06.816471+00
3274	match	1309	1	1309	\N	1.00	2026-09-06 22:42:06.816471+00
3275	match	1310	1	1310	\N	1.00	2026-09-06 22:42:06.816471+00
3276	match	1311	1	1311	\N	1.00	2026-09-06 22:42:06.816471+00
3277	match	1312	1	1312	\N	1.00	2026-09-06 22:42:06.816471+00
3278	match	1313	1	1313	\N	1.00	2026-09-06 22:42:06.816471+00
3279	match	1314	1	1314	\N	1.00	2026-09-06 22:42:06.816471+00
3280	match	1315	1	1315	\N	1.00	2026-09-06 22:42:06.816471+00
3281	match	1316	1	1316	\N	1.00	2026-09-06 22:42:06.816471+00
3282	match	1317	1	1317	\N	1.00	2026-09-06 22:42:06.816471+00
3283	match	1318	1	1318	\N	1.00	2026-09-06 22:42:06.816471+00
3284	match	1319	1	1319	\N	1.00	2026-09-06 22:42:06.816471+00
3285	match	1320	1	1320	\N	1.00	2026-09-06 22:42:06.816471+00
3286	match	1321	1	1321	\N	1.00	2026-09-06 22:42:06.816471+00
3287	match	1322	1	1322	\N	1.00	2026-09-06 22:42:06.816471+00
3288	match	1323	1	1323	\N	1.00	2026-09-06 22:42:06.816471+00
3289	match	1324	1	1324	\N	1.00	2026-09-06 22:42:06.816471+00
3290	match	1325	1	1325	\N	1.00	2026-09-06 22:42:06.816471+00
3291	match	1326	1	1326	\N	1.00	2026-09-06 22:42:06.816471+00
3292	match	1327	1	1327	\N	1.00	2026-09-06 22:42:06.816471+00
3293	match	1328	1	1328	\N	1.00	2026-09-06 22:42:06.816471+00
3294	match	1329	1	1329	\N	1.00	2026-09-06 22:42:06.816471+00
3295	match	1330	1	1330	\N	1.00	2026-09-06 22:42:06.816471+00
3296	match	1331	1	1331	\N	1.00	2026-09-06 22:42:06.816471+00
3297	match	1332	1	1332	\N	1.00	2026-09-06 22:42:06.816471+00
3298	match	1333	1	1333	\N	1.00	2026-09-06 22:42:06.816471+00
3299	match	1334	1	1334	\N	1.00	2026-09-06 22:42:06.816471+00
3300	match	1335	1	1335	\N	1.00	2026-09-06 22:42:06.816471+00
3301	match	1336	1	1336	\N	1.00	2026-09-06 22:42:06.816471+00
3302	match	1337	1	1337	\N	1.00	2026-09-06 22:42:06.816471+00
3303	match	1338	1	1338	\N	1.00	2026-09-06 22:42:06.816471+00
3304	match	1339	1	1339	\N	1.00	2026-09-06 22:42:06.816471+00
3305	match	1340	1	1340	\N	1.00	2026-09-06 22:42:06.816471+00
3306	match	1341	1	1341	\N	1.00	2026-09-06 22:42:06.816471+00
3307	match	1342	1	1342	\N	1.00	2026-09-06 22:42:06.816471+00
3308	match	1343	1	1343	\N	1.00	2026-09-06 22:42:06.816471+00
3309	match	1344	1	1344	\N	1.00	2026-09-06 22:42:06.816471+00
3310	match	1345	1	1345	\N	1.00	2026-09-06 22:42:06.816471+00
3311	match	1346	1	1346	\N	1.00	2026-09-06 22:42:06.816471+00
3312	match	1347	1	1347	\N	1.00	2026-09-06 22:42:06.816471+00
3313	match	1348	1	1348	\N	1.00	2026-09-06 22:42:06.816471+00
3314	match	1349	1	1349	\N	1.00	2026-09-06 22:42:06.816471+00
3315	match	1350	1	1350	\N	1.00	2026-09-06 22:42:06.816471+00
3316	match	1351	1	1351	\N	1.00	2026-09-06 22:42:06.816471+00
3317	match	1352	1	1352	\N	1.00	2026-09-06 22:42:06.816471+00
3318	match	1353	1	1353	\N	1.00	2026-09-06 22:42:06.816471+00
3319	match	1354	1	1354	\N	1.00	2026-09-06 22:42:06.816471+00
3320	match	1355	1	1355	\N	1.00	2026-09-06 22:42:06.816471+00
3321	match	1356	1	1356	\N	1.00	2026-09-06 22:42:06.816471+00
3322	match	1357	1	1357	\N	1.00	2026-09-06 22:42:06.816471+00
3323	match	1358	1	1358	\N	1.00	2026-09-06 22:42:06.816471+00
3324	match	1359	1	1359	\N	1.00	2026-09-06 22:42:06.816471+00
3325	match	1360	1	1360	\N	1.00	2026-09-06 22:42:06.816471+00
3326	match	1361	1	1361	\N	1.00	2026-09-06 22:42:06.816471+00
3327	match	1362	1	1362	\N	1.00	2026-09-06 22:42:06.816471+00
3328	match	1363	1	1363	\N	1.00	2026-09-06 22:42:06.816471+00
3329	match	1364	1	1364	\N	1.00	2026-09-06 22:42:06.816471+00
3330	match	1365	1	1365	\N	1.00	2026-09-06 22:42:06.816471+00
3331	match	1366	1	1366	\N	1.00	2026-09-06 22:42:06.816471+00
3332	match	1367	1	1367	\N	1.00	2026-09-06 22:42:06.816471+00
3333	match	1368	1	1368	\N	1.00	2026-09-06 22:42:06.816471+00
3334	match	1369	1	1369	\N	1.00	2026-09-06 22:42:06.816471+00
3335	match	1370	1	1370	\N	1.00	2026-09-06 22:42:06.816471+00
3336	match	1371	1	1371	\N	1.00	2026-09-06 22:42:06.816471+00
3337	match	1372	1	1372	\N	1.00	2026-09-06 22:42:06.816471+00
3338	match	1373	1	1373	\N	1.00	2026-09-06 22:42:06.816471+00
3339	match	1374	1	1374	\N	1.00	2026-09-06 22:42:06.816471+00
3340	match	1375	1	1375	\N	1.00	2026-09-06 22:42:06.816471+00
3341	match	1376	1	1376	\N	1.00	2026-09-06 22:42:06.816471+00
3342	match	1377	1	1377	\N	1.00	2026-09-06 22:42:06.816471+00
3343	match	1378	1	1378	\N	1.00	2026-09-06 22:42:06.816471+00
3344	match	1379	1	1379	\N	1.00	2026-09-06 22:42:06.816471+00
3345	match	1380	1	1380	\N	1.00	2026-09-06 22:42:06.816471+00
3346	match	1381	1	1381	\N	1.00	2026-09-06 22:42:06.816471+00
3347	match	1382	1	1382	\N	1.00	2026-09-06 22:42:06.816471+00
3348	match	1383	1	1383	\N	1.00	2026-09-06 22:42:06.816471+00
3349	match	1384	1	1384	\N	1.00	2026-09-06 22:42:06.816471+00
3350	match	1385	1	1385	\N	1.00	2026-09-06 22:42:06.816471+00
3351	match	1386	1	1386	\N	1.00	2026-09-06 22:42:06.816471+00
3352	match	1387	1	1387	\N	1.00	2026-09-06 22:42:06.816471+00
3353	match	1388	1	1388	\N	1.00	2026-09-06 22:42:06.816471+00
3354	match	1389	1	1389	\N	1.00	2026-09-06 22:42:06.816471+00
3355	match	1390	1	1390	\N	1.00	2026-09-06 22:42:06.816471+00
3356	match	1391	1	1391	\N	1.00	2026-09-06 22:42:06.816471+00
3357	match	1392	1	1392	\N	1.00	2026-09-06 22:42:06.816471+00
3358	match	1393	1	1393	\N	1.00	2026-09-06 22:42:06.816471+00
3359	match	1394	1	1394	\N	1.00	2026-09-06 22:42:06.816471+00
3360	match	1395	1	1395	\N	1.00	2026-09-06 22:42:06.816471+00
3361	match	1396	1	1396	\N	1.00	2026-09-06 22:42:06.816471+00
3362	match	1397	1	1397	\N	1.00	2026-09-06 22:42:06.816471+00
3363	match	1398	1	1398	\N	1.00	2026-09-06 22:42:06.816471+00
3364	match	1399	1	1399	\N	1.00	2026-09-06 22:42:06.816471+00
3365	match	1400	1	1400	\N	1.00	2026-09-06 22:42:06.816471+00
3366	match	1401	1	1401	\N	1.00	2026-09-06 22:42:06.816471+00
3367	match	1402	1	1402	\N	1.00	2026-09-06 22:42:06.816471+00
3368	match	1403	1	1403	\N	1.00	2026-09-06 22:42:06.816471+00
3369	match	1404	1	1404	\N	1.00	2026-09-06 22:42:06.816471+00
3370	match	1405	1	1405	\N	1.00	2026-09-06 22:42:06.816471+00
3371	match	1406	1	1406	\N	1.00	2026-09-06 22:42:06.816471+00
3372	match	1407	1	1407	\N	1.00	2026-09-06 22:42:06.816471+00
3373	match	1408	1	1408	\N	1.00	2026-09-06 22:42:06.816471+00
3374	match	1409	1	1409	\N	1.00	2026-09-06 22:42:06.816471+00
3375	match	1410	1	1410	\N	1.00	2026-09-06 22:42:06.816471+00
3376	match	1411	1	1411	\N	1.00	2026-09-06 22:42:06.816471+00
3377	match	1412	1	1412	\N	1.00	2026-09-06 22:42:06.816471+00
3378	match	1413	1	1413	\N	1.00	2026-09-06 22:42:06.816471+00
3379	match	1414	1	1414	\N	1.00	2026-09-06 22:42:06.816471+00
3380	match	1415	1	1415	\N	1.00	2026-09-06 22:42:06.816471+00
3381	match	1416	1	1416	\N	1.00	2026-09-06 22:42:06.816471+00
3382	match	1417	1	1417	\N	1.00	2026-09-06 22:42:06.816471+00
3383	match	1418	1	1418	\N	1.00	2026-09-06 22:42:06.816471+00
3384	match	1419	1	1419	\N	1.00	2026-09-06 22:42:06.816471+00
3385	match	1420	1	1420	\N	1.00	2026-09-06 22:42:06.816471+00
3386	match	1421	1	1421	\N	1.00	2026-09-06 22:42:06.816471+00
3387	match	1422	1	1422	\N	1.00	2026-09-06 22:42:06.816471+00
3388	match	1423	1	1423	\N	1.00	2026-09-06 22:42:06.816471+00
3389	match	1424	1	1424	\N	1.00	2026-09-06 22:42:06.816471+00
3390	match	1425	1	1425	\N	1.00	2026-09-06 22:42:06.816471+00
3391	match	1426	1	1426	\N	1.00	2026-09-06 22:42:06.816471+00
3392	match	1427	1	1427	\N	1.00	2026-09-06 22:42:06.816471+00
3393	match	1428	1	1428	\N	1.00	2026-09-06 22:42:06.816471+00
3394	match	1429	1	1429	\N	1.00	2026-09-06 22:42:06.816471+00
3395	match	1430	1	1430	\N	1.00	2026-09-06 22:42:06.816471+00
3396	match	1431	1	1431	\N	1.00	2026-09-06 22:42:06.816471+00
3397	match	1432	1	1432	\N	1.00	2026-09-06 22:42:06.816471+00
3398	match	1433	1	1433	\N	1.00	2026-09-06 22:42:06.816471+00
3399	match	1434	1	1434	\N	1.00	2026-09-06 22:42:06.816471+00
3400	match	1435	1	1435	\N	1.00	2026-09-06 22:42:06.816471+00
3401	match	1436	1	1436	\N	1.00	2026-09-06 22:42:06.816471+00
3402	match	1437	1	1437	\N	1.00	2026-09-06 22:42:06.816471+00
3403	match	1438	1	1438	\N	1.00	2026-09-06 22:42:06.816471+00
3404	match	1439	1	1439	\N	1.00	2026-09-06 22:42:06.816471+00
3405	match	1440	1	1440	\N	1.00	2026-09-06 22:42:06.816471+00
3406	match	1441	1	1441	\N	1.00	2026-09-06 22:42:06.816471+00
3407	match	1442	1	1442	\N	1.00	2026-09-06 22:42:06.816471+00
3408	match	1443	1	1443	\N	1.00	2026-09-06 22:42:06.816471+00
3409	match	1444	1	1444	\N	1.00	2026-09-06 22:42:06.816471+00
3410	match	1445	1	1445	\N	1.00	2026-09-06 22:42:06.816471+00
3411	match	1446	1	1446	\N	1.00	2026-09-06 22:42:06.816471+00
3412	match	1447	1	1447	\N	1.00	2026-09-06 22:42:06.816471+00
3413	match	1448	1	1448	\N	1.00	2026-09-06 22:42:06.816471+00
3414	match	1449	1	1449	\N	1.00	2026-09-06 22:42:06.816471+00
3415	match	1450	1	1450	\N	1.00	2026-09-06 22:42:06.816471+00
3416	match	1451	1	1451	\N	1.00	2026-09-06 22:42:06.816471+00
3417	match	1452	1	1452	\N	1.00	2026-09-06 22:42:06.816471+00
3418	match	1453	1	1453	\N	1.00	2026-09-06 22:42:06.816471+00
3419	match	1454	1	1454	\N	1.00	2026-09-06 22:42:06.816471+00
3420	match	1455	1	1455	\N	1.00	2026-09-06 22:42:06.816471+00
3421	match	1456	1	1456	\N	1.00	2026-09-06 22:42:06.816471+00
3422	match	1457	1	1457	\N	1.00	2026-09-06 22:42:06.816471+00
3423	match	1458	1	1458	\N	1.00	2026-09-06 22:42:06.816471+00
3424	match	1459	1	1459	\N	1.00	2026-09-06 22:42:06.816471+00
3425	match	1460	1	1460	\N	1.00	2026-09-06 22:42:06.816471+00
3426	match	1461	1	1461	\N	1.00	2026-09-06 22:42:06.816471+00
3427	match	1462	1	1462	\N	1.00	2026-09-06 22:42:06.816471+00
3428	match	1463	1	1463	\N	1.00	2026-09-06 22:42:06.816471+00
3429	match	1464	1	1464	\N	1.00	2026-09-06 22:42:06.816471+00
3430	match	1465	1	1465	\N	1.00	2026-09-06 22:42:06.816471+00
3431	match	1466	1	1466	\N	1.00	2026-09-06 22:42:06.816471+00
3432	match	1467	1	1467	\N	1.00	2026-09-06 22:42:06.816471+00
3433	match	1468	1	1468	\N	1.00	2026-09-06 22:42:06.816471+00
3434	match	1469	1	1469	\N	1.00	2026-09-06 22:42:06.816471+00
3435	match	1470	1	1470	\N	1.00	2026-09-06 22:42:06.816471+00
3436	match	1471	1	1471	\N	1.00	2026-09-06 22:42:06.816471+00
3437	match	1472	1	1472	\N	1.00	2026-09-06 22:42:06.816471+00
3438	match	1473	1	1473	\N	1.00	2026-09-06 22:42:06.816471+00
3439	match	1474	1	1474	\N	1.00	2026-09-06 22:42:06.816471+00
3440	match	1475	1	1475	\N	1.00	2026-09-06 22:42:06.816471+00
3441	match	1476	1	1476	\N	1.00	2026-09-06 22:42:06.816471+00
3442	match	1477	1	1477	\N	1.00	2026-09-06 22:42:06.816471+00
3443	match	1478	1	1478	\N	1.00	2026-09-06 22:42:06.816471+00
3444	match	1479	1	1479	\N	1.00	2026-09-06 22:42:06.816471+00
3445	match	1480	1	1480	\N	1.00	2026-09-06 22:42:06.816471+00
3446	match	1481	1	1481	\N	1.00	2026-09-06 22:42:06.816471+00
3447	match	1482	1	1482	\N	1.00	2026-09-06 22:42:06.816471+00
3448	match	1483	1	1483	\N	1.00	2026-09-06 22:42:06.816471+00
3449	match	1484	1	1484	\N	1.00	2026-09-06 22:42:06.816471+00
3450	match	1485	1	1485	\N	1.00	2026-09-06 22:42:06.816471+00
3451	match	1486	1	1486	\N	1.00	2026-09-06 22:42:06.816471+00
3452	match	1487	1	1487	\N	1.00	2026-09-06 22:42:06.816471+00
3453	match	1488	1	1488	\N	1.00	2026-09-06 22:42:06.816471+00
3454	match	1489	1	1489	\N	1.00	2026-09-06 22:42:06.816471+00
3455	match	1490	1	1490	\N	1.00	2026-09-06 22:42:06.816471+00
3456	match	1491	1	1491	\N	1.00	2026-09-06 22:42:06.816471+00
3457	match	1492	1	1492	\N	1.00	2026-09-06 22:42:06.816471+00
3458	match	1493	1	1493	\N	1.00	2026-09-06 22:42:06.816471+00
3459	match	1494	1	1494	\N	1.00	2026-09-06 22:42:06.816471+00
3460	match	1495	1	1495	\N	1.00	2026-09-06 22:42:06.816471+00
3461	match	1496	1	1496	\N	1.00	2026-09-06 22:42:06.816471+00
3462	match	1497	1	1497	\N	1.00	2026-09-06 22:42:06.816471+00
3463	match	1498	1	1498	\N	1.00	2026-09-06 22:42:06.816471+00
3464	match	1499	1	1499	\N	1.00	2026-09-06 22:42:06.816471+00
3465	match	1500	1	1500	\N	1.00	2026-09-06 22:42:06.816471+00
3466	match	1501	1	1501	\N	1.00	2026-09-06 22:42:06.816471+00
3467	match	1502	1	1502	\N	1.00	2026-09-06 22:42:06.816471+00
3468	match	1503	1	1503	\N	1.00	2026-09-06 22:42:06.816471+00
3469	match	1504	1	1504	\N	1.00	2026-09-06 22:42:06.816471+00
3470	match	1505	1	1505	\N	1.00	2026-09-06 22:42:06.816471+00
3471	match	1506	1	1506	\N	1.00	2026-09-06 22:42:06.816471+00
3472	match	1507	1	1507	\N	1.00	2026-09-06 22:42:06.816471+00
3473	match	1508	1	1508	\N	1.00	2026-09-06 22:42:06.816471+00
3474	match	1509	1	1509	\N	1.00	2026-09-06 22:42:06.816471+00
3475	match	1510	1	1510	\N	1.00	2026-09-06 22:42:06.816471+00
3476	match	1511	1	1511	\N	1.00	2026-09-06 22:42:06.816471+00
3477	match	1512	1	1512	\N	1.00	2026-09-06 22:42:06.816471+00
3478	match	1513	1	1513	\N	1.00	2026-09-06 22:42:06.816471+00
3479	match	1514	1	1514	\N	1.00	2026-09-06 22:42:06.816471+00
3480	match	1515	1	1515	\N	1.00	2026-09-06 22:42:06.816471+00
3481	match	1516	1	1516	\N	1.00	2026-09-06 22:42:06.816471+00
3482	match	1517	1	1517	\N	1.00	2026-09-06 22:42:06.816471+00
3483	match	1518	1	1518	\N	1.00	2026-09-06 22:42:06.816471+00
3484	match	1519	1	1519	\N	1.00	2026-09-06 22:42:06.816471+00
3485	match	1520	1	1520	\N	1.00	2026-09-06 22:42:06.816471+00
3486	match	1521	1	1521	\N	1.00	2026-09-06 22:42:06.816471+00
3487	match	1522	1	1522	\N	1.00	2026-09-06 22:42:06.816471+00
3488	match	1523	1	1523	\N	1.00	2026-09-06 22:42:06.816471+00
3489	match	1524	1	1524	\N	1.00	2026-09-06 22:42:06.816471+00
3490	match	1525	1	1525	\N	1.00	2026-09-06 22:42:06.816471+00
3491	match	1526	1	1526	\N	1.00	2026-09-06 22:42:06.816471+00
3492	match	1527	1	1527	\N	1.00	2026-09-06 22:42:06.816471+00
3493	match	1528	1	1528	\N	1.00	2026-09-06 22:42:06.816471+00
3494	match	1529	1	1529	\N	1.00	2026-09-06 22:42:06.816471+00
3495	match	1530	1	1530	\N	1.00	2026-09-06 22:42:06.816471+00
3496	match	1531	1	1531	\N	1.00	2026-09-06 22:42:06.816471+00
3497	match	1532	1	1532	\N	1.00	2026-09-06 22:42:06.816471+00
3498	match	1533	1	1533	\N	1.00	2026-09-06 22:42:06.816471+00
3499	match	1534	1	1534	\N	1.00	2026-09-06 22:42:06.816471+00
3500	match	1535	1	1535	\N	1.00	2026-09-06 22:42:06.816471+00
3501	match	1536	1	1536	\N	1.00	2026-09-06 22:42:06.816471+00
3502	match	1537	1	1537	\N	1.00	2026-09-06 22:42:06.816471+00
3503	match	1538	1	1538	\N	1.00	2026-09-06 22:42:06.816471+00
3504	match	1539	1	1539	\N	1.00	2026-09-06 22:42:06.816471+00
3505	match	1540	1	1540	\N	1.00	2026-09-06 22:42:06.816471+00
3506	match	1541	1	1541	\N	1.00	2026-09-06 22:42:06.816471+00
3507	match	1542	1	1542	\N	1.00	2026-09-06 22:42:06.816471+00
3508	match	1543	1	1543	\N	1.00	2026-09-06 22:42:06.816471+00
3509	match	1544	1	1544	\N	1.00	2026-09-06 22:42:06.816471+00
3510	match	1545	1	1545	\N	1.00	2026-09-06 22:42:06.816471+00
3511	match	1546	1	1546	\N	1.00	2026-09-06 22:42:06.816471+00
3512	match	1547	1	1547	\N	1.00	2026-09-06 22:42:06.816471+00
3513	match	1548	1	1548	\N	1.00	2026-09-06 22:42:06.816471+00
3514	match	1549	1	1549	\N	1.00	2026-09-06 22:42:06.816471+00
\.


--
-- Data for Name: match_events; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.match_events (id, match_id, team_id, player_id, related_player_id, minute, added_time, type, detail) FROM stdin;
1	13	76	979	\N	\N	\N	GOAL	\N
2	18	11	1032	\N	\N	\N	GOAL	\N
3	18	11	1032	\N	\N	\N	GOAL	\N
4	18	11	1032	\N	\N	\N	GOAL	\N
5	18	11	1033	\N	\N	\N	GOAL	\N
6	18	11	1032	\N	\N	\N	GOAL	\N
7	18	11	1031	\N	\N	\N	GOAL	\N
8	18	11	1018	\N	\N	\N	GOAL	\N
9	14	1	1067	\N	\N	\N	GOAL	\N
10	13	87	1136	\N	\N	\N	GOAL	\N
11	16	17	1219	\N	\N	\N	GOAL	\N
12	16	88	996	\N	\N	\N	GOAL	\N
13	16	17	1220	\N	\N	\N	GOAL	\N
14	19	2	1221	\N	\N	\N	GOAL	\N
15	17	7	1096	\N	\N	\N	GOAL	\N
16	21	5	1222	\N	\N	\N	GOAL	\N
17	20	13	1223	\N	\N	\N	GOAL	\N
18	20	13	1224	\N	\N	\N	GOAL	\N
19	20	86	\N	\N	\N	\N	GOAL	\N
20	55	23	1225	\N	\N	\N	GOAL	\N
21	55	23	1225	\N	\N	\N	GOAL	\N
22	22	13	1261	\N	\N	\N	GOAL	\N
23	22	13	1261	\N	\N	\N	GOAL	\N
24	22	16	1262	\N	\N	\N	GOAL	\N
25	22	16	1262	\N	\N	\N	GOAL	\N
26	24	76	982	\N	\N	\N	GOAL	\N
27	27	88	997	\N	\N	\N	GOAL	\N
28	27	2	\N	\N	\N	\N	GOAL	\N
29	25	7	\N	\N	\N	\N	GOAL	\N
30	28	4	1118	\N	\N	\N	GOAL	\N
31	28	15	1045	\N	\N	\N	GOAL	\N
32	29	8	1235	\N	\N	\N	GOAL	\N
33	27	88	1008	\N	\N	\N	GOAL	\N
34	26	87	1153	\N	\N	\N	GOAL	\N
35	36	1	1068	\N	\N	\N	GOAL	\N
36	30	88	1008	\N	\N	\N	GOAL	\N
37	32	7	1099	\N	\N	\N	GOAL	\N
38	32	2	1246	\N	\N	\N	GOAL	\N
39	33	16	1245	\N	\N	\N	GOAL	\N
40	33	76	979	\N	\N	\N	GOAL	\N
41	32	7	1079	\N	\N	\N	GOAL	\N
42	37	11	1032	\N	\N	\N	GOAL	\N
43	35	5	1222	\N	\N	\N	GOAL	\N
44	37	11	1032	\N	\N	\N	GOAL	\N
45	37	11	1035	\N	\N	\N	GOAL	\N
46	43	11	1031	\N	\N	\N	GOAL	\N
47	43	2	1246	\N	\N	\N	GOAL	\N
48	43	11	1022	\N	\N	\N	GOAL	\N
49	43	2	1221	\N	\N	\N	GOAL	\N
50	44	13	1263	\N	\N	\N	GOAL	\N
51	44	13	1261	\N	\N	\N	GOAL	\N
52	44	13	1261	\N	\N	\N	GOAL	\N
53	38	76	982	\N	\N	\N	GOAL	\N
54	44	17	1256	\N	\N	\N	GOAL	\N
55	42	86	1205	\N	\N	\N	GOAL	\N
56	40	15	1052	\N	\N	\N	GOAL	\N
57	40	7	1097	\N	\N	\N	GOAL	\N
58	41	12	\N	\N	\N	\N	GOAL	\N
59	41	12	\N	\N	\N	\N	GOAL	\N
60	41	5	1177	\N	\N	\N	GOAL	\N
61	39	88	999	\N	\N	\N	GOAL	\N
62	45	1	1068	\N	\N	\N	GOAL	\N
63	48	88	1007	\N	\N	\N	GOAL	\N
64	48	1	1277	\N	\N	\N	GOAL	\N
65	47	8	1227	\N	\N	\N	GOAL	\N
66	47	87	1133	\N	\N	\N	GOAL	\N
67	47	8	\N	\N	\N	\N	GOAL	\N
68	52	5	1177	\N	\N	\N	GOAL	\N
69	52	17	\N	\N	\N	\N	GOAL	\N
70	52	17	\N	\N	\N	\N	GOAL	\N
71	52	5	1222	\N	\N	\N	GOAL	\N
72	50	2	\N	\N	\N	\N	GOAL	\N
73	50	13	\N	\N	\N	\N	GOAL	\N
74	51	15	\N	\N	\N	\N	GOAL	\N
75	51	86	1211	\N	\N	\N	GOAL	\N
76	49	11	1031	\N	\N	\N	GOAL	\N
77	49	11	1034	\N	\N	\N	GOAL	\N
78	49	12	\N	\N	\N	\N	GOAL	\N
79	258	35	1295	\N	\N	\N	GOAL	\N
80	258	23	1225	\N	\N	\N	GOAL	\N
81	56	2	1299	\N	\N	\N	GOAL	\N
82	56	2	1310	\N	\N	\N	GOAL	\N
83	56	5	1222	\N	\N	\N	GOAL	\N
84	56	5	1182	\N	\N	\N	GOAL	\N
85	60	17	1260	\N	\N	\N	GOAL	\N
86	59	76	983	\N	\N	\N	GOAL	\N
87	59	76	982	\N	\N	\N	GOAL	\N
88	59	4	1114	\N	\N	\N	GOAL	\N
89	57	8	\N	\N	\N	\N	GOAL	\N
90	57	16	\N	\N	\N	\N	GOAL	\N
91	62	7	1097	\N	\N	\N	GOAL	\N
92	62	11	1032	\N	\N	\N	GOAL	\N
93	64	17	1219	\N	\N	\N	GOAL	\N
94	64	4	1114	\N	\N	\N	GOAL	\N
95	69	11	1032	\N	\N	\N	GOAL	\N
96	69	11	1028	\N	\N	\N	GOAL	\N
97	69	11	1028	\N	\N	\N	GOAL	\N
98	69	11	1034	\N	\N	\N	GOAL	\N
99	67	5	1222	\N	\N	\N	GOAL	\N
100	67	5	1180	\N	\N	\N	GOAL	\N
101	70	7	1081	\N	\N	\N	GOAL	\N
102	66	87	1139	\N	\N	\N	GOAL	\N
103	71	76	982	\N	\N	\N	GOAL	\N
104	71	76	982	\N	\N	\N	GOAL	\N
105	71	76	971	\N	\N	\N	GOAL	\N
106	71	76	983	\N	\N	\N	GOAL	\N
107	72	1	1068	\N	\N	\N	GOAL	\N
108	73	11	1031	\N	\N	\N	GOAL	\N
109	73	76	983	\N	\N	\N	GOAL	\N
110	75	2	1246	\N	\N	\N	GOAL	\N
111	74	8	1234	\N	\N	\N	GOAL	\N
112	78	16	1320	\N	\N	\N	GOAL	\N
113	74	4	1118	\N	\N	\N	GOAL	\N
114	75	87	1310	\N	\N	\N	GOAL	\N
115	75	87	1133	\N	\N	\N	GOAL	\N
116	74	4	1107	\N	\N	\N	GOAL	\N
117	78	17	\N	\N	\N	\N	GOAL	\N
118	79	13	1261	\N	\N	\N	GOAL	\N
119	80	16	1262	\N	\N	\N	GOAL	\N
120	82	4	1118	\N	\N	\N	GOAL	\N
121	82	13	1261	\N	\N	\N	GOAL	\N
122	84	1	1065	\N	\N	\N	GOAL	\N
123	87	11	1031	\N	\N	\N	GOAL	\N
124	86	87	1133	\N	\N	\N	GOAL	\N
125	86	17	1256	\N	\N	\N	GOAL	\N
126	259	64	1330	\N	\N	\N	GOAL	\N
127	259	23	1331	\N	\N	\N	GOAL	\N
128	88	88	1007	\N	\N	\N	GOAL	\N
129	93	16	1319	\N	\N	\N	GOAL	\N
130	90	15	1314	\N	\N	\N	GOAL	\N
131	89	11	1035	\N	\N	\N	GOAL	\N
132	93	16	1262	\N	\N	\N	GOAL	\N
133	93	2	1246	\N	\N	\N	GOAL	\N
134	95	76	983	\N	\N	\N	GOAL	\N
135	95	76	975	\N	\N	\N	GOAL	\N
136	95	76	983	\N	\N	\N	GOAL	\N
137	91	1	1056	\N	\N	\N	GOAL	\N
138	95	76	983	\N	\N	\N	GOAL	\N
139	95	76	975	\N	\N	\N	GOAL	\N
140	94	4	1107	\N	\N	\N	GOAL	\N
141	96	86	1206	\N	\N	\N	GOAL	\N
142	99	2	1311	\N	\N	\N	GOAL	\N
143	97	88	998	\N	\N	\N	GOAL	\N
144	97	88	1007	\N	\N	\N	GOAL	\N
145	97	5	1175	\N	\N	\N	GOAL	\N
146	98	13	1263	\N	\N	\N	GOAL	\N
147	101	15	1044	\N	\N	\N	GOAL	\N
148	101	15	1217	\N	\N	\N	GOAL	\N
149	101	16	1275	\N	\N	\N	GOAL	\N
150	102	11	1030	\N	\N	\N	GOAL	\N
151	102	87	1133	\N	\N	\N	GOAL	\N
152	103	1	1061	\N	\N	\N	GOAL	\N
153	103	7	1099	\N	\N	\N	GOAL	\N
154	260	62	1346	\N	\N	\N	GOAL	\N
155	260	62	1347	\N	\N	\N	GOAL	\N
156	264	90	997	\N	\N	\N	GOAL	\N
157	264	38	\N	\N	\N	\N	GOAL	\N
158	264	90	\N	\N	\N	\N	GOAL	\N
159	263	55	\N	\N	\N	\N	GOAL	\N
160	264	90	\N	\N	\N	\N	GOAL	\N
161	263	55	\N	\N	\N	\N	GOAL	\N
162	263	55	\N	\N	\N	\N	GOAL	\N
163	267	91	1060	\N	\N	\N	GOAL	\N
164	267	90	1223	\N	\N	\N	GOAL	\N
165	267	90	1359	\N	\N	\N	GOAL	\N
166	266	53	\N	\N	\N	\N	GOAL	\N
167	266	55	\N	\N	\N	\N	GOAL	\N
168	266	53	\N	\N	\N	\N	GOAL	\N
169	266	53	\N	\N	\N	\N	GOAL	\N
170	266	53	\N	\N	\N	\N	GOAL	\N
171	269	40	1360	\N	\N	\N	GOAL	\N
172	269	40	1361	\N	\N	\N	GOAL	\N
173	269	40	1362	\N	\N	\N	GOAL	\N
174	269	51	1363	\N	\N	\N	GOAL	\N
175	269	40	1362	\N	\N	\N	GOAL	\N
176	269	40	1364	\N	\N	\N	GOAL	\N
177	270	38	\N	\N	\N	\N	GOAL	\N
178	270	91	\N	\N	\N	\N	GOAL	\N
179	270	38	\N	\N	\N	\N	GOAL	\N
180	272	55	\N	\N	\N	\N	GOAL	\N
181	272	40	\N	\N	\N	\N	GOAL	\N
182	273	89	\N	\N	\N	\N	GOAL	\N
183	275	62	\N	\N	\N	\N	GOAL	\N
184	277	62	\N	\N	\N	\N	GOAL	\N
185	276	90	\N	\N	\N	\N	GOAL	\N
186	276	40	\N	\N	\N	\N	GOAL	\N
187	276	90	\N	\N	\N	\N	GOAL	\N
188	278	62	\N	\N	\N	\N	GOAL	\N
189	278	90	\N	\N	\N	\N	GOAL	\N
190	278	62	\N	\N	\N	\N	GOAL	\N
191	278	90	\N	\N	\N	\N	GOAL	\N
192	278	62	\N	\N	\N	\N	GOAL	\N
193	104	1	1369	\N	\N	\N	GOAL	\N
194	104	1	1370	\N	\N	\N	GOAL	\N
195	104	1	1059	\N	\N	\N	GOAL	\N
196	106	13	1336	\N	\N	\N	GOAL	\N
197	108	7	1085	\N	\N	\N	GOAL	\N
198	108	16	1319	\N	\N	\N	GOAL	\N
199	109	11	1035	\N	\N	\N	GOAL	\N
200	109	11	1035	\N	\N	\N	GOAL	\N
201	108	7	1098	\N	\N	\N	GOAL	\N
202	107	88	1001	\N	\N	\N	GOAL	\N
203	107	86	1203	\N	\N	\N	GOAL	\N
204	107	88	991	\N	\N	\N	GOAL	\N
205	107	88	1003	\N	\N	\N	GOAL	\N
206	110	2	1246	\N	\N	\N	GOAL	\N
207	110	2	1246	\N	\N	\N	GOAL	\N
208	111	17	1219	\N	\N	\N	GOAL	\N
209	111	17	1219	\N	\N	\N	GOAL	\N
210	111	15	1374	\N	\N	\N	GOAL	\N
211	116	7	1085	\N	\N	\N	GOAL	\N
212	113	2	1311	\N	\N	\N	GOAL	\N
213	115	12	1365	\N	\N	\N	GOAL	\N
214	113	8	1236	\N	\N	\N	GOAL	\N
215	114	13	1341	\N	\N	\N	GOAL	\N
216	114	5	1164	\N	\N	\N	GOAL	\N
217	114	13	1335	\N	\N	\N	GOAL	\N
218	114	13	1261	\N	\N	\N	GOAL	\N
219	114	5	1172	\N	\N	\N	GOAL	\N
220	119	86	1210	\N	\N	\N	GOAL	\N
221	112	1	\N	\N	\N	\N	GOAL	\N
222	112	16	1262	\N	\N	\N	GOAL	\N
223	118	11	1031	\N	\N	\N	GOAL	\N
224	118	11	1133	\N	\N	\N	GOAL	\N
225	118	11	1032	\N	\N	\N	GOAL	\N
226	118	11	1032	\N	\N	\N	GOAL	\N
227	123	12	1381	\N	\N	\N	GOAL	\N
228	127	8	1324	\N	\N	\N	GOAL	\N
229	126	76	971	\N	\N	\N	GOAL	\N
230	127	17	1257	\N	\N	\N	GOAL	\N
231	125	1	1065	\N	\N	\N	GOAL	\N
232	125	1	1277	\N	\N	\N	GOAL	\N
233	121	88	1383	\N	\N	\N	GOAL	\N
234	124	11	1026	\N	\N	\N	GOAL	\N
235	124	11	1035	\N	\N	\N	GOAL	\N
236	121	16	1245	\N	\N	\N	GOAL	\N
237	128	8	1234	\N	\N	\N	GOAL	\N
238	134	15	1047	\N	\N	\N	GOAL	\N
239	134	15	1047	\N	\N	\N	GOAL	\N
240	129	1	1071	\N	\N	\N	GOAL	\N
241	135	86	1206	\N	\N	\N	GOAL	\N
242	129	76	983	\N	\N	\N	GOAL	\N
243	129	76	960	\N	\N	\N	GOAL	\N
244	135	86	1385	\N	\N	\N	GOAL	\N
245	135	17	1220	\N	\N	\N	GOAL	\N
246	135	17	1386	\N	\N	\N	GOAL	\N
247	132	11	1035	\N	\N	\N	GOAL	\N
248	132	11	1035	\N	\N	\N	GOAL	\N
249	132	11	1032	\N	\N	\N	GOAL	\N
250	132	11	1032	\N	\N	\N	GOAL	\N
251	133	88	1001	\N	\N	\N	GOAL	\N
252	138	17	1257	\N	\N	\N	GOAL	\N
253	138	17	1386	\N	\N	\N	GOAL	\N
254	138	88	992	\N	\N	\N	GOAL	\N
255	138	88	1003	\N	\N	\N	GOAL	\N
256	138	88	996	\N	\N	\N	GOAL	\N
257	137	76	972	\N	\N	\N	GOAL	\N
258	141	13	\N	\N	\N	\N	GOAL	\N
259	141	13	1263	\N	\N	\N	GOAL	\N
260	137	76	971	\N	\N	\N	GOAL	\N
261	142	5	1180	\N	\N	\N	GOAL	\N
262	142	5	\N	\N	\N	\N	GOAL	\N
263	142	16	\N	\N	\N	\N	GOAL	\N
264	136	1	1065	\N	\N	\N	GOAL	\N
265	136	1	1061	\N	\N	\N	GOAL	\N
266	136	8	1236	\N	\N	\N	GOAL	\N
267	136	1	1071	\N	\N	\N	GOAL	\N
268	143	11	1035	\N	\N	\N	GOAL	\N
269	139	7	1100	\N	\N	\N	GOAL	\N
270	140	2	1306	\N	\N	\N	GOAL	\N
271	140	2	1246	\N	\N	\N	GOAL	\N
272	143	11	1028	\N	\N	\N	GOAL	\N
273	143	11	1035	\N	\N	\N	GOAL	\N
274	139	12	\N	\N	\N	\N	GOAL	\N
275	139	12	\N	\N	\N	\N	GOAL	\N
276	140	4	\N	\N	\N	\N	GOAL	\N
277	150	76	983	\N	\N	\N	GOAL	\N
278	150	76	983	\N	\N	\N	GOAL	\N
279	150	76	975	\N	\N	\N	GOAL	\N
280	150	76	983	\N	\N	\N	GOAL	\N
281	147	17	1258	\N	\N	\N	GOAL	\N
282	147	7	1079	\N	\N	\N	GOAL	\N
283	147	17	\N	\N	\N	\N	GOAL	\N
284	147	17	\N	\N	\N	\N	GOAL	\N
285	148	87	1027	\N	\N	\N	GOAL	\N
286	148	87	1286	\N	\N	\N	GOAL	\N
287	146	88	991	\N	\N	\N	GOAL	\N
288	144	11	1032	\N	\N	\N	GOAL	\N
289	146	2	1246	\N	\N	\N	GOAL	\N
290	146	88	\N	\N	\N	\N	GOAL	\N
291	148	87	\N	\N	\N	\N	GOAL	\N
292	151	5	1222	\N	\N	\N	GOAL	\N
293	151	8	1184	\N	\N	\N	GOAL	\N
294	151	8	1231	\N	\N	\N	GOAL	\N
295	151	5	1222	\N	\N	\N	GOAL	\N
296	145	15	1047	\N	\N	\N	GOAL	\N
297	145	15	1389	\N	\N	\N	GOAL	\N
298	279	76	973	\N	\N	\N	GOAL	\N
299	158	15	1314	\N	\N	\N	GOAL	\N
300	158	15	1313	\N	\N	\N	GOAL	\N
301	280	11	1026	\N	\N	\N	GOAL	\N
302	280	11	1035	\N	\N	\N	GOAL	\N
303	280	11	1035	\N	\N	\N	GOAL	\N
304	158	87	1286	\N	\N	\N	GOAL	\N
305	158	15	1217	\N	\N	\N	GOAL	\N
306	280	11	1032	\N	\N	\N	GOAL	\N
307	159	12	\N	\N	\N	\N	GOAL	\N
308	156	4	1122	\N	\N	\N	GOAL	\N
309	156	1	1329	\N	\N	\N	GOAL	\N
310	157	76	972	\N	\N	\N	GOAL	\N
311	157	76	983	\N	\N	\N	GOAL	\N
312	157	76	975	\N	\N	\N	GOAL	\N
313	157	16	1262	\N	\N	\N	GOAL	\N
314	157	76	972	\N	\N	\N	GOAL	\N
315	154	11	1035	\N	\N	\N	GOAL	\N
316	154	17	1252	\N	\N	\N	GOAL	\N
317	154	11	1032	\N	\N	\N	GOAL	\N
318	154	17	1219	\N	\N	\N	GOAL	\N
319	162	4	1105	\N	\N	\N	GOAL	\N
320	165	86	1210	\N	\N	\N	GOAL	\N
321	162	88	1383	\N	\N	\N	GOAL	\N
322	165	16	1269	\N	\N	\N	GOAL	\N
323	163	7	1088	\N	\N	\N	GOAL	\N
324	163	15	1042	\N	\N	\N	GOAL	\N
325	164	13	1338	\N	\N	\N	GOAL	\N
326	163	15	1217	\N	\N	\N	GOAL	\N
327	281	11	1032	\N	\N	\N	GOAL	\N
328	282	76	982	\N	\N	\N	GOAL	\N
329	282	92	\N	\N	\N	\N	GOAL	\N
330	168	11	1031	\N	\N	\N	GOAL	\N
331	168	11	1032	\N	\N	\N	GOAL	\N
332	168	11	1032	\N	\N	\N	GOAL	\N
333	168	11	1018	\N	\N	\N	GOAL	\N
334	168	11	1036	\N	\N	\N	GOAL	\N
335	161	76	971	\N	\N	\N	GOAL	\N
336	161	76	959	\N	\N	\N	GOAL	\N
337	161	8	1236	\N	\N	\N	GOAL	\N
338	176	11	1133	\N	\N	\N	GOAL	\N
339	176	11	1034	\N	\N	\N	GOAL	\N
340	176	12	1367	\N	\N	\N	GOAL	\N
341	176	12	1280	\N	\N	\N	GOAL	\N
342	176	11	1036	\N	\N	\N	GOAL	\N
343	176	12	1365	\N	\N	\N	GOAL	\N
344	174	86	1210	\N	\N	\N	GOAL	\N
345	174	15	1042	\N	\N	\N	GOAL	\N
346	174	86	1205	\N	\N	\N	GOAL	\N
347	171	1	1384	\N	\N	\N	GOAL	\N
348	169	4	\N	\N	\N	\N	GOAL	\N
349	169	4	\N	\N	\N	\N	GOAL	\N
350	169	16	\N	\N	\N	\N	GOAL	\N
351	173	13	1261	\N	\N	\N	GOAL	\N
352	170	87	1286	\N	\N	\N	GOAL	\N
353	170	87	1286	\N	\N	\N	GOAL	\N
354	170	8	1236	\N	\N	\N	GOAL	\N
355	285	95	1395	\N	\N	\N	GOAL	\N
356	285	76	983	\N	\N	\N	GOAL	\N
357	285	95	1394	\N	\N	\N	GOAL	\N
358	179	15	1217	\N	\N	\N	GOAL	\N
359	178	5	1164	\N	\N	\N	GOAL	\N
360	178	5	1222	\N	\N	\N	GOAL	\N
361	178	2	1307	\N	\N	\N	GOAL	\N
362	179	88	989	\N	\N	\N	GOAL	\N
363	283	11	1035	\N	\N	\N	GOAL	\N
364	283	94	1396	\N	\N	\N	GOAL	\N
365	283	94	1397	\N	\N	\N	GOAL	\N
366	283	11	1032	\N	\N	\N	GOAL	\N
367	182	87	1153	\N	\N	\N	GOAL	\N
368	182	86	1209	\N	\N	\N	GOAL	\N
369	182	87	1286	\N	\N	\N	GOAL	\N
370	177	8	1324	\N	\N	\N	GOAL	\N
371	181	1	1065	\N	\N	\N	GOAL	\N
372	184	76	982	\N	\N	\N	GOAL	\N
373	184	76	977	\N	\N	\N	GOAL	\N
374	190	13	1336	\N	\N	\N	GOAL	\N
375	190	13	1336	\N	\N	\N	GOAL	\N
376	190	7	1097	\N	\N	\N	GOAL	\N
377	187	15	1047	\N	\N	\N	GOAL	\N
378	187	15	1045	\N	\N	\N	GOAL	\N
379	187	5	1222	\N	\N	\N	GOAL	\N
380	187	5	1180	\N	\N	\N	GOAL	\N
381	185	1	1329	\N	\N	\N	GOAL	\N
382	185	1	1370	\N	\N	\N	GOAL	\N
383	185	2	1311	\N	\N	\N	GOAL	\N
384	191	76	982	\N	\N	\N	GOAL	\N
385	191	12	1381	\N	\N	\N	GOAL	\N
386	191	76	983	\N	\N	\N	GOAL	\N
387	186	4	1121	\N	\N	\N	GOAL	\N
388	287	54	1398	\N	\N	\N	GOAL	\N
389	287	23	1400	\N	\N	\N	GOAL	\N
390	287	54	1399	\N	\N	\N	GOAL	\N
391	287	54	1398	\N	\N	\N	GOAL	\N
392	287	54	\N	\N	\N	\N	GOAL	\N
393	288	23	1401	\N	\N	\N	GOAL	\N
394	288	23	1031	\N	\N	\N	GOAL	\N
395	192	11	1035	\N	\N	\N	GOAL	\N
396	192	11	1035	\N	\N	\N	GOAL	\N
397	198	7	1099	\N	\N	\N	GOAL	\N
398	198	7	1100	\N	\N	\N	GOAL	\N
399	198	7	1085	\N	\N	\N	GOAL	\N
400	289	76	967	\N	\N	\N	GOAL	\N
401	199	17	1219	\N	\N	\N	GOAL	\N
402	199	17	1219	\N	\N	\N	GOAL	\N
403	289	76	975	\N	\N	\N	GOAL	\N
404	199	17	1403	\N	\N	\N	GOAL	\N
405	199	16	1262	\N	\N	\N	GOAL	\N
406	199	16	1262	\N	\N	\N	GOAL	\N
407	195	4	1116	\N	\N	\N	GOAL	\N
408	195	8	1184	\N	\N	\N	GOAL	\N
409	194	12	1366	\N	\N	\N	GOAL	\N
410	194	12	1292	\N	\N	\N	GOAL	\N
411	194	12	1292	\N	\N	\N	GOAL	\N
412	194	86	1215	\N	\N	\N	GOAL	\N
413	180	11	1032	\N	\N	\N	GOAL	\N
414	207	88	1383	\N	\N	\N	GOAL	\N
415	206	17	1220	\N	\N	\N	GOAL	\N
416	206	17	1257	\N	\N	\N	GOAL	\N
417	207	76	965	\N	\N	\N	GOAL	\N
418	206	87	1404	\N	\N	\N	GOAL	\N
419	203	2	1308	\N	\N	\N	GOAL	\N
420	203	2	1405	\N	\N	\N	GOAL	\N
421	203	86	1209	\N	\N	\N	GOAL	\N
422	205	13	\N	\N	\N	\N	GOAL	\N
423	205	4	\N	\N	\N	\N	GOAL	\N
424	202	12	\N	\N	\N	\N	GOAL	\N
425	202	16	\N	\N	\N	\N	GOAL	\N
426	202	16	\N	\N	\N	\N	GOAL	\N
427	202	16	\N	\N	\N	\N	GOAL	\N
428	208	11	1032	\N	\N	\N	GOAL	\N
429	208	11	1133	\N	\N	\N	GOAL	\N
430	208	5	1180	\N	\N	\N	GOAL	\N
431	208	11	1035	\N	\N	\N	GOAL	\N
432	204	7	1099	\N	\N	\N	GOAL	\N
433	201	15	1047	\N	\N	\N	GOAL	\N
434	201	15	1216	\N	\N	\N	GOAL	\N
435	209	87	1139	\N	\N	\N	GOAL	\N
436	213	2	1221	\N	\N	\N	GOAL	\N
437	213	2	1221	\N	\N	\N	GOAL	\N
438	213	16	1262	\N	\N	\N	GOAL	\N
439	213	16	1262	\N	\N	\N	GOAL	\N
440	212	17	1256	\N	\N	\N	GOAL	\N
441	212	12	1367	\N	\N	\N	GOAL	\N
442	212	12	1292	\N	\N	\N	GOAL	\N
443	212	12	1366	\N	\N	\N	GOAL	\N
444	210	8	1234	\N	\N	\N	GOAL	\N
445	210	15	1042	\N	\N	\N	GOAL	\N
446	216	11	1035	\N	\N	\N	GOAL	\N
447	210	15	1374	\N	\N	\N	GOAL	\N
448	210	15	1216	\N	\N	\N	GOAL	\N
449	216	11	1032	\N	\N	\N	GOAL	\N
450	214	4	1114	\N	\N	\N	GOAL	\N
451	214	4	1114	\N	\N	\N	GOAL	\N
452	214	7	1100	\N	\N	\N	GOAL	\N
453	290	96	1406	\N	\N	\N	GOAL	\N
454	219	87	1286	\N	\N	\N	GOAL	\N
455	219	11	1034	\N	\N	\N	GOAL	\N
456	215	76	967	\N	\N	\N	GOAL	\N
457	215	5	1179	\N	\N	\N	GOAL	\N
458	220	5	1165	\N	\N	\N	GOAL	\N
459	220	88	1407	\N	\N	\N	GOAL	\N
460	218	86	1215	\N	\N	\N	GOAL	\N
461	218	86	1196	\N	\N	\N	GOAL	\N
462	222	16	1262	\N	\N	\N	GOAL	\N
463	223	1	1071	\N	\N	\N	GOAL	\N
464	222	15	1216	\N	\N	\N	GOAL	\N
465	222	16	1262	\N	\N	\N	GOAL	\N
466	222	16	1262	\N	\N	\N	GOAL	\N
467	200	11	1018	\N	\N	\N	GOAL	\N
468	221	17	1408	\N	\N	\N	GOAL	\N
469	228	17	1256	\N	\N	\N	GOAL	\N
470	228	15	\N	\N	\N	\N	GOAL	\N
471	229	88	1383	\N	\N	\N	GOAL	\N
472	229	88	994	\N	\N	\N	GOAL	\N
473	229	88	1409	\N	\N	\N	GOAL	\N
474	229	88	1000	\N	\N	\N	GOAL	\N
475	231	13	1338	\N	\N	\N	GOAL	\N
476	232	11	1032	\N	\N	\N	GOAL	\N
477	226	12	1292	\N	\N	\N	GOAL	\N
478	226	1	1071	\N	\N	\N	GOAL	\N
479	226	12	1279	\N	\N	\N	GOAL	\N
480	291	97	\N	\N	\N	\N	GOAL	\N
481	291	97	\N	\N	\N	\N	GOAL	\N
482	291	97	\N	\N	\N	\N	GOAL	\N
483	291	97	\N	\N	\N	\N	GOAL	\N
484	233	2	1372	\N	\N	\N	GOAL	\N
485	224	13	1263	\N	\N	\N	GOAL	\N
486	224	13	1341	\N	\N	\N	GOAL	\N
487	235	1	1071	\N	\N	\N	GOAL	\N
488	235	1	1063	\N	\N	\N	GOAL	\N
489	240	11	1015	\N	\N	\N	GOAL	\N
490	237	4	1114	\N	\N	\N	GOAL	\N
491	237	4	1107	\N	\N	\N	GOAL	\N
492	237	4	1121	\N	\N	\N	GOAL	\N
493	237	86	1215	\N	\N	\N	GOAL	\N
494	175	7	1085	\N	\N	\N	GOAL	\N
495	239	15	1230	\N	\N	\N	GOAL	\N
496	238	87	1136	\N	\N	\N	GOAL	\N
497	238	7	1098	\N	\N	\N	GOAL	\N
498	238	87	1136	\N	\N	\N	GOAL	\N
499	248	2	1299	\N	\N	\N	GOAL	\N
500	244	87	1140	\N	\N	\N	GOAL	\N
501	241	4	1107	\N	\N	\N	GOAL	\N
502	234	17	1386	\N	\N	\N	GOAL	\N
503	242	88	1003	\N	\N	\N	GOAL	\N
504	242	88	991	\N	\N	\N	GOAL	\N
505	242	88	999	\N	\N	\N	GOAL	\N
506	242	16	1315	\N	\N	\N	GOAL	\N
507	242	16	1319	\N	\N	\N	GOAL	\N
508	247	7	1085	\N	\N	\N	GOAL	\N
509	243	1	1071	\N	\N	\N	GOAL	\N
510	243	1	1063	\N	\N	\N	GOAL	\N
511	243	1	1071	\N	\N	\N	GOAL	\N
512	243	1	1071	\N	\N	\N	GOAL	\N
513	243	13	1261	\N	\N	\N	GOAL	\N
514	227	76	968	\N	\N	\N	GOAL	\N
515	246	8	1232	\N	\N	\N	GOAL	\N
516	246	8	1184	\N	\N	\N	GOAL	\N
517	246	8	1324	\N	\N	\N	GOAL	\N
518	245	76	981	\N	\N	\N	GOAL	\N
519	245	15	1047	\N	\N	\N	GOAL	\N
520	245	76	969	\N	\N	\N	GOAL	\N
521	245	15	1217	\N	\N	\N	GOAL	\N
522	256	16	1262	\N	\N	\N	GOAL	\N
523	251	8	1236	\N	\N	\N	GOAL	\N
524	251	8	1232	\N	\N	\N	GOAL	\N
525	249	87	\N	\N	\N	\N	GOAL	\N
526	250	13	1341	\N	\N	\N	GOAL	\N
527	256	11	1025	\N	\N	\N	GOAL	\N
528	251	12	1292	\N	\N	\N	GOAL	\N
529	249	4	\N	\N	\N	\N	GOAL	\N
530	249	4	\N	\N	\N	\N	GOAL	\N
531	251	8	1232	\N	\N	\N	GOAL	\N
532	255	2	1221	\N	\N	\N	GOAL	\N
533	255	15	1217	\N	\N	\N	GOAL	\N
534	254	17	1386	\N	\N	\N	GOAL	\N
535	254	17	\N	\N	\N	\N	GOAL	\N
536	253	1	1065	\N	\N	\N	GOAL	\N
537	253	76	\N	\N	\N	\N	GOAL	\N
538	253	1	1071	\N	\N	\N	GOAL	\N
539	253	1	1064	\N	\N	\N	GOAL	\N
540	318	11	1413	\N	29	\N	GOAL	\N
541	318	7	1099	\N	33	\N	GOAL	\N
542	318	11	1085	\N	48	\N	GOAL	\N
543	298	17	1443	\N	9	\N	GOAL	\N
544	298	4	1234	\N	20	\N	GOAL	\N
545	298	4	1234	\N	29	\N	GOAL	\N
546	296	87	1404	\N	58	\N	GOAL	\N
547	296	100	1444	\N	69	\N	GOAL	\N
548	295	2	1258	\N	79	\N	GOAL	\N
549	294	8	1381	\N	68	\N	GOAL	\N
550	297	101	1445	\N	18	\N	GOAL	\N
551	293	11	1413	\N	2	\N	GOAL	\N
552	299	12	1452	\N	49	\N	GOAL	\N
553	301	76	1451	\N	31	\N	GOAL	\N
554	301	7	1094	\N	72	\N	GOAL	\N
555	302	1	1453	\N	33	\N	GOAL	\N
556	302	1	1454	\N	45	\N	GOAL	\N
557	305	100	1455	\N	20	\N	GOAL	\N
558	304	88	1230	\N	29	\N	GOAL	\N
559	310	102	1260	\N	53	\N	GOAL	\N
560	310	15	1462	\N	70	\N	GOAL	\N
561	311	12	1292	\N	31	\N	GOAL	\N
562	306	7	1097	\N	37	\N	GOAL	\N
563	311	2	1002	\N	59	\N	GOAL	\N
564	308	87	1219	\N	49	\N	GOAL	\N
565	308	3	1463	\N	75	\N	GOAL	\N
566	313	6	1425	\N	9	\N	GOAL	\N
567	313	99	1464	\N	90	\N	GOAL	\N
568	307	11	1413	\N	11	\N	GOAL	\N
569	307	11	1413	\N	45	\N	GOAL	\N
570	312	1	999	\N	59	\N	GOAL	\N
571	312	1	1453	\N	79	\N	GOAL	\N
572	325	13	1338	\N	\N	\N	GOAL	\N
573	322	100	1766	\N	33	\N	GOAL	\N
574	323	7	1097	\N	9	\N	GOAL	\N
575	323	7	1088	\N	42	\N	GOAL	\N
576	323	5	1169	\N	48	\N	GOAL	\N
577	321	12	1365	\N	60	\N	GOAL	\N
578	322	102	1557	\N	80	\N	GOAL	\N
579	325	13	1686	\N	85	\N	GOAL	\N
580	327	3	1463	\N	79	\N	GOAL	\N
581	680	70	\N	\N	\N	\N	GOAL	\N
582	680	25	\N	\N	\N	\N	GOAL	\N
583	680	25	\N	\N	\N	\N	GOAL	\N
584	680	25	\N	\N	\N	\N	GOAL	\N
585	681	89	\N	\N	\N	\N	GOAL	\N
586	681	89	\N	\N	\N	\N	GOAL	\N
587	681	89	\N	\N	\N	\N	GOAL	\N
588	681	89	\N	\N	\N	\N	GOAL	\N
589	681	89	\N	\N	\N	\N	GOAL	\N
590	681	29	\N	\N	\N	\N	GOAL	\N
591	682	35	\N	\N	\N	\N	GOAL	\N
592	683	34	\N	\N	\N	\N	GOAL	\N
593	684	53	\N	\N	\N	\N	GOAL	\N
594	684	53	\N	\N	\N	\N	GOAL	\N
595	684	53	\N	\N	\N	\N	GOAL	\N
596	685	59	\N	\N	\N	\N	GOAL	\N
597	686	58	\N	\N	\N	\N	GOAL	\N
598	687	32	\N	\N	\N	\N	GOAL	\N
599	687	32	\N	\N	\N	\N	GOAL	\N
600	688	42	\N	\N	\N	\N	GOAL	\N
601	689	71	\N	\N	\N	\N	GOAL	\N
602	689	71	\N	\N	\N	\N	GOAL	\N
603	689	62	\N	\N	\N	\N	GOAL	\N
604	690	23	\N	\N	\N	\N	GOAL	\N
605	690	26	\N	\N	\N	\N	GOAL	\N
606	691	61	\N	\N	\N	\N	GOAL	\N
607	691	61	\N	\N	\N	\N	GOAL	\N
608	691	61	\N	\N	\N	\N	GOAL	\N
609	691	60	\N	\N	\N	\N	GOAL	\N
610	692	40	\N	\N	\N	\N	GOAL	\N
611	693	48	\N	\N	\N	\N	GOAL	\N
612	693	48	\N	\N	\N	\N	GOAL	\N
613	693	48	\N	\N	\N	\N	GOAL	\N
614	693	43	\N	\N	\N	\N	GOAL	\N
615	694	50	\N	\N	\N	\N	GOAL	\N
616	694	50	\N	\N	\N	\N	GOAL	\N
617	694	66	\N	\N	\N	\N	GOAL	\N
618	695	52	\N	\N	\N	\N	GOAL	\N
619	695	52	\N	\N	\N	\N	GOAL	\N
620	695	52	\N	\N	\N	\N	GOAL	\N
621	696	69	\N	\N	\N	\N	GOAL	\N
622	696	69	\N	\N	\N	\N	GOAL	\N
623	696	104	\N	\N	\N	\N	GOAL	\N
624	696	104	\N	\N	\N	\N	GOAL	\N
625	696	104	\N	\N	\N	\N	GOAL	\N
626	697	105	\N	\N	\N	\N	GOAL	\N
627	698	30	\N	\N	\N	\N	GOAL	\N
628	698	30	\N	\N	\N	\N	GOAL	\N
629	698	30	\N	\N	\N	\N	GOAL	\N
630	699	44	\N	\N	\N	\N	GOAL	\N
631	699	44	\N	\N	\N	\N	GOAL	\N
632	699	38	\N	\N	\N	\N	GOAL	\N
633	700	64	\N	\N	\N	\N	GOAL	\N
634	701	33	\N	\N	\N	\N	GOAL	\N
635	701	33	\N	\N	\N	\N	GOAL	\N
636	701	33	\N	\N	\N	\N	GOAL	\N
637	701	33	\N	\N	\N	\N	GOAL	\N
638	701	33	\N	\N	\N	\N	GOAL	\N
639	702	54	\N	\N	\N	\N	GOAL	\N
640	715	103	\N	\N	\N	\N	GOAL	\N
641	715	103	\N	\N	\N	\N	GOAL	\N
642	715	103	\N	\N	\N	\N	GOAL	\N
643	714	27	\N	\N	\N	\N	GOAL	\N
644	714	27	\N	\N	\N	\N	GOAL	\N
645	714	27	\N	\N	\N	\N	GOAL	\N
646	714	27	\N	\N	\N	\N	GOAL	\N
647	714	27	\N	\N	\N	\N	GOAL	\N
648	714	27	\N	\N	\N	\N	GOAL	\N
649	713	59	\N	\N	\N	\N	GOAL	\N
650	713	59	\N	\N	\N	\N	GOAL	\N
651	712	41	\N	\N	\N	\N	GOAL	\N
652	712	54	\N	\N	\N	\N	GOAL	\N
653	711	63	\N	\N	\N	\N	GOAL	\N
654	710	34	\N	\N	\N	\N	GOAL	\N
655	710	34	\N	\N	\N	\N	GOAL	\N
656	710	42	\N	\N	\N	\N	GOAL	\N
657	710	42	\N	\N	\N	\N	GOAL	\N
658	709	66	\N	\N	\N	\N	GOAL	\N
659	709	53	\N	\N	\N	\N	GOAL	\N
660	708	28	\N	\N	\N	\N	GOAL	\N
661	708	37	\N	\N	\N	\N	GOAL	\N
662	706	33	\N	\N	\N	\N	GOAL	\N
663	705	39	\N	\N	\N	\N	GOAL	\N
664	705	39	\N	\N	\N	\N	GOAL	\N
665	705	39	\N	\N	\N	\N	GOAL	\N
666	704	49	\N	\N	\N	\N	GOAL	\N
667	704	58	\N	\N	\N	\N	GOAL	\N
668	717	25	\N	\N	\N	\N	GOAL	\N
669	717	25	\N	\N	\N	\N	GOAL	\N
670	717	52	\N	\N	\N	\N	GOAL	\N
671	717	52	\N	\N	\N	\N	GOAL	\N
672	718	50	\N	\N	\N	\N	GOAL	\N
673	718	50	\N	\N	\N	\N	GOAL	\N
674	718	50	\N	\N	\N	\N	GOAL	\N
675	719	55	\N	\N	\N	\N	GOAL	\N
676	720	105	\N	\N	\N	\N	GOAL	\N
677	720	105	\N	\N	\N	\N	GOAL	\N
678	721	26	\N	\N	\N	\N	GOAL	\N
679	721	46	\N	\N	\N	\N	GOAL	\N
680	722	38	\N	\N	\N	\N	GOAL	\N
681	722	69	\N	\N	\N	\N	GOAL	\N
682	722	69	\N	\N	\N	\N	GOAL	\N
683	723	60	\N	\N	\N	\N	GOAL	\N
684	723	30	\N	\N	\N	\N	GOAL	\N
685	724	43	\N	\N	\N	\N	GOAL	\N
686	725	57	\N	\N	\N	\N	GOAL	\N
687	725	61	\N	\N	\N	\N	GOAL	\N
688	726	104	\N	\N	\N	\N	GOAL	\N
689	330	1	1064	\N	55	\N	GOAL	\N
690	330	17	1619	\N	71	\N	GOAL	\N
691	335	88	1246	\N	\N	\N	GOAL	\N
692	332	13	1336	\N	89	\N	GOAL	\N
693	332	13	1683	\N	74	\N	GOAL	\N
694	332	15	1266	\N	83	\N	GOAL	\N
695	338	5	1183	\N	18	\N	GOAL	\N
696	338	5	1222	\N	81	\N	GOAL	\N
697	336	76	1184	\N	1	\N	GOAL	\N
698	336	12	1665	\N	15	\N	GOAL	\N
699	336	76	982	\N	32	\N	GOAL	\N
700	336	76	966	\N	35	\N	GOAL	\N
701	336	76	1003	\N	58	\N	GOAL	\N
702	336	12	1665	\N	59	\N	GOAL	\N
703	336	12	1665	\N	91	\N	GOAL	\N
704	339	87	1403	\N	6	\N	GOAL	\N
705	341	8	1381	\N	40	\N	GOAL	\N
706	341	8	1381	\N	73	\N	GOAL	\N
707	341	7	1097	\N	23	\N	GOAL	\N
708	343	17	1253	\N	66	\N	GOAL	\N
709	343	3	1544	\N	87	\N	GOAL	\N
710	340	5	1222	\N	20	\N	GOAL	\N
711	340	5	1222	\N	33	\N	GOAL	\N
712	340	5	1179	\N	60	\N	GOAL	\N
713	340	15	1047	\N	51	\N	GOAL	\N
714	340	5	1245	\N	75	\N	GOAL	\N
715	340	15	1054	\N	90	\N	GOAL	\N
716	342	76	1451	\N	11	\N	GOAL	\N
717	345	13	1336	\N	38	\N	GOAL	\N
718	345	13	1683	\N	54	\N	GOAL	\N
719	345	4	1128	\N	82	\N	GOAL	\N
720	345	4	1522	\N	85	\N	GOAL	\N
721	346	2	1304	\N	26	\N	GOAL	\N
722	347	6	1435	\N	50	\N	GOAL	\N
723	347	88	1642	\N	57	\N	GOAL	\N
724	347	88	1246	\N	62	\N	GOAL	\N
725	347	6	1442	\N	70	\N	GOAL	\N
726	347	6	1379	\N	75	\N	GOAL	\N
727	348	102	1563	\N	9	\N	GOAL	\N
728	348	102	1311	\N	45	\N	GOAL	\N
729	353	5	1222	\N	34	\N	GOAL	\N
730	353	4	1125	\N	51	\N	GOAL	\N
731	350	11	1035	\N	41	\N	GOAL	\N
732	350	11	1035	\N	45	\N	GOAL	\N
733	350	11	1413	\N	50	\N	GOAL	\N
734	354	1	999	\N	59	\N	GOAL	\N
735	350	17	1408	\N	81	\N	GOAL	\N
736	352	76	980	\N	29	\N	GOAL	\N
737	352	76	980	\N	45	\N	GOAL	\N
738	357	12	1292	\N	37	\N	GOAL	\N
739	357	12	1365	\N	53	\N	GOAL	\N
740	355	7	1114	\N	25	\N	GOAL	\N
741	355	7	1114	\N	31	\N	GOAL	\N
742	357	12	1365	\N	82	\N	GOAL	\N
743	357	8	1825	\N	91	\N	GOAL	\N
744	356	2	1310	\N	94	\N	GOAL	\N
745	360	88	1246	\N	24	\N	GOAL	\N
746	360	88	1324	\N	67	\N	GOAL	\N
747	360	88	998	\N	89	\N	GOAL	\N
748	359	15	1462	\N	50	\N	GOAL	\N
749	364	7	1097	\N	28	\N	GOAL	\N
750	367	100	1460	\N	31	\N	GOAL	\N
751	367	2	1304	\N	50	\N	GOAL	\N
752	366	4	1522	\N	47	\N	GOAL	\N
753	366	4	1121	\N	52	\N	GOAL	\N
754	366	8	1814	\N	59	\N	GOAL	\N
755	366	4	1522	\N	86	\N	GOAL	\N
756	368	99	1759	\N	5	\N	GOAL	\N
757	368	99	1742	\N	10	\N	GOAL	\N
758	368	102	1311	\N	56	\N	GOAL	\N
759	375	101	1733	\N	29	\N	GOAL	\N
760	375	7	1100	\N	40	\N	GOAL	\N
761	375	7	1094	\N	81	\N	GOAL	\N
762	373	100	1780	\N	35	\N	GOAL	\N
763	369	3	1540	\N	56	\N	GOAL	\N
764	374	15	1054	\N	33	\N	GOAL	\N
765	371	5	1222	\N	\N	\N	GOAL	\N
766	377	1	1065	\N	39	\N	GOAL	\N
767	379	12	1292	\N	48	\N	GOAL	\N
768	379	87	1586	\N	79	\N	GOAL	\N
769	383	5	1245	\N	7	\N	GOAL	\N
770	383	13	1688	\N	41	\N	GOAL	\N
771	380	8	1381	\N	75	\N	GOAL	\N
772	380	88	1263	\N	86	\N	GOAL	\N
773	383	5	1169	\N	87	\N	GOAL	\N
774	384	7	1081	\N	3	\N	GOAL	\N
775	384	102	1311	\N	29	\N	GOAL	\N
776	381	11	1031	\N	9	\N	GOAL	\N
777	381	11	1032	\N	48	\N	GOAL	\N
778	381	6	1416	\N	62	\N	GOAL	\N
779	386	3	1540	\N	71	\N	GOAL	\N
780	386	99	1742	\N	91	\N	GOAL	\N
781	385	76	967	\N	16	\N	GOAL	\N
782	385	76	982	\N	91	\N	GOAL	\N
783	387	17	1618	\N	65	\N	GOAL	\N
784	388	1	979	\N	30	\N	GOAL	\N
785	388	1	1454	\N	70	\N	GOAL	\N
786	730	37	\N	\N	\N	\N	GOAL	\N
787	730	37	\N	\N	\N	\N	GOAL	\N
788	730	42	\N	\N	\N	\N	GOAL	\N
789	731	60	\N	\N	\N	\N	GOAL	\N
790	731	60	\N	\N	\N	\N	GOAL	\N
791	731	60	\N	\N	\N	\N	GOAL	\N
792	731	57	\N	\N	\N	\N	GOAL	\N
793	740	46	\N	\N	\N	\N	GOAL	\N
794	740	46	\N	\N	\N	\N	GOAL	\N
795	740	46	\N	\N	83	\N	GOAL	\N
796	739	27	\N	\N	7	\N	GOAL	\N
797	739	27	\N	\N	10	\N	GOAL	\N
798	739	27	\N	\N	29	\N	GOAL	\N
799	739	27	\N	\N	45	\N	GOAL	\N
800	739	24	\N	\N	85	\N	GOAL	\N
801	741	69	\N	\N	26	\N	GOAL	\N
802	741	69	\N	\N	54	\N	GOAL	\N
803	741	69	\N	\N	59	\N	GOAL	\N
804	741	69	\N	\N	76	\N	GOAL	\N
805	738	104	\N	\N	73	\N	GOAL	\N
806	735	59	\N	\N	3	\N	GOAL	\N
807	735	43	\N	\N	17	\N	GOAL	\N
808	735	43	\N	\N	53	\N	GOAL	\N
809	735	43	\N	\N	80	\N	GOAL	\N
810	736	66	\N	\N	28	\N	GOAL	\N
811	736	66	\N	\N	58	\N	GOAL	\N
812	734	58	\N	\N	62	\N	GOAL	\N
813	744	56	\N	\N	84	\N	GOAL	\N
814	744	41	\N	\N	7	\N	GOAL	\N
815	746	54	\N	\N	21	\N	GOAL	\N
816	746	54	\N	\N	74	\N	GOAL	\N
817	750	32	\N	\N	23	\N	GOAL	\N
818	750	32	\N	\N	25	\N	GOAL	\N
819	750	32	\N	\N	27	\N	GOAL	\N
820	750	32	\N	\N	74	\N	GOAL	\N
821	750	32	\N	\N	81	\N	GOAL	\N
822	750	32	\N	\N	90	\N	GOAL	\N
823	760	30	\N	\N	21	\N	GOAL	\N
824	775	52	\N	\N	17	\N	GOAL	\N
825	775	52	\N	\N	18	\N	GOAL	\N
826	775	52	\N	\N	50	\N	GOAL	\N
827	773	103	\N	\N	90	\N	GOAL	\N
828	776	62	\N	\N	23	\N	GOAL	\N
829	776	62	\N	\N	27	\N	GOAL	\N
830	776	62	\N	\N	67	\N	GOAL	\N
831	777	37	\N	\N	13	\N	GOAL	\N
832	777	42	\N	\N	53	\N	GOAL	\N
833	777	42	\N	\N	61	\N	GOAL	\N
834	771	30	\N	\N	21	\N	GOAL	\N
835	771	30	\N	\N	69	\N	GOAL	\N
836	771	61	\N	\N	90	\N	GOAL	\N
837	772	48	\N	\N	6	\N	GOAL	\N
838	772	48	\N	\N	55	\N	GOAL	\N
839	772	48	\N	\N	61	\N	GOAL	\N
840	774	105	\N	\N	17	\N	GOAL	\N
841	769	34	\N	\N	27	\N	GOAL	\N
842	769	28	\N	\N	69	\N	GOAL	\N
843	769	28	\N	\N	90	\N	GOAL	\N
844	768	40	\N	\N	12	\N	GOAL	\N
845	768	40	\N	\N	37	\N	GOAL	\N
846	768	40	\N	\N	64	\N	GOAL	\N
847	737	39	\N	\N	4	\N	GOAL	\N
848	737	39	\N	\N	58	\N	GOAL	\N
849	737	39	\N	\N	69	\N	GOAL	\N
850	737	39	\N	\N	90	\N	GOAL	\N
851	747	25	\N	\N	\N	\N	GOAL	\N
852	728	23	1400	\N	29	\N	GOAL	\N
853	728	23	1401	\N	57	\N	GOAL	\N
854	781	25	\N	\N	42	\N	GOAL	\N
855	758	49	\N	\N	\N	\N	GOAL	\N
856	758	49	\N	\N	\N	\N	GOAL	\N
857	758	103	\N	\N	\N	\N	GOAL	\N
858	758	103	\N	\N	\N	\N	GOAL	\N
859	765	53	\N	\N	\N	\N	GOAL	\N
860	765	50	\N	\N	\N	\N	GOAL	\N
861	763	66	\N	\N	\N	\N	GOAL	\N
862	762	38	\N	\N	\N	\N	GOAL	\N
863	762	104	\N	\N	\N	\N	GOAL	\N
864	749	27	\N	\N	\N	\N	GOAL	\N
865	749	27	\N	\N	\N	\N	GOAL	\N
866	780	56	\N	\N	\N	\N	GOAL	\N
867	766	28	\N	\N	\N	\N	GOAL	\N
868	748	52	\N	\N	\N	\N	GOAL	\N
869	755	64	\N	\N	\N	\N	GOAL	\N
870	756	40	\N	\N	\N	\N	GOAL	\N
871	756	40	\N	\N	\N	\N	GOAL	\N
872	779	89	\N	\N	\N	\N	GOAL	\N
873	779	89	\N	\N	\N	\N	GOAL	\N
874	779	39	\N	\N	\N	\N	GOAL	\N
875	779	39	\N	\N	\N	\N	GOAL	\N
876	779	39	\N	\N	\N	\N	GOAL	\N
877	757	57	\N	\N	\N	\N	GOAL	\N
878	757	57	\N	\N	\N	\N	GOAL	\N
879	757	60	\N	\N	\N	\N	GOAL	\N
880	752	59	\N	\N	\N	\N	GOAL	\N
881	751	65	\N	\N	\N	\N	GOAL	\N
882	751	105	\N	\N	\N	\N	GOAL	\N
883	751	105	\N	\N	\N	\N	GOAL	\N
884	760	61	\N	\N	\N	\N	GOAL	\N
885	391	6	1414	\N	8	\N	GOAL	\N
886	391	1	1065	\N	13	\N	GOAL	\N
887	391	1	1469	\N	88	\N	GOAL	\N
888	392	76	1451	\N	17	\N	GOAL	\N
889	392	76	1184	\N	24	\N	GOAL	\N
890	392	76	982	\N	88	\N	GOAL	\N
891	397	4	1125	\N	60	\N	GOAL	\N
892	396	11	1472	\N	30	\N	GOAL	\N
893	396	11	1032	\N	45	\N	GOAL	\N
894	398	2	1304	\N	48	\N	GOAL	\N
895	399	1	1065	\N	55	\N	GOAL	\N
896	407	87	1586	\N	9	\N	GOAL	\N
897	407	87	1404	\N	14	\N	GOAL	\N
898	407	87	1404	\N	39	\N	GOAL	\N
899	400	100	1771	\N	2	\N	GOAL	\N
900	400	4	1252	\N	22	\N	GOAL	\N
901	403	15	1054	\N	35	\N	GOAL	\N
902	403	15	1044	\N	66	\N	GOAL	\N
903	403	15	1054	\N	87	\N	GOAL	\N
904	401	11	1032	\N	10	\N	GOAL	\N
905	401	11	1133	\N	30	\N	GOAL	\N
906	401	11	1032	\N	62	\N	GOAL	\N
907	401	11	1286	\N	70	\N	GOAL	\N
908	401	11	1472	\N	87	\N	GOAL	\N
909	401	99	1757	\N	93	\N	GOAL	\N
910	405	5	1222	\N	2	\N	GOAL	\N
911	404	12	1232	\N	48	\N	GOAL	\N
912	404	7	1088	\N	63	\N	GOAL	\N
913	404	12	1232	\N	71	\N	GOAL	\N
914	406	8	1381	\N	19	\N	GOAL	\N
915	406	8	1825	\N	48	\N	GOAL	\N
916	406	101	1153	\N	71	\N	GOAL	\N
917	408	76	1450	\N	89	\N	GOAL	\N
918	412	3	1538	\N	78	\N	GOAL	\N
919	411	1	979	\N	29	\N	GOAL	\N
920	410	100	1780	\N	43	\N	GOAL	\N
921	410	99	1756	\N	54	\N	GOAL	\N
922	413	7	1496	\N	87	\N	GOAL	\N
923	409	11	1032	\N	7	\N	GOAL	\N
924	409	11	1413	\N	24	\N	GOAL	\N
925	409	11	1032	\N	53	\N	GOAL	\N
926	409	11	1032	\N	77	\N	GOAL	\N
927	409	11	1286	\N	89	\N	GOAL	\N
928	415	101	1153	\N	59	\N	GOAL	\N
929	415	6	1379	\N	70	\N	GOAL	\N
930	414	17	1618	\N	27	\N	GOAL	\N
931	416	5	1179	\N	11	\N	GOAL	\N
932	416	5	1222	\N	48	\N	GOAL	\N
933	416	2	1258	\N	83	\N	GOAL	\N
934	416	2	1258	\N	94	\N	GOAL	\N
935	417	76	1451	\N	10	\N	GOAL	\N
936	418	102	1182	\N	15	\N	GOAL	\N
937	418	102	1306	\N	60	\N	GOAL	\N
938	418	102	1306	\N	76	\N	GOAL	\N
939	420	12	1365	\N	2	\N	GOAL	\N
940	419	6	1425	\N	14	\N	GOAL	\N
941	419	6	1430	\N	26	\N	GOAL	\N
942	420	100	1766	\N	67	\N	GOAL	\N
943	420	100	1460	\N	85	\N	GOAL	\N
944	422	11	1413	\N	11	\N	GOAL	\N
945	423	7	1099	\N	1	\N	GOAL	\N
946	422	11	1413	\N	37	\N	GOAL	\N
947	423	7	1100	\N	56	\N	GOAL	\N
948	421	99	1755	\N	93	\N	GOAL	\N
949	423	7	1496	\N	63	\N	GOAL	\N
950	423	7	1114	\N	95	\N	GOAL	\N
951	425	1	979	\N	\N	\N	GOAL	\N
952	426	8	1816	\N	16	\N	GOAL	\N
953	426	76	1492	\N	24	\N	GOAL	\N
954	428	102	1557	\N	85	\N	GOAL	\N
955	429	100	1828	\N	\N	\N	GOAL	\N
956	435	12	1672	\N	10	\N	GOAL	\N
957	434	4	1522	\N	33	\N	GOAL	\N
958	431	99	1759	\N	54	\N	GOAL	\N
959	435	15	1054	\N	71	\N	GOAL	\N
960	434	88	1000	\N	90	\N	GOAL	\N
961	782	103	\N	\N	54	\N	GOAL	\N
962	782	103	\N	\N	66	\N	GOAL	\N
963	783	51	1363	\N	12	\N	GOAL	\N
964	783	51	\N	\N	59	\N	GOAL	\N
965	783	53	\N	\N	30	\N	GOAL	\N
966	783	53	\N	\N	45	\N	GOAL	\N
967	783	53	\N	\N	70	\N	GOAL	\N
968	783	53	\N	\N	89	\N	GOAL	\N
969	783	53	\N	\N	90	\N	GOAL	\N
970	784	27	\N	\N	32	\N	GOAL	\N
971	784	27	\N	\N	60	\N	GOAL	\N
972	784	27	\N	\N	90	\N	GOAL	\N
973	784	105	\N	\N	13	\N	GOAL	\N
974	784	105	\N	\N	72	\N	GOAL	\N
975	786	49	\N	\N	2	\N	GOAL	\N
976	786	35	\N	\N	67	\N	GOAL	\N
977	786	49	\N	\N	70	\N	GOAL	\N
978	787	50	\N	\N	11	\N	GOAL	\N
979	789	29	\N	\N	\N	\N	GOAL	\N
980	789	89	\N	\N	\N	\N	GOAL	\N
981	789	89	\N	\N	\N	\N	GOAL	\N
982	789	89	\N	\N	\N	\N	GOAL	\N
983	789	89	\N	\N	\N	\N	GOAL	\N
984	789	89	\N	\N	\N	\N	GOAL	\N
985	789	89	\N	\N	\N	\N	GOAL	\N
986	789	89	\N	\N	\N	\N	GOAL	\N
987	789	89	\N	\N	\N	\N	GOAL	\N
988	790	32	1827	\N	26	\N	GOAL	\N
989	790	39	\N	\N	10	\N	GOAL	\N
990	792	40	\N	\N	78	\N	GOAL	\N
991	788	41	\N	\N	\N	\N	GOAL	\N
992	788	41	\N	\N	\N	\N	GOAL	\N
993	788	41	\N	\N	\N	\N	GOAL	\N
994	788	64	\N	\N	\N	\N	GOAL	\N
995	794	25	\N	\N	82	\N	GOAL	\N
996	794	70	\N	\N	15	\N	GOAL	\N
997	794	70	\N	\N	70	\N	GOAL	\N
998	794	70	\N	\N	85	\N	GOAL	\N
999	796	33	\N	\N	4	\N	GOAL	\N
1000	796	33	\N	\N	24	\N	GOAL	\N
1001	793	26	\N	\N	75	\N	GOAL	\N
1002	800	38	\N	\N	10	\N	GOAL	\N
1003	800	38	\N	\N	45	\N	GOAL	\N
1004	800	44	\N	\N	27	\N	GOAL	\N
1005	800	44	\N	\N	90	\N	GOAL	\N
1006	804	24	\N	\N	19	\N	GOAL	\N
1007	804	65	\N	\N	55	\N	GOAL	\N
1008	804	65	\N	\N	77	\N	GOAL	\N
1009	805	34	\N	\N	63	\N	GOAL	\N
1010	795	56	\N	\N	55	\N	GOAL	\N
1011	795	54	\N	\N	15	\N	GOAL	\N
1012	795	54	\N	\N	28	\N	GOAL	\N
1013	795	54	\N	\N	30	\N	GOAL	\N
1014	795	54	\N	\N	90	\N	GOAL	\N
1015	798	60	\N	\N	38	\N	GOAL	\N
1016	798	61	\N	\N	25	\N	GOAL	\N
1017	799	57	\N	\N	72	\N	GOAL	\N
1018	801	104	\N	\N	11	\N	GOAL	\N
1019	801	69	\N	\N	20	\N	GOAL	\N
1020	802	43	\N	\N	45	\N	GOAL	\N
1021	802	43	\N	\N	57	\N	GOAL	\N
1022	802	48	\N	\N	69	\N	GOAL	\N
1023	803	36	\N	\N	4	\N	GOAL	\N
1024	803	59	\N	\N	19	\N	GOAL	\N
1025	803	59	\N	\N	84	\N	GOAL	\N
1026	328	76	1451	\N	10	\N	GOAL	\N
1027	328	17	1637	\N	40	\N	GOAL	\N
1028	328	76	1184	\N	58	\N	GOAL	\N
1029	320	1	1468	\N	11	\N	GOAL	\N
1030	320	15	1054	\N	28	\N	GOAL	\N
1031	320	1	999	\N	67	\N	GOAL	\N
1032	309	76	1451	\N	21	\N	GOAL	\N
1033	309	76	967	\N	74	\N	GOAL	\N
1034	361	76	1451	\N	20	\N	GOAL	\N
1035	361	76	1184	\N	53	\N	GOAL	\N
1036	441	15	1389	\N	70	\N	GOAL	\N
1037	443	5	1179	\N	2	\N	GOAL	\N
1038	443	5	1179	\N	20	\N	GOAL	\N
1039	443	5	1183	\N	23	\N	GOAL	\N
1040	443	5	1222	\N	28	\N	GOAL	\N
1041	444	4	1522	\N	6	\N	GOAL	\N
1042	441	3	1533	\N	87	\N	GOAL	\N
1043	443	6	1415	\N	23	\N	GOAL	\N
1044	442	87	1404	\N	31	\N	GOAL	\N
1045	442	101	1698	\N	39	\N	GOAL	\N
1046	446	17	1637	\N	21	\N	GOAL	\N
1047	447	76	980	\N	84	\N	GOAL	\N
1048	447	76	980	\N	90	\N	GOAL	\N
1049	448	12	1669	\N	53	\N	GOAL	\N
1050	448	1	1061	\N	66	\N	GOAL	\N
1051	448	1	1065	\N	77	\N	GOAL	\N
1052	448	1	1065	\N	85	\N	GOAL	\N
1053	438	1	1056	\N	37	\N	GOAL	\N
1054	438	1	1453	\N	54	\N	GOAL	\N
1055	438	1	1453	\N	58	\N	GOAL	\N
1056	438	1	1064	\N	63	\N	GOAL	\N
1057	451	12	1232	\N	38	\N	GOAL	\N
1058	453	17	1627	\N	33	\N	GOAL	\N
1059	453	17	1391	\N	40	\N	GOAL	\N
1060	453	17	1618	\N	62	\N	GOAL	\N
1061	453	17	1627	\N	85	\N	GOAL	\N
1062	456	100	1460	\N	5	\N	GOAL	\N
1063	457	101	1703	\N	38	\N	GOAL	\N
1064	457	76	965	\N	70	\N	GOAL	\N
1065	457	76	1451	\N	80	\N	GOAL	\N
1066	454	102	1373	\N	17	\N	GOAL	\N
1067	454	1	999	\N	45	\N	GOAL	\N
1068	452	87	1403	\N	36	\N	GOAL	\N
1069	452	87	1403	\N	43	\N	GOAL	\N
1070	454	102	1565	\N	65	\N	GOAL	\N
1071	454	1	979	\N	85	\N	GOAL	\N
1072	452	15	1054	\N	93	\N	GOAL	\N
1073	462	12	1661	\N	18	\N	GOAL	\N
1074	462	4	1315	\N	35	\N	GOAL	\N
1075	468	102	1311	\N	48	\N	GOAL	\N
1076	468	102	1300	\N	66	\N	GOAL	\N
1077	468	102	1306	\N	69	\N	GOAL	\N
1078	468	102	1556	\N	73	\N	GOAL	\N
1079	468	13	1335	\N	60	\N	GOAL	\N
1080	468	102	1306	\N	86	\N	GOAL	\N
1081	467	99	1764	\N	55	\N	GOAL	\N
1082	467	99	1464	\N	65	\N	GOAL	\N
1083	465	76	980	\N	11	\N	GOAL	\N
1084	465	15	1216	\N	31	\N	GOAL	\N
1085	465	76	1450	\N	78	\N	GOAL	\N
1086	465	15	1054	\N	84	\N	GOAL	\N
1087	465	76	1451	\N	94	\N	GOAL	\N
1088	464	2	1304	\N	7	\N	GOAL	\N
1089	464	17	1637	\N	15	\N	GOAL	\N
1090	464	2	1002	\N	65	\N	GOAL	\N
1091	437	11	1286	\N	12	\N	GOAL	\N
1092	437	11	1026	\N	14	\N	GOAL	\N
1093	437	102	1306	\N	67	\N	GOAL	\N
1094	433	76	965	\N	64	\N	GOAL	\N
1095	470	4	1115	\N	45	\N	GOAL	\N
1096	472	12	1669	\N	90	\N	GOAL	\N
1097	472	99	1759	\N	24	\N	GOAL	\N
1098	471	102	1311	\N	45	\N	GOAL	\N
1099	471	2	1308	\N	90	\N	GOAL	\N
1100	475	7	1099	\N	15	\N	GOAL	\N
1101	476	76	1451	\N	17	\N	GOAL	\N
1102	476	5	1185	\N	24	\N	GOAL	\N
1103	476	76	1451	\N	41	\N	GOAL	\N
1104	477	15	1389	\N	65	\N	GOAL	\N
1105	475	7	1089	\N	85	\N	GOAL	\N
1106	478	11	1035	\N	45	\N	GOAL	\N
1107	478	11	1031	\N	49	\N	GOAL	\N
1108	478	11	1031	\N	55	\N	GOAL	\N
1109	479	102	1260	\N	71	\N	GOAL	\N
1110	807	107	1836	\N	45	\N	GOAL	\N
1111	484	87	1205	\N	63	\N	GOAL	\N
1112	482	101	1733	\N	63	\N	GOAL	\N
1113	482	101	1731	\N	96	\N	GOAL	\N
1114	482	5	1180	\N	17	\N	GOAL	\N
1115	481	99	1096	\N	12	\N	GOAL	\N
1116	481	99	1759	\N	24	\N	GOAL	\N
1117	481	99	1365	\N	32	\N	GOAL	\N
1118	480	12	1294	\N	73	\N	GOAL	\N
1119	486	88	974	\N	63	\N	GOAL	\N
1120	486	100	1786	\N	58	\N	GOAL	\N
1121	808	1	999	\N	28	\N	GOAL	\N
1122	808	110	1837	\N	65	\N	GOAL	\N
1123	488	17	1210	\N	9	\N	GOAL	\N
1124	488	17	1210	\N	18	\N	GOAL	\N
1125	488	17	1614	\N	83	\N	GOAL	\N
1126	809	76	1838	\N	76	\N	GOAL	\N
1127	810	109	1839	\N	17	\N	GOAL	\N
1128	810	109	1840	\N	70	\N	GOAL	\N
1129	811	106	1841	\N	54	\N	GOAL	\N
1130	811	11	1036	\N	55	\N	GOAL	\N
1131	811	11	1413	\N	33	\N	GOAL	\N
1132	811	11	1413	\N	59	\N	GOAL	\N
1133	491	87	1136	\N	45	\N	GOAL	\N
1134	491	100	1460	\N	58	\N	GOAL	\N
1135	491	87	1403	\N	72	\N	GOAL	\N
1136	812	107	1842	\N	43	\N	GOAL	\N
1137	812	72	1843	\N	90	\N	GOAL	\N
1138	813	1	983	\N	33	\N	GOAL	\N
1139	813	1	1061	\N	44	\N	GOAL	\N
1140	813	1	983	\N	60	\N	GOAL	\N
1141	814	110	1844	\N	92	\N	GOAL	\N
1142	494	6	1233	\N	61	\N	GOAL	\N
1143	494	6	1887	\N	68	\N	GOAL	\N
1144	495	17	1253	\N	45	\N	GOAL	\N
1145	495	17	1637	\N	47	\N	GOAL	\N
1146	495	17	1637	\N	67	\N	GOAL	\N
1147	495	17	1637	\N	83	\N	GOAL	\N
1148	815	11	1479	\N	83	\N	GOAL	\N
1149	816	108	1845	\N	16	\N	GOAL	\N
1150	489	102	1300	\N	40	\N	GOAL	\N
1151	816	1	979	\N	75	\N	GOAL	\N
1152	496	15	1054	\N	58	\N	GOAL	\N
1153	816	1	983	\N	92	\N	GOAL	\N
1154	817	76	981	\N	35	\N	GOAL	\N
1155	817	109	1839	\N	42	\N	GOAL	\N
1156	817	109	1840	\N	62	\N	GOAL	\N
1157	818	72	1846	\N	70	\N	GOAL	\N
1158	818	72	1847	\N	84	\N	GOAL	\N
1159	818	72	1843	\N	90	\N	GOAL	\N
1160	819	11	1025	\N	21	\N	GOAL	\N
1161	820	110	1848	\N	3	\N	GOAL	\N
1162	820	76	1849	\N	20	\N	GOAL	\N
1163	820	76	1838	\N	28	\N	GOAL	\N
1164	820	76	971	\N	32	\N	GOAL	\N
1165	507	13	1335	\N	90	\N	GOAL	\N
1166	507	13	1336	\N	71	\N	GOAL	\N
1167	821	1	1056	\N	25	\N	GOAL	\N
1168	821	1	979	\N	76	\N	GOAL	\N
1169	821	109	1839	\N	87	\N	GOAL	\N
1170	499	99	1365	\N	19	\N	GOAL	\N
1171	499	99	1759	\N	57	\N	GOAL	\N
1172	838	1	1056	\N	9	\N	GOAL	\N
1173	838	1	1064	\N	62	\N	GOAL	\N
1174	838	1	983	\N	83	\N	GOAL	\N
1175	502	17	1637	\N	\N	\N	GOAL	\N
1176	502	88	1221	\N	\N	\N	GOAL	\N
1177	502	88	1221	\N	\N	\N	GOAL	\N
1178	500	102	1557	\N	66	\N	GOAL	\N
1179	822	112	1829	\N	53	\N	GOAL	\N
1180	822	112	1830	\N	45	\N	GOAL	\N
1181	822	113	1831	\N	38	\N	GOAL	\N
1182	823	116	1832	\N	67	\N	GOAL	\N
1183	823	115	1833	\N	90	\N	GOAL	\N
1184	839	11	\N	\N	\N	\N	GOAL	\N
1185	839	11	\N	\N	\N	\N	GOAL	\N
1186	839	11	\N	\N	\N	\N	GOAL	\N
1187	839	109	\N	\N	\N	\N	GOAL	\N
1188	824	119	1885	\N	\N	\N	GOAL	\N
1189	825	114	1878	\N	\N	\N	GOAL	\N
1190	825	114	1879	\N	\N	\N	GOAL	\N
1191	825	114	1880	\N	\N	\N	GOAL	\N
1192	825	114	1881	\N	\N	\N	GOAL	\N
1193	825	114	1882	\N	\N	\N	GOAL	\N
1194	825	111	1883	\N	\N	\N	GOAL	\N
1195	825	111	1884	\N	\N	\N	GOAL	\N
1196	828	11	1032	\N	47	\N	GOAL	\N
1197	828	11	1413	\N	51	\N	GOAL	\N
1198	828	11	1413	\N	67	\N	GOAL	\N
1199	829	123	1877	\N	65	\N	GOAL	\N
1200	829	123	1851	\N	79	\N	GOAL	\N
1201	840	1	997	\N	43	\N	GOAL	\N
1202	840	11	1013	\N	63	\N	GOAL	\N
1203	840	1	983	\N	72	\N	GOAL	\N
1204	505	101	1445	\N	21	\N	GOAL	\N
1205	505	100	1766	\N	12	\N	GOAL	\N
1206	505	101	1619	\N	61	\N	GOAL	\N
1207	505	101	1731	\N	85	\N	GOAL	\N
1208	505	100	1455	\N	65	\N	GOAL	\N
1209	506	2	1405	\N	13	\N	GOAL	\N
1210	506	2	1002	\N	47	\N	GOAL	\N
1211	506	12	1680	\N	63	\N	GOAL	\N
1212	512	5	1222	\N	\N	\N	GOAL	\N
1213	509	99	1096	\N	42	\N	GOAL	\N
1214	509	13	1333	\N	16	\N	GOAL	\N
1215	515	76	982	\N	12	\N	GOAL	\N
1216	515	76	980	\N	39	\N	GOAL	\N
1217	515	76	1450	\N	57	\N	GOAL	\N
1218	515	17	1637	\N	82	\N	GOAL	\N
1219	516	2	1247	\N	72	\N	GOAL	\N
1220	517	101	1070	\N	90	\N	GOAL	\N
1221	513	8	1381	\N	24	\N	GOAL	\N
1222	513	8	1886	\N	51	\N	GOAL	\N
1223	513	3	1314	\N	83	\N	GOAL	\N
1224	514	6	1233	\N	24	\N	GOAL	\N
1225	514	6	1233	\N	70	\N	GOAL	\N
1226	514	6	978	\N	82	\N	GOAL	\N
1227	514	4	1223	\N	36	\N	GOAL	\N
1228	514	4	1223	\N	87	\N	GOAL	\N
1229	518	102	1408	\N	15	\N	GOAL	\N
1230	518	102	1556	\N	21	\N	GOAL	\N
1231	518	100	1460	\N	68	\N	GOAL	\N
1232	518	102	1311	\N	74	\N	GOAL	\N
1233	518	100	1460	\N	78	\N	GOAL	\N
1234	518	102	1331	\N	86	\N	GOAL	\N
1235	518	102	1557	\N	93	\N	GOAL	\N
1236	832	115	1874	\N	\N	\N	GOAL	\N
1237	832	115	1874	\N	\N	\N	GOAL	\N
1238	831	117	1875	\N	\N	\N	GOAL	\N
1239	831	117	1875	\N	\N	\N	GOAL	\N
1240	831	117	1876	\N	\N	\N	GOAL	\N
1241	833	124	1862	\N	\N	\N	GOAL	\N
1242	833	123	1853	\N	\N	\N	GOAL	\N
1243	520	87	1136	\N	80	\N	GOAL	\N
1244	526	12	1232	\N	88	\N	GOAL	\N
1245	834	125	1860	\N	17	\N	GOAL	\N
1246	834	125	1860	\N	19	\N	GOAL	\N
1247	834	125	1871	\N	\N	\N	GOAL	\N
1248	834	125	1872	\N	71	\N	GOAL	\N
1249	834	125	1873	\N	\N	\N	GOAL	\N
1250	523	1	979	\N	66	\N	GOAL	\N
1251	836	119	1868	\N	\N	\N	GOAL	\N
1252	836	119	1869	\N	\N	\N	GOAL	\N
1253	836	119	1870	\N	\N	\N	GOAL	\N
1254	837	113	1864	\N	\N	\N	GOAL	\N
1255	837	113	1864	\N	\N	\N	GOAL	\N
1256	837	114	1867	\N	\N	\N	GOAL	\N
1257	522	100	1828	\N	49	\N	GOAL	\N
1258	522	100	1775	\N	91	\N	GOAL	\N
1259	528	99	1759	\N	33	\N	GOAL	\N
1260	528	99	1759	\N	55	\N	GOAL	\N
1261	528	5	1179	\N	81	\N	GOAL	\N
1262	527	4	1223	\N	17	\N	GOAL	\N
1263	527	101	1445	\N	15	\N	GOAL	\N
1264	841	127	\N	\N	\N	\N	GOAL	\N
1265	842	128	\N	\N	\N	\N	GOAL	\N
1266	842	128	\N	\N	\N	\N	GOAL	\N
1267	842	76	\N	\N	\N	\N	GOAL	\N
1268	842	128	\N	\N	\N	\N	GOAL	\N
1269	842	76	\N	\N	\N	\N	GOAL	\N
1270	843	74	\N	\N	\N	\N	GOAL	\N
1271	843	2	\N	\N	\N	\N	GOAL	\N
1272	843	74	\N	\N	\N	\N	GOAL	\N
1273	843	2	\N	\N	\N	\N	GOAL	\N
1274	843	74	\N	\N	\N	\N	GOAL	\N
1275	843	2	\N	\N	\N	\N	GOAL	\N
1276	843	74	\N	\N	\N	\N	GOAL	\N
1277	843	2	\N	\N	\N	\N	GOAL	\N
1278	843	2	\N	\N	\N	\N	GOAL	\N
1279	844	11	\N	\N	13	\N	GOAL	\N
1280	844	11	\N	\N	49	\N	GOAL	\N
1281	844	126	\N	\N	62	\N	GOAL	\N
1282	845	11	\N	\N	\N	\N	GOAL	\N
1283	845	127	\N	\N	\N	\N	GOAL	\N
1284	845	127	\N	\N	\N	\N	GOAL	\N
1285	846	2	\N	\N	\N	\N	GOAL	\N
1286	846	128	\N	\N	\N	\N	GOAL	\N
1287	846	2	\N	\N	\N	\N	GOAL	\N
1288	846	128	\N	\N	\N	\N	GOAL	\N
1289	846	2	\N	\N	\N	\N	GOAL	\N
1290	846	128	\N	\N	\N	\N	GOAL	\N
1291	846	128	\N	\N	\N	\N	GOAL	\N
1292	846	2	\N	\N	\N	\N	GOAL	\N
1293	846	128	\N	\N	\N	\N	GOAL	\N
1294	846	2	\N	\N	\N	\N	GOAL	\N
1295	846	128	\N	\N	\N	\N	GOAL	\N
1296	536	101	1733	\N	2	\N	GOAL	\N
1297	536	1	1064	\N	46	\N	GOAL	\N
1298	536	1	1468	\N	62	\N	GOAL	\N
1299	847	128	\N	\N	61	\N	GOAL	\N
1300	530	88	1221	\N	62	\N	GOAL	\N
1301	533	3	1552	\N	33	\N	GOAL	\N
1302	531	13	1336	\N	93	\N	GOAL	\N
1303	534	15	1042	\N	85	\N	GOAL	\N
1304	533	3	1544	\N	46	\N	GOAL	\N
1305	533	3	1463	\N	92	\N	GOAL	\N
1306	850	113	1863	\N	\N	\N	GOAL	\N
1307	850	113	1864	\N	\N	\N	GOAL	\N
1308	850	113	1865	\N	\N	\N	GOAL	\N
1309	850	111	1866	\N	\N	\N	GOAL	\N
1310	535	99	1759	\N	9	\N	GOAL	\N
1311	535	99	1754	\N	30	\N	GOAL	\N
1312	851	122	1835	\N	12	\N	GOAL	\N
1313	851	122	1854	\N	23	\N	GOAL	\N
1314	851	122	1855	\N	37	\N	GOAL	\N
1315	851	122	1835	\N	39	\N	GOAL	\N
1316	851	122	1855	\N	62	\N	GOAL	\N
1317	851	122	1856	\N	76	\N	GOAL	\N
1318	851	122	1857	\N	81	\N	GOAL	\N
1319	851	122	1856	\N	83	\N	GOAL	\N
1320	849	114	1867	\N	\N	\N	GOAL	\N
1321	852	125	1859	\N	\N	\N	GOAL	\N
1322	852	125	1860	\N	\N	\N	GOAL	\N
1323	852	124	1861	\N	\N	\N	GOAL	\N
1324	852	124	1862	\N	\N	\N	GOAL	\N
1325	855	116	1858	\N	51	\N	GOAL	\N
1326	853	123	1850	\N	2	\N	GOAL	\N
1327	853	123	1851	\N	23	\N	GOAL	\N
1328	853	123	1852	\N	30	\N	GOAL	\N
1329	853	123	1853	\N	34	\N	GOAL	\N
1330	853	123	1853	\N	40	\N	GOAL	\N
1331	537	100	1455	\N	29	\N	GOAL	\N
1332	537	76	981	\N	76	\N	GOAL	\N
1333	835	111	1866	\N	38	\N	GOAL	\N
1334	466	87	1376	\N	79	\N	GOAL	\N
1335	466	87	1376	\N	90	\N	GOAL	\N
1336	546	3	1552	\N	2	\N	GOAL	\N
1337	546	3	1888	\N	20	\N	GOAL	\N
1338	546	3	1463	\N	85	\N	GOAL	\N
1339	546	101	1070	\N	65	\N	GOAL	\N
1340	539	13	1336	\N	12	\N	GOAL	\N
1341	539	13	1415	\N	20	\N	GOAL	\N
1342	539	2	1309	\N	34	\N	GOAL	\N
1343	542	5	1183	\N	15	\N	GOAL	\N
1344	544	12	1292	\N	9	\N	GOAL	\N
1345	544	12	1292	\N	24	\N	GOAL	\N
1346	545	87	1403	\N	11	\N	GOAL	\N
1347	543	1	1453	\N	79	\N	GOAL	\N
1348	543	99	1759	\N	94	\N	GOAL	\N
1349	548	15	1053	\N	37	\N	GOAL	\N
1350	548	100	1784	\N	67	\N	GOAL	\N
1351	547	11	1413	\N	21	\N	GOAL	\N
1352	547	11	1028	\N	26	\N	GOAL	\N
1353	547	11	1035	\N	29	\N	GOAL	\N
1354	541	6	1887	\N	61	\N	GOAL	\N
1355	541	7	1114	\N	94	\N	GOAL	\N
1356	549	76	1450	\N	26	\N	GOAL	\N
1357	555	102	1566	\N	50	\N	GOAL	\N
1358	555	99	1752	\N	64	\N	GOAL	\N
1359	552	100	1784	\N	60	\N	GOAL	\N
1360	557	87	\N	\N	45	\N	GOAL	\N
1361	556	8	\N	\N	\N	\N	GOAL	\N
1362	557	1	1064	\N	81	\N	GOAL	\N
1363	550	17	1637	\N	78	\N	GOAL	\N
1364	556	8	\N	\N	\N	\N	GOAL	\N
1365	554	13	\N	\N	\N	\N	GOAL	\N
1366	856	11	1413	\N	64	\N	GOAL	\N
1367	857	115	1833	\N	16	\N	GOAL	\N
1368	857	115	1889	\N	89	\N	GOAL	\N
1369	858	116	1832	\N	58	\N	GOAL	\N
1370	858	116	1891	\N	78	\N	GOAL	\N
1371	862	124	1890	\N	78	\N	GOAL	\N
1372	561	13	1335	\N	35	\N	GOAL	\N
1373	562	101	1445	\N	39	\N	GOAL	\N
1374	562	7	1098	\N	64	\N	GOAL	\N
1375	562	101	1619	\N	79	\N	GOAL	\N
1376	560	17	1633	\N	65	\N	GOAL	\N
1377	560	17	1637	\N	79	\N	GOAL	\N
1378	560	100	1460	\N	75	\N	GOAL	\N
1379	566	2	1247	\N	33	\N	GOAL	\N
1380	565	8	1825	\N	17	\N	GOAL	\N
1381	563	5	1164	\N	54	\N	GOAL	\N
1382	563	12	1232	\N	86	\N	GOAL	\N
1383	568	11	1413	\N	71	\N	GOAL	\N
1384	564	88	974	\N	46	\N	GOAL	\N
1385	564	87	1165	\N	61	\N	GOAL	\N
1386	564	88	1221	\N	84	\N	GOAL	\N
1387	564	87	1403	\N	90	\N	GOAL	\N
1388	569	11	1035	\N	28	\N	GOAL	\N
1389	570	17	1637	\N	44	\N	GOAL	\N
1390	569	11	1286	\N	44	\N	GOAL	\N
1391	575	100	1460	\N	47	\N	GOAL	\N
1392	569	11	1035	\N	46	\N	GOAL	\N
1393	570	101	1070	\N	53	\N	GOAL	\N
1394	575	1	983	\N	51	\N	GOAL	\N
1395	570	17	1637	\N	\N	\N	GOAL	\N
1396	572	2	1310	\N	45	\N	GOAL	\N
1397	572	76	1451	\N	50	\N	GOAL	\N
1398	578	102	1300	\N	3	\N	GOAL	\N
1399	576	13	1336	\N	70	\N	GOAL	\N
1400	574	12	1294	\N	33	\N	GOAL	\N
1401	574	12	1661	\N	59	\N	GOAL	\N
1402	574	12	1232	\N	92	\N	GOAL	\N
1403	574	87	1219	\N	29	\N	GOAL	\N
1404	574	87	1205	\N	72	\N	GOAL	\N
1405	573	8	1381	\N	9	\N	GOAL	\N
1406	573	8	1186	\N	81	\N	GOAL	\N
1407	577	99	1365	\N	28	\N	GOAL	\N
1408	460	11	1413	\N	5	\N	GOAL	\N
1409	460	11	1035	\N	38	\N	GOAL	\N
1410	460	11	1413	\N	77	\N	GOAL	\N
1411	460	1	1063	\N	81	\N	GOAL	\N
1412	510	11	1472	\N	6	\N	GOAL	\N
1413	510	87	1219	\N	18	\N	GOAL	\N
1414	510	11	1472	\N	44	\N	GOAL	\N
1415	510	11	1413	\N	56	\N	GOAL	\N
1416	459	7	1081	\N	39	\N	GOAL	\N
1417	459	7	1114	\N	55	\N	GOAL	\N
1418	459	7	1098	\N	67	\N	GOAL	\N
1419	459	100	1460	\N	21	\N	GOAL	\N
1420	558	5	1179	\N	55	\N	GOAL	\N
1421	580	1	983	\N	7	\N	GOAL	\N
1422	580	6	1418	\N	15	\N	GOAL	\N
1423	580	1	997	\N	65	\N	GOAL	\N
1424	584	76	980	\N	75	\N	GOAL	\N
1425	583	3	1552	\N	6	\N	GOAL	\N
1426	581	15	1216	\N	12	\N	GOAL	\N
1427	581	15	1389	\N	13	\N	GOAL	\N
1428	581	15	1272	\N	20	\N	GOAL	\N
1429	581	15	1314	\N	22	\N	GOAL	\N
1430	581	15	1216	\N	28	\N	GOAL	\N
1431	581	15	1216	\N	68	\N	GOAL	\N
1432	581	17	1637	\N	3	\N	GOAL	\N
1433	581	17	1633	\N	60	\N	GOAL	\N
1434	588	7	1114	\N	37	\N	GOAL	\N
1435	587	11	1035	\N	52	\N	GOAL	\N
1436	588	7	1100	\N	49	\N	GOAL	\N
1437	587	11	1035	\N	66	\N	GOAL	\N
1438	579	13	1415	\N	5	\N	GOAL	\N
1439	579	88	\N	\N	\N	\N	GOAL	\N
1440	579	88	\N	\N	\N	\N	GOAL	\N
1441	586	4	\N	\N	\N	\N	GOAL	\N
1442	586	4	\N	\N	\N	\N	GOAL	\N
1443	830	120	1892	\N	\N	\N	GOAL	\N
1444	830	120	1892	\N	\N	\N	GOAL	\N
1445	827	122	1834	\N	\N	\N	GOAL	\N
1446	827	122	1835	\N	\N	\N	GOAL	\N
1447	848	121	1893	\N	\N	\N	GOAL	\N
1448	871	119	1869	\N	\N	\N	GOAL	\N
1449	871	119	1895	\N	\N	\N	GOAL	\N
1450	871	119	1896	\N	\N	\N	GOAL	\N
1451	871	121	1893	\N	\N	\N	GOAL	\N
1452	871	121	1894	\N	\N	\N	GOAL	\N
1453	559	3	1544	\N	45	\N	GOAL	\N
1454	559	6	1414	\N	75	\N	GOAL	\N
1455	591	1	1056	\N	16	\N	GOAL	\N
1456	591	1	997	\N	26	\N	GOAL	\N
1457	591	1	979	\N	60	\N	GOAL	\N
1458	591	1	983	\N	74	\N	GOAL	\N
1459	591	1	979	\N	78	\N	GOAL	\N
1460	591	3	1544	\N	80	\N	GOAL	\N
1461	591	1	1454	\N	\N	\N	GOAL	\N
1462	864	121	1903	\N	\N	\N	GOAL	\N
1463	864	122	1857	\N	\N	\N	GOAL	\N
1464	863	120	1904	\N	\N	\N	GOAL	\N
1465	865	115	1902	\N	\N	\N	GOAL	\N
1466	865	115	\N	\N	\N	\N	GOAL	\N
1467	866	117	1875	\N	\N	\N	GOAL	\N
1468	866	117	1899	\N	\N	\N	GOAL	\N
1469	866	118	1900	\N	\N	\N	GOAL	\N
1470	866	118	1901	\N	\N	\N	GOAL	\N
1471	590	6	1887	\N	13	\N	GOAL	\N
1472	590	13	1415	\N	51	\N	GOAL	\N
1473	590	13	1415	\N	69	\N	GOAL	\N
1474	867	125	1897	\N	\N	\N	GOAL	\N
1475	868	111	1898	\N	\N	\N	GOAL	\N
1476	868	111	1898	\N	\N	\N	GOAL	\N
1477	869	124	1862	\N	18	\N	GOAL	\N
1478	870	113	1905	\N	\N	\N	GOAL	\N
1479	870	113	1864	\N	\N	\N	GOAL	\N
1480	870	113	1906	\N	\N	\N	GOAL	\N
1481	869	124	1861	\N	52	\N	GOAL	\N
1482	595	87	1577	\N	\N	\N	GOAL	\N
1483	594	100	1784	\N	\N	\N	GOAL	\N
1484	592	7	1078	\N	\N	\N	GOAL	\N
1485	592	7	1257	\N	\N	\N	GOAL	\N
1486	597	102	1186	\N	17	\N	GOAL	\N
1487	596	5	1180	\N	19	\N	GOAL	\N
1488	596	17	1253	\N	22	\N	GOAL	\N
1489	597	76	972	\N	37	\N	GOAL	\N
1490	596	17	1637	\N	84	\N	GOAL	\N
1491	596	17	1633	\N	90	\N	GOAL	\N
1492	598	101	1367	\N	50	\N	GOAL	\N
1493	598	101	1445	\N	56	\N	GOAL	\N
1494	601	13	1345	\N	21	\N	GOAL	\N
1495	601	13	1415	\N	61	\N	GOAL	\N
1496	600	12	\N	\N	\N	\N	GOAL	\N
1497	600	12	\N	\N	\N	\N	GOAL	\N
1498	600	17	\N	\N	\N	\N	GOAL	\N
1499	603	1	1468	\N	66	\N	GOAL	\N
1500	603	1	1453	\N	74	\N	GOAL	\N
1501	603	1	979	\N	77	\N	GOAL	\N
1502	603	1	979	\N	90	\N	GOAL	\N
1503	606	87	1165	\N	24	\N	GOAL	\N
1504	605	4	\N	\N	\N	\N	GOAL	\N
1505	605	4	\N	\N	\N	\N	GOAL	\N
1506	605	7	\N	\N	\N	\N	GOAL	\N
1507	607	5	\N	\N	\N	\N	GOAL	\N
1508	607	5	\N	\N	\N	\N	GOAL	\N
1509	604	101	\N	\N	\N	\N	GOAL	\N
1510	872	118	\N	\N	\N	\N	GOAL	\N
1511	872	115	\N	\N	\N	\N	GOAL	\N
1512	872	115	\N	\N	\N	\N	GOAL	\N
1513	873	122	\N	\N	\N	\N	GOAL	\N
1514	873	122	\N	\N	\N	\N	GOAL	\N
1515	879	125	1859	\N	12	\N	GOAL	\N
1516	874	120	\N	\N	\N	\N	GOAL	\N
1517	879	11	1016	\N	36	\N	GOAL	\N
1518	879	11	1472	\N	90	\N	GOAL	\N
1519	875	123	\N	\N	\N	\N	GOAL	\N
1520	875	123	\N	\N	\N	\N	GOAL	\N
1521	875	123	\N	\N	\N	\N	GOAL	\N
1522	876	112	\N	\N	\N	\N	GOAL	\N
1523	876	112	\N	\N	\N	\N	GOAL	\N
1524	877	114	\N	\N	\N	\N	GOAL	\N
1525	878	116	\N	\N	\N	\N	GOAL	\N
1526	878	116	\N	\N	\N	\N	GOAL	\N
1527	878	117	\N	\N	\N	\N	GOAL	\N
1528	599	11	1020	\N	\N	\N	GOAL	\N
1529	599	11	1413	\N	\N	\N	GOAL	\N
1530	608	8	1186	\N	\N	\N	GOAL	\N
1531	608	8	\N	\N	\N	\N	GOAL	\N
1532	880	105	\N	\N	\N	\N	GOAL	\N
1533	880	105	\N	\N	\N	\N	GOAL	\N
1534	880	105	\N	\N	\N	\N	GOAL	\N
1535	880	105	\N	\N	\N	\N	GOAL	\N
1536	881	54	\N	\N	\N	\N	GOAL	\N
1537	881	41	\N	\N	\N	\N	GOAL	\N
1538	882	53	\N	\N	\N	\N	GOAL	\N
1539	882	66	\N	\N	\N	\N	GOAL	\N
1540	886	37	\N	\N	\N	\N	GOAL	\N
1541	886	37	\N	\N	\N	\N	GOAL	\N
1542	886	37	\N	\N	\N	\N	GOAL	\N
1543	886	37	\N	\N	\N	\N	GOAL	\N
1544	886	28	\N	\N	\N	\N	GOAL	\N
1545	885	42	\N	\N	\N	\N	GOAL	\N
1546	885	42	\N	\N	\N	\N	GOAL	\N
1547	885	34	\N	\N	\N	\N	GOAL	\N
1548	885	34	\N	\N	\N	\N	GOAL	\N
1549	887	69	\N	\N	\N	\N	GOAL	\N
1550	887	69	\N	\N	\N	\N	GOAL	\N
1551	887	69	\N	\N	\N	\N	GOAL	\N
1552	888	33	\N	\N	\N	\N	GOAL	\N
1553	890	52	\N	\N	\N	\N	GOAL	\N
1554	890	52	\N	\N	\N	\N	GOAL	\N
1555	889	50	\N	\N	\N	\N	GOAL	\N
1556	889	50	\N	\N	\N	\N	GOAL	\N
1557	889	50	\N	\N	\N	\N	GOAL	\N
1558	883	58	\N	\N	\N	\N	GOAL	\N
1559	883	58	\N	\N	\N	\N	GOAL	\N
1560	883	58	\N	\N	\N	\N	GOAL	\N
1561	884	65	\N	\N	\N	\N	GOAL	\N
1562	884	27	\N	\N	\N	\N	GOAL	\N
1563	894	23	1400	\N	20	\N	GOAL	\N
1564	894	23	\N	\N	\N	\N	GOAL	\N
1565	894	23	1400	\N	\N	\N	GOAL	\N
1566	891	61	\N	\N	\N	\N	GOAL	\N
1567	892	30	\N	\N	\N	\N	GOAL	\N
1568	892	30	\N	\N	\N	\N	GOAL	\N
1569	896	64	\N	\N	\N	\N	GOAL	\N
1570	896	64	\N	\N	\N	\N	GOAL	\N
1571	896	56	\N	\N	\N	\N	GOAL	\N
1572	897	89	\N	\N	\N	\N	GOAL	\N
1573	897	32	\N	\N	\N	\N	GOAL	\N
1574	897	32	\N	\N	\N	\N	GOAL	\N
1575	538	11	1035	\N	24	\N	GOAL	\N
1576	538	11	1035	\N	58	\N	GOAL	\N
1577	538	11	1413	\N	79	\N	GOAL	\N
1578	612	1	1063	\N	3	\N	GOAL	\N
1579	613	5	1179	\N	81	\N	GOAL	\N
1580	615	13	1336	\N	35	\N	GOAL	\N
1581	615	13	1415	\N	45	\N	GOAL	\N
1582	617	87	\N	\N	\N	\N	GOAL	\N
1583	617	87	\N	\N	\N	\N	GOAL	\N
1584	614	15	1216	\N	23	\N	GOAL	\N
1585	614	7	1098	\N	7	\N	GOAL	\N
1586	611	88	989	\N	29	\N	GOAL	\N
1587	611	88	1653	\N	45	\N	GOAL	\N
1588	616	101	1445	\N	45	\N	GOAL	\N
1589	610	100	1784	\N	63	\N	GOAL	\N
1590	609	8	1381	\N	20	\N	GOAL	\N
1591	609	76	972	\N	61	\N	GOAL	\N
1592	440	7	1088	\N	24	\N	GOAL	\N
1593	899	113	\N	\N	\N	\N	GOAL	\N
1594	899	113	\N	\N	\N	\N	GOAL	\N
1595	899	113	\N	\N	\N	\N	GOAL	\N
1596	899	113	\N	\N	\N	\N	GOAL	\N
1597	899	113	\N	\N	\N	\N	GOAL	\N
1598	621	87	1219	\N	57	\N	GOAL	\N
1599	621	87	1586	\N	80	\N	GOAL	\N
1600	621	17	1637	\N	\N	\N	GOAL	\N
1601	621	17	1637	\N	\N	\N	GOAL	\N
1602	624	88	\N	\N	\N	\N	GOAL	\N
1603	624	88	\N	\N	\N	\N	GOAL	\N
1604	624	4	\N	\N	\N	\N	GOAL	\N
1605	622	7	\N	\N	\N	\N	GOAL	\N
1606	623	3	\N	\N	\N	\N	GOAL	\N
1607	620	8	1381	\N	46	\N	GOAL	\N
1608	626	12	1290	\N	70	\N	GOAL	\N
1609	628	76	1451	\N	5	\N	GOAL	\N
1610	628	76	1451	\N	32	\N	GOAL	\N
1611	503	4	1128	\N	31	\N	GOAL	\N
1612	503	76	\N	\N	\N	\N	GOAL	\N
1613	503	76	1451	\N	48	\N	GOAL	\N
1614	503	4	1223	\N	58	\N	GOAL	\N
1615	503	76	968	\N	72	\N	GOAL	\N
1616	902	11	1032	\N	3	\N	GOAL	\N
1617	902	122	\N	\N	\N	\N	GOAL	\N
1618	902	122	\N	\N	\N	\N	GOAL	\N
1619	902	122	\N	\N	\N	\N	GOAL	\N
1620	902	122	\N	\N	\N	\N	GOAL	\N
1621	901	119	\N	\N	\N	\N	GOAL	\N
1622	901	119	\N	\N	\N	\N	GOAL	\N
1623	901	115	\N	\N	\N	\N	GOAL	\N
1624	901	115	\N	\N	\N	\N	GOAL	\N
1625	901	115	\N	\N	\N	\N	GOAL	\N
1626	903	123	\N	\N	\N	\N	GOAL	\N
1627	906	130	1908	\N	20	\N	GOAL	\N
1628	906	131	1910	\N	21	\N	GOAL	\N
1629	906	130	1907	\N	30	\N	GOAL	\N
1630	906	130	1909	\N	37	\N	GOAL	\N
1631	906	131	1911	\N	51	\N	GOAL	\N
1632	906	131	1912	\N	56	\N	GOAL	\N
1633	906	131	1910	\N	60	\N	GOAL	\N
1634	906	130	1907	\N	71	\N	GOAL	\N
1635	906	130	1913	\N	79	\N	GOAL	\N
1636	907	129	1914	\N	32	\N	GOAL	\N
1637	498	1	1057	\N	45	\N	GOAL	\N
1638	908	133	1915	\N	42	\N	GOAL	\N
1639	908	133	1916	\N	72	\N	GOAL	\N
1640	909	135	\N	\N	\N	\N	GOAL	\N
1641	909	136	\N	\N	\N	\N	GOAL	\N
1642	439	100	1784	\N	1	\N	GOAL	\N
1643	910	130	\N	\N	\N	\N	GOAL	\N
1644	439	11	1413	\N	48	\N	GOAL	\N
1645	497	7	1098	\N	52	\N	GOAL	\N
1646	439	11	1413	\N	68	\N	GOAL	\N
1647	911	132	\N	\N	15	\N	GOAL	\N
1648	911	132	\N	\N	28	\N	GOAL	\N
1649	911	132	\N	\N	77	\N	GOAL	\N
1650	912	133	\N	\N	\N	\N	GOAL	\N
1651	912	133	\N	\N	\N	\N	GOAL	\N
1652	912	135	\N	\N	\N	\N	GOAL	\N
1653	913	136	\N	\N	\N	\N	GOAL	\N
1654	504	8	1186	\N	62	\N	GOAL	\N
1655	913	134	\N	\N	\N	\N	GOAL	\N
1656	913	134	\N	\N	\N	\N	GOAL	\N
1657	450	4	1223	\N	18	\N	GOAL	\N
1658	450	4	1522	\N	40	\N	GOAL	\N
1659	450	11	1032	\N	64	\N	GOAL	\N
1660	915	131	\N	\N	\N	\N	GOAL	\N
1661	915	131	\N	\N	\N	\N	GOAL	\N
1662	915	129	\N	\N	\N	\N	GOAL	\N
1663	915	129	\N	\N	\N	\N	GOAL	\N
1664	915	129	\N	\N	\N	\N	GOAL	\N
1665	915	129	\N	\N	\N	\N	GOAL	\N
1666	914	130	\N	\N	\N	\N	GOAL	\N
1667	914	132	\N	\N	\N	\N	GOAL	\N
1668	917	134	\N	\N	\N	\N	GOAL	\N
1669	593	11	1025	\N	20	\N	GOAL	\N
1670	593	11	1032	\N	74	\N	GOAL	\N
1671	918	130	\N	\N	\N	\N	GOAL	\N
1672	918	130	\N	\N	\N	\N	GOAL	\N
1673	918	130	\N	\N	\N	\N	GOAL	\N
1674	918	130	\N	\N	\N	\N	GOAL	\N
1675	918	130	\N	\N	\N	\N	GOAL	\N
1676	918	130	\N	\N	\N	\N	GOAL	\N
1677	918	130	\N	\N	\N	\N	GOAL	\N
1678	918	130	\N	\N	\N	\N	GOAL	\N
1679	918	130	\N	\N	\N	\N	GOAL	\N
1680	918	134	\N	\N	\N	\N	GOAL	\N
1681	918	134	\N	\N	\N	\N	GOAL	\N
1682	918	134	\N	\N	\N	\N	GOAL	\N
1683	918	134	\N	\N	\N	\N	GOAL	\N
1684	918	134	\N	\N	\N	\N	GOAL	\N
1685	918	134	\N	\N	\N	\N	GOAL	\N
1686	918	134	\N	\N	\N	\N	GOAL	\N
1687	918	134	\N	\N	\N	\N	GOAL	\N
1688	918	134	\N	\N	\N	\N	GOAL	\N
1689	918	134	\N	\N	\N	\N	GOAL	\N
1690	919	129	\N	\N	\N	\N	GOAL	\N
1691	619	11	1032	\N	23	\N	GOAL	\N
1692	619	102	1260	\N	56	\N	GOAL	\N
1693	619	11	1035	\N	82	\N	GOAL	\N
1694	553	11	1035	\N	30	\N	GOAL	\N
1695	553	11	1035	\N	41	\N	GOAL	\N
1696	904	114	1878	\N	26	\N	GOAL	\N
1697	904	113	\N	\N	42	\N	GOAL	\N
1698	904	114	1882	\N	47	\N	GOAL	\N
1699	905	115	\N	\N	51	\N	GOAL	\N
1700	920	130	1907	\N	30	\N	GOAL	\N
1701	920	129	\N	\N	27	\N	GOAL	\N
1702	920	129	\N	\N	49	\N	GOAL	\N
1703	921	133	\N	\N	\N	\N	GOAL	\N
1704	921	133	\N	\N	\N	\N	GOAL	\N
1705	921	133	\N	\N	\N	\N	GOAL	\N
1706	921	133	\N	\N	\N	\N	GOAL	\N
1707	921	133	\N	\N	\N	\N	GOAL	\N
1708	921	134	\N	\N	\N	\N	GOAL	\N
1709	921	134	\N	\N	\N	\N	GOAL	\N
1710	921	134	\N	\N	\N	\N	GOAL	\N
1711	485	76	1184	\N	13	\N	GOAL	\N
1712	633	101	1367	\N	4	\N	GOAL	\N
1713	633	101	1735	\N	6	\N	GOAL	\N
1714	633	101	1619	\N	44	\N	GOAL	\N
1715	492	11	1085	\N	95	\N	GOAL	\N
1716	636	76	972	\N	23	\N	GOAL	\N
1717	636	13	1449	\N	32	\N	GOAL	\N
1718	636	76	1451	\N	66	\N	GOAL	\N
1719	508	5	1179	\N	22	\N	GOAL	\N
1720	635	99	\N	\N	\N	\N	GOAL	\N
1721	631	88	\N	\N	\N	\N	GOAL	\N
1722	630	3	\N	\N	\N	\N	GOAL	\N
1723	631	7	\N	\N	\N	\N	GOAL	\N
1724	508	11	1029	\N	67	\N	GOAL	\N
1725	508	11	1413	\N	83	\N	GOAL	\N
1726	630	15	\N	\N	\N	\N	GOAL	\N
1727	630	15	\N	\N	\N	\N	GOAL	\N
1728	630	15	\N	\N	\N	\N	GOAL	\N
1729	635	4	\N	\N	\N	\N	GOAL	\N
1730	635	99	\N	\N	\N	\N	GOAL	\N
1731	635	4	\N	\N	\N	\N	GOAL	\N
1732	631	88	\N	\N	32	\N	GOAL	\N
1733	924	1	979	\N	74	\N	GOAL	\N
1734	637	2	\N	\N	\N	\N	GOAL	\N
1735	618	11	1032	\N	11	\N	GOAL	\N
1736	927	87	1219	\N	27	\N	GOAL	\N
1737	927	87	1205	\N	38	\N	GOAL	\N
1738	632	102	1299	\N	50	\N	GOAL	\N
1739	634	1	1454	\N	17	\N	GOAL	\N
1740	634	12	1669	\N	70	\N	GOAL	\N
1741	632	102	1563	\N	84	\N	GOAL	\N
1742	638	11	1032	\N	11	\N	GOAL	\N
1743	638	11	1032	\N	20	\N	GOAL	\N
1744	638	100	1784	\N	35	\N	GOAL	\N
1745	639	7	1114	\N	34	\N	GOAL	\N
1746	638	11	1032	\N	47	\N	GOAL	\N
1747	638	11	1413	\N	70	\N	GOAL	\N
1748	638	11	1413	\N	75	\N	GOAL	\N
1749	638	11	1085	\N	81	\N	GOAL	\N
1750	638	11	1413	\N	83	\N	GOAL	\N
1751	638	11	1472	\N	90	\N	GOAL	\N
1752	639	3	1030	\N	63	\N	GOAL	\N
1753	639	3	1314	\N	75	\N	GOAL	\N
1754	639	7	1114	\N	65	\N	GOAL	\N
1755	644	6	1459	\N	8	\N	GOAL	\N
1756	644	6	1435	\N	72	\N	GOAL	\N
1757	644	2	1258	\N	3	\N	GOAL	\N
1758	644	2	1002	\N	27	\N	GOAL	\N
1759	644	2	1304	\N	40	\N	GOAL	\N
1760	642	99	1365	\N	21	\N	GOAL	\N
1761	642	99	1365	\N	40	\N	GOAL	\N
1762	642	99	1764	\N	43	\N	GOAL	\N
1763	642	17	1620	\N	58	\N	GOAL	\N
1764	646	15	\N	\N	35	\N	GOAL	\N
1765	646	15	1053	\N	38	\N	GOAL	\N
1766	640	12	1669	\N	37	\N	GOAL	\N
1767	640	12	1232	\N	59	\N	GOAL	\N
1768	640	88	1221	\N	44	\N	GOAL	\N
1769	640	88	1246	\N	53	\N	GOAL	\N
1770	647	101	1367	\N	9	\N	GOAL	\N
1771	928	137	1923	\N	\N	\N	GOAL	\N
1772	928	137	1923	\N	\N	\N	GOAL	\N
1773	929	142	\N	\N	\N	\N	GOAL	\N
1774	930	153	\N	\N	\N	\N	GOAL	\N
1775	930	154	\N	\N	\N	\N	GOAL	\N
1776	652	5	1175	\N	65	\N	GOAL	\N
1777	650	88	1246	\N	30	\N	GOAL	\N
1778	650	88	1246	\N	50	\N	GOAL	\N
1779	650	3	\N	\N	\N	\N	GOAL	\N
1780	650	3	1888	\N	78	\N	GOAL	\N
1781	652	5	1245	\N	88	\N	GOAL	\N
1782	652	5	\N	\N	81	\N	GOAL	\N
1783	649	8	\N	\N	\N	\N	GOAL	\N
1784	653	100	\N	\N	\N	\N	GOAL	\N
1785	658	102	1182	\N	61	\N	GOAL	\N
1786	655	76	972	\N	16	\N	GOAL	\N
1787	654	2	1297	\N	35	\N	GOAL	\N
1788	654	2	1304	\N	44	\N	GOAL	\N
1789	654	17	1627	\N	46	\N	GOAL	\N
1790	654	17	1259	\N	56	\N	GOAL	\N
1791	654	17	1627	\N	69	\N	GOAL	\N
1792	654	2	1069	\N	86	\N	GOAL	\N
1793	657	101	\N	\N	22	\N	GOAL	\N
1794	657	99	1096	\N	7	\N	GOAL	\N
1795	936	139	\N	\N	\N	\N	GOAL	\N
1796	937	149	\N	\N	\N	\N	GOAL	\N
1797	937	150	\N	\N	\N	\N	GOAL	\N
1798	939	143	\N	\N	\N	\N	GOAL	\N
1799	939	143	\N	\N	\N	\N	GOAL	\N
1800	939	143	\N	\N	\N	\N	GOAL	\N
1801	939	144	\N	\N	\N	\N	GOAL	\N
1802	932	145	\N	\N	\N	\N	GOAL	\N
1803	933	156	\N	\N	\N	\N	GOAL	\N
1804	657	99	\N	\N	\N	\N	GOAL	\N
1805	487	11	1035	\N	33	\N	GOAL	\N
1806	487	11	1472	\N	47	\N	GOAL	\N
1807	487	11	1032	\N	56	\N	GOAL	\N
1808	656	12	1674	\N	3	\N	GOAL	\N
1809	656	12	1232	\N	48	\N	GOAL	\N
1810	656	12	1661	\N	91	\N	GOAL	\N
1811	656	4	1223	\N	46	\N	GOAL	\N
1812	629	6	1436	\N	21	\N	GOAL	\N
1813	629	6	1416	\N	45	\N	GOAL	\N
1814	629	5	1183	\N	81	\N	GOAL	\N
1815	629	5	1502	\N	90	\N	GOAL	\N
1816	519	11	1413	\N	6	\N	GOAL	\N
1817	519	11	1413	\N	12	\N	GOAL	\N
1818	668	101	1367	\N	28	\N	GOAL	\N
1819	668	101	1367	\N	43	\N	GOAL	\N
1820	663	11	1413	\N	9	\N	GOAL	\N
1821	667	102	1373	\N	39	\N	GOAL	\N
1822	663	11	1035	\N	60	\N	GOAL	\N
1823	662	76	1451	\N	26	\N	GOAL	\N
1824	659	87	1219	\N	23	\N	GOAL	\N
1825	659	8	\N	\N	50	\N	GOAL	\N
1826	660	17	1615	\N	75	\N	GOAL	\N
1827	660	17	1637	\N	89	\N	GOAL	\N
1828	660	17	1210	\N	91	\N	GOAL	\N
1829	661	1	979	\N	2	\N	GOAL	\N
1830	661	1	1061	\N	68	\N	GOAL	\N
1831	665	100	1784	\N	70	\N	GOAL	\N
1832	664	99	1759	\N	2	\N	GOAL	\N
1833	664	99	1759	\N	19	\N	GOAL	\N
1834	664	99	1754	\N	47	\N	GOAL	\N
1835	664	12	\N	\N	44	\N	GOAL	\N
1836	664	12	1292	\N	53	\N	GOAL	\N
1837	941	11	1035	\N	9	\N	GOAL	\N
1838	941	11	1413	\N	16	\N	GOAL	\N
1839	941	165	\N	\N	24	\N	GOAL	\N
1840	941	11	1035	\N	32	\N	GOAL	\N
1841	941	165	\N	\N	49	\N	GOAL	\N
1842	941	11	1472	\N	61	\N	GOAL	\N
1843	941	165	\N	\N	\N	\N	GOAL	\N
1844	941	165	\N	\N	\N	\N	GOAL	\N
1845	941	165	\N	\N	\N	\N	GOAL	\N
1846	925	115	\N	\N	44	\N	GOAL	\N
1847	925	114	\N	\N	79	\N	GOAL	\N
1848	666	3	1544	\N	26	\N	GOAL	\N
1849	666	3	1544	\N	90	\N	GOAL	\N
1850	362	101	\N	\N	\N	\N	GOAL	\N
1851	362	11	\N	\N	\N	\N	GOAL	\N
1852	676	4	1106	\N	20	\N	GOAL	\N
1853	670	1	1058	\N	47	\N	GOAL	\N
1854	670	1	997	\N	50	\N	GOAL	\N
1855	676	2	1307	\N	60	\N	GOAL	\N
1856	673	3	1888	\N	51	\N	GOAL	\N
1857	673	3	1549	\N	71	\N	GOAL	\N
1858	672	17	\N	\N	\N	\N	GOAL	\N
1859	672	17	\N	\N	\N	\N	GOAL	\N
1860	672	17	\N	\N	\N	\N	GOAL	\N
1861	672	8	\N	\N	\N	\N	GOAL	\N
1862	674	15	\N	\N	\N	\N	GOAL	\N
1863	677	13	\N	\N	\N	\N	GOAL	\N
1864	677	13	\N	\N	\N	\N	GOAL	\N
1865	677	13	\N	\N	\N	\N	GOAL	\N
1866	677	87	\N	\N	\N	\N	GOAL	\N
1867	678	102	\N	\N	\N	\N	GOAL	\N
1868	678	102	\N	\N	\N	\N	GOAL	\N
1869	926	115	\N	\N	41	\N	GOAL	\N
1870	928	27	2173	\N	41	\N	GOAL	\N
1871	938	40	2175	\N	14	\N	GOAL	\N
1872	945	104	1963	\N	34	\N	GOAL	\N
1873	938	40	2174	\N	49	\N	GOAL	\N
1874	930	39	1944	\N	77	\N	GOAL	\N
1875	931	25	1978	\N	49	\N	GOAL	\N
1876	931	25	1986	\N	55	\N	GOAL	\N
1877	933	52	2052	\N	28	\N	GOAL	\N
1878	933	52	2048	\N	64	\N	GOAL	\N
1879	934	54	2124	\N	43	\N	GOAL	\N
1880	935	69	2169	\N	64	\N	GOAL	\N
1881	937	50	2188	\N	37	\N	GOAL	\N
1882	937	50	2189	\N	45	\N	GOAL	\N
1883	937	50	2191	\N	55	\N	GOAL	\N
1884	938	58	2195	\N	66	\N	GOAL	\N
1885	938	58	2196	\N	69	\N	GOAL	\N
1886	939	64	2185	\N	2	\N	GOAL	\N
1887	939	33	2199	\N	9	\N	GOAL	\N
1888	939	33	2198	\N	42	\N	GOAL	\N
1889	939	64	2185	\N	63	\N	GOAL	\N
1890	940	39	2201	\N	73	\N	GOAL	\N
1891	943	40	2174	\N	12	\N	GOAL	\N
1892	943	30	2202	\N	40	\N	GOAL	\N
1893	944	27	2204	\N	25	\N	GOAL	\N
1894	944	27	2203	\N	43	\N	GOAL	\N
1895	945	25	1975	\N	76	\N	GOAL	\N
1896	946	54	2121	\N	49	\N	GOAL	\N
1897	947	91	2080	\N	6	\N	GOAL	\N
1898	947	62	2103	\N	39	\N	GOAL	\N
1899	947	91	2076	\N	41	\N	GOAL	\N
1900	947	62	2097	\N	62	\N	GOAL	\N
1901	947	62	2103	\N	80	\N	GOAL	\N
1902	931	104	\N	\N	34	\N	GOAL	\N
1903	929	40	\N	\N	14	\N	GOAL	\N
1904	929	40	\N	\N	48	\N	GOAL	\N
1905	931	104	\N	\N	66	\N	GOAL	\N
1906	948	50	2192	\N	60	\N	GOAL	\N
1907	948	105	2205	\N	70	\N	GOAL	\N
1908	949	103	2006	\N	23	\N	GOAL	\N
1909	950	32	2137	\N	69	\N	GOAL	\N
1910	954	104	1940	\N	25	\N	GOAL	\N
1911	954	104	1940	\N	52	\N	GOAL	\N
1912	955	25	1988	\N	13	\N	GOAL	\N
1913	955	25	1978	\N	53	\N	GOAL	\N
1914	956	61	2206	\N	4	\N	GOAL	\N
1915	956	61	2186	\N	35	\N	GOAL	\N
1916	957	27	2203	\N	36	\N	GOAL	\N
1917	957	27	2204	\N	46	\N	GOAL	\N
1918	960	54	2126	\N	35	\N	GOAL	\N
1919	960	54	2125	\N	39	\N	GOAL	\N
1920	960	54	2125	\N	45	\N	GOAL	\N
1921	961	52	2057	\N	71	\N	GOAL	\N
1922	961	52	2051	\N	63	\N	GOAL	\N
1923	958	69	2166	\N	39	\N	GOAL	\N
1924	958	69	2161	\N	58	\N	GOAL	\N
1925	958	69	2168	\N	84	\N	GOAL	\N
1926	958	69	2171	\N	89	\N	GOAL	\N
1927	958	28	2033	\N	71	\N	GOAL	\N
1928	959	103	2000	\N	90	\N	GOAL	\N
1929	963	33	2198	\N	46	\N	GOAL	\N
1930	963	33	2200	\N	72	\N	GOAL	\N
1931	964	50	2193	\N	37	\N	GOAL	\N
1932	966	64	2208	\N	53	\N	GOAL	\N
1933	966	103	2006	\N	76	\N	GOAL	\N
1934	967	52	2057	\N	15	\N	GOAL	\N
1935	968	39	1944	\N	19	\N	GOAL	\N
1936	968	58	2196	\N	41	\N	GOAL	\N
1937	968	58	2197	\N	44	\N	GOAL	\N
1938	968	39	1944	\N	63	\N	GOAL	\N
1939	968	39	1938	\N	66	\N	GOAL	\N
1940	969	32	2143	\N	85	\N	GOAL	\N
1941	970	25	1979	\N	9	\N	GOAL	\N
1942	970	61	2186	\N	21	\N	GOAL	\N
1943	970	25	1987	\N	77	\N	GOAL	\N
1944	970	61	2187	\N	90	\N	GOAL	\N
1945	971	54	2121	\N	24	\N	GOAL	\N
1946	971	54	2124	\N	57	\N	GOAL	\N
1947	971	54	2125	\N	82	\N	GOAL	\N
1948	937	50	2190	\N	74	\N	GOAL	\N
1949	956	61	2207	\N	78	\N	GOAL	\N
1950	972	69	2168	\N	76	\N	GOAL	\N
1951	973	105	2209	\N	73	\N	GOAL	\N
1952	974	52	2047	\N	70	\N	GOAL	\N
1953	975	39	2246	\N	27	\N	GOAL	\N
1954	975	32	2137	\N	71	\N	GOAL	\N
1955	975	39	2236	\N	89	\N	GOAL	\N
1956	976	54	2119	\N	20	\N	GOAL	\N
1957	976	69	2169	\N	62	\N	GOAL	\N
1958	977	105	2259	\N	52	\N	GOAL	\N
1959	977	105	2182	\N	60	\N	GOAL	\N
1960	977	105	2268	\N	93	\N	GOAL	\N
1961	982	1	1056	\N	10	\N	GOAL	\N
1962	981	54	2124	\N	94	\N	GOAL	\N
1963	982	122	\N	\N	\N	\N	GOAL	\N
1964	982	1	\N	\N	\N	\N	GOAL	\N
1965	983	39	1944	\N	3	\N	GOAL	\N
1966	984	54	1398	\N	2	\N	GOAL	\N
1967	986	11	1472	\N	33	\N	GOAL	\N
1968	986	117	\N	\N	40	\N	GOAL	\N
1969	987	174	\N	\N	24	\N	GOAL	\N
1970	1008	1	1071	\N	14	\N	GOAL	\N
1971	1008	11	2270	\N	16	\N	GOAL	\N
1972	1008	11	2270	\N	22	\N	GOAL	\N
1973	1008	11	1472	\N	57	\N	GOAL	\N
1974	1008	1	1063	\N	78	\N	GOAL	\N
1975	1008	11	1032	\N	83	\N	GOAL	\N
1976	1027	188	\N	\N	29	\N	GOAL	\N
1977	1027	188	\N	\N	63	\N	GOAL	\N
1978	979	2	2278	\N	15	\N	GOAL	\N
1979	989	168	2280	\N	43	\N	GOAL	\N
1980	989	8	2281	\N	72	\N	GOAL	\N
1981	989	168	2280	\N	84	\N	GOAL	\N
1982	990	169	1186	\N	34	\N	GOAL	\N
1983	991	4	977	\N	15	\N	GOAL	\N
1984	991	4	2284	\N	90	\N	GOAL	\N
1985	1029	74	\N	\N	12	\N	GOAL	\N
1986	1028	189	\N	\N	14	\N	GOAL	\N
1987	1029	74	\N	\N	16	\N	GOAL	\N
1988	1030	191	\N	\N	14	\N	GOAL	\N
1989	1029	74	\N	\N	37	\N	GOAL	\N
1990	1030	192	\N	\N	40	\N	GOAL	\N
1991	992	17	2274	\N	25	\N	GOAL	\N
1992	993	87	2275	\N	9	\N	GOAL	\N
1993	993	87	2276	\N	28	\N	GOAL	\N
1994	1029	74	\N	\N	63	\N	GOAL	\N
1995	1029	74	\N	\N	69	\N	GOAL	\N
1996	1029	190	\N	\N	74	\N	GOAL	\N
1997	993	87	1136	\N	68	\N	GOAL	\N
1998	993	7	1088	\N	78	\N	GOAL	\N
1999	995	1	2273	\N	14	\N	GOAL	\N
2000	994	15	2272	\N	21	\N	GOAL	\N
2001	978	11	1413	\N	1	\N	GOAL	\N
2002	978	11	1413	\N	58	\N	GOAL	\N
2003	978	11	2271	\N	74	\N	GOAL	\N
2004	978	3	1553	\N	86	\N	GOAL	\N
2005	1017	128	2287	\N	30	\N	GOAL	\N
2006	1017	185	2286	\N	15	\N	GOAL	\N
2007	1017	128	2371	\N	55	\N	GOAL	\N
2008	1012	180	2369	\N	47	\N	GOAL	\N
2009	1012	180	2370	\N	60	\N	GOAL	\N
2010	1016	179	2319	\N	55	\N	GOAL	\N
2011	1016	183	2318	\N	71	\N	GOAL	\N
2012	1015	177	2322	\N	4	\N	GOAL	\N
2013	1013	181	2303	\N	46	\N	GOAL	\N
2014	1013	181	2303	\N	50	\N	GOAL	\N
2015	1015	177	2323	\N	40	\N	GOAL	\N
2016	1015	177	2324	\N	80	\N	GOAL	\N
2017	1009	74	2320	\N	27	\N	GOAL	\N
2018	1009	187	2321	\N	38	\N	GOAL	\N
2019	1009	187	2321	\N	63	\N	GOAL	\N
2020	1009	74	2326	\N	66	\N	GOAL	\N
2021	1009	74	2325	\N	83	\N	GOAL	\N
2022	1009	74	2327	\N	91	\N	GOAL	\N
2023	1011	186	2328	\N	56	\N	GOAL	\N
2024	1011	186	2329	\N	72	\N	GOAL	\N
2025	1011	175	2368	\N	76	\N	GOAL	\N
2026	1011	186	2330	\N	80	\N	GOAL	\N
2027	1010	176	2367	\N	85	\N	GOAL	\N
2028	1002	11	1413	\N	18	\N	GOAL	\N
2029	1002	7	1098	\N	21	\N	GOAL	\N
2030	1002	11	2271	\N	61	\N	GOAL	\N
2031	1005	100	2423	\N	64	\N	GOAL	\N
2032	1005	100	1460	\N	74	\N	GOAL	\N
2033	1022	182	2346	\N	41	\N	GOAL	\N
2034	1022	182	2347	\N	66	\N	GOAL	\N
2035	1022	179	2348	\N	82	\N	GOAL	\N
2036	1018	171	2350	\N	93	\N	GOAL	\N
2037	998	2	2353	\N	16	\N	GOAL	\N
2038	1031	76	2351	\N	25	\N	GOAL	\N
2039	1025	176	2373	\N	43	\N	GOAL	\N
2040	996	168	2352	\N	27	\N	GOAL	\N
2041	997	87	1219	\N	87	\N	GOAL	\N
2042	1031	193	\N	\N	94	\N	GOAL	\N
2043	1025	180	2374	\N	88	\N	GOAL	\N
2044	1033	194	\N	\N	20	\N	GOAL	\N
2045	996	168	2354	\N	46	\N	GOAL	\N
2046	1001	99	2355	\N	10	\N	GOAL	\N
2047	1001	4	2356	\N	20	\N	GOAL	\N
2048	1000	13	1335	\N	15	\N	GOAL	\N
2049	1000	13	1333	\N	37	\N	GOAL	\N
2050	1000	15	1054	\N	25	\N	GOAL	\N
2051	1001	4	977	\N	62	\N	GOAL	\N
2052	1056	99	2355	\N	11	\N	GOAL	\N
2053	1056	101	1619	\N	45	\N	GOAL	\N
2054	1024	186	2357	\N	15	\N	GOAL	\N
2055	1024	186	2357	\N	19	\N	GOAL	\N
2056	1024	127	2358	\N	46	\N	GOAL	\N
2057	1024	127	2359	\N	48	\N	GOAL	\N
2058	1024	127	2360	\N	73	\N	GOAL	\N
2059	1297	179	2377	\N	6	\N	GOAL	\N
2060	1297	179	2319	\N	50	\N	GOAL	\N
2061	1060	5	1245	\N	18	\N	GOAL	\N
2062	1059	8	1096	\N	87	\N	GOAL	\N
2063	1059	88	1368	\N	5	\N	GOAL	\N
2064	1062	4	2284	\N	38	\N	GOAL	\N
2065	1294	185	2363	\N	29	\N	GOAL	\N
2066	1295	127	2364	\N	10	\N	GOAL	\N
2067	1300	176	2365	\N	23	\N	GOAL	\N
2068	1300	176	2366	\N	52	\N	GOAL	\N
2069	1300	176	2366	\N	68	\N	GOAL	\N
2070	1301	187	2349	\N	79	\N	GOAL	\N
2071	1301	187	2380	\N	92	\N	GOAL	\N
2072	1302	74	2381	\N	12	\N	GOAL	\N
2073	1302	74	2382	\N	32	\N	GOAL	\N
2074	1296	181	2375	\N	74	\N	GOAL	\N
2075	1296	171	2376	\N	88	\N	GOAL	\N
2076	1299	170	2383	\N	28	\N	GOAL	\N
2077	1299	170	2285	\N	61	\N	GOAL	\N
2078	1299	170	2384	\N	77	\N	GOAL	\N
2079	1299	170	2384	\N	93	\N	GOAL	\N
2080	1125	13	1447	\N	17	\N	GOAL	\N
2081	1125	13	1336	\N	37	\N	GOAL	\N
2082	1130	102	1260	\N	39	\N	GOAL	\N
2083	1126	3	1261	\N	16	\N	GOAL	\N
2084	1125	7	1095	\N	60	\N	GOAL	\N
2085	1068	100	2386	\N	61	\N	GOAL	\N
2086	1125	13	2387	\N	91	\N	GOAL	\N
2087	1067	17	1118	\N	58	\N	GOAL	\N
2088	1068	15	\N	\N	95	\N	GOAL	\N
2089	1067	99	1755	\N	81	\N	GOAL	\N
2090	1131	11	1413	\N	3	\N	GOAL	\N
2091	1127	87	2388	\N	16	\N	GOAL	\N
2092	1131	11	1016	\N	35	\N	GOAL	\N
2093	1127	5	2362	\N	47	\N	GOAL	\N
2094	1127	5	2362	\N	47	\N	GOAL	\N
2095	1127	5	2389	\N	86	\N	GOAL	\N
2096	1127	87	1219	\N	77	\N	GOAL	\N
2097	1303	187	2400	\N	47	\N	GOAL	\N
2098	1304	185	2402	\N	4	\N	GOAL	\N
2099	1303	187	2401	\N	53	\N	GOAL	\N
2100	1304	184	2404	\N	14	\N	GOAL	\N
2101	1305	182	2391	\N	19	\N	GOAL	\N
2102	1303	187	2380	\N	73	\N	GOAL	\N
2103	1303	170	2285	\N	93	\N	GOAL	\N
2104	1304	185	2403	\N	63	\N	GOAL	\N
2105	1064	99	1764	\N	18	\N	GOAL	\N
2106	1321	193	2394	\N	25	\N	GOAL	\N
2107	1305	181	2375	\N	73	\N	GOAL	\N
2108	1321	76	2390	\N	29	\N	GOAL	\N
2109	1305	181	2392	\N	83	\N	GOAL	\N
2110	1305	181	2393	\N	91	\N	GOAL	\N
2111	1132	17	1259	\N	59	\N	GOAL	\N
2112	1132	2	2396	\N	92	\N	GOAL	\N
2113	1307	126	2405	\N	15	\N	GOAL	\N
2114	1307	126	2378	\N	35	\N	GOAL	\N
2115	1307	126	2378	\N	56	\N	GOAL	\N
2116	1307	126	2406	\N	63	\N	GOAL	\N
2117	1308	176	\N	\N	4	\N	GOAL	\N
2118	1308	177	\N	\N	34	\N	GOAL	\N
2119	1139	11	1413	\N	22	\N	GOAL	\N
2120	1135	7	2337	\N	23	\N	GOAL	\N
2121	1135	5	1245	\N	43	\N	GOAL	\N
2122	1134	13	1448	\N	83	\N	GOAL	\N
2123	1134	87	2275	\N	45	\N	GOAL	\N
2124	1139	11	2271	\N	54	\N	GOAL	\N
2125	1140	8	992	\N	75	\N	GOAL	\N
2126	1136	3	1544	\N	49	\N	GOAL	\N
2127	1134	13	1175	\N	9	\N	GOAL	\N
2128	1310	74	2325	\N	10	\N	GOAL	\N
2129	1310	74	2325	\N	27	\N	GOAL	\N
2130	1129	1	979	\N	33	\N	GOAL	\N
2131	1129	1	1058	\N	47	\N	GOAL	\N
2132	1311	180	2407	\N	21	\N	GOAL	\N
2133	1311	127	2408	\N	48	\N	GOAL	\N
2134	1128	76	1184	\N	7	\N	GOAL	\N
2135	1128	169	1210	\N	35	\N	GOAL	\N
2136	1128	169	1210	\N	56	\N	GOAL	\N
2137	1128	169	1210	\N	58	\N	GOAL	\N
2138	1128	76	2399	\N	65	\N	GOAL	\N
2139	1128	76	2399	\N	69	\N	GOAL	\N
2140	1314	128	2410	\N	57	\N	GOAL	\N
2141	1316	171	2411	\N	29	\N	GOAL	\N
2142	1316	183	2413	\N	38	\N	GOAL	\N
2143	1314	128	2409	\N	88	\N	GOAL	\N
2144	1316	171	2412	\N	50	\N	GOAL	\N
2145	1316	183	2414	\N	70	\N	GOAL	\N
2146	1317	177	2415	\N	94	\N	GOAL	\N
2147	1138	1	979	\N	62	\N	GOAL	\N
2148	1138	168	2280	\N	49	\N	GOAL	\N
2149	1138	1	1063	\N	91	\N	GOAL	\N
2150	1319	187	2380	\N	32	\N	GOAL	\N
2151	1319	176	2418	\N	45	\N	GOAL	\N
2152	1319	187	2419	\N	78	\N	GOAL	\N
2153	1319	187	2420	\N	88	\N	GOAL	\N
2154	1318	170	2416	\N	5	\N	GOAL	\N
2155	1318	127	2417	\N	60	\N	GOAL	\N
2156	1320	74	2327	\N	81	\N	GOAL	\N
2157	1318	170	2384	\N	87	\N	GOAL	\N
2158	1137	76	2395	\N	51	\N	GOAL	\N
2159	1312	180	\N	\N	51	\N	GOAL	\N
2160	1312	180	\N	\N	75	\N	GOAL	\N
2161	1312	180	\N	\N	79	\N	GOAL	\N
2162	1322	64	2217	\N	54	\N	GOAL	\N
2163	1142	13	1449	\N	60	\N	GOAL	\N
2164	1142	4	1236	\N	79	\N	GOAL	\N
2165	1144	168	2421	\N	75	\N	GOAL	\N
2166	1145	7	1081	\N	35	\N	GOAL	\N
2167	1143	15	1216	\N	3	\N	GOAL	\N
2168	1143	2	2422	\N	50	\N	GOAL	\N
2169	1065	17	1259	\N	3	\N	GOAL	\N
2170	1065	100	2423	\N	7	\N	GOAL	\N
2171	1141	88	2426	\N	3	\N	GOAL	\N
2172	1141	169	2424	\N	23	\N	GOAL	\N
2173	1065	100	1444	\N	59	\N	GOAL	\N
2174	1148	101	2434	\N	68	\N	GOAL	\N
2175	1141	169	2425	\N	90	\N	GOAL	\N
2176	1148	101	1619	\N	91	\N	GOAL	\N
2177	1158	76	2390	\N	57	\N	GOAL	\N
2178	1152	99	1752	\N	21	\N	GOAL	\N
2179	1153	168	\N	\N	39	\N	GOAL	\N
2180	1155	87	1219	\N	44	\N	GOAL	\N
2181	1155	8	\N	\N	76	\N	GOAL	\N
2182	1150	169	\N	\N	46	\N	GOAL	\N
2183	1156	11	1413	\N	50	\N	GOAL	\N
2184	1157	4	\N	\N	18	\N	GOAL	\N
2185	1157	4	977	\N	28	\N	GOAL	\N
2186	1157	4	\N	\N	32	\N	GOAL	\N
2187	1157	5	\N	\N	36	\N	GOAL	\N
2188	1157	4	\N	\N	61	\N	GOAL	\N
2189	1159	7	1114	\N	56	\N	GOAL	\N
2190	1159	7	2337	\N	88	\N	GOAL	\N
2191	1167	11	2271	\N	42	\N	GOAL	\N
2192	1160	100	1828	\N	23	\N	GOAL	\N
2193	1161	17	1259	\N	15	\N	GOAL	\N
2194	1161	17	2274	\N	25	\N	GOAL	\N
2195	1166	15	2272	\N	68	\N	GOAL	\N
2196	1069	101	1731	\N	68	\N	GOAL	\N
2197	1161	3	1553	\N	91	\N	GOAL	\N
2198	1161	3	\N	\N	93	\N	GOAL	\N
2199	1163	2	\N	\N	91	\N	GOAL	\N
2200	1164	13	2385	\N	60	\N	GOAL	\N
2201	1164	99	1733	\N	75	\N	GOAL	\N
2202	1163	5	1245	\N	93	\N	GOAL	\N
2203	1070	15	\N	\N	17	\N	GOAL	\N
2204	1169	17	1259	\N	33	\N	GOAL	\N
2205	1170	4	\N	\N	12	\N	GOAL	\N
2206	1171	7	1081	\N	20	\N	GOAL	\N
2207	1168	3	\N	\N	36	\N	GOAL	\N
2208	1168	3	\N	\N	41	\N	GOAL	\N
2209	1168	88	\N	\N	55	\N	GOAL	\N
2210	1170	4	977	\N	69	\N	GOAL	\N
2211	1171	100	\N	\N	11	\N	GOAL	\N
2212	1171	7	1114	\N	58	\N	GOAL	\N
2213	1172	87	1587	\N	34	\N	GOAL	\N
2214	1172	169	1186	\N	73	\N	GOAL	\N
2215	1172	87	1587	\N	74	\N	GOAL	\N
2216	1174	13	2385	\N	20	\N	GOAL	\N
2217	1174	2	1070	\N	91	\N	GOAL	\N
2218	1178	87	2276	\N	43	\N	GOAL	\N
2219	1178	87	2276	\N	71	\N	GOAL	\N
2220	1071	100	2423	\N	16	\N	GOAL	\N
2221	1180	11	1472	\N	44	\N	GOAL	\N
2222	1179	8	1430	\N	53	\N	GOAL	\N
2223	1180	11	2270	\N	78	\N	GOAL	\N
2224	1071	2	1070	\N	63	\N	GOAL	\N
2225	1183	13	\N	\N	77	\N	GOAL	\N
2226	1179	8	\N	\N	75	\N	GOAL	\N
2227	1180	11	2436	\N	87	\N	GOAL	\N
2228	1071	2	\N	\N	82	\N	GOAL	\N
2229	1182	102	2437	\N	30	\N	GOAL	\N
2230	1182	102	996	\N	58	\N	GOAL	\N
2231	1182	101	1887	\N	64	\N	GOAL	\N
2232	1315	126	\N	\N	20	\N	GOAL	\N
2233	1315	126	\N	\N	60	\N	GOAL	\N
2234	1188	3	1415	\N	22	\N	GOAL	\N
2235	1190	87	1219	\N	23	\N	GOAL	\N
2236	1181	169	1210	\N	59	\N	GOAL	\N
2237	1186	99	1750	\N	32	\N	GOAL	\N
2238	1072	168	2438	\N	40	\N	GOAL	\N
2239	1190	87	2276	\N	43	\N	GOAL	\N
2240	1072	15	2272	\N	48	\N	GOAL	\N
2241	1072	168	2439	\N	53	\N	GOAL	\N
2242	1187	2	1070	\N	61	\N	GOAL	\N
2243	1190	88	\N	\N	51	\N	GOAL	\N
2244	1190	87	1219	\N	58	\N	GOAL	\N
2245	1190	87	2276	\N	72	\N	GOAL	\N
2246	1190	87	2276	\N	87	\N	GOAL	\N
2247	1189	7	1257	\N	64	\N	GOAL	\N
2248	1194	4	2284	\N	25	\N	GOAL	\N
2249	1194	4	1113	\N	48	\N	GOAL	\N
2250	1193	76	2351	\N	75	\N	GOAL	\N
2251	1194	102	2437	\N	86	\N	GOAL	\N
2252	1192	1	2273	\N	2	\N	GOAL	\N
2253	1192	1	1364	\N	21	\N	GOAL	\N
2254	1192	101	1619	\N	32	\N	GOAL	\N
2255	1323	104	\N	\N	15	\N	GOAL	\N
2256	1323	35	2441	\N	68	\N	GOAL	\N
2257	1324	44	2442	\N	5	\N	GOAL	\N
2258	1324	44	2443	\N	94	\N	GOAL	\N
2259	1325	71	2444	\N	77	\N	GOAL	\N
2260	1325	26	2445	\N	93	\N	GOAL	\N
2261	1326	64	1330	\N	3	\N	GOAL	\N
2262	1326	39	2250	\N	45	\N	GOAL	\N
2263	1326	39	2249	\N	63	\N	GOAL	\N
2264	1327	45	2447	\N	68	\N	GOAL	\N
2265	1327	28	2448	\N	76	\N	GOAL	\N
2266	1328	42	2449	\N	40	\N	GOAL	\N
2267	1328	42	2450	\N	45	\N	GOAL	\N
2268	1328	42	2451	\N	73	\N	GOAL	\N
2269	1330	70	2452	\N	7	\N	GOAL	\N
2270	1330	70	2453	\N	44	\N	GOAL	\N
2271	1330	70	2454	\N	77	\N	GOAL	\N
2272	1331	52	2456	\N	26	\N	GOAL	\N
2273	1331	52	2457	\N	28	\N	GOAL	\N
2274	1333	43	2461	\N	3	\N	GOAL	\N
2275	1333	41	2459	\N	17	\N	GOAL	\N
2276	1333	41	2459	\N	18	\N	GOAL	\N
2277	1333	41	2460	\N	89	\N	GOAL	\N
2278	1334	49	2462	\N	51	\N	GOAL	\N
2279	1335	34	2463	\N	28	\N	GOAL	\N
2280	1335	34	2464	\N	31	\N	GOAL	\N
2281	1336	27	2466	\N	42	\N	GOAL	\N
2282	1336	62	2103	\N	67	\N	GOAL	\N
2283	1337	50	2190	\N	55	\N	GOAL	\N
2284	1337	104	1954	\N	64	\N	GOAL	\N
2285	1337	50	2467	\N	71	\N	GOAL	\N
2286	1337	104	2468	\N	74	\N	GOAL	\N
2287	1338	33	2200	\N	36	\N	GOAL	\N
2288	1338	33	2469	\N	80	\N	GOAL	\N
2289	1340	54	2107	\N	44	\N	GOAL	\N
2290	1340	54	2115	\N	68	\N	GOAL	\N
2291	1340	54	2121	\N	75	\N	GOAL	\N
2292	1340	54	2470	\N	86	\N	GOAL	\N
2293	1340	54	2115	\N	90	\N	GOAL	\N
2294	1342	63	2471	\N	15	\N	GOAL	\N
2295	1342	91	2080	\N	69	\N	GOAL	\N
2296	1342	91	2472	\N	92	\N	GOAL	\N
2297	1343	105	2205	\N	33	\N	GOAL	\N
2298	1343	105	2473	\N	41	\N	GOAL	\N
2299	1343	105	2473	\N	52	\N	GOAL	\N
2300	1343	89	2474	\N	45	\N	GOAL	\N
2301	1343	105	2205	\N	90	\N	GOAL	\N
2302	1345	25	1980	\N	18	\N	GOAL	\N
2303	1346	69	2164	\N	68	\N	GOAL	\N
2304	1348	50	2475	\N	14	\N	GOAL	\N
2305	1351	48	2476	\N	20	\N	GOAL	\N
2306	1352	40	2174	\N	31	\N	GOAL	\N
2307	1347	64	2230	\N	32	\N	GOAL	\N
2308	1351	48	2476	\N	40	\N	GOAL	\N
2309	1350	32	2477	\N	45	\N	GOAL	\N
2310	1348	50	2478	\N	49	\N	GOAL	\N
2311	1352	40	2479	\N	68	\N	GOAL	\N
2312	1349	52	2480	\N	59	\N	GOAL	\N
2313	1349	52	2480	\N	66	\N	GOAL	\N
2314	1349	52	2480	\N	68	\N	GOAL	\N
2315	1349	24	2481	\N	70	\N	GOAL	\N
2316	1349	52	2049	\N	77	\N	GOAL	\N
2317	1351	51	\N	\N	90	\N	GOAL	\N
2318	1353	60	2483	\N	19	\N	GOAL	\N
2319	1354	104	1943	\N	42	\N	GOAL	\N
2320	1354	104	1958	\N	70	\N	GOAL	\N
2321	1355	26	2484	\N	11	\N	GOAL	\N
2322	1355	39	1938	\N	26	\N	GOAL	\N
2323	1355	39	2246	\N	38	\N	GOAL	\N
2324	1355	39	2250	\N	75	\N	GOAL	\N
2325	1355	39	2250	\N	85	\N	GOAL	\N
2326	1356	58	2485	\N	71	\N	GOAL	\N
2327	1353	60	\N	\N	70	\N	GOAL	\N
2328	1353	60	\N	\N	71	\N	GOAL	\N
2329	1357	66	2491	\N	27	\N	GOAL	\N
2330	1357	66	2490	\N	45	\N	GOAL	\N
2331	1357	43	2498	\N	85	\N	GOAL	\N
2332	1359	46	2499	\N	6	\N	GOAL	\N
2333	1359	34	2464	\N	18	\N	GOAL	\N
2334	1359	46	2500	\N	57	\N	GOAL	\N
2335	1359	34	2501	\N	92	\N	GOAL	\N
2336	1361	62	2097	\N	35	\N	GOAL	\N
2337	1361	56	2502	\N	64	\N	GOAL	\N
2338	1360	61	2186	\N	48	\N	GOAL	\N
2339	1360	41	2503	\N	52	\N	GOAL	\N
2340	1360	61	2505	\N	75	\N	GOAL	\N
2341	1360	41	2504	\N	92	\N	GOAL	\N
2342	1363	54	2121	\N	15	\N	GOAL	\N
2343	1364	103	2006	\N	39	\N	GOAL	\N
2344	1364	103	2005	\N	27	\N	GOAL	\N
2345	1365	69	2153	\N	4	\N	GOAL	\N
2346	1365	55	\N	\N	16	\N	GOAL	\N
2347	1365	55	\N	\N	26	\N	GOAL	\N
2348	1364	103	1996	\N	83	\N	GOAL	\N
2349	1366	59	2194	\N	27	\N	GOAL	\N
2350	1366	59	2506	\N	91	\N	GOAL	\N
2351	1367	65	2507	\N	6	\N	GOAL	\N
2352	1367	25	1988	\N	10	\N	GOAL	\N
2353	1367	25	1988	\N	27	\N	GOAL	\N
2354	1367	25	1977	\N	38	\N	GOAL	\N
2355	1369	91	2076	\N	18	\N	GOAL	\N
2356	1367	25	2509	\N	53	\N	GOAL	\N
2357	1367	25	1973	\N	65	\N	GOAL	\N
2358	1367	65	2508	\N	77	\N	GOAL	\N
2359	1368	30	2202	\N	11	\N	GOAL	\N
2360	1368	37	2510	\N	20	\N	GOAL	\N
2361	1368	30	2202	\N	79	\N	GOAL	\N
2362	1369	89	\N	\N	67	\N	GOAL	\N
2363	1370	105	2205	\N	74	\N	GOAL	\N
2364	1369	89	\N	\N	81	\N	GOAL	\N
2365	1195	76	2351	\N	11	\N	GOAL	\N
2366	1195	76	2516	\N	22	\N	GOAL	\N
2367	1195	76	2399	\N	35	\N	GOAL	\N
2368	1195	3	1415	\N	13	\N	GOAL	\N
2369	1195	3	1454	\N	45	\N	GOAL	\N
2370	1203	99	1750	\N	15	\N	GOAL	\N
2371	1203	99	1738	\N	29	\N	GOAL	\N
2372	1197	100	1776	\N	15	\N	GOAL	\N
2373	1197	100	1780	\N	73	\N	GOAL	\N
2374	1197	168	2352	\N	15	\N	GOAL	\N
2375	1199	4	977	\N	31	\N	GOAL	\N
2376	1199	4	1252	\N	60	\N	GOAL	\N
2377	1199	87	1219	\N	40	\N	GOAL	\N
2378	1198	169	2517	\N	11	\N	GOAL	\N
2379	1198	169	2518	\N	84	\N	GOAL	\N
2380	1073	13	2385	\N	83	\N	GOAL	\N
2381	1073	17	2515	\N	70	\N	GOAL	\N
2382	1371	187	\N	\N	\N	\N	GOAL	\N
2383	1371	187	\N	\N	\N	\N	GOAL	\N
2384	1372	176	2365	\N	35	\N	GOAL	\N
2385	1372	176	2373	\N	37	\N	GOAL	\N
2386	1372	176	2373	\N	44	\N	GOAL	\N
2387	1372	176	2366	\N	70	\N	GOAL	\N
2388	1372	183	2519	\N	54	\N	GOAL	\N
2389	1372	183	2519	\N	85	\N	GOAL	\N
2390	1373	127	\N	\N	\N	\N	GOAL	\N
2391	1373	127	\N	\N	\N	\N	GOAL	\N
2392	1374	171	2412	\N	69	\N	GOAL	\N
2393	1374	171	2376	\N	72	\N	GOAL	\N
2394	1374	184	2520	\N	46	\N	GOAL	\N
2395	1375	170	\N	\N	10	\N	GOAL	\N
2396	1375	179	\N	\N	46	\N	GOAL	\N
2397	1375	179	\N	\N	53	\N	GOAL	\N
2398	1378	185	2521	\N	22	\N	GOAL	\N
2399	1378	126	2378	\N	86	\N	GOAL	\N
2400	1379	74	2381	\N	93	\N	GOAL	\N
2401	1196	1	1057	\N	15	\N	GOAL	\N
2402	1201	88	2522	\N	85	\N	GOAL	\N
2403	1202	11	2271	\N	39	\N	GOAL	\N
2404	1202	11	2523	\N	47	\N	GOAL	\N
2405	1202	11	2271	\N	75	\N	GOAL	\N
2406	1380	184	2520	\N	52	\N	GOAL	\N
2407	1380	182	2524	\N	5	\N	GOAL	\N
2408	1381	176	2525	\N	43	\N	GOAL	\N
2409	1381	176	2418	\N	80	\N	GOAL	\N
2410	1381	175	\N	\N	63	\N	GOAL	\N
2411	1382	181	2375	\N	57	\N	GOAL	\N
2412	1383	179	2377	\N	31	\N	GOAL	\N
2413	1383	128	2409	\N	43	\N	GOAL	\N
2414	1384	177	2322	\N	2	\N	GOAL	\N
2415	1384	186	\N	\N	42	\N	GOAL	\N
2416	1384	177	2526	\N	47	\N	GOAL	\N
2417	1386	126	2378	\N	14	\N	GOAL	\N
2418	1386	126	2378	\N	38	\N	GOAL	\N
2419	1386	170	2527	\N	81	\N	GOAL	\N
2420	1387	171	2528	\N	88	\N	GOAL	\N
2421	1388	127	2529	\N	30	\N	GOAL	\N
2422	1388	185	2521	\N	53	\N	GOAL	\N
2423	1390	182	2531	\N	30	\N	GOAL	\N
2424	1390	183	2318	\N	33	\N	GOAL	\N
2425	1390	183	2318	\N	38	\N	GOAL	\N
2426	1390	182	2531	\N	68	\N	GOAL	\N
2427	1390	183	2533	\N	81	\N	GOAL	\N
2428	1391	187	2349	\N	2	\N	GOAL	\N
2429	1391	187	2400	\N	51	\N	GOAL	\N
2430	1391	179	2534	\N	81	\N	GOAL	\N
2431	1392	175	\N	\N	45	\N	GOAL	\N
2432	1392	184	\N	\N	57	\N	GOAL	\N
2433	1396	186	2535	\N	39	\N	GOAL	\N
2434	1397	170	\N	\N	2	\N	GOAL	\N
2435	1397	176	2536	\N	45	\N	GOAL	\N
2436	1397	176	2537	\N	47	\N	GOAL	\N
2437	1397	170	\N	\N	49	\N	GOAL	\N
2438	1398	180	2538	\N	10	\N	GOAL	\N
2439	1398	180	2407	\N	29	\N	GOAL	\N
2440	1400	177	2541	\N	14	\N	GOAL	\N
2441	1400	187	2349	\N	97	\N	GOAL	\N
2442	1401	182	2346	\N	52	\N	GOAL	\N
2443	1401	171	2542	\N	60	\N	GOAL	\N
2444	1401	171	2528	\N	66	\N	GOAL	\N
2445	1401	182	2543	\N	85	\N	GOAL	\N
2446	1401	171	2350	\N	91	\N	GOAL	\N
2447	1402	74	2544	\N	56	\N	GOAL	\N
2448	1402	74	2544	\N	64	\N	GOAL	\N
2449	1402	74	2545	\N	79	\N	GOAL	\N
2450	1402	126	2406	\N	83	\N	GOAL	\N
2451	1402	74	2382	\N	89	\N	GOAL	\N
2452	1403	181	2546	\N	12	\N	GOAL	\N
2453	1404	170	2547	\N	38	\N	GOAL	\N
2454	1404	183	2548	\N	43	\N	GOAL	\N
2455	1404	170	2384	\N	45	\N	GOAL	\N
2456	1405	176	2365	\N	36	\N	GOAL	\N
2457	1405	176	2537	\N	41	\N	GOAL	\N
2458	1406	186	2329	\N	8	\N	GOAL	\N
2459	1406	186	2549	\N	40	\N	GOAL	\N
2460	1406	179	2550	\N	81	\N	GOAL	\N
2461	1407	186	\N	\N	\N	\N	GOAL	\N
2462	1407	186	\N	\N	\N	\N	GOAL	\N
2463	1408	177	\N	\N	\N	\N	GOAL	\N
2464	1408	177	\N	\N	\N	\N	GOAL	\N
2465	1409	180	\N	\N	79	\N	GOAL	\N
2466	1409	180	2551	\N	94	\N	GOAL	\N
2467	1410	184	2552	\N	84	\N	GOAL	\N
2468	1411	170	2384	\N	37	\N	GOAL	\N
2469	1412	185	2553	\N	74	\N	GOAL	\N
2470	1412	187	2349	\N	76	\N	GOAL	\N
2471	1412	185	2554	\N	78	\N	GOAL	\N
2472	1412	187	2555	\N	84	\N	GOAL	\N
2473	1413	128	2556	\N	15	\N	GOAL	\N
2474	1413	181	2301	\N	18	\N	GOAL	\N
2475	1413	181	2546	\N	35	\N	GOAL	\N
2476	1413	181	2546	\N	45	\N	GOAL	\N
2477	1413	128	2287	\N	69	\N	GOAL	\N
2478	1413	181	2557	\N	93	\N	GOAL	\N
2479	1414	126	2558	\N	6	\N	GOAL	\N
2480	1414	127	2560	\N	10	\N	GOAL	\N
2481	1414	126	2559	\N	14	\N	GOAL	\N
2482	1414	127	2561	\N	38	\N	GOAL	\N
2483	1415	74	2326	\N	45	\N	GOAL	\N
2484	1415	74	2381	\N	54	\N	GOAL	\N
2485	1416	187	2349	\N	82	\N	GOAL	\N
2486	1417	171	2542	\N	20	\N	GOAL	\N
2487	1417	171	2564	\N	41	\N	GOAL	\N
2488	1417	171	2376	\N	56	\N	GOAL	\N
2489	1417	171	2528	\N	87	\N	GOAL	\N
2490	1417	175	2563	\N	91	\N	GOAL	\N
2491	1418	74	2311	\N	45	\N	GOAL	\N
2492	1418	74	2382	\N	48	\N	GOAL	\N
2493	1419	179	2565	\N	34	\N	GOAL	\N
2494	1419	181	2566	\N	72	\N	GOAL	\N
2495	1420	186	2328	\N	2	\N	GOAL	\N
2496	1420	170	\N	\N	56	\N	GOAL	\N
2497	1420	170	\N	\N	83	\N	GOAL	\N
2498	1422	126	2567	\N	18	\N	GOAL	\N
2499	1309	183	2413	\N	47	\N	GOAL	\N
2500	1309	183	2318	\N	89	\N	GOAL	\N
2501	1205	13	2568	\N	25	\N	GOAL	\N
2502	1207	168	1365	\N	32	\N	GOAL	\N
2503	1424	185	2569	\N	93	\N	GOAL	\N
2504	1208	100	1780	\N	88	\N	GOAL	\N
2505	1211	1	983	\N	5	\N	GOAL	\N
2506	1211	1	983	\N	25	\N	GOAL	\N
2507	1206	3	1233	\N	15	\N	GOAL	\N
2508	1206	3	1415	\N	17	\N	GOAL	\N
2509	1211	1	1071	\N	33	\N	GOAL	\N
2510	1211	1	1071	\N	53	\N	GOAL	\N
2511	1211	1	983	\N	69	\N	GOAL	\N
2512	1206	15	1230	\N	40	\N	GOAL	\N
2513	1074	5	1245	\N	45	\N	GOAL	\N
2514	1074	17	\N	\N	65	\N	GOAL	\N
2515	1210	101	1706	\N	54	\N	GOAL	\N
2516	1209	4	2284	\N	39	\N	GOAL	\N
2517	1209	7	\N	\N	69	\N	GOAL	\N
2518	1209	7	1094	\N	78	\N	GOAL	\N
2519	1209	7	1094	\N	93	\N	GOAL	\N
2520	1074	17	1633	\N	90	\N	GOAL	\N
2521	1204	2	\N	\N	81	\N	GOAL	\N
2522	1204	2	1608	\N	88	\N	GOAL	\N
2523	1425	176	2373	\N	47	\N	GOAL	\N
2524	1425	176	2373	\N	52	\N	GOAL	\N
2525	1425	171	\N	\N	63	\N	GOAL	\N
2526	1425	176	\N	\N	83	\N	GOAL	\N
2527	1149	76	2351	\N	25	\N	GOAL	\N
2528	1149	99	1754	\N	55	\N	GOAL	\N
2529	1149	76	2399	\N	72	\N	GOAL	\N
2530	1426	177	2572	\N	8	\N	GOAL	\N
2531	1427	179	2576	\N	7	\N	GOAL	\N
2532	1426	128	2409	\N	25	\N	GOAL	\N
2533	1426	128	2573	\N	27	\N	GOAL	\N
2534	1427	126	2574	\N	33	\N	GOAL	\N
2535	1426	177	2541	\N	32	\N	GOAL	\N
2536	1429	183	2318	\N	39	\N	GOAL	\N
2537	1427	179	2577	\N	45	\N	GOAL	\N
2538	1429	183	2318	\N	47	\N	GOAL	\N
2539	1429	183	2318	\N	51	\N	GOAL	\N
2540	1427	126	2578	\N	55	\N	GOAL	\N
2541	1426	177	2575	\N	59	\N	GOAL	\N
2542	1426	177	2322	\N	64	\N	GOAL	\N
2543	1429	183	2533	\N	72	\N	GOAL	\N
2544	1426	177	2541	\N	75	\N	GOAL	\N
2545	1429	183	2413	\N	81	\N	GOAL	\N
2546	1429	183	2579	\N	87	\N	GOAL	\N
2547	1433	186	2329	\N	28	\N	GOAL	\N
2548	1432	187	2555	\N	56	\N	GOAL	\N
2549	1430	170	\N	\N	47	\N	GOAL	\N
2550	1147	3	1553	\N	12	\N	GOAL	\N
2551	1433	186	\N	\N	69	\N	GOAL	\N
2552	1433	186	\N	\N	86	\N	GOAL	\N
2553	1430	185	\N	\N	93	\N	GOAL	\N
2554	1147	1	1056	\N	79	\N	GOAL	\N
2555	1147	3	1454	\N	86	\N	GOAL	\N
2556	1147	1	2273	\N	88	\N	GOAL	\N
2557	1176	101	\N	\N	22	\N	GOAL	\N
2558	1165	76	1184	\N	73	\N	GOAL	\N
2559	1165	102	\N	\N	94	\N	GOAL	\N
2560	1436	127	2408	\N	27	\N	GOAL	\N
2561	1436	127	2408	\N	80	\N	GOAL	\N
2562	1436	127	2359	\N	84	\N	GOAL	\N
2563	1438	128	\N	\N	40	\N	GOAL	\N
2564	1438	187	2420	\N	69	\N	GOAL	\N
2565	1438	187	2380	\N	79	\N	GOAL	\N
2566	1438	187	2380	\N	87	\N	GOAL	\N
2567	1437	175	\N	\N	51	\N	GOAL	\N
2568	1437	185	\N	\N	61	\N	GOAL	\N
2569	1437	185	\N	\N	64	\N	GOAL	\N
2570	1434	179	\N	\N	57	\N	GOAL	\N
2571	1434	176	\N	\N	76	\N	GOAL	\N
2572	1434	176	\N	\N	94	\N	GOAL	\N
2573	1439	180	\N	\N	16	\N	GOAL	\N
2574	1439	177	\N	\N	31	\N	GOAL	\N
2575	1439	177	\N	\N	88	\N	GOAL	\N
2576	1439	177	\N	\N	95	\N	GOAL	\N
2577	1443	170	2285	\N	8	\N	GOAL	\N
2578	1443	184	\N	\N	38	\N	GOAL	\N
2579	1443	170	2547	\N	70	\N	GOAL	\N
2580	1450	187	2580	\N	73	\N	GOAL	\N
2581	1448	185	2569	\N	24	\N	GOAL	\N
2582	1448	185	2569	\N	35	\N	GOAL	\N
2583	1448	185	2569	\N	48	\N	GOAL	\N
2584	1448	186	2582	\N	74	\N	GOAL	\N
2585	1448	185	2581	\N	90	\N	GOAL	\N
2586	1445	176	2583	\N	9	\N	GOAL	\N
2587	1444	181	2393	\N	5	\N	GOAL	\N
2588	1444	181	2393	\N	20	\N	GOAL	\N
2589	1444	181	2302	\N	30	\N	GOAL	\N
2590	1444	175	2563	\N	83	\N	GOAL	\N
2591	1444	181	2306	\N	84	\N	GOAL	\N
2592	1454	185	2569	\N	32	\N	GOAL	\N
2593	1454	185	2569	\N	37	\N	GOAL	\N
2594	1454	185	2363	\N	63	\N	GOAL	\N
2595	1454	179	2319	\N	65	\N	GOAL	\N
2596	1459	176	2584	\N	21	\N	GOAL	\N
2597	1459	181	2393	\N	32	\N	GOAL	\N
2598	1459	181	2302	\N	50	\N	GOAL	\N
2599	1459	176	2373	\N	90	\N	GOAL	\N
2600	1458	128	2556	\N	23	\N	GOAL	\N
2601	1458	180	2407	\N	42	\N	GOAL	\N
2602	1458	128	2585	\N	58	\N	GOAL	\N
2603	1458	128	2585	\N	75	\N	GOAL	\N
2604	1458	180	2374	\N	82	\N	GOAL	\N
2605	1458	180	2407	\N	94	\N	GOAL	\N
2606	1453	183	2586	\N	25	\N	GOAL	\N
2607	1453	177	2322	\N	34	\N	GOAL	\N
2608	1453	177	2572	\N	73	\N	GOAL	\N
2609	1457	127	2359	\N	18	\N	GOAL	\N
2610	1457	127	2408	\N	62	\N	GOAL	\N
2611	1435	181	2393	\N	4	\N	GOAL	\N
2612	1435	181	2566	\N	16	\N	GOAL	\N
2613	1435	181	2546	\N	37	\N	GOAL	\N
2614	1442	126	2559	\N	43	\N	GOAL	\N
2615	1435	181	2546	\N	51	\N	GOAL	\N
2616	1440	74	2320	\N	47	\N	GOAL	\N
2617	1440	74	2325	\N	60	\N	GOAL	\N
2618	1440	74	2587	\N	64	\N	GOAL	\N
2619	1442	126	2378	\N	86	\N	GOAL	\N
2620	1442	126	2559	\N	91	\N	GOAL	\N
2621	1223	87	1137	\N	1	\N	GOAL	\N
2622	1076	3	2592	\N	45	\N	GOAL	\N
2623	1222	7	2341	\N	70	\N	GOAL	\N
2624	1223	87	2275	\N	70	\N	GOAL	\N
2625	1212	11	2436	\N	47	\N	GOAL	\N
2626	1212	76	1763	\N	50	\N	GOAL	\N
2627	1004	1	983	\N	15	\N	GOAL	\N
2628	1007	76	2351	\N	5	\N	GOAL	\N
2629	1058	100	1455	\N	55	\N	GOAL	\N
2630	1057	169	2588	\N	21	\N	GOAL	\N
2631	1057	169	2589	\N	78	\N	GOAL	\N
2632	1057	102	2590	\N	83	\N	GOAL	\N
2633	1061	11	1032	\N	11	\N	GOAL	\N
2634	1061	11	1413	\N	49	\N	GOAL	\N
2635	1061	11	1085	\N	56	\N	GOAL	\N
2636	1061	11	1085	\N	65	\N	GOAL	\N
2637	1146	11	2436	\N	46	\N	GOAL	\N
2638	1146	11	2332	\N	90	\N	GOAL	\N
2639	1075	168	2352	\N	90	\N	GOAL	\N
2640	1213	99	1738	\N	80	\N	GOAL	\N
2641	1214	87	1136	\N	6	\N	GOAL	\N
2642	1214	87	2276	\N	89	\N	GOAL	\N
2643	1215	100	2423	\N	40	\N	GOAL	\N
2644	1215	100	1460	\N	80	\N	GOAL	\N
2645	1217	15	1314	\N	29	\N	GOAL	\N
2646	1217	15	1054	\N	44	\N	GOAL	\N
2647	1217	4	977	\N	33	\N	GOAL	\N
2648	1218	102	2590	\N	41	\N	GOAL	\N
2649	1218	17	2591	\N	71	\N	GOAL	\N
2650	1219	76	1367	\N	85	\N	GOAL	\N
2651	1220	11	1032	\N	13	\N	GOAL	\N
2652	1220	11	2436	\N	87	\N	GOAL	\N
2653	1221	1	1066	\N	27	\N	GOAL	\N
2654	1221	88	1653	\N	63	\N	GOAL	\N
2655	1221	1	2273	\N	89	\N	GOAL	\N
2656	1227	102	1300	\N	12	\N	GOAL	\N
2657	1227	102	1300	\N	78	\N	GOAL	\N
2658	1216	169	\N	\N	82	\N	GOAL	\N
2659	1228	4	977	\N	\N	\N	GOAL	\N
2660	1228	4	1113	\N	\N	\N	GOAL	\N
2661	1228	4	1106	\N	\N	\N	GOAL	\N
2662	1229	11	1032	\N	21	\N	GOAL	\N
2663	1229	11	1085	\N	38	\N	GOAL	\N
2664	1229	11	1413	\N	88	\N	GOAL	\N
2665	1229	168	1365	\N	35	\N	GOAL	\N
2666	1229	168	2280	\N	71	\N	GOAL	\N
2667	1230	1	1071	\N	20	\N	GOAL	\N
2668	1077	5	\N	\N	\N	\N	GOAL	\N
2669	1077	5	\N	\N	\N	\N	GOAL	\N
2670	1077	168	2352	\N	32	\N	GOAL	\N
2671	1077	168	2352	\N	45	\N	GOAL	\N
2672	1077	168	1365	\N	55	\N	GOAL	\N
2673	1231	3	2592	\N	16	\N	GOAL	\N
2674	1232	17	2591	\N	54	\N	GOAL	\N
2675	1232	15	1054	\N	90	\N	GOAL	\N
2676	1233	100	1460	\N	77	\N	GOAL	\N
2677	1234	169	\N	\N	\N	\N	GOAL	\N
2678	1234	101	1153	\N	78	\N	GOAL	\N
2679	1237	102	\N	\N	\N	\N	GOAL	\N
2680	1237	87	1587	\N	\N	\N	GOAL	\N
2681	1239	2	1070	\N	\N	\N	GOAL	\N
2682	1239	11	1085	\N	\N	\N	GOAL	\N
2683	1239	11	1029	\N	\N	\N	GOAL	\N
2684	1236	76	2399	\N	11	\N	GOAL	\N
2685	1236	76	\N	\N	\N	\N	GOAL	\N
2686	1236	76	\N	\N	\N	\N	GOAL	\N
2687	1236	88	\N	\N	\N	\N	GOAL	\N
2688	1241	88	\N	\N	\N	\N	GOAL	\N
2689	1242	100	1460	\N	50	\N	GOAL	\N
2690	1242	101	\N	\N	\N	\N	GOAL	\N
2691	1243	169	\N	\N	\N	\N	GOAL	\N
2692	1243	169	\N	\N	\N	\N	GOAL	\N
2693	1243	4	\N	\N	\N	\N	GOAL	\N
2694	1078	5	\N	\N	\N	\N	GOAL	\N
2695	1078	5	\N	\N	\N	\N	GOAL	\N
2696	1078	8	\N	\N	\N	\N	GOAL	\N
2697	1078	8	\N	\N	\N	\N	GOAL	\N
2698	1244	13	1336	\N	\N	\N	GOAL	\N
2699	1244	13	1336	\N	\N	\N	GOAL	\N
2700	1244	168	2352	\N	\N	\N	GOAL	\N
2701	1244	168	\N	\N	\N	\N	GOAL	\N
2702	1244	168	1365	\N	\N	\N	GOAL	\N
2703	1247	1	1071	\N	\N	\N	GOAL	\N
2704	1247	1	1453	\N	\N	\N	GOAL	\N
2705	1245	102	1300	\N	\N	\N	GOAL	\N
2706	1245	102	1300	\N	\N	\N	GOAL	\N
2707	1246	99	1752	\N	30	\N	GOAL	\N
2708	1246	11	1029	\N	45	\N	GOAL	\N
2709	1246	11	1413	\N	59	\N	GOAL	\N
2710	1246	11	1472	\N	63	\N	GOAL	\N
2711	1246	11	1085	\N	77	\N	GOAL	\N
2712	1248	2	\N	\N	\N	\N	GOAL	\N
2713	1248	2	\N	\N	\N	\N	GOAL	\N
2714	1248	3	\N	\N	\N	\N	GOAL	\N
2715	1248	3	\N	\N	\N	\N	GOAL	\N
2716	1175	1	\N	\N	\N	\N	GOAL	\N
2717	1081	3	\N	\N	27	\N	GOAL	\N
2718	1268	5	\N	\N	46	\N	GOAL	\N
2719	1272	17	\N	\N	24	\N	GOAL	\N
2720	1272	17	1257	\N	42	\N	GOAL	\N
2721	1272	88	\N	\N	61	\N	GOAL	\N
2722	1272	88	\N	\N	90	\N	GOAL	\N
2723	1275	76	2399	\N	40	\N	GOAL	\N
2724	1273	87	\N	\N	22	\N	GOAL	\N
2725	1274	1	\N	\N	27	\N	GOAL	\N
2726	1274	1	983	\N	33	\N	GOAL	\N
2727	1274	1	983	\N	43	\N	GOAL	\N
2728	1274	102	1300	\N	82	\N	GOAL	\N
2729	1267	2	\N	\N	56	\N	GOAL	\N
2730	1267	99	\N	\N	68	\N	GOAL	\N
2731	1270	100	\N	\N	76	\N	GOAL	\N
2732	1270	100	997	\N	89	\N	GOAL	\N
2733	1080	11	1035	\N	57	\N	GOAL	\N
2734	1080	11	1035	\N	90	\N	GOAL	\N
2735	1080	169	1292	\N	22	\N	GOAL	\N
2736	1263	3	1415	\N	50	\N	GOAL	\N
2737	1258	168	2352	\N	33	\N	GOAL	\N
2738	1258	99	\N	\N	75	\N	GOAL	\N
2739	1259	8	1381	\N	2	\N	GOAL	\N
2740	1259	8	1096	\N	70	\N	GOAL	\N
2741	1259	8	1096	\N	87	\N	GOAL	\N
2742	1260	102	\N	\N	70	\N	GOAL	\N
2743	1261	101	1619	\N	18	\N	GOAL	\N
2744	1261	101	1619	\N	54	\N	GOAL	\N
2745	1261	88	\N	\N	44	\N	GOAL	\N
2746	1262	4	977	\N	14	\N	GOAL	\N
2747	1262	4	\N	\N	57	\N	GOAL	\N
2748	1264	15	1216	\N	74	\N	GOAL	\N
2749	1265	1	983	\N	45	\N	GOAL	\N
2750	1265	13	\N	\N	87	\N	GOAL	\N
2751	1266	76	1763	\N	14	\N	GOAL	\N
2752	1266	76	\N	\N	32	\N	GOAL	\N
2753	1266	87	\N	\N	58	\N	GOAL	\N
2754	1079	169	\N	\N	30	\N	GOAL	\N
2755	1249	168	\N	\N	36	\N	GOAL	\N
2756	1249	168	\N	\N	44	\N	GOAL	\N
2757	1249	168	\N	\N	60	\N	GOAL	\N
2758	1257	76	2399	\N	50	\N	GOAL	\N
2759	1256	5	\N	\N	8	\N	GOAL	\N
2760	1256	1	\N	\N	90	\N	GOAL	\N
2761	1255	11	2332	\N	7	\N	GOAL	\N
2762	1255	11	2332	\N	78	\N	GOAL	\N
2763	1253	15	\N	\N	7	\N	GOAL	\N
2764	1253	15	\N	\N	83	\N	GOAL	\N
2765	1253	15	\N	\N	47	\N	GOAL	\N
2766	1253	87	2276	\N	54	\N	GOAL	\N
2767	1252	101	1367	\N	29	\N	GOAL	\N
2768	1252	101	1367	\N	42	\N	GOAL	\N
2769	1252	15	1216	\N	65	\N	GOAL	\N
2770	1251	4	2593	\N	29	\N	GOAL	\N
2771	1251	4	2593	\N	84	\N	GOAL	\N
2772	1251	4	2593	\N	90	\N	GOAL	\N
2773	1283	11	1035	\N	45	\N	GOAL	\N
2774	1283	11	1016	\N	47	\N	GOAL	\N
2775	1283	11	1085	\N	57	\N	GOAL	\N
2776	1284	76	\N	\N	76	\N	GOAL	\N
2777	1290	169	2588	\N	10	\N	GOAL	\N
2778	1290	169	\N	\N	39	\N	GOAL	\N
2779	1290	102	2397	\N	82	\N	GOAL	\N
2780	1290	169	\N	\N	86	\N	GOAL	\N
2781	1291	11	1035	\N	26	\N	GOAL	\N
2782	1082	168	2438	\N	\N	\N	GOAL	\N
2783	1276	87	\N	\N	\N	\N	GOAL	\N
2784	1276	3	2592	\N	\N	\N	GOAL	\N
2785	1277	8	\N	\N	\N	\N	GOAL	\N
2786	1277	8	\N	\N	\N	\N	GOAL	\N
2787	1279	4	1236	\N	\N	\N	GOAL	\N
2788	1279	99	1755	\N	\N	\N	GOAL	\N
2789	1279	99	1738	\N	\N	\N	GOAL	\N
2790	1280	101	\N	\N	\N	\N	GOAL	\N
2791	1282	1	997	\N	\N	\N	GOAL	\N
2792	1278	13	\N	\N	\N	\N	GOAL	\N
2793	1278	13	\N	\N	\N	\N	GOAL	\N
2794	1278	13	\N	\N	\N	\N	GOAL	\N
2795	1083	17	2515	\N	\N	\N	GOAL	\N
2796	1083	168	2438	\N	\N	\N	GOAL	\N
2797	1285	3	1454	\N	\N	\N	GOAL	\N
2798	1286	101	\N	\N	\N	\N	GOAL	\N
2799	1287	8	1381	\N	\N	\N	GOAL	\N
2800	1288	15	1216	\N	\N	\N	GOAL	\N
2801	1289	4	977	\N	\N	\N	GOAL	\N
2802	1289	4	\N	\N	\N	\N	GOAL	\N
2803	1292	1	983	\N	\N	\N	GOAL	\N
2804	1292	100	1460	\N	\N	\N	GOAL	\N
2805	1292	100	\N	\N	\N	\N	GOAL	\N
2806	1084	2	\N	\N	\N	\N	GOAL	\N
2807	1084	2	1307	\N	\N	\N	GOAL	\N
2808	1084	2	2422	\N	\N	\N	GOAL	\N
2809	1084	88	1419	\N	\N	\N	GOAL	\N
2810	1478	169	1292	\N	\N	\N	GOAL	\N
2811	1478	76	1367	\N	\N	\N	GOAL	\N
2812	1479	100	\N	\N	\N	\N	GOAL	\N
2813	1479	15	2272	\N	\N	\N	GOAL	\N
2814	1479	15	\N	\N	\N	\N	GOAL	\N
2815	1480	5	1503	\N	\N	\N	GOAL	\N
2816	1480	5	1245	\N	\N	\N	GOAL	\N
2817	1480	87	\N	\N	\N	\N	GOAL	\N
2818	1482	11	1413	\N	\N	\N	GOAL	\N
2819	1483	168	1365	\N	\N	\N	GOAL	\N
2820	1483	168	1365	\N	\N	\N	GOAL	\N
2821	1483	102	1306	\N	\N	\N	GOAL	\N
2822	1484	8	1381	\N	\N	\N	GOAL	\N
2823	1484	1	\N	\N	\N	\N	GOAL	\N
2824	1486	99	1738	\N	\N	\N	GOAL	\N
2825	1486	99	1738	\N	\N	\N	GOAL	\N
2826	1486	99	1738	\N	\N	\N	GOAL	\N
2827	1486	99	\N	\N	\N	\N	GOAL	\N
2828	1486	17	1627	\N	\N	\N	GOAL	\N
2829	1487	169	2588	\N	\N	\N	GOAL	\N
2830	1487	169	2588	\N	\N	\N	GOAL	\N
2831	1487	169	\N	\N	\N	\N	GOAL	\N
2832	1487	15	\N	\N	\N	\N	GOAL	\N
2833	1488	5	1245	\N	\N	\N	GOAL	\N
2834	1490	3	1544	\N	\N	\N	GOAL	\N
2835	1491	168	2352	\N	\N	\N	GOAL	\N
2836	1492	8	1004	\N	\N	\N	GOAL	\N
2837	1492	8	\N	\N	\N	\N	GOAL	\N
2838	1492	102	\N	\N	\N	\N	GOAL	\N
2839	1493	2	1070	\N	\N	\N	GOAL	\N
2840	1493	17	1620	\N	\N	\N	GOAL	\N
2841	1493	17	2515	\N	\N	\N	GOAL	\N
2842	1489	11	\N	\N	37	\N	GOAL	\N
2843	1489	11	1413	\N	69	\N	GOAL	\N
2844	1489	101	\N	\N	71	\N	GOAL	\N
2845	1489	11	1032	\N	88	\N	GOAL	\N
2846	1085	99	1764	\N	\N	\N	GOAL	\N
2847	1085	88	\N	\N	\N	\N	GOAL	\N
2848	1494	13	1336	\N	\N	\N	GOAL	\N
2849	1494	13	1449	\N	\N	\N	GOAL	\N
2850	1502	1	\N	\N	88	\N	GOAL	\N
2851	1498	15	\N	\N	34	\N	GOAL	\N
2852	1498	15	1042	\N	54	\N	GOAL	\N
2853	1501	7	\N	\N	74	\N	GOAL	\N
2854	1503	76	1210	\N	50	\N	GOAL	\N
2855	1503	76	1210	\N	78	\N	GOAL	\N
2856	1086	17	\N	\N	\N	\N	GOAL	\N
2857	1086	17	\N	\N	\N	\N	GOAL	\N
2858	1496	169	\N	\N	\N	\N	GOAL	\N
2859	1497	4	\N	\N	\N	\N	GOAL	\N
2860	1497	13	\N	\N	\N	\N	GOAL	\N
2861	1499	87	\N	\N	\N	\N	GOAL	\N
2862	1499	168	\N	\N	\N	\N	GOAL	\N
2863	1499	168	\N	\N	\N	\N	GOAL	\N
2864	1500	101	\N	\N	\N	\N	GOAL	\N
2865	1504	11	\N	\N	70	\N	GOAL	\N
2866	1504	11	\N	\N	71	\N	GOAL	\N
2867	1505	76	2399	\N	37	\N	GOAL	\N
2868	1505	76	2351	\N	82	\N	GOAL	\N
2869	1508	15	1216	\N	\N	\N	GOAL	\N
2870	1087	100	\N	\N	\N	\N	GOAL	\N
2871	1509	7	1100	\N	\N	\N	GOAL	\N
2872	1509	168	\N	\N	\N	\N	GOAL	\N
2873	1510	4	\N	\N	\N	\N	GOAL	\N
2874	1510	4	\N	\N	\N	\N	GOAL	\N
2875	1510	5	\N	\N	\N	\N	GOAL	\N
2876	1510	5	\N	\N	\N	\N	GOAL	\N
2877	1510	5	\N	\N	\N	\N	GOAL	\N
2878	1507	101	\N	\N	\N	\N	GOAL	\N
2879	1513	1	2594	\N	5	\N	GOAL	\N
2880	1513	11	1018	\N	8	\N	GOAL	\N
2881	1513	11	2436	\N	16	\N	GOAL	\N
2882	1513	1	2273	\N	50	\N	GOAL	\N
2883	1513	11	1413	\N	71	\N	GOAL	\N
2884	1512	102	\N	\N	17	\N	GOAL	\N
2885	1506	169	1292	\N	61	\N	GOAL	\N
2886	1506	17	\N	\N	27	\N	GOAL	\N
2887	1506	17	1259	\N	95	\N	GOAL	\N
2888	1511	87	1219	\N	14	\N	GOAL	\N
2889	1511	87	1219	\N	72	\N	GOAL	\N
2890	1511	87	\N	\N	52	\N	GOAL	\N
2891	1511	8	1234	\N	22	\N	GOAL	\N
2892	1511	8	1381	\N	48	\N	GOAL	\N
2893	1511	8	1381	\N	88	\N	GOAL	\N
2894	1520	102	1260	\N	8	\N	GOAL	\N
2895	1520	102	1566	\N	19	\N	GOAL	\N
2896	1521	1	1063	\N	85	\N	GOAL	\N
2897	1516	7	1496	\N	16	\N	GOAL	\N
2898	1516	7	1257	\N	69	\N	GOAL	\N
2899	1516	7	1114	\N	82	\N	GOAL	\N
2900	1516	4	1236	\N	6	\N	GOAL	\N
2901	1517	88	\N	\N	\N	\N	GOAL	\N
2902	1517	13	2385	\N	17	\N	GOAL	\N
2903	1517	13	2385	\N	29	\N	GOAL	\N
2904	1514	15	1216	\N	31	\N	GOAL	\N
2905	1514	3	1544	\N	18	\N	GOAL	\N
2906	1519	17	2591	\N	26	\N	GOAL	\N
2907	1522	76	2595	\N	44	\N	GOAL	\N
2908	1518	87	\N	\N	\N	\N	GOAL	\N
2909	1528	1	2594	\N	23	\N	GOAL	\N
2910	1528	1	2594	\N	55	\N	GOAL	\N
2911	1528	15	2272	\N	73	\N	GOAL	\N
2912	1089	3	1261	\N	10	\N	GOAL	\N
2913	1523	8	\N	\N	\N	\N	GOAL	\N
2914	1523	8	\N	\N	\N	\N	GOAL	\N
2915	1523	4	1236	\N	65	\N	GOAL	\N
2916	1524	168	2352	\N	28	\N	GOAL	\N
2917	1524	101	\N	\N	\N	\N	GOAL	\N
2918	1525	5	1245	\N	64	\N	GOAL	\N
2919	1526	100	1460	\N	83	\N	GOAL	\N
2920	1526	100	\N	\N	90	\N	GOAL	\N
2921	1529	11	1413	\N	2	\N	GOAL	\N
2922	1529	11	2436	\N	13	\N	GOAL	\N
2923	1529	11	2436	\N	18	\N	GOAL	\N
2924	1529	11	1035	\N	19	\N	GOAL	\N
2925	1529	11	1413	\N	26	\N	GOAL	\N
2926	1529	11	1413	\N	42	\N	GOAL	\N
2927	1529	11	2270	\N	60	\N	GOAL	\N
2928	1529	11	1413	\N	70	\N	GOAL	\N
2929	1530	13	1449	\N	80	\N	GOAL	\N
2930	1531	102	\N	\N	62	\N	GOAL	\N
2931	1532	17	1633	\N	\N	\N	GOAL	\N
2932	1532	17	\N	\N	\N	\N	GOAL	\N
2933	1533	169	2588	\N	\N	\N	GOAL	\N
2934	1534	4	\N	\N	\N	\N	GOAL	\N
2935	1535	7	1114	\N	\N	\N	GOAL	\N
2936	1535	101	1887	\N	\N	\N	GOAL	\N
2937	1536	88	\N	\N	\N	\N	GOAL	\N
2938	1536	88	\N	\N	\N	\N	GOAL	\N
2939	1536	5	\N	\N	\N	\N	GOAL	\N
2940	1185	76	1367	\N	6	\N	GOAL	\N
2941	1537	102	1408	\N	41	\N	GOAL	\N
2942	1185	168	1365	\N	63	\N	GOAL	\N
2943	1537	102	1408	\N	80	\N	GOAL	\N
2944	1537	99	1464	\N	90	\N	GOAL	\N
2945	98	13	\N	\N	\N	\N	OWN_GOAL	\N
2946	184	4	1122	\N	\N	\N	OWN_GOAL	\N
2947	191	12	1279	\N	\N	\N	OWN_GOAL	\N
2948	736	51	\N	\N	88	\N	OWN_GOAL	\N
2949	396	12	1325	\N	78	\N	OWN_GOAL	\N
2950	785	63	\N	\N	52	\N	OWN_GOAL	\N
2951	479	6	1437	\N	29	\N	OWN_GOAL	\N
2952	525	2	1195	\N	4	\N	OWN_GOAL	\N
2953	456	100	1444	\N	49	\N	OWN_GOAL	\N
2954	442	101	1706	\N	66	\N	OWN_GOAL	\N
2955	387	101	1709	\N	90	\N	OWN_GOAL	\N
2956	372	87	1322	\N	49	\N	OWN_GOAL	\N
2957	351	15	1272	\N	62	\N	OWN_GOAL	\N
2958	580	6	\N	\N	90	\N	OWN_GOAL	\N
2959	830	121	1893	\N	\N	\N	OWN_GOAL	\N
2960	848	121	1894	\N	\N	\N	OWN_GOAL	\N
2961	597	102	\N	\N	67	\N	OWN_GOAL	\N
2962	645	11	1016	\N	42	\N	OWN_GOAL	\N
2963	667	2	1600	\N	2	\N	OWN_GOAL	\N
2964	944	28	2030	\N	89	\N	OWN_GOAL	\N
2965	932	28	2030	\N	89	\N	OWN_GOAL	\N
2966	973	105	2210	\N	90	\N	OWN_GOAL	\N
2967	980	105	2253	\N	101	\N	OWN_GOAL	\N
2968	981	39	2236	\N	40	\N	OWN_GOAL	\N
2969	979	2	2279	\N	92	\N	OWN_GOAL	\N
2970	1060	5	2362	\N	37	\N	OWN_GOAL	\N
2971	1301	187	2379	\N	59	\N	OWN_GOAL	\N
2972	1296	181	2361	\N	49	\N	OWN_GOAL	\N
2973	1133	169	1822	\N	5	\N	OWN_GOAL	\N
2974	1321	76	2395	\N	79	\N	OWN_GOAL	\N
2975	1308	176	\N	\N	11	\N	OWN_GOAL	\N
2976	1327	45	\N	\N	66	\N	OWN_GOAL	\N
2977	1330	47	2455	\N	62	\N	OWN_GOAL	\N
2978	1355	39	2239	\N	90	\N	OWN_GOAL	\N
2979	1197	168	\N	\N	94	\N	OWN_GOAL	\N
2980	1203	99	1755	\N	76	\N	OWN_GOAL	\N
2981	1388	127	2530	\N	50	\N	OWN_GOAL	\N
2982	1390	183	2519	\N	52	\N	OWN_GOAL	\N
2983	1391	187	2401	\N	16	\N	OWN_GOAL	\N
2984	1399	128	2540	\N	89	\N	OWN_GOAL	\N
2985	1415	176	2562	\N	64	\N	OWN_GOAL	\N
2986	1436	183	\N	\N	30	\N	OWN_GOAL	\N
2987	1436	127	\N	\N	44	\N	OWN_GOAL	\N
2988	1212	11	1016	\N	53	\N	OWN_GOAL	\N
2989	1214	2	\N	\N	76	\N	OWN_GOAL	\N
2990	1262	4	1115	\N	45	\N	OWN_GOAL	\N
2991	1254	102	\N	\N	22	\N	OWN_GOAL	\N
2992	1284	76	2571	\N	42	\N	OWN_GOAL	\N
2993	60	1	1060	\N	\N	\N	PENALTY_GOAL	\N
2994	96	8	1227	\N	\N	\N	PENALTY_GOAL	\N
2995	301	76	963	\N	40	\N	PENALTY_GOAL	\N
2996	311	2	1304	\N	58	\N	PENALTY_GOAL	\N
2997	312	1	999	\N	42	\N	PENALTY_GOAL	\N
2998	334	3	1552	\N	93	\N	PENALTY_GOAL	\N
2999	332	15	1047	\N	79	\N	PENALTY_GOAL	\N
3000	371	5	1222	\N	10	\N	PENALTY_GOAL	\N
3001	380	88	1246	\N	34	\N	PENALTY_GOAL	\N
3002	380	88	1246	\N	36	\N	PENALTY_GOAL	\N
3003	738	104	\N	\N	36	\N	PENALTY_GOAL	\N
3004	735	43	\N	\N	13	\N	PENALTY_GOAL	\N
3005	407	2	1304	\N	76	\N	PENALTY_GOAL	\N
3006	430	17	1391	\N	29	\N	PENALTY_GOAL	\N
3007	435	15	1054	\N	90	\N	PENALTY_GOAL	\N
3008	309	4	1522	\N	32	\N	PENALTY_GOAL	\N
3009	361	76	982	\N	79	\N	PENALTY_GOAL	\N
3010	446	102	1311	\N	15	\N	PENALTY_GOAL	\N
3011	447	13	1335	\N	45	\N	PENALTY_GOAL	\N
3012	447	76	982	\N	76	\N	PENALTY_GOAL	\N
3013	463	8	1381	\N	30	\N	PENALTY_GOAL	\N
3014	811	11	1035	\N	83	\N	PENALTY_GOAL	\N
3015	527	4	1234	\N	70	\N	PENALTY_GOAL	\N
3016	531	13	1335	\N	40	\N	PENALTY_GOAL	\N
3017	572	76	980	\N	68	\N	PENALTY_GOAL	\N
3018	612	1	979	\N	85	\N	PENALTY_GOAL	\N
3019	919	133	1915	\N	\N	\N	PENALTY_GOAL	\N
3020	919	129	\N	\N	\N	\N	PENALTY_GOAL	\N
3021	919	133	\N	\N	\N	\N	PENALTY_GOAL	\N
3022	919	133	\N	\N	\N	\N	PENALTY_GOAL	\N
3023	919	129	\N	\N	\N	\N	PENALTY_GOAL	\N
3024	919	133	\N	\N	\N	\N	PENALTY_GOAL	\N
3025	668	15	1216	\N	63	\N	PENALTY_GOAL	\N
3026	942	166	\N	\N	55	\N	PENALTY_GOAL	\N
3027	945	104	1959	\N	66	\N	PENALTY_GOAL	\N
3028	934	54	2115	\N	34	\N	PENALTY_GOAL	\N
3029	936	105	2182	\N	34	\N	PENALTY_GOAL	\N
3030	961	52	2057	\N	78	\N	PENALTY_GOAL	\N
3031	966	64	\N	\N	120	\N	PENALTY_GOAL	\N
3032	970	25	\N	\N	120	\N	PENALTY_GOAL	\N
3033	937	59	2194	\N	72	\N	PENALTY_GOAL	\N
3034	956	61	2186	\N	65	\N	PENALTY_GOAL	\N
3035	973	105	\N	\N	120	\N	PENALTY_GOAL	\N
3036	976	54	\N	\N	120	\N	PENALTY_GOAL	\N
3037	981	39	1944	\N	72	\N	PENALTY_GOAL	\N
3038	1027	102	1299	\N	87	\N	PENALTY_GOAL	\N
3039	1028	11	1018	\N	86	\N	PENALTY_GOAL	\N
3040	1012	170	2285	\N	29	\N	PENALTY_GOAL	\N
3041	1017	185	2372	\N	85	\N	PENALTY_GOAL	\N
3042	1009	74	2325	\N	51	\N	PENALTY_GOAL	\N
3043	1018	187	2349	\N	74	\N	PENALTY_GOAL	\N
3044	1298	126	2378	\N	75	\N	PENALTY_GOAL	\N
3045	1302	177	2322	\N	39	\N	PENALTY_GOAL	\N
3046	1131	11	1413	\N	78	\N	PENALTY_GOAL	\N
3047	1140	102	2397	\N	9	\N	PENALTY_GOAL	\N
3048	1134	87	2398	\N	18	\N	PENALTY_GOAL	\N
3049	1163	5	1245	\N	49	\N	PENALTY_GOAL	\N
3050	1180	11	1413	\N	8	\N	PENALTY_GOAL	\N
3051	1362	33	2198	\N	50	\N	PENALTY_GOAL	\N
3052	1367	25	1978	\N	35	\N	PENALTY_GOAL	\N
3053	1388	185	2372	\N	48	\N	PENALTY_GOAL	\N
3054	1390	183	2318	\N	62	\N	PENALTY_GOAL	\N
3055	1391	187	2349	\N	45	\N	PENALTY_GOAL	\N
3056	1398	180	2539	\N	52	\N	PENALTY_GOAL	\N
3057	1410	184	2520	\N	48	\N	PENALTY_GOAL	\N
3058	1439	177	\N	\N	62	\N	PENALTY_GOAL	\N
3059	1439	177	\N	\N	75	\N	PENALTY_GOAL	\N
3060	1224	100	2423	\N	28	\N	PENALTY_GOAL	\N
3061	1212	11	1413	\N	42	\N	PENALTY_GOAL	\N
3062	1263	100	1460	\N	61	\N	PENALTY_GOAL	\N
3063	1290	102	\N	\N	81	\N	PENALTY_GOAL	\N
3064	300	102	1557	\N	90	\N	RED_CARD	\N
3065	302	5	1171	\N	67	\N	RED_CARD	\N
3066	350	11	1035	\N	80	\N	RED_CARD	\N
3067	358	87	1134	\N	90	\N	RED_CARD	\N
3068	375	101	1710	\N	87	\N	RED_CARD	\N
3069	399	1	1061	\N	35	\N	RED_CARD	\N
3070	447	13	1683	\N	45	\N	RED_CARD	\N
3071	447	76	1184	\N	45	\N	RED_CARD	\N
3072	905	122	1917	\N	72	\N	RED_CARD	\N
3073	492	3	1538	\N	75	\N	RED_CARD	\N
3074	954	53	1930	\N	12	\N	RED_CARD	\N
3075	974	64	2217	\N	83	\N	RED_CARD	\N
3076	318	7	1078	\N	56	\N	YELLOW_CARD	\N
3077	293	13	1447	\N	\N	\N	YELLOW_CARD	\N
3078	301	7	1088	\N	45	\N	YELLOW_CARD	\N
3079	301	7	1091	\N	52	\N	YELLOW_CARD	\N
3080	302	5	1169	\N	26	\N	YELLOW_CARD	\N
3081	302	1	1055	\N	75	\N	YELLOW_CARD	\N
3082	302	1	997	\N	76	\N	YELLOW_CARD	\N
3083	304	17	1391	\N	21	\N	YELLOW_CARD	\N
3084	310	102	1373	\N	59	\N	YELLOW_CARD	\N
3085	310	15	1042	\N	90	\N	YELLOW_CARD	\N
3086	307	11	1413	\N	43	\N	YELLOW_CARD	\N
3087	312	8	1465	\N	54	\N	YELLOW_CARD	\N
3088	321	12	1289	\N	68	\N	YELLOW_CARD	\N
3089	329	6	1421	\N	\N	\N	YELLOW_CARD	\N
3090	293	13	1334	\N	76	\N	YELLOW_CARD	\N
3091	294	15	1217	\N	40	\N	YELLOW_CARD	\N
3092	294	8	1381	\N	49	\N	YELLOW_CARD	\N
3093	294	8	1243	\N	75	\N	YELLOW_CARD	\N
3094	295	99	1752	\N	93	\N	YELLOW_CARD	\N
3095	295	2	1069	\N	25	\N	YELLOW_CARD	\N
3096	295	2	1302	\N	93	\N	YELLOW_CARD	\N
3097	296	100	1768	\N	34	\N	YELLOW_CARD	\N
3098	296	100	1787	\N	80	\N	YELLOW_CARD	\N
3099	296	87	1154	\N	83	\N	YELLOW_CARD	\N
3100	297	101	1735	\N	69	\N	YELLOW_CARD	\N
3101	297	101	1724	\N	72	\N	YELLOW_CARD	\N
3102	297	101	1445	\N	76	\N	YELLOW_CARD	\N
3103	298	17	1390	\N	29	\N	YELLOW_CARD	\N
3104	299	12	1365	\N	78	\N	YELLOW_CARD	\N
3105	299	6	1415	\N	21	\N	YELLOW_CARD	\N
3106	299	6	1379	\N	35	\N	YELLOW_CARD	\N
3107	300	3	1236	\N	44	\N	YELLOW_CARD	\N
3108	300	3	1553	\N	73	\N	YELLOW_CARD	\N
3109	300	3	1548	\N	92	\N	YELLOW_CARD	\N
3110	300	102	1557	\N	90	\N	YELLOW_CARD	\N
3111	301	76	966	\N	2	\N	YELLOW_CARD	\N
3112	302	5	1171	\N	50	\N	YELLOW_CARD	\N
3113	304	88	1263	\N	66	\N	YELLOW_CARD	\N
3114	304	17	1403	\N	73	\N	YELLOW_CARD	\N
3115	308	87	1027	\N	56	\N	YELLOW_CARD	\N
3116	308	87	1376	\N	69	\N	YELLOW_CARD	\N
3117	308	87	1403	\N	93	\N	YELLOW_CARD	\N
3118	310	102	1300	\N	27	\N	YELLOW_CARD	\N
3119	311	2	1298	\N	66	\N	YELLOW_CARD	\N
3120	311	12	1365	\N	89	\N	YELLOW_CARD	\N
3121	312	8	1239	\N	80	\N	YELLOW_CARD	\N
3122	313	6	1437	\N	30	\N	YELLOW_CARD	\N
3123	313	6	1422	\N	66	\N	YELLOW_CARD	\N
3124	313	6	1416	\N	72	\N	YELLOW_CARD	\N
3125	313	99	1464	\N	92	\N	YELLOW_CARD	\N
3126	370	76	963	\N	23	\N	YELLOW_CARD	\N
3127	370	11	1446	\N	71	\N	YELLOW_CARD	\N
3128	381	11	1016	\N	71	\N	YELLOW_CARD	\N
3129	381	6	1430	\N	74	\N	YELLOW_CARD	\N
3130	609	8	1004	\N	\N	\N	YELLOW_CARD	\N
3131	492	3	1538	\N	25	\N	YELLOW_CARD	\N
3132	636	76	965	\N	45	\N	YELLOW_CARD	\N
3133	636	13	1224	\N	83	\N	YELLOW_CARD	\N
3134	655	76	963	\N	24	\N	YELLOW_CARD	\N
3135	657	101	1721	\N	34	\N	YELLOW_CARD	\N
3136	487	11	1013	\N	42	\N	YELLOW_CARD	\N
3137	941	11	1032	\N	38	\N	YELLOW_CARD	\N
3138	941	11	1013	\N	66	\N	YELLOW_CARD	\N
3139	944	28	2030	\N	92	\N	YELLOW_CARD	\N
3140	946	91	2069	\N	8	\N	YELLOW_CARD	\N
3141	946	91	2070	\N	35	\N	YELLOW_CARD	\N
3142	946	91	2080	\N	62	\N	YELLOW_CARD	\N
3143	938	40	2176	\N	35	\N	YELLOW_CARD	\N
3144	938	61	2177	\N	47	\N	YELLOW_CARD	\N
3145	938	61	2178	\N	54	\N	YELLOW_CARD	\N
3146	928	30	2179	\N	88	\N	YELLOW_CARD	\N
3147	929	40	2176	\N	35	\N	YELLOW_CARD	\N
3148	929	61	2177	\N	47	\N	YELLOW_CARD	\N
3149	929	61	2178	\N	54	\N	YELLOW_CARD	\N
3150	930	53	1926	\N	63	\N	YELLOW_CARD	\N
3151	931	25	1979	\N	53	\N	YELLOW_CARD	\N
3152	931	25	1971	\N	65	\N	YELLOW_CARD	\N
3153	931	25	1975	\N	81	\N	YELLOW_CARD	\N
3154	932	28	2030	\N	93	\N	YELLOW_CARD	\N
3155	933	91	2069	\N	9	\N	YELLOW_CARD	\N
3156	933	52	2049	\N	15	\N	YELLOW_CARD	\N
3157	933	91	2070	\N	36	\N	YELLOW_CARD	\N
3158	933	91	2080	\N	63	\N	YELLOW_CARD	\N
3159	933	91	2061	\N	91	\N	YELLOW_CARD	\N
3160	934	62	2089	\N	13	\N	YELLOW_CARD	\N
3161	934	62	2085	\N	18	\N	YELLOW_CARD	\N
3162	935	32	1827	\N	23	\N	YELLOW_CARD	\N
3163	935	69	2162	\N	40	\N	YELLOW_CARD	\N
3164	935	69	2166	\N	58	\N	YELLOW_CARD	\N
3165	935	69	2154	\N	61	\N	YELLOW_CARD	\N
3166	936	105	2181	\N	27	\N	YELLOW_CARD	\N
3167	936	43	2183	\N	33	\N	YELLOW_CARD	\N
3168	936	105	2182	\N	50	\N	YELLOW_CARD	\N
3169	940	104	1946	\N	27	\N	YELLOW_CARD	\N
3170	945	53	1935	\N	58	\N	YELLOW_CARD	\N
3171	945	25	1973	\N	82	\N	YELLOW_CARD	\N
3172	946	52	2044	\N	16	\N	YELLOW_CARD	\N
3173	946	54	2110	\N	21	\N	YELLOW_CARD	\N
3174	946	54	2109	\N	24	\N	YELLOW_CARD	\N
3175	946	52	2052	\N	39	\N	YELLOW_CARD	\N
3176	947	62	2097	\N	24	\N	YELLOW_CARD	\N
3177	947	91	2184	\N	29	\N	YELLOW_CARD	\N
3178	947	91	2071	\N	49	\N	YELLOW_CARD	\N
3179	947	62	2099	\N	55	\N	YELLOW_CARD	\N
3180	947	62	2081	\N	93	\N	YELLOW_CARD	\N
3181	949	69	2155	\N	59	\N	YELLOW_CARD	\N
3182	949	103	1997	\N	69	\N	YELLOW_CARD	\N
3183	954	104	1943	\N	18	\N	YELLOW_CARD	\N
3184	955	25	1975	\N	80	\N	YELLOW_CARD	\N
3185	958	28	2012	\N	71	\N	YELLOW_CARD	\N
3186	959	32	2144	\N	18	\N	YELLOW_CARD	\N
3187	959	32	2137	\N	18	\N	YELLOW_CARD	\N
3188	974	64	2228	\N	44	\N	YELLOW_CARD	\N
3189	974	52	2057	\N	91	\N	YELLOW_CARD	\N
3190	974	64	2227	\N	93	\N	YELLOW_CARD	\N
3191	975	32	1827	\N	13	\N	YELLOW_CARD	\N
3192	975	39	2244	\N	35	\N	YELLOW_CARD	\N
3193	975	32	2132	\N	49	\N	YELLOW_CARD	\N
3194	975	32	2146	\N	62	\N	YELLOW_CARD	\N
3195	975	32	2136	\N	75	\N	YELLOW_CARD	\N
3196	976	54	2107	\N	29	\N	YELLOW_CARD	\N
3197	976	69	2168	\N	29	\N	YELLOW_CARD	\N
3198	976	54	2117	\N	39	\N	YELLOW_CARD	\N
3199	976	69	2157	\N	43	\N	YELLOW_CARD	\N
3200	976	69	2150	\N	46	\N	YELLOW_CARD	\N
3201	976	69	2164	\N	88	\N	YELLOW_CARD	\N
3202	976	69	2158	\N	120	\N	YELLOW_CARD	\N
3203	977	25	1978	\N	86	\N	YELLOW_CARD	\N
3204	980	105	2205	\N	65	\N	YELLOW_CARD	\N
3205	980	52	2038	\N	72	\N	YELLOW_CARD	\N
3206	980	105	2268	\N	75	\N	YELLOW_CARD	\N
3207	981	54	1398	\N	51	\N	YELLOW_CARD	\N
3208	981	54	2119	\N	68	\N	YELLOW_CARD	\N
3209	981	54	2113	\N	70	\N	YELLOW_CARD	\N
3210	981	39	2239	\N	89	\N	YELLOW_CARD	\N
3211	983	39	2240	\N	18	\N	YELLOW_CARD	\N
3212	983	105	2181	\N	61	\N	YELLOW_CARD	\N
3213	983	105	2210	\N	92	\N	YELLOW_CARD	\N
3214	984	54	2107	\N	33	\N	YELLOW_CARD	\N
3215	984	54	2121	\N	54	\N	YELLOW_CARD	\N
3216	984	52	2047	\N	79	\N	YELLOW_CARD	\N
3217	984	52	2043	\N	80	\N	YELLOW_CARD	\N
3218	984	54	2113	\N	92	\N	YELLOW_CARD	\N
3219	984	54	2120	\N	94	\N	YELLOW_CARD	\N
3220	987	11	2269	\N	85	\N	YELLOW_CARD	\N
3221	1180	11	2336	\N	78	\N	YELLOW_CARD	\N
3222	1149	76	972	\N	29	\N	YELLOW_CARD	\N
\.


--
-- Data for Name: match_lineups; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.match_lineups (id, match_id, team_id, player_id, role, "position", shirt_number, minute_on, minute_off) FROM stdin;
1	30	88	985	STARTER	GK	\N	\N	\N
2	30	88	986	SUB	\N	\N	\N	\N
3	30	88	989	STARTER	DF	\N	\N	\N
4	30	88	991	STARTER	DF	\N	\N	\N
5	30	88	993	STARTER	DF	\N	\N	\N
6	30	88	994	SUB	\N	\N	\N	\N
7	30	88	995	STARTER	DF	\N	\N	\N
8	30	88	996	SUB	\N	\N	\N	\N
9	30	88	997	STARTER	MF	\N	\N	\N
10	30	88	998	SUB	\N	\N	\N	\N
11	30	88	999	STARTER	MF	\N	\N	\N
12	30	88	1003	STARTER	MF	\N	\N	\N
13	30	88	1004	STARTER	FW	\N	\N	\N
14	30	88	1005	SUB	\N	\N	\N	\N
15	30	88	1006	SUB	\N	\N	\N	\N
16	30	88	1007	STARTER	FW	\N	\N	\N
17	30	88	1008	STARTER	MF	\N	\N	\N
18	31	8	1226	STARTER	GK	\N	\N	\N
19	31	8	1227	STARTER	DF	\N	\N	\N
20	31	8	1228	SUB	\N	\N	\N	\N
21	31	8	1229	STARTER	DF	\N	\N	\N
22	31	8	1230	STARTER	MF	\N	\N	\N
23	31	8	1231	STARTER	DF	\N	\N	\N
24	31	8	1232	STARTER	FW	\N	\N	\N
25	31	8	1233	STARTER	MF	\N	\N	\N
26	31	8	1235	STARTER	MF	\N	\N	\N
27	31	8	1236	STARTER	FW	\N	\N	\N
28	31	8	1237	STARTER	MF	\N	\N	\N
29	31	8	1238	STARTER	MF	\N	\N	\N
30	31	8	1239	SUB	\N	\N	\N	\N
31	31	8	1240	SUB	\N	\N	\N	\N
32	31	8	1241	SUB	\N	\N	\N	\N
33	31	8	1242	SUB	\N	\N	\N	\N
34	31	8	1243	SUB	\N	\N	\N	\N
35	31	8	1244	SUB	\N	\N	\N	\N
36	32	7	1075	STARTER	GK	\N	\N	\N
37	32	7	1077	STARTER	DF	\N	\N	\N
38	32	7	1079	STARTER	DF	\N	\N	\N
39	32	7	1081	STARTER	DF	\N	\N	\N
40	32	7	1082	STARTER	DF	\N	\N	\N
41	32	7	1085	STARTER	FW	\N	\N	\N
42	32	7	1089	STARTER	MF	\N	\N	\N
43	32	7	1090	STARTER	MF	\N	\N	\N
44	32	7	1091	SUB	\N	\N	\N	\N
45	32	7	1093	STARTER	MF	\N	\N	\N
46	32	7	1096	STARTER	FW	\N	\N	\N
47	32	7	1097	SUB	\N	\N	\N	\N
48	32	7	1098	SUB	\N	\N	\N	\N
49	32	7	1099	SUB	\N	\N	\N	\N
50	32	7	1100	STARTER	FW	\N	\N	\N
51	33	76	955	STARTER	GK	\N	\N	\N
52	33	76	957	SUB	\N	\N	\N	\N
53	33	76	958	STARTER	DF	\N	\N	\N
54	33	76	959	SUB	\N	\N	\N	\N
55	33	76	960	STARTER	DF	\N	\N	\N
56	33	76	962	SUB	\N	\N	\N	\N
57	33	76	963	STARTER	DF	\N	\N	\N
58	33	76	965	SUB	\N	\N	\N	\N
59	33	76	966	STARTER	DF	\N	\N	\N
60	33	76	967	STARTER	MF	\N	\N	\N
61	33	76	970	SUB	\N	\N	\N	\N
62	33	76	972	STARTER	MF	\N	\N	\N
63	33	76	973	SUB	\N	\N	\N	\N
64	33	76	974	STARTER	MF	\N	\N	\N
65	33	76	975	SUB	\N	\N	\N	\N
66	33	76	979	STARTER	FW	\N	\N	\N
67	33	76	982	STARTER	FW	\N	\N	\N
68	33	76	983	STARTER	MF	\N	\N	\N
69	35	5	1160	STARTER	GK	\N	\N	\N
70	35	5	1161	SUB	\N	\N	\N	\N
71	35	5	1164	SUB	\N	\N	\N	\N
72	35	5	1165	STARTER	DF	\N	\N	\N
73	35	5	1166	STARTER	DF	\N	\N	\N
74	35	5	1168	STARTER	DF	\N	\N	\N
75	35	5	1169	STARTER	DF	\N	\N	\N
76	35	5	1170	STARTER	MF	\N	\N	\N
77	35	5	1172	SUB	\N	\N	\N	\N
78	35	5	1177	STARTER	MF	\N	\N	\N
79	35	5	1179	SUB	\N	\N	\N	\N
80	35	5	1180	STARTER	MF	\N	\N	\N
81	35	5	1181	SUB	\N	\N	\N	\N
82	35	5	1183	SUB	\N	\N	\N	\N
83	35	5	1184	STARTER	FW	\N	\N	\N
84	35	5	1186	STARTER	FW	\N	\N	\N
85	35	86	1190	STARTER	GK	\N	\N	\N
86	35	86	1191	STARTER	DF	\N	\N	\N
87	35	86	1192	STARTER	DF	\N	\N	\N
88	35	86	1195	STARTER	DF	\N	\N	\N
89	35	86	1196	STARTER	MF	\N	\N	\N
90	35	86	1197	STARTER	DF	\N	\N	\N
91	35	86	1203	STARTER	MF	\N	\N	\N
92	35	86	1204	SUB	\N	\N	\N	\N
93	35	86	1206	SUB	\N	\N	\N	\N
94	35	86	1207	STARTER	MF	\N	\N	\N
95	35	86	1208	SUB	\N	\N	\N	\N
96	35	86	1209	SUB	\N	\N	\N	\N
97	35	86	1210	STARTER	FW	\N	\N	\N
98	35	86	1215	STARTER	MF	\N	\N	\N
99	35	5	1222	STARTER	MF	\N	\N	\N
100	35	86	1247	STARTER	FW	\N	\N	\N
101	35	86	1248	SUB	\N	\N	\N	\N
102	35	86	1249	SUB	\N	\N	\N	\N
103	37	11	1009	STARTER	GK	\N	\N	\N
104	37	11	1010	SUB	\N	\N	\N	\N
105	37	11	1012	STARTER	DF	\N	\N	\N
106	37	11	1014	STARTER	DF	\N	\N	\N
107	37	11	1015	STARTER	DF	\N	\N	\N
108	37	11	1016	STARTER	DF	\N	\N	\N
109	37	11	1017	SUB	\N	\N	\N	\N
110	37	11	1021	SUB	\N	\N	\N	\N
111	37	11	1022	STARTER	MF	\N	\N	\N
112	37	11	1026	SUB	\N	\N	\N	\N
113	37	11	1028	STARTER	MF	\N	\N	\N
114	37	11	1029	SUB	\N	\N	\N	\N
115	37	11	1030	SUB	\N	\N	\N	\N
116	37	11	1031	STARTER	MF	\N	\N	\N
117	37	11	1032	STARTER	FW	\N	\N	\N
118	37	11	1034	SUB	\N	\N	\N	\N
119	37	11	1035	STARTER	FW	\N	\N	\N
120	37	11	1036	STARTER	MF	\N	\N	\N
121	37	17	1250	STARTER	GK	\N	\N	\N
122	37	17	1252	STARTER	DF	\N	\N	\N
123	37	17	1253	STARTER	DF	\N	\N	\N
124	37	17	1254	STARTER	DF	\N	\N	\N
125	37	17	1255	STARTER	DF	\N	\N	\N
126	37	17	1256	STARTER	MF	\N	\N	\N
127	37	17	1257	STARTER	MF	\N	\N	\N
128	37	17	1258	STARTER	MF	\N	\N	\N
129	37	17	1259	STARTER	FW	\N	\N	\N
130	37	17	1260	STARTER	FW	\N	\N	\N
131	38	76	955	STARTER	GK	\N	\N	\N
132	38	76	958	STARTER	DF	\N	\N	\N
133	38	76	960	STARTER	DF	\N	\N	\N
134	38	76	963	STARTER	DF	\N	\N	\N
135	38	76	966	STARTER	DF	\N	\N	\N
136	38	76	967	STARTER	MF	\N	\N	\N
137	38	76	968	STARTER	MF	\N	\N	\N
138	38	76	972	STARTER	MF	\N	\N	\N
139	38	76	979	STARTER	MF	\N	\N	\N
140	38	76	982	STARTER	MF	\N	\N	\N
141	38	76	983	STARTER	FW	\N	\N	\N
142	48	88	985	STARTER	GK	\N	\N	\N
143	48	88	986	SUB	\N	\N	\N	\N
144	48	88	989	STARTER	DF	\N	\N	\N
145	48	88	990	SUB	\N	\N	\N	\N
146	48	88	991	STARTER	DF	\N	\N	\N
147	48	88	993	STARTER	DF	\N	\N	\N
148	48	88	994	SUB	\N	\N	\N	\N
149	48	88	995	STARTER	DF	\N	\N	\N
150	48	88	996	STARTER	MF	\N	\N	\N
151	48	88	998	SUB	\N	\N	\N	\N
152	48	88	999	STARTER	MF	\N	\N	\N
153	48	88	1000	SUB	\N	\N	\N	\N
154	48	88	1003	STARTER	MF	\N	\N	\N
155	48	88	1004	STARTER	FW	\N	\N	\N
156	48	88	1005	SUB	\N	\N	\N	\N
157	48	88	1006	SUB	\N	\N	\N	\N
158	48	88	1007	STARTER	FW	\N	\N	\N
159	48	88	1008	STARTER	FW	\N	\N	\N
160	49	11	1009	STARTER	GK	\N	\N	\N
161	49	11	1010	SUB	\N	\N	\N	\N
162	49	11	1012	STARTER	DF	\N	\N	\N
163	49	11	1014	SUB	\N	\N	\N	\N
164	49	11	1016	SUB	\N	\N	\N	\N
165	49	11	1017	STARTER	DF	\N	\N	\N
166	49	11	1018	STARTER	DF	\N	\N	\N
167	49	11	1019	STARTER	DF	\N	\N	\N
168	49	11	1022	STARTER	MF	\N	\N	\N
169	49	11	1025	STARTER	MF	\N	\N	\N
170	49	11	1028	STARTER	MF	\N	\N	\N
171	49	11	1029	SUB	\N	\N	\N	\N
172	49	11	1031	STARTER	FW	\N	\N	\N
173	49	11	1032	STARTER	FW	\N	\N	\N
174	49	11	1034	SUB	\N	\N	\N	\N
175	49	11	1035	STARTER	FW	\N	\N	\N
176	49	11	1036	SUB	\N	\N	\N	\N
177	49	12	1278	STARTER	FW	\N	\N	\N
178	49	12	1279	STARTER	DF	\N	\N	\N
179	49	12	1280	STARTER	DF	\N	\N	\N
180	49	12	1281	STARTER	DF	\N	\N	\N
181	49	12	1282	STARTER	DF	\N	\N	\N
182	49	12	1283	STARTER	MF	\N	\N	\N
183	49	12	1284	STARTER	MF	\N	\N	\N
184	49	12	1285	STARTER	MF	\N	\N	\N
185	49	12	1286	STARTER	FW	\N	\N	\N
186	49	12	1287	STARTER	FW	\N	\N	\N
187	49	12	1288	STARTER	FW	\N	\N	\N
188	49	12	1289	SUB	\N	\N	\N	\N
189	49	12	1290	SUB	\N	\N	\N	\N
190	49	12	1291	SUB	\N	\N	\N	\N
191	49	12	1292	SUB	\N	\N	\N	\N
192	49	12	1293	SUB	\N	\N	\N	\N
193	49	12	1294	SUB	\N	\N	\N	\N
194	53	76	955	STARTER	GK	\N	\N	\N
195	53	76	956	SUB	\N	\N	\N	\N
196	53	76	958	STARTER	DF	\N	\N	\N
197	53	76	960	STARTER	DF	\N	\N	\N
198	53	76	961	SUB	\N	\N	\N	\N
199	53	76	962	SUB	\N	\N	\N	\N
200	53	76	963	STARTER	DF	\N	\N	\N
201	53	76	966	STARTER	DF	\N	\N	\N
202	53	76	967	STARTER	MF	\N	\N	\N
203	53	76	968	SUB	\N	\N	\N	\N
204	53	76	970	STARTER	MF	\N	\N	\N
205	53	76	971	STARTER	MF	\N	\N	\N
206	53	76	973	SUB	\N	\N	\N	\N
207	53	76	974	SUB	\N	\N	\N	\N
208	53	76	975	SUB	\N	\N	\N	\N
209	53	76	979	STARTER	FW	\N	\N	\N
210	53	76	982	STARTER	FW	\N	\N	\N
211	53	76	983	STARTER	FW	\N	\N	\N
212	53	7	1075	SUB	\N	\N	\N	\N
213	53	7	1076	STARTER	GK	\N	\N	\N
214	53	7	1077	STARTER	DF	\N	\N	\N
215	53	7	1078	SUB	\N	\N	\N	\N
216	53	7	1079	STARTER	DF	\N	\N	\N
217	53	7	1081	STARTER	DF	\N	\N	\N
218	53	7	1082	STARTER	DF	\N	\N	\N
219	53	7	1085	STARTER	FW	\N	\N	\N
220	53	7	1088	SUB	\N	\N	\N	\N
221	53	7	1089	STARTER	MF	\N	\N	\N
222	53	7	1091	SUB	\N	\N	\N	\N
223	53	7	1093	STARTER	MF	\N	\N	\N
224	53	7	1096	SUB	\N	\N	\N	\N
225	53	7	1097	STARTER	MF	\N	\N	\N
226	53	7	1100	STARTER	FW	\N	\N	\N
227	53	7	1159	SUB	\N	\N	\N	\N
228	56	5	1160	STARTER	GK	\N	\N	\N
229	56	5	1161	SUB	\N	\N	\N	\N
230	56	5	1164	STARTER	DF	\N	\N	\N
231	56	5	1166	STARTER	DF	\N	\N	\N
232	56	5	1168	STARTER	DF	\N	\N	\N
233	56	5	1169	STARTER	DF	\N	\N	\N
234	56	5	1170	SUB	\N	\N	\N	\N
235	56	5	1172	STARTER	MF	\N	\N	\N
236	56	5	1173	SUB	\N	\N	\N	\N
237	56	5	1174	SUB	\N	\N	\N	\N
238	56	5	1177	STARTER	MF	\N	\N	\N
239	56	5	1179	SUB	\N	\N	\N	\N
240	56	5	1180	STARTER	FW	\N	\N	\N
241	56	5	1182	SUB	\N	\N	\N	\N
242	56	5	1183	SUB	\N	\N	\N	\N
243	56	5	1184	STARTER	FW	\N	\N	\N
244	56	5	1186	STARTER	FW	\N	\N	\N
245	56	5	1222	STARTER	MF	\N	\N	\N
246	57	16	1245	STARTER	FW	\N	\N	\N
247	57	16	1262	STARTER	FW	\N	\N	\N
248	57	16	1268	STARTER	GK	\N	\N	\N
249	57	16	1269	STARTER	DF	\N	\N	\N
250	57	16	1270	STARTER	DF	\N	\N	\N
251	57	16	1271	STARTER	DF	\N	\N	\N
252	57	16	1272	STARTER	DF	\N	\N	\N
253	57	16	1273	STARTER	MF	\N	\N	\N
254	57	16	1274	STARTER	MF	\N	\N	\N
255	57	16	1275	STARTER	MF	\N	\N	\N
256	57	16	1276	SUB	\N	\N	\N	\N
257	57	16	1315	STARTER	FW	\N	\N	\N
258	57	16	1316	SUB	\N	\N	\N	\N
259	57	16	1317	SUB	\N	\N	\N	\N
260	57	16	1318	SUB	\N	\N	\N	\N
261	57	16	1319	SUB	\N	\N	\N	\N
262	57	16	1320	SUB	\N	\N	\N	\N
263	57	16	1321	SUB	\N	\N	\N	\N
264	58	15	1037	SUB	\N	\N	\N	\N
265	58	15	1039	SUB	\N	\N	\N	\N
266	58	15	1040	STARTER	DF	\N	\N	\N
267	58	15	1041	STARTER	DF	\N	\N	\N
268	58	15	1043	SUB	\N	\N	\N	\N
269	58	15	1044	STARTER	MF	\N	\N	\N
270	58	15	1045	STARTER	MF	\N	\N	\N
271	58	15	1046	STARTER	FW	\N	\N	\N
272	58	15	1047	SUB	\N	\N	\N	\N
273	58	15	1048	STARTER	FW	\N	\N	\N
274	58	15	1049	STARTER	DF	\N	\N	\N
275	58	15	1052	STARTER	MF	\N	\N	\N
276	58	15	1054	SUB	\N	\N	\N	\N
277	58	15	1218	SUB	\N	\N	\N	\N
278	58	15	1264	SUB	\N	\N	\N	\N
279	58	15	1312	STARTER	DF	\N	\N	\N
280	58	15	1313	STARTER	MF	\N	\N	\N
281	58	15	1314	STARTER	FW	\N	\N	\N
282	59	76	955	STARTER	GK	\N	\N	\N
283	59	76	956	SUB	\N	\N	\N	\N
284	59	76	958	STARTER	DF	\N	\N	\N
285	59	76	960	STARTER	DF	\N	\N	\N
286	59	76	961	SUB	\N	\N	\N	\N
287	59	76	962	SUB	\N	\N	\N	\N
288	59	76	963	STARTER	DF	\N	\N	\N
289	59	76	966	STARTER	DF	\N	\N	\N
290	59	76	967	SUB	\N	\N	\N	\N
291	59	76	969	SUB	\N	\N	\N	\N
292	59	76	970	STARTER	MF	\N	\N	\N
293	59	76	971	STARTER	MF	\N	\N	\N
294	59	76	972	STARTER	MF	\N	\N	\N
295	59	76	974	STARTER	FW	\N	\N	\N
296	59	76	975	SUB	\N	\N	\N	\N
297	59	76	981	SUB	\N	\N	\N	\N
298	59	76	982	STARTER	FW	\N	\N	\N
299	59	76	983	STARTER	MF	\N	\N	\N
300	62	11	1009	STARTER	GK	\N	\N	\N
301	62	11	1012	STARTER	DF	\N	\N	\N
302	62	11	1017	STARTER	DF	\N	\N	\N
303	62	11	1018	STARTER	DF	\N	\N	\N
304	62	11	1019	STARTER	DF	\N	\N	\N
305	62	11	1022	STARTER	MF	\N	\N	\N
306	62	11	1025	STARTER	MF	\N	\N	\N
307	62	11	1029	STARTER	MF	\N	\N	\N
308	62	11	1031	STARTER	FW	\N	\N	\N
309	62	11	1032	STARTER	FW	\N	\N	\N
310	62	11	1035	STARTER	FW	\N	\N	\N
311	62	7	1076	STARTER	GK	\N	\N	\N
312	62	7	1077	STARTER	DF	\N	\N	\N
313	62	7	1079	STARTER	DF	\N	\N	\N
314	62	7	1081	STARTER	DF	\N	\N	\N
315	62	7	1082	STARTER	DF	\N	\N	\N
316	62	7	1086	STARTER	MF	\N	\N	\N
317	62	7	1089	STARTER	MF	\N	\N	\N
318	62	7	1090	STARTER	MF	\N	\N	\N
319	62	7	1093	STARTER	MF	\N	\N	\N
320	62	7	1097	STARTER	FW	\N	\N	\N
321	62	7	1100	STARTER	MF	\N	\N	\N
322	65	1	1056	STARTER	DF	\N	\N	\N
323	65	1	1057	STARTER	DF	\N	\N	\N
324	65	1	1058	STARTER	GK	\N	\N	\N
325	65	1	1059	STARTER	DF	\N	\N	\N
326	65	1	1060	STARTER	DF	\N	\N	\N
327	65	1	1061	STARTER	FW	\N	\N	\N
328	65	1	1064	STARTER	MF	\N	\N	\N
329	65	1	1065	STARTER	FW	\N	\N	\N
330	65	1	1068	STARTER	MF	\N	\N	\N
331	66	87	1129	STARTER	GK	\N	\N	\N
332	66	87	1131	SUB	\N	\N	\N	\N
333	66	87	1132	STARTER	DF	\N	\N	\N
334	66	87	1133	STARTER	DF	\N	\N	\N
335	66	87	1135	SUB	\N	\N	\N	\N
336	66	87	1136	STARTER	MF	\N	\N	\N
337	66	87	1137	SUB	\N	\N	\N	\N
338	66	87	1139	STARTER	FW	\N	\N	\N
339	66	87	1140	STARTER	MF	\N	\N	\N
340	66	87	1141	STARTER	FW	\N	\N	\N
341	66	87	1143	STARTER	DF	\N	\N	\N
342	66	87	1144	STARTER	DF	\N	\N	\N
343	66	87	1148	SUB	\N	\N	\N	\N
344	66	87	1151	STARTER	MF	\N	\N	\N
345	66	87	1153	SUB	\N	\N	\N	\N
346	66	87	1155	STARTER	MF	\N	\N	\N
347	66	87	1156	SUB	\N	\N	\N	\N
348	66	87	1157	SUB	\N	\N	\N	\N
349	67	5	1160	STARTER	GK	\N	\N	\N
350	67	5	1161	SUB	\N	\N	\N	\N
351	67	5	1163	SUB	\N	\N	\N	\N
352	67	5	1166	STARTER	DF	\N	\N	\N
353	67	5	1168	STARTER	DF	\N	\N	\N
354	67	5	1169	STARTER	DF	\N	\N	\N
355	67	5	1170	STARTER	DF	\N	\N	\N
356	67	5	1172	STARTER	MF	\N	\N	\N
357	67	5	1173	SUB	\N	\N	\N	\N
358	67	5	1174	SUB	\N	\N	\N	\N
359	67	5	1177	STARTER	MF	\N	\N	\N
360	67	5	1179	SUB	\N	\N	\N	\N
361	67	5	1180	STARTER	FW	\N	\N	\N
362	67	5	1181	SUB	\N	\N	\N	\N
363	67	5	1182	SUB	\N	\N	\N	\N
364	67	5	1184	STARTER	MF	\N	\N	\N
365	67	5	1186	STARTER	FW	\N	\N	\N
366	67	5	1222	STARTER	FW	\N	\N	\N
367	68	88	985	STARTER	GK	\N	\N	\N
368	68	88	986	SUB	\N	\N	\N	\N
369	68	88	989	STARTER	DF	\N	\N	\N
370	68	88	990	SUB	\N	\N	\N	\N
371	68	88	991	STARTER	DF	\N	\N	\N
372	68	88	993	STARTER	DF	\N	\N	\N
373	68	88	994	SUB	\N	\N	\N	\N
374	68	88	995	STARTER	DF	\N	\N	\N
375	68	88	996	SUB	\N	\N	\N	\N
376	68	88	997	STARTER	MF	\N	\N	\N
377	68	88	998	SUB	\N	\N	\N	\N
378	68	88	999	STARTER	MF	\N	\N	\N
379	68	88	1000	SUB	\N	\N	\N	\N
380	68	88	1003	STARTER	MF	\N	\N	\N
381	68	88	1004	STARTER	FW	\N	\N	\N
382	68	88	1005	STARTER	FW	\N	\N	\N
383	68	88	1006	STARTER	MF	\N	\N	\N
384	68	88	1007	SUB	\N	\N	\N	\N
385	68	8	1226	STARTER	GK	\N	\N	\N
386	68	8	1227	STARTER	DF	\N	\N	\N
387	68	8	1229	STARTER	DF	\N	\N	\N
388	68	8	1230	SUB	\N	\N	\N	\N
389	68	8	1231	STARTER	MF	\N	\N	\N
390	68	8	1232	STARTER	MF	\N	\N	\N
391	68	8	1234	STARTER	MF	\N	\N	\N
392	68	8	1235	STARTER	MF	\N	\N	\N
393	68	8	1236	STARTER	FW	\N	\N	\N
394	68	8	1237	STARTER	DF	\N	\N	\N
395	68	8	1238	SUB	\N	\N	\N	\N
396	68	8	1239	SUB	\N	\N	\N	\N
397	68	8	1240	SUB	\N	\N	\N	\N
398	68	8	1241	SUB	\N	\N	\N	\N
399	68	8	1322	STARTER	DF	\N	\N	\N
400	69	11	1009	STARTER	GK	\N	\N	\N
401	69	11	1010	SUB	\N	\N	\N	\N
402	69	11	1013	STARTER	DF	\N	\N	\N
403	69	11	1014	STARTER	DF	\N	\N	\N
404	69	11	1016	STARTER	DF	\N	\N	\N
405	69	11	1017	SUB	\N	\N	\N	\N
406	69	11	1018	STARTER	DF	\N	\N	\N
407	69	11	1019	SUB	\N	\N	\N	\N
408	69	11	1022	SUB	\N	\N	\N	\N
409	69	11	1023	SUB	\N	\N	\N	\N
410	69	11	1025	STARTER	MF	\N	\N	\N
411	69	11	1026	SUB	\N	\N	\N	\N
412	69	11	1028	STARTER	MF	\N	\N	\N
413	69	11	1029	STARTER	MF	\N	\N	\N
414	69	11	1031	STARTER	FW	\N	\N	\N
415	69	11	1032	STARTER	FW	\N	\N	\N
416	69	11	1034	STARTER	FW	\N	\N	\N
417	69	11	1036	SUB	\N	\N	\N	\N
418	69	86	1188	STARTER	GK	\N	\N	\N
419	69	86	1191	STARTER	DF	\N	\N	\N
420	69	86	1192	STARTER	DF	\N	\N	\N
421	69	86	1196	STARTER	DF	\N	\N	\N
422	69	86	1197	STARTER	DF	\N	\N	\N
423	69	86	1201	SUB	\N	\N	\N	\N
424	69	86	1202	SUB	\N	\N	\N	\N
425	69	86	1203	STARTER	MF	\N	\N	\N
426	69	86	1204	STARTER	DF	\N	\N	\N
427	69	86	1205	STARTER	MF	\N	\N	\N
428	69	86	1206	STARTER	FW	\N	\N	\N
429	69	86	1208	STARTER	MF	\N	\N	\N
430	69	86	1209	SUB	\N	\N	\N	\N
431	69	86	1210	STARTER	FW	\N	\N	\N
432	69	86	1211	SUB	\N	\N	\N	\N
433	69	86	1215	SUB	\N	\N	\N	\N
434	69	86	1248	SUB	\N	\N	\N	\N
435	70	7	1075	SUB	\N	\N	\N	\N
436	70	7	1076	STARTER	GK	\N	\N	\N
437	70	7	1078	STARTER	DF	\N	\N	\N
438	70	7	1079	STARTER	DF	\N	\N	\N
439	70	7	1080	SUB	\N	\N	\N	\N
440	70	7	1081	STARTER	DF	\N	\N	\N
441	70	7	1082	STARTER	DF	\N	\N	\N
442	70	7	1085	SUB	\N	\N	\N	\N
443	70	7	1086	SUB	\N	\N	\N	\N
444	70	7	1088	SUB	\N	\N	\N	\N
445	70	7	1089	STARTER	MF	\N	\N	\N
446	70	7	1090	STARTER	MF	\N	\N	\N
447	70	7	1091	SUB	\N	\N	\N	\N
448	70	7	1093	STARTER	MF	\N	\N	\N
449	70	7	1096	SUB	\N	\N	\N	\N
450	70	7	1097	STARTER	FW	\N	\N	\N
451	70	7	1099	STARTER	FW	\N	\N	\N
452	70	7	1100	STARTER	FW	\N	\N	\N
453	71	76	955	STARTER	GK	\N	\N	\N
454	71	76	956	SUB	\N	\N	\N	\N
455	71	76	959	STARTER	DF	\N	\N	\N
456	71	76	960	STARTER	DF	\N	\N	\N
457	71	76	961	STARTER	DF	\N	\N	\N
458	71	76	962	SUB	\N	\N	\N	\N
459	71	76	964	STARTER	MF	\N	\N	\N
460	71	76	965	SUB	\N	\N	\N	\N
461	71	76	966	STARTER	DF	\N	\N	\N
462	71	76	970	SUB	\N	\N	\N	\N
463	71	76	971	STARTER	MF	\N	\N	\N
464	71	76	972	STARTER	MF	\N	\N	\N
465	71	76	974	STARTER	FW	\N	\N	\N
466	71	76	975	SUB	\N	\N	\N	\N
467	71	76	977	SUB	\N	\N	\N	\N
468	71	76	978	SUB	\N	\N	\N	\N
469	71	76	982	STARTER	FW	\N	\N	\N
470	71	76	983	STARTER	MF	\N	\N	\N
471	71	12	1278	STARTER	GK	\N	\N	\N
472	71	12	1279	STARTER	DF	\N	\N	\N
473	71	12	1280	STARTER	DF	\N	\N	\N
474	71	12	1281	STARTER	DF	\N	\N	\N
475	71	12	1282	SUB	\N	\N	\N	\N
476	71	12	1283	STARTER	MF	\N	\N	\N
477	71	12	1284	STARTER	FW	\N	\N	\N
478	71	12	1286	STARTER	MF	\N	\N	\N
479	71	12	1287	STARTER	FW	\N	\N	\N
480	71	12	1288	STARTER	MF	\N	\N	\N
481	71	12	1289	SUB	\N	\N	\N	\N
482	71	12	1290	SUB	\N	\N	\N	\N
483	71	12	1291	STARTER	MF	\N	\N	\N
484	71	12	1294	SUB	\N	\N	\N	\N
485	71	12	1325	STARTER	DF	\N	\N	\N
486	71	12	1326	SUB	\N	\N	\N	\N
487	71	12	1327	SUB	\N	\N	\N	\N
488	71	12	1328	SUB	\N	\N	\N	\N
489	73	76	955	STARTER	GK	\N	\N	\N
490	73	76	956	SUB	\N	\N	\N	\N
491	73	76	958	STARTER	DF	\N	\N	\N
492	73	76	959	SUB	\N	\N	\N	\N
493	73	76	960	STARTER	DF	\N	\N	\N
494	73	76	961	SUB	\N	\N	\N	\N
495	73	76	962	SUB	\N	\N	\N	\N
496	73	76	963	STARTER	DF	\N	\N	\N
497	73	76	964	SUB	\N	\N	\N	\N
498	73	76	966	STARTER	DF	\N	\N	\N
499	73	76	967	STARTER	MF	\N	\N	\N
500	73	76	971	STARTER	MF	\N	\N	\N
501	73	76	972	STARTER	MF	\N	\N	\N
502	73	76	974	STARTER	MF	\N	\N	\N
503	73	76	975	SUB	\N	\N	\N	\N
504	73	76	977	SUB	\N	\N	\N	\N
505	73	76	982	STARTER	FW	\N	\N	\N
506	73	76	983	STARTER	FW	\N	\N	\N
507	73	11	1009	STARTER	GK	\N	\N	\N
508	73	11	1010	SUB	\N	\N	\N	\N
509	73	11	1014	STARTER	DF	\N	\N	\N
510	73	11	1016	STARTER	DF	\N	\N	\N
511	73	11	1017	STARTER	DF	\N	\N	\N
512	73	11	1018	STARTER	DF	\N	\N	\N
513	73	11	1019	SUB	\N	\N	\N	\N
514	73	11	1022	STARTER	MF	\N	\N	\N
515	73	11	1025	STARTER	MF	\N	\N	\N
516	73	11	1026	SUB	\N	\N	\N	\N
517	73	11	1028	STARTER	FW	\N	\N	\N
518	73	11	1029	SUB	\N	\N	\N	\N
519	73	11	1030	SUB	\N	\N	\N	\N
520	73	11	1031	STARTER	MF	\N	\N	\N
521	73	11	1032	STARTER	FW	\N	\N	\N
522	73	11	1034	STARTER	FW	\N	\N	\N
523	73	11	1035	SUB	\N	\N	\N	\N
524	73	11	1036	SUB	\N	\N	\N	\N
525	75	87	1129	STARTER	GK	\N	\N	\N
526	75	87	1130	STARTER	DF	\N	\N	\N
527	75	87	1132	STARTER	DF	\N	\N	\N
528	75	87	1133	STARTER	DF	\N	\N	\N
529	75	87	1136	STARTER	MF	\N	\N	\N
530	75	87	1137	SUB	\N	\N	\N	\N
531	75	87	1139	STARTER	FW	\N	\N	\N
532	75	87	1140	STARTER	MF	\N	\N	\N
533	75	87	1141	STARTER	FW	\N	\N	\N
534	75	87	1142	SUB	\N	\N	\N	\N
535	75	87	1144	STARTER	DF	\N	\N	\N
536	75	87	1146	SUB	\N	\N	\N	\N
537	75	87	1147	SUB	\N	\N	\N	\N
538	75	87	1148	SUB	\N	\N	\N	\N
539	75	87	1150	SUB	\N	\N	\N	\N
540	75	87	1151	STARTER	FW	\N	\N	\N
541	75	87	1155	STARTER	MF	\N	\N	\N
542	75	87	1156	SUB	\N	\N	\N	\N
543	76	88	985	STARTER	GK	\N	\N	\N
544	76	88	989	STARTER	DF	\N	\N	\N
545	76	88	991	STARTER	DF	\N	\N	\N
546	76	88	992	STARTER	FW	\N	\N	\N
547	76	88	993	STARTER	DF	\N	\N	\N
548	76	88	995	STARTER	DF	\N	\N	\N
549	76	88	997	STARTER	MF	\N	\N	\N
550	76	88	999	STARTER	MF	\N	\N	\N
551	76	88	1003	STARTER	MF	\N	\N	\N
552	76	88	1006	STARTER	FW	\N	\N	\N
553	76	88	1007	STARTER	FW	\N	\N	\N
554	76	7	1076	STARTER	GK	\N	\N	\N
555	76	7	1078	STARTER	DF	\N	\N	\N
556	76	7	1079	STARTER	DF	\N	\N	\N
557	76	7	1081	STARTER	DF	\N	\N	\N
558	76	7	1082	STARTER	DF	\N	\N	\N
559	76	7	1090	STARTER	MF	\N	\N	\N
560	76	7	1093	STARTER	MF	\N	\N	\N
561	76	7	1096	STARTER	FW	\N	\N	\N
562	76	7	1097	STARTER	FW	\N	\N	\N
563	76	7	1099	STARTER	FW	\N	\N	\N
564	76	7	1100	STARTER	MF	\N	\N	\N
565	78	16	1245	STARTER	FW	\N	\N	\N
566	78	16	1262	STARTER	FW	\N	\N	\N
567	78	16	1268	STARTER	GK	\N	\N	\N
568	78	16	1269	STARTER	DF	\N	\N	\N
569	78	16	1270	STARTER	DF	\N	\N	\N
570	78	16	1272	STARTER	DF	\N	\N	\N
571	78	16	1273	STARTER	MF	\N	\N	\N
572	78	16	1274	STARTER	MF	\N	\N	\N
573	78	16	1318	STARTER	DF	\N	\N	\N
574	78	16	1320	STARTER	FW	\N	\N	\N
575	78	16	1321	STARTER	MF	\N	\N	\N
576	81	76	955	STARTER	GK	\N	\N	\N
577	81	76	957	SUB	\N	\N	\N	\N
578	81	76	959	STARTER	DF	\N	\N	\N
579	81	76	960	STARTER	DF	\N	\N	\N
580	81	76	961	SUB	\N	\N	\N	\N
581	81	76	962	SUB	\N	\N	\N	\N
582	81	76	963	STARTER	DF	\N	\N	\N
583	81	76	964	STARTER	MF	\N	\N	\N
584	81	76	966	STARTER	DF	\N	\N	\N
585	81	76	967	SUB	\N	\N	\N	\N
586	81	76	971	STARTER	MF	\N	\N	\N
587	81	76	972	STARTER	MF	\N	\N	\N
588	81	76	974	STARTER	FW	\N	\N	\N
589	81	76	975	SUB	\N	\N	\N	\N
590	81	76	981	SUB	\N	\N	\N	\N
591	81	76	982	STARTER	FW	\N	\N	\N
592	81	76	983	STARTER	FW	\N	\N	\N
593	81	88	985	STARTER	GK	\N	\N	\N
594	81	88	986	SUB	\N	\N	\N	\N
595	81	88	989	STARTER	DF	\N	\N	\N
596	81	88	990	SUB	\N	\N	\N	\N
597	81	88	991	STARTER	DF	\N	\N	\N
598	81	88	992	SUB	\N	\N	\N	\N
599	81	88	993	STARTER	DF	\N	\N	\N
600	81	88	995	STARTER	DF	\N	\N	\N
601	81	88	996	STARTER	FW	\N	\N	\N
602	81	88	997	STARTER	MF	\N	\N	\N
603	81	88	998	SUB	\N	\N	\N	\N
604	81	88	999	STARTER	MF	\N	\N	\N
605	81	88	1003	STARTER	MF	\N	\N	\N
606	81	88	1004	STARTER	FW	\N	\N	\N
607	81	88	1005	SUB	\N	\N	\N	\N
608	81	88	1006	SUB	\N	\N	\N	\N
609	81	88	1007	STARTER	FW	\N	\N	\N
610	81	88	1008	SUB	\N	\N	\N	\N
611	83	86	1191	STARTER	DF	\N	\N	\N
612	83	86	1192	STARTER	MF	\N	\N	\N
613	83	86	1196	STARTER	DF	\N	\N	\N
614	83	86	1201	STARTER	DF	\N	\N	\N
615	83	86	1203	STARTER	MF	\N	\N	\N
616	83	86	1204	STARTER	DF	\N	\N	\N
617	83	86	1209	STARTER	FW	\N	\N	\N
618	83	86	1210	STARTER	FW	\N	\N	\N
619	83	86	1211	STARTER	FW	\N	\N	\N
620	83	86	1248	STARTER	GK	\N	\N	\N
621	84	15	1037	STARTER	GK	\N	\N	\N
622	84	15	1041	STARTER	DF	\N	\N	\N
623	84	15	1042	STARTER	MF	\N	\N	\N
624	84	15	1044	STARTER	MF	\N	\N	\N
625	84	15	1045	STARTER	FW	\N	\N	\N
626	84	15	1049	STARTER	DF	\N	\N	\N
627	84	15	1050	STARTER	DF	\N	\N	\N
628	84	15	1051	STARTER	DF	\N	\N	\N
629	84	15	1052	STARTER	MF	\N	\N	\N
630	84	1	1055	STARTER	GK	\N	\N	\N
631	84	1	1056	STARTER	DF	\N	\N	\N
632	84	1	1057	STARTER	DF	\N	\N	\N
633	84	1	1058	STARTER	DF	\N	\N	\N
634	84	1	1059	STARTER	DF	\N	\N	\N
635	84	1	1060	STARTER	MF	\N	\N	\N
636	84	1	1061	STARTER	FW	\N	\N	\N
637	84	1	1064	STARTER	MF	\N	\N	\N
638	84	1	1065	STARTER	FW	\N	\N	\N
639	84	1	1068	STARTER	FW	\N	\N	\N
640	84	15	1217	STARTER	FW	\N	\N	\N
641	84	15	1314	STARTER	FW	\N	\N	\N
642	84	1	1329	STARTER	MF	\N	\N	\N
643	85	7	1076	STARTER	GK	\N	\N	\N
644	85	7	1078	STARTER	DF	\N	\N	\N
645	85	7	1079	STARTER	DF	\N	\N	\N
646	85	7	1081	STARTER	DF	\N	\N	\N
647	85	7	1082	STARTER	DF	\N	\N	\N
648	85	7	1085	STARTER	FW	\N	\N	\N
649	85	7	1089	STARTER	MF	\N	\N	\N
650	85	7	1090	STARTER	MF	\N	\N	\N
651	85	7	1093	STARTER	FW	\N	\N	\N
652	85	7	1097	STARTER	MF	\N	\N	\N
653	85	7	1098	STARTER	FW	\N	\N	\N
654	85	8	1226	STARTER	GK	\N	\N	\N
655	85	8	1227	STARTER	DF	\N	\N	\N
656	85	8	1229	STARTER	DF	\N	\N	\N
657	85	8	1231	STARTER	MF	\N	\N	\N
658	85	8	1232	STARTER	MF	\N	\N	\N
659	85	8	1233	STARTER	FW	\N	\N	\N
660	85	8	1235	STARTER	MF	\N	\N	\N
661	85	8	1244	STARTER	MF	\N	\N	\N
662	85	8	1322	STARTER	DF	\N	\N	\N
663	85	8	1323	STARTER	DF	\N	\N	\N
664	85	8	1324	STARTER	FW	\N	\N	\N
665	87	11	1009	STARTER	GK	\N	\N	\N
666	87	11	1010	SUB	\N	\N	\N	\N
667	87	11	1011	SUB	\N	\N	\N	\N
668	87	11	1014	STARTER	DF	\N	\N	\N
669	87	11	1016	STARTER	DF	\N	\N	\N
670	87	11	1017	SUB	\N	\N	\N	\N
671	87	11	1018	STARTER	DF	\N	\N	\N
672	87	11	1019	SUB	\N	\N	\N	\N
673	87	11	1022	STARTER	DF	\N	\N	\N
674	87	11	1023	SUB	\N	\N	\N	\N
675	87	11	1025	STARTER	MF	\N	\N	\N
676	87	11	1028	STARTER	MF	\N	\N	\N
677	87	11	1029	STARTER	MF	\N	\N	\N
678	87	11	1031	STARTER	FW	\N	\N	\N
679	87	11	1032	STARTER	FW	\N	\N	\N
680	87	11	1034	SUB	\N	\N	\N	\N
681	87	11	1035	STARTER	FW	\N	\N	\N
682	87	11	1036	SUB	\N	\N	\N	\N
683	87	5	1161	STARTER	GK	\N	\N	\N
684	87	5	1166	STARTER	DF	\N	\N	\N
685	87	5	1168	STARTER	DF	\N	\N	\N
686	87	5	1169	STARTER	DF	\N	\N	\N
687	87	5	1170	STARTER	DF	\N	\N	\N
688	87	5	1172	STARTER	MF	\N	\N	\N
689	87	5	1173	SUB	\N	\N	\N	\N
690	87	5	1174	SUB	\N	\N	\N	\N
691	87	5	1177	STARTER	MF	\N	\N	\N
692	87	5	1179	SUB	\N	\N	\N	\N
693	87	5	1182	STARTER	FW	\N	\N	\N
694	87	5	1183	SUB	\N	\N	\N	\N
695	87	5	1184	STARTER	MF	\N	\N	\N
696	87	5	1185	SUB	\N	\N	\N	\N
697	87	5	1186	STARTER	FW	\N	\N	\N
698	87	5	1222	STARTER	FW	\N	\N	\N
699	89	11	1009	STARTER	GK	\N	\N	\N
700	89	11	1010	SUB	\N	\N	\N	\N
701	89	11	1013	STARTER	DF	\N	\N	\N
702	89	11	1016	STARTER	DF	\N	\N	\N
703	89	11	1018	STARTER	DF	\N	\N	\N
704	89	11	1019	SUB	\N	\N	\N	\N
705	89	11	1022	STARTER	DF	\N	\N	\N
706	89	11	1023	SUB	\N	\N	\N	\N
707	89	11	1025	STARTER	FW	\N	\N	\N
708	89	11	1027	SUB	\N	\N	\N	\N
709	89	11	1028	STARTER	MF	\N	\N	\N
710	89	11	1029	STARTER	MF	\N	\N	\N
711	89	11	1030	STARTER	FW	\N	\N	\N
712	89	11	1031	STARTER	MF	\N	\N	\N
713	89	11	1033	SUB	\N	\N	\N	\N
714	89	11	1034	SUB	\N	\N	\N	\N
715	89	11	1035	STARTER	FW	\N	\N	\N
716	89	11	1036	SUB	\N	\N	\N	\N
717	89	13	1223	STARTER	MF	\N	\N	\N
718	89	13	1224	STARTER	DF	\N	\N	\N
719	89	13	1261	STARTER	FW	\N	\N	\N
720	89	13	1263	STARTER	FW	\N	\N	\N
721	89	13	1332	STARTER	GK	\N	\N	\N
722	89	13	1333	STARTER	DF	\N	\N	\N
723	89	13	1334	STARTER	DF	\N	\N	\N
724	89	13	1335	STARTER	MF	\N	\N	\N
725	89	13	1336	STARTER	MF	\N	\N	\N
726	89	13	1337	STARTER	FW	\N	\N	\N
727	89	13	1338	STARTER	DF	\N	\N	\N
728	89	13	1339	SUB	\N	\N	\N	\N
729	89	13	1340	SUB	\N	\N	\N	\N
730	89	13	1341	SUB	\N	\N	\N	\N
731	89	13	1342	SUB	\N	\N	\N	\N
732	89	13	1343	SUB	\N	\N	\N	\N
733	89	13	1344	SUB	\N	\N	\N	\N
734	89	13	1345	SUB	\N	\N	\N	\N
735	95	76	955	STARTER	GK	\N	\N	\N
736	95	76	958	STARTER	DF	\N	\N	\N
737	95	76	960	STARTER	DF	\N	\N	\N
738	95	76	961	STARTER	DF	\N	\N	\N
739	95	76	964	STARTER	DF	\N	\N	\N
740	95	76	966	STARTER	DF	\N	\N	\N
741	95	76	967	STARTER	MF	\N	\N	\N
742	95	76	971	STARTER	MF	\N	\N	\N
743	95	76	975	STARTER	FW	\N	\N	\N
744	95	76	982	STARTER	FW	\N	\N	\N
745	95	76	983	STARTER	MF	\N	\N	\N
746	95	5	1161	STARTER	GK	\N	\N	\N
747	95	5	1166	STARTER	DF	\N	\N	\N
748	95	5	1168	STARTER	DF	\N	\N	\N
749	95	5	1170	STARTER	DF	\N	\N	\N
750	95	5	1172	STARTER	MF	\N	\N	\N
751	95	5	1177	STARTER	MF	\N	\N	\N
752	95	5	1178	STARTER	DF	\N	\N	\N
753	95	5	1180	STARTER	FW	\N	\N	\N
754	95	5	1182	STARTER	FW	\N	\N	\N
755	95	5	1184	STARTER	MF	\N	\N	\N
756	95	5	1222	STARTER	FW	\N	\N	\N
757	97	88	984	SUB	\N	\N	\N	\N
758	97	88	985	STARTER	GK	\N	\N	\N
759	97	88	988	STARTER	DF	\N	\N	\N
760	97	88	989	STARTER	DF	\N	\N	\N
761	97	88	990	SUB	\N	\N	\N	\N
762	97	88	991	STARTER	DF	\N	\N	\N
763	97	88	992	SUB	\N	\N	\N	\N
764	97	88	993	STARTER	DF	\N	\N	\N
765	97	88	994	SUB	\N	\N	\N	\N
766	97	88	995	SUB	\N	\N	\N	\N
767	97	88	997	STARTER	MF	\N	\N	\N
768	97	88	998	STARTER	MF	\N	\N	\N
769	97	88	1000	SUB	\N	\N	\N	\N
770	97	88	1001	STARTER	MF	\N	\N	\N
771	97	88	1004	STARTER	FW	\N	\N	\N
772	97	88	1005	STARTER	FW	\N	\N	\N
773	97	88	1007	STARTER	FW	\N	\N	\N
774	97	5	1161	STARTER	GK	\N	\N	\N
775	97	5	1166	STARTER	DF	\N	\N	\N
776	97	5	1168	SUB	\N	\N	\N	\N
777	97	5	1169	STARTER	DF	\N	\N	\N
778	97	5	1171	STARTER	DF	\N	\N	\N
779	97	5	1172	STARTER	MF	\N	\N	\N
780	97	5	1174	SUB	\N	\N	\N	\N
781	97	5	1175	SUB	\N	\N	\N	\N
782	97	5	1177	STARTER	MF	\N	\N	\N
783	97	5	1178	STARTER	DF	\N	\N	\N
784	97	5	1179	STARTER	MF	\N	\N	\N
785	97	5	1180	STARTER	FW	\N	\N	\N
786	97	5	1182	STARTER	FW	\N	\N	\N
787	97	5	1183	SUB	\N	\N	\N	\N
788	97	5	1186	SUB	\N	\N	\N	\N
789	97	5	1222	STARTER	FW	\N	\N	\N
790	98	76	955	STARTER	GK	\N	\N	\N
791	98	76	956	SUB	\N	\N	\N	\N
792	98	76	958	STARTER	DF	\N	\N	\N
793	98	76	959	SUB	\N	\N	\N	\N
794	98	76	960	STARTER	DF	\N	\N	\N
795	98	76	961	STARTER	DF	\N	\N	\N
796	98	76	964	STARTER	MF	\N	\N	\N
797	98	76	966	STARTER	DF	\N	\N	\N
798	98	76	967	STARTER	MF	\N	\N	\N
799	98	76	969	SUB	\N	\N	\N	\N
800	98	76	971	STARTER	MF	\N	\N	\N
801	98	76	974	SUB	\N	\N	\N	\N
802	98	76	975	STARTER	FW	\N	\N	\N
803	98	76	977	SUB	\N	\N	\N	\N
804	98	76	978	SUB	\N	\N	\N	\N
805	98	76	982	STARTER	FW	\N	\N	\N
806	98	76	983	STARTER	FW	\N	\N	\N
807	101	15	1037	SUB	\N	\N	\N	\N
808	101	15	1040	SUB	\N	\N	\N	\N
809	101	15	1041	STARTER	DF	\N	\N	\N
810	101	15	1042	STARTER	MF	\N	\N	\N
811	101	15	1043	SUB	\N	\N	\N	\N
812	101	15	1044	STARTER	MF	\N	\N	\N
813	101	15	1045	SUB	\N	\N	\N	\N
814	101	15	1046	STARTER	MF	\N	\N	\N
815	101	15	1047	STARTER	FW	\N	\N	\N
816	101	15	1048	STARTER	GK	\N	\N	\N
817	101	15	1050	STARTER	DF	\N	\N	\N
818	101	15	1051	STARTER	DF	\N	\N	\N
819	101	15	1053	SUB	\N	\N	\N	\N
820	101	15	1217	STARTER	FW	\N	\N	\N
821	101	15	1218	SUB	\N	\N	\N	\N
822	101	15	1265	STARTER	DF	\N	\N	\N
823	101	15	1313	SUB	\N	\N	\N	\N
824	101	15	1314	STARTER	FW	\N	\N	\N
825	102	11	1009	STARTER	GK	\N	\N	\N
826	102	11	1010	SUB	\N	\N	\N	\N
827	102	11	1013	STARTER	DF	\N	\N	\N
828	102	11	1016	STARTER	DF	\N	\N	\N
829	102	11	1017	SUB	\N	\N	\N	\N
830	102	11	1018	STARTER	DF	\N	\N	\N
831	102	11	1019	SUB	\N	\N	\N	\N
832	102	11	1021	SUB	\N	\N	\N	\N
833	102	11	1022	STARTER	DF	\N	\N	\N
834	102	11	1025	STARTER	FW	\N	\N	\N
835	102	11	1028	STARTER	MF	\N	\N	\N
836	102	11	1029	STARTER	MF	\N	\N	\N
837	102	11	1030	STARTER	FW	\N	\N	\N
838	102	11	1031	STARTER	MF	\N	\N	\N
839	102	11	1033	SUB	\N	\N	\N	\N
840	102	11	1034	SUB	\N	\N	\N	\N
841	102	11	1035	STARTER	FW	\N	\N	\N
842	102	11	1036	SUB	\N	\N	\N	\N
843	102	87	1129	STARTER	DF	\N	\N	\N
844	102	87	1131	SUB	\N	\N	\N	\N
845	102	87	1132	STARTER	DF	\N	\N	\N
846	102	87	1133	STARTER	GK	\N	\N	\N
847	102	87	1135	SUB	\N	\N	\N	\N
848	102	87	1136	STARTER	MF	\N	\N	\N
849	102	87	1137	STARTER	FW	\N	\N	\N
850	102	87	1138	STARTER	FW	\N	\N	\N
851	102	87	1139	STARTER	FW	\N	\N	\N
852	102	87	1140	STARTER	MF	\N	\N	\N
853	102	87	1143	STARTER	DF	\N	\N	\N
854	102	87	1144	STARTER	DF	\N	\N	\N
855	102	87	1146	SUB	\N	\N	\N	\N
856	102	87	1150	STARTER	MF	\N	\N	\N
857	102	87	1151	SUB	\N	\N	\N	\N
858	102	87	1156	SUB	\N	\N	\N	\N
859	102	87	1157	SUB	\N	\N	\N	\N
860	104	1	1055	STARTER	GK	\N	\N	\N
861	104	1	1056	STARTER	DF	\N	\N	\N
862	104	1	1057	STARTER	DF	\N	\N	\N
863	104	1	1058	STARTER	DF	\N	\N	\N
864	104	1	1059	STARTER	DF	\N	\N	\N
865	104	1	1060	STARTER	MF	\N	\N	\N
866	104	1	1061	STARTER	MF	\N	\N	\N
867	104	1	1062	STARTER	FW	\N	\N	\N
868	104	1	1063	STARTER	FW	\N	\N	\N
869	104	1	1064	STARTER	FW	\N	\N	\N
870	104	1	1065	STARTER	FW	\N	\N	\N
871	104	12	1278	STARTER	GK	\N	\N	\N
872	104	12	1280	STARTER	DF	\N	\N	\N
873	104	12	1282	STARTER	FW	\N	\N	\N
874	104	12	1325	STARTER	DF	\N	\N	\N
875	104	12	1326	STARTER	MF	\N	\N	\N
876	104	12	1328	STARTER	DF	\N	\N	\N
877	104	12	1365	STARTER	MF	\N	\N	\N
878	104	12	1366	STARTER	MF	\N	\N	\N
879	104	12	1367	STARTER	FW	\N	\N	\N
880	109	11	1009	STARTER	GK	\N	\N	\N
881	109	11	1010	SUB	\N	\N	\N	\N
882	109	11	1013	SUB	\N	\N	\N	\N
883	109	11	1014	STARTER	DF	\N	\N	\N
884	109	11	1016	SUB	\N	\N	\N	\N
885	109	11	1018	STARTER	DF	\N	\N	\N
886	109	11	1020	STARTER	DF	\N	\N	\N
887	109	11	1021	SUB	\N	\N	\N	\N
888	109	11	1022	STARTER	DF	\N	\N	\N
889	109	11	1023	STARTER	FW	\N	\N	\N
890	109	11	1026	SUB	\N	\N	\N	\N
891	109	11	1028	STARTER	MF	\N	\N	\N
892	109	11	1029	STARTER	MF	\N	\N	\N
893	109	11	1031	STARTER	MF	\N	\N	\N
894	109	11	1033	STARTER	FW	\N	\N	\N
895	109	11	1035	STARTER	FW	\N	\N	\N
896	109	8	1184	STARTER	FW	\N	\N	\N
897	109	8	1226	STARTER	GK	\N	\N	\N
898	109	8	1227	STARTER	DF	\N	\N	\N
899	109	8	1229	STARTER	DF	\N	\N	\N
900	109	8	1231	STARTER	MF	\N	\N	\N
901	109	8	1232	STARTER	MF	\N	\N	\N
902	109	8	1233	STARTER	FW	\N	\N	\N
903	109	8	1235	STARTER	MF	\N	\N	\N
904	109	8	1237	SUB	\N	\N	\N	\N
905	109	8	1239	SUB	\N	\N	\N	\N
906	109	8	1241	SUB	\N	\N	\N	\N
907	109	8	1322	STARTER	DF	\N	\N	\N
908	109	8	1323	STARTER	DF	\N	\N	\N
909	109	8	1324	STARTER	MF	\N	\N	\N
910	110	76	955	STARTER	GK	\N	\N	\N
911	110	76	957	SUB	\N	\N	\N	\N
912	110	76	958	STARTER	DF	\N	\N	\N
913	110	76	959	SUB	\N	\N	\N	\N
914	110	76	960	STARTER	DF	\N	\N	\N
915	110	76	961	SUB	\N	\N	\N	\N
916	110	76	962	SUB	\N	\N	\N	\N
917	110	76	964	STARTER	MF	\N	\N	\N
918	110	76	965	STARTER	DF	\N	\N	\N
919	110	76	966	STARTER	DF	\N	\N	\N
920	110	76	967	STARTER	FW	\N	\N	\N
921	110	76	971	STARTER	MF	\N	\N	\N
922	110	76	972	STARTER	MF	\N	\N	\N
923	110	76	974	SUB	\N	\N	\N	\N
924	110	76	975	STARTER	FW	\N	\N	\N
925	110	76	977	SUB	\N	\N	\N	\N
926	110	76	980	STARTER	FW	\N	\N	\N
927	110	2	1246	STARTER	FW	\N	\N	\N
928	110	2	1297	STARTER	FW	\N	\N	\N
929	110	2	1299	STARTER	DF	\N	\N	\N
930	110	2	1301	STARTER	MF	\N	\N	\N
931	110	2	1306	STARTER	MF	\N	\N	\N
932	110	2	1308	STARTER	DF	\N	\N	\N
933	110	2	1309	STARTER	DF	\N	\N	\N
934	110	2	1311	STARTER	FW	\N	\N	\N
935	110	2	1371	STARTER	GK	\N	\N	\N
936	110	2	1372	STARTER	DF	\N	\N	\N
937	110	2	1373	STARTER	MF	\N	\N	\N
938	112	1	1055	STARTER	GK	\N	\N	\N
939	112	1	1056	STARTER	DF	\N	\N	\N
940	112	1	1057	STARTER	DF	\N	\N	\N
941	112	1	1059	STARTER	DF	\N	\N	\N
942	112	1	1060	STARTER	DF	\N	\N	\N
943	112	1	1062	STARTER	MF	\N	\N	\N
944	112	1	1065	STARTER	MF	\N	\N	\N
945	112	16	1245	STARTER	FW	\N	\N	\N
946	112	16	1262	STARTER	FW	\N	\N	\N
947	112	16	1268	STARTER	GK	\N	\N	\N
948	112	16	1270	STARTER	DF	\N	\N	\N
949	112	16	1271	STARTER	DF	\N	\N	\N
950	112	16	1273	STARTER	MF	\N	\N	\N
951	112	16	1275	STARTER	MF	\N	\N	\N
952	112	16	1317	STARTER	DF	\N	\N	\N
953	112	16	1318	STARTER	DF	\N	\N	\N
954	112	16	1321	STARTER	FW	\N	\N	\N
955	112	1	1329	STARTER	FW	\N	\N	\N
956	112	1	1369	STARTER	FW	\N	\N	\N
957	112	1	1370	STARTER	FW	\N	\N	\N
958	112	16	1375	STARTER	FW	\N	\N	\N
959	114	5	1160	STARTER	GK	\N	\N	\N
960	114	5	1164	STARTER	DF	\N	\N	\N
961	114	5	1166	STARTER	DF	\N	\N	\N
962	114	5	1170	STARTER	DF	\N	\N	\N
963	114	5	1171	STARTER	DF	\N	\N	\N
964	114	5	1173	STARTER	MF	\N	\N	\N
965	114	5	1177	STARTER	MF	\N	\N	\N
966	114	5	1180	STARTER	FW	\N	\N	\N
967	114	5	1183	STARTER	MF	\N	\N	\N
968	114	5	1222	STARTER	FW	\N	\N	\N
969	118	88	985	STARTER	GK	\N	\N	\N
970	118	88	989	STARTER	DF	\N	\N	\N
971	118	88	990	STARTER	MF	\N	\N	\N
972	118	88	991	STARTER	DF	\N	\N	\N
973	118	88	993	STARTER	DF	\N	\N	\N
974	118	88	994	STARTER	DF	\N	\N	\N
975	118	88	996	STARTER	FW	\N	\N	\N
976	118	88	999	STARTER	MF	\N	\N	\N
977	118	88	1003	STARTER	FW	\N	\N	\N
978	118	88	1004	STARTER	FW	\N	\N	\N
979	118	11	1009	STARTER	GK	\N	\N	\N
980	118	11	1014	STARTER	DF	\N	\N	\N
981	118	11	1018	STARTER	DF	\N	\N	\N
982	118	11	1020	STARTER	DF	\N	\N	\N
983	118	11	1022	STARTER	FW	\N	\N	\N
984	118	11	1029	STARTER	MF	\N	\N	\N
985	118	11	1030	STARTER	MF	\N	\N	\N
986	118	11	1031	STARTER	FW	\N	\N	\N
987	118	11	1035	STARTER	FW	\N	\N	\N
988	118	11	1036	STARTER	DF	\N	\N	\N
989	119	4	1101	STARTER	GK	\N	\N	\N
990	119	4	1102	STARTER	DF	\N	\N	\N
991	119	4	1103	STARTER	DF	\N	\N	\N
992	119	4	1104	STARTER	DF	\N	\N	\N
993	119	4	1105	STARTER	DF	\N	\N	\N
994	119	4	1106	STARTER	MF	\N	\N	\N
995	119	4	1107	STARTER	MF	\N	\N	\N
996	119	4	1108	STARTER	FW	\N	\N	\N
997	119	4	1109	STARTER	FW	\N	\N	\N
998	119	4	1111	STARTER	FW	\N	\N	\N
999	119	4	1112	STARTER	FW	\N	\N	\N
1000	119	86	1188	STARTER	GK	\N	\N	\N
1001	120	87	1131	STARTER	MF	\N	\N	\N
1002	120	87	1132	STARTER	DF	\N	\N	\N
1003	120	87	1136	STARTER	FW	\N	\N	\N
1004	120	87	1137	STARTER	FW	\N	\N	\N
1005	120	87	1139	STARTER	FW	\N	\N	\N
1006	120	87	1144	STARTER	DF	\N	\N	\N
1007	120	87	1155	STARTER	MF	\N	\N	\N
1008	120	87	1156	STARTER	DF	\N	\N	\N
1009	120	87	1157	STARTER	GK	\N	\N	\N
1010	120	5	1160	STARTER	GK	\N	\N	\N
1011	120	5	1164	STARTER	DF	\N	\N	\N
1012	120	5	1166	STARTER	DF	\N	\N	\N
1013	120	87	1376	STARTER	DF	\N	\N	\N
1014	123	2	1221	STARTER	GK	\N	\N	\N
1015	123	2	1246	STARTER	FW	\N	\N	\N
1016	123	12	1279	STARTER	DF	\N	\N	\N
1017	123	12	1289	STARTER	GK	\N	\N	\N
1018	123	2	1297	STARTER	FW	\N	\N	\N
1019	123	2	1299	STARTER	DF	\N	\N	\N
1020	123	2	1301	STARTER	MF	\N	\N	\N
1021	123	2	1306	STARTER	FW	\N	\N	\N
1022	123	2	1308	STARTER	DF	\N	\N	\N
1023	123	2	1309	STARTER	DF	\N	\N	\N
1024	123	2	1311	STARTER	FW	\N	\N	\N
1025	123	12	1325	STARTER	DF	\N	\N	\N
1026	123	12	1328	STARTER	DF	\N	\N	\N
1027	123	12	1365	STARTER	MF	\N	\N	\N
1028	123	2	1372	STARTER	DF	\N	\N	\N
1029	123	2	1373	STARTER	MF	\N	\N	\N
1030	123	12	1378	STARTER	DF	\N	\N	\N
1031	123	12	1379	STARTER	MF	\N	\N	\N
1032	123	12	1380	STARTER	FW	\N	\N	\N
1033	123	12	1381	STARTER	FW	\N	\N	\N
1034	124	4	1002	STARTER	FW	\N	\N	\N
1035	124	4	1005	STARTER	FW	\N	\N	\N
1036	124	11	1009	STARTER	GK	\N	\N	\N
1037	124	11	1014	STARTER	DF	\N	\N	\N
1038	124	11	1018	STARTER	DF	\N	\N	\N
1039	124	11	1022	STARTER	MF	\N	\N	\N
1040	124	11	1026	STARTER	MF	\N	\N	\N
1041	124	11	1029	STARTER	MF	\N	\N	\N
1042	124	11	1031	STARTER	MF	\N	\N	\N
1043	124	11	1032	STARTER	FW	\N	\N	\N
1044	124	11	1035	STARTER	FW	\N	\N	\N
1045	124	11	1036	STARTER	DF	\N	\N	\N
1046	124	4	1101	STARTER	GK	\N	\N	\N
1047	124	4	1103	STARTER	DF	\N	\N	\N
1048	124	4	1104	STARTER	DF	\N	\N	\N
1049	124	4	1105	STARTER	DF	\N	\N	\N
1050	124	4	1106	STARTER	MF	\N	\N	\N
1051	124	4	1108	STARTER	FW	\N	\N	\N
1052	124	4	1114	STARTER	MF	\N	\N	\N
1053	124	4	1119	STARTER	MF	\N	\N	\N
1054	124	4	1123	STARTER	DF	\N	\N	\N
1055	124	11	1133	STARTER	DF	\N	\N	\N
1056	126	76	955	STARTER	GK	\N	\N	\N
1057	126	76	959	STARTER	DF	\N	\N	\N
1058	126	76	962	STARTER	DF	\N	\N	\N
1059	126	76	966	STARTER	DF	\N	\N	\N
1060	126	76	967	STARTER	MF	\N	\N	\N
1061	126	76	970	STARTER	DF	\N	\N	\N
1062	126	76	971	STARTER	FW	\N	\N	\N
1063	126	76	972	STARTER	MF	\N	\N	\N
1064	126	76	980	STARTER	FW	\N	\N	\N
1065	126	76	982	STARTER	FW	\N	\N	\N
1066	126	15	1042	STARTER	MF	\N	\N	\N
1067	126	15	1044	STARTER	FW	\N	\N	\N
1068	126	15	1048	STARTER	GK	\N	\N	\N
1069	126	15	1050	STARTER	DF	\N	\N	\N
1070	126	15	1217	STARTER	FW	\N	\N	\N
1071	126	15	1265	STARTER	DF	\N	\N	\N
1072	126	15	1266	STARTER	FW	\N	\N	\N
1073	126	15	1314	STARTER	FW	\N	\N	\N
1074	126	15	1374	STARTER	MF	\N	\N	\N
1075	126	15	1382	STARTER	DF	\N	\N	\N
1076	129	76	955	STARTER	GK	\N	\N	\N
1077	129	76	959	STARTER	DF	\N	\N	\N
1078	129	76	960	STARTER	DF	\N	\N	\N
1079	129	76	963	STARTER	DF	\N	\N	\N
1080	129	76	966	STARTER	DF	\N	\N	\N
1081	129	76	967	STARTER	MF	\N	\N	\N
1082	129	76	970	STARTER	MF	\N	\N	\N
1083	129	76	972	STARTER	MF	\N	\N	\N
1084	129	76	975	STARTER	FW	\N	\N	\N
1085	129	76	982	STARTER	FW	\N	\N	\N
1086	129	76	983	STARTER	FW	\N	\N	\N
1087	129	1	1055	STARTER	GK	\N	\N	\N
1088	129	1	1056	STARTER	DF	\N	\N	\N
1089	129	1	1057	STARTER	DF	\N	\N	\N
1090	129	1	1059	STARTER	DF	\N	\N	\N
1091	129	1	1060	STARTER	DF	\N	\N	\N
1092	129	1	1061	STARTER	FW	\N	\N	\N
1093	129	1	1062	STARTER	MF	\N	\N	\N
1094	129	1	1064	STARTER	MF	\N	\N	\N
1095	129	1	1071	STARTER	FW	\N	\N	\N
1096	129	1	1370	STARTER	FW	\N	\N	\N
1097	129	1	1384	STARTER	MF	\N	\N	\N
1098	130	7	1074	STARTER	GK	\N	\N	\N
1099	130	7	1078	STARTER	DF	\N	\N	\N
1100	130	7	1079	STARTER	DF	\N	\N	\N
1101	130	7	1081	STARTER	DF	\N	\N	\N
1102	130	7	1085	STARTER	FW	\N	\N	\N
1103	130	7	1089	STARTER	FW	\N	\N	\N
1104	130	7	1090	STARTER	DF	\N	\N	\N
1105	130	7	1093	STARTER	FW	\N	\N	\N
1106	130	7	1098	STARTER	MF	\N	\N	\N
1107	130	7	1100	STARTER	MF	\N	\N	\N
1108	132	11	1009	STARTER	GK	\N	\N	\N
1109	132	11	1014	STARTER	DF	\N	\N	\N
1110	132	11	1015	STARTER	DF	\N	\N	\N
1111	132	11	1018	STARTER	DF	\N	\N	\N
1112	132	11	1021	STARTER	FW	\N	\N	\N
1113	132	11	1026	STARTER	MF	\N	\N	\N
1114	132	11	1029	STARTER	MF	\N	\N	\N
1115	132	11	1031	STARTER	FW	\N	\N	\N
1116	132	11	1032	STARTER	FW	\N	\N	\N
1117	132	11	1035	STARTER	FW	\N	\N	\N
1118	132	11	1133	STARTER	DF	\N	\N	\N
1119	132	16	1245	STARTER	FW	\N	\N	\N
1120	132	16	1262	STARTER	FW	\N	\N	\N
1121	132	16	1268	STARTER	GK	\N	\N	\N
1122	132	16	1270	STARTER	DF	\N	\N	\N
1123	132	16	1271	STARTER	DF	\N	\N	\N
1124	132	16	1273	STARTER	MF	\N	\N	\N
1125	132	16	1275	STARTER	MF	\N	\N	\N
1126	132	16	1318	STARTER	DF	\N	\N	\N
1127	132	16	1319	STARTER	FW	\N	\N	\N
1128	132	16	1320	STARTER	FW	\N	\N	\N
1129	132	16	1321	STARTER	DF	\N	\N	\N
1130	144	11	1009	STARTER	GK	\N	\N	\N
1131	144	11	1013	STARTER	DF	\N	\N	\N
1132	144	11	1015	STARTER	DF	\N	\N	\N
1133	144	11	1018	STARTER	DF	\N	\N	\N
1134	144	11	1022	STARTER	DF	\N	\N	\N
1135	144	11	1026	STARTER	MF	\N	\N	\N
1136	144	11	1029	STARTER	FW	\N	\N	\N
1137	144	11	1031	STARTER	FW	\N	\N	\N
1138	144	11	1032	STARTER	FW	\N	\N	\N
1139	144	11	1035	STARTER	FW	\N	\N	\N
1140	144	1	1055	STARTER	GK	\N	\N	\N
1141	144	1	1056	STARTER	DF	\N	\N	\N
1142	144	1	1057	STARTER	DF	\N	\N	\N
1143	144	1	1058	STARTER	DF	\N	\N	\N
1144	144	1	1059	STARTER	DF	\N	\N	\N
1145	144	1	1061	STARTER	FW	\N	\N	\N
1146	144	1	1062	STARTER	MF	\N	\N	\N
1147	144	1	1063	STARTER	MF	\N	\N	\N
1148	144	1	1065	STARTER	FW	\N	\N	\N
1149	144	1	1068	STARTER	FW	\N	\N	\N
1150	144	11	1133	STARTER	MF	\N	\N	\N
1151	144	1	1329	STARTER	FW	\N	\N	\N
1152	150	76	957	STARTER	GK	\N	\N	\N
1153	150	76	959	STARTER	DF	\N	\N	\N
1154	150	76	960	STARTER	DF	\N	\N	\N
1155	150	76	963	STARTER	DF	\N	\N	\N
1156	150	76	967	STARTER	MF	\N	\N	\N
1157	150	76	969	STARTER	MF	\N	\N	\N
1158	150	76	970	STARTER	DF	\N	\N	\N
1159	150	76	971	STARTER	FW	\N	\N	\N
1160	150	76	972	STARTER	MF	\N	\N	\N
1161	150	76	975	STARTER	FW	\N	\N	\N
1162	150	76	983	STARTER	FW	\N	\N	\N
1163	150	86	1191	STARTER	DF	\N	\N	\N
1164	150	86	1192	STARTER	DF	\N	\N	\N
1165	150	86	1196	STARTER	DF	\N	\N	\N
1166	150	86	1199	STARTER	MF	\N	\N	\N
1167	150	86	1206	STARTER	FW	\N	\N	\N
1168	150	86	1207	STARTER	MF	\N	\N	\N
1169	150	86	1210	STARTER	FW	\N	\N	\N
1170	150	86	1248	STARTER	GK	\N	\N	\N
1171	150	86	1385	STARTER	FW	\N	\N	\N
1172	150	86	1387	STARTER	DF	\N	\N	\N
1173	150	86	1388	STARTER	MF	\N	\N	\N
1174	154	11	1009	STARTER	GK	\N	\N	\N
1175	154	11	1013	STARTER	DF	\N	\N	\N
1176	154	11	1014	STARTER	DF	\N	\N	\N
1177	154	11	1015	STARTER	DF	\N	\N	\N
1178	154	11	1016	STARTER	DF	\N	\N	\N
1179	154	11	1018	STARTER	MF	\N	\N	\N
1180	154	11	1022	STARTER	MF	\N	\N	\N
1181	154	11	1026	STARTER	MF	\N	\N	\N
1182	154	11	1031	STARTER	FW	\N	\N	\N
1183	154	11	1032	STARTER	FW	\N	\N	\N
1184	154	11	1035	STARTER	FW	\N	\N	\N
1185	154	17	1219	STARTER	MF	\N	\N	\N
1186	154	17	1250	STARTER	GK	\N	\N	\N
1187	154	17	1252	STARTER	DF	\N	\N	\N
1188	154	17	1253	STARTER	DF	\N	\N	\N
1189	154	17	1258	STARTER	FW	\N	\N	\N
1190	154	17	1386	STARTER	MF	\N	\N	\N
1191	154	17	1390	STARTER	DF	\N	\N	\N
1192	154	17	1391	STARTER	MF	\N	\N	\N
1193	154	17	1392	STARTER	DF	\N	\N	\N
1194	157	76	957	STARTER	GK	\N	\N	\N
1195	157	76	959	STARTER	DF	\N	\N	\N
1196	157	76	960	STARTER	DF	\N	\N	\N
1197	157	76	966	STARTER	DF	\N	\N	\N
1198	157	76	969	STARTER	MF	\N	\N	\N
1199	157	76	970	STARTER	DF	\N	\N	\N
1200	157	76	971	STARTER	MF	\N	\N	\N
1201	157	76	972	STARTER	MF	\N	\N	\N
1202	157	76	975	STARTER	FW	\N	\N	\N
1203	157	76	982	STARTER	FW	\N	\N	\N
1204	157	76	983	STARTER	FW	\N	\N	\N
1205	161	76	955	STARTER	GK	\N	\N	\N
1206	161	76	959	STARTER	DF	\N	\N	\N
1207	161	76	962	STARTER	DF	\N	\N	\N
1208	161	76	963	STARTER	DF	\N	\N	\N
1209	161	76	964	STARTER	MF	\N	\N	\N
1210	161	76	967	STARTER	FW	\N	\N	\N
1211	161	76	970	STARTER	DF	\N	\N	\N
1212	161	76	971	STARTER	MF	\N	\N	\N
1213	161	76	972	STARTER	MF	\N	\N	\N
1214	161	76	975	STARTER	MF	\N	\N	\N
1215	161	76	982	STARTER	FW	\N	\N	\N
1216	161	8	1184	STARTER	FW	\N	\N	\N
1217	161	8	1226	STARTER	GK	\N	\N	\N
1218	161	8	1227	STARTER	DF	\N	\N	\N
1219	161	8	1229	STARTER	MF	\N	\N	\N
1220	161	8	1231	STARTER	DF	\N	\N	\N
1221	161	8	1232	STARTER	MF	\N	\N	\N
1222	161	8	1235	STARTER	MF	\N	\N	\N
1223	161	8	1236	STARTER	FW	\N	\N	\N
1224	161	8	1244	STARTER	DF	\N	\N	\N
1225	161	8	1323	STARTER	DF	\N	\N	\N
1226	161	8	1324	STARTER	MF	\N	\N	\N
1227	168	11	1009	STARTER	GK	\N	\N	\N
1228	168	11	1011	STARTER	MF	\N	\N	\N
1229	168	11	1013	STARTER	DF	\N	\N	\N
1230	168	11	1015	STARTER	DF	\N	\N	\N
1231	168	11	1018	STARTER	DF	\N	\N	\N
1232	168	11	1022	STARTER	DF	\N	\N	\N
1233	168	11	1029	STARTER	MF	\N	\N	\N
1234	168	11	1031	STARTER	FW	\N	\N	\N
1235	168	11	1032	STARTER	FW	\N	\N	\N
1236	168	11	1036	STARTER	FW	\N	\N	\N
1237	168	11	1133	STARTER	MF	\N	\N	\N
1238	174	15	1040	STARTER	DF	\N	\N	\N
1239	174	15	1042	STARTER	MF	\N	\N	\N
1240	174	15	1044	STARTER	MF	\N	\N	\N
1241	174	15	1047	STARTER	FW	\N	\N	\N
1242	174	15	1048	STARTER	GK	\N	\N	\N
1243	174	86	1188	STARTER	GK	\N	\N	\N
1244	174	86	1191	STARTER	DF	\N	\N	\N
1245	174	86	1193	STARTER	DF	\N	\N	\N
1246	174	86	1195	STARTER	DF	\N	\N	\N
1247	174	86	1198	STARTER	MF	\N	\N	\N
1248	174	86	1203	STARTER	MF	\N	\N	\N
1249	174	86	1205	STARTER	MF	\N	\N	\N
1250	174	86	1209	STARTER	FW	\N	\N	\N
1251	174	86	1210	STARTER	FW	\N	\N	\N
1252	174	15	1217	STARTER	FW	\N	\N	\N
1253	174	15	1230	STARTER	DF	\N	\N	\N
1254	174	86	1247	STARTER	FW	\N	\N	\N
1255	174	15	1265	STARTER	DF	\N	\N	\N
1256	174	15	1314	STARTER	MF	\N	\N	\N
1257	174	15	1374	STARTER	FW	\N	\N	\N
1258	174	15	1382	STARTER	DF	\N	\N	\N
1259	174	86	1393	STARTER	DF	\N	\N	\N
1260	175	76	955	STARTER	GK	\N	\N	\N
1261	175	76	958	STARTER	DF	\N	\N	\N
1262	175	76	959	STARTER	DF	\N	\N	\N
1263	175	76	964	STARTER	MF	\N	\N	\N
1264	175	76	965	STARTER	DF	\N	\N	\N
1265	175	76	968	STARTER	FW	\N	\N	\N
1266	175	76	969	STARTER	MF	\N	\N	\N
1267	175	76	970	STARTER	DF	\N	\N	\N
1268	175	76	975	STARTER	FW	\N	\N	\N
1269	175	76	981	STARTER	MF	\N	\N	\N
1270	175	7	1076	STARTER	GK	\N	\N	\N
1271	175	7	1078	STARTER	DF	\N	\N	\N
1272	175	7	1079	STARTER	DF	\N	\N	\N
1273	175	7	1082	STARTER	DF	\N	\N	\N
1274	175	7	1083	STARTER	DF	\N	\N	\N
1275	175	7	1085	STARTER	FW	\N	\N	\N
1276	175	7	1086	STARTER	MF	\N	\N	\N
1277	175	7	1088	STARTER	MF	\N	\N	\N
1278	175	7	1090	STARTER	MF	\N	\N	\N
1279	175	7	1096	STARTER	FW	\N	\N	\N
1280	175	7	1100	STARTER	FW	\N	\N	\N
1281	175	76	1411	STARTER	MF	\N	\N	\N
1282	176	11	1009	STARTER	GK	\N	\N	\N
1283	176	11	1013	STARTER	DF	\N	\N	\N
1284	176	11	1015	STARTER	DF	\N	\N	\N
1285	176	11	1018	STARTER	DF	\N	\N	\N
1286	176	11	1022	STARTER	DF	\N	\N	\N
1287	176	11	1028	STARTER	MF	\N	\N	\N
1288	176	11	1029	STARTER	MF	\N	\N	\N
1289	176	11	1031	STARTER	MF	\N	\N	\N
1290	176	11	1034	STARTER	FW	\N	\N	\N
1291	176	11	1036	STARTER	FW	\N	\N	\N
1292	176	11	1133	STARTER	MF	\N	\N	\N
1293	176	12	1279	STARTER	DF	\N	\N	\N
1294	176	12	1280	STARTER	DF	\N	\N	\N
1295	176	12	1282	STARTER	MF	\N	\N	\N
1296	176	12	1289	STARTER	GK	\N	\N	\N
1297	176	12	1325	STARTER	DF	\N	\N	\N
1298	176	12	1328	STARTER	DF	\N	\N	\N
1299	176	12	1365	STARTER	MF	\N	\N	\N
1300	176	12	1366	STARTER	FW	\N	\N	\N
1301	176	12	1367	STARTER	FW	\N	\N	\N
1302	176	12	1380	STARTER	MF	\N	\N	\N
1303	176	12	1381	STARTER	FW	\N	\N	\N
1304	180	11	1009	STARTER	GK	\N	\N	\N
1305	180	11	1013	STARTER	DF	\N	\N	\N
1306	180	11	1015	STARTER	DF	\N	\N	\N
1307	180	11	1020	STARTER	DF	\N	\N	\N
1308	180	11	1028	STARTER	MF	\N	\N	\N
1309	180	11	1029	STARTER	MF	\N	\N	\N
1310	180	11	1031	STARTER	MF	\N	\N	\N
1311	180	11	1032	STARTER	FW	\N	\N	\N
1312	180	11	1035	STARTER	FW	\N	\N	\N
1313	180	11	1036	STARTER	MF	\N	\N	\N
1314	180	7	1076	STARTER	GK	\N	\N	\N
1315	180	7	1080	STARTER	DF	\N	\N	\N
1316	180	7	1081	STARTER	DF	\N	\N	\N
1317	180	7	1083	STARTER	DF	\N	\N	\N
1318	180	7	1085	STARTER	FW	\N	\N	\N
1319	180	7	1088	STARTER	FW	\N	\N	\N
1320	180	7	1090	STARTER	MF	\N	\N	\N
1321	180	7	1091	STARTER	MF	\N	\N	\N
1322	180	7	1097	STARTER	MF	\N	\N	\N
1323	180	7	1100	STARTER	MF	\N	\N	\N
1324	180	11	1133	STARTER	DF	\N	\N	\N
1325	184	76	955	STARTER	GK	\N	\N	\N
1326	184	76	959	STARTER	DF	\N	\N	\N
1327	184	76	962	STARTER	DF	\N	\N	\N
1328	184	76	963	STARTER	DF	\N	\N	\N
1329	184	76	964	STARTER	MF	\N	\N	\N
1330	184	76	968	STARTER	MF	\N	\N	\N
1331	184	76	970	STARTER	DF	\N	\N	\N
1332	184	76	971	STARTER	FW	\N	\N	\N
1333	184	76	975	STARTER	MF	\N	\N	\N
1334	184	76	982	STARTER	FW	\N	\N	\N
1335	184	76	983	STARTER	FW	\N	\N	\N
1336	191	76	955	STARTER	GK	\N	\N	\N
1337	191	76	958	STARTER	DF	\N	\N	\N
1338	191	76	960	STARTER	DF	\N	\N	\N
1339	191	76	963	STARTER	DF	\N	\N	\N
1340	191	76	967	STARTER	FW	\N	\N	\N
1341	191	76	969	STARTER	MF	\N	\N	\N
1342	191	76	970	STARTER	DF	\N	\N	\N
1343	191	76	971	STARTER	MF	\N	\N	\N
1344	191	76	977	STARTER	MF	\N	\N	\N
1345	191	76	982	STARTER	FW	\N	\N	\N
1346	191	76	983	STARTER	FW	\N	\N	\N
1347	192	11	1009	STARTER	GK	\N	\N	\N
1348	192	11	1013	STARTER	DF	\N	\N	\N
1349	192	11	1014	STARTER	DF	\N	\N	\N
1350	192	11	1015	STARTER	MF	\N	\N	\N
1351	192	11	1018	STARTER	MF	\N	\N	\N
1352	192	11	1022	STARTER	MF	\N	\N	\N
1353	192	11	1031	STARTER	FW	\N	\N	\N
1354	192	11	1032	STARTER	FW	\N	\N	\N
1355	192	11	1035	STARTER	FW	\N	\N	\N
1356	192	11	1036	STARTER	DF	\N	\N	\N
1357	192	11	1133	STARTER	DF	\N	\N	\N
1358	192	86	1188	STARTER	GK	\N	\N	\N
1359	192	86	1193	STARTER	DF	\N	\N	\N
1360	192	86	1195	STARTER	DF	\N	\N	\N
1361	192	86	1198	STARTER	MF	\N	\N	\N
1362	192	86	1201	STARTER	DF	\N	\N	\N
1363	192	86	1203	STARTER	MF	\N	\N	\N
1364	192	86	1205	STARTER	MF	\N	\N	\N
1365	192	86	1209	STARTER	FW	\N	\N	\N
1366	192	86	1210	STARTER	FW	\N	\N	\N
1367	192	86	1385	STARTER	FW	\N	\N	\N
1368	192	86	1402	STARTER	DF	\N	\N	\N
1369	200	76	955	STARTER	GK	\N	\N	\N
1370	200	76	959	STARTER	DF	\N	\N	\N
1371	200	76	960	STARTER	DF	\N	\N	\N
1372	200	76	963	STARTER	DF	\N	\N	\N
1373	200	76	966	STARTER	DF	\N	\N	\N
1374	200	76	967	STARTER	FW	\N	\N	\N
1375	200	76	970	STARTER	MF	\N	\N	\N
1376	200	76	972	STARTER	MF	\N	\N	\N
1377	200	76	977	STARTER	MF	\N	\N	\N
1378	200	76	982	STARTER	FW	\N	\N	\N
1379	200	76	983	STARTER	FW	\N	\N	\N
1380	200	11	1009	STARTER	GK	\N	\N	\N
1381	200	11	1013	STARTER	DF	\N	\N	\N
1382	200	11	1015	STARTER	MF	\N	\N	\N
1383	200	11	1018	STARTER	DF	\N	\N	\N
1384	200	11	1022	STARTER	DF	\N	\N	\N
1385	200	11	1029	STARTER	MF	\N	\N	\N
1386	200	11	1031	STARTER	MF	\N	\N	\N
1387	200	11	1032	STARTER	FW	\N	\N	\N
1388	200	11	1035	STARTER	FW	\N	\N	\N
1389	200	11	1036	STARTER	MF	\N	\N	\N
1390	200	11	1133	STARTER	MF	\N	\N	\N
1391	207	76	955	STARTER	GK	\N	\N	\N
1392	207	76	959	STARTER	DF	\N	\N	\N
1393	207	76	962	STARTER	DF	\N	\N	\N
1394	207	76	963	STARTER	DF	\N	\N	\N
1395	207	76	965	STARTER	DF	\N	\N	\N
1396	207	76	967	STARTER	FW	\N	\N	\N
1397	207	76	971	STARTER	MF	\N	\N	\N
1398	207	76	972	STARTER	MF	\N	\N	\N
1399	207	76	977	STARTER	MF	\N	\N	\N
1400	207	76	982	STARTER	FW	\N	\N	\N
1401	207	76	983	STARTER	FW	\N	\N	\N
1402	207	88	984	STARTER	GK	\N	\N	\N
1403	207	88	989	STARTER	DF	\N	\N	\N
1404	207	88	991	STARTER	DF	\N	\N	\N
1405	207	88	994	STARTER	DF	\N	\N	\N
1406	207	88	996	STARTER	MF	\N	\N	\N
1407	207	88	997	STARTER	MF	\N	\N	\N
1408	207	88	1000	STARTER	FW	\N	\N	\N
1409	207	88	1003	STARTER	MF	\N	\N	\N
1410	207	88	1004	STARTER	FW	\N	\N	\N
1411	207	88	1383	STARTER	MF	\N	\N	\N
1412	224	76	956	STARTER	GK	\N	\N	\N
1413	224	76	958	STARTER	DF	\N	\N	\N
1414	224	76	964	STARTER	MF	\N	\N	\N
1415	224	76	965	STARTER	DF	\N	\N	\N
1416	224	76	968	STARTER	MF	\N	\N	\N
1417	224	76	969	STARTER	MF	\N	\N	\N
1418	224	76	975	STARTER	FW	\N	\N	\N
1419	224	76	976	STARTER	DF	\N	\N	\N
1420	224	76	981	STARTER	DF	\N	\N	\N
1421	224	76	1410	STARTER	FW	\N	\N	\N
1422	224	76	1411	STARTER	FW	\N	\N	\N
1423	234	76	955	STARTER	GK	\N	\N	\N
1424	234	76	959	STARTER	DF	\N	\N	\N
1425	234	76	962	STARTER	DF	\N	\N	\N
1426	234	76	966	STARTER	DF	\N	\N	\N
1427	234	76	967	STARTER	FW	\N	\N	\N
1428	234	76	968	STARTER	MF	\N	\N	\N
1429	234	76	969	STARTER	MF	\N	\N	\N
1430	234	76	970	STARTER	MF	\N	\N	\N
1431	234	76	973	STARTER	MF	\N	\N	\N
1432	234	76	974	STARTER	FW	\N	\N	\N
1433	234	76	977	STARTER	MF	\N	\N	\N
1434	234	17	1219	STARTER	FW	\N	\N	\N
1435	234	17	1220	STARTER	FW	\N	\N	\N
1436	234	17	1252	STARTER	DF	\N	\N	\N
1437	234	17	1256	STARTER	MF	\N	\N	\N
1438	234	17	1257	STARTER	MF	\N	\N	\N
1439	234	17	1259	STARTER	FW	\N	\N	\N
1440	234	17	1386	STARTER	MF	\N	\N	\N
1441	234	17	1390	STARTER	DF	\N	\N	\N
1442	234	17	1391	STARTER	DF	\N	\N	\N
1443	234	17	1392	STARTER	DF	\N	\N	\N
1444	234	17	1412	STARTER	GK	\N	\N	\N
1445	241	11	1011	STARTER	GK	\N	\N	\N
1446	241	11	1015	STARTER	MF	\N	\N	\N
1447	241	11	1016	STARTER	MF	\N	\N	\N
1448	241	11	1018	STARTER	DF	\N	\N	\N
1449	241	11	1020	STARTER	DF	\N	\N	\N
1450	241	11	1022	STARTER	DF	\N	\N	\N
1451	241	11	1029	STARTER	MF	\N	\N	\N
1452	241	11	1031	STARTER	MF	\N	\N	\N
1453	241	11	1032	STARTER	FW	\N	\N	\N
1454	241	11	1035	STARTER	FW	\N	\N	\N
1455	241	11	1036	STARTER	MF	\N	\N	\N
1456	283	11	1009	STARTER	GK	\N	\N	\N
1457	283	11	1013	STARTER	DF	\N	\N	\N
1458	283	11	1015	STARTER	MF	\N	\N	\N
1459	283	11	1018	STARTER	MF	\N	\N	\N
1460	283	11	1022	STARTER	DF	\N	\N	\N
1461	283	11	1029	STARTER	MF	\N	\N	\N
1462	283	11	1031	STARTER	FW	\N	\N	\N
1463	283	11	1032	STARTER	FW	\N	\N	\N
1464	283	11	1035	STARTER	FW	\N	\N	\N
1465	283	11	1036	STARTER	DF	\N	\N	\N
1466	283	11	1133	STARTER	DF	\N	\N	\N
1467	284	11	1009	STARTER	GK	\N	\N	\N
1468	284	11	1013	STARTER	DF	\N	\N	\N
1469	284	11	1014	STARTER	DF	\N	\N	\N
1470	284	11	1015	STARTER	MF	\N	\N	\N
1471	284	11	1018	STARTER	MF	\N	\N	\N
1472	284	11	1022	STARTER	FW	\N	\N	\N
1473	284	11	1029	STARTER	MF	\N	\N	\N
1474	284	11	1032	STARTER	FW	\N	\N	\N
1475	284	11	1035	STARTER	FW	\N	\N	\N
1476	284	11	1036	STARTER	DF	\N	\N	\N
1477	284	11	1133	STARTER	DF	\N	\N	\N
1478	286	76	955	STARTER	GK	\N	\N	\N
1479	286	76	958	STARTER	DF	\N	\N	\N
1480	286	76	960	STARTER	DF	\N	\N	\N
1481	286	76	963	STARTER	DF	\N	\N	\N
1482	286	76	966	STARTER	DF	\N	\N	\N
1483	286	76	968	STARTER	FW	\N	\N	\N
1484	286	76	970	STARTER	MF	\N	\N	\N
1485	286	76	971	STARTER	FW	\N	\N	\N
1486	286	76	972	STARTER	MF	\N	\N	\N
1487	286	76	977	STARTER	MF	\N	\N	\N
1488	286	76	983	STARTER	FW	\N	\N	\N
1489	292	76	955	STARTER	GK	\N	\N	\N
1490	292	76	959	STARTER	DF	\N	\N	\N
1491	292	76	960	STARTER	DF	\N	\N	\N
1492	292	76	963	STARTER	DF	\N	\N	\N
1493	292	76	966	STARTER	DF	\N	\N	\N
1494	292	76	968	STARTER	MF	\N	\N	\N
1495	292	76	971	STARTER	MF	\N	\N	\N
1496	292	76	973	STARTER	MF	\N	\N	\N
1497	292	76	974	STARTER	FW	\N	\N	\N
1498	292	76	977	STARTER	FW	\N	\N	\N
1499	292	76	983	STARTER	FW	\N	\N	\N
1500	293	11	1009	STARTER	GK	\N	\N	\N
1501	293	11	1015	STARTER	DF	\N	\N	\N
1502	293	11	1016	STARTER	DF	\N	\N	\N
1503	293	11	1018	STARTER	DF	\N	\N	\N
1504	293	11	1022	STARTER	MF	\N	\N	\N
1505	293	11	1029	STARTER	MF	\N	\N	\N
1506	293	11	1031	STARTER	FW	\N	\N	\N
1507	293	11	1035	STARTER	FW	\N	\N	\N
1508	293	11	1085	STARTER	MF	\N	\N	\N
1509	293	13	1224	STARTER	DF	\N	\N	\N
1510	293	13	1238	STARTER	FW	\N	\N	\N
1511	293	13	1332	STARTER	GK	\N	\N	\N
1512	293	13	1334	STARTER	DF	\N	\N	\N
1513	293	13	1335	STARTER	MF	\N	\N	\N
1514	293	13	1336	STARTER	MF	\N	\N	\N
1515	293	13	1338	STARTER	DF	\N	\N	\N
1516	293	13	1341	STARTER	FW	\N	\N	\N
1517	293	11	1413	STARTER	FW	\N	\N	\N
1518	293	11	1446	STARTER	DF	\N	\N	\N
1519	293	13	1447	STARTER	DF	\N	\N	\N
1520	293	13	1448	STARTER	MF	\N	\N	\N
1521	293	13	1449	STARTER	FW	\N	\N	\N
1522	301	76	956	STARTER	GK	\N	\N	\N
1523	301	76	958	STARTER	DF	\N	\N	\N
1524	301	76	960	STARTER	DF	\N	\N	\N
1525	301	76	963	STARTER	DF	\N	\N	\N
1526	301	76	965	STARTER	MF	\N	\N	\N
1527	301	76	966	STARTER	DF	\N	\N	\N
1528	301	76	972	STARTER	MF	\N	\N	\N
1529	301	76	1003	STARTER	FW	\N	\N	\N
1530	301	76	1184	STARTER	FW	\N	\N	\N
1531	301	76	1450	STARTER	MF	\N	\N	\N
1532	301	76	1451	STARTER	FW	\N	\N	\N
1533	318	11	1009	STARTER	GK	\N	\N	\N
1534	318	11	1018	STARTER	DF	\N	\N	\N
1535	318	11	1022	STARTER	MF	\N	\N	\N
1536	318	11	1029	STARTER	MF	\N	\N	\N
1537	318	11	1031	STARTER	FW	\N	\N	\N
1538	318	11	1032	STARTER	FW	\N	\N	\N
1539	318	11	1036	STARTER	DF	\N	\N	\N
1540	318	7	1076	STARTER	GK	\N	\N	\N
1541	318	7	1078	STARTER	DF	\N	\N	\N
1542	318	7	1079	STARTER	DF	\N	\N	\N
1543	318	7	1082	STARTER	DF	\N	\N	\N
1544	318	7	1083	STARTER	DF	\N	\N	\N
1545	318	7	1086	STARTER	MF	\N	\N	\N
1546	318	7	1088	STARTER	MF	\N	\N	\N
1547	318	7	1090	STARTER	MF	\N	\N	\N
1548	318	7	1099	STARTER	FW	\N	\N	\N
1549	318	7	1100	STARTER	FW	\N	\N	\N
1550	318	11	1133	STARTER	DF	\N	\N	\N
1551	370	76	956	STARTER	GK	\N	\N	\N
1552	370	76	960	STARTER	DF	\N	\N	\N
1553	370	76	962	SUB	\N	\N	\N	\N
1554	370	76	963	STARTER	DF	\N	\N	\N
1555	370	76	965	STARTER	MF	\N	\N	\N
1556	370	76	966	STARTER	DF	\N	\N	\N
1557	370	76	967	SUB	\N	\N	\N	\N
1558	370	76	970	SUB	\N	\N	\N	\N
1559	370	76	972	STARTER	FW	\N	\N	\N
1560	370	76	980	SUB	\N	\N	\N	\N
1561	370	76	981	SUB	\N	\N	\N	\N
1562	370	76	982	STARTER	FW	\N	\N	\N
1563	370	76	1003	STARTER	MF	\N	\N	\N
1564	370	11	1009	STARTER	GK	\N	\N	\N
1565	370	11	1015	STARTER	DF	\N	\N	\N
1566	370	11	1016	STARTER	DF	\N	\N	\N
1567	370	11	1018	STARTER	DF	\N	\N	\N
1568	370	11	1020	SUB	\N	\N	\N	\N
1569	370	11	1022	STARTER	MF	\N	\N	\N
1570	370	11	1023	SUB	\N	\N	\N	\N
1571	370	11	1026	SUB	\N	\N	\N	\N
1572	370	11	1029	STARTER	MF	\N	\N	\N
1573	370	11	1031	STARTER	FW	\N	\N	\N
1574	370	11	1032	STARTER	FW	\N	\N	\N
1575	370	11	1036	SUB	\N	\N	\N	\N
1576	370	11	1133	SUB	\N	\N	\N	\N
1577	370	76	1184	SUB	\N	\N	\N	\N
1578	370	11	1286	SUB	\N	\N	\N	\N
1579	370	76	1410	STARTER	DF	\N	\N	\N
1580	370	11	1413	STARTER	FW	\N	\N	\N
1581	370	11	1446	STARTER	DF	\N	\N	\N
1582	370	76	1450	STARTER	MF	\N	\N	\N
1583	370	76	1451	STARTER	FW	\N	\N	\N
1584	370	11	1472	STARTER	MF	\N	\N	\N
1585	370	11	1476	SUB	\N	\N	\N	\N
1586	370	76	1484	SUB	\N	\N	\N	\N
1587	485	1	979	STARTER	FW	\N	\N	\N
1588	485	1	983	STARTER	FW	\N	\N	\N
1589	485	1	997	STARTER	MF	\N	\N	\N
1590	485	1	1055	STARTER	GK	\N	\N	\N
1591	485	1	1057	STARTER	DF	\N	\N	\N
1592	485	1	1058	SUB	\N	\N	\N	\N
1593	485	1	1059	STARTER	DF	\N	\N	\N
1594	485	1	1061	SUB	\N	\N	\N	\N
1595	485	1	1062	STARTER	MF	\N	\N	\N
1596	485	1	1063	SUB	\N	\N	\N	\N
1597	485	1	1064	STARTER	FW	\N	\N	\N
1598	485	1	1364	STARTER	DF	\N	\N	\N
1599	485	1	1453	STARTER	MF	\N	\N	\N
1600	519	11	1009	STARTER	GK	\N	\N	\N
1601	519	11	1013	STARTER	DF	\N	\N	\N
1602	519	11	1016	STARTER	DF	\N	\N	\N
1603	519	11	1018	STARTER	DF	\N	\N	\N
1604	519	11	1025	STARTER	MF	\N	\N	\N
1605	519	11	1029	STARTER	MF	\N	\N	\N
1606	519	11	1035	STARTER	FW	\N	\N	\N
1607	519	11	1085	STARTER	MF	\N	\N	\N
1608	519	11	1286	SUB	\N	\N	\N	\N
1609	519	11	1413	STARTER	FW	\N	\N	\N
1610	519	11	1472	STARTER	FW	\N	\N	\N
1611	519	11	1479	SUB	\N	\N	\N	\N
1612	618	11	1009	STARTER	GK	\N	\N	\N
1613	618	11	1011	SUB	\N	\N	\N	\N
1614	618	11	1013	STARTER	DF	\N	\N	\N
1615	618	11	1016	STARTER	DF	\N	\N	\N
1616	618	11	1018	STARTER	DF	\N	\N	\N
1617	618	11	1022	STARTER	MF	\N	\N	\N
1618	618	11	1023	SUB	\N	\N	\N	\N
1619	618	11	1025	STARTER	FW	\N	\N	\N
1620	618	11	1026	SUB	\N	\N	\N	\N
1621	618	11	1028	STARTER	MF	\N	\N	\N
1622	618	11	1032	STARTER	FW	\N	\N	\N
1623	618	11	1036	SUB	\N	\N	\N	\N
1624	618	11	1085	SUB	\N	\N	\N	\N
1625	618	11	1413	STARTER	FW	\N	\N	\N
1626	618	11	1472	STARTER	MF	\N	\N	\N
1627	618	11	1476	SUB	\N	\N	\N	\N
1628	636	76	956	SUB	\N	\N	\N	\N
1629	636	76	957	STARTER	GK	\N	\N	\N
1630	636	76	959	SUB	\N	\N	\N	\N
1631	636	76	960	SUB	\N	\N	\N	\N
1632	636	76	964	SUB	\N	\N	\N	\N
1633	636	76	965	STARTER	DF	\N	\N	\N
1634	636	76	966	STARTER	DF	\N	\N	\N
1635	636	76	972	STARTER	MF	\N	\N	\N
1636	636	76	982	STARTER	FW	\N	\N	\N
1637	636	76	1184	STARTER	MF	\N	\N	\N
1638	636	76	1410	STARTER	DF	\N	\N	\N
1639	636	76	1450	STARTER	MF	\N	\N	\N
1640	636	76	1451	STARTER	FW	\N	\N	\N
1641	636	76	1491	STARTER	FW	\N	\N	\N
1642	636	76	1492	STARTER	DF	\N	\N	\N
1643	647	76	962	STARTER	DF	\N	\N	\N
1644	647	76	963	STARTER	DF	\N	\N	\N
1645	647	76	965	STARTER	DF	\N	\N	\N
1646	647	76	966	SUB	\N	\N	\N	\N
1647	647	76	967	SUB	\N	\N	\N	\N
1648	647	76	968	STARTER	MF	\N	\N	\N
1649	647	76	969	STARTER	MF	\N	\N	\N
1650	647	76	970	SUB	\N	\N	\N	\N
1651	647	76	971	SUB	\N	\N	\N	\N
1652	647	76	972	STARTER	MF	\N	\N	\N
1653	647	76	980	STARTER	FW	\N	\N	\N
1654	647	76	1451	STARTER	FW	\N	\N	\N
1655	647	76	1484	STARTER	GK	\N	\N	\N
1656	669	11	1009	SUB	\N	\N	\N	\N
1657	669	11	1013	STARTER	DF	\N	\N	\N
1658	669	11	1016	STARTER	DF	\N	\N	\N
1659	669	11	1018	SUB	\N	\N	\N	\N
1660	669	11	1022	STARTER	MF	\N	\N	\N
1661	669	11	1025	STARTER	FW	\N	\N	\N
1662	669	11	1028	STARTER	MF	\N	\N	\N
1663	669	11	1029	SUB	\N	\N	\N	\N
1664	669	11	1085	STARTER	MF	\N	\N	\N
1665	669	11	1413	STARTER	FW	\N	\N	\N
1666	669	11	1446	STARTER	DF	\N	\N	\N
1667	669	11	1472	STARTER	FW	\N	\N	\N
1668	669	11	1476	STARTER	GK	\N	\N	\N
1669	943	53	1926	STARTER	GK	\N	\N	\N
1670	943	53	1927	SUB	\N	\N	\N	\N
1671	943	53	1928	STARTER	FW	\N	\N	\N
1672	943	53	1929	STARTER	FW	\N	\N	\N
1673	943	53	1930	STARTER	MF	\N	\N	\N
1674	943	53	1931	STARTER	MF	\N	\N	\N
1675	943	53	1932	STARTER	MF	\N	\N	\N
1676	943	53	1933	STARTER	MF	\N	\N	\N
1677	943	53	1934	SUB	\N	\N	\N	\N
1678	943	53	1935	STARTER	FW	\N	\N	\N
1679	943	53	1936	SUB	\N	\N	\N	\N
1680	943	53	1937	SUB	\N	\N	\N	\N
1681	945	104	1940	SUB	\N	\N	\N	\N
1682	945	104	1941	SUB	\N	\N	\N	\N
1683	945	104	1942	STARTER	GK	\N	\N	\N
1684	945	104	1943	STARTER	DF	\N	\N	\N
1685	945	104	1946	STARTER	DF	\N	\N	\N
1686	945	104	1948	STARTER	DF	\N	\N	\N
1687	945	104	1949	STARTER	DF	\N	\N	\N
1688	945	104	1952	STARTER	MF	\N	\N	\N
1689	945	104	1953	STARTER	MF	\N	\N	\N
1690	945	104	1954	SUB	\N	\N	\N	\N
1691	945	104	1955	STARTER	MF	\N	\N	\N
1692	945	104	1958	SUB	\N	\N	\N	\N
1693	945	104	1959	STARTER	FW	\N	\N	\N
1694	945	104	1961	STARTER	FW	\N	\N	\N
1695	945	104	1962	SUB	\N	\N	\N	\N
1696	945	104	1963	STARTER	FW	\N	\N	\N
1697	945	25	1964	SUB	\N	\N	\N	\N
1698	945	25	1965	SUB	\N	\N	\N	\N
1699	945	25	1966	STARTER	GK	\N	\N	\N
1700	945	25	1967	SUB	\N	\N	\N	\N
1701	945	25	1968	STARTER	DF	\N	\N	\N
1702	945	25	1969	SUB	\N	\N	\N	\N
1703	945	25	1970	SUB	\N	\N	\N	\N
1704	945	25	1971	STARTER	DF	\N	\N	\N
1705	945	25	1972	STARTER	DF	\N	\N	\N
1706	945	25	1973	STARTER	DF	\N	\N	\N
1707	945	25	1975	STARTER	MF	\N	\N	\N
1708	945	25	1976	SUB	\N	\N	\N	\N
1709	945	25	1977	SUB	\N	\N	\N	\N
1710	945	25	1978	STARTER	MF	\N	\N	\N
1711	945	25	1979	STARTER	MF	\N	\N	\N
1712	945	25	1980	SUB	\N	\N	\N	\N
1713	945	25	1981	SUB	\N	\N	\N	\N
1714	945	25	1982	SUB	\N	\N	\N	\N
1715	945	25	1983	SUB	\N	\N	\N	\N
1716	945	25	1984	SUB	\N	\N	\N	\N
1717	945	25	1985	SUB	\N	\N	\N	\N
1718	945	25	1986	STARTER	FW	\N	\N	\N
1719	945	25	1987	STARTER	FW	\N	\N	\N
1720	945	25	1988	STARTER	FW	\N	\N	\N
1721	966	103	1989	SUB	\N	\N	\N	\N
1722	966	103	1990	STARTER	GK	\N	\N	\N
1723	966	103	1991	SUB	\N	\N	\N	\N
1724	966	103	1992	STARTER	DF	\N	\N	\N
1725	966	103	1993	STARTER	DF	\N	\N	\N
1726	966	103	1994	SUB	\N	\N	\N	\N
1727	966	103	1995	SUB	\N	\N	\N	\N
1728	966	103	1996	STARTER	DF	\N	\N	\N
1729	966	103	1997	STARTER	MF	\N	\N	\N
1730	966	103	1998	SUB	\N	\N	\N	\N
1731	966	103	1999	SUB	\N	\N	\N	\N
1732	966	103	2000	STARTER	MF	\N	\N	\N
1733	966	103	2001	STARTER	MF	\N	\N	\N
1734	966	103	2002	SUB	\N	\N	\N	\N
1735	966	103	2003	STARTER	MF	\N	\N	\N
1736	966	103	2004	STARTER	MF	\N	\N	\N
1737	966	103	2006	STARTER	FW	\N	\N	\N
1738	966	103	2008	STARTER	DF	\N	\N	\N
1739	966	103	2010	SUB	\N	\N	\N	\N
1740	966	103	2011	SUB	\N	\N	\N	\N
1741	974	64	1330	STARTER	MF	\N	\N	\N
1742	974	52	2035	SUB	\N	\N	\N	\N
1743	974	52	2036	STARTER	GK	\N	\N	\N
1744	974	52	2037	SUB	\N	\N	\N	\N
1745	974	52	2038	STARTER	DF	\N	\N	\N
1746	974	52	2039	SUB	\N	\N	\N	\N
1747	974	52	2040	SUB	\N	\N	\N	\N
1748	974	52	2041	SUB	\N	\N	\N	\N
1749	974	52	2042	STARTER	DF	\N	\N	\N
1750	974	52	2043	STARTER	DF	\N	\N	\N
1751	974	52	2044	STARTER	DF	\N	\N	\N
1752	974	52	2045	SUB	\N	\N	\N	\N
1753	974	52	2046	STARTER	MF	\N	\N	\N
1754	974	52	2047	STARTER	MF	\N	\N	\N
1755	974	52	2048	SUB	\N	\N	\N	\N
1756	974	52	2050	STARTER	MF	\N	\N	\N
1757	974	52	2051	SUB	\N	\N	\N	\N
1758	974	52	2052	STARTER	FW	\N	\N	\N
1759	974	52	2053	STARTER	FW	\N	\N	\N
1760	974	52	2054	SUB	\N	\N	\N	\N
1761	974	52	2055	SUB	\N	\N	\N	\N
1762	974	52	2056	SUB	\N	\N	\N	\N
1763	974	52	2057	STARTER	FW	\N	\N	\N
1764	974	64	2185	STARTER	MF	\N	\N	\N
1765	974	64	2208	STARTER	DF	\N	\N	\N
1766	974	64	2211	SUB	\N	\N	\N	\N
1767	974	64	2212	STARTER	GK	\N	\N	\N
1768	974	64	2213	SUB	\N	\N	\N	\N
1769	974	64	2214	STARTER	DF	\N	\N	\N
1770	974	64	2215	SUB	\N	\N	\N	\N
1771	974	64	2216	SUB	\N	\N	\N	\N
1772	974	64	2217	STARTER	DF	\N	\N	\N
1773	974	64	2218	STARTER	DF	\N	\N	\N
1774	974	64	2219	SUB	\N	\N	\N	\N
1775	974	64	2221	SUB	\N	\N	\N	\N
1776	974	64	2222	STARTER	MF	\N	\N	\N
1777	974	64	2223	STARTER	MF	\N	\N	\N
1778	974	64	2224	SUB	\N	\N	\N	\N
1779	974	64	2225	SUB	\N	\N	\N	\N
1780	974	64	2226	SUB	\N	\N	\N	\N
1781	974	64	2227	STARTER	FW	\N	\N	\N
1782	974	64	2228	STARTER	MF	\N	\N	\N
1783	974	64	2229	SUB	\N	\N	\N	\N
1784	974	64	2230	SUB	\N	\N	\N	\N
1785	975	32	1827	STARTER	FW	\N	\N	\N
1786	975	39	1938	STARTER	MF	\N	\N	\N
1787	975	39	1944	STARTER	FW	\N	\N	\N
1788	975	32	2127	SUB	\N	\N	\N	\N
1789	975	32	2128	STARTER	GK	\N	\N	\N
1790	975	32	2129	SUB	\N	\N	\N	\N
1791	975	32	2130	SUB	\N	\N	\N	\N
1792	975	32	2131	SUB	\N	\N	\N	\N
1793	975	32	2132	STARTER	DF	\N	\N	\N
1794	975	32	2133	SUB	\N	\N	\N	\N
1795	975	32	2134	STARTER	DF	\N	\N	\N
1796	975	32	2135	STARTER	DF	\N	\N	\N
1797	975	32	2136	STARTER	DF	\N	\N	\N
1798	975	32	2137	STARTER	MF	\N	\N	\N
1799	975	32	2138	SUB	\N	\N	\N	\N
1800	975	32	2139	STARTER	MF	\N	\N	\N
1801	975	32	2140	STARTER	MF	\N	\N	\N
1802	975	32	2141	SUB	\N	\N	\N	\N
1803	975	32	2142	SUB	\N	\N	\N	\N
1804	975	32	2143	STARTER	FW	\N	\N	\N
1805	975	32	2144	SUB	\N	\N	\N	\N
1806	975	32	2146	STARTER	FW	\N	\N	\N
1807	975	32	2147	SUB	\N	\N	\N	\N
1808	975	32	2148	SUB	\N	\N	\N	\N
1809	975	32	2149	SUB	\N	\N	\N	\N
1810	975	39	2201	STARTER	DF	\N	\N	\N
1811	975	39	2231	SUB	\N	\N	\N	\N
1812	975	39	2232	SUB	\N	\N	\N	\N
1813	975	39	2233	STARTER	GK	\N	\N	\N
1814	975	39	2234	SUB	\N	\N	\N	\N
1815	975	39	2235	STARTER	DF	\N	\N	\N
1816	975	39	2236	STARTER	DF	\N	\N	\N
1817	975	39	2237	SUB	\N	\N	\N	\N
1818	975	39	2238	SUB	\N	\N	\N	\N
1819	975	39	2239	STARTER	DF	\N	\N	\N
1820	975	39	2240	STARTER	MF	\N	\N	\N
1821	975	39	2241	STARTER	MF	\N	\N	\N
1822	975	39	2242	SUB	\N	\N	\N	\N
1823	975	39	2243	SUB	\N	\N	\N	\N
1824	975	39	2244	STARTER	MF	\N	\N	\N
1825	975	39	2245	SUB	\N	\N	\N	\N
1826	975	39	2246	STARTER	MF	\N	\N	\N
1827	975	39	2247	SUB	\N	\N	\N	\N
1828	975	39	2248	SUB	\N	\N	\N	\N
1829	975	39	2249	SUB	\N	\N	\N	\N
1830	975	39	2250	SUB	\N	\N	\N	\N
1831	980	52	2035	SUB	\N	\N	\N	\N
1832	980	52	2036	STARTER	GK	\N	\N	\N
1833	980	52	2037	SUB	\N	\N	\N	\N
1834	980	52	2038	STARTER	DF	\N	\N	\N
1835	980	52	2039	SUB	\N	\N	\N	\N
1836	980	52	2040	SUB	\N	\N	\N	\N
1837	980	52	2041	SUB	\N	\N	\N	\N
1838	980	52	2042	STARTER	DF	\N	\N	\N
1839	980	52	2043	STARTER	DF	\N	\N	\N
1840	980	52	2044	STARTER	DF	\N	\N	\N
1841	980	52	2045	SUB	\N	\N	\N	\N
1842	980	52	2046	SUB	\N	\N	\N	\N
1843	980	52	2047	STARTER	MF	\N	\N	\N
1844	980	52	2048	STARTER	FW	\N	\N	\N
1845	980	52	2049	STARTER	MF	\N	\N	\N
1846	980	52	2050	STARTER	MF	\N	\N	\N
1847	980	52	2051	SUB	\N	\N	\N	\N
1848	980	52	2053	STARTER	FW	\N	\N	\N
1849	980	52	2054	SUB	\N	\N	\N	\N
1850	980	52	2055	SUB	\N	\N	\N	\N
1851	980	52	2056	SUB	\N	\N	\N	\N
1852	980	52	2057	STARTER	FW	\N	\N	\N
1853	980	105	2181	SUB	\N	\N	\N	\N
1854	980	105	2182	STARTER	FW	\N	\N	\N
1855	980	105	2205	STARTER	FW	\N	\N	\N
1856	980	105	2209	STARTER	FW	\N	\N	\N
1857	980	105	2210	SUB	\N	\N	\N	\N
1858	980	105	2251	SUB	\N	\N	\N	\N
1859	980	105	2252	SUB	\N	\N	\N	\N
1860	980	105	2253	STARTER	DF	\N	\N	\N
1861	980	105	2254	STARTER	DF	\N	\N	\N
1862	980	105	2255	STARTER	DF	\N	\N	\N
1863	980	105	2256	SUB	\N	\N	\N	\N
1864	980	105	2257	SUB	\N	\N	\N	\N
1865	980	105	2258	SUB	\N	\N	\N	\N
1866	980	105	2259	STARTER	MF	\N	\N	\N
1867	980	105	2260	STARTER	DF	\N	\N	\N
1868	980	105	2261	SUB	\N	\N	\N	\N
1869	980	105	2262	STARTER	GK	\N	\N	\N
1870	980	105	2263	STARTER	MF	\N	\N	\N
1871	980	105	2264	SUB	\N	\N	\N	\N
1872	980	105	2265	STARTER	MF	\N	\N	\N
1873	980	105	2266	SUB	\N	\N	\N	\N
1874	980	105	2267	SUB	\N	\N	\N	\N
1875	980	105	2268	SUB	\N	\N	\N	\N
1876	981	54	1398	STARTER	FW	\N	\N	\N
1877	981	54	1399	SUB	\N	\N	\N	\N
1878	981	39	1938	STARTER	MF	\N	\N	\N
1879	981	39	1939	SUB	\N	\N	\N	\N
1880	981	39	1944	STARTER	FW	\N	\N	\N
1881	981	54	2104	SUB	\N	\N	\N	\N
1882	981	54	2105	STARTER	GK	\N	\N	\N
1883	981	54	2106	SUB	\N	\N	\N	\N
1884	981	54	2107	STARTER	DF	\N	\N	\N
1885	981	54	2108	STARTER	DF	\N	\N	\N
1886	981	54	2109	SUB	\N	\N	\N	\N
1887	981	54	2110	STARTER	DF	\N	\N	\N
1888	981	54	2111	SUB	\N	\N	\N	\N
1889	981	54	2112	SUB	\N	\N	\N	\N
1890	981	54	2113	STARTER	DF	\N	\N	\N
1891	981	54	2114	SUB	\N	\N	\N	\N
1892	981	54	2116	SUB	\N	\N	\N	\N
1893	981	54	2117	STARTER	MF	\N	\N	\N
1894	981	54	2118	SUB	\N	\N	\N	\N
1895	981	54	2119	STARTER	MF	\N	\N	\N
1896	981	54	2120	STARTER	MF	\N	\N	\N
1897	981	54	2121	STARTER	MF	\N	\N	\N
1898	981	54	2122	SUB	\N	\N	\N	\N
1899	981	54	2123	SUB	\N	\N	\N	\N
1900	981	54	2124	STARTER	MF	\N	\N	\N
1901	981	54	2125	SUB	\N	\N	\N	\N
1902	981	54	2126	SUB	\N	\N	\N	\N
1903	981	39	2201	STARTER	DF	\N	\N	\N
1904	981	39	2231	SUB	\N	\N	\N	\N
1905	981	39	2232	SUB	\N	\N	\N	\N
1906	981	39	2233	STARTER	GK	\N	\N	\N
1907	981	39	2234	SUB	\N	\N	\N	\N
1908	981	39	2235	STARTER	DF	\N	\N	\N
1909	981	39	2236	STARTER	DF	\N	\N	\N
1910	981	39	2237	SUB	\N	\N	\N	\N
1911	981	39	2238	SUB	\N	\N	\N	\N
1912	981	39	2239	STARTER	DF	\N	\N	\N
1913	981	39	2240	STARTER	MF	\N	\N	\N
1914	981	39	2241	STARTER	MF	\N	\N	\N
1915	981	39	2243	SUB	\N	\N	\N	\N
1916	981	39	2244	STARTER	MF	\N	\N	\N
1917	981	39	2245	SUB	\N	\N	\N	\N
1918	981	39	2246	STARTER	MF	\N	\N	\N
1919	981	39	2247	SUB	\N	\N	\N	\N
1920	981	39	2248	SUB	\N	\N	\N	\N
1921	981	39	2249	SUB	\N	\N	\N	\N
1922	981	39	2250	SUB	\N	\N	\N	\N
1923	984	54	1399	SUB	\N	\N	\N	\N
1924	984	52	2035	SUB	\N	\N	\N	\N
1925	984	52	2036	STARTER	GK	\N	\N	\N
1926	984	52	2037	SUB	\N	\N	\N	\N
1927	984	52	2039	SUB	\N	\N	\N	\N
1928	984	52	2040	SUB	\N	\N	\N	\N
1929	984	52	2041	STARTER	DF	\N	\N	\N
1930	984	52	2042	STARTER	DF	\N	\N	\N
1931	984	52	2043	STARTER	DF	\N	\N	\N
1932	984	52	2044	STARTER	DF	\N	\N	\N
1933	984	52	2045	SUB	\N	\N	\N	\N
1934	984	52	2046	STARTER	MF	\N	\N	\N
1935	984	52	2047	STARTER	MF	\N	\N	\N
1936	984	52	2048	SUB	\N	\N	\N	\N
1937	984	52	2049	SUB	\N	\N	\N	\N
1938	984	52	2050	STARTER	MF	\N	\N	\N
1939	984	52	2051	STARTER	MF	\N	\N	\N
1940	984	52	2052	SUB	\N	\N	\N	\N
1941	984	52	2053	STARTER	FW	\N	\N	\N
1942	984	52	2054	SUB	\N	\N	\N	\N
1943	984	52	2055	SUB	\N	\N	\N	\N
1944	984	52	2056	SUB	\N	\N	\N	\N
1945	984	52	2057	STARTER	MF	\N	\N	\N
1946	984	54	2104	SUB	\N	\N	\N	\N
1947	984	54	2105	STARTER	GK	\N	\N	\N
1948	984	54	2106	SUB	\N	\N	\N	\N
1949	984	54	2107	STARTER	DF	\N	\N	\N
1950	984	54	2108	STARTER	DF	\N	\N	\N
1951	984	54	2109	SUB	\N	\N	\N	\N
1952	984	54	2110	STARTER	DF	\N	\N	\N
1953	984	54	2111	SUB	\N	\N	\N	\N
1954	984	54	2112	SUB	\N	\N	\N	\N
1955	984	54	2113	STARTER	DF	\N	\N	\N
1956	984	54	2114	SUB	\N	\N	\N	\N
1957	984	54	2115	STARTER	FW	\N	\N	\N
1958	984	54	2116	SUB	\N	\N	\N	\N
1959	984	54	2117	STARTER	MF	\N	\N	\N
1960	984	54	2118	SUB	\N	\N	\N	\N
1961	984	54	2119	STARTER	MF	\N	\N	\N
1962	984	54	2120	STARTER	MF	\N	\N	\N
1963	984	54	2121	STARTER	FW	\N	\N	\N
1964	984	54	2122	SUB	\N	\N	\N	\N
1965	984	54	2123	SUB	\N	\N	\N	\N
1966	984	54	2124	STARTER	MF	\N	\N	\N
1967	984	54	2125	SUB	\N	\N	\N	\N
1968	984	54	2126	SUB	\N	\N	\N	\N
1969	1002	11	1009	STARTER	GK	\N	\N	\N
1970	1002	11	1015	STARTER	DF	\N	\N	\N
1971	1002	11	1016	STARTER	DF	\N	\N	\N
1972	1002	11	1019	STARTER	DF	\N	\N	\N
1973	1002	11	1028	STARTER	MF	\N	\N	\N
1974	1002	11	1029	SUB	\N	\N	\N	\N
1975	1002	11	1032	SUB	\N	\N	\N	\N
1976	1002	7	1074	STARTER	GK	\N	\N	\N
1977	1002	7	1077	STARTER	DF	\N	\N	\N
1978	1002	7	1079	STARTER	DF	\N	\N	\N
1979	1002	7	1081	STARTER	DF	\N	\N	\N
1980	1002	7	1082	STARTER	DF	\N	\N	\N
1981	1002	11	1085	STARTER	FW	\N	\N	\N
1982	1002	7	1088	STARTER	MF	\N	\N	\N
1983	1002	7	1094	STARTER	FW	\N	\N	\N
1984	1002	7	1098	STARTER	MF	\N	\N	\N
1985	1002	7	1257	STARTER	FW	\N	\N	\N
1986	1002	11	1413	STARTER	FW	\N	\N	\N
1987	1002	11	1472	STARTER	MF	\N	\N	\N
1988	1002	7	1497	SUB	\N	\N	\N	\N
1989	1002	11	2270	STARTER	FW	\N	\N	\N
1990	1002	11	2271	SUB	\N	\N	\N	\N
1991	1002	11	2331	STARTER	DF	\N	\N	\N
1992	1002	11	2332	STARTER	MF	\N	\N	\N
1993	1002	11	2333	SUB	\N	\N	\N	\N
1994	1002	11	2334	SUB	\N	\N	\N	\N
1995	1002	11	2335	SUB	\N	\N	\N	\N
1996	1002	11	2336	SUB	\N	\N	\N	\N
1997	1002	7	2337	STARTER	MF	\N	\N	\N
1998	1002	7	2338	STARTER	MF	\N	\N	\N
1999	1002	7	2339	SUB	\N	\N	\N	\N
2000	1002	7	2340	SUB	\N	\N	\N	\N
2001	1002	7	2341	SUB	\N	\N	\N	\N
2002	1002	7	2342	SUB	\N	\N	\N	\N
2003	1002	7	2343	SUB	\N	\N	\N	\N
2004	1002	7	2344	SUB	\N	\N	\N	\N
2005	1191	11	1009	STARTER	GK	\N	\N	\N
2006	1191	11	1015	STARTER	DF	\N	\N	\N
2007	1191	11	1016	STARTER	DF	\N	\N	\N
2008	1191	11	1018	STARTER	DF	\N	\N	\N
2009	1191	11	1028	SUB	\N	\N	\N	\N
2010	1191	11	1029	STARTER	MF	\N	\N	\N
2011	1191	11	1032	STARTER	FW	\N	\N	\N
2012	1191	11	1085	SUB	\N	\N	\N	\N
2013	1191	11	1413	STARTER	FW	\N	\N	\N
2014	1191	11	1446	STARTER	DF	\N	\N	\N
2015	1191	11	1479	SUB	\N	\N	\N	\N
2016	1191	11	2269	SUB	\N	\N	\N	\N
2017	1191	11	2270	STARTER	MF	\N	\N	\N
2018	1191	11	2333	SUB	\N	\N	\N	\N
2019	1191	11	2334	SUB	\N	\N	\N	\N
2020	1191	11	2336	STARTER	MF	\N	\N	\N
2021	1191	11	2436	SUB	\N	\N	\N	\N
\.


--
-- Data for Name: match_player_ratings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.match_player_ratings (match_id, player_id, rating, is_motm) FROM stdin;
\.


--
-- Data for Name: match_team_stats; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.match_team_stats (match_id, team_id, possession_pct, shots, shots_on_target, corners, fouls, offsides) FROM stdin;
\.


--
-- Data for Name: matches; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.matches (id, competition_edition_id, group_id, round, home_team_id, away_team_id, stadium_id, kickoff_at, status, home_score, away_score, home_score_et, away_score_et, home_score_pens, away_score_pens, attendance, referee_id) FROM stdin;
13	1	\N	1	76	87	12	2017-08-27 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
14	1	\N	1	8	1	9	2017-08-26 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
16	1	\N	1	17	88	18	2017-08-26 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
17	1	\N	1	7	12	8	2017-08-26 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
18	1	\N	1	11	15	12	2017-08-26 16:00:00+00	FULL_TIME	7	0	\N	\N	\N	\N	\N	\N
19	1	\N	1	4	2	5	2017-08-26 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
20	1	\N	1	86	13	20	2017-08-26 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
21	1	\N	1	5	16	6	2017-08-26 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
22	1	\N	2	13	16	6	2017-09-09 16:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
23	1	\N	2	1	11	2	2017-09-09 19:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
24	1	\N	2	86	76	20	2017-09-10 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
25	1	\N	2	7	17	8	2017-09-10 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
26	1	\N	2	87	12	21	2017-09-10 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
27	1	\N	2	88	2	22	2017-09-10 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
28	1	\N	2	4	15	5	2017-09-10 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
29	1	\N	2	5	8	6	2017-09-10 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
30	1	\N	3	12	88	13	2017-09-16 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
31	1	\N	3	13	8	6	2017-09-16 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
32	1	\N	3	7	2	8	2017-09-16 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
33	1	\N	3	16	76	17	2017-09-16 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
34	1	\N	3	87	15	21	2017-09-16 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
35	1	\N	3	5	86	6	2017-09-17 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
36	1	\N	3	1	4	2	2017-09-15 19:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
37	1	\N	3	11	17	12	2017-09-17 16:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
38	1	\N	4	76	8	12	2017-09-23 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
39	1	\N	4	88	4	22	2017-09-24 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
40	1	\N	4	15	7	4	2017-09-24 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
41	1	\N	4	12	5	13	2017-09-24 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
42	1	\N	4	16	86	17	2017-09-23 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
43	1	\N	4	2	11	19	2017-09-21 16:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
44	1	\N	4	17	13	18	2017-09-23 16:00:00+00	FULL_TIME	1	3	\N	\N	\N	\N	\N	\N
45	1	\N	4	1	87	2	2017-09-24 19:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
46	1	\N	5	16	4	17	2017-09-30 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
47	1	\N	5	8	87	9	2017-09-30 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
48	1	\N	5	88	1	2	2017-09-30 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
49	1	\N	5	12	11	13	2017-10-01 16:04:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
50	1	\N	5	2	13	19	2017-09-30 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
51	1	\N	5	15	86	4	2017-09-30 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
52	1	\N	5	17	5	18	2017-09-30 16:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
53	1	\N	5	76	7	12	2017-09-30 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
55	2	\N	FINAL	23	36	12	2017-09-02 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
56	1	\N	6	2	5	19	2017-10-13 16:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
57	1	\N	6	8	16	9	2017-10-14 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
58	1	\N	6	15	88	4	2017-10-14 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
59	1	\N	6	4	76	5	2017-10-14 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
60	1	\N	6	17	1	13	2017-10-14 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
61	1	\N	6	86	87	20	2017-10-14 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
62	1	\N	6	11	7	12	2017-10-15 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
63	1	\N	6	13	12	6	2017-10-15 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
64	1	\N	7	17	4	18	2017-10-20 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
65	1	\N	7	2	1	19	2017-10-21 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
66	1	\N	7	87	16	21	2017-10-21 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
67	1	\N	7	5	15	6	2017-10-21 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
68	1	\N	7	8	88	9	2017-10-21 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
69	1	\N	7	11	86	12	2017-10-21 16:00:00+00	FULL_TIME	4	0	\N	\N	\N	\N	\N	\N
70	1	\N	7	7	13	8	2017-10-21 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
71	1	\N	7	12	76	13	2017-10-22 16:07:00+00	FULL_TIME	0	4	\N	\N	\N	\N	\N	\N
72	1	\N	8	1	5	2	2017-10-27 19:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
73	1	\N	8	76	11	11	2017-10-28 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
74	1	\N	8	4	8	5	2017-10-29 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
75	1	\N	8	87	2	21	2017-10-29 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
76	1	\N	8	7	88	8	2017-10-29 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
77	1	\N	8	86	12	20	2017-10-29 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
78	1	\N	8	16	17	17	2017-10-29 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
79	1	\N	8	13	15	14	2017-10-30 16:05:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
80	1	\N	9	16	12	17	2017-11-03 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
81	1	\N	9	88	76	22	2017-11-04 16:02:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
82	1	\N	9	4	13	5	2017-11-04 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
83	1	\N	9	86	2	20	2017-11-04 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
84	1	\N	9	1	15	2	2017-11-04 19:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
85	1	\N	9	8	7	9	2017-11-04 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
86	1	\N	9	87	17	21	2017-11-05 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
87	1	\N	9	5	11	14	2017-11-05 16:04:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
88	1	\N	10	88	87	22	2017-11-17 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
89	1	\N	10	13	11	14	2017-11-18 16:05:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
90	1	\N	10	15	8	4	2017-11-18 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
91	1	\N	10	86	1	20	2017-11-19 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
92	1	\N	10	12	17	13	2017-11-18 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
93	1	\N	10	16	2	17	2017-11-18 16:05:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
94	1	\N	10	7	4	8	2017-11-19 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
95	1	\N	10	76	5	12	2017-11-19 16:00:00+00	FULL_TIME	5	0	\N	\N	\N	\N	\N	\N
96	1	\N	11	8	86	9	2017-11-24 16:05:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
97	1	\N	11	88	5	22	2017-11-25 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
98	1	\N	11	76	13	12	2017-11-25 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
99	1	\N	11	2	17	19	2017-11-25 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
100	1	\N	11	4	12	5	2017-11-25 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
101	1	\N	11	15	16	4	2017-11-25 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
102	1	\N	11	11	87	11	2017-11-26 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
103	1	\N	11	1	7	2	2017-11-27 19:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
104	1	\N	12	1	12	2	2017-12-29 19:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
105	1	\N	12	5	4	6	2018-01-02 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
106	1	\N	12	87	13	21	2017-12-30 14:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
107	1	\N	12	86	88	21	2017-12-31 14:00:00+00	FULL_TIME	1	3	\N	\N	\N	\N	\N	\N
108	1	\N	12	7	16	8	2017-12-30 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
109	1	\N	12	8	11	9	2017-12-30 16:13:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
110	1	\N	12	2	76	19	2017-12-31 16:15:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
111	1	\N	12	17	15	18	2018-01-01 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
112	1	\N	13	16	1	17	2018-01-18 14:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
113	1	\N	13	8	2	9	2018-01-13 16:05:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
114	1	\N	13	13	5	14	2018-01-14 16:00:00+00	FULL_TIME	3	2	\N	\N	\N	\N	\N	\N
115	1	\N	13	12	15	13	2018-01-13 16:05:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
116	1	\N	13	87	7	21	2018-01-13 16:05:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
117	1	\N	13	76	17	12	2018-01-17 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
118	1	\N	13	11	88	12	2018-01-18 16:00:00+00	FULL_TIME	4	0	\N	\N	\N	\N	\N	\N
119	1	\N	13	86	4	20	2018-01-15 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
120	1	\N	14	5	87	6	2018-01-19 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
121	1	\N	14	16	88	17	2018-01-22 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
122	1	\N	14	7	86	8	2018-01-20 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
123	1	\N	14	2	12	19	2018-01-20 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
124	1	\N	14	4	11	5	2018-01-22 16:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
125	1	\N	14	13	1	6	2018-01-21 16:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
126	1	\N	14	15	76	4	2018-01-21 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
127	1	\N	14	17	8	18	2018-01-21 16:15:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
128	1	\N	15	12	8	13	2018-01-25 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
129	1	\N	15	1	76	12	2018-01-27 16:05:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
130	1	\N	15	5	7	14	2018-01-27 16:05:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
131	1	\N	15	4	87	5	2018-01-27 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
132	1	\N	15	11	16	12	2018-01-28 16:00:00+00	FULL_TIME	4	0	\N	\N	\N	\N	\N	\N
133	1	\N	15	88	13	22	2018-01-28 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
134	1	\N	15	15	2	4	2018-01-26 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
135	1	\N	15	17	86	18	2018-01-27 16:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
136	1	\N	16	1	8	2	2018-02-03 19:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
137	1	\N	16	87	76	21	2018-02-03 16:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
138	1	\N	16	88	17	22	2018-02-03 14:05:00+00	FULL_TIME	3	2	\N	\N	\N	\N	\N	\N
139	1	\N	16	12	7	13	2018-02-04 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
140	1	\N	16	2	4	19	2018-02-04 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
141	1	\N	16	13	86	6	2018-02-03 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
142	1	\N	16	16	5	17	2018-02-03 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
143	1	\N	16	15	11	4	2018-02-04 16:00:00+00	FULL_TIME	0	3	\N	\N	\N	\N	\N	\N
144	1	\N	17	11	1	12	2018-02-07 16:30:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
145	1	\N	17	15	4	4	2018-02-08 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
146	1	\N	17	2	88	19	2018-02-07 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
147	1	\N	17	17	7	18	2018-02-07 14:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
148	1	\N	17	12	87	13	2018-02-07 16:00:00+00	FULL_TIME	0	3	\N	\N	\N	\N	\N	\N
149	1	\N	17	16	13	17	2018-02-07 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
150	1	\N	17	76	86	12	2018-02-06 16:00:00+00	FULL_TIME	4	0	\N	\N	\N	\N	\N	\N
151	1	\N	17	8	5	9	2018-02-07 16:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
152	1	\N	18	8	13	9	2018-02-11 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
153	1	\N	18	2	7	19	2018-02-11 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
154	1	\N	18	17	11	13	2018-02-15 16:35:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
155	1	\N	18	86	5	20	2018-02-11 14:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
156	1	\N	18	4	1	5	2018-02-12 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
157	1	\N	18	76	16	12	2018-02-14 16:00:00+00	FULL_TIME	4	1	\N	\N	\N	\N	\N	\N
158	1	\N	18	15	87	4	2018-02-11 16:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
159	1	\N	18	88	12	22	2018-02-11 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
160	1	\N	19	87	1	21	2018-02-16 16:33:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
161	1	\N	19	8	76	9	2018-02-28 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
162	1	\N	19	4	88	5	2018-02-17 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
163	1	\N	19	7	15	8	2018-02-19 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
164	1	\N	19	13	17	6	2018-02-19 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
165	1	\N	19	86	16	20	2018-02-17 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
166	1	\N	19	5	12	14	2018-02-18 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
168	1	\N	19	11	2	12	2018-02-26 16:00:00+00	FULL_TIME	5	0	\N	\N	\N	\N	\N	\N
169	1	\N	20	4	16	5	2018-03-03 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
170	1	\N	20	87	8	21	2018-03-04 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
171	1	\N	20	1	88	2	2018-03-03 19:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
172	1	\N	20	5	17	6	2018-03-04 14:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
173	1	\N	20	13	2	6	2018-03-04 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
174	1	\N	20	86	15	20	2018-03-03 14:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
175	1	\N	20	7	76	8	2018-05-13 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
176	1	\N	20	11	12	12	2018-03-02 16:00:00+00	FULL_TIME	3	3	\N	\N	\N	\N	\N	\N
177	1	\N	21	16	8	17	2018-03-08 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
178	1	\N	21	5	2	6	2018-03-07 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
179	1	\N	21	88	15	22	2018-03-07 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
180	1	\N	21	7	11	8	2018-04-09 16:05:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
181	1	\N	21	1	17	2	2018-03-08 19:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
182	1	\N	21	87	86	21	2018-03-08 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
183	1	\N	21	12	13	13	2018-03-08 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
184	1	\N	21	76	4	12	2018-03-09 16:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
185	1	\N	22	1	2	2	2018-03-11 19:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
186	1	\N	22	4	17	5	2018-03-13 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
187	1	\N	22	15	5	4	2018-03-11 16:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
188	1	\N	22	88	8	22	2018-03-11 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
189	1	\N	22	16	87	17	2018-03-11 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
190	1	\N	22	13	7	6	2018-03-11 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
191	1	\N	22	76	12	12	2018-03-12 16:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
192	1	\N	22	86	11	20	2018-04-03 16:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
193	1	\N	23	5	1	6	2018-04-08 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
194	1	\N	23	12	86	13	2018-04-08 16:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
195	1	\N	23	8	4	9	2018-04-08 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
196	1	\N	23	2	87	19	2018-04-06 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
197	1	\N	23	15	13	4	2018-04-08 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
198	1	\N	23	88	7	22	2018-04-06 16:03:00+00	FULL_TIME	0	3	\N	\N	\N	\N	\N	\N
199	1	\N	23	17	16	18	2018-04-07 16:00:00+00	FULL_TIME	3	2	\N	\N	\N	\N	\N	\N
200	1	\N	23	11	76	12	2018-04-29 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
201	1	\N	24	15	1	4	2018-04-13 16:05:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
202	1	\N	24	12	16	13	2018-04-11 16:00:00+00	FULL_TIME	1	3	\N	\N	\N	\N	\N	\N
203	1	\N	24	2	86	19	2018-04-11 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
204	1	\N	24	7	8	8	2018-04-12 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
205	1	\N	24	13	4	6	2018-04-11 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
206	1	\N	24	17	87	18	2018-04-11 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
207	1	\N	24	76	88	12	2018-04-11 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
208	1	\N	24	11	5	12	2018-04-12 16:05:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
209	1	\N	25	87	88	21	2018-04-15 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
210	1	\N	25	8	15	9	2018-04-16 16:00:00+00	FULL_TIME	1	3	\N	\N	\N	\N	\N	\N
211	1	\N	25	1	86	2	2018-04-15 19:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
212	1	\N	25	17	12	18	2018-04-15 16:00:00+00	FULL_TIME	1	3	\N	\N	\N	\N	\N	\N
213	1	\N	25	2	16	19	2018-04-15 16:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
214	1	\N	25	4	7	5	2018-04-16 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
215	1	\N	25	5	76	6	2018-04-22 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
216	1	\N	25	11	13	12	2018-04-16 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
217	1	\N	26	12	4	13	2018-04-28 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
218	1	\N	26	86	8	20	2018-04-27 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
219	1	\N	26	87	11	21	2018-04-21 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
220	1	\N	26	5	88	14	2018-04-27 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
221	1	\N	26	17	2	18	2018-04-30 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
222	1	\N	26	16	15	17	2018-04-28 16:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
223	1	\N	26	7	1	8	2018-04-28 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
224	1	\N	26	13	76	6	2018-05-10 16:30:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
225	1	\N	27	4	5	5	2018-05-06 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
226	1	\N	27	12	1	13	2018-05-06 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
227	1	\N	27	76	2	12	2018-05-22 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
228	1	\N	27	15	17	4	2018-05-04 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
229	1	\N	27	88	86	22	2018-05-05 16:00:00+00	FULL_TIME	4	0	\N	\N	\N	\N	\N	\N
230	1	\N	27	16	7	17	2018-05-06 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
231	1	\N	27	13	87	6	2018-05-05 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
232	1	\N	27	11	8	12	2018-05-06 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
233	1	\N	28	2	8	19	2018-05-10 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
234	1	\N	28	17	76	18	2018-05-19 16:05:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
235	1	\N	28	1	16	2	2018-05-11 19:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
236	1	\N	28	5	13	6	2018-05-13 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
237	1	\N	28	4	86	5	2018-05-12 16:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
238	1	\N	28	7	87	8	2018-05-16 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
239	1	\N	28	15	12	4	2018-05-14 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
240	1	\N	28	88	11	22	2018-05-12 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
241	1	\N	29	11	4	12	2018-05-19 14:15:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
242	1	\N	29	88	16	22	2018-05-19 16:00:00+00	FULL_TIME	3	2	\N	\N	\N	\N	\N	\N
243	1	\N	29	1	13	2	2018-05-20 20:00:00+00	FULL_TIME	4	1	\N	\N	\N	\N	\N	\N
244	1	\N	29	87	5	21	2018-05-19 14:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
245	1	\N	29	76	15	12	2018-05-25 16:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
246	1	\N	29	8	17	9	2018-05-23 16:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
247	1	\N	29	86	7	20	2018-05-20 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
248	1	\N	29	12	2	13	2018-05-18 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
249	1	\N	30	87	4	21	2018-05-28 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
250	1	\N	30	13	88	6	2018-05-28 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
251	1	\N	30	8	12	9	2018-05-28 16:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
252	1	\N	30	7	5	8	2018-05-28 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
253	1	\N	30	76	1	12	2018-05-28 20:00:00+00	FULL_TIME	1	3	\N	\N	\N	\N	\N	\N
254	1	\N	30	86	17	20	2018-05-28 16:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
255	1	\N	30	2	15	19	2018-05-28 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
256	1	\N	30	16	11	17	2018-05-28 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
258	2	\N	FINAL	23	35	11	2017-09-12 16:07:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
259	2	\N	FINAL	64	23	23	2017-10-18 18:05:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
260	3	\N	GROUP	62	38	24	2017-11-08 14:10:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
261	3	\N	GROUP	89	91	24	2017-11-08 16:18:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
262	3	\N	GROUP	40	53	24	2017-11-09 15:07:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
263	3	\N	GROUP	51	55	24	2017-11-10 15:00:00+00	FULL_TIME	0	3	\N	\N	\N	\N	\N	\N
264	3	\N	GROUP	90	38	24	2017-11-10 14:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
265	3	\N	GROUP	62	89	24	2017-11-10 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
266	3	\N	GROUP	53	55	24	2017-11-12 15:00:00+00	FULL_TIME	4	1	\N	\N	\N	\N	\N	\N
267	3	\N	GROUP	91	90	24	2017-11-12 14:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
268	3	\N	GROUP	38	89	24	2017-11-12 16:15:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
269	3	\N	GROUP	40	51	24	2017-11-13 15:00:00+00	FULL_TIME	5	1	\N	\N	\N	\N	\N	\N
270	3	\N	GROUP	38	91	24	2017-11-14 14:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
271	3	\N	GROUP	62	90	24	2017-11-14 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
272	3	\N	GROUP	55	40	24	2017-11-15 15:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
273	3	\N	GROUP	89	90	24	2017-11-16 14:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
274	3	\N	GROUP	51	53	24	2017-11-16 15:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
275	3	\N	GROUP	62	91	24	2017-11-16 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
276	3	\N	SEMI FINAL	40	90	24	2017-11-20 15:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
277	3	\N	SEMI FINAL	62	53	24	2017-11-19 15:05:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
278	3	\N	FINAL	62	90	24	2017-11-22 15:30:00+00	FULL_TIME	3	2	\N	\N	\N	\N	\N	\N
279	4	\N	GROUP	76	92	12	2018-02-10 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
280	4	\N	GROUP	11	93	12	2018-02-11 16:00:00+00	FULL_TIME	4	0	\N	\N	\N	\N	\N	\N
281	4	\N	GROUP	93	11	25	2018-02-20 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
282	4	\N	GROUP	92	76	26	2018-02-21 16:30:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
283	4	\N	GROUP	11	94	12	2018-03-07 18:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
284	4	\N	GROUP	94	11	25	2018-03-17 20:30:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
285	4	\N	GROUP	76	95	12	2018-03-06 16:35:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
286	4	\N	GROUP	95	76	25	2018-03-17 16:47:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
287	2	\N	FINAL	54	23	23	2018-03-22 20:04:00+00	FULL_TIME	4	1	\N	\N	\N	\N	\N	\N
288	2	\N	FINAL	23	61	12	2018-03-27 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
289	5	\N	GROUP	76	96	12	2018-04-07 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
290	5	\N	GROUP	96	76	25	2018-04-18 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
291	5	\N	GROUP	97	76	27	2018-05-06 22:00:00+00	FULL_TIME	4	0	\N	\N	\N	\N	\N	\N
292	5	\N	GROUP	76	98	12	2018-05-16 19:05:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
293	6	\N	1	11	13	12	2018-08-22 20:05:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
294	6	\N	1	15	8	4	2018-08-22 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
295	6	\N	1	99	2	19	2018-08-22 16:05:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
296	6	\N	1	100	87	16	2018-08-22 16:05:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
297	6	\N	1	88	101	22	2018-08-22 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
298	6	\N	1	4	17	5	2018-08-22 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
299	6	\N	1	12	6	13	2018-08-23 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
300	6	\N	1	3	102	28	2018-08-23 14:10:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
301	6	\N	1	7	76	12	2018-08-23 18:10:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
302	6	\N	1	1	5	2	2018-08-23 20:13:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
304	6	\N	2	88	17	22	2018-08-25 16:03:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
305	6	\N	2	100	101	16	2018-08-25 14:05:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
306	6	\N	2	7	13	8	2018-08-26 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
307	6	\N	2	11	5	12	2018-08-27 18:03:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
308	6	\N	2	3	87	28	2018-08-26 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
309	6	\N	2	4	76	5	2018-11-25 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
310	6	\N	2	15	102	4	2018-08-26 14:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
311	6	\N	2	12	2	13	2018-08-26 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
312	6	\N	2	1	8	2	2018-08-27 20:07:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
313	6	\N	2	99	6	29	2018-08-27 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
314	7	\N	GROUP	33	27	8	2018-08-10 10:52:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
315	7	\N	GROUP	39	52	8	2018-08-09 10:52:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
316	7	\N	GROUP	62	24	28	2018-08-23 10:52:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
317	7	\N	KNOCKOUT	56	91	24	2018-08-09 10:53:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
318	8	\N	FINAL	11	7	19	2018-08-18 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
319	6	\N	3	88	2	22	2018-08-31 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
320	6	\N	3	1	15	2	2018-11-22 19:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
321	6	\N	3	12	101	13	2018-09-01 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
322	6	\N	3	100	102	16	2018-09-01 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
323	6	\N	3	7	5	8	2018-09-01 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
324	6	\N	3	4	6	5	2018-09-01 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
325	6	\N	3	13	99	6	2018-09-01 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
326	6	\N	3	11	87	12	2018-11-23 16:05:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
327	6	\N	3	3	8	28	2018-09-02 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
328	6	\N	3	17	76	13	2018-11-22 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
329	6	\N	4	6	100	11	2018-09-14 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
330	6	\N	4	17	1	18	2018-09-14 14:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
331	6	\N	4	8	11	9	2018-09-15 16:16:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
332	6	\N	4	13	15	6	2018-09-15 16:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
333	6	\N	4	87	7	21	2018-09-15 14:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
334	6	\N	4	2	3	19	2018-09-15 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
335	6	\N	4	102	88	11	2018-09-15 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
336	6	\N	4	76	12	12	2018-09-16 16:00:00+00	FULL_TIME	4	3	\N	\N	\N	\N	\N	\N
337	6	\N	4	101	4	30	2018-09-15 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
338	6	\N	4	5	99	6	2018-09-16 14:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
339	6	\N	5	87	99	21	2018-09-19 14:03:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
340	6	\N	5	5	15	6	2018-09-19 16:00:00+00	FULL_TIME	4	2	\N	\N	\N	\N	\N	\N
341	6	\N	5	8	7	9	2018-09-19 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
342	6	\N	5	76	100	12	2018-09-19 19:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
343	6	\N	5	17	3	18	2018-09-19 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
344	6	\N	5	101	1	30	2018-09-19 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
345	6	\N	5	13	4	6	2018-09-20 14:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
346	6	\N	5	2	11	19	2018-09-20 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
347	6	\N	5	6	88	11	2018-09-20 16:00:00+00	FULL_TIME	3	2	\N	\N	\N	\N	\N	\N
348	6	\N	5	102	12	11	2018-09-21 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
349	6	\N	6	101	3	30	2018-09-22 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
350	6	\N	6	17	11	13	2018-09-23 16:00:00+00	FULL_TIME	1	3	\N	\N	\N	\N	\N	\N
351	6	\N	6	15	100	4	2018-09-22 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
352	6	\N	6	76	88	12	2018-09-23 19:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
353	6	\N	6	5	4	6	2018-09-23 14:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
354	6	\N	6	99	1	29	2018-09-23 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
355	6	\N	6	6	7	12	2018-09-24 19:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
356	6	\N	6	2	13	19	2018-09-24 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
357	6	\N	6	8	12	9	2018-09-24 16:00:00+00	FULL_TIME	1	3	\N	\N	\N	\N	\N	\N
358	6	\N	6	102	87	11	2018-09-25 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
359	6	\N	7	15	6	4	2018-09-27 14:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
360	6	\N	7	88	5	22	2018-09-26 16:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
361	6	\N	7	76	3	12	2018-11-29 16:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
362	6	\N	7	11	101	12	2019-05-25 15:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
363	6	\N	7	1	87	2	2018-09-28 19:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
364	6	\N	7	7	17	8	2018-09-27 16:03:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
365	6	\N	7	12	13	13	2018-09-28 14:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
366	6	\N	7	4	8	5	2018-09-28 16:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
367	6	\N	7	100	2	16	2018-09-28 16:10:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
368	6	\N	7	99	102	29	2018-09-29 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
369	6	\N	8	3	6	28	2018-10-01 16:05:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
370	6	\N	8	11	76	12	2018-09-30 17:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
371	6	\N	8	12	5	13	2018-10-01 16:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
372	6	\N	8	88	87	22	2018-10-01 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
373	6	\N	8	100	17	16	2018-10-01 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
374	6	\N	8	15	2	4	2018-10-01 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
375	6	\N	8	7	101	8	2018-10-01 14:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
376	6	\N	8	99	8	29	2018-10-02 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
377	6	\N	8	1	13	2	2018-10-02 19:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
378	6	\N	8	4	102	5	2018-10-02 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
379	6	\N	9	87	12	21	2018-10-05 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
380	6	\N	9	88	8	22	2018-10-06 16:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
381	6	\N	9	11	6	12	2018-10-06 19:03:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
382	6	\N	9	4	15	5	2018-10-06 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
383	6	\N	9	13	5	6	2018-10-06 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
384	6	\N	9	7	102	8	2018-10-06 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
385	6	\N	9	76	2	12	2018-10-07 19:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
386	6	\N	9	3	99	28	2018-10-07 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
387	6	\N	9	101	17	30	2018-10-07 14:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
388	6	\N	9	1	100	2	2018-10-08 19:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
389	6	\N	10	8	5	9	2018-10-19 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
390	6	\N	10	17	15	18	2018-10-19 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
391	6	\N	10	1	6	2	2018-10-19 19:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
392	6	\N	10	76	99	12	2018-10-20 16:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
393	6	\N	10	101	102	30	2018-10-20 16:03:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
394	6	\N	10	13	88	6	2018-10-20 14:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
395	6	\N	10	100	3	16	2018-10-20 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
396	6	\N	10	11	12	12	2018-10-21 16:07:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
397	6	\N	10	87	4	21	2018-10-21 14:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
398	6	\N	10	2	7	19	2018-10-21 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
399	6	\N	11	3	1	28	2018-10-24 16:07:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
400	6	\N	11	100	4	16	2018-10-24 14:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
401	6	\N	11	11	99	12	2018-10-24 19:00:00+00	FULL_TIME	5	1	\N	\N	\N	\N	\N	\N
402	6	\N	11	13	6	6	2018-10-24 16:05:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
403	6	\N	11	15	88	4	2018-10-24 16:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
404	6	\N	11	12	7	13	2018-10-25 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
405	6	\N	11	5	17	6	2018-10-25 14:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
406	6	\N	11	8	101	9	2018-10-25 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
407	6	\N	11	2	87	19	2018-10-24 16:00:00+00	FULL_TIME	1	3	\N	\N	\N	\N	\N	\N
408	6	\N	11	102	76	12	2018-10-25 19:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
409	6	\N	12	15	11	12	2018-10-28 19:00:00+00	FULL_TIME	0	5	\N	\N	\N	\N	\N	\N
410	6	\N	12	99	100	29	2018-10-28 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
411	6	\N	12	88	1	22	2018-10-28 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
412	6	\N	12	3	13	28	2018-10-28 14:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
413	6	\N	12	7	4	8	2018-10-28 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
414	6	\N	12	12	17	13	2018-10-29 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
415	6	\N	12	6	101	11	2018-10-29 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
416	6	\N	12	2	5	19	2018-10-30 16:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
417	6	\N	12	76	87	12	2018-10-30 19:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
418	6	\N	12	102	8	11	2018-10-31 16:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
419	6	\N	13	6	87	2	2018-11-02 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
420	6	\N	13	12	100	13	2018-11-02 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
421	6	\N	13	99	88	29	2018-11-03 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
422	6	\N	13	3	11	12	2018-11-03 16:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
423	6	\N	13	7	15	8	2018-11-03 16:00:00+00	FULL_TIME	4	0	\N	\N	\N	\N	\N	\N
424	6	\N	13	101	2	30	2018-11-03 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
425	6	\N	13	4	1	5	2018-11-04 14:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
426	6	\N	13	76	8	12	2018-11-04 19:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
427	6	\N	13	17	13	18	2018-11-04 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
428	6	\N	13	102	5	11	2018-11-05 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
429	6	\N	14	100	8	16	2018-11-07 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
430	6	\N	14	17	87	18	2018-11-07 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
431	6	\N	14	99	7	29	2018-11-07 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
432	6	\N	14	101	13	30	2018-11-07 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
433	6	\N	14	6	76	12	2018-12-20 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
434	6	\N	14	4	88	5	2018-11-07 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
435	6	\N	14	15	12	4	2018-11-07 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
436	6	\N	14	5	3	6	2018-11-08 16:30:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
437	6	\N	14	11	102	12	2018-12-19 18:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
438	6	\N	14	1	2	2	2018-12-07 19:00:00+00	FULL_TIME	4	0	\N	\N	\N	\N	\N	\N
439	6	\N	15	100	11	16	2019-04-17 14:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
440	6	\N	15	7	88	8	2019-01-22 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
441	6	\N	15	3	15	28	2018-12-02 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
442	6	\N	15	87	101	21	2018-12-02 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
443	6	\N	15	5	6	6	2018-12-02 16:00:00+00	FULL_TIME	4	1	\N	\N	\N	\N	\N	\N
444	6	\N	15	4	99	5	2018-12-02 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
445	6	\N	15	8	2	9	2018-12-02 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
446	6	\N	15	17	102	18	2018-12-03 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
447	6	\N	15	13	76	6	2018-12-03 16:00:00+00	FULL_TIME	1	3	\N	\N	\N	\N	\N	\N
448	6	\N	15	1	12	2	2018-12-04 19:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
449	6	\N	16	3	7	28	2019-01-25 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
450	6	\N	16	4	11	5	2019-04-20 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
451	6	\N	16	88	12	22	2018-12-07 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
452	6	\N	16	87	15	21	2018-12-10 16:10:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
453	6	\N	16	17	99	18	2018-12-08 16:00:00+00	FULL_TIME	4	0	\N	\N	\N	\N	\N	\N
454	6	\N	16	102	1	1	2018-12-10 15:55:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
455	6	\N	16	8	13	9	2018-12-08 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
456	6	\N	16	100	5	16	2018-12-09 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
457	6	\N	16	76	101	12	2018-12-09 19:05:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
458	6	\N	16	2	6	19	2018-12-11 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
459	6	\N	17	7	100	8	2019-02-26 16:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
460	6	\N	17	1	11	2	2019-02-22 16:07:00+00	FULL_TIME	1	3	\N	\N	\N	\N	\N	\N
461	6	\N	17	3	88	28	2018-12-14 14:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
462	6	\N	17	12	4	13	2018-12-14 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
463	6	\N	17	8	6	9	2018-12-16 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
464	6	\N	17	2	17	19	2018-12-17 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
465	6	\N	17	76	15	12	2018-12-16 16:00:00+00	FULL_TIME	3	2	\N	\N	\N	\N	\N	\N
466	6	\N	17	5	87	6	2018-12-15 16:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
467	6	\N	17	99	101	29	2018-12-16 14:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
468	6	\N	17	102	13	11	2018-12-15 16:00:00+00	FULL_TIME	5	1	\N	\N	\N	\N	\N	\N
469	6	\N	18	13	100	6	2018-12-28 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
470	6	\N	18	4	3	5	2018-12-28 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
471	6	\N	18	102	2	11	2018-12-28 14:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
472	6	\N	18	12	99	13	2018-12-28 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
473	6	\N	18	87	8	21	2018-12-29 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
474	6	\N	18	6	17	11	2018-12-29 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
475	6	\N	18	7	1	8	2018-12-29 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
476	6	\N	18	5	76	6	2018-12-29 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
477	6	\N	18	15	101	4	2018-12-29 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
478	6	\N	18	11	88	12	2018-12-29 19:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
479	6	\N	19	102	6	11	2019-01-01 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
480	6	\N	19	12	3	13	2019-01-02 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
481	6	\N	19	99	15	29	2019-01-02 16:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
482	6	\N	19	101	5	30	2019-01-02 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
483	6	\N	19	4	2	5	2019-01-02 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
484	6	\N	19	87	13	21	2019-01-02 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
485	6	\N	19	1	76	2	2019-04-29 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
486	6	\N	19	88	100	22	2019-01-02 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
487	6	\N	19	11	7	12	2019-05-16 16:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
488	6	\N	19	17	8	18	2019-01-03 16:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
489	6	\N	20	102	3	11	2019-01-07 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
490	6	\N	20	2	99	19	2019-01-05 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
491	6	\N	20	87	100	21	2019-01-05 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
492	6	\N	20	11	3	11	2019-04-30 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
493	6	\N	20	101	88	30	2019-01-06 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
494	6	\N	20	6	12	11	2019-01-06 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
495	6	\N	20	17	4	5	2019-01-06 16:00:00+00	FULL_TIME	4	0	\N	\N	\N	\N	\N	\N
496	6	\N	20	8	15	9	2019-01-07 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
497	6	\N	20	7	76	12	2019-04-17 14:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
498	6	\N	20	5	1	6	2019-04-14 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
499	6	\N	21	6	99	11	2019-01-10 16:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
500	6	\N	21	102	15	11	2019-01-11 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
501	6	\N	21	87	3	21	2019-01-12 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
502	6	\N	21	17	88	18	2019-01-11 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
503	6	\N	21	76	4	12	2019-04-11 16:00:00+00	FULL_TIME	3	2	\N	\N	\N	\N	\N	\N
504	6	\N	21	8	1	9	2019-04-18 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
505	6	\N	21	101	100	30	2019-01-13 16:00:00+00	FULL_TIME	3	2	\N	\N	\N	\N	\N	\N
506	6	\N	21	2	12	19	2019-01-13 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
507	6	\N	21	13	7	6	2019-01-08 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
508	6	\N	21	5	11	6	2019-05-03 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
509	6	\N	22	99	13	29	2019-01-15 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
510	6	\N	22	87	11	21	2019-02-26 16:00:00+00	FULL_TIME	1	3	\N	\N	\N	\N	\N	\N
511	6	\N	22	15	1	4	2019-01-16 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
512	6	\N	22	5	7	8	2019-01-14 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
513	6	\N	22	8	3	9	2019-01-16 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
514	6	\N	22	6	4	11	2019-01-16 16:00:00+00	FULL_TIME	3	2	\N	\N	\N	\N	\N	\N
515	6	\N	22	76	17	12	2019-01-15 19:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
516	6	\N	22	2	88	19	2019-01-16 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
517	6	\N	22	101	12	13	2019-01-16 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
518	6	\N	22	102	100	11	2019-01-17 16:00:00+00	FULL_TIME	5	2	\N	\N	\N	\N	\N	\N
519	6	\N	23	11	8	12	2019-05-19 16:03:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
520	6	\N	23	7	87	8	2019-01-19 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
521	6	\N	23	88	102	22	2019-04-10 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
522	6	\N	23	100	6	16	2019-01-19 14:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
523	6	\N	23	1	17	2	2019-01-19 19:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
524	6	\N	23	15	13	4	2019-01-20 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
525	6	\N	23	3	2	28	2019-01-20 16:12:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
526	6	\N	23	12	76	13	2019-01-19 16:07:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
527	6	\N	23	4	101	5	2019-01-20 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
528	6	\N	23	99	5	29	2019-01-20 14:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
529	6	\N	24	7	8	8	2019-01-31 14:01:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
530	6	\N	24	88	6	22	2019-01-31 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
531	6	\N	24	4	13	5	2019-02-01 16:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
532	6	\N	24	12	102	13	2019-02-01 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
533	6	\N	24	3	17	28	2019-02-01 16:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
534	6	\N	24	15	5	4	2019-02-01 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
535	6	\N	24	99	87	29	2019-02-02 18:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
536	6	\N	24	1	101	2	2019-01-25 19:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
537	6	\N	24	100	76	16	2019-02-03 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
538	6	\N	24	11	2	12	2019-03-31 16:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
539	6	\N	25	13	2	6	2019-02-06 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
540	6	\N	25	88	76	22	2019-02-06 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
541	6	\N	25	7	6	8	2019-02-08 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
542	6	\N	25	4	5	5	2019-02-06 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
543	6	\N	25	1	99	2	2019-02-06 19:30:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
544	6	\N	25	12	8	13	2019-02-06 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
545	6	\N	25	87	102	21	2019-02-06 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
546	6	\N	25	3	101	28	2019-02-06 16:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
547	6	\N	25	11	17	12	2019-02-07 19:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
548	6	\N	25	100	15	16	2019-02-07 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
549	6	\N	26	76	3	12	2019-02-10 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
550	6	\N	26	17	7	18	2019-02-11 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
551	6	\N	26	6	15	11	2019-02-11 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
552	6	\N	26	2	100	19	2019-02-11 14:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
553	6	\N	26	101	11	30	2019-04-27 16:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
554	6	\N	26	13	12	6	2019-02-11 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
555	6	\N	26	102	99	11	2019-02-10 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
556	6	\N	26	8	4	9	2019-02-11 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
557	6	\N	26	87	1	2	2019-02-11 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
558	6	\N	26	5	88	6	2019-02-27 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
559	6	\N	27	6	3	28	2019-03-05 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
560	6	\N	27	17	100	18	2019-02-14 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
561	6	\N	27	13	1	6	2019-02-14 14:10:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
562	6	\N	27	101	7	30	2019-02-14 16:05:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
563	6	\N	27	5	12	6	2019-02-15 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
564	6	\N	27	87	88	21	2019-02-17 16:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
565	6	\N	27	8	99	9	2019-02-15 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
566	6	\N	27	2	15	19	2019-02-15 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
567	6	\N	27	102	4	11	2019-02-15 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
568	6	\N	27	76	11	12	2019-02-16 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
569	6	\N	28	6	11	32	2019-02-19 16:07:00+00	FULL_TIME	0	3	\N	\N	\N	\N	\N	\N
570	6	\N	28	17	101	18	2019-02-19 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
571	6	\N	28	15	4	4	2019-02-19 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
572	6	\N	28	2	76	19	2019-02-20 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
573	6	\N	28	8	88	9	2019-02-20 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
574	6	\N	28	12	87	13	2019-02-20 16:00:00+00	FULL_TIME	3	2	\N	\N	\N	\N	\N	\N
575	6	\N	28	100	1	16	2019-02-19 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
576	6	\N	28	5	13	6	2019-02-20 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
577	6	\N	28	99	3	29	2019-02-21 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
578	6	\N	28	102	7	1	2019-02-20 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
579	6	\N	29	88	13	22	2019-03-03 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
580	6	\N	29	6	1	11	2019-03-01 16:00:00+00	FULL_TIME	1	3	\N	\N	\N	\N	\N	\N
581	6	\N	29	15	17	4	2019-03-02 16:00:00+00	FULL_TIME	6	2	\N	\N	\N	\N	\N	\N
582	6	\N	29	5	8	6	2019-03-03 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
583	6	\N	29	3	100	11	2019-03-02 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
584	6	\N	29	99	76	19	2019-03-02 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
585	6	\N	29	102	101	11	2019-03-02 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
586	6	\N	29	4	87	5	2019-03-03 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
587	6	\N	29	12	11	13	2019-03-03 16:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
588	6	\N	29	7	2	8	2019-03-03 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
589	6	\N	30	88	15	22	2019-03-07 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
590	6	\N	30	6	13	11	2019-03-09 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
591	6	\N	30	1	3	2	2019-03-08 19:00:00+00	FULL_TIME	6	1	\N	\N	\N	\N	\N	\N
592	6	\N	30	7	12	8	2019-03-09 14:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
593	6	\N	30	99	11	29	2019-04-23 16:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
594	6	\N	30	4	100	5	2019-03-09 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
595	6	\N	30	87	2	21	2019-03-09 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
596	6	\N	30	17	5	18	2019-03-10 16:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
597	6	\N	30	76	102	12	2019-03-10 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
598	6	\N	30	101	8	30	2019-03-11 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
599	6	\N	31	11	15	12	2019-03-19 19:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
600	6	\N	31	17	12	18	2019-03-15 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
601	6	\N	31	13	3	6	2019-03-15 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
602	6	\N	31	100	99	7	2019-03-16 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
603	6	\N	31	1	88	2	2019-03-15 19:00:00+00	FULL_TIME	4	0	\N	\N	\N	\N	\N	\N
604	6	\N	31	101	6	30	2019-03-16 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
605	6	\N	31	4	7	5	2019-03-16 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
606	6	\N	31	87	76	21	2019-03-16 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
607	6	\N	31	5	2	6	2019-03-16 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
608	6	\N	31	8	102	9	2019-03-17 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
609	6	\N	32	8	76	9	2019-04-04 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
610	6	\N	32	100	12	16	2019-04-03 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
611	6	\N	32	88	99	22	2019-04-03 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
612	6	\N	32	1	4	2	2019-04-02 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
613	6	\N	32	5	102	6	2019-04-02 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
614	6	\N	32	15	7	4	2019-04-03 14:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
615	6	\N	32	13	17	6	2019-04-03 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
616	6	\N	32	2	101	19	2019-04-03 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
617	6	\N	32	87	6	21	2019-04-03 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
618	6	\N	32	13	11	14	2019-05-05 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
619	6	\N	33	102	11	12	2019-04-25 16:03:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
620	6	\N	33	8	100	9	2019-04-07 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
621	6	\N	33	87	17	21	2019-04-06 16:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
622	6	\N	33	7	99	8	2019-04-06 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
623	6	\N	33	3	5	28	2019-04-06 14:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
624	6	\N	33	88	4	22	2019-04-06 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
625	6	\N	33	13	101	6	2019-04-06 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
626	6	\N	33	12	15	13	2019-04-07 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
627	6	\N	33	2	1	19	2019-04-07 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
628	6	\N	33	76	6	12	2019-04-08 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
629	6	\N	34	6	5	11	2019-05-18 16:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
630	6	\N	34	15	3	4	2019-05-03 16:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
631	6	\N	34	88	7	22	2019-05-03 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
632	6	\N	34	102	17	11	2019-05-06 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
633	6	\N	34	101	87	30	2019-04-30 16:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
634	6	\N	34	12	1	13	2019-05-06 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
635	6	\N	34	99	4	29	2019-05-03 16:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
636	6	\N	34	76	13	11	2019-05-02 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
637	6	\N	34	2	8	19	2019-05-04 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
638	6	\N	34	11	100	12	2019-05-08 16:05:00+00	FULL_TIME	8	1	\N	\N	\N	\N	\N	\N
639	6	\N	35	7	3	8	2019-05-08 16:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
640	6	\N	35	12	88	13	2019-05-09 16:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
641	6	\N	35	1	102	2	2019-05-09 20:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
642	6	\N	35	99	17	29	2019-05-09 16:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
643	6	\N	35	5	100	6	2019-05-15 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
644	6	\N	35	6	2	11	2019-05-09 16:00:00+00	FULL_TIME	2	3	\N	\N	\N	\N	\N	\N
645	6	\N	35	11	4	12	2019-05-10 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
646	6	\N	35	15	87	4	2019-05-09 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
647	6	\N	35	101	76	30	2019-05-10 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
648	6	\N	35	13	8	9	2019-05-08 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
649	6	\N	36	6	8	11	2019-05-12 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
650	6	\N	36	88	3	22	2019-05-12 16:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
651	6	\N	36	1	11	2	2019-05-13 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
652	6	\N	36	87	5	21	2019-05-12 16:00:00+00	FULL_TIME	0	3	\N	\N	\N	\N	\N	\N
653	6	\N	36	100	7	16	2019-05-12 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
654	6	\N	36	17	2	18	2019-05-14 16:00:00+00	FULL_TIME	3	3	\N	\N	\N	\N	\N	\N
655	6	\N	36	76	15	12	2019-05-14 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
656	6	\N	36	4	12	5	2019-05-16 16:00:00+00	FULL_TIME	1	3	\N	\N	\N	\N	\N	\N
657	6	\N	36	101	99	29	2019-05-15 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
658	6	\N	36	13	102	6	2019-05-13 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
659	6	\N	37	8	87	9	2019-05-22 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
660	6	\N	37	17	6	18	2019-05-22 16:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
661	6	\N	37	1	7	2	2019-05-22 20:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
662	6	\N	37	76	5	12	2019-05-22 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
663	6	\N	37	88	11	22	2019-05-21 16:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
664	6	\N	37	99	12	29	2019-05-23 16:00:00+00	FULL_TIME	3	2	\N	\N	\N	\N	\N	\N
665	6	\N	37	100	13	16	2019-05-23 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
666	6	\N	37	3	4	28	2019-05-25 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
667	6	\N	37	2	102	19	2019-05-21 16:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
668	6	\N	37	101	15	30	2019-05-20 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
669	6	\N	38	7	11	8	2019-05-28 15:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
670	6	\N	38	76	1	12	2019-05-28 16:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
671	6	\N	38	100	88	16	2019-05-28 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
672	6	\N	38	17	8	18	2019-05-28 16:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
673	6	\N	38	3	12	28	2019-05-28 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
674	6	\N	38	15	99	4	2019-05-28 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
675	6	\N	38	5	101	6	2019-05-28 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
676	6	\N	38	2	4	5	2019-05-28 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
677	6	\N	38	13	87	6	2019-05-28 16:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
678	6	\N	38	102	6	2	2019-05-28 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
679	9	\N	GROUP	40	23	26	2018-09-08 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
680	9	\N	GROUP	70	25	12	2017-06-09 22:00:00+00	FULL_TIME	1	3	\N	\N	\N	\N	\N	\N
681	9	\N	GROUP	89	29	12	2017-06-09 22:00:00+00	FULL_TIME	5	1	\N	\N	\N	\N	\N	\N
682	9	\N	GROUP	35	49	12	2017-06-10 22:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
683	9	\N	GROUP	37	34	12	2017-06-10 22:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
684	9	\N	GROUP	53	51	12	2017-06-10 22:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
685	9	\N	GROUP	36	59	12	2017-06-10 22:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
686	9	\N	GROUP	58	103	12	2017-06-10 22:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
687	9	\N	GROUP	39	32	12	2017-06-10 22:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
688	9	\N	GROUP	42	28	12	2017-06-10 22:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
689	9	\N	GROUP	71	62	12	2017-06-10 22:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
690	9	\N	GROUP	23	26	12	2017-06-10 22:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
691	9	\N	GROUP	61	60	12	2017-06-10 22:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
692	9	\N	GROUP	46	40	12	2017-06-10 22:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
693	9	\N	GROUP	48	43	12	2017-06-10 22:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
694	9	\N	GROUP	50	66	12	2017-06-10 22:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
695	9	\N	GROUP	52	63	12	2017-06-10 22:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
696	9	\N	GROUP	69	104	12	2017-06-10 22:00:00+00	FULL_TIME	2	3	\N	\N	\N	\N	\N	\N
697	9	\N	GROUP	105	27	12	2017-06-11 22:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
698	9	\N	GROUP	30	57	12	2017-06-11 22:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
699	9	\N	GROUP	44	38	12	2017-06-11 22:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
700	9	\N	GROUP	64	41	12	2017-06-11 22:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
701	9	\N	GROUP	33	55	12	2017-06-11 22:00:00+00	FULL_TIME	5	0	\N	\N	\N	\N	\N	\N
702	9	\N	GROUP	54	56	12	2017-06-11 22:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
703	9	\N	GROUP	65	24	12	2017-06-10 22:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
704	9	\N	GROUP	49	58	23	2018-09-08 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
705	9	\N	GROUP	29	39	23	2018-09-08 16:00:00+00	FULL_TIME	0	3	\N	\N	\N	\N	\N	\N
706	9	\N	GROUP	62	33	23	2018-09-08 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
707	9	\N	GROUP	32	89	23	2018-09-08 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
708	9	\N	GROUP	28	37	23	2018-09-08 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
709	9	\N	GROUP	66	53	23	2018-09-08 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
710	9	\N	GROUP	34	42	23	2018-09-08 16:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
711	9	\N	GROUP	63	70	23	2018-09-08 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
712	9	\N	GROUP	41	54	23	2018-09-08 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
713	9	\N	GROUP	59	48	23	2018-09-08 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
714	9	\N	GROUP	27	65	23	2018-09-08 16:00:00+00	FULL_TIME	6	0	\N	\N	\N	\N	\N	\N
715	9	\N	GROUP	103	35	23	2018-09-08 16:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
716	9	\N	GROUP	41	56	23	2018-09-09 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
717	9	\N	GROUP	25	52	23	2018-09-09 16:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
718	9	\N	GROUP	51	50	23	2018-09-09 16:00:00+00	FULL_TIME	0	3	\N	\N	\N	\N	\N	\N
719	9	\N	GROUP	55	71	23	2018-09-09 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
720	9	\N	GROUP	24	105	23	2018-09-09 16:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
721	9	\N	GROUP	26	46	23	2018-09-09 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
722	9	\N	GROUP	38	69	23	2018-09-09 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
723	9	\N	GROUP	60	30	23	2018-09-09 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
724	9	\N	GROUP	43	36	23	2018-09-09 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
725	9	\N	GROUP	57	61	23	2018-09-09 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
726	9	\N	GROUP	104	44	23	2018-09-09 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
727	9	\N	GROUP	56	64	23	2018-09-09 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
728	9	\N	GROUP	23	46	12	2018-10-16 17:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
729	9	\N	GROUP	55	62	23	2018-10-10 15:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
730	9	\N	GROUP	37	42	26	2018-10-10 17:30:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
731	9	\N	GROUP	60	57	27	2018-10-11 16:30:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
732	9	\N	GROUP	33	71	25	2018-10-11 18:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
733	9	\N	GROUP	41	64	25	2018-10-12 00:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
734	9	\N	GROUP	58	35	23	2018-10-12 16:30:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
735	9	\N	GROUP	43	59	25	2018-10-12 17:00:00+00	FULL_TIME	4	1	\N	\N	\N	\N	\N	\N
736	9	\N	GROUP	66	51	23	2018-10-12 17:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
737	9	\N	GROUP	39	89	26	2018-10-13 18:30:00+00	FULL_TIME	4	0	\N	\N	\N	\N	\N	\N
738	9	\N	GROUP	104	38	23	2018-10-12 18:30:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
739	9	\N	GROUP	27	24	27	2018-10-12 19:00:00+00	FULL_TIME	4	1	\N	\N	\N	\N	\N	\N
740	9	\N	GROUP	46	23	23	2018-10-12 20:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
741	9	\N	GROUP	69	44	26	2018-10-12 19:00:00+00	FULL_TIME	4	0	\N	\N	\N	\N	\N	\N
743	9	\N	GROUP	50	53	23	2018-10-12 21:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
744	9	\N	GROUP	56	41	26	2018-10-12 20:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
746	9	\N	GROUP	54	64	25	2018-10-12 21:45:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
747	9	\N	GROUP	63	25	23	2018-10-13 00:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
748	9	\N	GROUP	70	52	26	2018-10-16 20:30:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
749	9	\N	GROUP	24	27	27	2018-10-16 16:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
750	9	\N	GROUP	32	29	26	2018-10-13 00:00:00+00	FULL_TIME	6	0	\N	\N	\N	\N	\N	\N
751	9	\N	GROUP	65	105	27	2018-10-16 20:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
752	9	\N	GROUP	59	43	23	2018-10-16 20:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
753	9	\N	GROUP	36	48	25	2018-10-16 20:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
754	9	\N	GROUP	29	32	26	2018-10-16 16:30:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
755	9	\N	GROUP	64	54	26	2018-10-16 18:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
756	9	\N	GROUP	26	40	23	2018-10-16 19:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
757	9	\N	GROUP	57	60	25	2018-10-16 21:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
758	9	\N	GROUP	49	103	23	2018-10-16 15:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
760	9	\N	GROUP	30	61	27	2018-10-16 20:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
761	9	\N	GROUP	35	58	25	2018-10-16 16:30:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
762	9	\N	GROUP	38	104	25	2018-10-16 16:30:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
763	9	\N	GROUP	51	66	23	2018-10-16 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
764	9	\N	GROUP	44	69	23	2018-10-16 17:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
765	9	\N	GROUP	53	50	25	2018-10-16 20:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
766	9	\N	GROUP	28	34	23	2018-10-16 20:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
768	9	\N	GROUP	40	26	26	2018-10-13 15:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
769	9	\N	GROUP	34	28	26	2018-10-13 17:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
771	9	\N	GROUP	61	30	25	2018-10-13 19:30:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
772	9	\N	GROUP	48	36	23	2018-10-13 20:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
773	9	\N	GROUP	103	49	27	2018-10-13 20:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
774	9	\N	GROUP	105	65	25	2018-10-13 20:15:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
775	9	\N	GROUP	52	70	23	2018-10-13 21:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
776	9	\N	GROUP	62	55	27	2018-10-14 15:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
777	9	\N	GROUP	42	37	26	2018-10-14 18:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
778	9	\N	GROUP	71	33	26	2018-10-15 17:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
779	9	\N	GROUP	89	39	27	2018-10-16 21:00:00+00	FULL_TIME	2	3	\N	\N	\N	\N	\N	\N
780	9	\N	GROUP	41	56	25	2018-10-16 19:30:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
781	9	\N	GROUP	25	63	27	2018-10-16 14:30:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
782	9	\N	GROUP	103	58	25	2018-11-16 19:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
783	9	\N	GROUP	51	53	25	2018-11-16 19:00:00+00	FULL_TIME	2	5	\N	\N	\N	\N	\N	\N
784	9	\N	GROUP	27	105	27	2018-11-16 19:00:00+00	FULL_TIME	3	2	\N	\N	\N	\N	\N	\N
785	9	\N	GROUP	63	52	26	2018-11-16 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
786	9	\N	GROUP	49	35	23	2018-11-17 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
787	9	\N	GROUP	66	50	26	2018-11-17 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
788	9	\N	GROUP	41	64	25	2018-11-17 19:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
789	9	\N	GROUP	29	89	26	2018-11-17 16:00:00+00	FULL_TIME	1	8	\N	\N	\N	\N	\N	\N
790	9	\N	GROUP	32	39	23	2018-11-17 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
791	9	\N	GROUP	28	42	25	2018-11-17 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
792	9	\N	GROUP	40	46	25	2018-11-17 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
793	9	\N	GROUP	26	23	23	2018-11-18 17:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
794	9	\N	GROUP	25	70	27	2018-11-18 14:30:00+00	FULL_TIME	1	3	\N	\N	\N	\N	\N	\N
795	9	\N	GROUP	56	54	25	2018-11-18 19:00:00+00	FULL_TIME	1	4	\N	\N	\N	\N	\N	\N
796	9	\N	GROUP	55	33	26	2018-11-18 16:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
797	9	\N	GROUP	62	71	23	2018-11-18 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
798	9	\N	GROUP	60	61	27	2018-11-18 17:30:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
799	9	\N	GROUP	57	30	27	2018-11-18 19:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
800	9	\N	GROUP	38	44	27	2018-11-18 16:30:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
801	9	\N	GROUP	104	69	27	2018-11-18 20:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
802	9	\N	GROUP	43	48	27	2018-11-18 18:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
803	9	\N	GROUP	59	36	23	2018-11-18 20:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
804	9	\N	GROUP	24	65	25	2018-11-18 16:30:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
805	9	\N	GROUP	34	37	27	2018-11-18 16:30:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
806	10	\N	GROUP	108	109	34	2019-01-01 16:15:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
807	10	\N	GROUP	106	107	34	2019-01-02 16:15:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
808	10	\N	GROUP	1	110	34	2019-01-02 20:15:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
809	10	\N	GROUP	108	76	34	2019-01-03 20:21:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
810	10	\N	GROUP	110	109	34	2019-01-04 16:15:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
811	10	\N	GROUP	106	11	34	2019-01-04 20:25:00+00	FULL_TIME	1	4	\N	\N	\N	\N	\N	\N
812	10	\N	GROUP	107	72	34	2019-01-05 16:15:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
813	10	\N	GROUP	76	1	34	2019-01-05 20:15:00+00	FULL_TIME	0	3	\N	\N	\N	\N	\N	\N
814	10	\N	GROUP	110	108	34	2019-01-06 16:15:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
815	10	\N	GROUP	72	11	34	2019-01-06 20:15:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
816	10	\N	GROUP	1	108	34	2019-01-07 16:21:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
817	10	\N	GROUP	76	109	34	2019-01-07 20:15:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
818	10	\N	GROUP	72	106	34	2019-01-08 16:15:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
819	10	\N	GROUP	11	107	34	2019-01-08 20:15:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
820	10	\N	GROUP	76	110	34	2019-01-09 16:15:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
821	10	\N	GROUP	1	109	34	2019-01-09 20:21:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
822	11	\N	GROUP	112	113	23	2019-01-11 19:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
823	11	\N	GROUP	116	115	23	2019-01-11 19:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
824	11	\N	GROUP	120	119	23	2019-01-11 22:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
825	11	\N	GROUP	114	111	23	2019-01-11 22:00:00+00	FULL_TIME	5	2	\N	\N	\N	\N	\N	\N
826	11	\N	GROUP	118	117	23	2019-01-12 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
827	11	\N	GROUP	122	121	23	2019-01-12 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
828	11	\N	GROUP	11	124	23	2019-01-12 16:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
829	11	\N	GROUP	123	125	23	2019-01-12 20:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
830	11	\N	GROUP	121	120	23	2019-01-18 19:00:00+00	FULL_TIME	0	3	\N	\N	\N	\N	\N	\N
831	11	\N	GROUP	117	116	23	2019-01-18 19:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
832	11	\N	GROUP	115	118	23	2019-01-18 22:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
833	11	\N	GROUP	124	123	23	2019-01-18 22:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
834	11	\N	GROUP	125	11	23	2019-01-19 19:00:00+00	FULL_TIME	5	0	\N	\N	\N	\N	\N	\N
835	11	\N	GROUP	111	112	23	2019-01-19 19:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
836	11	\N	GROUP	119	122	23	2019-01-19 22:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
837	11	\N	GROUP	113	114	23	2019-01-19 22:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
838	10	\N	SEMI FINAL	1	72	34	2019-01-11 16:18:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
839	10	\N	SEMI FINAL	11	109	34	2019-01-11 20:20:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
840	10	\N	FINAL	1	11	34	2019-01-13 16:10:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
841	12	\N	QUARTER FINAL	88	127	12	2019-01-22 14:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
842	12	\N	QUARTER FINAL	76	128	12	2019-01-22 16:15:00+00	FULL_TIME	2	3	\N	\N	\N	\N	\N	\N
843	12	\N	QUARTER FINAL	2	74	12	2019-01-23 14:00:00+00	FULL_TIME	5	4	\N	\N	\N	\N	\N	\N
844	12	\N	QUARTER FINAL	11	126	12	2019-01-23 16:30:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
845	12	\N	SEMI FINAL	127	11	12	2019-01-25 14:05:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
846	12	\N	SEMI FINAL	2	128	12	2019-01-25 16:15:00+00	FULL_TIME	5	6	\N	\N	\N	\N	\N	\N
847	12	\N	FINAL	127	128	12	2019-01-27 16:15:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
848	11	\N	GROUP	121	119	23	2019-02-23 19:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
849	11	\N	GROUP	112	114	23	2019-02-02 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
850	11	\N	GROUP	113	111	23	2019-02-01 22:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
851	11	\N	GROUP	122	120	23	2019-02-02 16:00:00+00	FULL_TIME	8	0	\N	\N	\N	\N	\N	\N
852	11	\N	GROUP	125	124	23	2019-02-02 19:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
853	11	\N	GROUP	123	11	23	2019-02-02 22:00:00+00	FULL_TIME	5	0	\N	\N	\N	\N	\N	\N
854	11	\N	GROUP	117	115	23	2019-02-02 22:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
855	11	\N	GROUP	118	116	23	2019-02-02 19:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
856	11	\N	GROUP	11	123	12	2019-02-12 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
857	11	\N	GROUP	115	117	23	2019-02-12 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
858	11	\N	GROUP	116	118	23	2019-02-12 19:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
859	11	\N	GROUP	120	122	23	2019-02-12 19:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
860	11	\N	GROUP	111	113	23	2019-02-12 19:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
861	11	\N	GROUP	114	112	23	2019-02-12 22:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
862	11	\N	GROUP	124	125	23	2019-02-12 22:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
863	11	\N	GROUP	119	120	23	2019-03-08 19:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
864	11	\N	GROUP	121	122	23	2019-03-08 19:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
865	11	\N	GROUP	115	116	23	2019-03-08 22:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
866	11	\N	GROUP	117	118	23	2019-03-08 22:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
867	11	\N	GROUP	125	123	23	2019-03-09 19:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
868	11	\N	GROUP	111	114	23	2019-03-09 19:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
869	11	\N	GROUP	124	11	23	2019-03-09 22:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
870	11	\N	GROUP	113	112	23	2019-03-09 22:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
871	11	\N	GROUP	119	121	23	2019-03-02 22:00:00+00	FULL_TIME	3	2	\N	\N	\N	\N	\N	\N
872	11	\N	GROUP	118	115	23	2019-03-16 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
873	11	\N	GROUP	122	119	23	2019-03-16 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
874	11	\N	GROUP	120	121	23	2019-03-16 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
875	11	\N	GROUP	123	124	23	2019-03-16 19:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
876	11	\N	GROUP	112	111	23	2019-03-16 19:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
877	11	\N	GROUP	114	113	23	2019-03-16 19:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
878	11	\N	GROUP	116	117	23	2019-03-16 19:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
879	11	\N	GROUP	11	125	23	2019-03-16 19:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
880	9	\N	GROUP	105	24	23	2019-03-22 21:15:00+00	FULL_TIME	4	0	\N	\N	\N	\N	\N	\N
881	9	\N	GROUP	54	41	23	2019-03-22 22:45:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
882	9	\N	GROUP	53	66	23	2019-03-23 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
883	9	\N	GROUP	58	49	23	2019-03-23 18:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
884	9	\N	GROUP	65	27	23	2019-03-23 18:30:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
885	9	\N	GROUP	42	34	23	2019-03-23 19:30:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
886	9	\N	GROUP	37	28	23	2019-03-23 19:30:00+00	FULL_TIME	4	1	\N	\N	\N	\N	\N	\N
887	9	\N	GROUP	69	38	23	2019-03-23 20:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
888	9	\N	GROUP	33	62	23	2019-03-23 21:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
889	9	\N	GROUP	50	51	23	2019-03-23 22:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
890	9	\N	GROUP	52	25	23	2019-03-23 20:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
891	9	\N	GROUP	61	57	23	2019-03-24 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
892	9	\N	GROUP	30	60	23	2019-03-24 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
893	9	\N	GROUP	44	104	23	2019-03-24 17:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
894	9	\N	GROUP	23	40	12	2019-03-24 18:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
895	9	\N	GROUP	46	26	23	2019-03-24 18:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
896	9	\N	GROUP	64	56	23	2019-03-24 18:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
897	9	\N	GROUP	89	32	23	2019-03-24 20:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
898	11	\N	QUARTER FINAL	11	122	12	2019-04-06 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
899	11	\N	QUARTER FINAL	113	123	23	2019-04-06 16:00:00+00	FULL_TIME	5	0	\N	\N	\N	\N	\N	\N
900	11	\N	QUARTER FINAL	116	114	23	2019-04-06 19:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
901	11	\N	QUARTER FINAL	119	115	23	2019-04-06 16:00:00+00	FULL_TIME	2	3	\N	\N	\N	\N	\N	\N
902	11	\N	QUARTER FINAL	122	11	23	2019-04-13 16:00:00+00	FULL_TIME	4	1	\N	\N	\N	\N	\N	\N
903	11	\N	QUARTER FINAL	123	113	23	2019-04-13 19:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
904	11	\N	SEMI FINAL	114	113	23	2019-04-26 22:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
905	11	\N	QUARTER FINAL	115	122	23	2019-04-27 19:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
906	13	\N	GROUP	131	130	12	2019-04-14 16:00:00+00	FULL_TIME	4	5	\N	\N	\N	\N	\N	\N
907	13	\N	GROUP	129	132	12	2019-04-14 19:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
908	13	\N	GROUP	134	133	12	2019-04-15 14:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
909	13	\N	GROUP	135	136	12	2019-04-15 17:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
910	13	\N	GROUP	130	129	12	2019-04-17 14:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
911	13	\N	GROUP	132	131	12	2019-04-17 17:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
912	13	\N	GROUP	133	135	12	2019-04-18 14:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
913	13	\N	GROUP	136	134	12	2019-04-18 17:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
914	13	\N	GROUP	130	132	12	2019-04-20 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
915	13	\N	GROUP	131	129	12	2019-04-20 16:00:00+00	FULL_TIME	2	4	\N	\N	\N	\N	\N	\N
916	13	\N	GROUP	133	136	12	2019-04-21 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
917	13	\N	GROUP	134	135	12	2019-04-21 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
918	13	\N	SEMI FINAL	130	134	12	2019-04-24 16:00:00+00	FULL_TIME	9	10	\N	\N	\N	\N	\N	\N
919	13	\N	SEMI FINAL	133	129	12	2019-04-24 19:00:00+00	FULL_TIME	4	3	\N	\N	\N	\N	\N	\N
920	13	\N	KNOCKOUT	130	129	12	2019-04-27 04:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
921	13	\N	FINAL	133	134	12	2019-04-28 04:00:00+00	FULL_TIME	5	3	\N	\N	\N	\N	\N	\N
922	11	\N	SEMI FINAL	122	115	26	2019-05-04 04:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
923	11	\N	SEMI FINAL	113	114	26	2019-05-04 19:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
924	7	\N	SEMI FINAL	1	102	2	2019-05-03 19:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
925	11	\N	FINAL	114	115	26	2019-05-25 01:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
926	11	\N	FINAL	115	114	27	2018-06-01 00:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
927	7	\N	SEMI FINAL	87	76	21	2019-05-06 15:30:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
928	14	\N	GROUP	27	30	26	2019-06-21 23:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
929	14	\N	GROUP	61	40	27	2019-06-22 17:30:00+00	FULL_TIME	0	3	\N	\N	\N	\N	\N	\N
930	14	\N	GROUP	39	53	27	2019-06-22 20:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
931	14	\N	GROUP	104	25	23	2019-06-22 23:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
932	14	\N	GROUP	103	28	27	2019-06-23 17:30:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
933	14	\N	GROUP	52	91	23	2019-06-23 20:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
934	14	\N	GROUP	54	62	26	2019-06-23 23:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
935	14	\N	GROUP	69	32	27	2019-06-24 17:30:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
936	14	\N	GROUP	105	43	23	2019-06-24 20:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
937	14	\N	GROUP	50	59	23	2019-06-24 23:00:00+00	FULL_TIME	4	3	\N	\N	\N	\N	\N	\N
938	14	\N	GROUP	58	42	26	2019-06-25 20:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
939	14	\N	GROUP	33	64	27	2019-06-25 23:00:00+00	FULL_TIME	2	6	\N	\N	\N	\N	\N	\N
940	14	\N	GROUP	39	104	27	2019-06-26 17:30:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
941	15	\N	FINAL	11	165	12	2019-05-23 19:00:00+00	FULL_TIME	4	5	\N	\N	\N	\N	\N	\N
942	16	\N	FINAL	166	167	23	2019-05-26 23:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
943	14	\N	GROUP	40	30	26	2019-06-26 20:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
944	14	\N	GROUP	27	61	26	2019-06-26 23:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
945	14	\N	GROUP	25	53	26	2019-06-27 17:30:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
946	14	\N	GROUP	52	54	26	2019-06-27 20:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
947	14	\N	GROUP	62	91	26	2019-06-27 23:00:00+00	FULL_TIME	3	2	\N	\N	\N	\N	\N	\N
948	14	\N	GROUP	105	50	26	2019-06-28 17:30:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
949	14	\N	GROUP	103	69	26	2019-06-28 20:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
950	14	\N	GROUP	32	28	26	2019-06-28 23:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
951	14	\N	GROUP	59	43	27	2019-06-29 17:30:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
952	14	\N	GROUP	58	33	27	2019-06-29 20:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
953	14	\N	GROUP	64	42	23	2019-06-29 23:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
954	14	\N	GROUP	53	104	23	2019-06-30 19:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
955	14	\N	GROUP	25	39	27	2019-06-30 19:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
956	14	\N	GROUP	30	61	27	2019-06-30 22:00:00+00	FULL_TIME	0	4	\N	\N	\N	\N	\N	\N
957	14	\N	GROUP	40	27	27	2019-06-30 22:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
958	14	\N	GROUP	28	69	27	2019-07-01 19:00:00+00	FULL_TIME	1	4	\N	\N	\N	\N	\N	\N
959	14	\N	GROUP	32	103	27	2019-07-01 19:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
960	14	\N	GROUP	91	54	26	2019-07-01 22:00:00+00	FULL_TIME	0	3	\N	\N	\N	\N	\N	\N
961	14	\N	GROUP	62	52	23	2019-07-01 22:00:00+00	FULL_TIME	0	3	\N	\N	\N	\N	\N	\N
962	14	\N	GROUP	64	58	23	2019-07-02 19:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
963	14	\N	GROUP	42	33	23	2019-07-02 19:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
964	14	\N	GROUP	43	50	26	2019-07-02 22:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
965	14	\N	GROUP	59	105	26	2019-07-02 22:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
966	14	\N	KNOCKOUT	103	64	27	2019-07-05 19:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
967	14	\N	KNOCKOUT	40	52	27	2019-07-05 22:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
968	14	\N	KNOCKOUT	39	58	23	2019-07-06 19:00:00+00	FULL_TIME	3	2	\N	\N	\N	\N	\N	\N
969	14	\N	KNOCKOUT	27	32	23	2019-07-06 22:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
970	14	\N	KNOCKOUT	25	61	23	2019-07-07 19:00:00+00	FULL_TIME	3	2	\N	\N	\N	\N	\N	\N
971	14	\N	KNOCKOUT	54	104	27	2019-07-07 22:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
972	14	\N	KNOCKOUT	50	69	23	2019-07-08 19:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
973	14	\N	KNOCKOUT	33	105	23	2019-07-08 22:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
974	14	\N	QUARTER FINAL	52	64	23	2019-07-10 19:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
975	14	\N	QUARTER FINAL	39	32	26	2019-07-10 22:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
976	14	\N	QUARTER FINAL	69	54	23	2019-07-11 19:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
977	14	\N	QUARTER FINAL	25	105	27	2019-07-11 22:00:00+00	FULL_TIME	0	3	\N	\N	\N	\N	\N	\N
978	17	\N	1	3	11	11	2019-08-29 16:00:00+00	FULL_TIME	1	3	\N	\N	\N	\N	\N	\N
979	17	\N	1	2	99	19	2019-08-24 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
980	14	\N	SEMI FINAL	52	105	27	2019-07-14 19:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
981	14	\N	SEMI FINAL	54	39	27	2019-07-14 22:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
982	18	\N	GROUP	122	1	19	2019-07-16 18:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
983	14	\N	KNOCKOUT	105	39	26	2019-07-17 22:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
984	14	\N	FINAL	52	54	23	2019-07-19 22:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
985	18	\N	KNOCKOUT	122	1	28	2019-07-16 14:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
986	15	\N	FINAL	117	11	26	2019-07-30 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
987	19	\N	KNOCKOUT	189	11	12	2019-08-06 18:23:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
988	17	\N	1	5	13	6	2019-08-24 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
989	17	\N	1	168	8	9	2019-08-24 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
990	17	\N	1	169	100	1	2019-08-24 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
991	17	\N	1	101	4	5	2019-08-24 16:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
992	17	\N	1	17	88	18	2019-08-25 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
993	17	\N	1	87	7	4	2019-08-25 16:20:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
994	17	\N	1	76	15	12	2019-08-28 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
995	17	\N	1	102	1	11	2019-08-27 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
996	17	\N	2	168	88	30	2019-09-14 16:10:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
997	17	\N	2	3	87	28	2019-09-14 16:04:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
998	17	\N	2	2	101	19	2019-09-14 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
999	17	\N	2	8	17	9	2019-09-15 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1000	17	\N	2	13	15	6	2019-09-15 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1001	17	\N	2	99	4	29	2019-09-15 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
1002	17	\N	2	11	7	12	2019-09-13 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1003	17	\N	2	5	76	6	2019-09-18 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1004	17	\N	2	169	1	37	2019-09-18 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1005	17	\N	2	100	102	7	2019-09-13 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1006	17	\N	3	168	17	40	2019-09-21 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1007	17	\N	3	13	76	6	2019-09-21 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1008	20	\N	FINAL	1	11	12	2019-08-17 19:00:00+00	FULL_TIME	2	4	\N	\N	\N	\N	\N	\N
1009	21	\N	1	74	187	24	2019-08-31 16:20:00+00	FULL_TIME	5	2	\N	\N	\N	\N	\N	\N
1010	21	\N	1	176	126	24	2019-09-01 15:01:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1011	21	\N	1	186	175	24	2019-09-01 15:03:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
1012	21	\N	1	170	180	24	2019-08-30 15:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
1013	21	\N	1	184	181	24	2019-08-31 14:04:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
1014	21	\N	1	171	127	24	2019-08-31 15:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1015	21	\N	1	182	177	24	2019-08-31 15:08:00+00	FULL_TIME	0	3	\N	\N	\N	\N	\N	\N
1016	21	\N	1	183	179	24	2019-08-31 13:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1017	21	\N	1	128	185	24	2019-08-30 15:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
1018	21	\N	2	187	171	24	2019-09-14 14:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1019	21	\N	2	185	183	24	2019-09-14 15:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1020	21	\N	2	181	170	24	2019-09-14 15:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1021	21	\N	2	177	184	24	2019-09-15 15:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1022	21	\N	2	179	182	24	2019-09-14 13:08:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
1023	21	\N	2	175	74	24	2019-09-14 15:00:00+00	POSTPONED	\N	\N	\N	\N	\N	\N	\N	\N
1024	21	\N	2	127	186	24	2019-09-14 15:00:00+00	FULL_TIME	3	2	\N	\N	\N	\N	\N	\N
1025	21	\N	2	180	176	24	2019-09-14 16:17:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1026	21	\N	2	126	128	24	2019-09-15 16:15:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1027	22	\N	KNOCKOUT	102	188	12	2019-08-23 15:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
1028	19	\N	KNOCKOUT	11	189	12	2019-08-25 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1029	19	\N	KNOCKOUT	74	190	24	2019-08-25 16:00:00+00	FULL_TIME	5	1	\N	\N	\N	\N	\N	\N
1030	19	\N	KNOCKOUT	191	192	26	2019-08-25 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1031	19	\N	KNOCKOUT	76	193	12	2019-09-14 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1032	19	\N	KNOCKOUT	97	74	24	2019-09-14 19:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1033	19	\N	KNOCKOUT	194	189	26	2019-09-14 16:10:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1034	19	\N	KNOCKOUT	195	196	26	2019-09-14 18:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1035	17	\N	38	99	168	29	2020-05-24 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1036	17	\N	38	2	8	19	2020-05-24 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1037	17	\N	38	102	5	11	2020-05-24 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1038	17	\N	38	88	101	22	2020-05-24 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1039	17	\N	38	17	4	18	2020-05-24 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1040	17	\N	38	169	11	37	2020-05-24 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1041	17	\N	38	100	3	16	2020-05-24 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1042	17	\N	38	7	15	10	2020-05-24 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1043	17	\N	38	13	1	6	2020-05-24 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1044	17	\N	38	87	76	21	2020-05-24 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1045	17	\N	37	2	168	19	2020-05-20 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1046	17	\N	37	88	4	22	2020-05-20 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1047	17	\N	37	17	101	18	2020-05-20 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1048	17	\N	37	7	76	10	2020-05-20 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1049	17	\N	37	87	15	21	2020-05-20 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1050	17	\N	37	102	13	11	2020-05-20 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1051	17	\N	37	169	3	37	2020-05-20 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1052	17	\N	37	1	5	2	2020-05-20 19:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1053	17	\N	37	99	8	29	2020-05-21 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1054	17	\N	37	100	11	16	2020-05-21 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1055	17	\N	3	3	7	28	2019-09-21 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1056	17	\N	3	99	101	29	2019-09-20 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1057	17	\N	3	169	102	37	2019-09-22 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1058	17	\N	3	100	1	16	2019-09-21 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1059	17	\N	3	8	88	9	2019-09-21 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1060	17	\N	3	5	15	6	2019-09-21 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1061	17	\N	3	11	87	11	2019-09-22 16:00:00+00	FULL_TIME	4	0	\N	\N	\N	\N	\N	\N
1062	17	\N	3	2	4	29	2019-09-21 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1063	17	\N	4	88	2	22	2019-09-25 16:10:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1064	17	\N	5	88	99	22	2019-09-28 16:10:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1065	17	\N	6	100	17	16	2019-10-20 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1066	17	\N	7	100	88	16	2019-10-23 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1067	17	\N	4	17	99	18	2019-09-25 16:30:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1068	17	\N	4	15	100	28	2019-09-25 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1069	17	\N	8	101	168	30	2019-10-27 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1070	17	\N	9	15	102	4	2019-10-30 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1071	17	\N	10	100	2	16	2019-11-03 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
1072	17	\N	11	168	15	40	2019-11-06 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1073	17	\N	12	13	17	6	2019-11-22 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1074	17	\N	13	5	17	6	2019-11-26 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
1075	17	\N	14	3	168	28	2019-12-29 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1076	17	\N	15	3	8	28	2020-01-03 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1077	17	\N	16	5	168	6	2020-01-08 16:00:00+00	FULL_TIME	2	3	\N	\N	\N	\N	\N	\N
1078	17	\N	17	5	8	6	2020-01-11 16:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
1079	17	\N	18	3	169	28	2020-01-30 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1080	17	\N	19	11	169	11	2020-02-04 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1081	17	\N	20	11	3	11	2020-02-08 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1082	17	\N	21	88	168	22	2020-02-11 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1083	17	\N	22	17	168	18	2020-02-15 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1084	17	\N	23	2	88	19	2020-02-18 16:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
1085	17	\N	24	99	88	29	2020-02-23 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1086	17	\N	25	17	100	18	2020-02-29 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1087	17	\N	26	88	100	22	2020-03-04 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1088	17	\N	27	169	168	37	2020-03-07 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1089	17	\N	28	3	17	28	2020-03-10 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1090	17	\N	29	100	168	3	2020-04-14 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1091	17	\N	30	13	2	6	2020-04-17 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1092	17	\N	31	11	15	11	2020-04-10 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1093	17	\N	32	88	13	22	2020-04-15 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1094	17	\N	33	168	3	40	2020-04-19 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1095	17	\N	34	2	7	19	2020-05-08 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1096	17	\N	35	168	5	40	2019-05-13 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1097	17	\N	36	168	13	40	2020-05-16 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1098	17	\N	36	8	5	40	2020-05-16 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1099	17	\N	36	15	7	4	2020-05-16 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1100	17	\N	36	3	2	11	2020-05-16 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1101	17	\N	36	101	100	30	2020-05-16 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1102	17	\N	36	4	169	5	2020-05-16 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1103	17	\N	36	87	1	21	2020-05-16 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1104	17	\N	36	11	99	11	2020-05-16 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1105	17	\N	36	76	17	11	2020-05-17 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1106	17	\N	36	7	102	10	2020-05-16 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1107	17	\N	35	15	17	4	2020-05-13 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1108	17	\N	35	3	99	28	2020-05-13 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1109	17	\N	35	4	100	5	2020-05-13 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1110	17	\N	35	101	169	30	2020-05-13 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1111	17	\N	35	8	13	9	2020-05-13 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1112	17	\N	35	11	2	11	2020-05-13 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1113	17	\N	35	87	102	21	2020-05-13 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1114	17	\N	35	76	88	11	2020-05-14 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1115	17	\N	35	7	1	10	2020-05-13 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1116	17	\N	34	13	100	6	2020-05-09 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1117	17	\N	34	8	3	9	2020-05-09 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1118	17	\N	34	168	11	40	2020-05-09 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1119	17	\N	34	99	87	29	2020-05-09 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1120	17	\N	34	5	169	6	2019-08-09 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1121	17	\N	34	101	15	30	2020-05-09 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1122	17	\N	34	102	88	11	2020-05-09 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1123	17	\N	34	1	17	2	2019-08-09 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1124	17	\N	34	4	76	5	2019-08-10 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1125	17	\N	4	7	13	10	2019-09-25 16:00:00+00	FULL_TIME	1	3	\N	\N	\N	\N	\N	\N
1126	17	\N	4	101	3	30	2019-09-25 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1127	17	\N	4	87	5	21	2019-09-26 16:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
1128	17	\N	4	76	169	11	2019-10-03 16:00:00+00	FULL_TIME	3	3	\N	\N	\N	\N	\N	\N
1129	17	\N	4	1	8	2	2019-10-02 19:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1130	17	\N	4	102	168	2	2019-09-25 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1131	17	\N	4	4	11	5	2019-09-26 16:00:00+00	FULL_TIME	0	3	\N	\N	\N	\N	\N	\N
1132	17	\N	5	17	2	18	2019-09-28 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1133	17	\N	5	15	169	4	2019-09-28 16:08:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1134	17	\N	5	87	13	21	2019-09-29 16:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
1135	17	\N	5	7	5	10	2019-09-29 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1136	17	\N	5	4	3	51	2019-09-29 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1137	17	\N	5	76	100	11	2019-10-06 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1138	17	\N	5	1	168	2	2019-10-05 19:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1139	17	\N	5	101	11	30	2019-09-29 16:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
1140	17	\N	5	102	8	11	2019-09-29 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1141	17	\N	6	169	88	37	2019-10-20 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1142	17	\N	6	13	4	6	2019-10-19 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1143	17	\N	6	2	15	19	2019-10-19 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1144	17	\N	6	168	87	40	2019-10-19 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1145	17	\N	6	8	7	9	2019-10-19 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1146	17	\N	6	102	11	11	2019-10-19 16:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
1147	17	\N	6	1	3	2	2019-12-01 16:02:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
1148	17	\N	6	5	101	14	2019-10-20 16:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
1149	17	\N	6	99	76	19	2019-11-29 16:30:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
1150	17	\N	7	169	17	37	2019-10-23 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1151	17	\N	7	13	101	6	2019-10-23 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1152	17	\N	7	99	15	29	2019-10-23 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1153	17	\N	7	168	7	40	2019-10-23 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1154	17	\N	7	3	102	28	2019-10-22 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1155	17	\N	7	8	87	9	2019-10-23 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1156	17	\N	7	11	1	1	2019-10-23 17:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1157	17	\N	7	5	4	6	2019-10-24 16:00:00+00	FULL_TIME	1	4	\N	\N	\N	\N	\N	\N
1158	17	\N	7	2	76	19	2019-10-22 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1159	17	\N	8	7	169	10	2019-10-26 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1160	17	\N	8	87	100	21	2019-10-27 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1161	17	\N	8	17	3	18	2019-10-27 16:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
1162	17	\N	8	4	8	5	2019-11-29 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1163	17	\N	8	2	5	19	2019-10-28 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
1164	17	\N	8	99	13	29	2019-10-28 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1165	17	\N	8	76	102	11	2019-12-02 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1166	17	\N	8	15	1	4	2019-10-27 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1167	17	\N	8	88	11	22	2019-10-27 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1168	17	\N	9	88	3	22	2019-10-30 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
1169	17	\N	9	17	11	13	2019-10-30 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1170	17	\N	9	4	168	5	2019-10-30 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1171	17	\N	9	7	100	10	2019-10-30 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1172	17	\N	9	87	169	21	2019-10-30 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1173	17	\N	9	99	5	29	2019-10-31 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1174	17	\N	9	2	13	4	2019-10-31 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1175	17	\N	9	1	76	11	2020-01-18 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1176	17	\N	9	101	8	13	2019-12-02 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1177	17	\N	10	7	88	8	2019-11-02 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1178	17	\N	10	87	17	21	2019-11-02 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1179	17	\N	10	8	15	9	2019-11-03 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1180	17	\N	10	11	5	11	2019-11-03 16:00:00+00	FULL_TIME	4	0	\N	\N	\N	\N	\N	\N
1181	17	\N	10	169	99	37	2019-11-03 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1182	17	\N	10	102	101	11	2019-11-04 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1183	17	\N	10	3	13	28	2019-11-03 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1184	17	\N	10	1	4	2	2019-11-04 19:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1185	17	\N	10	168	76	40	2020-03-15 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1186	17	\N	11	100	99	16	2019-11-06 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1187	17	\N	11	169	2	37	2019-11-06 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1188	17	\N	11	3	5	28	2019-11-06 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1189	17	\N	11	7	17	10	2019-11-06 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1190	17	\N	11	87	88	21	2019-11-06 16:00:00+00	FULL_TIME	5	1	\N	\N	\N	\N	\N	\N
1191	17	\N	11	11	13	11	2019-11-07 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1192	17	\N	11	1	101	2	2019-11-08 19:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1193	17	\N	11	8	76	9	2019-11-08 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1194	17	\N	11	102	4	11	2019-11-08 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
1195	17	\N	12	76	3	11	2019-11-22 16:00:00+00	FULL_TIME	3	2	\N	\N	\N	\N	\N	\N
1196	17	\N	12	2	1	19	2019-11-23 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1197	17	\N	12	168	100	40	2019-11-22 16:00:00+00	FULL_TIME	1	3	\N	\N	\N	\N	\N	\N
1198	17	\N	12	8	169	9	2019-11-22 16:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
1199	17	\N	12	4	87	5	2019-11-22 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1200	17	\N	12	101	7	30	2019-11-23 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1201	17	\N	12	5	88	6	2019-11-23 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1202	17	\N	12	15	11	11	2019-11-23 16:00:00+00	FULL_TIME	0	3	\N	\N	\N	\N	\N	\N
1203	17	\N	12	99	102	29	2019-11-22 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1204	17	\N	13	2	102	29	2019-11-26 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1205	17	\N	13	13	88	6	2019-11-25 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1206	17	\N	13	3	15	28	2019-11-26 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1207	17	\N	13	168	169	40	2019-11-25 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1208	17	\N	13	8	100	9	2019-11-25 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1209	17	\N	13	4	7	5	2019-11-26 16:00:00+00	FULL_TIME	1	3	\N	\N	\N	\N	\N	\N
1210	17	\N	13	101	87	30	2019-11-26 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1211	17	\N	13	99	1	19	2019-11-26 16:00:00+00	FULL_TIME	0	5	\N	\N	\N	\N	\N	\N
1212	17	\N	13	11	76	12	2020-01-04 17:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
1213	17	\N	14	7	99	10	2019-12-30 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1214	17	\N	14	87	2	21	2019-12-30 16:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
1215	17	\N	14	100	5	16	2019-12-30 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1216	17	\N	14	169	13	37	2019-12-30 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1217	17	\N	14	15	4	4	2019-12-30 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1218	17	\N	14	17	102	13	2019-12-30 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1219	17	\N	14	76	101	11	2019-12-30 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1220	17	\N	14	11	8	11	2019-12-31 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1221	17	\N	14	88	1	22	2020-01-01 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
1222	17	\N	15	7	2	10	2020-01-03 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1223	17	\N	15	87	99	21	2020-01-03 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1224	17	\N	15	100	13	16	2020-01-03 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1225	17	\N	15	169	5	37	2020-01-03 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1226	17	\N	15	15	101	4	2020-01-03 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1227	17	\N	15	88	102	22	2020-01-05 16:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
1228	17	\N	15	76	4	18	2020-01-15 16:00:00+00	FULL_TIME	0	3	\N	\N	\N	\N	\N	\N
1229	17	\N	15	11	168	11	2020-01-29 16:00:00+00	FULL_TIME	3	2	\N	\N	\N	\N	\N	\N
1230	17	\N	15	17	1	18	2020-01-22 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1231	17	\N	16	99	3	29	2020-01-08 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1232	17	\N	16	17	15	18	2020-01-08 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1233	17	\N	16	100	4	16	2020-01-08 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1234	17	\N	16	169	101	37	2020-01-08 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1235	17	\N	16	13	8	6	2020-01-09 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1236	17	\N	16	88	76	22	2020-01-22 16:00:00+00	FULL_TIME	1	3	\N	\N	\N	\N	\N	\N
1237	17	\N	16	102	87	11	2020-01-08 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1238	17	\N	16	1	7	2	2020-01-15 19:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1239	17	\N	16	2	11	19	2020-01-16 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
1240	17	\N	17	17	76	13	2020-04-30 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1241	17	\N	17	88	15	22	2020-01-11 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1242	17	\N	17	100	101	16	2020-01-11 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1243	17	\N	17	169	4	37	2020-01-11 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1244	17	\N	17	13	168	6	2020-01-12 16:00:00+00	FULL_TIME	2	3	\N	\N	\N	\N	\N	\N
1245	17	\N	17	102	7	11	2020-01-17 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1246	17	\N	17	99	11	19	2020-01-19 16:00:00+00	FULL_TIME	1	4	\N	\N	\N	\N	\N	\N
1247	17	\N	17	1	87	2	2020-01-15 19:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1248	17	\N	17	2	3	19	2020-01-11 16:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
1249	17	\N	18	168	2	40	2020-02-01 16:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
1250	17	\N	18	8	99	9	2020-02-01 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1251	17	\N	18	4	88	5	2020-02-01 16:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
1252	17	\N	18	101	15	30	2020-02-01 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1253	17	\N	18	15	87	4	2020-02-01 16:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
1254	17	\N	18	13	102	6	2020-02-01 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1255	17	\N	18	11	100	11	2020-02-01 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1256	17	\N	18	5	1	6	2020-02-02 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1257	17	\N	18	76	7	11	2020-02-02 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1258	17	\N	19	168	99	40	2020-02-05 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1259	17	\N	19	8	2	9	2020-02-05 16:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
1260	17	\N	19	5	102	6	2020-02-05 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1261	17	\N	19	101	88	30	2020-02-05 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1262	17	\N	19	4	17	5	2020-02-05 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1263	17	\N	19	3	100	28	2020-02-05 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1264	17	\N	19	15	7	4	2020-02-05 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1265	17	\N	19	1	13	2	2020-02-05 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1266	17	\N	19	76	87	11	2020-02-05 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1267	17	\N	20	99	2	29	2020-02-08 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1268	17	\N	20	13	5	6	2020-02-08 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1269	17	\N	20	8	168	9	2020-02-08 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1270	17	\N	20	100	169	16	2020-02-08 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1271	17	\N	20	4	101	5	2020-02-08 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1272	17	\N	20	88	17	22	2020-02-08 16:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
1273	17	\N	20	7	87	10	2020-02-08 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1274	17	\N	20	1	102	2	2020-02-08 19:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
1275	17	\N	20	15	76	11	2020-02-09 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1276	17	\N	21	87	3	21	2020-02-11 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1277	17	\N	21	17	8	18	2020-02-11 16:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
1278	17	\N	21	15	13	4	2020-02-12 16:00:00+00	FULL_TIME	0	3	\N	\N	\N	\N	\N	\N
1279	17	\N	21	4	99	5	2020-02-11 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
1280	17	\N	21	101	2	30	2020-02-11 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1281	17	\N	21	102	100	11	2020-02-12 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1282	17	\N	21	1	169	2	2020-02-11 19:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1283	17	\N	21	7	11	10	2020-02-11 16:00:00+00	FULL_TIME	0	3	\N	\N	\N	\N	\N	\N
1284	17	\N	21	76	5	11	2020-02-11 19:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1285	17	\N	22	7	3	10	2020-02-15 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1286	17	\N	22	101	99	30	2020-02-15 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1287	17	\N	22	88	8	22	2020-02-15 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1288	17	\N	22	15	5	4	2020-02-15 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1289	17	\N	22	4	2	5	2020-02-15 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1290	17	\N	22	102	169	11	2020-02-15 14:00:00+00	FULL_TIME	2	3	\N	\N	\N	\N	\N	\N
1291	17	\N	22	87	11	21	2020-02-15 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1292	17	\N	22	1	100	2	2020-02-15 19:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
1293	17	\N	22	76	13	11	2020-02-15 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1294	21	\N	3	180	185	24	2019-09-22 14:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1295	21	\N	3	182	127	24	2019-09-22 15:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1296	21	\N	3	171	181	24	2019-09-21 14:03:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1297	21	\N	3	184	179	24	2019-09-21 15:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
1298	21	\N	3	183	126	24	2019-09-21 15:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1299	21	\N	3	170	175	24	2019-09-22 15:00:00+00	FULL_TIME	4	0	\N	\N	\N	\N	\N	\N
1300	21	\N	3	176	128	24	2019-09-22 15:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
1301	21	\N	3	186	187	24	2019-09-22 15:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
1302	21	\N	3	74	177	24	2019-09-22 16:15:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1303	21	\N	4	187	170	24	2019-09-28 14:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
1304	21	\N	4	184	185	24	2019-09-28 15:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
1305	21	\N	4	181	182	24	2019-09-28 15:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
1306	21	\N	4	128	171	24	2019-09-28 16:17:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1307	21	\N	4	126	175	24	2019-09-29 14:00:00+00	FULL_TIME	4	0	\N	\N	\N	\N	\N	\N
1308	21	\N	4	177	176	24	2019-09-29 15:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1309	21	\N	4	186	183	24	2019-09-29 15:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
1310	21	\N	4	179	74	24	2019-10-02 15:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
1311	21	\N	4	127	180	24	2019-10-03 15:03:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1312	21	\N	5	180	184	24	2019-10-07 15:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
1313	21	\N	5	185	181	24	2019-10-05 14:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1314	21	\N	5	175	128	24	2019-10-05 14:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
1315	21	\N	5	182	126	24	2019-10-05 15:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
1316	21	\N	5	171	183	24	2019-10-05 15:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
1317	21	\N	5	177	179	24	2019-10-05 15:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1318	21	\N	5	170	127	24	2019-10-06 15:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1319	21	\N	5	176	187	24	2019-10-06 14:00:00+00	FULL_TIME	1	3	\N	\N	\N	\N	\N	\N
1320	21	\N	5	74	186	24	2019-10-06 15:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1321	19	\N	KNOCKOUT	193	76	26	2019-09-28 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1322	23	\N	KNOCKOUT	64	54	36	2019-10-14 04:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1323	24	\N	GROUP	35	51	26	2019-11-13 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1324	24	\N	GROUP	44	53	25	2019-11-13 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1325	24	\N	GROUP	71	26	25	2019-11-13 19:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1326	24	\N	GROUP	39	64	26	2019-11-13 19:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1327	24	\N	GROUP	28	45	25	2019-11-13 19:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1328	24	\N	GROUP	42	24	23	2019-11-13 19:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
1329	24	\N	GROUP	58	46	25	2019-11-13 19:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1330	24	\N	GROUP	70	47	27	2019-11-13 19:00:00+00	FULL_TIME	4	0	\N	\N	\N	\N	\N	\N
1331	24	\N	GROUP	52	60	26	2019-11-13 22:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1332	24	\N	GROUP	48	40	23	2019-11-13 22:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1333	24	\N	GROUP	43	41	26	2019-11-13 22:00:00+00	FULL_TIME	1	3	\N	\N	\N	\N	\N	\N
1334	24	\N	GROUP	56	49	23	2019-11-14 19:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1335	24	\N	GROUP	34	38	23	2019-11-14 19:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1336	24	\N	GROUP	27	62	27	2019-11-14 19:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1337	24	\N	GROUP	50	104	25	2019-11-14 22:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
1338	24	\N	GROUP	33	32	26	2019-11-14 22:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1339	24	\N	GROUP	61	66	26	2019-11-14 22:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1340	24	\N	GROUP	54	37	27	2019-11-14 22:00:00+00	FULL_TIME	5	0	\N	\N	\N	\N	\N	\N
1341	24	\N	GROUP	30	36	25	2019-11-15 19:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1342	24	\N	GROUP	91	63	12	2019-11-15 19:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1343	24	\N	GROUP	105	89	25	2019-11-15 22:00:00+00	FULL_TIME	4	1	\N	\N	\N	\N	\N	\N
1344	24	\N	GROUP	103	59	26	2019-11-15 22:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1345	24	\N	GROUP	25	55	26	2019-11-16 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1346	24	\N	GROUP	69	65	26	2019-11-16 22:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1347	24	\N	GROUP	64	71	23	2019-11-17 16:05:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1348	24	\N	GROUP	45	50	25	2019-11-17 16:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
1349	24	\N	GROUP	24	52	26	2019-11-17 16:45:00+00	FULL_TIME	1	4	\N	\N	\N	\N	\N	\N
1350	24	\N	GROUP	32	70	25	2019-11-17 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1351	24	\N	GROUP	51	48	23	2019-11-17 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
1352	24	\N	GROUP	40	35	25	2019-11-17 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1353	24	\N	GROUP	60	42	25	2019-11-17 19:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
1354	24	\N	GROUP	104	28	26	2019-11-17 19:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1355	24	\N	GROUP	26	39	25	2019-11-17 19:00:00+00	FULL_TIME	2	4	\N	\N	\N	\N	\N	\N
1356	24	\N	GROUP	38	58	25	2019-11-17 19:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1357	24	\N	GROUP	66	43	23	2019-11-17 22:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1358	24	\N	GROUP	49	27	26	2019-11-18 19:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1359	24	\N	GROUP	46	34	26	2019-11-18 19:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
1360	24	\N	GROUP	41	61	26	2019-11-18 19:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
1361	24	\N	GROUP	62	56	26	2019-11-18 19:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1362	24	\N	GROUP	47	33	25	2019-11-18 19:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1363	24	\N	GROUP	36	54	26	2019-11-18 22:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1364	24	\N	GROUP	53	103	25	2019-11-19 16:00:00+00	FULL_TIME	0	3	\N	\N	\N	\N	\N	\N
1365	24	\N	GROUP	55	69	25	2019-11-19 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1366	24	\N	GROUP	59	44	25	2019-11-19 19:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1367	24	\N	GROUP	65	25	27	2019-11-19 16:00:00+00	FULL_TIME	2	6	\N	\N	\N	\N	\N	\N
1368	24	\N	GROUP	37	30	25	2019-11-19 19:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
1369	24	\N	GROUP	89	91	27	2019-11-19 22:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1370	24	\N	GROUP	63	105	23	2019-11-19 22:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1371	21	\N	6	187	182	24	2019-10-19 10:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1372	21	\N	6	183	176	24	2019-10-19 14:00:00+00	FULL_TIME	2	4	\N	\N	\N	\N	\N	\N
1373	21	\N	6	127	175	24	2019-10-19 15:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1374	21	\N	6	184	171	24	2019-10-19 15:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
1375	21	\N	6	179	170	24	2019-10-19 15:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1376	21	\N	6	181	177	24	2019-10-19 15:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1377	21	\N	6	186	180	24	2019-10-19 15:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1378	21	\N	6	126	185	24	2019-10-19 16:15:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1379	21	\N	6	128	74	24	2019-10-20 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1380	21	\N	7	182	184	24	2019-10-26 12:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1381	21	\N	7	175	176	24	2019-10-26 14:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
1382	21	\N	7	181	187	24	2019-10-26 15:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1383	21	\N	7	179	128	24	2019-10-26 15:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1384	21	\N	7	177	186	24	2019-10-26 15:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1385	21	\N	7	180	183	24	2019-10-27 14:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1386	21	\N	7	170	126	24	2019-10-27 16:15:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
1387	21	\N	7	74	171	24	2019-11-06 15:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1388	21	\N	7	185	127	24	2019-11-06 15:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
1389	21	\N	8	171	180	24	2019-11-01 14:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1390	21	\N	8	183	182	24	2019-11-02 10:00:00+00	FULL_TIME	4	3	\N	\N	\N	\N	\N	\N
1391	21	\N	8	187	179	24	2019-11-02 14:00:00+00	FULL_TIME	3	2	\N	\N	\N	\N	\N	\N
1392	21	\N	8	175	184	24	2019-11-02 15:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1393	21	\N	8	185	74	24	2020-01-08 15:00:00+00	POSTPONED	\N	\N	\N	\N	\N	\N	\N	\N
1394	21	\N	8	127	177	24	2020-02-12 15:00:00+00	POSTPONED	\N	\N	\N	\N	\N	\N	\N	\N
1395	21	\N	8	126	181	24	2019-11-02 16:15:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1396	21	\N	8	128	186	24	2019-11-03 15:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1397	21	\N	8	176	170	24	2019-11-03 15:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
1398	21	\N	9	180	175	24	2019-11-09 14:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
1399	21	\N	9	184	128	24	2019-11-09 15:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1400	21	\N	9	177	187	24	2019-11-09 15:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1401	21	\N	9	182	171	24	2019-11-10 12:00:00+00	FULL_TIME	2	3	\N	\N	\N	\N	\N	\N
1402	21	\N	9	74	126	24	2019-11-10 15:00:00+00	FULL_TIME	4	1	\N	\N	\N	\N	\N	\N
1403	21	\N	9	181	127	24	2019-11-10 15:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1404	21	\N	9	170	183	24	2019-11-10 15:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1405	21	\N	9	176	185	24	2019-11-10 15:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1406	21	\N	9	186	179	24	2019-11-10 15:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1407	21	\N	10	186	182	24	2019-11-20 15:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1408	21	\N	10	177	175	24	2019-11-20 15:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1409	21	\N	10	179	180	24	2019-11-20 15:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
1410	21	\N	10	184	183	24	2019-11-20 15:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1411	21	\N	10	171	170	24	2019-11-20 15:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1412	21	\N	10	187	185	24	2019-11-21 15:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
1413	21	\N	10	128	181	24	2019-11-21 15:00:00+00	FULL_TIME	2	4	\N	\N	\N	\N	\N	\N
1414	21	\N	10	127	126	24	2019-11-21 16:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
1415	21	\N	10	74	176	24	2019-11-21 16:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
1416	21	\N	11	180	187	24	2019-11-24 14:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1417	21	\N	11	175	171	24	2019-11-24 14:00:00+00	FULL_TIME	1	4	\N	\N	\N	\N	\N	\N
1418	21	\N	11	127	74	24	2019-11-24 15:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
1419	21	\N	11	181	179	24	2019-11-24 15:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1420	21	\N	11	170	186	24	2019-11-24 15:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1421	21	\N	11	176	182	24	2019-11-24 15:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1422	21	\N	11	126	184	24	2019-11-24 16:15:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1423	21	\N	11	183	128	24	2019-11-25 15:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1424	21	\N	11	185	177	24	2019-11-25 15:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1425	21	\N	12	171	176	24	2019-11-29 13:25:00+00	FULL_TIME	1	3	\N	\N	\N	\N	\N	\N
1426	21	\N	12	128	177	24	2019-11-30 15:00:00+00	FULL_TIME	2	5	\N	\N	\N	\N	\N	\N
1427	21	\N	12	179	126	24	2019-11-30 15:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
1428	21	\N	12	182	180	24	2019-11-30 15:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1429	21	\N	12	183	175	24	2019-11-30 15:00:00+00	FULL_TIME	6	0	\N	\N	\N	\N	\N	\N
1430	21	\N	12	185	170	24	2019-12-01 15:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1431	21	\N	12	74	181	24	2019-11-30 15:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1432	21	\N	12	187	127	24	2019-12-01 15:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1433	21	\N	12	186	184	24	2019-12-01 15:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
1434	21	\N	13	179	176	24	2019-12-07 15:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
1435	21	\N	13	181	186	24	2019-12-22 15:00:00+00	FULL_TIME	4	0	\N	\N	\N	\N	\N	\N
1436	21	\N	13	127	183	24	2019-12-06 14:00:00+00	FULL_TIME	4	1	\N	\N	\N	\N	\N	\N
1437	21	\N	13	175	185	24	2019-12-07 15:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
1438	21	\N	13	128	187	24	2019-12-06 13:30:00+00	FULL_TIME	1	3	\N	\N	\N	\N	\N	\N
1439	21	\N	13	177	180	24	2019-12-08 15:00:00+00	FULL_TIME	5	1	\N	\N	\N	\N	\N	\N
1440	21	\N	13	184	74	24	2019-12-22 15:00:00+00	FULL_TIME	0	3	\N	\N	\N	\N	\N	\N
1441	21	\N	13	170	182	24	2019-12-08 14:00:00+00	POSTPONED	\N	\N	\N	\N	\N	\N	\N	\N
1442	21	\N	13	126	171	24	2019-12-22 15:00:00+00	FULL_TIME	3	0	\N	\N	\N	\N	\N	\N
1443	21	\N	14	170	184	24	2019-12-10 15:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1444	21	\N	14	175	181	24	2019-12-11 13:00:00+00	FULL_TIME	1	4	\N	\N	\N	\N	\N	\N
1445	21	\N	14	176	127	24	2019-12-11 15:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1446	21	\N	14	171	179	24	2019-12-29 15:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1447	21	\N	14	182	128	24	2019-08-01 15:00:00+00	POSTPONED	\N	\N	\N	\N	\N	\N	\N	\N
1448	21	\N	14	185	186	24	2019-12-11 15:00:00+00	FULL_TIME	4	1	\N	\N	\N	\N	\N	\N
1449	21	\N	14	180	74	24	2019-12-29 15:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1450	21	\N	14	183	187	24	2019-11-11 15:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1451	21	\N	14	126	177	24	2019-12-12 16:15:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1452	21	\N	15	74	170	24	2020-01-29 15:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1453	21	\N	15	177	183	24	2019-12-15 15:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1454	21	\N	15	179	185	24	2019-12-15 15:00:00+00	FULL_TIME	1	3	\N	\N	\N	\N	\N	\N
1455	21	\N	15	182	175	24	2019-08-01 15:00:00+00	POSTPONED	\N	\N	\N	\N	\N	\N	\N	\N
1456	21	\N	15	186	171	24	2020-01-29 15:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1457	21	\N	15	184	127	24	2019-12-14 15:00:00+00	FULL_TIME	0	2	\N	\N	\N	\N	\N	\N
1458	21	\N	15	128	180	24	2019-12-15 15:00:00+00	FULL_TIME	3	3	\N	\N	\N	\N	\N	\N
1459	21	\N	15	181	176	24	2019-12-15 15:00:00+00	FULL_TIME	2	2	\N	\N	\N	\N	\N	\N
1460	21	\N	15	187	126	24	2019-12-15 16:15:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1461	21	\N	16	170	128	24	2020-01-04 14:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1462	21	\N	16	171	177	24	2020-01-04 15:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1463	21	\N	16	176	184	24	2020-01-04 15:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1464	21	\N	16	127	179	24	2020-01-04 15:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1465	21	\N	16	175	187	24	2020-01-04 15:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1466	21	\N	16	126	186	24	2020-01-04 16:15:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1467	21	\N	16	180	181	24	2020-01-05 14:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1468	21	\N	16	183	74	24	2020-01-05 16:15:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1469	21	\N	17	177	170	24	2020-01-08 14:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1470	21	\N	17	128	127	24	2020-01-08 15:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1471	21	\N	17	179	175	24	2020-01-18 15:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1472	21	\N	17	180	126	24	2020-01-18 15:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1473	21	\N	17	181	183	24	2020-01-18 15:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1474	21	\N	17	185	171	24	2020-01-18 15:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1475	21	\N	17	186	176	24	2020-01-19 15:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1476	21	\N	17	187	184	24	2020-01-19 15:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1477	25	\N	1	6	197	10	2020-02-10 20:15:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1478	17	\N	23	169	76	37	2020-02-18 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1479	17	\N	23	100	15	16	2020-02-18 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
1480	17	\N	23	5	87	6	2020-02-18 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1481	17	\N	23	3	101	35	2020-02-18 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1482	17	\N	23	11	4	12	2020-02-18 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1483	17	\N	23	168	102	40	2020-02-18 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1484	17	\N	23	8	1	9	2020-02-19 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1485	17	\N	23	13	7	6	2020-02-19 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1486	17	\N	23	99	17	29	2020-02-19 16:00:00+00	FULL_TIME	4	1	\N	\N	\N	\N	\N	\N
1487	17	\N	24	169	15	37	2020-02-22 16:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
1488	17	\N	24	5	7	6	2020-02-22 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1489	17	\N	24	11	101	12	2020-02-22 19:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
1490	17	\N	24	3	4	35	2020-02-22 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1491	17	\N	24	168	1	40	2020-02-22 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1492	17	\N	24	8	102	9	2020-02-22 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1493	17	\N	24	2	17	19	2020-02-22 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
1494	17	\N	24	13	87	6	2020-02-23 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1495	17	\N	24	100	76	16	2020-02-23 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1496	17	\N	25	88	169	22	2020-02-29 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1497	17	\N	25	4	13	5	2020-02-29 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1498	17	\N	25	15	2	4	2020-02-29 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1499	17	\N	25	87	168	21	2020-02-29 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
1500	17	\N	25	101	5	30	2020-02-29 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1501	17	\N	25	7	8	8	2020-02-29 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1502	17	\N	25	3	1	35	2020-02-29 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1503	17	\N	25	76	99	12	2020-02-29 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1504	17	\N	25	11	102	11	2020-03-01 20:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1505	17	\N	26	76	2	11	2020-03-03 19:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1506	17	\N	26	17	169	13	2020-03-04 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1507	17	\N	26	101	13	30	2020-03-04 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1508	17	\N	26	15	99	4	2020-03-04 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1509	17	\N	26	7	168	8	2020-03-04 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1510	17	\N	26	4	5	5	2020-03-04 16:00:00+00	FULL_TIME	2	3	\N	\N	\N	\N	\N	\N
1511	17	\N	26	87	8	21	2020-03-04 16:00:00+00	FULL_TIME	3	3	\N	\N	\N	\N	\N	\N
1512	17	\N	26	102	3	11	2020-03-04 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1513	17	\N	26	1	11	11	2020-03-04 19:10:00+00	FULL_TIME	2	3	\N	\N	\N	\N	\N	\N
1514	17	\N	27	15	3	4	2020-03-07 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1515	17	\N	27	100	8	16	2020-03-07 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1516	17	\N	27	7	4	8	2020-03-07 16:00:00+00	FULL_TIME	3	1	\N	\N	\N	\N	\N	\N
1517	17	\N	27	88	13	22	2020-03-07 16:00:00+00	FULL_TIME	1	2	\N	\N	\N	\N	\N	\N
1518	17	\N	27	87	101	21	2020-03-08 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1519	17	\N	27	17	5	18	2020-03-07 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1520	17	\N	27	102	2	11	2020-03-07 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1521	17	\N	27	1	99	2	2020-03-07 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1522	17	\N	27	76	11	11	2020-03-08 17:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1523	17	\N	28	8	4	9	2020-03-10 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1524	17	\N	28	168	101	40	2020-03-10 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1525	17	\N	28	5	2	6	2020-03-10 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1526	17	\N	28	100	87	16	2020-03-10 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1527	17	\N	28	169	7	37	2020-03-11 16:00:00+00	FULL_TIME	\N	\N	\N	\N	\N	\N	\N	\N
1528	17	\N	28	1	15	2	2020-03-10 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1529	17	\N	28	11	88	12	2020-03-11 16:00:00+00	FULL_TIME	8	0	\N	\N	\N	\N	\N	\N
1530	17	\N	28	13	99	6	2020-03-11 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1531	17	\N	28	102	76	12	2020-03-12 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1532	17	\N	29	17	13	13	2020-03-14 16:00:00+00	FULL_TIME	2	0	\N	\N	\N	\N	\N	\N
1533	17	\N	29	169	8	37	2020-03-14 16:00:00+00	FULL_TIME	1	0	\N	\N	\N	\N	\N	\N
1534	17	\N	29	87	4	21	2020-03-14 16:00:00+00	FULL_TIME	0	1	\N	\N	\N	\N	\N	\N
1535	17	\N	29	7	101	8	2020-03-14 16:00:00+00	FULL_TIME	1	1	\N	\N	\N	\N	\N	\N
1536	17	\N	29	88	5	22	2020-03-14 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1537	17	\N	29	102	99	11	2020-03-15 16:00:00+00	FULL_TIME	2	1	\N	\N	\N	\N	\N	\N
1538	17	\N	29	1	2	2	2020-03-31 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1539	17	\N	29	11	15	12	2020-04-30 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1540	17	\N	29	3	76	35	2020-04-30 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1541	17	\N	30	100	7	16	2020-04-18 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1542	17	\N	30	168	4	40	2020-04-18 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1543	17	\N	30	8	101	9	2020-04-18 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1544	17	\N	30	5	99	6	2020-04-18 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1545	17	\N	30	3	88	35	2020-04-18 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1546	17	\N	30	169	87	37	2020-04-18 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1547	17	\N	30	102	15	2	2020-04-18 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1548	17	\N	30	76	1	12	2020-04-30 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
1549	17	\N	30	11	17	12	2020-04-30 16:00:00+00	SCHEDULED	\N	\N	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: player_team_stints; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.player_team_stints (id, player_id, team_id, start_date, end_date, shirt_number, transfer_fee, transfer_type) FROM stdin;
1	955	76	2017-08-01	2019-07-31	\N	\N	PERMANENT
2	956	76	2017-08-01	2019-08-30	\N	\N	PERMANENT
3	957	76	2017-08-01	2019-07-31	\N	\N	PERMANENT
4	958	76	2015-08-01	2019-07-31	\N	\N	PERMANENT
5	959	76	2016-08-01	2018-01-08	\N	\N	PERMANENT
6	960	76	2016-08-01	2019-07-31	\N	\N	PERMANENT
7	961	76	2015-08-01	2019-07-31	\N	\N	PERMANENT
8	962	76	2015-08-01	2019-07-31	\N	\N	PERMANENT
9	963	76	2015-08-01	2019-07-31	\N	\N	PERMANENT
10	964	76	2017-08-01	2019-07-31	\N	\N	PERMANENT
11	965	76	2017-08-01	2019-07-31	\N	\N	PERMANENT
12	966	76	2016-08-01	2019-07-31	\N	\N	PERMANENT
13	967	76	2016-08-01	2019-07-31	\N	\N	PERMANENT
14	968	76	2015-08-01	2019-07-31	\N	\N	PERMANENT
15	969	76	2016-08-01	2019-07-31	\N	\N	PERMANENT
16	970	76	2016-08-01	2018-08-01	\N	\N	PERMANENT
17	971	76	2017-08-01	2019-07-31	\N	\N	PERMANENT
18	972	76	2017-08-01	2019-07-31	\N	\N	PERMANENT
19	973	76	2016-08-01	2019-07-31	\N	\N	PERMANENT
20	974	76	2015-08-01	2018-08-01	\N	\N	PERMANENT
21	975	76	2016-08-01	2019-01-01	\N	\N	PERMANENT
22	976	76	2017-08-01	2019-07-31	\N	\N	PERMANENT
23	977	76	2017-08-01	2019-08-01	\N	\N	PERMANENT
24	978	76	2017-08-01	2018-12-01	\N	\N	PERMANENT
25	979	76	2015-08-01	2018-08-01	\N	\N	PERMANENT
26	980	76	2015-08-01	2019-07-31	\N	\N	PERMANENT
27	981	76	2017-08-01	2019-07-31	\N	\N	PERMANENT
28	982	76	2017-08-01	2019-07-31	\N	\N	PERMANENT
29	983	76	2016-08-01	2018-12-01	\N	\N	PERMANENT
30	984	88	2017-08-01	2019-07-31	\N	\N	PERMANENT
31	985	88	2017-08-01	2019-07-31	\N	\N	PERMANENT
32	986	88	2017-08-01	2018-08-01	\N	\N	PERMANENT
33	987	88	2016-08-01	\N	\N	\N	PERMANENT
34	988	88	2017-08-01	\N	\N	\N	PERMANENT
35	989	88	2017-08-01	\N	\N	\N	PERMANENT
36	990	88	2017-08-01	2018-08-01	\N	\N	PERMANENT
37	991	88	2017-08-01	\N	\N	\N	PERMANENT
38	992	88	2017-08-01	2019-08-01	\N	\N	PERMANENT
39	993	88	2017-08-01	\N	\N	\N	PERMANENT
40	994	88	2017-08-01	\N	\N	\N	PERMANENT
41	995	88	2017-08-01	\N	\N	\N	PERMANENT
42	996	88	2017-08-01	2019-08-01	\N	\N	PERMANENT
43	997	88	2017-08-01	2018-08-01	\N	\N	PERMANENT
44	998	88	2017-08-01	\N	\N	\N	PERMANENT
45	999	88	2017-08-01	2018-08-01	\N	\N	PERMANENT
46	1000	88	2017-08-01	\N	\N	\N	PERMANENT
47	1001	88	2017-08-01	\N	\N	\N	PERMANENT
48	1002	4	2017-08-01	2018-08-01	\N	\N	PERMANENT
49	1003	88	2017-08-01	2018-08-01	\N	\N	PERMANENT
50	1004	88	2017-08-01	2018-01-08	\N	\N	PERMANENT
51	1005	4	2017-08-01	2018-01-08	\N	\N	PERMANENT
52	1006	88	2017-08-01	\N	\N	\N	PERMANENT
53	1007	88	2017-08-01	\N	\N	\N	PERMANENT
54	1008	88	2017-08-01	\N	\N	\N	PERMANENT
55	1009	11	2017-08-01	\N	\N	\N	PERMANENT
56	1010	11	2017-08-01	\N	\N	\N	PERMANENT
57	1011	11	2017-08-01	\N	\N	\N	PERMANENT
58	1012	11	2015-08-01	\N	\N	\N	PERMANENT
59	1013	11	2017-08-01	\N	\N	\N	PERMANENT
60	1014	11	2016-08-01	\N	\N	\N	PERMANENT
61	1015	11	2017-08-01	\N	\N	\N	PERMANENT
62	1016	11	2016-08-01	\N	\N	\N	PERMANENT
63	1017	11	2016-08-01	\N	\N	\N	PERMANENT
64	1018	11	2017-08-01	\N	\N	\N	PERMANENT
65	1019	11	2017-08-01	\N	\N	\N	PERMANENT
66	1020	11	2017-08-01	\N	\N	\N	PERMANENT
67	1021	11	2017-08-01	2018-08-01	\N	\N	PERMANENT
68	1022	11	2016-08-01	\N	\N	\N	PERMANENT
69	1023	11	2016-08-01	\N	\N	\N	PERMANENT
70	1024	11	2016-08-01	\N	\N	\N	PERMANENT
71	1025	11	2017-08-01	2019-08-01	\N	\N	PERMANENT
72	1026	11	2015-08-26	\N	\N	\N	PERMANENT
73	1027	87	2016-08-01	\N	\N	\N	PERMANENT
74	1028	11	2015-08-01	\N	\N	\N	PERMANENT
75	1029	11	2015-08-26	\N	\N	\N	PERMANENT
76	1030	11	2015-08-26	2018-08-01	\N	\N	PERMANENT
77	1031	11	2016-08-01	\N	\N	\N	PERMANENT
78	1032	11	2017-08-01	\N	\N	\N	PERMANENT
79	1033	11	2016-08-01	\N	\N	\N	PERMANENT
80	1034	11	2016-08-01	\N	\N	\N	PERMANENT
81	1035	11	2017-08-01	\N	\N	\N	PERMANENT
82	1036	11	2017-08-01	\N	\N	\N	PERMANENT
83	1037	15	2017-08-01	\N	\N	\N	PERMANENT
84	1038	15	2017-08-01	\N	\N	\N	PERMANENT
85	1039	15	2017-08-01	\N	\N	\N	PERMANENT
86	1040	15	2017-08-01	\N	\N	\N	PERMANENT
87	1041	15	2017-08-01	\N	\N	\N	PERMANENT
88	1042	15	2017-08-01	\N	\N	\N	PERMANENT
89	1043	15	2017-08-01	\N	\N	\N	PERMANENT
90	1044	15	2017-08-01	\N	\N	\N	PERMANENT
91	1045	15	2017-08-01	\N	\N	\N	PERMANENT
92	1046	15	2017-08-01	2018-08-01	\N	\N	PERMANENT
93	1047	15	2017-08-01	\N	\N	\N	PERMANENT
94	1048	15	2017-08-01	\N	\N	\N	PERMANENT
95	1049	15	2017-08-01	\N	\N	\N	PERMANENT
96	1050	15	2017-08-01	\N	\N	\N	PERMANENT
97	1051	15	2017-08-01	\N	\N	\N	PERMANENT
98	1052	15	2017-08-01	\N	\N	\N	PERMANENT
99	1053	15	2017-08-01	\N	\N	\N	PERMANENT
100	1054	15	2017-08-01	\N	\N	\N	PERMANENT
101	1055	1	2017-06-30	2020-06-30	\N	\N	PERMANENT
102	1056	1	2009-08-01	\N	\N	\N	PERMANENT
103	1057	1	2016-08-01	\N	\N	\N	PERMANENT
104	1058	1	2016-08-01	\N	\N	\N	PERMANENT
105	1059	1	2016-08-01	\N	\N	\N	PERMANENT
106	1060	1	2009-08-01	\N	\N	\N	PERMANENT
107	1061	1	2016-08-01	\N	\N	\N	PERMANENT
108	1062	1	2016-12-04	\N	\N	\N	PERMANENT
109	1063	1	2014-04-30	\N	\N	\N	PERMANENT
110	1064	1	2008-08-11	\N	\N	\N	PERMANENT
111	1065	1	2017-08-01	\N	\N	\N	PERMANENT
112	1066	1	2017-08-01	2018-01-08	\N	\N	PERMANENT
113	1067	1	2016-11-16	\N	\N	\N	PERMANENT
114	1068	1	2017-08-01	\N	\N	\N	PERMANENT
115	1069	1	2017-08-01	2018-08-01	\N	\N	PERMANENT
116	1070	1	2017-08-01	2018-12-01	\N	\N	PERMANENT
117	1071	1	2012-07-21	2020-07-21	\N	\N	PERMANENT
118	1072	1	2011-04-11	\N	\N	\N	PERMANENT
119	1073	1	2013-12-13	\N	\N	\N	PERMANENT
120	1074	7	2017-08-01	\N	\N	\N	PERMANENT
121	1075	7	2016-08-01	\N	\N	\N	PERMANENT
122	1076	7	2016-08-01	\N	\N	\N	PERMANENT
123	1077	7	2017-08-01	\N	\N	\N	PERMANENT
124	1078	7	2016-08-01	\N	\N	\N	PERMANENT
125	1079	7	2016-08-01	2018-08-01	\N	\N	PERMANENT
126	1080	7	2016-08-01	2019-08-01	\N	\N	PERMANENT
127	1081	7	2016-08-27	\N	\N	\N	PERMANENT
128	1082	7	2015-08-01	\N	\N	\N	PERMANENT
129	1083	7	2017-08-01	\N	\N	\N	PERMANENT
130	1084	7	2017-08-01	\N	\N	\N	PERMANENT
131	1085	7	2017-08-01	2018-08-01	\N	\N	PERMANENT
132	1086	7	2016-08-01	\N	\N	\N	PERMANENT
133	1087	7	2017-08-01	\N	\N	\N	PERMANENT
134	1088	7	2016-08-01	\N	\N	\N	PERMANENT
135	1089	7	2016-08-01	\N	\N	\N	PERMANENT
136	1090	7	2014-08-01	\N	\N	\N	PERMANENT
137	1091	7	2015-08-01	\N	\N	\N	PERMANENT
138	1092	7	2016-08-01	\N	\N	\N	PERMANENT
139	1093	7	2016-08-01	\N	\N	\N	PERMANENT
140	1094	7	2016-08-01	\N	\N	\N	PERMANENT
141	1095	7	2017-08-01	\N	\N	\N	PERMANENT
142	1096	7	2015-08-01	2018-12-11	\N	\N	PERMANENT
143	1097	7	2015-08-01	\N	\N	\N	PERMANENT
144	1098	7	2017-08-01	\N	\N	\N	PERMANENT
145	1099	7	2017-08-01	\N	\N	\N	PERMANENT
146	1100	7	2017-08-01	\N	\N	\N	PERMANENT
147	1101	4	2016-08-01	2018-08-01	\N	\N	PERMANENT
148	1102	4	2016-08-01	\N	\N	\N	PERMANENT
149	1103	4	2017-08-01	\N	\N	\N	PERMANENT
150	1104	4	2016-08-01	2018-08-01	\N	\N	PERMANENT
151	1105	4	2016-08-01	2018-08-01	\N	\N	PERMANENT
152	1106	4	2016-08-01	2018-08-01	\N	\N	PERMANENT
153	1107	4	2016-08-01	\N	\N	\N	PERMANENT
154	1108	4	2016-08-01	\N	\N	\N	PERMANENT
155	1109	4	2017-08-01	\N	\N	\N	PERMANENT
156	1110	4	2017-08-01	\N	\N	\N	PERMANENT
157	1111	4	2017-08-01	\N	\N	\N	PERMANENT
158	1112	4	2017-08-01	\N	\N	\N	PERMANENT
159	1113	4	2017-08-01	\N	\N	\N	PERMANENT
160	1114	4	2016-08-01	2018-01-08	\N	\N	PERMANENT
161	1115	4	2016-08-01	\N	\N	\N	PERMANENT
162	1116	4	2016-08-01	\N	\N	\N	PERMANENT
163	1117	4	2017-08-01	\N	\N	\N	PERMANENT
164	1118	4	2017-08-01	2019-08-01	\N	\N	PERMANENT
165	1119	4	2016-08-01	\N	\N	\N	PERMANENT
166	1120	4	2016-08-01	\N	\N	\N	PERMANENT
167	1121	4	2016-08-01	\N	\N	\N	PERMANENT
168	1122	4	2017-08-01	\N	\N	\N	PERMANENT
169	1123	4	2017-08-01	\N	\N	\N	PERMANENT
170	1124	4	2017-08-01	\N	\N	\N	PERMANENT
171	1125	4	2016-08-01	\N	\N	\N	PERMANENT
172	1126	4	2016-08-01	\N	\N	\N	PERMANENT
173	1127	4	2016-08-01	\N	\N	\N	PERMANENT
174	1128	4	2015-08-01	\N	\N	\N	PERMANENT
175	1129	87	2017-08-01	2018-08-01	\N	\N	PERMANENT
176	1130	87	2017-08-01	\N	\N	\N	PERMANENT
177	1131	87	2017-08-01	\N	\N	\N	PERMANENT
178	1132	87	2017-08-01	\N	\N	\N	PERMANENT
179	1133	11	2017-08-01	\N	\N	\N	PERMANENT
180	1134	87	2017-08-01	\N	\N	\N	PERMANENT
181	1135	87	2017-08-01	\N	\N	\N	PERMANENT
182	1136	87	2017-08-01	\N	\N	\N	PERMANENT
183	1137	87	2017-08-01	\N	\N	\N	PERMANENT
184	1138	87	2017-08-01	\N	\N	\N	PERMANENT
185	1139	87	2017-08-01	\N	\N	\N	PERMANENT
186	1140	87	2017-08-01	\N	\N	\N	PERMANENT
187	1141	87	2017-08-01	\N	\N	\N	PERMANENT
188	1142	87	2017-08-01	\N	\N	\N	PERMANENT
189	1143	87	2017-08-01	\N	\N	\N	PERMANENT
190	1144	87	2017-08-01	\N	\N	\N	PERMANENT
191	1145	87	2017-08-01	\N	\N	\N	PERMANENT
192	1146	87	2017-08-01	\N	\N	\N	PERMANENT
193	1147	87	2017-08-01	\N	\N	\N	PERMANENT
194	1148	87	2017-08-01	\N	\N	\N	PERMANENT
195	1149	87	2017-08-01	\N	\N	\N	PERMANENT
196	1150	87	2017-08-01	\N	\N	\N	PERMANENT
197	1151	87	2017-08-01	\N	\N	\N	PERMANENT
198	1152	87	2017-08-01	\N	\N	\N	PERMANENT
199	1153	87	2017-08-01	2018-08-01	\N	\N	PERMANENT
200	1154	87	2017-08-01	\N	\N	\N	PERMANENT
201	1155	87	2017-08-01	\N	\N	\N	PERMANENT
202	1156	87	2017-08-01	\N	\N	\N	PERMANENT
203	1157	87	2017-08-01	\N	\N	\N	PERMANENT
204	1158	7	2017-08-01	\N	\N	\N	PERMANENT
205	1159	7	2017-08-01	\N	\N	\N	PERMANENT
206	1160	5	2015-08-01	\N	\N	\N	PERMANENT
207	1161	5	2016-08-01	\N	\N	\N	PERMANENT
208	1162	5	2017-08-01	\N	\N	\N	PERMANENT
209	1163	5	2017-08-01	\N	\N	\N	PERMANENT
210	1164	5	2015-08-01	\N	\N	\N	PERMANENT
211	1165	5	2015-08-01	2018-02-08	\N	\N	PERMANENT
212	1166	5	2014-08-01	2018-08-01	\N	\N	PERMANENT
213	1167	5	2017-08-01	\N	\N	\N	PERMANENT
214	1168	5	2014-08-01	\N	\N	\N	PERMANENT
215	1169	5	2016-08-01	\N	\N	\N	PERMANENT
216	1170	5	2017-08-01	\N	\N	\N	PERMANENT
217	1171	5	2017-08-01	\N	\N	\N	PERMANENT
218	1172	5	2016-08-01	2018-08-01	\N	\N	PERMANENT
219	1173	5	2016-08-01	\N	\N	\N	PERMANENT
220	1174	5	2017-08-01	\N	\N	\N	PERMANENT
221	1175	5	2017-08-01	2019-08-01	\N	\N	PERMANENT
222	1176	5	2017-08-01	\N	\N	\N	PERMANENT
223	1177	5	2017-08-01	\N	\N	\N	PERMANENT
224	1178	5	2017-08-01	\N	\N	\N	PERMANENT
225	1179	5	2017-08-01	\N	\N	\N	PERMANENT
226	1180	5	2017-08-01	\N	\N	\N	PERMANENT
227	1181	5	2017-08-01	\N	\N	\N	PERMANENT
228	1182	5	2017-08-01	2018-08-01	\N	\N	PERMANENT
229	1183	5	2017-08-01	\N	\N	\N	PERMANENT
230	1184	5	2016-08-01	2017-12-01	\N	\N	PERMANENT
231	1185	5	2017-08-01	\N	\N	\N	PERMANENT
232	1186	5	2016-08-01	2018-01-08	\N	\N	PERMANENT
233	1187	5	2015-08-01	\N	\N	\N	PERMANENT
234	1188	86	2017-08-01	2018-08-01	\N	\N	PERMANENT
235	1189	86	2017-08-01	\N	\N	\N	PERMANENT
236	1190	86	2017-08-01	\N	\N	\N	PERMANENT
237	1191	86	2017-08-01	\N	\N	\N	PERMANENT
238	1192	86	2017-08-01	\N	\N	\N	PERMANENT
239	1193	86	2017-08-01	\N	\N	\N	PERMANENT
240	1194	86	2017-08-01	\N	\N	\N	PERMANENT
241	1195	86	2017-08-01	2018-08-01	\N	\N	PERMANENT
242	1196	86	2017-08-01	2018-08-01	\N	\N	PERMANENT
243	1197	86	2017-08-01	\N	\N	\N	PERMANENT
244	1198	86	2017-08-01	2018-08-01	\N	\N	PERMANENT
245	1199	86	2017-08-01	\N	\N	\N	PERMANENT
246	1200	86	2017-08-01	\N	\N	\N	PERMANENT
247	1201	86	2017-08-01	\N	\N	\N	PERMANENT
248	1202	86	2017-08-01	\N	\N	\N	PERMANENT
249	1203	86	2017-08-01	\N	\N	\N	PERMANENT
250	1204	86	2017-08-01	\N	\N	\N	PERMANENT
251	1205	86	2017-08-01	2018-01-08	\N	\N	PERMANENT
252	1206	86	2017-08-01	\N	\N	\N	PERMANENT
253	1207	86	2017-08-01	\N	\N	\N	PERMANENT
254	1208	86	2017-08-01	\N	\N	\N	PERMANENT
255	1209	86	2017-08-01	\N	\N	\N	PERMANENT
256	1210	86	2017-08-01	2018-08-01	\N	\N	PERMANENT
257	1211	86	2017-08-01	\N	\N	\N	PERMANENT
258	1212	86	2017-08-01	\N	\N	\N	PERMANENT
259	1213	86	2017-08-01	\N	\N	\N	PERMANENT
260	1214	86	2017-08-01	\N	\N	\N	PERMANENT
261	1215	86	2017-08-01	\N	\N	\N	PERMANENT
262	1216	15	2016-08-01	\N	\N	\N	PERMANENT
263	1217	15	2016-08-01	\N	\N	\N	PERMANENT
264	1218	15	2017-08-01	\N	\N	\N	PERMANENT
265	1219	17	2016-08-01	2018-08-01	\N	\N	PERMANENT
266	1220	17	2017-08-01	2018-01-08	\N	\N	PERMANENT
267	1221	2	2016-08-01	2018-08-01	\N	\N	PERMANENT
268	1222	5	2016-08-01	\N	\N	\N	PERMANENT
269	1223	13	2016-08-01	2018-12-01	\N	\N	PERMANENT
270	1224	13	2016-08-01	\N	\N	\N	PERMANENT
271	1225	76	2015-08-01	2017-07-31	\N	\N	PERMANENT
272	1226	8	2016-08-01	2018-08-01	\N	\N	PERMANENT
273	1227	8	2016-08-01	2018-07-31	\N	\N	PERMANENT
274	1228	8	2017-08-01	2019-07-31	\N	\N	PERMANENT
275	1229	8	2017-08-01	2018-08-01	\N	\N	PERMANENT
276	1230	15	2017-08-01	2018-08-01	\N	\N	PERMANENT
277	1231	8	2017-08-01	2019-07-31	\N	\N	PERMANENT
278	1232	8	2017-08-01	2018-08-01	\N	\N	PERMANENT
279	1233	8	2017-08-01	2018-12-01	\N	\N	PERMANENT
280	1234	8	2015-08-01	2018-08-01	\N	\N	PERMANENT
281	1235	8	2015-08-01	2018-08-01	\N	\N	PERMANENT
282	1236	8	2015-08-01	2018-08-01	\N	\N	PERMANENT
283	1237	8	2016-08-01	\N	\N	\N	PERMANENT
284	1238	8	2016-08-01	2018-08-01	\N	\N	PERMANENT
285	1239	8	2017-08-01	\N	\N	\N	PERMANENT
286	1240	8	2017-08-01	\N	\N	\N	PERMANENT
287	1241	8	2016-08-01	\N	\N	\N	PERMANENT
288	1242	8	2017-08-01	2018-08-01	\N	\N	PERMANENT
289	1243	8	2016-08-01	\N	\N	\N	PERMANENT
290	1244	8	2017-08-01	\N	\N	\N	PERMANENT
291	1245	16	2016-08-01	2018-08-01	\N	\N	PERMANENT
292	1246	2	2016-08-01	2018-08-01	\N	\N	PERMANENT
293	1247	86	2017-08-01	2018-08-01	\N	\N	PERMANENT
294	1248	86	2017-08-01	\N	\N	\N	PERMANENT
295	1249	86	2017-08-01	\N	\N	\N	PERMANENT
296	1250	17	2017-08-01	\N	\N	\N	PERMANENT
297	1251	17	2017-08-01	2018-01-08	\N	\N	PERMANENT
298	1252	17	2017-08-01	2018-08-01	\N	\N	PERMANENT
299	1253	17	2017-08-01	\N	\N	\N	PERMANENT
300	1254	17	2017-08-01	\N	\N	\N	PERMANENT
301	1255	17	2017-08-01	\N	\N	\N	PERMANENT
302	1256	17	2017-08-01	\N	\N	\N	PERMANENT
303	1257	17	2017-08-01	2018-01-08	\N	\N	PERMANENT
304	1258	17	2017-08-01	2018-08-01	\N	\N	PERMANENT
305	1259	17	2017-08-01	\N	\N	\N	PERMANENT
306	1260	17	2017-08-01	2018-08-01	\N	\N	PERMANENT
307	1261	13	2016-08-01	2018-08-01	\N	\N	PERMANENT
308	1262	16	2016-08-01	\N	\N	\N	PERMANENT
309	1263	13	2017-08-01	2018-08-01	\N	\N	PERMANENT
310	1264	15	2017-08-01	\N	\N	\N	PERMANENT
311	1265	15	2017-08-01	2019-08-01	\N	\N	PERMANENT
312	1266	15	2017-08-01	\N	\N	\N	PERMANENT
313	1267	15	2017-08-01	\N	\N	\N	PERMANENT
314	1268	16	2017-08-01	\N	\N	\N	PERMANENT
315	1269	16	2017-08-01	2018-01-08	\N	\N	PERMANENT
316	1270	16	2017-08-01	2018-08-01	\N	\N	PERMANENT
317	1271	16	2017-08-01	2018-08-01	\N	\N	PERMANENT
318	1272	16	2017-08-01	2018-01-08	\N	\N	PERMANENT
319	1273	16	2017-08-01	\N	\N	\N	PERMANENT
320	1274	16	2017-08-01	\N	\N	\N	PERMANENT
321	1275	16	2017-08-01	\N	\N	\N	PERMANENT
322	1276	16	2017-08-01	\N	\N	\N	PERMANENT
323	1277	1	2016-08-01	\N	\N	\N	PERMANENT
324	1278	12	2017-08-01	\N	\N	\N	PERMANENT
325	1279	12	2017-08-01	\N	\N	\N	PERMANENT
326	1280	12	2017-08-01	2018-08-01	\N	\N	PERMANENT
327	1281	12	2017-08-01	\N	\N	\N	PERMANENT
328	1282	12	2017-08-01	\N	\N	\N	PERMANENT
329	1283	12	2017-08-01	2018-01-08	\N	\N	PERMANENT
330	1284	12	2017-08-01	\N	\N	\N	PERMANENT
331	1285	12	2017-08-01	\N	\N	\N	PERMANENT
332	1286	87	2017-08-01	2018-08-01	\N	\N	PERMANENT
333	1287	12	2017-08-01	\N	\N	\N	PERMANENT
334	1288	12	2017-08-01	\N	\N	\N	PERMANENT
335	1289	12	2017-08-01	\N	\N	\N	PERMANENT
336	1290	12	2017-08-01	\N	\N	\N	PERMANENT
337	1291	12	2017-08-01	\N	\N	\N	PERMANENT
338	1292	12	2017-08-01	2018-08-01	\N	\N	PERMANENT
339	1293	12	2017-08-01	\N	\N	\N	PERMANENT
340	1294	12	2017-08-01	\N	\N	\N	PERMANENT
341	1295	35	2017-08-01	\N	\N	\N	PERMANENT
342	1296	2	2016-08-01	\N	\N	\N	PERMANENT
343	1297	2	2016-08-01	\N	\N	\N	PERMANENT
344	1298	2	2016-08-01	\N	\N	\N	PERMANENT
345	1299	2	2017-08-01	2018-08-01	\N	\N	PERMANENT
346	1300	2	2016-08-01	2018-08-01	\N	\N	PERMANENT
347	1301	2	2016-08-01	\N	\N	\N	PERMANENT
348	1302	2	2016-08-01	\N	\N	\N	PERMANENT
349	1303	2	2016-08-01	\N	\N	\N	PERMANENT
350	1304	2	2016-08-01	\N	\N	\N	PERMANENT
351	1305	2	2016-08-01	\N	\N	\N	PERMANENT
352	1306	2	2016-08-01	2018-08-01	\N	\N	PERMANENT
353	1307	2	2016-08-01	\N	\N	\N	PERMANENT
354	1308	2	2016-08-01	\N	\N	\N	PERMANENT
355	1309	2	2016-08-01	\N	\N	\N	PERMANENT
356	1310	2	2016-08-01	\N	\N	\N	PERMANENT
357	1311	2	2016-08-01	2018-08-01	\N	\N	PERMANENT
358	1312	15	2016-08-01	\N	\N	\N	PERMANENT
359	1313	15	2016-08-01	\N	\N	\N	PERMANENT
360	1314	15	2016-08-01	2018-12-01	\N	\N	PERMANENT
361	1315	16	2016-08-01	2018-08-01	\N	\N	PERMANENT
362	1316	16	2016-08-01	\N	\N	\N	PERMANENT
363	1317	16	2016-08-01	2018-01-08	\N	\N	PERMANENT
364	1318	16	2016-08-01	\N	\N	\N	PERMANENT
365	1319	16	2016-08-01	\N	\N	\N	PERMANENT
366	1320	16	2016-08-01	\N	\N	\N	PERMANENT
367	1321	16	2016-08-01	\N	\N	\N	PERMANENT
368	1322	8	2016-08-01	2018-06-01	\N	\N	PERMANENT
369	1323	8	2016-08-01	2018-08-01	\N	\N	PERMANENT
370	1324	8	2016-08-01	2018-08-01	\N	\N	PERMANENT
371	1325	12	2016-08-01	\N	\N	\N	PERMANENT
372	1326	12	2016-08-01	\N	\N	\N	PERMANENT
373	1327	12	2016-08-01	\N	\N	\N	PERMANENT
374	1328	12	2016-08-01	2018-08-01	\N	\N	PERMANENT
375	1329	1	2015-08-01	\N	\N	\N	PERMANENT
376	1330	64	2017-08-01	2019-07-31	\N	\N	PERMANENT
377	1331	23	2017-08-01	2018-12-01	\N	\N	PERMANENT
378	1332	13	2016-08-01	\N	\N	\N	PERMANENT
379	1333	13	2016-08-01	\N	\N	\N	PERMANENT
380	1334	13	2016-08-01	\N	\N	\N	PERMANENT
381	1335	13	2016-08-01	\N	\N	\N	PERMANENT
382	1336	13	2016-08-01	\N	\N	\N	PERMANENT
383	1337	13	2016-08-01	\N	\N	\N	PERMANENT
384	1338	13	2016-08-01	\N	\N	\N	PERMANENT
385	1339	13	2016-08-01	\N	\N	\N	PERMANENT
386	1340	13	2016-08-01	\N	\N	\N	PERMANENT
387	1341	13	2016-08-01	\N	\N	\N	PERMANENT
388	1342	13	2016-08-01	\N	\N	\N	PERMANENT
389	1343	13	2016-08-01	2018-08-01	\N	\N	PERMANENT
390	1344	13	2016-08-01	\N	\N	\N	PERMANENT
391	1345	13	2016-08-01	\N	\N	\N	PERMANENT
392	1346	62	2016-08-01	\N	\N	\N	PERMANENT
393	1347	62	2016-08-01	\N	\N	\N	PERMANENT
394	1348	89	2017-08-01	\N	\N	\N	PERMANENT
395	1349	89	2017-08-01	\N	\N	\N	PERMANENT
396	1350	89	2017-08-01	\N	\N	\N	PERMANENT
397	1351	89	2017-08-01	\N	\N	\N	PERMANENT
398	1352	89	2017-08-01	\N	\N	\N	PERMANENT
399	1353	89	2017-08-01	\N	\N	\N	PERMANENT
400	1354	89	2017-08-01	\N	\N	\N	PERMANENT
401	1355	89	2017-08-01	\N	\N	\N	PERMANENT
402	1356	89	2017-08-01	\N	\N	\N	PERMANENT
403	1357	89	2017-08-03	\N	\N	\N	PERMANENT
404	1358	89	2017-08-01	\N	\N	\N	PERMANENT
405	997	90	2017-08-01	2019-07-31	\N	\N	PERMANENT
406	1359	90	2016-08-01	\N	\N	\N	PERMANENT
407	1360	40	2016-08-01	\N	\N	\N	PERMANENT
408	1361	40	2016-08-08	\N	\N	\N	PERMANENT
409	1362	40	2016-08-01	\N	\N	\N	PERMANENT
410	1363	51	2016-08-01	\N	\N	\N	PERMANENT
411	1364	40	2016-08-01	2018-08-01	\N	\N	PERMANENT
412	1365	12	2016-08-01	2018-12-09	\N	\N	PERMANENT
413	1366	12	2016-08-01	\N	\N	\N	PERMANENT
414	1367	12	2016-08-01	2018-12-01	\N	\N	PERMANENT
415	1368	12	2016-08-01	2019-08-01	\N	\N	PERMANENT
416	1369	1	2017-08-01	\N	\N	\N	PERMANENT
417	1370	1	2016-08-01	\N	\N	\N	PERMANENT
418	1184	8	2016-08-01	2018-08-01	\N	\N	PERMANENT
419	1371	2	2016-08-01	\N	\N	\N	PERMANENT
420	1372	2	2016-08-01	\N	\N	\N	PERMANENT
421	1373	2	2016-08-01	2018-08-01	\N	\N	PERMANENT
422	1374	15	2015-08-01	\N	\N	\N	PERMANENT
423	1375	16	2016-08-01	\N	\N	\N	PERMANENT
424	1376	87	2017-08-01	\N	\N	\N	PERMANENT
425	1377	5	2017-08-01	\N	\N	\N	PERMANENT
426	1378	12	2017-08-01	\N	\N	\N	PERMANENT
427	1379	12	2017-08-01	2018-08-01	\N	\N	PERMANENT
428	1380	12	2017-08-01	\N	\N	\N	PERMANENT
429	1381	12	2017-08-01	2018-08-01	\N	\N	PERMANENT
430	1382	15	2017-08-01	\N	\N	\N	PERMANENT
431	1383	88	2017-08-01	\N	\N	\N	PERMANENT
432	1384	1	2017-08-01	\N	\N	\N	PERMANENT
433	1385	86	2017-08-27	\N	\N	\N	PERMANENT
434	1386	17	2017-08-01	2018-08-01	\N	\N	PERMANENT
435	1387	86	2017-08-01	\N	\N	\N	PERMANENT
436	1388	86	2017-08-01	\N	\N	\N	PERMANENT
437	1389	15	2017-08-01	\N	\N	\N	PERMANENT
438	1390	17	2017-08-01	\N	\N	\N	PERMANENT
439	1391	17	2017-08-01	\N	\N	\N	PERMANENT
440	1392	17	2017-08-01	\N	\N	\N	PERMANENT
441	1393	86	2017-08-01	\N	\N	\N	PERMANENT
442	1394	95	2017-08-01	\N	\N	\N	PERMANENT
443	1395	95	2017-08-01	\N	\N	\N	PERMANENT
444	1396	94	2017-08-01	\N	\N	\N	PERMANENT
445	1397	94	2017-08-01	\N	\N	\N	PERMANENT
446	1398	54	2017-08-01	\N	\N	\N	PERMANENT
447	1399	54	2017-08-01	\N	\N	\N	PERMANENT
448	1400	23	2016-08-01	\N	\N	\N	PERMANENT
449	1401	23	2016-08-01	\N	\N	\N	PERMANENT
450	1402	86	2017-08-01	\N	\N	\N	PERMANENT
451	1403	17	2016-08-01	2018-01-08	\N	\N	PERMANENT
452	1404	87	2017-08-01	\N	\N	\N	PERMANENT
453	1405	2	2017-08-01	\N	\N	\N	PERMANENT
454	1406	96	2017-08-01	\N	\N	\N	PERMANENT
455	1407	88	2017-08-01	\N	\N	\N	PERMANENT
456	1408	17	2017-08-01	2018-12-01	\N	\N	PERMANENT
457	1409	88	2017-08-01	\N	\N	\N	PERMANENT
458	1410	76	2017-08-01	\N	\N	\N	PERMANENT
459	1411	76	2017-08-01	\N	\N	\N	PERMANENT
460	1412	17	2017-08-01	\N	\N	\N	PERMANENT
461	1413	11	2018-08-01	2020-07-30	\N	\N	PERMANENT
462	1085	11	2018-08-01	\N	\N	\N	PERMANENT
463	1414	6	2018-08-01	\N	\N	\N	PERMANENT
464	1415	6	2018-08-01	2018-12-01	\N	\N	PERMANENT
465	1416	6	2018-08-01	\N	\N	\N	PERMANENT
466	1417	6	2018-08-01	\N	\N	\N	PERMANENT
467	1418	6	2018-08-01	\N	\N	\N	PERMANENT
468	1419	6	2018-08-01	2019-08-01	\N	\N	PERMANENT
469	1420	6	2018-08-01	\N	\N	\N	PERMANENT
470	1421	6	2018-08-01	\N	\N	\N	PERMANENT
471	1422	6	2018-08-01	\N	\N	\N	PERMANENT
472	1423	6	2018-08-01	\N	\N	\N	PERMANENT
473	1424	6	2018-08-01	\N	\N	\N	PERMANENT
474	1425	6	2018-08-01	\N	\N	\N	PERMANENT
475	1426	6	2018-08-01	2018-01-08	\N	\N	PERMANENT
476	1427	6	2018-08-01	\N	\N	\N	PERMANENT
477	1379	6	2018-08-01	\N	\N	\N	PERMANENT
478	1428	6	2018-08-01	\N	\N	\N	PERMANENT
479	1429	6	2018-08-01	\N	\N	\N	PERMANENT
480	1430	6	2018-08-01	2019-08-01	\N	\N	PERMANENT
481	1431	6	2018-08-01	\N	\N	\N	PERMANENT
482	1432	6	2018-08-01	\N	\N	\N	PERMANENT
483	1433	6	2018-08-01	\N	\N	\N	PERMANENT
484	1434	6	2018-08-01	\N	\N	\N	PERMANENT
485	1435	6	2018-08-01	\N	\N	\N	PERMANENT
486	1198	6	2018-08-01	\N	\N	\N	PERMANENT
487	1436	6	2018-08-01	\N	\N	\N	PERMANENT
488	1437	6	2018-08-01	\N	\N	\N	PERMANENT
489	1438	6	2018-08-01	\N	\N	\N	PERMANENT
490	1439	6	2018-08-01	\N	\N	\N	PERMANENT
491	1440	6	2018-08-01	\N	\N	\N	PERMANENT
492	1441	6	2018-08-01	\N	\N	\N	PERMANENT
493	1442	6	2018-08-01	\N	\N	\N	PERMANENT
494	979	1	2018-08-01	\N	\N	\N	PERMANENT
495	1219	87	2018-08-01	\N	\N	\N	PERMANENT
496	1234	4	2018-08-01	\N	\N	\N	PERMANENT
497	1443	17	2018-08-01	\N	\N	\N	PERMANENT
498	1444	100	2018-08-01	\N	\N	\N	PERMANENT
499	1258	2	2018-08-01	\N	\N	\N	PERMANENT
500	1381	8	2018-08-01	\N	\N	\N	PERMANENT
501	1445	101	2018-08-01	\N	\N	\N	PERMANENT
502	1446	11	2018-08-01	\N	\N	\N	PERMANENT
503	1447	13	2018-08-01	\N	\N	\N	PERMANENT
504	1448	13	2018-08-01	\N	\N	\N	PERMANENT
505	1238	13	2018-08-01	\N	\N	\N	PERMANENT
506	1449	13	2018-08-01	\N	\N	\N	PERMANENT
507	1450	76	2018-08-01	2018-08-01	\N	\N	PERMANENT
508	1451	76	2018-08-01	\N	\N	\N	PERMANENT
509	1003	76	2018-08-01	\N	\N	\N	PERMANENT
510	1184	76	2018-08-01	\N	\N	\N	PERMANENT
511	1452	12	2018-08-01	\N	\N	\N	PERMANENT
512	1453	1	2018-08-01	\N	\N	\N	PERMANENT
513	1454	1	2018-08-01	2018-08-01	\N	\N	PERMANENT
514	997	1	2018-08-01	2018-08-01	\N	\N	PERMANENT
515	1455	100	2018-08-01	\N	\N	\N	PERMANENT
516	1456	100	2018-08-01	\N	\N	\N	PERMANENT
517	1323	100	2018-08-01	\N	\N	\N	PERMANENT
518	1457	100	2018-08-01	\N	\N	\N	PERMANENT
519	1458	100	2018-08-01	\N	\N	\N	PERMANENT
520	1459	100	2018-08-01	2019-01-01	\N	\N	PERMANENT
521	1460	100	2018-08-01	\N	\N	\N	PERMANENT
522	1230	88	2018-08-01	\N	\N	\N	PERMANENT
523	1461	102	2018-08-01	\N	\N	\N	PERMANENT
524	1260	102	2018-08-01	\N	\N	\N	PERMANENT
525	1373	102	2018-08-01	\N	\N	\N	PERMANENT
526	1462	15	2018-08-01	\N	\N	\N	PERMANENT
527	1002	2	2018-08-01	\N	\N	\N	PERMANENT
528	1463	3	2018-08-01	\N	\N	\N	PERMANENT
529	1464	99	2018-08-01	\N	\N	\N	PERMANENT
530	999	1	2018-08-01	\N	\N	\N	PERMANENT
531	1465	8	2018-08-01	\N	\N	\N	PERMANENT
532	1466	1	2018-08-01	\N	\N	\N	PERMANENT
533	1210	1	2018-08-01	2018-12-01	\N	\N	PERMANENT
534	1364	1	2018-08-01	\N	\N	\N	PERMANENT
535	1467	1	2018-08-01	\N	\N	\N	PERMANENT
536	1468	1	2018-08-01	\N	\N	\N	PERMANENT
537	1469	1	2018-08-01	\N	\N	\N	PERMANENT
538	1470	1	2018-08-01	2020-07-01	\N	\N	PERMANENT
539	1471	1	2018-08-01	\N	\N	\N	PERMANENT
540	1166	1	2018-08-01	\N	\N	\N	PERMANENT
541	1472	11	2018-08-01	\N	\N	\N	PERMANENT
542	1261	11	2018-08-01	2018-08-01	\N	\N	PERMANENT
543	1473	11	2018-08-01	\N	\N	\N	PERMANENT
544	1474	11	2018-08-01	2018-08-01	\N	\N	PERMANENT
545	1475	11	2018-08-01	\N	\N	\N	PERMANENT
546	1476	11	2018-08-01	\N	\N	\N	PERMANENT
547	1477	11	2018-08-01	\N	\N	\N	PERMANENT
548	1242	11	2018-08-01	\N	\N	\N	PERMANENT
549	1478	11	2018-08-01	\N	\N	\N	PERMANENT
550	1286	11	2018-08-01	\N	\N	\N	PERMANENT
551	1479	11	2018-08-01	\N	\N	\N	PERMANENT
552	970	11	2018-08-01	2018-08-01	\N	\N	PERMANENT
553	1480	76	2018-08-01	2018-01-08	\N	\N	PERMANENT
554	1481	76	2018-08-01	\N	\N	\N	PERMANENT
555	1482	76	2018-08-01	\N	\N	\N	PERMANENT
556	1483	76	2018-08-01	\N	\N	\N	PERMANENT
557	1484	76	2018-08-01	\N	\N	\N	PERMANENT
558	1485	76	2018-08-01	\N	\N	\N	PERMANENT
559	1486	76	2018-08-01	\N	\N	\N	PERMANENT
560	1487	76	2018-08-01	\N	\N	\N	PERMANENT
561	1488	76	2018-08-01	\N	\N	\N	PERMANENT
562	1489	76	2018-08-01	\N	\N	\N	PERMANENT
563	1490	76	2018-08-01	\N	\N	\N	PERMANENT
564	1491	76	2018-08-01	\N	\N	\N	PERMANENT
565	1492	76	2018-08-01	\N	\N	\N	PERMANENT
566	970	11	2018-08-01	2018-01-08	\N	\N	PERMANENT
567	1493	76	2018-08-01	2018-08-01	\N	\N	PERMANENT
568	1494	7	2018-08-01	\N	\N	\N	PERMANENT
569	1495	7	2018-08-01	\N	\N	\N	PERMANENT
570	1496	7	2018-08-01	\N	\N	\N	PERMANENT
571	1257	7	2018-08-01	\N	\N	\N	PERMANENT
572	1497	7	2018-08-01	\N	\N	\N	PERMANENT
573	1114	7	2018-08-01	\N	\N	\N	PERMANENT
574	1498	5	2018-08-01	\N	\N	\N	PERMANENT
575	1499	5	2018-08-01	\N	\N	\N	PERMANENT
576	1500	5	2018-08-01	\N	\N	\N	PERMANENT
577	1501	5	2018-08-01	\N	\N	\N	PERMANENT
578	1502	5	2018-08-01	\N	\N	\N	PERMANENT
579	1503	5	2018-08-01	\N	\N	\N	PERMANENT
580	1270	5	2018-08-01	\N	\N	\N	PERMANENT
581	1245	5	2018-08-01	\N	\N	\N	PERMANENT
582	1504	5	2018-08-01	\N	\N	\N	PERMANENT
583	1505	4	2018-08-01	\N	\N	\N	PERMANENT
584	1506	4	2018-08-01	\N	\N	\N	PERMANENT
585	1507	4	2018-08-01	\N	\N	\N	PERMANENT
586	1508	4	2018-08-01	\N	\N	\N	PERMANENT
587	1509	4	2018-08-01	\N	\N	\N	PERMANENT
588	1510	4	2018-08-01	\N	\N	\N	PERMANENT
589	1511	4	2018-08-01	\N	\N	\N	PERMANENT
590	1512	4	2018-08-01	\N	\N	\N	PERMANENT
591	1513	4	2018-08-01	\N	\N	\N	PERMANENT
592	1514	4	2018-08-01	\N	\N	\N	PERMANENT
593	1235	4	2018-08-01	\N	\N	\N	PERMANENT
594	1515	4	2018-08-01	\N	\N	\N	PERMANENT
595	1516	4	2018-08-01	\N	\N	\N	PERMANENT
596	1517	4	2018-08-01	\N	\N	\N	PERMANENT
597	1518	4	2018-08-01	\N	\N	\N	PERMANENT
598	1519	4	2018-08-01	\N	\N	\N	PERMANENT
599	1226	4	2018-08-01	\N	\N	\N	PERMANENT
600	1520	4	2018-08-01	\N	\N	\N	PERMANENT
601	1315	4	2018-08-01	\N	\N	\N	PERMANENT
602	1521	4	2018-08-01	\N	\N	\N	PERMANENT
603	1522	4	2018-08-01	2018-08-01	\N	\N	PERMANENT
604	1523	4	2018-08-01	\N	\N	\N	PERMANENT
605	1229	4	2018-08-01	\N	\N	\N	PERMANENT
606	1252	4	2018-08-01	\N	\N	\N	PERMANENT
607	1524	4	2018-08-01	\N	\N	\N	PERMANENT
608	1525	4	2018-08-01	\N	\N	\N	PERMANENT
609	1526	4	2018-08-01	\N	\N	\N	PERMANENT
610	1527	4	2018-08-01	\N	\N	\N	PERMANENT
611	1528	4	2018-08-01	\N	\N	\N	PERMANENT
612	1529	4	2018-08-01	\N	\N	\N	PERMANENT
613	1530	4	2018-08-01	\N	\N	\N	PERMANENT
614	1531	3	2018-08-01	\N	\N	\N	PERMANENT
615	1324	3	2018-08-01	2018-08-01	\N	\N	PERMANENT
616	1532	3	2018-08-01	\N	\N	\N	PERMANENT
617	1261	3	2018-08-01	2018-01-08	\N	\N	PERMANENT
618	1533	3	2018-08-01	\N	\N	\N	PERMANENT
619	1534	3	2018-08-01	\N	\N	\N	PERMANENT
620	1105	3	2018-08-01	\N	\N	\N	PERMANENT
621	1535	3	2018-08-01	\N	\N	\N	PERMANENT
622	1536	3	2018-08-01	\N	\N	\N	PERMANENT
623	1537	3	2018-08-01	\N	\N	\N	PERMANENT
624	1538	3	2018-08-01	\N	\N	\N	PERMANENT
625	1236	3	2018-08-01	2019-08-01	\N	\N	PERMANENT
626	1539	3	2018-08-01	\N	\N	\N	PERMANENT
627	1540	3	2018-08-01	\N	\N	\N	PERMANENT
628	1541	3	2018-08-01	\N	\N	\N	PERMANENT
629	1542	3	2018-08-01	\N	\N	\N	PERMANENT
630	1543	3	2018-08-01	\N	\N	\N	PERMANENT
631	1544	3	2018-08-01	\N	\N	\N	PERMANENT
632	1545	3	2018-08-01	\N	\N	\N	PERMANENT
633	1546	3	2018-08-01	\N	\N	\N	PERMANENT
634	1547	3	2018-08-01	\N	\N	\N	PERMANENT
635	1548	3	2018-08-01	\N	\N	\N	PERMANENT
636	1549	3	2018-08-01	\N	\N	\N	PERMANENT
637	1522	3	2018-08-01	\N	\N	\N	PERMANENT
638	1550	3	2018-08-01	\N	\N	\N	PERMANENT
639	1551	3	2018-08-01	\N	\N	\N	PERMANENT
640	1552	3	2018-08-01	\N	\N	\N	PERMANENT
641	1553	3	2018-08-01	\N	\N	\N	PERMANENT
642	1106	3	2018-08-01	\N	\N	\N	PERMANENT
643	1030	3	2018-08-01	\N	\N	\N	PERMANENT
644	1554	102	2018-08-01	\N	\N	\N	PERMANENT
645	1555	102	2018-08-01	\N	\N	\N	PERMANENT
646	1556	102	2018-08-01	\N	\N	\N	PERMANENT
647	1280	102	2018-08-01	\N	\N	\N	PERMANENT
648	1557	102	2018-08-01	\N	\N	\N	PERMANENT
649	1311	102	2018-08-01	\N	\N	\N	PERMANENT
650	1306	102	2018-08-01	\N	\N	\N	PERMANENT
651	1558	102	2018-08-01	\N	\N	\N	PERMANENT
652	1101	102	2018-08-01	\N	\N	\N	PERMANENT
653	1559	102	2018-08-01	\N	\N	\N	PERMANENT
654	1182	102	2018-08-01	\N	\N	\N	PERMANENT
655	1560	102	2018-08-01	\N	\N	\N	PERMANENT
656	1300	102	2018-08-01	\N	\N	\N	PERMANENT
657	1561	102	2018-08-01	\N	\N	\N	PERMANENT
658	1299	102	2018-08-01	\N	\N	\N	PERMANENT
659	1562	102	2018-08-01	\N	\N	\N	PERMANENT
660	1563	102	2018-08-01	\N	\N	\N	PERMANENT
661	1564	102	2018-08-01	\N	\N	\N	PERMANENT
662	1186	102	2018-08-01	2018-12-01	\N	\N	PERMANENT
663	1066	102	2018-08-01	2020-01-01	\N	\N	PERMANENT
664	1565	102	2018-08-01	\N	\N	\N	PERMANENT
665	1566	102	2018-08-01	\N	\N	\N	PERMANENT
666	1567	87	2018-08-01	\N	\N	\N	PERMANENT
667	1568	87	2018-08-01	2018-08-01	\N	\N	PERMANENT
668	1569	87	2018-08-01	\N	\N	\N	PERMANENT
669	1570	87	2018-08-01	\N	\N	\N	PERMANENT
670	1571	87	2018-08-01	\N	\N	\N	PERMANENT
671	1572	87	2018-08-01	\N	\N	\N	PERMANENT
672	1573	87	2018-08-01	\N	\N	\N	PERMANENT
673	1574	87	2018-08-01	\N	\N	\N	PERMANENT
674	1575	87	2018-08-01	\N	\N	\N	PERMANENT
675	1576	87	2018-08-01	\N	\N	\N	PERMANENT
676	1577	87	2018-08-01	\N	\N	\N	PERMANENT
677	1578	87	2018-08-01	\N	\N	\N	PERMANENT
678	1579	87	2018-08-01	\N	\N	\N	PERMANENT
679	1580	87	2018-08-01	\N	\N	\N	PERMANENT
680	1581	87	2018-08-01	\N	\N	\N	PERMANENT
681	959	87	2018-08-01	\N	\N	\N	PERMANENT
682	1582	87	2018-08-01	\N	\N	\N	PERMANENT
683	1261	87	2018-08-01	\N	\N	\N	PERMANENT
684	1583	87	2018-08-01	\N	\N	\N	PERMANENT
685	1584	87	2018-08-01	\N	\N	\N	PERMANENT
686	1585	87	2018-08-01	\N	\N	\N	PERMANENT
687	1586	87	2018-08-01	\N	\N	\N	PERMANENT
688	1205	87	2018-08-01	\N	\N	\N	PERMANENT
689	1587	87	2018-08-01	\N	\N	\N	PERMANENT
690	1403	87	2018-08-01	\N	\N	\N	PERMANENT
691	1588	87	2018-08-01	\N	\N	\N	PERMANENT
692	1589	87	2018-08-01	\N	\N	\N	PERMANENT
693	1590	87	2018-08-01	\N	\N	\N	PERMANENT
694	1591	87	2018-08-01	\N	\N	\N	PERMANENT
695	1592	87	2018-08-01	\N	\N	\N	PERMANENT
696	1593	87	2018-08-01	\N	\N	\N	PERMANENT
697	1594	87	2018-08-01	\N	\N	\N	PERMANENT
698	1480	87	2018-08-01	\N	\N	\N	PERMANENT
699	1595	87	2018-08-01	\N	\N	\N	PERMANENT
700	1568	2	2018-08-01	\N	\N	\N	PERMANENT
701	1596	2	2018-08-01	\N	\N	\N	PERMANENT
702	1597	2	2018-08-01	\N	\N	\N	PERMANENT
703	1598	2	2018-08-01	\N	\N	\N	PERMANENT
704	1599	2	2018-08-01	\N	\N	\N	PERMANENT
705	1600	2	2018-08-01	\N	\N	\N	PERMANENT
706	1601	2	2018-08-01	\N	\N	\N	PERMANENT
707	1602	2	2018-08-01	\N	\N	\N	PERMANENT
708	1195	2	2018-08-01	\N	\N	\N	PERMANENT
709	1603	2	2018-08-01	\N	\N	\N	PERMANENT
710	990	2	2018-08-01	2018-08-01	\N	\N	PERMANENT
711	1604	2	2018-08-01	\N	\N	\N	PERMANENT
712	1247	2	2018-08-01	\N	\N	\N	PERMANENT
713	1605	2	2018-08-01	\N	\N	\N	PERMANENT
714	1069	2	2018-08-01	\N	\N	\N	PERMANENT
715	1606	2	2018-08-01	\N	\N	\N	PERMANENT
716	1607	2	2018-08-01	\N	\N	\N	PERMANENT
717	1608	2	2018-08-01	\N	\N	\N	PERMANENT
718	1609	2	2018-08-01	\N	\N	\N	PERMANENT
719	1610	17	2018-08-01	\N	\N	\N	PERMANENT
720	1611	17	2018-08-01	\N	\N	\N	PERMANENT
721	1612	17	2018-08-01	\N	\N	\N	PERMANENT
722	1613	17	2018-08-01	\N	\N	\N	PERMANENT
723	1614	17	2018-08-01	\N	\N	\N	PERMANENT
724	1615	17	2018-08-01	\N	\N	\N	PERMANENT
725	1616	17	2018-08-01	\N	\N	\N	PERMANENT
726	1617	17	2018-08-01	\N	\N	\N	PERMANENT
727	1618	17	2018-08-01	\N	\N	\N	PERMANENT
728	1619	17	2018-08-01	2018-12-01	\N	\N	PERMANENT
729	1620	17	2018-08-01	\N	\N	\N	PERMANENT
730	1621	17	2018-08-01	\N	\N	\N	PERMANENT
731	1622	17	2018-08-01	\N	\N	\N	PERMANENT
732	1623	17	2018-08-01	\N	\N	\N	PERMANENT
733	1624	17	2018-08-01	\N	\N	\N	PERMANENT
734	1328	17	2018-08-01	\N	\N	\N	PERMANENT
735	1625	17	2018-08-01	\N	\N	\N	PERMANENT
736	1626	17	2018-08-01	\N	\N	\N	PERMANENT
737	1627	17	2018-08-01	\N	\N	\N	PERMANENT
738	1628	17	2018-08-01	\N	\N	\N	PERMANENT
739	1629	17	2018-08-01	\N	\N	\N	PERMANENT
740	1630	17	2018-08-01	\N	\N	\N	PERMANENT
741	1631	17	2018-08-01	\N	\N	\N	PERMANENT
742	1632	17	2018-08-01	\N	\N	\N	PERMANENT
743	1633	17	2018-08-01	\N	\N	\N	PERMANENT
744	1634	17	2018-08-01	\N	\N	\N	PERMANENT
745	1635	17	2018-08-01	\N	\N	\N	PERMANENT
746	1636	17	2018-08-01	\N	\N	\N	PERMANENT
747	1637	17	2018-08-01	\N	\N	\N	PERMANENT
748	1638	88	2018-08-01	\N	\N	\N	PERMANENT
749	1221	88	2018-08-01	\N	\N	\N	PERMANENT
750	1188	88	2018-08-01	\N	\N	\N	PERMANENT
751	1639	1	2018-08-01	2018-08-01	\N	\N	PERMANENT
752	1639	88	2018-08-01	\N	\N	\N	PERMANENT
753	1640	88	2018-08-01	\N	\N	\N	PERMANENT
754	1246	88	2018-08-01	\N	\N	\N	PERMANENT
755	1641	88	2018-08-01	\N	\N	\N	PERMANENT
756	1642	88	2018-08-01	\N	\N	\N	PERMANENT
757	1643	88	2018-08-01	\N	\N	\N	PERMANENT
758	1644	88	2018-08-01	\N	\N	\N	PERMANENT
759	1343	88	2018-08-01	\N	\N	\N	PERMANENT
760	1645	88	2018-08-01	\N	\N	\N	PERMANENT
761	1646	88	2018-08-01	\N	\N	\N	PERMANENT
762	1647	88	2018-08-01	\N	\N	\N	PERMANENT
763	1648	88	2018-08-01	\N	\N	\N	PERMANENT
764	1649	88	2018-08-01	\N	\N	\N	PERMANENT
765	1650	88	2018-08-01	\N	\N	\N	PERMANENT
766	1651	88	2018-08-01	\N	\N	\N	PERMANENT
767	1450	88	2018-08-01	\N	\N	\N	PERMANENT
768	1324	88	2018-08-01	2018-01-08	\N	\N	PERMANENT
769	1454	88	2018-08-01	2019-08-01	\N	\N	PERMANENT
770	1263	88	2018-08-01	\N	\N	\N	PERMANENT
771	1652	88	2018-08-01	\N	\N	\N	PERMANENT
772	1079	88	2018-08-01	\N	\N	\N	PERMANENT
773	1653	88	2018-08-01	\N	\N	\N	PERMANENT
774	1654	88	2018-08-01	\N	\N	\N	PERMANENT
775	990	88	2018-08-01	\N	\N	\N	PERMANENT
776	1655	88	2018-08-01	\N	\N	\N	PERMANENT
777	1656	88	2018-08-01	\N	\N	\N	PERMANENT
778	1657	88	2018-08-01	\N	\N	\N	PERMANENT
779	1658	88	2018-08-01	\N	\N	\N	PERMANENT
780	1021	88	2018-08-01	\N	\N	\N	PERMANENT
781	1659	88	2018-08-01	\N	\N	\N	PERMANENT
782	1660	88	2018-08-01	\N	\N	\N	PERMANENT
783	974	88	2018-08-01	\N	\N	\N	PERMANENT
784	1386	88	2018-08-01	\N	\N	\N	PERMANENT
785	1661	12	2018-08-01	\N	\N	\N	PERMANENT
786	1662	12	2018-08-01	\N	\N	\N	PERMANENT
787	1663	12	2018-08-01	\N	\N	\N	PERMANENT
788	1664	12	2018-08-01	\N	\N	\N	PERMANENT
789	1665	12	2018-08-01	\N	\N	\N	PERMANENT
790	1666	12	2018-08-01	\N	\N	\N	PERMANENT
791	1667	12	2018-08-01	\N	\N	\N	PERMANENT
792	1668	12	2018-08-01	\N	\N	\N	PERMANENT
793	1232	12	2018-08-01	\N	\N	\N	PERMANENT
794	1669	12	2018-08-01	\N	\N	\N	PERMANENT
795	1670	12	2018-08-01	\N	\N	\N	PERMANENT
796	1671	12	2018-08-01	\N	\N	\N	PERMANENT
797	1672	12	2018-08-01	\N	\N	\N	PERMANENT
798	1673	12	2018-08-01	\N	\N	\N	PERMANENT
799	1172	12	2018-08-01	\N	\N	\N	PERMANENT
800	1674	12	2018-08-01	\N	\N	\N	PERMANENT
801	1196	12	2018-08-01	\N	\N	\N	PERMANENT
802	1675	12	2018-08-01	\N	\N	\N	PERMANENT
803	1676	12	2018-08-01	\N	\N	\N	PERMANENT
804	1677	12	2018-08-01	\N	\N	\N	PERMANENT
805	1678	12	2018-08-01	\N	\N	\N	PERMANENT
806	1679	12	2018-08-01	\N	\N	\N	PERMANENT
807	1680	12	2018-08-01	\N	\N	\N	PERMANENT
808	1681	13	2018-08-01	\N	\N	\N	PERMANENT
809	1682	13	2018-08-01	\N	\N	\N	PERMANENT
810	1683	13	2018-08-01	\N	\N	\N	PERMANENT
811	1684	13	2018-08-01	\N	\N	\N	PERMANENT
812	1685	13	2018-08-01	\N	\N	\N	PERMANENT
813	1686	13	2018-08-01	\N	\N	\N	PERMANENT
814	1687	13	2018-08-01	\N	\N	\N	PERMANENT
815	1688	13	2018-08-01	\N	\N	\N	PERMANENT
816	1689	13	2018-08-01	\N	\N	\N	PERMANENT
817	1690	13	2018-08-01	\N	\N	\N	PERMANENT
818	1691	13	2018-08-01	\N	\N	\N	PERMANENT
819	1692	101	2018-08-01	\N	\N	\N	PERMANENT
820	1693	101	2018-08-01	\N	\N	\N	PERMANENT
821	1694	101	2018-08-01	\N	\N	\N	PERMANENT
822	1695	101	2018-08-01	\N	\N	\N	PERMANENT
823	1696	101	2018-08-01	\N	\N	\N	PERMANENT
824	1697	101	2018-08-01	\N	\N	\N	PERMANENT
825	1698	101	2018-08-01	\N	\N	\N	PERMANENT
826	1699	101	2018-08-01	\N	\N	\N	PERMANENT
827	1700	101	2018-08-01	\N	\N	\N	PERMANENT
828	1701	101	2018-08-01	\N	\N	\N	PERMANENT
829	1702	101	2018-08-01	\N	\N	\N	PERMANENT
830	1703	101	2018-08-01	\N	\N	\N	PERMANENT
831	1704	101	2018-08-01	\N	\N	\N	PERMANENT
832	1705	101	2018-08-01	\N	\N	\N	PERMANENT
833	1706	101	2018-08-01	\N	\N	\N	PERMANENT
834	1707	101	2018-08-01	\N	\N	\N	PERMANENT
835	1708	101	2018-08-01	\N	\N	\N	PERMANENT
836	1709	101	2018-08-01	\N	\N	\N	PERMANENT
837	1710	101	2018-08-01	\N	\N	\N	PERMANENT
838	1711	101	2018-08-01	\N	\N	\N	PERMANENT
839	1712	101	2018-08-01	\N	\N	\N	PERMANENT
840	1713	101	2018-08-01	\N	\N	\N	PERMANENT
841	1714	101	2018-08-01	\N	\N	\N	PERMANENT
842	1715	101	2018-08-01	\N	\N	\N	PERMANENT
843	1716	101	2018-08-01	\N	\N	\N	PERMANENT
844	1717	101	2018-08-01	\N	\N	\N	PERMANENT
845	1718	101	2018-08-01	\N	\N	\N	PERMANENT
846	1719	101	2018-08-01	\N	\N	\N	PERMANENT
847	1720	101	2018-08-01	\N	\N	\N	PERMANENT
848	1721	101	2018-08-01	\N	\N	\N	PERMANENT
849	1722	101	2018-08-01	\N	\N	\N	PERMANENT
850	1723	101	2018-08-01	\N	\N	\N	PERMANENT
851	1724	101	2018-08-01	\N	\N	\N	PERMANENT
852	1725	101	2018-08-01	\N	\N	\N	PERMANENT
853	1726	101	2018-08-01	\N	\N	\N	PERMANENT
854	1727	101	2018-08-01	\N	\N	\N	PERMANENT
855	1728	101	2018-08-01	\N	\N	\N	PERMANENT
856	1153	101	2018-08-01	\N	\N	\N	PERMANENT
857	1729	101	2018-08-01	\N	\N	\N	PERMANENT
858	1730	101	2018-08-01	\N	\N	\N	PERMANENT
859	1731	101	2018-08-01	\N	\N	\N	PERMANENT
860	1732	101	2018-08-01	\N	\N	\N	PERMANENT
861	1733	101	2018-08-01	2019-08-01	\N	\N	PERMANENT
862	1734	101	2018-08-01	\N	\N	\N	PERMANENT
863	1735	101	2018-08-01	\N	\N	\N	PERMANENT
864	1736	101	2018-08-01	\N	\N	\N	PERMANENT
865	1737	101	2018-08-01	\N	\N	\N	PERMANENT
866	1738	99	2018-08-01	\N	\N	\N	PERMANENT
867	1739	99	2018-08-01	\N	\N	\N	PERMANENT
868	1740	99	2018-08-01	\N	\N	\N	PERMANENT
869	1741	99	2018-08-01	\N	\N	\N	PERMANENT
870	1046	99	2018-08-01	\N	\N	\N	PERMANENT
871	1742	99	2018-08-08	\N	\N	\N	PERMANENT
872	1743	99	2018-08-01	\N	\N	\N	PERMANENT
873	1744	99	2018-08-01	\N	\N	\N	PERMANENT
874	1745	99	2018-08-01	\N	\N	\N	PERMANENT
875	1746	99	2018-08-01	\N	\N	\N	PERMANENT
876	1747	99	2018-08-01	\N	\N	\N	PERMANENT
877	1748	99	2018-08-01	\N	\N	\N	PERMANENT
878	1749	99	2018-08-01	\N	\N	\N	PERMANENT
879	1750	99	2018-08-01	\N	\N	\N	PERMANENT
880	1751	99	2018-08-01	\N	\N	\N	PERMANENT
881	1752	99	2018-08-01	\N	\N	\N	PERMANENT
882	1753	99	2018-08-01	\N	\N	\N	PERMANENT
883	1754	99	2018-08-01	\N	\N	\N	PERMANENT
884	1755	99	2018-08-01	\N	\N	\N	PERMANENT
885	1756	99	2018-08-01	\N	\N	\N	PERMANENT
886	1757	99	2018-08-01	\N	\N	\N	PERMANENT
887	1758	99	2018-08-01	\N	\N	\N	PERMANENT
888	1759	99	2018-08-01	\N	\N	\N	PERMANENT
889	1760	99	2018-08-01	\N	\N	\N	PERMANENT
890	1761	99	2018-08-01	\N	\N	\N	PERMANENT
891	1762	99	2018-08-01	\N	\N	\N	PERMANENT
892	1763	99	2018-08-01	2020-01-01	\N	\N	PERMANENT
893	1764	99	2018-08-01	\N	\N	\N	PERMANENT
894	986	99	2018-08-01	2019-08-01	\N	\N	PERMANENT
895	1765	99	2018-08-01	\N	\N	\N	PERMANENT
896	1766	100	2018-08-01	\N	\N	\N	PERMANENT
897	1767	100	2018-08-01	\N	\N	\N	PERMANENT
898	1768	100	2018-08-01	\N	\N	\N	PERMANENT
899	1769	100	2018-08-01	\N	\N	\N	PERMANENT
900	1770	100	2018-08-01	\N	\N	\N	PERMANENT
901	1771	100	2018-08-01	\N	\N	\N	PERMANENT
902	1772	100	2018-08-01	\N	\N	\N	PERMANENT
903	1773	100	2018-08-01	2019-08-01	\N	\N	PERMANENT
904	1271	100	2018-08-01	\N	\N	\N	PERMANENT
905	1774	100	2018-08-01	\N	\N	\N	PERMANENT
906	1775	100	2018-08-01	\N	\N	\N	PERMANENT
907	1776	100	2018-08-01	\N	\N	\N	PERMANENT
908	1777	100	2018-08-01	\N	\N	\N	PERMANENT
909	1778	100	2018-08-01	\N	\N	\N	PERMANENT
910	1779	100	2018-08-01	\N	\N	\N	PERMANENT
911	1474	100	2018-08-01	\N	\N	\N	PERMANENT
912	1780	100	2018-08-01	\N	\N	\N	PERMANENT
913	1781	100	2018-08-01	\N	\N	\N	PERMANENT
914	1782	100	2018-08-01	\N	\N	\N	PERMANENT
915	1783	100	2018-08-01	\N	\N	\N	PERMANENT
916	1784	100	2018-08-01	\N	\N	\N	PERMANENT
917	1785	100	2018-08-01	\N	\N	\N	PERMANENT
918	1786	100	2018-08-01	\N	\N	\N	PERMANENT
919	1104	100	2018-08-01	\N	\N	\N	PERMANENT
920	1787	100	2018-08-01	\N	\N	\N	PERMANENT
921	1788	100	2018-08-01	\N	\N	\N	PERMANENT
922	1129	15	2018-08-01	\N	\N	\N	PERMANENT
923	1789	15	2018-08-01	\N	\N	\N	PERMANENT
924	1790	15	2018-08-01	\N	\N	\N	PERMANENT
925	1791	15	2018-08-01	\N	\N	\N	PERMANENT
926	1792	15	2018-08-01	\N	\N	\N	PERMANENT
927	1426	15	2018-01-08	\N	\N	\N	PERMANENT
928	1793	15	2018-08-01	\N	\N	\N	PERMANENT
929	1220	15	2018-01-08	\N	\N	\N	PERMANENT
930	1794	15	2018-08-01	\N	\N	\N	PERMANENT
931	1795	15	2018-08-01	\N	\N	\N	PERMANENT
932	1796	15	2018-08-01	\N	\N	\N	PERMANENT
933	1797	15	2018-08-01	\N	\N	\N	PERMANENT
934	1272	15	2018-01-08	\N	\N	\N	PERMANENT
935	1798	8	2018-08-01	\N	\N	\N	PERMANENT
936	1799	8	2018-08-01	\N	\N	\N	PERMANENT
937	1800	8	2018-08-01	\N	\N	\N	PERMANENT
938	1801	8	2018-08-01	\N	\N	\N	PERMANENT
939	1802	8	2018-08-01	\N	\N	\N	PERMANENT
940	1803	8	2018-08-01	\N	\N	\N	PERMANENT
941	1804	8	2018-08-01	\N	\N	\N	PERMANENT
942	1805	8	2018-08-01	\N	\N	\N	PERMANENT
943	1806	8	2018-08-01	\N	\N	\N	PERMANENT
944	1807	8	2018-08-01	\N	\N	\N	PERMANENT
945	1808	8	2018-08-01	\N	\N	\N	PERMANENT
946	1317	8	2018-01-08	\N	\N	\N	PERMANENT
947	1324	8	2018-01-08	\N	\N	\N	PERMANENT
948	1809	8	2018-08-01	\N	\N	\N	PERMANENT
949	970	8	2018-01-08	\N	\N	\N	PERMANENT
950	1004	8	2018-01-08	\N	\N	\N	PERMANENT
951	1810	8	2018-08-01	\N	\N	\N	PERMANENT
952	1811	8	2018-08-01	\N	\N	\N	PERMANENT
953	1251	8	2018-01-08	\N	\N	\N	PERMANENT
954	1812	8	2018-08-01	\N	\N	\N	PERMANENT
955	1813	8	2018-08-01	\N	\N	\N	PERMANENT
956	1814	8	2018-08-01	\N	\N	\N	PERMANENT
957	1815	8	2018-08-01	\N	\N	\N	PERMANENT
958	1816	8	2018-08-01	\N	\N	\N	PERMANENT
959	1817	8	2018-08-01	\N	\N	\N	PERMANENT
960	1283	8	2018-01-08	\N	\N	\N	PERMANENT
961	1818	8	2018-08-01	\N	\N	\N	PERMANENT
962	1819	8	2018-08-01	\N	\N	\N	PERMANENT
963	1820	8	2018-08-01	\N	\N	\N	PERMANENT
964	1821	8	2018-08-01	\N	\N	\N	PERMANENT
965	1822	8	2018-08-01	2019-08-01	\N	\N	PERMANENT
966	1005	8	2018-01-08	\N	\N	\N	PERMANENT
967	1823	8	2018-08-01	\N	\N	\N	PERMANENT
968	1824	8	2018-08-01	\N	\N	\N	PERMANENT
969	1825	8	2018-08-01	\N	\N	\N	PERMANENT
970	1269	8	2018-01-08	\N	\N	\N	PERMANENT
971	1826	8	2018-08-01	\N	\N	\N	PERMANENT
972	1827	32	2018-08-01	\N	\N	\N	PERMANENT
973	1828	100	2018-08-01	\N	\N	\N	PERMANENT
974	1096	99	2018-12-11	2019-08-01	\N	\N	PERMANENT
975	1365	99	2018-12-09	2019-08-01	\N	\N	PERMANENT
976	1210	17	2018-12-01	2019-08-01	\N	\N	PERMANENT
977	1233	6	2018-12-01	2019-08-01	\N	\N	PERMANENT
978	1829	112	2018-07-01	\N	\N	\N	PERMANENT
979	1830	112	2018-08-01	\N	\N	\N	PERMANENT
980	1831	113	2018-08-01	\N	\N	\N	PERMANENT
981	1832	116	2017-08-01	\N	\N	\N	PERMANENT
982	1833	115	2018-08-01	\N	\N	\N	PERMANENT
983	1834	122	2018-08-01	\N	\N	\N	PERMANENT
984	1835	122	2018-08-01	\N	\N	\N	PERMANENT
985	1836	107	2018-08-01	\N	\N	\N	PERMANENT
986	1837	110	2018-08-01	\N	\N	\N	PERMANENT
987	1838	76	2018-08-01	\N	\N	\N	PERMANENT
988	1839	109	2018-08-01	\N	\N	\N	PERMANENT
989	1840	109	2018-08-01	\N	\N	\N	PERMANENT
990	1841	106	2018-08-01	\N	\N	\N	PERMANENT
991	1842	107	2018-08-01	\N	\N	\N	PERMANENT
992	1843	72	2018-08-01	\N	\N	\N	PERMANENT
993	983	1	2018-12-01	\N	\N	\N	PERMANENT
994	1844	110	2018-08-01	\N	\N	\N	PERMANENT
995	1845	108	2018-08-01	\N	\N	\N	PERMANENT
996	1619	101	2018-12-01	\N	\N	\N	PERMANENT
997	1846	72	2018-08-01	\N	\N	\N	PERMANENT
998	1847	72	2018-08-01	\N	\N	\N	PERMANENT
999	1848	110	2018-08-01	\N	\N	\N	PERMANENT
1000	1849	76	2018-08-01	\N	\N	\N	PERMANENT
1001	1070	101	2018-12-01	2019-08-01	\N	\N	PERMANENT
1002	978	6	2018-12-01	\N	\N	\N	PERMANENT
1003	1223	4	2018-12-01	\N	\N	\N	PERMANENT
1004	1408	102	2018-12-01	\N	\N	\N	PERMANENT
1005	1850	123	2018-08-01	\N	\N	\N	PERMANENT
1006	1851	123	2018-08-01	\N	\N	\N	PERMANENT
1007	1852	123	2018-08-01	\N	\N	\N	PERMANENT
1008	1853	123	2018-08-01	\N	\N	\N	PERMANENT
1009	1854	122	2018-08-01	\N	\N	\N	PERMANENT
1010	1855	122	2018-08-01	\N	\N	\N	PERMANENT
1011	1856	122	2018-08-01	\N	\N	\N	PERMANENT
1012	1857	122	2018-08-01	\N	\N	\N	PERMANENT
1013	1858	116	2018-08-01	\N	\N	\N	PERMANENT
1014	1859	125	2018-08-01	\N	\N	\N	PERMANENT
1015	1860	125	2018-08-01	\N	\N	\N	PERMANENT
1016	1861	124	2018-08-01	\N	\N	\N	PERMANENT
1017	1862	124	2018-08-01	\N	\N	\N	PERMANENT
1018	1863	113	2018-08-01	\N	\N	\N	PERMANENT
1019	1864	113	2018-08-01	\N	\N	\N	PERMANENT
1020	1865	113	2018-08-01	\N	\N	\N	PERMANENT
1021	1866	111	2018-08-01	\N	\N	\N	PERMANENT
1022	1867	114	2018-08-01	\N	\N	\N	PERMANENT
1023	1868	119	2018-08-01	\N	\N	\N	PERMANENT
1024	1869	119	2018-08-01	\N	\N	\N	PERMANENT
1025	1870	119	2018-08-01	\N	\N	\N	PERMANENT
1026	1871	125	2018-08-01	\N	\N	\N	PERMANENT
1027	1872	125	2018-08-01	\N	\N	\N	PERMANENT
1028	1873	125	2018-08-01	\N	\N	\N	PERMANENT
1029	1874	115	2018-08-01	\N	\N	\N	PERMANENT
1030	1875	117	2018-08-01	\N	\N	\N	PERMANENT
1031	1876	117	2018-08-01	\N	\N	\N	PERMANENT
1032	1877	123	2018-08-01	\N	\N	\N	PERMANENT
1033	1878	114	2018-08-01	\N	\N	\N	PERMANENT
1034	1879	114	2018-08-01	\N	\N	\N	PERMANENT
1035	1880	114	2018-08-01	\N	\N	\N	PERMANENT
1036	1881	114	2018-08-01	\N	\N	\N	PERMANENT
1037	1882	114	2019-02-01	\N	\N	\N	PERMANENT
1038	1883	111	2018-08-01	\N	\N	\N	PERMANENT
1039	1884	111	2018-08-01	\N	\N	\N	PERMANENT
1040	1885	119	2018-08-01	\N	\N	\N	PERMANENT
1041	1331	102	2018-12-01	\N	\N	\N	PERMANENT
1042	1314	3	2018-12-01	\N	\N	\N	PERMANENT
1043	1886	8	2018-08-01	\N	\N	\N	PERMANENT
1044	1887	6	2018-08-01	2019-08-01	\N	\N	PERMANENT
1045	1322	87	2018-06-01	\N	\N	\N	PERMANENT
1046	1415	13	2018-12-01	2019-08-01	\N	\N	PERMANENT
1047	1888	3	2017-08-01	\N	\N	\N	PERMANENT
1048	1889	115	2018-08-01	\N	\N	\N	PERMANENT
1049	1890	124	2017-08-01	\N	\N	\N	PERMANENT
1050	1891	116	2017-08-01	\N	\N	\N	PERMANENT
1051	1165	87	2018-02-08	\N	\N	\N	PERMANENT
1052	1186	8	2018-12-01	2019-08-01	\N	\N	PERMANENT
1053	1892	120	2018-08-01	\N	\N	\N	PERMANENT
1054	1893	121	2018-08-01	\N	\N	\N	PERMANENT
1055	1894	121	2018-08-01	\N	\N	\N	PERMANENT
1056	1895	119	2018-08-01	\N	\N	\N	PERMANENT
1057	1896	119	2018-08-01	\N	\N	\N	PERMANENT
1058	1897	125	2018-08-01	\N	\N	\N	PERMANENT
1059	1898	111	2018-08-01	\N	\N	\N	PERMANENT
1060	1899	117	2018-08-01	\N	\N	\N	PERMANENT
1061	1900	118	2018-08-01	\N	\N	\N	PERMANENT
1062	1901	118	2018-08-01	\N	\N	\N	PERMANENT
1063	1902	115	2018-08-01	\N	\N	\N	PERMANENT
1064	1903	121	2018-08-01	\N	\N	\N	PERMANENT
1065	1904	120	2018-08-01	\N	\N	\N	PERMANENT
1066	1905	113	2018-08-01	\N	\N	\N	PERMANENT
1067	1906	113	2018-08-01	\N	\N	\N	PERMANENT
1068	1367	101	2018-12-01	2020-01-01	\N	\N	PERMANENT
1069	1907	130	2018-08-01	\N	\N	\N	PERMANENT
1070	1908	130	2018-08-01	\N	\N	\N	PERMANENT
1071	1909	130	2018-08-01	\N	\N	\N	PERMANENT
1072	1910	131	2018-08-01	\N	\N	\N	PERMANENT
1073	1911	131	2018-08-01	\N	\N	\N	PERMANENT
1074	1912	131	2018-08-01	\N	\N	\N	PERMANENT
1075	1913	130	2018-08-01	\N	\N	\N	PERMANENT
1076	1914	129	2018-08-01	\N	\N	\N	PERMANENT
1077	1915	133	2018-08-01	\N	\N	\N	PERMANENT
1078	1916	133	2018-08-01	\N	\N	\N	PERMANENT
1079	1917	122	2013-08-01	\N	\N	\N	PERMANENT
1080	1918	74	2018-08-01	2021-04-30	\N	\N	PERMANENT
1081	1919	74	2018-08-01	2020-04-30	\N	\N	PERMANENT
1082	1920	74	2018-08-01	2020-04-30	\N	\N	PERMANENT
1083	1921	74	2017-08-01	2020-04-30	\N	\N	PERMANENT
1084	1922	5	2017-07-01	2020-05-03	\N	\N	PERMANENT
1085	1459	6	2019-01-01	\N	\N	\N	PERMANENT
1086	975	15	2019-01-01	\N	\N	\N	PERMANENT
1087	1923	137	2018-07-01	2020-05-10	\N	\N	PERMANENT
1088	1924	153	2019-08-01	2020-08-01	\N	\N	PERMANENT
1089	1925	153	2019-08-01	2020-08-01	\N	\N	PERMANENT
1090	1926	53	2019-06-01	2019-07-31	\N	\N	PERMANENT
1091	1927	53	2019-06-01	2019-07-31	\N	\N	PERMANENT
1092	1928	53	2019-06-01	2019-07-31	\N	\N	PERMANENT
1093	1929	53	2019-06-01	2019-07-31	\N	\N	PERMANENT
1094	1930	53	2019-06-01	2019-07-31	\N	\N	PERMANENT
1095	1931	53	2019-06-01	2019-07-31	\N	\N	PERMANENT
1096	1932	53	2019-06-01	2019-07-31	\N	\N	PERMANENT
1097	1933	53	2019-06-01	2019-07-31	\N	\N	PERMANENT
1098	1934	53	2019-06-01	2019-07-31	\N	\N	PERMANENT
1099	1935	53	2019-06-01	2019-07-31	\N	\N	PERMANENT
1100	1936	53	2019-06-01	2019-07-31	\N	\N	PERMANENT
1101	1937	53	2019-06-01	2019-07-31	\N	\N	PERMANENT
1102	1938	39	2019-08-01	2021-08-01	\N	\N	PERMANENT
1103	1939	39	2019-08-01	2023-08-29	\N	\N	PERMANENT
1104	1940	104	2019-06-01	2019-07-31	\N	\N	PERMANENT
1105	1941	104	2019-06-01	2019-07-31	\N	\N	PERMANENT
1106	1942	104	2019-06-01	2019-07-31	\N	\N	PERMANENT
1107	1943	104	2019-06-01	2019-07-31	\N	\N	PERMANENT
1108	1944	39	2019-06-01	2019-07-31	\N	\N	PERMANENT
1109	1945	104	2019-06-01	2019-07-31	\N	\N	PERMANENT
1110	1946	104	2019-06-01	2019-07-31	\N	\N	PERMANENT
1111	1947	104	2019-06-01	2019-07-31	\N	\N	PERMANENT
1112	1948	104	2019-06-01	2019-07-31	\N	\N	PERMANENT
1113	1949	104	2019-06-01	2019-07-31	\N	\N	PERMANENT
1114	1950	104	2019-06-01	2019-07-31	\N	\N	PERMANENT
1115	1951	104	2019-06-01	2019-07-31	\N	\N	PERMANENT
1116	1952	104	2019-06-01	2019-07-31	\N	\N	PERMANENT
1117	1953	104	2019-06-01	2019-07-31	\N	\N	PERMANENT
1118	1954	104	2019-06-01	2019-07-31	\N	\N	PERMANENT
1119	1955	104	2019-06-01	2019-07-31	\N	\N	PERMANENT
1120	1956	104	2019-06-01	2019-07-31	\N	\N	PERMANENT
1121	1957	104	2019-06-01	2019-07-31	\N	\N	PERMANENT
1122	1958	104	2019-06-01	2019-07-31	\N	\N	PERMANENT
1123	1959	104	2019-06-01	2019-07-31	\N	\N	PERMANENT
1124	1960	104	2019-06-01	2019-07-31	\N	\N	PERMANENT
1125	1961	104	2019-06-01	2019-07-31	\N	\N	PERMANENT
1126	1962	104	2019-06-01	2019-07-31	\N	\N	PERMANENT
1127	1963	104	2019-06-01	2019-07-31	\N	\N	PERMANENT
1128	1964	25	2019-06-01	2019-07-31	\N	\N	PERMANENT
1129	1965	25	2019-06-01	2019-07-31	\N	\N	PERMANENT
1130	1966	25	2019-06-01	2019-07-31	\N	\N	PERMANENT
1131	1967	25	2019-06-01	2019-07-31	\N	\N	PERMANENT
1132	1968	25	2019-06-01	2019-07-31	\N	\N	PERMANENT
1133	1969	25	2019-06-01	2019-07-31	\N	\N	PERMANENT
1134	1970	25	2019-06-01	2019-07-31	\N	\N	PERMANENT
1135	1971	25	2019-06-01	2019-07-31	\N	\N	PERMANENT
1136	1972	25	2019-06-01	2019-07-31	\N	\N	PERMANENT
1137	1973	25	2019-06-01	2019-07-31	\N	\N	PERMANENT
1138	1974	25	2019-06-01	2019-07-31	\N	\N	PERMANENT
1139	1975	25	2019-06-01	2019-07-31	\N	\N	PERMANENT
1140	1976	25	2019-06-01	2019-07-31	\N	\N	PERMANENT
1141	1977	25	2019-06-01	2019-07-31	\N	\N	PERMANENT
1142	1978	25	2019-06-01	2019-07-31	\N	\N	PERMANENT
1143	1979	25	2019-06-01	2019-07-31	\N	\N	PERMANENT
1144	1980	25	2019-06-01	2019-07-31	\N	\N	PERMANENT
1145	1981	25	2019-06-01	2019-07-31	\N	\N	PERMANENT
1146	1982	25	2019-06-01	2019-07-31	\N	\N	PERMANENT
1147	1983	25	2019-06-01	2019-07-31	\N	\N	PERMANENT
1148	1984	25	2019-07-01	2019-07-31	\N	\N	PERMANENT
1149	1985	25	2019-06-01	2019-07-31	\N	\N	PERMANENT
1150	1986	25	2019-06-01	2019-07-31	\N	\N	PERMANENT
1151	1987	25	2019-06-01	2019-07-31	\N	\N	PERMANENT
1152	1988	25	2019-06-01	2019-07-31	\N	\N	PERMANENT
1153	1989	103	2019-06-01	2019-07-31	\N	\N	PERMANENT
1154	1990	103	2019-06-01	2019-07-31	\N	\N	PERMANENT
1155	1991	103	2019-06-01	2019-07-31	\N	\N	PERMANENT
1156	1992	103	2019-06-01	2019-07-31	\N	\N	PERMANENT
1157	1993	103	2019-06-01	2019-07-31	\N	\N	PERMANENT
1158	1994	103	2019-06-01	2019-07-31	\N	\N	PERMANENT
1159	1995	103	2019-06-01	2019-07-31	\N	\N	PERMANENT
1160	1996	103	2019-06-01	2019-07-31	\N	\N	PERMANENT
1161	1997	103	2019-06-01	2019-07-31	\N	\N	PERMANENT
1162	1998	103	2019-06-01	2019-07-31	\N	\N	PERMANENT
1163	1999	103	2019-06-01	2019-07-31	\N	\N	PERMANENT
1164	2000	103	2019-06-01	2019-07-31	\N	\N	PERMANENT
1165	2001	103	2019-06-01	2019-07-31	\N	\N	PERMANENT
1166	2002	103	2019-06-01	2019-07-31	\N	\N	PERMANENT
1167	2003	103	2019-06-01	2019-07-31	\N	\N	PERMANENT
1168	2004	103	2019-06-01	2019-07-31	\N	\N	PERMANENT
1169	2005	103	2019-06-01	2019-07-31	\N	\N	PERMANENT
1170	2006	103	2019-06-01	2019-07-31	\N	\N	PERMANENT
1171	2007	103	2019-06-01	2019-07-31	\N	\N	PERMANENT
1172	2008	103	2019-06-01	2019-07-31	\N	\N	PERMANENT
1173	2009	103	2019-06-01	2019-07-31	\N	\N	PERMANENT
1174	2010	103	2019-06-01	2019-07-31	\N	\N	PERMANENT
1175	2011	103	2019-06-01	2019-07-31	\N	\N	PERMANENT
1176	2012	28	2019-06-01	2019-07-31	\N	\N	PERMANENT
1177	2013	28	2019-06-01	2019-07-31	\N	\N	PERMANENT
1178	2014	28	2019-06-01	2019-07-31	\N	\N	PERMANENT
1179	2015	28	2019-06-01	2019-07-31	\N	\N	PERMANENT
1180	2016	28	2019-06-01	2019-07-31	\N	\N	PERMANENT
1181	2017	28	2019-06-01	2019-07-31	\N	\N	PERMANENT
1182	2018	28	2019-06-01	2019-07-31	\N	\N	PERMANENT
1183	2019	28	2019-06-01	2019-07-31	\N	\N	PERMANENT
1184	2020	28	2019-06-01	2019-07-31	\N	\N	PERMANENT
1185	2021	28	2019-06-01	2019-07-31	\N	\N	PERMANENT
1186	2022	28	2019-06-01	2019-07-31	\N	\N	PERMANENT
1187	2023	28	2019-06-01	2019-07-31	\N	\N	PERMANENT
1188	2024	28	2019-06-01	2019-07-31	\N	\N	PERMANENT
1189	2025	28	2019-06-01	2019-07-31	\N	\N	PERMANENT
1190	2026	28	2019-06-01	2019-07-31	\N	\N	PERMANENT
1191	2027	28	2019-06-01	2019-07-31	\N	\N	PERMANENT
1192	2028	28	2019-06-01	2019-07-31	\N	\N	PERMANENT
1193	2029	28	2019-06-01	2019-07-31	\N	\N	PERMANENT
1194	2030	28	2019-06-01	2019-07-31	\N	\N	PERMANENT
1195	2031	28	2019-06-01	2019-07-31	\N	\N	PERMANENT
1196	2032	28	2019-06-01	2019-07-31	\N	\N	PERMANENT
1197	2033	28	2019-06-01	2019-07-31	\N	\N	PERMANENT
1198	2034	28	2019-06-01	2019-07-31	\N	\N	PERMANENT
1199	2035	52	2019-06-01	2019-07-31	\N	\N	PERMANENT
1200	2036	52	2019-06-01	2019-07-31	\N	\N	PERMANENT
1201	2037	52	2019-06-01	2019-07-31	\N	\N	PERMANENT
1202	2038	52	2019-06-01	2019-07-31	\N	\N	PERMANENT
1203	2039	52	2019-06-01	2019-07-31	\N	\N	PERMANENT
1204	2040	52	2019-06-01	2019-07-31	\N	\N	PERMANENT
1205	2041	52	2019-06-01	2019-07-31	\N	\N	PERMANENT
1206	2042	52	2019-06-01	2019-07-31	\N	\N	PERMANENT
1207	2043	52	2019-06-01	2019-07-31	\N	\N	PERMANENT
1208	2044	52	2019-06-01	2019-07-31	\N	\N	PERMANENT
1209	2045	52	2019-06-01	2019-07-31	\N	\N	PERMANENT
1210	2046	52	2019-06-01	2019-07-31	\N	\N	PERMANENT
1211	2047	52	2019-06-01	2019-07-31	\N	\N	PERMANENT
1212	2048	52	2019-06-01	2019-07-31	\N	\N	PERMANENT
1213	2049	52	2019-06-01	2019-07-31	\N	\N	PERMANENT
1214	2050	52	2019-06-01	2019-07-31	\N	\N	PERMANENT
1215	2051	52	2019-06-01	2019-07-31	\N	\N	PERMANENT
1216	2052	52	2019-06-01	2019-07-31	\N	\N	PERMANENT
1217	2053	52	2019-06-01	2019-07-31	\N	\N	PERMANENT
1218	2054	52	2019-06-01	2019-07-31	\N	\N	PERMANENT
1219	2055	52	2019-06-01	2019-07-31	\N	\N	PERMANENT
1220	2056	52	2019-06-01	2019-07-31	\N	\N	PERMANENT
1221	2057	52	2019-06-01	2019-07-31	\N	\N	PERMANENT
1222	2058	91	2019-06-01	2019-07-31	\N	\N	PERMANENT
1223	2059	91	2019-06-01	2019-07-31	\N	\N	PERMANENT
1224	2060	91	2019-06-01	2019-07-31	\N	\N	PERMANENT
1225	2061	91	2019-06-01	2019-07-31	\N	\N	PERMANENT
1226	2062	91	2019-06-01	2019-07-31	\N	\N	PERMANENT
1227	2063	91	2019-06-01	2019-07-31	\N	\N	PERMANENT
1228	2064	91	2019-06-01	2019-07-31	\N	\N	PERMANENT
1229	2065	91	2019-06-01	2019-07-31	\N	\N	PERMANENT
1230	2066	91	2019-06-01	2019-07-31	\N	\N	PERMANENT
1231	2067	91	2019-06-01	2019-07-31	\N	\N	PERMANENT
1232	2068	91	2019-06-01	2019-07-31	\N	\N	PERMANENT
1233	2069	91	2019-06-01	2019-07-31	\N	\N	PERMANENT
1234	2070	91	2019-06-01	2019-07-31	\N	\N	PERMANENT
1235	2071	91	2019-06-01	2019-07-31	\N	\N	PERMANENT
1236	2072	91	2019-06-01	2019-07-31	\N	\N	PERMANENT
1237	2073	91	2019-06-01	2019-07-31	\N	\N	PERMANENT
1238	2074	91	2019-06-01	2019-07-31	\N	\N	PERMANENT
1239	2075	91	2019-06-01	2019-07-31	\N	\N	PERMANENT
1240	2076	91	2019-06-01	2019-07-31	\N	\N	PERMANENT
1241	2077	91	2019-06-01	2019-07-31	\N	\N	PERMANENT
1242	2078	91	2019-06-01	2019-07-31	\N	\N	PERMANENT
1243	2079	91	2019-06-01	2019-07-31	\N	\N	PERMANENT
1244	2080	91	2019-06-01	2019-07-31	\N	\N	PERMANENT
1245	2081	62	2019-06-01	2019-07-31	\N	\N	PERMANENT
1246	2082	62	2019-06-01	2019-07-31	\N	\N	PERMANENT
1247	2083	62	2019-06-01	2019-07-31	\N	\N	PERMANENT
1248	2084	62	2019-06-01	2019-07-31	\N	\N	PERMANENT
1249	2085	62	2019-06-01	2019-07-31	\N	\N	PERMANENT
1250	2086	62	2019-06-01	2019-07-31	\N	\N	PERMANENT
1251	2087	62	2019-06-01	2019-07-31	\N	\N	PERMANENT
1252	2088	62	2019-06-01	2019-07-31	\N	\N	PERMANENT
1253	2089	62	2019-06-01	2019-07-31	\N	\N	PERMANENT
1254	2090	62	2019-06-01	2019-07-31	\N	\N	PERMANENT
1255	2091	62	2019-06-01	2019-07-31	\N	\N	PERMANENT
1256	2092	62	2019-06-01	2019-07-31	\N	\N	PERMANENT
1257	2093	62	2019-06-01	2019-07-31	\N	\N	PERMANENT
1258	2094	62	2019-06-01	2019-07-31	\N	\N	PERMANENT
1259	2095	62	2019-06-01	2019-07-31	\N	\N	PERMANENT
1260	2096	62	2019-06-01	2019-07-31	\N	\N	PERMANENT
1261	2097	62	2019-06-01	2019-07-31	\N	\N	PERMANENT
1262	2098	62	2019-06-01	2019-07-31	\N	\N	PERMANENT
1263	2099	62	2019-06-01	2019-07-31	\N	\N	PERMANENT
1264	2100	62	2019-06-01	2019-07-31	\N	\N	PERMANENT
1265	2101	62	2019-06-01	2019-07-31	\N	\N	PERMANENT
1266	2102	62	2019-06-01	2019-07-31	\N	\N	PERMANENT
1267	2103	62	2019-06-01	2019-07-31	\N	\N	PERMANENT
1268	2104	54	2019-06-01	2019-07-31	\N	\N	PERMANENT
1269	2105	54	2019-06-01	2019-07-31	\N	\N	PERMANENT
1270	2106	54	2019-06-01	2019-07-31	\N	\N	PERMANENT
1271	2107	54	2019-06-01	2019-07-31	\N	\N	PERMANENT
1272	2108	54	2019-06-01	2019-07-31	\N	\N	PERMANENT
1273	2109	54	2019-06-01	2019-07-31	\N	\N	PERMANENT
1274	2110	54	2019-06-01	2019-07-31	\N	\N	PERMANENT
1275	2111	54	2019-06-01	2019-07-31	\N	\N	PERMANENT
1276	2112	54	2019-06-01	2019-07-31	\N	\N	PERMANENT
1277	2113	54	2019-06-01	2019-07-31	\N	\N	PERMANENT
1278	2114	54	2019-06-01	2019-07-31	\N	\N	PERMANENT
1279	2115	54	2019-06-01	2019-07-31	\N	\N	PERMANENT
1280	2116	54	2019-06-01	2019-07-31	\N	\N	PERMANENT
1281	2117	54	2019-06-01	2019-07-31	\N	\N	PERMANENT
1282	2118	54	2019-06-01	2019-07-31	\N	\N	PERMANENT
1283	2119	54	2019-06-01	2019-07-31	\N	\N	PERMANENT
1284	2120	54	2019-06-01	2019-07-31	\N	\N	PERMANENT
1285	2121	54	2019-06-01	2019-07-31	\N	\N	PERMANENT
1286	2122	54	2019-06-01	2019-07-31	\N	\N	PERMANENT
1287	2123	54	2019-06-01	2019-07-31	\N	\N	PERMANENT
1288	2124	54	2019-06-01	2019-07-31	\N	\N	PERMANENT
1289	2125	54	2019-06-01	2019-07-31	\N	\N	PERMANENT
1290	2126	54	2019-06-01	2019-07-31	\N	\N	PERMANENT
1291	2127	32	2019-06-01	2019-07-31	\N	\N	PERMANENT
1292	2128	32	2019-06-01	2019-07-31	\N	\N	PERMANENT
1293	2129	32	2019-06-01	2019-07-31	\N	\N	PERMANENT
1294	2130	32	2019-06-01	2019-07-31	\N	\N	PERMANENT
1295	2131	32	2019-06-01	2019-07-31	\N	\N	PERMANENT
1296	2132	32	2019-06-01	2019-07-31	\N	\N	PERMANENT
1297	2133	32	2019-06-01	2019-07-31	\N	\N	PERMANENT
1298	2134	32	2019-06-01	2019-07-31	\N	\N	PERMANENT
1299	2135	32	2019-06-01	2019-07-31	\N	\N	PERMANENT
1300	2136	32	2019-06-01	2019-07-31	\N	\N	PERMANENT
1301	2137	32	2019-06-01	2019-07-31	\N	\N	PERMANENT
1302	2138	32	2019-06-01	2019-07-31	\N	\N	PERMANENT
1303	2139	32	2019-06-01	2019-07-31	\N	\N	PERMANENT
1304	2140	32	2019-06-01	2019-07-31	\N	\N	PERMANENT
1305	2141	32	2019-06-01	2019-07-31	\N	\N	PERMANENT
1306	2142	32	2019-06-01	2019-07-31	\N	\N	PERMANENT
1307	2143	32	2019-06-01	2019-07-31	\N	\N	PERMANENT
1308	2144	32	2019-06-01	2019-07-31	\N	\N	PERMANENT
1309	2145	32	2019-06-01	2019-07-31	\N	\N	PERMANENT
1310	2146	32	2019-06-01	2019-07-31	\N	\N	PERMANENT
1311	2147	32	2019-06-01	2019-07-31	\N	\N	PERMANENT
1312	2148	32	2019-06-01	2019-07-31	\N	\N	PERMANENT
1313	2149	32	2019-06-01	2019-07-31	\N	\N	PERMANENT
1314	2150	69	2019-06-01	2019-07-31	\N	\N	PERMANENT
1315	2151	69	2019-06-01	2019-07-31	\N	\N	PERMANENT
1316	2152	69	2019-06-01	2019-07-31	\N	\N	PERMANENT
1317	2153	69	2019-06-01	2019-07-31	\N	\N	PERMANENT
1318	2154	69	2019-06-01	2019-07-31	\N	\N	PERMANENT
1319	2155	69	2019-06-01	2019-07-31	\N	\N	PERMANENT
1320	2156	69	2019-06-01	2019-07-31	\N	\N	PERMANENT
1321	2157	69	2019-06-01	2019-07-31	\N	\N	PERMANENT
1322	2158	69	2019-06-01	2019-07-31	\N	\N	PERMANENT
1323	2159	69	2019-06-01	2019-07-31	\N	\N	PERMANENT
1324	2160	69	2019-06-01	2019-07-31	\N	\N	PERMANENT
1325	2161	69	2019-06-01	2019-07-31	\N	\N	PERMANENT
1326	2162	69	2019-06-01	2019-07-31	\N	\N	PERMANENT
1327	2163	69	2019-06-01	2019-07-31	\N	\N	PERMANENT
1328	2164	69	2019-06-01	2019-07-31	\N	\N	PERMANENT
1329	2165	69	2019-06-01	2019-07-31	\N	\N	PERMANENT
1330	2166	69	2019-06-01	2019-07-31	\N	\N	PERMANENT
1331	2167	69	2019-06-01	2019-07-31	\N	\N	PERMANENT
1332	2168	69	2019-06-01	2019-07-31	\N	\N	PERMANENT
1333	2169	69	2019-06-01	2019-07-31	\N	\N	PERMANENT
1334	2170	69	2019-06-01	2019-07-31	\N	\N	PERMANENT
1335	2171	69	2019-06-01	2019-07-31	\N	\N	PERMANENT
1336	2172	69	2019-06-01	2019-07-31	\N	\N	PERMANENT
1337	2173	27	2019-06-01	2019-07-31	\N	\N	PERMANENT
1338	2174	40	2019-06-01	2019-07-31	\N	\N	PERMANENT
1339	2175	40	2019-06-01	2019-07-31	\N	\N	PERMANENT
1340	2176	40	2019-06-01	2019-07-31	\N	\N	PERMANENT
1341	2177	61	2019-06-01	2019-07-31	\N	\N	PERMANENT
1342	2178	61	2019-06-01	2019-07-31	\N	\N	PERMANENT
1343	2179	30	2019-06-01	2019-07-31	\N	\N	PERMANENT
1344	2180	53	2019-06-01	2019-07-31	\N	\N	PERMANENT
1345	2181	105	2019-06-01	2019-07-31	\N	\N	PERMANENT
1346	2182	105	2019-06-01	2019-07-31	\N	\N	PERMANENT
1347	2183	43	2019-06-01	2019-07-31	\N	\N	PERMANENT
1348	2184	91	2019-06-01	2019-07-31	\N	\N	PERMANENT
1349	2185	64	2019-06-01	2019-07-31	\N	\N	PERMANENT
1350	2186	61	2019-06-01	2019-07-31	\N	\N	PERMANENT
1351	2187	61	2019-06-01	2019-07-31	\N	\N	PERMANENT
1352	2188	50	2019-06-01	2019-07-31	\N	\N	PERMANENT
1353	2189	50	2019-06-01	2019-07-31	\N	\N	PERMANENT
1354	2190	50	2019-06-01	2019-07-31	\N	\N	PERMANENT
1355	2191	50	2019-06-01	2019-07-31	\N	\N	PERMANENT
1356	2192	50	2019-06-01	2019-07-31	\N	\N	PERMANENT
1357	2193	50	2019-06-01	2019-07-31	\N	\N	PERMANENT
1358	2194	59	2019-06-01	2019-07-31	\N	\N	PERMANENT
1359	2195	58	2019-06-01	2019-07-31	\N	\N	PERMANENT
1360	2196	58	2019-06-01	2019-07-31	\N	\N	PERMANENT
1361	2197	58	2019-06-01	2019-07-31	\N	\N	PERMANENT
1362	2198	33	2019-06-01	2019-07-31	\N	\N	PERMANENT
1363	2199	33	2019-06-01	2019-07-31	\N	\N	PERMANENT
1364	2200	33	2019-06-01	2019-07-31	\N	\N	PERMANENT
1365	2201	39	2019-06-01	2019-07-31	\N	\N	PERMANENT
1366	2202	30	2019-06-01	2019-07-31	\N	\N	PERMANENT
1367	2203	27	2019-06-01	2019-07-31	\N	\N	PERMANENT
1368	2204	27	2019-06-01	2019-07-31	\N	\N	PERMANENT
1369	2205	105	2019-06-01	2019-07-31	\N	\N	PERMANENT
1370	2206	61	2019-06-01	2019-07-31	\N	\N	PERMANENT
1371	2207	61	2019-06-01	2019-07-31	\N	\N	PERMANENT
1372	2208	64	2019-06-01	2019-07-31	\N	\N	PERMANENT
1373	2209	105	2019-06-01	2019-07-31	\N	\N	PERMANENT
1374	2210	105	2019-06-01	2019-07-31	\N	\N	PERMANENT
1375	2211	64	2019-06-01	2019-07-31	\N	\N	PERMANENT
1376	2212	64	2019-06-01	2019-07-31	\N	\N	PERMANENT
1377	2213	64	2019-06-01	2019-07-31	\N	\N	PERMANENT
1378	2214	64	2019-06-01	2019-07-31	\N	\N	PERMANENT
1379	2215	64	2019-07-01	2019-07-31	\N	\N	PERMANENT
1380	2216	64	2019-07-01	2019-07-31	\N	\N	PERMANENT
1381	2217	64	2019-07-01	2019-07-31	\N	\N	PERMANENT
1382	2218	64	2019-07-01	2019-07-31	\N	\N	PERMANENT
1383	2219	64	2019-07-01	2019-07-31	\N	\N	PERMANENT
1384	2220	64	2019-07-01	2019-07-31	\N	\N	PERMANENT
1385	2221	64	2019-07-01	2019-07-31	\N	\N	PERMANENT
1386	2222	64	2019-07-01	2019-07-31	\N	\N	PERMANENT
1387	2223	64	2019-07-01	2019-07-31	\N	\N	PERMANENT
1388	2224	64	2019-07-01	2019-07-31	\N	\N	PERMANENT
1389	2225	64	2019-07-01	2019-07-31	\N	\N	PERMANENT
1390	2226	64	2019-07-01	2019-07-31	\N	\N	PERMANENT
1391	2227	64	2019-07-01	2019-07-31	\N	\N	PERMANENT
1392	2228	64	2019-07-01	2019-07-31	\N	\N	PERMANENT
1393	2229	64	2019-07-01	2019-07-31	\N	\N	PERMANENT
1394	2230	64	2019-07-01	2019-07-31	\N	\N	PERMANENT
1395	2231	39	2019-07-01	2019-07-31	\N	\N	PERMANENT
1396	2232	39	2019-07-01	2019-07-31	\N	\N	PERMANENT
1397	2233	39	2019-07-01	2019-07-31	\N	\N	PERMANENT
1398	2234	39	2019-07-01	2019-07-31	\N	\N	PERMANENT
1399	2235	39	2019-07-01	2019-07-31	\N	\N	PERMANENT
1400	2236	39	2019-07-01	2019-07-31	\N	\N	PERMANENT
1401	2237	39	2019-07-01	2019-07-31	\N	\N	PERMANENT
1402	2238	39	2019-07-01	2019-07-31	\N	\N	PERMANENT
1403	2239	39	2019-07-01	2019-07-31	\N	\N	PERMANENT
1404	2240	39	2019-07-01	2019-07-31	\N	\N	PERMANENT
1405	2241	39	2019-07-01	2019-07-31	\N	\N	PERMANENT
1406	2242	39	2019-07-01	2019-07-31	\N	\N	PERMANENT
1407	2243	39	2019-07-01	2019-07-31	\N	\N	PERMANENT
1408	2244	39	2019-07-01	2019-07-31	\N	\N	PERMANENT
1409	2245	39	2019-07-01	2019-07-31	\N	\N	PERMANENT
1410	2246	39	2019-07-01	2019-07-31	\N	\N	PERMANENT
1411	2247	39	2019-07-01	2019-07-31	\N	\N	PERMANENT
1412	2248	39	2019-07-01	2019-07-31	\N	\N	PERMANENT
1413	2249	39	2019-07-01	2019-07-31	\N	\N	PERMANENT
1414	2250	39	2019-07-01	2019-07-31	\N	\N	PERMANENT
1415	2251	105	2019-07-01	2019-07-31	\N	\N	PERMANENT
1416	2252	105	2019-07-01	2019-07-31	\N	\N	PERMANENT
1417	2253	105	2019-07-01	2019-07-31	\N	\N	PERMANENT
1418	2254	105	2019-07-01	2019-07-31	\N	\N	PERMANENT
1419	2255	105	2019-07-01	2019-07-31	\N	\N	PERMANENT
1420	2256	105	2019-07-01	2019-07-31	\N	\N	PERMANENT
1421	2257	105	2019-07-01	2019-07-31	\N	\N	PERMANENT
1422	2258	105	2019-07-01	2019-07-31	\N	\N	PERMANENT
1423	2259	105	2019-07-01	2019-07-31	\N	\N	PERMANENT
1424	2260	105	2019-07-01	2019-07-31	\N	\N	PERMANENT
1425	2261	105	2019-07-01	2019-07-31	\N	\N	PERMANENT
1426	2262	105	2019-07-01	2019-07-31	\N	\N	PERMANENT
1427	2263	105	2019-07-01	2019-07-31	\N	\N	PERMANENT
1428	2264	105	2019-07-01	2019-07-31	\N	\N	PERMANENT
1429	2265	105	2019-07-01	2019-07-31	\N	\N	PERMANENT
1430	2266	105	2019-07-01	2019-07-31	\N	\N	PERMANENT
1431	2267	105	2019-07-01	2019-07-31	\N	\N	PERMANENT
1432	2268	105	2019-07-01	2019-07-31	\N	\N	PERMANENT
1433	2269	11	2019-08-06	2021-08-06	\N	\N	PERMANENT
1434	2270	11	2019-08-01	2021-08-17	\N	\N	PERMANENT
1435	2271	11	2019-08-01	2021-08-30	\N	\N	PERMANENT
1436	2272	15	2019-08-01	2021-08-30	\N	\N	PERMANENT
1437	2273	1	2019-08-01	2021-08-30	\N	\N	PERMANENT
1438	2274	17	2019-08-01	2021-08-30	\N	\N	PERMANENT
1439	2275	87	2019-08-01	2019-08-01	\N	\N	PERMANENT
1440	2276	87	2019-08-01	2021-08-30	\N	\N	PERMANENT
1441	2277	7	2019-08-01	2021-08-30	\N	\N	PERMANENT
1442	2278	2	2019-08-01	2021-08-30	\N	\N	PERMANENT
1443	2279	2	2019-08-01	2021-08-30	\N	\N	PERMANENT
1444	2280	168	2019-08-01	2019-08-01	\N	\N	PERMANENT
1445	2281	8	2019-08-01	2021-08-30	\N	\N	PERMANENT
1446	2284	4	2019-08-01	2021-08-31	\N	\N	PERMANENT
1447	2285	170	2019-08-01	2021-08-31	\N	\N	PERMANENT
1448	2286	185	2019-08-01	2021-08-31	\N	\N	PERMANENT
1449	2287	128	2019-08-01	2021-08-31	\N	\N	PERMANENT
1450	2288	181	2019-08-01	2022-08-31	\N	\N	PERMANENT
1451	2289	181	2019-08-01	2021-08-30	\N	\N	PERMANENT
1452	2290	181	2019-08-01	2022-08-31	\N	\N	PERMANENT
1453	2291	181	2019-08-01	2021-08-30	\N	\N	PERMANENT
1454	2292	181	2019-08-01	2022-08-30	\N	\N	PERMANENT
1455	2293	181	2019-08-01	2021-08-31	\N	\N	PERMANENT
1456	2294	181	2019-08-01	2021-08-31	\N	\N	PERMANENT
1457	2295	181	2019-08-01	2021-08-31	\N	\N	PERMANENT
1458	2296	181	2019-08-01	2021-08-31	\N	\N	PERMANENT
1459	2297	181	2019-08-01	2021-08-30	\N	\N	PERMANENT
1460	2298	181	2019-08-01	2021-08-31	\N	\N	PERMANENT
1461	2299	181	2019-08-01	2021-08-31	\N	\N	PERMANENT
1462	2300	181	2019-08-01	2021-08-31	\N	\N	PERMANENT
1463	2301	181	2019-08-01	2021-08-31	\N	\N	PERMANENT
1464	2302	181	2019-08-01	2021-08-31	\N	\N	PERMANENT
1465	2303	181	2019-08-01	2021-08-31	\N	\N	PERMANENT
1466	2304	181	2019-08-01	2021-08-31	\N	\N	PERMANENT
1467	2305	181	2019-08-01	2021-08-31	\N	\N	PERMANENT
1468	2306	181	2019-08-01	2021-08-31	\N	\N	PERMANENT
1469	2307	181	2019-08-01	2021-08-31	\N	\N	PERMANENT
1470	2308	181	2019-08-01	2021-08-31	\N	\N	PERMANENT
1471	2309	181	2019-08-01	2022-08-31	\N	\N	PERMANENT
1472	2310	181	2019-08-01	2021-08-31	\N	\N	PERMANENT
1473	2311	181	2019-08-01	2019-08-01	\N	\N	PERMANENT
1474	2312	181	2019-08-01	2021-08-30	\N	\N	PERMANENT
1475	2313	181	2019-08-01	2021-08-31	\N	\N	PERMANENT
1476	2314	181	2019-08-01	2021-08-30	\N	\N	PERMANENT
1477	2315	181	2019-08-01	2021-08-31	\N	\N	PERMANENT
1478	2316	181	2019-08-01	2021-08-30	\N	\N	PERMANENT
1479	2317	181	2019-08-01	2021-08-31	\N	\N	PERMANENT
1480	2318	183	2019-08-01	2021-08-31	\N	\N	PERMANENT
1481	2319	179	2019-08-01	2021-08-31	\N	\N	PERMANENT
1482	2320	74	2019-08-01	2021-08-31	\N	\N	PERMANENT
1483	2321	187	2019-08-01	2021-08-31	\N	\N	PERMANENT
1484	2322	177	2019-08-01	2021-08-31	\N	\N	PERMANENT
1485	2323	177	2019-08-01	2021-08-31	\N	\N	PERMANENT
1486	2324	177	2019-08-01	2021-08-31	\N	\N	PERMANENT
1487	2325	74	2019-08-01	2021-08-31	\N	\N	PERMANENT
1488	2326	74	2019-08-01	2021-08-31	\N	\N	PERMANENT
1489	2327	74	2019-08-01	2021-08-31	\N	\N	PERMANENT
1490	2328	186	2019-08-01	2021-09-30	\N	\N	PERMANENT
1491	2329	186	2019-08-01	2021-09-30	\N	\N	PERMANENT
1492	2330	186	2019-08-01	2021-09-30	\N	\N	PERMANENT
1493	1186	169	2019-08-01	\N	\N	\N	PERMANENT
1494	977	4	2019-08-01	\N	\N	\N	PERMANENT
1495	2331	11	2019-08-01	2021-08-31	\N	\N	PERMANENT
1496	2332	11	2019-08-01	2021-09-30	\N	\N	PERMANENT
1497	2333	11	2019-08-01	2021-09-30	\N	\N	PERMANENT
1498	2334	11	2019-08-01	2021-09-30	\N	\N	PERMANENT
1499	2335	11	2019-08-01	2021-09-30	\N	\N	PERMANENT
1500	2336	11	2019-08-01	2021-09-30	\N	\N	PERMANENT
1501	2337	7	2019-08-01	2021-09-30	\N	\N	PERMANENT
1502	2338	7	2019-08-01	2021-09-30	\N	\N	PERMANENT
1503	2339	7	2019-08-01	2021-09-30	\N	\N	PERMANENT
1504	2340	7	2019-08-01	2021-09-30	\N	\N	PERMANENT
1505	2341	7	2019-08-01	2021-09-30	\N	\N	PERMANENT
1506	2342	7	2019-09-01	2019-09-30	\N	\N	PERMANENT
1507	2343	7	2019-09-01	2021-09-30	\N	\N	PERMANENT
1508	2344	7	2019-08-01	2021-09-30	\N	\N	PERMANENT
1509	2345	100	2019-08-01	2021-09-30	\N	\N	PERMANENT
1510	2346	182	2019-08-01	2021-09-30	\N	\N	PERMANENT
1511	2347	182	2019-08-01	2021-09-30	\N	\N	PERMANENT
1512	2348	179	2019-08-01	2021-09-30	\N	\N	PERMANENT
1513	2349	187	2019-09-01	2021-09-30	\N	\N	PERMANENT
1514	2350	171	2019-09-01	2021-09-30	\N	\N	PERMANENT
1515	2351	76	2019-08-01	2022-09-14	\N	\N	PERMANENT
1516	2352	168	2019-09-01	2018-08-01	\N	\N	PERMANENT
1517	2353	2	2019-09-01	2021-09-30	\N	\N	PERMANENT
1518	2354	168	2019-09-01	2021-09-30	\N	\N	PERMANENT
1519	2355	99	2019-08-01	2021-09-30	\N	\N	PERMANENT
1520	2356	4	2019-09-01	2021-09-30	\N	\N	PERMANENT
1521	2357	186	2019-08-01	2021-09-30	\N	\N	PERMANENT
1522	2358	127	2019-08-01	2021-09-30	\N	\N	PERMANENT
1523	2359	127	2019-09-01	2021-09-30	\N	\N	PERMANENT
1524	2360	127	2019-09-01	2021-09-30	\N	\N	PERMANENT
1525	2361	171	2019-09-01	2019-08-01	\N	\N	PERMANENT
1526	1025	188	2019-08-01	\N	\N	\N	PERMANENT
1527	1096	8	2019-08-01	\N	\N	\N	PERMANENT
1528	1368	88	2019-08-01	\N	\N	\N	PERMANENT
1529	2362	5	2019-08-01	2021-09-30	\N	\N	PERMANENT
1530	2363	185	2019-08-01	2021-09-30	\N	\N	PERMANENT
1531	2364	127	2019-08-01	2021-09-30	\N	\N	PERMANENT
1532	2365	176	2019-08-01	2021-09-30	\N	\N	PERMANENT
1533	2366	176	2019-08-01	2021-09-30	\N	\N	PERMANENT
1534	2367	176	2019-08-01	2021-09-30	\N	\N	PERMANENT
1535	2368	175	2019-09-01	2021-09-30	\N	\N	PERMANENT
1536	2369	180	2019-08-01	2021-09-30	\N	\N	PERMANENT
1537	2370	180	2019-08-01	2021-09-30	\N	\N	PERMANENT
1538	2371	128	2019-09-01	2021-09-30	\N	\N	PERMANENT
1539	2372	185	2019-09-01	2021-09-30	\N	\N	PERMANENT
1540	2373	176	2019-09-01	2021-09-30	\N	\N	PERMANENT
1541	2374	180	2019-09-01	2022-09-30	\N	\N	PERMANENT
1542	2361	181	2019-08-01	\N	\N	\N	PERMANENT
1543	2375	181	2019-08-01	2021-09-30	\N	\N	PERMANENT
1544	2376	171	2019-09-01	2021-09-30	\N	\N	PERMANENT
1545	2377	179	2019-09-01	2021-09-30	\N	\N	PERMANENT
1546	2378	126	2019-09-01	2021-09-30	\N	\N	PERMANENT
1547	2379	187	2019-09-01	2021-09-30	\N	\N	PERMANENT
1548	2380	187	2019-09-01	2021-09-30	\N	\N	PERMANENT
1549	2381	187	2019-09-01	2019-08-01	\N	\N	PERMANENT
1550	2382	187	2019-09-01	2019-08-01	\N	\N	PERMANENT
1551	2381	74	2019-08-01	\N	\N	\N	PERMANENT
1552	2382	74	2019-08-01	\N	\N	\N	PERMANENT
1553	2383	170	2019-08-01	2021-09-30	\N	\N	PERMANENT
1554	2384	170	2019-09-01	2021-09-30	\N	\N	PERMANENT
1555	2385	13	2019-08-01	2022-09-30	\N	\N	PERMANENT
1556	2386	100	2019-08-01	2022-09-30	\N	\N	PERMANENT
1557	2387	13	2019-08-01	2022-09-30	\N	\N	PERMANENT
1558	1118	17	2019-08-01	\N	\N	\N	PERMANENT
1559	2388	87	2019-08-01	2022-09-30	\N	\N	PERMANENT
1560	2389	5	2019-08-01	2022-09-30	\N	\N	PERMANENT
1561	1822	169	2019-08-01	\N	\N	\N	PERMANENT
1562	2390	76	2019-08-01	2021-09-30	\N	\N	PERMANENT
1563	2391	182	2019-08-01	2022-09-30	\N	\N	PERMANENT
1564	2392	181	2019-08-01	2022-09-30	\N	\N	PERMANENT
1565	2393	181	2019-08-01	2022-09-30	\N	\N	PERMANENT
1566	2394	193	2019-09-01	2022-09-30	\N	\N	PERMANENT
1567	2395	76	2019-08-01	2021-09-30	\N	\N	PERMANENT
1568	2396	2	2019-08-01	2021-09-30	\N	\N	PERMANENT
1569	2397	102	2018-09-01	\N	\N	\N	PERMANENT
1570	992	8	2019-08-01	\N	\N	\N	PERMANENT
1571	1175	13	2019-08-01	\N	\N	\N	PERMANENT
1572	2398	87	2019-08-01	\N	\N	\N	PERMANENT
1573	2275	87	2019-08-01	\N	\N	\N	PERMANENT
1574	1210	169	2019-08-01	2020-01-01	\N	\N	PERMANENT
1575	2399	76	2019-08-01	2021-10-31	\N	\N	PERMANENT
1576	2280	168	2019-08-01	\N	\N	\N	PERMANENT
1577	2400	187	2019-08-01	2021-10-31	\N	\N	PERMANENT
1578	2401	187	2019-08-01	2021-10-31	\N	\N	PERMANENT
1579	2402	185	2019-08-01	2022-08-07	\N	\N	PERMANENT
1580	2403	185	2019-08-01	2021-10-31	\N	\N	PERMANENT
1581	2404	184	2019-08-01	2021-10-31	\N	\N	PERMANENT
1582	2405	126	2019-08-01	2022-08-31	\N	\N	PERMANENT
1583	2406	126	2019-08-01	2022-08-31	\N	\N	PERMANENT
1584	2407	180	2019-08-01	2021-10-31	\N	\N	PERMANENT
1585	2408	127	2019-08-01	2022-08-31	\N	\N	PERMANENT
1586	2409	128	2019-08-01	2021-10-31	\N	\N	PERMANENT
1587	2410	128	2019-08-01	2022-08-31	\N	\N	PERMANENT
1588	2411	171	2019-08-01	2019-08-31	\N	\N	PERMANENT
1589	2412	171	2019-08-01	2022-10-31	\N	\N	PERMANENT
1590	2413	183	2019-08-01	2022-08-31	\N	\N	PERMANENT
1591	2414	183	2019-08-01	2022-08-31	\N	\N	PERMANENT
1592	2415	177	2019-08-01	2022-08-31	\N	\N	PERMANENT
1593	2416	170	2019-08-01	2022-08-31	\N	\N	PERMANENT
1594	2417	127	2019-08-01	2022-08-31	\N	\N	PERMANENT
1595	2418	176	2019-08-01	2022-08-31	\N	\N	PERMANENT
1596	2419	187	2019-08-01	2022-08-31	\N	\N	PERMANENT
1597	2420	187	2019-08-01	2022-08-31	\N	\N	PERMANENT
1598	1236	4	2019-08-01	\N	\N	\N	PERMANENT
1599	2421	168	2019-08-01	2022-08-20	\N	\N	PERMANENT
1600	2422	2	2019-08-01	2022-10-31	\N	\N	PERMANENT
1601	2423	100	2019-08-01	2019-08-31	\N	\N	PERMANENT
1602	2424	169	2019-08-01	2021-08-31	\N	\N	PERMANENT
1603	2425	169	2019-08-01	2021-10-31	\N	\N	PERMANENT
1604	2426	88	2019-08-01	2021-08-31	\N	\N	PERMANENT
1605	986	88	2019-08-01	\N	\N	\N	PERMANENT
1606	2427	88	2019-08-01	2022-08-31	\N	\N	PERMANENT
1607	1419	88	2019-08-01	\N	\N	\N	PERMANENT
1608	1773	88	2019-08-01	\N	\N	\N	PERMANENT
1609	1265	88	2019-08-01	\N	\N	\N	PERMANENT
1610	2428	88	2019-08-01	2022-08-31	\N	\N	PERMANENT
1611	1080	88	2019-08-01	\N	\N	\N	PERMANENT
1612	2429	88	2019-08-01	2022-08-31	\N	\N	PERMANENT
1613	2430	88	2019-08-01	2019-08-31	\N	\N	PERMANENT
1614	2431	88	2019-08-01	2019-08-31	\N	\N	PERMANENT
1615	2432	88	2019-08-01	2022-08-31	\N	\N	PERMANENT
1616	2433	88	2019-08-01	2022-08-31	\N	\N	PERMANENT
1617	2434	101	2019-08-01	2022-08-31	\N	\N	PERMANENT
1618	1733	99	2019-08-01	\N	\N	\N	PERMANENT
1619	2435	11	2019-08-01	2022-08-31	\N	\N	PERMANENT
1620	1070	2	2019-08-01	\N	\N	\N	PERMANENT
1621	1430	8	2019-08-01	\N	\N	\N	PERMANENT
1622	2436	11	2019-08-01	2022-08-31	\N	\N	PERMANENT
1623	2437	102	2019-08-01	2022-08-01	\N	\N	PERMANENT
1624	996	102	2019-08-01	\N	\N	\N	PERMANENT
1625	1887	101	2019-08-01	\N	\N	\N	PERMANENT
1626	2438	168	2019-08-01	2022-08-31	\N	\N	PERMANENT
1627	1415	3	2019-08-01	\N	\N	\N	PERMANENT
1628	2439	168	2019-08-01	2022-08-31	\N	\N	PERMANENT
1629	2440	23	2019-08-01	\N	\N	\N	PERMANENT
1630	2441	35	2019-08-01	2023-11-30	\N	\N	PERMANENT
1631	2442	44	2019-11-01	2023-11-16	\N	\N	PERMANENT
1632	2443	44	2019-11-01	2023-11-30	\N	\N	PERMANENT
1633	2444	71	2019-11-01	2023-11-16	\N	\N	PERMANENT
1634	2445	26	2019-11-01	2023-11-16	\N	\N	PERMANENT
1635	2446	45	2019-11-01	2023-11-30	\N	\N	PERMANENT
1636	2447	45	2019-11-01	2023-11-16	\N	\N	PERMANENT
1637	2448	28	2019-11-01	2023-11-16	\N	\N	PERMANENT
1638	2449	42	2019-11-01	2023-11-30	\N	\N	PERMANENT
1639	2450	42	2019-11-01	2022-11-16	\N	\N	PERMANENT
1640	2451	42	2019-11-01	2022-11-30	\N	\N	PERMANENT
1641	2452	70	2019-11-01	2019-11-30	\N	\N	PERMANENT
1642	2453	70	2019-11-01	2023-11-16	\N	\N	PERMANENT
1643	2454	70	2019-11-01	2023-11-30	\N	\N	PERMANENT
1644	2455	47	2019-11-01	2023-11-30	\N	\N	PERMANENT
1645	2456	52	2019-11-01	2023-11-30	\N	\N	PERMANENT
1646	2457	52	2019-11-01	2023-11-30	\N	\N	PERMANENT
1647	2458	60	2019-11-01	2023-11-30	\N	\N	PERMANENT
1648	2459	41	2019-11-01	2023-11-30	\N	\N	PERMANENT
1649	2460	41	2019-11-01	2023-11-30	\N	\N	PERMANENT
1650	2461	43	2019-11-01	2023-11-16	\N	\N	PERMANENT
1651	2462	49	2019-11-01	2023-11-30	\N	\N	PERMANENT
1652	2463	34	2019-11-01	2023-11-30	\N	\N	PERMANENT
1653	2464	34	2019-11-01	2023-11-30	\N	\N	PERMANENT
1654	2465	34	2019-11-01	2019-11-16	\N	\N	PERMANENT
1655	2466	27	2019-11-01	2023-11-16	\N	\N	PERMANENT
1656	2467	50	2019-11-01	2023-11-30	\N	\N	PERMANENT
1657	2468	104	2019-11-01	2023-11-30	\N	\N	PERMANENT
1658	2469	33	2019-11-01	2023-11-30	\N	\N	PERMANENT
1659	2470	54	2019-11-01	2023-11-16	\N	\N	PERMANENT
1660	2471	63	2019-11-01	2023-11-30	\N	\N	PERMANENT
1661	2472	91	2019-11-01	2023-11-30	\N	\N	PERMANENT
1662	2473	105	2019-11-01	2023-11-30	\N	\N	PERMANENT
1663	2474	89	2019-11-01	2023-11-30	\N	\N	PERMANENT
1664	2475	50	2019-11-01	2023-11-30	\N	\N	PERMANENT
1665	2476	48	2019-11-01	2023-11-30	\N	\N	PERMANENT
1666	2477	32	2019-11-01	2023-11-30	\N	\N	PERMANENT
1667	2478	50	2019-11-01	2023-11-30	\N	\N	PERMANENT
1668	2479	40	2019-11-01	2023-11-30	\N	\N	PERMANENT
1669	2480	52	2019-11-01	2023-11-30	\N	\N	PERMANENT
1670	2481	24	2019-11-01	2023-11-30	\N	\N	PERMANENT
1671	2482	24	2019-11-01	2023-11-30	\N	\N	PERMANENT
1672	2483	60	2019-11-01	2023-11-30	\N	\N	PERMANENT
1673	2484	26	2019-11-01	2023-11-30	\N	\N	PERMANENT
1674	2485	58	2019-11-01	2023-11-30	\N	\N	PERMANENT
1675	2486	66	2019-11-01	2023-11-30	\N	\N	PERMANENT
1676	2487	66	2019-11-01	2023-11-30	\N	\N	PERMANENT
1677	2488	66	2019-11-01	2023-11-30	\N	\N	PERMANENT
1678	2489	66	2019-11-01	2023-11-30	\N	\N	PERMANENT
1679	2490	66	2019-11-01	2023-11-30	\N	\N	PERMANENT
1680	2491	66	2019-11-01	2023-11-30	\N	\N	PERMANENT
1681	2492	66	2019-11-01	2023-11-30	\N	\N	PERMANENT
1682	2493	66	2019-11-01	2023-11-30	\N	\N	PERMANENT
1683	2494	66	2019-11-01	2023-11-30	\N	\N	PERMANENT
1684	2495	66	2019-11-01	2023-11-30	\N	\N	PERMANENT
1685	2496	66	2019-11-01	2023-11-30	\N	\N	PERMANENT
1686	2497	43	2019-11-01	2023-11-30	\N	\N	PERMANENT
1687	2498	43	2019-11-01	2023-11-30	\N	\N	PERMANENT
1688	2499	46	2019-11-01	2023-11-30	\N	\N	PERMANENT
1689	2500	46	2019-11-01	2023-11-30	\N	\N	PERMANENT
1690	2501	34	2019-11-01	2023-11-30	\N	\N	PERMANENT
1691	2502	56	2019-11-01	2023-11-30	\N	\N	PERMANENT
1692	2503	41	2019-11-01	2023-11-30	\N	\N	PERMANENT
1693	2504	41	2019-11-01	2023-11-30	\N	\N	PERMANENT
1694	2505	61	2019-11-01	2023-11-30	\N	\N	PERMANENT
1695	2506	59	2019-11-01	2023-11-30	\N	\N	PERMANENT
1696	2507	65	2019-11-01	2023-11-30	\N	\N	PERMANENT
1697	2508	65	2019-11-01	2023-11-30	\N	\N	PERMANENT
1698	2509	25	2019-11-01	2023-11-30	\N	\N	PERMANENT
1699	2510	37	2019-11-01	2023-11-30	\N	\N	PERMANENT
1700	2511	55	2019-11-01	2023-11-30	\N	\N	PERMANENT
1701	2512	55	2019-11-01	2023-11-30	\N	\N	PERMANENT
1702	2513	55	2019-11-01	2023-11-30	\N	\N	PERMANENT
1703	2514	76	2019-08-01	\N	\N	\N	PERMANENT
1704	2515	17	2019-08-01	2022-08-30	\N	\N	PERMANENT
1705	2516	76	2019-08-01	2022-08-31	\N	\N	PERMANENT
1706	1454	3	2019-08-01	\N	\N	\N	PERMANENT
1707	2517	169	2019-08-01	2023-08-31	\N	\N	PERMANENT
1708	2518	169	2019-08-01	2023-08-31	\N	\N	PERMANENT
1709	2519	183	2019-08-01	2023-08-30	\N	\N	PERMANENT
1710	2520	184	2019-08-01	2023-08-31	\N	\N	PERMANENT
1711	2521	185	2019-08-01	2023-08-31	\N	\N	PERMANENT
1712	2522	88	2019-08-01	2023-08-31	\N	\N	PERMANENT
1713	2523	11	2019-08-01	2023-08-31	\N	\N	PERMANENT
1714	2524	182	2019-08-01	2022-08-31	\N	\N	PERMANENT
1715	2525	176	2019-08-01	2023-08-30	\N	\N	PERMANENT
1716	2526	177	2019-08-01	2023-08-31	\N	\N	PERMANENT
1717	2527	170	2019-08-01	2023-08-31	\N	\N	PERMANENT
1718	2528	171	2019-08-01	2022-08-31	\N	\N	PERMANENT
1719	2529	127	2019-08-01	2023-08-31	\N	\N	PERMANENT
1720	2530	127	2019-08-01	2023-08-31	\N	\N	PERMANENT
1721	2531	182	2019-08-01	2023-08-31	\N	\N	PERMANENT
1722	2532	182	2019-08-01	2022-08-31	\N	\N	PERMANENT
1723	2533	183	2019-08-01	2023-08-31	\N	\N	PERMANENT
1724	2534	179	2019-08-01	2023-08-31	\N	\N	PERMANENT
1725	2535	186	2019-08-01	2023-08-31	\N	\N	PERMANENT
1726	2536	176	2019-08-01	2023-08-31	\N	\N	PERMANENT
1727	2537	176	2019-08-01	2023-08-31	\N	\N	PERMANENT
1728	2538	180	2019-08-01	2023-08-31	\N	\N	PERMANENT
1729	2539	180	2019-08-01	2023-08-31	\N	\N	PERMANENT
1730	2540	128	2019-08-01	2023-08-31	\N	\N	PERMANENT
1731	2541	177	2019-08-01	2023-08-31	\N	\N	PERMANENT
1732	2542	171	2019-08-01	2023-08-31	\N	\N	PERMANENT
1733	2543	182	2019-08-01	2023-08-31	\N	\N	PERMANENT
1734	2544	74	2019-08-01	2023-08-31	\N	\N	PERMANENT
1735	2545	74	2019-08-01	2023-08-31	\N	\N	PERMANENT
1736	2546	181	2019-08-01	2023-08-31	\N	\N	PERMANENT
1737	2547	170	2019-08-01	2023-08-31	\N	\N	PERMANENT
1738	2548	183	2019-08-01	2023-08-31	\N	\N	PERMANENT
1739	2549	186	2019-08-01	2023-08-31	\N	\N	PERMANENT
1740	2550	179	2019-08-01	2023-08-31	\N	\N	PERMANENT
1741	2551	180	2019-08-01	2023-08-31	\N	\N	PERMANENT
1742	2552	184	2019-08-01	2023-08-31	\N	\N	PERMANENT
1743	2553	185	2019-08-01	2023-08-31	\N	\N	PERMANENT
1744	2554	185	2019-08-01	2023-08-31	\N	\N	PERMANENT
1745	2555	187	2019-08-01	2023-08-31	\N	\N	PERMANENT
1746	2556	128	2019-08-01	2023-08-31	\N	\N	PERMANENT
1747	2557	181	2019-08-01	2023-08-31	\N	\N	PERMANENT
1748	2558	126	2019-08-01	2023-08-31	\N	\N	PERMANENT
1749	2559	126	2019-08-01	2023-08-31	\N	\N	PERMANENT
1750	2560	127	2019-08-01	2023-08-31	\N	\N	PERMANENT
1751	2561	127	2019-08-01	2023-08-31	\N	\N	PERMANENT
1752	2562	176	2019-08-01	2023-08-31	\N	\N	PERMANENT
1753	2563	175	2019-08-01	2023-08-31	\N	\N	PERMANENT
1754	2564	171	2019-08-01	2023-08-31	\N	\N	PERMANENT
1755	2311	74	2019-08-01	\N	\N	\N	PERMANENT
1756	2565	179	2019-08-01	2023-08-31	\N	\N	PERMANENT
1757	2566	181	2019-08-01	2023-08-31	\N	\N	PERMANENT
1758	2567	126	2019-08-01	2023-08-31	\N	\N	PERMANENT
1759	1365	168	2019-08-01	\N	\N	\N	PERMANENT
1760	2568	13	2019-08-01	2023-08-31	\N	\N	PERMANENT
1761	2569	1	2019-08-01	2019-08-01	\N	\N	PERMANENT
1762	2569	185	2019-08-01	\N	\N	\N	PERMANENT
1763	1233	3	2019-08-01	\N	\N	\N	PERMANENT
1764	2570	76	2019-08-01	2023-08-31	\N	\N	PERMANENT
1765	2571	76	2019-08-01	2022-08-31	\N	\N	PERMANENT
1766	2572	177	2019-08-01	2023-08-01	\N	\N	PERMANENT
1767	2573	128	2019-08-01	2023-08-31	\N	\N	PERMANENT
1768	2574	126	2019-08-01	2023-08-31	\N	\N	PERMANENT
1769	2575	177	2019-08-01	2023-08-31	\N	\N	PERMANENT
1770	2576	179	2019-08-01	2023-08-31	\N	\N	PERMANENT
1771	2577	179	2019-08-01	2023-08-31	\N	\N	PERMANENT
1772	2578	126	2019-08-01	2023-08-31	\N	\N	PERMANENT
1773	2579	183	2019-08-01	2023-08-31	\N	\N	PERMANENT
1774	2580	187	2019-08-01	2023-08-17	\N	\N	PERMANENT
1775	2581	185	2019-08-01	2023-08-31	\N	\N	PERMANENT
1776	2582	186	2019-08-01	2023-08-31	\N	\N	PERMANENT
1777	2583	176	2019-08-01	2023-08-31	\N	\N	PERMANENT
1778	2584	176	2019-08-01	2023-08-31	\N	\N	PERMANENT
1779	2585	128	2019-08-01	2023-08-31	\N	\N	PERMANENT
1780	2586	183	2019-08-01	2023-08-31	\N	\N	PERMANENT
1781	2587	74	2019-08-01	2023-08-31	\N	\N	PERMANENT
1782	1763	76	2020-01-01	\N	\N	\N	PERMANENT
1783	2588	169	2019-08-01	2023-08-31	\N	\N	PERMANENT
1784	2589	169	2019-08-01	2023-08-31	\N	\N	PERMANENT
1785	2590	102	2019-08-01	2023-08-31	\N	\N	PERMANENT
1786	1210	76	2020-01-01	\N	\N	\N	PERMANENT
1787	2591	17	2019-08-01	2023-08-31	\N	\N	PERMANENT
1788	1367	76	2020-01-01	\N	\N	\N	PERMANENT
1789	1066	1	2020-01-01	\N	\N	\N	PERMANENT
1790	2592	3	2019-08-01	2023-08-31	\N	\N	PERMANENT
1791	997	100	2018-08-01	\N	\N	\N	PERMANENT
1792	1292	169	2018-08-01	\N	\N	\N	PERMANENT
1793	2352	168	2018-08-01	\N	\N	\N	PERMANENT
1794	2593	4	2019-08-01	2021-08-01	\N	\N	PERMANENT
1795	2594	1	2019-08-01	\N	\N	\N	PERMANENT
1796	2595	76	2019-08-01	\N	\N	\N	PERMANENT
\.


--
-- Data for Name: players; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.players (id, full_name, first_name, last_name, dob, nationality_id, "position", height_cm, preferred_foot, photo_url) FROM stdin;
955	Rostand Youthe	Rostand	Youthe	\N	5	GK	\N	\N	\N
956	Beno Kakolanya	Beno	Kakolanya	\N	56	GK	\N	\N	\N
957	Ramadhani Kabwili	Ramadhani	Kabwili	\N	56	GK	\N	\N	\N
958	Juma Abdul	Juma	Abdul	\N	56	DF	\N	\N	\N
959	Hassan Kessy Ramadhani	Hassan	Ramadhani	\N	56	GK	\N	\N	\N
960	Gadiel Michael	Gadiel	Michael	\N	56	DF	\N	\N	\N
961	Nadir Haroub	Nadir	Haroub	\N	56	DF	\N	\N	\N
962	Mwinyi Hadji	Mwinyi	Hadji	\N	56	DF	\N	\N	\N
963	Kelvin Yondani	Kelvin	Yondani	\N	56	DF	\N	\N	\N
964	Pato Ngonyani	Pato	Ngonyani	\N	56	DF	\N	\N	\N
965	Abdallah Shaibu	Abdallah	Shaibu	\N	56	DF	\N	\N	\N
966	Andrew Vicent Dante	Andrew	Vicent	\N	56	DF	\N	\N	\N
967	Rafael Daud	Rafael	Daud	\N	56	MF	\N	\N	\N
968	Thabani Kamusoko	Thabani	Kamusoko	\N	47	MF	\N	\N	\N
969	Maka Edward	Maka	Edward	\N	56	MF	\N	\N	\N
970	Said Juma	Said	Juma	\N	56	MF	\N	\N	\N
971	Pius Buswita	Pius	Buswita	\N	56	MF	\N	\N	\N
972	Pappy Kabamba Tshishimbi	Pappy	Tshishimbi	\N	51	MF	\N	\N	\N
973	Juma Mahadhi	Juma	Mahadhi	\N	56	MF	\N	\N	\N
974	Geofrey Mwashiuya	Geofrey	Mwashiuya	\N	56	MF	\N	\N	\N
975	Emmanuel Martin	Emmanuel	Martin	\N	56	MF	\N	\N	\N
976	Baruan Yahya	Baruan	Yahya	\N	56	MF	\N	\N	\N
977	Yusuph Mhilu	Yusuph	Mhilu	\N	56	MF	\N	\N	\N
978	Said Bakari Mussa	Said	Mussa	\N	56	MF	\N	\N	\N
979	Donald Ngoma	Donald	Ngoma	\N	47	FW	\N	\N	\N
980	Amissi Tambwe	Amissi	Tambwe	\N	4	FW	\N	\N	\N
981	Matheo Anthony	Matheo	Anthony	\N	56	FW	\N	\N	\N
982	Ibrahim Ajib Migomba	Ibrahim	Migomba	\N	56	FW	\N	\N	\N
983	Obrey Chirwa	Obrey	Chirwa	\N	58	FW	\N	\N	\N
984	Ally Mustapha Barthez	Ally	Mustapha	\N	56	GK	\N	\N	\N
985	Peter Manyika	Peter	Manyika	\N	56	GK	\N	\N	\N
986	Said Lubawa	Said	Lubawa	\N	56	GK	\N	\N	\N
987	Jacton Robert	Jacton	Robert	\N	56	GK	\N	\N	\N
988	Elisha Muroiwa	Elisha	Muroiwa	\N	47	DF	\N	\N	\N
989	Kennedy Juma	Kennedy	Juma	\N	56	DF	\N	\N	\N
990	Roland Msonjo	Roland	Msonjo	\N	56	DF	\N	\N	\N
991	Shafik Batambuze	Shafik	Batambuze	\N	54	DF	\N	\N	\N
992	Salum Chuku	Salum	Chuku	\N	56	DF	\N	\N	\N
993	Michel Rusheshangonga	Michel	Rusheshangonga	\N	39	DF	\N	\N	\N
994	Miraj Adam	Miraj	Adam	\N	56	DF	\N	\N	\N
995	Salum Kipaga	Salum	Kipaga	\N	56	DF	\N	\N	\N
996	Kenny Ally	Kenny	Ally	\N	56	MF	\N	\N	\N
997	Mudathir Yahya	Mudathir	Yahya	\N	56	MF	\N	\N	\N
998	Yusuph Kagoma	Yusuph	Kagoma	\N	56	MF	\N	\N	\N
999	Twafadzwa Kutinyu	Twafadzwa	Kutinyu	\N	47	MF	\N	\N	\N
1000	Nizar Khalfan	Nizar	Khalfan	\N	56	MF	\N	\N	\N
1001	Elinyesia Sumbi	Elinyesia	Sumbi	\N	56	FW	\N	\N	\N
1002	Pastory Athanas	Pastory	Athanas	\N	56	FW	\N	\N	\N
1003	Deus Kaseke	Deus	Kaseke	\N	56	FW	\N	\N	\N
1004	Kigi Makassy	Kigi	Makassy	\N	56	FW	\N	\N	\N
1005	Atupele Green	Atupele	Green	\N	56	FW	\N	\N	\N
1006	Simbarashe Nhivi	Simbarashe	Nhivi	\N	56	FW	\N	\N	\N
1007	Danny Usengimana	Danny	Usengimana	\N	39	FW	\N	\N	\N
1008	Michelle Katsvairo	Michelle	Katsvairo	\N	47	FW	\N	\N	\N
1009	Aishi Manula	Aishi	Manula	\N	56	GK	\N	\N	\N
1010	Emmanuel Mseja	Emmanuel	Mseja	\N	56	GK	\N	\N	\N
1011	Said Mohamed Nduda	Said	Mohamed	\N	56	GK	\N	\N	\N
1012	Salim Mbonde	Salim	Mbonde	\N	56	DF	\N	\N	\N
1013	Yusuph Mpilili	Yusuph	Mpilili	\N	56	DF	\N	\N	\N
1014	Juuko Murshid	Juuko	Murshid	\N	54	DF	\N	\N	\N
1015	Shomari Kapombe	Shomari	Kapombe	\N	56	DF	\N	\N	\N
1016	Mohamed Hussein Zibwe Jr	Mohamed	Hussein	\N	56	DF	\N	\N	\N
1017	Method Mwanjali	Method	Mwanjali	\N	47	DF	\N	\N	\N
1018	Erasto Nyoni	Erasto	Nyoni	\N	56	DF	\N	\N	\N
1019	Ally Shomari	Ally	Shomari	\N	56	DF	\N	\N	\N
1020	Paul Bukaba	Paul	Bukaba	\N	56	DF	\N	\N	\N
1021	Jamal Mwambeleko	Jamal	Mwambeleko	\N	56	DF	\N	\N	\N
1022	James Kotei	James	Kotei	\N	20	MF	\N	\N	\N
1023	Mohamed Ibrahim	Mohamed	Ibrahim	\N	56	MF	\N	\N	\N
1024	Mohamed Ibrahim	Mohamed	Ibrahim	\N	56	MF	\N	\N	\N
1025	Haruna Niyonzima	Haruna	Niyonzima	\N	39	MF	\N	\N	\N
1026	Said Hamis Ndemla	Said	Ndemla	\N	56	MF	\N	\N	\N
1027	Jamal Mnyate	Jamal	Mnyate	\N	56	MF	\N	\N	\N
1028	Mzamiru Yassin	Mzamiru	Yassin	\N	56	MF	\N	\N	\N
1029	Jonas Mkude	Jonas	Mkude	\N	56	MF	\N	\N	\N
1030	Mwinyi Kazimoto	Mwinyi	Kazimoto	\N	56	MF	\N	\N	\N
1031	Shiza Kichuya	Shiza	Kichuya	\N	56	MF	\N	\N	\N
1032	Francis Kahata	Francis	Kahata	\N	56	FW	\N	\N	\N
1033	Juma Luizio	Juma	Luizio	\N	56	FW	\N	\N	\N
1034	Laudit Mavugo	Laudit	Mavugo	\N	4	FW	\N	\N	\N
1035	John Bocco	John	Bocco	\N	56	FW	\N	\N	\N
1036	Nicholous Gyan	Nicholous	Gyan	\N	20	FW	\N	\N	\N
1037	Bidii Hussein	Bidii	Hussein	\N	56	GK	\N	\N	\N
1038	Said Madega	Said	Madega	\N	56	DF	\N	\N	\N
1039	Mangasini Mbonosi	Mangasini	Mbonosi	\N	56	DF	\N	\N	\N
1040	Yusuph Nguya	Yusuph	Nguya	\N	56	DF	\N	\N	\N
1041	Shaibu Nayopa	Shaibu	Nayopa	\N	56	DF	\N	\N	\N
1042	Baraka Mtuwi	Baraka	Mtuwi	\N	56	MF	\N	\N	\N
1043	Chande Magoja	Chande	Magoja	\N	56	MF	\N	\N	\N
1044	Shaban Msala	Shaban	Msala	\N	56	MF	\N	\N	\N
1045	Ishala Juma	Ishala	Juma	\N	56	MF	\N	\N	\N
1046	Jamal Soud	Jamal	Soud	\N	56	MF	\N	\N	\N
1047	Khamis Mcha	Khamis	Mcha	\N	56	FW	\N	\N	\N
1048	Abdallah Rashid	Abdallah	Rashid	\N	56	GK	\N	\N	\N
1049	Aman George	Aman	George	\N	56	DF	\N	\N	\N
1050	Mau Bofu	Mau	Bofu	\N	56	DF	\N	\N	\N
1051	Frank Msese	Frank	Msese	\N	56	FW	\N	\N	\N
1052	Zuberi Dabi	Zuberi	Dabi	\N	56	FW	\N	\N	\N
1053	William Patric	William	Patric	\N	56	MF	\N	\N	\N
1054	Said Dilunga	Said	Dilunga	\N	56	MF	\N	\N	\N
1055	Razak Abalora	Razak	Abalora	\N	20	GK	\N	\N	\N
1056	Agrey Moris	Agrey	Moris	\N	56	DF	\N	\N	\N
1057	Yakubu Mohamed	Yakubu	Mohamed	\N	20	DF	\N	\N	\N
1058	Daniel Amoah	Daniel	Amoah	\N	20	DF	\N	\N	\N
1059	Bruce Kangwa	Bruce	Kangwa	\N	47	DF	\N	\N	\N
1060	Himid Mao	Himid	Mao	\N	56	MF	\N	\N	\N
1061	Enock Atta Agyei	Enock	Agyei	\N	20	MF	\N	\N	\N
1062	Stephan Kingue Mpondo	Stephan	Mpondo	\N	5	MF	\N	\N	\N
1063	Frank Raymond Domayo	Frank	Domayo	\N	56	MF	\N	\N	\N
1064	Salum Abubakar	Salum	Abubakar	\N	56	MF	\N	\N	\N
1065	Yahya Zayd	Yahya	Zayd	\N	56	MF	\N	\N	\N
1066	Braison Raphael	Braison	Raphael	\N	56	MF	\N	\N	\N
1067	Yahaya Mohammed	Yahaya	Mohammed	\N	20	FW	\N	\N	\N
1068	Mbaraka Yusuph	Mbaraka	Yusuph	\N	56	FW	\N	\N	\N
1069	Hamimu Karim	Hamimu	Karim	\N	56	DF	\N	\N	\N
1070	Wazir Junior	Wazir	Junior	\N	56	FW	\N	\N	\N
1071	Shaban Idd Chilunda	Shaban	Chilunda	\N	56	FW	\N	\N	\N
1072	Khamis Mcha Khamis	Khamis	Khamis	\N	56	FW	\N	\N	\N
1073	Gadiel Michael Mbaga	Gadiel	Mbaga	\N	56	DF	\N	\N	\N
1074	Shaban Hassan Kado	Shaban	Kado	\N	56	GK	\N	\N	\N
1075	Abdallah Said Makangana	Abdallah	Makangana	\N	56	GK	\N	\N	\N
1076	Benedictor Tinocco Mlekwa	Benedictor	Mlekwa	\N	56	GK	\N	\N	\N
1077	Salum Kupela Kanoni	Salum	Kanoni	\N	56	DF	\N	\N	\N
1078	Rodgers Gabriel Jigwa	Rodgers	Jigwa	\N	56	DF	\N	\N	\N
1079	Issa Rashid Issa	Issa	Issa	\N	56	DF	\N	\N	\N
1080	Hassan Juma Mganga	Hassan	Mganga	\N	56	DF	\N	\N	\N
1081	Dickson Daud Mbeikya	Dickson	Mbeikya	\N	56	DF	\N	\N	\N
1082	Cassian Ponera Cassian	Cassian	Cassian	\N	56	DF	\N	\N	\N
1083	Hassan Suleyman Isihaka	Hassan	Isihaka	\N	56	DF	\N	\N	\N
1084	Hussen Idd Hante	Hussen	Hante	\N	56	DF	\N	\N	\N
1085	Hassan Saleh Dilunga	Hassan	Dilunga	\N	56	MF	\N	\N	\N
1086	Saleh Khamis Abdallah	Saleh	Abdallah	\N	56	MF	\N	\N	\N
1087	Ayoub Idrissa Semtawa	Ayoub	Semtawa	\N	56	MF	\N	\N	\N
1088	Ismail Aidan Mhesa	Ismail	Mhesa	\N	56	MF	\N	\N	\N
1089	Ally Makarani Kilombo	Ally	Kilombo	\N	56	MF	\N	\N	\N
1090	Shaban Mussa Nditi	Shaban	Nditi	\N	56	MF	\N	\N	\N
1091	Henry Joseph Shindika	Henry	Shindika	\N	56	MF	\N	\N	\N
1092	Vicent Barnabas Juma	Vicent	Juma	\N	56	MF	\N	\N	\N
1093	Mohamed Issa Juma	Mohamed	Juma	\N	56	MF	\N	\N	\N
1094	Haruna Athuman Chanongo	Haruna	Chanongo	\N	56	MF	\N	\N	\N
1095	Issa Kajia Kigingi	Issa	Kigingi	\N	56	MF	\N	\N	\N
1096	Hussein Omar Javu	Hussein	Javu	\N	56	FW	\N	\N	\N
1097	Stamil Mohamed Mbonde	Stamil	Mbonde	\N	56	FW	\N	\N	\N
1098	Riphat Khamis Msuya	Riphat	Msuya	\N	56	FW	\N	\N	\N
1099	Kelvin Sabato Kongwe	Kelvin	Kongwe	\N	56	FW	\N	\N	\N
1100	Salum Ramadhani Kihimbwa	Salum	Kihimbwa	\N	56	FW	\N	\N	\N
1101	Juma Kaseja	Juma	Kaseja	\N	56	GK	\N	\N	\N
1102	Said Kipao	Said	Kipao	\N	56	GK	\N	\N	\N
1103	Juma Nyoso	Juma	Nyoso	\N	56	DF	\N	\N	\N
1104	Adeyun Ahmed	Adeyun	Ahmed	\N	56	DF	\N	\N	\N
1105	Mohamed Fakh	Mohamed	Fakh	\N	56	DF	\N	\N	\N
1106	Ally Nassoro	Ally	Nassoro	\N	56	DF	\N	\N	\N
1107	Edward Christopher	Edward	Christopher	\N	56	DF	\N	\N	\N
1108	Ally Mashaka	Ally	Mashaka	\N	56	DF	\N	\N	\N
1109	Hassan Khatib	Hassan	Khatib	\N	56	DF	\N	\N	\N
1110	Hassan Khatib	Hassan	Khatib	\N	56	DF	\N	\N	\N
1111	Khashiru Salum.	Khashiru	Salum.	\N	56	GK	\N	\N	\N
1112	Uzoka Godspower	Uzoka	Godspower	\N	56	DF	\N	\N	\N
1113	Peter Mwalyanzi	Peter	Mwalyanzi	\N	56	MF	\N	\N	\N
1114	Japhary Kibaya	Japhary	Kibaya	\N	56	MF	\N	\N	\N
1115	Omary Daga	Omary	Daga	\N	56	MF	\N	\N	\N
1116	Abdalah Mguhi	Abdalah	Mguhi	\N	56	MF	\N	\N	\N
1117	Ramadhani Chalamanda	Ramadhani	Chalamanda	\N	56	MF	\N	\N	\N
1118	Venance Ludovic	Venance	Ludovic	\N	56	MF	\N	\N	\N
1119	George Kavira	George	Kavira	\N	56	MF	\N	\N	\N
1120	Godfrey Taita	Godfrey	Taita	\N	56	MF	\N	\N	\N
1121	Japhet Makalai	Japhet	Makalai	\N	56	MF	\N	\N	\N
1122	Juma Shemvuni	Juma	Shemvuni	\N	56	DF	\N	\N	\N
1123	Salvatory Mufelebe	Salvatory	Mufelebe	\N	56	MF	\N	\N	\N
1124	Salehe Mwaita	Salehe	Mwaita	\N	56	MF	\N	\N	\N
1125	Selemani Mangoma	Selemani	Mangoma	\N	56	MF	\N	\N	\N
1126	Ame Ally Zungu	Ame	Ally	\N	56	FW	\N	\N	\N
1127	Themi Felix	Themi	Felix	\N	58	FW	\N	\N	\N
1128	Paul Lucas Ngalyoma	Paul	Ngalyoma	\N	56	FW	\N	\N	\N
1129	Agathon Mkwando	Agathon	Mkwando	\N	56	GK	\N	\N	\N
1130	Samwel Mathayo	Samwel	Mathayo	\N	56	DF	\N	\N	\N
1131	Novalty Lufunga	Novalty	Lufunga	\N	56	DF	\N	\N	\N
1132	Joseph Owino	Joseph	Owino	\N	54	DF	\N	\N	\N
1133	Asante Kwasi	Asante	Kwasi	\N	56	DF	\N	\N	\N
1134	Paul Ngalema	Paul	Ngalema	\N	56	DF	\N	\N	\N
1135	Omega Seme	Omega	Seme	\N	56	MF	\N	\N	\N
1136	Seif Rashid Karihe	Seif	Karihe	\N	56	MF	\N	\N	\N
1137	Shaban Zuberi	Shaban	Zuberi	\N	56	MF	\N	\N	\N
1138	Ramadhani Madebe	Ramadhani	Madebe	\N	56	MF	\N	\N	\N
1139	Maalim Busungu	Maalim	Busungu	\N	56	FW	\N	\N	\N
1140	Mussa Nampaka	Mussa	Nampaka	\N	56	MF	\N	\N	\N
1141	Salum Machaku	Salum	Machaku	\N	56	MF	\N	\N	\N
1142	Aristotle Kyatwa	Aristotle	Kyatwa	\N	56	DF	\N	\N	\N
1143	Hussein Dumba	Hussein	Dumba	\N	56	DF	\N	\N	\N
1144	Ally Mtoni	Ally	Mtoni	\N	56	DF	\N	\N	\N
1145	Zamoyoni Pangapanga	Zamoyoni	Pangapanga	\N	56	MF	\N	\N	\N
1146	Tola Antony	Tola	Antony	\N	56	MF	\N	\N	\N
1147	Fadhil Butam	Fadhil	Butam	\N	56	MF	\N	\N	\N
1148	Moka Msafiri	Moka	Msafiri	\N	56	MF	\N	\N	\N
1149	Erick Kayombo	Erick	Kayombo	\N	56	MF	\N	\N	\N
1150	Hamad Manzi	Hamad	Manzi	\N	56	MF	\N	\N	\N
1151	Wazir Hussein	Wazir	Hussein	\N	56	MF	\N	\N	\N
1152	Mussa Ngunda	Mussa	Ngunda	\N	56	MF	\N	\N	\N
1153	Lambele Jerome	Lambele	Jerome	\N	56	MF	\N	\N	\N
1154	Emmanuel Kichiba	Emmanuel	Kichiba	\N	56	MF	\N	\N	\N
1155	Fred Tangalu	Fred	Tangalu	\N	56	MF	\N	\N	\N
1156	Martin Kazila	Martin	Kazila	\N	56	GK	\N	\N	\N
1157	Mohamed Yusuph	Mohamed	Yusuph	\N	56	FW	\N	\N	\N
1158	Hemed Mshewa	Hemed	Mshewa	\N	56	MF	\N	\N	\N
1159	Jamal Masenga	Jamal	Masenga	\N	56	MF	\N	\N	\N
1160	Owen Chaima	Owen	Chaima	\N	28	GK	\N	\N	\N
1161	Fikiri Bakari	Fikiri	Bakari	\N	56	GK	\N	\N	\N
1162	Haruna Mandanda	Haruna	Mandanda	\N	56	DF	\N	\N	\N
1163	Emmanuel Kakoti	Emmanuel	Kakoti	\N	56	DF	\N	\N	\N
1164	John Kabanda	John	Kabanda	\N	56	GK	\N	\N	\N
1165	Haruna Shamte	Haruna	Shamte	\N	56	DF	\N	\N	\N
1166	Hassan Mwasapile	Hassan	Mwasapile	\N	56	DF	\N	\N	\N
1167	Majaliwa Shaban	Majaliwa	Shaban	\N	56	DF	\N	\N	\N
1168	Sankhani Mkandawile	Sankhani	Mkandawile	\N	56	DF	\N	\N	\N
1169	Erick Kyaruzi	Erick	Kyaruzi	\N	56	MF	\N	\N	\N
1170	Ally Lundenga	Ally	Lundenga	\N	56	MF	\N	\N	\N
1171	Ramadhani Adam Malima	Ramadhani	Malima	\N	56	MF	\N	\N	\N
1172	Babu Ally	Babu	Ally	\N	56	MF	\N	\N	\N
1173	Medaoni Mwakatundu	Medaoni	Mwakatundu	\N	56	MF	\N	\N	\N
1174	Daniel Joram	Daniel	Joram	\N	56	MF	\N	\N	\N
1175	Hamidu Mohamed	Hamidu	Mohamed	\N	56	MF	\N	\N	\N
1176	Masoud Bakari	Masoud	Bakari	\N	56	MF	\N	\N	\N
1177	Mohamed Samata	Mohamed	Samata	\N	56	MF	\N	\N	\N
1178	Rajab Isihaka	Rajab	Isihaka	\N	56	MF	\N	\N	\N
1179	Idd Suleiman	Idd	Suleiman	\N	56	MF	\N	\N	\N
1180	Frank Khamis	Frank	Khamis	\N	56	MF	\N	\N	\N
1181	Anthony Mwingila	Anthony	Mwingila	\N	56	MF	\N	\N	\N
1182	Omary Ramadhani	Omary	Ramadhani	\N	56	MF	\N	\N	\N
1183	Victor Hangaya	Victor	Hangaya	\N	56	FW	\N	\N	\N
1184	Mrisho Ngassa	Mrisho	Ngassa	\N	56	FW	\N	\N	\N
1185	Meshack Suleman	Meshack	Suleman	\N	56	FW	\N	\N	\N
1186	Mohamed Mkopi	Mohamed	Mkopi	\N	56	FW	\N	\N	\N
1187	Kenny Ally	Kenny	Ally	\N	56	MF	\N	\N	\N
1188	David Kisu	David	Kisu	\N	56	GK	\N	\N	\N
1189	Salehe Libenanga	Salehe	Libenanga	\N	56	GK	\N	\N	\N
1190	Erick Kaphom	Erick	Kaphom	\N	56	GK	\N	\N	\N
1191	Agatho Mapund	Agatho	Mapund	\N	56	DF	\N	\N	\N
1192	Laban Kambole	Laban	Kambole	\N	56	DF	\N	\N	\N
1193	Hussein Hussein	Hussein	Hussein	\N	56	DF	\N	\N	\N
1194	Mark Mwambungulu	Mark	Mwambungulu	\N	56	DF	\N	\N	\N
1195	Peter Mwangosi	Peter	Mwangosi	\N	56	DF	\N	\N	\N
1196	Ahmed Tajudin	Ahmed	Tajudin	\N	56	DF	\N	\N	\N
1197	Innocent Lazaro	Innocent	Lazaro	\N	56	DF	\N	\N	\N
1198	Mustapha Athuman	Mustapha	Athuman	\N	56	DF	\N	\N	\N
1199	Aden Kipepeo	Aden	Kipepeo	\N	56	DF	\N	\N	\N
1200	Khatib Geofrey	Khatib	Geofrey	\N	56	MF	\N	\N	\N
1201	Christopher Kasewa	Christopher	Kasewa	\N	56	MF	\N	\N	\N
1202	Hassan Nassor	Hassan	Nassor	\N	56	MF	\N	\N	\N
1203	Awadh Juma	Awadh	Juma	\N	56	MF	\N	\N	\N
1204	Joshua John	Joshua	John	\N	56	MF	\N	\N	\N
1205	Jimmy Shoji	Jimmy	Shoji	\N	56	MF	\N	\N	\N
1206	Claide Wigenge	Claide	Wigenge	\N	56	MF	\N	\N	\N
1207	Juma Mpakala	Juma	Mpakala	\N	56	MF	\N	\N	\N
1208	Adam Bako	Adam	Bako	\N	56	MF	\N	\N	\N
1209	David Obashi	David	Obashi	\N	56	MF	\N	\N	\N
1210	Ditram Nchimbi	Ditram	Nchimbi	\N	56	FW	\N	\N	\N
1211	Kilupe Gwamaka	Kilupe	Gwamaka	\N	56	FW	\N	\N	\N
1212	Shaaban Kondo	Shaaban	Kondo	\N	56	FW	\N	\N	\N
1213	James Olashipe	James	Olashipe	\N	56	MF	\N	\N	\N
1214	Thomas Tamla	Thomas	Tamla	\N	56	MF	\N	\N	\N
1215	Notkely Masasi	Notkely	Masasi	\N	56	MF	\N	\N	\N
1216	Fully Maganga	Fully	Maganga	\N	56	FW	\N	\N	\N
1217	Issa Kanduru	Issa	Kanduru	\N	56	MF	\N	\N	\N
1218	Rafael Keyala	Rafael	Keyala	\N	56	MF	\N	\N	\N
1219	Paul Nonga	Paul	Nonga	\N	56	FW	\N	\N	\N
1220	Salim Hamis	Salim	Hamis	\N	56	MF	\N	\N	\N
1221	Boniface Maganga	Boniface	Maganga	\N	56	MF	\N	\N	\N
1222	Eliud Ambokile	Eliud	Ambokile	\N	56	FW	\N	\N	\N
1223	Kassim Hamis	Kassim	Hamis	\N	56	FW	\N	\N	\N
1224	Nurdin Chona	Nurdin	Chona	\N	56	MF	\N	\N	\N
1225	Simon Msuva	Simon	Msuva	\N	56	FW	\N	\N	\N
1226	Jeremia Kisubi	Jeremia	Kisubi	\N	56	GK	\N	\N	\N
1227	William Lucian	William	Lucian	\N	56	DF	\N	\N	\N
1228	Ally Mohammed	Ally	Mohammed	\N	56	DF	\N	\N	\N
1229	Hamad Waziri	Hamad	Waziri	\N	56	DF	\N	\N	\N
1230	Rajabu Zahiri	Rajabu	Zahiri	\N	56	DF	\N	\N	\N
1231	Hemed Khoja	Hemed	Khoja	\N	56	MF	\N	\N	\N
1232	Jacob Massawe	Jacob	Massawe	\N	56	MF	\N	\N	\N
1233	Jabiri Aziz	Jabiri	Aziz	\N	56	MF	\N	\N	\N
1234	Omary Mponda	Omary	Mponda	\N	56	MF	\N	\N	\N
1235	Majid Bakari	Majid	Bakari	\N	56	FW	\N	\N	\N
1236	Nassoro Kapama	Nassoro	Kapama	\N	56	FW	\N	\N	\N
1237	Ayoub Masoud	Ayoub	Masoud	\N	56	DF	\N	\N	\N
1238	Kelvin Friday	Kelvin	Friday	\N	56	MF	\N	\N	\N
1239	Diel Hassan	Diel	Hassan	\N	56	GK	\N	\N	\N
1240	Salum Minelly	Salum	Minelly	\N	56	DF	\N	\N	\N
1241	Alex Seth	Alex	Seth	\N	56	DF	\N	\N	\N
1242	Abdul Hamis	Abdul	Hamis	\N	56	MF	\N	\N	\N
1243	Baraka Majogoro	Baraka	Majogoro	\N	56	FW	\N	\N	\N
1244	Ahmad Msumi	Ahmad	Msumi	\N	56	FW	\N	\N	\N
1245	Peter Mapunda	Peter	Mapunda	\N	56	FW	\N	\N	\N
1246	Habib Kiyombo	Habib	Kiyombo	\N	56	FW	\N	\N	\N
1247	Rafael Siame	Rafael	Siame	\N	56	FW	\N	\N	\N
1248	Rajabu Mbulu	Rajabu	Mbulu	\N	56	GK	\N	\N	\N
1249	France Anyingisye	France	Anyingisye	\N	56	GK	\N	\N	\N
1250	Anold Massawe	Anold	Massawe	\N	56	GK	\N	\N	\N
1251	Malika Ndeule	Malika	Ndeule	\N	56	DF	\N	\N	\N
1252	David Luhende	David	Luhende	\N	56	DF	\N	\N	\N
1253	Revocatus Mgunga	Revocatus	Mgunga	\N	56	DF	\N	\N	\N
1254	Abdallah Mfuko	Abdallah	Mfuko	\N	56	MF	\N	\N	\N
1255	Razack Khalfan	Razack	Khalfan	\N	56	MF	\N	\N	\N
1256	Abdallah Sesseme	Abdallah	Sesseme	\N	56	MF	\N	\N	\N
1257	Awadhi Juma	Awadhi	Juma	\N	56	MF	\N	\N	\N
1258	Evaristus Mjwahuki	Evaristus	Mjwahuki	\N	56	MF	\N	\N	\N
1259	Gerald Mathias	Gerald	Mathias	\N	56	FW	\N	\N	\N
1260	Hassan Kabunda	Hassan	Kabunda	\N	56	FW	\N	\N	\N
1261	Mohamed Rashid	Mohamed	Rashid	\N	56	FW	\N	\N	\N
1262	Marcel Boniface	Marcel	Boniface	\N	56	FW	\N	\N	\N
1263	Eliuta Mpepo	Eliuta	Mpepo	\N	56	MF	\N	\N	\N
1264	Abdallah Abdallah	Abdallah	Abdallah	\N	56	GK	\N	\N	\N
1265	George Wawa	George	Wawa	\N	56	DF	\N	\N	\N
1266	Ayoub Kitala	Ayoub	Kitala	\N	56	MF	\N	\N	\N
1267	Kassim Dabi	Kassim	Dabi	\N	56	MF	\N	\N	\N
1268	Salehe Malande	Salehe	Malande	\N	56	GK	\N	\N	\N
1269	Aziz Sibo	Aziz	Sibo	\N	56	DF	\N	\N	\N
1270	Mpoki Mwakinyuke	Mpoki	Mwakinyuke	\N	56	DF	\N	\N	\N
1271	Kennedy Kipepe	Kennedy	Kipepe	\N	56	DF	\N	\N	\N
1272	Tumba Sued	Tumba	Sued	\N	56	DF	\N	\N	\N
1273	Hassan Hamis	Hassan	Hamis	\N	56	MF	\N	\N	\N
1274	Seleman Selembe	Seleman	Selembe	\N	56	MF	\N	\N	\N
1275	Yakubu Kibiga	Yakubu	Kibiga	\N	56	FW	\N	\N	\N
1276	Geofrey Mlawa	Geofrey	Mlawa	\N	56	FW	\N	\N	\N
1277	Paul Peter	Paul	Peter	\N	56	FW	\N	\N	\N
1278	Frank Muwonge	Frank	Muwonge	\N	56	GK	\N	\N	\N
1279	Ally Ally	Ally	Ally	\N	56	DF	\N	\N	\N
1280	Aroni Lulambo	Aroni	Lulambo	\N	56	DF	\N	\N	\N
1281	Hamad Kibopile	Hamad	Kibopile	\N	56	DF	\N	\N	\N
1282	Jisend Maganda	Jisend	Maganda	\N	56	DF	\N	\N	\N
1283	Rajabu Rashid	Rajabu	Rashid	\N	56	MF	\N	\N	\N
1284	Kitoba Emmanuel	Kitoba	Emmanuel	\N	56	MF	\N	\N	\N
1285	Mageta Milambo	Mageta	Milambo	\N	56	MF	\N	\N	\N
1286	Adam Salamba	Adam	Salamba	\N	56	MF	\N	\N	\N
1287	Mtasa Munashe	Mtasa	Munashe	\N	56	FW	\N	\N	\N
1288	John Rwitiko	John	Rwitiko	\N	56	FW	\N	\N	\N
1289	Mohamed Makaka	Mohamed	Makaka	\N	56	GK	\N	\N	\N
1290	Majid Kimbondile	Majid	Kimbondile	\N	56	DF	\N	\N	\N
1291	James Muganda	James	Muganda	\N	56	DF	\N	\N	\N
1292	Sixtus Sabilo	Sixtus	Sabilo	\N	56	MF	\N	\N	\N
1293	Kisatya Sahani	Kisatya	Sahani	\N	56	FW	\N	\N	\N
1294	Morice Mahela	Morice	Mahela	\N	56	FW	\N	\N	\N
1295	Ngambi Robert	Ngambi	Robert	\N	28	FW	\N	\N	\N
1296	Kelvin Igendelezi	Kelvin	Igendelezi	\N	56	GK	\N	\N	\N
1297	Abubakar Ngalema	Abubakar	Ngalema	\N	56	DF	\N	\N	\N
1298	Yusuph Mgeta	Yusuph	Mgeta	\N	56	DF	\N	\N	\N
1299	Yusuph Ndikumana	Yusuph	Ndikumana	\N	56	DF	\N	\N	\N
1300	Sadala Lipangile	Sadala	Lipangile	\N	56	MF	\N	\N	\N
1301	Ibrahim Njohole	Ibrahim	Njohole	\N	56	MF	\N	\N	\N
1302	Hussein Kassanga	Hussein	Kassanga	\N	56	MF	\N	\N	\N
1303	Mosses Shabani	Mosses	Shabani	\N	56	FW	\N	\N	\N
1304	Said Khamis Said	Said	Said	\N	56	FW	\N	\N	\N
1305	Kabally Swalehe	Kabally	Swalehe	\N	56	GK	\N	\N	\N
1306	James Msuva	James	Msuva	\N	56	DF	\N	\N	\N
1307	Herbet Lukindo	Herbet	Lukindo	\N	56	MF	\N	\N	\N
1308	Daud Mwasa	Daud	Mwasa	\N	56	MF	\N	\N	\N
1309	Amos Charles	Amos	Charles	\N	56	MF	\N	\N	\N
1310	Ndaki Kisambare	Ndaki	Kisambare	\N	56	FW	\N	\N	\N
1311	Emmanuel Muvyekore	Emmanuel	Muvyekore	\N	56	FW	\N	\N	\N
1312	Renatus Kisase	Renatus	Kisase	\N	56	DF	\N	\N	\N
1313	Hamis Ismail	Hamis	Ismail	\N	56	MF	\N	\N	\N
1314	Abdulahman Mussa	Abdulahman	Mussa	\N	56	FW	\N	\N	\N
1315	Jerrison Tegete	Jerrison	Tegete	\N	56	FW	\N	\N	\N
1316	Hashim Mussa	Hashim	Mussa	\N	56	GK	\N	\N	\N
1317	Idrissa Mohamed	Idrissa	Mohamed	\N	56	DF	\N	\N	\N
1318	Paulo Maona	Paulo	Maona	\N	56	DF	\N	\N	\N
1319	Jaffari Mohamed	Jaffari	Mohamed	\N	56	MF	\N	\N	\N
1320	Danny Mrwanda	Danny	Mrwanda	\N	56	FW	\N	\N	\N
1321	Lukasi Kikoti	Lukasi	Kikoti	\N	56	FW	\N	\N	\N
1322	Ibrahim Izack Job	Ibrahim	Job	\N	56	DF	\N	\N	\N
1323	Abdallah Waziri Selemani	Abdallah	Selemani	\N	56	MF	\N	\N	\N
1324	John Tibai George	John	George	\N	56	MF	\N	\N	\N
1325	Erick Mulilo	Erick	Mulilo	\N	56	DF	\N	\N	\N
1326	Juvenary Pastory	Juvenary	Pastory	\N	56	MF	\N	\N	\N
1327	Bakari Mohamed	Bakari	Mohamed	\N	56	MF	\N	\N	\N
1328	Miraji Makka	Miraji	Makka	\N	56	FW	\N	\N	\N
1329	Iddi Kipangwile	Iddi	Kipangwile	\N	56	MF	\N	\N	\N
1330	Stephan Sesegnon	Stephan	Sesegnon	\N	13	FW	\N	\N	\N
1331	Elius Maguli	Elius	Maguli	\N	56	FW	\N	\N	\N
1332	Aron Kalambo	Aron	Kalambo	\N	56	GK	\N	\N	\N
1333	Michael Ismail	Michael	Ismail	\N	56	DF	\N	\N	\N
1334	James Mwasote	James	Mwasote	\N	56	DF	\N	\N	\N
1335	Jumanne Elfadhili	Jumanne	Elfadhili	\N	56	DF	\N	\N	\N
1336	Salum Kimenya	Salum	Kimenya	\N	56	MF	\N	\N	\N
1337	Lambert Sabiyanka	Lambert	Sabiyanka	\N	56	FW	\N	\N	\N
1338	Laurian Mpapile	Laurian	Mpapile	\N	56	DF	\N	\N	\N
1339	Hassan Msham	Hassan	Msham	\N	56	GK	\N	\N	\N
1340	Hamis Maingo	Hamis	Maingo	\N	56	DF	\N	\N	\N
1341	Salum Bosco	Salum	Bosco	\N	56	MF	\N	\N	\N
1342	Fredy Chudu	Fredy	Chudu	\N	56	MF	\N	\N	\N
1343	Kazungu Mashauri	Kazungu	Mashauri	\N	56	MF	\N	\N	\N
1344	Leonsi Mutalemwa	Leonsi	Mutalemwa	\N	56	FW	\N	\N	\N
1345	Vedastus Mwishambi	Vedastus	Mwishambi	\N	56	FW	\N	\N	\N
1346	Juma Masoud	Juma	Masoud	\N	23	MF	\N	\N	\N
1347	Otiene Duncan	Otiene	Duncan	\N	23	FW	\N	\N	\N
1348	Abdullah Fakhi	Abdullah	Fakhi	\N	26	GK	\N	\N	\N
1349	Aljamal Tariq	Aljamal	Tariq	\N	26	DF	\N	\N	\N
1350	Sabbou Motassem	Sabbou	Motassem	\N	26	DF	\N	\N	\N
1351	Ajbarah Saed	Ajbarah	Saed	\N	26	DF	\N	\N	\N
1352	Maetoyq Ali	Maetoyq	Ali	\N	26	DF	\N	\N	\N
1353	Madeen Muhanad	Madeen	Muhanad	\N	26	MF	\N	\N	\N
1354	Albadri Faisal	Albadri	Faisal	\N	26	MF	\N	\N	\N
1355	Taktak Muftah	Taktak	Muftah	\N	26	MF	\N	\N	\N
1356	Mohamed Amer	Mohamed	Amer	\N	26	FW	\N	\N	\N
1357	Alharaish Zakaria	Alharaish	Zakaria	\N	26	FW	\N	\N	\N
1358	Saeid Saleh	Saeid	Saleh	\N	26	FW	\N	\N	\N
1359	Ibrahim Ahmada	Ibrahim	Ahmada	\N	56	MF	\N	\N	\N
1360	Milton Karisa	Milton	Karisa	\N	54	MF	\N	\N	\N
1361	Hood Kaweesa	Hood	Kaweesa	\N	54	FW	\N	\N	\N
1362	Derrick Nsibambi	Derrick	Nsibambi	\N	54	FW	\N	\N	\N
1363	Atak Laul	Atak	Laul	\N	48	FW	\N	\N	\N
1364	Nicholous Wadada	Nicholous	Wadada	\N	54	MF	\N	\N	\N
1365	Blais Babikakuhe Bigirimana	Blais	Bigirimana	\N	56	MF	\N	\N	\N
1366	Landry Ndikumana	Landry	Ndikumana	\N	56	MF	\N	\N	\N
1367	Tarick Seif	Tarick	Seif	\N	56	FW	\N	\N	\N
1368	Frank Zakaria	Frank	Zakaria	\N	56	FW	\N	\N	\N
1369	Salmin Hoza	Salmin	Hoza	\N	56	MF	\N	\N	\N
1370	Benard Arthur	Benard	Arthur	\N	56	MF	\N	\N	\N
1371	Yuan Kungumandiye	Yuan	Kungumandiye	\N	56	GK	\N	\N	\N
1372	Vicent Philipo	Vicent	Philipo	\N	56	DF	\N	\N	\N
1373	George Sangija	George	Sangija	\N	56	MF	\N	\N	\N
1374	Adam Ibrahim	Adam	Ibrahim	\N	56	MF	\N	\N	\N
1375	Six Mwasikaga	Six	Mwasikaga	\N	56	MF	\N	\N	\N
1376	Steven Mganga	Steven	Mganga	\N	56	DF	\N	\N	\N
1377	Ramadhani Adam Malima	Ramadhani	Malima	\N	56	MF	\N	\N	\N
1378	Makenzi Ramadhani	Makenzi	Ramadhani	\N	56	DF	\N	\N	\N
1379	Ismail Gambo	Ismail	Gambo	\N	56	MF	\N	\N	\N
1380	Abdul Kassim	Abdul	Kassim	\N	56	MF	\N	\N	\N
1381	Vitalis Mayanga	Vitalis	Mayanga	\N	56	MF	\N	\N	\N
1382	Damas Makwaya	Damas	Makwaya	\N	56	DF	\N	\N	\N
1383	Pappy Kambale	Pappy	Kambale	\N	56	MF	\N	\N	\N
1384	Joseph Kimwaga	Joseph	Kimwaga	\N	56	MF	\N	\N	\N
1385	Etienne Ngiladjoe	Etienne	Ngiladjoe	\N	56	FW	\N	\N	\N
1386	Awesu Awesu	Awesu	Awesu	\N	56	MF	\N	\N	\N
1387	Harerimana Lewis	Harerimana	Lewis	\N	56	DF	\N	\N	\N
1388	Willy Mgaya	Willy	Mgaya	\N	56	MF	\N	\N	\N
1389	Alinanuswe Martin	Alinanuswe	Martin	\N	56	MF	\N	\N	\N
1390	Joram Mugeveke	Joram	Mugeveke	\N	56	DF	\N	\N	\N
1391	Jean-Marie Girukwishaka	Jean-Marie	Girukwishaka	\N	4	DF	\N	\N	\N
1392	Iddy Mfaume	Iddy	Mfaume	\N	56	MF	\N	\N	\N
1393	Nickson Kababage	Nickson	Kababage	\N	56	DF	\N	\N	\N
1394	Motsholetsi Sikele	Motsholetsi	Sikele	\N	3	MF	\N	\N	\N
1395	Lemponye Tshireletso	Lemponye	Tshireletso	\N	3	FW	\N	\N	\N
1396	Ahmed Gomaa	Ahmed	Gomaa	\N	55	FW	\N	\N	\N
1397	Ahmed Abdalraof	Ahmed	Abdalraof	\N	55	FW	\N	\N	\N
1398	Baghdad Bounedjah	Baghdad	Bounedjah	\N	1	FW	\N	\N	\N
1399	Carl Medjani	Carl	Medjani	\N	1	MF	\N	\N	\N
1400	Simon Msuva	Simon	Msuva	\N	56	FW	\N	\N	\N
1401	Mbwana Samatta	Mbwana	Samatta	\N	56	FW	\N	\N	\N
1402	Steven Mwaijala	Steven	Mwaijala	\N	56	DF	\N	\N	\N
1403	Miraji Athumani	Miraji	Athumani	\N	56	FW	\N	\N	\N
1404	Zawadi Gift Mauya	Zawadi	Mauya	\N	56	MF	\N	\N	\N
1405	Rajesh Kotecha	Rajesh	Kotecha	\N	56	MF	\N	\N	\N
1406	Ushetu Mena	Ushetu	Mena	\N	15	FW	\N	\N	\N
1407	Maliki Antiri	Maliki	Antiri	\N	56	DF	\N	\N	\N
1408	Charles Ilanfya	Charles	Ilanfya	\N	56	MF	\N	\N	\N
1409	Lubinda Mundia	Lubinda	Mundia	\N	58	FW	\N	\N	\N
1410	Paul Godfrey	Paul	Godfrey	\N	56	FW	\N	\N	\N
1411	Yohana Mkomola	Yohana	Mkomola	\N	56	FW	\N	\N	\N
1412	Lucheke Gaga	Lucheke	Gaga	\N	56	GK	\N	\N	\N
1413	Meddie Kagere	Meddie	Kagere	\N	5	FW	\N	\N	\N
1414	Abdul Hood Mayanja	Abdul	Mayanja	\N	56	\N	\N	\N	\N
1415	Adam Omary Adam	Adam	Adam	\N	56	\N	\N	\N	\N
1416	Awadh Salum Mkana	Awadh	Mkana	\N	56	\N	\N	\N	\N
1417	Augustino Samson Nsata	Augustino	Nsata	\N	56	\N	\N	\N	\N
1418	Baraka Jaffari Nyakamande	Baraka	Nyakamande	\N	56	\N	\N	\N	\N
1419	Daudi Salim Mbweni	Daudi	Mbweni	\N	56	\N	\N	\N	\N
1420	Emmanuel Simwanza Namwando	Emmanuel	Namwando	\N	56	\N	\N	\N	\N
1421	Gervas Editha Benard	Gervas	Benard	\N	56	\N	\N	\N	\N
1422	Halfani Mbaruku Twenye	Halfani	Twenye	\N	56	\N	\N	\N	\N
1423	Hamis Jumanne Shengo	Hamis	Shengo	\N	56	\N	\N	\N	\N
1424	Hamisi Thabiti Nyige	Hamisi	Nyige	\N	56	\N	\N	\N	\N
1425	Haruna Moshi Shaaban	Haruna	Shaaban	\N	56	\N	\N	\N	\N
1426	Hashim Salum Mohamed	Hashim	Mohamed	\N	56	\N	\N	\N	\N
1427	Idris Kolawale	Idris	Kolawale	\N	56	\N	\N	\N	\N
1428	Kasembo Douglas	Kasembo	Douglas	\N	56	\N	\N	\N	\N
1429	Kassim Mohamed Simbaulanga	Kassim	Simbaulanga	\N	56	\N	\N	\N	\N
1430	Kasimu Salim Mdoe	Kasimu	Mdoe	\N	56	\N	\N	\N	\N
1431	Kayiwa Ibrahim	Kayiwa	Ibrahim	\N	56	\N	\N	\N	\N
1432	Kassim Ali Kiyungo	Kassim	Kiyungo	\N	56	\N	\N	\N	\N
1433	Liberatus Norbeth Humhiye	Liberatus	Humhiye	\N	56	\N	\N	\N	\N
1434	Mike Kashakala Ndera	Mike	Ndera	\N	56	\N	\N	\N	\N
1435	Mtikila Said Hussein Mwiga	Mtikila	Mwiga	\N	56	\N	\N	\N	\N
1436	Musta Hamis Batozi Mbaluku	Musta	Mbaluku	\N	56	\N	\N	\N	\N
1437	Omary Salum Kheri	Omary	Kheri	\N	56	\N	\N	\N	\N
1438	Said Ahmad Salum	Said	Salum	\N	56	\N	\N	\N	\N
1439	Tito Okelo	Tito	Okelo	\N	56	\N	\N	\N	\N
1440	Tony Charles Pakatika	Tony	Pakatika	\N	56	\N	\N	\N	\N
1441	Tonny John Kavishe	Tonny	Kavishe	\N	56	\N	\N	\N	\N
1442	Victor Da Costa	Victor	Da Costa	\N	56	\N	\N	\N	\N
1443	Salum Ijee	Salum	Ijee	\N	56	\N	\N	\N	\N
1444	Bakari Mwamnyeto	Bakari	Mwamnyeto	\N	56	\N	\N	\N	\N
1445	George William Makanga	George	Makanga	\N	56	\N	\N	\N	\N
1446	Paschal Wawa	Paschal	Wawa	\N	20	\N	\N	\N	\N
1447	Benjamin Asukile	Benjamin	Asukile	\N	56	\N	\N	\N	\N
1448	Clephace Mkandala	Clephace	Mkandala	\N	56	\N	\N	\N	\N
1449	Ismail Aziz Kada	Ismail	Kada	\N	56	\N	\N	\N	\N
1450	Feisal Salum Abdallah	Feisal	Abdallah	\N	56	\N	\N	\N	\N
1451	Heritier Ma Olongi Makambo	Heritier	Makambo	\N	56	\N	\N	\N	\N
1452	Mbirizi Eric	Mbirizi	Eric	\N	4	\N	\N	\N	\N
1453	Joseph Petro Mahundi	Joseph	Mahundi	\N	56	\N	\N	\N	\N
1454	Daniel Reuben Lyanga	Daniel	Lyanga	\N	56	\N	\N	\N	\N
1455	Haji Mohamed Ugando	Haji	Ugando	\N	56	\N	\N	\N	\N
1456	Abubakar Abbas Ibrahim	Abubakar	Ibrahim	\N	56	\N	\N	\N	\N
1457	Abubakar Nyakarungu Kinanda	Abubakar	Kinanda	\N	56	\N	\N	\N	\N
1458	Adan Mohamed Omar	Adan	Omar	\N	56	\N	\N	\N	\N
1459	Adil Nassor Sultan	Adil	Sultan	\N	56	\N	\N	\N	\N
1460	Ayub Reuben Lyanga	Ayub	Lyanga	\N	56	\N	\N	\N	\N
1461	Ramadhani Kipalamoto	Ramadhani	Kipalamoto	\N	56	\N	\N	\N	\N
1462	Said Saidi Mussa	Said	Mussa	\N	56	\N	\N	\N	\N
1463	Ally Bilal Mwale	Ally	Mwale	\N	56	\N	\N	\N	\N
1464	Michael Chinedu	Michael	Chinedu	\N	56	\N	\N	\N	\N
1465	Hassan Nassor Maulid	Hassan	Maulid	\N	56	\N	\N	\N	\N
1466	Abdu Haji Omary	Abdu	Omary	\N	56	\N	\N	\N	\N
1467	Mwadini Ali Mwadini	Mwadini	Mwadini	\N	56	\N	\N	\N	\N
1468	Ramadhani Yahaya Singano Singano	Ramadhani	Singano	\N	56	\N	\N	\N	\N
1469	Abdallah Salum Kheri	Abdallah	Kheri	\N	56	\N	\N	\N	\N
1470	David John Mwantika	David	Mwantika	\N	56	\N	\N	\N	\N
1471	Benedict Florence Haule	Benedict	Haule	\N	56	\N	\N	\N	\N
1472	Clatus Chama	Clatus	Chama	\N	58	\N	\N	\N	\N
1473	Mohamed Said Said	Mohamed	Said	\N	56	\N	\N	\N	\N
1474	Moses Peter	Moses	Peter	\N	56	\N	\N	\N	\N
1475	Serge Pascal Wawa	Serge	Wawa	\N	22	\N	\N	\N	\N
1476	Deogratias Bonaventur Munish	Deogratias	Munish	\N	56	\N	\N	\N	\N
1477	Marcel Bonaventure Kapama	Marcel	Kapama	\N	56	\N	\N	\N	\N
1478	Ally Salim Juma Khatoro	Ally	Juma	\N	56	\N	\N	\N	\N
1479	Rashid Juma Mtabwigwa	Rashid	Mtabwigwa	\N	56	\N	\N	\N	\N
1480	Abubakari Ally Mohamed Juma	Abubakari	Mohamed	\N	56	\N	\N	\N	\N
1481	Ally Ijumaa Kwalakwala	Ally	Kwalakwala	\N	56	\N	\N	\N	\N
1482	Ally Mohamed Ally Kibehele	Ally	Ally	\N	56	\N	\N	\N	\N
1483	Cleofas Sospeter Levo Gombanila	Cleofas	Levo	\N	56	\N	\N	\N	\N
1484	Klaus Nkizi Kindoki	Klaus	Kindoki	\N	11	\N	\N	\N	\N
1485	Kulina Mihambo Kajala	Kulina	Kajala	\N	56	\N	\N	\N	\N
1486	Mateo Anton Simon	Mateo	Simon	\N	56	\N	\N	\N	\N
1487	Sadi Kasimu Zabonye	Sadi	Zabonye	\N	56	\N	\N	\N	\N
1488	Salum Mkana Mwango	Salum	Mwango	\N	56	\N	\N	\N	\N
1489	Selemani Ahamad Hassani	Selemani	Hassani	\N	56	\N	\N	\N	\N
1490	Yassin Saleh Kirangi	Yassin	Kirangi	\N	56	\N	\N	\N	\N
1491	Mohammed Issa Juma	Mohammed	Juma	\N	56	\N	\N	\N	\N
1492	Jafari Mohamed Jafari	Jafari	Jafari	\N	56	\N	\N	\N	\N
1493	Yohana Oscar Mkomola	Yohana	Mkomola	\N	56	\N	\N	\N	\N
1494	Ally Shomari Sharifu	Ally	Sharifu	\N	56	\N	\N	\N	\N
1495	Hussein Idd Abdalah	Hussein	Abdalah	\N	56	\N	\N	\N	\N
1496	Juma Ally Liuzio	Juma	Liuzio	\N	56	\N	\N	\N	\N
1497	Abuutwalib Hamidu Mshery	Abuutwalib	Mshery	\N	56	\N	\N	\N	\N
1498	Aboubakary Shabani Pangalugombe	Aboubakary	Pangalugombe	\N	56	\N	\N	\N	\N
1499	Chunga Said Zito	Chunga	Zito	\N	56	\N	\N	\N	\N
1500	Godfrey Milla Milla	Godfrey	Milla	\N	56	\N	\N	\N	\N
1501	Keneth Godfrey Kunambi	Keneth	Kunambi	\N	56	\N	\N	\N	\N
1502	Mohamed Francis Kapeta	Mohamed	Kapeta	\N	56	\N	\N	\N	\N
1503	Seleman Ibrahimu Omary	Seleman	Omary	\N	56	\N	\N	\N	\N
1504	Ibrahimu Isihaka Ndunguri	Ibrahimu	Ndunguri	\N	56	\N	\N	\N	\N
1505	Abdul Azizi Seleman	Abdul	Seleman	\N	56	\N	\N	\N	\N
1506	Afidhu Rashid Rukindo	Afidhu	Rukindo	\N	56	\N	\N	\N	\N
1507	Avinus Kahatano Ezron	Avinus	Ezron	\N	56	\N	\N	\N	\N
1508	Derick Paulo Wilson	Derick	Wilson	\N	56	\N	\N	\N	\N
1509	Dickson Charles Mwizarubi	Dickson	Mwizarubi	\N	56	\N	\N	\N	\N
1510	Edsoni Egid Mugisha	Edsoni	Mugisha	\N	56	\N	\N	\N	\N
1511	Jonathan Charles Mulashani	Jonathan	Mulashani	\N	56	\N	\N	\N	\N
1512	Joram Kamazima Gerald	Joram	Gerald	\N	56	\N	\N	\N	\N
1513	Kelvin Mwemezi Salvatory	Kelvin	Salvatory	\N	56	\N	\N	\N	\N
1514	Kitoi Bosco Mgina	Kitoi	Mgina	\N	56	\N	\N	\N	\N
1515	Mickdad Juma Omary	Mickdad	Omary	\N	56	\N	\N	\N	\N
1516	Nelson Jackson Buberwa	Nelson	Buberwa	\N	56	\N	\N	\N	\N
1517	Pius Kibisa Jephu	Pius	Jephu	\N	56	\N	\N	\N	\N
1518	Sadru Sudi Abdalah	Sadru	Abdalah	\N	56	\N	\N	\N	\N
1519	Zuberi Juma Kakamega	Zuberi	Kakamega	\N	56	\N	\N	\N	\N
1520	Hemed Mohamed Koja	Hemed	Koja	\N	56	\N	\N	\N	\N
1521	Behewa Sembwana Behewa	Behewa	Behewa	\N	56	\N	\N	\N	\N
1522	Ramadhani Rashid Kapera	Ramadhani	Kapera	\N	56	\N	\N	\N	\N
1523	Kashiru Salum Said	Kashiru	Said	\N	56	\N	\N	\N	\N
1524	David Vedastus Mayungu	David	Mayungu	\N	56	\N	\N	\N	\N
1525	Omary Abdalah Nassoro	Omary	Nassoro	\N	56	\N	\N	\N	\N
1526	Emanuel Godfrey Joel	Emanuel	Joel	\N	56	\N	\N	\N	\N
1527	Kilasa Ruguge Nzutu	Kilasa	Nzutu	\N	56	\N	\N	\N	\N
1528	Kelvin Ladislaus Muyebe	Kelvin	Muyebe	\N	56	\N	\N	\N	\N
1529	Jordan Mutatina Gerald	Jordan	Gerald	\N	56	\N	\N	\N	\N
1530	Eriki Thomas John	Eriki	John	\N	56	\N	\N	\N	\N
1531	Abdulrahman Mohamed Mohamed	Abdulrahman	Mohamed	\N	56	\N	\N	\N	\N
1532	Naftali Nashon Matali	Naftali	Matali	\N	56	\N	\N	\N	\N
1533	Said Suleiman Luyaya	Said	Luyaya	\N	56	\N	\N	\N	\N
1534	Patrick Evance Munthali	Patrick	Munthali	\N	56	\N	\N	\N	\N
1535	Michael Aidan Pius	Michael	Pius	\N	56	\N	\N	\N	\N
1536	Idd Ally Mbaga	Idd	Mbaga	\N	56	\N	\N	\N	\N
1537	Nurdin Mohamed Seleman	Nurdin	Seleman	\N	56	\N	\N	\N	\N
1538	Anuar Selemani Kilemile	Anuar	Kilemile	\N	56	\N	\N	\N	\N
1539	Kelvin Nashon Naftal	Kelvin	Naftal	\N	56	\N	\N	\N	\N
1540	Abdereheman Musa Abdereheman	Abdereheman	Abdereheman	\N	56	\N	\N	\N	\N
1541	Frank Kwiniberth Nchimbi	Frank	Nchimbi	\N	56	\N	\N	\N	\N
1542	Salim Azizi Gila	Salim	Gila	\N	56	\N	\N	\N	\N
1543	Joseph Michael Ilunda	Joseph	Ilunda	\N	56	\N	\N	\N	\N
1544	Hassan Omary Mwaterema	Hassan	Mwaterema	\N	56	\N	\N	\N	\N
1545	Madenge Ramadhan Madenge	Madenge	Madenge	\N	56	\N	\N	\N	\N
1546	Mohamed Simba Magomba	Mohamed	Magomba	\N	56	\N	\N	\N	\N
1547	Daniel Charles Mecha	Daniel	Mecha	\N	56	\N	\N	\N	\N
1548	Rahimu Juma Abdalah	Rahimu	Abdalah	\N	56	\N	\N	\N	\N
1549	Najim Benjamin Najim	Najim	Najim	\N	56	\N	\N	\N	\N
1550	Pera Ramadhani Mavuo	Pera	Mavuo	\N	56	\N	\N	\N	\N
1551	Richard Daniel Maranya	Richard	Maranya	\N	56	\N	\N	\N	\N
1552	Ally Ally Ahmed	Ally	Ahmed	\N	56	\N	\N	\N	\N
1553	Edward Joseph Songo	Edward	Songo	\N	56	\N	\N	\N	\N
1554	Abdul Seif Seif	Abdul	Seif	\N	56	\N	\N	\N	\N
1555	Abdulhalim Hamoud Mohamed	Abdulhalim	Mohamed	\N	56	\N	\N	\N	\N
1556	Ally Hussein Msengi	Ally	Msengi	\N	56	\N	\N	\N	\N
1557	Cliff Antony Buyoya	Cliff	Buyoya	\N	56	\N	\N	\N	\N
1558	Jonathan Nahimana	Jonathan	Nahimana	\N	4	\N	\N	\N	\N
1559	Kelvin Sospeter Kijili	Kelvin	Kijili	\N	56	\N	\N	\N	\N
1560	Rehani Kibingu	Rehani	Kibingu	\N	56	\N	\N	\N	\N
1561	Samiru Mohamed Hassani	Samiru	Hassani	\N	56	\N	\N	\N	\N
1562	Yusuph Abdul Yusuph	Yusuph	Yusuph	\N	56	\N	\N	\N	\N
1563	Abdalah Mosoud Ahmad	Abdalah	Ahmad	\N	56	\N	\N	\N	\N
1564	Ali Hamadi Ali	Ali	Ali	\N	56	\N	\N	\N	\N
1565	Rayman Mngungila Elminus	Rayman	Elminus	\N	56	\N	\N	\N	\N
1566	Abdul Hillary Salum	Abdul	Salum	\N	56	\N	\N	\N	\N
1567	Abdul Bakari Msantu	Abdul	Msantu	\N	56	\N	\N	\N	\N
1568	Ally Musa Musa	Ally	Musa	\N	56	\N	\N	\N	\N
1569	Andrew Raymond Chamangu	Andrew	Chamangu	\N	56	\N	\N	\N	\N
1570	Hassan Said Komba	Hassan	Komba	\N	56	\N	\N	\N	\N
1571	Jesse Junior Zala	Jesse	Zala	\N	56	\N	\N	\N	\N
1572	Juma Miraji Zuberi	Juma	Zuberi	\N	56	\N	\N	\N	\N
1573	Kassim Omar Rajab Swaleh	Kassim	Rajab	\N	56	\N	\N	\N	\N
1574	Maalick Mursal Hussein	Maalick	Hussein	\N	56	\N	\N	\N	\N
1575	Mohamed Rajab Abdalah Kadidi	Mohamed	Abdalah	\N	56	\N	\N	\N	\N
1576	Mohamed Maulid Mohamed Ngalita	Mohamed	Mohamed	\N	56	\N	\N	\N	\N
1577	Mohamed Awadhi Abdual Mnali	Mohamed	Abdual Mnali	\N	56	\N	\N	\N	\N
1578	Musa Mohamed Abdalah Said	Musa	Abdalah	\N	56	\N	\N	\N	\N
1579	Mustapha Shaban Hussein Mwinchumu	Mustapha	Hussein	\N	56	\N	\N	\N	\N
1580	Nasser Mubaraka Nasser	Nasser	Nasser	\N	56	\N	\N	\N	\N
1581	Oscar Evaristo Daniel	Oscar	Daniel	\N	56	\N	\N	\N	\N
1582	Ramadhani Rashid Kaswale	Ramadhani	Kaswale	\N	56	\N	\N	\N	\N
1583	Salim Isihaka Abdalah Msambwa	Salim	Abdalah	\N	56	\N	\N	\N	\N
1584	Seif Hassan Ng'ingo	Seif	Ng'ingo	\N	56	\N	\N	\N	\N
1585	Elias William LUcian	Elias	LUcian	\N	56	\N	\N	\N	\N
1586	Issah Ally Rashidy Ngoah	Issah	Rashidy	\N	56	\N	\N	\N	\N
1587	Keneth Abeidy Masumbuko	Keneth	Masumbuko	\N	56	\N	\N	\N	\N
1588	Rajab Ally Daud Mbululo	Rajab	Daud	\N	56	\N	\N	\N	\N
1589	Hamis Haji Ibrahim	Hamis	Ibrahim	\N	56	\N	\N	\N	\N
1590	Andrew Michael Mhando	Andrew	Mhando	\N	56	\N	\N	\N	\N
1591	Richard Christian Wazir Chae	Richard	Wazir	\N	56	\N	\N	\N	\N
1592	Abdual Waheed Yusuph Adesola	Abdual	Yusuph	\N	56	\N	\N	\N	\N
1593	Abdalah Said Abdalah Makangana	Abdalah	Abdalah	\N	56	\N	\N	\N	\N
1594	Advent Pius Joseph Chonya	Advent	Joseph	\N	56	\N	\N	\N	\N
1595	Barnaba Kalo Mlomo	Barnaba	Mlomo	\N	56	\N	\N	\N	\N
1596	Andrew Peter Munisi	Andrew	Munisi	\N	56	\N	\N	\N	\N
1597	James Peter Munisi	James	Munisi	\N	56	\N	\N	\N	\N
1598	Musa Mohamed Wabilo	Musa	Wabilo	\N	56	\N	\N	\N	\N
1599	Rayson Joel Okkelo	Rayson	Okkelo	\N	56	\N	\N	\N	\N
1600	Sylivester Babilas Chitebe	Sylivester	Chitebe	\N	56	\N	\N	\N	\N
1601	Hassan Hamis Kapona	Hassan	Kapona	\N	56	\N	\N	\N	\N
1602	Emmanuel Maulucy Mtumbuka	Emmanuel	Mtumbuka	\N	56	\N	\N	\N	\N
1603	Hassan Jafari Kibailo	Hassan	Kibailo	\N	56	\N	\N	\N	\N
1604	Zam Elias Zamkufo	Zam	Zamkufo	\N	56	\N	\N	\N	\N
1605	Hashimu Yahaya Mussa	Hashimu	Mussa	\N	56	\N	\N	\N	\N
1606	Alawi Omary Janja	Alawi	Janja	\N	56	\N	\N	\N	\N
1607	Bruno Thomas Mrema	Bruno	Mrema	\N	56	\N	\N	\N	\N
1608	Abdulkarim Francis Segeja	Abdulkarim	Segeja	\N	56	\N	\N	\N	\N
1609	Ismail Ally Ally	Ismail	Ally	\N	56	\N	\N	\N	\N
1610	Arishy Suleiman Kombo	Arishy	Kombo	\N	56	\N	\N	\N	\N
1611	Charles Stephano Daud	Charles	Daud	\N	56	\N	\N	\N	\N
1612	Emmanuel George Lugisa	Emmanuel	Lugisa	\N	56	\N	\N	\N	\N
1613	Emmanuel Raphael Chabuluma	Emmanuel	Chabuluma	\N	56	\N	\N	\N	\N
1614	Frank Mushi Mbeshe	Frank	Mbeshe	\N	56	\N	\N	\N	\N
1615	Frank Magingi John	Frank	John	\N	56	\N	\N	\N	\N
1616	George Mbisa	George	Mbisa	\N	56	\N	\N	\N	\N
1617	Ibrahim Elisha Willson	Ibrahim	Willson	\N	56	\N	\N	\N	\N
1618	Ibrahim Irakoze Nasser	Ibrahim	Nasser	\N	56	\N	\N	\N	\N
1619	Innocent Edwin Edwin	Innocent	Edwin	\N	56	\N	\N	\N	\N
1620	Jackson Salvatory Shiga	Jackson	Shiga	\N	56	\N	\N	\N	\N
1621	John Elias Kasunzu	John	Kasunzu	\N	56	\N	\N	\N	\N
1622	Joseph Shila Mahona	Joseph	Mahona	\N	56	\N	\N	\N	\N
1623	Kombo Juma Athuman	Kombo	Athuman	\N	56	\N	\N	\N	\N
1624	Leonard Bhoke Bhoke	Leonard	Bhoke	\N	56	\N	\N	\N	\N
1625	Mohamed Abdul Mselem	Mohamed	Mselem	\N	56	\N	\N	\N	\N
1626	Nasir Salum Salum	Nasir	Salum	\N	56	\N	\N	\N	\N
1627	Otu Joseph Samuel	Otu	Samuel	\N	20	\N	\N	\N	\N
1628	Rajanu Magambo	Rajanu	Magambo	\N	56	\N	\N	\N	\N
1629	Rashid Said Risasi	Rashid	Risasi	\N	56	\N	\N	\N	\N
1630	Rodrigo Emmanuel Bulas	Rodrigo	Bulas	\N	56	\N	\N	\N	\N
1631	Shaban Abdul Hamza	Shaban	Hamza	\N	56	\N	\N	\N	\N
1632	Sylivester Ndikumana Chubwa	Sylivester	Chubwa	\N	56	\N	\N	\N	\N
1633	Walece Kiango	Walece	Kiango	\N	56	\N	\N	\N	\N
1634	Yombo Mkuli Mkenyenge	Yombo	Mkenyenge	\N	56	\N	\N	\N	\N
1635	Wandwi Jackson William	Wandwi	William	\N	56	\N	\N	\N	\N
1636	Issa Lawrence Mwakalebela	Issa	Mwakalebela	\N	56	\N	\N	\N	\N
1637	Salimu Salimu Aiyee	Salimu	Aiyee	\N	56	\N	\N	\N	\N
1638	Ally Khamis Ng'azi	Ally	Ng'azi	\N	56	\N	\N	\N	\N
1639	Dickson Revocatus Mnyasa	Dickson	Mnyasa	\N	56	\N	\N	\N	\N
1640	Emmanuel Saimon Kitundu	Emmanuel	Kitundu	\N	56	\N	\N	\N	\N
1641	Haji Salum Mkunda	Haji	Mkunda	\N	56	\N	\N	\N	\N
1642	Hans Kwofie	Hans	Kwofie	\N	20	\N	\N	\N	\N
1643	Jandashah Siraj Hussein	Jandashah	Hussein	\N	56	\N	\N	\N	\N
1644	Jonathan Henry Gesege	Jonathan	Gesege	\N	56	\N	\N	\N	\N
1645	Mohamed Abdalah Rashid	Mohamed	Rashid	\N	56	\N	\N	\N	\N
1646	Rashid Ismail Mkoko	Rashid	Mkoko	\N	56	\N	\N	\N	\N
1647	Robert David Vedastus	Robert	Vedastus	\N	56	\N	\N	\N	\N
1648	Said Mjie Said	Said	Said	\N	56	\N	\N	\N	\N
1649	Saleh Masoud Abdalah	Saleh	Abdalah	\N	56	\N	\N	\N	\N
1650	Yahya Haji Salmin	Yahya	Salmin	\N	56	\N	\N	\N	\N
1651	Juma Abdalah Mangua	Juma	Mangua	\N	56	\N	\N	\N	\N
1652	Mohamed Hamis Titi	Mohamed	Titi	\N	56	\N	\N	\N	\N
1653	Frank Zacharia Mkumbo	Frank	Mkumbo	\N	56	\N	\N	\N	\N
1654	Asad Ali Juma	Asad	Juma	\N	56	\N	\N	\N	\N
1655	Benedict Junior Beda	Benedict	Beda	\N	56	\N	\N	\N	\N
1656	Athanas Enimias Mdam	Athanas	Mdam	\N	56	\N	\N	\N	\N
1657	Diaby Amara	Diaby	Amara	\N	56	\N	\N	\N	\N
1658	Erick Tumua Agostino	Erick	Agostino	\N	56	\N	\N	\N	\N
1659	Ally Yusuph Sonda	Ally	Sonda	\N	56	\N	\N	\N	\N
1660	Aarony Francis Mdonko	Aarony	Mdonko	\N	56	\N	\N	\N	\N
1661	Datius Peter Felix	Datius	Felix	\N	56	\N	\N	\N	\N
1662	Philemon Ramadhani Mwezi	Philemon	Mwezi	\N	56	\N	\N	\N	\N
1663	Yusuph Jamal Khamis	Yusuph	Khamis	\N	56	\N	\N	\N	\N
1664	Alfred Juma Masumbakenda	Alfred	Masumbakenda	\N	56	\N	\N	\N	\N
1665	Hakizimana Kitenge Alexis	Hakizimana	Alexis	\N	56	\N	\N	\N	\N
1666	Bigirimana Ramadhan	Bigirimana	Ramadhan	\N	56	\N	\N	\N	\N
1667	Niyonkuru Nassor	Niyonkuru	Nassor	\N	56	\N	\N	\N	\N
1668	Castory Masanja Langula	Castory	Langula	\N	56	\N	\N	\N	\N
1669	Hafidhi Mussa Mtambo	Hafidhi	Mtambo	\N	56	\N	\N	\N	\N
1670	Saleh Lubili Masunga	Saleh	Masunga	\N	56	\N	\N	\N	\N
1671	Mussa Saul John	Mussa	John	\N	56	\N	\N	\N	\N
1672	Paul Materazi Luyungu	Paul	Luyungu	\N	56	\N	\N	\N	\N
1673	Nassor Suleiman Nassor	Nassor	Nassor	\N	56	\N	\N	\N	\N
1674	Chinonso Charles Abah	Chinonso	Abah	\N	36	\N	\N	\N	\N
1675	Nobert Juma Aidan	Nobert	Aidan	\N	56	\N	\N	\N	\N
1676	Mussa Mohamed Kirungi	Mussa	Kirungi	\N	56	\N	\N	\N	\N
1677	Elius Emmanuel Sospeter	Elius	Sospeter	\N	56	\N	\N	\N	\N
1678	Ndoriyobija Eric	Ndoriyobija	Eric	\N	56	\N	\N	\N	\N
1679	Mnubi Hassani Shaban	Mnubi	Shaban	\N	56	\N	\N	\N	\N
1680	Mwinyi Elias Amamed	Mwinyi	Amamed	\N	56	\N	\N	\N	\N
1681	Boniphance Alphonce Hau	Boniphance	Hau	\N	56	\N	\N	\N	\N
1682	Frank William Linus	Frank	Linus	\N	56	\N	\N	\N	\N
1683	Hassan Iddy Kapalata	Hassan	Kapalata	\N	56	\N	\N	\N	\N
1684	John Sungura Timas	John	Timas	\N	56	\N	\N	\N	\N
1685	Julius Kwanga Zowange	Julius	Zowange	\N	56	\N	\N	\N	\N
1686	ramadhan Abdalah Ibata	ramadhan	Ibata	\N	56	\N	\N	\N	\N
1687	Prosper Kaini Mwangupili	Prosper	Mwangupili	\N	56	\N	\N	\N	\N
1688	Jermiah Juma Ally	Jermiah	Ally	\N	56	\N	\N	\N	\N
1689	Metacha Boniphance Mnata	Metacha	Mnata	\N	56	\N	\N	\N	\N
1690	Sharifu Shabani Mkangara	Sharifu	Mkangara	\N	56	\N	\N	\N	\N
1691	Innocent Mwandelile Simon	Innocent	Simon	\N	56	\N	\N	\N	\N
1692	Edson Deus Magoma	Edson	Magoma	\N	56	\N	\N	\N	\N
1693	Hussein Almas Manyange	Hussein	Manyange	\N	56	\N	\N	\N	\N
1694	Joseph Mapembe Simbaulanga	Joseph	Simbaulanga	\N	56	\N	\N	\N	\N
1695	Sospeter Kasoli	Sospeter	Kasoli	\N	56	\N	\N	\N	\N
1696	Uhuru Seleman Mwambungu	Uhuru	Mwambungu	\N	56	\N	\N	\N	\N
1697	Wilfred Kouruma	Wilfred	Kouruma	\N	21	\N	\N	\N	\N
1698	Godfrey Joachim Malibiche	Godfrey	Malibiche	\N	56	\N	\N	\N	\N
1699	Angelo George Malima	Angelo	Malima	\N	56	\N	\N	\N	\N
1700	Derick Derick Musa	Derick	Musa	\N	56	\N	\N	\N	\N
1701	Derick Derick Musa	Derick	Musa	\N	56	\N	\N	\N	\N
1702	Edgar Phinias Bwire	Edgar	Bwire	\N	56	\N	\N	\N	\N
1703	Abualmajid Yahaya Mangalo	Abualmajid	Mangalo	\N	56	\N	\N	\N	\N
1704	Kazee Makuka Melkiad	Kazee	Melkiad	\N	56	\N	\N	\N	\N
1705	Boniphance Selestin Medard	Boniphance	Medard	\N	56	\N	\N	\N	\N
1706	Lenny Vedastus Kissu	Lenny	Kissu	\N	56	\N	\N	\N	\N
1707	Edson Alubinus Mturi	Edson	Mturi	\N	56	\N	\N	\N	\N
1708	Stanley Deodatus Nyakujerwa	Stanley	Nyakujerwa	\N	56	\N	\N	\N	\N
1709	Lameck Daniel Chamkaga	Lameck	Chamkaga	\N	56	\N	\N	\N	\N
1710	Meshack Abel Mwankina	Meshack	Mwankina	\N	56	\N	\N	\N	\N
1711	Patrick Petro Kate	Patrick	Kate	\N	56	\N	\N	\N	\N
1712	Hassan Abdalah Robert	Hassan	Robert	\N	56	\N	\N	\N	\N
1713	Mohamed Athuman Soud	Mohamed	Soud	\N	56	\N	\N	\N	\N
1714	Godfrey Marcus Mapunda	Godfrey	Mapunda	\N	56	\N	\N	\N	\N
1715	Taro Donald Joseph	Taro	Joseph	\N	56	\N	\N	\N	\N
1716	Daniel Johanes Mgore	Daniel	Mgore	\N	56	\N	\N	\N	\N
1717	Kalos Protus Kirenge	Kalos	Kirenge	\N	56	\N	\N	\N	\N
1718	Gipron Marco Macha	Gipron	Macha	\N	56	\N	\N	\N	\N
1719	Elia Haruna Chibule	Elia	Chibule	\N	56	\N	\N	\N	\N
1720	Nassor Iddy Kanyagu	Nassor	Kanyagu	\N	56	\N	\N	\N	\N
1721	Olumide Francis Alex	Olumide	Alex	\N	36	\N	\N	\N	\N
1722	Songa Bethel Jared	Songa	Jared	\N	56	\N	\N	\N	\N
1723	Astin Yapo Amos Achito	Astin	Amos	\N	22	\N	\N	\N	\N
1724	Adjiguesena Nouridine Balora	Adjiguesena	Balora	\N	57	\N	\N	\N	\N
1725	Wanjara Alex Kalebu	Wanjara	Kalebu	\N	56	\N	\N	\N	\N
1726	Kauswa Benard Manumbu	Kauswa	Manumbu	\N	56	\N	\N	\N	\N
1727	Godfrey Ndaro Masatu	Godfrey	Masatu	\N	56	\N	\N	\N	\N
1728	Hussein Almas Mamnyange	Hussein	Mamnyange	\N	56	\N	\N	\N	\N
1729	Metusela Nyaida Bia	Metusela	Bia	\N	56	\N	\N	\N	\N
1730	Mpapi Nassibu Salum	Mpapi	Salum	\N	56	\N	\N	\N	\N
1731	Juma Mohamed Mpakala	Juma	Mpakala	\N	56	\N	\N	\N	\N
1732	Edson Nyakwesi Magoma	Edson	Magoma	\N	56	\N	\N	\N	\N
1733	Daniel Boniphace Manyenye	Daniel	Manyenye	\N	56	\N	\N	\N	\N
1734	Yohana Moris Ng'onye	Yohana	Ng'onye	\N	56	\N	\N	\N	\N
1735	Frank James Sekule	Frank	Sekule	\N	56	\N	\N	\N	\N
1736	Fredrick Joseph Elias	Fredrick	Elias	\N	56	\N	\N	\N	\N
1737	Noel Christopher Makunja	Noel	Makunja	\N	56	\N	\N	\N	\N
1738	David Richard Uromi	David	Uromi	\N	56	\N	\N	\N	\N
1739	Godlove Aidan Mdumule	Godlove	Mdumule	\N	56	\N	\N	\N	\N
1740	Ibrahim Isihaka Ibrahim	Ibrahim	Ibrahim	\N	56	\N	\N	\N	\N
1741	Ismail Makorosa Ismail	Ismail	Ismail	\N	56	\N	\N	\N	\N
1742	Juhud Philemon Balayazi	Juhud	Balayazi	\N	56	\N	\N	\N	\N
1743	Kassembe Hassan	Kassembe	Hassan	\N	56	\N	\N	\N	\N
1744	Kelvin Longnus Faru	Kelvin	Faru	\N	56	\N	\N	\N	\N
1745	Kelvin Richard Kamalamo	Kelvin	Kamalamo	\N	56	\N	\N	\N	\N
1746	Mchembe Majaliwa Maganda	Mchembe	Maganda	\N	56	\N	\N	\N	\N
1747	Richard John Mkuyu	Richard	Mkuyu	\N	56	\N	\N	\N	\N
1748	Way Yeka Tatuwe	Way	Tatuwe	\N	56	\N	\N	\N	\N
1749	Nteze John Chileshi	Nteze	Chileshi	\N	56	\N	\N	\N	\N
1750	Geofrey Luseke Kigi	Geofrey	Kigi	\N	56	\N	\N	\N	\N
1751	Siraj Ramadhani Juma	Siraj	Juma	\N	56	\N	\N	\N	\N
1752	Israel Patrick Mwenda	Israel	Mwenda	\N	56	\N	\N	\N	\N
1753	Wema Sadoki Ibrahim	Wema	Ibrahim	\N	56	\N	\N	\N	\N
1754	Juma Nyangi Ganambali	Juma	Ganambali	\N	56	\N	\N	\N	\N
1755	Martin Kigi Luseke	Martin	Luseke	\N	56	\N	\N	\N	\N
1756	Hance Masoud Msonga	Hance	Msonga	\N	56	\N	\N	\N	\N
1757	Zabona Hamis Mayombya	Zabona	Mayombya	\N	56	\N	\N	\N	\N
1758	Shaban William Mkangara	Shaban	Mkangara	\N	56	\N	\N	\N	\N
1759	Dickson Isaack Ambundo	Dickson	Ambundo	\N	56	\N	\N	\N	\N
1760	Rajab Ramadhan Kibera	Rajab	Kibera	\N	56	\N	\N	\N	\N
1761	Rashid Ruhava Hussein	Rashid	Hussein	\N	56	\N	\N	\N	\N
1762	Juhudi Philemon Balayazi	Juhudi	Balayazi	\N	56	\N	\N	\N	\N
1763	Mapinduzi Elia Balama	Mapinduzi	Balama	\N	56	\N	\N	\N	\N
1764	Sameer Vicent Mwinyishehe	Sameer	Mwinyishehe	\N	56	\N	\N	\N	\N
1765	Joseph James Majagi	Joseph	Majagi	\N	56	\N	\N	\N	\N
1766	Hamis Mustafa Kanduru	Hamis	Kanduru	\N	56	\N	\N	\N	\N
1767	Ibrahim Ame Mohamed	Ibrahim	Mohamed	\N	56	\N	\N	\N	\N
1768	Iddy Athuman Athuman	Iddy	Athuman	\N	56	\N	\N	\N	\N
1769	Maulid Rajab Amri	Maulid	Amri	\N	56	\N	\N	\N	\N
1770	Maulid Abas Mdoe	Maulid	Mdoe	\N	56	\N	\N	\N	\N
1771	Mohamed Musa Abdalah	Mohamed	Abdalah	\N	56	\N	\N	\N	\N
1772	Muhsin Malima Makame	Muhsin	Makame	\N	56	\N	\N	\N	\N
1773	Said Seleman Mkwazu	Said	Mkwazu	\N	56	\N	\N	\N	\N
1774	Soud Abdallah Dondola	Soud	Dondola	\N	56	\N	\N	\N	\N
1775	Issa Abushehe Said	Issa	Said	\N	56	\N	\N	\N	\N
1776	Mtenje Albano Juma	Mtenje	Juma	\N	56	\N	\N	\N	\N
1777	Arqam Munir Abdalah	Arqam	Abdalah	\N	56	\N	\N	\N	\N
1778	Abdalah Wazir Nassor	Abdalah	Nassor	\N	56	\N	\N	\N	\N
1779	Prosper Aloyce Mushi	Prosper	Mushi	\N	56	\N	\N	\N	\N
1780	Deogratias Antony Kulwa	Deogratias	Kulwa	\N	56	\N	\N	\N	\N
1781	Hassan Ally Hamis	Hassan	Hamis	\N	56	\N	\N	\N	\N
1782	Ally Salehe Kiba	Ally	Kiba	\N	56	\N	\N	\N	\N
1783	Mohamed Twaha Shekue	Mohamed	Shekue	\N	56	\N	\N	\N	\N
1784	Raizin Hafidh Haji	Raizin	Haji	\N	56	\N	\N	\N	\N
1785	Hussein Mohamed Sharif	Hussein	Sharif	\N	56	\N	\N	\N	\N
1786	Mbwana Bakari Hamisi	Mbwana	Hamisi	\N	56	\N	\N	\N	\N
1787	Said Jellain Mkangu	Said	Mkangu	\N	56	\N	\N	\N	\N
1788	Bakari Ally Mtwiku	Bakari	Mtwiku	\N	56	\N	\N	\N	\N
1789	Abdalah Hussein Kilala	Abdalah	Kilala	\N	56	\N	\N	\N	\N
1790	Abdul Ally Mpambika	Abdul	Mpambika	\N	56	\N	\N	\N	\N
1791	Ali Mohamed Seleman	Ali	Seleman	\N	56	\N	\N	\N	\N
1792	Hamis Seleman Kasanga	Hamis	Kasanga	\N	56	\N	\N	\N	\N
1793	Hassan Ali Haji	Hassan	Haji	\N	56	\N	\N	\N	\N
1794	Mohamed Mdoe Mohamed	Mohamed	Mohamed	\N	56	\N	\N	\N	\N
1795	Moses Shaban Said	Moses	Said	\N	56	\N	\N	\N	\N
1796	Renatus Morris Ambross Cosmas	Renatus	Ambross	\N	56	\N	\N	\N	\N
1797	Shaban Sultan Mtambo	Shaban	Mtambo	\N	56	\N	\N	\N	\N
1798	Abeid Ally Kaisi	Abeid	Kaisi	\N	56	\N	\N	\N	\N
1799	Ali Humoud Badru	Ali	Badru	\N	56	\N	\N	\N	\N
1800	Asili Elias Mkondya	Asili	Mkondya	\N	56	\N	\N	\N	\N
1801	Atupele Jackson	Atupele	Jackson	\N	56	\N	\N	\N	\N
1802	Ayoub Masoud Abdalah	Ayoub	Abdalah	\N	56	\N	\N	\N	\N
1803	Cosmas Mchopa	Cosmas	Mchopa	\N	56	\N	\N	\N	\N
1804	Daud Rashid Milandu	Daud	Milandu	\N	56	\N	\N	\N	\N
1805	David Stephano Siminda	David	Siminda	\N	56	\N	\N	\N	\N
1806	Godlizen Paul Tumbo	Godlizen	Tumbo	\N	56	\N	\N	\N	\N
1807	Hamis John	Hamis	John	\N	56	\N	\N	\N	\N
1808	Iddy Ally	Iddy	Ally	\N	56	\N	\N	\N	\N
1809	Juma Daudi	Juma	Daudi	\N	56	\N	\N	\N	\N
1810	Lusius Lusius	Lusius	Lusius	\N	56	\N	\N	\N	\N
1811	Makame Ally	Makame	Ally	\N	56	\N	\N	\N	\N
1812	Mohamed Bakari Mohamed	Mohamed	Mohamed	\N	56	\N	\N	\N	\N
1813	Moshi Salum Nassor	Moshi	Nassor	\N	56	\N	\N	\N	\N
1814	Muhsin Mohamed Manzi	Muhsin	Manzi	\N	56	\N	\N	\N	\N
1815	Mussa Issa	Mussa	Issa	\N	56	\N	\N	\N	\N
1816	Nassoro Salehe Hashim	Nassoro	Hashim	\N	56	\N	\N	\N	\N
1817	Rajab Mohamed	Rajab	Mohamed	\N	56	\N	\N	\N	\N
1818	Rakibu Abdalah	Rakibu	Abdalah	\N	56	\N	\N	\N	\N
1819	Ramadhani Mwahali	Ramadhani	Mwahali	\N	56	\N	\N	\N	\N
1820	Shabani Said	Shabani	Said	\N	56	\N	\N	\N	\N
1821	Vitalisy Fraghton Marco	Vitalisy	Marco	\N	56	\N	\N	\N	\N
1822	Yassin Mustapha Salum	Yassin	Salum	\N	56	\N	\N	\N	\N
1823	Enrick Vitars Nkosi	Enrick	Nkosi	\N	56	\N	\N	\N	\N
1824	Omary Natalis Wyne	Omary	Wyne	\N	56	\N	\N	\N	\N
1825	Ismail Mussa Abdalah	Ismail	Abdalah	\N	56	\N	\N	\N	\N
1826	Abdalah Rajab Mfuko	Abdalah	Mfuko	\N	56	\N	\N	\N	\N
1827	Lebo Mothiba	Lebo	Mothiba	\N	46	\N	\N	\N	\N
1828	Andrew Sinchimba	Andrew	Sinchimba	\N	56	\N	\N	\N	\N
1829	Mathias Martins	Mathias	Martins	\N	20	\N	\N	\N	\N
1830	Kone Yaya Soumalia	Kone	Soumalia	\N	20	\N	\N	\N	\N
1831	Anthony Laffor	Anthony	Laffor	\N	46	\N	\N	\N	\N
1832	Ocansey Mandela	Ocansey	Mandela	\N	20	\N	\N	\N	\N
1833	Anice Badri	Anice	Badri	\N	53	\N	\N	\N	\N
1834	Chiko Ushindi Kubanza	Chiko	Ushindi	\N	11	\N	\N	\N	\N
1835	Kevin Mondeko Zatu	Kevin	Zatu	\N	11	\N	\N	\N	\N
1836	Abdulahmid Adam	Abdulahmid	Adam	\N	56	\N	\N	\N	\N
1837	Abdul Ramadhani	Abdul	Ramadhani	\N	56	\N	\N	\N	\N
1838	Shabani Mohamed	Shabani	Mohamed	\N	56	\N	\N	\N	\N
1839	Abdulswamad Ali	Abdulswamad	Ali	\N	23	\N	\N	\N	\N
1840	Juma Hamad	Juma	Hamad	\N	23	\N	\N	\N	\N
1841	Evidence Godwin Kilongozi	Evidence	Kilongozi	\N	56	\N	\N	\N	\N
1842	Mohamed Abdallah	Mohamed	Abdallah	\N	56	\N	\N	\N	\N
1843	Ibrahim Khatib	Ibrahim	Khatib	\N	56	\N	\N	\N	\N
1844	Haji Mwambe	Haji	Mwambe	\N	56	\N	\N	\N	\N
1845	Amour Bakari	Amour	Bakari	\N	56	\N	\N	\N	\N
1846	Salum Akida	Salum	Akida	\N	56	\N	\N	\N	\N
1847	Juma Mohamed	Juma	Mohamed	\N	56	\N	\N	\N	\N
1848	Khalfani Swalehe	Khalfani	Swalehe	\N	56	\N	\N	\N	\N
1849	Faraji Kilaza	Faraji	Kilaza	\N	56	\N	\N	\N	\N
1850	Amr Al Sulaya	Amr Al	Sulaya	\N	55	\N	\N	\N	\N
1851	Ally Maaloul	Ally	Maaloul	\N	55	\N	\N	\N	\N
1852	Junior Ajayi	Junior	Ajayi	\N	55	\N	\N	\N	\N
1853	Karim Walid Nedved	Karim	Walid	\N	55	\N	\N	\N	\N
1854	Miche Mika	Miche	Mika	\N	11	\N	\N	\N	\N
1855	Jackson Muleka	Jackson	Muleka	\N	11	\N	\N	\N	\N
1856	Tresor Mputu	Tresor	Mputu	\N	12	\N	\N	\N	\N
1857	Mechak Elia	Mechak	Elia	\N	11	\N	\N	\N	\N
1858	Hamed Marius Assoko	Hamed	Assoko	\N	20	\N	\N	\N	\N
1859	Kazadi Kasengu	Kazadi	Kasengu	\N	12	\N	\N	\N	\N
1860	Jean-Marc Makusu	Jean-Marc	Makusu	\N	12	\N	\N	\N	\N
1861	Mohamed El Amine Hammia	Mohamed	Hammia	\N	1	\N	\N	\N	\N
1862	Said Ali Yahia Cherif	Said	Cherif	\N	1	\N	\N	\N	\N
1863	Mosa Lebusa	Mosa	Lebusa	\N	46	\N	\N	\N	\N
1864	Themba Zwane	Themba	Zwane	\N	46	\N	\N	\N	\N
1865	Emiliano Tade	Emiliano	Tade	\N	2	\N	\N	\N	\N
1866	Ahmed Herve Diomande	Ahmed	Diomande	\N	2	\N	\N	\N	\N
1867	Mohamed Nahiri	Mohamed	Nahiri	\N	32	\N	\N	\N	\N
1868	Haoucine Benayada	Haoucine	Benayada	\N	1	\N	\N	\N	\N
1869	Nasraddine Zaalani	Nasraddine	Zaalani	\N	1	\N	\N	\N	\N
1870	Sid Ali Lamri	Sid	Lamri	\N	1	\N	\N	\N	\N
1871	Botuli Bompunga	Botuli	Bompunga	\N	12	\N	\N	\N	\N
1872	Fabrice Luamba Ngoma	Fabrice	Ngoma	\N	12	\N	\N	\N	\N
1873	Makwekwe Kupa	Makwekwe	Kupa	\N	12	\N	\N	\N	\N
1874	Taha Yassine Khenissi	Taha	Khenissi	\N	53	\N	\N	\N	\N
1875	Thembinkosi Lorch	Thembinkosi	Lorch	\N	46	\N	\N	\N	\N
1876	Justine Shonga	Justine	Shonga	\N	46	\N	\N	\N	\N
1877	Nasser Maher	Nasser	Maher	\N	55	\N	\N	\N	\N
1878	Ismail El Hadad	Ismail	El Hadad	\N	32	\N	\N	\N	\N
1879	Michael Babatunde	Michael	Babatunde	\N	36	\N	\N	\N	\N
1880	Zouhair El Moutaraji	Zouhair	El Moutaraji	\N	32	\N	\N	\N	\N
1881	Walid El Katri	Walid	El Katri	\N	32	\N	\N	\N	\N
1882	Badie Aouk	Badie	Aouk	\N	32	\N	\N	\N	\N
1883	Wonlo Coulibaly	Wonlo	Coulibaly	\N	20	\N	\N	\N	\N
1884	Salif Bagate	Salif	Bagate	\N	20	\N	\N	\N	\N
1885	Abdenour Belkheir	Abdenour	Belkheir	\N	1	\N	\N	\N	\N
1886	Emmanuel Memba	Emmanuel	Memba	\N	56	\N	\N	\N	\N
1887	Ramadhani Chombo	Ramadhani	Chombo	\N	56	\N	\N	\N	\N
1888	Samweli Kamuntu	Samweli	Kamuntu	\N	56	\N	\N	\N	\N
1889	Haythem Jouini	Haythem	Jouini	\N	53	\N	\N	\N	\N
1890	Ziri Hammar	Ziri	Hammar	\N	1	\N	\N	\N	\N
1891	Yakubu Hudu	Yakubu	Hudu	\N	20	\N	\N	\N	\N
1892	Gazi Ayadi	Gazi	Ayadi	\N	32	\N	\N	\N	\N
1893	Benson Shilongo	Benson	Shilongo	\N	34	\N	\N	\N	\N
1894	Emad Hamd	Emad	Hamd	\N	55	\N	\N	\N	\N
1895	Naseem Yettou	Naseem	Yettou	\N	1	\N	\N	\N	\N
1896	Dylan Bahamboula	Dylan	Bahamboula	\N	11	\N	\N	\N	\N
1897	Tuisila Kisinda	Tuisila	Kisinda	\N	11	\N	\N	\N	\N
1898	Ahmed Toure	Ahmed	Toure	\N	21	\N	\N	\N	\N
1899	Augustine Mulenga	Augustine	Mulenga	\N	46	\N	\N	\N	\N
1900	Never Tigere	Never	Tigere	\N	46	\N	\N	\N	\N
1901	Rainsome Pavari	Rainsome	Pavari	\N	46	\N	\N	\N	\N
1902	Franck Kom	Franck	Kom	\N	53	\N	\N	\N	\N
1903	Abedl Rahman Magdi	Abedl	Magdi	\N	55	\N	\N	\N	\N
1904	Bassirou Compaore	Bassirou	Compaore	\N	32	\N	\N	\N	\N
1905	Thapelo Morena	Thapelo	Morena	\N	46	\N	\N	\N	\N
1906	Lebohan Maboe	Lebohan	Maboe	\N	46	\N	\N	\N	\N
1907	Wisdom Ubani	Wisdom	Ubani	\N	36	\N	\N	\N	\N
1908	Olatomi Alfred Olaniyan	Olatomi	Olaniyan	\N	36	\N	\N	\N	\N
1909	Akinkumni Ayobemi Amoo	Akinkumni	Amoo	\N	36	\N	\N	\N	\N
1910	Edmund Godfrey John	Edmund	John	\N	56	\N	\N	\N	\N
1911	Kelvin Pius John	Kelvin	John	\N	56	\N	\N	\N	\N
1912	Morrice Michael Abraham	Morrice	Abraham	\N	56	\N	\N	\N	\N
1913	Ibraheem Olalekan Jabaar	Ibraheem	Jabaar	\N	36	\N	\N	\N	\N
1914	Osvaldo Pedro Capemba	Osvaldo	Capemba	\N	2	\N	\N	\N	\N
1915	Steve Regis Mvoue	Steve	Mvoue	\N	5	\N	\N	\N	\N
1916	Leonel Wamba Djouffo	Leonel	Djouffo	\N	5	\N	\N	\N	\N
1917	Kabaso Chongo Kabaso	Kabaso	Kabaso	\N	58	\N	\N	\N	\N
1918	ABDULKARIM Maqbul Maqbul	ABDULKARIM	Maqbul	\N	23	DF	\N	\N	\N
1919	Ephrem Guikan Ephrem Ephrem Guikan	Ephrem	Ephrem	\N	1	FW	\N	\N	\N
1920	Erisa Ssekisambu Erisa Ssekisambu Erisa Ssekisambu Erisa Ssekisambu	Erisa Ssekisambu	Erisa Ssekisambu	\N	54	FW	\N	\N	\N
1921	Harun Shakava Harun Shakava Harun Shakava Harun Shakava	Harun Shakava	Harun Shakava	\N	23	DF	\N	\N	\N
1922	ISMAIL AIDAN ISMAIL	ISMAIL	ISMAIL	\N	56	\N	\N	\N	\N
1923	Gogfrey Mwashiuya Mwashiuya	Gogfrey	Mwashiuya	\N	56	\N	\N	\N	\N
1924	Sanog sanogo	Sanog	sanogo	\N	56	\N	\N	\N	\N
1925	Richard Richard	Richard	Richard	\N	56	\N	\N	\N	\N
1926	Jonathan Nahimana	Jonathan	Nahimana	\N	4	\N	\N	\N	\N
1927	Justin Ndikumana	Justin	Ndikumana	\N	4	\N	\N	\N	\N
1928	Omar Moussa	Omar	Moussa	\N	4	\N	\N	\N	\N
1929	Gael Duhayindavyi	Gael	Duhayindavyi	\N	4	\N	\N	\N	\N
1930	Nsabiyumva Frederic	Nsabiyumva	Frederic	\N	4	\N	\N	\N	\N
1931	Omar Ngando	Omar	Ngando	\N	4	\N	\N	\N	\N
1932	Gael Bigirimana	Gael	Bigirimana	\N	4	\N	\N	\N	\N
1933	Shassiri Nahimana	Shassiri	Nahimana	\N	4	\N	\N	\N	\N
1934	Francis Mustafa	Francis	Mustafa	\N	4	\N	\N	\N	\N
1935	Amissi Cedric	Amissi	Cedric	\N	4	\N	\N	\N	\N
1936	Abdoul Fiston Razak	Abdoul	Razak	\N	4	\N	\N	\N	\N
1937	Saido Berahino	Saido	Berahino	\N	4	\N	\N	\N	\N
1938	alex iwobi iwobi iwobi	alex	iwobi	\N	36	\N	\N	\N	\N
1939	obi michel obi obi	obi	obi	\N	36	\N	\N	\N	\N
1940	NABY MOUSSA YATTARA	NABY	YATTARA	\N	21	\N	\N	\N	\N
1941	IBRAHIM KONE	IBRAHIM	KONE	\N	21	\N	\N	\N	\N
1942	ALY KEITA	ALY	KEITA	\N	21	\N	\N	\N	\N
1943	Issiaga Sylla	Issiaga	Sylla	\N	21	\N	\N	\N	\N
1944	Odion Jude Ighalo	Odion	Ighalo	\N	36	\N	\N	\N	\N
1945	Ernest Seka Boka	Ernest	Boka	\N	21	\N	\N	\N	\N
1946	Falette Simon Augustin	Falette	Augustin	\N	21	\N	\N	\N	\N
1947	Ousmane Sidibe	Ousmane	Sidibe	\N	21	\N	\N	\N	\N
1948	Julian Marc Jeanvier	Julian	Jeanvier	\N	21	\N	\N	\N	\N
1949	Dyrestam Mikael Bertil	Dyrestam	Bertil	\N	21	\N	\N	\N	\N
1950	Mohamed Baissama Sankoh	Mohamed	Sankoh	\N	21	\N	\N	\N	\N
1951	Fode Camara	Fode	Camara	\N	21	\N	\N	\N	\N
1952	Amadou Diawara	Amadou	Diawara	\N	21	\N	\N	\N	\N
1953	Mohamed Mady Camara	Mohamed	Camara	\N	21	\N	\N	\N	\N
1954	Naby Deco Keita	Naby	Keita	\N	21	\N	\N	\N	\N
1955	Ibrahima Cisse	Ibrahima	Cisse	\N	21	\N	\N	\N	\N
1956	Boubacar Fofana	Boubacar	Fofana	\N	21	\N	\N	\N	\N
1957	Mohamed Lamine Yattara	Mohamed	Yattara	\N	21	\N	\N	\N	\N
1958	Martinez Jose Kante	Martinez	Kante	\N	21	\N	\N	\N	\N
1959	Francois Kamano	Francois	Kamano	\N	21	\N	\N	\N	\N
1960	Idrissa Sylla	Idrissa	Sylla	\N	21	\N	\N	\N	\N
1961	Ibrahima Traore	Ibrahima	Traore	\N	21	\N	\N	\N	\N
1962	Fode Bangaly Koita	Fode	Koita	\N	21	\N	\N	\N	\N
1963	Sory Kaba	Sory	Kaba	\N	21	\N	\N	\N	\N
1964	Ibrahima Ousmane Arthur Dabo	Ibrahima	Dabo	\N	27	\N	\N	\N	\N
1965	Jean Dieu Donne Randrianarisoa	Jean	Randrianarisoa	\N	27	\N	\N	\N	\N
1966	Melvin Adrien	Melvin	Adrien	\N	27	\N	\N	\N	\N
1967	Mamy Nirina Gervais Randrianarisoa	Mamy	Randrianarisoa	\N	27	\N	\N	\N	\N
1968	Razakanantenaina Pascal	Razakanantenaina	Pascal	\N	27	\N	\N	\N	\N
1969	Jeremy Michel Morel	Jeremy	Morel	\N	27	\N	\N	\N	\N
1970	Toavina Hasitiana Rambeloson	Toavina	Rambeloson	\N	27	\N	\N	\N	\N
1971	Romain Metanire	Romain	Metanire	\N	27	\N	\N	\N	\N
1972	Thomas Fontaine	Thomas	Fontaine	\N	27	\N	\N	\N	\N
1973	Jerome Mombris	Jerome	Mombris	\N	27	\N	\N	\N	\N
1974	Jean Romario Baggio Rakotoarisoa	Jean	Rakotoarisoa	\N	27	\N	\N	\N	\N
1975	Marco Ilaimaharitra	Marco	Ilaimaharitra	\N	27	\N	\N	\N	\N
1976	Caloin Dimitry	Caloin	Dimitry	\N	27	\N	\N	\N	\N
1977	Andriamirado Aro Hasina	Andriamirado	Hasina	\N	27	\N	\N	\N	\N
1978	Anicet Andrianantenaina	Anicet	Andrianantenaina	\N	27	\N	\N	\N	\N
1979	Ibrahim Samuel Amada	Ibrahim	Amada	\N	27	\N	\N	\N	\N
1980	Rayan Arnaldo Raveloson NY Aina	Rayan	Raveloson	\N	27	\N	\N	\N	\N
1981	William Gros	William	Gros	\N	27	\N	\N	\N	\N
1982	Francois Kamano	Francois	Kamano	\N	27	\N	\N	\N	\N
1983	Idrissa Sylla	Idrissa	Sylla	\N	27	\N	\N	\N	\N
1984	Sory Kaba	Sory	Kaba	\N	27	\N	\N	\N	\N
1985	Fode Bangaly Koita	Fode	Koita	\N	27	\N	\N	\N	\N
1986	Charles Andriamahitsinoro	Charles	Andriamahitsinoro	\N	27	\N	\N	\N	\N
1987	Faneva Andriatsima	Faneva	Andriatsima	\N	27	\N	\N	\N	\N
1988	Lalaina Nomenjanahary	Lalaina	Nomenjanahary	\N	27	\N	\N	\N	\N
1989	Mounir El Kajoui	Mounir	Kajoui	\N	32	\N	\N	\N	\N
1990	Yassine Bounou	Yassine	Bounou	\N	32	\N	\N	\N	\N
1991	Ahmed Reda Tagnaouti	Ahmed	Tagnaouti	\N	32	\N	\N	\N	\N
1992	Marouane Da Costa	Marouane	Costa	\N	32	\N	\N	\N	\N
1993	Romain Saiss	Romain	Saiss	\N	32	\N	\N	\N	\N
1994	Yunis Abdelhamid	Yunis	Abdelhamid	\N	32	\N	\N	\N	\N
1995	Medhi Benatia	Medhi	Benatia	\N	32	\N	\N	\N	\N
1996	Achraf Hakimi	Achraf	Hakimi	\N	32	\N	\N	\N	\N
1997	Karim El Ahmadi	Karim	Ahmadi	\N	32	\N	\N	\N	\N
1998	Youssef Ait Bennasser	Youssef	Bennasser	\N	32	\N	\N	\N	\N
1999	Mehdi Bourabia	Mehdi	Bourabia	\N	32	\N	\N	\N	\N
2000	Mbark Boussoufa	Mbark	Boussoufa	\N	32	\N	\N	\N	\N
2001	Younes Belhanda	Younes	Belhanda	\N	32	\N	\N	\N	\N
2002	Faycal Fajr	Faycal	Fajr	\N	32	\N	\N	\N	\N
2003	Nordin Amrabat	Nordin	Amrabat	\N	32	\N	\N	\N	\N
2004	Hakim Ziyech	Hakim	Ziyech	\N	32	\N	\N	\N	\N
2005	Noussair Mazraoui	Noussair	Mazraoui	\N	32	\N	\N	\N	\N
2006	Youssef En-Nesyri	Youssef	En-Nesyri	\N	32	\N	\N	\N	\N
2007	Sofiane Boufal	Sofiane	Boufal	\N	32	\N	\N	\N	\N
2008	Nabil Dirar	Nabil	Dirar	\N	32	\N	\N	\N	\N
2009	Abderazak Hamed Allah	Abderazak	Allah	\N	32	\N	\N	\N	\N
2010	Khalid Boutaib	Khalid	Boutaib	\N	32	\N	\N	\N	\N
2011	Oussama Idrissi	Oussama	Idrissi	\N	32	\N	\N	\N	\N
2012	Ratanda Mbazuvara	Ratanda	Mbazuvara	\N	34	\N	\N	\N	\N
2013	Loydt Kazapua	Loydt	Kazapua	\N	34	\N	\N	\N	\N
2014	Max Mbaeva	Max	Mbaeva	\N	34	\N	\N	\N	\N
2015	Ryan Nyambe	Ryan	Nyambe	\N	34	\N	\N	\N	\N
2016	Larry Horaeb	Larry	Horaeb	\N	34	\N	\N	\N	\N
2017	Denzil Haoseb	Denzil	Haoseb	\N	34	\N	\N	\N	\N
2018	Ivan Kamberipa	Ivan	Kamberipa	\N	34	\N	\N	\N	\N
2019	Charles Hambira	Charles	Hambira	\N	34	\N	\N	\N	\N
2020	Riaan Hanamub	Riaan	Hanamub	\N	34	\N	\N	\N	\N
2021	Ananias Gebhardt	Ananias	Gebhardt	\N	34	\N	\N	\N	\N
2022	Absalom Iimbondi	Absalom	Iimbondi	\N	34	\N	\N	\N	\N
2023	Willy Stephanus	Willy	Stephanus	\N	34	\N	\N	\N	\N
2024	Petrus Shitembi	Petrus	Shitembi	\N	34	\N	\N	\N	\N
2025	Ronald Ketjijere	Ronald	Ketjijere	\N	34	\N	\N	\N	\N
2026	Dynamo Fredericks	Dynamo	Fredericks	\N	34	\N	\N	\N	\N
2027	Marcel Papama	Marcel	Papama	\N	34	\N	\N	\N	\N
2028	Manfred Starke	Manfred	Starke	\N	34	\N	\N	\N	\N
2029	Deon Hotto	Deon	Hotto	\N	34	\N	\N	\N	\N
2030	Itamunua Keimuine	Itamunua	Keimuine	\N	34	\N	\N	\N	\N
2031	Benson Shilongo	Benson	Shilongo	\N	34	\N	\N	\N	\N
2032	Peter Shalulile	Peter	Shalulile	\N	34	\N	\N	\N	\N
2033	Joslyn Kamatuka	Joslyn	Kamatuka	\N	34	\N	\N	\N	\N
2034	Isaskar Gurirab.	Isaskar	Gurirab.	\N	34	\N	\N	\N	\N
2035	Abdoulaye Diallo	Abdoulaye	Diallo	\N	42	\N	\N	\N	\N
2036	Alfred Gomis	Alfred	Gomis	\N	42	\N	\N	\N	\N
2037	Edouard Mendy	Edouard	Mendy	\N	42	\N	\N	\N	\N
2038	Kalidou Koulibaly	Kalidou	Koulibaly	\N	42	\N	\N	\N	\N
2039	Moussa Wague	Moussa	Wague	\N	42	\N	\N	\N	\N
2040	Pape Abdou Cisse	Pape	Cisse	\N	42	\N	\N	\N	\N
2041	Salif Sane	Salif	Sane	\N	42	\N	\N	\N	\N
2042	Youssouf Sabaly	Youssouf	Sabaly	\N	42	\N	\N	\N	\N
2043	Lamine Gassama	Lamine	Gassama	\N	42	\N	\N	\N	\N
2044	Cheikhou Kouyate	Cheikhou	Kouyate	\N	42	\N	\N	\N	\N
2045	Saliou Ciss	Saliou	Ciss	\N	42	\N	\N	\N	\N
2046	Alfred Ndiaye	Alfred	Ndiaye	\N	42	\N	\N	\N	\N
2047	Idrissa Gana Gueye	Idrissa	Gueye	\N	42	\N	\N	\N	\N
2048	Keprin Diatta	Keprin	Diatta	\N	42	\N	\N	\N	\N
2049	Pape Alioune Ndiaye	Pape	Ndiaye	\N	42	\N	\N	\N	\N
2050	Henri Saivet	Henri	Saivet	\N	42	\N	\N	\N	\N
2051	Ismaila Sarr	Ismaila	Sarr	\N	42	\N	\N	\N	\N
2052	Keita Balde	Keita	Balde	\N	42	\N	\N	\N	\N
2053	Mbaye Niang	Mbaye	Niang	\N	42	\N	\N	\N	\N
2054	Moussa Konate	Moussa	Konate	\N	42	\N	\N	\N	\N
2055	Mbaye Diagne	Mbaye	Diagne	\N	42	\N	\N	\N	\N
2056	Sada Thioub	Sada	Thioub	\N	42	\N	\N	\N	\N
2057	Sadio Mane	Sadio	Mane	\N	42	\N	\N	\N	\N
2058	Aishi Manula	Aishi	Manula	\N	56	\N	\N	\N	\N
2059	Metacha Mhata	Metacha	Mhata	\N	56	\N	\N	\N	\N
2060	Aron Kalambo	Aron	Kalambo	\N	56	\N	\N	\N	\N
2061	Hassan Ramadan	Hassan	Ramadan	\N	56	\N	\N	\N	\N
2062	Vincent Phillipo	Vincent	Phillipo	\N	56	\N	\N	\N	\N
2063	Gadiel Michael	Gadiel	Michael	\N	56	\N	\N	\N	\N
2064	Ally Mtoni	Ally	Mtoni	\N	56	\N	\N	\N	\N
2065	Mohammed Hussein	Mohammed	Hussein	\N	1	\N	\N	\N	\N
2066	Kelvin Yondani	Kelvin	Yondani	\N	56	\N	\N	\N	\N
2067	Erasto Nyoni	Erasto	Nyoni	\N	56	\N	\N	\N	\N
2068	Agrey Moris	Agrey	Moris	\N	56	\N	\N	\N	\N
2069	Feisal Salum	Feisal	Salum	\N	56	\N	\N	\N	\N
2070	Himid Mao	Himid	Mao	\N	56	\N	\N	\N	\N
2071	Mudathir Yahya	Mudathir	Yahya	\N	56	\N	\N	\N	\N
2072	Frank Domayo	Frank	Domayo	\N	56	\N	\N	\N	\N
2073	Farid Mussa	Farid	Mussa	\N	56	\N	\N	\N	\N
2074	Yahya Zayd	Yahya	Zayd	\N	56	\N	\N	\N	\N
2075	Rashid Mandawa	Rashid	Mandawa	\N	56	\N	\N	\N	\N
2076	Mbwana Ally Samatta	Mbwana	Samatta	\N	56	\N	\N	\N	\N
2077	Thomas Ulimwengu	Thomas	Ulimwengu	\N	56	\N	\N	\N	\N
2078	John Bocco	John	Bocco	\N	56	\N	\N	\N	\N
2079	Abdillanie Mussa	Abdillanie	Mussa	\N	56	\N	\N	\N	\N
2080	Simon Msuva	Simon	Msuva	\N	56	\N	\N	\N	\N
2081	Patrick Matasi	Patrick	Matasi	\N	23	\N	\N	\N	\N
2082	John Oyemba	John	Oyemba	\N	23	\N	\N	\N	\N
2083	Faruk Shikalo	Faruk	Shikalo	\N	23	\N	\N	\N	\N
2084	Joash Onyango	Joash	Onyango	\N	23	\N	\N	\N	\N
2085	Philemon Otieno	Philemon	Otieno	\N	23	\N	\N	\N	\N
2086	Musa Mohammed	Musa	Mohammed	\N	23	\N	\N	\N	\N
2087	Bernard Ochieng	Bernard	Ochieng	\N	23	\N	\N	\N	\N
2088	Joseph Okumu	Joseph	Okumu	\N	23	\N	\N	\N	\N
2089	Abud Omar	Abud	Omar	\N	23	\N	\N	\N	\N
2090	Eric Ouma	Eric	Ouma	\N	23	\N	\N	\N	\N
2091	David Owino	David	Owino	\N	23	\N	\N	\N	\N
2092	Ismael Gonzalez	Ismael	Gonzalez	\N	23	\N	\N	\N	\N
2093	Eric Johana	Eric	Johana	\N	23	\N	\N	\N	\N
2094	Francis Kahata	Francis	Kahata	\N	23	\N	\N	\N	\N
2095	Ovella Ochieng	Ovella	Ochieng	\N	23	\N	\N	\N	\N
2096	Dennis Odhiambo	Dennis	Odhiambo	\N	23	\N	\N	\N	\N
2097	Johanna Omollo	Johanna	Omollo	\N	23	\N	\N	\N	\N
2098	Ayub Timbe	Ayub	Timbe	\N	23	\N	\N	\N	\N
2099	Victor Wanyama	Victor	Wanyama	\N	23	\N	\N	\N	\N
2100	Paul Were	Paul	Were	\N	23	\N	\N	\N	\N
2101	John Avire	John	Avire	\N	23	\N	\N	\N	\N
2102	Masoud Juma	Masoud	Juma	\N	23	\N	\N	\N	\N
2103	Michael Olunga	Michael	Olunga	\N	23	\N	\N	\N	\N
2104	Azzedine Doukha	Azzedine	Doukha	\N	1	\N	\N	\N	\N
2105	Rais M’Bolhi	Rais	M’Bolhi	\N	1	\N	\N	\N	\N
2106	Alexandre Oukidja	Alexandre	Oukidja	\N	1	\N	\N	\N	\N
2107	Ramy Bensebaini	Ramy	Bensebaini	\N	1	\N	\N	\N	\N
2108	Mehdi Zeffane	Mehdi	Zeffane	\N	1	\N	\N	\N	\N
2109	Youcef Atal	Youcef	Atal	\N	1	\N	\N	\N	\N
2110	Djamel Benlamri	Djamel	Benlamri	\N	1	\N	\N	\N	\N
2111	Mohamed Fares	Mohamed	Fares	\N	1	\N	\N	\N	\N
2112	Rafik Halliche	Rafik	Halliche	\N	1	\N	\N	\N	\N
2113	Aissa Mandi	Aissa	Mandi	\N	1	\N	\N	\N	\N
2114	Mehdi Tahrat	Mehdi	Tahrat	\N	1	\N	\N	\N	\N
2115	Baghdad Bounedjah	Baghdad	Bounedjah	\N	1	\N	\N	\N	\N
2116	Mehdi Abeid	Mehdi	Abeid	\N	1	\N	\N	\N	\N
2117	Ismail Bennacer	Ismail	Bennacer	\N	1	\N	\N	\N	\N
2118	Hicham Boudaoui	Hicham	Boudaoui	\N	1	\N	\N	\N	\N
2119	Sofiane Feghouli	Sofiane	Feghouli	\N	1	\N	\N	\N	\N
2120	Adlene Guedioura	Adlene	Guedioura	\N	1	\N	\N	\N	\N
2121	Youcef Belaili	Youcef	Belaili	\N	1	\N	\N	\N	\N
2122	Yacine Brahimi	Yacine	Brahimi	\N	1	\N	\N	\N	\N
2123	Andy Delort	Andy	Delort	\N	1	\N	\N	\N	\N
2124	Riyad Mahrez	Riyad	Mahrez	\N	1	\N	\N	\N	\N
2125	Adam Ounas	Adam	Ounas	\N	1	\N	\N	\N	\N
2126	Islam Slimani	Islam	Slimani	\N	1	\N	\N	\N	\N
2127	Darren Keet	Darren	Keet	\N	46	\N	\N	\N	\N
2128	Ronwen Hayden Williams	Ronwen	Williams	\N	1	\N	\N	\N	\N
2129	Bruce Hlamulo Bvuma	Bruce	Bvuma	\N	46	\N	\N	\N	\N
2130	Daniel Antonio Cardoso	Daniel	Cardoso	\N	46	\N	\N	\N	\N
2131	Ramahlwe Mphahlele	Ramahlwe	Mphahlele	\N	46	\N	\N	\N	\N
2132	Thulani Hlatshwayo	Thulani	Hlatshwayo	\N	46	\N	\N	\N	\N
2133	Sakhile Innocent Maela Francis	Sakhile	Maela	\N	46	\N	\N	\N	\N
2134	S’Fiso Sandile Hlanti	S’Fiso	Hlanti	\N	46	\N	\N	\N	\N
2135	Buhlebuyeza Wilson Mkhwanazi	Buhlebuyeza	Mkhwanazi	\N	46	\N	\N	\N	\N
2136	Thamsanqa Innocent Mkhize	Thamsanqa	Mkhize	\N	46	\N	\N	\N	\N
2137	Bongani Zungu	Bongani	Zungu	\N	46	\N	\N	\N	\N
2138	Hlompho Alpheus Kekana	Hlompho	Kekana	\N	46	\N	\N	\N	\N
2139	Dean Furman	Dean	Furman	\N	46	\N	\N	\N	\N
2140	Kamohelo Mokotjo	Kamohelo	Mokotjo	\N	46	\N	\N	\N	\N
2141	Samuel Tiyani Mabunda	Samuel	Mabunda	\N	46	\N	\N	\N	\N
2142	Thulani caleb Serero	Thulani	Serero	\N	46	\N	\N	\N	\N
2143	Thembinkosi Christopher Lorch	Thembinkosi	Lorch	\N	46	\N	\N	\N	\N
2144	Themba Zwane	Themba	Zwane	\N	46	\N	\N	\N	\N
2145	Lebo Mothiba	Lebo	Mothiba	\N	46	\N	\N	\N	\N
2146	Percy Muzi Tau	Percy	Tau	\N	46	\N	\N	\N	\N
2147	Lars Veldwijk	Lars	Veldwijk	\N	46	\N	\N	\N	\N
2148	Lebogang Kgosana Maboe	Lebogang	Maboe	\N	46	\N	\N	\N	\N
2149	Sibusiso Vilakazi	Sibusiso	Vilakazi	\N	46	\N	\N	\N	\N
2150	Sylvain Gbohouo	Sylvain	Gbohouo	\N	22	\N	\N	\N	\N
2151	Ali Badra	Ali	Badra	\N	22	\N	\N	\N	\N
2152	Tape Ira	Tape	Ira	\N	22	\N	\N	\N	\N
2153	Serge Aurier	Serge	Aurier	\N	22	\N	\N	\N	\N
2154	Wilfried Kanon	Wilfried	Kanon	\N	22	\N	\N	\N	\N
2155	Wonlo Coulibaly	Wonlo	Coulibaly	\N	22	\N	\N	\N	\N
2156	Ismaël Traoré	Ismaël	Traoré	\N	22	\N	\N	\N	\N
2157	Mamadou Bagayoko	Mamadou	Bagayoko	\N	22	\N	\N	\N	\N
2158	Cheikh Comara	Cheikh	Comara	\N	22	\N	\N	\N	\N
2159	Souleyman Bamba	Souleyman	Bamba	\N	22	\N	\N	\N	\N
2160	Jean Philippe Gbamin	Jean	Gbamin	\N	22	\N	\N	\N	\N
2161	Geoffrey Serey Dié	Geoffrey	Dié	\N	22	\N	\N	\N	\N
2162	Jean Michaël Seri	Jean	Seri	\N	22	\N	\N	\N	\N
2163	Victorian Angban	Victorian	Angban	\N	22	\N	\N	\N	\N
2164	Franck Kessié	Franck	Kessié	\N	22	\N	\N	\N	\N
2165	Ibrahim Sangaré	Ibrahim	Sangaré	\N	22	\N	\N	\N	\N
2166	Max Alain Gradel	Max	Gradel	\N	22	\N	\N	\N	\N
2167	Nicolas Pépé	Nicolas	Pépé	\N	1	\N	\N	\N	\N
2168	Wilfried Zaha	Wilfried	Zaha	\N	22	\N	\N	\N	\N
2169	Jonathan Kodjia	Jonathan	Kodjia	\N	22	\N	\N	\N	\N
2170	Roger Assalé	Roger	Assalé	\N	22	\N	\N	\N	\N
2171	Maxwel Cornet	Maxwel	Cornet	\N	22	\N	\N	\N	\N
2172	Wilfried Bony	Wilfried	Bony	\N	22	\N	\N	\N	\N
2173	Mahmoud Hassan Trezeguet	Mahmoud	Trezeguet	\N	55	\N	\N	\N	\N
2174	Emmanuel Arnold Okwi	Emmanuel	Okwi	\N	54	\N	\N	\N	\N
2175	Patrick Henry Kaddu	Patrick	Kaddu	\N	54	\N	\N	\N	\N
2176	Murushid Jjuuko	Murushid	Jjuuko	\N	54	\N	\N	\N	\N
2177	Yannick Bolasie	Yannick	Bolasie	\N	12	\N	\N	\N	\N
2178	Merveille Bope Bokadi	Merveille	Bokadi	\N	12	\N	\N	\N	\N
2179	Talent Chawapihwa	Talent	Chawapihwa	\N	47	\N	\N	\N	\N
2180	Shassir Nahimana	Shassir	Nahimana	\N	4	\N	\N	\N	\N
2181	Ghaylen Chaalali	Ghaylen	Chaalali	\N	53	\N	\N	\N	\N
2182	Youssef Msakni	Youssef	Msakni	\N	53	\N	\N	\N	\N
2183	Toni Cabaça	Toni	Cabaça	\N	2	\N	\N	\N	\N
2184	David Issa Mwantika	David	Mwantika	\N	56	\N	\N	\N	\N
2185	Mickael Pote	Mickael	Pote	\N	13	\N	\N	\N	\N
2186	Cédric Bakambu	Cédric	Bakambu	\N	12	\N	\N	\N	\N
2187	Chancel Mangulu Mbemba	Chancel	Mbemba	\N	12	\N	\N	\N	\N
2188	Abdoulay Diaby	Abdoulay	Diaby	\N	12	\N	\N	\N	\N
2189	Moussa Marega	Moussa	Marega	\N	29	\N	\N	\N	\N
2190	Adama Traoré I	Adama	Traoré I	\N	29	\N	\N	\N	\N
2191	Adama Traoré II	Adama	Traoré II	\N	29	\N	\N	\N	\N
2192	Diadie Samassékou	Diadie	Samassékou	\N	29	\N	\N	\N	\N
2193	Amadou Haidara	Amadou	Haidara	\N	29	\N	\N	\N	\N
2194	Moctar Sidi El Hacen	Moctar	El Hacen	\N	30	\N	\N	\N	\N
2195	Banana Yaya	Banana	Yaya	\N	5	\N	\N	\N	\N
2196	Stéphane Bahoken	Stéphane	Bahoken	\N	5	\N	\N	\N	\N
2197	Clinton N'Jie	Clinton	N'Jie	\N	5	\N	\N	\N	\N
2198	Jordan Pierre Ayew	Jordan	Ayew	\N	20	\N	\N	\N	\N
2199	André Morgan Rami Ayew Dede Ayew	André	Ayew	\N	20	\N	\N	\N	\N
2200	Thomas Teye Partey	Thomas	Partey	\N	20	\N	\N	\N	\N
2201	Kenneth Josiah Omeruo	Kenneth	Omeruo	\N	36	\N	\N	\N	\N
2202	Khama Billiat	Khama	Billiat	\N	47	\N	\N	\N	\N
2203	Mohamed Salah	Mohamed	Salah	\N	55	\N	\N	\N	\N
2204	Ahmed El Mohamady	Ahmed	El Mohamady	\N	55	\N	\N	\N	\N
2205	Wahbi Khazri	Wahbi	Khazri	\N	53	\N	\N	\N	\N
2206	Jonathan Bolingi	Jonathan	Bolingi	\N	12	\N	\N	\N	\N
2207	Britt Curtis Assombalonga	Britt	Assombalonga	\N	12	\N	\N	\N	\N
2208	Moise Adilehou	Moise	Adilehou	\N	13	\N	\N	\N	\N
2209	Taha Yassine Khenissi	Taha	Khenissi	\N	53	\N	\N	\N	\N
2210	Rami Bedoui	Rami	Bedoui	\N	53	\N	\N	\N	\N
2211	Fabien Ceddy Farnolle	Fabien	Farnolle	\N	13	\N	\N	\N	\N
2212	Owalabi Saturnin Allagbé Kassifa	Owalabi	Kassifa	\N	13	\N	\N	\N	\N
2213	Chérif Dine Kakpo	Chérif	Kakpo	\N	13	\N	\N	\N	\N
2214	Séidou Barazé Guero	Séidou	Guero	\N	13	\N	\N	\N	\N
2215	Khaled Adénon	Khaled	Adénon	\N	13	\N	\N	\N	\N
2216	Junior Salomon	Junior	Salomon	\N	13	\N	\N	\N	\N
2217	Olivier Verdon	Olivier	Verdon	\N	13	\N	\N	\N	\N
2218	Emmanuel Imorou	Emmanuel	Imorou	\N	13	\N	\N	\N	\N
2219	David Kiki	David	Kiki	\N	13	\N	\N	\N	\N
2220	Rodrigue Fassinou	Rodrigue	Fassinou	\N	13	\N	\N	\N	\N
2221	Tidjani Anaane	Tidjani	Anaane	\N	13	\N	\N	\N	\N
2222	Jordan Adéoti	Jordan	Adéoti	\N	13	\N	\N	\N	\N
2223	Sessi D'Almeida	Sessi	D'Almeida	\N	13	\N	\N	\N	\N
2224	Mama Séïbou	Mama	Séïbou	\N	13	\N	\N	\N	\N
2225	Rodrigue Kossi	Rodrigue	Kossi	\N	13	\N	\N	\N	\N
2226	David Djigla	David	Djigla	\N	13	\N	\N	\N	\N
2227	Steve Mounié	Steve	Mounié	\N	13	\N	\N	\N	\N
2228	Cebio Soukou	Cebio	Soukou	\N	13	\N	\N	\N	\N
2229	Segbé Azankpo	Segbé	Azankpo	\N	13	\N	\N	\N	\N
2230	Jodel Dossou	Jodel	Dossou	\N	13	\N	\N	\N	\N
2231	Ikechukwu Vincent Ezenwa	Ikechukwu	Ezenwa	\N	36	\N	\N	\N	\N
2232	Francis Odinaka Uzoho	Francis	Uzoho	\N	36	\N	\N	\N	\N
2233	Daniel Akpeyi	Daniel	Akpeyi	\N	36	\N	\N	\N	\N
2234	Ola Aina	Ola	Aina	\N	36	\N	\N	\N	\N
2235	Jamilu Collins	Jamilu	Collins	\N	36	\N	\N	\N	\N
2236	William Paul Troost-Ekong	William	Troost-Ekong	\N	36	\N	\N	\N	\N
2237	Leon Aderemi Balogun	Leon	Balogun	\N	36	\N	\N	\N	\N
2238	Shehu Unman Abdullahi	Shehu	Abdullahi	\N	36	\N	\N	\N	\N
2239	Chidozie Collins Awaziem	Chidozie	Awaziem	\N	36	\N	\N	\N	\N
2240	Wilfred Ndidi	Wilfred	Ndidi	\N	36	\N	\N	\N	\N
2241	Peter Etebo	Peter	Etebo	\N	36	\N	\N	\N	\N
2242	John Obi Mikel	John	Mikel	\N	36	\N	\N	\N	\N
2243	John Ogu	John	Ogu	\N	36	\N	\N	\N	\N
2244	Ahmed Musa	Ahmed	Musa	\N	36	\N	\N	\N	\N
2245	Henry Onyekuru	Henry	Onyekuru	\N	36	\N	\N	\N	\N
2246	Samuel Chukwueze	Samuel	Chukwueze	\N	36	\N	\N	\N	\N
2247	Paul Onuachu	Paul	Onuachu	\N	36	\N	\N	\N	\N
2248	Moses Daddy Simon	Moses	Simon	\N	36	\N	\N	\N	\N
2249	Samuel Kalu	Samuel	Kalu	\N	36	\N	\N	\N	\N
2250	Victor James Osimhen	Victor	Osimhen	\N	36	\N	\N	\N	\N
2251	Farouk Ben Mustapha	Farouk	Mustapha	\N	53	\N	\N	\N	\N
2252	Wajdi Kechrida	Wajdi	Kechrida	\N	53	\N	\N	\N	\N
2253	Dylan Bronn	Dylan	Bronn	\N	53	\N	\N	\N	\N
2254	Yassine Meriah	Yassine	Meriah	\N	53	\N	\N	\N	\N
2255	Oussama Haddadi	Oussama	Haddadi	\N	53	\N	\N	\N	\N
2256	Firas Chaouat	Firas	Chaouat	\N	53	\N	\N	\N	\N
2257	Anice Badri	Anice	Badri	\N	53	\N	\N	\N	\N
2258	Karim Aouadhi	Karim	Aouadhi	\N	53	\N	\N	\N	\N
2259	Ferjani Sassi	Ferjani	Sassi	\N	53	\N	\N	\N	\N
2260	Mohamed Dräger	Mohamed	Dräger	\N	53	\N	\N	\N	\N
2261	Marc Martin Lamti	Marc	Lamti	\N	53	\N	\N	\N	\N
2262	Mouez Hassen	Mouez	Hassen	\N	53	\N	\N	\N	\N
2263	Ellyes Skhiri	Ellyes	Skhiri	\N	53	\N	\N	\N	\N
2264	Bassem Srarfi	Bassem	Srarfi	\N	53	\N	\N	\N	\N
2265	Ayman Ben Mohamed	Ayman	Mohamed	\N	53	\N	\N	\N	\N
2266	Nassim Hnid	Nassim	Hnid	\N	53	\N	\N	\N	\N
2267	Moez Ben Cherifia	Moez	Cherifia	\N	53	\N	\N	\N	\N
2268	Naïm Sliti	Naïm	Sliti	\N	53	\N	\N	\N	\N
2269	Gogfrey Fraha Viera viera	Gogfrey	Viera	\N	3	\N	\N	\N	\N
2270	Sharaf Aldin Abdurahman Shiboub	Sharaf	Shiboub	\N	56	\N	\N	\N	\N
2271	Miraji Athumani	Miraji	Athumani	\N	56	\N	\N	\N	\N
2272	Sadat Mohamed	Sadat	Mohamed	\N	56	\N	\N	\N	\N
2273	Idd Seleman	Idd	Seleman	\N	1	\N	\N	\N	\N
2274	Hassan Kapalata	Hassan	Kapalata	\N	56	\N	\N	\N	\N
2275	Paul Materazi	Paul	Materazi	\N	56	\N	\N	\N	\N
2276	Daruesh Saliboko	Daruesh	Saliboko	\N	56	\N	\N	\N	\N
2277	Ismail Mhesa	Ismail	Mhesa	\N	56	\N	\N	\N	\N
2278	Frank Pasco	Frank	Pasco	\N	56	\N	\N	\N	\N
2279	Ibrahim Said	Ibrahim	Said	\N	56	\N	\N	\N	\N
2280	Lucas Kikoti	Lucas	Kikoti	\N	56	\N	\N	\N	\N
2281	Omary Issa	Omary	Issa	\N	56	\N	\N	\N	\N
2284	Awesu Awesu	Awesu	Awesu	\N	56	\N	\N	\N	\N
2285	Asieche Ellie	Asieche	Ellie	\N	23	\N	\N	\N	\N
2286	Kennedy Otieno	Kennedy	Otieno	\N	23	\N	\N	\N	\N
2287	Kapaito Erick	Kapaito	Erick	\N	23	\N	\N	\N	\N
2288	Abdalla Hamisi	Abdalla	Hamisi	\N	23	\N	\N	\N	\N
2289	Evans Amwoka	Evans	Amwoka	\N	23	\N	\N	\N	\N
2290	Mark Bikokwa	Mark	Bikokwa	\N	23	\N	\N	\N	\N
2291	Brian Birgen	Brian	Birgen	\N	23	\N	\N	\N	\N
2292	Omar Boraafya	Omar	Boraafya	\N	23	\N	\N	\N	\N
2293	Fredrick Chitai	Fredrick	Chitai	\N	23	\N	\N	\N	\N
2294	Cliff Kasuti	Cliff	Kasuti	\N	23	\N	\N	\N	\N
2295	Geoffrey Kokoyo	Geoffrey	Kokoyo	\N	23	\N	\N	\N	\N
2296	Omar Mbongi	Omar	Mbongi	\N	23	\N	\N	\N	\N
2297	Hassan Mohammed	Hassan	Mohammed	\N	23	\N	\N	\N	\N
2298	Churchill Muloma	Churchill	Muloma	\N	23	\N	\N	\N	\N
2299	Elijah Mwanzia	Elijah	Mwanzia	\N	23	\N	\N	\N	\N
2300	Masuta Masita	Masuta	Masita	\N	23	\N	\N	\N	\N
2301	Elvis Nandwa	Elvis	Nandwa	\N	23	\N	\N	\N	\N
2302	John Kago Njoroge	John	Njoroge	\N	23	\N	\N	\N	\N
2303	Enosh Ochieng'	Enosh	Ochieng'	\N	23	\N	\N	\N	\N
2304	Jacktone Odhiambo	Jacktone	Odhiambo	\N	23	\N	\N	\N	\N
2305	Timothy Odhiambo	Timothy	Odhiambo	\N	23	\N	\N	\N	\N
2306	Ezekiel Okare	Ezekiel	Okare	\N	23	\N	\N	\N	\N
2307	Rodgers Omondi	Rodgers	Omondi	\N	23	\N	\N	\N	\N
2308	Bernard Ongoma	Bernard	Ongoma	\N	23	\N	\N	\N	\N
2309	Justine Onwonga	Justine	Onwonga	\N	23	\N	\N	\N	\N
2310	Boniface Onyango	Boniface	Onyango	\N	23	\N	\N	\N	\N
2311	Samuel Ouma Onyango	Samuel	Onyango	\N	23	\N	\N	\N	\N
2312	Michael Otieno	Michael	Otieno	\N	23	\N	\N	\N	\N
2313	Oliver Ruto	Oliver	Ruto	\N	23	\N	\N	\N	\N
2314	Benson Sande	Benson	Sande	\N	23	\N	\N	\N	\N
2315	James Saruni	James	Saruni	\N	23	\N	\N	\N	\N
2316	Ibrahim Shambi	Ibrahim	Shambi	\N	23	\N	\N	\N	\N
2317	Cylus Ambeyi Shitote	Cylus	Shitote	\N	23	\N	\N	\N	\N
2318	Elvis Rupia	Elvis	Rupia	\N	23	\N	\N	\N	\N
2319	Collins Wakhungu	Collins	Wakhungu	\N	23	\N	\N	\N	\N
2320	Nicholas Kipkirui	Nicholas	Kipkirui	\N	23	\N	\N	\N	\N
2321	Boniface Muchiri	Boniface	Muchiri	\N	23	\N	\N	\N	\N
2322	Enock Agwanda	Enock	Agwanda	\N	23	\N	\N	\N	\N
2323	Stephen Waruru	Stephen	Waruru	\N	23	\N	\N	\N	\N
2324	Dennis Odhiambo	Dennis	Odhiambo	\N	23	\N	\N	\N	\N
2325	Kenneth Muguna	Kenneth	Muguna	\N	23	\N	\N	\N	\N
2326	Charles Momanyi	Charles	Momanyi	\N	23	\N	\N	\N	\N
2327	Boniface Omondi	Boniface	Omondi	\N	23	\N	\N	\N	\N
2328	Kepha Ondati	Kepha	Ondati	\N	1	\N	\N	\N	\N
2329	Deric Anami	Deric	Anami	\N	23	\N	\N	\N	\N
2330	Newton Ondari	Newton	Ondari	\N	23	\N	\N	\N	\N
2331	Trairone Santos	Trairone	Santos	\N	1	\N	\N	\N	\N
2332	Gerson Fraga	Gerson	Fraga	\N	1	\N	\N	\N	\N
2333	Beno Kakolanya	Beno	Kakolanya	\N	56	\N	\N	\N	\N
2334	Gadiel Michael	Gadiel	Michael	\N	56	\N	\N	\N	\N
2335	Haruna Shamte	Haruna	Shamte	\N	56	\N	\N	\N	\N
2336	Ibrahim Ajibu	Ibrahim	Ajibu	\N	56	\N	\N	\N	\N
2337	Abdulharim Humudi	Abdulharim	Humudi	\N	56	\N	\N	\N	\N
2338	Ally Yusuph	Ally	Yusuph	\N	56	\N	\N	\N	\N
2339	Omary Hassan	Omary	Hassan	\N	56	\N	\N	\N	\N
2340	Henry Joseph	Henry	Joseph	\N	56	\N	\N	\N	\N
2341	Awadh Issa	Awadh	Issa	\N	56	\N	\N	\N	\N
2342	Stamil Mbonde	Stamil	Mbonde	\N	56	\N	\N	\N	\N
2343	Abdul Haule	Abdul	Haule	\N	56	\N	\N	\N	\N
2344	Nassor Kiziwa	Nassor	Kiziwa	\N	56	\N	\N	\N	\N
2345	Shaban Idd	Shaban	Idd	\N	56	\N	\N	\N	\N
2346	Stephen Kadogo Onyango	Stephen	Onyango	\N	23	\N	\N	\N	\N
2347	Salmon Omollo	Salmon	Omollo	\N	23	\N	\N	\N	\N
2348	Brian Wepo	Brian	Wepo	\N	23	\N	\N	\N	\N
2349	Timothy Otieno	Timothy	Otieno	\N	23	\N	\N	\N	\N
2350	Klinsman Omulunga	Klinsman	Omulunga	\N	23	\N	\N	\N	\N
2351	Patrick Sibomana	Patrick	Sibomana	\N	39	\N	\N	\N	\N
2352	Reliant Lusajo	Reliant	Lusajo	\N	56	\N	\N	\N	\N
2353	Emmanuel Lukinda	Emmanuel	Lukinda	\N	56	\N	\N	\N	\N
2354	Mo Ibrahim	Mo	Ibrahim	\N	56	\N	\N	\N	\N
2355	Jerry Tegete	Jerry	Tegete	\N	56	\N	\N	\N	\N
2356	Evarist Mjwahuki	Evarist	Mjwahuki	\N	56	\N	\N	\N	\N
2357	Collins Neto	Collins	Neto	\N	23	\N	\N	\N	\N
2358	Danson Namasakha	Danson	Namasakha	\N	23	\N	\N	\N	\N
2359	Yemi Mwana	Yemi	Mwana	\N	23	\N	\N	\N	\N
2360	Messi Agege	Messi	Agege	\N	23	\N	\N	\N	\N
2361	George Owino	George	Owino	\N	23	\N	\N	\N	\N
2362	George Chota	George	Chota	\N	56	\N	\N	\N	\N
2363	Godfrey Villa Orachaman	Godfrey	Orachaman	\N	23	\N	\N	\N	\N
2364	Darius Msagha	Darius	Msagha	\N	23	\N	\N	\N	\N
2365	Kennedy Onyango	Kennedy	Onyango	\N	23	\N	\N	\N	\N
2366	Allan Wanga	Allan	Wanga	\N	23	\N	\N	\N	\N
2367	Stephen Etyang	Stephen	Etyang	\N	23	\N	\N	\N	\N
2368	Rashid Athman	Rashid	Athman	\N	23	\N	\N	\N	\N
2369	Gerson Likono	Gerson	Likono	\N	23	\N	\N	\N	\N
2370	Eliud Lokuwam	Eliud	Lokuwam	\N	23	\N	\N	\N	\N
2371	Patrick Otieno	Patrick	Otieno	\N	23	\N	\N	\N	\N
2372	Samuel Abawa	Samuel	Abawa	\N	23	\N	\N	\N	\N
2373	Peter Thiongo	Peter	Thiongo	\N	23	\N	\N	\N	\N
2374	George Oporia	George	Oporia	\N	23	\N	\N	\N	\N
2375	Daniel Waweru	Daniel	Waweru	\N	23	\N	\N	\N	\N
2376	Clifford Alwanga	Clifford	Alwanga	\N	23	\N	\N	\N	\N
2377	Leonard Kasembeli	Leonard	Kasembeli	\N	23	\N	\N	\N	\N
2378	John Makwatta	John	Makwatta	\N	23	\N	\N	\N	\N
2379	Rodgers Aloro	Rodgers	Aloro	\N	23	\N	\N	\N	\N
2380	Luke Namanda	Luke	Namanda	\N	23	\N	\N	\N	\N
2381	Ismeal Akwasi Afriye	Ismeal	Afriye	\N	23	\N	\N	\N	\N
2382	Lawrence Juma	Lawrence	Juma	\N	23	\N	\N	\N	\N
2383	Timonah Wanyonyi	Timonah	Wanyonyi	\N	23	\N	\N	\N	\N
2384	Brian Nyakan	Brian	Nyakan	\N	23	\N	\N	\N	\N
2385	Samson B Mbangula	Samson	Mbangula	\N	56	\N	\N	\N	\N
2386	Menz Chili	Menz	Chili	\N	56	\N	\N	\N	\N
2387	Ezekia Mwashilindi	Ezekia	Mwashilindi	\N	56	\N	\N	\N	\N
2388	Issah Noah	Issah	Noah	\N	56	\N	\N	\N	\N
2389	Ibrahim Mwakamele	Ibrahim	Mwakamele	\N	56	\N	\N	\N	\N
2390	Sadney Khoetage	Sadney	Khoetage	\N	11	\N	\N	\N	\N
2391	John Makwata	John	Makwata	\N	23	\N	\N	\N	\N
2392	Moses Mwangi	Moses	Mwangi	\N	23	\N	\N	\N	\N
2393	Enosh Ochieng	Enosh	Ochieng	\N	23	\N	\N	\N	\N
2394	Jesse Were	Jesse	Were	\N	47	\N	\N	\N	\N
2395	Abdul-aziz Makame	Abdul-aziz	Makame	\N	56	\N	\N	\N	\N
2396	Chilo Mkama	Chilo	Mkama	\N	56	\N	\N	\N	\N
2397	Ally Ramadhani	Ally	Ramadhani	\N	56	\N	\N	\N	\N
2398	kameta kameta	kameta	kameta	\N	56	\N	\N	\N	\N
2399	David Molinga	David	Molinga	\N	56	\N	\N	\N	\N
2400	Mike Madoya	Mike	Madoya	\N	23	\N	\N	\N	\N
2401	Hillary Wandera	Hillary	Wandera	\N	23	\N	\N	\N	\N
2402	Hassan Kiyoyo	Hassan	Kiyoyo	\N	23	\N	\N	\N	\N
2403	Vitalis Akumu	Vitalis	Akumu	\N	23	\N	\N	\N	\N
2404	Michael Owino	Michael	Owino	\N	23	\N	\N	\N	\N
2405	Soter Kayumba	Soter	Kayumba	\N	23	\N	\N	\N	\N
2406	Tresor Ndikumana	Tresor	Ndikumana	\N	39	\N	\N	\N	\N
2407	Francis Nambute	Francis	Nambute	\N	23	\N	\N	\N	\N
2408	Shaban Kenga	Shaban	Kenga	\N	23	\N	\N	\N	\N
2409	Duke Abuya	Duke	Abuya	\N	23	\N	\N	\N	\N
2410	Patilla Omoto	Patilla	Omoto	\N	23	\N	\N	\N	\N
2411	Bernard Ochieng	Bernard	Ochieng	\N	23	\N	\N	\N	\N
2412	Kevin Kimani	Kevin	Kimani	\N	23	\N	\N	\N	\N
2413	Victor Ndinya	Victor	Ndinya	\N	23	\N	\N	\N	\N
2414	Derrick Onyango	Derrick	Onyango	\N	23	\N	\N	\N	\N
2415	Martin Nderitu	Martin	Nderitu	\N	23	\N	\N	\N	\N
2416	Cercidy Okeyo	Cercidy	Okeyo	\N	23	\N	\N	\N	\N
2417	William Wadri	William	Wadri	\N	23	\N	\N	\N	\N
2418	David Odhiambo Okoth	David	Okoth	\N	23	\N	\N	\N	\N
2419	David Majak	David	Majak	\N	23	\N	\N	\N	\N
2420	George Ogutu	George	Ogutu	\N	23	\N	\N	\N	\N
2421	Hashim Manyanya	Hashim	Manyanya	\N	56	\N	\N	\N	\N
2422	Jordan John	Jordan	John	\N	56	\N	\N	\N	\N
2423	Hamis Shaban	Hamis	Shaban	\N	56	\N	\N	\N	\N
2424	Marcel Kaheza	Marcel	Kaheza	\N	56	\N	\N	\N	\N
2425	Erick Msagati	Erick	Msagati	\N	56	\N	\N	\N	\N
2426	Stephen Opoku	Stephen	Opoku	\N	20	\N	\N	\N	\N
2427	Msafiri Mkumbo	Msafiri	Mkumbo	\N	56	\N	\N	\N	\N
2428	Gilbert Mwale	Gilbert	Mwale	\N	58	\N	\N	\N	\N
2429	Pius Luchangula	Pius	Luchangula	\N	56	\N	\N	\N	\N
2430	Meshack Kibonna	Meshack	Kibonna	\N	56	\N	\N	\N	\N
2431	David Nartey	David	Nartey	\N	20	\N	\N	\N	\N
2432	Methew Michel	Methew	Michel	\N	56	\N	\N	\N	\N
2433	Ramadhan Ntobi Yego	Ramadhan	Yego	\N	56	\N	\N	\N	\N
2434	Ally Kombo	Ally	Kombo	\N	56	\N	\N	\N	\N
2435	Agrey Stephen	Agrey	Stephen	\N	56	\N	\N	\N	\N
2436	Deogratius Kanda	Deogratius	Kanda	\N	56	\N	\N	\N	\N
2437	Serge Nogues	Serge	Nogues	\N	20	\N	\N	\N	\N
2438	Nzigamasabo Styve	Nzigamasabo	Styve	\N	4	\N	\N	\N	\N
2439	John Kelvin	John	Kelvin	\N	56	\N	\N	\N	\N
2440	Juma Kaseja	Juma	Kaseja	\N	56	\N	\N	\N	\N
2441	Gabadinho Mhango	Gabadinho	Mhango	\N	28	\N	\N	\N	\N
2442	Vianney Mabide	Vianney	Mabide	\N	7	\N	\N	\N	\N
2443	Louis Mafouta	Louis	Mafouta	\N	7	\N	\N	\N	\N
2444	Kwame Quee	Kwame	Quee	\N	44	\N	\N	\N	\N
2445	Thaba Jane Ntso	Thaba	Ntso	\N	24	\N	\N	\N	\N
2446	Adoassou Matthieu	Adoassou	Matthieu	\N	8	\N	\N	\N	\N
2447	Ezechiel Ndouassel	Ezechiel	Ndouassel	\N	8	\N	\N	\N	\N
2448	Chris Katjiukua	Chris	Katjiukua	\N	34	\N	\N	\N	\N
2449	Jorge Intima	Jorge	Intima	\N	37	\N	\N	\N	\N
2450	Piqueti Djassi Brito Silva	Piqueti	Silva	\N	37	\N	\N	\N	\N
2451	Joao Mario	Joao	Mario	\N	37	\N	\N	\N	\N
2452	Ramadan Agab	Ramadan	Agab	\N	1	\N	\N	\N	\N
2453	Ahmed Hamed Eltetsh	Ahmed	Eltetsh	\N	49	\N	\N	\N	\N
2454	Mohamed El-Rashee	Mohamed	El-Rashee	\N	49	\N	\N	\N	\N
2455	Jordao Diogo	Jordao	Diogo	\N	41	\N	\N	\N	\N
2456	Sidy Sarr	Sidy	Sarr	\N	42	\N	\N	\N	\N
2457	Habibou Mouhamadou Diallo	Habibou	Diallo	\N	42	\N	\N	\N	\N
2458	Harvy Ossete	Harvy	Ossete	\N	11	\N	\N	\N	\N
2459	Assan Ceesay	Assan	Ceesay	\N	19	\N	\N	\N	\N
2460	Sulayman Marreh	Sulayman	Marreh	\N	19	\N	\N	\N	\N
2461	Wilson Eduardo	Wilson	Eduardo	\N	2	\N	\N	\N	\N
2462	Faiz Selemanie	Faiz	Selemanie	\N	9	\N	\N	\N	\N
2463	Stélio Marcelino Ernesto Telinho	Stélio	Ernesto	\N	33	\N	\N	\N	\N
2464	Edson Mexer	Edson	Mexer	\N	33	\N	\N	\N	\N
2465	Edson Mexer	Edson	Mexer	\N	33	\N	\N	\N	\N
2466	Mahmoud Kahraba	Mahmoud	Kahraba	\N	55	\N	\N	\N	\N
2467	Sekou Koita	Sekou	Koita	\N	29	\N	\N	\N	\N
2468	Sekou Conde	Sekou	Conde	\N	21	\N	\N	\N	\N
2469	Mohammed Kudus	Mohammed	Kudus	\N	20	\N	\N	\N	\N
2470	El Arbi Soudani	El Arbi	Soudani	\N	1	\N	\N	\N	\N
2471	Pedro Obiang	Pedro	Obiang	\N	14	\N	\N	\N	\N
2472	Salum Abubakar	Salum	Abubakar	\N	56	\N	\N	\N	\N
2473	Saif-Eddine Khaoui	Saif-Eddine	Khaoui	\N	53	\N	\N	\N	\N
2474	Hamdou Elhouni	Hamdou	Elhouni	\N	26	\N	\N	\N	\N
2475	Moussa Djenepo	Moussa	Djenepo	\N	29	\N	\N	\N	\N
2476	Aristide Bance	Aristide	Bance	\N	57	\N	\N	\N	\N
2477	Lebogang Phiri	Lebogang	Phiri	\N	46	\N	\N	\N	\N
2478	Mohamed Camara	Mohamed	Camara	\N	29	\N	\N	\N	\N
2479	Fahad Bayo	Fahad	Bayo	\N	54	\N	\N	\N	\N
2480	Famara Diedhiou	Famara	Diedhiou	\N	42	\N	\N	\N	\N
2481	Fganelo Mamba	Fganelo	Mamba	\N	51	\N	\N	\N	\N
2482	Fganelo Mamba	Fganelo	Mamba	\N	51	\N	\N	\N	\N
2483	Prince Vinny Ibara Doniama	Prince	Ibara	\N	11	\N	\N	\N	\N
2484	Masoabi Nkoto	Masoabi	Nkoto	\N	24	\N	\N	\N	\N
2485	Ngoumo Ngamaleu	Ngoumo	Ngamaleu	\N	5	\N	\N	\N	\N
2486	Anthony Mfa Mezui	Anthony	Mezui	\N	18	\N	\N	\N	\N
2487	Wilfried Abessolo	Wilfried	Abessolo	\N	18	\N	\N	\N	\N
2488	Aaron Appidangoye	Aaron	Appidangoye	\N	18	\N	\N	\N	\N
2489	Pierre Emerick Aubameyang	Pierre	Aubameyang	\N	18	\N	\N	\N	\N
2490	Denis Bouanga	Denis	Bouanga	\N	18	\N	\N	\N	\N
2491	Aaron Boupendza	Aaron	Boupendza	\N	18	\N	\N	\N	\N
2492	Bruno Ecuele Manga	Bruno	Manga	\N	18	\N	\N	\N	\N
2493	Guelor Kanga	Guelor	Kanga	\N	18	\N	\N	\N	\N
2494	Mario Lemina	Mario	Lemina	\N	18	\N	\N	\N	\N
2495	Didier Ndong	Didier	Ndong	\N	18	\N	\N	\N	\N
2496	Lloyd Palun	Lloyd	Palun	\N	18	\N	\N	\N	\N
2497	Fabio Abreu	Fabio	Abreu	\N	2	\N	\N	\N	\N
2498	Adriano Belmiro Duarte Nicolaou	Adriano	Duarte	\N	2	\N	\N	\N	\N
2499	Garry Rodrigues	Garry	Rodrigues	\N	6	\N	\N	\N	\N
2500	Ryan Mendes	Ryan	Mendes	\N	6	\N	\N	\N	\N
2501	Witiness Chimoio João Quembo	Witiness	Quembo	\N	33	\N	\N	\N	\N
2502	Hakim Ouro-Sama	Hakim	Ouro-Sama	\N	52	\N	\N	\N	\N
2503	Futty Danso	Futty	Danso	\N	19	\N	\N	\N	\N
2504	Pa Modou	Pa	Modou	\N	19	\N	\N	\N	\N
2505	Jackson Muleka	Jackson	Muleka	\N	12	\N	\N	\N	\N
2506	Diallo Guidileye	Diallo	Guidileye	\N	30	\N	\N	\N	\N
2507	Amadou Wonkoye	Amadou	Wonkoye	\N	35	\N	\N	\N	\N
2508	Yussif Moussa	Yussif	Moussa	\N	35	\N	\N	\N	\N
2509	Paulin Voavy	Paulin	Voavy	\N	27	\N	\N	\N	\N
2510	Patson Daka	Patson	Daka	\N	58	\N	\N	\N	\N
2511	Surafel Dagnachew	Surafel	Dagnachew	\N	15	\N	\N	\N	\N
2512	Surafel Dagnachew	Surafel	Dagnachew	\N	15	\N	\N	\N	\N
2513	Surafel Dagnachew	Surafel	Dagnachew	\N	15	\N	\N	\N	\N
2514	Farouk Shikhalo shikhalo	Farouk	shikhalo	\N	56	\N	\N	\N	\N
2515	Raphael Aloba	Raphael	Aloba	\N	56	\N	\N	\N	\N
2516	Juma Balinya	Juma	Balinya	\N	56	\N	\N	\N	\N
2517	Andrea Raymond	Andrea	Raymond	\N	56	\N	\N	\N	\N
2518	Iddy Mobby	Iddy	Mobby	\N	56	\N	\N	\N	\N
2519	Johnstone Omurwa	Johnstone	Omurwa	\N	23	\N	\N	\N	\N
2520	Arabe Gershom	Arabe	Gershom	\N	23	\N	\N	\N	\N
2521	Jobita Baron Oketch	Jobita	Oketch	\N	23	\N	\N	\N	\N
2522	Emmanuel Maziku	Emmanuel	Maziku	\N	56	\N	\N	\N	\N
2523	Tairone Da Silva	Tairone	Da Silva	\N	56	\N	\N	\N	\N
2524	John Mwita	John	Mwita	\N	23	\N	\N	\N	\N
2525	Mwinyi Shami Kibwana	Mwinyi	Kibwana	\N	23	\N	\N	\N	\N
2526	Ian Motanda	Ian	Motanda	\N	23	\N	\N	\N	\N
2527	Ronald Okoth	Ronald	Okoth	\N	23	\N	\N	\N	\N
2528	Daniel Otieno	Daniel	Otieno	\N	23	\N	\N	\N	\N
2529	Hassan Abdallah	Hassan	Abdallah	\N	23	\N	\N	\N	\N
2530	Brian Otieno	Brian	Otieno	\N	23	\N	\N	\N	\N
2531	Kevin Omundi	Kevin	Omundi	\N	23	\N	\N	\N	\N
2532	Bonaventure Atse	Bonaventure	Atse	\N	23	\N	\N	\N	\N
2533	Derrick Otanga	Derrick	Otanga	\N	23	\N	\N	\N	\N
2534	Ian Simiyu	Ian	Simiyu	\N	23	\N	\N	\N	\N
2535	Norman Werunga	Norman	Werunga	\N	23	\N	\N	\N	\N
2536	Moses Chikati	Moses	Chikati	\N	23	\N	\N	\N	\N
2537	Ali Bali	Ali	Bali	\N	23	\N	\N	\N	\N
2538	Charles Odete	Charles	Odete	\N	23	\N	\N	\N	\N
2539	Joseph Mbugi	Joseph	Mbugi	\N	23	\N	\N	\N	\N
2540	Amani Kyata	Amani	Kyata	\N	23	\N	\N	\N	\N
2541	Reagan Otieno	Reagan	Otieno	\N	23	\N	\N	\N	\N
2542	Chris Oduor	Chris	Oduor	\N	23	\N	\N	\N	\N
2543	Salim Chacha	Salim	Chacha	\N	23	\N	\N	\N	\N
2544	Yikpe Ghislain	Yikpe	Ghislain	\N	23	\N	\N	\N	\N
2545	Clifton Miheso	Clifton	Miheso	\N	23	\N	\N	\N	\N
2546	Oscar Musa Wamalwa	Oscar	Wamalwa	\N	23	\N	\N	\N	\N
2547	Kepha Aswani	Kepha	Aswani	\N	23	\N	\N	\N	\N
2548	Joe Waithira	Joe	Waithira	\N	23	\N	\N	\N	\N
2549	Dominic Ouma	Dominic	Ouma	\N	23	\N	\N	\N	\N
2550	Ibrahim Gaetan Masha	Ibrahim	Masha	\N	23	\N	\N	\N	\N
2551	Marcellus Ingotsi	Marcellus	Ingotsi	\N	23	\N	\N	\N	\N
2552	Erick Otieno	Erick	Otieno	\N	23	\N	\N	\N	\N
2553	Abdalla Wankuru	Abdalla	Wankuru	\N	23	\N	\N	\N	\N
2554	Henry Onyango	Henry	Onyango	\N	23	\N	\N	\N	\N
2555	Humphrey Mieno	Humphrey	Mieno	\N	23	\N	\N	\N	\N
2556	Sydney Lokale	Sydney	Lokale	\N	23	\N	\N	\N	\N
2557	Harun Mwale	Harun	Mwale	\N	23	\N	\N	\N	\N
2558	Jaffari Owiti	Jaffari	Owiti	\N	23	\N	\N	\N	\N
2559	Vincent Oburu	Vincent	Oburu	\N	23	\N	\N	\N	\N
2560	Sosthenes Idah	Sosthenes	Idah	\N	23	\N	\N	\N	\N
2561	Cliff Kasuti	Cliff	Kasuti	\N	23	\N	\N	\N	\N
2562	Festus Okiring	Festus	Okiring	\N	23	\N	\N	\N	\N
2563	David Simiyu	David	Simiyu	\N	23	\N	\N	\N	\N
2564	James Kinyanjui	James	Kinyanjui	\N	23	\N	\N	\N	\N
2565	Felicien Okanda	Felicien	Okanda	\N	23	\N	\N	\N	\N
2566	John Njuguna	John	Njuguna	\N	23	\N	\N	\N	\N
2567	Whyvonne Isuza	Whyvonne	Isuza	\N	23	\N	\N	\N	\N
2568	Adilly Buha	Adilly	Buha	\N	56	\N	\N	\N	\N
2569	Benson Omala	Benson	Omala	\N	23	\N	\N	\N	\N
2570	Adam Kiondo	Adam	Kiondo	\N	56	\N	\N	\N	\N
2571	Lamine Moro	Lamine	Moro	\N	42	\N	\N	\N	\N
2572	Simon Munala	Simon	Munala	\N	23	\N	\N	\N	\N
2573	Julius Masaba	Julius	Masaba	\N	23	\N	\N	\N	\N
2574	Boniface Mukhekhe	Boniface	Mukhekhe	\N	23	\N	\N	\N	\N
2575	Samuel Mwangi	Samuel	Mwangi	\N	23	\N	\N	\N	\N
2576	Thomas Wainaina	Thomas	Wainaina	\N	23	\N	\N	\N	\N
2577	Abraham Kipkogei	Abraham	Kipkogei	\N	23	\N	\N	\N	\N
2578	Austin Makacha	Austin	Makacha	\N	23	\N	\N	\N	\N
2579	Pistone Mutamba	Pistone	Mutamba	\N	23	\N	\N	\N	\N
2580	Eric Ambunya	Eric	Ambunya	\N	23	\N	\N	\N	\N
2581	Salim Hamisi	Salim	Hamisi	\N	23	\N	\N	\N	\N
2582	Denis Ongeri	Denis	Ongeri	\N	23	\N	\N	\N	\N
2583	Christopher Mbehelo Masinza	Christopher	Masinza	\N	23	\N	\N	\N	\N
2584	Stephen Mukongolo Wakanya	Stephen	Wakanya	\N	23	\N	\N	\N	\N
2585	James Mazembe	James	Mazembe	\N	23	\N	\N	\N	\N
2586	Lloyd Kinguru	Lloyd	Kinguru	\N	23	\N	\N	\N	\N
2587	Bernard Ondiek	Bernard	Ondiek	\N	23	\N	\N	\N	\N
2588	Marcelo Boniventure	Marcelo	Boniventure	\N	56	\N	\N	\N	\N
2589	Erick Okorai	Erick	Okorai	\N	56	\N	\N	\N	\N
2590	Abdul Hassan	Abdul	Hassan	\N	56	\N	\N	\N	\N
2591	Enock Mkanga	Enock	Mkanga	\N	56	\N	\N	\N	\N
2592	Edson Katanga	Edson	Katanga	\N	56	\N	\N	\N	\N
2593	Kelvin Sabato Sabato sabato	Kelvin	Sabato	\N	56	\N	\N	\N	\N
2594	Never Tigere	Never	Tigere	\N	47	\N	\N	\N	\N
2595	Benard Morrison	Benard	Morrison	\N	20	\N	\N	\N	\N
\.


--
-- Data for Name: reconciliation_diffs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.reconciliation_diffs (id, reconciliation_run_id, entity_id_a, entity_id_b, field_name, value_a, value_b, resolution, resolved_value, resolved_at) FROM stdin;
\.


--
-- Data for Name: reconciliation_runs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.reconciliation_runs (id, entity_type, data_source_a_id, data_source_b_id, run_at, notes) FROM stdin;
\.


--
-- Data for Name: seasons; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.seasons (id, label, start_date, end_date) FROM stdin;
1	2017/2018	\N	\N
2	2016/2017	\N	\N
3	2018/2019	\N	\N
4	2019/2020	\N	\N
\.


--
-- Data for Name: stadiums; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.stadiums (id, name, city, country_id, capacity, latitude, longitude) FROM stdin;
1	Uhuru Stadium	Morogoro	56	\N	\N	\N
2	Chamazi	Dar es Salaam	56	\N	\N	\N
3	Mkwawani	Tanga	56	\N	\N	\N
4	Mabatini	Pwani	56	\N	\N	\N
5	Kaitaba	Kagera	56	\N	\N	\N
6	Sokoine	Mbeya	56	\N	\N	\N
7	Mkwawani	Tanga	56	\N	\N	\N
8	Manungu	Morogoro	56	\N	\N	\N
9	Nangwanda	Mtwara	56	\N	\N	\N
10	Jamuhuri	Morogoro	56	\N	\N	\N
11	Uhuru	Dar es salaam	56	\N	\N	\N
12	National Stadium	Dar es Salaam	56	\N	\N	\N
13	Kambarage	Shinyanga	56	\N	\N	\N
14	Sokoine	Mbeya	56	\N	\N	\N
16	Mkwakwani	Tanga	56	\N	\N	\N
17	Maji Maji Stadium	Ruvuma	56	\N	\N	\N
18	Mwadui	Shinyanga	56	\N	\N	\N
19	CCM Kirumba	Mwanza	56	\N	\N	\N
20	Saba saba 	Njombe	56	\N	\N	\N
21	Samora	Iringa	56	\N	\N	\N
22	Namfua	Singida	56	\N	\N	\N
23	Stade de l'Amitié	Benin	13	\N	\N	\N
24	Kenya	Kenya	56	\N	\N	\N
25	Stade Goulade	Djibout	17	\N	\N	\N
26	Stade Elinite	Seychelles	43	\N	\N	\N
27	Stade du 5 Juillet	Algeria	1	\N	\N	\N
28	MAJ.GEN.ISAMUHYO	Dar es salaam	56	\N	\N	\N
29	Nyamaghana	Mwanza	56	\N	\N	\N
30	Karume stadium	Musoma	56	\N	\N	\N
32	SH. AMRI ABEID	Arusha	56	\N	\N	\N
33	Waja Secondary	Geita	56	\N	\N	\N
34	Amaan Stadium	Zanzibar	56	\N	\N	\N
35	Jamhuri	Dodoma	56	\N	\N	\N
36	Ali Hassan Mwinyi	Tabora	56	\N	\N	\N
37	Ushirika	Moshi	56	\N	\N	\N
38	Bomang'ombe	Kilimanjaro	56	\N	\N	\N
39	Bandari	Dar es salaam	56	\N	\N	\N
40	Majaliwa Stadium	Lindi	56	\N	\N	\N
41	Filbert Bayi Stadium	Pwani	56	\N	\N	\N
42	Ilulu Stadium	Lindi	56	\N	\N	\N
43	Kinesi Stadium	Dar es salaam	56	\N	\N	\N
44	Singe Secondary Stadium	Babati	56	\N	\N	\N
45	Tukuyu Stadium	Mbeya	56	\N	\N	\N
46	Highland Estate 	Mbeya	56	\N	\N	\N
47	Kabanga Secondary 	Kagera	56	\N	\N	\N
48	Kahama Stadium	Shinyanga	56	\N	\N	\N
49	CCM Mkamba Stadium	Morogoro	56	\N	\N	\N
50	Kibaigwa Stadium	Dodoma	56	\N	\N	\N
51	Kasulu Teaching College	Kigoma	56	\N	\N	\N
52	Nyankumbu Secondary Stadium	Geita	56	\N	\N	\N
\.


--
-- Data for Name: teams; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.teams (id, name, short_name, type, country_id, stadium_id, founded_year, logo_url) FROM stdin;
1	Azam FC	AZM	CLUB	56	2	\N	1.png
2	Mbao FC	MBA	CLUB	56	\N	\N	2.png
3	JKT Tanzania	JKT	CLUB	56	28	\N	3.png
4	Kagera Sugar	KGR	CLUB	56	\N	\N	4.png
5	Mbeya City	MBY	CLUB	56	14	\N	5.png
6	African Lyon	AFL	CLUB	56	\N	\N	africanLyon.1531999258.jpeg
7	Mtibwa Sugar	MTB	CLUB	56	\N	\N	7.png
8	Ndanda FC	NDA	CLUB	56	\N	\N	8.png
9	Polisi Morogoro	MOR	CLUB	56	\N	\N	9.png
11	Simba SC	SMB	CLUB	56	12	\N	11.png
12	Stand United	STN	CLUB	56	\N	\N	121532003550.png
13	Tanzania Prisons	PRS	CLUB	56	\N	\N	13.png
15	Ruvu Shooting	RVS	CLUB	56	\N	\N	ruvushooting1534967984.png
16	Maji Maji FC	MAJ	CLUB	56	\N	\N	17.png
17	Mwadui FC	MWA	CLUB	56	\N	\N	61532003647.png
18	Toto African	TOT	CLUB	56	\N	\N	15.png
23	Taifa Stars	TZ	NATIONAL	56	1	\N	index1561227063.jpg
24	Swaziland	ESW	NATIONAL	51	\N	\N	Swaziland1573945250.png
25	Madagascar	MDC	NATIONAL	27	17	\N	2246-004-9002B3311561231517.jpg
26	Lesotho	LES	NATIONAL	24	\N	\N	lesotho1573942703.png
27	Egypt	EGY	NATIONAL	55	\N	\N	EGY1561240226.png
28	Namibia	NMB	NATIONAL	34	\N	\N	flag-wave-2501561238939.png
29	Seychelles	SEY	NATIONAL	43	\N	\N	images1573942813.jpg
30	Zimbabwe	ZIM	NATIONAL	47	\N	\N	zw1561240290.png
31	Mauritius	MAU	NATIONAL	31	\N	\N	Mauritius1573942884.png
32	South Africa	RSA	NATIONAL	46	\N	\N	index1561328428.png
33	Ghana	GHN	NATIONAL	20	\N	\N	flag-4001561328622.png
34	Mozambique	MOZ	NATIONAL	33	\N	\N	Mozambique1573942945.png
35	Malawi	MLW	NATIONAL	28	\N	\N	Malawi1573943019.png
36	Botswana	BOT	NATIONAL	3	\N	\N	Botswana1573943117.png
37	Zambia	ZAM	NATIONAL	58	\N	\N	Zambia1573943170.jpg
38	Rwanda	RWA	NATIONAL	39	\N	\N	Rwanda1573943252.png
39	Nigeria	NGA	NATIONAL	36	\N	\N	NGA1561239964.png
40	Uganda	UGA	NATIONAL	54	\N	\N	UG1561240045.png
41	Gambia	GAM	NATIONAL	19	\N	\N	Gambia1573943338.png
42	Guinea-Bissau	GBU	NATIONAL	37	\N	\N	gw1561328559.png
43	Angola	ANG	NATIONAL	2	\N	\N	angola1559387230.png
44	Central African Republic	CAR	NATIONAL	7	\N	\N	Central African Republic1573943423.png
45	Chad	CHA	NATIONAL	8	\N	\N	Chad1573943528.jpg
46	Cape Verde	CDE	NATIONAL	6	\N	\N	Cape Verde1573943627.png
47	São Tomé and Príncipe	STP	NATIONAL	41	\N	\N	Sao Tome1573943919.png
48	Burkina Faso	BFO	NATIONAL	57	\N	\N	Burkina Faso1573944007.png
49	Comoros	CMS	NATIONAL	9	\N	\N	Comoros1573944061.png
50	Mali	MAL	NATIONAL	29	\N	\N	MA;LI1561239662.png
51	South Sudan	SSN	NATIONAL	48	\N	\N	South Sudan1573944160.jpg
52	Senegal	SEN	NATIONAL	42	\N	\N	900px-Flag_of_Senegal.svg1561239040.png
53	Burundi	BUR	NATIONAL	4	\N	\N	2000px-Flag_of_Burundi.svg1561220929.png
54	Algeria	ALG	NATIONAL	1	\N	\N	ag-lgflag1561239156.gif
55	Ethiopia	ETH	NATIONAL	15	\N	\N	Ethiopia1573944264.jpg
56	Togo	TOG	NATIONAL	52	\N	\N	Togo1573944330.gif
57	Liberia	LIB	NATIONAL	25	\N	\N	Liberia1573944446.png
58	Cameroon	CRN	NATIONAL	5	\N	\N	flag-4001561328493.png
59	Mauritania	MAU	NATIONAL	30	\N	\N	255px-Flag_of_Mauritania.svg1561239788.png
60	Congo	CON	NATIONAL	11	\N	\N	Congo1573944534.png
61	DR Congo	DRC	NATIONAL	12	\N	\N	cd1561240099.png
62	Kenya	KEN	NATIONAL	23	\N	\N	kenya1561239235.jpg
63	Equtorial Guinea	EGA	NATIONAL	14	\N	\N	Equtorial Guinea1573944609.png
64	Benin	BNN	NATIONAL	13	\N	\N	1280px-Flag_of_Benin.svg1561328683.png
65	Niger	NGR	NATIONAL	35	\N	\N	Niger1573944754.png
66	Gabon	GAB	NATIONAL	18	\N	\N	Gabon1573944807.png
69	Ivory Coast	COT	NATIONAL	22	\N	\N	200px-Flag_of_Côte_d'Ivoire.svg1561239421.png
70	Sudan	SUD	NATIONAL	49	\N	\N	Sudan1573944919.jpg
71	Sierra Leon	SLN	NATIONAL	44	\N	\N	Sierra Leon1573945167.png
72	KMKM	\N	CLUB	56	\N	\N	72.png
73	APR	\N	CLUB	56	\N	\N	73.png
74	GorMahia	\N	CLUB	56	\N	\N	74.png
75	Al-Shandy	\N	CLUB	56	\N	\N	75.png
76	Yanga SC	YNG	CLUB	56	\N	\N	76.png
77	LLB FC	\N	CLUB	56	\N	\N	77.png
78	Heegan FC	\N	CLUB	56	\N	\N	78.png
80	Malakia	\N	CLUB	56	\N	\N	80.png
81	Adama City	\N	CLUB	56	\N	\N	81.png
82	KCCA	\N	CLUB	56	\N	\N	82.png
83	Telecom	\N	CLUB	56	\N	\N	83.png
84	Al-Khartoum	\N	CLUB	56	\N	\N	84.png
85	URA FC	URA	CLUB	20	\N	\N	ura.png
86	Njombe Mji FC	NJM	CLUB	56	\N	\N	njombe.jpg
87	Lipuli FC	LPL	CLUB	56	\N	\N	16.png
88	Singida United	SND	CLUB	56	\N	\N	151532003588.png
89	Libya	LYA	NATIONAL	26	\N	\N	Libya1573945012.gif
90	Zanzibar	ZNZ	NATIONAL	59	\N	\N	Zanzibar1573945064.png
91	Tanzania	TZ	NATIONAL	56	12	\N	1280px-Flag_of_Tanzania.svg1561239095.png
92	Saint Louis	STL	CLUB	43	12	\N	download1518267334.png
93	Gendarmerie FC	GNM	CLUB	17	12	\N	11518334284.png
94	Al-Masry SC	ASC	CLUB	55	25	\N	AL MASRY1559387516.png
95	Township Rollers	TRFC	CLUB	3	25	\N	tr.png
96	Welayta Dicha	WDFC	CLUB	15	26	\N	wltd.png
97	USM Alger	USM	CLUB	1	23	\N	index1566920854.png
98	Rayon Sports FC	RSFC	CLUB	39	25	\N	rayonsports.png
99	Alliance FC	ALL	CLUB	56	19	\N	Alliance logo1534967785.png
100	Coastal Union	COA	CLUB	56	3	\N	coastal1531986034.png
101	Biashara United	BIA	CLUB	56	19	\N	BIASHARA LOGO1535195423.png
102	KMC FC	KMC	CLUB	56	1	\N	kmc fc logo1534967858.jpg
103	Morroco	MOR	NATIONAL	32	26	\N	shutterstock-7426382831561238895.jpg
104	Guinea	GUI	NATIONAL	21	25	\N	gnlarge1561231456.gif
105	Tunisia	TUN	NATIONAL	53	23	\N	flag-4001561239590.png
106	Chipukizi	CHI	CLUB	59	32	\N	\N
107	Mlandege	MLA	CLUB	59	32	\N	\N
108	KVZ	KVZ	CLUB	59	32	\N	\N
109	Malindi	MAL	CLUB	23	32	\N	\N
110	Jamuhuri	JAM	CLUB	59	32	\N	\N
111	ASEC Mimosas	ASEC	CLUB	22	23	\N	asec1546968432.png
112	Lobi Stars	LOB	CLUB	36	26	\N	lobi.1546968518.jpeg
113	Mamelodi Sundowns	MAM	CLUB	46	23	\N	mamelodi1546968636.png
114	WAC Casablanca	WAC	CLUB	32	23	\N	wac1546968840.png
115	ES Tunis	ESP	CLUB	53	25	\N	ES1546968912.png
116	Horoya FC	HOR	CLUB	21	23	\N	horoya1546969115.png
117	Orlando Pirates	ORL	CLUB	46	23	\N	orlando.1546969180.jpeg
118	F.C. Platinum	PLA	CLUB	47	23	\N	platinum.1546969248.jpeg
119	CS Constantine	CON	CLUB	1	23	\N	constantine.1546969316.jpeg
120	Club Africain	AFR	CLUB	53	23	\N	africain.1546969955.jpeg
121	Ismaily SC	ISM	CLUB	55	23	\N	ismaily.1546970224.jpeg
122	TP Mazembe	MAZ	CLUB	12	23	\N	mazembe.1546970298.jpeg
123	Al Ahly SC	AHL	CLUB	55	23	\N	alhaly1546970435.png
124	JS Saoura	SAO	CLUB	1	23	\N	saoura1546970518.png
125	Vita Club	VIT	CLUB	12	23	\N	VITA1546970635.png
126	AFC Leopards	LEO	CLUB	23	26	\N	leop.1548081201.jpeg
127	Bandari F.C.	BAN	CLUB	23	26	\N	bandari.1548080909.jpeg
128	Kariobangi Sharks	KAR	CLUB	23	26	\N	kario1548080976.png
129	Angola-U17	ANG	NATIONAL	2	23	\N	ang1555237734.png
130	Nigeria-U17	NIG	NATIONAL	36	23	\N	nigeria1555237815.png
131	Tanzania-U17	TAN	NATIONAL	56	12	\N	tz1555238486.png
132	Uganda-U17	UG	NATIONAL	54	23	\N	ug1555238546.png
133	Cameroon-U17	CAM	NATIONAL	5	23	\N	cam1555238616.png
134	Guinea-U17	GUI	NATIONAL	21	23	\N	gui1555238663.png
135	Morroco-U17	MOR	NATIONAL	32	23	\N	mor1555238718.png
136	Senegal-U17	SEN	NATIONAL	42	23	\N	sen1555238821.png
137	Mabibo FC	MBB	CLUB	56	1	\N	mZmCD5u4_400x4001557226659.jpg
138	Msewe FC	MFC	CLUB	56	1	\N	mZmCD5u4_400x4001557226710.jpg
139	Friens Rangers	FR	CLUB	56	1	\N	mZmCD5u4_400x4001557227138.jpg
140	Mwenge Kombaini	MK	CLUB	56	1	\N	mZmCD5u4_400x4001557227196.jpg
141	Atletico Mabibo	ADM	CLUB	56	1	\N	mZmCD5u4_400x4001557227274.jpg
142	Dili chuma	DC FC	CLUB	56	1	\N	mZmCD5u4_400x4001557227365.jpg
143	Stimu Tosha	STFC	CLUB	56	1	\N	mZmCD5u4_400x4001557228272.jpg
144	Sinza United	SU	CLUB	56	1	\N	mZmCD5u4_400x4001557228414.jpg
145	Ubungo Kombaini	UK	CLUB	56	1	\N	mZmCD5u4_400x4001557228463.jpg
146	Mbeya Boys	MB	CLUB	56	1	\N	mZmCD5u4_400x4001557228506.jpg
147	Mamu Phamacy	MP	CLUB	56	1	\N	mZmCD5u4_400x4001557228595.jpg
148	Katabazi FC	KTBFC	CLUB	56	1	\N	mZmCD5u4_400x4001557228673.jpg
149	Goba Ham FC	GMFC	CLUB	56	1	\N	mZmCD5u4_400x4001557233208.jpg
150	Ukwakwani FC	UFC	CLUB	56	1	\N	mZmCD5u4_400x4001557234038.jpg
151	Rangers FC	RFC	CLUB	56	1	\N	mZmCD5u4_400x4001557234094.jpg
152	Taswa FC	TFC	CLUB	56	1	\N	mZmCD5u4_400x4001557234133.jpg
153	Navy Kenzo	NAVY	CLUB	56	1	\N	2tL-WdKu_400x4001557581891.jpg
154	Sifa United	SU	CLUB	56	1	\N	mZmCD5u4_400x4001557234254.jpg
155	Beira Hotspurs	BHS	CLUB	56	1	\N	mZmCD5u4_400x4001557234323.jpg
156	Magomeni Kombaini	MK	CLUB	56	19	\N	mZmCD5u4_400x4001557234427.jpg
157	Kichangani Kombaini	KK	CLUB	56	1	\N	mZmCD5u4_400x4001557234483.jpg
158	Kibada One	KO	CLUB	56	1	\N	mZmCD5u4_400x4001557234522.jpg
159	Ninga FC	NFC	CLUB	56	1	\N	mZmCD5u4_400x4001557234561.jpg
160	Kapten Sport Center	KSC	CLUB	56	1	\N	mZmCD5u4_400x4001557234629.jpg
161	Wauza Matairi	WM	CLUB	56	1	\N	mZmCD5u4_400x4001557234673.jpg
162	Chang'ombe Youth	CY	CLUB	56	1	\N	mZmCD5u4_400x4001557234945.jpg
163	Iron Eleven	IE	CLUB	56	1	\N	mZmCD5u4_400x4001557235260.jpg
164	Opec FC	OFC	CLUB	56	1	\N	mZmCD5u4_400x4001557235308.jpg
165	Sevilla	scl	CLUB	50	12	\N	images1558625956.png
166	Zamalek fc	Zfc	CLUB	55	27	\N	index1558869901.jpg
167	Rs berkane	RSB	CLUB	32	26	\N	indexerere1558870017.jpg
168	Namungo	NM	CLUB	56	22	\N	namungo1569006128.jpg
169	Polisi Tanzania	PTZ	CLUB	56	6	\N	polisi tz1569006276.jpg
170	Sofapaka	SOFC	CLUB	23	12	\N	index1563145802.jpg
171	Mathare Utd.	MUtd.	CLUB	23	12	\N	index1563145872.png
172	Green Eagles	GEFC	CLUB	58	12	\N	index1563279064.jpg
173	Minema union	MNFC	CLUB	11	12	\N	\N
174	Power dinamos fc	PDFC	CLUB	58	34	\N	index1565033095.jpg
175	Chemelil Sugar	csfc	CLUB	23	4	\N	chemelil-sugar1566407360.png
176	Kakamega Homeboyz	KKH	CLUB	23	4	\N	kakamega-homeboyz1566407468.png
177	KCB	KCBFC	CLUB	23	1	\N	kcb1566407757.png
178	Mathare United	MUFC	CLUB	23	1	\N	mathare-united1566407812.png
179	Nzoia United	NUFC	CLUB	23	1	\N	nzoia-united1566407863.png
180	Posta Rangers	PRSFC	CLUB	23	1	\N	posta-rangers1566407919.png
181	Ulinzi Stars	USL	CLUB	23	1	\N	ulinzi-stars1566407978.png
182	SoNy Sugar	SSFC	CLUB	23	1	\N	sony-sugar1566408169.png
183	Wazito FC	WFCDS	CLUB	23	1	\N	Wazito-FC-1567249078.png
184	Kisumu All Stars	KAS	CLUB	23	1	\N	Kisumu-All-Stars1567249051.jpg
185	Western Stima	WSFC	CLUB	23	1	\N	western-stima1566408308.png
186	Zoo Kericho	ZOO	CLUB	23	1	\N	zoo-kericho1566408369.png
187	Tusker FC	TFC	CLUB	23	1	\N	tusker-fc1566408496.png
188	AS Kigali	ASK	CLUB	39	12	\N	index1566562467.jpg
189	UD Songo	UDSN	CLUB	33	12	\N	index1566734207.png
190	Aigle Noir	AN	CLUB	4	12	\N	iVndex1566738699.jpg
191	Mekelle 70 Enderta F.C	M70	CLUB	15	12	\N	inAdex1566739463.jpg
192	Cano Sport	CS	CLUB	20	12	\N	100151566739650.png
193	ZESCO FC	ZSC	CLUB	58	12	\N	index1566920447.png
194	Platinum	PLM	CLUB	58	12	\N	index1566921189.jpg
195	Petro Atletico	Petro	CLUB	2	12	\N	index1566921449.jpg
196	Kampala City	KCCA	CLUB	54	12	\N	index1566921556.png
197	DODOMA FC	DDM	CLUB	56	44	\N	Club Default Logo-0115337269081567161479.png
198	Ihefu FC	IFC	CLUB	56	13	\N	Club Default Logo-0115337269081567161533.png
199	Boma	BM	CLUB	56	10	\N	Club Default Logo-0115337269081567161601.png
200	Ashanti United FC	AUFC	CLUB	56	12	\N	Club Default Logo-0115337269081567161656.png
201	Mufindi United FC	MU	CLUB	56	43	\N	Club Default Logo-0115337269081567161739.png
202	Mbeya Kwanza FC	MKFC	CLUB	56	6	\N	Club Default Logo-0115337269081567161816.png
203	Reha FC	REHA	CLUB	56	14	\N	Club Default Logo-0115337269081567161862.png
204	Friends Rangers FC	FRR	CLUB	56	14	\N	Club Default Logo-0115337269081567161947.png
205	Triangle fc	Tfc	CLUB	47	23	\N	\N
\.


--
-- Name: coach_team_stints_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.coach_team_stints_id_seq', 22, true);


--
-- Name: coaches_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.coaches_id_seq', 22, true);


--
-- Name: competition_edition_teams_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.competition_edition_teams_id_seq', 1, false);


--
-- Name: competition_editions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.competition_editions_id_seq', 25, true);


--
-- Name: competition_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.competition_groups_id_seq', 1, false);


--
-- Name: competitions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.competitions_id_seq', 19, true);


--
-- Name: confederations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.confederations_id_seq', 6, true);


--
-- Name: countries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.countries_id_seq', 59, true);


--
-- Name: data_sources_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.data_sources_id_seq', 1, true);


--
-- Name: entity_source_map_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.entity_source_map_id_seq', 3514, true);


--
-- Name: match_events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.match_events_id_seq', 3222, true);


--
-- Name: match_lineups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.match_lineups_id_seq', 2021, true);


--
-- Name: matches_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.matches_id_seq', 1549, true);


--
-- Name: player_team_stints_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.player_team_stints_id_seq', 1796, true);


--
-- Name: players_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.players_id_seq', 2595, true);


--
-- Name: reconciliation_diffs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.reconciliation_diffs_id_seq', 1, false);


--
-- Name: reconciliation_runs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.reconciliation_runs_id_seq', 1, false);


--
-- Name: seasons_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.seasons_id_seq', 4, true);


--
-- Name: stadiums_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.stadiums_id_seq', 52, true);


--
-- Name: teams_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.teams_id_seq', 205, true);


--
-- Name: coach_team_stints coach_team_stints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coach_team_stints
    ADD CONSTRAINT coach_team_stints_pkey PRIMARY KEY (id);


--
-- Name: coaches coaches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coaches
    ADD CONSTRAINT coaches_pkey PRIMARY KEY (id);


--
-- Name: competition_edition_teams competition_edition_teams_competition_edition_id_team_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competition_edition_teams
    ADD CONSTRAINT competition_edition_teams_competition_edition_id_team_id_key UNIQUE (competition_edition_id, team_id);


--
-- Name: competition_edition_teams competition_edition_teams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competition_edition_teams
    ADD CONSTRAINT competition_edition_teams_pkey PRIMARY KEY (id);


--
-- Name: competition_editions competition_editions_competition_id_season_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competition_editions
    ADD CONSTRAINT competition_editions_competition_id_season_id_key UNIQUE (competition_id, season_id);


--
-- Name: competition_editions competition_editions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competition_editions
    ADD CONSTRAINT competition_editions_pkey PRIMARY KEY (id);


--
-- Name: competition_groups competition_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competition_groups
    ADD CONSTRAINT competition_groups_pkey PRIMARY KEY (id);


--
-- Name: competitions competitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competitions
    ADD CONSTRAINT competitions_pkey PRIMARY KEY (id);


--
-- Name: competitions competitions_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competitions
    ADD CONSTRAINT competitions_slug_key UNIQUE (slug);


--
-- Name: confederations confederations_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.confederations
    ADD CONSTRAINT confederations_code_key UNIQUE (code);


--
-- Name: confederations confederations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.confederations
    ADD CONSTRAINT confederations_pkey PRIMARY KEY (id);


--
-- Name: countries countries_iso_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_iso_code_key UNIQUE (iso_code);


--
-- Name: countries countries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (id);


--
-- Name: data_sources data_sources_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_sources
    ADD CONSTRAINT data_sources_name_key UNIQUE (name);


--
-- Name: data_sources data_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_sources
    ADD CONSTRAINT data_sources_pkey PRIMARY KEY (id);


--
-- Name: entity_source_map entity_source_map_entity_type_data_source_id_external_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entity_source_map
    ADD CONSTRAINT entity_source_map_entity_type_data_source_id_external_id_key UNIQUE (entity_type, data_source_id, external_id);


--
-- Name: entity_source_map entity_source_map_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entity_source_map
    ADD CONSTRAINT entity_source_map_pkey PRIMARY KEY (id);


--
-- Name: match_events match_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.match_events
    ADD CONSTRAINT match_events_pkey PRIMARY KEY (id);


--
-- Name: match_lineups match_lineups_match_id_player_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.match_lineups
    ADD CONSTRAINT match_lineups_match_id_player_id_key UNIQUE (match_id, player_id);


--
-- Name: match_lineups match_lineups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.match_lineups
    ADD CONSTRAINT match_lineups_pkey PRIMARY KEY (id);


--
-- Name: match_player_ratings match_player_ratings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.match_player_ratings
    ADD CONSTRAINT match_player_ratings_pkey PRIMARY KEY (match_id, player_id);


--
-- Name: match_team_stats match_team_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.match_team_stats
    ADD CONSTRAINT match_team_stats_pkey PRIMARY KEY (match_id, team_id);


--
-- Name: matches matches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_pkey PRIMARY KEY (id);


--
-- Name: player_team_stints player_team_stints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_team_stints
    ADD CONSTRAINT player_team_stints_pkey PRIMARY KEY (id);


--
-- Name: players players_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_pkey PRIMARY KEY (id);


--
-- Name: reconciliation_diffs reconciliation_diffs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reconciliation_diffs
    ADD CONSTRAINT reconciliation_diffs_pkey PRIMARY KEY (id);


--
-- Name: reconciliation_runs reconciliation_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reconciliation_runs
    ADD CONSTRAINT reconciliation_runs_pkey PRIMARY KEY (id);


--
-- Name: seasons seasons_label_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.seasons
    ADD CONSTRAINT seasons_label_key UNIQUE (label);


--
-- Name: seasons seasons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.seasons
    ADD CONSTRAINT seasons_pkey PRIMARY KEY (id);


--
-- Name: stadiums stadiums_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stadiums
    ADD CONSTRAINT stadiums_pkey PRIMARY KEY (id);


--
-- Name: teams teams_name_country_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_name_country_id_key UNIQUE (name, country_id);


--
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- Name: coach_team_stints coach_team_stints_coach_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coach_team_stints
    ADD CONSTRAINT coach_team_stints_coach_id_fkey FOREIGN KEY (coach_id) REFERENCES public.coaches(id);


--
-- Name: coach_team_stints coach_team_stints_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coach_team_stints
    ADD CONSTRAINT coach_team_stints_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: coaches coaches_nationality_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coaches
    ADD CONSTRAINT coaches_nationality_id_fkey FOREIGN KEY (nationality_id) REFERENCES public.countries(id);


--
-- Name: competition_edition_teams competition_edition_teams_competition_edition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competition_edition_teams
    ADD CONSTRAINT competition_edition_teams_competition_edition_id_fkey FOREIGN KEY (competition_edition_id) REFERENCES public.competition_editions(id);


--
-- Name: competition_edition_teams competition_edition_teams_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competition_edition_teams
    ADD CONSTRAINT competition_edition_teams_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.competition_groups(id);


--
-- Name: competition_edition_teams competition_edition_teams_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competition_edition_teams
    ADD CONSTRAINT competition_edition_teams_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: competition_editions competition_editions_competition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competition_editions
    ADD CONSTRAINT competition_editions_competition_id_fkey FOREIGN KEY (competition_id) REFERENCES public.competitions(id);


--
-- Name: competition_editions competition_editions_host_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competition_editions
    ADD CONSTRAINT competition_editions_host_country_id_fkey FOREIGN KEY (host_country_id) REFERENCES public.countries(id);


--
-- Name: competition_editions competition_editions_season_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competition_editions
    ADD CONSTRAINT competition_editions_season_id_fkey FOREIGN KEY (season_id) REFERENCES public.seasons(id);


--
-- Name: competition_groups competition_groups_competition_edition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competition_groups
    ADD CONSTRAINT competition_groups_competition_edition_id_fkey FOREIGN KEY (competition_edition_id) REFERENCES public.competition_editions(id);


--
-- Name: competitions competitions_confederation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competitions
    ADD CONSTRAINT competitions_confederation_id_fkey FOREIGN KEY (confederation_id) REFERENCES public.confederations(id);


--
-- Name: competitions competitions_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competitions
    ADD CONSTRAINT competitions_country_id_fkey FOREIGN KEY (country_id) REFERENCES public.countries(id);


--
-- Name: countries countries_confederation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_confederation_id_fkey FOREIGN KEY (confederation_id) REFERENCES public.confederations(id);


--
-- Name: entity_source_map entity_source_map_data_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entity_source_map
    ADD CONSTRAINT entity_source_map_data_source_id_fkey FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


--
-- Name: match_events match_events_match_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.match_events
    ADD CONSTRAINT match_events_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id);


--
-- Name: match_events match_events_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.match_events
    ADD CONSTRAINT match_events_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.players(id);


--
-- Name: match_events match_events_related_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.match_events
    ADD CONSTRAINT match_events_related_player_id_fkey FOREIGN KEY (related_player_id) REFERENCES public.players(id);


--
-- Name: match_events match_events_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.match_events
    ADD CONSTRAINT match_events_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: match_lineups match_lineups_match_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.match_lineups
    ADD CONSTRAINT match_lineups_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id);


--
-- Name: match_lineups match_lineups_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.match_lineups
    ADD CONSTRAINT match_lineups_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.players(id);


--
-- Name: match_lineups match_lineups_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.match_lineups
    ADD CONSTRAINT match_lineups_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: match_player_ratings match_player_ratings_match_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.match_player_ratings
    ADD CONSTRAINT match_player_ratings_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id);


--
-- Name: match_player_ratings match_player_ratings_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.match_player_ratings
    ADD CONSTRAINT match_player_ratings_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.players(id);


--
-- Name: match_team_stats match_team_stats_match_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.match_team_stats
    ADD CONSTRAINT match_team_stats_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(id);


--
-- Name: match_team_stats match_team_stats_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.match_team_stats
    ADD CONSTRAINT match_team_stats_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: matches matches_away_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_away_team_id_fkey FOREIGN KEY (away_team_id) REFERENCES public.teams(id);


--
-- Name: matches matches_competition_edition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_competition_edition_id_fkey FOREIGN KEY (competition_edition_id) REFERENCES public.competition_editions(id);


--
-- Name: matches matches_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.competition_groups(id);


--
-- Name: matches matches_home_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_home_team_id_fkey FOREIGN KEY (home_team_id) REFERENCES public.teams(id);


--
-- Name: matches matches_referee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_referee_id_fkey FOREIGN KEY (referee_id) REFERENCES public.coaches(id);


--
-- Name: matches matches_stadium_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_stadium_id_fkey FOREIGN KEY (stadium_id) REFERENCES public.stadiums(id);


--
-- Name: player_team_stints player_team_stints_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_team_stints
    ADD CONSTRAINT player_team_stints_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.players(id);


--
-- Name: player_team_stints player_team_stints_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_team_stints
    ADD CONSTRAINT player_team_stints_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: players players_nationality_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_nationality_id_fkey FOREIGN KEY (nationality_id) REFERENCES public.countries(id);


--
-- Name: reconciliation_diffs reconciliation_diffs_reconciliation_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reconciliation_diffs
    ADD CONSTRAINT reconciliation_diffs_reconciliation_run_id_fkey FOREIGN KEY (reconciliation_run_id) REFERENCES public.reconciliation_runs(id);


--
-- Name: reconciliation_runs reconciliation_runs_data_source_a_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reconciliation_runs
    ADD CONSTRAINT reconciliation_runs_data_source_a_id_fkey FOREIGN KEY (data_source_a_id) REFERENCES public.data_sources(id);


--
-- Name: reconciliation_runs reconciliation_runs_data_source_b_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reconciliation_runs
    ADD CONSTRAINT reconciliation_runs_data_source_b_id_fkey FOREIGN KEY (data_source_b_id) REFERENCES public.data_sources(id);


--
-- Name: stadiums stadiums_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stadiums
    ADD CONSTRAINT stadiums_country_id_fkey FOREIGN KEY (country_id) REFERENCES public.countries(id);


--
-- Name: teams teams_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_country_id_fkey FOREIGN KEY (country_id) REFERENCES public.countries(id);


--
-- Name: teams teams_stadium_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_stadium_id_fkey FOREIGN KEY (stadium_id) REFERENCES public.stadiums(id);


--
-- PostgreSQL database dump complete
--

\unrestrict SgLtMaQEQHBPcF9EZVgfFP9UzqduC13GyeQOoq4dJW3E4q9GisCVhbmWf5h1wvP

