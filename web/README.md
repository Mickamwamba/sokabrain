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

## Not done yet

Live scores (priority 5) and Socket.io push (priority 6). There is no admin UI —
the write endpoints from priority 3 are API-only so far.
