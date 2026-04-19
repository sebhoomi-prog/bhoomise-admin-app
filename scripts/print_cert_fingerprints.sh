#!/usr/bin/env bash
# Print signing info for Firebase / Google Cloud.
#
# Android: copy SHA-1 and SHA-256 into Firebase Console → Project settings → Your apps → Android app.
# iOS: Firebase uses Bundle ID + GoogleService-Info.plist (not Android-style SHA fingerprints).

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo ""
echo "=== ANDROID — SHA-1 / SHA-256 (add both in Firebase Console for com.bhoomise) ==="
echo ""
cd "$ROOT/android"
./gradlew :app:signingReport

echo ""
echo "=== iOS — Firebase (Bundle ID + plist; no SHA-1/256 like Android) ==="
echo ""
echo "• Register the iOS app in Firebase with the same Bundle ID as Xcode (Runner)."
echo "• Place GoogleService-Info.plist in ios/Runner/."
echo ""
if [[ -f "$ROOT/ios/Runner/Info.plist" ]]; then
  echo -n "• Current Runner bundle id: "
  /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$ROOT/ios/Runner/Info.plist" 2>/dev/null || echo "(unresolved)"
fi
echo ""
echo "• Code signing identities on this Mac (Apple Developer — not pasted into Firebase as SHA):"
security find-identity -v -p codesigning 2>/dev/null | head -25 || true
echo ""
