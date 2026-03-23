# ── Stage 1: Builder ──────────────────────────────────────────────────────────
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Copy go mod files first for layer caching
COPY go.mod go.sum ./
RUN go mod download

# Copy source
COPY . .

# Build static binary
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o server ./cmd/server

# ── Stage 2: Distroless runtime ───────────────────────────────────────────────
FROM gcr.io/distroless/static:nonroot

WORKDIR /app

# Copy binary
COPY --from=builder /app/server .

# Copy migrations
COPY --from=builder /app/internal/db/migrations ./internal/db/migrations

ENV PORT=8080
ENV MIGRATIONS_PATH=/app/internal/db/migrations

EXPOSE 8080

USER nonroot:nonroot

ENTRYPOINT ["/app/server"]
