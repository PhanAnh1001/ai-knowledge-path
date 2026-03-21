package com.aiwisdombattle.service;

import com.aiwisdombattle.domain.entity.User;
import com.aiwisdombattle.dto.request.LoginRequest;
import com.aiwisdombattle.dto.request.RegisterRequest;
import com.aiwisdombattle.dto.response.AuthResponse;
import com.aiwisdombattle.exception.EmailAlreadyUsedException;
import com.aiwisdombattle.exception.InvalidCredentialsException;
import com.aiwisdombattle.repository.UserRepository;
import com.aiwisdombattle.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;

    @Value("${app.jwt.expiration-ms}")
    private long jwtExpirationMs;

    /**
     * Đăng ký tài khoản mới.
     * Ném {@link EmailAlreadyUsedException} nếu email đã tồn tại.
     */
    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new EmailAlreadyUsedException(request.getEmail());
        }

        User user = User.builder()
            .email(request.getEmail())
            .displayName(request.getDisplayName())
            .passwordHash(passwordEncoder.encode(request.getPassword()))
            .explorerType(request.getExplorerType())
            .ageGroup(request.getAgeGroup())
            .build();

        userRepository.save(user);

        return buildAuthResponse(user);
    }

    /**
     * Đăng nhập.
     * Ném {@link InvalidCredentialsException} nếu email hoặc mật khẩu sai.
     * Dùng thời gian constant-time để tránh timing attack.
     */
    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
            .orElseThrow(InvalidCredentialsException::new);

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new InvalidCredentialsException();
        }

        return buildAuthResponse(user);
    }

    private AuthResponse buildAuthResponse(User user) {
        String token = tokenProvider.generate(user.getId());

        return AuthResponse.builder()
            .accessToken(token)
            .expiresIn(jwtExpirationMs)
            .userId(user.getId())
            .displayName(user.getDisplayName())
            .explorerType(user.getExplorerType())
            .ageGroup(user.getAgeGroup())
            .premium(user.isPremium())
            .build();
    }
}
