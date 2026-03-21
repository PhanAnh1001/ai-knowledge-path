package com.aiwisdombattle.service;

import com.aiwisdombattle.config.CacheConfig;
import com.aiwisdombattle.domain.entity.KnowledgeNode;
import com.aiwisdombattle.repository.KnowledgeNodeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

/**
 * Service quản lý KnowledgeNode với caching Redis.
 * Cache các published node theo domain (TTL 10 phút).
 * Per-user filtering (seenIds) vẫn được áp dụng sau khi lấy từ cache.
 */
@Service
@RequiredArgsConstructor
public class KnowledgeNodeService {

    private final KnowledgeNodeRepository nodeRepository;

    /** Lấy tất cả published node theo domain — kết quả được cache 10 phút. */
    @Cacheable(value = CacheConfig.NODES_BY_DOMAIN, key = "#domain")
    public List<KnowledgeNode> getPublishedByDomain(String domain) {
        return nodeRepository.findByDomainAndPublishedTrue(domain);
    }

    /** Lấy tất cả published node (mọi domain) — kết quả được cache 10 phút. */
    @Cacheable(value = CacheConfig.ALL_NODES, key = "'all'")
    public List<KnowledgeNode> getAllPublished() {
        return nodeRepository.findByPublishedTrue();
    }

    /** Xóa cache khi có thay đổi published state. */
    @CacheEvict(value = {CacheConfig.NODES_BY_DOMAIN, CacheConfig.ALL_NODES}, allEntries = true)
    public void evictNodeCaches() {
        // triggered externally when nodes are published/unpublished
    }

    /** Lọc bỏ những node đã học — áp dụng sau khi lấy từ cache. */
    public List<KnowledgeNode> filterUnseen(List<KnowledgeNode> nodes, List<UUID> seenIds) {
        if (seenIds.isEmpty()) return nodes;
        return nodes.stream()
            .filter(n -> !seenIds.contains(n.getId()))
            .toList();
    }
}
