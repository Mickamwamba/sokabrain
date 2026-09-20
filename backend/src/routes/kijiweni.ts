import { Router, type Request, type Response } from 'express';
import { z } from 'zod';
import { prisma } from '../db.js';

export const kijiweniRouter = Router();

// GET /api/kijiweni/spaces - List all active Vijiwe
kijiweniRouter.get('/spaces', async (_req: Request, res: Response) => {
  try {
    const spaces = await prisma.kijiwe_spaces.findMany({
      orderBy: { display_order: 'asc' },
      include: {
        _count: {
          select: { threads: true },
        },
      },
    });

    res.json({
      spaces: spaces.map((s) => ({
        id: s.id,
        slug: s.slug,
        nameSw: s.name_sw,
        nameEn: s.name_en,
        descriptionSw: s.description_sw,
        descriptionEn: s.description_en,
        icon: s.icon,
        badgeColor: s.badge_color,
        threadsCount: s._count.threads,
      })),
    });
  } catch (err) {
    console.error('Failed to fetch kijiweni spaces:', err);
    res.status(500).json({ error: 'Failed to fetch spaces' });
  }
});

// GET /api/kijiweni/threads - List threads with filters
kijiweniRouter.get('/threads', async (req: Request, res: Response) => {
  try {
    const spaceSlug = typeof req.query.spaceSlug === 'string' ? req.query.spaceSlug : undefined;
    const tag = typeof req.query.tag === 'string' && req.query.tag !== 'ALL' ? req.query.tag.toUpperCase() : undefined;
    const sort = req.query.sort === 'popular' ? 'popular' : 'latest';

    const where: Record<string, unknown> = {};
    if (spaceSlug) {
      const space = await prisma.kijiwe_spaces.findUnique({ where: { slug: spaceSlug } });
      if (!space) {
        res.status(404).json({ error: 'Kijiwe space not found' });
        return;
      }
      where.kijiwe_id = space.id;
    }
    if (tag) {
      where.tag = tag;
    }

    const orderBy =
      sort === 'popular'
        ? [{ is_pinned: 'desc' as const }, { likes_count: 'desc' as const }, { created_at: 'desc' as const }]
        : [{ is_pinned: 'desc' as const }, { created_at: 'desc' as const }];

    const threads = await prisma.kijiwe_threads.findMany({
      where,
      orderBy,
      take: 50,
      include: {
        kijiwe: {
          select: {
            slug: true,
            name_sw: true,
            name_en: true,
            icon: true,
            badge_color: true,
          },
        },
      },
    });

    res.json({
      threads: threads.map((t) => ({
        id: t.id,
        title: t.title,
        content: t.content,
        authorName: t.author_name,
        authorTeamName: t.author_team_name,
        tag: t.tag,
        likesCount: t.likes_count,
        commentsCount: t.comments_count,
        isPinned: t.is_pinned,
        createdAt: t.created_at.toISOString(),
        kijiwe: {
          slug: t.kijiwe.slug,
          nameSw: t.kijiwe.name_sw,
          nameEn: t.kijiwe.name_en,
          icon: t.kijiwe.icon,
          badgeColor: t.kijiwe.badge_color,
        },
      })),
    });
  } catch (err) {
    console.error('Failed to fetch threads:', err);
    res.status(500).json({ error: 'Failed to fetch threads' });
  }
});

// GET /api/kijiweni/threads/:id - Thread details with comments
kijiweniRouter.get('/threads/:id', async (req: Request, res: Response) => {
  try {
    const rawId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const threadId = parseInt(rawId ?? '', 10);
    if (isNaN(threadId)) {
      res.status(400).json({ error: 'Invalid thread ID' });
      return;
    }

    const thread = await prisma.kijiwe_threads.findUnique({
      where: { id: threadId },
      include: {
        kijiwe: {
          select: {
            slug: true,
            name_sw: true,
            name_en: true,
            icon: true,
            badge_color: true,
          },
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
        likesCount: thread.likes_count,
        commentsCount: thread.comments_count,
        isPinned: thread.is_pinned,
        createdAt: thread.created_at.toISOString(),
        kijiwe: {
          slug: thread.kijiwe.slug,
          nameSw: thread.kijiwe.name_sw,
          nameEn: thread.kijiwe.name_en,
          icon: thread.kijiwe.icon,
          badgeColor: thread.kijiwe.badge_color,
        },
        comments: thread.comments.map((c) => ({
          id: c.id,
          authorName: c.author_name,
          authorTeamName: c.author_team_name,
          content: c.content,
          likesCount: c.likes_count,
          createdAt: c.created_at.toISOString(),
        })),
      },
    });
  } catch (err) {
    console.error('Failed to fetch thread detail:', err);
    res.status(500).json({ error: 'Failed to fetch thread' });
  }
});

const CreateThreadSchema = z.object({
  spaceSlug: z.string().min(1),
  title: z.string().min(3).max(200),
  content: z.string().min(5).max(3000),
  authorName: z.string().min(2).max(50),
  authorTeamName: z.string().max(80).optional(),
  tag: z.enum(['UBISHI', 'CHOMBEZA', 'UTABIRI', 'MBINU']).default('UBISHI'),
});

// POST /api/kijiweni/threads - Start a new thread
kijiweniRouter.post('/threads', async (req: Request, res: Response) => {
  try {
    const parsed = CreateThreadSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid input', details: parsed.error.issues });
      return;
    }

    const { spaceSlug, title, content, authorName, authorTeamName, tag } = parsed.data;

    const space = await prisma.kijiwe_spaces.findUnique({
      where: { slug: spaceSlug },
    });

    if (!space) {
      res.status(404).json({ error: 'Kijiwe space not found' });
      return;
    }

    const thread = await prisma.kijiwe_threads.create({
      data: {
        kijiwe_id: space.id,
        title: title.trim(),
        content: content.trim(),
        author_name: authorName.trim(),
        author_team_name: authorTeamName?.trim() || null,
        tag,
      },
    });

    res.status(201).json({
      thread: {
        id: thread.id,
        title: thread.title,
        slug: space.slug,
      },
    });
  } catch (err) {
    console.error('Failed to create thread:', err);
    res.status(500).json({ error: 'Failed to create thread' });
  }
});

const CreateCommentSchema = z.object({
  authorName: z.string().min(2).max(50),
  authorTeamName: z.string().max(80).optional(),
  content: z.string().min(2).max(2000),
});

// POST /api/kijiweni/threads/:id/comments - Add comment to a thread
kijiweniRouter.post('/threads/:id/comments', async (req: Request, res: Response) => {
  try {
    const rawId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const threadId = parseInt(rawId ?? '', 10);
    if (isNaN(threadId)) {
      res.status(400).json({ error: 'Invalid thread ID' });
      return;
    }

    const parsed = CreateCommentSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid input', details: parsed.error.issues });
      return;
    }

    const { authorName, authorTeamName, content } = parsed.data;

    const [comment] = await prisma.$transaction([
      prisma.kijiwe_comments.create({
        data: {
          thread_id: threadId,
          author_name: authorName.trim(),
          author_team_name: authorTeamName?.trim() || null,
          content: content.trim(),
        },
      }),
      prisma.kijiwe_threads.update({
        where: { id: threadId },
        data: { comments_count: { increment: 1 } },
      }),
    ]);

    res.status(201).json({
      comment: {
        id: comment.id,
        authorName: comment.author_name,
        authorTeamName: comment.author_team_name,
        content: comment.content,
        likesCount: comment.likes_count,
        createdAt: comment.created_at.toISOString(),
      },
    });
  } catch (err) {
    console.error('Failed to add comment:', err);
    res.status(500).json({ error: 'Failed to add comment' });
  }
});

const LikeSchema = z.object({
  fanFingerprint: z.string().min(1).max(100),
  reactionType: z.string().default('LIKE'),
});

// POST /api/kijiweni/threads/:id/like - Toggle like on thread
kijiweniRouter.post('/threads/:id/like', async (req: Request, res: Response) => {
  try {
    const rawId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const threadId = parseInt(rawId ?? '', 10);
    if (isNaN(threadId)) {
      res.status(400).json({ error: 'Invalid thread ID' });
      return;
    }

    const parsed = LikeSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid input' });
      return;
    }

    const { fanFingerprint, reactionType } = parsed.data;

    const existing = await prisma.kijiwe_likes.findUnique({
      where: {
        thread_id_fan_fingerprint: {
          thread_id: threadId,
          fan_fingerprint: fanFingerprint,
        },
      },
    });

    if (existing) {
      // Unlike
      await prisma.$transaction([
        prisma.kijiwe_likes.delete({ where: { id: existing.id } }),
        prisma.kijiwe_threads.update({
          where: { id: threadId },
          data: { likes_count: { decrement: 1 } },
        }),
      ]);

      const updated = await prisma.kijiwe_threads.findUnique({
        where: { id: threadId },
        select: { likes_count: true },
      });

      res.json({ liked: false, likesCount: updated?.likes_count ?? 0 });
    } else {
      // Like
      await prisma.$transaction([
        prisma.kijiwe_likes.create({
          data: {
            thread_id: threadId,
            fan_fingerprint: fanFingerprint,
            reaction_type: reactionType,
          },
        }),
        prisma.kijiwe_threads.update({
          where: { id: threadId },
          data: { likes_count: { increment: 1 } },
        }),
      ]);

      const updated = await prisma.kijiwe_threads.findUnique({
        where: { id: threadId },
        select: { likes_count: true },
      });

      res.json({ liked: true, likesCount: updated?.likes_count ?? 1 });
    }
  } catch (err) {
    console.error('Failed to toggle thread like:', err);
    res.status(500).json({ error: 'Failed to toggle like' });
  }
});

// POST /api/kijiweni/comments/:id/like - Toggle like on comment
kijiweniRouter.post('/comments/:id/like', async (req: Request, res: Response) => {
  try {
    const rawId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const commentId = parseInt(rawId ?? '', 10);
    if (isNaN(commentId)) {
      res.status(400).json({ error: 'Invalid comment ID' });
      return;
    }

    const parsed = LikeSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid input' });
      return;
    }

    const { fanFingerprint, reactionType } = parsed.data;

    const existing = await prisma.kijiwe_likes.findUnique({
      where: {
        comment_id_fan_fingerprint: {
          comment_id: commentId,
          fan_fingerprint: fanFingerprint,
        },
      },
    });

    if (existing) {
      // Unlike
      await prisma.$transaction([
        prisma.kijiwe_likes.delete({ where: { id: existing.id } }),
        prisma.kijiwe_comments.update({
          where: { id: commentId },
          data: { likes_count: { decrement: 1 } },
        }),
      ]);

      const updated = await prisma.kijiwe_comments.findUnique({
        where: { id: commentId },
        select: { likes_count: true },
      });

      res.json({ liked: false, likesCount: updated?.likes_count ?? 0 });
    } else {
      // Like
      await prisma.$transaction([
        prisma.kijiwe_likes.create({
          data: {
            comment_id: commentId,
            fan_fingerprint: fanFingerprint,
            reaction_type: reactionType,
          },
        }),
        prisma.kijiwe_comments.update({
          where: { id: commentId },
          data: { likes_count: { increment: 1 } },
        }),
      ]);

      const updated = await prisma.kijiwe_comments.findUnique({
        where: { id: commentId },
        select: { likes_count: true },
      });

      res.json({ liked: true, likesCount: updated?.likes_count ?? 1 });
    }
  } catch (err) {
    console.error('Failed to toggle comment like:', err);
    res.status(500).json({ error: 'Failed to toggle like' });
  }
});
