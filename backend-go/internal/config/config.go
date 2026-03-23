package config

import (
	"os"
	"strconv"
	"strings"
	"time"
)

type Config struct {
	DatabaseURL string
	Port        string

	JWTSecret              string
	JWTExpiration          time.Duration
	JWTRefreshExpiration   time.Duration

	CORSAllowedOrigins []string

	RateLimitMax    int
	RateLimitWindow time.Duration
}

func Load() *Config {
	return &Config{
		DatabaseURL: getEnv("DATABASE_URL", "postgres://postgres:postgres@localhost:5432/ai_wisdom_battle"),
		Port:        getEnv("PORT", "8080"),

		JWTSecret:            requireEnv("JWT_SECRET"),
		JWTExpiration:        getDurationMs("JWT_EXPIRATION_MS", 86400000),
		JWTRefreshExpiration: getDurationMs("JWT_REFRESH_EXPIRATION_MS", 2592000000),

		CORSAllowedOrigins: strings.Split(getEnv("CORS_ALLOWED_ORIGINS", "http://localhost:5173"), ","),

		RateLimitMax:    getInt("RATE_LIMIT_MAX", 20),
		RateLimitWindow: time.Duration(getInt("RATE_LIMIT_WINDOW", 60)) * time.Second,
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func requireEnv(key string) string {
	v := os.Getenv(key)
	if v == "" {
		panic("required environment variable not set: " + key)
	}
	return v
}

func getInt(key string, fallback int) int {
	if v := os.Getenv(key); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			return n
		}
	}
	return fallback
}

func getDurationMs(key string, fallbackMs int64) time.Duration {
	if v := os.Getenv(key); v != "" {
		if n, err := strconv.ParseInt(v, 10, 64); err == nil {
			return time.Duration(n) * time.Millisecond
		}
	}
	return time.Duration(fallbackMs) * time.Millisecond
}
