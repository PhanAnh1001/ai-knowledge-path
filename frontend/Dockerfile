# =============================================================================
# Multi-stage Dockerfile — React Frontend
# Stage 1 (builder): npm build
# Stage 2 (runtime): nginx serve static files
# =============================================================================

# ── Stage 1: builder ──────────────────────────────────────────────────────────
FROM node:22-alpine AS builder

WORKDIR /app

# Cache node_modules layer
COPY package.json package-lock.json ./
RUN npm ci --prefer-offline || npm ci

# Build args for runtime env injection
ARG VITE_API_BASE_URL=/api/v1
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL

COPY . .
RUN npm run build

# ── Stage 2: runtime ──────────────────────────────────────────────────────────
FROM nginx:1.27-alpine AS runtime

# Xóa default config
RUN rm /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/conf.d/app.conf
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
