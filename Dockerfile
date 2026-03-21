# =============================================================================
# Multi-stage Dockerfile — AI Wisdom Battle Spring Boot
# Stage 1 (builder): compile + package với Maven
# Stage 2 (runtime): image tối giản chỉ chứa JAR
# =============================================================================

# ── Stage 1: builder ──────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /build

# Cache Maven dependencies trước (chỉ re-download khi pom.xml thay đổi)
COPY pom.xml .
RUN --mount=type=cache,target=/root/.m2 \
    mvn dependency:go-offline -B --quiet 2>/dev/null || true

# Copy source và build
COPY src ./src
RUN --mount=type=cache,target=/root/.m2 \
    mvn clean package -DskipTests -B -q

# Unpack layered JAR để tối ưu Docker layer cache
RUN java -Djarmode=layertools \
         -jar target/ai-wisdom-battle-*.jar extract --destination /build/extracted


# ── Stage 2: runtime ──────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre-alpine AS runtime

# Non-root user vì lý do bảo mật
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

WORKDIR /app

# Copy layered JAR theo thứ tự tăng dần tần suất thay đổi
COPY --from=builder /build/extracted/dependencies/          ./
COPY --from=builder /build/extracted/spring-boot-loader/    ./
COPY --from=builder /build/extracted/snapshot-dependencies/ ./
COPY --from=builder /build/extracted/application/           ./

EXPOSE 8080

ENV JAVA_OPTS="-XX:+UseContainerSupport \
               -XX:MaxRAMPercentage=75.0 \
               -Djava.security.egd=file:/dev/./urandom"

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS org.springframework.boot.loader.launch.JarLauncher"]
