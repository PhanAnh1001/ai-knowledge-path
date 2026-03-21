package com.aiwisdombattle.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.util.UUID;

@Getter
@Builder
public class AuthResponse {

    private String accessToken;

    @Builder.Default
    private String tokenType = "Bearer";

    private long expiresIn;     // milliseconds

    // Thông tin người dùng cơ bản — tránh round-trip thêm sau login
    private UUID   userId;
    private String displayName;
    private String explorerType;
    private String ageGroup;
    private boolean premium;
}
