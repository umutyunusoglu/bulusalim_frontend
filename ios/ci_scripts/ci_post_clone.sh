#!/bin/sh
set -e

cd "$CI_PRIMARY_REPOSITORY_PATH"

echo "Running Flutter iOS CI setup..."
echo "Project root: $CI_PRIMARY_REPOSITORY_PATH"

# Install Flutter in the Xcode Cloud worker
git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

flutter --version

# Download iOS artifacts needed by Flutter
flutter precache --ios

# Install Dart/Flutter packages
flutter pub get

# Install CocoaPods
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods || true

cd ios
pod install

echo "iOS post-clone setup complete."