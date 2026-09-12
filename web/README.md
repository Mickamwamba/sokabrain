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

A full-screen console, separate from the public site: a dark left sidebar with
every section grouped under Overview, Vault, Data quality and Settings, and a
slim top bar with the signed-in admin and sign-out. Below the `lg` breakpoint
the sidebar becomes a drawer behind a menu button.

The first account comes from `npm run admin:create` in `backend/`; after that,
admins add each other under Access management.

| Route | Does |
|---|---|
| `/admin/login` | sign in (outside the console shell) |
| `/admin` | dashboard: totals, what's live, open flags, seasons needing attention |
| `/admin/competitions` | all competitions, searchable · `/new` to create |
| `/admin/competitions/[id]` | one competition: pick a season for its stats, matches, detected issues, publish toggle, settings, add or delete a season |
| `/admin/competitions/[id]/edit` | rename, retype, delete |
| `/admin/seasons` | every season with the competitions using it; add one · `/[id]` to edit or delete |
| `/admin/participants` | teams in a competition's season: add, set group, remove; picks up teams playing matches but not listed |
| `/admin/matches` | matches for one competition + season; optional "needs a score" filter |
| `/admin/matches/[id]` | two-sided match sheet: events per side, missing scorers, result, add event, raise and resolve flags |
| `/admin/teams` | clubs and national teams, searchable and paged · `/new` · `/[id]` shows the current squad and former players, and edits or deletes |
| `/admin/players` | players with their current club (or free agent), searchable and paged · `/new` registers with a club and join date, or as a free agent |
| `/admin/players/[id]` | career history (club and international, overlaps flagged with one-click fixes), record a transfer/loan/release, details, delete |
| `/admin/issues` | every match needing attention, by competition + season + issue type |
| `/admin/flags` | open and resolved flags |
| `/admin/access` | admin accounts: add, rename, reset password, revoke or restore access |
| `/admin/account` | your own details and password |

### Every change goes through a confirmation dialog

`components/admin/confirm-form.tsx` is the only way the console submits a
change — create, edit, delete, publish, resolve, sign out. Use it for anything
new; there is no other form wrapper.

- **It shows what will be written.** Fields carrying `data-label` are read back
  into the dialog: every value for `review="all"`, old → new for
  `review="changes"`. An edit that changes nothing says so and can't be
  confirmed.
- **Enter can't bypass it.** An implicit submit while the dialog is closed opens
  the dialog instead. The guard asks the `<dialog>` element whether it is open —
  React state went stale once and let a save straight through.
- **A failed save keeps the editor's input.** The action is dispatched in a
  transition rather than through the form's `action` prop, because React resets
  a form after its action settles, even when the server rejected it.
- **Short prompts live inside the dialog** via `fields` (a new password, a
  resolution note), validated on confirm.
- Success closes the dialog and raises a toast (`components/admin/toaster.tsx`,
  mounted in `app/admin/layout.tsx` so it survives the redirect after a create).

Deletes are refused by the API when anything depends on the record, and the edit
pages show that dependency list up front, with the delete button disabled.

### Two kinds of problem

`/admin/issues` shows both, and the difference matters:

* **Detected issues** are computed from the data on every read — a missing
  score, a goal with no scorer, goals absent from the event log, events that
  contradict the score. They vanish the moment the data is fixed, so nobody has
  to remember to close them.
* **Flags** are what a person knows and the data cannot reveal — a date
  contradicted by an external source, a score disputed by a match report. They
  persist until someone resolves them, with a note.

Event dialogs name exactly what will change — "Removing the 23' goal by John
Bocco for Simba SC" rather than a generic "Are you sure?". For an own goal the
dialog also states which side the goal will count for.

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
- **Mutations are server actions**, not client fetches: `app/admin/actions.ts`
  and `app/admin/manage-actions.ts`, sharing `lib/admin-actions.ts`.
- **The console checks the session once**, in `app/admin/(console)/layout.tsx`,
  against `/api/admin/me` — so a deactivated admin's still-valid cookie gets
  nothing. Pages load through `lib/admin-page.ts`, which sends a 401 to sign-in
  and a 404 to the not-found page.
- **Two route groups keep the chromes apart.** `app/(site)/` holds the public
  pages and their header/footer; `app/admin/(console)/` holds the sidebar shell.
  The root layout is only the document. Neither group changes a URL.
- **Publishing is the public gate.** An edition is invisible to the public site
  until published, and can't be published while it carries an open BLOCKER flag.
- **A blank score box means "unknown", not 0.** The editor sends null, so an
  unrecorded match never becomes a goalless draw.
- **Adding an event does not move the score** — the UI says so. The two are
  edited deliberately and separately (see the backend README).

## Not done yet

Socket.io push (priority 6). The dashboard has no team/player editor yet —
those endpoints exist in the API but have no screen.
