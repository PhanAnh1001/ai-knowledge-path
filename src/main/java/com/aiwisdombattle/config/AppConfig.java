package com.aiwisdombattle.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

import java.time.Duration;

@Configuration
public class AppConfig {

    @Bean
    public RestTemplate adaptiveEngineRestTemplate(
        RestTemplateBuilder builder,
        @Value("${app.adaptive-engine.url:http://localhost:8001}") String baseUrl
    ) {
        return builder
            .rootUri(baseUrl)
            .setConnectTimeout(Duration.ofSeconds(3))
            .setReadTimeout(Duration.ofSeconds(5))
            .build();
    }
}
