#!/bin/sh
set -e

cd "$CI_PRIMARY_REPOSITORY_PATH"

echo "Running Flutter iOS CI setup..."
echo "Project root: $CI_PRIMARY_REPOSITORY_PATH"

cat > .env <<EOF
MAPBOX_ACCESS_TOKEN=$MAPBOX_ACCESS_TOKEN
EOF

echo ".env created"

# Reuse existing Flutter if available; otherwise install the pinned SDK version.
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

flutter --version

# Download iOS artifacts only when needed by a fresh worker.
if [ ! -d "$HOME/flutter/bin/cache/artifacts/engine/ios" ]; then
	flutter precache --ios
fi

# Install Dart/Flutter packages
flutter pub get --enforce-lockfile

# Install CocoaPods only if it is not preinstalled in the runner image.
if ! command -v pod >/dev/null 2>&1; then
	HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods
fi

cd ios
pod install --deployment

echo "iOS post-clone setup complete."