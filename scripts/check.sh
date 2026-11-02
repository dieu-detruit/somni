#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift test
xcodegen generate
xcodebuild archive -project Somnio.xcodeproj -scheme Somnio \
  -destination 'generic/platform=iOS' -archivePath /tmp/Somnio.xcarchive \
  CODE_SIGNING_ALLOWED=NO DEVELOPMENT_TEAM=
python3 scripts/check-archive.py /tmp/Somnio.xcarchive
