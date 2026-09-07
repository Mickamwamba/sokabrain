import Link from 'next/link';
import { redirect } from 'next/navigation';
import {
  adminFetch,
  AdminApiError,
  type AdminCompetition,
  type IssuesResponse,
} from '@/lib/adminApi';
import { Card, CardHead, StatTile } from '@/components/ui';
import { ActionForm, SeverityTag } from '@/components/admin-ui';
import { IssueFilters } from '@/components/issue-filters';
import { resolveFlagAction } from '../actions';

export const dynamic = 'force-dynamic';

const KIND_LABEL: Record<string, string> = {
  MISSING_SCORE: 'No score recorded',
  GOALS_WITHOUT_EVENTS: 'Goals missing from the event log',
  UNNAMED_SCORER: 'Goal with no scorer',
  EVENTS_CONTRADICT_SCORE: 'Events contradict the score',
  ORPHAN_EVENT: 'Event not attached to a team',
  SELF_FIXTURE: 'Team listed against itself',
};

export default async function AdminIssuesPage(props: PageProps<'/admin/issues'>) {
  const sp = await props.searchParams;
  const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);
  const kind = one(sp.kind);

  let competitions: AdminCompetition[];
  try {
    competitions = (
      await adminFetch<{ competitions: AdminCompetition[] }>('/api/admin/competitions')
    ).competitions;
  } catch (err) {
    if (err instanceof AdminApiError && err.status === 401) redirect('/admin/login');
    if (err instanceof AdminApiError) return <p className="text-sm text-loss">{err.message}</p>;
    throw err;
  }

  const selectable = competitions.filter((c) => c.editions.length > 0);
  const requestedComp = Number(one(sp.competitionId));
  const requestedEdition = Number(one(sp.editionId));

  // A season wins over a competition when they disagree — links from elsewhere
  // in the admin carry only editionId.
  const owner = selectable.find((c) => c.editions.some((e) => e.editionId === requestedEdition));
  const byMatches = [...selectable].sort((a, b) => b.matchCount - a.matchCount);
  const competition = owner ?? selectable.find((c) => c.id === requestedComp) ?? byMatches[0];
  const edition =
    competition?.editions.find((e) => e.editionId === requestedEdition) ?? competition?.editions[0];

  let data: IssuesResponse | null = null;
  if (edition) {
    try {
      data = await adminFetch<IssuesResponse>(
        `/api/admin/editions/${edition.editionId}/match-issues`,
      );
    } catch (err) {
      if (err instanceof AdminApiError && err.status === 401) redirect('/admin/login');
      throw err;
    }
  }

  const shown = (data?.matches ?? []).filter(
    (m) => !kind || m.issues.some((i) => i.kind === kind),
  );

  const kinds = Object.entries(data?.totals.byKind ?? {}).map(([value, count]) => ({
    value,
    label: KIND_LABEL[value] ?? value,
    count,
  }));

  return (
    <div className="space-y-5">
      <div>
        <h1 className="display text-2xl font-extrabold tracking-tight">Issues</h1>
        <p className="mt-1 text-sm text-muted">
          Every match needing attention, in one place. Problems detected from the data
          disappear on their own once fixed; flags stay until you resolve them.
        </p>
      </div>

      {selectable.length > 0 ? (
        <Card className="p-4">
          <IssueFilters
            competitions={selectable.map((c) => ({
              id: c.id, name: c.name, country: c.country, editions: c.editions,
            }))}
            competitionId={competition?.id}
            editionId={edition?.editionId}
            kind={kind}
            kinds={kinds}
          />
        </Card>
      ) : null}

      {data ? (
        <>
          <div className="grid gap-3 sm:grid-cols-4">
            <StatTile figure={data.totals.matchesWithIssues} label="Matches affected"
              sub={`of ${edition?.matchCount ?? 0}`} />
            <StatTile figure={data.totals.blockers} label="Blocking publication" />
            <StatTile figure={data.totals.openFlags} label="Open flags" />
            <StatTile
              figure={data.edition.isPublished ? 'Live' : 'Hidden'}
              label="Public status"
            />
          </div>

          {shown.length === 0 ? (
            <Card className="px-6 py-14 text-center text-sm text-muted">
              {kind
                ? 'No matches have that issue in this season.'
                : `Nothing needs attention in ${data.edition.competition} ${data.edition.season}.`}
            </Card>
          ) : (
            <Card className="overflow-hidden">
              <CardHead
                title={`${shown.length} match${shown.length === 1 ? '' : 'es'}`}
                hint={`${data.edition.competition} ${data.edition.season}`}
              />
              <ul>
                {shown.map((m) => (
                  <li key={m.matchId} className="border-b border-line px-5 py-3 last:border-0">
                    <div className="flex flex-wrap items-baseline gap-x-3 gap-y-1">
                      <Link
                        href={`/admin/matches/${m.matchId}`}
                        className="text-sm font-semibold hover:text-brand"
                      >
                        {m.homeTeam}{' '}
                        <span className="nums text-muted">
                          {m.homeScore === null || m.awayScore === null
                            ? '– –'
                            : `${m.homeScore}–${m.awayScore}`}
                        </span>{' '}
                        {m.awayTeam}
                      </Link>
                      <span className="text-xs text-muted">
                        {m.kickoffAt ? new Date(m.kickoffAt).toLocaleDateString('en-GB') : 'date unknown'}
                        {m.round ? ` · round ${m.round}` : ''}
                      </span>
                    </div>

                    <ul className="mt-1.5 space-y-1">
                      {m.issues.map((i, idx) => (
                        <li key={idx} className="flex flex-wrap items-center gap-2 text-xs">
                          <SeverityTag severity={i.severity} />
                          <span className="text-muted">{i.detail}</span>
                          <Link
                            href={`/admin/matches/${m.matchId}`}
                            className="font-semibold text-brand hover:text-brand-dark"
                          >
                            Fix →
                          </Link>
                        </li>
                      ))}
                      {m.openFlags.map((f) => (
                        <li key={`f${f.id}`} className="flex flex-wrap items-center gap-2 text-xs">
                          <SeverityTag severity={f.severity} />
                          <span className="min-w-0 flex-1 text-muted">{f.reason}</span>
                          <ActionForm
                            action={resolveFlagAction}
                            submitLabel="Resolve"
                            className="flex items-center gap-1.5"
                            submitClassName="rounded border border-line px-2 py-1 text-[11px] font-semibold hover:border-ink disabled:opacity-50"
                          >
                            <input type="hidden" name="flagId" value={f.id} />
                            <input name="note" placeholder="Note (optional)"
                              className="w-40 rounded border border-line bg-paper px-2 py-1 text-[11px]" />
                          </ActionForm>
                        </li>
                      ))}
                    </ul>
                  </li>
                ))}
              </ul>
            </Card>
          )}
        </>
      ) : (
        <Card className="px-6 py-12 text-center text-sm text-muted">
          Pick a competition and season.
        </Card>
      )}
    </div>
  );
}
