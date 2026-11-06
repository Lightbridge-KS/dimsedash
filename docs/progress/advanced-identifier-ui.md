---
summary: Compact Advanced Identifier table and stacked editor for common Query keys, with explicit retained-value states.
read_when:
  - implementing or reviewing the Advanced Identifier presentation
---

# Advanced Identifier UI refinement

Parent: [first-preview tracker](overview-first-preview.md).

## Confirmed scope

A Query-specific Table editor with Include, DICOM attribute, Purpose and Value
columns adapts to stacked rows at narrow widths. QuerySession retains the single
canonical draft. Required, app-added and automatic fields remain read-only.
Saved values are read-only until included and set to Match. Return-only values
are sent empty; omitted keys are not sent. Body part at STUDY is a separate
next-series draft. Arbitrary tags/sequences and results-table changes remain
out of scope. No dependencies, schema or public core API changes.

## Progress

- [x] Implement editor, shared field and composer integration.
- [x] Verify state, masking, focus, responsive layout and native Query flow.
- [x] Run format/dry/native-query and capture synthetic native screenshots.

Implementation `40c8908` merged in PR #2 at `08c72f0`; see delivery below.
Manual desktop acceptance remains pending.

## Verification — 2026-11-05

Uncommitted on base `3a2ccd1`, including earlier Query and Settings refinements.

- Focused editor/composer suites passed. New editor coverage verifies Match,
  Return only and Omitted without value loss, masked saved values, hierarchy and
  automatic fields, optional pending body part, invalid friendly dates, DA edits,
  focus/caret preservation during runtime notifications and resizing, and narrow
  light/dark layouts at 150% text scale.
- `just format` and `just dry` passed: 143 Flutter tests, 22 core tests, analysis,
  architecture/design/secrets/dependency checks and macOS release build.
- `just native-query` passed with owned loopback fixtures: friendly input →
  Advanced edit → Resolved view → real STUDY/SERIES/IMAGE requests → read-only
  retrieval review → restart clearing. The native test explicitly settles text
  entry before switching panels. Fixture containers/network were cleaned up.
- Native dark-theme review verified the table and narrow stacked layout with
  synthetic configuration and a masked synthetic Patient ID. A clipped Return
  only dropdown label was corrected through compact typography/padding; the full
  dry gate passed again afterward. Native Query passed before that styling-only
  adjustment. Light/dark and 150% layout coverage is automated widget evidence.
- Captures: [table](../design/assets/dimsedash-screenshots/advanced-identifier/table-dark.png)
  and [stacked layout](../design/assets/dimsedash-screenshots/advanced-identifier/stacked-dark.png).
  No query was sent during screenshot inspection. Further screenshot framing
  stopped after intermittent desktop-tool window-access failures; the saved
  images document the inspected layouts.

These checks do not complete S2B authoring, production retrieval, hosted CI,
Linux testing or deferred manual desktop acceptance.

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
