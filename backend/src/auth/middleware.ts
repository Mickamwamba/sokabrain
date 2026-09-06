import type { NextFunction, Request, Response } from 'express';
import { prisma } from '../db.js';
import { verifyAdminToken } from './jwt.js';

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      admin?: { id: number; email: string; displayName: string };
    }
  }
}

/**
 * Requires a valid admin bearer token.
 *
 * The account is re-read on every request rather than trusted from the token
 * alone, so deactivating an admin takes effect immediately instead of when
 * their 12-hour token happens to expire.
 */
export async function requireAdmin(req: Request, res: Response, next: NextFunction) {
  const header = req.get('authorization');
  if (!header?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing bearer token' });
  }

  const claims = await verifyAdminToken(header.slice('Bearer '.length).trim());
  if (!claims) return res.status(401).json({ error: 'Invalid or expired token' });

  const admin = await prisma.admins.findUnique({
    where: { id: claims.adminId },
    select: { id: true, email: true, display_name: true, is_active: true },
  });
  if (!admin || !admin.is_active) {
    return res.status(401).json({ error: 'Account not found or deactivated' });
  }

  req.admin = { id: admin.id, email: admin.email, displayName: admin.display_name };
  next();
}
