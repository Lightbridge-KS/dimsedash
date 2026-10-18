---
summary: S0 configuration scenarios, local and Ubuntu 24.04 verification evidence, and outstanding native desktop acceptance.
read_when:
  - verifying or continuing S0
  - distinguishing automated configuration checks from desktop acceptance
---

# S0 — configuration verification

Parent: [implementation tracker](../progress/overview-first-preview.md).
Setup and tool pins: [development](../dev/development.md).

## Repeatable scenarios

| Scenario | Check |
|---|---|
| Initial startup | Empty node list, `DIMSE_DASH`, editable listen port, receiver stopped, values masked; no automatic network work |
| Save/reopen | Enter synthetic node name, `PACS_AET`, `192.0.2.1:104`, `TEST_CLIENT`, listen port `11113`; Apply, reopen storage and compare every field |
| Invalid input | Empty/long/non-ASCII/backslash AE, malformed address and ports outside 1–65535 cannot save |
| Discard | Unsaved edits revert to the applied snapshot |
| Atomicity | Force a SQLite write failure after the node update; neither node nor client settings changes |
| Revisions | Reject a stale draft; preserve node ID; increment node revision only for node changes |
| Shutdown | Drain an accepted save, reject new work after close begins, reopen the result |
| Unsafe startup | Refuse a newer schema and preserve a corrupt file byte-for-byte; never reset |
| Single writer | A second OS process cannot acquire the lock until the owner releases it |
| Architecture | Reject UI→adapter imports/exports, conditional bypasses, core effects, private APIs, escaping parts and unscaffolded trees |
| Presentation | Explicit Apply, Discard, validation feedback, new-scope reveal reset and long node labels at a 760×600 window |

`just test` runs core, storage, architecture and widget checks. `just native-test`
runs the UI against native SQLite using a temporary support directory. It tears
down and recreates the runtime and widget tree; it is **not** an OS process restart.
Synthetic text input is registered explicitly so desktop IME events cannot replace
injected test values. Real keyboard behavior therefore remains a separate check.

## Evidence — 2026-10-19

The initial implementation is recorded in `fdaf6d4`. Results below are local
evidence; no hosted CI success or signed/installed distribution is claimed.
The publication gate reran `just dry` successfully: 43 tests, static checks,
secret/advisory scans and a macOS release build.

| Environment/check | Result | Limit |
|---|---|---|
| Flutter 3.47.7 / Dart 3.13.5 | Workspace resolves with enforced lockfile | Pins do not establish every supported desktop behavior |
| macOS 15.7.7 arm64, Xcode 16.4 | Debug and release builds; automated UI → SQLite → runtime reopen passes | Development bundle, no notarized DMG |
| Ubuntu 24.04 amd64 isolated container | Analysis, architecture, core/storage/widget tests and release build pass; Xvfb GTK integration flow passes | No stock GNOME desktop, Wayland session or package installation |
| macOS release smoke inspection | Idle shell, Settings and validation feedback visibly render; clean relaunch restores unsaved defaults | Automation of native field replacement was inconclusive; no claim of a completed real-keyboard save/process-restart round-trip |
| Local quality checks | Formatting, analysis, positive/negative architecture checks, design lint, hooks and secret scan pass | CI workflow is authored but has not run on GitHub |
| Dependency advisory check | Pub reports 114 package records with no current advisory/retraction failures | Time-bound registry result; does not audit Git source |

Raw local logs and the release screenshot are in the ignored
`_playground/2026-10-19_s0/outputs/` session. The durable summary above is the
portable evidence; those scratch files are not required to build the project.
The disposable Linux test environment was removed after collecting its results.

The final sidebar scrolling/minimum-window refinement has a local widget regression
check. The Linux build/integration result predates that presentation-only refinement;
repeat the final tree's native checks during desktop acceptance.

## Outstanding S0 acceptance

1. On macOS 15 arm64, use real keyboard input to configure, Apply, quit the entire
   release process and relaunch. Verify all five fields, Discard, theme persistence,
   reset reveal state and idle receiver. Repeat invalid input and narrow-window use.
2. On stock Ubuntu Desktop 24.04 amd64, repeat the same workflow in **both Wayland
   and Xorg** sessions. Include focus, keyboard shortcuts, close/relaunch and rendering.
3. Record the source revision for each remaining native acceptance run. Do not
   mark S0 complete from a container result or a successful compile alone.

Current-stable macOS release qualification, signed/notarized DMG, DEB install/upgrade/
remove and the complete DIMSE workflow remain S8 obligations. A later native OS test
cannot be inferred from the macOS 15 result.
