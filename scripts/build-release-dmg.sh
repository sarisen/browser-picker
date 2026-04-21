#!/usr/bin/env bash
set -euo pipefail

PROJECT_PATH="${PROJECT_PATH:-BrowserPicker.xcodeproj}"
SCHEME="${SCHEME:-BrowserPicker}"
APP_NAME="${APP_NAME:-BrowserPicker}"
VERSION="${GITHUB_REF_NAME:-v1.0.0}"
VERSION="${VERSION#refs/tags/}"

BUILD_DIR="build"
DERIVED_DIR="$BUILD_DIR/DerivedData"
STAGE_DIR="$BUILD_DIR/stage"
RELEASE_DIR="$BUILD_DIR/release"

echo "→ Building $APP_NAME $VERSION"

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration Release \
  -derivedDataPath "$DERIVED_DIR" \
  CODE_SIGNING_ALLOWED=NO \
  build

APP_PATH=$(find "$DERIVED_DIR" -name "$APP_NAME.app" -maxdepth 6 | head -1)

if [ -z "$APP_PATH" ]; then
  echo "✗ Could not find $APP_NAME.app in $DERIVED_DIR"
  exit 1
fi

echo "→ Found app at $APP_PATH"

rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR" "$RELEASE_DIR"

cp -R "$APP_PATH" "$STAGE_DIR/"
ln -s /Applications "$STAGE_DIR/Applications"

DMG_PATH="$RELEASE_DIR/$APP_NAME-$VERSION.dmg"

echo "→ Creating $DMG_PATH"

hdiutil create \
  -volname "$APP_NAME $VERSION" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "✓ Done: $DMG_PATH"
