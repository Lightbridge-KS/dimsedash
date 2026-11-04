import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bindings/configuration.dart';

/// Live Query handoff: no synthetic execution, listener or file operations.
class RetrieveTargetReview extends ConsumerWidget {
  const RetrieveTargetReview({
    super.key,
    required this.result,
    required this.row,
    required this.header,
  });
  final QueryResultContext result;
  final QueryMatch row;
  final Widget header;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reveal = ref.watch(revealProvider), id = result.request.identifier;
    final stale = result.request.targetChanged(
      ref.watch(configurationProvider),
    );
    String value(String? v) => v == null
        ? 'Not returned'
        : reveal
        ? v
        : '••••';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Text(
            'Retrieve target review',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Text(
            'Retrieval execution is not yet available. No C-GET, C-MOVE, receiver or file operation is performed.',
          ),
          const SizedBox(height: 16),
          Text(switch (id.level) {
            FindLevel.study => 'Scope: all instances in this study',
            FindLevel.series => 'Scope: all instances in this series',
            FindLevel.image => 'Scope: this instance only',
          }),
          if (id.level != FindLevel.image)
            const Text(
              'Parent retrieval includes objects not displayed in Query. A returned series count is not a transfer denominator.',
            ),
          if (stale)
            const Text(
              'Connection identity changed since this selection. Query again before continuing in a future retrieval implementation.',
            ),
          Text(
            'Source query: ${result.runId} · ${result.request.node.label} · revision ${result.request.node.revision}',
          ),
          const SizedBox(height: 16),
          Text('QueryRetrieveLevel: ${id.level.name.toUpperCase()}'),
          SelectableText('StudyInstanceUID: ${value(row.studyUid)}'),
          if (id.level != FindLevel.study)
            SelectableText('SeriesInstanceUID: ${value(row.seriesUid)}'),
          if (id.level == FindLevel.image)
            SelectableText('SOPInstanceUID: ${value(row.sopUid)}'),
          Text(
            'Instance count: ${id.level == FindLevel.image
                ? '1'
                : id.level == FindLevel.series
                ? row.value(0x00201209) ?? 'Not returned'
                : 'Not returned'}',
          ),
          const Text(
            'Find matching predicates are not part of this retrieval target.',
          ),
        ],
      ),
    );
  }
}
