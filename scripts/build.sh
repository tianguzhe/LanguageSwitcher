#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA="${LANGUAGE_SWITCHER_DERIVED_DATA:-$PROJECT_DIR/build/DerivedData}"
SOURCE_APP="$DERIVED_DATA/Build/Products/Release/LanguageSwitcher.app"
APP_PATH="$PROJECT_DIR/build/LanguageSwitcher.app"
ICON_MASTER="$PROJECT_DIR/LanguageSwitcher/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png"
BUILD_LOG="$PROJECT_DIR/build/build.log"
PYTHON="${LANGUAGE_SWITCHER_PYTHON:-python3}"
mkdir -p "$PROJECT_DIR/build"

if [ ! -f "$ICON_MASTER" ] || [ "$PROJECT_DIR/GenerateIcon.swift" -nt "$ICON_MASTER" ] || [ "$PROJECT_DIR/generate_icon.sh" -nt "$ICON_MASTER" ] \
    || ! "$PYTHON" "$PROJECT_DIR/Tests/check_assets.py" >/dev/null 2>&1; then
    bash "$PROJECT_DIR/generate_icon.sh"
fi
VERSION="$(bash "$PROJECT_DIR/scripts/app-version.sh")"
printf 'Building LanguageSwitcher %s (Apple Silicon + Intel)…\n' "$VERSION"
if ! xcodebuild -project "$PROJECT_DIR/LanguageSwitcher.xcodeproj" \
    -scheme LanguageSwitcher -configuration Release \
    -destination 'generic/platform=macOS' -derivedDataPath "$DERIVED_DATA" \
    ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO CODE_SIGNING_ALLOWED=NO \
    build > "$BUILD_LOG" 2>&1; then
    tail -n 80 "$BUILD_LOG" >&2
    exit 1
fi

# Sign and validate a fresh copy before replacing the last successful build.
STAGING_DIR="$(mktemp -d "$PROJECT_DIR/build/app.XXXXXX")"
trap 'rm -rf "$STAGING_DIR"' EXIT
ditto "$SOURCE_APP" "$STAGING_DIR/LanguageSwitcher.app"
codesign --force --sign - "$STAGING_DIR/LanguageSwitcher.app"
bash "$PROJECT_DIR/scripts/verify-app.sh" "$STAGING_DIR/LanguageSwitcher.app" "$VERSION"
rm -rf "$APP_PATH"
mv "$STAGING_DIR/LanguageSwitcher.app" "$APP_PATH"
printf 'Built: %s\n' "$APP_PATH"
