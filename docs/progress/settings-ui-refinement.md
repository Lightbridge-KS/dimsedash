---
summary: Settings General card and icon theme segments, with page-wide explicit save and discard.
read_when:
  - reviewing Settings theme layout and verification
---

# Settings UI refinement

Parent: [first-preview tracker](overview-first-preview.md).
Design: [visual guidance](../../DESIGN.md) and
[surface architecture](../design/03-surface-architecture.md).

## Settled scope

General is the first card. Theme uses labeled System, Light and Dark icon
segments, with a short description of the selected draft value. Local DICOM
settings remain in a separate card. Save settings and Discard edits follow both
cards and retain their existing page-wide, atomic behavior. Theme changes require
Save; no immediate preview, schema or dependency change. Narrow or scaled layouts
stack the segments vertically while retaining labels.

## Progress

- [x] Separate cards, replace dropdown and move page-wide actions.
- [x] Update widget/native selectors and cover draft-only selection and discard.
- [x] Complete dry and native configuration checks.

Implementation `40c8908` merged in PR #2 at `08c72f0`. Manual desktop acceptance remains pending.

## Verification — 2026-11-05

Uncommitted changes on base `3a2ccd1`, including the preceding Query refinements.

- Focused Settings widget suite: 8 tests passed. Coverage includes explicit-save
  theme selection, discard restoration, disabled controls during pending saves,
  storage/conflict failures, light/dark layouts and vertical segments at 150%.
- `just format` and `just dry` passed: 137 Flutter tests, 22 core tests, analysis,
  architecture/design/secrets/dependency checks and macOS release build.
- `just native-test` passed: native configuration saves to SQLite and reopens with
  the selected appearance. The harness reported a foreground-launch warning;
  the integration test completed successfully. This is automated native evidence,
  not a new visual acceptance receipt.
- No new dependencies, database changes or networking behavior changes.

Full manual macOS/Ubuntu GNOME acceptance remains pending.

## Landed delivery — 2026-11-06

Implementation `40c8908` merged through
[PR #2](https://github.com/Lightbridge-KS/dimsedash/pull/2) at `08c72f0`.
The final pre-push dry gate passed with 143 Flutter and 22 core tests, analysis,
architecture/design/secrets/dependency checks and a macOS release build.
Commit hooks and reproducibility review passed.
[Hosted dry gates](https://github.com/Lightbridge-KS/dimsedash/actions/runs/42140287933)
passed on macOS 15 and Ubuntu 24.04, verified during this reconciliation.

The earlier uncommitted receipts above describe their original verification
checkpoints. Hosted Linux dry checks do not establish native GNOME acceptance.
Results-table work, complete S2B authoring and manual desktop acceptance remain
pending. No application code changed in this reconciliation.
