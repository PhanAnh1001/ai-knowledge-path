package com.aiwisdombattle.repository;

import com.aiwisdombattle.domain.entity.KnowledgeNode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface KnowledgeNodeRepository extends JpaRepository<KnowledgeNode, UUID> {

    List<KnowledgeNode> findByDomainAndPublishedTrue(String domain);

    /**
     * Lấy các node chưa học, sắp xếp theo curiosity_score giảm dần.
     * Dùng để seed gợi ý cho người dùng mới.
     */
    @Query("""
        SELECT k FROM KnowledgeNode k
        WHERE k.published = true
          AND k.domain = :domain
          AND k.id NOT IN :seenIds
        ORDER BY k.curiosityScore DESC, k.difficulty ASC
        """)
    List<KnowledgeNode> findUnseenByDomain(
        @Param("domain") String domain,
        @Param("seenIds") List<UUID> seenIds
    );
}
