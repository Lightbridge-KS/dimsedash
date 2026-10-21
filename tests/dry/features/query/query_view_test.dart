import 'package:dimsedash/app/shell.dart';
import 'package:dimsedash/bindings/configuration.dart';
import 'package:dimsedash/features/query/query_preview.dart';
import 'package:dimsedash/features/query/query_view.dart';
import 'package:dimsedash/ui/theme.dart';
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/node_config_store.dart';

const one = PacsNode(
  id: 'one',
  label: 'Example archive',
  host: '192.0.2.1',
  port: 104,
  calledAe: 'PACS_AET',
);
const two = PacsNode(
  id: 'two',
  label: 'Second archive',
  host: '192.0.2.2',
  port: 104,
  calledAe: 'PACS_AET',
);
Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<(NodeConfigStore, ProviderContainer)> launch(
  WidgetTester tester, {
  Brightness brightness = Brightness.light,
  Size size = const Size(1300, 1000),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final store = NodeConfigStore(
    const AppConfiguration(nodes: [one, two], selectedNodeId: 'one'),
  );
  final container = ProviderContainer(
    overrides: [
      configStoreProvider.overrideWithValue(store),
      initialConfigurationProvider.overrideWithValue(store.value),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: workbenchTheme(brightness),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const WorkbenchShell(),
      ),
    ),
  );
  await tap(tester, find.byKey(const ValueKey('open-node-one')));
  await tap(tester, find.text('Query'));
  return (store, container);
}

QueryPreviewController controller(WidgetTester tester) =>
    tester.widget<QueryPreviewView>(find.byType(QueryPreviewView)).controller;
void main() {
  testWidgets(
    'blank preview, shared editors, dates, frozen evidence and return semantics',
    (tester) async {
      final (store, _) = await launch(tester);
      expect(
        find.text('UI preview · synthetic data · no network'),
        findsOneWidget,
      );
      final c = controller(tester);
      final from = find.widgetWithText(TextFormField, 'Study date From');
      await tester.ensureVisible(from);
      await tester.enterText(from, '2026-10-01');
      await tester.pumpAndSettle();
      expect(c.draft.entry(PreviewKey.date).value, '20261001-');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Study date Through'),
        '2026-10-22',
      );
      await tester.pumpAndSettle();
      await tap(tester, find.text('Advanced Identifier'));
      expect(
        find.widgetWithText(TextFormField, '20261001-20261022'),
        findsOneWidget,
      );
      c.advanced(
        PreviewKey.patientId,
        value: 'SYNTH-101',
        purpose: IdentifierPurpose.match,
      );
      await tester.pumpAndSettle();
      await tap(tester, find.text('Filters'));
      expect(find.widgetWithText(TextFormField, 'SYNTH-101'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('run-query-preview')));
      final frozen = c.result!.request;
      expect(c.result!.rows, hasLength(3));
      expect(store.commands, isEmpty);
      c.edit(PreviewKey.patientId, 'CHANGED');
      await tester.pumpAndSettle();
      expect(find.textContaining('Draft changed'), findsOneWidget);
      expect(frozen.draft.entry(PreviewKey.patientId).value, 'SYNTH-101');
      c.advanced(PreviewKey.patientId, purpose: IdentifierPurpose.returnKey);
      await tester.pumpAndSettle();
      expect(find.textContaining('Return key · empty on wire'), findsWidgets);
      c.advanced(PreviewKey.patientId, enabled: false);
      await tester.pumpAndSettle();
      expect(find.textContaining('Disabled · omitted'), findsOneWidget);
    },
  );
  testWidgets(
    'scenarios and hierarchy preserve parent results; inspect and retrieval are separate',
    (tester) async {
      await launch(tester);
      final c = controller(tester);
      await tap(tester, find.text('Reveal values'));
      await tap(tester, find.byKey(const ValueKey('run-query-preview')));
      await tap(tester, find.text('Inspect').first);
      expect(c.selected, isNull);
      expect(find.text('Returned metadata · preview'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      await tap(tester, find.text('Open series').first);
      expect(c.result, isNull);
      expect(c.draft.level, QueryLevel.series);
      await tap(tester, find.byKey(const ValueKey('run-query-preview')));
      await tap(tester, find.text('Open instances').first);
      expect(c.result, isNull);
      await tap(tester, find.byKey(const ValueKey('run-query-preview')));
      await tap(tester, find.text('Select').first);
      await tap(tester, find.text('Review retrieve'));
      expect(find.text('This instance only'), findsOneWidget);
      expect(find.textContaining('SOPInstanceUID ='), findsWidgets);
      await tap(tester, find.text('Close'));
      await tap(tester, find.text('Studies'));
      expect(c.result!.rows, hasLength(3));
      expect(c.selected, isNull);
      for (final scenario in [
        PreviewScenario.empty,
        PreviewScenario.partial,
        PreviewScenario.rejected,
      ]) {
        c.setScenario(scenario);
        await tester.pumpAndSettle();
        await tap(tester, find.byKey(const ValueKey('run-query-preview')));
        expect(c.result!.scenario, scenario);
      }
      expect(
        find.textContaining('Query failed — not an empty result'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'same node retains draft selection editor collapse scroll; another node clears',
    (tester) async {
      final (store, _) = await launch(tester);
      final c = controller(tester);
      c.edit(PreviewKey.patientId, 'SYNTH-101');
      c.run(store.value, echoActive: false);
      c.select(c.result!.rows.first);
      c.setEditor(QueryEditor.resolved);
      c.setCollapsed(true);
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey('query-scroll')),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      final offset = c.scrollOffset;
      await tap(tester, find.widgetWithText(ListTile, 'Settings'));
      expect(find.byType(QueryPreviewView), findsNothing);
      await tap(tester, find.widgetWithText(ListTile, 'Nodes'));
      await tap(tester, find.byKey(const ValueKey('open-node-one')));
      expect(controller(tester), same(c));
      expect(c.selected, isNotNull);
      expect(c.editor, QueryEditor.resolved);
      expect(c.collapsed, isTrue);
      expect(c.scrollOffset, closeTo(offset, 1));
      expect(store.commands, isEmpty);
      await tap(tester, find.widgetWithText(ListTile, 'Nodes'));
      await tap(tester, find.byKey(const ValueKey('open-node-two')));
      expect(find.byType(QueryPreviewView), findsNothing);
      await tap(tester, find.text('Query'));
      expect(controller(tester).result, isNull);
      expect(
        controller(tester).draft.entry(PreviewKey.patientId).value,
        isEmpty,
      );
    },
  );
  testWidgets(
    'settings mismatch preserves snapshot; node removal clears preview',
    (tester) async {
      final (store, container) = await launch(tester);
      final c = controller(tester);
      await tap(tester, find.byKey(const ValueKey('run-query-preview')));
      await container
          .read(configurationProvider.notifier)
          .saveClientSettings(
            const ClientSettings(callingAe: 'CHANGED_AE'),
            expectedRevision: store.value.revision,
          );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Current settings apply to the next preview'),
        findsOneWidget,
      );
      expect(c.result!.request.client.callingAe, 'DIMSE_DASH');
      await container
          .read(configurationProvider.notifier)
          .changeNode(RemoveNode(store.value.revision, 'one'));
      await tester.pumpAndSettle();
      expect(find.text('DICOM nodes'), findsOneWidget);
      expect(find.byType(QueryPreviewView), findsNothing);
    },
  );
  for (final brightness in Brightness.values) {
    testWidgets(
      'minimum scaled layout and keyboard dialogs in ${brightness.name}',
      (tester) async {
        await launch(
          tester,
          brightness: brightness,
          size: const Size(760, 600),
          scale: 1.5,
        );
        expect(tester.takeException(), isNull);
        await tap(tester, find.text('Advanced Identifier'));
        await tap(tester, find.text('Tag / sequence sketch'));
        expect(tester.takeException(), isNull);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        await tap(tester, find.text('Resolved Identifier'));
        await tap(tester, find.byKey(const ValueKey('run-query-preview')));
        expect(find.textContaining('Identifier values masked'), findsOneWidget);
        await tap(tester, find.text('Reveal values'));
        expect(
          find.textContaining('QueryRetrieveLevel = STUDY'),
          findsOneWidget,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(FocusManager.instance.primaryFocus, isNotNull);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
