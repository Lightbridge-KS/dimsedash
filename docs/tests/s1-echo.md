---
summary: S1 deterministic, loopback live, native and release Echo verification with independent disposable fixtures.
read_when:
  - running or reviewing S1 Echo verification
  - distinguishing automated networking evidence from desktop acceptance
---

# S1 Echo verification

Parent: [S1 tracker](../progress/s1-echo.md).

## Dry coverage

`just dry` checks formatting, analysis, core/UI/persistence tests, architectural
boundaries, design tokens, secrets, dependency advisories and the native release
build. No PACS starts. `tests/dry/operations` exercises admission, frozen settings,
failed initial and mid-run writes, stop/response races, subscription independence,
bounded shutdown, stale handles and separately counted live/history omissions. Persistence tests cover CRUD/revisions,
selection, deletion without history loss, v1 migration/recovery, privacy canaries
and retention boundaries, including committed WAL content in the recovery snapshot. Widget tests cover both themes, evidence tabs, timeout
validation and navigation while a run remains owned by the runtime.

## Explicit loopback fixtures

Prerequisites: Docker Compose, uv, Python 3 and the repository's Flutter SDK.

```sh
just live
just native-echo
just native-echo-release
```

`tools/live/run.py` owns a unique disposable Compose project and a helper process
group. It refuses occupied ports, waits for readiness, and removes its own services
and ephemeral volumes in `finally`. It never connects to an existing PACS.
Orthanc **26.9.1** publishes DICOM only on loopback; there is no published REST
port or persistent volume. Controlled peers pin **pynetdicom 3.0.4** and
**pydicom 3.0.2**. These peers exchange Verification commands only; no DICOM image
fixtures, sibling repository or clinical service is needed.

Default Orthanc port: 4242. Helper ports: 4250–4256. Override occupied ports:

```sh
DIMSEDASH_ORTHANC_PORT=18424 DIMSEDASH_PEER_PORT=18450 just live
```

| Scenario | Evidence required |
|---|---|
| Orthanc success | Observed status 0, successful outcome, durable history, transport cleanup |
| Refused connection | Connection failure from an unused loopback port |
| Wrong AE | Numeric association rejection result/source/reason |
| Unsupported Verification context | Rejected negotiation and no Echo command |
| Association and DIMSE delays | Typed timeout phase and bounded termination |
| Peer abort | Numeric abort evidence retained |
| Stop during establishment/operation | Local stop intent, no invented C-CANCEL acknowledgement, cleanup before retry |
| Release failure after response | Status 0 retained; diagnostic warning and separate cleanup failure |

The release-failure peer proxies a real pynetdicom Echo exchange, then suppresses
the release response. The native test changes Settings during a delayed Echo,
navigates between pages, inspects evidence tabs and explicitly retries/stops.
Synthetic text entry is not physical keyboard acceptance.

Flutter Driver does not support desktop release mode. `native-echo-release`
therefore builds a separate `tools/live/release_probe.dart` entrypoint with the
same release runner/entitlements and real app bootstrap/adapter. It records a
successful loopback Echo and storage result before exiting. This proves release
networking; it does not replace manual acceptance of the production UI. Rebuild
`just build` afterward to restore the production entrypoint in the build output.

On macOS, inspect the production artifact:

```sh
codesign -d --entitlements - build/macos/Build/Products/Release/DimseDash.app
```

Both source entitlement files and the signed release artifact must include
`com.apple.security.network.client`. Listener permission remains future receive
work. CI continues to run dry checks only. Ubuntu 24.04 automated/build/headless
results and GNOME Wayland/Xorg acceptance are recorded separately in the tracker.

## Released dependency and isolated-source verification

S1 uses `v0.1.0-dev.2` for `dartdicom`, `dartdicom_net` and `dartdicom_pixel`.
All three lock entries must have version `0.1.0-dev.2`, source `git`, and
resolved ref `53ee5ec9c204e58382bf9235a621eb05af8d4179`. The four dependency
refs in the root/core manifests must agree on the tag. The root core-library
Git override is necessary; a filesystem override is not part of delivery.

Before verifying delivery, disable any ignored `pubspec_overrides.yaml`, run
`just setup`, `just versions`, and check the resolved roots in
`.dart_tool/package_config.json`. Each library must come from a Git checkout of
the release commit, with a clean source tree. Generated diagnostic provenance
must read `0.1.0-dev.2@53ee5ec9c204e58382bf9235a621eb05af8d4179` without a dirty
marker. This is library provenance; it does not claim committed app sources.

For uncommitted app work, use an isolated source snapshot with a fresh package
cache and no copied build state. The following preserves tracked and non-ignored
new files. Its temporary Git index lets the secret gate inspect the complete
snapshot; it does not create an implementation commit.

```sh
verification_root="$PWD/_playground/$(date +%F)_release-check"
mkdir -p "$verification_root/source"
git ls-files -z --cached --others --exclude-standard |
  rsync -a --from0 --files-from=- ./ "$verification_root/source/"
git -C "$verification_root/source" init
git -C "$verification_root/source" add --all
cd "$verification_root/source"
export PUB_CACHE="$verification_root/pub-cache"
just setup
fvm dart run tools/write_build_versions.dart --check
just dry
# Choose unoccupied loopback ports for the disposable fixtures.
export DIMSEDASH_ORTHANC_PORT=18424
export DIMSEDASH_PEER_PORT=18450
just live
just native-test
just native-echo
just native-echo-release
just build
fvm dart run tools/write_build_versions.dart --check
git diff --exit-code -- pubspec.lock lib/app/build_versions.dart
```

Compare the snapshot's source hashes against the working copy and check the
three package roots/lock entries again after the gates. Record host OS, SDK,
source baseline plus uncommitted changes, tested release ref, command results and
limits in the [tracker](../progress/s1-echo.md). A snapshot is not a clean clone
of a committed S1 revision. Hosted app CI and manual desktop acceptance require
their own evidence.

On Ubuntu 24.04 amd64, fresh dependency resolution, analysis, dry/core tests,
architecture checks, release builds, live cases and Xvfb native flows can also run
in a disposable container. Provision the pinned Flutter SDK and documented Linux
build prerequisites, use the same source snapshot without any sibling mount,
and keep loopback fixtures isolated. Xvfb and CPU emulation must be disclosed;
neither establishes GNOME Wayland/Xorg acceptance.

The released cleanup contract permits `Association.closed` to fail when cleanup
cannot be confirmed. A repeated wait after `forceClose` can retain that failure;
the adapter bounds and handles it, preserving the Echo response/status separately.
The live release-failure scenario verifies status 0 plus a cleanup warning. It
does not inject a faulty custom transport into the socket adapter.

Recorded 2026-10-19: the complete macOS and Ubuntu 24.04.5 amd64 snapshot checks
passed against the release tag. Both platforms passed full dry gates, generated
Drift parity, 52 Flutter/22 core tests, 10 live cases, native configuration/Echo
flows and release networking/history probes, followed by production rebuilds.
Linux used CPU emulation and Xvfb; the tracker records display/foreground warnings
and deferred acceptance. The exact runtime/test/tool/manifests/native sources
match the verified snapshot; final evidence-document edits do not change them.
