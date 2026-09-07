'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

/**
 * Left sidebar. A client component only because it needs the current path to
 * mark the active item — everything it links to is a server-rendered page.
 */
const ITEMS = [
  { href: '/admin', label: 'Overview', exact: true },
  { href: '/admin/competitions', label: 'Competitions' },
  { href: '/admin/matches', label: 'Matches' },
  { href: '/admin/flags', label: 'Flags' },
];

export function AdminNav() {
  const pathname = usePathname();

  return (
    <nav className="space-y-0.5">
      {ITEMS.map((i) => {
        const active = i.exact ? pathname === i.href : pathname.startsWith(i.href);
        return (
          <Link
            key={i.href}
            href={i.href}
            className={`block rounded-lg px-3 py-2 text-sm font-medium transition-colors ${
              active ? 'bg-ink text-white' : 'text-muted hover:bg-wash hover:text-ink'
            }`}
          >
            {i.label}
          </Link>
        );
      })}
    </nav>
  );
}
