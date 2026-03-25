#!/usr/bin/env bash
# Stop hook — comprehensive code check before task ends.
# Runs Go build + TypeScript type check. Outputs systemMessage on failure.

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=()

# --- Go build ---
if command -v go &>/dev/null && [ -d "$REPO/backend-go" ]; then
    OUT=$(cd "$REPO/backend-go" && go build ./... 2>&1) || {
        MSG=$(echo "$OUT" | head -5 | tr '\n' '; ')
        ERRORS+=("Go build: $MSG")
    }
fi

# --- TypeScript ---
TSC="$REPO/frontend/node_modules/.bin/tsc"
if [ -f "$TSC" ]; then
    OUT=$(cd "$REPO/frontend" && "$TSC" --noEmit 2>&1) || {
        MSG=$(echo "$OUT" | head -5 | tr '\n' '; ')
        ERRORS+=("TypeScript: $MSG")
    }
fi

if [ ${#ERRORS[@]} -gt 0 ]; then
    COMBINED=$(printf '%s | ' "${ERRORS[@]}")
    COMBINED="${COMBINED% | }"
    ESCAPED=$(printf '%s' "$COMBINED" | sed 's/\\/\\\\/g; s/"/\\"/g')
    printf '{"systemMessage": "[Code check FAILED] %s — Fix before reporting done."}\n' "$ESCAPED"
fi
# Silent on success — no output needed
