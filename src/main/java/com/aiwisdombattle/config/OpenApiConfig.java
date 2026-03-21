package com.aiwisdombattle.config;

import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
@SecurityScheme(
    name = "bearerAuth",
    type = SecuritySchemeType.HTTP,
    scheme = "bearer",
    bearerFormat = "JWT"
)
public class OpenApiConfig {

    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("AI Wisdom Battle API")
                .description("API cho hệ thống học kiến thức thích nghi — sessions, knowledge graph, adaptive scoring")
                .version("v1")
                .contact(new Contact()
                    .name("AI Wisdom Battle Team")
                    .email("dev@aiwisdombattle.com")))
            .servers(List.of(
                new Server().url("http://localhost:8080").description("Local dev"),
                new Server().url("https://api.aiwisdombattle.com").description("Production")
            ));
    }
}
