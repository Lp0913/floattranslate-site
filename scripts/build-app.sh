#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/FloatTranslate.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
SWIFT_BIN="${SWIFT_BIN:-swift}"
SWIFTC_BIN="${SWIFTC_BIN:-${SWIFT_BIN}c}"
SIGNING_IDENTITY="${FLOATTRANSLATE_SIGNING_IDENTITY:-FloatTranslate Local Development}"
DIRECT_BUILD_DIR="/private/tmp/floattranslate-direct-build"
DIRECT_BIN="$DIRECT_BUILD_DIR/FloatTranslate"

export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-/private/tmp/floattranslate-clang-cache}"
export SWIFT_MODULECACHE_PATH="${SWIFT_MODULECACHE_PATH:-/private/tmp/floattranslate-swift-cache}"

cd "$ROOT_DIR"
if BIN_DIR="$("$SWIFT_BIN" build --disable-sandbox -c release --show-bin-path)" \
    && "$SWIFT_BIN" build --disable-sandbox -c release --product FloatTranslate; then
    BIN_PATH="$BIN_DIR/FloatTranslate"
else
    echo "SwiftPM manifest failed; falling back to direct swiftc build." >&2
    SDK_PATH="${FLOATTRANSLATE_SDK_PATH:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.5.sdk}"
    if [[ ! -d "$SDK_PATH" ]]; then
        SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
    fi
    ARCH="$(uname -m)"
    mkdir -p "$DIRECT_BUILD_DIR"
    "$SWIFTC_BIN" \
        -sdk "$SDK_PATH" \
        -target "$ARCH-apple-macosx15.0" \
        -Onone \
        -whole-module-optimization \
        -parse-as-library \
        "$ROOT_DIR"/Sources/FloatTranslate/*.swift \
        -o "$DIRECT_BIN"
    BIN_PATH="$DIRECT_BIN"
fi

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
cp "$BIN_PATH" "$MACOS_DIR/FloatTranslate"
cp "$ROOT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
chmod +x "$MACOS_DIR/FloatTranslate"

if security find-identity -v -p codesigning | grep -Fq "\"$SIGNING_IDENTITY\""; then
    codesign --force --deep --sign "$SIGNING_IDENTITY" "$APP_DIR"
    echo "Built $APP_DIR with fixed signing identity: $SIGNING_IDENTITY"
elif [[ "${FLOATTRANSLATE_ALLOW_ADHOC:-0}" == "1" ]]; then
    codesign --force --deep --sign - "$APP_DIR"
    echo "Built $APP_DIR with ad-hoc signing for packaging."
else
    echo "Missing fixed signing identity: $SIGNING_IDENTITY" >&2
    echo "Run scripts/setup-local-signing.sh once, or set FLOATTRANSLATE_ALLOW_ADHOC=1 for a sharing build." >&2
    exit 1
fi
