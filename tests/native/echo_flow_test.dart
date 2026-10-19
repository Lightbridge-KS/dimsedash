import 'dart:io';

import 'package:dimsedash/app/app.dart';
import 'package:dimsedash/app/app_runtime.dart';
import 'package:dimsedash/app/bootstrap.dart';
import 'package:dimsedash/bindings/configuration.dart';
import 'package:dimsedash/bindings/echo.dart';
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native Echo survives navigation and settings edits, then retries',
    (tester) async {
      tester.testTextInput.register();
      final dir = await Directory.systemTemp.createTemp(
        'dimsedash-native-echo-',
      );
      final runtime =
          (await bootstrap(supportDirectory: dir) as Success<AppRuntime>).value;
      try {
        final saved = (await runtime.configStore.save(
          const AppConfiguration(
            client: ClientSettings(
              timeouts: EchoTimeouts(
                connect: 2,
                association: 2,
                dimse: 6,
                idle: 6,
              ),
            ),
            node: PacsNode(
              id: '',
              label: 'Synthetic delayed peer',
              calledAe: 'PACS_AET',
              host: '127.0.0.1',
              port: int.fromEnvironment('PEER_PORT', defaultValue: 4250) + 3,
            ),
          ),
        ) as Success<AppConfiguration>).value;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              configStoreProvider.overrideWithValue(runtime.configStore),
              initialConfigurationProvider.overrideWithValue(saved),
              operationRunnerProvider.overrideWithValue(runtime.runner),
            ],
            child: DimseDashApp(runtime: runtime),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Run Echo'));
        await tester.pumpAndSettle();
        expect(runtime.runner!.active, isTrue);
        await tester.tap(find.widgetWithText(ListTile, 'Settings'));
        await tester.pumpAndSettle();
        final timeout = find.byKey(const ValueKey('dimse'));
        await tester.ensureVisible(timeout);
        await tester.tap(timeout);
        await tester.enterText(timeout, '1');
        await tester.ensureVisible(find.text('Apply connection'));
        await tester.tap(find.text('Apply connection'));
        await tester.pumpAndSettle();
        expect(runtime.runner!.state.request!.client.timeouts.dimse, 6);
        await tester.tap(find.widgetWithText(ListTile, 'Workbench'));
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          if (runtime.runner!.active) {
            await runtime.runner!.changes
                .firstWhere((s) => !s.active)
                .timeout(const Duration(seconds: 8));
          }
        });
        await tester.pumpAndSettle();
        expect(runtime.runner!.state.summary!.outcome!.status, 0);
        for (final tab in ['Timeline', 'Negotiation', 'Trace', 'Summary']) {
          await tester.tap(find.text(tab));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        final id = runtime.runner!.state.summary!.id;
        await tester.tap(find.text('Run Echo'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Stop Echo'));
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          if (runtime.runner!.active) {
            await runtime.runner!.changes
                .firstWhere((s) => !s.active)
                .timeout(const Duration(seconds: 5));
          }
        });
        expect(runtime.runner!.state.summary!.id, isNot(id));
        expect(runtime.runner!.state.summary!.stopRequested, isTrue);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await runtime.close();
        await dir.delete(recursive: true);
        tester.testTextInput.unregister();
      }
    },
  );
}
