# sokabrain web

Next.js 16 (App Router) front end over the vault read API. Build priority 4:
vault browsing, demoable before any live-score work.

## Setup

```bash
cp .env.example .env.local     # API_URL, defaults to http://localhost:4010
npm install
npm run dev
```

The backend must be running — see `../backend/README.md`. With it stopped, pages
render a "can't reach the API" message rather than a stack trace.

## Pages

| Route | Shows |
|---|---|
| `/` | stats dashboard: headline totals, top scorers, top clubs, latest results |
| `/players` | player leaderboard; `?sort=goals\|appearances\|yellowCards\|redCards`, `?position=`, `?editionId=`, `?teamId=` |
| `/clubs` | club leaderboard; `?sort=points\|goalsFor\|cleanSheets\|winRate`, `?editionId=` |
| `/head-to-head` | two-club comparison; `?teamA=&teamB=` |
| `/competitions` | published editions grouped by country |
| `/editions/[id]` | table + top scorers for one edition |
| `/matches` | results grouped by day; `?editionId=`, `?status=`, `?offset=` |

## Design

- **Light only, no dark mode.** One fixed palette in `globals.css` so a stat card
  looks identical everywhere. There are no `dark:` variants anywhere — don't
  reintroduce them without doing the whole palette.
- **Archivo for display, Inter for body.** Archivo carries the heavy weights the
  stat figures need; Inter keeps dense tables readable small. Stat numbers use
  `.stat-figure` and tables use `.nums` for tabular figures so columns don't
  jitter.
- **Filters are links, not client state**, so every filtered view is a URL a fan
  can share and every page stays a server component.

## Notes for whoever picks this up

- **Next.js 16 specifics.** `params` and `searchParams` are Promises and must be
  awaited. Pages are typed with the global `PageProps<'/route/[param]'>` helper,
  which comes from route typegen (`next typegen`, also run by dev/build) — a
  fresh clone will not typecheck until that has run once.
- **Filters are plain links, not client state.** Every page stays a server
  component and every filtered view is a shareable URL. There is no `use client`
  in the app except the error boundary, which React requires.
- **Coverage notes are load-bearing, not decoration.** The vault is partial —
  61 of the 380 matches in TPL 2018/19 have no score, and ~27% of goal events
  have no scorer — so tables legitimately show teams on different games played.
  Each page states what its data is missing; without that a correct table reads
  as broken. Don't remove them to tidy the UI.
- **Team crests are initials, not images.** `logo_url` in the vault holds bare
  filenames (`11.png`) with no host and no files behind them, so rendering them
  as images would just produce broken images.
- **API types in `lib/api.ts` are hand-written** to mirror the backend's
  responses. If a route's payload changes, change it there too.

## Admin dashboard (`/admin`)

Sign in with an account made by `npm run admin:create` in `backend/`.

Left sidebar navigation; the working area sits beside it.

| Route | Does |
|---|---|
| `/admin/login` | sign in (renders without the sidebar) |
| `/admin` | overview: what's live, what needs attention, open flags |
| `/admin/competitions` | all competitions, searchable, with "add competition" |
| `/admin/competitions/[id]` | one competition — pick a season, see its stats and every match |
| `/admin/matches` | matches for one competition + season, chosen by dropdown; optional "needs a score" filter |
| `/admin/matches/[id]` | two-sided match sheet: home events left, away right; name missing scorers inline; edit score & status; raise flags |
| `/admin/issues` | **every match needing attention**, by competition + season + issue type |
| `/admin/flags` | open and resolved flags, with resolution notes |

### Two kinds of problem

`/admin/issues` shows both, and the difference matters:

* **Detected issues** are computed from the data on every read — a missing
  score, a goal with no scorer, goals absent from the event log, events that
  contradict the score. They vanish the moment the data is fixed, so nobody has
  to remember to close them.
* **Flags** are what a person knows and the data cannot reveal — a date
  contradicted by an external source, a score disputed by a match report. They
  persist until someone resolves them, with a note.

Adding, editing and deleting an event each go through a confirmation dialog
that names what will change — "Removing the 23' goal by John Bocco for Simba
SC" rather than a generic "Are you sure?". For an own goal the dialog also
states which side the goal will count for. The submit button lives inside the
dialog, so Enter in the form cannot bypass it.

Matches with goals whose scorer was never recorded carry a red dot and a count
in every list. The dot has a screen-reader label with the exact count, so the
signal is not colour-only.

The competition page is the main working surface: pick a season and you get its
completeness numbers (matches, teams, goals, how many lack a score, how many
have an event log, goals with no scorer), the detected issues as one-click
flags, the publish toggle, and the full match list with problem rows
highlighted.

### How it works

- **Session is a JWT in an httpOnly cookie**, so page JavaScript cannot read it
  and an XSS bug can't exfiltrate it. Every admin API call is made server-side.
- **Mutations are server actions**, not client fetches. Each screen redirects to
  login on a 401 rather than rendering a broken page.
- **Publishing is the public gate.** An edition is invisible to the public site
  until published, and can't be published while it carries an open BLOCKER flag.
- **A blank score box means "unknown", not 0.** The editor sends null, so an
  unrecorded match never becomes a goalless draw.
- **Adding an event does not move the score** — the UI says so. The two are
  edited deliberately and separately (see the backend README).

## Not done yet

Socket.io push (priority 6). The dashboard has no team/player editor yet —
those endpoints exist in the API but have no screen.
