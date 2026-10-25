#!/bin/bash
# Repackage the existing signed build without compiling it again.
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$PROJECT_DIR/scripts/package-dmg.sh" --skip-build "$@"
