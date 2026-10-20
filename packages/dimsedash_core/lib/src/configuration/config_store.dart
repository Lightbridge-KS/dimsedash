import '../foundation/result.dart';
import 'configuration.dart';

abstract interface class ConfigStore {
  Future<Result<AppConfiguration>> load();

  /// Atomically saves client and selected node, rejecting a stale revision.
  Future<Result<AppConfiguration>> save(AppConfiguration draft);

  /// Saves global settings only; preserves every node and the selection.
  /// Rejects stale configuration revisions without merging or overwriting.
  Future<Result<AppConfiguration>> saveClientSettings(
    ClientSettings settings, {
    required int expectedRevision,
  });
  Future<void> close();
}

abstract interface class NodeStore {
  Future<Result<AppConfiguration>> changeNode(NodeCommand command);
}

sealed class NodeCommand {
  const NodeCommand(this.expectedRevision);
  final int expectedRevision;
}

final class AddNode extends NodeCommand {
  const AddNode(super.expectedRevision, this.draft);
  final PacsNode draft;
}

final class EditNode extends NodeCommand {
  const EditNode(super.expectedRevision, this.node);
  final PacsNode node;
}

final class SelectNode extends NodeCommand {
  const SelectNode(super.expectedRevision, this.id);
  final String? id;
}

final class RemoveNode extends NodeCommand {
  const RemoveNode(super.expectedRevision, this.id);
  final String id;
}
