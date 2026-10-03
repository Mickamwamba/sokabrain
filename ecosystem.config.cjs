// PM2 process definitions for the shared-server deployment path.
// See docs/DEPLOYMENT.md, "Deploying to a shared server (Apache and PM2)".
//
// No secrets here. The backend reads its own backend/.env; the web app's
// API_URL lives in the single web/.env.production file (same doc, (f)/(g)).
// Exactly one instance each, fork mode — the live-score cron and Kijiweni's
// rate-limit counters live in the backend's memory and must not be split
// across workers (docs/ARCHITECTURE.md, "Constraints that shape deployment").
module.exports = {
  apps: [
    {
      name: 'sokabrain-api',
      cwd: '/opt/sokabrain/backend',
      script: 'dist/index.js',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
      },
    },
    {
      name: 'sokabrain-web',
      cwd: '/opt/sokabrain/web',
      script: 'node_modules/.bin/next',
      // -H binds the web app to loopback only, matching the main guide's
      // systemd unit (docs/DEPLOYMENT.md, step 4.3). The npm "start" script
      // doesn't carry -p/-H, so they're passed here instead of using it.
      args: 'start -p 3100 -H 127.0.0.1',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
      },
    },
  ],
};
