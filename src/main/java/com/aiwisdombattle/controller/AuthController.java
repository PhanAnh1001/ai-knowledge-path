package com.aiwisdombattle.controller;

import com.aiwisdombattle.dto.request.LoginRequest;
import com.aiwisdombattle.dto.request.RegisterRequest;
import com.aiwisdombattle.dto.response.AuthResponse;
import com.aiwisdombattle.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
@Tag(name = "Auth", description = "Đăng ký và đăng nhập")
public class AuthController {

    private final AuthService authService;

    @Operation(summary = "Đăng ký tài khoản mới",
        responses = {
            @ApiResponse(responseCode = "201", description = "Đăng ký thành công, trả về JWT"),
            @ApiResponse(responseCode = "409", description = "Email đã tồn tại")
        })
    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        AuthResponse response = authService.register(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @Operation(summary = "Đăng nhập",
        responses = {
            @ApiResponse(responseCode = "200", description = "Đăng nhập thành công, trả về JWT"),
            @ApiResponse(responseCode = "401", description = "Sai email hoặc mật khẩu")
        })
    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }
}
