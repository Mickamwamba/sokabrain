import Link from 'next/link';
import {
  AlertTriangle,
  ArrowRight,
  CalendarRange,
  CheckCircle2,
  CircleCheck,
  Eye,
  Flag as FlagIcon,
  Heart,
  LayoutDashboard,
  MessageCircle,
  MessagesSquare,
  Pin,
  ScanSearch,
  TriangleAlert,
  Trophy,
  Wrench,
} from 'lucide-react';
import {
  adminFetch,
  type AdminCompetition,
  type AdminEdition,
  type AdminKijiweniStats,
  type AuditRun,
  type Flag,
} from '@/lib/adminApi';
import { load } from '@/lib/admin-page';
import {
  Badge,
  EmptyState,
  ErrorState,
  PageHeader,
  Panel,
  SeverityBadge,
  StatCard,
  fmtDate,
  fmtDateTime,
} from '@/components/admin/kit';
import { btn } from '@/components/admin/styles';
import {
  CurrentSeasonAttentionCenter,
  type CurrentSeasonData,
} from '@/components/admin/current-season-attention-center';

export const dynamic = 'force-dynamic';

export default async function AdminDashboardPage() {
  const res = await load(() =>
    Promise.all([
      adminFetch<{ editions: AdminEdition[] }>('/api/admin/editions').then((r) => r.editions),
      adminFetch<{ flags: Flag[] }>('/api/admin/flags?status=OPEN&limit=6').then((r) => r.flags),
      adminFetch<{ competitions: AdminCompetition[] }>('/api/admin/competitions').then((r) => r.competitions),
      adminFetch<AdminKijiweniStats>('/api/admin/kijiweni/stats'),
      adminFetch<{ runs: AuditRun[] }>('/api/admin/audit/runs?limit=1').then((r) => r.runs),
    ]),
  );

  if (!res.ok) return <ErrorState message={res.error} />;
  const [
    editions,
    flags,
    competitions,
    kijiweniStats,
    auditRuns,
  ] = res.data;

  // Filter published competitions
  const publishedComps = competitions.filter((c) => c.publishedCount > 0);

  // Map each published competition to its active/current published season
  const currentSeasonData: CurrentSeasonData[] = publishedComps.map((comp) => {
    // Find the latest published edition for this competition
    const latestPublishedSummary = comp.editions.find((e) => e.isPublished);
    // Retrieve full edition data including flags and suggested issues
    const fullEdition = editions.find((e) => e.editionId === latestPublishedSummary?.editionId);

    const issues = fullEdition?.issues ?? [];
    const totalIssues = issues.reduce((acc, i) => acc + i.count, 0);
    const blockers = fullEdition?.flags.BLOCKER ?? 0;
    const warnings = fullEdition?.flags.WARNING ?? 0;
    const openFlags = fullEdition?.openFlags ?? 0;

    const hasMissingScores = issues.some((i) => i.key === 'missing_scores' && i.count > 0);
    const isUrgent = blockers > 0 || hasMissingScores;
    const needsReview = totalIssues > 0 || warnings > 0 || openFlags > 0;
    const isClean = !isUrgent && !needsReview;

    return {
      competitionId: comp.id,
      competitionName: comp.displayName,
      country: comp.country,
      type: comp.type,
      tier: comp.tier,
      editionId: latestPublishedSummary?.editionId ?? 0,
      seasonLabel: latestPublishedSummary?.season ?? 'Current',
      matchCount: latestPublishedSummary?.matchCount ?? 0,
      isPublished: true,
      issues,
      totalIssues,
      blockers,
      warnings,
      openFlags,
      isUrgent,
      needsReview,
      isClean,
    };
  });

  // Sort: Urgent issues first, then Needs Review, then Clean
  currentSeasonData.sort((a, b) => {
    if (a.isUrgent !== b.isUrgent) return a.isUrgent ? -1 : 1;
    if (a.needsReview !== b.needsReview) return a.needsReview ? -1 : 1;
    return b.totalIssues - a.totalIssues;
  });

  const urgentCurrentCount = currentSeasonData.filter((s) => s.isUrgent).length;
  const reviewCurrentCount = currentSeasonData.filter((s) => !s.isUrgent && s.needsReview).length;
  const cleanCurrentCount = currentSeasonData.filter((s) => s.isClean).length;
  const totalCurrentSeasonIssues = currentSeasonData.reduce((sum, s) => sum + s.totalIssues, 0);

  // Historical editions with issues (excluding the current ones)
  const currentEditionIds = new Set(currentSeasonData.map((s) => s.editionId));
  const historicalWithIssues = editions
    .filter((e) => !currentEditionIds.has(e.editionId) && e.matchCount > 0 && e.issues.length > 0)
    .sort((a, b) => {
      const countA = a.issues.reduce((n, i) => n + i.count, 0);
      const countB = b.issues.reduce((n, i) => n + i.count, 0);
      return a.isPublished !== b.isPublished ? (a.isPublished ? -1 : 1) : countB - countA;
    });

  const lastAudit = auditRuns[0];

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <PageHeader
        icon={<LayoutDashboard />}
        title="Command Dashboard"
        description="Live match integrity, published competition health, fan zone moderation, and vault operations."
        actions={
          <div className="flex flex-wrap items-center gap-2">
            <Link href="/admin/audit" className={btn('secondary')}>
              <ScanSearch /> System Audit
            </Link>
            <Link href="/admin/kijiweni" className={btn('secondary')}>
              <MessagesSquare /> Fan Zone
            </Link>
            <Link href="/" target="_blank" className={btn('primary')}>
              <Eye /> View Public Site
            </Link>
          </div>
        }
      />

      {/* Immediate Attention Alert Banner (if live seasons have problems) */}
      {urgentCurrentCount > 0 ? (
        <div className="flex items-start justify-between gap-4 rounded-xl border border-loss/30 bg-loss/10 p-4 text-sm text-loss dark:text-red-300">
          <div className="flex items-start gap-3">
            <AlertTriangle className="h-5 w-5 shrink-0 text-loss mt-0.5" />
            <div>
              <p className="font-bold">
                Urgent Action Required: {urgentCurrentCount} active competition
                {urgentCurrentCount === 1 ? '' : 's'} have critical issues in their current season!
              </p>
              <p className="mt-0.5 text-xs opacity-90">
                Completed matches with missing scores or open blocker flags directly impact the public standings and fan experience.
              </p>
            </div>
          </div>
          <Link href="/admin/audit" className={btn('primary', 'sm')}>
            Resolve Blockers
          </Link>
        </div>
      ) : reviewCurrentCount > 0 ? (
        <div className="flex items-center justify-between gap-4 rounded-xl border border-line border-l-4 border-l-amber-500 bg-paper p-4 text-sm shadow-sm">
          <div className="flex items-start gap-3">
            <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-amber-500/10 text-amber-600 ring-1 ring-amber-500/20">
              <TriangleAlert className="h-5 w-5" />
            </span>
            <div>
              <p className="font-bold text-ink">
                {reviewCurrentCount} active competition{reviewCurrentCount === 1 ? '' : 's'} need review on current season data
              </p>
              <p className="mt-0.5 text-xs text-muted">
                Unattributed goal scorers or matches missing event logs have been detected in live published editions.
              </p>
            </div>
          </div>
          <Link href="#current-seasons" className={btn('secondary', 'sm')}>
            Review Issues
          </Link>
        </div>
      ) : (
        <div className="flex items-center justify-between gap-4 rounded-xl border border-brand/30 bg-brand/10 p-4 text-sm text-brand-dark dark:text-emerald-300">
          <div className="flex items-center gap-3">
            <CheckCircle2 className="h-5 w-5 shrink-0 text-brand" />
            <div>
              <p className="font-bold">All active published seasons are clean & verified</p>
              <p className="text-xs opacity-90">
                Fans are seeing 100% verified scores and events across all {publishedComps.length} live competitions.
              </p>
            </div>
          </div>
          <Badge tone="green">All Clean</Badge>
        </div>
      )}

      {/* Primary KPI Grid */}
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-5">
        <StatCard
          label="Published Leagues"
          value={publishedComps.length}
          icon={<Trophy />}
          tone="blue"
          hint={`${cleanCurrentCount} clean · ${urgentCurrentCount + reviewCurrentCount} with issues`}
        />
        <StatCard
          label="Active Seasons"
          value={currentSeasonData.length}
          icon={<CalendarRange />}
          tone="green"
          hint={`${currentSeasonData.reduce((n, s) => n + s.matchCount, 0).toLocaleString()} live matches`}
        />
        <StatCard
          label="Current Season Issues"
          value={totalCurrentSeasonIssues}
          icon={<TriangleAlert />}
          tone={urgentCurrentCount > 0 ? 'red' : totalCurrentSeasonIssues > 0 ? 'amber' : 'green'}
          hint={urgentCurrentCount > 0 ? `${urgentCurrentCount} blocker` : 'active season items'}
        />
        <StatCard
          label="Open Flags"
          value={flags.length === 6 ? '6+' : flags.length}
          icon={<FlagIcon />}
          tone={flags.length ? 'amber' : 'green'}
          hint="across entire vault"
        />
        <StatCard
          label="Fan Zone Activity"
          value={kijiweniStats.totalThreads}
          icon={<MessagesSquare />}
          tone="blue"
          hint={`${kijiweniStats.totalComments} replies · ${kijiweniStats.totalLikes} likes`}
        />
      </div>

      {/* Featured Section: Current Season Attention Center */}
      <div id="current-seasons">
        <CurrentSeasonAttentionCenter seasons={currentSeasonData} />
      </div>

      {/* Operations 2-Column Grid */}
      <div className="grid gap-6 xl:grid-cols-2">
        {/* Left: Open Data Flags & Audit Status */}
        <div className="space-y-6">
          <Panel
            title="Open Data Flags"
            description="Items flagged by editors or automated checks requiring review"
            actions={
              <Link href="/admin/flags" className={btn('secondary', 'sm')}>
                All Flags <ArrowRight />
              </Link>
            }
          >
            {flags.length === 0 ? (
              <EmptyState icon={<CircleCheck />} title="No open flags" />
            ) : (
              <ul className="divide-y divide-line">
                {flags.map((f) => (
                  <li key={f.id} className="px-5 py-3.5 text-sm hover:bg-wash/40 transition-colors">
                    <div className="flex items-center justify-between gap-2">
                      <div className="flex items-center gap-2">
                        <SeverityBadge severity={f.severity} />
                        <span className="text-xs text-muted">
                          {f.entityType.replaceAll('_', ' ')} #{f.entityId}
                        </span>
                      </div>
                      <span className="text-xs text-muted">{fmtDate(f.createdAt)}</span>
                    </div>
                    <p className="mt-1 line-clamp-2 text-ink font-medium">{f.reason}</p>
                  </li>
                ))}
              </ul>
            )}
          </Panel>

          {/* Audit Freshness Card */}
          <Panel title="Automated Integrity Audit">
            <div className="p-5 text-sm">
              <div className="flex items-center justify-between">
                <div>
                  <span className="font-semibold text-ink">Last Audit Run:</span>{' '}
                  <span className="text-muted">
                    {lastAudit?.finishedAt ? fmtDateTime(lastAudit.finishedAt) : 'Never'}
                  </span>
                </div>
                {lastAudit?.status === 'COMPLETED' ? (
                  <Badge tone="green">Completed</Badge>
                ) : (
                  <Badge tone="gray">{lastAudit?.status ?? 'None'}</Badge>
                )}
              </div>
              <div className="mt-3 grid grid-cols-3 gap-2 rounded-lg bg-wash p-3 text-center text-xs">
                <div>
                  <span className="block text-muted">Checks Run</span>
                  <span className="text-base font-bold text-ink nums">{lastAudit?.checksRun ?? 0}</span>
                </div>
                <div>
                  <span className="block text-muted">Detected</span>
                  <span className="text-base font-bold text-ink nums">{lastAudit?.detected ?? 0}</span>
                </div>
                <div>
                  <span className="block text-muted">Resolved</span>
                  <span className="text-base font-bold text-brand nums">{lastAudit?.resolved ?? 0}</span>
                </div>
              </div>
              <div className="mt-4 flex justify-end">
                <Link href="/admin/audit" className={btn('secondary', 'sm')}>
                  <ScanSearch /> Run New System Audit
                </Link>
              </div>
            </div>
          </Panel>
        </div>

        {/* Right: Fan Zone Community Activity */}
        <Panel
          title="Fan Zone (Kijiweni) Activity"
          description="Recent fan discussions, banter, and community posts"
          actions={
            <Link href="/admin/kijiweni" className={btn('secondary', 'sm')}>
              Moderate <ArrowRight />
            </Link>
          }
        >
          {kijiweniStats.recentThreads.length === 0 ? (
            <EmptyState icon={<MessagesSquare />} title="No community activity yet" />
          ) : (
            <ul className="divide-y divide-line">
              {kijiweniStats.recentThreads.map((t) => (
                <li key={t.id} className="p-4 hover:bg-wash/40 transition-colors">
                  <div className="flex items-start justify-between gap-2">
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-2">
                        <span
                          className="inline-flex items-center rounded px-1.5 py-0.5 text-[10px] font-bold"
                          style={{
                            backgroundColor: `${t.space.badgeColor}15`,
                            color: t.space.badgeColor,
                          }}
                        >
                          {t.space.nameSw}
                        </span>
                        {t.isPinned && (
                          <span className="inline-flex items-center gap-0.5 text-[10px] font-semibold text-amber-600">
                            <Pin className="h-2.5 w-2.5" /> Pinned
                          </span>
                        )}
                        <span className="text-xs text-muted">by {t.authorName}</span>
                      </div>
                      <Link
                        href={`/kijiweni?thread=${t.id}`}
                        target="_blank"
                        className="mt-1 block font-semibold text-ink hover:text-brand transition-colors line-clamp-1"
                      >
                        {t.title}
                      </Link>
                    </div>

                    <div className="flex items-center gap-2 shrink-0 text-xs text-muted nums">
                      <span className="inline-flex items-center gap-1">
                        <MessageCircle className="h-3 w-3" /> {t.commentsCount}
                      </span>
                      <span className="inline-flex items-center gap-1">
                        <Heart className="h-3 w-3 text-loss" /> {t.likesCount}
                      </span>
                    </div>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </Panel>
      </div>

      {/* Historical Seasons Back-Catalog */}
      <Panel
        title="Historical Seasons Back-Catalog"
        description="Older archived seasons with data issues requiring backfill or reconciliation"
      >
        {historicalWithIssues.length === 0 ? (
          <EmptyState icon={<CircleCheck />} title="All historical seasons are clean" />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[640px] text-sm">
              <thead className="border-b border-line bg-wash/60">
                <tr>
                  <th className="py-2.5 pl-5 pr-3 text-left font-semibold text-muted text-xs">Competition & Season</th>
                  <th className="px-3 py-2.5 text-left font-semibold text-muted text-xs">Status</th>
                  <th className="px-3 py-2.5 text-left font-semibold text-muted text-xs">Issues</th>
                  <th className="py-2.5 pl-3 pr-5 text-right font-semibold text-muted text-xs">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-line">
                {historicalWithIssues.slice(0, 8).map((e) => (
                  <tr key={e.editionId} className="hover:bg-wash/60">
                    <td className="py-3 pl-5 pr-3">
                      <span className="font-semibold text-ink">{e.competition}</span>{' '}
                      <span className="text-muted">{e.season}</span>
                      <span className="ml-2 text-xs text-muted">({e.matchCount} matches)</span>
                    </td>
                    <td className="px-3 py-3">
                      {e.isPublished ? (
                        <Badge tone="green" dot>
                          Live
                        </Badge>
                      ) : (
                        <Badge>Hidden</Badge>
                      )}
                    </td>
                    <td className="px-3 py-3 text-xs text-muted">
                      {e.issues.map((i) => `${i.count} ${i.label}`).join(' · ')}
                    </td>
                    <td className="py-3 pl-3 pr-5 text-right">
                      <Link
                        href={`/admin/audit?editionId=${e.editionId}`}
                        className={btn('secondary', 'sm')}
                      >
                        <Wrench className="h-3.5 w-3.5" /> Fix
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Panel>
    </div>
  );
}
