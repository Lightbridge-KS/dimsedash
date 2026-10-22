import 'package:flutter/material.dart';

import '../preview/query_preview_controller.dart';
import '../preview/query_preview_model.dart';
import 'query_display.dart';

/// Browses retained rows, keeping inspection separate from target selection.
class QueryResults extends StatelessWidget {
  const QueryResults({
    super.key,
    required this.controller,
    required this.reveal,
    required this.onRetrieve,
    this.retrieveFocus,
  });
  final QueryPreviewController controller;
  final bool reveal;
  final ValueChanged<QueryRetrieveSelection> onRetrieve;
  final FocusNode? retrieveFocus;
  QueryPreviewController get c => controller;

  @override
  Widget build(BuildContext context) {
    final result = c.result;
    return queryCard([
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
          queryNotice(
            context,
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
                          Text(querySensitive(row.description, reveal)),
                          Text(
                            '${querySensitive(row.patientName, reveal)} · ${querySensitive(row.patientId, reveal)}',
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        '${querySensitive(row.date, reveal)}\n${row.modality}',
                      ),
                    ),
                    DataCell(
                      Text(
                        c.draft.level == QueryLevel.study
                            ? '${querySensitive(row.accession, reveal)}\n${row.seriesCount == null ? 'Series count: Not returned' : '${row.seriesCount} series'}'
                            : c.draft.level == QueryLevel.series
                            ? (row.bodyPart ?? 'Not returned')
                            : querySensitive(row.sopUid, reveal),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => _inspect(context, row),
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
            : '${querySensitive(c.selected!.description, reveal)} · ${c.draft.level == QueryLevel.image ? 'this instance only' : 'all instances in this ${c.draft.level.name}'}',
      ),
      Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton(
          focusNode: retrieveFocus,
          onPressed: c.selected == null || c.result == null
              ? null
              : () => onRetrieve((row: c.selected!, result: c.result!)),
          child: const Text('Review retrieve'),
        ),
      ),
    ]);
  }

  void _inspect(BuildContext context, PreviewMatch row) => showQueryDialog(
    context,
    'Returned metadata · preview',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Inspection does not select a retrieval target.'),
        queryIdentifier(
          context,
          'PatientID = ${row.patientId}\nPatientName = ${row.patientName}\nAccessionNumber = ${row.accession}\nDescription = ${row.description}\nStudyInstanceUID = ${row.studyUid ?? 'Not returned'}\nSeriesInstanceUID = ${row.seriesUid ?? 'Not returned'}\nSOPInstanceUID = ${row.sopUid ?? 'Not returned'}',
          reveal,
        ),
      ],
    ),
  );
}
