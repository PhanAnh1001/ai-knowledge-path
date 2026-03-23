package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"
	"time"

	"github.com/aiwisdombattle/backend/internal/cache"
	"github.com/aiwisdombattle/backend/internal/config"
	appdb "github.com/aiwisdombattle/backend/internal/db"
	"github.com/aiwisdombattle/backend/internal/handler"
	"github.com/aiwisdombattle/backend/internal/middleware"
	"github.com/aiwisdombattle/backend/internal/repository"
	"github.com/aiwisdombattle/backend/internal/service"
	"github.com/go-chi/chi/v5"
	chimiddleware "github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	"github.com/joho/godotenv"
)

func main() {
	// Load .env (optional — ignore error in production where env vars are set directly)
	_ = godotenv.Load()

	cfg := config.Load()

	// ── Database ──────────────────────────────────────────────────────────────
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	pool, err := appdb.NewPool(ctx, cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("connect to database: %v", err)
	}
	defer pool.Close()

	// Determine migration path relative to binary location
	migrationsPath := migrationsDir()
	if err := appdb.RunMigrations(ctx, pool, migrationsPath); err != nil {
		log.Fatalf("run migrations: %v", err)
	}
	log.Println("database migrations applied")

	// ── Repositories ─────────────────────────────────────────────────────────
	userRepo     := repository.NewUserRepository(pool)
	nodeRepo     := repository.NewNodeRepository(pool)
	sessionRepo  := repository.NewSessionRepository(pool)
	progressRepo := repository.NewProgressRepository(pool)

	// ── Cache ─────────────────────────────────────────────────────────────────
	nodeCache := cache.NewNodeCache()

	// ── JWT Provider ──────────────────────────────────────────────────────────
	jwtProvider := middleware.NewJWTProvider(
		cfg.JWTSecret,
		cfg.JWTExpiration,
		cfg.JWTRefreshExpiration,
	)

	// ── Services ──────────────────────────────────────────────────────────────
	authSvc    := service.NewAuthService(userRepo, jwtProvider)
	nodeSvc    := service.NewNodeService(nodeRepo, nodeCache)
	sessionSvc := service.NewSessionService(sessionRepo, nodeRepo, userRepo, progressRepo)

	// ── Handlers ──────────────────────────────────────────────────────────────
	authHandler    := handler.NewAuthHandler(authSvc)
	nodeHandler    := handler.NewNodeHandler(nodeSvc, sessionSvc)
	sessionHandler := handler.NewSessionHandler(sessionSvc)

	// ── Rate Limiter ──────────────────────────────────────────────────────────
	rateLimiter := middleware.NewRateLimiter(cfg.RateLimitMax, cfg.RateLimitWindow)

	// ── Router ────────────────────────────────────────────────────────────────
	r := chi.NewRouter()

	// Global middleware
	r.Use(chimiddleware.Logger)
	r.Use(chimiddleware.Recoverer)
	r.Use(chimiddleware.RequestID)
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   cfg.CORSAllowedOrigins,
		AllowedMethods:   []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Authorization", "Content-Type", "X-Requested-With"},
		ExposedHeaders:   []string{"Authorization"},
		AllowCredentials: true,
		MaxAge:           3600,
	}))

	// Health check (Caddy rewrite: /actuator/health → /health)
	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		middleware.WriteJSON(w, http.StatusOK, map[string]string{"status": "UP"})
	})
	r.Get("/actuator/health", func(w http.ResponseWriter, r *http.Request) {
		middleware.WriteJSON(w, http.StatusOK, map[string]string{"status": "UP"})
	})

	// API v1
	r.Route("/api/v1", func(r chi.Router) {
		// Auth routes (rate-limited, no JWT required)
		r.Route("/auth", func(r chi.Router) {
			r.Use(rateLimiter.Limit)
			r.Post("/register", authHandler.Register)
			r.Post("/login", authHandler.Login)
			r.Post("/refresh", authHandler.Refresh)
			// Protected auth routes
			r.Group(func(r chi.Router) {
				r.Use(jwtProvider.Authenticate)
				r.Get("/me", authHandler.Me)
				r.Post("/logout", authHandler.Logout)
			})
		})

		// Session routes (JWT required)
		r.Route("/sessions", func(r chi.Router) {
			r.Use(jwtProvider.Authenticate)
			r.Post("/", sessionHandler.Start)
			r.Post("/complete", sessionHandler.Complete)
		})

		// Node routes (JWT required)
		r.Route("/nodes", func(r chi.Router) {
			r.Use(jwtProvider.Authenticate)
			r.Get("/", nodeHandler.List)
			r.Get("/{nodeId}", nodeHandler.Get)
			r.Get("/{nodeId}/map", nodeHandler.Map)
			r.Get("/{nodeId}/deep-dive", nodeHandler.DeepDive)
			r.Get("/{nodeId}/cross-domain", nodeHandler.CrossDomain)
		})
	})

	// ── Server ────────────────────────────────────────────────────────────────
	srv := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      r,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM)

	go func() {
		log.Printf("server listening on :%s", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("listen: %v", err)
		}
	}()

	<-quit
	log.Println("shutting down server...")
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer shutdownCancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Printf("server shutdown error: %v", err)
	}
	log.Println("server stopped")
}

// migrationsDir returns the path to the SQL migrations directory.
// Supports running from project root or from within the binary directory.
func migrationsDir() string {
	// Prefer explicit env var (useful in Docker)
	if p := os.Getenv("MIGRATIONS_PATH"); p != "" {
		return p
	}
	// Relative to working directory (go run from project root)
	candidates := []string{
		"internal/db/migrations",
		filepath.Join("..", "..", "internal", "db", "migrations"),
	}
	for _, c := range candidates {
		if _, err := os.Stat(c); err == nil {
			return c
		}
	}
	return "internal/db/migrations"
}
