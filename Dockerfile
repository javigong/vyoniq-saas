# syntax=docker.io/docker/dockerfile:1

FROM node:20-alpine AS base

# Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Install pnpm
RUN corepack enable pnpm

# Install dependencies
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app

# Set dummy environment variables for build time
ENV POSTGRES_URL="postgresql://dummy:dummy@localhost:5432/dummy"
ENV STRIPE_SECRET_KEY="sk_test_dummy"
ENV STRIPE_WEBHOOK_SECRET="whsec_dummy"
ENV BASE_URL="http://localhost:3000"
ENV AUTH_SECRET="dummy_secret"
ENV NEXT_TELEMETRY_DISABLED=1
# Skip static generation of dynamic pages
ENV NEXT_SKIP_INVALID_PRERENDER=true

# Enable pnpm and copy dependencies
RUN corepack enable pnpm
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Create public directory if it doesn't exist
RUN mkdir -p public

# Build the application
RUN pnpm build

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Create necessary directories
RUN mkdir -p public .next/static
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["node", "server.js"]
