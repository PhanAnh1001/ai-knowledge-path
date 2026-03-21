#!/usr/bin/env bash
# Script cập nhật tài liệu tích lũy sau mỗi phiên làm việc.
# Ghi thêm vào docs/PROJECT_LOG.md (không tạo file mới mỗi phiên).

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="$REPO_DIR/docs/PROJECT_LOG.md"

# Đọc session_id từ stdin JSON
SESSION_ID=$(jq -r '.session_id // "unknown"' - 2>/dev/null || echo "unknown")
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')
DATE=$(date +%Y-%m-%d)

# Thu thập thông tin git
cd "$REPO_DIR"
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

# Commit mới nhất kể từ lần cập nhật log trước (dựa trên git log)
# Lấy các commit chưa được ghi vào log: so sánh với nội dung hiện tại
LAST_LOGGED=$(grep -m1 'commit\b' "$LOG_FILE" 2>/dev/null | grep -oP '[a-f0-9]{7}' | head -1 || echo "")
if [ -n "$LAST_LOGGED" ]; then
    NEW_COMMITS=$(git log --oneline "${LAST_LOGGED}..HEAD" 2>/dev/null || git log --oneline -10)
else
    NEW_COMMITS=$(git log --oneline -10 2>/dev/null || echo "(no commits)")
fi

# Nếu không có commit mới, vẫn ghi entry để theo dõi phiên làm việc
if [ -z "$NEW_COMMITS" ]; then
    NEW_COMMITS="(không có commit mới trong phiên này)"
fi

GIT_STATUS=$(git status --short 2>/dev/null || echo "")

# Tạo file nếu chưa tồn tại với header
if [ ! -f "$LOG_FILE" ]; then
    mkdir -p "$(dirname "$LOG_FILE")"
    cat > "$LOG_FILE" <<'HEADER'
# AI Wisdom Battle — Nhật ký Dự án

File này được cập nhật tự động sau mỗi phiên làm việc với Claude.
Dùng làm cơ sở cho các cuộc thảo luận, lên kế hoạch và triển khai tiếp theo.

---

HEADER
fi

# Chuẩn bị nội dung entry mới
ENTRY=$(cat <<EOF

## Phiên $DATE — $BRANCH

- **Thời điểm**: $DATETIME
- **Session**: \`${SESSION_ID:0:12}\`
- **Branch**: \`$BRANCH\`

### Công việc đã thực hiện (commits mới)

\`\`\`
$NEW_COMMITS
\`\`\`
EOF
)

# Thêm trạng thái working tree nếu có thay đổi chưa commit
if [ -n "$GIT_STATUS" ]; then
    ENTRY="$ENTRY

### Thay đổi chưa commit

\`\`\`
$GIT_STATUS
\`\`\`"
fi

ENTRY="$ENTRY

---"

# Chèn entry mới ngay sau dòng "---" đầu tiên (sau header) để mới nhất ở trên
# Dùng Python để thao tác an toàn hơn sed với multiline
python3 - "$LOG_FILE" "$ENTRY" <<'PYEOF'
import sys

log_file = sys.argv[1]
new_entry = sys.argv[2]

with open(log_file, 'r', encoding='utf-8') as f:
    content = f.read()

# Tìm vị trí sau dòng "---" đầu tiên (header separator)
sep = '\n---\n'
idx = content.find(sep)
if idx != -1:
    insert_at = idx + len(sep)
    content = content[:insert_at] + new_entry + '\n' + content[insert_at:]
else:
    content = content + new_entry + '\n'

with open(log_file, 'w', encoding='utf-8') as f:
    f.write(content)
PYEOF

# Auto-commit log (không push — để người dùng quyết định khi nào push)
cd "$REPO_DIR"
git add "$LOG_FILE" 2>/dev/null || true
git diff --cached --quiet "$LOG_FILE" 2>/dev/null || \
    git commit -m "Update PROJECT_LOG: session $DATE ${SESSION_ID:0:8}" \
        --no-verify 2>/dev/null || true

echo "Đã cập nhật tài liệu: $LOG_FILE" >&2
