import Link from "next/link";
import { api, ApiError } from "@/lib/api";
import { ChipRow, Empty, PageTitle } from "@/components/ui";
import { MatchDays } from "@/components/match-list";

export const dynamic = "force-dynamic";

const PAGE_SIZE = 25;
const STATUSES = [
  { value: undefined, label: "Any" },
  { value: "FULL_TIME", label: "Finished" },
  { value: "SCHEDULED", label: "Scheduled" },
  { value: "POSTPONED", label: "Postponed" },
];

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
        title="All matches"
        sub={`${data.total.toLocaleString()} results${active ? ` · ${active.competition} ${active.season}` : ""} · newest first`}
      />

      <p className="mb-5 text-sm text-muted">
        The full archive, across every published season.{" "}
        <Link href="/" className="font-medium text-brand hover:text-brand-dark">
          Browse by date or round
        </Link>{" "}
        for what is on now.
      </p>

      <div className="mb-5 space-y-2.5">
        <ChipRow
          label="Season"
          options={[
            { value: undefined, label: "All" },
            // Every season, newest first, labelled the way the rest of the site
            // labels them. The old list showed seven in load order and called
            // 2018/19 "Premier League 2018".
            ...editions
              .slice()
              .sort((a, b) => b.season.localeCompare(a.season))
              .map((e) => ({ value: String(e.editionId), label: e.season.replace("/20", "/") })),
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
        <MatchDays matches={data.matches} showCompetition />
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
