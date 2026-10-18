import 'package:dimsedash_core/dimsedash_core.dart';
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
    final (icon, title, description) = switch (_page) {
      0 => (
        Icons.hub_outlined,
        config.node == null
            ? 'Configure your first connection'
            : 'Connection configured',
        'Settings are ready. Echo and query workflows will be available in a later preview.',
      ),
      1 => (
        Icons.folder_outlined,
        'No received files',
        'This workflow will be available in a later preview.',
      ),
      _ => (
        Icons.history,
        'No run history',
        'This workflow will be available in a later preview.',
      ),
    };
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
          _WorkbenchSidebar(
            configuration: config,
            selectedPage: _page,
            onPageSelected: (page) => setState(() => _page = page),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _page == 3
                ? const SettingsView()
                : _WorkflowPlaceholder(
                    icon: icon,
                    title: title,
                    description: description,
                    onOpenSettings: () => setState(() => _page = 3),
                  ),
          ),
        ],
      ),
    );
  }
}

class _WorkbenchSidebar extends StatelessWidget {
  const _WorkbenchSidebar({
    required this.configuration,
    required this.selectedPage,
    required this.onPageSelected,
  });

  final AppConfiguration configuration;
  final int selectedPage;
  final ValueChanged<int> onPageSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 220,
      child: Material(
        color: colors.surfaceContainerLow,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                        if (configuration.node case final node?)
                          Card(
                            color: colors.primaryContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                            selected: selectedPage == index,
                            onTap: () => onPageSelected(index),
                          ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Divider(),
                        const Text('LOCAL RECEIVER'),
                        Text(configuration.client.callingAe),
                        Text('Port ${configuration.client.listenPort}'),
                        const SizedBox(height: 8),
                        const Chip(
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          avatar: Icon(Icons.stop_circle_outlined, size: 18),
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
    );
  }
}

class _WorkflowPlaceholder extends StatelessWidget {
  const _WorkflowPlaceholder({
    required this.icon,
    required this.title,
    required this.description,
    required this.onOpenSettings,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(description),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onOpenSettings,
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
