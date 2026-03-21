#!/usr/bin/env bash
# Script ghi đè context mới nhất sau mỗi phiên làm việc.
# Xoá context cũ, chỉ giữ trạng thái hiện tại của dự án.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="$REPO_DIR/docs/PROJECT_LOG.md"

SESSION_ID=$(jq -r '.session_id // "unknown"' - 2>/dev/null || echo "unknown")
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')
DATE=$(date +%Y-%m-%d)

cd "$REPO_DIR"
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
GIT_LOG=$(git log --oneline -15 2>/dev/null || echo "(no commits)")
GIT_STATUS=$(git status --short 2>/dev/null || echo "")

mkdir -p "$(dirname "$LOG_FILE")"

# Ghi đè toàn bộ file — chỉ giữ context mới nhất
cat > "$LOG_FILE" <<EOF
# AI Wisdom Battle — Context Dự án

> Cập nhật lần cuối: $DATETIME
> Session: \`${SESSION_ID:0:12}\`
> Branch: \`$BRANCH\`

---

## Trạng thái hiện tại

### Các commit gần nhất

\`\`\`
$GIT_LOG
\`\`\`
EOF

if [ -n "$GIT_STATUS" ]; then
    cat >> "$LOG_FILE" <<EOF

### Thay đổi chưa commit

\`\`\`
$GIT_STATUS
\`\`\`
EOF
fi

cat >> "$LOG_FILE" <<'EOF'

---

## Ghi chú & Quyết định

<!-- Claude và người dùng ghi chú thủ công vào đây trong quá trình làm việc -->

EOF

# Auto-commit
git add "$LOG_FILE" 2>/dev/null || true
git diff --cached --quiet "$LOG_FILE" 2>/dev/null || \
    git commit -m "Update PROJECT_LOG: $DATE ${SESSION_ID:0:8}" \
        --no-verify 2>/dev/null || true

echo "Đã cập nhật context: $LOG_FILE" >&2
