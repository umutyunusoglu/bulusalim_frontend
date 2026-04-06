#!/bin/sh
set -e

echo "Running Flutter setup..."

# Install Flutter dependencies
flutter pub get

# Generate iOS build files (this is the KEY part)
flutter build ios --release --no-codesign