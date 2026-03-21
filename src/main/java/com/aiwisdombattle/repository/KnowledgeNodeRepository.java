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
     * Lấy node chưa học theo domain, sắp xếp theo curiosity_score.
     * Dùng coalesce trick để tránh lỗi "IN ()" với list rỗng:
     * khi seenIds rỗng, điều kiện NOT IN luôn đúng.
     */
    @Query("""
        SELECT k FROM KnowledgeNode k
        WHERE k.published = true
          AND k.domain = :domain
          AND (:#{#seenIds.size()} = 0 OR k.id NOT IN :seenIds)
        ORDER BY k.curiosityScore DESC, k.difficulty ASC
        """)
    List<KnowledgeNode> findUnseenByDomain(
        @Param("domain") String domain,
        @Param("seenIds") List<UUID> seenIds
    );

    /**
     * Lấy tất cả node chưa học (không lọc domain), dùng khi không có domain filter.
     */
    @Query("""
        SELECT k FROM KnowledgeNode k
        WHERE k.published = true
          AND (:#{#seenIds.size()} = 0 OR k.id NOT IN :seenIds)
        ORDER BY k.curiosityScore DESC, k.difficulty ASC
        """)
    List<KnowledgeNode> findAllUnseen(@Param("seenIds") List<UUID> seenIds);
}
