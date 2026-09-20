import Link from "next/link";
import { MainNav } from "@/components/main-nav";
import { LanguageProvider } from "@/lib/i18n";

/**
 * The public site's chrome — header with active tabs, quick search, and footer.
 *
 * It lives in the (site) route group rather than the root layout so the admin
 * dashboard can be a full-screen application of its own instead of a page
 * squeezed between a fan-facing header and footer.
 */
export default function SiteLayout({ children }: { children: React.ReactNode }) {
  return (
    <LanguageProvider>
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
                <p className="mt-1 max-w-xl text-xs text-muted leading-relaxed">
                  The premier football statistics and records platform for East Africa.
                  Covering the NBC Premier League, regional derbies, and continental tournaments.
                </p>
                <p className="mt-2 text-[11px] text-muted/70">
                  &copy; {new Date().getFullYear()} SokaBrain. All rights reserved.
                </p>
              </div>
              <div className="flex flex-wrap items-center gap-4 text-xs font-medium">
                <Link href="/" className="text-muted hover:text-ink transition-colors">
                  Matches
                </Link>
                <Link href="/table" className="text-muted hover:text-ink transition-colors">
                  Standings
                </Link>
                <Link href="/stats" className="text-muted hover:text-ink transition-colors">
                  Statistics
                </Link>
                <Link href="/kijiweni" className="text-brand font-bold hover:underline transition-colors">
                  Kijiweni 🔥
                </Link>
                <Link href="/stats/head-to-head" className="text-muted hover:text-ink transition-colors">
                  Head to Head
                </Link>
                <Link href="/stats/players" className="text-muted hover:text-ink transition-colors">
                  Top Scorers
                </Link>
              </div>
            </div>
          </div>
        </footer>
      </div>
    </LanguageProvider>
  );
}
