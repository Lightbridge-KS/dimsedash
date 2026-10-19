---
summary: Reproducible contributor setup, S1 released dependency pins, generated files, commands and version ownership.
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
DICOM packages use the public `v0.1.0-dev.2` tag at
`53ee5ec9c204e58382bf9235a621eb05af8d4179`; the root Git override ensures one
shared `dartdicom` value package. S1 needs no local library checkout.

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

## S1 dependencies and diagnostic provenance

All three DICOM libraries resolve from the GitHub-only `v0.1.0-dev.2` tag to
`53ee5ec9c204e58382bf9235a621eb05af8d4179`. The root `dartdicom` Git override
aligns the library's transitive dependency with the pure-Dart core's Git source;
it is required and must remain a Git source. A sibling checkout is not required.

For an intentional upstream change, update every Git ref in the root and core
manifests together, resolve the workspace lockfile and regenerate provenance.
An ignored `pubspec_overrides.yaml` may support paired development, but must be
disabled for delivery verification. Never commit filesystem overrides or a
lockfile containing them. Enforce the lockfile again with `just setup` and check
that `.dart_tool/package_config.json` points all three libraries into the Git
cache at the recorded revision. The [S1 runbook](../tests/s1-echo.md) records
isolated-source verification separately from a committed clean clone.

`just versions` derives diagnostic app/library versions from manifests and the
resolved library Git source, including a `-dirty` marker during paired work.
`lib/app/build_versions.dart` is generated; regenerate it when versions or the
resolved source change. The app manifest remains the version authority.

## S1 schema and run recovery

Schema v2 preserves all v1 configuration and adds timeout fields, run summaries
and typed events. Before upgrading a file database, startup uses SQLite
`VACUUM INTO` to create one consistent `dimsedash.sqlite.recovery` copy, including
committed WAL content. Migration and integrity validation are transactional. The
copy is removed only after successful migration/configuration loading; a retained
copy blocks subsequent startup writes and requires explicit recovery. No automatic
reset, downgrade or recovery-copy deletion is offered.

Runs are recorded before network dispatch. On restart, unfinished rows become
`interrupted` with the **reconciliation time**, not a fabricated network end time.
No run is replayed. History stores allowlisted facts only; saved node configuration
is still potentially identifying. Node deletion clears its reference in history
without deleting the historical summary or changing a live request.

See the [Echo verification runbook](../tests/s1-echo.md) for independent loopback
fixtures and native/release checks.
