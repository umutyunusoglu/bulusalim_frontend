#!/bin/sh
set -e

export COCOAPODS_DISABLE_STATS=1
export COCOAPODS_MAX_CONCURRENT_DOWNLOADS=1

SCRIPT_START_TS=$(date +%s)

start_step() {
	STEP_NAME="$1"
	STEP_START_TS=$(date +%s)
	echo "[CI TIMER] START: $STEP_NAME"
}

end_step() {
	STEP_END_TS=$(date +%s)
	STEP_DURATION=$((STEP_END_TS - STEP_START_TS))
	echo "[CI TIMER] END: $STEP_NAME (${STEP_DURATION}s)"
}

print_total_duration() {
	SCRIPT_END_TS=$(date +%s)
	SCRIPT_DURATION=$((SCRIPT_END_TS - SCRIPT_START_TS))
	echo "[CI TIMER] TOTAL: iOS post-clone setup (${SCRIPT_DURATION}s)"
}

run_with_retry() {
	MAX_ATTEMPTS="$1"
	INITIAL_DELAY="$2"
	shift 2

	ATTEMPT=1
	DELAY="$INITIAL_DELAY"

	while [ "$ATTEMPT" -le "$MAX_ATTEMPTS" ]; do
		echo "Attempt ${ATTEMPT}/${MAX_ATTEMPTS}: $*"
		if "$@"; then
			return 0
		fi

		if [ "$ATTEMPT" -lt "$MAX_ATTEMPTS" ]; then
			echo "Command failed. Retrying in ${DELAY}s..."
			sleep "$DELAY"
			DELAY=$((DELAY * 2))
		fi

		ATTEMPT=$((ATTEMPT + 1))
	done

	echo "Command failed after ${MAX_ATTEMPTS} attempts."
	return 1
}

cd "$CI_PRIMARY_REPOSITORY_PATH"

echo "Running Flutter iOS CI setup..."
echo "Project root: $CI_PRIMARY_REPOSITORY_PATH"

cat > .env <<EOF
MAPBOX_ACCESS_TOKEN=$MAPBOX_ACCESS_TOKEN
EOF

echo ".env created"

# Reuse existing Flutter if available; otherwise install the pinned SDK version.
start_step "Flutter SDK resolution"
if command -v flutter >/dev/null 2>&1; then
	echo "Using preinstalled Flutter: $(command -v flutter)"
elif [ -x "$HOME/flutter/bin/flutter" ]; then
	export PATH="$PATH:$HOME/flutter/bin"
	echo "Using cached Flutter from $HOME/flutter"
else
	echo "Installing Flutter 3.41.6..."
	git clone https://github.com/flutter/flutter.git --depth 1 -b 3.41.6 "$HOME/flutter"
	export PATH="$PATH:$HOME/flutter/bin"
fi
end_step

start_step "Flutter version check"
flutter --version
end_step

# Download iOS artifacts only when needed by a fresh worker.
start_step "Flutter iOS precache"
if [ ! -d "$HOME/flutter/bin/cache/artifacts/engine/ios" ]; then
	flutter precache --ios
else
	echo "iOS engine artifacts already cached; skipping precache."
fi
end_step

# Install Dart/Flutter packages (offline-first when cache is warm).
start_step "Flutter pub get"
if ! flutter pub get --enforce-lockfile --offline; then
	echo "Offline pub get cache miss, falling back to network..."
	flutter pub get --enforce-lockfile
fi
end_step

# Keep iOS version name from pubspec and auto-increment build number in Xcode Cloud.
start_step "iOS build version setup"
PUBSPEC_VERSION=$(grep '^version:' pubspec.yaml | head -n1 | awk '{print $2}')
PUBSPEC_BUILD_NAME=${PUBSPEC_VERSION%%+*}
PUBSPEC_BUILD_NUMBER=$(echo "$PUBSPEC_VERSION" | sed -nE 's/^[^+]+\+([0-9]+)$/\1/p')
IOS_BUILD_NUMBER=${CI_BUILD_NUMBER:-$PUBSPEC_BUILD_NUMBER}

if [ -z "$IOS_BUILD_NUMBER" ]; then
	IOS_BUILD_NUMBER=1
fi

GENERATED_XCCONFIG="ios/Flutter/Generated.xcconfig"
if [ -f "$GENERATED_XCCONFIG" ]; then
	if grep -q '^FLUTTER_BUILD_NAME=' "$GENERATED_XCCONFIG"; then
		sed -i.bak "s/^FLUTTER_BUILD_NAME=.*/FLUTTER_BUILD_NAME=$PUBSPEC_BUILD_NAME/" "$GENERATED_XCCONFIG"
	else
		echo "FLUTTER_BUILD_NAME=$PUBSPEC_BUILD_NAME" >> "$GENERATED_XCCONFIG"
	fi

	if grep -q '^FLUTTER_BUILD_NUMBER=' "$GENERATED_XCCONFIG"; then
		sed -i.bak "s/^FLUTTER_BUILD_NUMBER=.*/FLUTTER_BUILD_NUMBER=$IOS_BUILD_NUMBER/" "$GENERATED_XCCONFIG"
	else
		echo "FLUTTER_BUILD_NUMBER=$IOS_BUILD_NUMBER" >> "$GENERATED_XCCONFIG"
	fi

	rm -f "$GENERATED_XCCONFIG.bak"
	echo "iOS build version configured: name=$PUBSPEC_BUILD_NAME number=$IOS_BUILD_NUMBER"
else
	echo "Warning: $GENERATED_XCCONFIG not found; skipping iOS build version override."
fi
end_step

# Ensure FlutterFire CLI is available when Crashlytics symbol upload build phase is enabled.
start_step "FlutterFire CLI availability"
export PATH="$PATH:$HOME/.pub-cache/bin"
if grep -q 'flutterfire upload-crashlytics-symbols' ios/Runner.xcodeproj/project.pbxproj; then
	if ! command -v flutterfire >/dev/null 2>&1; then
		echo "Installing flutterfire_cli for Crashlytics symbols upload..."
		dart pub global activate flutterfire_cli
	else
		echo "flutterfire already available; skipping install."
	fi
else
	echo "Crashlytics upload phase not found; skipping flutterfire check."
fi
end_step

# Install CocoaPods only if it is not preinstalled in the runner image.
start_step "CocoaPods availability"
if ! command -v pod >/dev/null 2>&1; then
	HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods
else
	echo "CocoaPods already installed; skipping brew install."
fi

# Work around intermittent HTTP/2 transport issues while cloning pod git sources.
git config --global http.version HTTP/1.1
git config --global http.postBuffer 524288000
end_step

start_step "pod install"
cd ios
# Skip pod install when pods already match lockfile on a warm worker.
if [ -f "Pods/Manifest.lock" ] && cmp -s "Pods/Manifest.lock" "Podfile.lock"; then
	echo "Pods are already in sync with Podfile.lock; skipping pod install."
else
	run_with_retry 4 8 pod install --deployment --repo-update
fi
end_step

print_total_duration

echo "iOS post-clone setup complete."