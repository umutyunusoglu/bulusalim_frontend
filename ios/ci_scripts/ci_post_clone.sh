#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo "Running Flutter iOS CI setup..."
echo "Project root: $PROJECT_ROOT"

if ! command -v flutter >/dev/null 2>&1; then
	echo "flutter is not available on PATH"
	exit 1
fi

flutter --version

echo "Fetching Flutter dependencies..."
flutter pub get

if [ -d "ios" ] && [ -f "ios/Podfile" ]; then
	echo "Installing CocoaPods dependencies..."
	cd ios
	pod install --repo-update
	cd "$PROJECT_ROOT"
fi

echo "iOS post-clone setup complete. Build will be handled by Xcode Cloud."