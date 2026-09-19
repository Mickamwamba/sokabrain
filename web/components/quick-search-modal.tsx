"use client";

import { useEffect, useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Crest } from "@/components/ui";

type SearchItem = {
  id: number;
  name: string;
  country?: string | null;
  type?: string;
};

const QUICK_SHORTCUTS = [
  { href: "/", label: "Today's Matches" },
  { href: "/table", label: "League Standings" },
  { href: "/stats", label: "All-Time Statistics" },
  { href: "/stats/players", label: "Top Scorers & Player Stats" },
  { href: "/stats/head-to-head", label: "Head to Head Comparison" },
];

export function QuickSearchModal({
  isOpen,
  onClose,
}: {
  isOpen: boolean;
  onClose: () => void;
}) {
  const router = useRouter();
  const [query, setQuery] = useState("");
  const [teams, setTeams] = useState<SearchItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [, startTransition] = useTransition();

  const handleClose = () => {
    setQuery("");
    onClose();
  };

  useEffect(() => {
    let ignore = false;
    if (!isOpen || teams.length > 0) return;

    fetch("/api/vault/teams")
      .then((res) => {
        if (!res.ok) throw new Error("Failed");
        return res.json();
      })
      .then((data) => {
        if (!ignore && data && Array.isArray(data.teams)) {
          setTeams(data.teams);
          setLoading(false);
        }
      })
      .catch(() => {
        if (!ignore) {
          setTeams([
            { id: 1, name: "Simba SC", country: "Tanzania", type: "CLUB" },
            { id: 2, name: "Yanga SC", country: "Tanzania", type: "CLUB" },
            { id: 3, name: "Azam FC", country: "Tanzania", type: "CLUB" },
            { id: 4, name: "Singida Black Stars", country: "Tanzania", type: "CLUB" },
            { id: 5, name: "Coastal Union", country: "Tanzania", type: "CLUB" },
            { id: 6, name: "Namungo FC", country: "Tanzania", type: "CLUB" },
            { id: 7, name: "Geita Gold FC", country: "Tanzania", type: "CLUB" },
            { id: 8, name: "Pamba Jiji", country: "Tanzania", type: "CLUB" },
          ]);
          setLoading(false);
        }
      });

    return () => {
      ignore = true;
    };
  }, [isOpen, teams.length]);

  useEffect(() => {
    function onKeyDown(e: KeyboardEvent) {
      if (e.key === "Escape") handleClose();
    }
    if (isOpen) {
      window.addEventListener("keydown", onKeyDown);
      return () => window.removeEventListener("keydown", onKeyDown);
    }
  });

  if (!isOpen) return null;

  const cleanQ = query.trim().toLowerCase();
  const filteredTeams = cleanQ
    ? teams.filter((t) => t.name.toLowerCase().includes(cleanQ)).slice(0, 8)
    : teams.slice(0, 6);

  const filteredShortcuts = cleanQ
    ? QUICK_SHORTCUTS.filter((s) => s.label.toLowerCase().includes(cleanQ))
    : QUICK_SHORTCUTS;

  const navigateTo = (href: string) => {
    handleClose();
    startTransition(() => {
      router.push(href);
    });
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-start justify-center p-4 sm:pt-20 bg-ink/50 backdrop-blur-xs animate-in fade-in duration-150"
      onClick={handleClose}
    >
      <div
        className="w-full max-w-xl overflow-hidden rounded-2xl border border-line bg-paper shadow-2xl animate-in zoom-in-95 duration-150"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Search Input Bar */}
        <div className="flex items-center border-b border-line px-4 py-3">
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
            type="text"
            placeholder="Search clubs, national teams, or pages..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            autoFocus
            className="w-full bg-transparent text-base font-medium text-ink placeholder:text-muted focus:outline-hidden"
          />
          <kbd className="hidden sm:inline-block rounded border border-line bg-wash px-1.5 py-0.5 text-[10px] font-semibold text-muted">
            ESC
          </kbd>
        </div>

        {/* Search Results */}
        <div className="max-h-[60vh] overflow-y-auto p-2 divide-y divide-line/40">
          {/* Teams / Clubs Section */}
          <div className="py-2">
            <p className="px-3 pb-1.5 text-[11px] font-bold uppercase tracking-wider text-muted">
              Clubs & Teams
            </p>
            {loading ? (
              <p className="px-3 py-2 text-xs text-muted">Loading teams...</p>
            ) : filteredTeams.length > 0 ? (
              <div className="space-y-0.5">
                {filteredTeams.map((t) => (
                  <button
                    key={t.id}
                    onClick={() => navigateTo(`/teams/${t.id}`)}
                    className="flex w-full items-center gap-3 rounded-lg px-3 py-2 text-left text-sm font-medium hover:bg-wash transition-colors group cursor-pointer"
                  >
                    <Crest name={t.name} size={26} />
                    <span className="flex-1 font-semibold text-ink group-hover:text-brand transition-colors">
                      {t.name}
                    </span>
                    {t.country ? (
                      <span className="text-xs text-muted font-normal">{t.country}</span>
                    ) : null}
                  </button>
                ))}
              </div>
            ) : (
              <p className="px-3 py-2 text-xs text-muted">No matching clubs found.</p>
            )}
          </div>

          {/* Quick Shortcuts */}
          {filteredShortcuts.length > 0 && (
            <div className="py-2">
              <p className="px-3 pb-1.5 text-[11px] font-bold uppercase tracking-wider text-muted">
                Quick Navigation
              </p>
              <div className="space-y-0.5">
                {filteredShortcuts.map((s) => (
                  <button
                    key={s.href}
                    onClick={() => navigateTo(s.href)}
                    className="flex w-full items-center justify-between rounded-lg px-3 py-2 text-left text-sm font-medium hover:bg-wash transition-colors text-ink group cursor-pointer"
                  >
                    <span className="group-hover:text-brand transition-colors">{s.label}</span>
                    <span className="text-xs text-muted">Go →</span>
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Modal Footer */}
        <div className="flex items-center justify-between border-t border-line bg-wash/60 px-4 py-2 text-[11px] text-muted">
          <span>Search the SokaBrain football vault</span>
          <span>Tip: Press ESC to close</span>
        </div>
      </div>
    </div>
  );
}
