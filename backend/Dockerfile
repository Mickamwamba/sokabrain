# Sokabrain backend: the API, the live-score cron, and the npm scripts the
# scheduled jobs run. One image does all three.
FROM node:22-bookworm-slim

WORKDIR /app
ENV NODE_ENV=production

# Dev dependencies are installed on purpose: the sm:*, editions:* and admin:*
# scripts run through tsx, and `prisma generate` needs the prisma CLI.
COPY package.json package-lock.json ./
RUN npm ci --include=dev

COPY . .
# prisma.config.ts reads DATABASE_URL; generate doesn't connect, so a
# placeholder is enough at build time. The real one comes from the environment.
RUN DATABASE_URL=postgresql://build@localhost/build npx prisma generate \
 && npm run build

USER node
EXPOSE 4010
CMD ["node", "dist/index.js"]
