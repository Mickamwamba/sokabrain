'use server';

import { revalidatePath } from 'next/cache';
import { adminFetch } from '@/lib/adminApi';
import { fail, id, mutate, type ActionState } from '@/lib/admin-actions';

export async function togglePinThreadAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const threadId = id(fd, 'threadId');
  if (threadId === null) return fail('Invalid thread ID');
  const isPinned = fd.get('isPinned') === 'true';

  const res = await mutate(
    () =>
      adminFetch(`/api/admin/kijiweni/threads/${threadId}`, {
        method: 'PATCH',
        body: { isPinned },
      }),
    isPinned ? 'Topic pinned to the top.' : 'Topic unpinned.',
  );
  revalidatePath('/admin/kijiweni');
  revalidatePath('/admin');
  revalidatePath('/kijiweni');
  return res;
}

export async function toggleHideThreadAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const threadId = id(fd, 'threadId');
  if (threadId === null) return fail('Invalid thread ID');
  const isHidden = fd.get('isHidden') === 'true';

  const res = await mutate(
    () =>
      adminFetch(`/api/admin/kijiweni/threads/${threadId}`, {
        method: 'PATCH',
        body: { isHidden },
      }),
    isHidden ? 'Topic hidden from public fan zone.' : 'Topic restored and visible to public.',
  );
  revalidatePath('/admin/kijiweni');
  revalidatePath(`/admin/kijiweni/${threadId}`);
  revalidatePath('/admin');
  revalidatePath('/kijiweni');
  return res;
}

export async function deleteThreadAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const threadId = id(fd, 'threadId');
  if (threadId === null) return fail('Invalid thread ID');

  const res = await mutate(
    () =>
      adminFetch(`/api/admin/kijiweni/threads/${threadId}`, {
        method: 'DELETE',
      }),
    'Topic and all comments deleted permanently.',
  );
  revalidatePath('/admin/kijiweni');
  revalidatePath('/admin');
  revalidatePath('/kijiweni');
  return res;
}

export async function toggleHideCommentAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const commentId = id(fd, 'commentId');
  const threadId = id(fd, 'threadId');
  if (commentId === null) return fail('Invalid comment ID');
  const isHidden = fd.get('isHidden') === 'true';

  const res = await mutate(
    () =>
      adminFetch(`/api/admin/kijiweni/comments/${commentId}`, {
        method: 'PATCH',
        body: { isHidden },
      }),
    isHidden ? 'Comment hidden from public fan zone.' : 'Comment restored to public.',
  );
  if (threadId) revalidatePath(`/admin/kijiweni/${threadId}`);
  revalidatePath('/admin/kijiweni');
  revalidatePath('/kijiweni');
  return res;
}

export async function deleteCommentAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const commentId = id(fd, 'commentId');
  const threadId = id(fd, 'threadId');
  if (commentId === null) return fail('Invalid comment ID');

  const res = await mutate(
    () =>
      adminFetch(`/api/admin/kijiweni/comments/${commentId}`, {
        method: 'DELETE',
      }),
    'Comment deleted permanently.',
  );
  if (threadId) revalidatePath(`/admin/kijiweni/${threadId}`);
  revalidatePath('/admin/kijiweni');
  revalidatePath('/kijiweni');
  return res;
}
