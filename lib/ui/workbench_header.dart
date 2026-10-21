import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';

import 'node_fields.dart';

enum WorkbenchOperation { echo, query }

class WorkbenchHeader extends StatelessWidget {
  const WorkbenchHeader({
    super.key,
    required this.config,
    required this.nodeId,
    required this.onBack,
    this.operation,
    this.onOperationChanged,
  });
  final AppConfiguration config;
  final String nodeId;
  final VoidCallback onBack;
  final WorkbenchOperation? operation;
  final ValueChanged<WorkbenchOperation>? onOperationChanged;
  @override
  Widget build(BuildContext context) {
    final node = config.node?.id == nodeId ? config.node : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('All nodes'),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              node?.label ?? 'Node unavailable',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (node != null) NodeEnvironmentBadge(node.environment),
          ],
        ),
        if (node != null) Text('${node.calledAe} · ${node.host}:${node.port}'),
        Text('Calling AE · ${config.client.callingAe}'),
        ExpansionTile(
          key: PageStorageKey('connection-details-$nodeId'),
          tilePadding: EdgeInsets.zero,
          title: const Text('Connection details'),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Timeouts · connect ${config.client.timeouts.connect}s · association ${config.client.timeouts.association}s · DIMSE ${config.client.timeouts.dimse}s · idle ${config.client.timeouts.idle}s',
              ),
            ),
          ],
        ),
        if (operation != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<WorkbenchOperation>(
                segments: const [
                  ButtonSegment(
                    value: WorkbenchOperation.echo,
                    label: Text('Echo'),
                  ),
                  ButtonSegment(
                    value: WorkbenchOperation.query,
                    label: Text('Query'),
                  ),
                ],
                selected: {operation!},
                onSelectionChanged: (value) =>
                    onOperationChanged?.call(value.single),
              ),
            ),
          ),
      ],
    );
  }
}
