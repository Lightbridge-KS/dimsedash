---
summary: Behavior-preserving Retrieve model/controller and presentation extraction, compatible feature exports and verification evidence.
read_when:
  - reviewing or continuing Retrieve refactoring
status: complete
date: 2026-10-22
---

# Retrieve refactoring

Parent: [First-preview tracker](../overview-first-preview.md) · Design: [Blueprint](../../structure/01-codebase-blueprint.md)

Baseline: `07b181a` plus the verified Query/date refactoring. Local refactoring
and verification completed 2026-10-22.

- [x] #1 Separate preview models/controller and retain public imports via exports.
- [x] #2 Extract review and frozen evidence widgets; retain route/admission/scroll ownership.
- [x] #3 Isolate receipt dialog and Retrieve-local presentation helpers.
- [x] Complete focused, differential/visual, architecture, dry and native verification.

Preserve: public declarations and constructors, settings/map equality, UID errors
and ordering, immutable snapshots, seven fixed scenarios and exact counters,
unknown versus zero, source/latest retention, sample IDs and transition guards,
shell session ownership, fresh Echo admission reads, stale-route checks,
review/run scroll, field/disclosure keys, expansion state, live dialog masking,
object reveal and all layout/copy values. Query and Retrieve remain independent.
No dependencies, core APIs, schemas, files or networking are introduced.

Proof: original-test-name comparison, old-code characterization, model matrix,
map differential against Flutter, parsed-source comparison, export identity,
architecture violations/mutations, dark/light and minimum-scaled visual snapshots,
`just dry`, native configuration and native Echo checks.

## Not picked

- No shared Query/Retrieve widget framework; their presentation differs.
- No additional test harness; existing Query workbench support has two consumers.
- No production retrieval/receiving/storage abstraction ahead of S3–S6.

## Evidence

- All 108 pre-Retrieve Flutter test names/results are retained. Eight additional
  cases bring the final dry count to 116 Flutter plus 22 core tests: inspection,
  failed-save handling, scroll/disclosures, map equality, public export identity
  and three Retrieve architecture cases. Original Query/date sources and its
  date regression tests remain byte-identical.
- The new inspection/scroll/map characterization passes against the original
  Retrieve code and after extraction. UID-map and timeout comparisons match
  Flutter's prior entry-equality behavior across 250 seeded pairs each.
- Ten original model/controller declarations retain identical parsed source after
  normalizing the two helper call names. Public view construction, review/run
  scroll lifecycle, private dialog classes and original test statements match.
- A 63-case before/after matrix matches exactly: 36 scope/method/scenario
  combinations and 27 UID-boundary cases, including statuses, identifiers,
  validation messages, peer/local counters, nulls and synthetic receipts.
- All 36 pre/post visual comparisons match: dark/light, wide and 760 × 600 at
  150% scale, review, MOVE Identifier, receiving evidence, receipts, revealed and
  masked headers, unsupported/revealed thumbnails and failed-save inspection.
  Fixtures remain ignored exploratory evidence rather than a new CI golden gate.
- Independent review found no actionable regressions. Eight deliberate mutations
  are rejected: internal-import bypass, cycle omission, model presentation
  dependency, missing view export, weakened map equality, stale dialog masking,
  exposed failed-save data and discarded scroll restoration. Mutations are
  restored byte-for-byte.
- `just dry` passes after the model split, UI extraction and final structure:
  format/analysis, tests, strict architecture/design gates, secrets scan,
  dependency audit (114 records; no advisory/retraction failures) and macOS
  release build. Existing Query architecture cases remain intact.
- Final `just native-test` passes (18 seconds) through Query/Retrieve inspection,
  SQLite reopen and preview clearing. `just native-echo` passes (15 seconds)
  with repository-owned loopback fixtures, preserving real Echo ownership and
  admission through Retrieve navigation. Owned containers/network/helper are
  cleaned up. Both runners emit the existing foreground-launch warning; this
  does not establish manual keyboard, launch/focus or packaged acceptance.

Hosted CI, new Linux execution and manual macOS/Ubuntu GNOME acceptance have
not been verified for the delivery revision. No
production S3–S6 or release acceptance is implied.
