package com.aiwisdombattle.repository;

import com.aiwisdombattle.domain.entity.UserNodeProgress;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserNodeProgressRepository extends JpaRepository<UserNodeProgress, UUID> {

    Optional<UserNodeProgress> findByUserIdAndNodeId(UUID userId, UUID nodeId);

    /** Lấy danh sách nodes cần ôn hôm nay hoặc quá hạn */
    List<UserNodeProgress> findByUserIdAndNextReviewDateLessThanEqual(UUID userId, LocalDate date);
}
