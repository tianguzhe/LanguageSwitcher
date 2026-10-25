#!/bin/bash
# Build and package a Universal app using the same script as GitHub Actions.
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$PROJECT_DIR/scripts/package-dmg.sh" "$@"
