package com.aiwisdombattle.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.Duration;

/**
 * Rate limiter dựa trên Redis INCR/EXPIRE.
 * Áp dụng cho /api/v1/auth/** — ngăn brute-force và spam đăng ký.
 * Key: "rate:{ip}:{windowStart}" — window 1 phút.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class RateLimitFilter extends OncePerRequestFilter {

    private final StringRedisTemplate redisTemplate;

    @Value("${app.rate-limit.auth.max-requests:20}")
    private int maxRequests;

    @Value("${app.rate-limit.auth.window-seconds:60}")
    private long windowSeconds;

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !request.getRequestURI().startsWith("/api/v1/auth/");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        String ip = extractIp(request);
        long window = System.currentTimeMillis() / (windowSeconds * 1000);
        String key = "rate:" + ip + ":" + window;

        Long count = redisTemplate.opsForValue().increment(key);
        if (count == null) count = 1L;

        if (count == 1) {
            redisTemplate.expire(key, Duration.ofSeconds(windowSeconds + 5));
        }

        response.setHeader("X-RateLimit-Limit", String.valueOf(maxRequests));
        response.setHeader("X-RateLimit-Remaining", String.valueOf(Math.max(0, maxRequests - count)));

        if (count > maxRequests) {
            log.warn("Rate limit exceeded for IP {} on {}", ip, request.getRequestURI());
            response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
            response.setContentType("application/problem+json");
            response.getWriter().write(
                "{\"status\":429,\"detail\":\"Too many requests. Retry after " + windowSeconds + " seconds.\","
                + "\"instance\":\"" + request.getRequestURI() + "\"}");
            return;
        }

        chain.doFilter(request, response);
    }

    private String extractIp(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            return forwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
