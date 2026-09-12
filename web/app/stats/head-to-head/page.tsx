import Link from "next/link";
import { api, ApiError, type HeadToHead, type TeamRefLite } from "@/lib/api";
import { Card, CardHead, Crest, Empty } from "@/components/ui";
import { AllTimeBadge } from "@/components/scope-select";

export const dynamic = "force-dynamic";

/** Percentage width for the three-way record bar. */
function pct(n: number, total: number) {
  return total === 0 ? 0 : Math.round((n / total) * 100);
}

/** Club picker column. Declared at module scope, not inside render. */
function Picker({
  side,
  selectedId,
  teams,
  hrefFor,
}: {
  side: "teamA" | "teamB";
  selectedId?: string | undefined;
  teams: TeamRefLite[];
  hrefFor: (side: "teamA" | "teamB", id: number) => string;
}) {
  const clubs = teams.filter((t) => t.type !== "NATIONAL");
  const nations = teams.filter((t) => t.type === "NATIONAL");
  const ordered: [string, TeamRefLite[]][] = [];
  if (clubs.length) ordered.push(["Clubs", clubs]);
  if (nations.length) ordered.push(["National teams", nations]);
  const showHeadings = ordered.length > 1;

  return (
    <Card className="overflow-hidden">
      <CardHead title={side === "teamA" ? "Team one" : "Team two"} />
      <div className="max-h-72 overflow-y-auto">
        {/* Clubs and nations are listed under their own heading: they never
            meet, so an unlabelled single list invites a pairing that can only
            ever return no matches. */}
        {ordered.map(([heading, list]) => (
          <div key={heading}>
            {showHeadings ? (
              <p className="sticky top-0 border-b border-line bg-wash px-4 py-1.5 text-[10px] font-bold uppercase tracking-wider text-muted">
                {heading}
              </p>
            ) : null}
            {list.map((t) => (
          <Link
            key={t.id}
            href={hrefFor(side, t.id)}
            className={`flex items-center gap-2.5 border-b border-line px-4 py-2 text-sm last:border-0 hover:bg-wash ${
              String(t.id) === selectedId ? "bg-wash font-semibold" : ""
            }`}
          >
            <Crest name={t.name} size={22} />
            <span className="min-w-0 flex-1 truncate">{t.name}</span>
            {t.country ? (
              <span className="shrink-0 text-[11px] text-muted">{t.country.slice(0, 12)}</span>
            ) : null}
          </Link>
            ))}
          </div>
        ))}
      </div>
    </Card>
  );
}

export default async function HeadToHeadPage(props: PageProps<"/stats/head-to-head">) {
  const sp = await props.searchParams;
  const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);
  const teamA = one(sp.teamA);
  const teamB = one(sp.teamB);

  let teams: TeamRefLite[];
  try {
    teams = (await api.teams()).teams;
  } catch (err) {
    if (err instanceof ApiError) return <Empty>{err.message}</Empty>;
    throw err;
  }

  let h2h: HeadToHead | null = null;
  let error: string | null = null;
  if (teamA && teamB && teamA !== teamB) {
    try {
      h2h = await api.headToHead(teamA, teamB);
    } catch (err) {
      error = err instanceof ApiError ? err.message : "Could not load that comparison.";
    }
  }

  const pickerHref = (side: "teamA" | "teamB", id: number) => {
    const q = new URLSearchParams();
    if (side === "teamA") {
      q.set("teamA", String(id));
      if (teamB) q.set("teamB", teamB);
    } else {
      if (teamA) q.set("teamA", teamA);
      q.set("teamB", String(id));
    }
    return `/stats/head-to-head?${q}`;
  };

  return (
    <div>
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <p className="text-sm text-muted">
          Every recorded meeting between two clubs. There is no season selector here on
          purpose — two clubs meet twice a season, so a single season is not a record.
        </p>
        <AllTimeBadge />
      </div>

      {h2h ? (
        <div className="mb-6 space-y-5">
          {/* The record, read at a glance. */}
          <Card className="px-6 py-6">
            <div className="flex items-center justify-between gap-4">
              <div className="flex min-w-0 flex-1 items-center gap-3">
                <Crest name={h2h.teamA.name} size={40} />
                <span className="min-w-0">
                  <span className="display block truncate text-lg font-bold">{h2h.teamA.name}</span>
                  <span className="block text-xs text-muted">{h2h.aGoals} goals</span>
                </span>
              </div>
              <div className="shrink-0 text-center">
                <p className="stat-figure text-3xl">
                  {h2h.aWins}<span className="mx-1.5 text-muted">–</span>{h2h.draws}<span className="mx-1.5 text-muted">–</span>{h2h.bWins}
                </p>
                <p className="mt-1 text-[11px] font-semibold uppercase tracking-wide text-muted">
                  W · D · L
                </p>
              </div>
              <div className="flex min-w-0 flex-1 items-center justify-end gap-3 text-right">
                <span className="min-w-0">
                  <span className="display block truncate text-lg font-bold">{h2h.teamB.name}</span>
                  <span className="block text-xs text-muted">{h2h.bGoals} goals</span>
                </span>
                <Crest name={h2h.teamB.name} size={40} />
              </div>
            </div>

            <div className="mt-5 flex h-2.5 overflow-hidden rounded-full bg-wash">
              <span className="bg-brand" style={{ width: `${pct(h2h.aWins, h2h.meetings)}%` }} />
              <span className="bg-muted" style={{ width: `${pct(h2h.draws, h2h.meetings)}%` }} />
              <span className="bg-loss" style={{ width: `${pct(h2h.bWins, h2h.meetings)}%` }} />
            </div>
            <p className="mt-2 text-center text-xs text-muted">
              {h2h.meetings} meeting{h2h.meetings === 1 ? "" : "s"} on record
            </p>
          </Card>

          <Card>
            <CardHead title="Every meeting" />
            {h2h.matches.length === 0 ? (
              <p className="px-5 py-10 text-center text-sm text-muted">
                These two clubs have no recorded meeting in the published data.
              </p>
            ) : (
              <ul>
                {h2h.matches.map((m) => (
                  <li
                    key={m.id}
                    className="flex items-center gap-3 border-b border-line px-5 py-3 text-sm last:border-0"
                  >
                    <span className="w-20 shrink-0 text-xs text-muted">
                      {m.kickoffAt
                        ? new Date(m.kickoffAt).toLocaleDateString("en-GB", {
                            day: "2-digit",
                            month: "short",
                            year: "2-digit",
                          })
                        : "—"}
                    </span>
                    <span className="min-w-0 flex-1 truncate text-right">{m.homeTeam}</span>
                    <span className="stat-figure shrink-0 rounded bg-wash px-2.5 py-1">
                      {m.homeScore}‑{m.awayScore}
                    </span>
                    <span className="min-w-0 flex-1 truncate">{m.awayTeam}</span>
                    <span className="hidden w-40 shrink-0 truncate text-right text-xs text-muted sm:block">
                      {m.competition} {m.season}
                    </span>
                  </li>
                ))}
              </ul>
            )}
          </Card>

          <Link href="/stats/head-to-head" className="inline-block text-sm font-semibold text-brand hover:text-brand-dark">
            ← Pick two different clubs
          </Link>
        </div>
      ) : null}

      {error ? <div className="mb-5"><Empty>{error}</Empty></div> : null}

      {!h2h ? (
        <>
          {teamA && teamB && teamA === teamB ? (
            <div className="mb-4"><Empty>Pick two different clubs.</Empty></div>
          ) : null}
          <div className="grid gap-4 sm:grid-cols-2">
            <Picker side="teamA" selectedId={teamA} teams={teams} hrefFor={pickerHref} />
            <Picker side="teamB" selectedId={teamB} teams={teams} hrefFor={pickerHref} />
          </div>
        </>
      ) : null}
    </div>
  );
}
