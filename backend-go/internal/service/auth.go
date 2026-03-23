package service

import (
	"context"
	"fmt"

	"github.com/aiwisdombattle/backend/internal/domain"
	"github.com/aiwisdombattle/backend/internal/middleware"
	"github.com/aiwisdombattle/backend/internal/repository"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type AuthService struct {
	users *repository.UserRepository
	jwt   *middleware.JWTProvider
}

func NewAuthService(users *repository.UserRepository, jwt *middleware.JWTProvider) *AuthService {
	return &AuthService{users: users, jwt: jwt}
}

func (s *AuthService) Register(ctx context.Context, req domain.RegisterRequest) (*domain.AuthResponse, error) {
	if err := validateRegister(req); err != nil {
		return nil, err
	}

	exists, err := s.users.ExistsByEmail(ctx, req.Email)
	if err != nil {
		return nil, fmt.Errorf("check email: %w", err)
	}
	if exists {
		return nil, domain.ErrConflict
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("hash password: %w", err)
	}

	u := &domain.User{
		Email:        req.Email,
		PasswordHash: string(hash),
		DisplayName:  req.DisplayName,
		ExplorerType: req.ExplorerType,
		AgeGroup:     req.AgeGroup,
	}
	if err := s.users.Create(ctx, u); err != nil {
		return nil, fmt.Errorf("create user: %w", err)
	}

	return s.buildAuthResponse(u, true)
}

func (s *AuthService) Login(ctx context.Context, req domain.LoginRequest) (*domain.AuthResponse, error) {
	u, err := s.users.FindByEmail(ctx, req.Email)
	if err != nil {
		return nil, domain.ErrInvalidCreds
	}
	if err := bcrypt.CompareHashAndPassword([]byte(u.PasswordHash), []byte(req.Password)); err != nil {
		return nil, domain.ErrInvalidCreds
	}
	return s.buildAuthResponse(u, true)
}

func (s *AuthService) GetProfile(ctx context.Context, userID uuid.UUID) (*domain.UserProfileResponse, error) {
	u, err := s.users.FindByID(ctx, userID)
	if err != nil {
		return nil, err
	}
	return &domain.UserProfileResponse{
		UserID:        u.ID.String(),
		Email:         u.Email,
		DisplayName:   u.DisplayName,
		ExplorerType:  u.ExplorerType,
		AgeGroup:      u.AgeGroup,
		Premium:       u.Premium,
		TotalSessions: u.TotalSessions,
	}, nil
}

func (s *AuthService) Refresh(ctx context.Context, req domain.RefreshTokenRequest) (*domain.AuthResponse, error) {
	userID, err := s.jwt.ValidateRefreshToken(req.RefreshToken)
	if err != nil {
		return nil, domain.ErrUnauthorized
	}
	u, err := s.users.FindByID(ctx, userID)
	if err != nil {
		return nil, domain.ErrUnauthorized
	}
	access, err := s.jwt.GenerateAccessToken(u.ID)
	if err != nil {
		return nil, fmt.Errorf("generate access token: %w", err)
	}
	return &domain.AuthResponse{
		AccessToken: access,
		TokenType:   "Bearer",
		ExpiresIn:   s.jwt.AccessExpiration().Milliseconds(),
		Premium:     u.Premium,
	}, nil
}

// ─── private helpers ──────────────────────────────────────────────────────────

func (s *AuthService) buildAuthResponse(u *domain.User, withRefresh bool) (*domain.AuthResponse, error) {
	access, err := s.jwt.GenerateAccessToken(u.ID)
	if err != nil {
		return nil, fmt.Errorf("generate access token: %w", err)
	}
	resp := &domain.AuthResponse{
		AccessToken:  access,
		TokenType:    "Bearer",
		ExpiresIn:    s.jwt.AccessExpiration().Milliseconds(),
		UserID:       u.ID,
		DisplayName:  u.DisplayName,
		ExplorerType: u.ExplorerType,
		AgeGroup:     u.AgeGroup,
		Premium:      u.Premium,
	}
	if withRefresh {
		refresh, err := s.jwt.GenerateRefreshToken(u.ID)
		if err != nil {
			return nil, fmt.Errorf("generate refresh token: %w", err)
		}
		resp.RefreshToken = refresh
	}
	return resp, nil
}

func validateRegister(req domain.RegisterRequest) error {
	if req.Email == "" || req.Password == "" || req.DisplayName == "" {
		return fmt.Errorf("%w: email, password, and displayName are required", domain.ErrValidation)
	}
	if len(req.Password) < 8 {
		return fmt.Errorf("%w: password must be at least 8 characters", domain.ErrValidation)
	}
	validExplorer := map[string]bool{"nature": true, "technology": true, "history": true, "creative": true}
	if !validExplorer[req.ExplorerType] {
		req.ExplorerType = "nature"
	}
	validAge := map[string]bool{"child_8_10": true, "teen_11_17": true, "adult_18_plus": true}
	if !validAge[req.AgeGroup] {
		req.AgeGroup = "adult_18_plus"
	}
	return nil
}
