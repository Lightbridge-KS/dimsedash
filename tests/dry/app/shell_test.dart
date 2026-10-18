import 'package:dimsedash/bindings/configuration.dart';
import 'package:dimsedash/app/shell.dart';
import 'package:dimsedash/features/settings/settings_view.dart';
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_config_store.dart';

void main() {
  testWidgets('minimum window handles a long saved node without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(760, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final config = AppConfiguration(
      node: PacsNode(
        id: 'test',
        label: 'N' * 100,
        calledAe: 'PACS_AET',
        host: 'pacs.example',
        port: 104,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [initialConfigurationProvider.overrideWithValue(config)],
        child: const MaterialApp(home: WorkbenchShell()),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Settings').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  for (final configured in [false, true]) {
    testWidgets(
      'shell navigation and placeholders with configured=$configured',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final configuration = AppConfiguration(
          node: configured
              ? const PacsNode(
                  id: 'synthetic',
                  label: 'Synthetic PACS',
                  calledAe: 'PACS_AET',
                  host: 'pacs.example',
                  port: 104,
                )
              : null,
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              initialConfigurationProvider.overrideWithValue(configuration),
            ],
            child: const MaterialApp(home: WorkbenchShell()),
          ),
        );
        expect(
          find.text('No saved nodes'),
          configured ? findsNothing : findsOneWidget,
        );
        expect(find.text('Stopped'), findsOneWidget);
        expect(
          find.text('Receiver unavailable in this build.'),
          findsOneWidget,
        );
        final navigation = find.byType(ListTile);
        expect(
          tester
              .widgetList<ListTile>(navigation)
              .map((tile) => (tile.title! as Text).data),
          ['Workbench', 'Received files', 'History', 'Settings'],
        );
        expect(tester.getTopLeft(navigation.first).dx, 16);
        expect(tester.getSize(navigation.first).width, 188);
        for (final (page, title, icon) in [
          (
            'Workbench',
            configured
                ? 'Connection configured'
                : 'Configure your first connection',
            Icons.hub_outlined,
          ),
          ('Received files', 'No received files', Icons.folder_outlined),
          ('History', 'No run history', Icons.history),
        ]) {
          await tester.tap(find.widgetWithText(ListTile, page));
          await tester.pumpAndSettle();
          expect(find.text(title), findsOneWidget);
          expect(
            find.text(
              page == 'Workbench'
                  ? 'Settings are ready. Echo and query workflows will be available in a later preview.'
                  : 'This workflow will be available in a later preview.',
            ),
            findsOneWidget,
          );
          expect(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Icon && widget.icon == icon && widget.size == 44,
            ),
            findsOneWidget,
          );
          expect(
            tester
                .widget<ListTile>(find.widgetWithText(ListTile, page))
                .selected,
            isTrue,
          );
          await tester.tap(find.text('Open Settings'));
          await tester.pumpAndSettle();
          expect(find.byType(SettingsView), findsOneWidget);
          expect(
            tester
                .widget<ListTile>(find.widgetWithText(ListTile, 'Settings'))
                .selected,
            isTrue,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('shell updates saved sidebar details without changing the page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = MemoryConfigStore();
    final container = ProviderContainer(
      overrides: [configStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: WorkbenchShell()),
      ),
    );
    await tester.tap(find.widgetWithText(ListTile, 'History'));
    await tester.pumpAndSettle();
    final failure = await container
        .read(configurationProvider.notifier)
        .save(
          const AppConfiguration(
            client: ClientSettings(callingAe: 'TEST_CLIENT', listenPort: 11113),
            node: PacsNode(
              id: 'synthetic',
              label: 'Synthetic PACS',
              calledAe: 'PACS_AET',
              host: 'pacs.example',
              port: 104,
              environment: NodeEnvironment.production,
            ),
          ),
        );
    expect(failure, isNull);
    await tester.pumpAndSettle();
    for (final text in [
      'Synthetic PACS',
      'PACS_AET',
      'pacs.example : 104',
      'production',
      'TEST_CLIENT',
      'Port 11113',
      'No run history',
      'Stopped',
    ]) {
      expect(find.text(text), findsOneWidget);
    }
    expect(find.text('No saved nodes'), findsNothing);
    expect(store.saves, 1);
    await tester.tap(find.widgetWithText(ListTile, 'Workbench'));
    await tester.pumpAndSettle();
    expect(find.text('Connection configured'), findsOneWidget);
  });
  testWidgets(
    'shell discards abandoned Settings edits and retains reveal state',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: WorkbenchShell())),
      );
      expect(find.text('Reveal values'), findsOneWidget);
      await tester.tap(find.text('Reveal values'));
      await tester.pumpAndSettle();
      expect(find.text('Mask values'), findsOneWidget);
      await tester.tap(find.widgetWithText(ListTile, 'Settings'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('callingAe')),
        'UNSAVED',
      );
      await tester.tap(find.widgetWithText(ListTile, 'History'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsView), findsNothing);
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('callingAe')))
            .controller!
            .text,
        'DIMSE_DASH',
      );
      expect(find.text('Mask values'), findsOneWidget);
      await tester.tap(find.text('Mask values'));
      await tester.pumpAndSettle();
      expect(find.text('Reveal values'), findsOneWidget);
    },
  );
}
