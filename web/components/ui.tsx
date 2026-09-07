import Link from "next/link";

/** A white panel — the unit everything on the site is built from. */
export function Card({
  children,
  className = "",
}: {
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <div className={`rounded-xl border border-line bg-paper ${className}`}>{children}</div>
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
    <div className="flex items-baseline justify-between gap-3 border-b border-line px-5 py-3.5">
      <div>
        <h2 className="display text-sm font-bold uppercase tracking-wide">{title}</h2>
        {hint ? <p className="mt-0.5 text-xs text-muted">{hint}</p> : null}
      </div>
      {action ? (
        <Link
          href={action.href}
          className="shrink-0 text-xs font-semibold text-brand hover:text-brand-dark"
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
 * Club identity mark. `logo_url` in the vault holds bare filenames with no
 * files behind them, so initials are the honest representation.
 */
export function Crest({ name, size = 28 }: { name: string; size?: number }) {
  const initials = name
    .split(/\s+/)
    .filter((w) => /^[A-Za-z]/.test(w))
    .slice(0, 2)
    .map((w) => w[0]!.toUpperCase())
    .join("");
  return (
    <span
      aria-hidden
      className="inline-flex shrink-0 items-center justify-center rounded-full bg-ink font-display text-[10px] font-bold text-white"
      style={{ width: size, height: size, fontSize: Math.round(size * 0.36) }}
    >
      {initials}
    </span>
  );
}

/** Rank badge — gold for the leader, so a table has an obvious focal point. */
export function Rank({ n }: { n: number }) {
  return (
    <span
      className={`inline-flex h-6 w-6 shrink-0 items-center justify-center rounded text-xs font-bold nums ${
        n === 1 ? "bg-gold text-ink" : "text-muted"
      }`}
    >
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
            className={`rounded-full border px-3 py-1 text-xs font-medium transition-colors ${
              active
                ? "border-ink bg-ink text-white"
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
 *
 * Not decoration: many matches carry no score and a quarter of goals have no
 * scorer, so a table without this reads as broken rather than incomplete.
 */
export function DataNote({ children }: { children: React.ReactNode }) {
  return (
    <p className="rounded-lg border border-line bg-paper px-4 py-2.5 text-xs text-muted">
      <span className="font-semibold text-ink">Note </span>
      {children}
    </p>
  );
}

export function PageTitle({ title, sub }: { title: string; sub?: string }) {
  return (
    <div className="mb-6">
      <h1 className="display text-3xl font-extrabold tracking-tight">{title}</h1>
      {sub ? <p className="mt-1.5 text-sm text-muted">{sub}</p> : null}
    </div>
  );
}

/** Form guide: last N results, most recent first. */
export function FormDots({ results }: { results: ("W" | "D" | "L")[] }) {
  return (
    <span className="flex gap-1">
      {results.map((r, i) => (
        <span
          key={i}
          title={r}
          className={`inline-flex h-5 w-5 items-center justify-center rounded text-[10px] font-bold text-white ${
            r === "W" ? "bg-brand" : r === "D" ? "bg-muted" : "bg-loss"
          }`}
        >
          {r}
        </span>
      ))}
    </span>
  );
}
