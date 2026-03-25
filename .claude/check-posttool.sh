#!/usr/bin/env bash
# PostToolUse hook — quick build check after editing Go or TypeScript files.
# Reads tool input JSON from stdin, exits 2 on error to wake model (asyncRewake).

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FILE=$(jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")
ERRORS=""

# --- Go file → go build ./... ---
if echo "$FILE" | grep -qE 'backend-go/.*\.go$'; then
    OUT=$(cd "$REPO/backend-go" && go build ./... 2>&1) || {
        MSG=$(echo "$OUT" | head -5 | tr '\n' '; ' | sed 's/"/\\"/g')
        ERRORS="Go build FAILED: $MSG"
    }
fi

# --- TypeScript file → tsc --noEmit ---
if echo "$FILE" | grep -qE 'frontend/src/.*\.(ts|tsx)$'; then
    TSC="$REPO/frontend/node_modules/.bin/tsc"
    if [ -f "$TSC" ]; then
        OUT=$(cd "$REPO/frontend" && "$TSC" --noEmit 2>&1) || {
            MSG=$(echo "$OUT" | head -5 | tr '\n' '; ' | sed 's/"/\\"/g')
            [ -n "$ERRORS" ] && ERRORS="$ERRORS | "
            ERRORS="${ERRORS}TypeScript FAILED: $MSG"
        }
    fi
fi

if [ -n "$ERRORS" ]; then
    printf '{"systemMessage": "[Build check] %s"}\n' "$ERRORS"
    exit 2  # asyncRewake: wakes model so it can fix the error
fi
