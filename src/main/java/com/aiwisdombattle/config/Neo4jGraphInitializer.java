package com.aiwisdombattle.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.neo4j.core.Neo4jClient;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

/**
 * Khởi tạo knowledge graph trong Neo4j khi ứng dụng start.
 * Dùng MERGE để bảo đảm idempotent — an toàn khi chạy nhiều lần.
 *
 * Kích hoạt bằng: app.neo4j.init=true trong application.yml
 */
@Component
@ConditionalOnProperty(name = "app.neo4j.init", havingValue = "true")
@RequiredArgsConstructor
@Slf4j
public class Neo4jGraphInitializer implements ApplicationRunner {

    private final Neo4jClient neo4jClient;

    // ── Node IDs (đồng bộ với PostgreSQL seed data) ────────────────────────────
    // Nature (V5): 11111111-0000-0000-0000-00000000000{1..10}
    private static final List<String> NATURE_IDS = List.of(
        "11111111-0000-0000-0000-000000000001",
        "11111111-0000-0000-0000-000000000002",
        "11111111-0000-0000-0000-000000000003",
        "11111111-0000-0000-0000-000000000004",
        "11111111-0000-0000-0000-000000000005",
        "11111111-0000-0000-0000-000000000006",
        "11111111-0000-0000-0000-000000000007",
        "11111111-0000-0000-0000-000000000008",
        "11111111-0000-0000-0000-000000000009",
        "11111111-0000-0000-0000-000000000010"
    );

    // Technology (V7): 22222222-0000-0000-0000-00000000000{1..7}
    private static final List<String> TECHNOLOGY_IDS = List.of(
        "22222222-0000-0000-0000-000000000001",
        "22222222-0000-0000-0000-000000000002",
        "22222222-0000-0000-0000-000000000003",
        "22222222-0000-0000-0000-000000000004",
        "22222222-0000-0000-0000-000000000005",
        "22222222-0000-0000-0000-000000000006",
        "22222222-0000-0000-0000-000000000007"
    );

    // Creative (V8): 44444444-0000-0000-0000-00000000000{1..6}
    private static final List<String> CREATIVE_IDS = List.of(
        "44444444-0000-0000-0000-000000000001",
        "44444444-0000-0000-0000-000000000002",
        "44444444-0000-0000-0000-000000000003",
        "44444444-0000-0000-0000-000000000004",
        "44444444-0000-0000-0000-000000000005",
        "44444444-0000-0000-0000-000000000006"
    );

    // History (V6): 55555555-0000-0000-0000-00000000000{1..7}
    private static final List<String> HISTORY_IDS = List.of(
        "55555555-0000-0000-0000-000000000001",
        "55555555-0000-0000-0000-000000000002",
        "55555555-0000-0000-0000-000000000003",
        "55555555-0000-0000-0000-000000000004",
        "55555555-0000-0000-0000-000000000005",
        "55555555-0000-0000-0000-000000000006",
        "55555555-0000-0000-0000-000000000007"
    );

    // Cross-domain pairs: {fromId, toId, concept, insight}
    private static final List<CrossDomainEntry> CROSS_DOMAIN_PAIRS = List.of(
        // Photosynthesis (Nature) ↔ GPS (Technology): both use light/energy physics
        new CrossDomainEntry(
            "11111111-0000-0000-0000-000000000001",
            "22222222-0000-0000-0000-000000000001",
            "energy_conversion",
            "Ánh sáng vừa là nguồn thức ăn của cây, vừa là 'thước đo' khoảng cách của GPS"
        ),
        // Monarch Butterfly navigation (Nature) ↔ GPS (Technology): both solve navigation
        new CrossDomainEntry(
            "11111111-0000-0000-0000-000000000002",
            "22222222-0000-0000-0000-000000000001",
            "navigation_systems",
            "Con bướm và GPS đều giải cùng một bài toán: tìm đường không có bản đồ"
        ),
        // Marie Curie (History) ↔ Nature nodes: radioactivity is in nature
        new CrossDomainEntry(
            "55555555-0000-0000-0000-000000000001",
            "11111111-0000-0000-0000-000000000001",
            "scientific_discovery",
            "Curie khám phá radioactivity giống như cây khám phá ánh sáng — cả hai biến thứ vô hình thành hữu hình"
        ),
        // History figure (Leonardo da Vinci = History 2) ↔ Creative: art + science
        new CrossDomainEntry(
            "55555555-0000-0000-0000-000000000002",
            "44444444-0000-0000-0000-000000000001",
            "art_and_science",
            "Da Vinci không thấy ranh giới giữa nghệ thuật và khoa học — jazz cũng vậy"
        ),
        // Jazz (Creative 1) ↔ Technology: pattern recognition and AI
        new CrossDomainEntry(
            "44444444-0000-0000-0000-000000000001",
            "22222222-0000-0000-0000-000000000003",
            "pattern_and_creativity",
            "Jazz improvisation và thuật toán đều làm việc với patterns — chỉ khác ở nguồn cảm hứng"
        ),
        // Creative → History: art reflects history
        new CrossDomainEntry(
            "44444444-0000-0000-0000-000000000002",
            "55555555-0000-0000-0000-000000000003",
            "culture_and_history",
            "Nghệ thuật là nhật ký của lịch sử — mỗi tác phẩm kể câu chuyện thời đại nó"
        )
    );

    @Override
    public void run(ApplicationArguments args) {
        log.info("Neo4jGraphInitializer: bắt đầu khởi tạo knowledge graph...");
        try {
            mergeNodes(NATURE_IDS, "NATURE");
            mergeNodes(TECHNOLOGY_IDS, "TECHNOLOGY");
            mergeNodes(CREATIVE_IDS, "CREATIVE");
            mergeNodes(HISTORY_IDS, "HISTORY");

            createLeadsToChain(NATURE_IDS, 0.85);
            createLeadsToChain(TECHNOLOGY_IDS, 0.85);
            createLeadsToChain(CREATIVE_IDS, 0.8);
            createLeadsToChain(HISTORY_IDS, 0.8);

            createCrossDomainRelationships();

            log.info("Neo4jGraphInitializer: hoàn tất. {} domains, {} cross-domain links.",
                4, CROSS_DOMAIN_PAIRS.size());
        } catch (Exception e) {
            log.warn("Neo4jGraphInitializer: không thể kết nối Neo4j — {}. Graph sẽ trống.", e.getMessage());
        }
    }

    /** Merge KnowledgeNode nodes theo danh sách IDs */
    private void mergeNodes(List<String> ids, String domain) {
        for (String id : ids) {
            neo4jClient.query(
                "MERGE (n:KnowledgeNode {id: $id}) SET n.domain = $domain, n.isPublished = true"
            ).bindAll(Map.of("id", id, "domain", domain)).run();
        }
        log.debug("Neo4j: merged {} nodes for domain {}", ids.size(), domain);
    }

    /** Tạo LEADS_TO chain: node[0]→node[1]→...→node[n-1] */
    private void createLeadsToChain(List<String> ids, double baseWeight) {
        for (int i = 0; i < ids.size() - 1; i++) {
            String fromId = ids.get(i);
            String toId   = ids.get(i + 1);
            double weight = baseWeight - (i * 0.02);   // giảm nhẹ weight theo độ xa
            neo4jClient.query("""
                MATCH (a:KnowledgeNode {id: $fromId}), (b:KnowledgeNode {id: $toId})
                MERGE (a)-[r:LEADS_TO]->(b)
                SET r.weight = $weight, r.relationVi = 'Khám phá tiếp'
                """)
                .bindAll(Map.of("fromId", fromId, "toId", toId, "weight", weight))
                .run();
        }
    }

    /** Tạo CROSS_DOMAIN relationships từ danh sách cặp được định nghĩa sẵn */
    private void createCrossDomainRelationships() {
        for (CrossDomainEntry entry : CROSS_DOMAIN_PAIRS) {
            neo4jClient.query("""
                MATCH (a:KnowledgeNode {id: $fromId}), (b:KnowledgeNode {id: $toId})
                MERGE (a)-[r:CROSS_DOMAIN]->(b)
                SET r.concept = $concept, r.insightVi = $insight
                """)
                .bindAll(Map.of(
                    "fromId", entry.fromId(),
                    "toId",   entry.toId(),
                    "concept", entry.concept(),
                    "insight", entry.insight()
                ))
                .run();
        }
        log.debug("Neo4j: created {} cross-domain relationships", CROSS_DOMAIN_PAIRS.size());
    }

    private record CrossDomainEntry(String fromId, String toId, String concept, String insight) {}
}
