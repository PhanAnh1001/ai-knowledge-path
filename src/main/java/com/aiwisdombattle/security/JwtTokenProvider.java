package com.aiwisdombattle.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.UUID;

@Component
public class JwtTokenProvider {

    private static final String CLAIM_TOKEN_TYPE = "type";
    private static final String TYPE_ACCESS  = "access";
    private static final String TYPE_REFRESH = "refresh";

    private final SecretKey key;
    private final long expirationMs;
    private final long refreshExpirationMs;

    public JwtTokenProvider(
        @Value("${app.jwt.secret}") String secret,
        @Value("${app.jwt.expiration-ms}") long expirationMs,
        @Value("${app.jwt.refresh-expiration-ms:2592000000}") long refreshExpirationMs
    ) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.expirationMs = expirationMs;
        this.refreshExpirationMs = refreshExpirationMs;
    }

    /** Tạo access JWT với subject là userId (UUID dạng String) */
    public String generate(UUID userId) {
        return buildToken(userId, TYPE_ACCESS, expirationMs);
    }

    /** Tạo refresh JWT với thời hạn dài hơn (mặc định 30 ngày) */
    public String generateRefreshToken(UUID userId) {
        return buildToken(userId, TYPE_REFRESH, refreshExpirationMs);
    }

    public String extractUserId(String token) {
        return parseClaims(token).getSubject();
    }

    public boolean isValid(String token) {
        try {
            parseClaims(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }

    /** Trả về true nếu token có claim type=refresh */
    public boolean isRefreshToken(String token) {
        try {
            Claims claims = parseClaims(token);
            return TYPE_REFRESH.equals(claims.get(CLAIM_TOKEN_TYPE, String.class));
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }

    /**
     * Kết hợp kiểm tra hợp lệ và loại token trong một lần parse.
     * Dùng thay cho gọi riêng isValid() + isRefreshToken().
     *
     * @return true nếu token hợp lệ VÀ có type=refresh
     */
    public boolean isValidRefreshToken(String token) {
        try {
            Claims claims = parseClaims(token);
            return TYPE_REFRESH.equals(claims.get(CLAIM_TOKEN_TYPE, String.class));
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }

    private String buildToken(UUID userId, String type, long ttlMs) {
        Date now = new Date();
        return Jwts.builder()
            .subject(userId.toString())
            .claim(CLAIM_TOKEN_TYPE, type)
            .issuedAt(now)
            .expiration(new Date(now.getTime() + ttlMs))
            .signWith(key)
            .compact();
    }

    private Claims parseClaims(String token) {
        return Jwts.parser()
            .verifyWith(key)
            .build()
            .parseSignedClaims(token)
            .getPayload();
    }
}
