import 'dart:async';

import 'package:dimsedash/app/shell.dart';
import 'package:dimsedash/bindings/configuration.dart';
import 'package:dimsedash/bindings/echo.dart';
import 'package:dimsedash/features/nodes/node_editor.dart';
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/node_config_store.dart';
import '../../operations/echo_test.dart' show Runs, Gateway;

const alpha = PacsNode(
  id: 'a',
  label: 'Alpha archive',
  calledAe: 'ALPHA',
  host: '192.0.2.1',
  port: 104,
  revision: 1,
  environment: NodeEnvironment.production,
);
const beta = PacsNode(
  id: 'b',
  label: 'Beta sandbox',
  calledAe: 'BETA',
  host: '192.0.2.2',
  port: 4242,
  revision: 1,
);

Future<ProviderContainer> pumpShell(
  WidgetTester tester,
  NodeConfigStore store, {
  Size size = const Size(1200, 1000),
  Brightness brightness = Brightness.light,
  double textScale = 1,
  OperationRunner? runner,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      initialConfigurationProvider.overrideWithValue(store.value),
      configStoreProvider.overrideWithValue(store),
      operationRunnerProvider.overrideWithValue(runner),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(brightness: brightness),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const WorkbenchShell(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> nav(WidgetTester t, String label) async {
  final target = find.widgetWithText(ListTile, label);
  await t.ensureVisible(target);
  await t.pumpAndSettle();
  await t.tap(target);
  await t.pumpAndSettle();
}

Future<void> menu(WidgetTester t, String id, String action) async {
  final target = find.byKey(ValueKey('node-menu-$id'));
  await t.ensureVisible(target);
  await t.pumpAndSettle();
  await t.tap(target);
  await t.pumpAndSettle();
  await t.tap(find.text(action).last);
  await t.pumpAndSettle();
}

Future<void> press(WidgetTester t, String label) async {
  final target = find.text(label).last;
  await t.ensureVisible(target);
  await t.pumpAndSettle();
  await t.tap(target);
  await t.pumpAndSettle();
}

void main() {
  late NodeConfigStore store;
  setUp(() {
    store = NodeConfigStore(
      const AppConfiguration(
        nodes: [beta, alpha],
        selectedNodeId: 'a',
        revision: 1,
      ),
    );
  });

  testWidgets(
    'library restores selection and session filters without dispatch',
    (t) async {
      await pumpShell(t, store);
      expect(find.text('DICOM nodes'), findsOneWidget);
      final semantics = t.ensureSemantics();
      expect(
        find.bySemanticsLabel('Actions for Alpha archive'),
        findsOneWidget,
      );
      semantics.dispose();
      expect(find.text('Selected'), findsOneWidget);
      expect(store.commands, isEmpty);
      expect(
        t.getTopLeft(find.text('Alpha archive')).dx,
        lessThan(t.getTopLeft(find.text('Beta sandbox')).dx),
      );
      await t.enterText(find.byKey(const ValueKey('node-search')), 'BETA');
      await t.pumpAndSettle();
      expect(find.text('Alpha archive'), findsNothing);
      await press(t, 'List');
      await nav(t, 'Settings');
      await nav(t, 'Nodes');
      expect(
        t
            .widget<TextField>(find.byKey(const ValueKey('node-search')))
            .controller!
            .text,
        'BETA',
      );
      expect(
        t
            .widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>))
            .selected,
        {true},
      );
      await t.enterText(find.byKey(const ValueKey('node-search')), 'not found');
      await t.pumpAndSettle();
      expect(find.text('No matching nodes'), findsOneWidget);
      await press(t, 'Clear filters');
      await t.tap(find.byType(DropdownButtonFormField<String>));
      await t.pumpAndSettle();
      await t.tap(find.text('Production').last);
      await t.pumpAndSettle();
      expect(find.text('Beta sandbox'), findsNothing);
      await nav(t, 'Settings');
      await nav(t, 'Nodes');
      expect(find.text('Beta sandbox'), findsNothing);
      expect(store.commands, isEmpty);
    },
  );

  testWidgets(
    'selection waits for successful write; already selected opens without writing',
    (t) async {
      await pumpShell(t, store);
      store.gate = Completer<void>();
      await t.tap(find.byKey(const ValueKey('open-node-b')));
      await t.pump();
      expect(find.text('DICOM nodes'), findsOneWidget);
      expect(store.commands, hasLength(1));
      store.failure = const AppFailure(
        FailureKind.storage,
        'Storage unavailable',
      );
      store.gate!.complete();
      await t.pumpAndSettle();
      expect(find.text('Storage unavailable'), findsOneWidget);
      expect(store.value.selectedNodeId, 'a');
      await t.tap(find.byKey(const ValueKey('open-node-a')));
      await t.pumpAndSettle();
      expect(find.text('All nodes'), findsOneWidget);
      expect(store.commands, hasLength(1));
    },
  );

  testWidgets(
    'edit unselected node keeps selection and handles conflict/reload',
    (t) async {
      await pumpShell(t, store);
      await menu(t, 'b', 'Edit node');
      await t.enterText(find.byKey(const ValueKey('label')), 'Unsaved label');
      // Simulate an intervening configuration write outside this editor.
      store.value = AppConfiguration(
        nodes: store.value.nodes,
        selectedNodeId: 'a',
        revision: 2,
      );
      await press(t, 'Save changes');
      expect(
        find.text('Configuration changed. Reload before editing.'),
        findsOneWidget,
      );
      expect(
        t
            .widget<TextField>(find.byKey(const ValueKey('label')))
            .controller!
            .text,
        'Unsaved label',
      );
      await press(t, 'Reload saved values');
      expect(
        t
            .widget<TextField>(find.byKey(const ValueKey('label')))
            .controller!
            .text,
        'Beta sandbox',
      );
      await t.enterText(find.byKey(const ValueKey('label')), 'Updated beta');
      await press(t, 'Save changes');
      expect(find.byType(NodeEditor), findsNothing);
      expect(find.text('DICOM nodes'), findsOneWidget);
      expect(store.value.selectedNodeId, 'a');
      expect(
        store.value.nodes.singleWhere((n) => n.id == 'b').label,
        'Updated beta',
      );
      final command = store.commands.last as EditNode;
      expect(command.node.id, 'b');
      expect(command.node.revision, 1);
      expect(command.expectedRevision, 2);
    },
  );

  testWidgets(
    'duplicate discard, validation, storage failure and single pending save',
    (t) async {
      await pumpShell(t, store);
      await menu(t, 'b', 'Duplicate');
      expect(
        t
            .widget<TextField>(find.byKey(const ValueKey('label')))
            .controller!
            .text,
        'Beta sandbox copy',
      );
      await press(t, 'Discard');
      expect(store.commands, isEmpty);
      await menu(t, 'b', 'Duplicate');
      await t.enterText(find.byKey(const ValueKey('pacsPort')), '0');
      await press(t, 'Save & open Workbench');
      expect(find.text('Use a port from 1 to 65535.'), findsOneWidget);
      expect(store.commands, isEmpty);
      await t.enterText(find.byKey(const ValueKey('pacsPort')), '4242');
      store.failure = const AppFailure(FailureKind.storage, 'Disk unavailable');
      await press(t, 'Save & open Workbench');
      expect(find.text('Disk unavailable'), findsOneWidget);
      store.failure = null;
      store.gate = Completer<void>();
      await t.tap(find.text('Save & open Workbench'));
      await t.pumpAndSettle();
      expect(
        t
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Saving…'))
            .onPressed,
        isNull,
      );
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(find.byType(NodeEditor), findsOneWidget);
      expect(store.commands, hasLength(2));
      store.gate!.complete();
      await t.pumpAndSettle();
      expect(store.value.nodes, hasLength(3));
      expect(store.value.node!.label, 'Beta sandbox copy');
      expect(store.value.node!.id, isNot('b'));
      expect(find.text('All nodes'), findsOneWidget);
    },
  );

  testWidgets('removal confirms and clears selection without a fallback', (
    t,
  ) async {
    await pumpShell(t, store);
    await menu(t, 'a', 'Remove node');
    expect(find.text('Remove Alpha archive?'), findsOneWidget);
    await press(t, 'Keep node');
    expect(store.commands, isEmpty);
    await menu(t, 'a', 'Remove node');
    await press(t, 'Remove node');
    expect(store.value.selectedNodeId, isNull);
    expect(store.value.nodes, hasLength(1));
    expect(find.text('DICOM nodes'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('open-node-b')));
    await t.pumpAndSettle();
    expect(store.value.selectedNodeId, 'b');
    expect(find.text('Change target node'), findsNothing);
  });

  testWidgets(
    'active Echo survives target change and removal with frozen evidence',
    (t) async {
      final gateway = Gateway();
      final runs = Runs();
      var sequence = 0;
      final runner = OperationRunner(
        configuration: store,
        gateway: gateway,
        store: runs,
        newId: () => 'run-${sequence++}',
        appVersion: 'test',
        libraryVersion: 'test',
      );
      await pumpShell(t, store, runner: runner);
      await t.tap(find.byKey(const ValueKey('open-node-a')));
      await t.pumpAndSettle();
      expect(gateway.calls, isEmpty);
      await press(t, 'Run Echo');
      await nav(t, 'Nodes');
      expect(find.text('View run'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('open-node-b')));
      await t.pumpAndSettle();
      expect(gateway.calls.single.request.node.id, 'a');
      expect(gateway.calls.single.stopped, isFalse);
      expect(
        find.text('No retained Echo evidence for this node'),
        findsOneWidget,
      );
      expect(
        t
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Echo running'),
            )
            .onPressed,
        isNull,
      );
      await nav(t, 'Nodes');
      await menu(t, 'a', 'Remove node');
      await press(t, 'Remove node');
      await press(t, 'View run');
      gateway.calls.single.completer.complete(
        const EchoOutcome(EchoDisposition.success, status: 0),
      );
      await t.pumpAndSettle();
      expect(
        find.textContaining('Frozen target: Alpha archive'),
        findsOneWidget,
      );
      expect(runs.summaries.last.nodeId, 'a');
      expect(find.text('Run Echo'), findsNothing);
      await press(t, 'Back');
      await t.tap(find.byKey(const ValueKey('open-node-b')));
      await t.pumpAndSettle();
      await press(t, 'Run Echo');
      expect(gateway.calls, hasLength(2));
      expect(gateway.calls.last.request.node.id, 'b');
      await press(t, 'Stop Echo');
      expect(gateway.calls.last.stopped, isTrue);
      gateway.calls.last.completer.complete(
        const EchoOutcome(EchoDisposition.stopped),
      );
      await t.pumpAndSettle();
    },
  );

  testWidgets('empty library adds an unsaved draft and persists only on save', (
    t,
  ) async {
    store.value = const AppConfiguration();
    await pumpShell(t, store);
    expect(find.text('Add your first DICOM node'), findsOneWidget);
    await press(t, 'Add node');
    expect(store.commands, isEmpty);
    for (final entry in {
      'label': 'New archive',
      'calledAe': 'PACS_AET',
      'host': '192.0.2.5',
    }.entries) {
      await t.enterText(find.byKey(ValueKey(entry.key)), entry.value);
    }
    await press(t, 'Save & open Workbench');
    expect(store.value.node!.label, 'New archive');
    expect(find.text('All nodes'), findsOneWidget);
    expect(store.commands, hasLength(1));
    expect(store.commands.single, isA<AddNode>());
  });

  testWidgets(
    'library scroll and density survive navigation; menu Escape restores focus',
    (t) async {
      store.value = AppConfiguration(
        nodes: List.generate(
          30,
          (i) => PacsNode(
            id: '$i',
            label: 'Archive ${i.toString().padLeft(2, '0')}',
            calledAe: 'PACS_AET',
            host: '192.0.2.1',
            port: 104,
          ),
        ),
      );
      await pumpShell(t, store);
      await press(t, 'List');
      final library = find.byKey(const PageStorageKey('node-library'));
      await t.drag(library, const Offset(0, -700));
      await t.pumpAndSettle();
      final offset = t.widget<ListView>(library).controller!.offset;
      expect(offset, greaterThan(0));
      await nav(t, 'Settings');
      await nav(t, 'Nodes');
      expect(t.widget<ListView>(library).controller!.offset, offset);
      final action = find.byKey(const ValueKey('node-menu-3'));
      await t.ensureVisible(action);
      await t.pumpAndSettle();
      await t.tap(action);
      await t.pumpAndSettle();
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(find.text('Open Workbench'), findsNothing);
      expect(store.commands, isEmpty);
    },
  );

  testWidgets(
    'equal labels sort by stable ID and search covers host and called AE',
    (t) async {
      store.value = const AppConfiguration(
        nodes: [
          PacsNode(
            id: 'c',
            label: 'alpha archive',
            calledAe: 'RESEARCH',
            host: '192.0.2.3',
            port: 104,
          ),
          beta,
          alpha,
        ],
      );
      await pumpShell(t, store);
      await press(t, 'List');
      expect(
        t.getTopLeft(find.byKey(const ValueKey('open-node-a'))).dy,
        lessThan(t.getTopLeft(find.byKey(const ValueKey('open-node-c'))).dy),
      );
      expect(
        t.getTopLeft(find.byKey(const ValueKey('open-node-c'))).dy,
        lessThan(t.getTopLeft(find.byKey(const ValueKey('open-node-b'))).dy),
      );
      final search = find.byKey(const ValueKey('node-search'));
      for (final query in ['research', '192.0.2.3']) {
        await t.enterText(search, query);
        await t.pumpAndSettle();
        expect(find.byKey(const ValueKey('open-node-c')), findsOneWidget);
        expect(find.byKey(const ValueKey('open-node-a')), findsNothing);
        expect(find.byKey(const ValueKey('open-node-b')), findsNothing);
      }
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'minimum window, text scaling and receiver alignment in ${brightness.name}',
      (t) async {
        store.value = AppConfiguration(
          nodes: [
            PacsNode(
              id: 'long',
              label: 'L' * 100,
              calledAe: 'LONG_AE',
              host: '${'segment.' * 20}example',
              port: 104,
            ),
          ],
          selectedNodeId: 'long',
        );
        await pumpShell(
          t,
          store,
          size: const Size(760, 600),
          brightness: brightness,
          textScale: 1.5,
        );
        expect(t.takeException(), isNull);
        await t.ensureVisible(find.byKey(const ValueKey('receiver-status')));
        await t.pumpAndSettle();
        final semantics = t.ensureSemantics();
        expect(
          t.getSemantics(
            find.bySemanticsLabel(
              'Local receiver stopped. Receiver unavailable in this build.',
            ),
          ),
          matchesSemantics(
            label:
                'Local receiver stopped. Receiver unavailable in this build.',
          ),
        );
        semantics.dispose();
        expect(
          t.getTopLeft(find.byKey(const ValueKey('receiver-status'))).dx,
          t.getTopLeft(find.text('LOCAL RECEIVER')).dx,
        );
        expect(
          find.ancestor(of: find.text('Stopped'), matching: find.byType(Chip)),
          findsNothing,
        );
        await t.ensureVisible(find.byKey(const ValueKey('open-node-long')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const ValueKey('open-node-long')));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        await press(t, 'Connection details');
        expect(t.takeException(), isNull);
        await press(t, 'All nodes');
        await menu(t, 'long', 'Edit node');
        expect(t.takeException(), isNull);
        await t.sendKeyEvent(LogicalKeyboardKey.escape);
        await t.pumpAndSettle();
        expect(find.byType(NodeEditor), findsNothing);
      },
    );
  }

  testWidgets('keyboard opens a card and All nodes restores card focus', (
    t,
  ) async {
    await pumpShell(t, store);
    var cardFocused = false;
    for (var i = 0; i < 30 && !cardFocused; i++) {
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pumpAndSettle();
      FocusManager.instance.primaryFocus?.context?.visitAncestorElements((
        element,
      ) {
        if (element.widget.key == const ValueKey('open-node-a')) {
          cardFocused = true;
        }
        return !cardFocused;
      });
    }
    expect(cardFocused, isTrue);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pumpAndSettle();
    expect(find.text('All nodes'), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pumpAndSettle();
    expect(find.text('All nodes'), findsOneWidget);
    await press(t, 'All nodes');
    final card = t.widget<InkWell>(find.byKey(const ValueKey('open-node-a')));
    expect(card.focusNode!.hasFocus, isTrue);
    expect(store.commands, isEmpty);
  });
  testWidgets(
    'late selection completion never pulls navigation back from Settings',
    (t) async {
      await pumpShell(t, store);
      store.gate = Completer<void>();
      await t.tap(find.byKey(const ValueKey('open-node-b')));
      await t.pump();
      await nav(t, 'Settings');
      store.gate!.complete();
      await t.pumpAndSettle();
      expect(find.text('Save settings'), findsOneWidget);
      expect(find.text('All nodes'), findsNothing);
      expect(store.value.selectedNodeId, 'b');
      await nav(t, 'Nodes');
      expect(find.text('DICOM nodes'), findsOneWidget);
    },
  );

  testWidgets(
    'external selection or removal returns to library and missing card focuses heading',
    (t) async {
      final container = await pumpShell(t, store);
      await t.tap(find.byKey(const ValueKey('open-node-a')));
      await t.pumpAndSettle();
      await container
          .read(configurationProvider.notifier)
          .changeNode(SelectNode(store.value.revision, 'b'));
      await t.pumpAndSettle();
      expect(find.text('DICOM nodes'), findsOneWidget);
      expect(find.text('All nodes'), findsNothing);
      await t.tap(find.byKey(const ValueKey('open-node-b')));
      await t.pumpAndSettle();
      await container
          .read(configurationProvider.notifier)
          .changeNode(RemoveNode(store.value.revision, 'b'));
      await t.pumpAndSettle();
      expect(find.text('DICOM nodes'), findsOneWidget);
      expect(FocusManager.instance.primaryFocus!.debugLabel, 'Nodes heading');
    },
  );

  testWidgets(
    'Back preserves filtered library scroll and excludes hidden cards from focus',
    (t) async {
      store.value = AppConfiguration(
        nodes: List.generate(
          20,
          (i) => PacsNode(
            id: '$i',
            label: 'Archive ${i.toString().padLeft(2, '0')}',
            calledAe: 'PACS_AET',
            host: '192.0.2.1',
            port: 104,
          ),
        ),
      );
      await pumpShell(t, store);
      await t.enterText(find.byKey(const ValueKey('node-search')), 'Archive');
      await press(t, 'List');
      final card = find.byKey(const ValueKey('open-node-8'));
      await t.ensureVisible(card);
      await t.pumpAndSettle();
      final library = find.byKey(const PageStorageKey('node-library'));
      final offset = t.widget<ListView>(library).controller!.offset;
      await t.tap(card);
      await t.pumpAndSettle();
      expect(find.text('Change node'), findsNothing);
      expect(find.widgetWithText(ListTile, 'Workbench'), findsNothing);
      final hidden = t.widget<InkWell>(
        find.byKey(const ValueKey('open-node-8'), skipOffstage: false),
      );
      expect(hidden.focusNode!.canRequestFocus, isFalse);
      await press(t, 'All nodes');
      expect(t.widget<ListView>(library).controller!.offset, offset);
      expect(t.widget<InkWell>(card).focusNode!.hasFocus, isTrue);
      t.widget<ListView>(library).controller!.jumpTo(0);
      await t.pumpAndSettle();
      expect(
        t
            .widget<TextField>(find.byKey(const ValueKey('node-search')))
            .controller!
            .text,
        'Archive',
      );
    },
  );

  testWidgets(
    'filtered-out newly saved node returns focus to library heading',
    (t) async {
      await pumpShell(t, store);
      await t.enterText(find.byKey(const ValueKey('node-search')), 'Alpha');
      await press(t, 'Add node');
      for (final entry in {
        'label': 'New node',
        'calledAe': 'PACS_AET',
        'host': '192.0.2.4',
      }.entries) {
        await t.enterText(find.byKey(ValueKey(entry.key)), entry.value);
      }
      await press(t, 'Save & open Workbench');
      await press(t, 'All nodes');
      expect(FocusManager.instance.primaryFocus!.debugLabel, 'Nodes heading');
      expect(find.text('Alpha archive'), findsOneWidget);
    },
  );

  testWidgets(
    'settings mismatch, latest run routing and stale run IDs retain provenance',
    (t) async {
      final gateway = Gateway();
      var sequence = 0;
      final runner = OperationRunner(
        configuration: store,
        gateway: gateway,
        store: Runs(),
        newId: () => 'run-${sequence++}',
        appVersion: 'test',
        libraryVersion: 'test',
      );
      final container = await pumpShell(t, store, runner: runner);
      await t.tap(find.byKey(const ValueKey('open-node-a')));
      await t.pumpAndSettle();
      await press(t, 'Run Echo');
      await container
          .read(configurationProvider.notifier)
          .save(
            AppConfiguration(
              nodes: store.value.nodes,
              selectedNodeId: 'a',
              revision: store.value.revision + 1,
              client: const ClientSettings(callingAe: 'CHANGED_AE'),
            ),
          );
      await t.pumpAndSettle();
      expect(find.textContaining('Current settings apply'), findsOneWidget);
      expect(gateway.calls.single.request.client.callingAe, 'DIMSE_DASH');
      gateway.calls.single.completer.complete(
        const EchoOutcome(EchoDisposition.success, status: 0),
      );
      await t.pumpAndSettle();
      await press(t, 'All nodes');
      expect(find.text('Latest Echo · Alpha archive'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('open-node-b')));
      await t.pumpAndSettle();
      final commands = store.commands.length;
      await press(t, 'View run');
      expect(store.commands.length, commands);
      expect(store.value.selectedNodeId, 'b');
      expect(
        find.textContaining('Frozen target: Alpha archive'),
        findsOneWidget,
      );
      expect(find.text('Run Echo'), findsNothing);
      expect(
        t.widget<ListTile>(find.widgetWithText(ListTile, 'Nodes')).selected,
        isTrue,
      );
      // A newer run may arrive through the runtime while an old run route is open.
      await runner.start(store.value.revision);
      await t.pumpAndSettle();
      expect(
        find.text('This run detail is no longer retained.'),
        findsOneWidget,
      );
      expect(find.textContaining('Frozen target:'), findsNothing);
      expect(find.text('Stop Echo'), findsNothing);
      await press(t, 'View run');
      expect(find.text('Echo run · Beta sandbox'), findsOneWidget);
      await press(t, 'Stop Echo');
      expect(gateway.calls.last.stopped, isTrue);
      gateway.calls.last.completer.complete(
        const EchoOutcome(EchoDisposition.stopped),
      );
      await t.pumpAndSettle();
      await press(t, 'Back');
      expect(find.text('All nodes'), findsOneWidget);
      expect(find.text('Beta sandbox'), findsOneWidget);
      expect(store.commands.length, commands);
    },
  );
  testWidgets(
    'removed offscreen return target reveals and focuses library heading',
    (t) async {
      store.value = AppConfiguration(
        nodes: List.generate(
          20,
          (i) => PacsNode(
            id: '$i',
            label: 'Archive $i',
            calledAe: 'PACS_AET',
            host: '192.0.2.1',
            port: 104,
          ),
        ),
      );
      final container = await pumpShell(t, store);
      await press(t, 'List');
      final card = find.byKey(const ValueKey('open-node-8'));
      await t.ensureVisible(card);
      await t.pumpAndSettle();
      await t.tap(card);
      await t.pumpAndSettle();
      await container
          .read(configurationProvider.notifier)
          .changeNode(RemoveNode(store.value.revision, '8'));
      await t.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus!.debugLabel, 'Nodes heading');
      expect(
        t
            .widget<ListView>(find.byKey(const PageStorageKey('node-library')))
            .controller!
            .offset,
        0,
      );
    },
  );
  testWidgets('a stale Stop callback cannot terminate a newer run', (t) async {
    final gateway = Gateway();
    var sequence = 0;
    final runner = OperationRunner(
      configuration: store,
      gateway: gateway,
      store: Runs(),
      newId: () => 'run-${sequence++}',
      appVersion: 'test',
      libraryVersion: 'test',
    );
    await pumpShell(t, store, runner: runner);
    await t.tap(find.byKey(const ValueKey('open-node-a')));
    await t.pumpAndSettle();
    await press(t, 'Run Echo');
    await press(t, 'All nodes');
    await press(t, 'View run');
    final staleStop = t
        .widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Stop Echo'),
        )
        .onPressed!;
    gateway.calls.single.completer.complete(
      const EchoOutcome(EchoDisposition.success, status: 0),
    );
    await t.pumpAndSettle();
    await runner.start(store.value.revision);
    staleStop();
    expect(gateway.calls.last.stopped, isFalse);
    gateway.calls.last.completer.complete(
      const EchoOutcome(EchoDisposition.success, status: 0),
    );
    await t.pumpAndSettle();
  });
}
