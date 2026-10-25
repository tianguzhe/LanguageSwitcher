#!/bin/bash
# Preserve the command's exit code and expose useful failures in the Actions UI.
set -uo pipefail
if [ "$#" -lt 2 ]; then
    printf 'Usage: bash scripts/ci-annotate.sh <title> <command> [args...]\n' >&2
    exit 2
fi
TITLE="$1"
shift
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$PROJECT_DIR/build/logs"
LOG_NAME="$(printf '%s' "$TITLE" | LC_ALL=C tr -cs 'a-zA-Z0-9_-' '-')"
LOG_FILE="$PROJECT_DIR/build/logs/$LOG_NAME.log"
"$@" 2>&1 | tee "$LOG_FILE"
STATUS=${PIPESTATUS[0]}
if [ "$STATUS" -ne 0 ]; then
    DETAILS="$(awk 'tolower($0) ~ /error:|failed|fatal error|fail:/ { print }' "$LOG_FILE" | tail -n 40)"
    if [ -z "$DETAILS" ]; then DETAILS="$(tail -n 40 "$LOG_FILE")"; fi
    DETAILS=${DETAILS//'%'/'%25'}
    DETAILS=${DETAILS//$'\r'/'%0D'}
    DETAILS=${DETAILS//$'\n'/'%0A'}
    TITLE=${TITLE//'%'/'%25'}
    TITLE=${TITLE//$'\r'/'%0D'}
    TITLE=${TITLE//$'\n'/'%0A'}
    TITLE=${TITLE//':'/'%3A'}
    TITLE=${TITLE//','/'%2C'}
    printf '::error title=%s failed::%s\n' "$TITLE" "$DETAILS"
fi
exit "$STATUS"
