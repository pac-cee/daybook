#!/bin/bash
# Capture native evidence in separate processes, keeping the app's data.
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
flutter_bin="${FLUTTER_BIN:-flutter}"
device_id="${1:-}"
if [[ -z "$device_id" ]]; then
  device_id="$(xcrun simctl list devices booted -j | python3 -c 'import json,sys; devices=[d["udid"] for group in json.load(sys.stdin)["devices"].values() for d in group if d.get("state")=="Booted"]; print(devices[0] if devices else "")')"
fi
if [[ -z "$device_id" ]]; then
  echo 'Boot an iOS simulator first.' >&2
  exit 1
fi
cd "$project_root/daybook"
"$flutter_bin" pub get
for phase in before after; do
  "$flutter_bin" test integration_test/submission_test.dart --no-uninstall \
    -d "$device_id" --dart-define="SUBMISSION_PHASE=$phase"
done
container_path="$(xcrun simctl get_app_container "$device_id" rw.sessionfive.daybook data)"
mkdir -p screenshots "$project_root/screenshots" "$project_root/docs/submission-evidence"
for screenshot in before after api no-internet; do
  cp "$container_path/tmp/daybook-submission/$screenshot.png" "screenshots/$screenshot.png"
  cp "screenshots/$screenshot.png" "$project_root/screenshots/$screenshot.png"
done
cp "$container_path/tmp/daybook-submission/before-records.json" "$project_root/docs/submission-evidence/"
cp "$container_path/tmp/daybook-submission/api-observation.json" "$project_root/docs/submission-evidence/"
# Restore the ordinary entry point after the test application exits.
"$flutter_bin" build ios --simulator --debug --no-codesign -t lib/main.dart
xcrun simctl install "$device_id" build/ios/iphonesimulator/Runner.app
xcrun simctl launch "$device_id" rw.sessionfive.daybook
