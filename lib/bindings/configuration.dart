import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final configStoreProvider = Provider<ConfigStore>(
  (ref) => throw StateError('Inject ConfigStore at bootstrap.'),
);
final initialConfigurationProvider = Provider<AppConfiguration>(
  (ref) => const AppConfiguration(),
);
final configurationProvider =
    NotifierProvider<ConfigurationController, AppConfiguration>(
      ConfigurationController.new,
    );

class ConfigurationController extends Notifier<AppConfiguration> {
  @override
  AppConfiguration build() => ref.read(initialConfigurationProvider);
  Future<AppFailure?> changeNode(NodeCommand command) async {
    final store = ref.read(configStoreProvider);
    if (store is! NodeStore) {
      return const AppFailure(FailureKind.storage, 'Node storage unavailable.');
    }
    final result = await (store as NodeStore).changeNode(command);
    switch (result) {
      case Success<AppConfiguration>(:final value):
        state = value;
        return null;
      case Failure<AppConfiguration>(:final error):
        return error;
    }
  }

  /// Explicit recovery after a conflict; never overwrites an editor draft.
  Future<AppFailure?> reload() async {
    final result = await ref.read(configStoreProvider).load();
    switch (result) {
      case Success<AppConfiguration>(:final value):
        state = value;
        return null;
      case Failure<AppConfiguration>(:final error):
        return error;
    }
  }

  Future<AppFailure?> saveClientSettings(
    ClientSettings settings, {
    required int expectedRevision,
  }) async {
    final result = await ref
        .read(configStoreProvider)
        .saveClientSettings(settings, expectedRevision: expectedRevision);
    switch (result) {
      case Success<AppConfiguration>(:final value):
        state = value;
        return null;
      case Failure<AppConfiguration>(:final error):
        return error;
    }
  }

  Future<AppFailure?> save(AppConfiguration draft) async {
    final result = await ref.read(configStoreProvider).save(draft);
    switch (result) {
      case Success<AppConfiguration>(:final value):
        state = value;
        return null;
      case Failure<AppConfiguration>(:final error):
        return error;
    }
  }
}

final revealProvider = NotifierProvider<RevealController, bool>(
  RevealController.new,
);

class RevealController extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
}
