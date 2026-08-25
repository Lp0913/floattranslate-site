#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="/private/tmp/floattranslate-self-tests"
OUTPUT_BIN="$OUTPUT_DIR/FloatTranslateSelfTests"
SDK_PATH="${FLOATTRANSLATE_SDK_PATH:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.5.sdk}"
if [[ ! -d "$SDK_PATH" ]]; then
    SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
fi

export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-/private/tmp/floattranslate-test-clang-cache}"
export SWIFT_MODULECACHE_PATH="${SWIFT_MODULECACHE_PATH:-/private/tmp/floattranslate-test-swift-cache}"

mkdir -p "$OUTPUT_DIR"
swiftc \
    -sdk "$SDK_PATH" \
    -target "$(uname -m)-apple-macosx15.0" \
    "$ROOT_DIR/scripts/self-test/SelfTestMain.swift" \
    "$ROOT_DIR/Sources/FloatTranslate/LookupTextNormalizer.swift" \
    "$ROOT_DIR/Sources/FloatTranslate/DefinitionFormatter.swift" \
    "$ROOT_DIR/Sources/FloatTranslate/TranslationLanguage.swift" \
    "$ROOT_DIR/Sources/FloatTranslate/EnglishAccent.swift" \
    "$ROOT_DIR/Sources/FloatTranslate/DictionaryService.swift" \
    "$ROOT_DIR/Sources/FloatTranslate/TextValidator.swift" \
    "$ROOT_DIR/Sources/FloatTranslate/TranslationCardLayout.swift" \
    "$ROOT_DIR/Sources/FloatTranslate/PanelPositioner.swift" \
    -o "$OUTPUT_BIN"

"$OUTPUT_BIN"
