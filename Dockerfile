# -------- Stage 1: Build --------
FROM node:18-alpine AS builder

WORKDIR /app

# Set environment
ENV NODE_ENV=production

# Install dependencies first (better caching)
COPY package*.json ./
RUN npm ci --omit=dev

# Copy only required files
COPY index.js ./
COPY public ./public

# -------- Stage 2: Production --------
FROM node:18-alpine

WORKDIR /app

ENV NODE_ENV=production

# Copy from builder
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/index.js ./
COPY --from=builder /app/public ./public

# Expose app port
EXPOSE 3000

# Create non-root user
RUN addgroup -S nodejs && adduser -S nodejs -G nodejs

# Set ownership
RUN chown -R nodejs:nodejs /app

USER nodejs

# Healthcheck (improved)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/api/hello || exit 1

# Start app
CMD ["node", "index.js"]