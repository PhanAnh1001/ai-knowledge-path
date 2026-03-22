package com.aiwisdombattle.dto.response;

import lombok.Builder;
import lombok.Value;

/**
 * Profile thông tin người dùng hiện tại.
 * Trả về bởi GET /api/v1/auth/me
 */
@Value
@Builder
public class UserProfileResponse {
    String userId;
    String email;
    String displayName;
    String explorerType;
    String ageGroup;
    boolean premium;
    int totalSessions;
}
