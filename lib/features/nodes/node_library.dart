import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bindings/configuration.dart';
import '../../ui/node_fields.dart';
import 'node_editor.dart';

class NodeLibrary extends ConsumerStatefulWidget {
  const NodeLibrary({super.key, required this.onOpen, this.restoreFocus = 0});
  final Future<bool> Function(PacsNode) onOpen;
  final int restoreFocus;

  @override
  ConsumerState<NodeLibrary> createState() => _NodeLibraryState();
}

class _NodeLibraryState extends ConsumerState<NodeLibrary> {
  final _cardFocus = <String, FocusNode>{};
  final _headingFocus = FocusNode(debugLabel: 'Nodes heading');
  String? _openedNode;

  @override
  void didUpdateWidget(covariant NodeLibrary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.restoreFocus != widget.restoreFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final visible = ref
            .read(configurationProvider)
            .searchNodes(_search.text)
            .any(
              (node) =>
                  node.id == _openedNode &&
                  (_environment == null || node.environment == _environment),
            );
        final card = visible ? _cardFocus[_openedNode] : null;
        if (card?.context != null) {
          card!.requestFocus();
        } else {
          // Reveal the fallback before focusing it: lazy-list focus attachment
          // can lag behind the frame that restores the library.
          if (_scroll.hasClients) _scroll.jumpTo(0);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _headingFocus.requestFocus();
          });
          WidgetsBinding.instance.scheduleFrame();
        }
      });
    }
  }

  final _search = TextEditingController();
  final _scroll = ScrollController();
  NodeEnvironment? _environment;
  bool _list = false, _busy = false;
  String? _error;

  @override
  void dispose() {
    _headingFocus.dispose();
    for (final focus in _cardFocus.values) {
      focus.dispose();
    }
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configurationProvider);
    final removedIds = _cardFocus.keys
        .where((id) => !config.nodes.any((node) => node.id == id))
        .toList();
    for (final id in removedIds) {
      final obsolete = _cardFocus.remove(id)!;
      WidgetsBinding.instance.addPostFrameCallback((_) => obsolete.dispose());
    }
    final nodes = config
        .searchNodes(_search.text)
        .where((n) => _environment == null || n.environment == _environment)
        .toList();
    return ListView(
      key: const PageStorageKey('node-library'),
      controller: _scroll,
      padding: const EdgeInsets.all(24),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Focus(
                  focusNode: _headingFocus,
                  child: Text(
                    'DICOM nodes',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 6),
                const Text('Choose a destination and open its workbench.'),
              ],
            ),
            FilledButton.icon(
              onPressed: _busy ? null : () => _edit(null),
              icon: const Icon(Icons.add),
              label: const Text('Add node'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: constraints.maxWidth.clamp(0, 380),
                child: TextField(
                  key: const ValueKey('node-search'),
                  controller: _search,
                  decoration: const InputDecoration(
                    labelText: 'Search nodes',
                    hintText: 'Label, host or called AE',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                width: constraints.maxWidth.clamp(0, 300),
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  key: ValueKey('environment-${_environment?.name ?? 'all'}'),
                  initialValue: _environment?.name ?? 'all',
                  decoration: const InputDecoration(labelText: 'Environment'),
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('All environments'),
                    ),
                    DropdownMenuItem(value: 'test', child: Text('Test')),
                    DropdownMenuItem(
                      value: 'production',
                      child: Text('Production'),
                    ),
                  ],
                  onChanged: (v) => setState(
                    () => _environment = switch (v) {
                      'test' => NodeEnvironment.test,
                      'production' => NodeEnvironment.production,
                      _ => null,
                    },
                  ),
                ),
              ),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.grid_view),
                    label: Text('Cards'),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.view_list),
                    label: Text('List'),
                  ),
                ],
                selected: {_list},
                onSelectionChanged: (v) => setState(() => _list = v.single),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('${nodes.length} of ${config.nodes.length} nodes · Name A–Z'),
        if (_error != null) Semantics(liveRegion: true, child: Text(_error!)),
        const SizedBox(height: 12),
        if (nodes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                const Icon(Icons.dns_outlined, size: 40),
                const SizedBox(height: 12),
                Text(
                  config.nodes.isEmpty
                      ? 'Add your first DICOM node'
                      : 'No matching nodes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  config.nodes.isEmpty
                      ? 'Save a PACS endpoint and called AE to get started.'
                      : 'Try another label, host, called AE or environment.',
                ),
                if (config.nodes.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() {
                      _search.clear();
                      _environment = null;
                    }),
                    child: const Text('Clear filters'),
                  ),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = _list
                  ? 1
                  : ((constraints.maxWidth + 16) / 280).floor().clamp(1, 6);
              final width =
                  (constraints.maxWidth - (columns - 1) * 16) / columns;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final node in nodes)
                    SizedBox(
                      width: width,
                      child: _NodeCard(
                        focusNode: _cardFocus.putIfAbsent(
                          node.id,
                          () => FocusNode(debugLabel: 'Node ${node.id}'),
                        ),
                        node: node,
                        selected: node.id == config.selectedNodeId,
                        compact: _list,
                        enabled: !_busy,
                        onOpen: () => _open(node),
                        onAction: (action) => _action(action, node),
                      ),
                    ),
                ],
              );
            },
          ),
        const SizedBox(height: 20),
        const Text(
          'Selecting or saving a node sends no traffic. Run Echo explicitly in Workbench.',
        ),
      ],
    );
  }

  Future<void> _open(PacsNode node) async {
    _openedNode = node.id;
    setState(() => _busy = true);
    try {
      await widget.onOpen(node);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _action(_NodeAction action, PacsNode node) async {
    switch (action) {
      case _NodeAction.open:
        await _open(node);
      case _NodeAction.edit:
        await _edit(node);
      case _NodeAction.duplicate:
        await _edit(duplicateNode(node), duplicate: true);
      case _NodeAction.remove:
        await _remove(node);
    }
  }

  Future<void> _edit(PacsNode? node, {bool duplicate = false}) async {
    final result = await showDialog<NodeEditorSaved>(
      context: context,
      barrierDismissible: false,
      builder: (_) => NodeEditor(
        mode: node == null || duplicate
            ? NodeEditorMode.add
            : NodeEditorMode.edit,
        draft:
            node ??
            const PacsNode(
              id: '',
              label: '',
              calledAe: '',
              host: '',
              port: 104,
            ),
      ),
    );
    if (!mounted || result == null || result.mode != NodeEditorMode.add) return;
    final saved = ref
        .read(configurationProvider)
        .nodes
        .where((n) => n.id == result.nodeId)
        .firstOrNull;
    if (saved != null) await _open(saved);
  }

  Future<void> _remove(PacsNode node) async {
    final base = ref.read(configurationProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${node.label}?'),
        content: Text(
          'Remove this saved configuration. ${base.selectedNodeId == node.id ? 'Selection will be cleared. ' : ''}Run history and active Echo evidence are retained.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep node'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove node'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final failure = await ref
          .read(configurationProvider.notifier)
          .changeNode(RemoveNode(base.revision, node.id));
      if (mounted) setState(() => _error = failure?.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

enum _NodeAction { open, edit, duplicate, remove }

class _NodeCard extends StatelessWidget {
  const _NodeCard({
    required this.node,
    required this.focusNode,
    required this.selected,
    required this.compact,
    required this.enabled,
    required this.onOpen,
    required this.onAction,
  });
  final PacsNode node;
  final FocusNode focusNode;
  final bool selected, compact, enabled;
  final VoidCallback onOpen;
  final ValueChanged<_NodeAction> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = <Widget>[
      Semantics(
        label: 'Open ${node.label} in Workbench',
        button: true,
        selected: selected,
        child: InkWell(
          key: ValueKey('open-node-${node.id}'),
          focusNode: focusNode,
          onTap: enabled ? onOpen : null,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!compact) ...[
                  Icon(
                    Icons.dns_outlined,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(height: 14),
                ],
                Text(node.label, style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                Text('Called AE · ${node.calledAe}'),
                const SizedBox(height: 4),
                Text('Endpoint · ${node.host}:${node.port}'),
              ],
            ),
          ),
        ),
      ),
      const Divider(height: 1),
      Padding(
        padding: const EdgeInsets.only(left: 16, right: 4),
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  NodeEnvironmentBadge(node.environment),
                  if (selected) const Text('Selected'),
                ],
              ),
            ),
            PopupMenuButton<_NodeAction>(
              key: ValueKey('node-menu-${node.id}'),
              tooltip: 'Actions for ${node.label}',
              icon: Icon(
                Icons.more_horiz,
                semanticLabel: 'Actions for ${node.label}',
              ),
              enabled: enabled,
              onSelected: onAction,
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _NodeAction.open,
                  child: Text('Open Workbench'),
                ),
                PopupMenuItem(
                  value: _NodeAction.edit,
                  child: Text('Edit node'),
                ),
                PopupMenuItem(
                  value: _NodeAction.duplicate,
                  child: Text('Duplicate'),
                ),
                PopupMenuItem(
                  value: _NodeAction.remove,
                  child: Text('Remove node'),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (compact && constraints.maxWidth >= 600) {
            return Row(
              children: [
                Expanded(child: content[0]),
                SizedBox(width: 240, child: content[2]),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: content,
          );
        },
      ),
    );
  }
}
