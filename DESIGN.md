---
version: alpha
name: DimseDash Blue Workbench
summary: Approved compact blue desktop workbench tokens extracted from the Material Theme Builder palette and reviewed Settings prototype.
read_when:
  - building or changing the DimseDash desktop UI
colors:
  primary: "#415F91"
  on-primary: "#FFFFFF"
  surface: "#F9F9FF"
  on-surface: "#191C20"
  primary-container: "#D6E3FF"
  on-primary-container: "#284777"
  error: "#BA1A1A"
  on-error: "#FFFFFF"
typography:
  body:
    fontFamily: system-ui
    fontSize: 14px
    fontWeight: 400
  heading:
    fontFamily: system-ui
    fontSize: 24px
    fontWeight: 600
spacing:
  field: 16px
  page: 24px
rounded:
  control: 8px
  card: 10px
components:
  primary-button:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    rounded: "{rounded.control}"
  card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.card}"
---

# DimseDash visual identity

## Overview

The approved reference is the compact blue diagnostic workbench in
`docs/design/assets/workbench-v2.html`, with its earlier Settings panel now superseded by the global-only Settings design in `docs/design/03-surface-architecture.md`. Node-library navigation follows approved Option A in
`docs/design/assets/navigation-options.html`; the earlier node-library comparison
remains available for design history.
The palette comes from the supplied Material Theme Builder blue theme. This
extraction preserves that direction; it is not a new visual proposal.

## Colors

**Blue** {colors.primary} identifies the primary action with white
{colors.on-primary} text. Use **pale blue** {colors.primary-container} and
{colors.on-primary-container} for selected navigation. **Surface**
{colors.surface} carries **ink** {colors.on-surface}. Errors use
{colors.error} with {colors.on-error}; messages also identify the error in text.
Light and dark ColorSchemes are preserved in `lib/ui/theme.dart` from the supplied
theme. No runtime font or theme downloads.

## Typography

Use the native system font: {typography.body} for controls and
{typography.heading} for screen headings. Technical identifiers may use a local
monospace fallback. Text scaling remains enabled.

## Layout

A stable labeled sidebar (Nodes, Received files, History, Settings)
and persistent receiver status frame the workspace. Nodes is the initial destination; a card opens its nested workbench, with All nodes returning to the preserved library. Nodes stays selected in both views. Use
{spacing.page} page padding and {spacing.field} between fields. Client identity is edited in Settings; remote PACS fields are edited in Nodes. Narrow windows stack fields
and keep scrolling local to the workspace. At the 760 × 600 minimum, reduce card
columns and allow sidebar scrolling if needed. Receiver status is a left-aligned
icon-and-text row, aligned with its heading and identity; it is not a button.

## Elevation & Depth

Use tonal surfaces and fine outlines, with restrained elevation. Status is
expressed through text and icons as well as color.

## Shapes

Controls use {rounded.control}; cards use {rounded.card}. Keep alignment regular
across node, Settings and future query surfaces.

## Components

The {components.primary-button} marks explicit Save settings or Save node; Discard is secondary.
The {components.card} groups related settings. Every input has a persistent label
and validation message. Node cards show label, called AE, endpoint, environment
and a distinct Selected marker, with a separate action menu. List density, local
search and environment filtering use the same records. Test/Production denotes
configuration, never connectivity. The node heading shows environment, endpoint and calling AE once; Connection details expands the labeled timeouts. Workbench distinguishes current settings
from the frozen executed target. Unimplemented workflows show an honest explanatory state.

## Do's and Don'ts

- Preserve the blue palette, density and separation of client/PACS ownership.
- Keep focus visible and every action reachable by keyboard.
- Do not fabricate run results, connectivity status or a listening receiver.
- Do not imply masking removes identifying data from stored DICOM objects.

## Query preview

Approved Option A places the full-width query composer above results inside the
node workbench, with Echo / Query switching under the shared node header. Filters,
Advanced Identifier and Resolved Identifier share a draft; Collapse is explicit.
At narrow widths fields stack and tables scroll horizontally within their panel.

The current Query implementation is labeled **UI preview · synthetic data · no
network**. Fixed fixtures are distinct from live Echo evidence. Preview controls
live in a disclosure; arbitrary tag/sequence editing is an illustrative sketch.
Remote queries and retrieval remain pending. See
[the Query preview tracker](docs/progress/query-ui-preview.md).
