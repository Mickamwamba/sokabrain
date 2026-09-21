import Link from 'next/link';
import {
  ExternalLink,
  Eye,
  EyeOff,
  Heart,
  MessageCircle,
  MessageSquare,
  MessagesSquare,
  Pin,
  PinOff,
  Trash2,
  Users,
} from 'lucide-react';
import {
  adminFetch,
  type AdminKijiweniStats,
  type AdminKijiweniThreadList,
} from '@/lib/adminApi';
import { load, one } from '@/lib/admin-page';
import {
  Badge,
  EmptyState,
  ErrorState,
  FilterTabs,
  PageHeader,
  Pagination,
  Panel,
  SearchBar,
  StatCard,
} from '@/components/admin/kit';
import { ConfirmForm } from '@/components/admin/confirm-form';
import { btn, td, th } from '@/components/admin/styles';
import {
  deleteThreadAction,
  toggleHideThreadAction,
  togglePinThreadAction,
} from './actions';

export const dynamic = 'force-dynamic';

export default async function AdminKijiweniPage(props: PageProps<'/admin/kijiweni'>) {
  const sp = await props.searchParams;
  const page = Math.max(1, Number(one(sp.page)) || 1);
  const spaceSlug = one(sp.space) ?? 'ALL';
  const tag = one(sp.tag) ?? 'ALL';
  const q = one(sp.q) ?? '';
  const visibility = one(sp.visibility) ?? 'ALL';

  const queryParams = new URLSearchParams({
    page: String(page),
    pageSize: '25',
  });
  if (spaceSlug !== 'ALL') queryParams.set('spaceSlug', spaceSlug);
  if (tag !== 'ALL') queryParams.set('tag', tag);
  if (visibility !== 'ALL') queryParams.set('visibility', visibility);
  if (q.trim()) queryParams.set('q', q.trim());

  const res = await load(() =>
    Promise.all([
      adminFetch<AdminKijiweniStats>('/api/admin/kijiweni/stats'),
      adminFetch<AdminKijiweniThreadList>(`/api/admin/kijiweni/threads?${queryParams}`),
    ]),
  );

  if (!res.ok) return <ErrorState message={res.error} />;
  const [stats, threadList] = res.data;

  const hrefForSpace = (slug: string) => {
    const u = new URLSearchParams(queryParams);
    if (slug === 'ALL') u.delete('spaceSlug');
    else u.set('spaceSlug', slug);
    u.set('page', '1');
    return `/admin/kijiweni?${u.toString()}`;
  };

  const spaceItems = [
    {
      href: hrefForSpace('ALL'),
      label: 'All Spaces',
      active: spaceSlug === 'ALL',
      count: stats.totalThreads,
    },
    ...stats.spaces.map((s) => ({
      href: hrefForSpace(s.slug),
      label: s.nameSw,
      active: spaceSlug === s.slug,
      count: s.threadsCount,
    })),
  ];

  const hrefForVisibility = (vis: string) => {
    const u = new URLSearchParams(queryParams);
    if (vis === 'ALL') u.delete('visibility');
    else u.set('visibility', vis);
    u.set('page', '1');
    return `/admin/kijiweni?${u.toString()}`;
  };

  const visibilityItems = [
    { href: hrefForVisibility('ALL'), label: 'All Topics', active: visibility === 'ALL' },
    { href: hrefForVisibility('VISIBLE'), label: 'Public & Visible', active: visibility === 'VISIBLE' },
    { href: hrefForVisibility('HIDDEN'), label: 'Hidden / Moderated', active: visibility === 'HIDDEN', count: stats.hiddenThreads },
  ];

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<MessagesSquare />}
        title="Fan Zone (Kijiweni) Moderation"
        description="Hide inappropriate topics and comments, pin discussions, or permanently remove violating content."
        actions={
          <Link href="/kijiweni" target="_blank" className={btn('secondary')}>
            <ExternalLink /> View Fan Zone
          </Link>
        }
      />

      {/* Metrics Row */}
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <StatCard
          label="Total Discussions"
          value={stats.totalThreads}
          icon={<MessagesSquare />}
          tone="blue"
          hint={`${stats.pinnedThreads} pinned · ${stats.hiddenThreads} hidden`}
        />
        <StatCard
          label="Fan Replies"
          value={stats.totalComments}
          icon={<MessageCircle />}
          tone="green"
        />
        <StatCard
          label="Fan Likes"
          value={stats.totalLikes}
          icon={<Heart />}
          tone="amber"
        />
        <StatCard
          label="Active Vijiwe"
          value={stats.totalSpaces}
          icon={<Users />}
          tone="gray"
          hint="Community Corner Spaces"
        />
      </div>

      {/* Filter Tabs by Space and Visibility */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <FilterTabs items={spaceItems} />
        <FilterTabs items={visibilityItems} />
      </div>

      {/* Threads Table Panel */}
      <Panel
        title={`${threadList.total} Topic${threadList.total === 1 ? '' : 's'}`}
        actions={
          <SearchBar
            action="/admin/kijiweni"
            q={q}
            placeholder="Search topics, content, or fan handle…"
            keep={{
              space: spaceSlug === 'ALL' ? '' : spaceSlug,
              visibility: visibility === 'ALL' ? '' : visibility,
            }}
          />
        }
      >
        {threadList.threads.length === 0 ? (
          <EmptyState
            icon={<MessagesSquare />}
            title={q ? `Nothing matches "${q}"` : 'No topics found'}
          >
            {q
              ? 'Try a different search query or reset your space/visibility filter.'
              : 'Fans will start discussions in the public Kijiweni spaces.'}
          </EmptyState>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[780px] text-sm">
              <thead className="border-b border-line bg-wash/60">
                <tr>
                  <th className={th}>Topic & Content</th>
                  <th className={th}>Space</th>
                  <th className={th}>Author</th>
                  <th className={`${th} text-right`}>Engagement</th>
                  <th className={th}>Status</th>
                  <th className={`${th} text-right`}>Moderation Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-line">
                {threadList.threads.map((t) => (
                  <tr key={t.id} className={`hover:bg-wash/60 ${t.isHidden ? 'bg-loss/5' : ''}`}>
                    <td className={td}>
                      <div className="flex items-start gap-2 max-w-md">
                        <div>
                          <div className="flex items-center gap-1.5 flex-wrap">
                            <Link
                              href={`/admin/kijiweni/${t.id}`}
                              className="font-semibold text-ink hover:text-brand transition-colors line-clamp-1"
                            >
                              {t.title}
                            </Link>
                          </div>
                          <p className="mt-0.5 line-clamp-1 text-xs text-muted">
                            {t.content}
                          </p>
                        </div>
                      </div>
                    </td>
                    <td className={td}>
                      <span
                        className="inline-flex items-center gap-1.5 rounded-md px-2 py-0.5 text-xs font-semibold"
                        style={{
                          backgroundColor: `${t.space.badgeColor}15`,
                          color: t.space.badgeColor,
                        }}
                      >
                        {t.space.nameSw}
                      </span>
                    </td>
                    <td className={td}>
                      <div className="text-xs">
                        <span className="font-semibold text-ink">{t.authorName}</span>
                        {t.authorTeamName && (
                          <span className="block text-muted">{t.authorTeamName}</span>
                        )}
                      </div>
                    </td>
                    <td className={`${td} text-right`}>
                      <div className="inline-flex items-center gap-3 text-xs text-muted nums">
                        <Link
                          href={`/admin/kijiweni/${t.id}`}
                          className="inline-flex items-center gap-1 hover:text-brand font-medium"
                          title="Moderate comments"
                        >
                          <MessageCircle className="h-3.5 w-3.5" /> {t.commentsCount}
                        </Link>
                        <span className="inline-flex items-center gap-1">
                          <Heart className="h-3.5 w-3.5 text-loss" /> {t.likesCount}
                        </span>
                      </div>
                    </td>
                    <td className={td}>
                      <div className="flex flex-wrap items-center gap-1">
                        {t.isHidden ? (
                          <Badge tone="red" dot>
                            Hidden
                          </Badge>
                        ) : (
                          <Badge tone="green" dot>
                            Visible
                          </Badge>
                        )}
                        {t.isPinned && (
                          <span className="inline-flex items-center gap-0.5 rounded bg-amber-500/10 px-1.5 py-0.5 text-[10px] font-bold text-amber-600">
                            <Pin className="h-2.5 w-2.5" /> Pinned
                          </span>
                        )}
                      </div>
                    </td>
                    <td className={`${td} text-right`}>
                      <div className="inline-flex items-center justify-end gap-1.5">
                        {/* Inspect comments */}
                        <Link
                          href={`/admin/kijiweni/${t.id}`}
                          className={btn('secondary', 'sm')}
                          title="Moderate comments"
                        >
                          <MessageSquare className="h-3.5 w-3.5" /> Comments ({t.commentsCount})
                        </Link>

                        {/* Hide / Unhide Form */}
                        <ConfirmForm
                          action={toggleHideThreadAction}
                          title={t.isHidden ? `Unhide topic "${t.title}"?` : `Hide topic "${t.title}" from public?`}
                          description={
                            t.isHidden
                              ? 'This topic will be restored and visible to all fans on the public site.'
                              : 'This topic will immediately be hidden from all public fans. Only admins can see it.'
                          }
                          confirmLabel={t.isHidden ? 'Unhide topic' : 'Hide topic'}
                          tone={t.isHidden ? 'primary' : 'danger'}
                          trigger={
                            t.isHidden ? (
                              <Eye className="h-3.5 w-3.5 text-brand" />
                            ) : (
                              <EyeOff className="h-3.5 w-3.5 text-muted hover:text-loss" />
                            )
                          }
                          triggerClassName={btn('ghost', 'sm')}
                          triggerAriaLabel={t.isHidden ? 'Unhide topic' : 'Hide topic'}
                        >
                          <input type="hidden" name="threadId" value={t.id} />
                          <input type="hidden" name="isHidden" value={t.isHidden ? 'false' : 'true'} />
                        </ConfirmForm>

                        {/* Pin / Unpin Form */}
                        <ConfirmForm
                          action={togglePinThreadAction}
                          title={t.isPinned ? `Unpin topic "${t.title}"?` : `Pin "${t.title}" to top?`}
                          description={
                            t.isPinned
                              ? 'This topic will return to regular chronological sorting.'
                              : 'This topic will be pinned to the top of its Kijiwe space.'
                          }
                          confirmLabel={t.isPinned ? 'Unpin' : 'Pin to top'}
                          trigger={
                            t.isPinned ? (
                              <PinOff className="h-3.5 w-3.5 text-amber-600" />
                            ) : (
                              <Pin className="h-3.5 w-3.5 text-muted hover:text-ink" />
                            )
                          }
                          triggerClassName={btn('ghost', 'sm')}
                          triggerAriaLabel={t.isPinned ? 'Unpin topic' : 'Pin topic'}
                        >
                          <input type="hidden" name="threadId" value={t.id} />
                          <input
                            type="hidden"
                            name="isPinned"
                            value={t.isPinned ? 'false' : 'true'}
                          />
                        </ConfirmForm>

                        {/* Public Link */}
                        <Link
                          href={`/kijiweni?thread=${t.id}`}
                          target="_blank"
                          title="Open public discussion"
                          className={btn('ghost', 'sm')}
                        >
                          <ExternalLink className="h-3.5 w-3.5" />
                        </Link>

                        {/* Delete Form with confirmation dialog */}
                        <ConfirmForm
                          action={deleteThreadAction}
                          title={`Permanently delete topic "${t.title}"?`}
                          description="This will permanently delete this discussion topic and all fan replies from the database. This action cannot be undone."
                          confirmLabel="Delete permanently"
                          tone="danger"
                          trigger={<Trash2 className="h-3.5 w-3.5 text-loss" />}
                          triggerClassName={btn('ghost', 'sm')}
                          triggerAriaLabel="Delete topic"
                        >
                          <input type="hidden" name="threadId" value={t.id} />
                        </ConfirmForm>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        <Pagination
          page={threadList.page}
          pageSize={threadList.pageSize}
          total={threadList.total}
          href={(p) => {
            const u = new URLSearchParams(queryParams);
            u.set('page', String(p));
            return `/admin/kijiweni?${u.toString()}`;
          }}
        />
      </Panel>
    </div>
  );
}
