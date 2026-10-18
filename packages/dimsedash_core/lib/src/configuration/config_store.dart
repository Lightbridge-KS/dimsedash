import '../foundation/result.dart';
import 'configuration.dart';

abstract interface class ConfigStore {
  Future<Result<AppConfiguration>> load();

  /// Atomically saves client and selected node, rejecting a stale revision.
  Future<Result<AppConfiguration>> save(AppConfiguration draft);
  Future<void> close();
}
