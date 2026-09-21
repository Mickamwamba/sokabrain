import { Router, type Request, type Response } from 'express';
import { z } from 'zod';
import { prisma } from '../db.js';

export const adminKijiweniRouter = Router();

const idParam = z.object({ id: z.coerce.number().int().positive() });

// GET /api/admin/kijiweni/stats - Community high-level metrics
adminKijiweniRouter.get('/stats', async (_req: Request, res: Response) => {
  try {
    const [totalSpaces, totalThreads, totalComments, totalLikes, pinnedThreads, hiddenThreads, spaces, recentThreads] =
      await Promise.all([
        prisma.kijiwe_spaces.count(),
        prisma.kijiwe_threads.count(),
        prisma.kijiwe_comments.count(),
        prisma.kijiwe_likes.count(),
        prisma.kijiwe_threads.count({ where: { is_pinned: true } }),
        prisma.kijiwe_threads.count({ where: { is_hidden: true } }),
        prisma.kijiwe_spaces.findMany({
          orderBy: { display_order: 'asc' },
          include: { _count: { select: { threads: true } } },
        }),
        prisma.kijiwe_threads.findMany({
          orderBy: { created_at: 'desc' },
          take: 6,
          include: {
            kijiwe: {
              select: { name_sw: true, name_en: true, slug: true, badge_color: true },
            },
          },
        }),
      ]);

    res.json({
      totalSpaces,
      totalThreads,
      totalComments,
      totalLikes,
      pinnedThreads,
      hiddenThreads,
      spaces: spaces.map((s) => ({
        id: s.id,
        slug: s.slug,
        nameSw: s.name_sw,
        nameEn: s.name_en,
        icon: s.icon,
        badgeColor: s.badge_color,
        threadsCount: s._count.threads,
      })),
      recentThreads: recentThreads.map((t) => ({
        id: t.id,
        title: t.title,
        authorName: t.author_name,
        authorTeamName: t.author_team_name,
        tag: t.tag,
        isPinned: t.is_pinned,
        isHidden: t.is_hidden,
        likesCount: t.likes_count,
        commentsCount: t.comments_count,
        createdAt: t.created_at.toISOString(),
        space: {
          slug: t.kijiwe.slug,
          nameSw: t.kijiwe.name_sw,
          nameEn: t.kijiwe.name_en,
          badgeColor: t.kijiwe.badge_color,
        },
      })),
    });
  } catch (err) {
    console.error('Failed to load admin kijiweni stats:', err);
    res.status(500).json({ error: 'Failed to load stats' });
  }
});

// GET /api/admin/kijiweni/threads - Paged list with search and filters
const listQuery = z.object({
  page: z.coerce.number().int().min(1).default(1),
  pageSize: z.coerce.number().int().min(1).max(100).default(30),
  spaceSlug: z.string().optional(),
  tag: z.string().optional(),
  q: z.string().optional(),
  visibility: z.enum(['ALL', 'VISIBLE', 'HIDDEN']).default('ALL'),
});

adminKijiweniRouter.get('/threads', async (req: Request, res: Response) => {
  const parsed = listQuery.safeParse(req.query);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid query parameters' });
    return;
  }

  const { page, pageSize, spaceSlug, tag, q, visibility } = parsed.data;

  try {
    const where: Record<string, unknown> = {};

    if (visibility === 'VISIBLE') where.is_hidden = false;
    else if (visibility === 'HIDDEN') where.is_hidden = true;

    if (spaceSlug && spaceSlug !== 'ALL') {
      const space = await prisma.kijiwe_spaces.findUnique({ where: { slug: spaceSlug } });
      if (space) where.kijiwe_id = space.id;
    }

    if (tag && tag !== 'ALL') {
      where.tag = tag.toUpperCase();
    }

    if (q && q.trim()) {
      const query = q.trim();
      where.OR = [
        { title: { contains: query, mode: 'insensitive' } },
        { content: { contains: query, mode: 'insensitive' } },
        { author_name: { contains: query, mode: 'insensitive' } },
        { author_team_name: { contains: query, mode: 'insensitive' } },
      ];
    }

    const [total, threads] = await Promise.all([
      prisma.kijiwe_threads.count({ where }),
      prisma.kijiwe_threads.findMany({
        where,
        orderBy: [{ is_pinned: 'desc' }, { created_at: 'desc' }],
        skip: (page - 1) * pageSize,
        take: pageSize,
        include: {
          kijiwe: {
            select: { name_sw: true, name_en: true, slug: true, badge_color: true },
          },
        },
      }),
    ]);

    res.json({
      total,
      page,
      pageSize,
      threads: threads.map((t) => ({
        id: t.id,
        title: t.title,
        content: t.content,
        authorName: t.author_name,
        authorTeamName: t.author_team_name,
        tag: t.tag,
        isPinned: t.is_pinned,
        isHidden: t.is_hidden,
        likesCount: t.likes_count,
        commentsCount: t.comments_count,
        createdAt: t.created_at.toISOString(),
        space: {
          slug: t.kijiwe.slug,
          nameSw: t.kijiwe.name_sw,
          nameEn: t.kijiwe.name_en,
          badgeColor: t.kijiwe.badge_color,
        },
      })),
    });
  } catch (err) {
    console.error('Failed to list admin kijiweni threads:', err);
    res.status(500).json({ error: 'Failed to list threads' });
  }
});

// GET /api/admin/kijiweni/threads/:id - Detailed thread with all comments for moderation
adminKijiweniRouter.get('/threads/:id', async (req: Request, res: Response) => {
  const p = idParam.safeParse(req.params);
  if (!p.success) {
    res.status(400).json({ error: 'Invalid thread ID' });
    return;
  }

  try {
    const thread = await prisma.kijiwe_threads.findUnique({
      where: { id: p.data.id },
      include: {
        kijiwe: {
          select: { name_sw: true, name_en: true, slug: true, badge_color: true },
        },
        comments: {
          orderBy: { created_at: 'asc' },
        },
      },
    });

    if (!thread) {
      res.status(404).json({ error: 'Thread not found' });
      return;
    }

    res.json({
      thread: {
        id: thread.id,
        title: thread.title,
        content: thread.content,
        authorName: thread.author_name,
        authorTeamName: thread.author_team_name,
        tag: thread.tag,
        isPinned: thread.is_pinned,
        isHidden: thread.is_hidden,
        likesCount: thread.likes_count,
        commentsCount: thread.comments_count,
        createdAt: thread.created_at.toISOString(),
        space: {
          slug: thread.kijiwe.slug,
          nameSw: thread.kijiwe.name_sw,
          nameEn: thread.kijiwe.name_en,
          badgeColor: thread.kijiwe.badge_color,
        },
        comments: thread.comments.map((c) => ({
          id: c.id,
          authorName: c.author_name,
          authorTeamName: c.author_team_name,
          content: c.content,
          likesCount: c.likes_count,
          isHidden: c.is_hidden,
          createdAt: c.created_at.toISOString(),
        })),
      },
    });
  } catch (err) {
    console.error('Failed to get thread for moderation:', err);
    res.status(500).json({ error: 'Failed to get thread' });
  }
});

// PATCH /api/admin/kijiweni/threads/:id - Update thread (pin/unpin, hide/unhide, tag)
const updateThreadSchema = z.object({
  isPinned: z.boolean().optional(),
  isHidden: z.boolean().optional(),
  tag: z.string().max(30).optional(),
});

adminKijiweniRouter.patch('/threads/:id', async (req: Request, res: Response) => {
  const p = idParam.safeParse(req.params);
  if (!p.success) {
    res.status(400).json({ error: 'Invalid thread ID' });
    return;
  }

  const parsed = updateThreadSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid request body' });
    return;
  }

  try {
    const thread = await prisma.kijiwe_threads.update({
      where: { id: p.data.id },
      data: {
        ...(parsed.data.isPinned !== undefined && { is_pinned: parsed.data.isPinned }),
        ...(parsed.data.isHidden !== undefined && { is_hidden: parsed.data.isHidden }),
        ...(parsed.data.tag !== undefined && { tag: parsed.data.tag.toUpperCase() }),
      },
    });

    res.json({
      ok: true,
      isPinned: thread.is_pinned,
      isHidden: thread.is_hidden,
      tag: thread.tag,
    });
  } catch (err) {
    console.error('Failed to update thread:', err);
    res.status(500).json({ error: 'Failed to update thread' });
  }
});

// PATCH /api/admin/kijiweni/comments/:id - Hide/unhide comment
const updateCommentSchema = z.object({
  isHidden: z.boolean().optional(),
});

adminKijiweniRouter.patch('/comments/:id', async (req: Request, res: Response) => {
  const p = idParam.safeParse(req.params);
  if (!p.success) {
    res.status(400).json({ error: 'Invalid comment ID' });
    return;
  }

  const parsed = updateCommentSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid request body' });
    return;
  }

  try {
    const comment = await prisma.kijiwe_comments.update({
      where: { id: p.data.id },
      data: {
        ...(parsed.data.isHidden !== undefined && { is_hidden: parsed.data.isHidden }),
      },
    });

    res.json({ ok: true, isHidden: comment.is_hidden });
  } catch (err) {
    console.error('Failed to update comment:', err);
    res.status(500).json({ error: 'Failed to update comment' });
  }
});

// DELETE /api/admin/kijiweni/threads/:id - Delete thread and cascade
adminKijiweniRouter.delete('/threads/:id', async (req: Request, res: Response) => {
  const p = idParam.safeParse(req.params);
  if (!p.success) {
    res.status(400).json({ error: 'Invalid thread ID' });
    return;
  }

  try {
    await prisma.kijiwe_threads.delete({
      where: { id: p.data.id },
    });
    res.json({ ok: true });
  } catch (err) {
    console.error('Failed to delete thread:', err);
    res.status(500).json({ error: 'Failed to delete thread' });
  }
});

// DELETE /api/admin/kijiweni/comments/:id - Delete comment
adminKijiweniRouter.delete('/comments/:id', async (req: Request, res: Response) => {
  const p = idParam.safeParse(req.params);
  if (!p.success) {
    res.status(400).json({ error: 'Invalid comment ID' });
    return;
  }

  try {
    const comment = await prisma.kijiwe_comments.findUnique({
      where: { id: p.data.id },
      select: { thread_id: true },
    });

    if (!comment) {
      res.status(404).json({ error: 'Comment not found' });
      return;
    }

    await prisma.$transaction([
      prisma.kijiwe_comments.delete({ where: { id: p.data.id } }),
      prisma.kijiwe_threads.update({
        where: { id: comment.thread_id },
        data: { comments_count: { decrement: 1 } },
      }),
    ]);

    res.json({ ok: true });
  } catch (err) {
    console.error('Failed to delete comment:', err);
    res.status(500).json({ error: 'Failed to delete comment' });
  }
});
