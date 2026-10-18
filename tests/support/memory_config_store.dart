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
  Future<void> close() async {}
}
