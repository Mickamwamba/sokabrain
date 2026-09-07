import Link from 'next/link';
import { redirect } from 'next/navigation';
import { adminFetch, AdminApiError, type AdminCompetition, type AdminMatchRow } from '@/lib/adminApi';
import { Card, CardHead } from '@/components/ui';
import { IncompleteDot, SeverityTag } from '@/components/admin-ui';
import { MatchFilters } from '@/components/match-filters';

export const dynamic = 'force-dynamic';

export default async function AdminMatchesPage(props: PageProps<'/admin/matches'>) {
  const sp = await props.searchParams;
  const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);
  const needsAttention = one(sp.needsAttention) === 'true';

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

  // Only competitions that actually have seasons are selectable.
  const selectable = competitions.filter((c) => c.editions.length > 0);

  // Resolve the selection, falling back to the biggest competition's newest
  // season so the screen always opens on something worth working on.
  const requestedComp = Number(one(sp.competitionId));
  const requestedEdition = Number(one(sp.editionId));

  const byMatches = [...selectable].sort((a, b) => b.matchCount - a.matchCount);

  // A specific season wins over a competition when the two disagree — links
  // from elsewhere in the admin carry only editionId, and that is the more
  // precise intent. Otherwise fall back to the largest competition's newest
  // season, so the screen always opens on something worth working on.
  const ownerOfEdition = selectable.find((c) =>
    c.editions.some((e) => e.editionId === requestedEdition),
  );
  const competition =
    ownerOfEdition ?? selectable.find((c) => c.id === requestedComp) ?? byMatches[0];

  const edition =
    competition?.editions.find((e) => e.editionId === requestedEdition) ??
    competition?.editions[0];

  let matches: AdminMatchRow[] = [];
  let total = 0;
  if (edition) {
    const qs = new URLSearchParams({ editionId: String(edition.editionId), limit: '500' });
    if (needsAttention) qs.set('needsAttention', 'true');
    try {
      const res = await adminFetch<{ total: number; matches: AdminMatchRow[] }>(
        `/api/admin/matches?${qs}`,
      );
      matches = res.matches;
      total = res.total;
    } catch (err) {
      if (err instanceof AdminApiError && err.status === 401) redirect('/admin/login');
      throw err;
    }
  }

  const noScore = (m: AdminMatchRow) =>
    m.status === 'FULL_TIME' && (m.homeScore === null || m.awayScore === null);

  return (
    <div className="space-y-5">
      <div>
        <h1 className="display text-2xl font-extrabold tracking-tight">Matches</h1>
        <p className="mt-1 text-sm text-muted">
          {competition && edition
            ? `${competition.name} · ${edition.season}`
            : 'No competition has any seasons recorded.'}
        </p>
      </div>

      {selectable.length > 0 ? (
        <Card className="p-4">
          <MatchFilters
            competitions={selectable.map((c) => ({
              id: c.id,
              name: c.name,
              country: c.country,
              editions: c.editions,
            }))}
            competitionId={competition?.id}
            editionId={edition?.editionId}
            needsAttention={needsAttention}
          />
        </Card>
      ) : null}

      {!edition ? (
        <Card className="px-6 py-12 text-center text-sm text-muted">
          Pick a competition and season to see its matches.
        </Card>
      ) : (
        <Card className="overflow-hidden">
          <CardHead
            title={`${total} match${total === 1 ? '' : 'es'}`}
            hint={needsAttention ? 'Completed matches with no score recorded' : undefined}
            action={{
              href: `/admin/competitions/${competition!.id}?season=${edition.editionId}`,
              label: 'Season overview',
            }}
          />
          {matches.length === 0 ? (
            <p className="px-5 py-12 text-center text-sm text-muted">
              {needsAttention
                ? 'Nothing needs a score in this season. '
                : 'No matches recorded for this season.'}
              {needsAttention ? (
                <Link
                  href={`/admin/matches?competitionId=${competition!.id}&editionId=${edition.editionId}`}
                  className="font-semibold text-brand hover:text-brand-dark"
                >
                  Show all matches
                </Link>
              ) : null}
            </p>
          ) : (
            <ul>
              {matches.map((m) => (
                <li key={m.id} className={noScore(m) ? 'bg-gold/10' : ''}>
                  <Link
                    href={`/admin/matches/${m.id}`}
                    className="flex items-center gap-3 border-b border-line px-5 py-2.5 text-sm hover:bg-wash"
                  >
                    <span className="w-20 shrink-0 text-xs text-muted">
                      {m.kickoffAt ? new Date(m.kickoffAt).toLocaleDateString('en-GB') : '—'}
                    </span>
                    <span className="min-w-0 flex-1 truncate text-right font-medium">
                      {m.homeTeam.name}
                    </span>
                    <span
                      className={`w-16 shrink-0 text-center nums font-semibold ${noScore(m) ? 'text-loss' : ''}`}
                    >
                      {m.homeScore === null || m.awayScore === null
                        ? '– –'
                        : `${m.homeScore}–${m.awayScore}`}
                    </span>
                    <span className="min-w-0 flex-1 truncate font-medium">{m.awayTeam.name}</span>
                    <span className="flex w-32 shrink-0 items-center justify-end gap-2">
                      {m.openFlags.map((s, i) => (
                        <SeverityTag key={i} severity={s} />
                      ))}
                      <IncompleteDot count={m.unattributedGoals} />
                      <span className="text-[10px] text-muted">
                        {m.eventCount === 0 ? 'no ev' : `${m.eventCount} ev`}
                      </span>
                    </span>
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </Card>
      )}
    </div>
  );
}
