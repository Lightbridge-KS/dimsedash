# DimseDash

An open-source Flutter desktop workbench for PACS integration engineers to test
and diagnose DICOM DIMSE communication.

The planned first-preview workflow is **C-FIND → select a study, series or instance
→ C-GET/C-MOVE → receive → inspect headers, thumbnails and transfer evidence**,
with friendly filters and an advanced DICOM Identifier editor.

## Status

**Early implementation:** node management, persistent connection settings and an
explicit C-ECHO workflow with typed diagnostic evidence and bounded history are
implemented in S1. Query/retrieve, receiving and image inspection remain later
slices. Startup and Apply send no PACS traffic.

S1 uses the GitHub-only `dartdicom` family prerelease `v0.1.0-dev.2`, pinned
consistently in the workspace manifests and lockfile. No sibling checkout or
local dependency override is required. See [dependency provenance](docs/dev/development.md#s1-dependencies-and-diagnostic-provenance)
and the [S1 tracker](docs/progress/s1-echo.md) for verification and acceptance limits.

There is no installable preview release yet. Desktop acceptance is still in
progress; see the [implementation tracker](docs/progress/overview-first-preview.md).

## Build from source

Targets: macOS 15+ on Apple Silicon and Ubuntu Desktop 24.04 LTS amd64.
The [platform baseline](docs/progress/overview-first-preview.md#settled-platformdistribution-baseline)
defines the narrower tested support contract.

Install FVM, just and the platform's Flutter build prerequisites, then:

```sh
git clone https://github.com/Lightbridge-KS/dimsedash.git
cd dimsedash
fvm install
fvm use
just setup
just run
```

The exact SDK is in `.fvmrc`; `pubspec.lock` locks the application workspace.
See [contributor setup](docs/dev/development.md) for dependencies and checks.

## Contributing

Start with the [PRD](docs/req/dimsedash-prd.md),
[codebase blueprint](docs/structure/01-codebase-blueprint.md) and
[repository guidance](AGENTS.md). Work proceeds in vertical slices. Run `just dry`
before submitting changes; native integration checks use `just native-test`.
Use synthetic fixtures only—never include patient data or real deployment details.

Licensed under [MIT](LICENSE). Maintained by [Lightbridge-KS](https://github.com/Lightbridge-KS).
