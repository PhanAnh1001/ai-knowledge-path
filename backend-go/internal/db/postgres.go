package db

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"
)

// NewPool creates a new pgx connection pool.
func NewPool(ctx context.Context, databaseURL string) (*pgxpool.Pool, error) {
	pool, err := pgxpool.New(ctx, databaseURL)
	if err != nil {
		return nil, fmt.Errorf("create pool: %w", err)
	}
	if err := pool.Ping(ctx); err != nil {
		return nil, fmt.Errorf("ping database: %w", err)
	}
	return pool, nil
}

// RunMigrations applies SQL migration files from migrationsPath (*.up.sql),
// tracking applied migrations in a schema_migrations table.
func RunMigrations(ctx context.Context, pool *pgxpool.Pool, migrationsPath string) error {
	// Ensure migrations tracking table exists
	_, err := pool.Exec(ctx, `
		CREATE TABLE IF NOT EXISTS schema_migrations (
			version TEXT PRIMARY KEY,
			applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
		)`)
	if err != nil {
		return fmt.Errorf("create schema_migrations: %w", err)
	}

	// Find all *.up.sql files
	pattern := filepath.Join(migrationsPath, "*.up.sql")
	files, err := filepath.Glob(pattern)
	if err != nil {
		return fmt.Errorf("glob migrations: %w", err)
	}
	sort.Strings(files)

	for _, f := range files {
		version := filepath.Base(f)
		version = strings.TrimSuffix(version, ".up.sql")

		// Check if already applied
		var exists bool
		_ = pool.QueryRow(ctx,
			`SELECT EXISTS(SELECT 1 FROM schema_migrations WHERE version=$1)`, version,
		).Scan(&exists)
		if exists {
			continue
		}

		// Read and apply SQL
		content, err := os.ReadFile(f)
		if err != nil {
			return fmt.Errorf("read migration %s: %w", version, err)
		}

		if _, err := pool.Exec(ctx, string(content)); err != nil {
			return fmt.Errorf("apply migration %s: %w", version, err)
		}

		if _, err := pool.Exec(ctx,
			`INSERT INTO schema_migrations (version) VALUES ($1)`, version,
		); err != nil {
			return fmt.Errorf("record migration %s: %w", version, err)
		}
	}
	return nil
}
