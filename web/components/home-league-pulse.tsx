import Link from "next/link";
import { Crest } from "@/components/ui";
import { type StandingsRow } from "@/lib/api";

export function MiniStandings({
  standings,
  editionId,
  competitionName,
}: {
  standings: StandingsRow[];
  editionId: number;
  competitionName?: string;
}) {
  if (!standings || standings.length === 0) return null;

  // Show top 4 + bottom 2 (relegation zone)
  const top4 = standings.slice(0, 4);
  const bottom2 = standings.length > 6 ? standings.slice(-2) : [];
  const showDivider = standings.length > 6;

  return (
    <div className="rounded-2xl border border-line bg-paper p-4 shadow-xs">
      <div className="flex items-center justify-between border-b border-line/60 pb-3">
        <div>
          <h3 className="text-xs font-black uppercase tracking-wider text-ink">
            Standings Snapshot
          </h3>
          <p className="text-[11px] text-muted truncate">{competitionName || "League Table"}</p>
        </div>
        <Link
          href={`/table?editionId=${editionId}`}
          className="text-xs font-bold text-brand hover:underline"
        >
          Full Table →
        </Link>
      </div>

      <div className="mt-2 divide-y divide-line/30 text-xs">
        <div className="flex items-center justify-between py-1 px-1 text-[10px] font-bold uppercase tracking-wider text-muted">
          <div className="flex items-center gap-2">
            <span className="w-5 text-center">#</span>
            <span>Club</span>
          </div>
          <div className="flex items-center gap-4 text-right">
            <span className="w-5">PL</span>
            <span className="w-6">GD</span>
            <span className="w-6 font-black text-ink">PTS</span>
          </div>
        </div>

        {top4.map((row) => (
          <Link
            key={row.teamId}
            href={`/teams/${row.teamId}`}
            className="flex items-center justify-between py-2 px-1 hover:bg-wash rounded-lg transition-colors group"
          >
            <div className="flex items-center gap-2.5 min-w-0">
              <span
                className={`w-5 text-center font-bold text-xs ${
                  row.position <= 2
                    ? "text-emerald-600 dark:text-emerald-400"
                    : row.position === 3
                    ? "text-blue-600 dark:text-blue-400"
                    : "text-muted"
                }`}
              >
                {row.position}
              </span>
              <Crest name={row.teamName} size={20} />
              <span className="truncate font-semibold text-ink group-hover:text-brand transition-colors">
                {row.teamName}
              </span>
            </div>
            <div className="flex items-center gap-4 text-right shrink-0">
              <span className="w-5 text-muted nums">{row.played}</span>
              <span
                className={`w-6 font-medium nums ${
                  row.goalDifference > 0
                    ? "text-emerald-600"
                    : row.goalDifference < 0
                    ? "text-rose-600"
                    : "text-muted"
                }`}
              >
                {row.goalDifference > 0 ? `+${row.goalDifference}` : row.goalDifference}
              </span>
              <span className="w-6 font-black text-ink nums">{row.points}</span>
            </div>
          </Link>
        ))}

        {showDivider && (
          <div className="py-1 text-center text-[10px] text-muted tracking-widest font-mono">
            ···
          </div>
        )}

        {bottom2.map((row) => (
          <Link
            key={row.teamId}
            href={`/teams/${row.teamId}`}
            className="flex items-center justify-between py-2 px-1 hover:bg-wash rounded-lg transition-colors group bg-rose-500/5"
          >
            <div className="flex items-center gap-2.5 min-w-0">
              <span className="w-5 text-center font-bold text-xs text-rose-600">
                {row.position}
              </span>
              <Crest name={row.teamName} size={20} />
              <span className="truncate font-semibold text-ink group-hover:text-brand transition-colors">
                {row.teamName}
              </span>
            </div>
            <div className="flex items-center gap-4 text-right shrink-0">
              <span className="w-5 text-muted nums">{row.played}</span>
              <span
                className={`w-6 font-medium nums ${
                  row.goalDifference > 0
                    ? "text-emerald-600"
                    : row.goalDifference < 0
                    ? "text-rose-600"
                    : "text-muted"
                }`}
              >
                {row.goalDifference > 0 ? `+${row.goalDifference}` : row.goalDifference}
              </span>
              <span className="w-6 font-black text-ink nums">{row.points}</span>
            </div>
          </Link>
        ))}
      </div>
    </div>
  );
}

export function MiniTopScorers({
  scorers,
  editionId,
}: {
  scorers: {
    rank: number;
    playerId: number;
    playerName: string;
    teamId: number | null;
    teamName: string | null;
    goals: number;
  }[];
  editionId: number;
}) {
  if (!scorers || scorers.length === 0) return null;

  return (
    <div className="rounded-2xl border border-line bg-paper p-4 shadow-xs">
      <div className="flex items-center justify-between border-b border-line/60 pb-3">
        <div>
          <h3 className="text-xs font-black uppercase tracking-wider text-ink">
            Golden Boot Leaders
          </h3>
          <p className="text-[11px] text-muted">Top Goalscorers</p>
        </div>
        <Link
          href={`/stats/players?editionId=${editionId}`}
          className="text-xs font-bold text-brand hover:underline"
        >
          View All →
        </Link>
      </div>

      <div className="mt-2.5 space-y-2">
        {scorers.slice(0, 3).map((scorer, i) => (
          <div
            key={scorer.playerId}
            className="flex items-center justify-between p-2 rounded-xl bg-wash/60 border border-line/40"
          >
            <div className="flex items-center gap-2.5 min-w-0">
              <span
                className={`flex h-6 w-6 items-center justify-center rounded-full text-xs font-black ${
                  i === 0
                    ? "bg-amber-400/20 text-amber-700 border border-amber-400/40"
                    : i === 1
                    ? "bg-slate-300/30 text-slate-700 border border-slate-300/50"
                    : "bg-amber-700/20 text-amber-800 border border-amber-700/30"
                }`}
              >
                {i + 1}
              </span>
              <div className="min-w-0">
                <div className="font-bold text-xs text-ink truncate">{scorer.playerName}</div>
                <div className="text-[10px] text-muted truncate">{scorer.teamName || "—"}</div>
              </div>
            </div>
            <div className="text-right shrink-0">
              <span className="text-sm font-black text-ink nums">{scorer.goals}</span>
              <span className="text-[10px] font-bold text-muted ml-1">⚽</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
