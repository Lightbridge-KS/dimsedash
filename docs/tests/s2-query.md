---
summary: S2A dry, loopback and native C-FIND verification, pinned upstream dependency setup and explicit acceptance boundaries.
read_when:
  - running or reviewing real Study Root Query checks
  - reproducing checks with public Git dependencies
---

# S2A Query verification

Parent: [S2 tracker](../progress/s2-query.md). Prerequisites and SDK pin:
[development setup](../dev/development.md). All DICOM package references resolve to
upstream commit `32f0f90f4cd36cb643663c23b2b47943c9b0f7c5`, which includes the
merged Find APIs. The package version remains dev.2; the older dev.2 release tag
does not contain these additions. Run `just setup` without local overrides.
Paired development may use an ignored `pubspec_overrides.yaml`, but disable it
before delivery checks and never commit path-based lockfile entries.

Run in order:

```sh
just format
just dry
just live
just native-test
just native-echo
just native-query
```

Dry tests cover common Identifier/date/encoding semantics; optional body part;
exact parent hierarchy; row/byte limits and a 10,000-row burst; admission, frozen
snapshots, storage failure and recovery; masking, inspection, navigation/focus,
760 × 600 at 150% text and both themes. Existing synthetic Query/Retrieve
component tests use an isolated historical shell fixture. They are not proof
of live networking. Native configuration tests browse Query without dispatch;
networking has an independent native-query gate.

The loopback harness owns a unique disposable Orthanc **26.9.1** Compose project,
helper process group and cleanup. `uv` supplies pinned **pydicom 3.0.2** and
**pynetdicom 3.0.4**. It seeds three one-pixel synthetic instances: two studies,
three series, three instances. The CT study has two series, one without Body Part
Examined; the MR study has one. Expected values are defined by
`tools/live/seed_query.py`, not a sibling catalog. No REST port is published.

Default ports: Orthanc 4242; helper range 4250–4264. Existing listeners are refused.
Choose distinct free loopback ports when needed:

```sh
DIMSEDASH_ORTHANC_PORT=18424 DIMSEDASH_PEER_PORT=18450 just live
DIMSEDASH_ORTHANC_PORT=18424 DIMSEDASH_PEER_PORT=18450 just native-query
```

`tests/live/find_test.dart` drives the actual app bootstrap, store, runner and
adapter. It checks literal filtering, date/modality, hierarchy, empty success,
optional-key warnings, failed-after-results, rejection, context rejection,
timeout, abort, oversize Identifier, missing UID, unsupported character set,
cancellation/ignored cancellation and release failure. `native-query` drives the
Flutter controls through Study → Series → Instance → read-only retrieve review,
then restarts the isolated app to prove drafts/results do not persist. Native Echo
uses a 20-second controlled response delay so navigation and Settings edits can
finish before the peer responds; ordinary live tests retain the 3-second delay.
Native tests establish a frame before asynchronous database setup. The harness
bounds its test subprocess to ten minutes and always cleans its owned fixtures.

The optional Orthanc test bundle `dimsedash` profile is an interoperability bench,
not a test dependency. Follow that repository's profile README, verify its contract
and derive expected UIDs/counts from its generated catalog. Keep its evidence
separate from the owned fixture suite; never substitute hospital nodes.

Linux automated checks should record OS/SDK and command results separately.
Headless execution can use Xvfb but does not establish Ubuntu GNOME Wayland/Xorg
acceptance. Automated macOS UI tests and review screenshots likewise do not close
the deferred manual desktop checklist. Upstream publication, final pins,
clean-clone delivery, S2B authoring and actual retrieval remain separate gates.
