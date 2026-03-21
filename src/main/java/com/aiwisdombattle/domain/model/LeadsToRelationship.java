package com.aiwisdombattle.domain.model;

import lombok.*;
import org.springframework.data.neo4j.core.schema.*;

/**
 * Relationship LEADS_TO trong Neo4j.
 * Node A --[LEADS_TO {weight, relation_vi}]--> Node B
 */
@RelationshipProperties
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LeadsToRelationship {

    @RelationshipId
    private Long relId;

    /** Mức độ liên quan 0.0–1.0 — dùng để sắp xếp gợi ý */
    private double weight;

    /** Nhãn hiển thị trên UI, ví dụ: "Khám phá tiếp" */
    private String relationVi;

    @TargetNode
    private KnowledgeNodeGraph target;
}
