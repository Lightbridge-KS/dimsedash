---
summary: S1 implementation tracker for node management, typed Echo diagnostics, bounded history and released dartdicom dependency verification.
read_when:
  - implementing or reviewing S1 Echo
  - checking upstream readiness and S1 verification
---

# S1 — Configure a node and diagnose Echo

Parent: [first-preview overview](overview-first-preview.md).

## Now / Next

S1 implementation and released-dependency verification are complete locally.
Delivery to `main` is active: commit the reviewed sources, verify a fresh clone
from the remote and hosted macOS/Linux CI, then record immutable receipts here.
All DICOM libraries resolve to published `v0.1.0-dev.2` at
`53ee5ec9c204e58382bf9235a621eb05af8d4179`, without a local override.
S0 native acceptance remains deferred. S1 is not an installable public-preview
release, and no later slice has started.

## Settled contracts

- One active Echo; runtime owns subscriptions independently of presentation.
- Global editable timeouts: connect/association/DIMSE 30s, idle 60s; 1–600 seconds.
- Typed public upstream observations only; no formatted-trace parsing or invented timings.
- Stop Echo cancels establishment or aborts an association, never sends C-CANCEL.
- Frozen execution settings; future edits never rewrite observed evidence.
- History allowlist excludes endpoints, AE titles, labels, arbitrary text and payloads.
- Retention: 30 days/1,000 terminal runs; 16 KiB/event, 4 MiB/run, 64 MiB total detail.
- Five-second bounded shutdown, with Stay or Stop and quit during active work.

## Implementation checklist

- [x] U1: backward-compatible typed observations, negotiation, numeric abort data and establishment cancellation; upstream tests.
- [x] Multi-node configuration commands and global timeouts with optimistic revisions.
- [x] Schema v2, consistent migration recovery snapshot and preservation tests.
- [x] RunStore allowlist, bounded retention, interrupted-run recovery and storage failure behavior.
- [x] OperationRunner/RunHandle, owned cancellation and immutable runtime observations.
- [x] Public dartdicom adapter and outbound macOS entitlements.
- [x] Node management, Echo controls and Summary/Timeline/Negotiation/Trace views.
- [x] Deterministic dry tests, independent loopback peers and live orchestration.
- [x] macOS native/release checks; record Linux automated evidence separately.
- [x] Update owning design/runbook documents and review all uncommitted changes.
- [x] Consume the published upstream tag consistently; verify isolated sources with fresh Git dependency resolution on both platforms.
- [ ] Record the app implementation commit, committed-clone checks and hosted app CI after review.

## Initial paired verification ledger

Evidence date: 2026-10-19. macOS host: 15.7.7 arm64; Flutter 3.47.7 / Dart 3.13.5. App baseline `182e12a` and library baseline
`7f9a80d`, plus uncommitted S1 changes; no hosted CI or new commit is claimed.

| Check | Result and limit |
|---|---|
| Upstream full dry suite | Passed formatting, analysis, dependency boundaries, VM/web/Wasm and existing differential gates. Network-package publish dry-run deliberately skipped by its script while changes are uncommitted. |
| Final upstream network suite | 169 tests passed, including observer-fault isolation, rejected contexts, numeric peer fields, absent parameters and late socket cancellation. |
| macOS app dry gate | Passed analysis, architecture/design checks, secrets/advisory checks, core/UI/storage tests and production release build. Final test run: 52 Flutter and 22 core tests; includes the additional committed-WAL snapshot regression. |
| Loopback app live matrix | 10 tests passed through the real runtime/adapter: success, refusal, AE/context rejection, association/DIMSE timeout, peer abort, two stop/retry cases and release failure after status 0. |
| macOS native Echo | Passed Settings edits/navigation during an association, frozen timeout, evidence tabs and explicit retry/stop. Flutter reported a foreground-launch warning; this is automated evidence, not physical keyboard/desktop acceptance. |
| macOS release networking | Separate release probe passed real Echo and history persistence using the app runtime and release entitlements; production entrypoint rebuilt afterward. Signed production artifact includes `com.apple.security.network.client`. |
| Ubuntu 24.04 amd64 automated snapshot | Passed analysis, 47 Flutter dry tests, 22 core tests, architecture gate and Linux release build in an isolated container under CPU emulation. Later shared-Dart history/omission/handle hardening, provider rebuild handling and extra close/WAL tests are covered by the final macOS checks. |
| Ubuntu Xvfb native/live | Configuration native test, 10 app live cases and native Echo navigation/settings/retry/stop test passed. Xvfb is not GNOME Wayland/Xorg acceptance. |

The [runbook](../tests/s1-echo.md) owns reproducible commands and fixture versions.
Ignored scratch outputs preserve local logs and the Linux source snapshot; they
are not committed artifacts or hosted CI receipts. Protocol outcomes, cleanup,
persistence availability and recovery provenance remain distinct.

Implementation review notes:

- One runtime-owned Echo, immutable resolved configuration, local stop intent and
  transport cleanup completion govern admission. Timings use monotonic elapsed
  measurements; persisted timestamps remain UTC wall-clock facts. A stale handle
  cannot stop a later retry, and provider rebuilds cannot miss terminal state.
- SQLite history projections validate protocol UID fields independently of the
  adapter, omit arbitrary text and record detail loss. The write queue is bounded
  as well as the latest live evidence window.
- Malformed old schemas fail inside migration; recovery-file presence is reported
  and blocks writes. The original data is never reset.
- The initial paired verification used an ignored filesystem override. The release
  migration below supersedes that dependency state; the original override is
  retained only as ignored scratch material and is disabled.
- Full history browsing is still S7; query/retrieve/receiver workflows remain
  later slices. No C-CANCEL-ECHO, TLS or local rule engine was added.

## Released dependency verification — 2026-10-19

The [GitHub prerelease](https://github.com/Lightbridge-KS/dartdicom/releases/tag/v0.1.0-dev.2)
is published, GitHub-only. All three consumed packages are version
`0.1.0-dev.2`, source `git`, with literal tag `v0.1.0-dev.2` and resolved commit
`53ee5ec9c204e58382bf9235a621eb05af8d4179`. The required root `dartdicom`
override remains a Git source. The filesystem override is disabled. Generated
library provenance is `0.1.0-dev.2@53ee5ec9c204e58382bf9235a621eb05af8d4179`.

Source provenance: app baseline `182e12a` plus uncommitted S1 and migration
changes. An isolated snapshot contains tracked and non-ignored new files, with
a temporary Git index for secret scanning and no implementation commit. macOS 15.7.7 arm64 uses Flutter 3.47.7 / Dart 3.13.5 and a fresh package cache;
Linux uses the same SDK in a fresh Ubuntu 24.04.5 amd64 container under
CPU emulation. Neither mounts a sibling library checkout. No committed S1 clean
clone or hosted app CI result is claimed. Library Git roots, versions, clean
status and resolved revision are checked independently of generated app text.

| Check | Result and limit |
|---|---|
| Working-copy `fvm flutter pub get`, `just versions`, `just dry` | Passed; all four dependency refs updated together, 52 Flutter and 22 core tests plus macOS production release build. |
| Isolated macOS `just setup`, `just dry`, `just generate` | Passed with fresh package cache and enforced lock; 52 Flutter and 22 core tests, analysis, architecture/design, secrets/advisory, build and unchanged generated Drift source. |
| Isolated macOS `just live` | All 10 runtime/real-adapter scenarios passed against the released Git source. |
| Isolated macOS `just native-test`, `just native-echo` | Both native scenarios passed, including navigation/Settings during Echo and retry/stop. Foreground-launch warning remains; this is automated UI evidence. |
| Isolated macOS `just native-echo-release`, then `just build` | Release Echo/history probe passed; production entrypoint rebuilt. Built production entitlements contain `com.apple.security.network.client`. Signing/notarization acceptance is not claimed. |
| macOS source/provenance checks after gates | Lockfile and generated build versions unchanged; all three library roots use a clean Git checkout at the release commit, with no filesystem overrides. |
| Released-source Ubuntu 24.04.5 amd64 | Full `just dry`, enforced setup and generated Drift parity passed: 52 Flutter + 22 core tests, formatting, analysis, architecture/design, secrets, 114 dependency-advisory records with zero failures, and production release build. Fresh container under CPU emulation; lockfile hash unchanged before/after all checks. |
| Ubuntu Xvfb/native/live/release | Configuration and Echo native flows, all 10 runtime/adapter live scenarios, and release Echo/history probe passed; production entrypoint rebuilt. Headless display/accessibility warnings are logged; GNOME desktop behavior is not established. |

Compatibility fix: `Association.closed` can retain an unconfirmed-cleanup error
after `forceClose`. The adapter now bounds and handles the second wait, preserving
observed DIMSE status and cleanup failure separately instead of leaking an error
from `finally`. The live matrix verifies status 0 followed by release failure;
it does not inject a faulty custom transport into the app socket adapter.
Outgoing DIMSE observations mean first-PDU transport submission, not peer receipt.

Commands and source-snapshot procedure: [S1 runbook](../tests/s1-echo.md#released-dependency-and-isolated-source-verification).
Raw logs, source hashes and dependency receipts remain in ignored scratch output.
The runtime/test sources and dependency files must match the verified snapshot;
subsequent tracker/runbook text changes are documentation only.

## Pending delivery / acceptance

- Upstream publication is complete. All four manifest refs and three lock entries
  use `v0.1.0-dev.2` at `53ee5ec9c204e58382bf9235a621eb05af8d4179`.
  Released-dependency checks above passed; DimseDash remains uncommitted.
- A committed S1 clean clone and hosted app CI remain pending until the app changes land. The isolated snapshots include uncommitted sources and are not substitute commit receipts.
- S0 real-keyboard/process-restart and Ubuntu GNOME Wayland/Xorg acceptance remain deferred.
- S1 automated native/live evidence is recorded above; manual desktop acceptance, release signing/notarization and packaging are not inferred from it.
