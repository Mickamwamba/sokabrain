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
| `/` | competitions grouped by country, editions with match counts |
| `/editions/[id]` | league table + top scorers for one edition |
| `/matches` | paginated match list; `?editionId=`, `?status=`, `?offset=` |

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

| Route | Does |
|---|---|
| `/admin/login` | sign in |
| `/admin` | competitions: publish / hide, detected issues, one-click flagging |
| `/admin/matches` | match worklist, filterable to "completed with no score" |
| `/admin/matches/[id]` | edit score & status, add/delete events, raise flags |
| `/admin/flags` | open and resolved flags, with resolution notes |

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
