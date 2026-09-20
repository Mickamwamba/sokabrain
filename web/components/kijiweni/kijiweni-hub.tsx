"use client";

import { useState } from "react";
import { useLanguage } from "@/lib/i18n";
import { useFanProfile } from "@/lib/fan-profile";
import { Crest } from "@/components/ui";
import { KijiweSpaceCard, KijiweSpace } from "./kijiwe-space-card";
import { ThreadCard, ThreadItem } from "./thread-card";
import { CreateThreadModal } from "./create-thread-modal";
import { FanProfileModal } from "./fan-profile-modal";

export function KijiweniHub({
  spaces,
  initialThreads,
  activeSpaceSlug,
}: {
  spaces: KijiweSpace[];
  initialThreads: ThreadItem[];
  activeSpaceSlug?: string;
}) {
  const { lang, t } = useLanguage();
  const { profile } = useFanProfile();

  const [selectedTag, setSelectedTag] = useState<string>("ALL");
  const [sortOrder, setSortOrder] = useState<"latest" | "popular">("latest");
  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [profileModalOpen, setProfileModalOpen] = useState(false);

  // Client-side filter
  const filteredThreads = initialThreads
    .filter((th) => {
      if (activeSpaceSlug && th.kijiwe.slug !== activeSpaceSlug) return false;
      if (selectedTag !== "ALL" && th.tag !== selectedTag) return false;
      return true;
    })
    .sort((a, b) => {
      if (sortOrder === "popular") {
        return b.likesCount - a.likesCount;
      }
      return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
    });

  const activeSpace = activeSpaceSlug ? spaces.find((s) => s.slug === activeSpaceSlug) : null;
  const activeSpaceName = activeSpace ? (lang === "sw" ? activeSpace.nameSw : activeSpace.nameEn) : null;
  const activeSpaceDesc = activeSpace ? (lang === "sw" ? activeSpace.descriptionSw : activeSpace.descriptionEn) : null;

  return (
    <div className="space-y-6">
      {/* Kijiweni Hero Banner */}
      <div className="relative overflow-hidden rounded-3xl border border-line bg-gradient-to-br from-ink via-ink/95 to-ink p-6 sm:p-8 text-white shadow-md">
        <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div className="space-y-2 max-w-2xl">
            <div className="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-3 py-1 text-xs font-bold text-brand-light backdrop-blur-xs">
              <span>🔥</span>
              <span>{activeSpaceName ? activeSpaceName : t.kijiweni.heroTitle}</span>
            </div>
            <h1 className="text-2xl sm:text-3xl lg:text-4xl font-black tracking-tight text-white">
              {activeSpaceName ? activeSpaceName : t.kijiweni.heroTitle}
            </h1>
            <p className="text-xs sm:text-sm text-white/70 leading-relaxed max-w-xl">
              {activeSpaceDesc ? activeSpaceDesc : t.kijiweni.heroSub}
            </p>
          </div>

          {/* Right Action: Anzisha Mada + Fan Handle Trigger */}
          <div className="flex flex-col sm:flex-row md:flex-col items-start md:items-end gap-3 shrink-0">
            <button
              onClick={() => setCreateModalOpen(true)}
              className="inline-flex items-center gap-2 rounded-2xl bg-brand hover:bg-brand-light px-5 py-3 text-sm font-black text-white shadow-lg transition-all hover:scale-[1.02] cursor-pointer"
            >
              <span>✍️</span>
              <span>{t.kijiweni.startThread}</span>
            </button>

            {/* Fan Handle Badge */}
            <button
              onClick={() => setProfileModalOpen(true)}
              className="inline-flex items-center gap-2 rounded-xl border border-white/15 bg-white/10 px-3 py-1.5 text-xs text-white/80 hover:bg-white/15 transition-all cursor-pointer"
            >
              <Crest name={profile.team || "Simba SC"} size={20} />
              <span className="font-bold">{profile.name || t.kijiweni.fanHandle}</span>
              <span className="text-white/40 text-[10px]">✏️</span>
            </button>
          </div>
        </div>

        {/* Ambient background glow */}
        <div className="pointer-events-none absolute -bottom-10 -right-10 h-64 w-64 rounded-full bg-brand/20 blur-3xl" />
      </div>

      {/* Static Vijiwe Spaces Carousel / Grid (shown when on main hub) */}
      {!activeSpaceSlug && (
        <div className="space-y-2.5">
          <div className="flex items-center justify-between px-1">
            <h2 className="text-xs font-black uppercase tracking-wider text-muted">
              {t.kijiweni.allSpaces}
            </h2>
            <span className="text-[11px] font-semibold text-brand">
              {spaces.length} Vijiwe
            </span>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3.5">
            {spaces.map((space) => (
              <KijiweSpaceCard key={space.slug} space={space} />
            ))}
          </div>
        </div>
      )}

      {/* Filter & Sort Bar */}
      <div className="flex flex-wrap items-center justify-between gap-3 rounded-2xl border border-line bg-paper p-3 shadow-2xs">
        {/* Category Tags */}
        <div className="flex flex-wrap items-center gap-1.5 overflow-x-auto pb-1 sm:pb-0">
          <button
            type="button"
            onClick={() => setSelectedTag("ALL")}
            className={`rounded-full px-3 py-1 text-xs font-bold transition-all cursor-pointer ${
              selectedTag === "ALL"
                ? "bg-ink text-white shadow-xs"
                : "border border-line/60 bg-wash/50 text-ink hover:bg-wash"
            }`}
          >
            {t.kijiweni.allTags}
          </button>
          {(["UBISHI", "CHOMBEZA", "UTABIRI", "MBINU"] as const).map((tKey) => {
            const isSelected = selectedTag === tKey;
            return (
              <button
                key={tKey}
                type="button"
                onClick={() => setSelectedTag(tKey)}
                className={`rounded-full px-3 py-1 text-xs font-bold transition-all cursor-pointer ${
                  isSelected
                    ? "bg-ink text-white shadow-xs"
                    : "border border-line/60 bg-wash/50 text-ink hover:bg-wash"
                }`}
              >
                {t.tags[tKey]}
              </button>
            );
          })}
        </div>

        {/* Sort Switcher (Latest / Popular) */}
        <div className="inline-flex rounded-xl border border-line bg-wash/50 p-0.5 text-xs font-bold">
          <button
            type="button"
            onClick={() => setSortOrder("latest")}
            className={`rounded-lg px-2.5 py-1 transition-all cursor-pointer ${
              sortOrder === "latest" ? "bg-paper text-ink shadow-2xs" : "text-muted hover:text-ink"
            }`}
          >
            {t.kijiweni.sortLatest}
          </button>
          <button
            type="button"
            onClick={() => setSortOrder("popular")}
            className={`rounded-lg px-2.5 py-1 transition-all cursor-pointer ${
              sortOrder === "popular" ? "bg-paper text-ink shadow-2xs" : "text-muted hover:text-ink"
            }`}
          >
            {t.kijiweni.sortPopular}
          </button>
        </div>
      </div>

      {/* Threads Stream */}
      {filteredThreads.length === 0 ? (
        <div className="rounded-3xl border border-line bg-wash/30 p-12 text-center space-y-3">
          <span className="text-4xl">☕</span>
          <h3 className="text-base font-black text-ink">{t.kijiweni.noThreads}</h3>
          <p className="text-xs text-muted max-w-sm mx-auto">{t.kijiweni.noThreadsSub}</p>
          <button
            onClick={() => setCreateModalOpen(true)}
            className="rounded-xl bg-brand px-5 py-2.5 text-xs font-black text-white hover:bg-brand/90 transition-all shadow-sm cursor-pointer"
          >
            {t.kijiweni.startThread}
          </button>
        </div>
      ) : (
        <div className="space-y-4">
          {filteredThreads.map((thread) => (
            <ThreadCard
              key={thread.id}
              thread={thread}
              showSpaceBadge={!activeSpaceSlug}
            />
          ))}
        </div>
      )}

      {/* Modals */}
      <CreateThreadModal
        isOpen={createModalOpen}
        onClose={() => setCreateModalOpen(false)}
        spaces={spaces}
        defaultSpaceSlug={activeSpaceSlug}
      />

      <FanProfileModal
        isOpen={profileModalOpen}
        onClose={() => setProfileModalOpen(false)}
      />
    </div>
  );
}
