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
          text: `"${thread.title}" - Kijiweni SokaBrain`,
          url,
        });
        return;
      } catch {
        // Fallback
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

  const handleWhatsApp = () => {
    const url = typeof window !== "undefined" ? window.location.href : "";
    const msg = encodeURIComponent(`🔥 Mada Kijiweni: *${thread.title}*\n\nBisha na toa mtazamo wako hapa: ${url}`);
    window.open(`https://api.whatsapp.com/send?text=${msg}`, "_blank");
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
    });
  };

  return (
    <div className="space-y-6 max-w-4xl mx-auto">
      {/* Breadcrumb Navigation */}
      <div className="flex items-center gap-2 text-xs font-bold text-muted">
        <Link href="/kijiweni" className="hover:text-ink transition-colors">
          Kijiweni
        </Link>
        <span>/</span>
        <Link
          href={`/kijiweni/${thread.kijiwe.slug}`}
          className="hover:text-ink transition-colors flex items-center gap-1"
        >
          <span>{thread.kijiwe.icon}</span>
          <span>{spaceName}</span>
        </Link>
      </div>

      {/* Main Thread Card */}
      <div className="rounded-2xl border border-line bg-paper p-5 sm:p-7 shadow-xs space-y-4">
        {/* Meta Header */}
        <div className="flex flex-wrap items-center justify-between gap-3 border-b border-line/50 pb-4">
          <div className="flex items-center gap-3">
            {thread.authorTeamName ? (
              <Crest name={thread.authorTeamName} size={36} />
            ) : (
              <div className="flex h-9 w-9 items-center justify-center rounded-full bg-brand/10 text-brand text-sm font-black">
                ⚽
              </div>
            )}
            <div>
              <div className="flex items-center gap-2">
                <span className="font-black text-sm text-ink">{thread.authorName}</span>
                {thread.authorTeamName && (
                  <span className="rounded-md bg-wash px-2 py-0.5 text-[11px] font-bold text-muted border border-line/60">
                    {thread.authorTeamName}
                  </span>
                )}
              </div>
              <span className="text-[11px] text-muted">{formatDate(thread.createdAt)}</span>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <span className="rounded-full bg-brand/10 px-3 py-1 text-xs font-black uppercase tracking-wider text-brand">
              {tagLabel}
            </span>
          </div>
        </div>

        {/* Title and Full Content */}
        <div className="space-y-3 py-2">
          <h1 className="text-xl sm:text-2xl font-black text-ink leading-snug">
            {thread.title}
          </h1>
          <div className="text-sm sm:text-base text-ink/90 leading-relaxed whitespace-pre-line">
            {thread.content}
          </div>
        </div>

        {/* Action Bar */}
        <div className="flex flex-wrap items-center justify-between gap-3 border-t border-line/50 pt-4 text-xs">
          <div className="flex items-center gap-2">
            {/* Like */}
            <button
              onClick={handleThreadLike}
              className={`inline-flex items-center gap-1.5 rounded-xl px-4 py-2 text-xs font-bold transition-all cursor-pointer ${
                hasLiked
                  ? "bg-rose-500/10 text-rose-600 border border-rose-500/30"
                  : "border border-line bg-wash/60 text-ink hover:bg-wash hover:border-ink/40"
              }`}
            >
              <span className="text-sm">{hasLiked ? "❤️" : "🤍"}</span>
              <span className="nums font-black">{likes}</span>
              <span className="hidden sm:inline font-medium">{t.kijiweni.likesCount}</span>
            </button>

            {/* Comment Count Anchor */}
            <a
              href="#comments"
              className="inline-flex items-center gap-1.5 rounded-xl border border-line bg-wash/60 px-4 py-2 text-xs font-bold text-ink hover:bg-wash hover:border-ink/40 transition-all"
            >
              <span className="text-sm">💬</span>
              <span className="nums font-black">{thread.commentsCount}</span>
              <span className="hidden sm:inline font-medium">{t.kijiweni.commentsCount}</span>
            </a>
          </div>

          {/* Social Share */}
          <div className="flex items-center gap-2">
            <button
              onClick={handleWhatsApp}
              className="inline-flex items-center gap-1.5 rounded-xl bg-emerald-500/10 text-emerald-700 hover:bg-emerald-500/20 px-3.5 py-2 text-xs font-bold border border-emerald-500/20 transition-all cursor-pointer"
            >
              <span>📲</span>
              <span>{t.kijiweni.shareWhatsapp}</span>
            </button>
            <button
              onClick={handleShare}
              className="inline-flex items-center gap-1.5 rounded-xl border border-line bg-wash/60 hover:bg-wash px-3.5 py-2 text-xs font-bold text-ink transition-all cursor-pointer"
            >
              <span>🔗</span>
              <span>{copied ? t.kijiweni.copiedLink : t.kijiweni.shareThread}</span>
            </button>
          </div>
        </div>
      </div>

      {/* Discussion / Comments Stream */}
      <div id="comments" className="space-y-4 pt-2">
        <div className="flex items-center justify-between px-1">
          <h2 className="text-base font-black text-ink flex items-center gap-2">
            <span>💬</span>
            <span>{t.kijiweni.commentsTitle}</span>
            <span className="rounded-full bg-wash px-2 py-0.5 text-xs text-muted border border-line">
              {thread.comments.length}
            </span>
          </h2>

          {/* Fan Handle indicator */}
          <button
            onClick={() => setProfileModalOpen(true)}
            className="flex items-center gap-1.5 text-xs font-bold text-brand hover:underline cursor-pointer"
          >
            <Crest name={profile.team || "Simba SC"} size={18} />
            <span>{profile.name || t.kijiweni.changeProfile}</span>
          </button>
        </div>

        {/* Comment Box */}
        <form
          onSubmit={handleCommentSubmit}
          className="rounded-2xl border border-line bg-paper p-4 shadow-2xs space-y-3"
        >
          <div className="flex items-center gap-2 text-xs font-bold text-muted pb-1">
            <span>Unaandika kama:</span>
            <span className="text-ink font-black">{profile.name || "Shabiki mgeni"}</span>
            <span className="text-muted/60">({profile.team || "Simba SC"})</span>
          </div>

          <textarea
            rows={3}
            required
            value={commentText}
            onChange={(e) => setCommentText(e.target.value)}
            placeholder={t.kijiweni.commentPlaceholder}
            className="w-full rounded-xl border border-line bg-wash/40 p-3 text-sm text-ink placeholder:text-muted/60 focus:border-brand focus:bg-paper focus:outline-none transition-all"
          />

          {commentError && (
            <p className="text-xs text-rose-500 font-semibold">{commentError}</p>
          )}

          <div className="flex items-center justify-between pt-1">
            <span className="text-[11px] text-muted">
              💡 Chombeza kwa heshima ya kijiwe
            </span>
            <button
              type="submit"
              disabled={isSubmittingComment}
              className="rounded-xl bg-brand px-5 py-2 text-xs font-black text-white hover:bg-brand/90 transition-all shadow-sm disabled:opacity-50 cursor-pointer"
            >
              {isSubmittingComment ? "Inatuma..." : t.kijiweni.postComment}
            </button>
          </div>
        </form>

        {/* Comments List */}
        {thread.comments.length === 0 ? (
          <div className="rounded-2xl border border-line bg-wash/30 p-8 text-center space-y-1">
            <p className="text-sm font-bold text-ink">{t.kijiweni.noComments}</p>
            <p className="text-xs text-muted">{t.kijiweni.noCommentsSub}</p>
          </div>
        ) : (
          <div className="space-y-3">
            {thread.comments.map((comment) => (
              <div
                key={comment.id}
                className="rounded-xl border border-line bg-paper p-4 shadow-2xs space-y-2 hover:border-ink/30 transition-all"
              >
                <div className="flex items-center justify-between text-xs">
                  <div className="flex items-center gap-2">
                    {comment.authorTeamName ? (
                      <Crest name={comment.authorTeamName} size={22} />
                    ) : (
                      <span className="flex h-5 w-5 items-center justify-center rounded-full bg-brand/10 text-brand text-[10px] font-black">
                        ⚽
                      </span>
                    )}
                    <span className="font-black text-ink">{comment.authorName}</span>
                    {comment.authorTeamName && (
                      <span className="text-[11px] font-medium text-muted">
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
