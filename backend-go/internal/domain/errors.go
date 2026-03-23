package domain

import "errors"

var (
	ErrNotFound     = errors.New("resource not found")
	ErrConflict     = errors.New("resource already exists")
	ErrInvalidCreds = errors.New("email hoặc mật khẩu không chính xác")
	ErrUnauthorized = errors.New("unauthorized")
	ErrValidation   = errors.New("validation failed")
	ErrForbidden    = errors.New("forbidden")
)
