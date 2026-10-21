import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bindings/configuration.dart';
import '../../bindings/echo.dart';
import 'query_preview.dart';

class QueryPreviewView extends ConsumerStatefulWidget {
  const QueryPreviewView({
    super.key,
    required this.controller,
    required this.header,
  });
  final QueryPreviewController controller;
  final Widget header;
  @override
  ConsumerState<QueryPreviewView> createState() => _QueryPreviewViewState();
}

class _QueryPreviewViewState extends ConsumerState<QueryPreviewView> {
  late final ScrollController _scroll;
  String? _error;
  QueryPreviewController get c => widget.controller;
  @override
  void initState() {
    super.initState();
    _scroll = ScrollController(initialScrollOffset: c.scrollOffset);
    _scroll.addListener(() => c.scrollOffset = _scroll.offset);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configurationProvider);
    final echoActive = ref.watch(echoStateProvider.select((s) => s.active));
    final reveal = ref.watch(revealProvider);
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => SingleChildScrollView(
        key: const ValueKey('query-scroll'),
        controller: _scroll,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            widget.header,
            _notice('UI preview · synthetic data · no network'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Fixed sample responses do not evaluate entered criteria or emulate PACS matching.',
              ),
            ),
            _card([
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
                      Text(
                        'Study Root / ${c.draft.level.name.toUpperCase()} · C-FIND',
                      ),
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
                  QueryEditor.filters => _filters(),
                  QueryEditor.advanced => _advanced(),
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
                      _identifier(c.draft.identifier, reveal),
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
              if (_error != null)
                Text(
                  _error!,
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
                  onPressed: echoActive || c.draft.validation != null
                      ? null
                      : () {
                          final error = c.run(
                            ref.read(configurationProvider),
                            echoActive: ref.read(echoStateProvider).active,
                          );
                          setState(() => _error = error);
                        },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Run Query · preview'),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _results(reveal),
            if (c.result != null) ...[
              if (c.result!.request.settingsDiffer(config))
                _notice(
                  'Current settings apply to the next preview. Results retain the frozen node revision, calling AE and timeouts.',
                ),
              _evidence(reveal),
            ],
            ExpansionTile(
              title: const Text('Preview controls'),
              children: [
                DropdownButtonFormField<PreviewScenario>(
                  initialValue: c.scenario,
                  decoration: const InputDecoration(
                    labelText: 'Synthetic response scenario',
                  ),
                  items: [
                    for (final scenario in PreviewScenario.values)
                      DropdownMenuItem(
                        value: scenario,
                        child: Text(switch (scenario) {
                          PreviewScenario.complete => 'Complete',
                          PreviewScenario.empty => 'No matches',
                          PreviewScenario.partial => 'Partial / local limit',
                          PreviewScenario.rejected => 'Association rejected',
                        }),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) c.setScenario(v);
                  },
                ),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Only the selected scenario determines sample rows. Preview data is session-only and never enters run history.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
  Widget _notice(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text),
    ),
  );
  Widget _identifier(String text, bool reveal) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.symmetric(vertical: 12),
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    child: Text(
      reveal ? text : 'Identifier values masked. Use Reveal values to inspect the synthetic request.',
      style: const TextStyle(fontFamily: 'monospace'),
    ),
  );
  String _sensitive(String? value, bool reveal) => value == null
      ? 'Not returned'
      : reveal
      ? value
      : '••••••';
  String _intent(PreviewKey key) {
    final e = c.draft.entry(key);
    return !e.enabled
        ? 'Disabled · omitted from request'
        : e.purpose == IdentifierPurpose.returnKey
        ? 'Return key · empty on wire'
        : 'Matching key';
  }

  Widget _field(PreviewKey key, String label, {String? hint}) => TextFormField(
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
  Widget _filters() {
    final fields = <Widget>[
      if (c.draft.level == QueryLevel.study) ...[
        _field(
          PreviewKey.patientId,
          'Patient ID',
          hint: 'No automatic wildcard',
        ),
        _field(
          PreviewKey.patientName,
          'Patient name',
          hint: 'Family^Given; patterns explicit',
        ),
        _field(PreviewKey.accession, 'Accession number'),
        _dates(),
      ] else
        _identifier(
          'Parent StudyInstanceUID = ${c.draft.studyUid}${c.draft.seriesUid == null ? '' : '\nParent SeriesInstanceUID = ${c.draft.seriesUid}'}',
          ref.read(revealProvider),
        ),
      if (c.draft.level != QueryLevel.image) ...[
        _field(
          PreviewKey.modality,
          c.draft.level == QueryLevel.study
              ? 'Modalities in study'
              : 'Series modality',
          hint: 'Optional matching support unknown',
        ),
        _field(
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
          _notice(
            'Body part is pending for the next series query. Study results are not body-part-filtered.',
          ),
      ],
    );
  }

  Widget _dates() {
    final raw = c.draft.entry(PreviewKey.date).value;
    final parts = raw.split('-');
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
    String display(String value) => value.length == 8
        ? '${value.substring(0, 4)}-${value.substring(4, 6)}-${value.substring(6)}'
        : value;
    final from = parts.first, to = parts.length > 1 ? parts[1] : parts.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Study date period · inclusive'),
        const SizedBox(height: 8),
        for (final isFrom in [true, false])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextFormField(
              key: ValueKey('date-$isFrom-${c.formRevision}'),
              initialValue: display(isFrom ? from : to),
              decoration: InputDecoration(
                labelText: isFrom ? 'Study date From' : 'Study date Through',
                hintText: 'YYYY-MM-DD',
                helperText: isFrom
                    ? 'Blank means no lower bound'
                    : 'Blank means no upper bound',
              ),
              onChanged: (value) {
                final current = c.draft.entry(PreviewKey.date).value.split('-');
                final start = isFrom
                    ? value.replaceAll('-', '')
                    : current.first;
                final end = isFrom
                    ? (current.length > 1 ? current[1] : current.first)
                    : value.replaceAll('-', '');
                c.edit(
                  PreviewKey.date,
                  start.isEmpty && end.isEmpty ? '' : '$start-$end',
                );
              },
            ),
          ),
        Text(_intent(PreviewKey.date)),
      ],
    );
  }

  Widget _advanced() => Column(
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
          'Service-required (locked) · StudyInstanceUID = ${_sensitive(c.draft.studyUid, ref.read(revealProvider))}',
        ),
      if (c.draft.level == QueryLevel.image)
        Text(
          'Service-required (locked) · SeriesInstanceUID = ${_sensitive(c.draft.seriesUid, ref.read(revealProvider))}',
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
        onPressed: () => _dialog(
          'Tag / sequence editor · illustrative sketch',
          const Text(
            'Future S2 editor: numeric tag path, VR, purpose, enabled state and value; expandable sequence items and private-creator context.\n\n(0040,0275) SQ RequestAttributesSequence\n  Item · one matching group\n    (0040,1001) SH RequestedProcedureID\n\nThis sketch cannot author or validate arbitrary tags or sequences.',
          ),
        ),
        child: const Text('Tag / sequence sketch'),
      ),
    ],
  );

  Widget _results(bool reveal) {
    final result = c.result;
    return _card([
      Wrap(
        spacing: 8,
        children: [
          for (final level in QueryLevel.values.where(
            (l) => l.index <= c.draft.level.index,
          ))
            TextButton(
              onPressed: level == c.draft.level ? null : () => c.backTo(level),
              child: Text(switch (level) {
                QueryLevel.study => 'Studies',
                QueryLevel.series => 'Series',
                QueryLevel.image => 'Instances',
              }),
            ),
        ],
      ),
      if (result != null) ...[
        Text(result.status),
        Text(
          '${result.rows.length} retained rows · preview-${result.sequence} · ${result.request.draft.level.name.toUpperCase()}',
        ),
        if (c.dirty)
          _notice(
            'Draft changed — rows belong to the previous executed Identifier.',
          ),
      ],
      if (result == null || result.rows.isEmpty)
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            result == null
                ? 'No query results yet. Review criteria, then Run Query · preview.'
                : result.scenario == PreviewScenario.rejected
                ? 'Query failed — not an empty result. No DIMSE response in this synthetic scenario.'
                : 'No matches returned · synthetic',
            textAlign: TextAlign.center,
          ),
        )
      else
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            dataRowMinHeight: 64,
            dataRowMaxHeight: double.infinity,
            columns: [
              DataColumn(
                label: Text(
                  c.draft.level == QueryLevel.study
                      ? 'Study / patient'
                      : 'Description / patient',
                ),
              ),
              const DataColumn(label: Text('Date / modality')),
              DataColumn(
                label: Text(
                  c.draft.level == QueryLevel.study
                      ? 'Accession / series'
                      : 'Body part / UID',
                ),
              ),
              const DataColumn(label: Text('Actions')),
            ],
            rows: [
              for (final row in result.rows)
                DataRow(
                  selected: identical(c.selected, row),
                  cells: [
                    DataCell(
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_sensitive(row.description, reveal)),
                          Text(
                            '${_sensitive(row.patientName, reveal)} · ${_sensitive(row.patientId, reveal)}',
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text('${_sensitive(row.date, reveal)}\n${row.modality}'),
                    ),
                    DataCell(
                      Text(
                        c.draft.level == QueryLevel.study
                            ? '${_sensitive(row.accession, reveal)}\n${row.seriesCount == null ? 'Series count: Not returned' : '${row.seriesCount} series'}'
                            : c.draft.level == QueryLevel.series
                            ? (row.bodyPart ?? 'Not returned')
                            : _sensitive(row.sopUid, reveal),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => _inspect(row, reveal),
                            child: const Text('Inspect'),
                          ),
                          if (c.draft.level != QueryLevel.image)
                            Tooltip(
                              message: row.canTarget(c.draft.level)
                                  ? 'Prepare a child query without executing it'
                                  : 'Required parent UID not returned',
                              child: TextButton(
                                onPressed: row.canTarget(c.draft.level)
                                    ? () => c.openChild(row)
                                    : null,
                                child: Text(
                                  c.draft.level == QueryLevel.study
                                      ? 'Open series'
                                      : 'Open instances',
                                ),
                              ),
                            ),
                          Tooltip(
                            message: row.canTarget(c.draft.level)
                                ? 'Select one retrieval target'
                                : 'Required target UID not returned',
                            child: TextButton(
                              onPressed: row.canTarget(c.draft.level)
                                  ? () => c.select(row)
                                  : null,
                              child: Text(
                                identical(c.selected, row)
                                    ? 'Selected'
                                    : 'Select',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      const Divider(height: 24),
      Text(
        c.selected == null
            ? 'Inspect metadata or select one retrieval target.'
            : '${_sensitive(c.selected!.description, reveal)} · ${c.draft.level == QueryLevel.image ? 'this instance only' : 'all instances in this ${c.draft.level.name}'}',
      ),
      Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton(
          onPressed: c.selected == null
              ? null
              : () => _dialog(
                  'Retrieve handoff · preview',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.draft.level == QueryLevel.image
                            ? 'This instance only'
                            : 'All instances in this ${c.draft.level.name}',
                      ),
                      _identifier(
                        c.selected!.targetIdentifier(c.draft.level),
                        reveal,
                      ),
                      const Text(
                        'Retrieval unavailable. C-GET / C-MOVE and destination readiness belong to a later implementation. No files are transferred.',
                      ),
                    ],
                  ),
                ),
          child: const Text('Review retrieve'),
        ),
      ),
    ]);
  }

  Widget _evidence(bool reveal) {
    final result = c.result!, request = c.result!.request;
    return ExpansionTile(
      key: ValueKey('preview-evidence-${result.sequence}'),
      title: const Text('Query evidence · preview'),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '${result.status}\nFrozen target: ${request.node.label} · ${request.node.calledAe} · ${request.node.host}:${request.node.port}\nNode revision ${request.node.revision} · Calling AE ${request.client.callingAe}\nTimeouts · connect ${request.client.timeouts.connect}s · association ${request.client.timeouts.association}s · DIMSE ${request.client.timeouts.dimse}s · idle ${request.client.timeouts.idle}s',
          ),
        ),
        _identifier(request.draft.identifier, reveal),
        Text(
          result.scenario == PreviewScenario.partial
              ? 'Synthetic local limit reached. Cancellation intent is illustrated; final confirmation is not observed.'
              : result.scenario == PreviewScenario.rejected
              ? 'Synthetic association rejection; no DIMSE status observed.'
              : 'Synthetic final response. Optional matching-key support remains unknown.',
        ),
        const Text(
          'Preview evidence only. No live protocol observations or persistent history.',
        ),
      ],
    );
  }

  void _inspect(PreviewMatch row, bool reveal) => _dialog(
    'Returned metadata · preview',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Inspection does not select a retrieval target.'),
        _identifier(
          'PatientID = ${row.patientId}\nPatientName = ${row.patientName}\nAccessionNumber = ${row.accession}\nDescription = ${row.description}\nStudyInstanceUID = ${row.studyUid ?? 'Not returned'}\nSeriesInstanceUID = ${row.seriesUid ?? 'Not returned'}\nSOPInstanceUID = ${row.sopUid ?? 'Not returned'}',
          reveal,
        ),
      ],
    ),
  );
  Future<void> _dialog(String title, Widget body) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
