---
summary: Test suite ownership, explicit dry and native runner paths, package-local core tests and fixture scope.
read_when:
  - running, locating or reorganizing tests
  - changing test discovery, runner commands or shared test fixtures
---

# Test suite map

Tests are grouped by execution gate, then by the code that owns the behavior.
The [S0 runbook](s0-configuration.md) owns scenarios and acceptance evidence;
the [progress tracker](../progress/overview-first-preview.md) records current work.

```text
tests/
  dry/
    app/
      bootstrap_test.dart
      shell_test.dart
    bindings/
      configuration_test.dart
    adapters/persistence/
      config_store_test.dart
      process_guard_test.dart
      support/lock_probe.dart
    features/settings/
      settings_view_test.dart
    tools/
      architecture_test.dart
  native/
    configuration_flow_test.dart
  support/
    memory_config_store.dart
    synthetic_configuration.dart
integration_test -> tests/native
packages/dimsedash_core/tests/
  configuration_test.dart
```

## Commands and discovery

| Command | Scope |
|---|---|
| `just test` | Flutter tests explicitly under `tests/dry`, then pure-Dart core tests |
| `just dry` | Formatting, analysis, dry tests, architecture/design checks, secret/dependency scans and native release build |
| `just native-test` | Native desktop configuration flow through `integration_test/configuration_flow_test.dart` |
| `fvm flutter test tests/dry/app/shell_test.dart --no-pub` | One app test suite |
| `fvm dart test packages/dimsedash_core/tests` | Core tests from the workspace root |
| `fvm dart test` inside `packages/dimsedash_core` | Core tests using package-local `dart_test.yaml` discovery |

Bare `flutter test` defaults to `test/`, so use explicit paths or the recipes.
Do not run `flutter test tests/`: it would include the native source as a widget
test. The pinned Flutter tool recognizes native integration tests through the root
`integration_test/` prefix. That path is a relative symlink to the canonical
`tests/native/` directory. Keep it as a symlink and run native cases through it.
Formatting targets the canonical trees once.

VS Code workspace settings allow test files outside the conventional `test/`
folder. Native cases still require the alias route; `just native-test` is the
portable entry point. CI invokes `just dry` and does not launch a desktop test.

## Cohesion and fixtures

- Settings tests own editing, validation, Apply/Discard, remote draft visibility,
  enum restoration and pending-save/failure feedback. Form interaction helpers and
  the controlled pending/failing store remain local to that suite.
- Shell tests own navigation, placeholder states, saved sidebar updates, minimum
  window behavior and Settings removal. The bindings suite owns reveal scope reset.
- Persistence tests own storage atomicity, revisions, schema refusal and closing.
  Bootstrap tests own corrupt-file preservation and runtime reopening.
- Architecture tests retain local positive/negative source fixtures. The process
  guard's child executable stays beside its owning suite, without a `_test.dart`
  suffix.
- `MemoryConfigStore` is shared by Settings and shell tests. It saves immediately
  and increments the configuration revision. It remains separate from the local
  controlled store used to hold or fail a save.
- The synthetic configuration builder is shared by persistence and bootstrap.
  Expected values and assertions stay local so fixture reuse cannot make an oracle
  agree with a defect.
- The native configuration flow remains one end-to-end validation/save/runtime-
  reopen scenario. It uses a real desktop app and SQLite, but recreating its runtime
  does not prove an OS process restart or installed-package acceptance.
