import Link from 'next/link';
import { notFound, redirect } from 'next/navigation';
import {
  adminFetch,
  AdminApiError,
  type AdminEditionRow,
  type AdminMatchRow,
  type EditionSummary,
} from '@/lib/adminApi';
import { Card, CardHead, StatTile } from '@/components/ui';
import { ActionForm, SeverityTag } from '@/components/admin-ui';
import { createFlagAction, publishEditionAction } from '../../actions';

export const dynamic = 'force-dynamic';

type Detail = {
  competition: { id: number; name: string; type: string; tier: number | null; country: string | null };
  editions: AdminEditionRow[];
};

export default async function AdminCompetitionPage(
  props: PageProps<'/admin/competitions/[id]'>,
) {
  const { id } = await props.params;
  const sp = await props.searchParams;
  const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);
  const competitionId = Number(id);
  if (!Number.isInteger(competitionId) || competitionId <= 0) notFound();

  let detail: Detail;
  try {
    detail = await adminFetch<Detail>(`/api/admin/competitions/${competitionId}`);
  } catch (err) {
    if (err instanceof AdminApiError && err.status === 401) redirect('/admin/login');
    if (err instanceof AdminApiError && err.status === 404) notFound();
    if (err instanceof AdminApiError) return <p className="text-sm text-loss">{err.message}</p>;
    throw err;
  }

  // Default to the season the editor most likely wants: the newest.
  const requested = one(sp.season);
  const selected =
    detail.editions.find((e) => String(e.editionId) === requested) ?? detail.editions[0];

  let summary: EditionSummary | null = null;
  let matches: AdminMatchRow[] = [];
  if (selected) {
    try {
      [summary, matches] = await Promise.all([
        adminFetch<EditionSummary>(`/api/admin/editions/${selected.editionId}/summary`),
        adminFetch<{ matches: AdminMatchRow[] }>(
          `/api/admin/matches?editionId=${selected.editionId}&limit=500`,
        ).then((r) => r.matches),
      ]);
    } catch (err) {
      if (err instanceof AdminApiError && err.status === 401) redirect('/admin/login');
      throw err;
    }
  }

  const problem = (m: AdminMatchRow) =>
    m.status === 'FULL_TIME' && (m.homeScore === null || m.awayScore === null);

  return (
    <div className="space-y-5">
      <div>
        <Link href="/admin/competitions" className="text-sm text-muted hover:text-ink">
          ← All competitions
        </Link>
        <h1 className="display mt-1 text-2xl font-extrabold tracking-tight">
          {detail.competition.name}
        </h1>
        <p className="mt-1 text-sm text-muted">
          {detail.competition.country ?? 'Continental / international'} ·{' '}
          {detail.competition.type.replaceAll('_', ' ').toLowerCase()}
          {detail.competition.tier ? ` · tier ${detail.competition.tier}` : ''}
        </p>
      </div>

      {detail.editions.length === 0 ? (
        <Card className="px-6 py-12 text-center text-sm text-muted">
          No seasons recorded for this competition yet.
        </Card>
      ) : (
        <>
          {/* Season picker */}
          <div className="flex flex-wrap items-center gap-1.5">
            <span className="mr-1 text-xs font-semibold uppercase tracking-wide text-muted">
              Season
            </span>
            {detail.editions.map((e) => {
              const active = e.editionId === selected?.editionId;
              return (
                <Link
                  key={e.editionId}
                  href={`/admin/competitions/${competitionId}?season=${e.editionId}`}
                  className={`rounded-full border px-3.5 py-1.5 text-sm font-medium transition-colors ${
                    active
                      ? 'border-ink bg-ink text-white'
                      : 'border-line bg-paper text-muted hover:border-ink hover:text-ink'
                  }`}
                >
                  {e.season}
                  {e.isPublished ? (
                    <span className={`ml-1.5 text-[10px] ${active ? 'text-white/70' : 'text-brand'}`}>
                      ●
                    </span>
                  ) : null}
                </Link>
              );
            })}
          </div>

          {summary && selected ? (
            <>
              <div className="flex flex-wrap items-center justify-between gap-3">
                <p className="text-sm">
                  <span className="font-semibold">{summary.edition.season}</span>{' '}
                  <span className="text-muted">
                    {summary.edition.isPublished ? '· live on the public site' : '· hidden from the public'}
                  </span>
                </p>
                <ActionForm
                  action={publishEditionAction}
                  submitLabel={summary.edition.isPublished ? 'Hide from public' : 'Publish season'}
                  submitClassName={
                    summary.canPublish || summary.edition.isPublished
                      ? 'rounded-lg bg-ink px-4 py-2 text-sm font-semibold text-white hover:bg-ink-soft disabled:opacity-50'
                      : 'rounded-lg border border-line px-4 py-2 text-sm font-semibold text-muted opacity-50'
                  }
                >
                  <input type="hidden" name="editionId" value={summary.edition.editionId} />
                  <input type="hidden" name="publish" value={String(!summary.edition.isPublished)} />
                </ActionForm>
              </div>

              {/* The numbers an editor is actually judging completeness by. */}
              <div className="grid gap-3 sm:grid-cols-3 lg:grid-cols-6">
                <StatTile figure={summary.counts.total} label="Matches" />
                <StatTile figure={summary.counts.teams} label="Teams" />
                <StatTile figure={summary.counts.goals} label="Goals" />
                <StatTile
                  figure={summary.counts.missingScore}
                  label="No score"
                  sub={summary.counts.missingScore > 0 ? 'needs fixing' : 'complete'}
                />
                <StatTile
                  figure={`${summary.counts.withEvents}/${summary.counts.total}`}
                  label="With events"
                />
                <StatTile
                  figure={summary.events.unattributed}
                  label="Goals, no scorer"
                />
              </div>

              {summary.issues.length > 0 ? (
                <Card className="p-5">
                  <h2 className="display mb-3 text-sm font-bold uppercase tracking-wide">
                    Detected in this season
                  </h2>
                  <ul className="space-y-2">
                    {summary.issues.map((i) => (
                      <li key={i.key} className="flex flex-wrap items-center gap-2 text-sm">
                        <SeverityTag severity={i.severity} />
                        <span className="text-muted">
                          <strong className="text-ink">{i.count}</strong> {i.label}
                        </span>
                        <ActionForm action={createFlagAction} submitLabel="Track as flag" className="inline">
                          <input type="hidden" name="entityType" value="competition_edition" />
                          <input type="hidden" name="entityId" value={summary.edition.editionId} />
                          <input type="hidden" name="severity" value={i.severity} />
                          <input type="hidden" name="reason" value={`${i.count} ${i.label}`} />
                        </ActionForm>
                      </li>
                    ))}
                  </ul>
                </Card>
              ) : null}

              <Card className="overflow-hidden">
                <CardHead
                  title={`Matches (${matches.length})`}
                  hint="Rows needing a score are highlighted"
                  action={{
                    href: `/admin/matches?editionId=${summary.edition.editionId}&needsAttention=true`,
                    label: 'Only problems',
                  }}
                />
                {matches.length === 0 ? (
                  <p className="px-5 py-10 text-center text-sm text-muted">
                    No matches recorded for this season.
                  </p>
                ) : (
                  <ul className="max-h-[32rem] overflow-y-auto">
                    {matches.map((m) => (
                      <li key={m.id} className={problem(m) ? 'bg-gold/10' : ''}>
                        <Link
                          href={`/admin/matches/${m.id}`}
                          className="flex items-center gap-3 border-b border-line px-5 py-2.5 text-sm hover:bg-wash"
                        >
                          <span className="w-20 shrink-0 text-xs text-muted">
                            {m.kickoffAt ? new Date(m.kickoffAt).toLocaleDateString('en-GB') : '—'}
                          </span>
                          <span className="min-w-0 flex-1 truncate text-right">{m.homeTeam.name}</span>
                          <span
                            className={`w-16 shrink-0 text-center nums font-semibold ${
                              problem(m) ? 'text-loss' : ''
                            }`}
                          >
                            {m.homeScore === null || m.awayScore === null
                              ? '– –'
                              : `${m.homeScore}–${m.awayScore}`}
                          </span>
                          <span className="min-w-0 flex-1 truncate">{m.awayTeam.name}</span>
                          <span className="hidden w-24 shrink-0 justify-end gap-1 text-[10px] text-muted sm:flex">
                            {m.eventCount === 0 ? <span>no events</span> : <span>{m.eventCount} ev</span>}
                          </span>
                        </Link>
                      </li>
                    ))}
                  </ul>
                )}
              </Card>
            </>
          ) : null}
        </>
      )}
    </div>
  );
}
