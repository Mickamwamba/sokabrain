import Link from "next/link";
import { api, ApiError, type Match } from "@/lib/api";
import { Card, ChipRow, Crest, Empty, PageTitle } from "@/components/ui";

export const dynamic = "force-dynamic";

const PAGE_SIZE = 25;
const STATUSES = [
  { value: undefined, label: "Any" },
  { value: "FULL_TIME", label: "Finished" },
  { value: "SCHEDULED", label: "Scheduled" },
  { value: "POSTPONED", label: "Postponed" },
];

/** Group matches by calendar day, the way a fan reads a fixture list. */
function byDay(matches: Match[]) {
  const days = new Map<string, Match[]>();
  for (const m of matches) {
    const key = m.kickoffAt
      ? new Date(m.kickoffAt).toLocaleDateString("en-GB", {
          weekday: "short",
          day: "numeric",
          month: "long",
          year: "numeric",
        })
      : "Date unknown";
    const list = days.get(key);
    if (list) list.push(m);
    else days.set(key, [m]);
  }
  return [...days.entries()];
}

function Score({ match }: { match: Match }) {
  const { home, away, homePenalties, awayPenalties } = match.score;
  if (home === null || away === null) {
    return (
      <span className="rounded bg-wash px-2.5 py-1 text-xs font-medium text-muted">
        {match.status === "FULL_TIME" ? "No score" : match.status.replace("_", " ").toLowerCase()}
      </span>
    );
  }
  return (
    <span className="stat-figure whitespace-nowrap rounded bg-ink px-2.5 py-1 text-sm text-white">
      {home}‑{away}
      {homePenalties !== null && awayPenalties !== null ? (
        <span className="ml-1 text-[10px] font-normal text-white/70">
          ({homePenalties}‑{awayPenalties}p)
        </span>
      ) : null}
    </span>
  );
}

export default async function MatchesPage(props: PageProps<"/matches">) {
  const sp = await props.searchParams;
  const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);
  const editionId = one(sp.editionId);
  const status = one(sp.status);
  const offset = Math.max(0, Number(one(sp.offset) ?? 0) || 0);

  let data: Awaited<ReturnType<typeof api.matches>>;
  let editions: Awaited<ReturnType<typeof api.editions>>["editions"];
  try {
    [data, editions] = await Promise.all([
      api.matches({ editionId, status, limit: PAGE_SIZE, offset }),
      api.editions().then((r) => r.editions),
    ]);
  } catch (err) {
    if (err instanceof ApiError) return <Empty>{err.message}</Empty>;
    throw err;
  }

  const href = (patch: Record<string, string | number | undefined>) => {
    const q = new URLSearchParams();
    for (const [k, v] of Object.entries({ editionId, status, offset, ...patch })) {
      if (v !== undefined && v !== "" && !(k === "offset" && Number(v) === 0)) q.set(k, String(v));
    }
    const s = q.toString();
    return s ? `/matches?${s}` : "/matches";
  };

  const active = editions.find((e) => String(e.editionId) === editionId);

  return (
    <div>
      <PageTitle
        title="Matches"
        sub={`${data.total.toLocaleString()} results${active ? ` · ${active.competition} ${active.season}` : ""}`}
      />

      <div className="mb-5 space-y-2.5">
        <ChipRow
          label="Competition"
          options={[
            { value: undefined, label: "All" },
            ...editions
              .filter((e) => e.matchCount >= 19)
              .slice(0, 7)
              .map((e) => ({ value: String(e.editionId), label: `${e.competition} ${e.season.slice(0, 4)}` })),
          ]}
          activeValue={editionId}
          hrefFor={(v) => href({ editionId: v, offset: 0 })}
        />
        <ChipRow
          label="Status"
          options={STATUSES}
          activeValue={status}
          hrefFor={(v) => href({ status: v, offset: 0 })}
        />
      </div>

      {data.matches.length === 0 ? (
        <Empty>No matches match these filters.</Empty>
      ) : (
        <div className="space-y-5">
          {byDay(data.matches).map(([day, list]) => (
            <div key={day}>
              <h2 className="display mb-2 text-xs font-bold uppercase tracking-wider text-muted">
                {day}
              </h2>
              <Card className="overflow-hidden">
                <ul>
                  {list.map((m) => (
                    <li
                      key={m.id}
                      className="flex items-center gap-3 border-b border-line px-4 py-3 text-sm last:border-0"
                    >
                      <span className="flex min-w-0 flex-1 items-center justify-end gap-2">
                        <span className="truncate font-medium">{m.homeTeam.name}</span>
                        <Crest name={m.homeTeam.name} size={24} />
                      </span>
                      <span className="w-24 shrink-0 text-center">
                        <Score match={m} />
                      </span>
                      <span className="flex min-w-0 flex-1 items-center gap-2">
                        <Crest name={m.awayTeam.name} size={24} />
                        <span className="truncate font-medium">{m.awayTeam.name}</span>
                      </span>
                      <span className="hidden w-40 shrink-0 truncate text-right text-xs text-muted lg:block">
                        {m.competition.name}
                      </span>
                    </li>
                  ))}
                </ul>
              </Card>
            </div>
          ))}
        </div>
      )}

      <div className="mt-6 flex items-center justify-between text-sm">
        <span className="text-xs text-muted">
          {data.total === 0
            ? "0"
            : `${offset + 1}–${Math.min(offset + PAGE_SIZE, data.total)} of ${data.total.toLocaleString()}`}
        </span>
        <span className="flex gap-2">
          {offset > 0 ? (
            <Link href={href({ offset: Math.max(0, offset - PAGE_SIZE) })} className="rounded-full border border-line bg-paper px-4 py-1.5 text-xs font-semibold hover:border-ink">
              Previous
            </Link>
          ) : null}
          {offset + PAGE_SIZE < data.total ? (
            <Link href={href({ offset: offset + PAGE_SIZE })} className="rounded-full border border-line bg-paper px-4 py-1.5 text-xs font-semibold hover:border-ink">
              Next
            </Link>
          ) : null}
        </span>
      </div>
    </div>
  );
}
