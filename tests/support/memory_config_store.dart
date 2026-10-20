import 'package:dimsedash_core/dimsedash_core.dart';

class MemoryConfigStore implements ConfigStore {
  AppConfiguration value = const AppConfiguration();
  int saves = 0;
  @override
  Future<Result<AppConfiguration>> load() async => Success(value);
  @override
  Future<Result<AppConfiguration>> save(AppConfiguration draft) async {
    saves++;
    value = AppConfiguration(
      client: draft.client,
      node: draft.node,
      revision: value.revision + 1,
    );
    return Success(value);
  }

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
    saves++;
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
