package com.aiwisdombattle.domain.model;

import lombok.*;
import org.springframework.data.neo4j.core.schema.*;

/**
 * Relationship CROSS_DOMAIN trong Neo4j.
 * Kết nối hai node ở các domain khác nhau qua một khái niệm chung.
 */
@RelationshipProperties
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CrossDomainRelationship {

    @RelationshipId
    private Long relId;

    /** Tên khái niệm chung, ví dụ: "structural_strength" */
    private String concept;

    /** Câu giải thích ngắn hiển thị trên UI */
    private String insightVi;

    @TargetNode
    private KnowledgeNodeGraph target;
}
