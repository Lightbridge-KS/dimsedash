# DimseDash

An open-source Flutter desktop workbench for PACS integration engineers to test
and diagnose DICOM DIMSE communication.

The planned first-preview workflow is **C-FIND → select a study, series or instance
→ C-GET/C-MOVE → receive → inspect headers, thumbnails and transfer evidence**,
with friendly filters and an advanced DICOM Identifier editor.

## Status

**Early implementation:** S1 provides node management, persistent settings,
explicit C-ECHO and bounded diagnostic history. S2A adds real Study Root C-FIND
at study, series and instance levels, metadata inspection and read-only retrieval
review. Body part is optional. Full structured Identifier editing, retrieval,
receiving and image inspection remain pending. Startup and saving settings send
no PACS traffic.

DICOM dependencies are pinned to the merged upstream Find implementation at
`32f0f90f4cd36cb643663c23b2b47943c9b0f7c5`. No sibling checkout or local override
is required. The packages still report `0.1.0-dev.2`; the commit pin includes APIs
added after that release tag. See the [Query runbook](docs/tests/s2-query.md).

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
