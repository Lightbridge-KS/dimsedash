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
  WidgetController.hitTestWarningShouldBeFatal = true;
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
      await tester.pumpAndSettle();
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
      await tester.ensureVisible(find.text('Save settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save settings'));
      await tester.pumpAndSettle();
      expect(find.textContaining('1–16 ASCII'), findsOneWidget);
      expect(
        (await runtime!.configStore.load() as Success<AppConfiguration>)
            .value
            .revision,
        0,
      );
      await tester.tap(find.text('Discard edits'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('callingAe')))
            .controller!
            .text,
        'DIMSE_DASH',
      );
      expect(find.textContaining('1–16 ASCII'), findsNothing);
      await enterText('callingAe', 'TEST_CLIENT');
      await enterText('listenPort', '11113');
      final appearance = find.byType(DropdownButtonFormField<Appearance>);
      await tester.ensureVisible(appearance);
      await tester.pumpAndSettle();
      await tester.tap(appearance);
      await tester.pumpAndSettle();
      await tester.tap(find.text('light').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save settings'));
      await tester.pumpAndSettle();
      for (
        var i = 0;
        i < 200 &&
            find
                .text('Settings saved. No network request sent.')
                .evaluate()
                .isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(
        find.text('Settings saved. No network request sent.'),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((w) => w.data)
            .join(' | '),
      );
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.light,
      );
      // Node configuration has one editing surface: the Nodes library.
      expect(
        (await runtime!.configStore.load() as Success<AppConfiguration>)
            .value
            .nodes,
        isEmpty,
      );
      await tester.tap(find.widgetWithText(ListTile, 'Nodes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add node'));
      await tester.pumpAndSettle();
      for (final entry in {
        'label': 'Synthetic PACS',
        'calledAe': 'PACS_AET',
        'host': '192.0.2.1',
        'pacsPort': '104',
      }.entries) {
        await enterText(entry.key, entry.value);
      }
      await tester.ensureVisible(find.text('Save & open Workbench'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save & open Workbench'));
      for (
        var i = 0;
        i < 200 && find.text('All nodes').evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();
      expect(find.text('All nodes'), findsOneWidget);
      await tester.tap(find.text('Reveal values'));
      await tester.pumpAndSettle();
      expect(find.text('Mask values'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await runtime!.close();
      await launch();
      expect(runtime!.initial.client.callingAe, 'TEST_CLIENT');
      expect(runtime!.initial.client.listenPort, 11113);
      expect(runtime!.initial.client.appearance, Appearance.light);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.light,
      );
      expect(runtime!.initial.node!.host, '192.0.2.1');
      expect(runtime!.initial.node!.calledAe, 'PACS_AET');
      expect(runtime!.initial.node!.port, 104);
      expect(find.textContaining('Stopped'), findsWidgets);
      expect(find.text('Reveal values'), findsOneWidget);
      expect(find.text('DICOM nodes'), findsOneWidget);
      expect(find.text('Selected'), findsOneWidget);
      final nodeId = runtime!.initial.node!.id;
      await tester.tap(find.byKey(ValueKey('open-node-$nodeId')));
      await tester.pumpAndSettle();
      expect(find.text('All nodes'), findsOneWidget);
      await tester.tap(find.widgetWithText(ListTile, 'Nodes'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('node-menu-$nodeId')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit node'));
      await tester.pumpAndSettle();
      await enterText('label', 'Renamed synthetic PACS');
      await tester.tap(find.text('Save changes'));
      for (
        var i = 0;
        i < 200 && find.text('Save changes').evaluate().isNotEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();
      final edited =
          (await runtime!.configStore.load() as Success<AppConfiguration>)
              .value;
      expect(edited.node!.id, nodeId);
      expect(edited.node!.label, 'Renamed synthetic PACS');
      expect(find.text('DICOM nodes'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await runtime?.close();
      await dir.delete(recursive: true);
    }
  });
}
