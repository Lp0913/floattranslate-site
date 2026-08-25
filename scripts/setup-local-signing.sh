#!/bin/zsh
set -euo pipefail

IDENTITY_NAME="${FLOATTRANSLATE_SIGNING_IDENTITY:-FloatTranslate Local Development}"
KEYCHAIN="${FLOATTRANSLATE_KEYCHAIN:-$HOME/Library/Keychains/login.keychain-db}"

if security find-identity -v -p codesigning "$KEYCHAIN" | grep -Fq "\"$IDENTITY_NAME\""; then
    echo "Signing identity already installed: $IDENTITY_NAME"
    exit 0
fi

TMP_DIR="$(mktemp -d /private/tmp/floattranslate-signing.XXXXXX)"
P12_PASSWORD="$(uuidgen)"
trap 'rm -rf "$TMP_DIR"' EXIT

openssl req \
    -x509 \
    -newkey rsa:2048 \
    -sha256 \
    -nodes \
    -days 3650 \
    -subj "/CN=$IDENTITY_NAME/O=FloatTranslate Local Development" \
    -addext "keyUsage=critical,digitalSignature" \
    -addext "extendedKeyUsage=codeSigning" \
    -keyout "$TMP_DIR/signing.key" \
    -out "$TMP_DIR/signing.crt"

PKCS12_ARGS=(-export)
if openssl pkcs12 -help 2>&1 | grep -q -- "-legacy"; then
    PKCS12_ARGS+=(-legacy)
fi

openssl pkcs12 \
    "${PKCS12_ARGS[@]}" \
    -inkey "$TMP_DIR/signing.key" \
    -in "$TMP_DIR/signing.crt" \
    -name "$IDENTITY_NAME" \
    -passout "pass:$P12_PASSWORD" \
    -out "$TMP_DIR/signing.p12"

security import "$TMP_DIR/signing.p12" \
    -k "$KEYCHAIN" \
    -P "$P12_PASSWORD" \
    -T /usr/bin/codesign

security add-trusted-cert \
    -d \
    -r trustRoot \
    -p codeSign \
    -k "$KEYCHAIN" \
    "$TMP_DIR/signing.crt"

security find-identity -v -p codesigning "$KEYCHAIN" | grep -F "\"$IDENTITY_NAME\""
echo "Installed signing identity: $IDENTITY_NAME"
