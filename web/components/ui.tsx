import Link from "next/link";

/**
 * Reports what a page's underlying data does and does not contain.
 *
 * The legacy vault is partial — many matches carry no score and roughly a
 * quarter of goal events have no scorer — so a table rendered without this
 * reads as broken rather than incomplete. Backend design principle 6.
 */
export function CoverageNote({ children }: { children: React.ReactNode }) {
  return (
    <p className="rounded-md border border-border bg-surface px-3 py-2 text-xs text-muted">
      {children}
    </p>
  );
}

export function Empty({ children }: { children: React.ReactNode }) {
  return (
    <div className="rounded-md border border-dashed border-border px-4 py-10 text-center text-sm text-muted">
      {children}
    </div>
  );
}

export function Badge({ children }: { children: React.ReactNode }) {
  return (
    <span className="rounded border border-border bg-surface px-1.5 py-0.5 text-[11px] uppercase tracking-wide text-muted">
      {children}
    </span>
  );
}

/** A team's crest, or its initials when the logo file isn't available. */
export function TeamCrest({ name, size = 20 }: { name: string; size?: number }) {
  const initials = name
    .split(/\s+/)
    .filter((w) => /^[A-Za-z]/.test(w))
    .slice(0, 2)
    .map((w) => w[0]!.toUpperCase())
    .join("");
  return (
    <span
      aria-hidden
      className="inline-flex shrink-0 items-center justify-center rounded-full border border-border bg-surface font-mono text-[10px] text-muted"
      style={{ width: size, height: size }}
    >
      {initials}
    </span>
  );
}

export function BackLink({ href, children }: { href: string; children: React.ReactNode }) {
  return (
    <Link href={href} className="text-sm text-muted hover:text-foreground">
      ← {children}
    </Link>
  );
}
