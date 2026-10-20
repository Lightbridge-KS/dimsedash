import 'dart:async';

import 'package:dimsedash/bindings/configuration.dart';
import 'package:dimsedash/features/settings/settings_view.dart';
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/memory_config_store.dart';

class _ControlledConfigStore extends MemoryConfigStore {
  final pending = Completer<Result<AppConfiguration>>();
  ClientSettings? settings;
  int? expectedRevision;
  @override
  Future<Result<AppConfiguration>> save(AppConfiguration draft) =>
      throw StateError('Settings must not use the combined node write.');
  @override
  Future<Result<AppConfiguration>> saveClientSettings(
    ClientSettings settings, {
    required int expectedRevision,
  }) {
    saves++;
    this.settings = settings;
    this.expectedRevision = expectedRevision;
    return pending.future;
  }
}

const node = PacsNode(
  id: 'node',
  label: 'Synthetic PACS',
  calledAe: 'PACS_AET',
  host: '192.0.2.1',
  port: 104,
  revision: 4,
);

Future<void> pumpSettings(
  WidgetTester tester,
  MemoryConfigStore store, {
  Size size = const Size(1200, 1000),
  Brightness brightness = Brightness.light,
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        configStoreProvider.overrideWithValue(store),
        initialConfigurationProvider.overrideWithValue(store.value),
      ],
      child: MaterialApp(
        theme: ThemeData(brightness: brightness),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const Scaffold(body: SettingsView()),
      ),
    ),
  );
}

Future<void> tap(WidgetTester t, String text) async {
  await t.ensureVisible(find.text(text).last);
  await t.pumpAndSettle();
  await t.tap(find.text(text).last);
  await t.pumpAndSettle();
}

String fieldText(WidgetTester t, String key) =>
    t.widget<TextField>(find.byKey(ValueKey(key))).controller!.text;

void main() {
  for (final selected in [true, false]) {
    testWidgets(
      'global fields only with selected=$selected; saves preserve library',
      (t) async {
        final store = MemoryConfigStore()
          ..value = AppConfiguration(
            nodes: const [node],
            selectedNodeId: selected ? 'node' : null,
            revision: 7,
          );
        await pumpSettings(t, store);
        expect(find.text('Local DICOM settings'), findsOneWidget);
        expect(find.textContaining('For C-MOVE, register'), findsOneWidget);
        expect(find.text('Remote PACS · selected node'), findsNothing);
        expect(find.text('Configure a remote PACS'), findsNothing);
        for (final key in ['label', 'calledAe', 'host', 'pacsPort']) {
          expect(find.byKey(ValueKey(key)), findsNothing);
        }
        await t.enterText(
          find.byKey(const ValueKey('callingAe')),
          'TEST_CLIENT',
        );
        await tap(t, 'Save settings');
        expect(store.saves, 1);
        expect(store.value.client.callingAe, 'TEST_CLIENT');
        expect(store.value.nodes.single, same(node));
        expect(store.value.selectedNodeId, selected ? 'node' : null);
        expect(store.value.revision, 8);
        await t.enterText(find.byKey(const ValueKey('callingAe')), 'UNSAVED');
        await tap(t, 'Discard edits');
        expect(fieldText(t, 'callingAe'), 'TEST_CLIENT');
        expect(store.saves, 1);
      },
    );
  }
  testWidgets(
    'without nodes validates client fields and never creates a node',
    (t) async {
      final store = MemoryConfigStore();
      await pumpSettings(t, store);
      await t.enterText(find.byKey(const ValueKey('callingAe')), 'A' * 17);
      await t.enterText(find.byKey(const ValueKey('listenPort')), '0');
      await t.enterText(find.byKey(const ValueKey('dimse')), '1.5');
      await tap(t, 'Save settings');
      expect(store.saves, 0);
      expect(find.textContaining('1–16 ASCII'), findsOneWidget);
      expect(find.text('Use a port from 1 to 65535.'), findsOneWidget);
      expect(find.text('Use whole seconds from 1 to 600.'), findsOneWidget);
      await tap(t, 'Discard edits');
      await tap(t, 'Save settings');
      expect(store.value.nodes, isEmpty);
      expect(store.value.selectedNodeId, isNull);
    },
  );
  for (final failure in [FailureKind.storage, FailureKind.conflict]) {
    testWidgets(
      'pending save disables controls; $failure preserves draft until discard',
      (t) async {
        final store = _ControlledConfigStore()
          ..value = const AppConfiguration(
            nodes: [node],
            selectedNodeId: 'node',
            revision: 9,
          );
        await pumpSettings(t, store);
        await t.enterText(find.byKey(const ValueKey('callingAe')), 'UNSAVED');
        await tap(t, 'Save settings');
        expect(store.settings!.callingAe, 'UNSAVED');
        expect(store.expectedRevision, 9);
        expect(
          t.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        expect(
          t.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
          isNull,
        );
        expect(
          t
              .widget<DropdownButtonFormField<Appearance>>(
                find.byType(DropdownButtonFormField<Appearance>),
              )
              .onChanged,
          isNull,
        );
        for (final field in t.widgetList<TextField>(find.byType(TextField))) {
          expect(field.enabled, isFalse);
        }
        store.value = const AppConfiguration(
          client: ClientSettings(callingAe: 'RELOADED'),
          nodes: [node],
          selectedNodeId: 'node',
          revision: 10,
        );
        store.pending.complete(
          Failure(AppFailure(failure, 'Synthetic failure.')),
        );
        await t.pumpAndSettle();
        expect(fieldText(t, 'callingAe'), 'UNSAVED');
        expect(find.text('Synthetic failure.'), findsOneWidget);
        expect(store.saves, 1);
        await tap(t, 'Discard edits');
        expect(fieldText(t, 'callingAe'), 'RELOADED');
        expect(find.text('Synthetic failure.'), findsNothing);
      },
    );
  }
  for (final brightness in Brightness.values) {
    testWidgets(
      'appearance saves and layout fits scaled minimum in $brightness',
      (t) async {
        final store = MemoryConfigStore();
        await pumpSettings(
          t,
          store,
          size: const Size(760, 600),
          scale: 1.5,
          brightness: brightness,
        );
        final appearance = find.byType(DropdownButtonFormField<Appearance>);
        await t.ensureVisible(appearance);
        await t.pumpAndSettle();
        await t.tap(appearance);
        await t.pumpAndSettle();
        await tap(t, 'dark');
        await tap(t, 'Save settings');
        expect(store.value.client.appearance, Appearance.dark);
        expect(
          find.text('Settings saved. No network request sent.'),
          findsOneWidget,
        );
        expect(t.takeException(), isNull);
      },
    );
  }
}
