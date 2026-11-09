---
summary: Adaptive Query results table and compact rows, with explicit selection and retained-result navigation.
read_when:
  - implementing or reviewing Query result presentation
---

# Query results refinement

Parent: [first-preview tracker](overview-first-preview.md).

## Confirmed scope

Option A: table at wide widths, shared stacked cells at narrow widths. Preserve
arrival order, 50-row local pages, runtime ownership, masking and separate
inspection, child navigation and single-target selection. No sorting, filtering,
protocol, schema or dependency changes. Retrieval review remains read-only.

## Progress

- [x] Implement results panel and selection footer.
- [x] Verify responsive layout, focus, state and native Query flow.
- [x] Record dry/native gates and synthetic visual evidence.

Implementation is prepared for draft PR review. S2B, production retrieval and manual
macOS/Ubuntu GNOME acceptance remain pending.

## Implementation notes

`FindResultsPanel` receives immutable results and callbacks; `QuerySession`
remains the owner. Clear selection affects session state only. Stable interactive
cell keys retain focus across table/stacked transitions and runtime notifications.
Only the current 50-row page is rendered. Page changes focus and reveal the
results heading. Selection survives local paging and can return to its page.

Wide rows use grouped metadata and explicit actions. Narrow rows place the radio
beside the description, with metadata/actions below. Dates are formatted only
when the returned eight-digit value is a valid full calendar date. Raw inspection
and missing/empty/decode-limited distinctions are preserved.

## Verification — 2026-11-06

Uncommitted changes on base `598e009`.

- Focused results/view suites passed (12 tests). Coverage includes all hierarchy
  levels, bounded pages/off-page selection, clear selection, missing metadata,
  valid date formatting, long values, disabled invalid-identity actions, masking,
  complete/non-complete empty states and separate cleanup warnings. Focus survives
  streaming updates and table-to-stacked transitions.
- `just format`, `just dry` and `just native-query` passed sequentially after the
  final compact-row spacing adjustment. Dry: 152 Flutter tests, 22 core tests,
  analysis, architecture/design/secrets/dependency gates and macOS release build.
- Native Query used repository-owned loopback fixtures on configurable alternate
  ports. It exercised real STUDY → SERIES → IMAGE, metadata inspection, selection
  clear/reselect, read-only retrieval review, navigation/evidence and restart
  clearing. Owned fixture containers and networks were removed after completion.
- Light/dark 150% text at 760 × 600 is widget evidence. Hosted CI, Linux execution
  and full manual desktop acceptance were not performed for this refinement.

## Native visual review

An isolated native harness rendered the production results component with four
synthetic studies and no network/persistence actions. Wide light/dark tables,
selected-row highlighting and the narrow stacked layout were inspected. The
initial blank window belonged to a stale scratch build; reopening the current
harness restored rendered content. Narrow spacing was tightened after inspection,
then focused/dry/native Query gates were repeated successfully.

Captures: [light table](../design/assets/dimsedash-screenshots/query-results/table-light.jpg),
[dark table](../design/assets/dimsedash-screenshots/query-results/table-dark.jpg),
[dark stacked rows](../design/assets/dimsedash-screenshots/query-results/stacked-dark.jpg).
These are component-review captures, not full application or platform acceptance.
The synthetic harness disables retrieval; real read-only review was verified by
the native Query flow. The historical mockups are unchanged.

## Pre-commit review — 2026-11-09

Visible run-local result numbers distinguish masked or repeated descriptions in
both layouts and the selected-target footer. Regression coverage checks two
lookalike rows. Screenshot extensions now match their JPEG encoding. The captures
above predate the result-number addition; they remain layout-review evidence.
