-- Migration 002: node_relations — replaces Neo4j graph storage
CREATE TABLE node_relations (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_node_id    UUID NOT NULL REFERENCES knowledge_nodes(id) ON DELETE CASCADE,
    to_node_id      UUID NOT NULL REFERENCES knowledge_nodes(id) ON DELETE CASCADE,
    relation_type   TEXT NOT NULL
                        CHECK (relation_type IN ('LEADS_TO','DEEP_DIVE','CROSS_DOMAIN')),
    weight          DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    relation_vi     TEXT,   -- label for LEADS_TO (e.g. "Khám phá tiếp")
    concept         TEXT,   -- shared concept for CROSS_DOMAIN
    insight_vi      TEXT,   -- explanation for CROSS_DOMAIN
    UNIQUE (from_node_id, to_node_id, relation_type)
);

CREATE INDEX idx_node_relations_from ON node_relations(from_node_id);
CREATE INDEX idx_node_relations_type ON node_relations(relation_type);
