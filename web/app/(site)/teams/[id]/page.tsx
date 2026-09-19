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

function ordinal(n: number) {
  const tens = n % 100;
  if (tens >= 11 && tens <= 13) return `${n}th`;
  return `${n}${({ 1: "st", 2: "nd", 3: "rd" } as Record<number, string>)[n % 10] ?? "th"}`;
}

function fmtDate(iso: string | null) {
  if (!iso) return "—";
  return new Date(iso).toLocaleDateString("en-GB", {
    day: "numeric",
    month: "short",
    year: "numeric",
    timeZone: "Africa/Dar_es_Salaam",
  });
}

const ROUND_LABEL: Record<string, string> = {
  "ROUND OF 16": "Round of 16",
  "QUARTER FINAL": "Quarter-finals",
  "SEMI FINAL": "Semi-finals",
  "THIRD PLACE": "Third-place play-off",
  FINAL: "Final",
};

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

function ResultRow({ m }: { m: TeamFormMatch }) {
  const style =
    m.result === "W"
      ? "bg-emerald-600 text-white"
      : m.result === "D"
      ? "bg-amber-500 text-ink"
      : "bg-rose-600 text-white";

  return (
    <li>
      <Link
        href={`/matches/${m.matchId}`}
        className="flex items-center gap-3 px-5 py-3 text-sm transition-colors hover:bg-wash/70 group"
      >
        <span
          className={`inline-flex h-6 w-6 shrink-0 items-center justify-center rounded-md font-display text-[11px] font-black shadow-2xs ${style}`}
        >
          {m.result}
        </span>
        <span className="min-w-0 flex-1">
          <span className="block truncate font-bold text-ink group-hover:text-brand transition-colors">
            <span className="mr-1.5 text-xs font-semibold text-muted">{m.home ? "vs" : "at"}</span>
            {m.opponent}
          </span>
          <span className="block truncate text-xs text-muted">
            {fmtDate(m.kickoffAt)} · {m.competition} {shortSeason(m.season)}
          </span>
        </span>
        <span className="stat-figure shrink-0 rounded-md bg-wash px-2.5 py-1 text-sm font-black text-ink">
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
        className="flex items-center gap-3 px-5 py-3 text-sm transition-colors hover:bg-wash/70 group"
      >
        <Crest name={opponent.name} size={28} />
        <span className="min-w-0 flex-1">
          <span className="block truncate font-bold text-ink group-hover:text-brand transition-colors">
            <span className="mr-1.5 text-xs font-semibold text-muted">{home ? "vs" : "at"}</span>
            {opponent.name}
          </span>
          <span className="block truncate text-xs text-muted">
            {m.competition.name}
            {m.round && !/^\d+$/.test(m.round) ? ` · ${ROUND_LABEL[m.round] ?? m.round}` : ""}
          </span>
        </span>
        <span className="shrink-0 text-right text-xs">
          <span className="block font-bold text-ink">{fmtDate(m.kickoffAt)}</span>
          <span className="block text-muted nums">{kickoffTime(m.kickoffAt) ?? ""}</span>
        </span>
      </Link>
    </li>
  );
}

function RecordCard({
  title,
  m,
  type,
}: {
  title: string;
  m: TeamFormMatch | null;
  type: "win" | "defeat";
}) {
  return (
    <Card
      className={`px-5 py-4 border-l-4 ${
        type === "win" ? "border-l-emerald-600 bg-emerald-50/10" : "border-l-rose-600 bg-rose-50/10"
      }`}
    >
      <p className="text-xs font-bold uppercase tracking-wider text-muted">{title}</p>
      {m ? (
        <Link href={`/matches/${m.matchId}`} className="mt-2 block group">
          <p className="stat-figure text-3xl font-black text-ink">
            {m.goalsFor}‑{m.goalsAgainst}
          </p>
          <p className="mt-1 text-sm font-bold text-ink group-hover:text-brand transition-colors">
            {m.home ? "vs" : "at"} {m.opponent}
          </p>
          <p className="text-xs text-muted mt-0.5">
            {fmtDate(m.kickoffAt)} · {m.competition} {shortSeason(m.season)}
          </p>
        </Link>
      ) : (
        <p className="mt-2 text-sm text-muted">None on record.</p>
      )}
    </Card>
  );
}

export default async function TeamPage(props: PageProps<"/teams/[id]">) {
  const { id } = await props.params;
  if (!/^\d+$/.test(id)) notFound();

  let profile: TeamProfile;
  let upcoming: Match[];
  try {
    [profile, upcoming] = await Promise.all([
      api.team(id),
      api
        .matches({
          teamId: id,
          status: "SCHEDULED",
          order: "asc",
          limit: 5,
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
    !isNational && team.country ? team.country.replace(", United Republic of", "") : null,
  ].filter(Boolean).join(" · ");

  const header = (
    <div className="mb-6 flex flex-wrap items-center gap-5">
      <Crest name={team.name} size={68} className="shadow-md ring-4 ring-white" />
      <div className="min-w-0 flex-1">
        <div className="flex flex-wrap items-center gap-2">
          <h1 className="display text-3xl font-black tracking-tight text-ink">{team.name}</h1>
          {titles > 0 && (
            <span className="inline-flex items-center gap-1 rounded-full bg-gold/20 border border-gold/40 px-3 py-0.5 text-xs font-black text-ink shadow-2xs">
              <span>🏆 {titles} {titles === 1 ? "Title" : "Titles"}</span>
            </span>
          )}
        </div>
        <p className="mt-1 text-sm font-medium text-muted">
          {identity}
          {team.stadium ? (
            <>
              {" · "}Home: {team.stadium.name}
              {team.stadium.city ? `, ${team.stadium.city}` : ""}
              {team.stadium.capacity ? ` (${team.stadium.capacity.toLocaleString()} cap)` : ""}
            </>
          ) : null}
        </p>
      </div>
      {form.length ? (
        <div className="text-right">
          <p className="mb-1.5 text-[10px] font-bold uppercase tracking-wider text-muted">
            Recent Form
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
            {team.name} is in the vault, but none of its competitions has been released by an editor.
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
    <div className="space-y-6">
      {header}

      {/* Headline Metric Cards */}
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
          sub={titles ? "in seasons on record" : "none on record"}
        />
      </div>

      {/* Main Breakdown Grid */}
      <div className="grid gap-6 lg:grid-cols-2">
        <div className="space-y-6">
          {upcoming.length ? (
            <Card className="overflow-hidden">
              <CardHead title="Upcoming Fixtures" hint="Kickoff in Tanzanian time" />
              <ul className="divide-y divide-line/60">
                {upcoming.map((m) => (
                  <FixtureRow key={m.id} m={m} teamId={team.id} />
                ))}
              </ul>
            </Card>
          ) : null}

          <Card className="overflow-hidden">
            <CardHead title="Recent Results" hint="Most recent first" />
            <ul className="divide-y divide-line/60">
              {form.map((m) => (
                <ResultRow key={m.matchId} m={m} />
              ))}
            </ul>
          </Card>

          <div className="grid grid-cols-2 gap-3">
            <RecordCard title="Biggest Win" m={profile.biggestWin} type="win" />
            <RecordCard title="Heaviest Defeat" m={profile.heaviestDefeat} type="defeat" />
          </div>
        </div>

        {/* Top Scorers */}
        <Card className="overflow-hidden self-start">
          <CardHead
            title="All-Time Top Scorers"
            hint={`For ${team.name}, every published competition`}
            action={{ href: `/stats/players?teamId=${team.id}`, label: "All players" }}
          />
          {players.players.length ? (
            <ol className="divide-y divide-line/60">
              {players.players.map((p, i) => (
                <li
                  key={p.playerId}
                  className="flex items-center gap-3 px-5 py-3 hover:bg-wash/60 transition-colors"
                >
                  <Rank n={i + 1} />
                  <span className="min-w-0 flex-1 truncate text-sm font-bold text-ink">
                    {p.playerName}
                  </span>
                  {showAssists ? (
                    <span className="w-16 shrink-0 text-right text-xs text-muted nums font-medium">
                      {p.assists === null ? "—" : `${p.assists} ast`}
                    </span>
                  ) : null}
                  <span className="stat-figure w-10 shrink-0 text-right text-lg font-black text-ink">
                    {p.goals}
                  </span>
                </li>
              ))}
            </ol>
          ) : (
            <p className="px-5 py-8 text-sm text-muted text-center">
              No goal in this team&rsquo;s published matches names its scorer.
            </p>
          )}
          {goalsAreAFloor ? (
            <div className="border-t border-line/80 p-4">
              <DataNote>
                Scorers are verified for {Math.round(coverage.goalAttributionRate * 100)}% of{" "}
                {team.name}&rsquo;s {coverage.goalsScored.toLocaleString()} goals.
              </DataNote>
            </div>
          ) : null}
        </Card>
      </div>

      {/* Season by season historical record */}
      <Card className="overflow-hidden">
        <CardHead title="Season by Season Archive" />
        <div className="overflow-x-auto">
          <table className="w-full min-w-[580px] border-collapse text-sm">
            <thead>
              <tr className="border-b border-line bg-wash/80 text-left text-[11px] font-bold uppercase tracking-wider text-muted">
                <th className="py-3 pl-5 pr-2">Season</th>
                <th className="px-2 py-3">Competition</th>
                <th className="px-2 py-3 text-right">P</th>
                <th className="px-2 py-3 text-right">W</th>
                <th className="px-2 py-3 text-right">D</th>
                <th className="px-2 py-3 text-right">L</th>
                <th className="px-2 py-3 text-right">GD</th>
                <th className="px-2 py-3 text-right">Pts</th>
                <th className="py-3 pl-2 pr-5 text-right">Finish</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-line/60">
              {seasons.map((s) => {
                const f = finish(s);
                return (
                  <tr key={`${s.competitionId}-${s.season}`} className="hover:bg-wash/70 transition-colors">
                    <td className="py-3 pl-5 pr-2 font-bold text-ink">
                      <Link
                        href={`/table?editionId=${s.editionId}`}
                        className="hover:text-brand transition-colors"
                      >
                        {shortSeason(s.season)}
                      </Link>
                    </td>
                    <td className="px-2 py-3 text-muted">{s.competition}</td>
                    <td className="px-2 py-3 text-right nums text-muted">{s.played}</td>
                    <td className="px-2 py-3 text-right nums text-muted">{s.won}</td>
                    <td className="px-2 py-3 text-right nums text-muted">{s.drawn}</td>
                    <td className="px-2 py-3 text-right nums text-muted">{s.lost}</td>
                    <td className="px-2 py-3 text-right nums font-semibold text-ink">
                      {s.goalDifference > 0 ? `+${s.goalDifference}` : s.goalDifference}
                    </td>
                    <td className="stat-figure px-2 py-3 text-right text-sm font-black text-ink">
                      {s.competitionType === "LEAGUE" ? s.points : "—"}
                    </td>
                    <td className="py-3 pl-2 pr-5 text-right font-bold text-xs">
                      <span className={f.gold ? "text-gold font-black" : "text-muted"}>
                        {f.text}
                      </span>
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
