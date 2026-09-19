import Link from "next/link";
import { MainNav } from "@/components/main-nav";

/**
 * The public site's chrome — header with active tabs, quick search, and footer.
 *
 * It lives in the (site) route group rather than the root layout so the admin
 * dashboard can be a full-screen application of its own instead of a page
 * squeezed between a fan-facing header and footer.
 */
export default function SiteLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen flex flex-col bg-wash">
      <MainNav />

      <main className="mx-auto w-full max-w-6xl flex-1 px-4 py-6 sm:py-8">
        {children}
      </main>

      <footer className="mt-12 border-t border-line bg-paper/80">
        <div className="mx-auto max-w-6xl px-4 py-8 text-xs text-muted">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <div>
              <p className="font-bold text-ink text-sm">
                soka<span className="text-brand">brain</span>
              </p>
              <p className="mt-1 max-w-2xl text-xs text-muted leading-relaxed">
                The Tanzania Premier League (2008/09 to 2026/27) and Africa Cup of
                Nations (2002 to 2025) — built from the SokaFC archive and reconciled against
                official league records, RSSSF and verified match data.
              </p>
            </div>
            <div className="flex items-center gap-4 text-xs font-medium">
              <Link href="/table" className="text-muted hover:text-ink transition-colors">
                Standings
              </Link>
              <Link href="/stats" className="text-muted hover:text-ink transition-colors">
                Stats
              </Link>
              <Link href="/admin" className="text-muted hover:text-ink transition-colors">
                Admin Console
              </Link>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
