import { SignJWT, jwtVerify } from 'jose';
import { env } from '../env.js';

export type AdminClaims = { adminId: number; email: string };

const ISSUER = 'sokabrain';
const AUDIENCE = 'sokabrain-admin';
const TTL = '12h';

function secret(): Uint8Array {
  if (!env.JWT_SECRET) {
    // Reached only if a write route is hit without JWT_SECRET set; the read API
    // deliberately still boots without it.
    throw new Error('JWT_SECRET is not set — admin auth is unavailable');
  }
  return new TextEncoder().encode(env.JWT_SECRET);
}

export async function signAdminToken(claims: AdminClaims): Promise<string> {
  return new SignJWT({ email: claims.email })
    .setProtectedHeader({ alg: 'HS256' })
    .setSubject(String(claims.adminId))
    .setIssuer(ISSUER)
    .setAudience(AUDIENCE)
    .setIssuedAt()
    .setExpirationTime(TTL)
    .sign(secret());
}

export async function verifyAdminToken(token: string): Promise<AdminClaims | null> {
  try {
    const { payload } = await jwtVerify(token, secret(), {
      issuer: ISSUER,
      audience: AUDIENCE,
      algorithms: ['HS256'], // pinned: never let the token pick its own algorithm
    });
    const adminId = Number(payload.sub);
    if (!Number.isInteger(adminId) || typeof payload.email !== 'string') return null;
    return { adminId, email: payload.email };
  } catch {
    return null;
  }
}
