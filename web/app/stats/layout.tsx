import Link from "next/link";
import { PageTitle } from "@/components/ui";

/**
 * One home for every aggregate the vault can support.
 *
 * The old navigation had Stats, Players, Clubs and Head to head side by side at
 * the top level, which asked a fan to know the difference before clicking. They
 * are all the same thing — statistics — so they are tabs under one heading, and
 * the top-level navigation is left with the three things a fan actually
 * distinguishes: what's on, the table, and the numbers.
 */

const TABS = [
  { href: "/stats", label: "Overview" },
  { href: "/stats/players", label: "Players" },
  { href: "/stats/clubs", label: "Clubs" },
  { href: "/stats/head-to-head", label: "Head to head" },
];

export default function StatsLayout({ children }: { children: React.ReactNode }) {
  return (
    <div>
      <PageTitle title="Statistics" sub="Tanzania Premier League, 2008/09 to 2026/27" />
      <nav className="mb-5 -mx-4 overflow-x-auto px-4">
        <ul className="flex min-w-max gap-1.5 border-b border-line pb-px">
          {TABS.map((t) => (
            <li key={t.href}>
              <Link
                href={t.href}
                className="inline-block rounded-t-lg px-3.5 py-2 text-sm font-semibold text-muted transition-colors hover:bg-wash hover:text-ink aria-[current=page]:text-ink"
              >
                {t.label}
              </Link>
            </li>
          ))}
        </ul>
      </nav>
      {children}
    </div>
  );
}
