"use client";

import { useState } from "react";
import Link from "next/link";
import { useLanguage } from "@/lib/i18n";
import { useFanProfile } from "@/lib/fan-profile";
import { Crest } from "@/components/ui";
import { FanProfileModal } from "./fan-profile-modal";

export interface CommentItem {
  id: number;
  authorName: string;
  authorTeamName?: string | null;
  content: string;
  likesCount: number;
  createdAt: string;
}

export interface ThreadDetail {
  id: number;
  title: string;
  content: string;
  authorName: string;
  authorTeamName?: string | null;
  tag: string;
  likesCount: number;
  commentsCount: number;
  createdAt: string;
  kijiwe: {
    slug: string;
    nameSw: string;
    nameEn: string;
    icon: string;
    badgeColor: string;
  };
  comments: CommentItem[];
}

export function ThreadDetailView({ initialThread }: { initialThread: ThreadDetail }) {
  const { lang, t } = useLanguage();
  const { profile, hasProfile } = useFanProfile();

  const [thread, setThread] = useState<ThreadDetail>(initialThread);
  const [likes, setLikes] = useState(initialThread.likesCount);
  const [hasLiked, setHasLiked] = useState(false);
  const [copied, setCopied] = useState(false);

  // Comment input state
  const [commentText, setCommentText] = useState("");
  const [isSubmittingComment, setIsSubmittingComment] = useState(false);
  const [profileModalOpen, setProfileModalOpen] = useState(false);
  const [commentError, setCommentError] = useState("");

  const spaceName = lang === "sw" ? thread.kijiwe.nameSw : thread.kijiwe.nameEn;
  const tagLabel = t.tags[thread.tag as keyof typeof t.tags] ?? thread.tag;

  const handleThreadLike = async () => {
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
      setHasLiked(!nextLiked);
      setLikes(thread.likesCount);
    }
  };

  const handleShare = async () => {
    const url = typeof window !== "undefined" ? window.location.href : "";
    if (navigator.share) {
      try {
        await navigator.share({
          title: thread.title,
          text: `"${thread.title}" - Kijiweni Sokabrain`,
          url,
        });
        return;
      } catch {
        // Fall through to clipboard
      }
    }
    try {
      await navigator.clipboard.writeText(url);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      // ignore
    }
  };

  const handleCommentSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!commentText.trim()) return;

    if (!hasProfile && !profile.name.trim()) {
      setProfileModalOpen(true);
      return;
    }

    setIsSubmittingComment(true);
    setCommentError("");

    try {
      const res = await fetch(`/api/kijiweni/threads/${thread.id}/comments`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          authorName: profile.name.trim() || "Mwanakijiwe",
          authorTeamName: profile.team || "Simba SC",
          content: commentText.trim(),
        }),
      });

      if (!res.ok) throw new Error("Failed to post comment");

      const data = await res.json();
      setThread((prev) => ({
        ...prev,
        commentsCount: prev.commentsCount + 1,
        comments: [...prev.comments, data.comment],
      }));
      setCommentText("");
    } catch {
      setCommentError("Hitilafu imetokea wakati wa kutuma maoni. Jaribu tena.");
    } finally {
      setIsSubmittingComment(false);
    }
  };

  const formatDate = (dateStr: string) => {
    return new Date(dateStr).toLocaleDateString("en-GB", {
      day: "numeric",
      month: "short",
      year: "numeric",
    });
  };

  return (
    <div className="space-y-6 max-w-4xl mx-auto">
      {/* Breadcrumb Navigation */}
      <div className="flex items-center gap-2 text-xs text-muted">
        <Link href="/kijiweni" className="hover:text-ink transition-colors font-semibold">
          Kijiweni
        </Link>
        <span>/</span>
        <Link
          href={`/kijiweni/${thread.kijiwe.slug}`}
          className="hover:text-ink transition-colors font-semibold flex items-center gap-1"
        >
          <span>{thread.kijiwe.icon}</span>
          <span>{spaceName}</span>
        </Link>
      </div>

      {/* Main Thread Card */}
      <div className="rounded-xl border border-line bg-paper p-5 sm:p-6 space-y-4">
        {/* Meta Header */}
        <div className="flex flex-wrap items-center justify-between gap-3 border-b border-line/40 pb-3.5">
          <div className="flex items-center gap-3">
            {thread.authorTeamName ? (
              <Crest name={thread.authorTeamName} size={32} />
            ) : (
              <div className="flex h-8 w-8 items-center justify-center rounded-full bg-wash text-muted text-xs font-bold">
                ⚽
              </div>
            )}
            <div>
              <div className="flex items-center gap-2">
                <span className="font-bold text-sm text-ink">{thread.authorName}</span>
                {thread.authorTeamName && (
                  <span className="rounded bg-wash px-2 py-0.5 text-[11px] font-medium text-muted border border-line/50">
                    {thread.authorTeamName}
                  </span>
                )}
              </div>
              <span className="text-[11px] text-muted">{formatDate(thread.createdAt)}</span>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <span className="rounded bg-wash px-2.5 py-1 text-xs font-bold uppercase tracking-wider text-muted border border-line/50">
              {tagLabel}
            </span>
          </div>
        </div>

        {/* Title and Full Content */}
        <div className="space-y-3 py-1">
          <h1 className="text-xl sm:text-2xl font-bold text-ink leading-snug">
            {thread.title}
          </h1>
          <div className="text-sm sm:text-base text-ink/90 leading-relaxed whitespace-pre-line">
            {thread.content}
          </div>
        </div>

        {/* Action Bar */}
        <div className="flex flex-wrap items-center justify-between gap-3 border-t border-line/40 pt-3 text-xs">
          <div className="flex items-center gap-2">
            {/* Like */}
            <button
              onClick={handleThreadLike}
              className={`inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-xs font-semibold transition-colors cursor-pointer ${
                hasLiked
                  ? "bg-rose-500/10 text-rose-600 border border-rose-500/30"
                  : "border border-line/60 bg-wash/40 text-muted hover:text-ink hover:bg-wash"
              }`}
            >
              <span>{hasLiked ? "❤️" : "🤍"}</span>
              <span className="nums font-bold">{likes}</span>
              <span className="hidden sm:inline text-muted font-normal">{t.kijiweni.likesCount}</span>
            </button>

            {/* Comment Count Anchor */}
            <a
              href="#comments"
              className="inline-flex items-center gap-1.5 rounded-lg border border-line/60 bg-wash/40 px-3 py-1.5 text-xs font-semibold text-muted hover:text-ink hover:bg-wash transition-colors"
            >
              <span>💬</span>
              <span className="nums font-bold">{thread.commentsCount}</span>
              <span className="hidden sm:inline text-muted font-normal">{t.kijiweni.commentsCount}</span>
            </a>
          </div>

          {/* Single Share Button */}
          <div>
            <button
              onClick={handleShare}
              aria-label={t.kijiweni.shareThread}
              className="inline-flex items-center gap-1.5 rounded-lg border border-line/60 bg-wash/40 hover:bg-wash px-3 py-1.5 text-xs font-semibold text-muted hover:text-ink transition-colors cursor-pointer"
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

      {/* Discussion / Comments Stream */}
      <div id="comments" className="space-y-4 pt-2">
        <div className="flex items-center justify-between px-1">
          <h2 className="text-base font-bold text-ink flex items-center gap-2">
            <span>{t.kijiweni.commentsTitle}</span>
            <span className="rounded bg-wash px-2 py-0.5 text-xs text-muted border border-line/60">
              {thread.comments.length}
            </span>
          </h2>

          {/* Fan Handle indicator */}
          <button
            onClick={() => setProfileModalOpen(true)}
            className="flex items-center gap-1.5 text-xs font-semibold text-brand hover:underline cursor-pointer"
          >
            <Crest name={profile.team || "Simba SC"} size={16} />
            <span>{profile.name || t.kijiweni.changeProfile}</span>
          </button>
        </div>

        {/* Comment Box */}
        <form
          onSubmit={handleCommentSubmit}
          className="rounded-xl border border-line bg-paper p-4 space-y-3"
        >
          <div className="flex items-center gap-2 text-xs text-muted pb-0.5">
            <span>Unaandika kama:</span>
            <span className="text-ink font-bold">{profile.name || "Shabiki mgeni"}</span>
            <span className="text-muted">({profile.team || "Simba SC"})</span>
          </div>

          <textarea
            rows={3}
            required
            value={commentText}
            onChange={(e) => setCommentText(e.target.value)}
            placeholder={t.kijiweni.commentPlaceholder}
            className="w-full rounded-lg border border-line bg-wash/30 p-3 text-sm text-ink placeholder:text-muted focus:border-brand focus:bg-paper focus:outline-none transition-colors"
          />

          {commentError && (
            <p className="text-xs text-rose-500 font-medium">{commentError}</p>
          )}

          <div className="flex items-center justify-end pt-1">
            <button
              type="submit"
              disabled={isSubmittingComment}
              className="rounded-lg bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand/90 transition-colors disabled:opacity-50 cursor-pointer"
            >
              {isSubmittingComment ? "Inatuma..." : t.kijiweni.postComment}
            </button>
          </div>
        </form>

        {/* Comments List */}
        {thread.comments.length === 0 ? (
          <div className="rounded-xl border border-line bg-wash/20 p-8 text-center space-y-1">
            <p className="text-sm font-semibold text-ink">{t.kijiweni.noComments}</p>
            <p className="text-xs text-muted">{t.kijiweni.noCommentsSub}</p>
          </div>
        ) : (
          <div className="space-y-3">
            {thread.comments.map((comment) => (
              <div
                key={comment.id}
                className="rounded-xl border border-line bg-paper p-3.5 space-y-2"
              >
                <div className="flex items-center justify-between text-xs">
                  <div className="flex items-center gap-2">
                    {comment.authorTeamName ? (
                      <Crest name={comment.authorTeamName} size={20} />
                    ) : (
                      <span className="flex h-5 w-5 items-center justify-center rounded-full bg-wash text-muted text-[10px] font-bold">
                        ⚽
                      </span>
                    )}
                    <span className="font-bold text-ink">{comment.authorName}</span>
                    {comment.authorTeamName && (
                      <span className="text-[11px] text-muted">
                        • {comment.authorTeamName}
                      </span>
                    )}
                  </div>
                  <span className="text-[11px] text-muted">{formatDate(comment.createdAt)}</span>
                </div>

                <p className="text-xs sm:text-sm text-ink leading-relaxed whitespace-pre-line pl-7">
                  {comment.content}
                </p>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Fan Profile Modal */}
      <FanProfileModal
        isOpen={profileModalOpen}
        onClose={() => setProfileModalOpen(false)}
      />
    </div>
  );
}
