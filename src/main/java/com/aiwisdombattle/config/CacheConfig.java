package com.aiwisdombattle.config;

import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.cache.RedisCacheConfiguration;
import org.springframework.data.redis.cache.RedisCacheManager;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.serializer.GenericJackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.RedisSerializationContext;

import java.time.Duration;
import java.util.Map;

@Configuration
@EnableCaching
public class CacheConfig {

    /** Cache nodes published trong 10 phút */
    public static final String NODES_BY_DOMAIN = "nodesByDomain";
    /** Cache danh sách tất cả node trong 10 phút */
    public static final String ALL_NODES       = "allNodes";

    @Bean
    public RedisCacheManager cacheManager(RedisConnectionFactory factory) {
        var jsonSerializer = new GenericJackson2JsonRedisSerializer();
        var jsonConfig = RedisCacheConfiguration.defaultCacheConfig()
            .serializeValuesWith(
                RedisSerializationContext.SerializationPair.fromSerializer(jsonSerializer))
            .disableCachingNullValues();

        return RedisCacheManager.builder(factory)
            .withInitialCacheConfigurations(Map.of(
                NODES_BY_DOMAIN, jsonConfig.entryTtl(Duration.ofMinutes(10)),
                ALL_NODES,       jsonConfig.entryTtl(Duration.ofMinutes(10))
            ))
            .cacheDefaults(jsonConfig.entryTtl(Duration.ofMinutes(5)))
            .build();
    }
}
