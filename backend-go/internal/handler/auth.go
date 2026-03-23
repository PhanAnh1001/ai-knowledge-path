package handler

import (
	"encoding/json"
	"net/http"

	"github.com/aiwisdombattle/backend/internal/domain"
	"github.com/aiwisdombattle/backend/internal/middleware"
	"github.com/aiwisdombattle/backend/internal/service"
)

type AuthHandler struct {
	svc *service.AuthService
}

func NewAuthHandler(svc *service.AuthService) *AuthHandler {
	return &AuthHandler{svc: svc}
}

// POST /api/v1/auth/register
func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request) {
	var req domain.RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		middleware.WriteError(w, r, domain.ErrValidation)
		return
	}
	resp, err := h.svc.Register(r.Context(), req)
	if err != nil {
		middleware.WriteError(w, r, err)
		return
	}
	middleware.WriteJSON(w, http.StatusCreated, resp)
}

// POST /api/v1/auth/login
func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var req domain.LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		middleware.WriteError(w, r, domain.ErrValidation)
		return
	}
	resp, err := h.svc.Login(r.Context(), req)
	if err != nil {
		middleware.WriteError(w, r, err)
		return
	}
	middleware.WriteJSON(w, http.StatusOK, resp)
}

// GET /api/v1/auth/me
func (h *AuthHandler) Me(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		middleware.WriteError(w, r, domain.ErrUnauthorized)
		return
	}
	resp, err := h.svc.GetProfile(r.Context(), userID)
	if err != nil {
		middleware.WriteError(w, r, err)
		return
	}
	middleware.WriteJSON(w, http.StatusOK, resp)
}

// POST /api/v1/auth/refresh
func (h *AuthHandler) Refresh(w http.ResponseWriter, r *http.Request) {
	var req domain.RefreshTokenRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		middleware.WriteError(w, r, domain.ErrValidation)
		return
	}
	resp, err := h.svc.Refresh(r.Context(), req)
	if err != nil {
		middleware.WriteError(w, r, err)
		return
	}
	middleware.WriteJSON(w, http.StatusOK, resp)
}

// POST /api/v1/auth/logout
func (h *AuthHandler) Logout(w http.ResponseWriter, r *http.Request) {
	// Stateless JWT — client drops the token; server just returns 204
	w.WriteHeader(http.StatusNoContent)
}
