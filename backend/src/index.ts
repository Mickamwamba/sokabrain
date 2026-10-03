import express, { type NextFunction, type Request, type Response } from 'express';
import cors from 'cors';
import { env } from './env.js';
import { prisma } from './db.js';
import { vaultRouter } from './routes/vault.js';
import { adminRouter } from './routes/admin.js';
import { kijiweniRouter } from './routes/kijiweni.js';
import { startLiveScoreSync } from './jobs/liveScoreSync.js';

const app = express();
// Decides what req.ip is behind a proxy; Kijiweni's rate limits key on it.
app.set('trust proxy', env.TRUST_PROXY);
app.use(cors());
app.use(express.json());

app.get('/health', async (_req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.json({ status: 'ok', database: 'connected' });
  } catch {
    res.status(503).json({ status: 'degraded', database: 'unreachable' });
  }
});

// Read side of the vault (public), the fan forum, and the authenticated write side.
app.use('/api/vault', vaultRouter);
app.use('/api/kijiweni', kijiweniRouter);
app.use('/api/admin', adminRouter);

app.use((_req, res) => res.status(404).json({ error: 'Not found' }));

// Express 5 forwards rejected promises from async handlers here automatically.
app.use((err: unknown, _req: Request, res: Response, _next: NextFunction) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

const onListening = () => {
  console.log(`sokabrain api listening on http://${env.HOST ?? 'localhost'}:${env.PORT}`);
};
const server = env.HOST
  ? app.listen(env.PORT, env.HOST, onListening)
  : app.listen(env.PORT, onListening);

// Warns and no-ops when API_FOOTBALL_KEY is unset — the read and admin APIs
// are fully usable without a live-score provider.
const stopLiveSync =
  env.LIVE_SYNC_ENABLED === 'true' ? startLiveScoreSync() : null;

// Without this a port clash prints nothing useful and the process just dies.
server.on('error', (err: NodeJS.ErrnoException) => {
  if (err.code === 'EADDRINUSE') {
    console.error(
      `Port ${env.PORT} is already in use. Set PORT in backend/.env to a free port.`,
    );
  } else {
    console.error('Server failed to start:', err);
  }
  process.exit(1);
});

for (const signal of ['SIGINT', 'SIGTERM'] as const) {
  process.on(signal, () => {
    stopLiveSync?.();
    server.close(() => {
      void prisma.$disconnect().then(() => process.exit(0));
    });
  });
}
