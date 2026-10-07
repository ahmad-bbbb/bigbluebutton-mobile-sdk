#!/usr/bin/env bash
# Fills ios/Frameworks/ with the SDK's XCFrameworks for the CocoaPods integration (vendored_frameworks).
# The podspec runs it on `pod install` while Frameworks/ is empty.
#
#   ios/fetch_frameworks.sh             ../../../ios/local/xcframeworks of an SDK repository checkout
#                                       when present, else the zips of the SDK's GitHub Release
#   ios/fetch_frameworks.sh --release   always download the release zips
#
# The release zips are checked against frameworks.sha256 (name + SHA-256 per line, from the SDK build).
# Env: BBB_SDK_FRAMEWORKS_URL  where the zips are (default: the GitHub Release of the plugin's version).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${HERE:?}/Frameworks"
SUMS="$HERE/frameworks.sha256"
LOCAL="$HERE/../../../ios/local/xcframeworks"
VERSION="$(sed -n "s/^ *s.version *= *'\(.*\)'.*/\1/p" "$HERE/bbb_meeting_sdk.podspec")"
BASE="${BBB_SDK_FRAMEWORKS_URL:-https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk/releases/download/v$VERSION}"

mkdir -p "$OUT"
find "${OUT:?}" -maxdepth 1 -name '*.xcframework' -exec rm -rf {} +

if [ "${1:-}" != "--release" ] && [ -d "$LOCAL" ]; then
  for fw in "$LOCAL"/*.xcframework; do ditto "$fw" "$OUT/$(basename "$fw")"; done
else
  TMP="$(mktemp -d)"
  trap 'rm -rf "${TMP:?}"' EXIT
  while read -r name sum; do
    [ -n "${name:-}" ] || continue
    echo "bbb_meeting_sdk: downloading $name.xcframework ($VERSION)"
    curl -fsSL --retry 3 "$BASE/$name.xcframework.zip" -o "$TMP/$name.zip"
    echo "$sum  $TMP/$name.zip" | shasum -a 256 -c --status \
      || { echo "bbb_meeting_sdk: checksum mismatch for $name.xcframework.zip" >&2; exit 1; }
    ditto -x -k "$TMP/$name.zip" "$OUT"
    rm -f "$TMP/$name.zip"
  done < "$SUMS"
fi
ls "$OUT"
