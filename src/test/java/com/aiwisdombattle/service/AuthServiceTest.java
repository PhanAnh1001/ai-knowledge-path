package com.aiwisdombattle.service;

import com.aiwisdombattle.domain.entity.User;
import com.aiwisdombattle.dto.request.LoginRequest;
import com.aiwisdombattle.dto.request.RefreshTokenRequest;
import com.aiwisdombattle.dto.request.RegisterRequest;
import com.aiwisdombattle.dto.response.AuthResponse;
import com.aiwisdombattle.exception.EmailAlreadyUsedException;
import com.aiwisdombattle.exception.InvalidCredentialsException;
import com.aiwisdombattle.repository.UserRepository;
import com.aiwisdombattle.security.JwtTokenProvider;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock UserRepository userRepository;
    @Mock PasswordEncoder passwordEncoder;
    @Mock JwtTokenProvider tokenProvider;

    @InjectMocks AuthService authService;

    private RegisterRequest registerRequest;
    private LoginRequest loginRequest;
    private User existingUser;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(authService, "jwtExpirationMs", 86400000L);

        registerRequest = mockRegisterRequest();
        loginRequest    = mockLoginRequest();

        existingUser = User.builder()
            .id(UUID.randomUUID())
            .email("user@example.com")
            .displayName("Test User")
            .passwordHash("$2a$hashed")
            .explorerType("nature")
            .ageGroup("teen_11_17")
            .build();
    }

    // ── register ──────────────────────────────────────────────────────────────

    @Test
    void register_succeeds_withValidData() {
        when(userRepository.existsByEmail(anyString())).thenReturn(false);
        when(passwordEncoder.encode(anyString())).thenReturn("$2a$hashed");
        when(userRepository.save(any())).thenReturn(existingUser);
        when(tokenProvider.generate(any())).thenReturn("jwt.token.here");
        when(tokenProvider.generateRefreshToken(any())).thenReturn("refresh.token.here");

        AuthResponse response = authService.register(registerRequest);

        assertThat(response.getAccessToken()).isEqualTo("jwt.token.here");
        assertThat(response.getRefreshToken()).isEqualTo("refresh.token.here");
        assertThat(response.getTokenType()).isEqualTo("Bearer");
        assertThat(response.getDisplayName()).isEqualTo(existingUser.getDisplayName());
        assertThat(response.getExplorerType()).isEqualTo("nature");
        verify(userRepository).save(any(User.class));
    }

    @Test
    void register_throws_whenEmailAlreadyUsed() {
        when(userRepository.existsByEmail(registerRequest.getEmail())).thenReturn(true);

        assertThatThrownBy(() -> authService.register(registerRequest))
            .isInstanceOf(EmailAlreadyUsedException.class)
            .hasMessageContaining(registerRequest.getEmail());

        verify(userRepository, never()).save(any());
    }

    @Test
    void register_hashesPassword_beforeSaving() {
        when(userRepository.existsByEmail(anyString())).thenReturn(false);
        when(passwordEncoder.encode("Secret123")).thenReturn("$2a$hashed");
        when(userRepository.save(any())).thenAnswer(inv -> {
            User u = inv.getArgument(0);
            // Mật khẩu gốc không được lưu
            assertThat(u.getPasswordHash()).isEqualTo("$2a$hashed");
            assertThat(u.getPasswordHash()).doesNotContain("Secret123");
            return existingUser;
        });
        when(tokenProvider.generate(any())).thenReturn("token");
        when(tokenProvider.generateRefreshToken(any())).thenReturn("refresh");

        authService.register(registerRequest);

        verify(passwordEncoder).encode("Secret123");
    }

    // ── login ─────────────────────────────────────────────────────────────────

    @Test
    void login_succeeds_withCorrectCredentials() {
        when(userRepository.findByEmail("user@example.com")).thenReturn(Optional.of(existingUser));
        when(passwordEncoder.matches("Secret123", "$2a$hashed")).thenReturn(true);
        when(tokenProvider.generate(existingUser.getId())).thenReturn("jwt.token.here");
        when(tokenProvider.generateRefreshToken(existingUser.getId())).thenReturn("refresh.token.here");

        AuthResponse response = authService.login(loginRequest);

        assertThat(response.getAccessToken()).isEqualTo("jwt.token.here");
        assertThat(response.getUserId()).isEqualTo(existingUser.getId());
    }

    @Test
    void login_throws_whenEmailNotFound() {
        when(userRepository.findByEmail(anyString())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.login(loginRequest))
            .isInstanceOf(InvalidCredentialsException.class);
    }

    @Test
    void login_throws_whenPasswordWrong() {
        when(userRepository.findByEmail("user@example.com")).thenReturn(Optional.of(existingUser));
        when(passwordEncoder.matches(anyString(), anyString())).thenReturn(false);

        assertThatThrownBy(() -> authService.login(loginRequest))
            .isInstanceOf(InvalidCredentialsException.class);
    }

    @Test
    void login_doesNotReveal_whichFieldIsWrong() {
        // Cả 2 trường hợp sai email và sai mật khẩu đều ném cùng exception
        when(userRepository.findByEmail(anyString())).thenReturn(Optional.empty());
        assertThatThrownBy(() -> authService.login(loginRequest))
            .isInstanceOf(InvalidCredentialsException.class)
            .hasMessage("Email hoặc mật khẩu không chính xác");

        when(userRepository.findByEmail("user@example.com")).thenReturn(Optional.of(existingUser));
        when(passwordEncoder.matches(anyString(), anyString())).thenReturn(false);
        assertThatThrownBy(() -> authService.login(loginRequest))
            .isInstanceOf(InvalidCredentialsException.class)
            .hasMessage("Email hoặc mật khẩu không chính xác");
    }

    // ── refreshAccessToken ────────────────────────────────────────────────────

    @Test
    void refreshAccessToken_returnsNewAccessToken_withValidRefreshToken() {
        String refreshTokenStr = "valid.refresh.token";
        RefreshTokenRequest req = new RefreshTokenRequest();
        ReflectionTestUtils.setField(req, "refreshToken", refreshTokenStr);

        when(tokenProvider.isValidRefreshToken(refreshTokenStr)).thenReturn(true);
        when(tokenProvider.extractUserId(refreshTokenStr)).thenReturn(existingUser.getId().toString());
        when(userRepository.existsById(existingUser.getId())).thenReturn(true);
        when(tokenProvider.generate(existingUser.getId())).thenReturn("new.access.token");

        AuthResponse response = authService.refreshAccessToken(req);

        assertThat(response.getAccessToken()).isEqualTo("new.access.token");
        assertThat(response.getRefreshToken()).isNull();
    }

    @Test
    void refreshAccessToken_throws_whenTokenIsInvalidOrWrongType() {
        String badToken = "expired.or.access.type.token";
        RefreshTokenRequest req = new RefreshTokenRequest();
        ReflectionTestUtils.setField(req, "refreshToken", badToken);

        when(tokenProvider.isValidRefreshToken(badToken)).thenReturn(false);

        assertThatThrownBy(() -> authService.refreshAccessToken(req))
            .isInstanceOf(InvalidCredentialsException.class);

        verify(userRepository, never()).existsById(any());
    }

    @Test
    void refreshAccessToken_throws_whenUserNoLongerExists() {
        String refreshTokenStr = "valid.refresh.token";
        RefreshTokenRequest req = new RefreshTokenRequest();
        ReflectionTestUtils.setField(req, "refreshToken", refreshTokenStr);

        when(tokenProvider.isValidRefreshToken(refreshTokenStr)).thenReturn(true);
        when(tokenProvider.extractUserId(refreshTokenStr)).thenReturn(existingUser.getId().toString());
        when(userRepository.existsById(existingUser.getId())).thenReturn(false);

        assertThatThrownBy(() -> authService.refreshAccessToken(req))
            .isInstanceOf(InvalidCredentialsException.class);
    }

    @Test
    void login_includesRefreshToken_inResponse() {
        when(userRepository.findByEmail("user@example.com")).thenReturn(Optional.of(existingUser));
        when(passwordEncoder.matches("Secret123", "$2a$hashed")).thenReturn(true);
        when(tokenProvider.generate(existingUser.getId())).thenReturn("access.token");
        when(tokenProvider.generateRefreshToken(existingUser.getId())).thenReturn("refresh.token");

        AuthResponse response = authService.login(loginRequest);

        assertThat(response.getAccessToken()).isEqualTo("access.token");
        assertThat(response.getRefreshToken()).isEqualTo("refresh.token");
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    private RegisterRequest mockRegisterRequest() {
        // Dùng reflection vì Lombok @Getter + no-arg constructor
        RegisterRequest req = new RegisterRequest();
        ReflectionTestUtils.setField(req, "email",        "user@example.com");
        ReflectionTestUtils.setField(req, "displayName",  "Test User");
        ReflectionTestUtils.setField(req, "password",     "Secret123");
        ReflectionTestUtils.setField(req, "explorerType", "nature");
        ReflectionTestUtils.setField(req, "ageGroup",     "teen_11_17");
        return req;
    }

    private LoginRequest mockLoginRequest() {
        LoginRequest req = new LoginRequest();
        ReflectionTestUtils.setField(req, "email",    "user@example.com");
        ReflectionTestUtils.setField(req, "password", "Secret123");
        return req;
    }
}
