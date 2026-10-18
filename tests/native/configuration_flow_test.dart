import 'dart:io';

import 'package:dimsedash/app/app.dart';
import 'package:dimsedash/app/app_runtime.dart';
import 'package:dimsedash/app/bootstrap.dart';
import 'package:dimsedash/bindings/configuration.dart';
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native UI saves SQLite and reopens idle with masked values', (
    tester,
  ) async {
    // Keep synthetic text input isolated from the desktop IME; real keyboard
    // editing is a separate native acceptance check.
    tester.testTextInput.register();
    addTearDown(tester.testTextInput.unregister);
    final dir = await Directory.systemTemp.createTemp('dimsedash-native-');
    AppRuntime? runtime;
    Future<void> enterText(String key, String text) async {
      final field = find.byKey(ValueKey(key));
      await tester.ensureVisible(field);
      // Re-establish focus after button taps or scrolling before injecting text.
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, text);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(field).controller!.text,
        text,
        reason: 'Synthetic input must reach $key before continuing.',
      );
    }

    Future<void> launch() async {
      runtime =
          (await bootstrap(supportDirectory: dir) as Success<AppRuntime>).value;
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            configStoreProvider.overrideWithValue(runtime!.configStore),
            initialConfigurationProvider.overrideWithValue(runtime!.initial),
          ],
          child: DimseDashApp(runtime: runtime!),
        ),
      );
      await tester.pumpAndSettle();
    }

    try {
      await launch();
      expect(find.textContaining('Stopped'), findsWidgets);
      await tester.tap(find.text('Settings').first);
      await tester.pumpAndSettle();
      await enterText('callingAe', 'TOO_LONG_AE_TITLE_VALUE');
      await tester.ensureVisible(find.text('Apply connection'));
      await tester.tap(find.text('Apply connection'));
      await tester.pumpAndSettle();
      expect(find.textContaining('1–16 ASCII'), findsOneWidget);
      expect(
        (await runtime!.configStore.load() as Success<AppConfiguration>)
            .value
            .revision,
        0,
      );
      await enterText('callingAe', 'TEST_CLIENT');
      await enterText('listenPort', '11113');
      await tester.tap(find.text('Configure a remote PACS'));
      await tester.pumpAndSettle();
      for (final entry in {
        'label': 'Synthetic PACS',
        'calledAe': 'PACS_AET',
        'host': '192.0.2.1',
        'pacsPort': '104',
      }.entries) {
        await enterText(entry.key, entry.value);
      }
      await tester.ensureVisible(find.text('Apply connection'));
      await tester.tap(find.text('Apply connection'));
      await tester.pumpAndSettle();
      for (
        var i = 0;
        i < 200 &&
            find
                .text('Connection saved. No network request sent.')
                .evaluate()
                .isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(
        find.text('Connection saved. No network request sent.'),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((w) => w.data)
            .join(' | '),
      );
      await tester.pumpWidget(const SizedBox());
      await runtime!.close();
      await launch();
      expect(runtime!.initial.client.callingAe, 'TEST_CLIENT');
      expect(runtime!.initial.client.listenPort, 11113);
      expect(runtime!.initial.node!.host, '192.0.2.1');
      expect(runtime!.initial.node!.calledAe, 'PACS_AET');
      expect(runtime!.initial.node!.port, 104);
      expect(find.textContaining('Stopped'), findsWidgets);
      expect(find.text('Reveal values'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await runtime?.close();
      await dir.delete(recursive: true);
    }
  });
}
