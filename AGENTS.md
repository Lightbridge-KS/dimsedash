# Repository guidance

DimseDash is an MIT-licensed Flutter desktop workbench for DICOM DIMSE diagnostics.
Current implementation scope and evidence live in
[the progress tracker](docs/progress/overview-first-preview.md). Read it before
starting work and update it as a slice advances; do not infer completion from a build.

## Design and boundaries

- Read the [PRD](docs/req/dimsedash-prd.md), relevant [architecture](docs/design/),
  and [codebase blueprint](docs/structure/01-codebase-blueprint.md) before changing
  behavior. Read [DESIGN.md](DESIGN.md) before building or restyling UI.
- Keep feature UI in `lib/features`, Riverpod bindings in `lib/bindings`, concrete
  adapters in `lib/adapters`, and composition in `lib/app`.
- Keep `packages/dimsedash_core` pure Dart: no Flutter, Riverpod, filesystem,
  database or network dependencies. Import package public APIs, never `src/`.
- Use typed results for expected command failures and typed events/outcomes for
  running operations. Exceptions represent unexpected defects.
- Add only the modules needed by the active slice. Update design documents in
  place while the design is unshipped; record progress separately.

## Development

- Use the SDK pinned in `.fvmrc` through FVM and the committed workspace lockfile.
  See [development setup](docs/dev/development.md) for prerequisites.
- Run `just setup` and `just hooks` after cloning. Use `just run` to launch.
- Run `just format` after Dart edits and relevant tests immediately. Before delivery,
  run `just dry`; use `just native-test` for native configuration integration.
- Regenerate checked-in Drift code with `just generate`; never edit it manually.
  Preserve existing databases on failures and test migrations explicitly.
- Keep the architecture gate strict. Fix forbidden dependencies rather than
  weakening its policy. No `print()` in production Dart.

## Evidence and publication

- Use synthetic DICOM fixtures and example endpoints only. Never commit patient
  data, secrets, deployment addresses, personal paths or local overrides.
- Distinguish unit/widget tests, native integration, actual desktop acceptance,
  hosted CI and packaged release evidence in the tracker.
- Keep scratch/build output ignored. New docs need `summary` and `read_when`
  frontmatter. `CLAUDE.md` is a symlink to this file; preserve it.
- Use Conventional Commits. The app manifest owns the version; releases are
  drafted for human publication, never published automatically.
