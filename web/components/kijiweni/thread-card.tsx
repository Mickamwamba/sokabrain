"use client";

import { useState } from "react";
import Link from "next/link";
import { useLanguage } from "@/lib/i18n";
import { useFanProfile } from "@/lib/fan-profile";
import { Crest } from "@/components/ui";

export interface ThreadItem {
  id: number;
  title: string;
  content: string;
  authorName: string;
  authorTeamName?: string | null;
  tag: "UBISHI" | "CHOMBEZA" | "UTABIRI" | "MBINU" | string;
  likesCount: number;
  commentsCount: number;
  isPinned?: boolean;
  createdAt: string;
  kijiwe: {
    slug: string;
    nameSw: string;
    nameEn: string;
    icon: string;
    badgeColor: string;
  };
}

export function ThreadCard({
  thread,
  showSpaceBadge = true,
}: {
  thread: ThreadItem;
  showSpaceBadge?: boolean;
}) {
  const { lang, t } = useLanguage();
  const { profile } = useFanProfile();
  const [likes, setLikes] = useState(thread.likesCount);
  const [hasLiked, setHasLiked] = useState(false);
  const [isLiking, setIsLiking] = useState(false);
  const [copied, setCopied] = useState(false);

  const spaceName = lang === "sw" ? thread.kijiwe.nameSw : thread.kijiwe.nameEn;
  const tagLabel = t.tags[thread.tag as keyof typeof t.tags] ?? thread.tag;

  const handleLike = async (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (isLiking) return;
    setIsLiking(true);

    // Optimistic UI
    const nextLiked = !hasLiked;
    setHasLiked(nextLiked);
    setLikes((prev) => (nextLiked ? prev + 1 : Math.max(0, prev - 1)));

    try {
      const res = await fetch(`/api/kijiweni/threads/${thread.id}/like`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          fanFingerprint: profile.fingerprint || "anon_fan",
          reactionType: "LIKE",
        }),
      });
      if (res.ok) {
        const data = await res.json();
        setLikes(data.likesCount);
        setHasLiked(data.liked);
      }
    } catch {
      // rollback
      setHasLiked(!nextLiked);
      setLikes(thread.likesCount);
    } finally {
      setIsLiking(false);
    }
  };

  const handleShare = async (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    const url = typeof window !== "undefined" ? `${window.location.origin}/kijiweni/${thread.kijiwe.slug}/${thread.id}` : "";

    if (navigator.share) {
      try {
        await navigator.share({
          title: thread.title,
          text: `"${thread.title}" - Kijiweni SokaBrain`,
          url,
        });
        return;
      } catch {
        // Fallback to clipboard
      }
    }

    // Clipboard fallback
    try {
      await navigator.clipboard.writeText(url);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      // ignore
    }
  };

  const handleWhatsApp = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    const url = typeof window !== "undefined" ? `${window.location.origin}/kijiweni/${thread.kijiwe.slug}/${thread.id}` : "";
    const msg = encodeURIComponent(`🔥 Mada Kijiweni: *${thread.title}*\n\nFungua usome na ubishe hapa: ${url}`);
    window.open(`https://api.whatsapp.com/send?text=${msg}`, "_blank");
  };

  const formattedDate = new Date(thread.createdAt).toLocaleDateString("en-GB", {
    day: "numeric",
    month: "short",
  });

  return (
    <div className="group rounded-2xl border border-line bg-paper p-4 sm:p-5 shadow-xs hover:border-ink/40 transition-all">
      {/* Top Meta: Author + Team Crest + Space Tag */}
      <div className="flex flex-wrap items-center justify-between gap-2 border-b border-line/50 pb-3 text-xs">
        <div className="flex items-center gap-2 min-w-0">
          {thread.authorTeamName ? (
            <Crest name={thread.authorTeamName} size={24} />
          ) : (
            <span className="flex h-6 w-6 items-center justify-center rounded-full bg-brand/10 text-brand text-xs font-black">
              ⚽
            </span>
          )}
          <span className="font-bold text-ink truncate max-w-[150px]">
            {thread.authorName}
          </span>
          {thread.authorTeamName && (
            <span className="hidden sm:inline-block text-[11px] font-semibold text-muted/80 truncate max-w-[120px]">
              • {thread.authorTeamName}
            </span>
          )}
          <span className="text-[11px] text-muted">
            • {formattedDate}
          </span>
        </div>

        <div className="flex items-center gap-2 shrink-0">
          {showSpaceBadge && (
            <Link
              href={`/kijiweni/${thread.kijiwe.slug}`}
              className="inline-flex items-center gap-1 rounded-full bg-wash px-2.5 py-0.5 text-[11px] font-bold text-ink hover:bg-wash/80 border border-line/60 transition-colors"
            >
              <span>{thread.kijiwe.icon}</span>
              <span className="truncate max-w-[120px]">{spaceName}</span>
            </Link>
          )}
          <span className="rounded-full bg-brand/10 px-2.5 py-0.5 text-[10px] font-black uppercase tracking-wider text-brand">
            {tagLabel}
          </span>
        </div>
      </div>

      {/* Main Content (Clickable Link to Thread Detail) */}
      <Link
        href={`/kijiweni/${thread.kijiwe.slug}/${thread.id}`}
        className="block py-3.5 space-y-2 group/body"
      >
        <h3 className="text-base sm:text-lg font-black text-ink group-hover/body:text-brand transition-colors leading-snug">
          {thread.title}
        </h3>
        <p className="text-xs sm:text-sm text-muted leading-relaxed line-clamp-3">
          {thread.content}
        </p>
      </Link>

      {/* Action Bar: Likes, Comments, Share */}
      <div className="flex items-center justify-between border-t border-line/50 pt-3 text-xs">
        {/* Left: Like & Comment actions */}
        <div className="flex items-center gap-2">
          {/* Like Button */}
          <button
            type="button"
            onClick={handleLike}
            className={`inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-bold transition-all cursor-pointer ${
              hasLiked
                ? "bg-rose-500/10 text-rose-600 border border-rose-500/30"
                : "border border-line/70 bg-wash/50 text-ink hover:bg-wash hover:border-ink/30"
            }`}
          >
            <span>{hasLiked ? "❤️" : "🤍"}</span>
            <span className="nums">{likes}</span>
          </button>

          {/* Comment Count Link */}
          <Link
            href={`/kijiweni/${thread.kijiwe.slug}/${thread.id}#comments`}
            className="inline-flex items-center gap-1.5 rounded-full border border-line/70 bg-wash/50 px-3 py-1 text-xs font-bold text-ink hover:bg-wash hover:border-ink/30 transition-all"
          >
            <span>💬</span>
            <span className="nums">{thread.commentsCount}</span>
            <span className="hidden sm:inline font-medium text-muted">
              {t.kijiweni.commentsCount}
            </span>
          </Link>
        </div>

        {/* Right: Share options */}
        <div className="flex items-center gap-1.5">
          <button
            type="button"
            onClick={handleWhatsApp}
            title="Tuma WhatsApp"
            className="inline-flex items-center gap-1 rounded-full bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-700 px-2.5 py-1 text-xs font-bold border border-emerald-500/20 transition-all cursor-pointer"
          >
            <span>📲</span>
            <span className="hidden sm:inline">WhatsApp</span>
          </button>

          <button
            type="button"
            onClick={handleShare}
            className="inline-flex items-center gap-1 rounded-full border border-line/70 bg-wash/50 hover:bg-wash px-2.5 py-1 text-xs font-bold text-ink transition-all cursor-pointer"
          >
            <span>🔗</span>
            <span>{copied ? t.kijiweni.copiedLink : t.kijiweni.shareThread}</span>
          </button>
        </div>
      </div>
    </div>
  );
}
