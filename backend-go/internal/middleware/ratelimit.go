package middleware

import (
	"fmt"
	"net/http"
	"strings"
	"sync"
	"time"
)

// RateLimiter is a sliding-window, per-IP rate limiter stored in memory.
type RateLimiter struct {
	mu      sync.Mutex
	windows map[string][]time.Time
	max     int
	window  time.Duration
}

func NewRateLimiter(max int, window time.Duration) *RateLimiter {
	rl := &RateLimiter{
		windows: make(map[string][]time.Time),
		max:     max,
		window:  window,
	}
	// Periodically clean stale entries
	go rl.cleanup()
	return rl
}

// Limit returns a Chi middleware that rate-limits requests by IP.
func (rl *RateLimiter) Limit(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ip := realIP(r)
		remaining, ok := rl.allow(ip)
		w.Header().Set("X-RateLimit-Limit", fmt.Sprintf("%d", rl.max))
		w.Header().Set("X-RateLimit-Remaining", fmt.Sprintf("%d", remaining))
		if !ok {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusTooManyRequests)
			_, _ = w.Write([]byte(`{"status":429,"error":"Too Many Requests","message":"rate limit exceeded"}`))
			return
		}
		next.ServeHTTP(w, r)
	})
}

func (rl *RateLimiter) allow(ip string) (remaining int, ok bool) {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	now := time.Now()
	cutoff := now.Add(-rl.window)

	// Prune old timestamps
	ts := rl.windows[ip]
	var fresh []time.Time
	for _, t := range ts {
		if t.After(cutoff) {
			fresh = append(fresh, t)
		}
	}

	if len(fresh) >= rl.max {
		rl.windows[ip] = fresh
		return 0, false
	}

	fresh = append(fresh, now)
	rl.windows[ip] = fresh
	return rl.max - len(fresh), true
}

func (rl *RateLimiter) cleanup() {
	ticker := time.NewTicker(5 * time.Minute)
	for range ticker.C {
		rl.mu.Lock()
		now := time.Now()
		for ip, ts := range rl.windows {
			var fresh []time.Time
			for _, t := range ts {
				if t.After(now.Add(-rl.window)) {
					fresh = append(fresh, t)
				}
			}
			if len(fresh) == 0 {
				delete(rl.windows, ip)
			} else {
				rl.windows[ip] = fresh
			}
		}
		rl.mu.Unlock()
	}
}

func realIP(r *http.Request) string {
	if ip := r.Header.Get("CF-Connecting-IP"); ip != "" {
		return ip
	}
	if ip := r.Header.Get("X-Forwarded-For"); ip != "" {
		return strings.Split(ip, ",")[0]
	}
	if ip := r.Header.Get("X-Real-IP"); ip != "" {
		return ip
	}
	// Strip port
	addr := r.RemoteAddr
	if i := strings.LastIndex(addr, ":"); i != -1 {
		return addr[:i]
	}
	return addr
}
