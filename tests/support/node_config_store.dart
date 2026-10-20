import 'dart:async';

import 'package:dimsedash_core/dimsedash_core.dart';

/// Controllable command boundary for presentation tests. Persistence policy is
/// independently exercised against SQLite in the storage tests.
class NodeConfigStore implements ConfigStore, NodeStore {
  NodeConfigStore(this.value);
  AppConfiguration value;
  final commands = <NodeCommand>[];
  AppFailure? failure;
  Completer<void>? gate;
  int _nextId = 0;

  @override
  Future<Result<AppConfiguration>> load() async => Success(value);
  @override
  Future<Result<AppConfiguration>> save(AppConfiguration draft) async {
    value = draft;
    return Success(value);
  }

  @override
  Future<Result<AppConfiguration>> changeNode(NodeCommand command) async {
    commands.add(command);
    await gate?.future;
    if (failure != null) return Failure(failure!);
    if (command.expectedRevision != value.revision) {
      return const Failure(
        AppFailure(
          FailureKind.conflict,
          'Configuration changed. Reload before editing.',
        ),
      );
    }
    var nodes = value.nodes.toList();
    var selected = value.selectedNodeId;
    switch (command) {
      case AddNode(:final draft):
        final id = 'new-${_nextId++}';
        nodes.add(_copy(draft, id, 1));
        selected = id;
      case EditNode(:final node):
        nodes = [
          for (final n in nodes)
            n.id == node.id ? _copy(node, node.id, n.revision + 1) : n,
        ];
      case SelectNode(:final id):
        selected = id;
      case RemoveNode(:final id):
        nodes.removeWhere((n) => n.id == id);
        if (selected == id) selected = null;
    }
    value = AppConfiguration(
      client: value.client,
      nodes: nodes,
      selectedNodeId: selected,
      revision: value.revision + 1,
    );
    return Success(value);
  }

  PacsNode _copy(PacsNode n, String id, int revision) => PacsNode(
    id: id,
    revision: revision,
    label: n.label,
    calledAe: n.calledAe,
    host: n.host,
    port: n.port,
    environment: n.environment,
  );

  @override
  Future<Result<AppConfiguration>> saveClientSettings(
    ClientSettings settings, {
    required int expectedRevision,
  }) async {
    if (expectedRevision != value.revision) {
      return const Failure(
        AppFailure(
          FailureKind.conflict,
          'Settings changed. Reload the saved configuration before applying.',
        ),
      );
    }
    value = AppConfiguration(
      client: settings,
      nodes: value.nodes,
      selectedNodeId: value.selectedNodeId,
      revision: value.revision + 1,
    );
    return Success(value);
  }

  @override
  Future<void> close() async {}
}
