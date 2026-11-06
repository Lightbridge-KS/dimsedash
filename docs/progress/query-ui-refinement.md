---
summary: Query composer refinement with Material tabs, adaptive criteria groups and built-in date pickers; results presentation unchanged.
read_when:
  - implementing or reviewing the Query presentation refinement
---

# Query UI refinement

Parent: [first-preview tracker](overview-first-preview.md).

## Confirmed scope

Full-width criteria with primary/secondary tabs, persistent labels and tag hints,
three adaptive columns, editable modality suggestions, independent Material date
pickers, concise help and a compact action footer. Dates remain optional and
support one-sided ranges. No new dependency, schema or public core API.
Results-table changes and manual desktop acceptance remain deferred.

## Implementation and evidence

- [x] Refine shared workbench header and Query composer.
- [x] Verify draft synchronization, dates, focus and responsive layouts.
- [x] Run dry and native configuration/Echo/Query gates.
- [x] Capture synthetic macOS review screenshots.

Implementation `40c8908` merged in PR #2 at `08c72f0`; see delivery below.

## Verification — 2026-11-05

Base: `3a2ccd1`, uncommitted refinement. Flutter 3.47.7 / Dart 3.13.5.
No manifest, dependency pin or database change.

- `just format` and `just dry` passed: 134 Flutter tests, 22 core tests,
  analysis, architecture/design/secrets/dependency gates and macOS release build.
- `just native-test`, `just native-echo` and `just native-query` passed in that
  order. Loopback fixtures used configurable alternate ports and cleaned up.
- New composer coverage verifies keyboard tab activation, three-column grouping,
  modality suggestions/custom values, omitted-key re-enabling, optional body part,
  typed/calendar/open-ended dates, invalid/reversed ranges, cancellation and
  advanced synchronization. Narrow 150% light/dark layouts and existing 760 × 600
  hierarchy/navigation tests passed. Existing result rendering remains unchanged.
- Older Echo/native assertions were updated for the new Query criteria heading.
- Native visual review used an isolated synthetic configuration. The light/dark
  composer, three-column grouping, compact footer and Material date picker were
  inspected. Escape dismissed the picker without populating a date; Settings and
  node navigation restored Query and its scroll position. No query was sent during
  this visual review.
- Review captures: [dark composer](../design/assets/dimsedash-screenshots/query-ui-refinement/composer-dark.png),
  [dark footer](../design/assets/dimsedash-screenshots/query-ui-refinement/composer-footer-dark.png),
  [light composer](../design/assets/dimsedash-screenshots/query-ui-refinement/composer-light.png),
  [Material date picker](../design/assets/dimsedash-screenshots/query-ui-refinement/material-date-picker-dark.png).

Automated checks do not close manual macOS or Ubuntu GNOME acceptance. No hosted
CI or Linux run was performed for this presentation refinement.

## Input alignment follow-up — 2026-11-05

Date, modality and body-part groups now share an above-input heading layout.
Modality and body-part inputs no longer repeat their heading in the border;
accessible input names remain available. Equal padding aligns the input borders,
while tag hints, clear actions and validation grow below. Narrow layouts keep
natural heading spacing without adding alignment-only spacers.

- Focused composer tests passed (6), including input-border alignment at 100% and
  150% text scale before and after date errors and omitted-key state changes.
- `just format` and `just dry` passed for this follow-up: 136 Flutter tests,
  22 core tests, analysis, architecture/design/secrets/dependency checks and macOS
  release build. Earlier native receipts and screenshots above predate this
  alignment adjustment; native service flows were not repeated for this layout-only change.

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
