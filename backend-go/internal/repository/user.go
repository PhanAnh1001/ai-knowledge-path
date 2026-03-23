package repository

import (
	"context"
	"errors"
	"fmt"

	"github.com/aiwisdombattle/backend/internal/domain"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type UserRepository struct {
	db *pgxpool.Pool
}

func NewUserRepository(db *pgxpool.Pool) *UserRepository {
	return &UserRepository{db: db}
}

func (r *UserRepository) Create(ctx context.Context, u *domain.User) error {
	const q = `
		INSERT INTO users (email, password_hash, display_name, explorer_type, age_group)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, created_at, updated_at`
	return r.db.QueryRow(ctx, q,
		u.Email, u.PasswordHash, u.DisplayName, u.ExplorerType, u.AgeGroup,
	).Scan(&u.ID, &u.CreatedAt, &u.UpdatedAt)
}

func (r *UserRepository) FindByEmail(ctx context.Context, email string) (*domain.User, error) {
	const q = `
		SELECT id, email, password_hash, display_name, explorer_type, age_group,
		       streak_days, total_sessions, premium, created_at, updated_at
		FROM users WHERE email = $1`
	u := &domain.User{}
	err := r.db.QueryRow(ctx, q, email).Scan(
		&u.ID, &u.Email, &u.PasswordHash, &u.DisplayName, &u.ExplorerType, &u.AgeGroup,
		&u.StreakDays, &u.TotalSessions, &u.Premium, &u.CreatedAt, &u.UpdatedAt,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, domain.ErrNotFound
	}
	return u, err
}

func (r *UserRepository) FindByID(ctx context.Context, id uuid.UUID) (*domain.User, error) {
	const q = `
		SELECT id, email, password_hash, display_name, explorer_type, age_group,
		       streak_days, total_sessions, premium, created_at, updated_at
		FROM users WHERE id = $1`
	u := &domain.User{}
	err := r.db.QueryRow(ctx, q, id).Scan(
		&u.ID, &u.Email, &u.PasswordHash, &u.DisplayName, &u.ExplorerType, &u.AgeGroup,
		&u.StreakDays, &u.TotalSessions, &u.Premium, &u.CreatedAt, &u.UpdatedAt,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, domain.ErrNotFound
	}
	return u, err
}

func (r *UserRepository) ExistsByEmail(ctx context.Context, email string) (bool, error) {
	var exists bool
	err := r.db.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM users WHERE email=$1)`, email).Scan(&exists)
	return exists, err
}

func (r *UserRepository) IncrementTotalSessions(ctx context.Context, userID uuid.UUID) error {
	_, err := r.db.Exec(ctx,
		`UPDATE users SET total_sessions = total_sessions + 1 WHERE id = $1`, userID)
	if err != nil {
		return fmt.Errorf("increment total sessions: %w", err)
	}
	return nil
}
