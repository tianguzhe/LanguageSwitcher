#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(xcodebuild -project "$PROJECT_DIR/LanguageSwitcher.xcodeproj" \
    -scheme LanguageSwitcher -configuration Release -destination 'generic/platform=macOS' -showBuildSettings \
    CODE_SIGNING_ALLOWED=NO | awk '$1 == "MARKETING_VERSION" && $2 == "=" { version = $3 } END { if (version == "") exit 1; print version }')"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
    echo "Invalid MARKETING_VERSION: $VERSION" >&2
    exit 1
fi

printf '%s\n' "$VERSION"
