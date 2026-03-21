package com.aiwisdombattle.controller;

import com.aiwisdombattle.dto.request.LoginRequest;
import com.aiwisdombattle.dto.request.RegisterRequest;
import com.aiwisdombattle.dto.response.AuthResponse;
import com.aiwisdombattle.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    /**
     * POST /api/v1/auth/register
     *
     * Body:
     * {
     *   "email":        "user@example.com",
     *   "displayName":  "Khám Phá Gia",
     *   "password":     "Secret123",
     *   "explorerType": "nature",
     *   "ageGroup":     "teen_11_17"
     * }
     *
     * Response 201: AuthResponse (accessToken + user info)
     * Response 409: email đã tồn tại
     */
    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        AuthResponse response = authService.register(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * POST /api/v1/auth/login
     *
     * Body:
     * {
     *   "email":    "user@example.com",
     *   "password": "Secret123"
     * }
     *
     * Response 200: AuthResponse (accessToken + user info)
     * Response 401: sai email hoặc mật khẩu
     */
    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }
}
