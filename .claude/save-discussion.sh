#!/usr/bin/env bash
# Script lưu kết quả thảo luận vào docs/discussions/
# Được gọi bởi Stop hook trong .claude/settings.json

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DISCUSSIONS_DIR="$REPO_DIR/docs/discussions"
mkdir -p "$DISCUSSIONS_DIR"

# Đọc session_id từ stdin JSON
SESSION_ID=$(jq -r '.session_id // "unknown"' - 2>/dev/null || echo "unknown")
DATE=$(date +%Y-%m-%d)
DATETIME=$(date +%Y-%m-%d_%H-%M-%S)
FILE="$DISCUSSIONS_DIR/$DATE-${SESSION_ID:0:8}.md"

# Thu thập thông tin git
cd "$REPO_DIR"
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
GIT_LOG=$(git log --oneline -10 2>/dev/null || echo "(no commits)")
GIT_STATUS=$(git status --short 2>/dev/null || echo "(clean)")
LAST_COMMIT_MSG=$(git log -1 --pretty=%B 2>/dev/null | head -5 || echo "(none)")

# Ghi file markdown
cat > "$FILE" <<EOF
# Phiên làm việc: $DATETIME

- **Session ID**: \`$SESSION_ID\`
- **Branch**: \`$BRANCH\`
- **Thời điểm kết thúc**: $(date '+%Y-%m-%d %H:%M:%S')

## Commit gần nhất

\`\`\`
$LAST_COMMIT_MSG
\`\`\`

## Lịch sử commit (10 commit gần nhất)

\`\`\`
$GIT_LOG
\`\`\`

## Trạng thái working tree khi kết thúc

\`\`\`
${GIT_STATUS:-"(không có thay đổi chưa commit)"}
\`\`\`
EOF

echo "Đã lưu kết quả thảo luận: $FILE" >&2
