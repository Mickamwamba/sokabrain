"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useLanguage } from "@/lib/i18n";
import { useFanProfile, POPULAR_FAN_TEAMS } from "@/lib/fan-profile";
import { Crest } from "@/components/ui";
import { KijiweSpace } from "./kijiwe-space-card";

export function CreateThreadModal({
  isOpen,
  onClose,
  spaces,
  defaultSpaceSlug,
}: {
  isOpen: boolean;
  onClose: () => void;
  spaces: KijiweSpace[];
  defaultSpaceSlug?: string;
}) {
  const router = useRouter();
  const { lang, t } = useLanguage();
  const { profile, update: updateProfile } = useFanProfile();

  const [spaceSlug, setSpaceSlug] = useState(defaultSpaceSlug || spaces[0]?.slug || "kariakoo-derby");
  const [tag, setTag] = useState<"UBISHI" | "CHOMBEZA" | "UTABIRI" | "MBINU">("UBISHI");
  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [authorName, setAuthorName] = useState(profile.name || "");
  const [authorTeam, setAuthorTeam] = useState(profile.team || "Simba SC");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState("");

  if (!isOpen) return null;

  const currentSpace = spaces.find((s) => s.slug === spaceSlug) || spaces[0];
  const currentSpaceName = currentSpace
    ? lang === "sw"
      ? currentSpace.nameSw
      : currentSpace.nameEn
    : "";
  const currentSpaceDesc = currentSpace
    ? lang === "sw"
      ? currentSpace.descriptionSw
      : currentSpace.descriptionEn
    : "";

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !content.trim()) {
      setError(lang === "sw" ? "Tafadhali jaza kichwa na maelezo ya mada" : "Please enter title and content");
      return;
    }

    const finalAuthor = (authorName || profile.name).trim() || "Shabiki wa Soka";
    const finalTeam = authorTeam || profile.team || "Simba SC";

    // Save profile for future
    updateProfile({ name: finalAuthor, team: finalTeam });

    setIsSubmitting(true);
    setError("");

    try {
      const res = await fetch("/api/kijiweni/threads", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          spaceSlug,
          tag,
          title: title.trim(),
          content: content.trim(),
          authorName: finalAuthor,
          authorTeamName: finalTeam,
        }),
      });

      if (!res.ok) {
        const errData = await res.json();
        throw new Error(errData.error || "Failed to create thread");
      }

      const data = await res.json();
      onClose();
      router.push(`/kijiweni/${spaceSlug}/${data.thread.id}`);
      router.refresh();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "Error creating thread";
      setError(msg);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4">
      <div className="w-full max-w-lg rounded-xl border border-line bg-paper p-5 sm:p-6 shadow-xl space-y-4 max-h-[92vh] overflow-y-auto">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-line/40 pb-3">
          <div>
            <h3 className="text-base font-bold text-ink">{t.kijiweni.startThread}</h3>
            <p className="text-xs text-muted mt-0.5">{t.kijiweni.startThreadSub}</p>
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label={t.kijiweni.cancel}
            className="text-muted hover:text-ink text-xl font-bold p-1 cursor-pointer"
          >
            ×
          </button>
        </div>

        {error && (
          <div className="rounded-lg bg-rose-500/10 border border-rose-500/20 px-3 py-2 text-xs font-medium text-rose-600">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Explicit Kijiwe Destination Choice */}
          <div className="space-y-2">
            <label className="block text-xs font-bold text-ink">
              {t.kijiweni.selectSpace}
            </label>
            <select
              value={spaceSlug}
              onChange={(e) => setSpaceSlug(e.target.value)}
              aria-label={t.kijiweni.selectSpace}
              className="w-full rounded-lg border border-line bg-wash/40 px-3 py-2 text-xs font-bold text-ink focus:border-brand focus:bg-paper focus:outline-none"
            >
              {spaces.map((s) => {
                const name = lang === "sw" ? s.nameSw : s.nameEn;
                return (
                  <option key={s.slug} value={s.slug}>
                    {s.icon} {name}
                  </option>
                );
              })}
            </select>

            {/* Destination Confirmation Card */}
            {currentSpace && (
              <div className="rounded-lg border border-line/70 bg-wash/40 p-2.5 flex items-start gap-2.5 text-xs">
                <span className="text-lg select-none shrink-0">{currentSpace.icon}</span>
                <div className="space-y-0.5">
                  <div className="text-ink font-semibold">
                    {t.kijiweni.postingIn}{" "}
                    <span className="text-brand font-bold">{currentSpaceName}</span>
                  </div>
                  <p className="text-[11px] text-muted leading-relaxed">
                    {currentSpaceDesc}
                  </p>
                </div>
              </div>
            )}
          </div>

          {/* Category Tag */}
          <div>
            <label className="block text-xs font-bold text-ink mb-1.5">
              {t.kijiweni.selectTag}
            </label>
            <div className="flex flex-wrap gap-1.5">
              {(["UBISHI", "CHOMBEZA", "UTABIRI", "MBINU"] as const).map((tKey) => {
                const isSelected = tag === tKey;
                return (
                  <button
                    key={tKey}
                    type="button"
                    onClick={() => setTag(tKey)}
                    className={`rounded px-2.5 py-1 text-xs font-semibold transition-colors cursor-pointer ${
                      isSelected
                        ? "bg-ink text-white"
                        : "bg-wash border border-line text-muted hover:text-ink hover:border-ink/40"
                    }`}
                  >
                    {t.tags[tKey]}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Title */}
          <div>
            <label className="block text-xs font-bold text-ink mb-1">
              Kichwa cha Mada <span className="text-rose-500">*</span>
            </label>
            <input
              type="text"
              required
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder={t.kijiweni.titlePlaceholder}
              className="w-full rounded-lg border border-line bg-wash/30 px-3 py-2 text-sm font-semibold text-ink placeholder:text-muted focus:border-brand focus:bg-paper focus:outline-none transition-colors"
            />
          </div>

          {/* Content */}
          <div>
            <label className="block text-xs font-bold text-ink mb-1">
              Maudhui / Maelezo <span className="text-rose-500">*</span>
            </label>
            <textarea
              required
              rows={4}
              value={content}
              onChange={(e) => setContent(e.target.value)}
              placeholder={t.kijiweni.contentPlaceholder}
              className="w-full rounded-lg border border-line bg-wash/30 px-3 py-2 text-sm text-ink placeholder:text-muted focus:border-brand focus:bg-paper focus:outline-none transition-colors"
            />
          </div>

          {/* Fan Identity */}
          <div className="rounded-lg border border-line bg-wash/40 p-3 space-y-2">
            <div className="flex items-center justify-between text-xs font-bold text-ink">
              <span>{t.kijiweni.fanHandle}:</span>
              <span className="text-muted font-normal text-[11px]">Hifadhiwa kiotomatiki</span>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
              <input
                type="text"
                value={authorName}
                onChange={(e) => setAuthorName(e.target.value)}
                placeholder="Jina lako kijiweni"
                className="rounded border border-line bg-paper px-2.5 py-1.5 text-xs font-bold text-ink focus:border-brand focus:outline-none"
              />
              <select
                value={authorTeam}
                onChange={(e) => setAuthorTeam(e.target.value)}
                aria-label="Klabu unayoshabikia"
                className="rounded border border-line bg-paper px-2.5 py-1.5 text-xs font-semibold text-ink focus:border-brand focus:outline-none"
              >
                {POPULAR_FAN_TEAMS.map((tName) => (
                  <option key={tName} value={tName}>
                    {tName}
                  </option>
                ))}
              </select>
            </div>
            <div className="flex items-center gap-2 pt-0.5 text-xs">
              <Crest name={authorTeam} size={18} />
              <span className="font-bold text-ink">{authorName || "Shabiki wa Soka"}</span>
              <span className="text-[11px] text-muted">({authorTeam})</span>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex items-center justify-end gap-2 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="px-3.5 py-1.5 text-xs font-semibold text-muted hover:text-ink transition-colors cursor-pointer"
            >
              {t.kijiweni.cancel}
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="rounded-lg bg-brand px-5 py-2 text-xs font-bold text-white hover:bg-brand/90 transition-colors disabled:opacity-50 cursor-pointer"
            >
              {isSubmitting ? "Inapakia..." : t.kijiweni.postThread}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
