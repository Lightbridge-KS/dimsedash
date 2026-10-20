import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bindings/configuration.dart';
import '../../ui/node_fields.dart';

enum NodeEditorMode { add, edit }

/// Returned only after durable success; dismissing a dialog returns null.
final class NodeEditorSaved {
  const NodeEditorSaved(this.mode, this.nodeId);
  final NodeEditorMode mode;
  final String nodeId;
}

class NodeEditor extends ConsumerStatefulWidget {
  const NodeEditor({super.key, required this.mode, required this.draft});
  final NodeEditorMode mode;
  final PacsNode draft;

  @override
  ConsumerState<NodeEditor> createState() => _NodeEditorState();
}

class _NodeEditorState extends ConsumerState<NodeEditor> {
  final _controllers = <String, TextEditingController>{
    for (final key in ['label', 'calledAe', 'host', 'pacsPort'])
      key: TextEditingController(),
  };
  late AppConfiguration _base;
  late PacsNode _node;
  late NodeEnvironment _environment;
  Map<String, String> _errors = {};
  AppFailure? _failure;
  bool _saving = false;
  bool _missing = false;

  @override
  void initState() {
    super.initState();
    _restore(widget.draft);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Actions(
      actions: {
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (_) {
            if (!_saving) Navigator.pop(context);
            return null;
          },
        ),
      },
      child: Focus(
        autofocus: true,
        skipTraversal: true,
        child: Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.mode == NodeEditorMode.edit
                        ? 'Edit node'
                        : 'New node draft',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Saving changes configuration only. No network traffic is sent.',
                  ),
                  const SizedBox(height: 24),
                  NodeFields(
                    controllers: _controllers,
                    environment: _environment,
                    onEnvironmentChanged: (value) =>
                        setState(() => _environment = value),
                    errors: _errors,
                    enabled: !_saving && !_missing,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Client calling AE: ${_base.client.callingAe} · managed in Settings.',
                  ),
                  if (_failure case final failure?) ...[
                    const SizedBox(height: 16),
                    Semantics(liveRegion: true, child: Text(failure.message)),
                    TextButton(
                      onPressed: _saving ? null : _reload,
                      child: const Text('Reload saved values'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: _saving || _missing ? null : _save,
                        child: Text(
                          _saving
                              ? 'Saving…'
                              : widget.mode == NodeEditorMode.edit
                              ? 'Save changes'
                              : 'Save & open Workbench',
                        ),
                      ),
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Discard'),
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

  void _restore(PacsNode node) {
    _base = ref.read(configurationProvider);
    _node = node;
    _environment = node.environment;
    for (final entry in {
      'label': node.label,
      'calledAe': node.calledAe,
      'host': node.host,
      'pacsPort': '${node.port}',
    }.entries) {
      _controllers[entry.key]!.text = entry.value;
    }
    _failure = null;
    _errors = {};
    _missing = false;
  }

  Future<void> _reload() async {
    setState(() => _saving = true);
    final failure = await ref.read(configurationProvider.notifier).reload();
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (failure != null) {
        _failure = failure;
        return;
      }
      final saved = ref
          .read(configurationProvider)
          .nodes
          .where((n) => n.id == _node.id)
          .firstOrNull;
      if (widget.mode == NodeEditorMode.edit && saved == null) {
        _missing = true;
        _failure = const AppFailure(
          FailureKind.conflict,
          'This node was removed. Discard this editor.',
        );
      } else {
        _restore(widget.mode == NodeEditorMode.edit ? saved! : widget.draft);
      }
    });
  }

  Future<void> _save() async {
    if (_saving || _missing) return;
    String value(String key) => _controllers[key]!.text.trim();
    final node = PacsNode(
      id: _node.id,
      revision: _node.revision,
      label: value('label'),
      calledAe: value('calledAe'),
      host: value('host'),
      port: int.tryParse(value('pacsPort')) ?? 0,
      environment: _environment,
    );
    final errors = validateConfiguration(
      AppConfiguration(client: _base.client, node: node),
    );
    setState(() {
      _errors = errors;
      _failure = null;
    });
    if (errors.isNotEmpty) return;
    setState(() => _saving = true);
    final failure = await ref
        .read(configurationProvider.notifier)
        .changeNode(
          widget.mode == NodeEditorMode.add
              ? AddNode(_base.revision, node)
              : EditNode(_base.revision, node),
        );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _failure = failure;
    });
    if (failure == null) {
      Navigator.pop(
        context,
        NodeEditorSaved(
          widget.mode,
          widget.mode == NodeEditorMode.add
              ? ref.read(configurationProvider).selectedNodeId!
              : node.id,
        ),
      );
    }
  }
}
