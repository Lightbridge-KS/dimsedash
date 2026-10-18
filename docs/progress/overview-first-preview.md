---
summary: First-preview implementation plan and durable vertical-slice tracker for DimseDash; approved design baseline, dependencies, acceptance gates, upstream readiness, evidence ledger and remaining release decisions. S0 implementation is in progress.
read_when:
  - starting or resuming DimseDash implementation
  - choosing the next vertical slice or recording completion evidence
  - checking preview readiness, dependencies or deferred scope
---

# DimseDash — First-preview implementation tracker

> Created: 2026-10-19 · Status: implementation sequence and design baseline approved; platform baseline approved · Implementation: S0 in progress
>
> Inputs: [PRD](../req/dimsedash-prd.md) · [System](../design/01-system-architecture.md) · [Data](../design/02-data-architecture.md) · [Surface](../design/03-surface-architecture.md) · [Codebase blueprint](../structure/01-codebase-blueprint.md)

This is the durable implementation plan and status record. Architecture remains in the linked documents. Checkboxes below mean implemented and verified, not merely designed. At tracker creation there was no application or executable gate. S0 now has a scaffold, dependency lock, persistent Settings, architecture checks and local verification; the evidence ledger distinguishes these from remaining native acceptance. Initial implementation is recorded in `fdaf6d4`; no published release exists. Writing this plan does not authorize publishing a release or claim upstream changes have landed.

## Now / Next

**Now:** the S0–S8 sequence and Study Root-only preview scope are approved (2026-10-19). The platform/distribution baseline is approved (2026-10-19). The updated Settings design is approved (2026-10-19), including editable calling/called AE titles, PACS IP/port, client listening port and `DIMSE_DASH` as the default local AE. S0 implementation is authorized and in progress; no later slice is active.

**Active:** S0 — shell, persistent Settings, failure handling and executable gates are implemented. Automated UI/SQLite checks pass on macOS and Ubuntu 24.04 under Xvfb. Remaining native acceptance is pending and deferred for now (2026-10-19): real-keyboard/process-restart acceptance on macOS and stock Ubuntu 24.04 GNOME Wayland/Xorg acceptance. The support baseline is unchanged. See [S0 evidence/runbook](../tests/s0-configuration.md). S1 then makes Echo the first real network tracer bullet; Echo alone is not a public-preview release.

**Preview finish line:** configure → Find → select one study/series/instance → review exact Identifier → C-GET or C-MOVE → receive/save → inspect headers and a supported thumbnail → inspect/export truthful evidence. The complete workflow must run in packaged macOS and Linux apps with failure, retention and restart behavior verified.

## Settled contracts

- [x] Platform/distribution baseline approved (2026-10-19): macOS 15 arm64 and Ubuntu Desktop 24.04 amd64; signed/notarized DMG and DEB.
- [x] PRD direction, complete retrieval workflow and basic thumbnails approved.
- [x] S0–S8 vertical-slice sequence and Study Root-only preview scope approved (2026-10-19); Patient Root, MWL, standalone Store sending and third-party Move destinations remain deferred.
- [x] System choices approved: root Flutter app/private Dart core, Riverpod only in Flutter, one active outbound retrieve and bounded independent receiving.
- [x] Storage choices approved: Drift/native SQLite; separate per-delivery files; independent history/inventory lifetimes and the recorded retention budgets.
- [x] Advanced Identifier editor included; local rule engine deferred.
- [x] Surface choices approved: one target including instances, structured nested editor, mask-on-launch with separate thumbnail reveal.
- [x] Codebase blueprint approved: typed results/events, feature UI/capability core/shared adapters, conceptual types plus enforceable invariants.
- [x] Settings refinement approved: local identity/listen port separated from the selected remote node; explicit Apply/Discard and no implicit network action.

These checks record approvals only. They are not application acceptance. Implementation discoveries that change a contract must update the owning design document and link the change here; do not silently change behavior to satisfy a test. No ADR is required for routine refinement of this unshipped design.

## Decisions attached to scheduled work

| Decision | Recommendation / required outcome | Needed by |
|---|---|---|
| Platform and distribution baseline | Settled 2026-10-19; see the approved matrix below. Native verification remains an implementation gate. | S0 / S8 |

Routine engineering work is not another product fork: choose a compatible FVM SDK/dependency set during S0, validate it on both selected baselines, and record pins. Do not select a version merely because it is globally installed. Native filesystem guarantees, receive/result/worker caps and shutdown deadlines require measured evidence and documented limits; assign them to S2/S3/S6, not an arbitrary promise here.

### Settled platform/distribution baseline

Approved 2026-10-19. These are support targets; compatibility evidence and SDK pins are recorded separately.

| Dimension | Approved first-preview baseline |
|---|---|
| macOS | macOS 15 Sequoia minimum, Apple Silicon arm64; test the minimum and the current stable macOS used for release qualification. List exact tested releases; future OS releases are not automatically supported. |
| Linux | Ubuntu Desktop 24.04 LTS, amd64/x86-64, stock GNOME; test the installed app in Wayland and Xorg sessions. Build the Linux release on 24.04 to avoid accidentally requiring libraries from a newer distribution. |
| macOS artifact | Direct-download `.dmg` containing a Developer ID-signed app, notarized with its ticket stapled. Public-preview delivery requires signing access; local development/source builds can proceed before that is configured. |
| Linux artifact | `.deb` with desktop entry, icon and declared runtime dependencies; verify install, launch, upgrade and removal on clean 24.04. Do not claim general Debian-family compatibility. |
| Distribution | GitHub Release artifacts, checksums, release notes and source-build instructions. Existing CI-draft/human-publication policy remains unchanged. No in-app updater in P0. |
| Deferred matrix | Intel Macs, Linux ARM64, other distributions/desktops, Snap/Flatpak/AppImage, stores/package repositories and Windows. Newer Ubuntu LTS releases can be evaluated separately; “24.04 or later” is not blanket support. |

S0 must prove the chosen FVM/dependency combination builds and launches on these targets; specify how the minimum macOS version will actually be tested. S3–S8 must verify receive-folder access, inbound/outbound networking, restart recovery, native file dialogs, rendering and packaged behavior. macOS build-host/Xcode requirements are distinct from the minimum supported runtime OS. Early packaging smoke checks should expose dependency/entitlement failures before S8; final signing and acceptance remain S8 obligations.

Evidence: [Flutter platform matrix](https://docs.flutter.dev/reference/supported-platforms) lists Ubuntu 24.04 and macOS 15 within its supported range; its broader matrix is not an app guarantee and must be rechecked for the SDK pinned in S0. [Canonical's lifecycle](https://ubuntu.com/about/release-cycle) gives 24.04 standard security maintenance through May 2029. [Apple Developer ID](https://developer.apple.com/developer-id/) supports direct distribution with signing/notarization; [Flutter's macOS guidance](https://docs.flutter.dev/platform-integration/macos/building) requires attention to release networking entitlements. Artifact formats and the narrower CPU/desktop matrix are approved project choices.

## Sequence and dependencies

| Slice | Operator-visible increment | Depends on | Primary PRD coverage | Status |
|---|---|---|---|---|
| S0 | Launch, configure and reopen | Initial platform baseline | R-01, R-15, R-17, R-18 | In progress |
| S1 | Manage nodes and diagnose an Echo exchange | S0; U1 observations | R-01, R-02, R-11–R-13, R-15 | Not started |
| S2 | Find and inspect an exact study/series/instance subset | S1; U2 Find terminal evidence | R-03, R-04, R-09, R-12, R-16, R-19 | Not started |
| S3 | Independently receive and durably save DICOM objects | S1; U3 storage contract | R-07, R-08, R-12, R-15, R-16 | Not started |
| S4 | Retrieve a reviewed target through C-GET | S2 + S3; U2 retrieve evidence | R-04, R-06, R-08, R-12, R-19 | Not started |
| S5 | Retrieve through C-MOVE with honest callback correlation | S4; U3 originator/context evidence | R-05, R-07, R-08, R-11, R-12 | Not started |
| S6 | Inspect saved headers and basic thumbnails | S5; U4 decode behavior | R-09, R-10, R-15–R-17 | Not started |
| S7 | Revisit/export evidence and explicitly clean up files/history | S6 | R-13–R-16 | Not started |
| S8 | Install and accept the complete preview on both platforms | S7; distribution baseline | R-17, R-18 and all PRD acceptance scenarios | Not started |

S2 and S3 are structurally independent after S1, but the default execution order above keeps one slice active. No parallel work or whole-layer build is assumed. S0 is a small platform/configuration slice, not permission to generate every blueprint file. S4 completes the first Find → Retrieve → Save path; S5 adds the callback path. S6–S8 are still required for public-preview usefulness and acceptance.

## Slice checklists

### S0 — Launch, configure, close and reopen

**Demo:** launch the real desktop app, add a synthetic target, edit the five approved connection fields, apply, close and reopen. Settings persist; the receiver remains stopped; no automatic request is sent.

- [x] Select and record compatible FVM SDK, Riverpod, Drift/native SQLite and public DICOM dependency pins. Use official Flutter/Dart scaffolding for the root app/private core; add only modules needed by this slice.
- [x] Establish Git/repository basics, MIT license, contributor setup, app manifest version ownership and application lockfile. A public remote/publication is a separate delivery action; no personal filesystem dependency enters the build.
- [x] Implement the approved shell/theme and Settings through ConfigStore and real SQLite, including node/local ownership, Apply/Discard, validation, masked launch and immutable node revisions. Start with an empty node list; mockup addresses are not production defaults.
- [x] Add startup schema handling, process ownership guard, safe database-open failure and clean shutdown. Introduce migrations as schema grows; never reset a failed database silently.
- [x] Implement the blueprint AST import/dependency checker with positive/negative fixtures. Establish `just` commands, pinned runner-backed hooks and `prek`; format/analyze both packages. Create the lightweight test hub/runbook under `docs/tests/` for reusable scenarios and evidence paths.
- [ ] Build and launch on both initial native baselines; verify persistence, invalid-input rejection and idle startup. Record exact versions/platforms and any limitation.

**Exit:** real UI → configuration seam → SQLite → reopen works on both platforms; core boundary checks fail on forbidden imports. Native app behavior is verified, not inferred from cross-compilation. No network feature or speculative table family is required.


### S1 — Configure a node and diagnose Echo

**Demo:** add/edit/duplicate/find/remove nodes, explicitly Echo a controlled peer, and distinguish success, association rejection and connection failure in the evidence pane.

- [ ] Add complete P0 node management and selected-target/local-identity display; selecting a node sends nothing.
- [ ] Implement OperationRunner/RunHandle, the DICOM adapter and typed results/events using U1. Freeze request/configuration; views only observe runtime-owned subscriptions.
- [ ] Add summary/timeline/negotiation evidence from available structured observations. Show unknown when unavailable, preserve numeric status and separate facts from suggested causes.
- [ ] Persist only allowlisted bounded run/event projections. Implement the approved age/count/byte/event limits and interrupted-run recovery as history first becomes durable; prove sensitive canaries cannot leak. Full history UI waits for S7.
- [ ] Add a minimal reproducible synthetic peer/fixture setup with pinned dependencies and deterministic identities. Provide a clean-checkout demo path; an optional external Orthanc bundle profile cannot be the only test setup.
- [ ] Verify success, rejection, timeout, explicit retry, provider rebuild/navigation and quit behavior. Live Echo and native app checks run on both platforms; no reuse of library-only results as app evidence.

**Exit:** one real explicit network command yields truthful, bounded evidence and a safe retained summary. Required structured evidence is available through public APIs; trace-string parsing is not a substitute.

### S2 — Query with friendly and exact identifiers

**Demo:** query a synthetic date/modality/patient/accession subset; navigate studies → series → instances, refine a series-level body-part query, inspect returned headers, and review one instance's complete UID hierarchy.

- [ ] Build the immutable Identifier model and shared friendly/advanced editor, numeric tag/VR/value validation, matching/return-key distinction, private context, nested same-item sequence groups and resolved tree. Add capability/unknown warnings without inventing peer support.
- [ ] Implement explicit Study Root STUDY/SERIES/IMAGE Find and result navigation. Keep study versus series filter placement accurate; do not emulate unsupported remote filtering with a hidden local rule engine.
- [ ] Keep query results and literal drafts bounded in session memory; clear stale target context on applied connection changes. Separate inspector focus from target selection. Inspect nested query metadata with search and charset limitations.
- [ ] Distinguish no matches, incomplete results, final failure, limit-triggered cancellation, user cancellation and abort using U2. Check navigation/disposal cannot pause or cancel the protocol subscription.
- [ ] Verify friendly/advanced equivalence, invalid enabled entries, private/nested values, missing parent UID, exact IMAGE hierarchy, result limits and sensitive-canary exclusion. Demonstrate the actual scoped Find workflow on both platforms.

**Exit:** every displayed target is tied to its originating node/query/parents; preview equals the materialized request. No missing UID broadens selection. Complex editor capabilities are implemented here, not postponed behind a basic-filter-only preview.

### S3 — Receive independently and save safely

**Demo:** select a real receive folder, explicitly start the receiver, send a synthetic object from a controlled peer, then reopen the app and inspect its saved delivery record. Repeat with a duplicate and a failed save.

- [ ] Implement ReceiverController and explicit local AE/listen endpoint/peer rules; prevent applying incompatible configuration while receiving. Bind conflicts and rejected peers are visible; navigation never stops the listener.
- [ ] Implement ReceiveCoordinator and LocalInstanceStore: opaque delivery/file IDs, registered receive roots, durable save intents, staged Part 10 writes, no-overwrite finalization, short DB commits and startup reconciliation.
- [ ] Wire the public sink bridge so typed persistence failures cause upstream storage failure, never successful acknowledgement. Separate received, saved and acknowledgement evidence. Whole-instance buffering limits remain explicit.
- [ ] Add independent file/receipt inventory, per-delivery duplicate/conflict classification, fileless-failure retention and uncorrelated receipt states. Preserve minimal sensitive inventory separately from allowlisted history.
- [ ] Measure and enforce incoming association/work budgets; test writable/full/missing storage, SQLite failures, concurrent duplicate delivery, interruption at each save boundary, idempotent recovery and bounded shutdown. Existing files are never evicted to admit new ones.
- [ ] Verify external Echo/Store, selected-folder access, finalized bytes and restart recovery in native macOS/Linux apps against synthetic peers.

**Exit:** failed saves cannot acknowledge success; receipt inventory survives history removal and restart. Recovery and resource admission are part of this slice, not deferred to S8.

### S4 — Find → C-GET → saved objects

**Demo:** query, select one study/series/instance, review the exact target and receive folder, retrieve through C-GET with the standalone listener stopped, and see linked delivery/save counts.

- [ ] Implement RetrieveTarget/review, UID-based advanced edits and stale-revision rejection; exclude arbitrary Find predicates. Share the same validated model with the adapter.
- [ ] Enforce one active outbound retrieve, with no automatic retry/queue. Freeze connection, target and receive root. Release admission only when ownership is settled.
- [ ] Negotiate required storage contexts/roles and connect C-GET receipt to the S3 save path with direct run context. Keep absent peer counters unknown.
- [ ] Verify exact study/series/IMAGE requests, role refusal, partial/warning outcomes, local failure, cancel-versus-abort, late callbacks, navigation and timeout. Preserve saved objects after interruption.
- [ ] Demonstrate the complete flow and reopen its inventory on both native platforms.

**Exit:** C-GET works without a separate listener; a selected instance retrieves exactly its identity in the controlled fixture. Protocol completion and local save completeness remain distinct.

### S5 — Find → C-MOVE → callback receipt

**Demo:** register the app's client AE/address/port in the synthetic PACS, start its receiver explicitly, retrieve the same fixture via C-MOVE, and inspect separate operation and inbound receipt evidence.

- [ ] Implement local destination review/readiness using the configured client AE and listening port; explain external PACS registration. Local binding alone never claims remote reachability.
- [ ] Map U3 association/originator observations to persisted correlation facts. Handle absent/reused originator IDs, ambiguous peers, unrelated/late sends and delivery after the retrieve terminal response without time-based attribution guesses.
- [ ] Exercise unknown destination, no observed callback, failed sub-operations, missing counters, simultaneous independent Store and cancellation while receiving. Preserve uncertainty and already saved files.
- [ ] Verify actual separate callback connections on both native platforms and document reproducible container/host routing for the synthetic setup.

**Exit:** Move and Get share durable receive policy but retain their different transport and correlation evidence. One active retrieve is never treated as correlation proof.

### S6 — Inspect headers and basic thumbnails

**Demo:** inspect a received object's nested headers, deliberately reveal its thumbnail, then inspect an unsupported/non-image object without losing successful-transfer evidence.

- [ ] Implement saved-object header inspection, tag/keyword/value search and file availability/reveal actions. Use InstanceStore read leases and bounded worker requests.
- [ ] Render the supported first-frame grayscale thumbnail through public upstream APIs; keep cache in bounded memory. Decode does not block storage acknowledgement or run on the UI thread.
- [ ] Implement per-object thumbnail reveal, session metadata masking/copy behavior, unsupported codec/charset/non-image states and cancellation of obsolete inspection work.
- [ ] Verify large/unsupported fixtures, worker limits, external removal, lease release on navigation and thumbnail regeneration after restart. Verify packaged Flutter image display on both platforms; the current `dartdicom_pixel` grayscale implementation is pure Dart and does not itself require a native codec library.

**Exit:** supported pixels render in the installed app; fallback is explicit and independent of storage status. No clinical viewer, multi-frame controls or persistent thumbnail catalogue is introduced.

### S7 — History, reports and intentional cleanup

**Demo:** reopen retained history, create a draft with omitted inputs clearly missing, preview/export a report, clear history while files remain, then separately preview Forget or Delete.

- [ ] Complete history inspection and draft restoration, handling missing/changed node revisions and unavailable evidence. Never auto-execute or promise exact replay of discarded criteria.
- [ ] Add versioned Markdown/JSON report projection, exact preview and explicit native save. Metadata/thumbnail reveal cannot expand its allowlist; synthetic canaries test every export route.
- [ ] Expose retention settings and eligible history cleanup; verify age/count/byte boundaries, active/pending protections and independent fileless-failure retention. Reuse S1/S3 policies rather than a second retention mechanism.
- [ ] Implement exact file-action previews, identity revalidation and lease conflicts; Forget leaves bytes, Delete records recoverable intent. Handle changed paths/symlinks, external removal, missing volumes and interrupted deletion.
- [ ] Run schema migration/backup/restore fixtures across all supported schema versions introduced so far, including newer-schema refusal; check DB failure never becomes automatic reset. Verify native export/cleanup on both platforms.

**Exit:** all P0 lifetime and export controls are usable, and cleanup cannot silently cross from history into stored DICOM files. No claims of secure erasure or de-identification.

### S8 — Packaged preview acceptance and release preparation

**Demo:** install artifacts built from the same revision on the declared macOS/Linux baselines and run the complete operator workflow plus the failure corpus from the contributor runbook.

- [ ] Complete native keyboard/focus/screen-reader labels, pane resizing, text scaling, light/dark status readability, folder permissions, process ownership and bounded quit/restart checks. Earlier slices include essential accessibility; this is full-workflow acceptance.
- [ ] Run the full dry and live suites plus native packaged checks for every PRD §9 scenario. Record exact app/library/toolchain versions, fixtures, platforms and workload/resource limits; do not substitute container success for native desktop acceptance.
- [ ] Verify a clean checkout's setup/build/demo route without private services, sibling paths, bundled patient data or runtime downloads. Finalize supported format/codec/charset and platform limitations.
- [ ] Finish release automation: app `pubspec.yaml` version as SSOT, tag/version equality check, annotated version-tag push as normal trigger, CI-created draft release from matching CHANGELOG section, human review/publication. Document signing/install formats per the approved release baseline.
- [ ] Prepare acceptance evidence and a draft release candidate. Keep engineering acceptance, distribution/signing evidence and human publication as separate recorded states.

**Exit:** all P0 acceptance rows have current evidence on both declared platforms; unresolved blocking failures prevent preview readiness. Publication remains a human release act, not an automatic consequence of passing tests.

## Upstream readiness lane

This lane buys down library gaps alongside the first affected slice. It is not a separate whole-library refactor and does not authorize editing the dependency in this planning task. Recheck the pinned public API before opening focused upstream work. Consumer adapters can proceed against typed fakes, but affected real acceptance remains blocked until public observations are available and proven.

| Item | Required public contract / evidence | Needed for | State |
|---|---|---|---|
| U1 | Structured association lifecycle, available transport milestones, negotiation and numeric reject/abort data; source/provenance without parsing formatted trace | S1 | Not verified for app acceptance |
| U2 | Find final status, cancellation/abort distinction and retrieve counter presence; subscription cancellation completion is not cancellation proof | S2, S4 | Gap recorded in PRD/blueprint; implementation pending |
| U3 | Receipt/association context, originator fields and sink acknowledgement behavior; concurrent save failure propagation | S3, S5 | Contract verification and any upstream delta pending |
| U4 | Public grayscale rendering and explicit unsupported-charset/codec behavior; packaged Flutter display on both platforms; current grayscale decoding is pure Dart | S2 headers, S6 pixels | App/platform verification pending |

When work lands upstream, record issue/PR, release or commit pin, contract tests and the consuming app revision here. Do not import upstream `src`, build a replacement DIMSE parser, or claim an unobserved fact while waiting. A placeholder “unknown” preserves truth but does not automatically satisfy a required diagnostic acceptance scenario.

## Evidence and completion rules

1. Keep one active slice in Now/Next. Create a child tracker only if a slice needs its own lifecycle; give it a `Parent:` link here.
2. Start with the user-visible scenario, implement the smallest real path through UI/core/adapters, then exercise relevant failures immediately. Add only files/schema that the slice needs.
3. **Dry:** hermetic formatting/analysis, architecture negative fixtures, invariant/adapter/widget tests, clean builds and dependency/secrets audit. Run on PR CI; no test PACS started as part of a dry check. Dependency audit mechanics are selected and documented with the toolchain.
4. **Live:** explicit synthetic peer interoperability, controlled storage/network faults and end-to-end workflows. Use one reusable scenario catalogue with stable fixture identities and expected counts.
5. **Native:** installed/packaged app behavior on each supported desktop baseline. A successful build, library test or container run is not native UI evidence. Establish parity in S0 and repeat slice-specific native checks as capabilities arrive.
6. Mark a slice complete only with its requirements, landed commit SHA(s), upstream pin if changed, dry/live/native evidence applicable to that slice and unresolved limitations recorded. Do not check future tasks merely because their interface exists.
7. Track engineering issues in GitHub when a remote exists; link issues rather than duplicating them in this document. Until then, attach precise blockers to their slice here. Do not create a second global issue list.

| Slice | Landed revision | Dry evidence | Live evidence | Native macOS / Linux | Acceptance |
|---|---|---|---|---|---|
| S0 | `fdaf6d4`; refactor `15dba15`, native harness `b8dee94` | 52 local dry tests pass; hosted macOS 15 and Ubuntu 24.04 dry jobs pass at `da80283` | No DIMSE work in scope | macOS automated native flow + release smoke / Ubuntu 24.04 Xvfb flow; GNOME acceptance pending | In progress — [evidence and remaining checks](../tests/s0-configuration.md) |
| S1 | — | Not run | Not run | Not run / Not run | Pending |
| S2 | — | Not run | Not run | Not run / Not run | Pending |
| S3 | — | Not run | Not run | Not run / Not run | Pending |
| S4 | — | Not run | Not run | Not run / Not run | Pending |
| S5 | — | Not run | Not run | Not run / Not run | Pending |
| S6 | — | Not run | Not run | Not run / Not run | Pending |
| S7 | — | Not run | Not run | Not run / Not run | Pending |
| S8 | — | Not run | Not run | Not run / Not run | Pending |

### Refactoring verification — 2026-10-19

Source revisions: `15dba15` (configuration/widgets, test organization and tooling) and
`b8dee94` (native synthetic-input focus correction). These changes preserve S0
behavior and do not complete its remaining desktop acceptance.

- Configuration validation now has a separate owner from the records, with the
  same package exports, rules, exact messages, error order and immutable results.
  Two added characterization tests pass against the original and extracted
  implementation; boundary, message and default mutations are rejected.
- Private shell sidebar/placeholder and Settings enum/connection widgets retain
  parent-owned state, controllers, callbacks and persistence. Public constructors,
  field keys, layout, masking and Settings disposal behavior are preserved.
  Added characterization tests pass against both implementations; navigation,
  subscription, draft retention, dropdown-key and save-state mutations are rejected.
- All 40 local pre/post visual comparisons pass: 16 shell snapshots at 760 × 600,
  and 24 Settings snapshots at 760 × 600 and 1200 × 1000, across light/dark and
  empty/edited/saved states. Deliberate one-pixel layout changes are rejected.
  Fixtures remain ignored exploratory evidence, not a cross-platform golden gate.
- Dry tests are grouped by owner under `tests/dry`; core tests remain package-local
  under `packages/dimsedash_core/tests`. Baseline/reorganized discovery preserves
  all 30 Flutter and 22 core test names/results. Token comparison preserves the
  23 Flutter test declarations and fixture behavior, apart from the relocated
  process-probe path. Core tests also pass independently from their package folder.
- Native source lives under `tests/native`, reached through the relative
  `integration_test` symlink. A repeated run exposed dropped synthetic input after
  focus changes; the harness now focuses fields and checks each injected value.
  All original validation/save/runtime-reopen/masking assertions remain.
  `just native-test` passes twice on macOS 15.7.7 arm64 through the alias. Flutter
  emits `Failed to foreground app; open returned 1`; automated success does not
  verify interactive foregrounding or real keyboard input.
- `tools/` replaces `tool/`; all four script bodies are unchanged. Runner, CI,
  hook, test-import and documentation paths agree. VS Code selects the FVM SDK
  and recognizes tests outside `test/`; the pinned analyzer reports no issues.
- Final `just dry` passes: formatting, analysis, 52 tests, architecture/design
  checks, secrets scan, dependency audit (114 records; zero advisory/retraction
  failures) and macOS release build. Commit hooks pass. Hosted CI, Linux execution,
  OS process restart and packaged desktop acceptance are separate evidence.
  See the [suite map](../tests/README.md) and [S0 runbook](../tests/s0-configuration.md).

## Deferred

The [PRD later-scope table](../req/dimsedash-prd.md#10-preserved-later-scope) remains authoritative: local rule engine, multi-target batching/queues, saved templates/import-export, TLS, legacy Thai, richer viewers/codecs, automation and broader service/platform scope do not enter these slices incidentally. Numeric performance targets require workload/hardware evidence before becoming acceptance thresholds. Broader vendor field evaluation follows separately authorized testing; synthetic preview gates do not prove commercial PACS conformance.

## Revision history

| Revision | Date | Change |
|---|---|---|
| 0.1 | 2026-10-19 | Record approved Settings design and propose S0–S8 with upstream dependencies, per-slice exits and a pending evidence ledger |
| 0.2 | 2026-10-19 | Record slice-plan and Study Root scope approval; propose macOS/Ubuntu support and distribution baselines for review |
| 0.3 | 2026-10-19 | Settle platform/distribution baselines and start S0; native Linux baseline verification remains distinct from container checks |
| 0.4 | 2026-10-19 | Implement S0 configuration slice and gates; record macOS and Ubuntu 24.04 automated evidence separately from pending native desktop acceptance |

## S0 acceptance continuation — 2026-10-19

Reconciled the local tracker rollback with the committed implementation and
refactoring evidence at `da80283`. Restored completed S0 implementation items and
the settled platform decision; native acceptance remains open. The remaining
macOS and Ubuntu desktop acceptance checks are deferred for now (2026-10-19).

[Hosted dry gate](https://github.com/Lightbridge-KS/dimsedash/actions/runs/39158194863)
now passes on both macOS 15 and Ubuntu 24.04 at `da80283`, including generated
source parity. A fresh local `just dry` also passes (52 tests and release build).
Ubuntu 24.04 GNOME acceptance is explicitly skipped for this continuation and
remains pending; no container or CI result substitutes for it.

The native test now also verifies invalid-draft Discard, appearance persistence
and reveal reset after reveal was enabled. The expanded `just native-test` and
subsequent analysis pass on macOS. Native UI automation could not reliably
complete real keyboard save/restart, so that acceptance remains inconclusive.
No product behavior was changed. See the [continuation evidence](../tests/s0-configuration.md#acceptance-continuation--2026-10-19).
