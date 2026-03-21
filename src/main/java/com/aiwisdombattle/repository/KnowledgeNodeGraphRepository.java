package com.aiwisdombattle.repository;

import com.aiwisdombattle.domain.model.KnowledgeNodeGraph;
import org.springframework.data.neo4j.repository.Neo4jRepository;
import org.springframework.data.neo4j.repository.query.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface KnowledgeNodeGraphRepository extends Neo4jRepository<KnowledgeNodeGraph, String> {

    /**
     * Gợi ý 3 node tiếp theo sau khi hoàn thành một session.
     * Lọc bỏ các node đã học, sắp xếp theo weight giảm dần.
     */
    @Query("""
        MATCH (done:KnowledgeNode {id: $completedNodeId})-[r:LEADS_TO]->(next:KnowledgeNode)
        WHERE next.isPublished = true
          AND NOT next.id IN $seenIds
        RETURN next, r
        ORDER BY r.weight DESC
        LIMIT 3
        """)
    List<KnowledgeNodeGraph> findNextSuggestions(
        @Param("completedNodeId") String completedNodeId,
        @Param("seenIds") List<String> seenIds
    );

    /**
     * Lấy subgraph cho knowledge map visualization.
     */
    @Query("""
        MATCH (n:KnowledgeNode)
        WHERE n.id IN $seenIds
        WITH n
        MATCH (n)-[r:LEADS_TO|CROSS_DOMAIN]-(neighbor:KnowledgeNode)
        WHERE neighbor.isPublished = true
        RETURN n, r, neighbor
        LIMIT 100
        """)
    List<KnowledgeNodeGraph> findKnowledgeMapSubgraph(@Param("seenIds") List<String> seenIds);

    /**
     * Rabbit Hole Mode — chuỗi deep dive tối đa 3 bước.
     */
    @Query("""
        MATCH path = (start:KnowledgeNode {id: $nodeId})-[:DEEP_DIVE*1..3]->(end:KnowledgeNode)
        WHERE end.isPublished = true
        RETURN end
        ORDER BY length(path) ASC
        """)
    List<KnowledgeNodeGraph> findDeepDiveChain(@Param("nodeId") String nodeId);

    /**
     * Cross-domain surprises (Premium) — kết nối bất ngờ xuyên domain.
     */
    @Query("""
        MATCH (n:KnowledgeNode {id: $nodeId})-[r:CROSS_DOMAIN]-(other:KnowledgeNode)
        WHERE other.domain <> n.domain AND other.isPublished = true
        RETURN other, r
        ORDER BY rand()
        LIMIT 2
        """)
    List<KnowledgeNodeGraph> findCrossDomainSurprises(@Param("nodeId") String nodeId);
}
