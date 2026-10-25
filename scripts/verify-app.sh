#!/bin/bash
# Shared checks for the build product and the copy inside the installer.
set -euo pipefail

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    printf 'Usage: bash scripts/verify-app.sh <LanguageSwitcher.app> [expected-version]\n' >&2
    exit 2
fi
APP_PATH="$1"
PLIST="$APP_PATH/Contents/Info.plist"
if [ ! -f "$PLIST" ]; then
    printf 'Missing app bundle: %s\n' "$APP_PATH" >&2
    exit 1
fi
IDENTIFIER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$PLIST")"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST")"
if [ "$IDENTIFIER" != com.yikwing.LanguageSwitcher ]; then
    printf 'Unexpected app identifier: %s\n' "$IDENTIFIER" >&2
    exit 1
fi
if [ "$#" -eq 2 ] && [ "$VERSION" != "$2" ]; then
    printf 'App version %s does not match expected version %s; rebuild before packaging.\n' "$VERSION" "$2" >&2
    exit 1
fi
# Read the actual slices: Xcode's lipo versions parse -verify_arch differently.
ARCHITECTURES="$(xcrun lipo -archs "$APP_PATH/Contents/MacOS/LanguageSwitcher")"
for architecture in arm64 x86_64; do
    case " $ARCHITECTURES " in
        *" $architecture "*) ;;
        *) printf 'Missing %s architecture in %s (found: %s)\n' "$architecture" "$APP_PATH" "$ARCHITECTURES" >&2; exit 1 ;;
    esac
done
codesign --verify --deep --strict "$APP_PATH"
if [ ! -s "$APP_PATH/Contents/Resources/AppIcon.icns" ]; then
    printf 'Missing compiled app icon in %s\n' "$APP_PATH" >&2
    exit 1
fi
