import Link from "next/link";
import { getClubTheme } from "@/lib/club-colors";

/** A white panel — the unit everything on the site is built from. */
export function Card({
  children,
  className = "",
}: {
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <div className={`rounded-xl border border-line bg-paper shadow-[0_1px_3px_rgba(11,27,43,0.04)] transition-all ${className}`}>
      {children}
    </div>
  );
}

export function CardHead({
  title,
  action,
  hint,
}: {
  title: string;
  action?: { href: string; label: string };
  hint?: string;
}) {
  return (
    <div className="flex items-baseline justify-between gap-3 border-b border-line px-5 py-3.5 bg-paper/50">
      <div>
        <h2 className="display text-sm font-bold uppercase tracking-wide text-ink">{title}</h2>
        {hint ? <p className="mt-0.5 text-xs text-muted">{hint}</p> : null}
      </div>
      {action ? (
        <Link
          href={action.href}
          className="shrink-0 text-xs font-semibold text-brand hover:text-brand-dark transition-colors"
        >
          {action.label} →
        </Link>
      ) : null}
    </div>
  );
}

/** A single headline number. The largest thing on the page by design. */
export function StatTile({
  figure,
  label,
  sub,
}: {
  figure: string | number;
  label: string;
  sub?: string;
}) {
  return (
    <Card className="px-4 py-4">
      <p className="stat-figure text-3xl text-ink">
        {typeof figure === "number" ? figure.toLocaleString() : figure}
      </p>
      <p className="mt-1 text-xs font-semibold uppercase tracking-wide text-muted">{label}</p>
      {sub ? <p className="mt-0.5 text-xs text-muted">{sub}</p> : null}
    </Card>
  );
}

/**
 * Club identity mark. Uses curated club colors for authentic team identification
 * without broken image URLs.
 */
export function Crest({
  name,
  size = 28,
  className = "",
}: {
  name: string;
  size?: number;
  className?: string;
}) {
  const initials = name
    .split(/\s+/)
    .filter((w) => /^[A-Za-z]/.test(w))
    .slice(0, 2)
    .map((w) => w[0]!.toUpperCase())
    .join("");

  const theme = getClubTheme(name);

  return (
    <span
      aria-hidden
      className={`inline-flex shrink-0 items-center justify-center rounded-full font-display font-bold shadow-xs select-none ${className}`}
      style={{
        width: size,
        height: size,
        backgroundColor: theme.bg,
        color: theme.text,
        border: `1.5px solid ${theme.border ?? theme.bg}`,
        fontSize: Math.max(9, Math.round(size * 0.36)),
        lineHeight: 1,
      }}
      title={name}
    >
      {initials}
    </span>
  );
}

/** Rank badge — Gold, Silver, Bronze for top 3 so charts and tables have clear focal hierarchy. */
export function Rank({ n }: { n: number }) {
  if (n === 1) {
    return (
      <span className="inline-flex h-6 w-6 shrink-0 items-center justify-center rounded-md bg-gold text-ink font-extrabold text-xs shadow-xs" title="1st Place">
        1
      </span>
    );
  }
  if (n === 2) {
    return (
      <span className="inline-flex h-6 w-6 shrink-0 items-center justify-center rounded-md bg-slate-200 text-slate-800 font-bold text-xs" title="2nd Place">
        2
      </span>
    );
  }
  if (n === 3) {
    return (
      <span className="inline-flex h-6 w-6 shrink-0 items-center justify-center rounded-md bg-amber-100 text-amber-900 border border-amber-300 font-bold text-xs" title="3rd Place">
        3
      </span>
    );
  }
  return (
    <span className="inline-flex h-6 w-6 shrink-0 items-center justify-center rounded text-xs font-medium nums text-muted">
      {n}
    </span>
  );
}

/** Filter chips rendered as links, so every view stays a shareable URL. */
export function ChipRow({
  label,
  options,
  activeValue,
  hrefFor,
}: {
  label: string;
  options: { value: string | undefined; label: string }[];
  activeValue: string | undefined;
  hrefFor: (value: string | undefined) => string;
}) {
  return (
    <div className="flex flex-wrap items-center gap-1.5">
      <span className="mr-1 text-xs font-semibold uppercase tracking-wide text-muted">
        {label}
      </span>
      {options.map((o) => {
        const active = o.value === activeValue;
        return (
          <Link
            key={o.label}
            href={hrefFor(o.value)}
            className={`rounded-full border px-3 py-1 text-xs font-semibold transition-all ${
              active
                ? "border-ink bg-ink text-white shadow-xs"
                : "border-line bg-paper text-muted hover:border-ink hover:text-ink"
            }`}
          >
            {o.label}
          </Link>
        );
      })}
    </div>
  );
}

export function Empty({ children }: { children: React.ReactNode }) {
  return (
    <Card className="px-6 py-14 text-center text-sm text-muted">{children}</Card>
  );
}

/**
 * States what the underlying data is missing.
 * Framed as a trusted data fidelity notice rather than a broken page.
 */
export function DataNote({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex items-start gap-2.5 rounded-lg border border-line/80 bg-paper/60 px-4 py-2.5 text-xs text-muted shadow-2xs">
      <span className="mt-0.5 inline-block h-2 w-2 shrink-0 rounded-full bg-brand" />
      <div className="flex-1 leading-relaxed">
        <span className="font-semibold text-ink">Archive note: </span>
        {children}
      </div>
    </div>
  );
}

export function PageTitle({
  title,
  sub,
  right,
}: {
  title: string;
  sub?: string;
  right?: React.ReactNode;
}) {
  return (
    <div className="mb-6 flex flex-wrap items-center justify-between gap-3">
      <div>
        <h1 className="display text-3xl font-extrabold tracking-tight text-ink">{title}</h1>
        {sub ? <p className="mt-1 text-sm font-medium text-muted">{sub}</p> : null}
      </div>
      {right ? <div className="pt-0.5">{right}</div> : null}
    </div>
  );
}

/** Form guide: last N results, most recent first. */
export function FormDots({ results }: { results: ("W" | "D" | "L")[] }) {
  return (
    <span className="inline-flex gap-1 items-center">
      {results.map((r, i) => (
        <span
          key={i}
          title={r === "W" ? "Win" : r === "D" ? "Draw" : "Loss"}
          className={`inline-flex h-5 w-5 items-center justify-center rounded font-display text-[10px] font-extrabold text-white shadow-2xs ${
            r === "W" ? "bg-emerald-600" : r === "D" ? "bg-amber-500 text-ink" : "bg-rose-600"
          }`}
        >
          {r}
        </span>
      ))}
    </span>
  );
}

/**
 * A team's name, linking to its page.
 */
export function TeamLink({
  id,
  name,
  className = "",
  children,
}: {
  id: number | null | undefined;
  name: string;
  className?: string;
  children?: React.ReactNode;
}) {
  if (id == null) return <span className={className}>{children ?? name}</span>;
  return (
    <Link href={`/teams/${id}`} className={`transition-colors hover:text-brand ${className}`}>
      {children ?? name}
    </Link>
  );
}

/**
 * The in-play marker.
 *
 * No minute: the vault stores a live score but not the clock, and inventing one
 * would be worse than omitting it. The pulse is what carries "this is moving".
 *
 * `size="sm"` is for a fixture list, where it sits where a score pill would.
 */
export function LiveBadge({ size = "md" }: { size?: "sm" | "md" }) {
  const pad = size === "sm" ? "px-2 py-0.5 text-[10px]" : "px-3 py-0.5 text-[10px]";
  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full bg-red-600 font-black uppercase tracking-wider text-white shadow-2xs ${pad}`}
    >
      <span className="relative flex h-1.5 w-1.5">
        <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-white opacity-75" />
        <span className="relative inline-flex h-1.5 w-1.5 rounded-full bg-white" />
      </span>
      Live
    </span>
  );
}
