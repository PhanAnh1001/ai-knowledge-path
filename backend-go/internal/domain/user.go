package domain

import (
	"time"

	"github.com/google/uuid"
)

type User struct {
	ID           uuid.UUID `json:"id"`
	Email        string    `json:"email"`
	PasswordHash string    `json:"-"`
	DisplayName  string    `json:"displayName"`
	ExplorerType string    `json:"explorerType"`
	AgeGroup     string    `json:"ageGroup"`
	StreakDays   int       `json:"streakDays"`
	TotalSessions int      `json:"totalSessions"`
	Premium      bool      `json:"premium"`
	CreatedAt    time.Time `json:"createdAt"`
	UpdatedAt    time.Time `json:"updatedAt"`
}

// ── Request DTOs ──────────────────────────────────────────────────────────────

type RegisterRequest struct {
	Email        string `json:"email"`
	DisplayName  string `json:"displayName"`
	Password     string `json:"password"`
	ExplorerType string `json:"explorerType"`
	AgeGroup     string `json:"ageGroup"`
}

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type RefreshTokenRequest struct {
	RefreshToken string `json:"refreshToken"`
}

// ── Response DTOs ─────────────────────────────────────────────────────────────

type AuthResponse struct {
	AccessToken  string    `json:"accessToken"`
	TokenType    string    `json:"tokenType"`
	ExpiresIn    int64     `json:"expiresIn"`
	RefreshToken string    `json:"refreshToken,omitempty"`
	UserID       uuid.UUID `json:"userId,omitempty"`
	DisplayName  string    `json:"displayName,omitempty"`
	ExplorerType string    `json:"explorerType,omitempty"`
	AgeGroup     string    `json:"ageGroup,omitempty"`
	Premium      bool      `json:"premium"`
}

type UserProfileResponse struct {
	UserID        string `json:"userId"`
	Email         string `json:"email"`
	DisplayName   string `json:"displayName"`
	ExplorerType  string `json:"explorerType"`
	AgeGroup      string `json:"ageGroup"`
	Premium       bool   `json:"premium"`
	TotalSessions int    `json:"totalSessions"`
}
