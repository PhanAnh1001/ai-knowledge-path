package com.aiwisdombattle.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Builder;
import lombok.Getter;

import java.util.UUID;

@Getter
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class AuthResponse {

    private String accessToken;

    @Builder.Default
    private String tokenType = "Bearer";

    private long expiresIn;     // milliseconds

    /** Refresh token — chỉ trả về khi đăng nhập/đăng ký, null khi refresh */
    private String refreshToken;

    // Thông tin người dùng cơ bản — tránh round-trip thêm sau login
    private UUID   userId;
    private String displayName;
    private String explorerType;
    private String ageGroup;
    private boolean premium;
}
