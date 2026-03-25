#!/usr/bin/env bash
# Build check script — works in two contexts:
#   PostToolUse: stdin has tool input JSON with file_path → check only that file type
#   Stop:        stdin has session JSON (no file_path)   → check everything
#
# Exits 2 on failure so asyncRewake wakes the model (PostToolUse context).
# Outputs JSON systemMessage on failure.

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FILE=$(jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")
ERRORS=""

RUN_GO=false
RUN_TS=false

if [ -n "$FILE" ]; then
    # PostToolUse: check only the edited file's language
    echo "$FILE" | grep -qE 'backend-go/.*\.go$'          && RUN_GO=true
    echo "$FILE" | grep -qE 'frontend/src/.*\.(ts|tsx)$'  && RUN_TS=true
else
    # Stop: check everything present
    command -v go &>/dev/null && [ -d "$REPO/backend-go" ] && RUN_GO=true
    [ -f "$REPO/frontend/node_modules/.bin/tsc" ]          && RUN_TS=true
fi

if $RUN_GO; then
    OUT=$(cd "$REPO/backend-go" && go build ./... 2>&1) || {
        MSG=$(echo "$OUT" | head -5 | tr '\n' '; ' | sed 's/"/\\"/g')
        ERRORS="Go build FAILED: $MSG"
    }
fi

if $RUN_TS; then
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
    exit 2
fi
