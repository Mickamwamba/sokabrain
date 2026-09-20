"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { QuickSearchModal } from "./quick-search-modal";
import { LanguageToggle } from "./kijiweni/language-toggle";
import { useLanguage } from "@/lib/i18n";

export function MainNav() {
  const pathname = usePathname();
  const { t } = useLanguage();
  const [searchOpen, setSearchOpen] = useState(false);

  const navItems = [
    { href: "/", label: t.nav.matches, match: (p: string) => p === "/" || (p.startsWith("/matches") && !p.startsWith("/kijiweni")) },
    { href: "/table", label: t.nav.table, match: (p: string) => p.startsWith("/table") },
    { href: "/stats", label: t.nav.stats, match: (p: string) => p.startsWith("/stats") },
    { href: "/kijiweni", label: t.nav.kijiweni, match: (p: string) => p.startsWith("/kijiweni") },
  ];

  useEffect(() => {
    function onKeyDown(e: KeyboardEvent) {
      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault();
        setSearchOpen((prev) => !prev);
      }
    }
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, []);

  return (
    <>
      <header className="sticky top-0 z-40 bg-ink/95 backdrop-blur-md text-white border-b border-white/10 shadow-sm">
        <div className="mx-auto flex max-w-6xl items-center justify-between gap-3 px-4 py-3 sm:py-3.5">
          {/* Logo & Tagline */}
          <div className="flex items-center gap-3 sm:gap-4">
            <Link href="/" className="display text-xl font-black tracking-tight group flex items-center gap-1.5">
              <span className="text-white group-hover:text-white/90">soka</span>
              <span className="rounded bg-brand px-1.5 py-0.5 text-xs font-black uppercase tracking-wider text-white">
                 brain
              </span>
            </Link>
            <span className="hidden h-4 w-px bg-white/20 md:block" />
            <span className="hidden text-xs font-medium text-white/50 md:block">
              East African football, in depth
            </span>
          </div>

          {/* Right Header Actions: Search + Language Switcher */}
          <div className="flex items-center gap-2 sm:gap-3">
            {/* Quick Search Affordance */}
            <button
              onClick={() => setSearchOpen(true)}
              className="flex items-center gap-2 rounded-full border border-white/15 bg-white/10 px-3 py-1.5 text-xs text-white/80 hover:bg-white/15 hover:border-white/25 transition-all cursor-pointer shadow-2xs"
              title="Search clubs and stats (Cmd+K)"
            >
              <svg
                className="h-3.5 w-3.5 text-white/60"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                />
              </svg>
              <span className="hidden sm:inline">{t.nav.search}</span>
              <span className="sm:hidden">Search</span>
              <kbd className="hidden sm:inline-block rounded bg-white/20 px-1.5 py-0.2 text-[10px] font-mono text-white/90">
                ⌘K
              </kbd>
            </button>

            {/* Bilingual Toggle (SW | EN) */}
            <LanguageToggle />
          </div>
        </div>

        {/* Navigation Strip */}
        <nav className="border-t border-white/10 bg-ink-soft/40">
          <div className="mx-auto flex max-w-6xl gap-1 overflow-x-auto px-4 scrollbar-none">
            {navItems.map((item) => {
              const active = item.match(pathname);
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`relative whitespace-nowrap px-4 py-2.5 text-sm font-semibold transition-all ${
                    active
                      ? "text-white"
                      : "text-white/60 hover:text-white/90"
                  }`}
                >
                  {item.label}
                  {active && (
                    <span className="absolute bottom-0 left-2 right-2 h-0.5 rounded-full bg-brand" />
                  )}
                </Link>
              );
            })}
          </div>
        </nav>
      </header>

      <QuickSearchModal isOpen={searchOpen} onClose={() => setSearchOpen(false)} />
    </>
  );
}
