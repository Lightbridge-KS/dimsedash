import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bindings/configuration.dart';
import '../../bindings/echo.dart';
import '../../ui/workbench_header.dart';
import 'echo_evidence.dart';

class EchoView extends ConsumerStatefulWidget {
  const EchoView({
    super.key,
    required this.nodeId,
    required this.onBack,
    this.workspaceHeader,
  });
  final String nodeId;
  final VoidCallback onBack;
  final Widget? workspaceHeader;
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
    final validTarget = node != null && node.id == widget.nodeId;
    final ownsEvidence =
        state.summary != null && state.request?.node.id == widget.nodeId;
    return EchoEvidence(
      state: ownsEvidence ? state : null,
      emptyMessage: 'No retained Echo evidence for this node',
      header: [
        widget.workspaceHeader ??
            WorkbenchHeader(
              config: config,
              nodeId: widget.nodeId,
              onBack: widget.onBack,
            ),
        if (ownsEvidence && _settingsDiffer(config, state))
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Current settings apply to the next run. Evidence retains the frozen run settings.',
            ),
          ),
        const SizedBox(height: 12),
        Text(
          'Echo · Verification',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed:
                  !validTarget || runner == null || state.active || _starting
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
            if (ownsEvidence)
              OutlinedButton(
                onPressed: state.active
                    ? () => _stopRun(ref, state.summary!.id)
                    : null,
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
        const SizedBox(height: 12),
      ],
    );
  }

  bool _settingsDiffer(AppConfiguration config, EchoState state) {
    final request = state.request!;
    return config.node?.revision != request.node.revision ||
        config.client.callingAe != request.client.callingAe ||
        config.client.timeouts.values.entries.any(
          (e) => request.client.timeouts.values[e.key] != e.value,
        );
  }
}

/// Inspects one retained run without selecting its node or permitting a retry.
class EchoRunView extends ConsumerWidget {
  const EchoRunView({super.key, required this.runId, required this.onBack});
  final String runId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(echoStateProvider);
    final state = latest.summary?.id == runId ? latest : null;
    return EchoEvidence(
      state: state,
      emptyMessage: 'This run detail is no longer retained.',
      header: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),
        ),
        Text(
          state == null
              ? 'Echo run'
              : 'Echo run · ${state.request?.node.label ?? 'Frozen target'}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text('Run $runId'),
        const Text(
          'Frozen run evidence. Viewing this run does not change the next target.',
        ),
        if (state != null && !state.historyAvailable)
          const Text(
            'History unavailable. Live evidence is retained; further starts require storage recovery.',
          ),
        if (state?.active ?? false)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: () => _stopRun(ref, runId),
              child: const Text('Stop Echo'),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// A callback retained through a rebuild must never stop a newer run.
void _stopRun(WidgetRef ref, String runId) {
  final runner = ref.read(operationRunnerProvider);
  if (runner?.state.summary?.id == runId) runner?.stop();
}
