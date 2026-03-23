package middleware

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

type contextKey string

const userIDKey contextKey = "userID"

// JWTProvider issues and validates JWT tokens.
type JWTProvider struct {
	secret          []byte
	accessExp       time.Duration
	refreshExp      time.Duration
}

func NewJWTProvider(secret string, accessExp, refreshExp time.Duration) *JWTProvider {
	return &JWTProvider{
		secret:     []byte(secret),
		accessExp:  accessExp,
		refreshExp: refreshExp,
	}
}

func (p *JWTProvider) AccessExpiration() time.Duration { return p.accessExp }

type claims struct {
	jwt.RegisteredClaims
	Type string `json:"type"`
}

func (p *JWTProvider) GenerateAccessToken(userID uuid.UUID) (string, error) {
	return p.generate(userID, "access", p.accessExp)
}

func (p *JWTProvider) GenerateRefreshToken(userID uuid.UUID) (string, error) {
	return p.generate(userID, "refresh", p.refreshExp)
}

func (p *JWTProvider) generate(userID uuid.UUID, tokenType string, exp time.Duration) (string, error) {
	now := time.Now()
	c := &claims{
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID.String(),
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(exp)),
		},
		Type: tokenType,
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, c)
	signed, err := token.SignedString(p.secret)
	if err != nil {
		return "", fmt.Errorf("sign token: %w", err)
	}
	return signed, nil
}

// ValidateAccessToken validates an access token and returns the user UUID.
func (p *JWTProvider) ValidateAccessToken(tokenStr string) (uuid.UUID, error) {
	return p.validate(tokenStr, "access")
}

// ValidateRefreshToken validates a refresh token and returns the user UUID.
func (p *JWTProvider) ValidateRefreshToken(tokenStr string) (uuid.UUID, error) {
	return p.validate(tokenStr, "refresh")
}

func (p *JWTProvider) validate(tokenStr, expectedType string) (uuid.UUID, error) {
	token, err := jwt.ParseWithClaims(tokenStr, &claims{}, func(t *jwt.Token) (any, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
		}
		return p.secret, nil
	})
	if err != nil {
		return uuid.Nil, err
	}
	c, ok := token.Claims.(*claims)
	if !ok || !token.Valid {
		return uuid.Nil, errors.New("invalid token claims")
	}
	if c.Type != expectedType {
		return uuid.Nil, fmt.Errorf("expected token type %q, got %q", expectedType, c.Type)
	}
	id, err := uuid.Parse(c.Subject)
	if err != nil {
		return uuid.Nil, fmt.Errorf("parse subject uuid: %w", err)
	}
	return id, nil
}

// ─── HTTP Middleware ──────────────────────────────────────────────────────────

// Authenticate is a Chi middleware that validates the Bearer access token.
func (p *JWTProvider) Authenticate(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		header := r.Header.Get("Authorization")
		if !strings.HasPrefix(header, "Bearer ") {
			writeUnauthorized(w)
			return
		}
		tokenStr := strings.TrimPrefix(header, "Bearer ")
		userID, err := p.ValidateAccessToken(tokenStr)
		if err != nil {
			writeUnauthorized(w)
			return
		}
		ctx := context.WithValue(r.Context(), userIDKey, userID)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// UserIDFromContext extracts the authenticated user UUID from the request context.
func UserIDFromContext(ctx context.Context) (uuid.UUID, bool) {
	id, ok := ctx.Value(userIDKey).(uuid.UUID)
	return id, ok
}

func writeUnauthorized(w http.ResponseWriter) {
	http.Error(w, `{"status":401,"error":"Unauthorized","message":"missing or invalid token"}`, http.StatusUnauthorized)
}
