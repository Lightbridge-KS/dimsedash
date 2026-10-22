import 'package:dimsedash/app/shell.dart';
import 'package:dimsedash/bindings/configuration.dart';
import 'package:dimsedash/bindings/echo.dart';
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../operations/echo_test.dart' show Config, Runs, Gateway;

void main() {
  test(
    'provider rebuild retains terminal evidence and never cancels execution',
    () async {
      final config = Config();
      final gateway = Gateway();
      final runner = OperationRunner(
        configuration: config,
        gateway: gateway,
        store: Runs(),
        newId: () => 'rebuild',
        appVersion: 'test',
        libraryVersion: 'test',
      );
      final container = ProviderContainer(
        overrides: [operationRunnerProvider.overrideWithValue(runner)],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(echoStateProvider, (_, _) {});
      addTearDown(subscription.close);
      final handle = (await runner.start(1) as Success<RunHandle>).value;
      container.invalidate(echoStateProvider);
      gateway.calls.single.completer.complete(
        const EchoOutcome(EchoDisposition.success, status: 0),
      );
      await handle.done;
      expect(container.read(echoStateProvider).summary!.outcome!.status, 0);
      expect(gateway.calls.single.stopped, isFalse);
    },
  );
  for (final brightness in Brightness.values) {
    testWidgets(
      'Echo controls and evidence remain usable in ${brightness.name}',
      (tester) async {
        tester.view.physicalSize = const Size(1100, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final config = Config();
        final gateway = Gateway();
        final runs = Runs();
        final runner = OperationRunner(
          configuration: config,
          gateway: gateway,
          store: runs,
          newId: () => 'test',
          appVersion: 'test',
          libraryVersion: 'test',
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              initialConfigurationProvider.overrideWithValue(config.value),
              configStoreProvider.overrideWithValue(config),
              operationRunnerProvider.overrideWithValue(runner),
            ],
            child: MaterialApp(
              theme: ThemeData(brightness: brightness),
              home: const WorkbenchShell(),
            ),
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(FocusManager.instance.primaryFocus, isNotNull);
        await tester.tap(find.byKey(const ValueKey('node-menu-node')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Duplicate'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(find.byKey(const ValueKey('label')))
              .controller!
              .text,
          'CANARY_LABEL copy',
        );
        await tester.ensureVisible(find.text('Discard'));
        await tester.tap(find.text('Discard'));
        await tester.pumpAndSettle();
        expect(config.value.node!.id, 'node');
        expect(gateway.calls, isEmpty);
        await tester.tap(find.byKey(const ValueKey('node-menu-node')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Remove node'));
        await tester.pumpAndSettle();
        expect(find.text('Remove CANARY_LABEL?'), findsOneWidget);
        await tester.tap(find.text('Keep node'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('open-node-node')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Run Echo'));
        await tester.pumpAndSettle();
        expect(find.text('Echo running'), findsOneWidget);
        await tester.tap(find.text('Query'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Echo running ·'), findsOneWidget);
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('run-query-preview')),
              )
              .onPressed,
          isNull,
        );
        expect(gateway.calls, hasLength(1));
        expect(gateway.calls.single.stopped, isFalse);
        await tester.tap(find.text('View run'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Back'));
        await tester.pumpAndSettle();
        expect(
          find.text('UI preview · synthetic data · no network'),
          findsOneWidget,
        );

        await tester.tap(find.widgetWithText(ListTile, 'Settings'));
        await tester.pumpAndSettle();
        expect(gateway.calls.single.stopped, isFalse);
        final field = find.byKey(const ValueKey('dimse'));
        await tester.ensureVisible(field);
        await tester.enterText(field, '1.5');
        await tester.ensureVisible(find.text('Save settings'));
        await tester.tap(find.text('Save settings'));
        await tester.pumpAndSettle();
        expect(find.text('Use whole seconds from 1 to 600.'), findsOneWidget);
        await tester.tap(find.text('View run'));
        await tester.pumpAndSettle();
        gateway.calls.single.observe(
          EchoObservation(
            sequence: 1,
            elapsedMicros: 15,
            kind: EvidenceKind.dimse,
            command: 0x8030,
            status: 0,
          ),
        );
        gateway.calls.single.completer.complete(
          const EchoOutcome(EchoDisposition.success, status: 0),
        );
        await tester.pumpAndSettle();
        for (final name in ['Timeline', 'Negotiation', 'Trace', 'Summary']) {
          await tester.tap(find.text(name));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        expect(find.textContaining('Echo status: 0x0000'), findsOneWidget);
        final writes = runs.summaries.length;
        final eventWrites = runs.events.length;
        final runId = runner.state.summary!.id;
        await tester.tap(find.widgetWithText(ListTile, 'Nodes'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('open-node-node')));
        await tester.pumpAndSettle();
        // Query remains the last operation selected for this node.
        expect(
          find.text('UI preview · synthetic data · no network'),
          findsOneWidget,
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('run-query-preview')),
        );
        await tester.tap(find.byKey(const ValueKey('run-query-preview')));
        await tester.pumpAndSettle();
        expect(find.textContaining('3 retained rows'), findsOneWidget);
        Future<void> tapVisible(Finder finder) async {
          await tester.ensureVisible(finder);
          await tester.pumpAndSettle();
          await tester.tap(finder);
          await tester.pumpAndSettle();
        }

        await tapVisible(find.text('Select').first);
        await tapVisible(find.text('Review retrieve'));
        await tapVisible(find.text('Choose sample folder'));
        await tapVisible(find.byKey(const ValueKey('show-retrieve-sample')));
        expect(
          find.textContaining('Synthetic final status 0x0000'),
          findsOneWidget,
        );
        await tapVisible(find.text('View run'));
        expect(find.textContaining('Echo status: 0x0000'), findsOneWidget);
        await tapVisible(find.text('Back'));
        expect(find.text('Back to results'), findsOneWidget);

        expect(gateway.calls, hasLength(1));
        expect(runs.summaries.length, writes);
        expect(runs.events.length, eventWrites);
        expect(runner.state.summary!.id, runId);
      },
    );
  }
}
