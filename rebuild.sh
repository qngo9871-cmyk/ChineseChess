#!/bin/bash
# Full clean rebuild script for Chinese Chess Pro Classic
# Usage: ./rebuild.sh

set -e

echo "=== Cleaning build artifacts ==="
xcodebuild clean -project ChineseChess.xcodeproj -scheme ChineseChess -quiet 2>/dev/null || true

echo "=== Building for simulator ==="
xcodebuild -project ChineseChess.xcodeproj \
    -scheme ChineseChess \
    -destination 'generic/platform=iOS Simulator' \
    -quiet build

echo "=== Building for device (archive) ==="
xcodebuild -project ChineseChess.xcodeproj \
    -scheme ChineseChess \
    -destination 'generic/platform=iOS' \
    -quiet build

echo "=== BUILD SUCCEEDED ==="
echo "To archive for App Store: open Xcode → Product → Archive"
echo "Make sure target is 'Any iOS Device (arm64)'"
