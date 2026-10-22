---
summary: Approved full-width synthetic Retrieve preview implementation and verification tracker; production receiving and retrieval remain pending.
read_when:
  - implementing or reviewing the Retrieve UI preview
  - checking synthetic versus production retrieval evidence
---

# Retrieve UI preview

Parent: [First preview](overview-first-preview.md) · Design: [Retrieve options](../design/07-retrieve-workbench-options.md)

## Now / Next

Implemented and locally verified 2026-10-22. Option A and initial C-GET are approved. Sample folders only; receipts, header inspection and thumbnail placeholders stay inside Retrieve. No network, filesystem access, durable history or production core changes. Approved for delivery to `main` on 2026-10-22.

## Checklist

- [x] Nested Query → Retrieve review/run navigation and session restoration.
- [x] Required UID draft, method/folder/receiver preview readiness and frozen snapshots.
- [x] Fixed scenarios, truthful separate counters and synthetic object inspection.
- [x] Model/widget/native coverage and strict architecture boundary verification.
- [x] Sequential format, dry, native configuration and native Echo gates.
- [x] Running macOS UI inspection and review screenshots.
- [x] Reconcile surface, visual guidance and blueprint.

## Confirmed contracts

- C-GET is the initial method for a fresh target; no automatic fallback.
- One shell-owned in-memory session; new node, selection loss, deletion and restart clear it.
- Sample runs are explicit snapshots, not runtime operations or timers. Real Echo admission and shutdown remain independent.
- Global Received files and the actual sidebar receiver remain unchanged.
- Missing peer facts remain unknown; source-query counts are not completion denominators.

## Verification evidence

Recorded against the uncommitted implementation review tree on 2026-10-22:

| Gate | Result |
|---|---|
| Focused tests | Passed: Retrieve model/widget coverage, Query and Echo regressions, architecture negative fixtures. |
| `just format` / `just dry` | Passed: analyzer, 100 Flutter tests, 22 core tests, strict architecture/design/secrets checks, 114 dependency records with zero advisory/retraction failures, macOS release build. |
| `just native-test` | Passed: Query → Retrieve → sample headers, no Echo record, configuration persistence and absence of Query/Retrieve samples after restart. |
| `just native-echo` | Passed with repository-owned loopback fixtures on alternate ports: real Echo continues through Retrieve, preview execution stays disabled while occupied, View run/Back preserves context and configuration, settings changes and explicit retry remain intact. Owned fixtures cleaned up. |
| Native visual inspection | Inspected the running macOS app in dark/light themes: full-width review, C-MOVE sample-folder/receiver gating, frozen evidence, separate peer/local counts, masked header dialog and retained sample after Settings/library navigation. Screenshots captured. |
| `git diff --check` | Passed. |

Model/widget checks cover hierarchy and invalid UIDs, immutable edited/reset
identifiers, all seven sample scenarios, instance-only bounds, cancellation intent,
stale run IDs, settings/readiness changes, same-node restoration, deletion and
node-switch clearing, no gateway/history dispatch from samples, and 760 × 600 at
150% text scale in both themes. Existing receiver alignment coverage is retained.

The first two native Echo fixture attempts encountered occupied Docker ports;
existing services were left untouched. The successful run used
`DIMSEDASH_ORTHANC_PORT=24242 DIMSEDASH_PEER_PORT=24250 just native-echo`.
An initial navigation test exposed an offscreen All nodes tap after Query scroll
restoration; the harness now ensures that action is visible before tapping, and
the rerun passed. Native runners emitted the existing foreground-launch warning.

Local logs and review screenshots live under the ignored
`_playground/2026-10-22_retrieve-preview/outputs/` directory:
`dry.log`, `native-test.log`, `native-echo.log`, `retrieve-review-dark.png`,
`retrieve-move-ready-dark.png`, `retrieve-inspection-dark.png` and
`retrieve-evidence-light.png`. Earlier failed-attempt logs remain alongside them.
The review entry point uses isolated synthetic configuration. A copied review
bundle has a distinct temporary identifier to avoid local app-registration
ambiguity; the project's identity, normal configuration and packaged output are
unchanged. The isolated review app was stopped after review.

## Remaining scope

No real retrieval, listener, folder access, receipt persistence, decoded headers
or image pixels are implemented by this checkpoint. Production S3–S6, hosted CI
for this review tree, Linux execution of the new checks, and deferred manual
macOS / Ubuntu GNOME acceptance remain pending. Existing Query/S1 and browser
prototype receipts remain historical evidence for their tested versions.
Delivery is authorized directly to `main`; no release publication is included.
