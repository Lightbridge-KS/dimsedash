---
summary: Archived initial DimseDash inventory before PRD promotion. Historical proposals and superseded scope; not authoritative requirements.
read_when:
  - refining DimseDash scope before writing the PRD
  - reviewing original feature ideas and their later corrections
---

# DimseDash — Initial Ideas (Archived)

> Archived on 2026-10-18 before pruning. Current requirements: [DimseDash PRD](../req/dimsedash-prd.md). Original feature IDs, version roadmap, examples and assumptions below are historical, not implementation instructions.

> **Exploration, not an approved PRD.** The feature tables and version roadmap below are the original idea inventory. The [exploration review](../ideas/2026-10-18-exploration.md) corrects library assumptions and proposes a smaller first-preview scope. No ADR is needed at this stage.

## Confirmed direction — 2026-10-18

- Open source, **MIT**, initially under **Lightbridge-KS**.
- Primary audience: **PACS and integration engineers**, with advanced protocol details available.
- First public preview: a complete **Find → Move/Get → receive** workflow, rather than an Echo-only release.
- **Basic image thumbnails are included in the first preview.** Unsupported preview formats must remain distinguishable from receipt/storage failures.
- **TLS is deferred. Legacy Thai character-set support is not required for the first preview.**
- Develop on macOS; **macOS and Linux are equally supported from the first preview**. Windows remains a cross-platform goal; its first supported release is not yet decided.
- Flutter version management through **FVM**; command orchestration through a **justfile**.
- Blue Material theme export is a starting point; final visual design remains open.
- Formal PRD in `docs/req/`, followed by system and surface architecture, after exploration settles.

The earlier version numbering and P0 labels below are proposals, not release commitments. Outstanding decisions are collected in the exploration review.

| | |
|---|---|
| **Status** | Initial feature inventory; exploration in progress |
| **Author** | Kittipos Sirivongrungson (KS / Lightbridge) |
| **Date** | 2026-10-18 |
| **Product** | **DimseDash**: a cross-platform desktop app for testing and diagnosing DICOM network (DIMSE) communication with PACS and other DICOM nodes |
| **Repository** | Planned: `github.com/Lightbridge-KS/dimsedash`, a consumer of the `dartdicom` ecosystem |
| **Built on** | `dartdicom` · `dartdicom_net` · `dartdicom_pixel` |
| **Inspiration** | [API Dash](https://github.com/foss42/apidash), the open-source API client built with Flutter. DimseDash is *inspired by* it and **not affiliated with** API Dash or foss42. |
| **Purpose of this doc** | Define what to build, for whom, and in what order, as a basis for design discussion and implementation with Codex. |

---

## 1. TL;DR

**DimseDash is "API Dash for DICOM networking."** You pick a DICOM node from a saved library and run an operation: C-ECHO, C-FIND, C-MOVE, C-GET or C-STORE. DimseDash then shows **what happened at every layer and why it failed**:

- a stage-by-stage timeline
- decoded rejection and status codes
- the presentation-context negotiation
- a PDU inspector
- plain-language fix hints

It ships a **built-in Storage SCP**, so retrieve (C-MOVE / C-GET) can be tested end-to-end. Every action is reproducible, because it can be exported as a DCMTK command, a pynetdicom script or a `dartdicom_net` snippet.

Desktop-first (macOS, Windows, Linux). Local-first, no telemetry, safe around PHI and production systems.

---

## 2. Problem & Motivation

### 2.1 How DIMSE connectivity is tested today

| Tool | Strengths | Pain |
|---|---|---|
| **DCMTK CLI** (`echoscu`, `findscu`, `movescu`, `getscu`, `storescu`, `storescp`) | The de-facto reference, scriptable, very complete | Cryptic output. Diagnosing means reading `-d`/`-dd` logs. No saved nodes, no history. C-MOVE testing means running `storescp` in a second terminal. |
| **pynetdicom** (library + bundled apps) | Flexible, very good for developers | Needs Python and code. Not for non-programmers. |
| **DVTk** | Deep validation | Windows-centric, steep learning curve |
| **"Echo" buttons in PACS/modality admin UIs** | Built-in | Pass/fail only, vendor-specific, no detail |
| **Wireshark** (DICOM dissector) | Ground truth on the wire | Packet-level, needs capture rights, no DICOM-level guidance |

### 2.2 Pain points

1. **"It doesn't connect." But why?** The cause could be the network, a firewall, the AE title, a SOP class or transfer syntax, or the remote application. Finding out takes expertise and logs.
2. **C-MOVE confusion.** A retrieve needs the PACS to connect *back* to a destination that it knows by AE title, IP and port. This is the single most common integration failure, and the hardest to see.
3. **No shared, reusable setup.** AE titles, IPs and ports live in spreadsheets, emails and sticky notes. Each integration ticket starts over.
4. **No reproducibility.** It's hard to hand a vendor a precise description of what was tried and what came back.
5. **No modern cross-platform GUI** with a Postman / API Dash-style workflow exists for DIMSE.

### 2.3 Why build it now

- The `dartdicom` ecosystem already provides core data handling, the five DIMSE SCU operations, an embedded Storage SCP, and native pixel decoding in `0.1.0-dev.1`. Richer structured diagnostics still need upstream work; see the exploration review. DimseDash can be the **flagship app that dogfoods them**.
- Flutter gives one codebase for macOS, Windows and Linux, with a polished UI.

---

## 3. Vision & Guiding Principles

> *"Ping, query, retrieve — and see exactly why it failed."*

| # | Principle | In practice |
|---|---|---|
| P1 | **Diagnose, don't just execute** | Every failure is classified to a layer (network, TLS, association, negotiation, DIMSE, application) and comes with an explanation and fix hints. |
| P2 | **Familiar workflow** | The API Dash / Postman mental model: node library ≈ collections, environments, history, "copy as code". |
| P3 | **Reproducible** | Every operation can be replayed, and exported as a DCMTK command, a pynetdicom script or a `dartdicom_net` snippet. |
| P4 | **Safe around PHI and production** | Redaction mode, a production guard, opt-in storage of result data, secrets in the OS keychain. |
| P5 | **Local-first, open** | No telemetry, no account. The workspace is plain files you can keep in git. Open source. |
| P6 | **No protocol code in the app** | All DICOM logic lives in the `dartdicom_*` libraries. The app orchestrates and presents. Anything missing is a library requirement (§10). |
| P7 | **Desktop-grade UX** | Keyboard-first (command palette, shortcuts), resizable panes, light and dark themes, accessibility. |

---

## 4. Target Users & Use Cases

### 4.1 Personas

| Persona | Context | What they need from DimseDash |
|---|---|---|
| **PACS administrator / radiology IT** | Registers new nodes, troubleshoots "images not arriving" | Fast echo/find/move checks, clear failure reasons, a health-check report |
| **Integration / interface engineer** | Connects modalities, viewers, archives and routers across sites and vendors | Saved node library per site, environments, conformance probe, exportable evidence for vendors |
| **Modality / applications engineer** | Commissions a modality: worklist (MWL), storage, storage commitment | MWL query testing, C-STORE with per-file status, an SCP to receive test sends |
| **DICOM software developer** | Builds SCUs/SCPs (gateways, routers, AI inference services, viewers) | PDU-level inspection, a mock SCP that can simulate failures, code export |
| **QA / validation engineer** | Verifies releases and interoperability | Repeatable test suites with assertions (later), comparable runs |
| **Educator / student** | Learns how DICOM networking works | Annotated PDU trace and timeline as a teaching aid |

### 4.2 User stories

- *As a PACS admin,* I can echo a node and, when it fails, see in one glance whether it's the network, the AE title or the remote application.
- *As an integration engineer,* I can run a C-MOVE to DimseDash's built-in SCP and watch the PACS connect back. If it doesn't, I see why (`0xA801 Move destination unknown`, or completed with zero received).
- *As a modality engineer,* I can query a Modality Worklist with today's date and a station AE title, and inspect the returned items.
- *As a developer,* I can point my SCU at DimseDash's SCP, configured to reject or delay, and check how my software handles it.
- *As anyone,* I can export a diagnostic report, with PHI redacted, and attach it to a vendor ticket.
- *As anyone,* I can copy the exact `findscu` command that reproduces what DimseDash just did.

---

## 5. Concept

### 5.1 API Dash → DimseDash mapping

| API Dash | DimseDash |
|---|---|
| Request (GET / POST / …) | **Operation**: C-ECHO, C-FIND, C-MOVE, C-GET, C-STORE (later: N-services) |
| URL | **Remote node**: host, port, called AE title (plus the local calling AE title) |
| Headers / auth | **Association settings**: presentation contexts, max PDU, user identity, role selection, TLS |
| Body | **Query identifier** (C-FIND/C-MOVE keys) or **files to send** (C-STORE) |
| Response + status code | **DIMSE status** (decoded) plus result datasets or received instances |
| Response preview | Results table, DICOM header viewer, image thumbnails |
| Collections / folders | **Node library** (folders per site, department or vendor) |
| Environments + variables | **Environments** (dev / test / production) with `{{VARIABLES}}` |
| History | **Run history**, replayable |
| Code generation | **Copy as** DCMTK / pynetdicom / `dartdicom_net` |
| Import from cURL | (Later) **Paste a DCMTK command** to create an operation |
| DashBot | (Later) **"Explain this failure"** assistant, PHI-stripped, opt-in |

### 5.2 Domain glossary (ubiquitous language)

| Term | Meaning in DimseDash |
|---|---|
| **AE (Application Entity)** | A DICOM endpoint, identified by an AE title (≤ 16 chars) plus host and port |
| **Local AE profile** | DimseDash's own identity: calling AE title, listening port, implementation identity |
| **Node** | A saved remote AE (PACS, archive, modality, worklist provider, router) |
| **Environment** | A named set of variables and a safety level (`dev`, `test`, `production`) |
| **Operation** | A configured action against a node (type + parameters), which can be saved in the library |
| **Run** | One execution of an operation: an immutable, time-stamped **event log** |
| **Stage** | A step within a run: DNS, TCP, TLS, association, DIMSE exchange, release |
| **Diagnosis** | The classification of a run's outcome (layer + cause) with **hints** |
| **Built-in SCP** | DimseDash's own listener (Storage + Verification SCP, later a mock Q/R SCP) |
| **Received instance** | An object that arrived at the built-in SCP |
| **Health check** | A predefined sequence of safe operations that produces a report card |
| **Conformance probe** | Systematic negotiation of SOP classes × transfer syntaxes to map what a node accepts |

---

## 6. User Experience

### 6.1 Main window

```
┌─ DimseDash ───────────────────────────────────────────────────────────────────────┐
│ Env: [ Test ▾ ]  Local AE: DIMSEDASH :11112  ● SCP running   👁 Redact   ⌘K       │
├────────────────┬──────────────────────────────────────────────────────────────────┤
│ NODES          │ C-FIND ▾  PACS Main · pacs-test.local:104 · PACS_MAIN   [ Run ▶ ] │
│ ▾ Site A       │ ┌ Query ─┬ Contexts ─┬ Identity ─┬ Options ┐                       │
│   • PACS Main  │ │ Model: Study Root     Level: STUDY                               │
│   • Archive    │ │ PatientID          = 12345*                                      │
│ ▾ Modalities   │ │ StudyDate          = 20261001-20261018                           │
│   • CT-1 (MWL) │ │ ModalitiesInStudy  = CT                                          │
│ ▾ Dev          │ │ + return keys: StudyInstanceUID, AccessionNumber, …              │
│   • Orthanc    │ └──────────────────────────────────────────────────────────────────┘│
│                │ ┌ Results (23) ─┬ Diagnostics ✓ ─┬ PDU trace ─┬ Code ┐             │
│ HISTORY        │ │ PatientName  PatientID  StudyDate  Mods  Accession  #Series     │
│ 10:31 C-FIND ✓ │ │ ████████     ██████     20261012   CT    ██████     3           │
│ 10:29 C-ECHO ✗ │ │ …                                                (redacted)     │
│ 10:28 C-ECHO ✓ │ └──────────────────────────────────────────────────────────────────┘│
├────────────────┴──────────────────────────────────────────────────────────────────┤
│ 23 matches · first result 84 ms · total 312 ms · association accepted (2/2 ctx)  │
└───────────────────────────────────────────────────────────────────────────────────┘
```

### 6.2 Diagnostics panel (failed C-ECHO)

```
┌ C-ECHO → PACS Main (10.0.0.5:104) ─────────────────────────────── ✗ FAILED ┐
│  ● DNS resolve            2 ms   ✓                                         │
│  ● TCP connect           11 ms   ✓                                         │
│  ● TLS handshake           —     (disabled)                                │
│  ● A-ASSOCIATE-RQ →      14 ms   ✓ sent (1 presentation context)           │
│  ● ← A-ASSOCIATE-RJ      19 ms   ✗ rejected-permanent                      │
│        source: DICOM UL service-user                                       │
│        reason: called-AE-title-not-recognized                              │
│                                                                            │
│  Layer: ASSOCIATION · Category: AE configuration                           │
│  Hint: The remote node doesn't recognise the called AE title "PACS_MIAN".     │
│     • Check the spelling and case against the PACS configuration           │
│     • AE titles are at most 16 characters                                  │
│                                                                            │
│  [ PDU trace ] [ Hex ] [ Copy as echoscu ] [ Export report ] [ Re-run ]    │
└────────────────────────────────────────────────────────────────────────────┘
```

### 6.3 Retrieve with the built-in SCP (C-MOVE)

```
┌ C-MOVE → PACS Main · destination DIMSEDASH (built-in SCP) ──────── running ┐
│ Sub-operations  remaining 41 │ completed 79 │ failed 0 │ warning 0         │
│ ██████████████████████████████░░░░░░░░░░░░░░  66 %   18.4 MB/s            │
│                                                                            │
│ ⇠ Incoming association  PACS_MAIN @ 10.0.0.5 → DIMSEDASH                   │
│   CT Image Storage · JPEG 2000 Lossless (accepted)                         │
│ Received  CT · 512×512 · 1.2.840.…  [▣ thumbnail]                          │
└────────────────────────────────────────────────────────────────────────────┘
```

### 6.4 Key flows

1. **First run:** set up the local AE profile (default AE `DIMSEDASH`, port `11112`). Optionally add a demo node: a local Orthanc via docker-compose from the docs.
2. **Echo a node:** pick a node and press Run (`⌘↵`). See the timeline and diagnosis.
3. **Find → drill down:** Study results → "Find series" → "Find instances" → "Move / Get this".
4. **Retrieve:** a C-MOVE to the built-in SCP with live sub-operation counters and received thumbnails. Or a C-GET over the same association.
5. **Send:** drag and drop files or folders → C-STORE with per-file status and throughput.
6. **Evidence:** health check → report card → export (Markdown, PDF or JSON, redacted by default).

---

## 7. Functional Requirements

Priority key: **P0** = MVP (v0.1–v0.3), **P1** = v0.4–v1.0, **P2** = later.

### 7.1 Workspace, nodes & environments (WS)

| ID | Requirement | Pri |
|---|---|---|
| WS-01 | **Local AE profiles**: calling AE title, listening port for the built-in SCP, implementation class UID and version name (overridable for testing). More than one profile allowed. | P0 |
| WS-02 | **Node library**: name, host, port, called AE title, TLS settings, default presentation contexts, tags, notes. CRUD, duplicate, search. | P0 |
| WS-03 | Folders and drag-to-reorder in the library. | P0 |
| WS-04 | **Environments** with `{{VARIABLE}}` substitution in any node or operation field, and a quick environment switcher. Each environment has a **safety level** (`dev` / `test` / `production`). | P0 |
| WS-05 | **Workspace on disk as human-readable files** (YAML or JSON, see Appendix C), so it can be kept in git. Secrets (user-identity passwords, TLS private keys) go in the **OS keychain**, never in workspace files. | P0 |
| WS-06 | Saved **operations** (node + type + parameters) inside the library, like saved requests. | P1 |
| WS-07 | Import and export nodes (CSV/JSON). Import the AE table from a DCMTK `dcmqrscp.cfg`. | P2 |

### 7.2 Operations, as SCU (OP)

| ID | Requirement | Pri |
|---|---|---|
| OP-01 | **C-ECHO** (Verification). | P0 |
| OP-02 | **C-FIND**: Patient Root and Study Root information models at PATIENT / STUDY / SERIES / IMAGE level. Query builder with matching types (single value, wildcard `*` `?`, date/time range, list of UIDs, universal matching for return keys). A raw identifier editor (tag/keyword list or DICOM JSON). Results stream into the table as they arrive, with **C-CANCEL**. | P0 |
| OP-03 | **C-MOVE**: destination AE (defaults to the built-in SCP) with live sub-operation counters (remaining, completed, failed, warning) and a list of received instances. C-CANCEL. | P0 |
| OP-04 | **C-GET**: storage presentation contexts proposed with SCP/SCU role selection. Instances received over the same association. | P0 |
| OP-05 | **C-STORE**: send files or folders (drag and drop), with per-file status, throughput and abort. If the original transfer syntax isn't accepted, fall back to an accepted uncompressed one where `dartdicom` can re-encode; otherwise report clearly. | P0 |
| OP-06 | **Modality Worklist** C-FIND (presets: today, station AE, modality). | P1 |
| OP-07 | **Advanced association settings**: hand-pick presentation contexts and transfer syntaxes, max PDU length, user identity (username, username + passcode; later Kerberos/SAML/JWT), role selection, asynchronous operations window, timeouts (connect, ACSE, DIMSE). | P1 |
| OP-08 | **TLS** (DICOM TLS profiles): CA trust store, client certificate, verify or skip hostname (with a warning). | P1 |
| OP-09 | **N-services**: Storage Commitment (N-ACTION / N-EVENT-REPORT) and MPPS (N-CREATE / N-SET). | P2 |
| OP-10 | Drill-down actions from results: "find series", "find instances", "move/get this", "send this file to another node". | P1 |

### 7.3 Built-in SCP (SCP)

| ID | Requirement | Pri |
|---|---|---|
| SCP-01 | **Storage SCP**: AE title and port from the local profile; accepts all storage SOP classes with configurable transfer syntaxes. Start/stop, with a status indicator in the header. | P0 |
| SCP-02 | **Verification SCP** (answers C-ECHO), so the remote side can echo DimseDash. | P0 |
| SCP-03 | **Incoming association log** with the same diagnostics as outgoing runs: calling AE, peer IP, contexts, and accept/reject decisions. | P0 |
| SCP-04 | Received instances saved to a configurable folder, organised by Patient/Study/Series. A visible location and one-click purge. Optional memory-only mode. | P0 |
| SCP-05 | **Mock policies** for SCU developers: accept or reject by calling AE or SOP class, return a chosen DIMSE status, add latency, abort mid-transfer. | P1 |
| SCP-06 | **Mock Q/R SCP**: serve C-FIND / C-MOVE / C-GET from the received-instances store, so DimseDash can act as a tiny test PACS. | P2 |

### 7.4 Diagnostics (DX): the differentiator

| ID | Requirement | Pri |
|---|---|---|
| DX-01 | **Stage timeline** for every run: DNS → TCP connect → TLS → A-ASSOCIATE-RQ/AC/RJ → each DIMSE request/response → A-RELEASE or A-ABORT. Each stage shows timestamps, duration and pass/fail. | P0 |
| DX-02 | **Failure classifier**: map the first failing stage to a **layer** (Network, TLS, Association, Negotiation, DIMSE, Application, Retrieve-callback) and a **cause category**, with a plain-language explanation and fix hints from a versioned **knowledge base** (Appendix A). | P0 |
| DX-03 | **Decoders**: A-ASSOCIATE-RJ (result, source, reason), A-ABORT (source, reason), presentation-context results, DIMSE status by service class, including Error Comment (0000,0902), Offending Element (0000,0901) and Error ID. | P0 |
| DX-04 | **Presentation-context table**: proposed abstract syntax and transfer syntaxes → result → accepted transfer syntax. | P0 |
| DX-05 | **Peer fingerprint**: Implementation Class UID and Version Name (often identifies the vendor and version), max PDU, async operations, role selection and the user-identity response. | P0 |
| DX-06 | **PDU inspector**: a structured tree plus hex for every PDU and PDV, with decoded command sets and data sets (header viewer). | P0 |
| DX-07 | **Metrics**: time to first result, total time, C-STORE throughput (MB/s, instances/s), per-instance latency. | P1 |
| DX-08 | **Health check**: a safe sequence that produces a report card. Steps: echo; find with a small result limit; a **move-destination probe** that moves nothing (for example, a C-MOVE of a non-existent Study Instance UID to confirm the destination AE is known); built-in SCP reachability. PACS behaviour varies, so the probe is labelled "indicative". | P1 |
| DX-09 | **Conformance probe**: negotiate SOP classes × transfer syntaxes in batches (≤ 128 presentation contexts per association) and show an acceptance matrix. Exportable. | P1 |
| DX-10 | **Export**: diagnostic report (Markdown / PDF / JSON) and PDU trace (text), **redacted by default**. | P1 |
| DX-11 | **Compare two runs** (contexts accepted, statuses, timings), e.g. before and after a PACS configuration change. | P2 |
| DX-12 | Export a synthetic **pcapng** of the PDU stream for Wireshark. | P2 |

### 7.5 Results & DICOM viewing (RV)

| ID | Requirement | Pri |
|---|---|---|
| RV-01 | **Results table** for C-FIND: column chooser, sort, filter, copy as TSV/CSV. Virtualised for 10k+ rows. | P0 |
| RV-02 | **Header viewer**: tree of tag, VR, VM, keyword and value, with nested sequences, search, and copy a tag path. Shows Specific Character Set handling (e.g. UTF-8, Latin-1, TIS-620). | P0 |
| RV-03 | **Basic image thumbnails** of received instances through `dartdicom_pixel` are included in the first preview. Unsupported formats show a clear preview-unavailable state while receipt/storage outcomes remain visible. Interactive window/level and a frame scrubber remain later ideas. | P0 (basic thumbnails) / P1 (viewer controls) |
| RV-04 | Open a local DICOM file or folder in the header viewer, without any network. | P1 |

### 7.6 History & reproducibility (HX)

| ID | Requirement | Pri |
|---|---|---|
| HX-01 | **Run history**: operation, node, environment, outcome, timings. Re-run, or open the full diagnostics of past runs. | P0 |
| HX-02 | **Privacy-aware history**: store run metadata and the event log by default; **result datasets only if opted in**; configurable retention. | P0 |
| HX-03 | **Copy as code**: DCMTK (`echoscu`, `findscu`, `movescu`, `getscu`, `storescu`), a pynetdicom script, and a `dartdicom_net` snippet. All are generated from the operation model, so they can't drift from it. | P0 (DCMTK) / P1 (others) |
| HX-04 | **Paste a DCMTK command** to create the equivalent operation. | P2 |

### 7.7 Safety & privacy (SF)

| ID | Requirement | Pri |
|---|---|---|
| SF-01 | **Production guard**: in a `production` environment, a persistent red banner, and a confirmation step before anything that writes or moves data (C-STORE, C-MOVE to a destination other than DimseDash, N-ACTION). An optional **read-only mode** that allows only C-ECHO and C-FIND. | P0 |
| SF-02 | **Redaction mode**: masks PN, IDs, dates of birth, accession numbers and similar attributes in the UI, and always applies to exports unless explicitly turned off. | P0 |
| SF-03 | **No telemetry**. No outbound connections except to configured nodes. Update checks are opt-in. | P0 |
| SF-04 | Secrets live only in the OS keychain (WS-05). | P0 |
| SF-05 | A clear **"Not for clinical or diagnostic use"** notice. DimseDash is a connectivity tool, not an image-reading tool. | P0 |
| SF-06 | Logs never contain PHI unless a debug option is explicitly enabled, and the app then shows a warning. | P0 |

### 7.8 Automation & assistance (AU), later

| ID | Requirement | Pri |
|---|---|---|
| AU-01 | **Test suites**: ordered operations with assertions (status equals, result count ≥ n, latency < t, context accepted). | P2 |
| AU-02 | **Headless CLI** (`dimsedash run suite.yaml`) sharing the same core as the app, for CI and monitoring. | P2 |
| AU-03 | **Monitors**: a periodic echo or health check with desktop notifications. | P2 |
| AU-04 | **"Explain this failure"** assistant: sends a PHI-stripped event log to a user-chosen local or cloud LLM. Opt-in. | P2 |

---

## 8. Non-Functional Requirements

| Area | Requirement |
|---|---|
| **Platforms** | **Confirmed first preview:** macOS and Linux with equal acceptance criteria; exact OS/CPU baselines remain to be decided. Windows remains a goal with release timing open. Mobile is a later idea. **Web: not supported**, because browsers cannot open raw TCP sockets for DIMSE. |
| **Responsiveness** | The UI never blocks. All networking and dataset decoding runs on **background isolates**. Smooth scrolling while C-FIND streams 10k+ results. |
| **Performance** | C-STORE throughput on a LAN within ~80% of DCMTK `storescu` (target, to be benchmarked). Cold start < 2 s on a modern laptop. |
| **Reliability** | Every network stage has a timeout and can be cancelled. Associations are released or aborted cleanly when the app quits. The SCP survives malformed peers. |
| **Correctness** | Diagnostics derive from the library's event stream (§9.3), not from heuristics on logs. Decoder tables come from the DICOM standard (PS3.7, PS3.8) and are unit-tested. |
| **Interop testing** | CI integration tests against Orthanc and DCMTK (`dcmqrscp`, `storescp`) in docker, plus pynetdicom-based SCPs. Field testing against at least two commercial PACS before 1.0. |
| **Accessibility** | Full keyboard navigation, command palette, screen-reader labels, high-contrast and dark/light themes, status shown by **icon + text**, never by colour alone. |
| **Internationalisation** | English first. Strings in ARB files from day one so the app can be localised. Correct display of non-ASCII names per Specific Character Set. |
| **Packaging** | Signed and notarised macOS build (sandbox entitlements: `network.client` and `network.server`), signed Windows installer/MSIX, Linux AppImage/Flatpak/deb. Reproducible CI builds. |
| **Code quality** | Unit tests for domain and diagnostics, widget and golden tests for key screens, integration tests against docker nodes. Lints enforced, documented architecture (§9). |
| **License** | MIT; initial repository owner Lightbridge-KS. Third-party notices bundled. |

---

## 9. Architecture

### 9.1 Layers (Clean Architecture, right-sized)

```
┌──────────────────────────────── dimsedash (Flutter app) ──────────────────────────────┐
│  Presentation    widgets · screens · view-models/state   (Flutter only lives here)    │
│        │                                                                              │
│        ▼                                                                              │
├──────────────────────────────── dimsedash_core (pure Dart) ───────────────────────────┤
│  Application     use cases: RunEcho · RunFind · RunMove · RunGet · RunStore ·         │
│                  StartScp · HealthCheck · ConformanceProbe · ExportReport · CopyAsCode│
│        │                                                                              │
│  Domain          Node · LocalAeProfile · Environment · Operation · Run(event log) ·   │
│                  Stage · Diagnosis · Hint · KnowledgeBase · Redactor                  │
│        ▲  ports (interfaces): DimseGateway · WorkspaceRepository · SecretStore ·      │
│        │                       InstanceStore · Clock                                  │
├────────┴──────────────────────────────────────────────────────────────────────────────┤
│  Infrastructure  DartdicomNetGateway (isolate) · YAML/JSON workspace files ·          │
│                  OS keychain · file-system instance store · FakeDimseGateway (tests)  │
└───────────────────────────────────────────────────────────────────────────────────────┘
          │ uses
          ▼
   dartdicom_net        dartdicom          dartdicom_pixel
```

- **`dimsedash_core` is pure Dart** (no Flutter). The future headless CLI (AU-02) reuses it, and it's testable on the plain Dart VM.
- **Ports & adapters.** The `DimseGateway` port isolates the app from `dartdicom_net`. A `FakeDimseGateway` that replays recorded event logs lets UI and diagnostics work **start before the network library is finished**, and gives deterministic tests.

### 9.2 Repository layout

```
dimsedash/                          ← git root (satellite repo in the dartdicom org)
├── pubspec.yaml                    # pub workspace: [app, packages/dimsedash_core, (later) packages/dimsedash_cli]
├── app/                            # Flutter app (macOS, Windows, Linux)
├── packages/
│   ├── dimsedash_core/             # domain, use cases, diagnostics knowledge base, workspace format
│   └── dimsedash_cli/              # (P2) headless runner
├── knowledge_base/                 # failure → hint rules (YAML), versioned, community-editable
├── docker/                         # Orthanc / DCMTK nodes for integration tests and demos
├── docs/                           # docs/PRD.md (this file), docs/adr/
└── .github/workflows/              # analyze, test, integration (docker), desktop builds
```

The current `dartdicom` prerelease is **GitHub-only**, not on pub.dev. Pin all Git package dependencies to the same release tag or commit, including the required core-package override; commit the lockfile. Local path overrides belong in ignored `pubspec_overrides.yaml`. Revisit published dependencies when available.

### 9.3 Runs as event logs

Every run is recorded as an **append-only stream of typed events** that comes from `dartdicom_net`, plus app-level events:

```
RunStarted ─ DnsResolved ─ TcpConnected ─ (TlsHandshaked) ─ PduSent(A-ASSOCIATE-RQ)
  ─ PduReceived(A-ASSOCIATE-AC | RJ) ─ ContextsNegotiated ─ DimseSent(C-FIND-RQ)
  ─ DimseReceived(C-FIND-RSP, Pending)×n ─ DimseReceived(Success) ─ Released ─ RunFinished
```

Everything else is a **projection** of that log:

```
                    ┌─▶ timeline view (DX-01)
 Run event log ─────┼─▶ classifier → Diagnosis + Hints (DX-02)
 (immutable,        ├─▶ PDU inspector (DX-06)
  serialisable)     ├─▶ metrics (DX-07)
                    ├─▶ report export (DX-10, via Redactor)
                    └─▶ history persistence (HX-01/02) and FakeDimseGateway replay
```

Benefits:

- one source of truth
- re-run analysis with a newer knowledge base
- deterministic tests from recorded logs
- easy to attach to bug reports, once redacted

### 9.4 Concurrency

- **Isolates:** one network isolate per active association (or a pool), plus one isolate for the built-in SCP. The isolates exchange **sendable** commands and events with the UI isolate.
- **Cancellation:** C-CANCEL and abort are first-class commands.
- **Backpressure:** C-FIND results and received instances stream in, and the UI subscribes with batching.

---

## 10. Upstream Requirements for the dartdicom Libraries

DimseDash needs these from the libraries. They should go into the ecosystem PRD.

| Need | Library | Ecosystem PRD ref | Pri for DimseDash |
|---|---|---|---|
| **Observability event stream**: time-stamped events for TCP connect, TLS handshake, every PDU (raw bytes + decoded), state-machine transitions, negotiation results, DIMSE messages. Events must be sendable across isolates. | `dartdicom_net` | extends N-15 (new P0) | P0 |
| Raw access to A-ASSOCIATE-RJ / A-ABORT fields and full A-ASSOCIATE-AC user-information items | `dartdicom_net` | N-01 | P0 |
| Every association parameter configurable: contexts, max PDU, implementation UID/version, user identity, role selection, async ops, timeouts | `dartdicom_net` | N-01, N-03, N-12 | P0 / P1 |
| C-CANCEL and abort exposed on the SCU APIs | `dartdicom_net` | N-12 | P0 |
| SCP hooks per association **and** a policy hook (accept/reject/delay/status override) for mock behaviour | `dartdicom_net` | N-10 | P0 / P1 |
| Streaming results (`Stream`) for C-FIND / C-MOVE / C-GET with sub-operation counters | `dartdicom_net` | N-08, N-09 | P0 |
| DIMSE status registry by service class (meaning, category) | `dartdicom_net` | new | P0 |
| Header tree API, DICOM JSON, Specific Character Set decoding | `dartdicom` | C-05, C-09, C-13 | P0 |
| De-identification / redaction helper | `dartdicom` | C-16 (raise priority) | P0 |
| Transcode to an uncompressed transfer syntax for the C-STORE fallback | `dartdicom` / `dartdicom_pixel` | C-08, X-02 | P1 |
| Basic thumbnails using the existing native pixel renderer, with explicit unsupported-preview handling; compressed decoding is not a first-preview prerequisite | `dartdicom_pixel` | Re-map against current library PRD | P0 |

---

## 11. Roadmap

```
v0.1 Echo ──▶ v0.2 Find ──▶ v0.3 Retrieve & Send ──▶ v0.4 Evidence ──▶ v0.5 Developer tools ──▶ v1.0
```

| Version | Scope | Depends on (ecosystem) | Exit criteria |
|---|---|---|---|
| **v0.1 Echo** | WS-01…05, OP-01, SCP-02, DX-01…06, HX-01…03 (DCMTK), SF-01…06 | `dartdicom_net` 0.1 (C-ECHO + event stream); UI can start on `FakeDimseGateway` | Echo against Orthanc / DCMTK / pynetdicom. Each of the top 10 failure cases in Appendix A is diagnosed correctly. |
| **v0.2 Find** | OP-02, RV-01, RV-02, HX-02 | `dartdicom_net` C-FIND; `dartdicom` header API | Patient/Study root queries at all levels, streaming 10k rows, C-CANCEL works |
| **v0.3 Retrieve & Send** | SCP-01, SCP-03, SCP-04, OP-03…05, RV-03 (basic) | C-MOVE / C-GET / C-STORE; `dartdicom_pixel` 0.1 | End-to-end C-MOVE to the built-in SCP with live counters. C-STORE of a 1k-instance folder. |
| **v0.4 Evidence** | DX-07…10, OP-07, OP-08, HX-03 (all), WS-06, OP-10 | TLS, user identity | Health-check report, conformance matrix, TLS echo against a TLS-enabled Orthanc |
| **v0.5 Developer tools** | SCP-05, OP-06, RV-04 | SCP policy hook | Mock SCP simulates reject, status and latency. MWL presets. |
| **v1.0** | Polish, packaging, accessibility audit, docs site, field testing | Ecosystem libraries at a stable API | Signed builds for all three desktop OSes, ≥ 2 commercial PACS field-tested |
| **Later** | AU-01…04, OP-09, SCP-06, DX-11, DX-12, HX-04, WS-07, mobile | N-services | — |

---

## 12. Success Metrics

- **Time to diagnosis:** in usability tests, users find the cause of each of the 10 common failures (Appendix A) **in under 2 minutes, without reading logs**.
- **Diagnostic accuracy:** ≥ 95% correct classification on a recorded corpus of failure event logs.
- **Interop:** passes the matrix (Orthanc, DCMTK `dcmqrscp`/`storescp`, pynetdicom SCPs, ≥ 2 commercial PACS) for every supported operation.
- **Reproducibility:** for each supported operation, the exported DCMTK and pynetdicom code reproduces the same outcome.
- **Adoption** (no telemetry, so public signals only): GitHub stars, release downloads, issues and PRs from outside contributors, knowledge-base contributions.
- **Library health:** every `dartdicom_net` bug found through DimseDash becomes a regression test in the library.

---

## 13. Risks & Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| PHI exposure via screenshots, exports or history | Privacy incident | Redaction on by default for exports, opt-in storage of result data, no telemetry, PHI-free logs (SF-02, HX-02, SF-06) |
| Accidental writes to a production PACS | Data integrity incident | Production guard, read-only mode, confirmations (SF-01) |
| **Inbound connectivity for C-MOVE** (firewalls, NAT, VPN, OS firewall prompts) | Retrieve "doesn't work" for reasons outside the app | Explicit "Retrieve-callback" diagnosis layer; built-in SCP reachability check; C-GET as an alternative; docs on firewall setup |
| Privileged ports (< 1024, e.g. 104) need elevated rights on macOS/Linux | The SCP can't start | Default to `11112`, with a clear error and hint if binding fails |
| Library not ready (`dartdicom_net` timelines) | App blocked | `FakeDimseGateway` with recorded event logs; app milestones mapped to library milestones (§11) |
| Vendor quirks make hints wrong | Misleading guidance | Hints labelled by confidence; vendor-specific notes in the knowledge base; "report a wrong hint" link |
| Scope creep toward a viewer or PACS | Never ships | Explicit non-goals (§15); image preview stays minimal |
| Confusion with API Dash branding | Trust or legal friction | "Inspired by, not affiliated" in the README and About; distinct name, logo and colours |
| Mac App Store sandbox limits (listening sockets, file access) | Distribution friction | Direct notarised download first; App Store later if feasible |

---

## 14. Open Questions

1. **License — settled**: MIT, initially under Lightbridge-KS.
2. **State management**: Riverpod, Bloc, or plain `ChangeNotifier` + signals? (Constraint: view-models consume streams from `dimsedash_core`.)
3. **Workspace file format**: YAML (readable, git-friendly) or JSON (simpler, schema-validated)? One file per node or one file per folder?
4. **Knowledge-base format**: declarative YAML rules vs Dart code? How are community contributions reviewed?
5. **Received-instance storage**: DICOM files on disk by default vs memory-only by default?
6. **Mobile**: is iPad/Android worth it, given the background-listening limits?
7. **DICOMweb**: out of scope by name. Ever add a secondary DICOMweb tab via `dartdicom_web`, or leave that to a sibling app?
8. **Branding**: logo and final visual treatment remain open; initial repository owner is Lightbridge-KS. Start from the supplied blue Material theme.
9. **Demo onboarding**: ship a docker-compose demo PACS (Orthanc) with sample data, and with which de-identified sample datasets?
10. **Distribution**: direct downloads only, or also Homebrew cask / winget / Flathub / app stores?

---

## 15. Out of Scope (v1)

- Diagnostic image viewing, measurements, hanging protocols. DimseDash is **not** a viewer.
- Acting as a production PACS, router or archive. The mock SCP is for testing only.
- DICOMweb (QIDO/WADO/STOW), HL7 v2, FHIR.
- OS-level packet capture (libpcap). Diagnostics come from the protocol library's own event stream.
- Clinical certification of any kind.

---

## Appendix A — Diagnostic knowledge base (starter set)

These are the first rules the classifier (DX-02) must handle. Codes and meanings are from DICOM PS3.7 (DIMSE) and PS3.8 (Upper Layer).

| # | Symptom (first failing stage) | Layer | Likely cause | Hint shown to the user |
|---|---|---|---|---|
| 1 | TCP connect → *connection refused* | Network | Nothing is listening on host:port | Check the port number and that the DICOM service is running on the remote host |
| 2 | TCP connect → *timeout* | Network | Firewall, routing or VPN | Check firewalls and routes between this machine and the host. Try from the same subnet. |
| 3 | TLS handshake fails | TLS | Certificate trust, TLS version, cipher, or a non-TLS port | Check the CA and certificates, and whether this port expects TLS at all |
| 4 | A-ASSOCIATE-RJ, source *service-user*, reason **7: called-AE-title-not-recognized** | Association | Wrong called AE | Check the called AE spelling and case (≤ 16 chars) against the remote configuration |
| 5 | A-ASSOCIATE-RJ, source *service-user*, reason **3: calling-AE-title-not-recognized** | Association | DimseDash's AE isn't registered on the remote side | Ask the PACS admin to add AE `DIMSEDASH` (and often its IP and port) to the allowed list |
| 6 | A-ASSOCIATE-RJ, source *service-provider (presentation)*, reason **1: temporary-congestion** / **2: local-limit-exceeded** (often *rejected-transient*) | Association | Too many associations or a busy node | Retry later. Check the remote's maximum-associations setting. |
| 7 | Presentation context result **3: abstract-syntax-not-supported** | Negotiation | The remote doesn't support this SOP class | Check the remote's conformance statement. Run the conformance probe. |
| 8 | Presentation context result **4: transfer-syntaxes-not-supported** | Negotiation | None of the proposed transfer syntaxes is accepted | Also propose Implicit VR Little Endian, the default every node must support |
| 9 | A-ABORT right after A-ASSOCIATE-AC or the first P-DATA | Association | IP not allowed, policy, or a protocol mismatch | Check the remote's access rules by IP and AE. Inspect the abort source and reason in the PDU trace. |
| 10 | C-MOVE status **0xA801: Refused, move destination unknown** | Application | The PACS doesn't know the destination AE | Register the destination AE title **with its IP and port** on the PACS |
| 11 | C-MOVE completes, but **failed sub-operations > 0 and nothing received** | Retrieve-callback | The PACS can't connect back to the destination | Check the IP and port registered for the destination, the local OS firewall, and NAT/VPN. Or use C-GET. |
| 12 | C-STORE status **0xA7xx: Refused, out of resources** | Application | Storage full or resources exhausted on the remote | Contact the remote admin (disk or quota) |
| 13 | DIMSE status **0x0122: Refused, SOP class not supported** | Application | Accepted at negotiation but refused at the service level | Check the remote's configuration for this SOP class |
| 14 | DIMSE status **0xA900** (identifier / data set does not match SOP class) or **0xCxxx: unable to process** | Application | Malformed query keys or data | Check the query level, required keys and Specific Character Set. See Error Comment (0000,0902). |
| 15 | Negotiated max PDU very small (e.g. ≤ 16 KB) with slow C-STORE | Performance | Peer limitation | Raise the max PDU on the remote, if it's configurable |

Reference values (PS3.8):

- **A-ASSOCIATE-RJ result:** 1 = rejected-permanent, 2 = rejected-transient.
- **Source:**
  - 1 = service-user: reasons 1 no-reason-given, 2 application-context-name-not-supported, 3 calling-AE-title-not-recognized, 7 called-AE-title-not-recognized.
  - 2 = service-provider (ACSE): reasons 1 no-reason-given, 2 protocol-version-not-supported.
  - 3 = service-provider (presentation): reasons 1 temporary-congestion, 2 local-limit-exceeded.
- **Presentation context result:** 0 acceptance, 1 user-rejection, 2 no-reason (provider rejection), 3 abstract-syntax-not-supported, 4 transfer-syntaxes-not-supported.
- **A-ABORT source:** 0 service-user, 2 service-provider. Provider reasons: 0 not specified, 1 unrecognized PDU, 2 unexpected PDU, 4 unrecognized PDU parameter, 5 unexpected PDU parameter, 6 invalid PDU parameter value.

## Appendix B — Example generated code (HX-03)

A C-ECHO from the profile `DIMSEDASH` to node `PACS_MAIN` at `pacs-test.local:104`:

```bash
# DCMTK
echoscu -v -aet DIMSEDASH -aec PACS_MAIN pacs-test.local 104
```

```python
# pynetdicom
from pynetdicom import AE
from pynetdicom.sop_class import Verification

ae = AE(ae_title="DIMSEDASH")
ae.add_requested_context(Verification)
assoc = ae.associate("pacs-test.local", 104, ae_title="PACS_MAIN")
if assoc.is_established:
    status = assoc.send_c_echo()
    print(f"C-ECHO status: 0x{status.Status:04X}")
    assoc.release()
```

```dart
// dartdicom_net (API per the ecosystem PRD; subject to change)
final ae = ApplicationEntity(aeTitle: 'DIMSEDASH')
  ..addRequestedContext(SopClass.verification);
final assoc = await ae.associate('pacs-test.local', 104, aeTitle: 'PACS_MAIN');
if (assoc.isEstablished) {
  final status = await assoc.sendCEcho();
  print('C-ECHO status: ${status.hex}');
  await assoc.release();
}
```

## Appendix C — Workspace file format (sketch)

```yaml
# workspace/environments/test.yaml
kind: environment
name: Test
safety: test            # dev | test | production
variables:
  PACS_HOST: pacs-test.local
  PACS_PORT: "104"
```

```yaml
# workspace/nodes/site-a/pacs-main.yaml
kind: node
name: PACS Main
host: "{{PACS_HOST}}"
port: "{{PACS_PORT}}"
calledAeTitle: PACS_MAIN
tls:
  enabled: false
contexts: default-storage-and-qr   # named preset
tags: [site-a, pacs]
notes: Primary archive. Ask the PACS admin before C-STORE.
```

```yaml
# workspace/operations/site-a/find-ct-this-week.yaml
kind: operation
type: c-find
node: site-a/pacs-main
model: study-root
level: STUDY
query:
  StudyDate: "{{THIS_WEEK}}"
  ModalitiesInStudy: CT
returnKeys: [StudyInstanceUID, AccessionNumber, PatientID, PatientName, NumberOfStudyRelatedSeries]
```

Secrets (passwords, private keys) are referenced by keychain ID, never stored inline.

## Appendix D — Suggested first prompts for Codex

1. *"Read the ideas and exploration review. Settle the remaining product choices, then write the PRD in `docs/req/` and the system and surface architecture. Edit early decisions in place; no ADR yet."*
2. *"Scaffold the `dimsedash` repo per §9.2: pub workspace, Flutter desktop app shell (three-pane layout from §6.1), a pure-Dart `dimsedash_core` package, lints and CI."*
3. *"In `dimsedash_core`, model the run event log (§9.3) and the `DimseGateway` port. Implement `FakeDimseGateway`, which replays recorded logs for the 15 failure cases in Appendix A."*
4. *"Implement the failure classifier (DX-02) as a projection over the event log, with table-driven tests for every Appendix A row."*
5. *"Build the diagnostics panel (§6.2) and the timeline against `FakeDimseGateway`, with golden tests in light and dark themes."*

## Appendix E — References

- API Dash (inspiration; Apache-2.0) — https://github.com/foss42/apidash
- DICOM PS3.7 Message Exchange (DIMSE services, status codes) — https://www.dicomstandard.org/current
- DICOM PS3.8 Network Communication Support (Upper Layer, PDUs, A-ASSOCIATE-RJ/A-ABORT) — https://www.dicomstandard.org/current
- DICOM PS3.15 Security Profiles (TLS, de-identification) — https://www.dicomstandard.org/current
- DCMTK network tools — https://dicom.offis.de/dcmtk
- pynetdicom — https://github.com/pydicom/pynetdicom
- Orthanc (test PACS) — https://www.orthanc-server.com
- `dartdicom` release and current design: https://github.com/Lightbridge-KS/dartdicom/releases/tag/v0.1.0-dev.1

---

## Revision history

| Version | Date | Changes |
|---|---|---|
| v0.1 | 2026-10-18 | First draft: name **DimseDash**, general user personas, full requirement set, architecture, roadmap |
| v0.1.1 | 2026-10-18 | The coding assistant referenced is now Codex (purpose line, Appendix D) |
