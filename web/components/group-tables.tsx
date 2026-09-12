import Link from "next/link";
import type { GroupTable, KnockoutRound, StandingsRow } from "@/lib/api";
import { Card, CardHead, Crest, Rank } from "@/components/ui";

/**
 * A tournament's group stage and knockout bracket.
 *
 * A cup is not one table. AFCON 2019 summed into a single ranking puts Algeria
 * top on 19 points from seven matches while a side eliminated in the group has
 * three — a comparison between teams that never had the same opportunity. What
 * IS a table is each group, played as its own round robin, so those are shown
 * as tables and the knockout is shown as ties.
 */

const COLS = ["P", "W", "D", "L", "GF", "GA", "GD"] as const;

/** "ROUND OF 16" -> "Round of 16". Stored rounds are upper case. */
function titleCase(round: string) {
  const small = new Set(["of", "the"]);
  return round
    .toLowerCase()
    .split(" ")
    .map((w, i) => (i > 0 && small.has(w) ? w : w.charAt(0).toUpperCase() + w.slice(1)))
    .join(" ");
}

function cells(r: StandingsRow) {
  return [r.played, r.won, r.drawn, r.lost, r.goalsFor, r.goalsAgainst];
}

export function GroupTables({ groups }: { groups: GroupTable[] }) {
  if (groups.length === 0) return null;
  return (
    <div className="grid gap-5 md:grid-cols-2">
      {groups.map((g) => (
        <Card key={g.groupId} className="overflow-hidden">
          <CardHead title={`Group ${g.name}`} />
          <div className="overflow-x-auto">
            <table className="w-full min-w-[420px] border-collapse text-sm">
              <thead>
                <tr className="border-b border-line bg-wash text-left text-[11px] font-semibold uppercase tracking-wide text-muted">
                  <th className="py-2.5 pl-5 pr-2">#</th>
                  <th className="px-2 py-2.5">Team</th>
                  {COLS.map((h) => (
                    <th key={h} className="px-2 py-2.5 text-right">{h}</th>
                  ))}
                  <th className="py-2.5 pl-2 pr-5 text-right">Pts</th>
                </tr>
              </thead>
              <tbody>
                {g.standings.map((r) => (
                  <tr
                    key={r.teamId}
                    className="border-b border-line last:border-0 hover:bg-wash"
                  >
                    <td className="py-2.5 pl-5 pr-2"><Rank n={r.position} /></td>
                    <td className="px-2 py-2.5">
                      <span className="flex items-center gap-2 font-semibold">
                        <Crest name={r.teamName} size={20} />
                        <span className="truncate">{r.teamName}</span>
                      </span>
                    </td>
                    {cells(r).map((v, i) => (
                      <td key={i} className="px-2 py-2.5 text-right nums text-muted">{v}</td>
                    ))}
                    <td className="px-2 py-2.5 text-right nums text-muted">
                      {r.goalDifference > 0 ? `+${r.goalDifference}` : r.goalDifference}
                    </td>
                    <td className="stat-figure py-2.5 pl-2 pr-5 text-right text-base">
                      {r.points}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      ))}
    </div>
  );
}

/** How a knockout result reads once extra time and a shootout are involved. */
function scoreline(m: KnockoutRound["matches"][number]) {
  if (m.homeScore === null || m.awayScore === null) return { main: "v", note: null };
  const wentToEt = m.homeScoreEt !== null && m.awayScoreEt !== null;
  const h = wentToEt ? m.homeScoreEt : m.homeScore;
  const a = wentToEt ? m.awayScoreEt : m.awayScore;
  const bits: string[] = [];
  if (wentToEt) bits.push("aet");
  if (m.homeScorePens !== null && m.awayScorePens !== null) {
    bits.push(`${m.homeScorePens}-${m.awayScorePens} on pens`);
  }
  return { main: `${h} – ${a}`, note: bits.length ? bits.join(", ") : null };
}

export function KnockoutBracket({ rounds }: { rounds: KnockoutRound[] }) {
  if (rounds.length === 0) return null;
  return (
    <div className="space-y-5">
      {rounds.map((r) => (
        <Card key={r.round} className="overflow-hidden">
          <CardHead title={titleCase(r.round)} />
          <ul>
            {r.matches.map((m) => {
              const { main, note } = scoreline(m);
              const homeWon = m.winnerTeamId === m.homeTeamId;
              const awayWon = m.winnerTeamId === m.awayTeamId;
              return (
                <li key={m.matchId} className="border-b border-line last:border-0">
                  <Link
                    href={`/matches/${m.matchId}`}
                    className="flex items-center gap-3 px-5 py-3 hover:bg-wash"
                  >
                    <span
                      className={`flex min-w-0 flex-1 items-center justify-end gap-2 text-right ${
                        homeWon ? "font-semibold" : "text-muted"
                      }`}
                    >
                      <span className="truncate">{m.homeTeamName}</span>
                      <Crest name={m.homeTeamName} size={20} />
                    </span>
                    <span className="shrink-0 text-center">
                      <span className="stat-figure block text-base whitespace-nowrap">{main}</span>
                      {note ? (
                        <span className="block text-[11px] whitespace-nowrap text-muted">{note}</span>
                      ) : null}
                    </span>
                    <span
                      className={`flex min-w-0 flex-1 items-center gap-2 ${
                        awayWon ? "font-semibold" : "text-muted"
                      }`}
                    >
                      <Crest name={m.awayTeamName} size={20} />
                      <span className="truncate">{m.awayTeamName}</span>
                    </span>
                  </Link>
                </li>
              );
            })}
          </ul>
        </Card>
      ))}
    </div>
  );
}
