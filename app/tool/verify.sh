#!/usr/bin/env bash
# Runs the same checks as CI. Use before every commit (from app/).
set -euo pipefail
cd "$(dirname "$0")/.."
dart run build_runner build --delete-conflicting-outputs >/dev/null
flutter gen-l10n >/dev/null
dart format lib test tool >/dev/null
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
dart run tool/check_l10n.dart
dart run tool/check_hardcoded_strings.dart
flutter test
