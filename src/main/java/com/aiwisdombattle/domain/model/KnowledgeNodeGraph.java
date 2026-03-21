package com.aiwisdombattle.domain.model;

import lombok.*;
import org.springframework.data.neo4j.core.schema.*;

import java.util.ArrayList;
import java.util.List;

/**
 * Node trong Neo4j knowledge graph.
 * ID trùng với {@code KnowledgeNode.id} trong PostgreSQL (dạng String UUID).
 */
@Node("KnowledgeNode")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class KnowledgeNodeGraph {

    @Id
    private String id;               // UUID dạng String, đồng bộ với PostgreSQL

    private String title;
    private String domain;
    private String ageGroup;
    private int difficulty;
    private int curiosityScore;
    private boolean isPublished;

    /** Các node mở ra sau khi hoàn thành session này */
    @Relationship(type = "LEADS_TO", direction = Relationship.Direction.OUTGOING)
    @Builder.Default
    private List<LeadsToRelationship> leadsTo = new ArrayList<>();

    /** Các node deep-dive (Rabbit Hole Mode) */
    @Relationship(type = "DEEP_DIVE", direction = Relationship.Direction.OUTGOING)
    @Builder.Default
    private List<KnowledgeNodeGraph> deepDives = new ArrayList<>();

    /** Kết nối xuyên domain */
    @Relationship(type = "CROSS_DOMAIN", direction = Relationship.Direction.OUTGOING)
    @Builder.Default
    private List<CrossDomainRelationship> crossDomains = new ArrayList<>();
}
