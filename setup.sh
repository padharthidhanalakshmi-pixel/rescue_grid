#!/usr/bin/env bash
# One-time setup: generates the android/ platform folder (not committed as
# generated boilerplate) and applies RescueGrid's Android manifest.
set -euo pipefail
cd "$(dirname "$0")"

if [ ! -d android ]; then
  flutter create . --platforms=android --org in.ac.lbrce --project-name rescuegrid
fi
cp android_overrides/AndroidManifest.xml android/app/src/main/AndroidManifest.xml

flutter pub get
echo "✓ Setup complete. Next: flutter analyze && flutter test && flutter build apk --release"
