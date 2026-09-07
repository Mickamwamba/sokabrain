import type { Metadata } from "next";
import Link from "next/link";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({ variable: "--font-geist-sans", subsets: ["latin"] });
const geistMono = Geist_Mono({ variable: "--font-geist-mono", subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Sokabrain — Football Vault",
  description:
    "Historical football records for East African leagues, with the statistical depth global apps reserve for Europe.",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="en"
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col font-sans">
        <header className="border-b border-border">
          <nav className="mx-auto flex max-w-6xl items-center gap-6 px-4 py-4">
            <Link href="/" className="font-semibold tracking-tight">
              soka<span className="text-accent">brain</span>
            </Link>
            <div className="flex gap-4 text-sm text-muted">
              <Link href="/" className="hover:text-foreground">Competitions</Link>
              <Link href="/matches" className="hover:text-foreground">Matches</Link>
              <Link href="/admin" className="hover:text-foreground">Admin</Link>
            </div>
          </nav>
        </header>
        <main className="mx-auto w-full max-w-6xl flex-1 px-4 py-8">{children}</main>
        <footer className="border-t border-border">
          <div className="mx-auto max-w-6xl px-4 py-6 text-xs text-muted">
            Vault data migrated from SokaFC (2017–2020). Coverage is partial — each
            page reports what its underlying data does and does not contain.
          </div>
        </footer>
      </body>
    </html>
  );
}
