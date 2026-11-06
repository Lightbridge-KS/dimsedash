---
summary: S2A real Study Root C-FIND implementation, paired upstream contracts, verification evidence and the boundary before the complete S2B Identifier editor.
read_when:
  - implementing or reviewing real Query execution
  - checking S2A evidence and remaining S2 work
---

# S2 — Real Query

Parent: [first-preview tracker](overview-first-preview.md).

## Now / Next

S2A merged in PR #1 at `3a2ccd1`. Real Study Root Query replaces normal-app
synthetic execution. The upstream Find contract is merged and publicly pinned.
Query/Settings/editor refinements subsequently merged in PR #2 at `08c72f0`.
Release publication and desktop acceptance remain separate steps. Previous [Query preview](query-ui-preview.md) and
[refactoring](../archive/refactor/refactor-query.md) receipts remain historical evidence.

## Confirmed contracts

- Study Root STUDY, SERIES and IMAGE; explicit execution at every level.
- Full-width friendly/common advanced/resolved Identifier composer.
- Body part is optional and blank by default. It is absent at STUDY and applies
  only at SERIES; blank is never a matching restriction or a local row filter.
- One active outbound Echo or Find through cleanup; navigation observes runtime
  work and cannot pause, cancel or retarget it.
- Real results support inspection and read-only retrieval review. No synthetic
  receipt or real Get/Move execution is reachable from a real target.
- Result defaults: 1,000 rows per query, editable 1–10,000; 32 MiB accounted
  retained result payload across contexts; 1 MiB incoming Find Identifier.
  These are client limits, not a PACS workload or process-memory guarantee.
- Query datasets, literals and UIDs remain session-only. History uses a separate
  allowlist and the existing retention policy.
- S2B retains arbitrary tags, private creators and sequence authoring. S2A does
  not complete S2, retrieval, receiving or deferred desktop acceptance.

## Implementation

- [x] Verify additive upstream Find lifecycle/status/cancellation, response
  correlation, Identifier size limit and charset support contract.
- [x] Add immutable production Query model, runtime admission/ownership,
  gateway and compatible allowlisted history.
- [x] Connect common-key Query UI, streaming/pagination, hierarchy, inspection,
  settings invalidation, generalized evidence navigation and target review.
- [x] Add dry, owned-loopback live and native Query coverage; retain Echo gates.
- [x] Reconcile standing design, visual guidance, blueprint and test runbooks.

## Verification

Evidence date: **2026-11-04**. DimseDash base `43e6859`; paired dartdicom base
`53ee5ec` (`v0.1.0-dev.2`), both with uncommitted changes. Flutter **3.47.7** /
Dart **3.13.5**. The ignored local override supplies reviewed core/net/pixel
sources. Public Git pins stay at dev.2 and do not contain the additive APIs.
The tracked lockfile retains public Git sources; no sibling path is delivered.

| Gate | Result and scope |
|---|---|
| Upstream association/trace tests | 95 passed, including the additive Find contract tests |
| Upstream `mise exec -- just dry` | Passed format/analysis/boundaries, VM, web, Wasm and fixture gates; dirty core/net publish dry-runs skipped, unchanged pixel/web dry-runs passed |
| Upstream `mise exec -- just floor` | Dart 3.6 analysis and VM tests passed |
| `just format`, `just dry` | Passed: 130 Flutter tests, 22 core tests, strict architecture, design lint, secrets scan, dependency audit (114 records, no advisory/retraction failures), macOS release build |
| `just live` | 24 actual adapter/runtime loopback tests passed (Echo + Find) |
| `just native-test` | macOS isolated SQLite/configuration flow and restart passed |
| `just native-echo` | macOS real Echo, Query navigation, Settings edits, frozen evidence, retry and stop passed |
| `just native-query` | macOS real STUDY → SERIES → IMAGE, missing body part, metadata inspection, target review and restart clearing passed |
| Ubuntu 24.04.5 amd64 automated subset | In an emulated x64 container: analysis, 130 Flutter tests, 22 core tests and Linux release build passed. Final Query presentation was rechecked with analysis, 14 Query tests and a release rebuild. No Linux desktop or live network gate is implied. |
| External Orthanc bundle | Two already-seeded synthetic catalog packs (`cxr-longitudinal`, `cxr-sameseries`) matched catalog study/series/instance expectations through the real app adapter. Full `dimsedash` profile verification failed because only 2/5 expected packs were complete; existing service/config/data were not changed. This scoped result does not qualify the complete profile. |
| Native visual inspection/screenshots | Completed after desktop access resumed: real synthetic Study → Series → Image, optional/empty body part, masked/revealed values, metadata inspection/Escape, frozen evidence, target review and light/dark presentation. Screenshots below. This scoped review does not close the deferred desktop acceptance checklist. |

The final local sequence ran format → dry → live → native-test → native-echo →
native-query. Native test startup initially stalled before the first frame;
establishing a frame before asynchronous setup resolved it. The native Echo peer
uses a longer controlled delay to keep the association active during navigation.
The final repeated sequence passed without manual UI intervention. Flutter still
reported a foreground warning; automated interaction completed successfully.

Resource probes cover a 10,001-response burst retaining exactly 10,000 rows,
coalesced presentation updates, shared byte-budget rejection, limit-triggered
cancellation and fragmented oversized Identifiers. These are accounting and
lifecycle checks, not total-process RSS, throughput or PACS workload guarantees.

Local command logs are scratch evidence; the maintained reproduction entry point
is [the S2A runbook](../tests/s2-query.md). Local overrides and uncommitted source
checks do not establish hosted CI, upstream publication or clean-clone delivery.

## Visual follow-up

The native review found that returning to a parent query did not refresh the
shell's latest-run strip. The shell now observes displayed-query identity changes,
so a retained child run remains reachable without another network request.
Regression assertions cover child preparation, parent return, View run and Back;
the same path is included in `native-query`. The affected dry/native gates and
Linux Query tests/build were repeated after this correction.

An initial debug process launched while its bundle was being rebuilt terminated
with a DartWorker SIGSEGV. Its root cause was not established. The subsequent
review used a single process launched from a completed build and completed the
workflow. This is recorded as a development-launch limitation, not a closed
startup/restart acceptance item. Raw OS reports remain local because they contain
environment identifiers.

All images show repository-owned synthetic fixtures and loopback endpoints:

- [Friendly criteria, dark](../design/assets/dimsedash-screenshots/s2a/query-filters-dark.png)
- [Resolved Identifier, dark](../design/assets/dimsedash-screenshots/s2a/query-resolved-dark.png)
- [Masked study results, dark](../design/assets/dimsedash-screenshots/s2a/query-results-masked-dark.png)
- [Series with empty body part, dark](../design/assets/dimsedash-screenshots/s2a/query-series-dark.png)
- [Returned metadata, dark](../design/assets/dimsedash-screenshots/s2a/query-inspection-dark.png)
- [Single-instance target review, dark](../design/assets/dimsedash-screenshots/s2a/retrieve-review-dark.png)
- [Frozen IMAGE evidence, dark](../design/assets/dimsedash-screenshots/s2a/query-evidence-dark.png)
- [Retained instance selection, light](../design/assets/dimsedash-screenshots/s2a/query-instance-light.png)
- [Restored study and latest child run, light](../design/assets/dimsedash-screenshots/s2a/query-study-light.png)

## Deferred

S2B structured editor; S3–S6 receiving/retrieval/pixels; S7 full history browsing;
upstream release publication; clean-clone delivery;
manual macOS and Ubuntu GNOME Wayland/Xorg acceptance.

## Public dependency delivery (2026-11-05)

Upstream [PR #1](https://github.com/Lightbridge-KS/dartdicom/pull/1) merged at
`32f0f90f4cd36cb643663c23b2b47943c9b0f7c5`. Every active Git dependency now pins
that commit. Local overrides are disabled for delivery verification; the locked
public packages supply the Find APIs. Package versions remain dev.2, with the
commit recorded separately in generated diagnostic provenance. Earlier local
receipts above retain their original scope. Public-pin delivery checks passed: `just format`, `just dry` (130 Flutter and
22 core tests plus macOS release build), all-file hooks, 24 live Echo/Find cases
and `just native-query`. The default live port was occupied; the documented
alternate ports were used without changing the existing service. A relocated
staged-source snapshot passed `just setup`, analysis and provenance validation
without local overrides or sibling sources. This is source-snapshot evidence;
hosted CI and a fresh clone of the final commit remain separate checks.

Design assets now separate native screenshots under
`docs/design/assets/dimsedash-screenshots/s2a/` from historical HTML/PNG mockups
under `docs/design/assets/mockup/`. Earlier refactor receipts are archived.

## Landed delivery reconciliation — 2026-11-06

[PR #1](https://github.com/Lightbridge-KS/dimsedash/pull/1) merged at `3a2ccd1`.
Its [hosted dry gates](https://github.com/Lightbridge-KS/dimsedash/actions/runs/41887991186)
passed on macOS 15 and Ubuntu 24.04. The merge and checks were verified from
GitHub during reconciliation. Earlier source-snapshot and local receipts retain
their original scope; a fresh clone of the final commit has not been recorded.

Presentation implementation `40c8908` merged in
[PR #2](https://github.com/Lightbridge-KS/dimsedash/pull/2) at `08c72f0`.
Its [hosted dry gates](https://github.com/Lightbridge-KS/dimsedash/actions/runs/42140287933)
also passed on both platforms. This includes common-key editor refinement, not
S2B arbitrary-tag/private-creator/sequence authoring. Upstream release publication,
production retrieval and deferred desktop acceptance remain pending.
