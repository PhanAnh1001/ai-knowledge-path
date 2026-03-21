package com.aiwisdombattle.repository;

import com.aiwisdombattle.domain.entity.Session;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface SessionRepository extends JpaRepository<Session, UUID> {

    List<Session> findByUserIdOrderByStartedAtDesc(UUID userId);

    Optional<Session> findByUserIdAndKnowledgeNodeId(UUID userId, UUID nodeId);

    /**
     * Trả về danh sách ID các node mà user đã hoàn thành.
     * Dùng để lọc gợi ý tiếp theo trong Neo4j.
     */
    @Query("""
        SELECT s.knowledgeNode.id FROM Session s
        WHERE s.user.id = :userId
          AND s.status = 'COMPLETED'
        """)
    List<UUID> findCompletedNodeIdsByUserId(@Param("userId") UUID userId);
}
