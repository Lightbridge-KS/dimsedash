---
summary: Approved Option A Nodes dashboard, with retained Option B comparison and interaction contracts for S1.
read_when:
  - reviewing the location and interaction of DICOM node management
  - implementing an approved node-library UI refinement
---

# Node library placement — approved dashboard

Status: dashboard Option A approved 2026-10-20; its separate Workbench destination and picker are superseded by the [approved nested-workbench refinement](05-navigation-simplification.md). This document and its prototype retain the earlier comparison and rationale.

[Interactive comparison](assets/node-library-options.html) · [Approved surface](03-surface-architecture.md) · [S1 tracker](../progress/s1-echo.md)

The previous sidebar grew with the number of nodes, pushing navigation below configuration content. Both options make the sidebar a stable navigation surface and move node management into the main workspace. The existing blue palette, local identity, explicit networking and runtime ownership remain intact.

## Options

| | A — Nodes dashboard (approved) | B — Workbench gallery |
|---|---|---|
| Navigation | Nodes, Workbench, Received files, History, Settings | Workbench, Received files, History, Settings |
| Node library | Dedicated Nodes destination, opened on launch | Expandable gallery above the operation composer |
| Click card | Select node and open Workbench | Select node and collapse gallery into a target strip |
| Switch target while working | Searchable Change node dialog; Manage nodes opens dashboard | Change node expands the inline gallery |
| Diagnostic space | Full workspace available to operations/evidence | Gallery competes with operations/evidence while expanded |
| Best fit | Growing libraries and future Find/retrieve tables | Small libraries and a preference for one main destination |
| Main cost | One additional navigation destination | More layout movement and scrolling when choosing nodes |

**Settled:** Option A provides a dedicated Nodes destination. Upcoming query results and retrieval evidence keep the full Workbench workspace. Option B is retained only for comparison.

The compact list toggle is a density option within either design, not a third information architecture. Cards aid recognition; the list makes larger libraries easier to scan. Both use label ordering with stable ID tie-breaking, local search across label/host/called AE, and a local Test/Production filter. No folders, favorites, tags, automatic probes or persistent per-node health cache are introduced.

## Card and menu

Each card shows the node label, called AE, endpoint, environment and selected-target marker. Use a restrained server icon and environment chip; operating-system imagery does not describe DICOM behavior. Production styling is a configuration designation, not an error or connectivity result.

- The card body is a single keyboard-focusable Open Workbench action.
- A separate three-dot button offers Open Workbench, Edit node, Duplicate and Remove node.
- Edit opens the existing connection fields without selecting the edited node. Save preserves its ID and checks its revision; it does not alter an active run.
- Duplicate opens an unsaved draft. Saving assigns a new ID, selects it and opens Workbench. Discard creates nothing.
- Remove requires confirmation. Removing the selected node clears selection; history and active evidence survive. No replacement node is silently chosen.
- Add node is always visible beside the library title. A first-launch empty state uses the same action; a filtered empty state offers Clear filters.

Card activation is navigation and configuration selection only. Run Echo remains a deliberate action inside Workbench; no card menu shortcut sends traffic. Avoid online/offline dots: S1 has no continuous reachability observation. A future last-Echo annotation would need an explicit timestamp, scope and configuration-revision match, and is not part of this proposal.

## Workbench and Settings

The operation header shows **Target for next run**, node label, environment, called AE and endpoint. Calling AE and global timeouts remain visible nearby. A run's frozen target is separately labeled in its evidence. A mismatch notice appears when selection or configuration changes after Run. Selecting another node while Echo runs prepares the next target; it never cancels, retargets or releases the current run, and admission remains occupied until cleanup finishes.

The latest run remains the app's current/latest run, not an invented per-node history tab. Navigating between Nodes, Workbench and Settings does not change operation ownership. A small active-run strip provides a return path to evidence from other destinations.

Global Settings retains appearance, calling AE, client listening port and timeouts. The later approved Settings simplification removes its selected-node editor; Nodes exclusively owns remote-node editing. Full Settings controls are outside this prototype. Reveal/masking behavior remains as approved; the draft contains only synthetic configuration and omits the global reveal control for focus.

## Layout and interaction requirements

- Keep navigation stable regardless of node count. The receiver stays at the bottom when space permits, with its status icon/text left-aligned to the heading and identity. Status is informational, without button semantics. Retain the unavailable explanation; scroll the sidebar at constrained heights.
- Scroll the library/workspace independently from navigation in Flutter. Use an adaptive card grid with a readable minimum width; let the list scroll within its content area.
- Card selection and a running operation use distinct labels. Environment, selection and outcomes must not rely on color alone.
- Preserve search, filter and library scroll position when returning during the session. View mode is also retained for the session; no persistent preference fields are added.
- Tab reaches card actions and their menus separately; Enter opens a card. Escape dismisses menus/dialogs, restores launcher focus and never stops Echo. Modal focus trapping and error announcements need Flutter verification.
- At narrow supported desktop widths, reduce grid columns and retain labeled navigation. The supported minimum remains 760 × 600. The browser draft also has a narrow horizontal navigation fallback; this does not propose mobile support or a new Flutter minimum width.
- Keep launch selection restoration from S1. Option A initially shows Nodes with the restored selection indicated; Workbench resumes that configured target without running it. Option B initially shows the gallery with restored selection indicated.

## Prototype limits and review

The HTML draft is self-contained, uses synthetic example endpoints, stores edits only in memory, and makes no DICOM requests. Run Echo simulates a twelve-second operation to expose navigation/target ownership; its outcome is illustrative, not diagnostic evidence. Echo detail tabs illustrate space and labeling only.

The prototype demonstrates both layouts, theme switching, card/list density, search/filtering, add/edit/duplicate/remove dialogs, empty states, target switching and frozen run target labeling. It does not implement full DICOM validation, revision conflicts, durable persistence, native accessibility, virtualized large lists, or Flutter pane scrolling. Future implementation should reuse S1 commands and retain the existing runtime/persistence tests, with new widget coverage for navigation, focus and responsive behavior.

The approved dashboard is recorded in the surface document and S1 tracker. The HTML remains a comparative prototype; the tracker records Flutter verification separately. Manual desktop acceptance remains pending.

## Persistence and editor completion

Opening a node waits for successful selection persistence before navigating. Opening the selected node does not write again. Add and Duplicate use explicit Add mode; Edit captures node identity and revision without changing selection. Typed editor completion identifies a successful saved node; dismissal never means success.

Expected storage or conflict failures retain the entered draft. Reload saved values and Discard are explicit recovery actions; there is no automatic overwrite or retry. Pending saves disable duplicate submissions and dismissal. Escape closes idle menus and dialogs. Shared remote-node fields live in `lib/ui`; feature navigation is coordinated by shell callbacks.
