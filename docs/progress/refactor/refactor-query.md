---
summary: Query preview modularization and a separately verified friendly-date validation correction; behavior and public imports preserved during extraction.
read_when:
  - reviewing or continuing Query refactoring and date-input verification
status: complete
date: 2026-10-22
---

# Query refactoring

Parent: [First-preview tracker](../overview-first-preview.md) · Design: [Blueprint](../../structure/01-codebase-blueprint.md)

Baseline: `07b181a`. Local refactoring and verification completed 2026-10-22.

- [x] #1 Separate preview models and session controller behind compatible exports.
- [x] #2 Extract composer, results/inspection and frozen evidence presentation.
- [x] #3 Move the shared Query/Retrieve test harness to test support.
- [x] Verify behavior-preserving changes with dry gates and native configuration/Echo checks.
- [x] Separately reject malformed friendly-date separators; retain blank bounds, valid dates/ranges and Advanced DA input. Test again.

Preserve: public import paths and declarations, constructors, validation messages and ordering, Identifier text/order, immutable snapshots, fixture values and row identity, hierarchy restoration, shell-owned session, provider/scroll/focus lifecycle, form keys and revision, masking, layout and callback payloads. No dependencies, core API, schema, network or persistence changes.

Proof: baseline test-name/results comparison, pure-move comparison, public export identity checks, architecture negative fixtures, focused Query/Retrieve/Echo tests, pre/post light/dark and narrow/scaled visual comparisons, full dry gates and native configuration/Echo checks. Date correction has its own regression evidence.

## Not picked

- Keep the small fixture generator private to the controller; a separate provider abstraction has no second consumer.
- Defer production core Query contracts and runtime execution to S2.
- Keep Query presentation helpers feature-local; no generic UI framework or per-control files.

## Evidence

Refactor phase, before the date behavior change:

- All 100 baseline Flutter test names/results are retained; four added export and
  architecture cases bring the dry count to 104 Flutter plus 22 core tests.
- Fifteen original model/controller declarations, the handoff alias, shared
  harness and original Query/Retrieve test bodies have identical parsed source.
- All 24 visual comparisons pass: dark/light, wide/minimum scaled layouts, empty
  composer, Advanced/Resolved Identifier, results, inspection and series evidence.
- `just dry` passes, including analysis, architecture/design, secrets/dependency
  checks (114 records; no advisory/retraction failures) and macOS release build.
- `just native-test` and `just native-echo` pass on macOS using repository-owned
  loopback fixtures, which are removed afterward. Native configuration covers
  SQLite reopening and preview clearing; Echo covers independent runtime ownership
  through preview navigation. No new Linux/native desktop acceptance is claimed.
- Deliberately disabling each new entrypoint/cycle/model architecture rule and
  removing the handoff export makes the corresponding test fail.
- An initial native run inspected through accessibility tooling failed a
  semantics-handle teardown assertion. The uninspected rerun passed. Automated
  native success remains distinct from real-keyboard and packaged acceptance.

Date correction, after refactor verification:

- Two regressions fail against the pre-fix composer: malformed separators are
  accepted and opposite-bound editing does not keep them invalid.
- Friendly bounds now accept exact `YYYY-MM-DD`, compact eight-digit dates or
  blanks. Invalid literals are retained rather than normalized into valid dates;
  the existing draft validation disables Run. Advanced DA ranges, calendar/order
  checks and blank bounds remain unchanged.
- A private date-field state keeps each bound separate while editing and follows
  external controller updates. A preservation test passes on the original code
  and verifies `edit`, `advanced` and clearing while Filters remains mounted.
- Four date tests and the focused Query/Retrieve/Echo suites pass. All 24 visual
  comparisons still match. Reintroducing permissive normalization or removing
  calendar validation is rejected.
- Final `just dry` passes: 108 Flutter and 22 core tests, all static gates/audits
  and the macOS release build. Final `just native-test` and `just native-echo`
  reruns pass; owned loopback fixtures are removed afterward.
- A final configuration attempt stalled in Settings before reaching Query and
  ended without completing. The uninspected retry passed in 18 seconds; native
  Echo passed in 15 seconds. The existing foreground-launch warning persists.
  This is local automated evidence, not a claim that native launch/focus behavior
  or manual desktop acceptance is resolved.

Hosted CI and manual macOS/Ubuntu GNOME acceptance have not been verified for
the delivery revision. No slice completion or release acceptance
is implied.
