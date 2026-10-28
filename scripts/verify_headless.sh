#!/bin/bash
# Real Flutter renderer + SQLite checks without a VM-service socket (macOS).
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
flutter_bin="${FLUTTER_BIN:-flutter}"
if [[ -n "${SESSION5_FLUTTER_SDK:-}" ]]; then
  session5_sdk_root="$SESSION5_FLUTTER_SDK"
else
  session5_flutter_path="$(command -v "$flutter_bin")"
  session5_sdk_root="$(python3 -c 'import os,sys; print(os.path.dirname(os.path.dirname(os.path.realpath(sys.argv[1]))))' "$session5_flutter_path")"
fi
shopt -s nullglob
engines=("$session5_sdk_root"/bin/cache/artifacts/engine/darwin-*/flutter_tester)
if [[ ${#engines[@]} -eq 0 ]]; then
  echo 'Flutter macOS test engine is missing. Run flutter precache --macos first.' >&2
  exit 1
fi
cd "$project_root/kigali_weather"
"$flutter_bin" build bundle --target=tool/verify.dart --target-platform=darwin --asset-dir=build/verification_assets
"${engines[0]}" --disable-vm-service --enable-software-rendering --run-forever \
  --flutter-assets-dir=build/verification_assets build/verification_assets/kernel_blob.bin
