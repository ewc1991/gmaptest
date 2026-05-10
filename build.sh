#!/bin/bash
set -e

# Install Flutter (stable)
git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter_sdk
export PATH="$PATH:$(pwd)/flutter_sdk/bin"

# Enable web
flutter config --enable-web --no-analytics

# Inject API key from Cloudflare environment variable into .env asset
echo "GOOGLE_MAPS_API_KEY=${GOOGLE_MAPS_API_KEY}" > .env

# Build
flutter pub get
flutter build web --release --no-tree-shake-icons
