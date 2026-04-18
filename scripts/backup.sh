#!/bin/bash
# =============================================================================
# AI Knowledge Path — Backup Script
# Dump PostgreSQL → gzip → upload Oracle Object Storage (Always Free 20GB)
#
# Cài đặt cron (chạy mỗi ngày 2h sáng):
#   sudo -u deploy crontab -e
#   0 2 * * * /opt/ai-knowledge-path/scripts/backup.sh >> /var/log/awb-backup.log 2>&1
#
# Yêu cầu:
#   - OCI CLI đã cài và configured: oci setup config
#   - Bucket đã tạo trên Oracle Object Storage (xem DEPLOY-ORACLE.md Phần E)
#   - .env tồn tại tại /opt/ai-knowledge-path/.env
# =============================================================================

set -euo pipefail

APP_DIR="/opt/ai-knowledge-path"
BUCKET="awb-backups"
KEEP_DAYS=7    # giữ backup trong 7 ngày
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TMP_DIR=$(mktemp -d)

# Load env vars
# shellcheck disable=SC1091
source "${APP_DIR}/.env"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

# ── Cleanup khi thoát ────────────────────────────────────────────────────────
cleanup() { rm -rf "${TMP_DIR}"; }
trap cleanup EXIT

log "=== Backup bắt đầu: ${TIMESTAMP} ==="

# ── 1. Dump PostgreSQL ───────────────────────────────────────────────────────
PG_FILE="${TMP_DIR}/pg_${TIMESTAMP}.sql.gz"
log "Dumping PostgreSQL → ${PG_FILE}"
docker exec awb-postgres \
    pg_dump -U "${POSTGRES_USER}" "${POSTGRES_DB}" \
    | gzip -9 > "${PG_FILE}"
log "PostgreSQL dump size: $(du -sh "${PG_FILE}" | cut -f1)"

# ── 2. Upload lên Oracle Object Storage ──────────────────────────────────────
log "Uploading to Oracle Object Storage bucket: ${BUCKET}"
oci os object put \
    --bucket-name "${BUCKET}" \
    --file "${PG_FILE}" \
    --name "postgres/pg_${TIMESTAMP}.sql.gz" \
    --force \
    --no-retry

log "Upload thành công: postgres/pg_${TIMESTAMP}.sql.gz"

# ── 3. Xóa backup cũ hơn KEEP_DAYS ngày ─────────────────────────────────────
log "Xóa backup cũ hơn ${KEEP_DAYS} ngày..."
CUTOFF=$(date -d "-${KEEP_DAYS} days" +%Y-%m-%dT%H:%M:%S 2>/dev/null \
    || date -v -${KEEP_DAYS}d +%Y-%m-%dT%H:%M:%S)    # macOS fallback

oci os object list \
    --bucket-name "${BUCKET}" \
    --prefix "postgres/" \
    --query "data[?\"time-created\" < '${CUTOFF}'].name" \
    --output json \
    | jq -r '.[]' \
    | while read -r obj; do
        log "Deleting old backup: ${obj}"
        oci os object delete \
            --bucket-name "${BUCKET}" \
            --object-name "${obj}" \
            --force
    done

log "=== Backup hoàn tất ==="
