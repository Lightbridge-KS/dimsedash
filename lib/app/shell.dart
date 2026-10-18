import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bindings/configuration.dart';
import '../features/settings/settings_view.dart';

class WorkbenchShell extends ConsumerStatefulWidget {
  const WorkbenchShell({super.key});
  @override
  ConsumerState<WorkbenchShell> createState() => _WorkbenchShellState();
}

class _WorkbenchShellState extends ConsumerState<WorkbenchShell> {
  int _page = 0;
  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configurationProvider);
    final reveal = ref.watch(revealProvider);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('DimseDash'),
        actions: [
          TextButton.icon(
            onPressed: () => ref.read(revealProvider.notifier).toggle(),
            icon: Icon(reveal ? Icons.visibility : Icons.visibility_off),
            label: Text(reveal ? 'Mask values' : 'Reveal values'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          SizedBox(
            width: 220,
            child: Material(
              color: colors.surfaceContainerLow,
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'DICOM NODES',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              const SizedBox(height: 12),
                              if (config.node case final node?)
                                Card(
                                  color: colors.primaryContainer,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          node.label,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: colors.onPrimaryContainer,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(node.calledAe),
                                        Text(
                                          '${node.host} : ${node.port}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(node.environment.name),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Text('No saved nodes'),
                                ),
                              const SizedBox(height: 16),
                              for (final (index, label, icon) in [
                                (0, 'Workbench', Icons.dashboard_outlined),
                                (1, 'Received files', Icons.folder_outlined),
                                (2, 'History', Icons.history),
                                (3, 'Settings', Icons.settings_outlined),
                              ])
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  leading: Icon(icon),
                                  title: Text(label),
                                  selected: _page == index,
                                  onTap: () => setState(() => _page = index),
                                ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Divider(),
                              const Text('LOCAL RECEIVER'),
                              Text(config.client.callingAe),
                              Text('Port ${config.client.listenPort}'),
                              const SizedBox(height: 8),
                              const Chip(
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                avatar: Icon(
                                  Icons.stop_circle_outlined,
                                  size: 18,
                                ),
                                label: Text('Stopped'),
                              ),
                              const Text(
                                'Receiver unavailable in this build.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _page == 3
                ? const SettingsView()
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _page == 0
                                ? Icons.hub_outlined
                                : _page == 1
                                ? Icons.folder_outlined
                                : Icons.history,
                            size: 44,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _page == 0
                                ? (config.node == null
                                      ? 'Configure your first connection'
                                      : 'Connection configured')
                                : _page == 1
                                ? 'No received files'
                                : 'No run history',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _page == 0
                                ? 'Settings are ready. Echo and query workflows will be available in a later preview.'
                                : 'This workflow will be available in a later preview.',
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: () => setState(() => _page = 3),
                            child: const Text('Open Settings'),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
