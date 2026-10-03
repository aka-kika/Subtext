#!/usr/bin/env bash
# Build a signed, notarized, stapled Subtext.dmg for Developer ID distribution.
# No secrets in this script:
#   • the signing identity is auto-detected from your Keychain
#   • notarization uses a Keychain credential profile (default: reshelf-notary,
#     shared across KIKA apps; override with SUBTEXT_NOTARY_PROFILE)
#
# Then:  bash scripts/release.sh
set -euo pipefail

APP_NAME="Subtext"
NOTARY_PROFILE="${SUBTEXT_NOTARY_PROFILE:-reshelf-notary}"

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$PROJECT_DIR/.build/dist"
APP="$DIST/$APP_NAME.app"
RES="$PROJECT_DIR/Subtext/Resources"

# Sign by certificate hash, not display name — duplicate certs with the same
# name in the keychain make name-based signing fail as "ambiguous".
# G2 Developer ID (2026-10-03, valid to 2031-09-17); the old authority ends 2027-02-01.
IDENTITY="${SUBTEXT_SIGN_IDENTITY:-7E3E9BC6656A41A13F77F5C05E1663E77419388E}"
if [ -z "$IDENTITY" ]; then
  echo "✗ No 'Developer ID Application' identity found in the Keychain." >&2
  exit 1
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$RES/Info.plist")"
DMG="$DIST/$APP_NAME-$VERSION.dmg"

echo "▶︎ Identity: $IDENTITY"
echo "▶︎ Version:  $VERSION"
rm -rf "$DIST"; mkdir -p "$DIST"

echo "▶︎ Building Release (arm64)…"
swift build -c release --package-path "$PROJECT_DIR" >/dev/null
BINARY="$PROJECT_DIR/.build/release/$APP_NAME"

echo "▶︎ Assembling $APP_NAME.app…"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BINARY" "$APP/Contents/MacOS/$APP_NAME"
cp "$RES/Info.plist" "$APP/Contents/Info.plist"
find "$RES" -maxdepth 1 -type f ! -name "Info.plist" -exec cp {} "$APP/Contents/Resources/" \;

echo "▶︎ Signing (hardened runtime)…"
codesign --force --options runtime --timestamp --sign "$IDENTITY" "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"

echo "▶︎ Notarizing the app (pass 1 of 2, via ZIP)…"
ZIP="$DIST/$APP_NAME-$VERSION.zip"
ditto -c -k --keepParent "$APP" "$ZIP"
xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
rm -f "$ZIP"

echo "▶︎ Creating DMG…"
create-dmg \
  --volname "$APP_NAME $VERSION" \
  --window-size 540 380 --icon-size 110 \
  --icon "$APP_NAME.app" 150 185 \
  --app-drop-link 390 185 \
  --no-internet-enable \
  "$DMG" "$APP" >/dev/null 2>&1 || true
[ -f "$DMG" ] || { echo "✗ DMG creation failed" >&2; exit 1; }

echo "▶︎ Signing DMG…"
codesign --force --timestamp --sign "$IDENTITY" "$DMG"

echo "▶︎ Notarizing the DMG (pass 2 of 2)…"
xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait

echo "▶︎ Stapling + verifying…"
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"
spctl --assess --type open --context context:primary-signature -v "$DMG" 2>&1 || true

echo ""
echo "✅ Done: $DMG"
