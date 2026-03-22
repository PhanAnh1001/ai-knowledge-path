package com.aiwisdombattle.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Builder;
import lombok.Getter;

import java.time.Instant;
import java.util.List;

/**
 * Format lỗi nhất quán cho tất cả API responses.
 * {
 *   "timestamp": "2024-01-01T00:00:00Z",
 *   "status": 404,
 *   "error": "Not Found",
 *   "message": "Session not found: abc-123",
 *   "path": "/api/v1/sessions/complete",
 *   "fieldErrors": [{"field": "email", "message": "must not be blank"}]  // optional
 * }
 */
@Getter
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiError {

    private final Instant timestamp;
    private final int status;
    private final String error;
    private final String message;
    private final String path;
    private final List<FieldError> fieldErrors;

    @Getter
    @Builder
    public static class FieldError {
        private final String field;
        private final String message;
    }
}
