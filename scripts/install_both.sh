#!/bin/bash
# Builds and installs both apps on an already booted iOS simulator.
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
flutter_bin="${FLUTTER_BIN:-flutter}"
device_id="${1:-}"
if [[ -z "$device_id" ]]; then
  device_id="$(xcrun simctl list devices booted -j | python3 -c 'import json,sys; devices=[d["udid"] for group in json.load(sys.stdin)["devices"].values() for d in group if d.get("state")=="Booted"]; print(devices[0] if devices else "")')"
fi
if [[ -z "$device_id" ]]; then
  echo 'No booted iOS simulator found. Start one in Simulator, then run this script again.' >&2
  exit 1
fi
for app in kigali_weather daybook; do
  (
    cd "$project_root/$app"
    "$flutter_bin" pub get
    "$flutter_bin" build ios --simulator --debug --no-codesign
    xcrun simctl install "$device_id" build/ios/iphonesimulator/Runner.app
  )
done
xcrun simctl launch "$device_id" rw.sessionfive.kigaliWeather
xcrun simctl launch "$device_id" rw.sessionfive.daybook
echo 'Kigali Weather and Daybook are installed. Daybook is open; both icons are on the home screen.'
