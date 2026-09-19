"use client";

import { useCallback, useEffect, useMemo, useRef, useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Crest } from "@/components/ui";

type TeamResult = {
  type: "team";
  id: number;
  title: string;
  subtitle: string | null;
  badge?: string;
  href: string;
};

type PlayerResult = {
  type: "player";
  id: number;
  title: string;
  subtitle: string | null;
  badge?: string;
  teamId: number | null;
  href: string;
};

type H2HResult = {
  type: "h2h";
  id: string;
  title: string;
  subtitle: string;
  href: string;
};

type EditionResult = {
  type: "edition";
  id: number;
  title: string;
  subtitle: string;
  href: string;
};

type NavResult = {
  type: "nav";
  id: string;
  title: string;
  subtitle: string;
  href: string;
};

type SearchResultItem =
  | TeamResult
  | PlayerResult
  | H2HResult
  | EditionResult
  | NavResult;

type SearchResponse = {
  teams: TeamResult[];
  players: PlayerResult[];
  derbies: H2HResult[];
  editions: EditionResult[];
  shortcuts: NavResult[];
};

export function QuickSearchModal({
  isOpen,
  onClose,
}: {
  isOpen: boolean;
  onClose: () => void;
}) {
  const router = useRouter();
  const [query, setQuery] = useState("");
  const [data, setData] = useState<SearchResponse>({
    teams: [],
    players: [],
    derbies: [],
    editions: [],
    shortcuts: [],
  });
  const [loading, setLoading] = useState(false);
  const [selectedIndex, setSelectedIndex] = useState(0);
  const [, startTransition] = useTransition();
  const inputRef = useRef<HTMLInputElement>(null);

  const handleClose = useCallback(() => {
    setQuery("");
    setSelectedIndex(0);
    onClose();
  }, [onClose]);

  // Fetch search results on query change (with debouncing)
  useEffect(() => {
    if (!isOpen) return;

    const controller = new AbortController();

    const timer = setTimeout(() => {
      setLoading(true);
      fetch(`/api/search?q=${encodeURIComponent(query.trim())}`, {
        signal: controller.signal,
      })
        .then((res) => {
          if (!res.ok) throw new Error("Search failed");
          return res.json();
        })
        .then((json: SearchResponse) => {
          setData(json);
          setLoading(false);
          setSelectedIndex(0);
        })
        .catch((err) => {
          if (err.name !== "AbortError") {
            setLoading(false);
          }
        });
    }, 100);

    return () => {
      clearTimeout(timer);
      controller.abort();
    };
  }, [isOpen, query]);

  // Focus input on open
  useEffect(() => {
    if (isOpen) {
      setTimeout(() => inputRef.current?.focus(), 50);
    }
  }, [isOpen]);

  // Flatten items for keyboard arrow-key navigation
  const allItems: SearchResultItem[] = useMemo(
    () => [
      ...data.derbies,
      ...data.teams,
      ...data.players,
      ...data.editions,
      ...data.shortcuts,
    ],
    [data]
  );

  const navigateTo = useCallback((href: string) => {
    handleClose();
    startTransition(() => {
      router.push(href);
    });
  }, [handleClose, router]);

  // Keyboard navigation: Escape, ArrowDown, ArrowUp, Enter
  useEffect(() => {
    function onKeyDown(e: KeyboardEvent) {
      if (!isOpen) return;

      if (e.key === "Escape") {
        e.preventDefault();
        handleClose();
      } else if (e.key === "ArrowDown") {
        e.preventDefault();
        setSelectedIndex((prev) =>
          allItems.length > 0 ? (prev + 1) % allItems.length : 0
        );
      } else if (e.key === "ArrowUp") {
        e.preventDefault();
        setSelectedIndex((prev) =>
          allItems.length > 0 ? (prev - 1 + allItems.length) % allItems.length : 0
        );
      } else if (e.key === "Enter") {
        e.preventDefault();
        if (allItems[selectedIndex]) {
          navigateTo(allItems[selectedIndex].href);
        }
      }
    }

    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [isOpen, selectedIndex, allItems, handleClose, navigateTo]);

  if (!isOpen) return null;

  let currentCounter = -1;
  const hasAnyResults = allItems.length > 0;

  return (
    <div
      className="fixed inset-0 z-50 flex items-start justify-center p-3 sm:p-4 sm:pt-20 bg-ink/50 backdrop-blur-xs animate-in fade-in duration-150"
      onClick={handleClose}
    >
      <div
        className="w-full max-w-xl overflow-hidden rounded-2xl border border-line bg-paper shadow-2xl animate-in zoom-in-95 duration-150 flex flex-col max-h-[82vh]"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Search Input Bar */}
        <div className="flex items-center border-b border-line px-4 py-3 bg-paper shrink-0">
          <svg
            className="h-5 w-5 text-muted mr-3 shrink-0"
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
          <input
            ref={inputRef}
            type="text"
            placeholder="Search clubs, players, head-to-heads (e.g. Simba vs Yanga)..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            className="w-full bg-transparent text-base font-medium text-ink placeholder:text-muted focus:outline-hidden"
          />
          {query ? (
            <button
              onClick={() => setQuery("")}
              className="mr-2 text-xs text-muted hover:text-ink cursor-pointer p-1 rounded-sm"
              title="Clear search"
            >
              ✕
            </button>
          ) : null}
          <kbd className="hidden sm:inline-block rounded border border-line bg-wash px-1.5 py-0.5 text-[10px] font-semibold text-muted">
            ESC
          </kbd>
        </div>

        {/* Search Results / Content */}
        <div className="overflow-y-auto p-2 divide-y divide-line/40 space-y-1">
          {loading && allItems.length === 0 ? (
            <div className="py-8 text-center text-sm text-muted">
              Searching football vault...
            </div>
          ) : !hasAnyResults ? (
            <div className="py-8 text-center">
              <p className="text-sm font-semibold text-ink">No results found for &ldquo;{query}&rdquo;</p>
              <p className="text-xs text-muted mt-1">Try searching club names, top players, or derbies</p>
            </div>
          ) : null}

          {/* Derbies / Head-to-Head Section */}
          {data.derbies.length > 0 && (
            <div className="py-1">
              <p className="px-3 py-1 text-[11px] font-bold uppercase tracking-wider text-muted">
                Head to Head Matchups
              </p>
              <div className="space-y-0.5">
                {data.derbies.map((item) => {
                  currentCounter++;
                  const itemIndex = currentCounter;
                  const isSelected = itemIndex === selectedIndex;
                  return (
                    <button
                      key={item.id}
                      onClick={() => navigateTo(item.href)}
                      onMouseEnter={() => setSelectedIndex(itemIndex)}
                      className={`flex w-full items-center gap-3 rounded-lg px-3 py-2 text-left text-sm font-medium transition-colors cursor-pointer ${
                        isSelected ? "bg-wash text-brand border border-line/60" : "hover:bg-wash/70 text-ink"
                      }`}
                    >
                      <div className="h-7 w-7 rounded-full bg-amber-500/15 text-amber-700 flex items-center justify-center shrink-0 text-sm">
                        🔥
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="font-semibold text-ink truncate">{item.title}</div>
                        <div className="text-xs text-muted truncate">{item.subtitle}</div>
                      </div>
                      <span className="text-xs text-brand font-medium shrink-0">View H2H →</span>
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {/* Clubs & Teams Section */}
          {data.teams.length > 0 && (
            <div className="py-1">
              <p className="px-3 py-1 text-[11px] font-bold uppercase tracking-wider text-muted">
                Clubs & Teams
              </p>
              <div className="space-y-0.5">
                {data.teams.map((item) => {
                  currentCounter++;
                  const itemIndex = currentCounter;
                  const isSelected = itemIndex === selectedIndex;
                  return (
                    <button
                      key={item.id}
                      onClick={() => navigateTo(item.href)}
                      onMouseEnter={() => setSelectedIndex(itemIndex)}
                      className={`flex w-full items-center gap-3 rounded-lg px-3 py-2 text-left text-sm font-medium transition-colors cursor-pointer ${
                        isSelected ? "bg-wash text-brand border border-line/60" : "hover:bg-wash/70 text-ink"
                      }`}
                    >
                      <Crest name={item.title} size={28} />
                      <div className="flex-1 min-w-0">
                        <div className="font-semibold text-ink truncate">{item.title}</div>
                        {item.subtitle ? (
                          <div className="text-xs text-muted truncate">{item.subtitle}</div>
                        ) : null}
                      </div>
                      {item.badge ? (
                        <span className="text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-full bg-line text-muted">
                          {item.badge}
                        </span>
                      ) : (
                        <span className="text-xs text-muted font-normal">Team Profile →</span>
                      )}
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {/* Players Section */}
          {data.players.length > 0 && (
            <div className="py-1">
              <p className="px-3 py-1 text-[11px] font-bold uppercase tracking-wider text-muted">
                Players & Top Scorers
              </p>
              <div className="space-y-0.5">
                {data.players.map((item) => {
                  currentCounter++;
                  const itemIndex = currentCounter;
                  const isSelected = itemIndex === selectedIndex;
                  return (
                    <button
                      key={item.id}
                      onClick={() => navigateTo(item.href)}
                      onMouseEnter={() => setSelectedIndex(itemIndex)}
                      className={`flex w-full items-center gap-3 rounded-lg px-3 py-2 text-left text-sm font-medium transition-colors cursor-pointer ${
                        isSelected ? "bg-wash text-brand border border-line/60" : "hover:bg-wash/70 text-ink"
                      }`}
                    >
                      <div className="h-7 w-7 rounded-full bg-emerald-500/15 text-emerald-700 flex items-center justify-center shrink-0 text-xs font-bold">
                        ⚽
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="font-semibold text-ink truncate">{item.title}</div>
                        <div className="text-xs text-muted truncate">{item.subtitle}</div>
                      </div>
                      {item.badge ? (
                        <span className="text-xs font-bold px-2 py-0.5 rounded-md bg-wash border border-line text-ink">
                          {item.badge}
                        </span>
                      ) : null}
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {/* Competitions / Editions */}
          {data.editions.length > 0 && (
            <div className="py-1">
              <p className="px-3 py-1 text-[11px] font-bold uppercase tracking-wider text-muted">
                Competitions & Editions
              </p>
              <div className="space-y-0.5">
                {data.editions.map((item) => {
                  currentCounter++;
                  const itemIndex = currentCounter;
                  const isSelected = itemIndex === selectedIndex;
                  return (
                    <button
                      key={item.id}
                      onClick={() => navigateTo(item.href)}
                      onMouseEnter={() => setSelectedIndex(itemIndex)}
                      className={`flex w-full items-center gap-3 rounded-lg px-3 py-2 text-left text-sm font-medium transition-colors cursor-pointer ${
                        isSelected ? "bg-wash text-brand border border-line/60" : "hover:bg-wash/70 text-ink"
                      }`}
                    >
                      <div className="h-7 w-7 rounded-full bg-amber-500/15 text-amber-700 flex items-center justify-center shrink-0 text-xs font-bold">
                        🏆
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="font-semibold text-ink truncate">{item.title}</div>
                        <div className="text-xs text-muted truncate">{item.subtitle}</div>
                      </div>
                      <span className="text-xs text-muted">View Standings →</span>
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {/* Quick Shortcuts */}
          {data.shortcuts.length > 0 && (
            <div className="py-1">
              <p className="px-3 py-1 text-[11px] font-bold uppercase tracking-wider text-muted">
                Quick Navigation
              </p>
              <div className="space-y-0.5">
                {data.shortcuts.map((item) => {
                  currentCounter++;
                  const itemIndex = currentCounter;
                  const isSelected = itemIndex === selectedIndex;
                  return (
                    <button
                      key={item.id}
                      onClick={() => navigateTo(item.href)}
                      onMouseEnter={() => setSelectedIndex(itemIndex)}
                      className={`flex w-full items-center justify-between rounded-lg px-3 py-2 text-left text-sm font-medium transition-colors cursor-pointer ${
                        isSelected ? "bg-wash text-brand border border-line/60" : "hover:bg-wash/70 text-ink"
                      }`}
                    >
                      <div className="flex items-center gap-3">
                        <span className="text-sm">📌</span>
                        <div>
                          <span className="font-semibold text-ink">{item.title}</span>
                          <p className="text-xs text-muted">{item.subtitle}</p>
                        </div>
                      </div>
                      <span className="text-xs text-muted">Go →</span>
                    </button>
                  );
                })}
              </div>
            </div>
          )}
        </div>

        {/* Modal Footer */}
        <div className="flex items-center justify-between border-t border-line bg-wash/60 px-4 py-2.5 text-[11px] text-muted shrink-0">
          <span className="flex items-center gap-2">
            <kbd className="rounded border border-line bg-paper px-1.5 py-0.5 text-[10px] font-semibold text-muted">↑</kbd>
            <kbd className="rounded border border-line bg-paper px-1.5 py-0.5 text-[10px] font-semibold text-muted">↓</kbd>
            <span>to navigate</span>
            <kbd className="rounded border border-line bg-paper px-1.5 py-0.5 text-[10px] font-semibold text-muted">↵</kbd>
            <span>to select</span>
          </span>
          <span>SokaBrain Football Vault</span>
        </div>
      </div>
    </div>
  );
}
