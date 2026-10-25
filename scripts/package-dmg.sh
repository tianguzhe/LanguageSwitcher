#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
usage() {
    printf 'Usage: bash scripts/package-dmg.sh [--skip-build] [<LanguageSwitcher.app> [<output.dmg>]]\n'
}
SKIP_BUILD=false
POSITIONAL=()
while [ "$#" -gt 0 ]; do
    case "$1" in
        --skip-build) SKIP_BUILD=true ;;
        -h|--help) usage; exit 0 ;;
        --) shift; POSITIONAL+=("$@"); break ;;
        -*) usage >&2; exit 2 ;;
        *) POSITIONAL+=("$1") ;;
    esac
    shift
done
if [ "${#POSITIONAL[@]}" -gt 2 ]; then
    usage >&2
    exit 2
fi
# An explicit app is an existing build, just like create_dmg.sh --skip-build.
if [ "${#POSITIONAL[@]}" -gt 0 ]; then SKIP_BUILD=true; fi
APP_PATH="${POSITIONAL[0]:-$PROJECT_DIR/build/LanguageSwitcher.app}"
DMG_PATH="${POSITIONAL[1]:-$PROJECT_DIR/dist/LanguageSwitcher.dmg}"
case "$APP_PATH" in /*) ;; *) APP_PATH="$PWD/$APP_PATH" ;; esac
case "$DMG_PATH" in /*) ;; *) DMG_PATH="$PWD/$DMG_PATH" ;; esac
if [ "$(basename "$APP_PATH")" != LanguageSwitcher.app ] || [[ "$DMG_PATH" != *.dmg ]]; then
    printf 'Expected a LanguageSwitcher.app bundle and an output ending in .dmg.\n' >&2
    exit 2
fi
PYTHON="${LANGUAGE_SWITCHER_PYTHON:-python3}"
for tool in xcodebuild xcrun codesign hdiutil shasum "$PYTHON"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf 'Required tool not found: %s (install Xcode and Python 3.10+).\n' "$tool" >&2
        exit 1
    fi
done
"$PYTHON" -c 'import sys; assert sys.version_info >= (3, 10), "DMG packaging requires Python 3.10+"'
if [ "$SKIP_BUILD" = false ]; then
    bash "$PROJECT_DIR/scripts/build.sh"
fi
EXPECTED_VERSION="$(bash "$PROJECT_DIR/scripts/app-version.sh")"
bash "$PROJECT_DIR/scripts/verify-app.sh" "$APP_PATH" "$EXPECTED_VERSION"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"

ARTWORK_DIR="$PROJECT_DIR/build/dmg"
VENV_DIR="$PROJECT_DIR/build/dmg-venv"
mkdir -p "$ARTWORK_DIR" "$(dirname "$DMG_PATH")"
WORK_DIR="$(mktemp -d "$ARTWORK_DIR/package.XXXXXX")"
MOUNT_DIR=""
cleanup() {
    if [ -n "$MOUNT_DIR" ]; then
        hdiutil detach "$MOUNT_DIR" >/dev/null 2>&1 || true
        rmdir "$MOUNT_DIR" 2>/dev/null || true
    fi
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

if [ ! -x "$VENV_DIR/bin/python" ]; then
    "$PYTHON" -m venv "$VENV_DIR"
fi
# The requirements file is the only source of dependency versions. Retain pip's
# download cache so setup-python's cache also speeds up fresh CI environments.
if ! "$VENV_DIR/bin/python" - "$PROJECT_DIR/Tools/dmg-requirements.txt" <<'PY' >/dev/null 2>&1
from importlib.metadata import version
from pathlib import Path
import sys
for line in Path(sys.argv[1]).read_text().splitlines():
    line = line.strip()
    if line and not line.startswith('#'):
        name, expected = line.split('==', 1)
        assert version(name) == expected
PY
then
    "$VENV_DIR/bin/python" -m pip --disable-pip-version-check install \
        --prefer-binary -r "$PROJECT_DIR/Tools/dmg-requirements.txt"
fi

ARTWORK_TOOL="$ARTWORK_DIR/GenerateArtwork"
if [ ! -x "$ARTWORK_TOOL" ] || [ "$PROJECT_DIR/Tools/GenerateDMGArtwork.swift" -nt "$ARTWORK_TOOL" ]; then
    xcrun swiftc -parse-as-library -module-cache-path "$PROJECT_DIR/build/ModuleCache" \
        "$PROJECT_DIR/Tools/GenerateDMGArtwork.swift" -o "$ARTWORK_TOOL"
fi
# Load the compiled ICNS directly: actool may put large sizes only in Assets.car.
"$ARTWORK_TOOL" "$ARTWORK_DIR" "$VERSION" "$APP_PATH/Contents/Resources/AppIcon.icns"

printf 'Creating LanguageSwitcher %s drag-to-install DMG…\n' "$VERSION"
"$VENV_DIR/bin/dmgbuild" -s "$PROJECT_DIR/Tools/dmg-settings.py" \
    -D "app=$APP_PATH" -D "background=$ARTWORK_DIR/background.tiff" \
    -D "icon=$APP_PATH/Contents/Resources/AppIcon.icns" \
    LanguageSwitcher "$WORK_DIR/LanguageSwitcher.dmg"
hdiutil verify "$WORK_DIR/LanguageSwitcher.dmg"

MOUNT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/LanguageSwitcher-mount.XXXXXX")"
hdiutil attach "$WORK_DIR/LanguageSwitcher.dmg" -readonly -nobrowse -mountpoint "$MOUNT_DIR" >/dev/null
bash "$PROJECT_DIR/scripts/verify-app.sh" "$MOUNT_DIR/LanguageSwitcher.app" "$VERSION"
if [ "$(readlink "$MOUNT_DIR/Applications")" != /Applications ]; then
    printf 'Installer is missing the Applications shortcut.\n' >&2
    exit 1
fi
# Release the disk image before moving it, and publish only verified artifacts.
hdiutil detach "$MOUNT_DIR" >/dev/null
rmdir "$MOUNT_DIR"
MOUNT_DIR=""
mv -f "$WORK_DIR/LanguageSwitcher.dmg" "$DMG_PATH"
DMG_NAME="$(basename "$DMG_PATH")"
(cd "$(dirname "$DMG_PATH")" && shasum -a 256 "$DMG_NAME" > "$DMG_NAME.sha256")
(cd "$(dirname "$DMG_PATH")" && shasum -a 256 -c "$DMG_NAME.sha256")
printf 'Installer: %s\nChecksum: %s.sha256\n' "$DMG_PATH" "$DMG_PATH"
