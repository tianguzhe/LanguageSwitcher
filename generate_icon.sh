#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENERATOR_DIR="$(mktemp -d "${TMPDIR:-/tmp}/LanguageSwitcher-icon.XXXXXX")"
trap 'rm -rf "$GENERATOR_DIR"' EXIT
xcrun swiftc -module-cache-path "$GENERATOR_DIR/ModuleCache" \
    "$PROJECT_DIR/GenerateIcon.swift" -o "$GENERATOR_DIR/GenerateIcon"
"$GENERATOR_DIR/GenerateIcon" "$PROJECT_DIR/LanguageSwitcher/Assets.xcassets/AppIcon.appiconset"
