import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bindings/configuration.dart';
import '../../bindings/echo.dart';

class EchoView extends ConsumerStatefulWidget {
  const EchoView({super.key});
  @override
  ConsumerState<EchoView> createState() => _EchoViewState();
}

class _EchoViewState extends ConsumerState<EchoView> {
  String? _error;
  bool _starting = false;
  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configurationProvider);
    final runner = ref.watch(operationRunnerProvider);
    final state = ref.watch(echoStateProvider);
    final node = config.node;
    return DefaultTabController(
      length: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Echo · Verification',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              node == null
                  ? 'Configure your first connection in Settings or add a node.'
                  : '${node.label} · ${node.host}:${node.port} · Called ${node.calledAe}\nCalling ${config.client.callingAe} · ${node.environment.name} environment',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                FilledButton.icon(
                  onPressed:
                      node == null ||
                          runner == null ||
                          state.active ||
                          _starting
                      ? null
                      : () async {
                          setState(() {
                            _starting = true;
                            _error = null;
                          });
                          final result = await runner.start(config.revision);
                          if (!mounted) return;
                          setState(() {
                            _starting = false;
                            if (result case Failure<RunHandle>(:final error)) {
                              _error = error.message;
                            }
                          });
                        },
                  icon: const Icon(Icons.play_arrow),
                  label: Text(state.active ? 'Echo running' : 'Run Echo'),
                ),
                OutlinedButton(
                  onPressed: state.active ? runner?.stop : null,
                  child: const Text('Stop Echo'),
                ),
              ],
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (!state.historyAvailable)
              const Text(
                'History unavailable. Live evidence is retained; further starts require storage recovery.',
              ),
            const SizedBox(height: 12),
            const Text(
              'Echo success proves only the verification exchange. It does not prove query, retrieval or storage support.',
            ),
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Summary'),
                Tab(text: 'Timeline'),
                Tab(text: 'Negotiation'),
                Tab(text: 'Trace'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _summary(state),
                  _lines(
                    state.events.map(
                      (e) =>
                          '${(e.elapsedMicros / 1000).toStringAsFixed(1)} ms · ${e.direction.name} · ${e.kind.name}${_codes(e)}',
                    ),
                  ),
                  _negotiation(state),
                  _lines([
                    'Typed observations only; no raw payloads or peer comments.',
                    for (final e in state.events)
                      '#${e.sequence} +${e.elapsedMicros}µs ${e.direction.name} ${e.kind.name}${_codes(e)}',
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(EchoState state) {
    final s = state.summary;
    final request = state.request;
    final observed = state.events.any(
      (e) => e.kind == EvidenceKind.transportClosed,
    );
    return _lines(
      s == null
          ? ['No Echo has run. Saving settings sends no traffic.']
          : [
              'Run ${s.id}',
              'Outcome: ${state.active ? 'running' : s.outcome?.disposition.name ?? 'unknown'}',
              'Echo status: ${s.outcome?.status == null ? 'unobserved' : _hex(s.outcome!.status!)}',
              'Failure: ${s.outcome?.failure?.name ?? 'none observed'}',
              'Cleanup failure: ${s.outcome?.cleanupFailed ?? false}',
              'Stop requested: ${state.stopRequested} · no C-CANCEL service exists for Echo',
              'Transport termination: ${observed ? 'observed' : 'unobserved'}',
              'Frozen target: ${request?.node.host}:${request?.node.port} · ${request?.node.calledAe}',
              'Frozen calling AE: ${request?.client.callingAe} · node revision ${s.nodeRevision}',
              'Started: ${s.started.toIso8601String()}',
              'Elapsed: ${s.ended == null ? 'running' : '${(s.elapsedMicros ?? 0) / 1000} ms'}',
              'Timeouts: ${s.timeouts.values}',
              'Provenance: live protocol observations; connection timing includes name resolution.',
              'Live detail omitted: ${state.omitted}; events dropped before persistence: ${state.historyDropped}. Missing facts are not inferred.',
              'Suggested checks: verify address, port, AE registration and firewall when an exchange fails. These are suggestions, not observed causes.',
            ],
    );
  }

  Widget _negotiation(EchoState state) {
    final negotiation = state.events
        .where((e) => e.kind == EvidenceKind.associateAccept)
        .lastOrNull;
    final proposal = state.events
        .where((e) => e.kind == EvidenceKind.associateRequest)
        .lastOrNull;
    return _lines([
      'Peer maximum PDU: ${negotiation?.peerMaxPduLength ?? 'unobserved'}',
      'Peer implementation class: ${negotiation?.peerImplementationClassUid ?? 'unobserved'}',
      'Async invoked / performed: ${negotiation?.maxInvoked ?? 'unobserved'} / ${negotiation?.maxPerformed ?? 'unobserved'}',
      'Implementation version text and unknown user-information bytes are deliberately omitted.',
      for (final c
          in (negotiation ?? proposal)?.contexts ?? <NegotiatedContext>[])
        'Context ${c.id} · ${c.abstractSyntax}\nProposed: ${c.proposed.join(', ')}\nResult: ${c.result ?? 'unobserved'} · selected syntax: ${c.selected ?? 'unobserved'}',
      if (negotiation == null) 'No accepted association observed.',
    ]);
  }

  Widget _lines(Iterable<String> lines) => ListView(
    padding: const EdgeInsets.symmetric(vertical: 16),
    children: [
      for (final line in lines)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SelectableText(line),
        ),
    ],
  );
  String _codes(EchoObservation e) => [
    if (e.timeoutPhase != null) 'timer=${e.timeoutPhase!.name}',
    if (e.command != null) 'command=${_hex(e.command!)}',
    if (e.status != null) 'status=${_hex(e.status!)}',
    if (e.result != null) 'result=${e.result}',
    if (e.source != null) 'source=${e.source}',
    if (e.reason != null) 'reason=${e.reason}',
  ].map((v) => ' $v').join();
  String _hex(int code) =>
      '0x${code.toRadixString(16).padLeft(4, '0').toUpperCase()}';
}
