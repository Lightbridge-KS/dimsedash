import 'package:dimsedash_core/dimsedash_core.dart';

import '../adapters/persistence/process_guard.dart';

class AppRuntime {
  AppRuntime({
    required this.configStore,
    required this.initial,
    required this.guard,
  });
  final ConfigStore configStore;
  final AppConfiguration initial;
  final ProcessGuard guard;
  Future<void>? _closing;
  Future<void> close() => _closing ??= _close();
  Future<void> _close() async {
    try {
      await configStore.close();
    } finally {
      await guard.close();
    }
  }
}
