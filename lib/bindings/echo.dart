import 'dart:async';

import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final operationRunnerProvider = Provider<OperationRunner?>((ref) => null);
final echoStateProvider = NotifierProvider<EchoPresentation, EchoState>(
  EchoPresentation.new,
);

/// Subscribe before taking the snapshot, without an async yield gap that could
/// lose a terminal event during navigation or a provider rebuild.
class EchoPresentation extends Notifier<EchoState> {
  @override
  EchoState build() {
    final runner = ref.watch(operationRunnerProvider);
    if (runner == null) return EchoState();
    final subscription = runner.changes.listen((value) => state = value);
    ref.onDispose(() => unawaited(subscription.cancel()));
    return runner.state;
  }
}
