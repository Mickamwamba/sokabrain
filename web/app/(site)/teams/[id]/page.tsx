import Link from "next/link";
import { notFound } from "next/navigation";
import {
  api,
  ApiError,
  type Match,
  type TeamFormMatch,
  type TeamProfile,
  type TeamSeason,
} from "@/lib/api";
import { shortSeason } from "@/lib/competitions";
import { kickoffTime } from "@/components/match-list";
import {
  Card,
  CardHead,
  Crest,
  DataNote,
  Empty,
  FormDots,
  Rank,
  StatTile,
} from "@/components/ui";

export const dynamic = "force-dynamic";

/**
 * One team, across everything the vault has published about it.
 *
 * All-time by nature — a club is not a season — so there is no scope picker.
 * The detail lives in the breakdowns instead, which keep a league record and a
 * tournament record apart rather than summing them into a total nobody plays
 * for. Points appear only per competition for the same reason.
 *
 * What is deliberately absent: founding year (no team in the vault has one),
 * crests (`logo_url` holds filenames with no files behind them), squad
 * appearances and cards (team sheets survive for too few matches to count).
 */

/* ------------------------------------------------------------ formatting -- */

function ordinal(n: number) {
  const tens = n % 100;
  if (tens >= 11 && tens <= 13) return `${n}th`;
  return `${n}${({ 1: "st", 2: "nd", 3: "rd" } as Record<number, string>)[n % 10] ?? "th"}`;
}

function fmtDate(iso: string | null) {
  if (!iso) return "—";
  return new Date(iso).toLocaleDateString("en-GB", {
    day: "numeric", month: "short", year: "numeric", timeZone: "Africa/Dar_es_Salaam",
  });
}

const ROUND_LABEL: Record<string, string> = {
  "ROUND OF 16": "Round of 16",
  "QUARTER FINAL": "Quarter-finals",
  "SEMI FINAL": "Semi-finals",
  "THIRD PLACE": "Third-place play-off",
  FINAL: "Final",
};

/**
 * How a season ended, in the words a fan would use.
 *
 * Never names a champion the data cannot support: a league season in progress
 * reads "so far", and one with fixtures missing from every source is marked
 * incomplete rather than awarded — the same call `/table` makes.
 */
function finish(s: TeamSeason): { text: string; gold: boolean } {
  if (s.competitionType === "LEAGUE") {
    if (s.position === null) return { text: "—", gold: false };
    const place = `${ordinal(s.position)} of ${s.teamsInEdition}`;
    if (s.champion) return { text: "Champions", gold: true };
    if (!s.settled) return { text: `${place} · incomplete season`, gold: false };
    if (!s.finished) return { text: `${place} so far`, gold: false };
    return { text: place, gold: false };
  }
  if (s.champion) return { text: "Winners", gold: true };
  if (s.furthestRound === "FINAL" && s.champion === false) return { text: "Runners-up", gold: false };
  if (s.furthestRound) return { text: ROUND_LABEL[s.furthestRound] ?? s.furthestRound, gold: false };
  return { text: s.finished ? "Group stage" : "In progress", gold: false };
}

const RESULT_STYLE = {
  W: "bg-brand text-white",
  D: "bg-muted text-white",
  L: "bg-loss text-white",
} as const;

/* ------------------------------------------------------------ components -- */

function ResultRow({ m }: { m: TeamFormMatch }) {
  return (
    <li>
      <Link
        href={`/matches/${m.matchId}`}
        className="flex items-center gap-3 border-b border-line px-5 py-3 text-sm transition-colors last:border-0 hover:bg-wash"
      >
        <span
          className={`inline-flex h-6 w-6 shrink-0 items-center justify-center rounded text-[11px] font-bold ${RESULT_STYLE[m.result]}`}
        >
          {m.result}
        </span>
        <span className="min-w-0 flex-1">
          <span className="block truncate font-semibold">
            <span className="mr-1.5 text-xs font-medium text-muted">{m.home ? "vs" : "at"}</span>
            {m.opponent}
          </span>
          <span className="block truncate text-xs text-muted">
            {fmtDate(m.kickoffAt)} · {m.competition} {shortSeason(m.season)}
          </span>
        </span>
        <span className="stat-figure shrink-0 rounded bg-wash px-2 py-1 text-sm">
          {m.goalsFor}‑{m.goalsAgainst}
        </span>
      </Link>
    </li>
  );
}

function FixtureRow({ m, teamId }: { m: Match; teamId: number }) {
  const home = m.homeTeam.id === teamId;
  const opponent = home ? m.awayTeam : m.homeTeam;
  return (
    <li>
      <Link
        href={`/matches/${m.id}`}
        className="flex items-center gap-3 border-b border-line px-5 py-3 text-sm transition-colors last:border-0 hover:bg-wash"
      >
        <Crest name={opponent.name} size={26} />
        <span className="min-w-0 flex-1">
          <span className="block truncate font-semibold">
            <span className="mr-1.5 text-xs font-medium text-muted">{home ? "vs" : "at"}</span>
            {opponent.name}
          </span>
          <span className="block truncate text-xs text-muted">
            {m.competition.name}
            {m.round && !/^\d+$/.test(m.round) ? ` · ${ROUND_LABEL[m.round] ?? m.round}` : ""}
          </span>
        </span>
        <span className="shrink-0 text-right text-xs">
          <span className="block font-semibold">{fmtDate(m.kickoffAt)}</span>
          <span className="block text-muted nums">{kickoffTime(m.kickoffAt) ?? ""}</span>
        </span>
      </Link>
    </li>
  );
}

function RecordCard({ title, m }: { title: string; m: TeamFormMatch | null }) {
  return (
    <Card className="px-5 py-4">
      <p className="text-xs font-semibold uppercase tracking-wide text-muted">{title}</p>
      {m ? (
        <Link href={`/matches/${m.matchId}`} className="mt-2 block group">
          <p className="stat-figure text-3xl">
            {m.goalsFor}‑{m.goalsAgainst}
          </p>
          <p className="mt-1 text-sm font-semibold group-hover:text-brand">
            {m.home ? "vs" : "at"} {m.opponent}
          </p>
          <p className="text-xs text-muted">
            {fmtDate(m.kickoffAt)} · {m.competition} {shortSeason(m.season)}
          </p>
        </Link>
      ) : (
        <p className="mt-2 text-sm text-muted">None on record.</p>
      )}
    </Card>
  );
}

/* ------------------------------------------------------------------ page -- */

export default async function TeamPage(props: PageProps<"/teams/[id]">) {
  const { id } = await props.params;
  if (!/^\d+$/.test(id)) notFound();

  let profile: TeamProfile;
  let upcoming: Match[];
  try {
    [profile, upcoming] = await Promise.all([
      api.team(id),
      // From now, not merely SCHEDULED: a fixture whose kickoff has passed
      // without a result (several this week, a dozen stranded in 2021) is
      // awaiting a score, not upcoming.
      api
        .matches({
          teamId: id, status: "SCHEDULED", order: "asc", limit: 5,
          from: new Date().toISOString(),
        })
        .then((r) => r.matches),
    ]);
  } catch (err) {
    if (err instanceof ApiError && err.status === 404) notFound();
    if (err instanceof ApiError) return <Empty>{err.message}</Empty>;
    throw err;
  }

  const { team, record, competitions, seasons, form, players, coverage } = profile;
  const isNational = team.type === "NATIONAL";
  const titles = competitions.reduce((n, c) => n + c.titles, 0);

  const identity = [
    isNational ? "National team" : "Club",
    // A national team's country is its name; saying it twice adds nothing.
    !isNational && team.country ? team.country.replace(", United Republic of", "") : null,
  ].filter(Boolean).join(" · ");

  const header = (
    <div className="mb-6 flex flex-wrap items-center gap-4">
      <Crest name={team.name} size={64} />
      <div className="min-w-0 flex-1">
        <h1 className="display text-3xl font-extrabold tracking-tight">{team.name}</h1>
        <p className="mt-1 text-sm text-muted">
          {identity}
          {team.stadium ? (
            <>
              {" · "}Home ground {team.stadium.name}
              {team.stadium.city ? `, ${team.stadium.city}` : ""}
            </>
          ) : null}
        </p>
      </div>
      {form.length ? (
        <div className="text-right">
          <p className="mb-1 text-[11px] font-semibold uppercase tracking-wide text-muted">
            Form, latest first
          </p>
          <FormDots results={form.map((f) => f.result)} />
        </div>
      ) : null}
    </div>
  );

  if (record.played === 0) {
    return (
      <div>
        {header}
        <Empty>
          <p className="font-semibold text-ink">No published matches yet.</p>
          <p className="mt-1">
            {team.name} is in the vault, but none of its competitions has been released by an
            editor.
          </p>
        </Empty>
      </div>
    );
  }

  const goalsAreAFloor = coverage.goalAttributionRate < 0.995;
  const showAssists = players.coverage.assistsRecorded > 0;
  const span = (() => {
    const labels = seasons.map((s) => s.season).sort();
    const first = shortSeason(labels[0] ?? "");
    const last = shortSeason(labels[labels.length - 1] ?? "");
    return first === last ? first : `${first} to ${last}`;
  })();

  return (
    <div className="space-y-5">
      {header}

      {/* Headline figures. Points are left out on purpose: summed across a
          league and a tournament they are not a number anyone competes for. */}
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-6">
        <StatTile figure={record.played} label="Played" sub={`${seasons.length} seasons · ${span}`} />
        <StatTile figure={record.won} label="Won" sub={`${record.drawn} drawn · ${record.lost} lost`} />
        <StatTile figure={`${record.winRate}%`} label="Win rate" />
        <StatTile
          figure={record.goalsFor}
          label="Goals"
          sub={`${record.goalsAgainst} conceded · ${record.goalsPerGame} a game`}
        />
        <StatTile
          figure={record.cleanSheets}
          label="Clean sheets"
          sub={`${Math.round((record.cleanSheets * 100) / record.played)}% of matches`}
        />
        <StatTile
          figure={titles}
          label={titles === 1 ? "Title" : "Titles"}
          sub={titles ? "in the seasons on record" : "none in the seasons on record"}
        />
      </div>

      <div className="grid gap-5 lg:grid-cols-2">
        <div className="space-y-5">
          {upcoming.length ? (
            <Card className="overflow-hidden">
              <CardHead title="Upcoming" hint="Kickoff in Tanzanian time" />
              <ul>
                {upcoming.map((m) => (
                  <FixtureRow key={m.id} m={m} teamId={team.id} />
                ))}
              </ul>
            </Card>
          ) : null}

          <Card className="overflow-hidden">
            <CardHead title="Recent results" hint="Most recent first" />
            <ul>
              {form.map((m) => (
                <ResultRow key={m.matchId} m={m} />
              ))}
            </ul>
          </Card>

          <div className="grid grid-cols-2 gap-3">
            <RecordCard title="Biggest win" m={profile.biggestWin} />
            <RecordCard title="Heaviest defeat" m={profile.heaviestDefeat} />
          </div>
        </div>

        <Card className="overflow-hidden self-start">
          <CardHead
            title="Top scorers"
            hint={`For ${team.name}, every published competition`}
            action={{ href: `/stats/players?teamId=${team.id}`, label: "All players" }}
          />
          {players.players.length ? (
            <ol>
              {players.players.map((p, i) => (
                <li
                  key={p.playerId}
                  className="flex items-center gap-3 border-b border-line px-5 py-2.5 last:border-0"
                >
                  <Rank n={i + 1} />
                  <span className="min-w-0 flex-1 truncate text-sm font-semibold">
                    {p.playerName}
                  </span>
                  {showAssists ? (
                    <span className="w-14 shrink-0 text-right text-xs text-muted nums">
                      {p.assists === null ? "—" : `${p.assists} ast`}
                    </span>
                  ) : null}
                  <span className="stat-figure w-8 shrink-0 text-right text-lg">{p.goals}</span>
                </li>
              ))}
            </ol>
          ) : (
            <p className="px-5 py-6 text-sm text-muted">
              No goal in this team&rsquo;s published matches names its scorer.
            </p>
          )}
          {goalsAreAFloor ? (
            <div className="border-t border-line px-5 py-3">
              <DataNote>
                Scorers are named for {Math.round(coverage.goalAttributionRate * 100)}% of{" "}
                {team.name}&rsquo;s {coverage.goalsScored.toLocaleString()} goals —{" "}
                {coverage.seasonsWithScorers} of {coverage.seasonsPlayed} seasons record them —
                so these totals are a minimum, not a career record.
                {showAssists ? " Assists are recorded from 2023/24 onward only." : ""}
              </DataNote>
            </div>
          ) : null}
        </Card>
      </div>

      {/* One row per competition: the league record and the tournament record
          side by side, never summed. This is the only place points appear. */}
      <Card className="overflow-hidden">
        <CardHead title="By competition" />
        <div className="overflow-x-auto">
          <table className="w-full min-w-[640px] text-sm">
            <thead>
              <tr className="border-b border-line text-left text-[11px] font-semibold uppercase tracking-wide text-muted">
                <th className="py-2.5 pl-5 pr-2">Competition</th>
                <th className="px-2 py-2.5 text-right">Seasons</th>
                {["P", "W", "D", "L", "GF", "GA", "GD"].map((h) => (
                  <th key={h} className="px-2 py-2.5 text-right">{h}</th>
                ))}
                <th className="px-2 py-2.5 text-right">Pts</th>
                <th className="py-2.5 pl-2 pr-5 text-right">Titles</th>
              </tr>
            </thead>
            <tbody>
              {competitions.map((c) => (
                <tr key={c.competitionId} className="border-b border-line last:border-0">
                  <td className="py-2.5 pl-5 pr-2">
                    <Link
                      href={`/table?competitionId=${c.competitionId}`}
                      className="font-semibold hover:text-brand"
                    >
                      {c.competition}
                    </Link>
                    <span className="block text-xs text-muted">
                      {shortSeason(c.firstSeason)} to {shortSeason(c.lastSeason)}
                    </span>
                  </td>
                  <td className="px-2 py-2.5 text-right nums">{c.seasons}</td>
                  <td className="px-2 py-2.5 text-right nums">{c.played}</td>
                  <td className="px-2 py-2.5 text-right nums">{c.won}</td>
                  <td className="px-2 py-2.5 text-right nums">{c.drawn}</td>
                  <td className="px-2 py-2.5 text-right nums">{c.lost}</td>
                  <td className="px-2 py-2.5 text-right nums">{c.goalsFor}</td>
                  <td className="px-2 py-2.5 text-right nums">{c.goalsAgainst}</td>
                  <td className="px-2 py-2.5 text-right nums">
                    {c.goalDifference > 0 ? `+${c.goalDifference}` : c.goalDifference}
                  </td>
                  <td className="px-2 py-2.5 text-right font-semibold nums">
                    {/* A tournament awards points only in its groups, so a
                        points total across its knockouts is meaningless. */}
                    {c.competitionType === "LEAGUE" ? c.points : "—"}
                  </td>
                  <td className="py-2.5 pl-2 pr-5 text-right stat-figure">{c.titles}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>

      <Card className="overflow-hidden">
        <CardHead title="Season by season" hint="Newest first" />
        <div className="overflow-x-auto">
          <table className="w-full min-w-[640px] text-sm">
            <thead>
              <tr className="border-b border-line text-left text-[11px] font-semibold uppercase tracking-wide text-muted">
                <th className="py-2.5 pl-5 pr-2">Season</th>
                <th className="px-2 py-2.5">Finish</th>
                {["P", "W", "D", "L", "GF", "GA"].map((h) => (
                  <th key={h} className="px-2 py-2.5 text-right">{h}</th>
                ))}
                <th className="py-2.5 pl-2 pr-5 text-right">Pts</th>
              </tr>
            </thead>
            <tbody>
              {seasons.map((s) => {
                const f = finish(s);
                return (
                  <tr key={s.editionId} className="border-b border-line last:border-0">
                    <td className="py-2.5 pl-5 pr-2">
                      <Link
                        href={`/table?editionId=${s.editionId}`}
                        className="font-semibold hover:text-brand"
                      >
                        {shortSeason(s.season)}
                      </Link>
                      {competitions.length > 1 ? (
                        <span className="block text-xs text-muted">{s.competition}</span>
                      ) : null}
                    </td>
                    <td className="px-2 py-2.5">
                      <span
                        className={
                          f.gold
                            ? "rounded bg-gold px-1.5 py-0.5 text-xs font-bold text-ink"
                            : "text-xs text-muted"
                        }
                      >
                        {f.text}
                      </span>
                    </td>
                    <td className="px-2 py-2.5 text-right nums">{s.played}</td>
                    <td className="px-2 py-2.5 text-right nums">{s.won}</td>
                    <td className="px-2 py-2.5 text-right nums">{s.drawn}</td>
                    <td className="px-2 py-2.5 text-right nums">{s.lost}</td>
                    <td className="px-2 py-2.5 text-right nums">{s.goalsFor}</td>
                    <td className="px-2 py-2.5 text-right nums">{s.goalsAgainst}</td>
                    <td className="py-2.5 pl-2 pr-5 text-right font-semibold nums">
                      {s.competitionType === "LEAGUE" ? s.points : "—"}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  );
}
