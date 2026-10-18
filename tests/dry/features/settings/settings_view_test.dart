import 'dart:async';

import 'package:dimsedash/bindings/configuration.dart';
import 'package:dimsedash/features/settings/settings_view.dart';
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/memory_config_store.dart';

class _ControlledConfigStore implements ConfigStore {
  final pending = Completer<Result<AppConfiguration>>();
  AppConfiguration? draft;
  int saves = 0;

  @override
  Future<Result<AppConfiguration>> load() async =>
      const Success(AppConfiguration());

  @override
  Future<Result<AppConfiguration>> save(AppConfiguration configuration) {
    saves++;
    draft = configuration;
    return pending.future;
  }

  @override
  Future<void> close() async {}
}

Future<void> _pumpSettings(
  WidgetTester tester,
  _ControlledConfigStore store, {
  AppConfiguration configuration = const AppConfiguration(),
}) async {
  tester.view.physicalSize = const Size(1200, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        configStoreProvider.overrideWithValue(store),
        initialConfigurationProvider.overrideWithValue(configuration),
      ],
      child: const MaterialApp(home: Scaffold(body: SettingsView())),
    ),
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _select<T extends Enum>(WidgetTester tester, T value) async {
  await _tap(tester, find.byType(DropdownButtonFormField<T>));
  await _tap(tester, find.text(value.name).last);
}

T? _selection<T extends Enum>(WidgetTester tester) => tester
    .state<FormFieldState<T>>(find.byType(DropdownButtonFormField<T>))
    .value;

String _text(WidgetTester tester, String field) =>
    tester.widget<TextField>(find.byKey(ValueKey(field))).controller!.text;

void main() {
  testWidgets(
    'Apply validates, saves explicitly, and Discard restores saved fields',
    (tester) async {
      tester.view.reset();
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final store = MemoryConfigStore();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [configStoreProvider.overrideWithValue(store)],
          child: const MaterialApp(home: Scaffold(body: SettingsView())),
        ),
      );
      expect(store.saves, 0);
      await tester.enterText(find.byKey(const ValueKey('callingAe')), 'A' * 17);
      await tester.tap(find.text('Apply connection'));
      await tester.pump();
      expect(store.saves, 0);
      expect(find.textContaining('1–16 ASCII'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('callingAe')),
        'TEST_CLIENT',
      );
      await tester.tap(find.text('Apply connection'));
      await tester.pumpAndSettle();
      expect(store.saves, 1);
      expect(store.value.client.callingAe, 'TEST_CLIENT');
      await tester.enterText(
        find.byKey(const ValueKey('callingAe')),
        'UNSAVED',
      );
      await tester.tap(find.text('Discard edits'));
      await tester.pump();
      expect(find.text('TEST_CLIENT'), findsOneWidget);
      expect(store.saves, 1);
    },
  );

  testWidgets('enum controls restore saved selections and Apply both values', (
    tester,
  ) async {
    final store = _ControlledConfigStore();
    await _pumpSettings(
      tester,
      store,
      configuration: const AppConfiguration(
        client: ClientSettings(appearance: Appearance.light),
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
    expect(find.text('Configure a remote PACS'), findsNothing);
    expect(find.text('Remote PACS · selected node'), findsOneWidget);
    expect(
      tester.widget(find.byType(DropdownButtonFormField<Appearance>)).key,
      const ValueKey(Appearance.light),
    );
    expect(
      tester.widget(find.byType(DropdownButtonFormField<NodeEnvironment>)).key,
      const ValueKey(NodeEnvironment.production),
    );
    expect(
      tester
          .widget<DropdownButton<Appearance>>(
            find.byType(DropdownButton<Appearance>),
          )
          .items!
          .map((item) => item.value),
      Appearance.values,
    );
    expect(
      tester
          .widget<DropdownButton<NodeEnvironment>>(
            find.byType(DropdownButton<NodeEnvironment>),
          )
          .items!
          .map((item) => item.value),
      NodeEnvironment.values,
    );
    await _select(tester, Appearance.dark);
    await _select(tester, NodeEnvironment.test);
    await _tap(tester, find.text('Discard edits'));
    expect(_selection<Appearance>(tester), Appearance.light);
    expect(_selection<NodeEnvironment>(tester), NodeEnvironment.production);
    expect(store.saves, 0);
    await _select(tester, Appearance.dark);
    await _select(tester, NodeEnvironment.test);
    await _tap(tester, find.text('Apply connection'));
    expect(store.saves, 1);
    expect(store.draft!.client.appearance, Appearance.dark);
    expect(store.draft!.node!.environment, NodeEnvironment.test);
    store.pending.complete(Success(store.draft!));
    await tester.pumpAndSettle();
    expect(_selection<Appearance>(tester), Appearance.dark);
    expect(_selection<NodeEnvironment>(tester), NodeEnvironment.test);
    expect(
      find.text('Connection saved. No network request sent.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'remote visibility retains draft fields and errors until Discard',
    (tester) async {
      final store = _ControlledConfigStore();
      await _pumpSettings(tester, store);
      final checkbox = find.text('Configure a remote PACS');
      final remoteHelp = find.textContaining(
        'For C-MOVE, register the client AE',
      );
      expect(find.byKey(const ValueKey('label')), findsNothing);
      expect(remoteHelp, findsNothing);
      await _tap(tester, checkbox);
      expect(remoteHelp, findsOneWidget);
      for (final entry in {
        'label': 'Draft PACS',
        'calledAe': 'PACS_AET',
        'host': 'pacs.example',
        'pacsPort': '0',
      }.entries) {
        await tester.enterText(find.byKey(ValueKey(entry.key)), entry.value);
      }
      await _select(tester, NodeEnvironment.production);
      await _tap(tester, find.text('Apply connection'));
      expect(find.text('Use a port from 1 to 65535.'), findsOneWidget);
      expect(store.saves, 0);
      await _tap(tester, checkbox);
      expect(find.byKey(const ValueKey('label')), findsNothing);
      expect(remoteHelp, findsNothing);
      await _tap(tester, checkbox);
      expect(_text(tester, 'label'), 'Draft PACS');
      expect(_text(tester, 'calledAe'), 'PACS_AET');
      expect(_text(tester, 'host'), 'pacs.example');
      expect(_text(tester, 'pacsPort'), '0');
      expect(_selection<NodeEnvironment>(tester), NodeEnvironment.production);
      expect(find.text('Use a port from 1 to 65535.'), findsOneWidget);
      await _tap(tester, find.text('Discard edits'));
      expect(find.byKey(const ValueKey('label')), findsNothing);
      await _tap(tester, checkbox);
      expect(_text(tester, 'label'), isEmpty);
      expect(_selection<NodeEnvironment>(tester), NodeEnvironment.test);
      expect(find.text('Use a port from 1 to 65535.'), findsNothing);
      expect(store.saves, 0);
    },
  );

  testWidgets(
    'pending save disables controls and failure preserves the draft',
    (tester) async {
      final store = _ControlledConfigStore();
      await _pumpSettings(tester, store);
      await _tap(tester, find.text('Configure a remote PACS'));
      for (final entry in {
        'label': 'Draft PACS',
        'calledAe': 'PACS_AET',
        'host': 'pacs.example',
        'pacsPort': '104',
      }.entries) {
        await tester.enterText(find.byKey(ValueKey(entry.key)), entry.value);
      }
      await _select(tester, Appearance.dark);
      await _select(tester, NodeEnvironment.production);
      await _tap(tester, find.text('Apply connection'));
      expect(store.saves, 1);
      expect(find.text('Saving…'), findsOneWidget);
      for (final field in tester.widgetList<TextField>(
        find.byType(TextField),
      )) {
        expect(field.enabled, isFalse);
      }
      expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile))
            .onChanged,
        isNull,
      );
      expect(
        tester
            .widget<DropdownButtonFormField<Appearance>>(
              find.byType(DropdownButtonFormField<Appearance>),
            )
            .onChanged,
        isNull,
      );
      expect(
        tester
            .widget<DropdownButtonFormField<NodeEnvironment>>(
              find.byType(DropdownButtonFormField<NodeEnvironment>),
            )
            .onChanged,
        isNull,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );
      store.pending.complete(
        const Failure(
          AppFailure(FailureKind.storage, 'Synthetic storage failure.'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Synthetic storage failure.'), findsOneWidget);
      expect(_text(tester, 'label'), 'Draft PACS');
      expect(_selection<Appearance>(tester), Appearance.dark);
      expect(_selection<NodeEnvironment>(tester), NodeEnvironment.production);
      expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile))
            .onChanged,
        isNotNull,
      );
      expect(
        tester
            .widget<DropdownButtonFormField<Appearance>>(
              find.byType(DropdownButtonFormField<Appearance>),
            )
            .onChanged,
        isNotNull,
      );
      expect(
        tester
            .widget<DropdownButtonFormField<NodeEnvironment>>(
              find.byType(DropdownButtonFormField<NodeEnvironment>),
            )
            .onChanged,
        isNotNull,
      );
      await _tap(tester, find.text('Discard edits'));
      expect(find.text('Synthetic storage failure.'), findsNothing);
      expect(find.byKey(const ValueKey('label')), findsNothing);
      expect(_selection<Appearance>(tester), Appearance.system);
    },
  );
}
