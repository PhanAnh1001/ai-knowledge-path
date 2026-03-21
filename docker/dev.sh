#!/usr/bin/env bash
# =============================================================================
# Script tiện ích cho môi trường dev
# Sử dụng: bash docker/dev.sh <command>
# =============================================================================

set -euo pipefail

COMPOSE="docker compose"
ENV_FILE=".env"

check_env() {
    if [ ! -f "$ENV_FILE" ]; then
        echo "Chưa có file .env. Tạo từ template..."
        cp .env.example .env
        echo "Đã tạo .env — hãy điền mật khẩu thật trước khi tiếp tục."
        exit 1
    fi
}

case "${1:-help}" in

    # Khởi động chỉ infra (postgres + neo4j + redis), không build app
    infra)
        check_env
        echo "Khởi động infra services..."
        $COMPOSE up -d postgres neo4j redis
        echo "Chờ healthcheck..."
        $COMPOSE ps
        ;;

    # Khởi động chỉ backend (infra + app + adaptive-engine, không build frontend)
    backend)
        check_env
        echo "Khởi động backend services..."
        $COMPOSE up -d postgres neo4j redis app adaptive-engine
        $COMPOSE ps
        ;;

    # Khởi động toàn bộ (bao gồm build app)
    up)
        check_env
        echo "Build và khởi động toàn bộ..."
        $COMPOSE up -d --build
        ;;

    # Dừng tất cả
    down)
        $COMPOSE down
        ;;

    # Xoá toàn bộ volumes (reset dữ liệu)
    reset)
        echo "CẢNH BÁO: Thao tác này sẽ xoá toàn bộ dữ liệu local!"
        read -rp "Xác nhận (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            $COMPOSE down -v
            echo "Đã xoá toàn bộ volumes."
        else
            echo "Đã huỷ."
        fi
        ;;

    # Xem log adaptive-engine
    logs-engine)
        $COMPOSE logs -f adaptive-engine
        ;;

    # Xem log frontend
    logs-fe)
        $COMPOSE logs -f frontend
        ;;

    # Xem log app (hoặc service bất kỳ: bash dev.sh logs neo4j)
    logs)
        $COMPOSE logs -f "${2:-app}"
        ;;

    # Kết nối psql
    psql)
        check_env
        source "$ENV_FILE"
        $COMPOSE exec postgres psql -U "${POSTGRES_USER:-postgres}" -d "${POSTGRES_DB:-ai_wisdom_battle}"
        ;;

    # Kết nối redis-cli
    redis)
        check_env
        source "$ENV_FILE"
        $COMPOSE exec redis redis-cli -a "${REDIS_PASSWORD:-redis_dev}"
        ;;

    # Chạy Neo4j seed thủ công
    seed-neo4j)
        check_env
        echo "Chạy Neo4j seeder..."
        $COMPOSE run --rm neo4j-seeder
        ;;

    # Kiểm tra health toàn bộ services
    status)
        $COMPOSE ps
        ;;

    help|*)
        cat <<EOF
Sử dụng: bash docker/dev.sh <command>

  infra        Khởi động postgres + neo4j + redis (không build app)
  backend      Khởi động backend: infra + app + adaptive-engine
  up           Build và khởi động toàn bộ (bao gồm frontend)
  down         Dừng tất cả containers
  reset        Xoá toàn bộ containers + volumes (mất dữ liệu!)
  logs [svc]   Xem log (mặc định: app)
  logs-engine  Xem log adaptive-engine
  logs-fe      Xem log frontend
  psql         Mở psql shell
  redis        Mở redis-cli
  seed-neo4j   Chạy Neo4j seed script thủ công
  status       Kiểm tra trạng thái các services
EOF
        ;;
esac
