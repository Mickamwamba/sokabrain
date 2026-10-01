# Sokabrain web: public site and admin console.
FROM node:22-bookworm-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
# Next.js bakes the /api/vault and /api/kijiweni rewrite targets into the build,
# so the backend's address has to be known here, not only at run time.
ARG API_URL=http://backend:4010
ENV API_URL=$API_URL NEXT_TELEMETRY_DISABLED=1
RUN npm run build

FROM node:22-bookworm-slim
WORKDIR /app
ARG API_URL=http://backend:4010
ENV NODE_ENV=production API_URL=$API_URL NEXT_TELEMETRY_DISABLED=1
COPY --from=build /app/package.json /app/package-lock.json ./
RUN npm ci --omit=dev
COPY --from=build /app/.next ./.next
COPY --from=build /app/public ./public
COPY --from=build /app/next.config.ts ./
USER node
EXPOSE 3100
CMD ["npx", "next", "start", "-H", "0.0.0.0", "-p", "3100"]
