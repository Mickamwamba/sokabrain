import Link from 'next/link';
import { ArrowLeft, ScanSearch } from 'lucide-react';
import type { AuditFinding } from '@/lib/adminApi';
import { Badge, type Tone } from './kit';
import { FindingActions } from './finding-actions';
import { btn } from './styles';

const SEVERITY_TONE: Record<string, Tone> = { CRITICAL: 'red', WARNING: 'amber', INFO: 'gray' };
const STATUS: Record<string, { label: string; tone: Tone }> = {
  OPEN: { label: 'Open', tone: 'red' },
  FIXED: { label: 'Fixed — awaiting a run', tone: 'blue' },
  ACCEPTED: { label: 'Accepted', tone: 'gray' },
};

/**
 * The audit's findings for the record on screen, above the part of the page
 * where they get fixed. Mark one fixed here once the data is corrected; the
 * next audit run confirms it.
 */
export function EntityFindings({
  findings,
  returnTo,
  auditHref,
}: {
  findings: AuditFinding[];
  /** The filtered audit list the editor came from, if they came from one. */
  returnTo: string | null;
  /** Where "see all in the audit" goes when they didn't. */
  auditHref: string;
}) {
  if (findings.length === 0 && !returnTo) return null;
  return (
    <section className="overflow-hidden rounded-xl border border-gold/40 bg-gold/5 shadow-sm">
      <header className="flex flex-wrap items-center justify-between gap-3 border-b border-gold/30 px-5 py-3">
        <h2 className="flex items-center gap-2 text-sm font-bold">
          <ScanSearch className="h-4 w-4" />
          {findings.length
            ? `${findings.length} audit finding${findings.length === 1 ? '' : 's'} to fix here`
            : 'No open audit findings here'}
        </h2>
        <Link href={returnTo ?? auditHref} className={btn('secondary', 'sm')}>
          <ArrowLeft /> {returnTo ? 'Back to the audit' : 'Open in Data audit'}
        </Link>
      </header>
      {findings.length ? (
        <ul className="divide-y divide-gold/20">
          {findings.map((f) => (
            <li key={f.id} className="flex flex-wrap items-start gap-3 px-5 py-3 text-sm">
              <Badge tone={SEVERITY_TONE[f.severity]}>{f.severity.charAt(0) + f.severity.slice(1).toLowerCase()}</Badge>
              <div className="min-w-0 flex-1">
                <p className="font-semibold">{f.check.label}</p>
                <p className="text-xs text-muted">{f.detail}</p>
                {f.status !== 'OPEN' ? (
                  <p className="mt-1 text-xs text-muted">
                    <Badge tone={STATUS[f.status]!.tone}>{STATUS[f.status]!.label}</Badge>
                    {f.reviewedBy ? ` ${f.reviewedBy}${f.reviewNote ? `: “${f.reviewNote}”` : ''}` : ''}
                  </p>
                ) : null}
              </div>
              <FindingActions finding={f} />
            </li>
          ))}
        </ul>
      ) : (
        <p className="px-5 py-3 text-sm text-muted">
          Everything the audit flagged here has been dealt with. Run the audit again to confirm.
        </p>
      )}
    </section>
  );
}
