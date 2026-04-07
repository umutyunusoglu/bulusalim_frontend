#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo "Running Flutter iOS CI setup..."
echo "Project root: $PROJECT_ROOT"

resolve_flutter() {
	if command -v flutter >/dev/null 2>&1; then
		return 0
	fi

	# Preferred: FLUTTER_ROOT provided by CI environment.
	if [ -n "${FLUTTER_ROOT:-}" ] && [ -x "$FLUTTER_ROOT/bin/flutter" ]; then
		export PATH="$FLUTTER_ROOT/bin:$PATH"
		return 0
	fi

	# Fallback common install locations.
	for candidate in \
		"$HOME/flutter/bin/flutter" \
		"/opt/homebrew/Caskroom/flutter/latest/flutter/bin/flutter" \
		"/usr/local/Caskroom/flutter/latest/flutter/bin/flutter" \
		"/Applications/flutter/bin/flutter"
	do
		if [ -x "$candidate" ]; then
			export PATH="$(dirname "$candidate"):$PATH"
			return 0
		fi
	done

	return 1
}

if ! resolve_flutter; then
	echo "flutter is not available on PATH"
	echo "Set FLUTTER_ROOT in Xcode Cloud Environment Variables, e.g.:"
	echo "  FLUTTER_ROOT=/Applications/flutter"
	exit 1
fi

flutter --version

echo "Fetching Flutter dependencies (lockfile-enforced)..."
if flutter pub get --help 2>/dev/null | grep -q -- "--enforce-lockfile"; then
	flutter pub get --enforce-lockfile
else
	echo "WARNING: This Flutter version does not support --enforce-lockfile; falling back to flutter pub get"
	flutter pub get
fi

if [ -d "ios" ] && [ -f "ios/Podfile" ]; then
	echo "Installing CocoaPods dependencies (deployment mode)..."
	cd ios
	pod install --deployment
	if ! diff -q Podfile.lock Pods/Manifest.lock >/dev/null 2>&1; then
		echo "ERROR: CocoaPods lockfiles are out of sync after install."
		echo "Run 'cd ios && pod install' locally and commit Podfile.lock."
		exit 1
	fi
	cd "$PROJECT_ROOT"
fi

echo "iOS post-clone setup complete. Build will be handled by Xcode Cloud."