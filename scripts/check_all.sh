#!/bin/bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
flutter_bin="${FLUTTER_BIN:-flutter}"
(cd "$project_root/kigali_weather" && "$flutter_bin" pub get && "$flutter_bin" analyze && "$flutter_bin" test)
(cd "$project_root/daybook" && "$flutter_bin" pub get && "$flutter_bin" analyze)
