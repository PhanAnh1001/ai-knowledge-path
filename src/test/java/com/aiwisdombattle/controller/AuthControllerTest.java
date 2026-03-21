package com.aiwisdombattle.controller;

import com.aiwisdombattle.dto.response.AuthResponse;
import com.aiwisdombattle.exception.EmailAlreadyUsedException;
import com.aiwisdombattle.exception.InvalidCredentialsException;
import com.aiwisdombattle.service.AuthService;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.stubbing.Answer;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(AuthController.class)
@Import(com.aiwisdombattle.config.SecurityConfig.class)
class AuthControllerTest {

    @Autowired MockMvc mockMvc;
    @Autowired ObjectMapper objectMapper;

    @MockBean AuthService authService;
    @MockBean com.aiwisdombattle.security.JwtAuthFilter jwtAuthFilter;
    @MockBean com.aiwisdombattle.security.RateLimitFilter rateLimitFilter;
    @MockBean com.aiwisdombattle.security.JwtTokenProvider jwtTokenProvider;

    @BeforeEach
    void setUpFilter() throws Exception {
        // Tất cả filter mock phải pass-through để request đến được controller
        Answer<Void> passThrough = inv -> {
            ((FilterChain) inv.getArgument(2))
                .doFilter(inv.getArgument(0), inv.getArgument(1));
            return null;
        };
        doAnswer(passThrough).when(jwtAuthFilter).doFilter(any(), any(), any());
        doAnswer(passThrough).when(rateLimitFilter).doFilter(any(), any(), any());
    }

    private static final AuthResponse SAMPLE_RESPONSE = AuthResponse.builder()
        .accessToken("jwt.token.here")
        .expiresIn(86400000)
        .userId(UUID.randomUUID())
        .displayName("Test User")
        .explorerType("nature")
        .ageGroup("teen_11_17")
        .premium(false)
        .build();

    // ── POST /register ────────────────────────────────────────────────────────

    @Test
    void register_returns201_withValidBody() throws Exception {
        when(authService.register(any())).thenReturn(SAMPLE_RESPONSE);

        mockMvc.perform(post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "email":        "user@example.com",
                      "displayName":  "Test User",
                      "password":     "Secret123",
                      "explorerType": "nature",
                      "ageGroup":     "teen_11_17"
                    }
                    """))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.accessToken").value("jwt.token.here"))
            .andExpect(jsonPath("$.tokenType").value("Bearer"))
            .andExpect(jsonPath("$.explorerType").value("nature"));
    }

    @Test
    void register_returns409_whenEmailAlreadyUsed() throws Exception {
        when(authService.register(any())).thenThrow(new EmailAlreadyUsedException("user@example.com"));

        mockMvc.perform(post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "email":        "user@example.com",
                      "displayName":  "Test User",
                      "password":     "Secret123",
                      "explorerType": "nature",
                      "ageGroup":     "teen_11_17"
                    }
                    """))
            .andExpect(status().isConflict());
    }

    @Test
    void register_returns400_withInvalidExplorerType() throws Exception {
        mockMvc.perform(post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "email":        "user@example.com",
                      "displayName":  "Test User",
                      "password":     "Secret123",
                      "explorerType": "invalid_domain",
                      "ageGroup":     "teen_11_17"
                    }
                    """))
            .andExpect(status().isBadRequest());
    }

    @Test
    void register_returns400_withShortPassword() throws Exception {
        mockMvc.perform(post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "email":        "user@example.com",
                      "displayName":  "Test User",
                      "password":     "short",
                      "explorerType": "nature",
                      "ageGroup":     "teen_11_17"
                    }
                    """))
            .andExpect(status().isBadRequest());
    }

    // ── POST /login ───────────────────────────────────────────────────────────

    @Test
    void login_returns200_withCorrectCredentials() throws Exception {
        when(authService.login(any())).thenReturn(SAMPLE_RESPONSE);

        mockMvc.perform(post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "email":    "user@example.com",
                      "password": "Secret123"
                    }
                    """))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.accessToken").value("jwt.token.here"))
            .andExpect(jsonPath("$.userId").isNotEmpty());
    }

    @Test
    void login_returns401_withWrongCredentials() throws Exception {
        when(authService.login(any())).thenThrow(new InvalidCredentialsException());

        mockMvc.perform(post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "email":    "user@example.com",
                      "password": "wrong"
                    }
                    """))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void login_returns400_withMissingFields() throws Exception {
        mockMvc.perform(post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{}"))
            .andExpect(status().isBadRequest());
    }
}
