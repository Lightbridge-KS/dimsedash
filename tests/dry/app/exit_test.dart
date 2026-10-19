import 'dart:ui' show AppExitResponse;

import 'package:dimsedash/adapters/persistence/process_guard.dart';
import 'package:dimsedash/app/app.dart';
import 'package:dimsedash/app/app_runtime.dart';
import 'package:dimsedash/bindings/configuration.dart';
import 'package:dimsedash/bindings/echo.dart';
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../operations/echo_test.dart' show Config, Runs, Gateway;

class TestGuard implements ProcessGuard {
  bool closed = false;
  @override
  Future<void> close() async {
    closed = true;
  }
}

void main() {
  testWidgets('active close offers Stay and Stop and quit', (tester) async {
    tester.view.physicalSize = const Size(1100, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final config = Config();
    final gateway = Gateway();
    final runtime = AppRuntime(
      configStore: config,
      initial: config.value,
      guard: TestGuard(),
      runner: OperationRunner(
        configuration: config,
        gateway: gateway,
        store: Runs(),
        newId: () => 'exit',
        appVersion: 'test',
        libraryVersion: 'test',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          configStoreProvider.overrideWithValue(runtime.configStore),
          initialConfigurationProvider.overrideWithValue(runtime.initial),
          operationRunnerProvider.overrideWithValue(runtime.runner),
        ],
        child: DimseDashApp(runtime: runtime),
      ),
    );
    await runtime.runner!.start(1);
    await tester.pumpAndSettle();
    final stay = tester.binding.handleRequestAppExit();
    await tester.pumpAndSettle();
    expect(find.text('Echo is running'), findsOneWidget);
    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();
    expect(await stay, AppExitResponse.cancel);
    expect(gateway.calls.single.stopped, isFalse);
    final quit = tester.binding.handleRequestAppExit();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stop and quit'));
    await tester.pump();
    expect(gateway.calls.single.stopped, isTrue);
    gateway.calls.single.completer.complete(
      const EchoOutcome(EchoDisposition.stopped),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(await quit, AppExitResponse.exit);
    expect((runtime.guard as TestGuard).closed, isTrue);
  });
}
