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
          text: `"${thread.title}" - Kijiweni Sokabrain`,
          url,
        });
        return;
      } catch {
        // user cancelled or share sheet failed, fall through to clipboard
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

  const formattedDate = new Date(thread.createdAt).toLocaleDateString("en-GB", {
    day: "numeric",
    month: "short",
  });

  return (
    <div className="group rounded-xl border border-line bg-paper p-4 transition-colors hover:border-ink/30">
      {/* Top Meta: Author + Team Crest + Space Tag */}
      <div className="flex flex-wrap items-center justify-between gap-2 border-b border-line/40 pb-2.5 text-xs">
        <div className="flex items-center gap-2 min-w-0">
          {thread.authorTeamName ? (
            <Crest name={thread.authorTeamName} size={22} />
          ) : (
            <span className="flex h-5 w-5 items-center justify-center rounded-full bg-wash text-muted text-[11px] font-bold">
              ⚽
            </span>
          )}
          <span className="font-bold text-ink truncate max-w-[150px]">
            {thread.authorName}
          </span>
          {thread.authorTeamName && (
            <span className="hidden sm:inline text-[11px] text-muted truncate max-w-[120px]">
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
              className="inline-flex items-center gap-1 rounded bg-wash px-2 py-0.5 text-[11px] font-medium text-ink hover:bg-wash/80 border border-line/50 transition-colors"
            >
              <span>{thread.kijiwe.icon}</span>
              <span className="truncate max-w-[120px]">{spaceName}</span>
            </Link>
          )}
          <span className="rounded bg-wash px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider text-muted border border-line/50">
            {tagLabel}
          </span>
        </div>
      </div>

      {/* Main Content (Clickable Link to Thread Detail) */}
      <Link
        href={`/kijiweni/${thread.kijiwe.slug}/${thread.id}`}
        className="block py-3 space-y-1.5 group/body"
      >
        <h3 className="text-base font-bold text-ink group-hover/body:text-brand transition-colors leading-snug">
          {thread.title}
        </h3>
        <p className="text-xs sm:text-sm text-muted leading-relaxed line-clamp-2">
          {thread.content}
        </p>
      </Link>

      {/* Action Bar: Likes, Comments, Single Share */}
      <div className="flex items-center justify-between border-t border-line/40 pt-2.5 text-xs">
        {/* Left: Like & Comment actions */}
        <div className="flex items-center gap-2">
          {/* Like Button */}
          <button
            type="button"
            onClick={handleLike}
            className={`inline-flex items-center gap-1.5 rounded-lg px-2.5 py-1 text-xs font-semibold transition-colors cursor-pointer ${
              hasLiked
                ? "bg-rose-500/10 text-rose-600 border border-rose-500/30"
                : "border border-line/60 bg-wash/40 text-muted hover:text-ink hover:bg-wash"
            }`}
          >
            <span>{hasLiked ? "❤️" : "🤍"}</span>
            <span className="nums font-bold">{likes}</span>
          </button>

          {/* Comment Count Link */}
          <Link
            href={`/kijiweni/${thread.kijiwe.slug}/${thread.id}#comments`}
            className="inline-flex items-center gap-1.5 rounded-lg border border-line/60 bg-wash/40 px-2.5 py-1 text-xs font-semibold text-muted hover:text-ink hover:bg-wash transition-colors"
          >
            <span>💬</span>
            <span className="nums font-bold">{thread.commentsCount}</span>
            <span className="hidden sm:inline text-muted">
              {t.kijiweni.commentsCount}
            </span>
          </Link>
        </div>

        {/* Right: Single Share Button */}
        <div>
          <button
            type="button"
            onClick={handleShare}
            aria-label={t.kijiweni.shareThread}
            className="inline-flex items-center gap-1.5 rounded-lg border border-line/60 bg-wash/40 hover:bg-wash px-2.5 py-1 text-xs font-semibold text-muted hover:text-ink transition-colors cursor-pointer"
          >
            <svg
              className="h-3.5 w-3.5"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z"
              />
            </svg>
            <span>{copied ? t.kijiweni.copiedLink : t.kijiweni.shareThread}</span>
          </button>
        </div>
      </div>
    </div>
  );
}
