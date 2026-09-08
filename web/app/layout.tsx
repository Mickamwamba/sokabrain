import type { Metadata } from "next";
import Link from "next/link";
import { Archivo, Inter } from "next/font/google";
import "./globals.css";

// Archivo carries the bold display weights the stat figures need; Inter keeps
// dense tables readable at small sizes.
const archivo = Archivo({
  variable: "--font-archivo",
  subsets: ["latin"],
  weight: ["600", "700", "800"],
});
const inter = Inter({ variable: "--font-inter", subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Sokabrain — East African Football Stats",
  description:
    "Records, tables and stats for Tanzanian and Kenyan football — the depth global apps reserve for Europe.",
};

/**
 * Three destinations, because a fan only distinguishes three things: what is on,
 * where my club stands, and the numbers.
 *
 * The previous six put Stats, Players, Clubs and Head to head side by side, all
 * of which are statistics; a fan had to know our internal split before
 * clicking. Those are now tabs inside Statistics, and Competitions is the
 * season picker on the Table page rather than a destination of its own.
 */
const NAV = [
  { href: "/", label: "Matches" },
  { href: "/table", label: "Table" },
  { href: "/stats", label: "Statistics" },
];

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="en" className={`${archivo.variable} ${inter.variable} h-full`}>
      <body className="min-h-full font-sans antialiased">
        <header className="bg-ink text-white">
          <div className="mx-auto flex max-w-6xl items-center gap-6 px-4 py-4">
            <Link href="/" className="display text-lg font-extrabold tracking-tight">
              soka<span className="text-brand">brain</span>
            </Link>
            <span className="hidden text-xs text-white/50 sm:block">
              East African football, in depth
            </span>
          </div>
          <nav className="border-t border-white/10">
            <div className="mx-auto flex max-w-6xl gap-1 overflow-x-auto px-2">
              {NAV.map((n) => (
                <Link
                  key={n.href}
                  href={n.href}
                  className="whitespace-nowrap px-3 py-3 text-sm font-medium text-white/70 transition-colors hover:text-white"
                >
                  {n.label}
                </Link>
              ))}
            </div>
          </nav>
        </header>

        <main className="mx-auto w-full max-w-6xl px-4 py-8">{children}</main>

        <footer className="mt-12 border-t border-line bg-paper">
          <div className="mx-auto max-w-6xl px-4 py-8 text-xs text-muted">
            <p className="font-medium text-ink">Sokabrain</p>
            <p className="mt-1 max-w-2xl">
              Tanzania Premier League, 2008/09 to 2026/27, built from the SokaFC archive
              and reconciled against the official league site, RSSSF and WhoScored. Only
              competitions reviewed and released by an editor appear here, and each page
              states what its data is missing rather than filling the gaps with guesses.
            </p>
            <Link href="/admin" className="mt-3 inline-block text-muted hover:text-ink">
              Admin
            </Link>
          </div>
        </footer>
      </body>
    </html>
  );
}
