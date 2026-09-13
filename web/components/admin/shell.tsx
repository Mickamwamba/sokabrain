'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useState, type ReactNode } from 'react';
import {
  ArrowRightLeft,
  CalendarDays,
  CalendarRange,
  ExternalLink,
  Flag,
  KeyRound,
  LayoutDashboard,
  ListChecks,
  Menu,
  Shield,
  ScanSearch,
  Trophy,
  UserCog,
  UserRound,
  X,
  type LucideIcon,
} from 'lucide-react';

/**
 * The admin application frame: a fixed left sidebar holding every section,
 * and a slim top bar. Below the lg breakpoint the sidebar becomes a drawer
 * behind a menu button, and closes itself on navigation.
 *
 * Sections are grouped by what an editor is doing — maintaining the vault's
 * records, fixing its quality, or managing who can do either — rather than
 * listed flat.
 */

type Item = { href: string; label: string; icon: LucideIcon; exact?: boolean };

const GROUPS: { label: string; items: Item[] }[] = [
  {
    label: 'Overview',
    items: [{ href: '/admin', label: 'Dashboard', icon: LayoutDashboard, exact: true }],
  },
  {
    label: 'Vault',
    items: [
      { href: '/admin/competitions', label: 'Competitions', icon: Trophy },
      { href: '/admin/seasons', label: 'Seasons', icon: CalendarRange },
      { href: '/admin/participants', label: 'Participants', icon: ListChecks },
      { href: '/admin/matches', label: 'Matches', icon: CalendarDays },
      { href: '/admin/teams', label: 'Teams', icon: Shield },
      { href: '/admin/players', label: 'Players', icon: UserRound },
      { href: '/admin/transfers', label: 'Transfers', icon: ArrowRightLeft },
    ],
  },
  {
    label: 'Data quality',
    items: [
      { href: '/admin/audit', label: 'Data audit', icon: ScanSearch },
      { href: '/admin/flags', label: 'Flags', icon: Flag },
    ],
  },
  {
    label: 'Settings',
    items: [
      { href: '/admin/access', label: 'Access management', icon: KeyRound },
      { href: '/admin/account', label: 'My account', icon: UserCog },
    ],
  },
];

function Nav({ pathname, onNavigate }: { pathname: string; onNavigate: () => void }) {
  return (
    <nav className="flex-1 space-y-6 overflow-y-auto px-3 py-5">
      {GROUPS.map((g) => (
        <div key={g.label}>
          <p className="mb-1.5 px-3 text-[10px] font-bold uppercase tracking-[0.12em] text-white/35">
            {g.label}
          </p>
          <ul className="space-y-0.5">
            {g.items.map((i) => {
              const active = i.exact
                ? pathname === i.href
                : pathname === i.href || pathname.startsWith(`${i.href}/`);
              const Icon = i.icon;
              return (
                <li key={i.href}>
                  <Link
                    href={i.href}
                    // Picking a section closes the mobile drawer.
                    onClick={onNavigate}
                    aria-current={active ? 'page' : undefined}
                    className={`group relative flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors ${
                      active
                        ? 'bg-white/10 text-white'
                        : 'text-white/60 hover:bg-white/5 hover:text-white'
                    }`}
                  >
                    {active ? (
                      <span aria-hidden className="absolute inset-y-1.5 left-0 w-0.5 rounded-full bg-brand" />
                    ) : null}
                    <Icon
                      className={`h-[18px] w-[18px] shrink-0 ${
                        active ? 'text-brand' : 'text-white/45 group-hover:text-white/80'
                      }`}
                    />
                    {i.label}
                  </Link>
                </li>
              );
            })}
          </ul>
        </div>
      ))}
    </nav>
  );
}

export function AdminShell({
  admin,
  signOut,
  children,
}: {
  admin: { displayName: string; email: string };
  /** The sign-out control, rendered on the server so it can hold its action. */
  signOut: ReactNode;
  children: ReactNode;
}) {
  const pathname = usePathname();
  const [drawer, setDrawer] = useState(false);

  const initials = admin.displayName
    .split(/\s+/)
    .slice(0, 2)
    .map((w) => w[0]?.toUpperCase() ?? '')
    .join('');

  const sidebar = (
    <div className="flex h-full flex-col bg-ink">
      <div className="flex h-16 items-center justify-between gap-2 border-b border-white/10 px-6">
        <Link href="/admin" onClick={() => setDrawer(false)} className="flex items-baseline gap-2">
          <span className="display text-lg font-extrabold tracking-tight text-white">
            soka<span className="text-brand">brain</span>
          </span>
          <span className="rounded bg-white/10 px-1.5 py-0.5 text-[10px] font-bold uppercase tracking-wider text-white/60">
            Admin
          </span>
        </Link>
        <button
          type="button"
          onClick={() => setDrawer(false)}
          aria-label="Close menu"
          className="rounded-lg p-1.5 text-white/60 hover:bg-white/10 hover:text-white lg:hidden"
        >
          <X className="h-5 w-5" />
        </button>
      </div>
      <Nav pathname={pathname} onNavigate={() => setDrawer(false)} />
      <div className="border-t border-white/10 p-3">
        <Link
          href="/"
          target="_blank"
          className="flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium text-white/60 hover:bg-white/5 hover:text-white"
        >
          <ExternalLink className="h-[18px] w-[18px] text-white/45" />
          View public site
        </Link>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen bg-wash">
      {/* Desktop sidebar */}
      <aside className="fixed inset-y-0 left-0 z-30 hidden w-64 lg:block">{sidebar}</aside>

      {/* Mobile drawer */}
      {drawer ? (
        <div className="fixed inset-0 z-40 lg:hidden">
          <button
            type="button"
            aria-label="Close menu"
            onClick={() => setDrawer(false)}
            className="absolute inset-0 bg-ink/50"
          />
          <aside className="absolute inset-y-0 left-0 w-72 max-w-[85vw] shadow-2xl">{sidebar}</aside>
        </div>
      ) : null}

      <div className="lg:pl-64">
        <header className="sticky top-0 z-20 flex h-16 items-center gap-3 border-b border-line bg-paper/90 px-4 backdrop-blur sm:px-6">
          <button
            type="button"
            onClick={() => setDrawer(true)}
            aria-label="Open menu"
            className="rounded-lg p-2 text-muted hover:bg-wash hover:text-ink lg:hidden"
          >
            <Menu className="h-5 w-5" />
          </button>
          <div className="flex-1" />
          <div className="flex items-center gap-3">
            <div className="hidden text-right sm:block">
              <p className="text-sm font-semibold leading-tight">{admin.displayName}</p>
              <p className="text-xs leading-tight text-muted">{admin.email}</p>
            </div>
            <span
              aria-hidden
              className="flex h-9 w-9 items-center justify-center rounded-full bg-ink text-xs font-bold text-white"
            >
              {initials}
            </span>
            <span className="mx-1 h-6 w-px bg-line" />
            {signOut}
          </div>
        </header>

        <main className="mx-auto w-full max-w-7xl px-4 py-6 sm:px-6 lg:px-8 lg:py-8">{children}</main>
      </div>
    </div>
  );
}
