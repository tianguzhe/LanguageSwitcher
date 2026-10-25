#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/LanguageSwitcher-tests.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT
cd "$PROJECT_DIR"

for script in build_universal.sh create_dmg.sh generate_icon.sh scripts/*.sh; do
    bash -n "$script"
done

"${LANGUAGE_SWITCHER_PYTHON:-python3}" Tests/check_assets.py

xcrun swiftc -swift-version 5 \
    -target "$(uname -m)-apple-macos14.0" \
    -module-cache-path "$TEST_DIR/ModuleCache" \
    LanguageSwitcher/AppLanguageScanner.swift Tests/AppLanguageScannerTests.swift \
    -o "$TEST_DIR/ScannerTests"
"$TEST_DIR/ScannerTests"
