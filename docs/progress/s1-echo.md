---
summary: S1 implementation tracker for node management, typed Echo diagnostics, bounded history and released dartdicom verification; approved Nodes dashboard refinement and local review evidence.
read_when:
  - implementing or reviewing S1 Echo
  - checking upstream readiness and S1 verification
---

# S1 — Configure a node and diagnose Echo

Parent: [first-preview overview](overview-first-preview.md).

## Now / Next

The approved Nodes dashboard, nested workbench and global-only Settings refinements
are committed in `80ede60`. Pre-push formatting, analysis, 76 Flutter / 22 core
tests, architecture/design, secret and dependency checks passed again; commit
hooks passed. Native/release evidence is recorded below. Hosted CI for this
refinement and deferred manual desktop acceptance are not yet verified.

S1 is landed on `main` at [`40b1563`](https://github.com/Lightbridge-KS/dimsedash/commit/40b15631e2dfd7c3c10de597be47f356934c0cbf).
A fresh clone from GitHub passed the complete macOS verification matrix and stayed
clean. [Hosted CI](https://github.com/Lightbridge-KS/dimsedash/actions/runs/39249838352) passed on that exact commit for `macos-15` and
`ubuntu-24.04`. All DICOM libraries resolve to `v0.1.0-dev.2` at
`53ee5ec9c204e58382bf9235a621eb05af8d4179`, without a local override.
Implementation and automated delivery verification are complete. Manual desktop
acceptance remains pending, including the deferred S0 checks. Later slices have
not started; S1 is not an installable public-preview release.

## Nodes dashboard refinement — approved

Option A is approved (2026-10-20): a dedicated Nodes dashboard, searchable
Workbench target switcher, and left-aligned non-interactive receiver status.
[Design and comparison](../design/04-node-library-options.md).

- [x] Stable navigation and session-preserved adaptive dashboard.
- [x] Shared connection fields; explicit Add/Edit and typed save completion.
- [x] Target switching, frozen-evidence mismatch and active-run navigation.
- [x] Receiver alignment, responsive layout and keyboard/focus coverage.
- [x] Dry, native configuration and native Echo gates; UI review screenshots.
- [x] Reconcile surface/visual guidance and record verification results.

At this stage, the implementation preserved core/public persistence interfaces, schema v2, dependency
pins and runtime-owned networking. `lib/ui/node_fields.dart` shares presentation
between Settings and explicit node editors; the shell coordinates named
destinations. Hidden dashboard focus is excluded while its session state is kept.

Approved for main delivery on 2026-10-20. This refinement does not complete deferred
manual macOS or Ubuntu GNOME acceptance, or start a later implementation slice.

### Refinement verification — 2026-10-20

| Check | Observed result and scope |
|---|---|
| `just format`, `just dry` | Passed: analysis, architecture/design, secret/advisory checks, 65 Flutter tests, 22 core tests and macOS release build. No schema, dependency pin or generated persistence changes. |
| Dashboard widget coverage | 13 new scenarios cover restored selection, sorting/ties/search/filter, density/scroll preservation, empty states, persistence failures, draft validation/reload/discard, removal, active Echo target changes and explicit retry. Keyboard activation, Escape/focus restoration, named action semantics, non-button receiver alignment, long values and 760 × 600 at 150% text scale pass in light/dark. |
| `just native-test` | Passed: SQLite configuration/reopen, initial Nodes selection, card navigation and editing a node with stable identity. |
| `just native-echo` | Passed against owned loopback fixtures using configurable alternate ports: select another next-run target during Echo, edit/persist timeout, preserve frozen request, inspect evidence, retry against the new target and stop. Owned services cleaned up. |
| Native test reliability | Scroll helpers settle before input; missed taps now fail both flows. Echo verifies the entered timeout and the durable saved value, independently of frozen run settings. Foreground-launch warnings remain; automated success is not manual acceptance. |
| Running macOS UI review | Inspected cards/list, action menu/editor, Workbench target header and picker; checked Escape dismissal and light/dark appearance with an isolated synthetic database. Captured review screenshots. Native accessibility exposes receiver status as text and node menus with explicit names. |

Raw logs and screenshots are retained in ignored review scratch output. An initial
native configuration attempt was interrupted after stalling; final normal reruns
passed. The default Docker fixture port was occupied; the successful run used
`DIMSEDASH_ORTHANC_PORT=44242 DIMSEDASH_PEER_PORT=44250` without stopping the existing
service. This refinement has local macOS evidence only: no new Linux or hosted CI
run is claimed, and earlier S1 receipts remain tied to their original commit.


## Nested Nodes workbench — approved

Option A approved 2026-10-20: one Nodes destination, card entry into its
workbench, All nodes return, and separately addressable frozen-run evidence.
[Approved navigation design](../design/05-navigation-simplification.md). This
supersedes the separate Workbench destination and picker above; earlier receipts
remain evidence for that earlier implementation.

- [x] Shell-owned inner navigation, persistent library state and restored focus.
- [x] Simplified workspace header and removal of the target picker.
- [x] Shared evidence rendering, run-ID routing and independent target ownership.
- [x] Navigation/failure/race/accessibility tests and updated native flows.
- [x] Reconcile design, PRD and blueprint; run dry/native gates and capture UI.

Approved for main delivery on 2026-10-20. Manual macOS and Ubuntu GNOME acceptance stays pending.

### Nested navigation verification — 2026-10-20

| Check | Observed result and scope |
|---|---|
| `just format`, `just dry` | Passed: 71 Flutter tests, 22 core tests, analyzer, architecture/design, secret/advisory checks and macOS release build. No core API, schema or dependency changes. |
| Focused node/widget checks | 19 scenarios pass, including persisted entry, late selection completion, external selection/removal, preserved library filters/density/scroll, hidden-focus exclusion, visible/missing-card focus restoration, frozen settings, stale run IDs and stale Stop callbacks. Existing CRUD/editor/error coverage remains. |
| Constrained layout | Light/dark at 760 × 600 and 150% text scale pass with long labels/endpoints, expandable details and receiver alignment/non-button assertions. |
| `just native-test` | Passed: SQLite configuration save/reopen, initial library, card entry, All nodes return and node editing. |
| `just native-echo` | Passed: real adapter/runtime against owned loopback fixtures; Back and another node during Echo, Settings edits, run inspection, explicit retry and Stop. Fixture resources removed after completion. |
| Native UI inspection | Synthetic database: verified four sidebar destinations, card entry, All nodes return, expanded timeouts and light/dark appearance. Saved dashboard and workbench review screenshots. |

An initial native build overlapped the release build and failed on the Xcode build
database lock. Final dry → native configuration → native Echo runs were sequential
and passed. Fixture ports were configured through the existing runner; unrelated
services were not changed. Logs and screenshots are retained in ignored review
output. Prior dashboard receipts remain above; no new Linux/hosted CI or manual
desktop acceptance is claimed by this local refinement.

## Global-only Settings — approved

Approved: remote node configuration belongs in Nodes only. Settings retains
calling AE, listening port, global timeouts and appearance, with Save settings.
A dedicated client-settings write preserves nodes, selection and node revisions;
configuration revision/conflict checks still apply. No schema migration is needed.

- [x] Remove remote fields and relocate C-MOVE guidance.
- [x] Verify global-only persistence, failures and stale edits.
- [x] Update native flows, design docs and run dry/native gates.

Verification (2026-10-20): `just format` and `just dry` passed, including 76 Flutter
and 22 core tests, static analysis, architecture/design/secrets/dependency checks
and the macOS release build. `just native-test` passed (12 seconds); the launcher's
foreground warning did not prevent the test. `just native-echo` passed (7 seconds),
including Settings edits during a frozen Echo and explicit retry; owned fixtures
were cleaned up. The gates ran sequentially. Persistence tests prohibit node writes
with database triggers and verify selected/unselected saves, reopen, stale/invalid
input and storage rollback. Widget checks include no-node Settings, retained failure
drafts, explicit reload, and light/dark minimum size at 150% text scale.
Native light/dark Settings layouts were inspected using a temporary synthetic
database; review screenshots are retained in ignored playground output.

Approved for main delivery on 2026-10-20; manual macOS and Ubuntu GNOME acceptance remains
pending. These local receipts do not replace the earlier verification records or
claim new Linux/hosted CI evidence.

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
- [x] Record the app implementation commit, committed-clone checks and hosted app CI: `40b1563`; receipts below.

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
CPU emulation. Neither mounts a sibling library checkout. This snapshot phase
did not claim a committed S1 clean clone or hosted app CI; the landed verification
below supplies those receipts. Library Git roots, versions, clean
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

## Landed implementation and clean-clone verification — 2026-10-19

Implementation: [`40b15631e2dfd7c3c10de597be47f356934c0cbf`](https://github.com/Lightbridge-KS/dimsedash/commit/40b15631e2dfd7c3c10de597be47f356934c0cbf)
(`feat: add node management and Echo diagnostics`), pushed directly to `main`.
The following checks use a fresh HTTPS clone from GitHub at that commit, a separate
package cache, and the pinned Flutter 3.47.7 / Dart 3.13.5 SDK on macOS 15.7.7 arm64.
No sibling source, filesystem dependency override, copied package configuration or build
output is used. The clone is clean before and after all checks.

| Check | Observed result |
|---|---|
| `just setup`, `just hooks`, provenance checks | Enforced lockfile resolution and hook installation passed. All three libraries resolve from Git at `53ee5ec`, version `0.1.0-dev.2`; library checkouts are clean. |
| `just generate` and generated-source diff | Passed; committed Drift source is unchanged. |
| `just dry` | Passed formatting, analysis, architecture/design, secret/advisory checks, 52 Flutter + 22 core tests, and macOS release build. |
| `just live` | All 10 real-adapter/runtime scenarios passed. |
| `just native-test`, `just native-echo` | Both native flows passed. Foreground-launch warning remains an automated-test limitation. |
| `just native-echo-release`, then `just build` | Real release Echo/history probe passed; production entrypoint restored. Built production entitlements include `com.apple.security.network.client`. |
| Final provenance and `git status --porcelain` | Passed; lockfile, generated versions and all tracked sources unchanged; no untracked files. Owned fixtures removed. |
| [Hosted Dry gates](https://github.com/Lightbridge-KS/dimsedash/actions/runs/39249838352) | Both `dry (macos-15)` and `dry (ubuntu-24.04)` passed on implementation commit `40b1563`, including generated-source parity and release builds. |

The 110 non-documentation runtime/test/tool/manifest/native and supporting files
in this commit match the previously verified released-dependency snapshot by
content hash. Earlier Ubuntu Xvfb/live/release evidence therefore has identical
source inputs, but remains snapshot/container evidence; hosted Ubuntu dry gates
are independently tied to the implementation commit. No GNOME or physical-keyboard
acceptance is inferred from either. The implementation receipt remains pinned to
`40b1563`; evidence-only documentation updates use the normal push CI workflow.

## Remaining acceptance

- S0 real-keyboard/process-restart and stock Ubuntu 24.04 GNOME Wayland/Xorg
  acceptance remain pending and deferred.
- Manual desktop acceptance remains pending. Automated native/live checks do not
  establish it.
- Release signing/notarization, packaging and installed-artifact qualification
  remain S8 work. No app release or later slice is included in this delivery.
