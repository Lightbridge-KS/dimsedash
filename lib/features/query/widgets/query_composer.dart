import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';

import '../preview/query_preview_controller.dart';
import '../preview/query_preview_model.dart';
import 'query_display.dart';

/// Edits the shared preview draft without owning its session or Run admission.
class QueryComposer extends StatelessWidget {
  const QueryComposer({
    super.key,
    required this.controller,
    required this.config,
    required this.reveal,
    required this.echoActive,
    required this.error,
    required this.onRun,
  });
  final QueryPreviewController controller;
  final AppConfiguration config;
  final bool reveal, echoActive;
  final String? error;
  final VoidCallback onRun;
  QueryPreviewController get c => controller;

  @override
  Widget build(BuildContext context) => queryCard([
    Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Query criteria',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text('Study Root / ${c.draft.level.name.toUpperCase()} · C-FIND'),
          ],
        ),
        TextButton(
          onPressed: () => c.setCollapsed(!c.collapsed),
          child: Text(c.collapsed ? 'Edit criteria' : 'Collapse'),
        ),
      ],
    ),
    if (c.collapsed)
      Text(
        '${c.draft.level.name.toUpperCase()} · ${c.draft.keys.where((k) => c.draft.entry(k).enabled && c.draft.entry(k).purpose == IdentifierPurpose.match).length} matching keys · expand to inspect exact criteria',
      )
    else ...[
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final e in QueryEditor.values)
            ChoiceChip(
              label: Text(switch (e) {
                QueryEditor.filters => 'Filters',
                QueryEditor.advanced => 'Advanced Identifier',
                QueryEditor.resolved => 'Resolved Identifier',
              }),
              selected: c.editor == e,
              onSelected: (_) => c.setEditor(e),
            ),
        ],
      ),
      const SizedBox(height: 16),
      switch (c.editor) {
        QueryEditor.filters => _filters(context),
        QueryEditor.advanced => _advanced(context),
        QueryEditor.resolved => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Next request · read-only application preview, not a packet capture',
            ),
            Text(
              'C-FIND · Study Root · ${config.node?.calledAe ?? 'Node unavailable'} · ${config.node?.host ?? ''}:${config.node?.port ?? ''}',
            ),
            Text(
              'Calling AE ${config.client.callingAe} · command settings are outside the dataset',
            ),
            queryIdentifier(context, c.draft.identifier, reveal),
          ],
        ),
      },
    ],
    const Divider(height: 28),
    if (c.draft.validation != null)
      Text(
        c.draft.validation!,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    if (error != null)
      Text(
        error!,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    if (echoActive)
      const Text(
        'Echo is active. Preview Run is unavailable until resource cleanup finishes.',
      ),
    Align(
      alignment: Alignment.centerRight,
      child: FilledButton.icon(
        key: const ValueKey('run-query-preview'),
        onPressed: echoActive || c.draft.validation != null ? null : onRun,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Run Query · preview'),
      ),
    ),
  ]);

  String _intent(PreviewKey key) {
    final e = c.draft.entry(key);
    return !e.enabled
        ? 'Disabled · omitted from request'
        : e.purpose == IdentifierPurpose.returnKey
        ? 'Return key · empty on wire'
        : 'Matching key';
  }

  Widget _field(
    BuildContext context,
    PreviewKey key,
    String label, {
    String? hint,
  }) => TextFormField(
    key: ValueKey('friendly-${c.draft.level}-$key-${c.formRevision}'),
    initialValue: c.draft.entry(key).value,
    decoration: InputDecoration(
      labelText: label,
      helperText:
          '${keyTag(key, c.draft.level)} · ${_intent(key)}${hint == null ? '' : '\n$hint'}',
      helperMaxLines: 4,
    ),
    onChanged: (v) => c.edit(key, v),
  );
  Widget _filters(BuildContext context) {
    final fields = <Widget>[
      if (c.draft.level == QueryLevel.study) ...[
        _field(
          context,
          PreviewKey.patientId,
          'Patient ID',
          hint: 'No automatic wildcard',
        ),
        _field(
          context,
          PreviewKey.patientName,
          'Patient name',
          hint: 'Family^Given; patterns explicit',
        ),
        _field(context, PreviewKey.accession, 'Accession number'),
        _dates(context),
      ] else
        queryIdentifier(
          context,
          'Parent StudyInstanceUID = ${c.draft.studyUid}${c.draft.seriesUid == null ? '' : '\nParent SeriesInstanceUID = ${c.draft.seriesUid}'}',
          reveal,
        ),
      if (c.draft.level != QueryLevel.image) ...[
        _field(
          context,
          PreviewKey.modality,
          c.draft.level == QueryLevel.study
              ? 'Modalities in study'
              : 'Series modality',
          hint: 'Optional matching support unknown',
        ),
        _field(
          context,
          PreviewKey.bodyPart,
          c.draft.level == QueryLevel.study
              ? 'Body part · next series query'
              : 'Body part',
          hint: c.draft.level == QueryLevel.study
              ? 'Not sent at STUDY level'
              : 'Matching support unknown',
        ),
      ],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final columns = box.maxWidth >= 1000
                ? 3
                : box.maxWidth >= 660
                ? 2
                : 1;
            final width = (box.maxWidth - 16 * (columns - 1)) / columns;
            return Wrap(
              spacing: 16,
              runSpacing: 20,
              children: [
                for (final field in fields)
                  SizedBox(width: width, child: field),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          c.draft.level == QueryLevel.study
              ? 'Filled keys combine without an inferred OR. Editing a field re-enables its key.'
              : 'Opening this level loads no results. Run the preview explicitly with these parent UIDs.',
        ),
        if (c.draft.level == QueryLevel.study &&
            c.draft.entry(PreviewKey.bodyPart).value.isNotEmpty)
          queryNotice(
            context,
            'Body part is pending for the next series query. Study results are not body-part-filtered.',
          ),
      ],
    );
  }

  Widget _dates(BuildContext context) {
    final raw = c.draft.entry(PreviewKey.date).value;
    // Unsupported advanced expressions remain visible, never coerced to dates.
    final simple = RegExp(r'^(\d{8})?(-(\d{8})?)?$').hasMatch(raw);
    if (!simple && c.dateEditedInAdvanced) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Study date period · Custom — edit in Advanced'),
          TextButton(
            onPressed: () => c.setEditor(QueryEditor.advanced),
            child: const Text('Edit date in Advanced'),
          ),
        ],
      );
    }
    return _QueryDateFields(
      key: ValueKey('date-fields-${c.formRevision}'),
      controller: c,
      intent: _intent(PreviewKey.date),
    );
  }

  Widget _advanced(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Common keys only · purpose and enabled state are explicit. Full tag/VR validation is not implemented.',
      ),
      const SizedBox(height: 12),
      Text(
        'Service-required (locked) · QueryRetrieveLevel = ${c.draft.level.name.toUpperCase()}',
      ),
      if (c.draft.level != QueryLevel.study)
        Text(
          'Service-required (locked) · StudyInstanceUID = ${querySensitive(c.draft.studyUid, reveal)}',
        ),
      if (c.draft.level == QueryLevel.image)
        Text(
          'Service-required (locked) · SeriesInstanceUID = ${querySensitive(c.draft.seriesUid, reveal)}',
        ),
      for (final key in c.draft.keys)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${keyTag(key, c.draft.level)} ${keyVr(key)} · ${keyName(key, c.draft.level)}',
                ),
                value: c.draft.entry(key).enabled,
                onChanged: (v) => c.advanced(key, enabled: v),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              DropdownButtonFormField<IdentifierPurpose>(
                key: ValueKey('purpose-$key-${c.formRevision}'),
                initialValue: c.draft.entry(key).purpose,
                decoration: InputDecoration(
                  labelText: '${keyName(key, c.draft.level)} purpose',
                ),
                items: const [
                  DropdownMenuItem(
                    value: IdentifierPurpose.match,
                    child: Text('Match'),
                  ),
                  DropdownMenuItem(
                    value: IdentifierPurpose.returnKey,
                    child: Text('Return key'),
                  ),
                ],
                onChanged: (v) => c.advanced(key, purpose: v),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: ValueKey('advanced-$key-${c.formRevision}'),
                initialValue: c.draft.entry(key).value,
                enabled:
                    c.draft.entry(key).enabled &&
                    c.draft.entry(key).purpose == IdentifierPurpose.match,
                decoration: InputDecoration(
                  labelText: '${keyName(key, c.draft.level)} value',
                  helperText: _intent(key),
                ),
                onChanged: (v) => c.advanced(key, value: v),
              ),
            ],
          ),
        ),
      const Text(
        'Unique result UID and displayed metadata return keys are included automatically; inspect Resolved Identifier.',
      ),
      TextButton(
        onPressed: () => showQueryDialog(
          context,
          'Tag / sequence editor · illustrative sketch',
          const Text(
            'Future S2 editor: numeric tag path, VR, purpose, enabled state and value; expandable sequence items and private-creator context.\n\n(0040,0275) SQ RequestAttributesSequence\n  Item · one matching group\n    (0040,1001) SH RequestedProcedureID\n\nThis sketch cannot author or validate arbitrary tags or sequences.',
          ),
        ),
        child: const Text('Tag / sequence sketch'),
      ),
    ],
  );
}

/// Retains each literal bound while typing so one edit cannot reinterpret the
/// other bound by splitting a malformed date as though it were a DA range.
class _QueryDateFields extends StatefulWidget {
  const _QueryDateFields({
    super.key,
    required this.controller,
    required this.intent,
  });
  final QueryPreviewController controller;
  final String intent;

  @override
  State<_QueryDateFields> createState() => _QueryDateFieldsState();
}

class _QueryDateFieldsState extends State<_QueryDateFields> {
  late String _from, _through, _lastRaw;

  @override
  void initState() {
    super.initState();
    _load(widget.controller.draft.entry(PreviewKey.date).value);
  }

  @override
  void didUpdateWidget(covariant _QueryDateFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    final raw = widget.controller.draft.entry(PreviewKey.date).value;
    if (raw != _lastRaw) _load(raw);
  }

  void _load(String raw) {
    _lastRaw = raw;
    final simple = RegExp(r'^(\d{8})?(-(\d{8})?)?$').hasMatch(raw);
    final parts = raw.split('-');
    // Keep a malformed expression intact when returning to the friendly editor.
    _from = simple ? parts.first : raw;
    _through = simple ? (parts.length > 1 ? parts[1] : parts.first) : '';
  }

  String _display(String value) => RegExp(r'^\d{8}$').hasMatch(value)
      ? '${value.substring(0, 4)}-${value.substring(4, 6)}-${value.substring(6)}'
      : value;

  void _edit(bool isFrom, String value) {
    // Only the advertised date shape (or compact DA) may lose separators.
    // Invalid literals remain invalid in the shared draft and therefore block Run.
    final normalized = RegExp(r'^(\d{8}|\d{4}-\d{2}-\d{2})$').hasMatch(value)
        ? value.replaceAll('-', '')
        : value;
    if (isFrom) {
      _from = normalized;
    } else {
      _through = normalized;
    }
    _lastRaw = _from.isEmpty && _through.isEmpty ? '' : '$_from-$_through';
    widget.controller.edit(PreviewKey.date, _lastRaw);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Study date period · inclusive'),
      const SizedBox(height: 8),
      for (final isFrom in [true, false])
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextFormField(
            key: ValueKey('date-$isFrom-${widget.controller.formRevision}'),
            initialValue: _display(isFrom ? _from : _through),
            decoration: InputDecoration(
              labelText: isFrom ? 'Study date From' : 'Study date Through',
              hintText: 'YYYY-MM-DD',
              helperText: isFrom
                  ? 'Blank means no lower bound'
                  : 'Blank means no upper bound',
            ),
            onChanged: (value) => _edit(isFrom, value),
          ),
        ),
      Text(widget.intent),
    ],
  );
}
