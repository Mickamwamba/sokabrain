'use client';

import { useState } from 'react';
import Link from 'next/link';
import {
  CheckCircle2,
  ChevronRight,
  Flame,
  ScanSearch,
  TriangleAlert,
} from 'lucide-react';
import { Badge, Panel } from '@/components/admin/kit';
import { btn } from '@/components/admin/styles';

export type CurrentSeasonData = {
  competitionId: number;
  competitionName: string;
  country: string | null;
  type: string;
  tier: number | null;
  editionId: number;
  seasonLabel: string;
  matchCount: number;
  isPublished: boolean;
  issues: { key: string; count: number; label: string; severity: string }[];
  totalIssues: number;
  blockers: number;
  warnings: number;
  openFlags: number;
  isUrgent: boolean;
  needsReview: boolean;
  isClean: boolean;
};

export function CurrentSeasonAttentionCenter({
  seasons,
}: {
  seasons: CurrentSeasonData[];
}) {
  const [filter, setFilter] = useState<'attention' | 'all' | 'clean'>('attention');

  const urgentCount = seasons.filter((s) => s.isUrgent || s.needsReview).length;
  const cleanCount = seasons.filter((s) => s.isClean).length;

  const filtered = seasons.filter((s) => {
    if (filter === 'attention') return s.isUrgent || s.needsReview;
    if (filter === 'clean') return s.isClean;
    return true;
  });

  return (
    <Panel
      title={
        <div className="flex items-center gap-2">
          <Flame className="h-4 w-4 text-brand" />
          <span>Current Season Attention Center</span>
        </div>
      }
      description="Active seasons of published competitions currently being viewed by fans on the live site"
      actions={
        <div className="flex items-center gap-1.5 rounded-lg bg-wash p-1 text-xs">
          <button
            type="button"
            onClick={() => setFilter('attention')}
            className={`rounded-md px-2.5 py-1 font-medium transition-all ${
              filter === 'attention'
                ? 'bg-paper text-ink shadow-sm ring-1 ring-line'
                : 'text-muted hover:text-ink'
            }`}
          >
            Needs Attention ({urgentCount})
          </button>
          <button
            type="button"
            onClick={() => setFilter('all')}
            className={`rounded-md px-2.5 py-1 font-medium transition-all ${
              filter === 'all'
                ? 'bg-paper text-ink shadow-sm ring-1 ring-line'
                : 'text-muted hover:text-ink'
            }`}
          >
            All Active ({seasons.length})
          </button>
          <button
            type="button"
            onClick={() => setFilter('clean')}
            className={`rounded-md px-2.5 py-1 font-medium transition-all ${
              filter === 'clean'
                ? 'bg-paper text-ink shadow-sm ring-1 ring-line'
                : 'text-muted hover:text-ink'
            }`}
          >
            Clean & Verified ({cleanCount})
          </button>
        </div>
      }
    >
      {filtered.length === 0 ? (
        <div className="py-12 text-center">
          <div className="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-brand/10 text-brand">
            <CheckCircle2 className="h-6 w-6" />
          </div>
          <h3 className="text-base font-bold text-ink">
            {filter === 'attention'
              ? 'No issues on current seasons!'
              : 'No competitions found'}
          </h3>
          <p className="mx-auto mt-1 max-w-sm text-xs text-muted">
            {filter === 'attention'
              ? 'All active published seasons are clean, consistent, and ready for fans.'
              : 'Adjust your filter to view published competitions.'}
          </p>
        </div>
      ) : (
        <div className="divide-y divide-line">
          {filtered.map((s) => (
            <div
              key={s.editionId}
              className="flex flex-col gap-4 p-5 transition-colors hover:bg-wash/50 lg:flex-row lg:items-center lg:justify-between"
            >
              {/* Competition Details */}
              <div className="min-w-0 flex-1">
                <div className="flex flex-wrap items-center gap-2">
                  <span className="text-base font-bold text-ink">
                    {s.competitionName}
                  </span>
                  <span className="rounded bg-wash px-2 py-0.5 text-xs font-semibold text-muted">
                    {s.seasonLabel}
                  </span>
                  {s.country && (
                    <span className="text-xs text-muted">
                      · {s.country.replace(', United Republic of', '')}
                    </span>
                  )}
                  {s.isUrgent ? (
                    <Badge tone="red" dot>
                      Blocker Detected
                    </Badge>
                  ) : s.needsReview ? (
                    <Badge tone="amber" dot>
                      {s.totalIssues} Issue{s.totalIssues === 1 ? '' : 's'}
                    </Badge>
                  ) : (
                    <Badge tone="green" dot>
                      100% Fan Ready
                    </Badge>
                  )}
                </div>

                <div className="mt-1 flex flex-wrap items-center gap-3 text-xs text-muted">
                  <span>{s.matchCount.toLocaleString()} matches</span>
                  {s.openFlags > 0 && (
                    <span className="text-loss font-semibold">
                      · {s.openFlags} open flag{s.openFlags === 1 ? '' : 's'}
                    </span>
                  )}
                </div>

                {/* Specific Issue Pills */}
                {s.issues.length > 0 && (
                  <div className="mt-2.5 flex flex-wrap gap-1.5">
                    {s.issues.map((issue) => (
                      <span
                        key={issue.key}
                        className="inline-flex items-center gap-1.5 rounded-md bg-wash px-2.5 py-1 text-xs ring-1 ring-inset ring-line"
                      >
                        <TriangleAlert className="h-3.5 w-3.5 text-amber-600 shrink-0" />
                        <span className="font-bold text-ink nums">{issue.count}</span>
                        <span className="text-muted">{issue.label}</span>
                      </span>
                    ))}
                  </div>
                )}
              </div>

              {/* Action Buttons */}
              <div className="flex flex-wrap items-center gap-2 shrink-0">
                {s.totalIssues > 0 || s.openFlags > 0 ? (
                  <Link
                    href={`/admin/audit?editionId=${s.editionId}`}
                    className={btn('primary', 'sm')}
                  >
                    <ScanSearch /> Fix & Audit
                  </Link>
                ) : (
                  <Link
                    href={`/admin/audit?editionId=${s.editionId}`}
                    className={btn('secondary', 'sm')}
                  >
                    <ScanSearch /> Audit
                  </Link>
                )}

                <Link
                  href={`/admin/matches?editionId=${s.editionId}`}
                  className={btn('secondary', 'sm')}
                >
                  Matches
                </Link>

                <Link
                  href={`/admin/competitions/${s.competitionId}`}
                  className={btn('ghost', 'sm')}
                  title="Competition Overview"
                >
                  Manage <ChevronRight className="h-3.5 w-3.5" />
                </Link>
              </div>
            </div>
          ))}
        </div>
      )}
    </Panel>
  );
}
