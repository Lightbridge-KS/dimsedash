# dimsedash_core

Private, pure Dart workspace package for DimseDash policy and injected seams.
S0 includes validated connection values, typed results and the ConfigStore port.
No Flutter, database or filesystem dependency belongs here.

Run its tests from the workspace root with `fvm dart test packages/dimsedash_core/tests`.

From this package directory, `fvm dart test` uses `dart_test.yaml` to discover `tests/`.
