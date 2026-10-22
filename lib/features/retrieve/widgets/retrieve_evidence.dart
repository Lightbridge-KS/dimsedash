import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';

import '../preview/retrieve_preview_model.dart';
import 'retrieve_display.dart';
import 'retrieve_receipt_dialog.dart';

/// Shows one resolved, frozen sample with separate peer and local evidence.
class RetrieveEvidence extends StatelessWidget {
  const RetrieveEvidence({
    super.key,
    required this.sample,
    required this.config,
    required this.active,
    required this.reveal,
    required this.expanded,
    required this.onTransition,
    required this.onReview,
  });
  final RetrieveSample sample;
  final AppConfiguration config;
  final bool active, reveal;
  final Map<String, bool> expanded;
  final ValueChanged<RetrieveScenario> onTransition;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final r = sample.request;
    String count(int? n) => n?.toString() ?? 'Not reported';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        retrievePanel(context, 'Frozen sample request', [
          Text('${r.draft.method.label} · ${r.draft.seed.scopeLabel}'),
          Text(
            r.draft.edited
                ? 'Edited identifier · remote match unverified'
                : retrieveValue(r.draft.seed.description, reveal),
          ),
          Text(
            'Frozen node ${r.node.label} · ${r.node.calledAe} · ${r.node.host}:${r.node.port}',
          ),
          Text(
            'Node revision ${r.node.revision} · Calling AE ${r.client.callingAe}',
          ),
          Text(
            'Timeouts · connect ${r.client.timeouts.connect}s · association ${r.client.timeouts.association}s · DIMSE ${r.client.timeouts.dimse}s · idle ${r.client.timeouts.idle}s',
          ),
          Text('Sample destination · ${r.draft.folder}'),
          if (r.draft.method == RetrieveMethod.move)
            Text(
              'Move Destination ${r.client.callingAe} · port ${r.client.listenPort}',
            ),
          if (r.differs(config))
            retrieveNotice(
              context,
              'Current connection settings differ from this frozen sample.',
            ),
          retrieveDisclosure(
            expanded,
            'executed',
            'Executed Identifier · synthetic',
            [Text(retrieveValue(r.draft.identifier, reveal))],
          ),
        ]),
        retrievePanel(context, 'Sample outcome', [
          Text(sample.status),
          const Text(
            'All counts, statuses and observations below are synthetic.',
          ),
          if (sample.transitional) ...[
            const Text(
              'This is a static snapshot. Navigation does not advance it or own any operation.',
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed:
                      active ||
                          sample.scenario == RetrieveScenario.cancelRequested
                      ? null
                      : () => onTransition(RetrieveScenario.cancelRequested),
                  child: const Text('Preview cancel request'),
                ),
                OutlinedButton(
                  onPressed: active
                      ? null
                      : () => onTransition(RetrieveScenario.complete),
                  child: const Text('Show completion snapshot'),
                ),
              ],
            ),
          ],
          if (active)
            retrieveNotice(
              context,
              'Echo is active. Sample transitions wait for cleanup; browsing remains available.',
            ),
        ]),
        retrievePanel(context, 'Peer reported · synthetic', [
          Text(
            'Completed ${count(sample.completed)} · Failed ${count(sample.failed)} · Warning ${count(sample.warning)} · Remaining ${count(sample.remaining)}',
          ),
          const Text(
            'Missing counts are not zero. Query counts are not a transfer denominator.',
          ),
        ]),
        retrievePanel(context, 'Local receipts / save results · synthetic', [
          Text(
            'Received ${sample.received} · Saved ${sample.saved} · Save failed ${sample.saveFailed}',
          ),
          const Text(
            'Saved does not prove successful acknowledgement or unique SOP count.',
          ),
          if (sample.noReceipts)
            const Text(
              'No linked receipts in this sample. No cause is established.',
            ),
          for (final receipt in sample.receipts)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sample delivery ${receipt.id} · ${receipt.saved ? 'Saved (synthetic)' : 'Save failed (synthetic)'}',
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => showRetrieveReceiptDialog(
                          context,
                          receipt,
                          thumbnail: false,
                        ),
                        child: Text('Inspect headers ${receipt.id}'),
                      ),
                      TextButton(
                        onPressed: () => showRetrieveReceiptDialog(
                          context,
                          receipt,
                          thumbnail: true,
                        ),
                        child: Text('Thumbnail ${receipt.id}'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ]),
        if (r.draft.method == RetrieveMethod.move)
          retrievePanel(context, 'Receiver-wide activity · synthetic', [
            const Text(
              'Unlinked deliveries: Not observed in this fixture. Excluded from run-linked totals.',
            ),
            const Text(
              'No callback does not establish a firewall failure. Suggested checks: destination registration and callback path.',
            ),
          ]),
        TextButton(
          onPressed: onReview,
          child: const Text('Review new retrieve'),
        ),
      ],
    );
  }
}
