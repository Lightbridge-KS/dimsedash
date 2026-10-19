import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bindings/configuration.dart';

class NodeLibrary extends ConsumerStatefulWidget {
  const NodeLibrary({super.key, required this.onDraft, required this.onEdit});
  final ValueChanged<PacsNode> onDraft;
  final VoidCallback onEdit;
  @override
  ConsumerState<NodeLibrary> createState() => _NodeLibraryState();
}

class _NodeLibraryState extends ConsumerState<NodeLibrary> {
  String _search = '';
  Future<void> _command(NodeCommand command) async {
    final error = await ref
        .read(configurationProvider.notifier)
        .changeNode(command);
    if (mounted && error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configurationProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search nodes',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => _search = v),
        ),
        const SizedBox(height: 8),
        if (config.nodes.isEmpty) const Text('No saved nodes'),
        for (final node in config.searchNodes(_search))
          ListTile(
            contentPadding: EdgeInsets.zero,
            selected: node.id == config.selectedNodeId,
            title: Text(
              node.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${node.calledAe}\n${node.host}:${node.port}\n${node.environment.name}',
            ),
            onTap: () => _command(SelectNode(config.revision, node.id)),
          ),
        OutlinedButton.icon(
          onPressed: () => widget.onDraft(
            const PacsNode(
              id: '',
              label: '',
              calledAe: '',
              host: '',
              port: 104,
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Add node'),
        ),
        if (config.node case final node?)
          Wrap(
            children: [
              TextButton(onPressed: widget.onEdit, child: const Text('Edit')),
              TextButton(
                onPressed: () => widget.onDraft(duplicateNode(node)),
                child: const Text('Duplicate'),
              ),
              TextButton(
                onPressed: () async {
                  final remove = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Remove selected node?'),
                      content: const Text(
                        'Selection will be cleared. Run history and active Echo evidence are retained.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Keep node'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  );
                  if (remove == true) {
                    await _command(RemoveNode(config.revision, node.id));
                  }
                },
                child: const Text('Remove'),
              ),
            ],
          ),
      ],
    );
  }
}
