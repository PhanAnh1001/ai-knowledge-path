package com.aiwisdombattle.exception;

import com.aiwisdombattle.controller.AuthController;
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

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(AuthController.class)
@Import(com.aiwisdombattle.config.SecurityConfig.class)
class GlobalExceptionHandlerTest {

    @Autowired MockMvc mockMvc;
    @Autowired ObjectMapper objectMapper;

    @MockBean AuthService authService;
    @MockBean com.aiwisdombattle.security.JwtAuthFilter jwtAuthFilter;
    @MockBean com.aiwisdombattle.security.JwtTokenProvider jwtTokenProvider;

    @BeforeEach
    void allowFilterChain() throws Exception {
        doAnswer((Answer<Void>) inv -> {
            ((FilterChain) inv.getArgument(2))
                .doFilter(inv.getArgument(0), inv.getArgument(1));
            return null;
        }).when(jwtAuthFilter).doFilter(
            any(HttpServletRequest.class),
            any(HttpServletResponse.class),
            any(FilterChain.class)
        );
    }

    @Test
    void register_returns409_whenEmailAlreadyUsed() throws Exception {
        when(authService.register(any())).thenThrow(new EmailAlreadyUsedException("x@x.com"));

        String body = "{\"email\":\"x@x.com\",\"displayName\":\"Explorer\",\"password\":\"Pass1234!\","
            + "\"explorerType\":\"nature\",\"ageGroup\":\"adult_18_plus\"}";

        mockMvc.perform(post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(body))
            .andExpect(status().isConflict())
            .andExpect(jsonPath("$.status").value(409))
            .andExpect(jsonPath("$.detail").isNotEmpty())
            .andExpect(jsonPath("$.instance").value("/api/v1/auth/register"));
    }

    @Test
    void login_returns401_whenInvalidCredentials() throws Exception {
        when(authService.login(any())).thenThrow(new InvalidCredentialsException());

        mockMvc.perform(post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"x@x.com\",\"password\":\"wrong\"}"))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.status").value(401));
    }

    @Test
    void register_returns400_whenValidationFails() throws Exception {
        mockMvc.perform(post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"not-an-email\",\"displayName\":\"\",\"password\":\"x\"}"))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400))
            .andExpect(jsonPath("$.fieldErrors").isArray());
    }
}
