import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';

import 'find_composer.dart';
import 'find_evidence.dart';
import 'find_inspection.dart';

/// Bounded, presentation-only projection of the current local results page.
class FindResultsPanel extends StatefulWidget {
  const FindResultsPanel({
    super.key,
    required this.level,
    required this.result,
    required this.selected,
    required this.page,
    required this.reveal,
    required this.warnings,
    required this.actionProblem,
    required this.onSelect,
    required this.onClear,
    required this.onPage,
    required this.onInspect,
    required this.onOpenChild,
    required this.onRetrieve,
    required this.retrieveFocus,
  });
  final FindLevel level;
  final QueryResultContext? result;
  final QueryMatch? selected;
  final int page;
  final bool reveal;
  final List<String> warnings;
  final String? Function(QueryMatch) actionProblem;
  final ValueChanged<QueryMatch> onSelect, onInspect, onOpenChild;
  final VoidCallback onClear;
  final ValueChanged<int> onPage;
  final VoidCallback? onRetrieve;
  final FocusNode retrieveFocus;

  @override
  State<FindResultsPanel> createState() => _FindResultsPanelState();
}

class _FindResultsPanelState extends State<FindResultsPanel> {
  final _heading = FocusNode();
  final _headingKey = GlobalKey();
  // Reparent interactive cells across table/stacked layouts without losing focus.
  final _controls = <String, GlobalKey>{};

  @override
  void didUpdateWidget(FindResultsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result?.runId != widget.result?.runId) _controls.clear();
    final visible = widget.result?.rows.skip(widget.page * 50).take(50);
    final ids = {for (final row in visible ?? <QueryMatch>[]) row.ordinal};
    _controls.removeWhere(
      (key, _) => !ids.contains(int.parse(key.split(':')[0])),
    );
  }

  @override
  void dispose() {
    _heading.dispose();
    super.dispose();
  }

  void _page(int value) {
    widget.onPage(value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _heading.requestFocus();
      Scrollable.ensureVisible(_headingKey.currentContext!);
    });
  }

  GlobalKey _key(QueryMatch row, String action) =>
      _controls.putIfAbsent('${row.ordinal}:$action', GlobalKey.new);

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final rows = result?.rows ?? const <QueryMatch>[];
    final selectedIndex = widget.selected == null
        ? -1
        : rows.indexOf(widget.selected!);
    final colors = Theme.of(context).colorScheme;
    return Card.outlined(
      margin: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Focus(
              key: _headingKey,
              focusNode: _heading,
              skipTraversal: true,
              child: Semantics(
                header: true,
                child: Text(
                  findLevelLabel(widget.level),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (result != null) ...[
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(
                    result.active
                        ? Icons.sync
                        : result.outcome?.disposition ==
                              FindDisposition.complete
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    size: 20,
                  ),
                  Text(
                    findResultLabel(result),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              Text('${result.received} received · ${rows.length} retained'),
              if (result.outcome?.cleanupFailed ?? false)
                _warning(
                  'Cleanup failed. The observed query outcome is unchanged.',
                ),
            ],
            for (final warning in widget.warnings) _warning(warning),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  result == null
                      ? 'No query has run at this level. Review criteria, then Run query.'
                      : result.active
                      ? 'Waiting for responses…'
                      : result.outcome?.disposition == FindDisposition.complete
                      ? 'No matches returned.'
                      : 'Query ended without retained results. See the outcome and evidence.',
                ),
              )
            else ...[
              const SizedBox(height: 16),
              RadioGroup<QueryMatch>(
                groupValue: widget.selected,
                onChanged: (row) {
                  if (row != null) widget.onSelect(row);
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final scale = MediaQuery.textScalerOf(context);
                    final widths = [
                      88.0,
                      260.0,
                      160.0,
                      if (widget.level != FindLevel.image) 180.0,
                      220.0,
                    ].map(scale.scale).toList();
                    final pageRows = rows
                        .skip(widget.page * 50)
                        .take(50)
                        .toList();
                    if (constraints.maxWidth < widths.reduce((a, b) => a + b)) {
                      return Column(
                        key: const ValueKey('results-stacked'),
                        children: [
                          for (final row in pageRows)
                            Container(
                              decoration: BoxDecoration(
                                color: identical(row, widget.selected)
                                    ? colors.primaryContainer
                                    : null,
                                border: Border(
                                  bottom: BorderSide(
                                    color: colors.outlineVariant,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: _stacked(context, row),
                            ),
                        ],
                      );
                    }
                    final titles = switch (widget.level) {
                      FindLevel.study => [
                        'Select',
                        'Study / patient',
                        'Date / modalities',
                        'Accession / series',
                        'Actions',
                      ],
                      FindLevel.series => [
                        'Select',
                        'Series',
                        'Modality / body part',
                        'Instances',
                        'Actions',
                      ],
                      FindLevel.image => [
                        'Select',
                        'Instance',
                        'SOP Instance UID',
                        'Actions',
                      ],
                    };
                    return Table(
                      key: const ValueKey('results-table'),
                      defaultVerticalAlignment: TableCellVerticalAlignment.top,
                      columnWidths: {
                        for (var i = 0; i < widths.length; i++)
                          i: i == 1
                              ? FlexColumnWidth()
                              : FixedColumnWidth(widths[i]),
                      },
                      border: TableBorder(
                        horizontalInside: BorderSide(
                          color: colors.outlineVariant,
                        ),
                      ),
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                          ),
                          children: [
                            for (final title in titles)
                              _pad(
                                Text(
                                  title,
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                          ],
                        ),
                        for (final row in pageRows)
                          TableRow(
                            decoration: BoxDecoration(
                              color: identical(row, widget.selected)
                                  ? colors.primaryContainer
                                  : null,
                            ),
                            children: [
                              for (final cell in _cells(context, row))
                                _pad(cell),
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Showing ${widget.page * 50 + 1}–${((widget.page + 1) * 50).clamp(0, rows.length)} of ${rows.length} retained results',
                  ),
                  if (rows.length > 50) ...[
                    TextButton(
                      onPressed: widget.page > 0
                          ? () => _page(widget.page - 1)
                          : null,
                      child: const Text('Previous page'),
                    ),
                    Text(
                      'Page ${widget.page + 1} of ${(rows.length / 50).ceil()}',
                    ),
                    TextButton(
                      onPressed: (widget.page + 1) * 50 < rows.length
                          ? () => _page(widget.page + 1)
                          : null,
                      child: const Text('Next page'),
                    ),
                  ],
                  const Tooltip(
                    message: '50 retained results per local page. Changing pages sends no request.',
                    child: Icon(
                      Icons.info_outline,
                      semanticLabel: 'Local pagination help',
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
            if (result != null) ...[
              const Divider(height: 32),
              if (selectedIndex < 0)
                const Text(
                  'No target selected. Inspect metadata or select one retrieval target.',
                )
              else ...[
                Text(
                  'Selected ${widget.level == FindLevel.image ? 'instance' : widget.level.name} · ${_description(widget.selected!)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(switch (widget.level) {
                  FindLevel.study => 'Scope: all instances in this study',
                  FindLevel.series => 'Scope: all instances in this series',
                  FindLevel.image => 'Scope: this instance only',
                }),
                if (selectedIndex ~/ 50 != widget.page)
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Selected target is on page ${selectedIndex ~/ 50 + 1}',
                      ),
                      TextButton(
                        onPressed: () => _page(selectedIndex ~/ 50),
                        child: const Text('Show selected'),
                      ),
                    ],
                  ),
              ],
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (selectedIndex >= 0)
                    TextButton(
                      onPressed: widget.onClear,
                      child: const Text('Clear selection'),
                    ),
                  FilledButton.tonal(
                    focusNode: widget.retrieveFocus,
                    onPressed: widget.onRetrieve,
                    child: const Text('Review retrieve'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stacked(BuildContext context, QueryMatch row) {
    final cells = _cells(context, row);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 48, child: cells[0]),
              const SizedBox(width: 8),
              Expanded(child: cells[1]),
            ],
          ),
          for (final cell in cells.skip(2))
            Padding(padding: const EdgeInsets.only(top: 8), child: cell),
        ],
      ),
    );
  }

  Widget _pad(Widget child) =>
      Padding(padding: const EdgeInsets.all(12), child: child);

  Widget _warning(String text) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: _pad(Text(text)),
    ),
  );

  String _value(QueryMatch row, int tag, {bool sensitive = false}) =>
      queryValue(row, tag, widget.reveal, sensitive: sensitive);
  String _description(QueryMatch row) =>
      'Result ${row.ordinal} · ${_value(row, switch (widget.level) {
        FindLevel.study => 0x00081030,
        FindLevel.series => 0x0008103E,
        FindLevel.image => 0x00200013,
      }, sensitive: widget.level != FindLevel.image)}';

  Widget _info(
    BuildContext context,
    List<(String, String)> values, {
    bool primary = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final (label, value) in values)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            '$label: $value',
            style: primary && label == values.first.$1
                ? Theme.of(context).textTheme.titleSmall
                : Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
    ],
  );

  List<Widget> _cells(BuildContext context, QueryMatch row) {
    final problem = widget.actionProblem(row);
    return [
      SizedBox(
        key: _key(row, 'select'),
        child: Semantics(
          label: 'Select result ${row.ordinal}',
          child: Radio<QueryMatch>(value: row, enabled: problem == null),
        ),
      ),
      _info(context, [
        (
          widget.level == FindLevel.image
              ? 'Instance number'
              : widget.level == FindLevel.study
              ? 'Study'
              : 'Series',
          _description(row),
        ),
        if (widget.level == FindLevel.study) ...[
          ('Patient', _value(row, 0x00100010, sensitive: true)),
          ('ID', _value(row, 0x00100020, sensitive: true)),
        ],
      ], primary: true),
      _info(context, switch (widget.level) {
        FindLevel.study => [
          ('Study date', _date(row)),
          ('Modalities', _value(row, 0x00080061)),
        ],
        FindLevel.series => [
          ('Modality', _value(row, 0x00080060)),
          ('Body part', _value(row, 0x00180015)),
        ],
        FindLevel.image => [
          ('SOP Instance UID', _value(row, 0x00080018, sensitive: true)),
        ],
      }),
      if (widget.level != FindLevel.image)
        _info(
          context,
          widget.level == FindLevel.study
              ? [
                  ('Accession', _value(row, 0x00080050, sensitive: true)),
                  ('Returned series', _value(row, 0x00201206)),
                ]
              : [('Returned instances', _value(row, 0x00201209))],
        ),
      Column(
        key: _key(row, 'actions'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
            onPressed: () => widget.onInspect(row),
            child: const Text('Inspect'),
          ),
          if (widget.level != FindLevel.image)
            TextButton(
              onPressed: problem == null ? () => widget.onOpenChild(row) : null,
              child: Text(
                widget.level == FindLevel.study
                    ? 'Open series'
                    : 'Open instances',
              ),
            ),
          if (problem != null) Text(problem),
        ],
      ),
    ];
  }

  String _date(QueryMatch row) {
    final value = _value(row, 0x00080020);
    if (!RegExp(r'^\d{8}$').hasMatch(value)) return value;
    final year = int.parse(value.substring(0, 4)),
        month = int.parse(value.substring(4, 6)),
        day = int.parse(value.substring(6));
    final date = DateTime.utc(year, month, day);
    if (year < 1 ||
        date.year != year ||
        date.month != month ||
        date.day != day) {
      return value;
    }
    return '${value.substring(0, 4)}-${value.substring(4, 6)}-${value.substring(6)}';
  }
}
