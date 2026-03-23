package handler

import (
	"encoding/json"
	"net/http"

	"github.com/aiwisdombattle/backend/internal/domain"
	"github.com/aiwisdombattle/backend/internal/middleware"
	"github.com/aiwisdombattle/backend/internal/service"
)

type SessionHandler struct {
	svc *service.SessionService
}

func NewSessionHandler(svc *service.SessionService) *SessionHandler {
	return &SessionHandler{svc: svc}
}

// POST /api/v1/sessions
func (h *SessionHandler) Start(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		middleware.WriteError(w, r, domain.ErrUnauthorized)
		return
	}
	var req domain.StartSessionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		middleware.WriteError(w, r, domain.ErrValidation)
		return
	}
	resp, err := h.svc.StartSession(r.Context(), userID, req)
	if err != nil {
		middleware.WriteError(w, r, err)
		return
	}
	middleware.WriteJSON(w, http.StatusOK, resp)
}

// POST /api/v1/sessions/complete
func (h *SessionHandler) Complete(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		middleware.WriteError(w, r, domain.ErrUnauthorized)
		return
	}
	var req domain.CompleteSessionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		middleware.WriteError(w, r, domain.ErrValidation)
		return
	}
	resp, err := h.svc.CompleteSession(r.Context(), userID, req)
	if err != nil {
		middleware.WriteError(w, r, err)
		return
	}
	middleware.WriteJSON(w, http.StatusOK, resp)
}
