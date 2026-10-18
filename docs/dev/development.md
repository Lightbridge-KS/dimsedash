---
summary: Reproducible S0 contributor setup, dependency pins, generated files, commands and version ownership.
read_when:
  - building or testing DimseDash from a clean checkout
  - updating the SDK or dependencies
---

# Development

## Toolchain

`.fvmrc` owns Flutter **3.47.7** (Dart **3.13.5**). Use FVM **4.0.1**.
The root application `pubspec.yaml` owns the app version; native runners derive it
from Flutter build variables. The core package is private and is not separately
released. Commit the root workspace lockfile; do not add package lockfiles or
personal path overrides.

Resolved direct pins: Riverpod 3.4.3, Drift 2.35.2, drift_dev 2.35.1,
sqlite3 3.7.1, build_runner 2.16.1, analyzer 13.3.0 and test 1.31.1.
The analyzer/test/build-runner versions intentionally satisfy both Drift and the
Flutter SDK's test_api pin. Newest versions are not necessarily mutually compatible.
DICOM packages use the public `v0.1.0-dev.1` commit
`7f9a80d3a257a6936011250ce3e701b47b717385`; the root override ensures one shared
`dartdicom` value package. No local library checkout is needed.

Developer command versions verified for S0: just 1.53.0, prek 0.5.5,
gitleaks 8.30.1. Hook hygiene tools pin pre-commit-hooks 6.0.0 through `uvx`.
The design linter is `@google/design.md@0.4.0`, invoked by pnpm.
Install these tools, uv, Python 3 and pnpm before running the complete gate.

## Native prerequisites

- macOS: Xcode and command-line tools, accepted license and an Apple Silicon host.
  S0 was built with Xcode 16.4 on macOS 15.7.7. Deployment target is 15.0.
- Ubuntu 24.04 amd64: `clang cmake ninja-build pkg-config libgtk-3-dev
  libstdc++-13-dev`, Git, curl, unzip and xz-utils. A desktop session is needed
  for interactive acceptance; Xvfb supplies only a headless test display.

```sh
fvm install
fvm use
just setup
just hooks
just dry
just native-test
```

`just setup` enforces the checked-in lock. After an intentional dependency change,
run `fvm flutter pub get`, inspect the lockfile, then rerun the gates.
`just generate` regenerates Drift's checked-in `database.g.dart`. Changes to schema
must include explicit migration policy and preservation tests; deleting a database
is never a migration.

### VS Code

Open the repository root so `.vscode/settings.json` selects the FVM Flutter SDK
and its bundled Dart SDK for both the app and the pure-Dart core. Run `fvm install`
and `fvm use` first to create `.fvm/flutter_sdk`. After changing SDK settings,
run **Developer: Reload Window** if the analyzer still uses the previous SDK.
An older global analyzer can misread newer SDK annotations; for example,
`@Deprecated.implement` on `RegExp` restricts implementing the class, while
constructing regular expressions remains supported. Verify diagnostics with
`fvm dart analyze` or `just analyze` before changing valid source code.

## Tests and gates

Tests live under `tests/dry`, `tests/native` and the core package's `tests/`.
Use `just test` for dry tests; bare `flutter test` still expects a conventional
`test/` directory. VS Code permits test files outside that default folder through
the workspace settings. Run native tests with `just native-test` through the
`integration_test` symlink, rather than targeting `tests/native` directly.
See the [test suite map](../tests/README.md) for commands and ownership.

`just dry` does not contact a PACS or provision a runner. SDK/package setup and
native dependency downloads may require network access. `just audit` uses pub.dev
advisory/retraction metadata through `dart pub outdated --json --show-all` and
fails if the query fails or any current package is affected/retracted. This
registry audit is the dry gate's network-dependent supply-chain check, not a live
service test. It does not audit Git source: the DICOM commit needs separate review. Native GUI scenarios are
explicit under `just native-test`. Linux headless execution can use
`xvfb-run -a just native-test`; it does not prove GNOME session behavior.

CI uses the same just recipes with `FLUTTER_COMMAND=flutter` and
`DART_COMMAND=dart` pointed at the SDK from `.fvmrc`. Overrides are for runners,
not permission to change the SDK. Future release automation must guard tag versus
manifest version, draft the release from CHANGELOG and leave publication to a human.

## S0 storage and boundaries

The platform application-support directory contains `dimsedash.sqlite` and a
persistent lock file. There is no DICOM receive root yet. An exclusive OS lock
prevents simultaneous writers from separate processes; do not remove the lock file
while an app is running. Lock ownership ends when the handle/process closes.

Settings are applied explicitly in one transaction. Failed input or stale revisions
cannot partially update a node. Accepted saves finish before storage closes.
Startup refuses a newer schema or corrupt database without resetting it.

`tools/check_architecture.dart` checks production AST directives, conditional
branches, exports, normalized paths, part ownership, private APIs and core
manifest dependencies. Tests may instantiate concrete adapters. Extend its explicit
module policy with the blueprint when adding a capability; do not weaken it to make
a forbidden import pass.
