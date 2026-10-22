---
summary: Approved Option A Flutter Query UI preview implementation; synthetic responses only, with production S2 networking and complete Identifier editing still pending.
read_when:
  - implementing or reviewing the Query UI preview
  - distinguishing preview checks from S2 protocol acceptance
---

# Query UI preview

Parent: [First-preview tracker](overview-first-preview.md#s2--query-with-friendly-and-exact-identifiers)
Design: [Query options](../design/06-query-workbench-options.md)

## Now / Next

Implemented and locally verified 2026-10-22: Option A in the normal app with a synthetic-data banner, common editable keys and illustrative arbitrary-tag/sequence sketches. Fixed complete/empty/partial/rejection fixtures do not evaluate criteria. The UI preview is approved for delivery to `main`; production S2 remains pending.

- [x] In-memory preview model/controller, immutable request snapshots and scoped hierarchy.
- [x] Shared node header, Echo/Query switch and retained preview session.
- [x] Full-width composer, results, inspection and retrieval handoff.
- [x] Focused state/widget/native coverage and Echo isolation checks.
- [x] Format, dry, native configuration and native Echo gates.
- [x] Native visual inspection, screenshots and documentation reconciliation.

## Confirmed contracts

No networking, durable query/history writes, schema/dependency changes or core public API additions. The shell retains one preview session for the selected node across navigation, clearing it on node change/removal/selection loss. Echo remains runtime-owned. Query preview cannot stop, retarget or replace it. Real Echo admission disables preview Run until cleanup finishes.

Friendly and common advanced controls share one draft. Return/disabled/matching intent is explicit. Body part is pending at STUDY and included only in SERIES. Opening a child sends nothing and loads no fixtures. An explicit preview run freezes its Identifier and effective connection settings. The original read-only retrieval handoff is superseded by the [synthetic Retrieve workspace](retrieve-ui-preview.md); it still cannot transfer files. Prior verification receipts below describe the original Query implementation.

## Verification evidence

Recorded 2026-10-22 against the implementation review tree:

| Gate | Result |
|---|---|
| `just format` | Passed. |
| `just dry` | Passed: analyzer, 89 Flutter tests, 22 core tests, architecture/design/secrets gates, dependency audit (114 records; zero advisory/retraction failures), macOS release build. |
| Focused Echo regression after the dry run | 3 tests passed; additionally verifies sample generation leaves gateway dispatch count, run summaries/events and latest Echo identity unchanged. |
| `just native-test` | Passed; configuration lifecycle includes preview generation and absence of sample results after restart. |
| `just native-echo` | Passed with repository-owned loopback fixtures; active Echo remains independent while Query is visible. Owned fixture containers were removed. |
| Native visual inspection | Dark/light app inspection with an isolated synthetic configuration. Confirmed explicit preview execution, complete rows, collapsed composer, receiver alignment and retention across Settings/library navigation. Screenshots captured. |
| Pre-commit verification | Format, analyzer and all Flutter/core tests passed again before delivery. |
| `git diff --check` | Passed. |

Widget checks include 760 × 600 at 150% text scale, dark/light themes, keyboard/dialog dismissal, masking, date validation, shared key intent, hierarchy, frozen settings and session resets. A scaled result-row overflow discovered during development was corrected before the passing gates. Native runners emitted a foreground-launch warning, but both integration suites completed successfully; the app was subsequently opened and inspected through native UI control.

Local logs and screenshots are retained under the ignored `_playground/2026-10-22_query-preview/outputs/` directory (`dry.log`, `native-test.log`, `native-echo.log`, `query-dark.png`, `query-results-dark.png`, `query-results-light.png`). The synthetic review entry point uses an isolated temporary database and does not alter ordinary application configuration.

## Remaining scope

Production S2, complete tag/sequence editing and VR/private-creator validation, actual C-FIND/C-GET/C-MOVE, hosted CI for this review tree, and manual macOS/Ubuntu GNOME acceptance remain pending. Fixed fixtures do not filter against criteria or establish protocol correctness. Existing S1 receipts remain evidence for their tested versions. The isolated review app was stopped before delivery to `main`.
