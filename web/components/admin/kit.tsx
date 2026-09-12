import Link from 'next/link';
import type { ReactNode } from 'react';
import { ArrowLeft, ChevronLeft, ChevronRight, CircleAlert, Search } from 'lucide-react';
import { btn, input } from './styles';

/**
 * Server-safe building blocks for every admin screen.
 *
 * Nothing here holds state, so pages stay server components and only the
 * pieces that genuinely interact (dialogs, filters, the sidebar) ship
 * JavaScript.
 */

export function PageHeader({
  title,
  description,
  icon,
  actions,
  back,
}: {
  title: ReactNode;
  description?: ReactNode;
  icon?: ReactNode;
  actions?: ReactNode;
  back?: { href: string; label: string };
}) {
  return (
    <div className="mb-6">
      {back ? (
        <Link
          href={back.href}
          className="mb-3 inline-flex items-center gap-1 text-sm text-muted hover:text-ink"
        >
          <ArrowLeft className="h-3.5 w-3.5" /> {back.label}
        </Link>
      ) : null}
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div className="flex min-w-0 items-start gap-3">
          {icon ? (
            <span className="mt-0.5 flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-paper text-ink shadow-sm ring-1 ring-line [&_svg]:h-5 [&_svg]:w-5">
              {icon}
            </span>
          ) : null}
          <div className="min-w-0">
            <h1 className="display text-2xl font-extrabold tracking-tight">{title}</h1>
            {description ? <p className="mt-1 text-sm text-muted">{description}</p> : null}
          </div>
        </div>
        {actions ? <div className="flex flex-wrap items-center gap-2">{actions}</div> : null}
      </div>
    </div>
  );
}

export function Panel({
  title,
  description,
  actions,
  children,
  className = '',
  bodyClassName = '',
  tone = 'default',
}: {
  title?: ReactNode;
  description?: ReactNode;
  actions?: ReactNode;
  children: ReactNode;
  className?: string;
  bodyClassName?: string;
  tone?: 'default' | 'danger';
}) {
  return (
    <section
      className={`overflow-hidden rounded-xl border bg-paper shadow-sm ${
        tone === 'danger' ? 'border-loss/30' : 'border-line'
      } ${className}`}
    >
      {title || actions ? (
        <header className="flex flex-wrap items-center justify-between gap-3 border-b border-line px-5 py-3.5">
          <div className="min-w-0">
            {title ? (
              <h2 className={`text-sm font-bold ${tone === 'danger' ? 'text-loss' : ''}`}>{title}</h2>
            ) : null}
            {description ? <p className="mt-0.5 text-xs text-muted">{description}</p> : null}
          </div>
          {actions ? <div className="flex flex-wrap items-center gap-2">{actions}</div> : null}
        </header>
      ) : null}
      <div className={bodyClassName}>{children}</div>
    </section>
  );
}

export type Tone = 'green' | 'gray' | 'amber' | 'red' | 'blue';

const TONE: Record<Tone, string> = {
  green: 'bg-brand/10 text-brand-dark ring-brand/20',
  gray: 'bg-wash text-muted ring-line',
  amber: 'bg-gold/15 text-[#8a5a00] ring-gold/30',
  red: 'bg-loss/10 text-loss ring-loss/20',
  blue: 'bg-sky-50 text-sky-700 ring-sky-200',
};

export function Badge({ tone = 'gray', children, dot = false }: {
  tone?: Tone; children: ReactNode; dot?: boolean;
}) {
  return (
    <span
      className={`inline-flex items-center gap-1 whitespace-nowrap rounded-full px-2 py-0.5 text-[11px] font-semibold ring-1 ring-inset ${TONE[tone]}`}
    >
      {dot ? <span aria-hidden className="h-1.5 w-1.5 rounded-full bg-current" /> : null}
      {children}
    </span>
  );
}

export function SeverityBadge({ severity }: { severity: string }) {
  const tone: Tone = severity === 'BLOCKER' ? 'red' : severity === 'WARNING' ? 'amber' : 'gray';
  return <Badge tone={tone}>{severity.charAt(0) + severity.slice(1).toLowerCase()}</Badge>;
}

export function StatCard({
  label,
  value,
  hint,
  icon,
  tone = 'gray',
}: {
  label: string;
  value: ReactNode;
  hint?: ReactNode;
  icon?: ReactNode;
  tone?: Tone;
}) {
  return (
    <div className="rounded-xl border border-line bg-paper p-4 shadow-sm">
      <div className="flex items-start justify-between gap-2">
        <p className="text-xs font-semibold text-muted">{label}</p>
        {icon ? (
          <span className={`flex h-8 w-8 items-center justify-center rounded-lg ring-1 ring-inset [&_svg]:h-4 [&_svg]:w-4 ${TONE[tone]}`}>
            {icon}
          </span>
        ) : null}
      </div>
      <p className="stat-figure mt-1 text-2xl text-ink">
        {typeof value === 'number' ? value.toLocaleString() : value}
      </p>
      {hint ? <p className="mt-0.5 text-xs text-muted">{hint}</p> : null}
    </div>
  );
}

export function EmptyState({
  icon,
  title,
  children,
  action,
}: {
  icon?: ReactNode;
  title: ReactNode;
  children?: ReactNode;
  action?: ReactNode;
}) {
  return (
    <div className="flex flex-col items-center px-6 py-14 text-center">
      {icon ? (
        <span className="mb-3 flex h-11 w-11 items-center justify-center rounded-full bg-wash text-muted [&_svg]:h-5 [&_svg]:w-5">
          {icon}
        </span>
      ) : null}
      <p className="text-sm font-semibold">{title}</p>
      {children ? <div className="mt-1 max-w-md text-sm text-muted">{children}</div> : null}
      {action ? <div className="mt-4">{action}</div> : null}
    </div>
  );
}

export function ErrorState({ message }: { message: string }) {
  return (
    <div className="flex items-start gap-3 rounded-xl border border-loss/30 bg-loss/5 px-5 py-4 text-sm">
      <CircleAlert className="mt-0.5 h-4 w-4 shrink-0 text-loss" />
      <div>
        <p className="font-semibold text-loss">Couldn’t load this page</p>
        <p className="mt-0.5 text-muted">{message}</p>
      </div>
    </div>
  );
}

/** A form control with its label, and an optional hint beneath. */
export function Field({
  label,
  hint,
  children,
  className = '',
  required = false,
}: {
  label: string;
  hint?: ReactNode;
  children: ReactNode;
  className?: string;
  required?: boolean;
}) {
  return (
    <label className={`block ${className}`}>
      <span className="mb-1.5 block text-xs font-semibold text-ink">
        {label}
        {required ? <span className="ml-0.5 text-loss">*</span> : null}
      </span>
      {children}
      {hint ? <span className="mt-1 block text-xs text-muted">{hint}</span> : null}
    </label>
  );
}

/** Label/value pairs, e.g. a record's read-only facts. */
export function Facts({ items }: { items: { label: string; value: ReactNode }[] }) {
  return (
    <dl className="divide-y divide-line">
      {items.map((i) => (
        <div key={i.label} className="flex items-baseline justify-between gap-4 px-5 py-2.5 text-sm">
          <dt className="text-muted">{i.label}</dt>
          <dd className="min-w-0 truncate text-right font-medium">{i.value}</dd>
        </div>
      ))}
    </dl>
  );
}

/**
 * GET search form. Keeps the other query parameters (a type filter, say) as
 * hidden inputs, so searching never silently drops a filter, and resets paging.
 */
export function SearchBar({
  action,
  q,
  placeholder,
  keep = {},
  children,
}: {
  action: string;
  q: string;
  placeholder: string;
  keep?: Record<string, string | undefined>;
  children?: ReactNode;
}) {
  return (
    <form method="get" action={action} className="flex flex-wrap items-center gap-2">
      {Object.entries(keep).map(([k, v]) =>
        v ? <input key={k} type="hidden" name={k} value={v} /> : null,
      )}
      <div className="relative min-w-56 flex-1 sm:max-w-sm">
        <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted" />
        <input name="q" defaultValue={q} placeholder={placeholder} className={`${input} pl-9`} />
      </div>
      {children}
      <button type="submit" className={btn('secondary')}>Search</button>
      {q ? (
        <Link
          href={`${action}?${new URLSearchParams(
            Object.fromEntries(Object.entries(keep).filter(([, v]) => v)) as Record<string, string>,
          )}`}
          className="text-sm text-muted hover:text-ink"
        >
          Clear
        </Link>
      ) : null}
    </form>
  );
}

export function Pagination({
  page,
  pageSize,
  total,
  href,
}: {
  page: number;
  pageSize: number;
  total: number;
  href: (page: number) => string;
}) {
  const pages = Math.max(1, Math.ceil(total / pageSize));
  if (total === 0) return null;
  const from = (page - 1) * pageSize + 1;
  const to = Math.min(total, page * pageSize);
  return (
    <div className="flex flex-wrap items-center justify-between gap-3 border-t border-line px-5 py-3 text-sm">
      <p className="text-muted">
        Showing <span className="font-semibold text-ink nums">{from.toLocaleString()}–{to.toLocaleString()}</span> of{' '}
        <span className="font-semibold text-ink nums">{total.toLocaleString()}</span>
      </p>
      <div className="flex items-center gap-1.5">
        {page > 1 ? (
          <Link href={href(page - 1)} className={btn('secondary', 'sm')}>
            <ChevronLeft /> Previous
          </Link>
        ) : (
          <span className={btn('secondary', 'sm', 'pointer-events-none opacity-40')}>
            <ChevronLeft /> Previous
          </span>
        )}
        <span className="px-2 text-xs text-muted nums">
          Page {page} of {pages}
        </span>
        {page < pages ? (
          <Link href={href(page + 1)} className={btn('secondary', 'sm')}>
            Next <ChevronRight />
          </Link>
        ) : (
          <span className={btn('secondary', 'sm', 'pointer-events-none opacity-40')}>
            Next <ChevronRight />
          </span>
        )}
      </div>
    </div>
  );
}

/** Link-styled tabs for switching a list's filter, each a shareable URL. */
export function FilterTabs({
  items,
}: {
  items: { href: string; label: string; active: boolean; count?: number }[];
}) {
  return (
    <div className="inline-flex rounded-lg border border-line bg-wash p-0.5">
      {items.map((i) => (
        <Link
          key={i.href}
          href={i.href}
          className={`rounded-md px-3 py-1.5 text-xs font-semibold transition-colors ${
            i.active ? 'bg-paper text-ink shadow-sm' : 'text-muted hover:text-ink'
          }`}
        >
          {i.label}
          {i.count !== undefined ? <span className="ml-1.5 text-muted nums">{i.count}</span> : null}
        </Link>
      ))}
    </div>
  );
}

/**
 * Marks a record as incomplete — a goal whose scorer was never recorded. A dot
 * plus a count, with a text label, so it is not colour-only.
 */
export function IncompleteDot({ count, what = 'goal' }: { count: number; what?: string }) {
  if (count <= 0) return null;
  const label = `${count} ${what}${count === 1 ? '' : 's'} with no scorer recorded`;
  return (
    <span className="inline-flex items-center gap-1" title={label}>
      <span aria-hidden className="inline-block h-2 w-2 rounded-full bg-loss" />
      <span className="sr-only">{label}</span>
      <span aria-hidden className="text-[10px] font-semibold text-loss">{count}</span>
    </span>
  );
}

export const fmtDate = (iso: string | null | undefined) =>
  iso ? new Date(iso).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' }) : '—';

export const fmtDateTime = (iso: string | null | undefined) =>
  iso
    ? new Date(iso).toLocaleString('en-GB', {
        day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit',
      })
    : '—';

export const humanise = (s: string) => s.charAt(0) + s.slice(1).toLowerCase().replaceAll('_', ' ');
