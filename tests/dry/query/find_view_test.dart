import 'package:dimsedash/app/shell.dart';
import 'package:dimsedash/bindings/configuration.dart';
import 'package:dimsedash/bindings/echo.dart';
import 'package:dimsedash/features/query/query.dart';
import 'package:dimsedash/ui/theme.dart';
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/node_config_store.dart';
import '../operations/echo_test.dart' show Runs;
import 'find_test.dart' show FindFake, row;

const node = PacsNode(
  id: 'one',
  label: 'Synthetic archive',
  host: '192.0.2.1',
  port: 104,
  calledAe: 'PACS_AET',
);
const other = PacsNode(
  id: 'two',
  label: 'Other synthetic archive',
  host: '192.0.2.2',
  port: 104,
  calledAe: 'PACS_AET',
);
Future<void> tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

QuerySession session(WidgetTester t) =>
    t.widget<FindView>(find.byType(FindView)).session;

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'real Query hierarchy, masking, focus and scaled ${brightness.name} layout',
      (t) async {
        t.view.physicalSize = const Size(760, 600);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final config = NodeConfigStore(
          const AppConfiguration(nodes: [node, other], selectedNodeId: 'one'),
        );
        final gateway = FindFake(), runs = Runs();
        var n = 0;
        final runner = OperationRunner(
          configuration: config,
          gateway: gateway,
          store: runs,
          newId: () => '${++n}',
          appVersion: 'test',
          libraryVersion: 'test',
        );
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              configStoreProvider.overrideWithValue(config),
              initialConfigurationProvider.overrideWithValue(config.value),
              operationRunnerProvider.overrideWithValue(runner),
            ],
            child: MaterialApp(
              theme: workbenchTheme(brightness),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.5)),
                child: child!,
              ),
              home: const WorkbenchShell(),
            ),
          ),
        );
        await tap(t, find.byKey(const ValueKey('open-node-one')));
        await tap(t, find.text('Query'));
        final c = session(t);
        expect(find.text('Change node'), findsNothing);
        expect(find.textContaining('synthetic data'), findsNothing);
        expect(gateway.finds, isEmpty);
        await tap(t, find.text('Advanced Identifier'));
        expect(t.takeException(), isNull);
        await tap(t, find.text('Resolved Identifier'));
        expect(t.takeException(), isNull);
        await tap(t, find.text('Filters'));
        c.setCollapsed(true);
        await t.pumpAndSettle();
        await tap(t, find.text('Run query'));
        gateway.finds.last.match(row());
        gateway.finds.last.finish();
        await t.pumpAndSettle();
        expect(find.text('CANARY_PATIENT'), findsNothing);
        expect(c.result!.rows, hasLength(1));
        expect(c.collapsed, isTrue);
        await tap(t, find.text('Inspect'));
        expect(c.selected, isNull);
        expect(find.text('Inspect returned metadata'), findsOneWidget);
        await t.sendKeyEvent(LogicalKeyboardKey.escape);
        await t.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        await tap(t, find.text('Open series'));
        expect(c.result, isNull);
        expect(find.text('Latest Query · Synthetic archive'), findsOneWidget);
        expect(gateway.finds, hasLength(1));
        expect(c.draft.entry(FindKey.bodyPart).value, '');
        c.setCollapsed(true);
        await t.pumpAndSettle();
        await tap(t, find.text('Run query'));
        gateway.finds.last.match(row(series: '2.25.2'));
        gateway.finds.last.finish();
        await t.pumpAndSettle();
        await tap(t, find.text('Open instances'));
        c.setCollapsed(true);
        await t.pumpAndSettle();
        await tap(t, find.text('Run query'));
        gateway.finds.last.match(row(series: '2.25.2', sop: '2.25.3'));
        gateway.finds.last.finish();
        await t.pumpAndSettle();
        await tap(t, find.byType(Radio<QueryMatch>).first);
        await tap(t, find.text('Review retrieve'));
        expect(find.text('Scope: this instance only'), findsOneWidget);
        expect(
          find.textContaining('Retrieval execution is not yet available'),
          findsOneWidget,
        );
        expect(find.textContaining('2.25.3'), findsNothing);
        expect(find.text('Choose sample folder'), findsNothing);
        await tap(t, find.text('Back to results'));
        expect(session(t), same(c));
        expect(
          t
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Review retrieve'),
              )
              .focusNode!
              .hasFocus,
          isTrue,
        );
        await tap(t, find.widgetWithText(TextButton, 'Studies'));
        expect(c.result!.rows, hasLength(1));
        expect(find.text('Latest Query · Synthetic archive'), findsOneWidget);
        final parentRunId = c.runId;
        await tap(t, find.text('View run'));
        expect(find.textContaining('Study Root IMAGE'), findsOneWidget);
        await tap(t, find.text('Back'));
        expect(session(t).runId, parentRunId);
        expect(gateway.finds.length, 3);
        await tap(t, find.text('All nodes'));
        await tap(t, find.byKey(const ValueKey('open-node-one')));
        expect(session(t), same(c));
        final status = find.byKey(const ValueKey('receiver-status'));
        expect(
          find.ancestor(of: status, matching: find.byType(OutlinedButton)),
          findsNothing,
        );
        expect(t.takeException(), isNull);
        expect(config.commands, isEmpty);
        expect(gateway.finds.length, 3);
        await t.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets(
    'active Find survives node selection and evidence navigation; obsolete routes do not switch runs',
    (t) async {
      t.view.physicalSize = const Size(1200, 1000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final config = NodeConfigStore(
        const AppConfiguration(nodes: [node, other], selectedNodeId: 'one'),
      );
      final gateway = FindFake();
      var id = 0;
      final runner = OperationRunner(
        configuration: config,
        gateway: gateway,
        store: Runs(),
        newId: () => '${++id}',
        appVersion: 'test',
        libraryVersion: 'test',
      );
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            configStoreProvider.overrideWithValue(config),
            initialConfigurationProvider.overrideWithValue(config.value),
            operationRunnerProvider.overrideWithValue(runner),
          ],
          child: MaterialApp(home: const WorkbenchShell()),
        ),
      );
      await tap(t, find.byKey(const ValueKey('open-node-one')));
      await tap(t, find.text('Query'));
      final first = session(t);
      first.setCollapsed(true);
      await t.pumpAndSettle();
      await tap(t, find.text('Run query'));
      final run = runner.state.summary!.id;
      gateway.finds.single.match(row());
      await t.pump(const Duration(milliseconds: 60));
      await tap(t, find.text('All nodes'));
      await tap(t, find.byKey(const ValueKey('open-node-two')));
      expect(gateway.finds.single.cancelled, isFalse);
      expect(runner.active, isTrue);
      expect(
        t
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Run Echo'))
            .onPressed,
        isNull,
      );
      final writes = config.commands.length;
      await tap(t, find.text('View run'));
      expect(config.commands.length, writes);
      expect(find.text('Query run'), findsOneWidget);
      expect(
        find.textContaining('Frozen destination: Synthetic archive'),
        findsOneWidget,
      );
      gateway.finds.single.finish();
      await t.pumpAndSettle();
      expect(find.textContaining('0x0000'), findsWidgets);
      expect(find.text('Run query'), findsNothing);
      final h = (await runner.startFind(
        config.value.revision,
        FindIdentifier(),
      ) as Success<RunHandle>).value;
      gateway.finds.last.finish();
      await t.pumpAndSettle();
      await h.done;
      expect(h.id, isNot(run));
      expect(
        find.text('This run detail is no longer retained.'),
        findsOneWidget,
      );
      await tap(t, find.text('Back'));
      await tap(t, find.text('Query'));
      expect(session(t), isNot(same(first)));
      expect(session(t).result, isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
}
