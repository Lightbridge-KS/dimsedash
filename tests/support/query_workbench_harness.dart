import 'package:dimsedash/app/shell.dart';
import 'package:dimsedash/bindings/configuration.dart';
import 'package:dimsedash/features/query/query_preview.dart';
import 'package:dimsedash/features/query/query_view.dart';
import 'package:dimsedash/ui/theme.dart';
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'node_config_store.dart';

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
