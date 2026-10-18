import 'package:dimsedash/bindings/configuration.dart';
import 'package:dimsedash/app/shell.dart';
import 'package:dimsedash/features/settings/settings_view.dart';
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryConfigStore implements ConfigStore {
  AppConfiguration value = const AppConfiguration();
  int saves = 0;
  @override
  Future<Result<AppConfiguration>> load() async => Success(value);
  @override
  Future<Result<AppConfiguration>> save(AppConfiguration draft) async {
    saves++;
    value = AppConfiguration(
      client: draft.client,
      node: draft.node,
      revision: value.revision + 1,
    );
    return Success(value);
  }

  @override
  Future<void> close() async {}
}

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
  test('reveal state resets in a new application scope', () {
    final first = ProviderContainer();
    expect(first.read(revealProvider), isFalse);
    first.read(revealProvider.notifier).toggle();
    expect(first.read(revealProvider), isTrue);
    first.dispose();
    final second = ProviderContainer();
    expect(second.read(revealProvider), isFalse);
    second.dispose();
  });
}
