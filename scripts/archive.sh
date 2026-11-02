#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${APPLE_TEAM_ID:?Missing APPLE_TEAM_ID}"
# Codemagic project counter is shared across workflows.
if [[ -z "${BUILD_NUMBER:-}" ]]; then
  : "${PROJECT_BUILD_NUMBER:?Missing build counter}"
  BUILD_NUMBER="$((PROJECT_BUILD_NUMBER + 1))"
fi
export BUILD_NUMBER
xcodegen generate
xcode-project use-profiles --project Somnio.xcodeproj --export-options-plist /tmp/somnio-export-options.plist
xcodebuild archive -project Somnio.xcodeproj -scheme Somnio \
  -destination 'generic/platform=iOS' -archivePath /tmp/Somnio.xcarchive \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" CURRENT_PROJECT_VERSION="$BUILD_NUMBER"
python3 scripts/check-archive.py /tmp/Somnio.xcarchive
xcodebuild -exportArchive -archivePath /tmp/Somnio.xcarchive \
  -exportOptionsPlist /tmp/somnio-export-options.plist -exportPath /tmp/somnio-export
