import Link from 'next/link';
import { CalendarDays } from 'lucide-react';
import { adminFetch, type AdminCompetition, type AdminMatchRow } from '@/lib/adminApi';
import { load, one } from '@/lib/admin-page';
import {
  Badge, EmptyState, ErrorState, IncompleteDot, PageHeader, Panel, SeverityBadge, fmtDate,
} from '@/components/admin/kit';
import { MatchFilters } from '@/components/admin/match-filters';
import { btn } from '@/components/admin/styles';

export const dynamic = 'force-dynamic';

export default async function AdminMatchesPage(props: PageProps<'/admin/matches'>) {
  const sp = await props.searchParams;
  const needsAttention = one(sp.needsAttention) === 'true';

  const comps = await load(() =>
    adminFetch<{ competitions: AdminCompetition[] }>('/api/admin/competitions').then((r) => r.competitions),
  );
  if (!comps.ok) return <ErrorState message={comps.error} />;
  const selectable = comps.data.filter((c) => c.editions.length > 0);

  // A specific season wins over a competition when they disagree — links from
  // elsewhere carry only editionId, the more precise intent. Otherwise open on
  // the largest competition's newest season, which is worth working on.
  const wantEdition = Number(one(sp.editionId));
  const competition =
    selectable.find((c) => c.editions.some((e) => e.editionId === wantEdition)) ??
    selectable.find((c) => c.id === Number(one(sp.competitionId))) ??
    [...selectable].sort((a, b) => b.matchCount - a.matchCount)[0];
  const edition = competition?.editions.find((e) => e.editionId === wantEdition) ?? competition?.editions[0];

  let matches: AdminMatchRow[] = [];
  let total = 0;
  if (edition) {
    const qs = new URLSearchParams({ editionId: String(edition.editionId), limit: '500' });
    if (needsAttention) qs.set('needsAttention', 'true');
    const res = await load(() => adminFetch<{ total: number; matches: AdminMatchRow[] }>(`/api/admin/matches?${qs}`));
    if (!res.ok) return <ErrorState message={res.error} />;
    ({ matches, total } = res.data);
  }

  const noScore = (m: AdminMatchRow) => m.status === 'FULL_TIME' && (m.homeScore === null || m.awayScore === null);

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<CalendarDays />}
        title="Matches"
        description="Results, events and scorers, one season at a time."
      />

      {selectable.length ? (
        <Panel bodyClassName="p-5">
          <MatchFilters
            competitions={selectable.map((c) => ({ id: c.id, name: c.name, country: c.country, editions: c.editions }))}
            competitionId={competition?.id}
            editionId={edition?.editionId}
            needsAttention={needsAttention}
          />
        </Panel>
      ) : null}

      {!competition || !edition ? (
        <Panel><EmptyState icon={<CalendarDays />} title="No competition has any seasons recorded" /></Panel>
      ) : (
        <Panel
          title={`${competition.name} ${edition.season}`}
          description={`${total.toLocaleString()} match${total === 1 ? '' : 'es'}${needsAttention ? ' needing a score' : ''}`}
          actions={
            <>
              {edition.isPublished ? <Badge tone="green" dot>Live</Badge> : <Badge>Hidden</Badge>}
              <Link href={`/admin/competitions/${competition.id}?season=${edition.editionId}`} className={btn('secondary', 'sm')}>
                Season overview
              </Link>
            </>
          }
        >
          {matches.length === 0 ? (
            <EmptyState icon={<CalendarDays />} title={needsAttention ? 'Nothing needs a score in this season' : 'No matches recorded'}>
              {needsAttention ? (
                <Link href={`/admin/matches?editionId=${edition.editionId}`} className="font-semibold text-brand">Show all matches</Link>
              ) : null}
            </EmptyState>
          ) : (
            <ul className="divide-y divide-line">
              {matches.map((m) => (
                <li key={m.id} className={noScore(m) ? 'bg-gold/10' : ''}>
                  <Link href={`/admin/matches/${m.id}`} className="flex items-center gap-3 px-5 py-2.5 text-sm hover:bg-wash">
                    <span className="w-24 shrink-0 text-xs text-muted">{fmtDate(m.kickoffAt)}</span>
                    <span className="min-w-0 flex-1 truncate text-right font-medium">{m.homeTeam.name}</span>
                    <span className={`w-16 shrink-0 rounded-md bg-wash py-1 text-center font-semibold nums ${noScore(m) ? 'text-loss' : ''}`}>
                      {m.homeScore === null || m.awayScore === null ? '– –' : `${m.homeScore}–${m.awayScore}`}
                    </span>
                    <span className="min-w-0 flex-1 truncate font-medium">{m.awayTeam.name}</span>
                    <span className="hidden w-40 shrink-0 items-center justify-end gap-2 md:flex">
                      {m.openFlags.map((s, i) => <SeverityBadge key={i} severity={s} />)}
                      <IncompleteDot count={m.unattributedGoals} />
                      <span className="text-[11px] text-muted">{m.eventCount === 0 ? 'no events' : `${m.eventCount} events`}</span>
                    </span>
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </Panel>
      )}
    </div>
  );
}
