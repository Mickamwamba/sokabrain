import Link from 'next/link';
import {
  ExternalLink,
  Eye,
  EyeOff,
  Heart,
  MessageCircle,
  MessagesSquare,
  Pin,
  Trash2,
} from 'lucide-react';
import {
  adminFetch,
  type AdminKijiweThreadDetail,
} from '@/lib/adminApi';
import { load } from '@/lib/admin-page';
import {
  Badge,
  EmptyState,
  ErrorState,
  PageHeader,
  Panel,
  fmtDateTime,
} from '@/components/admin/kit';
import { ConfirmForm } from '@/components/admin/confirm-form';
import { btn } from '@/components/admin/styles';
import {
  deleteCommentAction,
  deleteThreadAction,
  toggleHideCommentAction,
  toggleHideThreadAction,
} from '../actions';

export const dynamic = 'force-dynamic';

export default async function AdminKijiweThreadDetailPage(
  props: PageProps<'/admin/kijiweni/[id]'>,
) {
  const { id: rawId } = await props.params;
  const threadId = parseInt(rawId, 10);
  if (isNaN(threadId)) return <ErrorState message="Invalid thread ID" />;

  const res = await load(() =>
    adminFetch<{ thread: AdminKijiweThreadDetail }>(
      `/api/admin/kijiweni/threads/${threadId}`,
    ).then((r) => r.thread),
  );

  if (!res.ok) return <ErrorState message={res.error} />;
  const thread = res.data;

  return (
    <div className="space-y-6">
      <PageHeader
        back={{ href: '/admin/kijiweni', label: 'Back to Fan Zone' }}
        icon={<MessagesSquare />}
        title="Topic & Comment Moderation"
        description={`Moderating "${thread.title}" in ${thread.space.nameSw}`}
        actions={
          <div className="flex flex-wrap items-center gap-2">
            <Link
              href={`/kijiweni?thread=${thread.id}`}
              target="_blank"
              className={btn('secondary')}
            >
              <ExternalLink /> View on Public Site
            </Link>

            {/* Hide / Unhide Topic */}
            <ConfirmForm
              action={toggleHideThreadAction}
              title={
                thread.isHidden
                  ? `Unhide topic "${thread.title}"?`
                  : `Hide topic "${thread.title}" from public?`
              }
              description={
                thread.isHidden
                  ? 'This topic will immediately become visible to all fans on the public site.'
                  : 'This topic will be hidden from public fans. Only admins will be able to see it.'
              }
              confirmLabel={thread.isHidden ? 'Unhide topic' : 'Hide topic'}
              tone={thread.isHidden ? 'primary' : 'danger'}
              trigger={
                thread.isHidden ? (
                  <>
                    <Eye /> Unhide Topic
                  </>
                ) : (
                  <>
                    <EyeOff /> Hide Topic
                  </>
                )
              }
              triggerClassName={btn('secondary')}
            >
              <input type="hidden" name="threadId" value={thread.id} />
              <input
                type="hidden"
                name="isHidden"
                value={thread.isHidden ? 'false' : 'true'}
              />
            </ConfirmForm>

            {/* Delete Topic */}
            <ConfirmForm
              action={deleteThreadAction}
              title={`Permanently delete topic "${thread.title}"?`}
              description="This will permanently delete this entire discussion topic and all fan replies from the database. This action cannot be undone."
              confirmLabel="Delete permanently"
              tone="danger"
              trigger={
                <>
                  <Trash2 /> Delete Topic
                </>
              }
              triggerClassName={btn('danger')}
            >
              <input type="hidden" name="threadId" value={thread.id} />
            </ConfirmForm>
          </div>
        }
      />

      {/* Topic Card */}
      <Panel
        title={
          <div className="flex items-center gap-2 flex-wrap">
            <span
              className="inline-flex items-center gap-1.5 rounded-md px-2 py-0.5 text-xs font-semibold"
              style={{
                backgroundColor: `${thread.space.badgeColor}15`,
                color: thread.space.badgeColor,
              }}
            >
              {thread.space.nameSw}
            </span>
            <span className="text-base font-bold text-ink">{thread.title}</span>
            {thread.isHidden ? (
              <Badge tone="red" dot>
                Hidden
              </Badge>
            ) : (
              <Badge tone="green" dot>
                Visible
              </Badge>
            )}
            {thread.isPinned && (
              <span className="inline-flex items-center gap-0.5 rounded bg-amber-500/10 px-1.5 py-0.5 text-[10px] font-bold text-amber-600">
                <Pin className="h-2.5 w-2.5" /> Pinned
              </span>
            )}
          </div>
        }
        description={`Posted by ${thread.authorName}${thread.authorTeamName ? ` (${thread.authorTeamName})` : ''} on ${fmtDateTime(thread.createdAt)}`}
      >
        <div className="p-5 text-sm text-ink whitespace-pre-wrap leading-relaxed border-b border-line">
          {thread.content}
        </div>
        <div className="flex items-center justify-between px-5 py-3 bg-wash/40 text-xs text-muted">
          <div className="flex items-center gap-4">
            <span className="inline-flex items-center gap-1 font-semibold text-ink">
              <MessageCircle className="h-4 w-4" /> {thread.commentsCount} Comments
            </span>
            <span className="inline-flex items-center gap-1 font-semibold text-ink">
              <Heart className="h-4 w-4 text-loss" /> {thread.likesCount} Likes
            </span>
          </div>
          <span>Tag: {thread.tag}</span>
        </div>
      </Panel>

      {/* Comments List Panel */}
      <Panel
        title={`Comments & Replies (${thread.comments.length})`}
        description="Review, hide, or permanently delete inappropriate fan comments on this topic"
      >
        {thread.comments.length === 0 ? (
          <EmptyState
            icon={<MessageCircle />}
            title="No comments on this topic yet"
          >
            Fans have not posted any replies to this discussion.
          </EmptyState>
        ) : (
          <div className="divide-y divide-line">
            {thread.comments.map((comment) => (
              <div
                key={comment.id}
                className={`p-5 transition-colors ${comment.isHidden ? 'bg-loss/5' : 'hover:bg-wash/40'}`}
              >
                <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-2 text-xs">
                      <span className="font-bold text-ink">{comment.authorName}</span>
                      {comment.authorTeamName && (
                        <span className="rounded bg-wash px-1.5 py-0.5 text-[10px] font-semibold text-muted">
                          {comment.authorTeamName}
                        </span>
                      )}
                      <span className="text-muted">· {fmtDateTime(comment.createdAt)}</span>
                      {comment.isHidden ? (
                        <Badge tone="red" dot>
                          Hidden from fans
                        </Badge>
                      ) : (
                        <Badge tone="green" dot>
                          Visible
                        </Badge>
                      )}
                    </div>

                    <p className="mt-2 text-sm text-ink whitespace-pre-wrap leading-relaxed">
                      {comment.content}
                    </p>

                    <div className="mt-2 flex items-center gap-1 text-xs text-muted">
                      <Heart className="h-3 w-3 text-loss" />
                      <span className="nums font-medium">{comment.likesCount} likes</span>
                    </div>
                  </div>

                  {/* Comment Moderation Actions */}
                  <div className="flex items-center gap-2 shrink-0">
                    {/* Hide / Unhide Comment */}
                    <ConfirmForm
                      action={toggleHideCommentAction}
                      title={
                        comment.isHidden
                          ? 'Unhide comment?'
                          : 'Hide comment from public?'
                      }
                      description={
                        comment.isHidden
                          ? 'This comment will be restored and visible to all fans on the public site.'
                          : 'This comment will immediately be hidden from the public fan zone. Only admins can see it.'
                      }
                      confirmLabel={comment.isHidden ? 'Unhide comment' : 'Hide comment'}
                      tone={comment.isHidden ? 'primary' : 'danger'}
                      trigger={
                        comment.isHidden ? (
                          <>
                            <Eye className="h-3.5 w-3.5 text-brand" /> Unhide
                          </>
                        ) : (
                          <>
                            <EyeOff className="h-3.5 w-3.5 text-muted" /> Hide
                          </>
                        )
                      }
                      triggerClassName={btn('secondary', 'sm')}
                      triggerAriaLabel={comment.isHidden ? 'Unhide comment' : 'Hide comment'}
                    >
                      <input type="hidden" name="commentId" value={comment.id} />
                      <input type="hidden" name="threadId" value={thread.id} />
                      <input
                        type="hidden"
                        name="isHidden"
                        value={comment.isHidden ? 'false' : 'true'}
                      />
                    </ConfirmForm>

                    {/* Delete Comment */}
                    <ConfirmForm
                      action={deleteCommentAction}
                      title="Permanently delete comment?"
                      description="This will permanently delete this fan comment from the database. This action cannot be undone."
                      confirmLabel="Delete permanently"
                      tone="danger"
                      trigger={
                        <>
                          <Trash2 className="h-3.5 w-3.5 text-loss" /> Delete
                        </>
                      }
                      triggerClassName={btn('ghost', 'sm')}
                      triggerAriaLabel="Delete comment"
                    >
                      <input type="hidden" name="commentId" value={comment.id} />
                      <input type="hidden" name="threadId" value={thread.id} />
                    </ConfirmForm>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </Panel>
    </div>
  );
}
