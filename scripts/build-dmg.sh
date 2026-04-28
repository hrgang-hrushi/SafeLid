#!/usr/bin/env bash

set -euo pipefail

APP_PATH=""
OUTPUT_PATH=""
VOLUME_NAME="SafeLid"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/build-dmg.sh --app /path/to/SafeLid.app [--output /path/to/SafeLid.dmg]

Options:
  --app       Path to the built .app bundle.
  --output    Output DMG path. Defaults to ./dist/SafeLid.dmg.
  --volume    Mounted volume name inside the DMG. Defaults to SafeLid.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app)
      APP_PATH="${2:-}"
      shift 2
      ;;
    --output)
      OUTPUT_PATH="${2:-}"
      shift 2
      ;;
    --volume)
      VOLUME_NAME="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$APP_PATH" ]]; then
  echo "Missing --app path." >&2
  usage >&2
  exit 1
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "App bundle not found: $APP_PATH" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -z "$OUTPUT_PATH" ]]; then
  mkdir -p "$REPO_ROOT/dist"
  OUTPUT_PATH="$REPO_ROOT/dist/SafeLid.dmg"
else
  mkdir -p "$(dirname "$OUTPUT_PATH")"
fi

STAGING_DIR="$(mktemp -d /tmp/safelid-dmg.XXXXXX)"
cleanup() {
  rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

cp -R "$APP_PATH" "$STAGING_DIR/"

ln -s /Applications "$STAGING_DIR/Applications"

rm -f "$OUTPUT_PATH"
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$OUTPUT_PATH"

echo "Created: $OUTPUT_PATH"