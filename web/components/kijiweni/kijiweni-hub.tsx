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
    <div className="space-y-5">
      {/* Standard Clean Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-line pb-4">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-xl sm:text-2xl font-bold text-ink">
              {activeSpaceName ? activeSpaceName : t.kijiweni.heroTitle}
            </h1>
            {activeSpace && <span className="text-xl">{activeSpace.icon}</span>}
          </div>
          <p className="text-xs sm:text-sm text-muted mt-1 max-w-xl leading-relaxed">
            {activeSpaceDesc ? activeSpaceDesc : t.kijiweni.heroSub}
          </p>
        </div>

        {/* Action: Anzisha Mada + Fan Handle Trigger */}
        <div className="flex items-center gap-2.5 shrink-0">
          <button
            onClick={() => setCreateModalOpen(true)}
            className="inline-flex items-center gap-1.5 rounded-lg bg-brand hover:bg-brand/90 px-4 py-2 text-xs font-bold text-white transition-colors cursor-pointer"
          >
            <span>+</span>
            <span>{t.kijiweni.startThread}</span>
          </button>

          {/* Fan Handle Badge */}
          <button
            onClick={() => setProfileModalOpen(true)}
            className="inline-flex items-center gap-1.5 rounded-lg border border-line bg-paper px-3 py-1.5 text-xs text-ink hover:bg-wash transition-colors cursor-pointer"
          >
            <Crest name={profile.team || "Simba SC"} size={18} />
            <span className="font-semibold">{profile.name || t.kijiweni.fanHandle}</span>
          </button>
        </div>
      </div>

      {/* Static Vijiwe Spaces Grid (shown when on main hub) */}
      {!activeSpaceSlug && (
        <div className="space-y-2">
          <div className="flex items-center justify-between px-0.5">
            <h2 className="text-xs font-bold uppercase tracking-wider text-muted">
              {t.kijiweni.allSpaces}
            </h2>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
            {spaces.map((space) => (
              <KijiweSpaceCard key={space.slug} space={space} />
            ))}
          </div>
        </div>
      )}

      {/* Filter & Sort Bar */}
      <div className="flex flex-wrap items-center justify-between gap-2.5 rounded-xl border border-line bg-paper p-2.5">
        {/* Category Tags */}
        <div className="flex flex-wrap items-center gap-1.5">
          <button
            type="button"
            onClick={() => setSelectedTag("ALL")}
            className={`rounded px-2.5 py-1 text-xs font-semibold transition-colors cursor-pointer ${
              selectedTag === "ALL"
                ? "bg-ink text-white"
                : "border border-line/60 bg-wash/40 text-muted hover:text-ink hover:bg-wash"
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
                className={`rounded px-2.5 py-1 text-xs font-semibold transition-colors cursor-pointer ${
                  isSelected
                    ? "bg-ink text-white"
                    : "border border-line/60 bg-wash/40 text-muted hover:text-ink hover:bg-wash"
                }`}
              >
                {t.tags[tKey]}
              </button>
            );
          })}
        </div>

        {/* Sort Switcher (Latest / Popular) */}
        <div className="inline-flex rounded-lg border border-line bg-wash/40 p-0.5 text-xs font-semibold">
          <button
            type="button"
            onClick={() => setSortOrder("latest")}
            className={`rounded px-2.5 py-1 transition-colors cursor-pointer ${
              sortOrder === "latest" ? "bg-paper text-ink font-bold shadow-2xs" : "text-muted hover:text-ink"
            }`}
          >
            {t.kijiweni.sortLatest}
          </button>
          <button
            type="button"
            onClick={() => setSortOrder("popular")}
            className={`rounded px-2.5 py-1 transition-colors cursor-pointer ${
              sortOrder === "popular" ? "bg-paper text-ink font-bold shadow-2xs" : "text-muted hover:text-ink"
            }`}
          >
            {t.kijiweni.sortPopular}
          </button>
        </div>
      </div>

      {/* Threads Stream */}
      {filteredThreads.length === 0 ? (
        <div className="rounded-xl border border-line bg-wash/20 p-10 text-center space-y-2">
          <p className="text-sm font-semibold text-ink">{t.kijiweni.noThreads}</p>
          <p className="text-xs text-muted max-w-sm mx-auto">{t.kijiweni.noThreadsSub}</p>
          <button
            onClick={() => setCreateModalOpen(true)}
            className="rounded-lg bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand/90 transition-colors cursor-pointer"
          >
            {t.kijiweni.startThread}
          </button>
        </div>
      ) : (
        <div className="space-y-3">
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
