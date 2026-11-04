import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bindings/configuration.dart';
import '../../bindings/echo.dart';
import 'find_composer.dart';
import 'find_inspection.dart';

String findResultLabel(QueryResultContext result) {
  final o = result.outcome;
  if (result.active) {
    return result.limitReached
        ? 'Limit reached · cancelling / cleaning up'
        : 'Query running';
  }
  if (o == null) return 'Outcome unobserved';
  if (o.failure == FindFailure.identifierTooLarge) {
    return 'Identifier size limit exceeded · results incomplete';
  }
  if (o.failure == FindFailure.timeout) return 'Timeout · results incomplete';
  if (o.failure == FindFailure.peerAbort) {
    return 'Peer abort · results incomplete';
  }
  return switch (o.disposition) {
    FindDisposition.complete =>
      result.rows.isEmpty ? 'Complete · no matches' : 'Complete',
    FindDisposition.limited => 'Limited · results incomplete',
    FindDisposition.cancelled => 'Cancelled · results incomplete',
    FindDisposition.stopped => 'Stopped · peer cancellation not confirmed',
    FindDisposition.failed =>
      result.rows.isEmpty ? 'Failed' : 'Failed after results · incomplete',
  };
}

class FindEvidence extends StatelessWidget {
  const FindEvidence({
    super.key,
    required this.result,
    required this.reveal,
    this.state,
  });
  final QueryResultContext result;
  final bool reveal;
  final EchoState? state;
  @override
  Widget build(BuildContext context) {
    final o = result.outcome;
    final s = state?.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          findResultLabel(result),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          'Run ${result.runId} · live C-FIND · Study Root ${result.request.identifier.level.name.toUpperCase()}',
        ),
        Text(
          'Received ${result.received} · retained ${result.rows.length} · accounted bytes ${result.accountedBytes}',
        ),
        Text(
          'Peer final status: ${o?.status == null ? 'unobserved' : '0x${o!.status!.toRadixString(16).padLeft(4, '0').toUpperCase()}'} · failure: ${o?.failure?.name ?? 'none observed'}',
        ),
        Text(
          'Cancel requested: ${o?.cancelRequested ?? state?.stopRequested ?? false} · peer confirmed: ${o?.cancellationConfirmed ?? false}',
        ),
        if (o?.optionalKeysUnsupported ?? false)
          const Text(
            'Peer warning: one or more optional keys were not supported (0xFF01).',
          ),
        if (o?.cleanupFailed ?? false)
          const Text(
            'Diagnostic warning: association cleanup failed. The observed peer outcome above is preserved.',
          ),
        Text(
          'Frozen destination: ${result.request.node.label} · ${result.request.node.host}:${result.request.node.port} · ${result.request.node.calledAe}',
        ),
        Text(
          'Frozen calling AE: ${result.request.client.callingAe} · node revision ${result.request.node.revision}',
        ),
        Text(
          'Frozen timeouts: ${result.request.client.timeouts.values} · row limit ${result.request.identifier.rowLimit}',
        ),
        if (s != null)
          Text(
            'Started ${s.started.toIso8601String()} · elapsed ${s.elapsedMicros == null ? 'running' : '${s.elapsedMicros! / 1000} ms'}',
          ),
        ExpansionTile(
          title: const Text('Executed Identifier · frozen'),
          children: [
            IdentifierLines(
              identifier: result.request.identifier,
              reveal: reveal,
            ),
          ],
        ),
        if (state != null) ...[
          if (!state!.historyAvailable)
            const Text(
              'History unavailable. Bounded live evidence is retained. Further starts require storage recovery.',
            ),
          Text(
            'Omitted live events: ${state!.omitted} · events dropped before persistence: ${state!.historyDropped}',
          ),
          ExpansionTile(
            title: const Text('Timeline and negotiation · typed observations'),
            children: [
              for (final e in state!.events)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SelectableText(
                    '${e.elapsedMicros / 1000} ms · ${e.direction.name} ${e.kind.name}${e.status == null ? '' : ' · status 0x${e.status!.toRadixString(16).padLeft(4, '0')}'}${e.result == null ? '' : ' · result ${e.result}'}${e.command == null ? '' : ' · command 0x${e.command!.toRadixString(16)}'}${e.responseTo == null ? '' : ' · response to ${e.responseTo}'}${e.source == null ? '' : ' · source ${e.source}'}${e.reason == null ? '' : ' · reason ${e.reason}'}${e.timeoutPhase == null ? '' : ' · timer ${e.timeoutPhase!.name}'}\n${e.contexts.map((c) => 'Context ${c.id} ${c.abstractSyntax} · proposed ${c.proposed.join(', ')} · result ${c.result ?? 'unobserved'} · selected ${c.selected ?? 'unobserved'}').join('\n')}',
                  ),
                ),
            ],
          ),
        ] else
          const Text(
            'Detailed protocol events are no longer retained for this context. The executed Identifier and outcome remain frozen.',
          ),
      ],
    );
  }
}

class FindRunView extends ConsumerStatefulWidget {
  const FindRunView({super.key, required this.runId, required this.onBack});
  final String runId;
  final VoidCallback onBack;
  @override
  ConsumerState<FindRunView> createState() => _FindRunViewState();
}

class _FindRunViewState extends ConsumerState<FindRunView> {
  int _page = 0;
  @override
  Widget build(BuildContext context) {
    final runId = widget.runId;
    final onBack = widget.onBack;
    final state = ref.watch(echoStateProvider);
    final runner = ref.watch(operationRunnerProvider);
    final result = runner?.findResult(runId);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),
        ),
        Text('Query run', style: Theme.of(context).textTheme.headlineSmall),
        if (result == null)
          const Text('This run detail is no longer retained.')
        else ...[
          if (result.active)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () {
                  if (runner?.state.summary?.id == runId) runner?.stop();
                },
                child: const Text('Cancel query'),
              ),
            ),
          FindEvidence(
            result: result,
            reveal: ref.watch(revealProvider),
            state: state.summary?.id == runId ? state : null,
          ),
          ExpansionTile(
            title: const Text('Retained responses · inspect only'),
            children: [
              for (final row in result.rows.skip(_page * 50).take(50))
                ListTile(
                  title: Text('Response ${row.ordinal}'),
                  trailing: TextButton(
                    onPressed: () => inspectQueryMatch(
                      context,
                      row,
                      ref.read(revealProvider),
                      null,
                    ),
                    child: const Text('Inspect'),
                  ),
                ),
              if (result.rows.length > 50)
                Wrap(
                  children: [
                    TextButton(
                      onPressed: _page > 0
                          ? () => setState(() => _page--)
                          : null,
                      child: const Text('Previous page'),
                    ),
                    Text('Page ${_page + 1}'),
                    TextButton(
                      onPressed: (_page + 1) * 50 < result.rows.length
                          ? () => setState(() => _page++)
                          : null,
                      child: const Text('Next page'),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ],
    );
  }
}
