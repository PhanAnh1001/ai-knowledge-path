package com.aiwisdombattle.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.util.UUID;

/**
 * DTO trả về khi bắt đầu session mới.
 * Gộp sessionId + toàn bộ nội dung 6 giai đoạn của node
 * để frontend có thể render ngay mà không cần gọi thêm request.
 */
@Getter
@Builder
public class SessionStartResponse {

    private UUID sessionId;

    /** Toàn bộ nội dung 6 giai đoạn của KnowledgeNode */
    private KnowledgeNodeResponse node;
}
