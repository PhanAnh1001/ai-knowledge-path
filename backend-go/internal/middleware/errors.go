package middleware

import (
	"encoding/json"
	"errors"
	"net/http"
	"time"

	"github.com/aiwisdombattle/backend/internal/domain"
)

// APIError matches the RFC 7807-like format used by the Java backend.
type APIError struct {
	Timestamp string `json:"timestamp"`
	Status    int    `json:"status"`
	Error     string `json:"error"`
	Message   string `json:"message"`
	Path      string `json:"path"`
}

// WriteError maps a domain error to the appropriate HTTP status and writes the JSON body.
func WriteError(w http.ResponseWriter, r *http.Request, err error) {
	status, errStr := errorToStatus(err)
	body := APIError{
		Timestamp: time.Now().UTC().Format(time.RFC3339),
		Status:    status,
		Error:     errStr,
		Message:   err.Error(),
		Path:      r.URL.Path,
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}

// WriteJSON writes a successful JSON response with HTTP 200.
func WriteJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

func errorToStatus(err error) (int, string) {
	switch {
	case errors.Is(err, domain.ErrNotFound):
		return http.StatusNotFound, "Not Found"
	case errors.Is(err, domain.ErrConflict):
		return http.StatusConflict, "Conflict"
	case errors.Is(err, domain.ErrInvalidCreds):
		return http.StatusUnauthorized, "Unauthorized"
	case errors.Is(err, domain.ErrUnauthorized):
		return http.StatusUnauthorized, "Unauthorized"
	case errors.Is(err, domain.ErrForbidden):
		return http.StatusForbidden, "Forbidden"
	case errors.Is(err, domain.ErrValidation):
		return http.StatusBadRequest, "Bad Request"
	default:
		return http.StatusInternalServerError, "Internal Server Error"
	}
}
