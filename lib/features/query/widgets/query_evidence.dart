import 'package:flutter/material.dart';

import '../preview/query_preview_model.dart';
import 'query_display.dart';

/// Shows executed context rather than the editable next-request draft.
class QueryEvidence extends StatelessWidget {
  const QueryEvidence({super.key, required this.result, required this.reveal});
  final PreviewResultContext result;
  final bool reveal;

  @override
  Widget build(BuildContext context) {
    final request = result.request;
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
        queryIdentifier(context, request.draft.identifier, reveal),
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
}
