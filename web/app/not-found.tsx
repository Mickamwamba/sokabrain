import Link from "next/link";

/**
 * The 404 for a URL that matches no route at all. It renders under the bare
 * root layout, with neither the site's nor the admin's chrome around it, so it
 * frames itself. A missing team or match inside the site uses
 * app/(site)/not-found.tsx instead, which keeps the header.
 */
export default function NotFound() {
  return (
    <main className="grid min-h-screen place-items-center bg-wash px-4">
      <div className="w-full max-w-md rounded-xl border border-line bg-paper px-6 py-16 text-center">
        <p className="display text-lg font-extrabold tracking-tight">
          soka<span className="text-brand">brain</span>
        </p>
        <p className="display mt-6 text-xl font-extrabold">Not in the vault</p>
        <p className="mt-1.5 text-sm text-muted">That page doesn’t exist.</p>
        <Link
          href="/"
          className="mt-5 inline-block rounded-full bg-ink px-5 py-2 text-sm font-semibold text-white"
        >
          Back to stats
        </Link>
      </div>
    </main>
  );
}
