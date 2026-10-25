#!/bin/bash
# Create and push a version tag; GitHub Actions builds and publishes the release.
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf 'Run this script from a Git checkout with an origin remote.\n' >&2
    exit 1
fi
if [ "$(git branch --show-current)" != main ]; then
    printf 'Switch to main before releasing.\n' >&2
    exit 1
fi
if [ -n "$(git status --porcelain)" ]; then
    printf 'Commit or stash changes before releasing.\n' >&2
    exit 1
fi
VERSION="$(bash scripts/app-version.sh)"
TAG="v$VERSION"
if git rev-parse --verify --quiet "refs/tags/$TAG" >/dev/null; then
    printf 'Tag %s already exists. Update MARKETING_VERSION before releasing.\n' "$TAG" >&2
    exit 1
fi
bash scripts/test.sh
git tag -a "$TAG" -m "LanguageSwitcher $TAG"
if ! git push --atomic origin main "refs/tags/$TAG"; then
    git tag -d "$TAG" >/dev/null
    printf 'Push failed; removed the local tag %s so you can retry.\n' "$TAG" >&2
    exit 1
fi
printf 'Pushed %s. GitHub Actions will build the DMG and publish the release.\n' "$TAG"
