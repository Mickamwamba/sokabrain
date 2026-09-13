import Link from 'next/link';
import {
  CalendarDays,
  CalendarPlus,
  Eye,
  EyeOff,
  Flag as FlagIcon,
  ListChecks,
  Pencil,
  Save,
  Trash2,
  ScanSearch,
  Trophy,
} from 'lucide-react';
import {
  adminFetch,
  type AdminEditionRow,
  type AdminMatchRow,
  type AuditFindings,
  type EditionSummary,
  type Lookups,
} from '@/lib/adminApi';
import { load, one } from '@/lib/admin-page';
import { safeReturn } from '@/lib/audit-targets';
import { EntityFindings } from '@/components/admin/entity-findings';
import {
  Badge,
  EmptyState,
  ErrorState,
  Field,
  IncompleteDot,
  PageHeader,
  Panel,
  SeverityBadge,
  StatCard,
  fmtDate,
  humanise,
} from '@/components/admin/kit';
import { ConfirmForm } from '@/components/admin/confirm-form';
import { btn, input } from '@/components/admin/styles';
import {
  createEditionAction,
  createFlagAction,
  deleteEditionAction,
  publishEditionAction,
  updateEditionAction,
} from '../../../actions';

export const dynamic = 'force-dynamic';

type Detail = {
  competition: {
    id: number; name: string; type: string; tier: number | null;
    country: string | null; countryId: number | null;
  };
  editions: AdminEditionRow[];
};

const FORMAT_HINT: Record<string, string> = {
  ROUND_ROBIN: 'Round robin (league)',
  GROUPS_KNOCKOUT: 'Groups, then knockout',
  KNOCKOUT: 'Knockout only',
};

export default async function AdminCompetitionPage(props: PageProps<'/admin/competitions/[id]'>) {
  const { id } = await props.params;
  const sp = await props.searchParams;

  const base = await load(() =>
    Promise.all([
      adminFetch<Detail>(`/api/admin/competitions/${Number(id)}`),
      adminFetch<Lookups>('/api/admin/lookups'),
    ]),
  );
  if (!base.ok) return <ErrorState message={base.error} />;
  const [detail, lookups] = base.data;
  const { competition, editions } = detail;

  const selected = editions.find((e) => String(e.editionId) === one(sp.season)) ?? editions[0];

  const season = selected
    ? await load(() =>
        Promise.all([
          adminFetch<EditionSummary>(`/api/admin/editions/${selected.editionId}/summary`),
          adminFetch<{ matches: AdminMatchRow[] }>(`/api/admin/matches?editionId=${selected.editionId}&limit=500`)
            .then((r) => r.matches),
        ]),
      )
    : null;
  if (season && !season.ok) return <ErrorState message={season.error} />;
  const [summary, matches] = season?.ok ? season.data : [null, [] as AdminMatchRow[]];
  const returnTo = safeReturn(one(sp.from));
  // The season's own findings (settings, missing fixtures); match-level ones
  // live on each match.
  const seasonFindings = selected
    ? await load(() =>
        adminFetch<AuditFindings>(`/api/admin/audit/findings?entityType=competition_edition&entityId=${selected.editionId}&status=ACTIVE`)
          .then((r) => r.findings),
      )
    : null;

  const takenSeasons = new Set(editions.map((e) => e.seasonId));
  const freeSeasons = lookups.seasons.filter((s) => !takenSeasons.has(s.id));
  const noScore = (m: AdminMatchRow) => m.status === 'FULL_TIME' && (m.homeScore === null || m.awayScore === null);

  const addSeason = (
    <Panel title="Add a season" description="Creates an edition of this competition. It starts hidden.">
      {freeSeasons.length === 0 ? (
        <p className="px-5 py-4 text-sm text-muted">
          Every season in the vault already has an edition.{' '}
          <Link href="/admin/seasons" className="font-semibold text-brand hover:text-brand-dark">Create a season</Link> first.
        </p>
      ) : (
        <ConfirmForm
          action={createEditionAction}
          title={`Add a season to ${competition.name}?`}
          description="The new season is hidden from the public until you publish it."
          confirmLabel="Add season"
          review="all"
          trigger={<><CalendarPlus /> Add season</>}
          triggerVariant="secondary"
          className="space-y-4 p-5"
        >
          <input type="hidden" name="competitionId" value={competition.id} />
          <Field label="Season" required>
            <select name="seasonId" required defaultValue="" data-label="Season" className={input}>
              <option value="" disabled>Choose a season…</option>
              {freeSeasons.map((s) => <option key={s.id} value={s.id}>{s.label}</option>)}
            </select>
          </Field>
          <div className="grid grid-cols-2 gap-3">
            <Field label="Format">
              <select name="format" defaultValue="" data-label="Format" className={input}>
                <option value="">Not set</option>
                {lookups.editionFormats.map((f) => <option key={f} value={f}>{FORMAT_HINT[f] ?? humanise(f)}</option>)}
              </select>
            </Field>
            <Field label="Teams">
              <input name="numTeams" type="number" min={2} max={250} data-label="Teams" className={input} />
            </Field>
          </div>
        </ConfirmForm>
      )}
    </Panel>
  );

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<Trophy />}
        back={{ href: '/admin/competitions', label: 'Competitions' }}
        title={competition.name}
        description={[
          competition.country?.replace(', United Republic of', '') ?? 'International',
          humanise(competition.type),
          competition.tier ? `Tier ${competition.tier}` : null,
          `${editions.length} season${editions.length === 1 ? '' : 's'}`,
        ].filter(Boolean).join(' · ')}
        actions={
          <Link href={`/admin/competitions/${competition.id}/edit`} className={btn('secondary')}>
            <Pencil /> Edit details
          </Link>
        }
      />

      {editions.length === 0 || !selected || !summary ? (
        <div className="grid gap-6 lg:grid-cols-3">
          <Panel className="lg:col-span-2">
            <EmptyState icon={<CalendarDays />} title="No seasons yet">
              Add the first season to start recording participants and matches.
            </EmptyState>
          </Panel>
          {addSeason}
        </div>
      ) : (
        <>
          {/* Season selector — one row, scrolls sideways rather than wrapping into a wall. */}
          <div className="-mx-1 flex gap-1.5 overflow-x-auto px-1 pb-1">
            {editions.map((e) => {
              const active = e.editionId === selected.editionId;
              return (
                <Link
                  key={e.editionId}
                  href={`/admin/competitions/${competition.id}?season=${e.editionId}`}
                  className={`inline-flex shrink-0 items-center gap-1.5 rounded-lg border px-3 py-1.5 text-sm font-medium transition-colors ${
                    active ? 'border-ink bg-ink text-white' : 'border-line bg-paper text-muted hover:border-ink/40 hover:text-ink'
                  }`}
                >
                  {e.isPublished ? <span aria-label="live" className="h-1.5 w-1.5 rounded-full bg-brand" /> : null}
                  {e.season}
                </Link>
              );
            })}
          </div>

          <div className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-line bg-paper px-5 py-4 shadow-sm">
            <div className="flex flex-wrap items-center gap-3">
              <h2 className="display text-xl font-extrabold">{summary.edition.season}</h2>
              {summary.edition.isPublished ? (
                <Badge tone="green" dot>Live since {fmtDate(summary.edition.publishedAt)}</Badge>
              ) : (
                <Badge>Hidden from the public</Badge>
              )}
              {!summary.canPublish ? <Badge tone="red">Blocked by a flag</Badge> : null}
            </div>
            <div className="flex flex-wrap items-center gap-2">
              <Link href={`/admin/participants?editionId=${selected.editionId}`} className={btn('secondary', 'sm')}>
                <ListChecks /> Participants
              </Link>
              <Link href={`/admin/audit?competitionId=${competition.id}&editionId=${selected.editionId}`} className={btn('secondary', 'sm')}>
                <ScanSearch /> Data audit
              </Link>
              {summary.edition.isPublished ? (
                <ConfirmForm
                  action={publishEditionAction}
                  tone="danger"
                  title={`Hide ${competition.name} ${summary.edition.season}?`}
                  description="Fans will immediately stop seeing its table, matches and statistics. You can publish it again at any time."
                  confirmLabel="Hide from public"
                  trigger={<><EyeOff /> Unpublish</>}
                  triggerVariant="secondary"
                  triggerSize="sm"
                >
                  <input type="hidden" name="editionId" value={selected.editionId} />
                  <input type="hidden" name="publish" value="false" />
                </ConfirmForm>
              ) : (
                <ConfirmForm
                  action={publishEditionAction}
                  title={`Publish ${competition.name} ${summary.edition.season}?`}
                  description={
                    <>
                      Its {summary.counts.total.toLocaleString()} matches, table and statistics become public straight away.
                      {summary.issues.length ? ` It still has ${summary.issues.length} kinds of detected issue.` : ''}
                    </>
                  }
                  confirmLabel="Publish"
                  trigger={<><Eye /> Publish</>}
                  triggerVariant="success"
                  triggerSize="sm"
                  disabled={!summary.canPublish}
                >
                  <input type="hidden" name="editionId" value={selected.editionId} />
                  <input type="hidden" name="publish" value="true" />
                </ConfirmForm>
              )}
            </div>
          </div>

          <EntityFindings
            findings={seasonFindings?.ok ? seasonFindings.data : []}
            returnTo={returnTo}
            auditHref={`/admin/audit?competitionId=${competition.id}&editionId=${selected.editionId}`}
          />

          <div className="grid grid-cols-2 gap-4 md:grid-cols-3 xl:grid-cols-6">
            <StatCard label="Matches" value={summary.counts.total} />
            <StatCard label="Teams" value={summary.counts.teams} />
            <StatCard label="Goals" value={summary.counts.goals} />
            <StatCard label="No score" value={summary.counts.missingScore}
              tone={summary.counts.missingScore ? 'red' : 'green'} hint={summary.counts.missingScore ? 'needs fixing' : 'complete'} />
            <StatCard label="With events" value={`${summary.counts.withEvents}/${summary.counts.total}`} />
            <StatCard label="Goals, no scorer" value={summary.events.unattributed}
              tone={summary.events.unattributed ? 'amber' : 'green'} />
          </div>

          <div className="grid gap-6 xl:grid-cols-3">
            <Panel
              id="matches"
              className="xl:col-span-2"
              title={`Matches (${matches.length})`}
              description="Completed matches with no score are highlighted"
              actions={
                <Link href={`/admin/matches?editionId=${selected.editionId}`} className={btn('secondary', 'sm')}>
                  <CalendarDays /> Open in Matches
                </Link>
              }
            >
              {matches.length === 0 ? (
                <EmptyState icon={<CalendarDays />} title="No matches recorded for this season" />
              ) : (
                <ul className="max-h-[36rem] divide-y divide-line overflow-y-auto">
                  {matches.map((m) => (
                    <li key={m.id} className={noScore(m) ? 'bg-gold/10' : ''}>
                      <Link href={`/admin/matches/${m.id}`} className="flex items-center gap-3 px-5 py-2.5 text-sm hover:bg-wash">
                        <span className="w-20 shrink-0 text-xs text-muted">{fmtDate(m.kickoffAt)}</span>
                        <span className="min-w-0 flex-1 truncate text-right">{m.homeTeam.name}</span>
                        <span className={`w-14 shrink-0 text-center font-semibold nums ${noScore(m) ? 'text-loss' : ''}`}>
                          {m.homeScore === null || m.awayScore === null ? '– –' : `${m.homeScore}–${m.awayScore}`}
                        </span>
                        <span className="min-w-0 flex-1 truncate">{m.awayTeam.name}</span>
                        <span className="hidden w-20 shrink-0 items-center justify-end gap-2 text-[11px] text-muted sm:flex">
                          <IncompleteDot count={m.unattributedGoals} />
                          {m.eventCount === 0 ? 'no events' : `${m.eventCount} ev`}
                        </span>
                      </Link>
                    </li>
                  ))}
                </ul>
              )}
            </Panel>

            <div className="space-y-6">
              <Panel title="Detected issues">
                {summary.issues.length === 0 ? (
                  <p className="px-5 py-4 text-sm text-muted">Nothing detected in this season.</p>
                ) : (
                  <ul className="divide-y divide-line">
                    {summary.issues.map((i) => (
                      <li key={i.key} className="flex items-center gap-3 px-5 py-3 text-sm">
                        <SeverityBadge severity={i.severity} />
                        <span className="min-w-0 flex-1"><strong>{i.count}</strong> <span className="text-muted">{i.label}</span></span>
                        <ConfirmForm
                          action={createFlagAction}
                          title="Track this as a flag?"
                          description={<>Raises a {i.severity.toLowerCase()} flag: “{i.count} {i.label}”.{i.severity === 'BLOCKER' ? ' A blocker stops this season being published.' : ''}</>}
                          confirmLabel="Raise flag"
                          trigger={<FlagIcon />}
                          triggerAriaLabel="Track as flag"
                          triggerVariant="ghost"
                          triggerSize="sm"
                        >
                          <input type="hidden" name="entityType" value="competition_edition" />
                          <input type="hidden" name="entityId" value={selected.editionId} />
                          <input type="hidden" name="severity" value={i.severity} />
                          <input type="hidden" name="reason" value={`${i.count} ${i.label}`} />
                        </ConfirmForm>
                      </li>
                    ))}
                  </ul>
                )}
              </Panel>

              <Panel id="season-settings" title="Season settings">
                <ConfirmForm
                  action={updateEditionAction}
                  title={`Save ${summary.edition.season} settings?`}
                  confirmLabel="Save changes"
                  review="changes"
                  trigger={<><Save /> Save</>}
                  triggerVariant="secondary"
                  triggerSize="sm"
                  className="space-y-4 p-5"
                >
                  <input type="hidden" name="editionId" value={selected.editionId} />
                  <Field label="Format">
                    <select name="format" defaultValue={selected.format ?? ''} data-label="Format" className={input}>
                      <option value="">Not set</option>
                      {lookups.editionFormats.map((f) => <option key={f} value={f}>{FORMAT_HINT[f] ?? humanise(f)}</option>)}
                    </select>
                  </Field>
                  <Field label="Number of teams" hint="A league uses this to tell how many fixtures a full season has.">
                    <input name="numTeams" type="number" min={2} max={250} defaultValue={selected.numTeams ?? ''}
                      data-label="Number of teams" className={input} />
                  </Field>
                </ConfirmForm>
              </Panel>

              <Panel title="Delete this season" tone="danger">
                <div className="space-y-3 p-5 text-sm">
                  <p className="text-muted">
                    {summary.edition.isPublished
                      ? 'A live season cannot be deleted. Unpublish it first.'
                      : summary.counts.total > 0
                        ? `It has ${summary.counts.total.toLocaleString()} matches, which would have to be removed first. The vault never deletes match history in bulk.`
                        : 'Removes this edition and its participant list. It has no matches.'}
                  </p>
                  <ConfirmForm
                    action={deleteEditionAction}
                    tone="danger"
                    title={`Delete ${competition.name} ${summary.edition.season}?`}
                    description="This removes the edition, its groups and its participant list. It cannot be undone."
                    confirmLabel="Delete season"
                    trigger={<><Trash2 /> Delete season</>}
                    triggerVariant="danger"
                    triggerSize="sm"
                    disabled={summary.edition.isPublished || summary.counts.total > 0}
                  >
                    <input type="hidden" name="editionId" value={selected.editionId} />
                    <input type="hidden" name="competitionId" value={competition.id} />
                  </ConfirmForm>
                </div>
              </Panel>

              {addSeason}
            </div>
          </div>
        </>
      )}
    </div>
  );
}
