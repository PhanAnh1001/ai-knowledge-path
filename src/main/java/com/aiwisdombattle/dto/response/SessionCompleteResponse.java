package com.aiwisdombattle.dto.response;

import com.aiwisdombattle.domain.model.KnowledgeNodeGraph;
import lombok.*;

import java.util.List;
import java.util.UUID;

@Getter
@Builder
public class SessionCompleteResponse {

    private UUID sessionId;
    private int score;

    /** Điểm thích nghi từ Python Adaptive Engine (fallback = score nếu engine down) */
    private double adaptiveScore;

    /** 3 node gợi ý tiếp theo từ Neo4j */
    private List<KnowledgeNodeGraph> nextSuggestions;
}
