# Runner overrides must point at the exact SDK pinned in .fvmrc.
flutter := env('FLUTTER_COMMAND', 'fvm flutter')
dart := env('DART_COMMAND', 'fvm dart')

setup:
    {{flutter}} pub get --enforce-lockfile

run:
    {{flutter}} run -d {{ if os() == 'macos' { 'macos' } else { 'linux' } }}

generate:
    {{dart}} run build_runner build

format:
    {{dart}} format lib packages/dimsedash_core/lib packages/dimsedash_core/test test integration_test tool

check-format:
    {{dart}} format --output=none --set-exit-if-changed lib packages/dimsedash_core/lib packages/dimsedash_core/test test integration_test tool

analyze:
    {{flutter}} analyze --no-pub

test:
    {{flutter}} test --no-pub
    {{dart}} test packages/dimsedash_core/test

check-architecture:
    {{dart}} run tool/check_architecture.dart

check-design:
    pnpm dlx @google/design.md@0.4.0 lint DESIGN.md

audit:
    {{dart}} run tool/check_dependencies.dart

secrets:
    python3 tool/check_secrets.py

build:
    {{flutter}} build {{ if os() == 'macos' { 'macos' } else { 'linux' } }} --release --no-pub

# No PACS, container, paid runner, or remote service is started here.
dry: check-format analyze test check-architecture check-design secrets audit build

native-test:
    {{flutter}} test integration_test/configuration_flow_test.dart -d {{ if os() == 'macos' { 'macos' } else { 'linux' } }} --no-pub

hooks:
    prek install
