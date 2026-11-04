import 'dart:io';

import 'package:dimsedash/app/app.dart';
import 'package:dimsedash/app/app_runtime.dart';
import 'package:dimsedash/app/bootstrap.dart';
import 'package:dimsedash/bindings/configuration.dart';
import 'package:dimsedash/bindings/echo.dart';
import 'package:dimsedash/features/query/query.dart';
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'native real Find hierarchy, target review and restart clearing',
    (tester) async {
      tester.testTextInput.register();
      // Establish the native frame before asynchronous database/fixture setup.
      await tester.pumpWidget(const SizedBox.shrink());
      final dir = await Directory.systemTemp.createTemp(
        'dimsedash-native-query-',
      );
      AppRuntime? runtime;
      Future<void> launch() async {
        runtime = (await bootstrap(
          supportDirectory: dir,
        ) as Success<AppRuntime>).value;
        var initial = runtime!.initial;
        if (initial.node == null) {
          initial = (await runtime!.configStore.save(
            const AppConfiguration(
              node: PacsNode(
                id: '',
                label: 'Synthetic Query archive',
                calledAe: 'PACS_AET',
                host: '127.0.0.1',
                port: int.fromEnvironment('ORTHANC_PORT', defaultValue: 4242),
              ),
            ),
          ) as Success<AppConfiguration>).value;
        }
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              configStoreProvider.overrideWithValue(runtime!.configStore),
              initialConfigurationProvider.overrideWithValue(initial),
              operationRunnerProvider.overrideWithValue(runtime!.runner),
            ],
            child: DimseDashApp(runtime: runtime!),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('open-node-${initial.node!.id}')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Query'));
        await tester.pumpAndSettle();
      }

      Future<void> tap(Finder f) async {
        await tester.ensureVisible(f);
        await tester.pumpAndSettle();
        await tester.tap(f);
        await tester.pumpAndSettle();
      }

      QuerySession session() =>
          tester.widget<FindView>(find.byType(FindView)).session;
      Future<void> run() async {
        final before = runtime!.runner!.state.summary?.id;
        await tap(find.text('Run query'));
        await tester.runAsync(() async {
          final deadline = DateTime.now().add(const Duration(seconds: 15));
          while (runtime!.runner!.state.summary?.id == before ||
              runtime!.runner!.active) {
            if (DateTime.now().isAfter(deadline)) {
              throw StateError('Native Find did not complete');
            }
            await Future<void>.delayed(const Duration(milliseconds: 25));
          }
        });
        await tester.pumpAndSettle();
        expect(session().result!.outcome!.status, 0);
        expect(runtime!.runner!.state.historyAvailable, isTrue);
      }

      try {
        await launch();
        expect(
          find.textContaining('No query has run at this level'),
          findsOneWidget,
        );
        final patient = find.widgetWithText(TextField, 'Patient ID');
        await tap(patient);
        await tester.enterText(patient, 'SYNTH-1');
        await tester.pumpAndSettle();
        await tap(find.text('Collapse'));
        await run();
        expect(session().result!.rows.length, 1);
        await tap(find.text('Inspect'));
        expect(find.text('Inspect returned metadata'), findsOneWidget);
        await tap(find.text('Close'));
        await tap(find.text('Open series'));
        expect(session().result, isNull);
        await tap(find.text('Collapse'));
        await run();
        expect(session().result!.rows.length, 2);
        expect(
          session().result!.rows.any(
            (r) => r.value(0x00180015) == null || r.value(0x00180015)!.isEmpty,
          ),
          isTrue,
        );
        await tap(find.text('Open instances').first);
        await tap(find.text('Collapse'));
        await run();
        expect(session().result!.rows.length, 1);
        await tap(find.text('Select'));
        await tap(find.text('Review retrieve'));
        expect(find.text('Scope: this instance only'), findsOneWidget);
        expect(
          find.textContaining('Retrieval execution is not yet available'),
          findsOneWidget,
        );
        expect(find.text('Choose sample folder'), findsNothing);
        await tap(find.text('Back to results'));
        expect(session().selected, isNotNull);
        final last = runtime!.runner!.state.summary!.id;
        await tap(find.text('STUDY'));
        expect(session().result!.request.identifier.level, FindLevel.study);
        expect(find.text('View run'), findsOneWidget);
        await tap(find.text('View run'));
        expect(find.textContaining('Study Root IMAGE'), findsOneWidget);
        await tap(find.text('Back'));
        expect(session().result!.request.identifier.level, FindLevel.study);
        expect(runtime!.runner!.state.summary!.id, last);
        await tap(find.widgetWithText(ListTile, 'Settings'));
        await tap(find.text('View run'));
        expect(find.text('Query run'), findsOneWidget);
        expect(runtime!.runner!.state.summary!.id, last);
        await tester.pumpWidget(const SizedBox());
        await runtime!.close();
        await launch();
        expect(session().result, isNull);
        expect(session().draft.entry(FindKey.patientId).value, '');
        expect(runtime!.runner!.state.summary, isNull);
        expect(
          find.textContaining('No query has run at this level'),
          findsOneWidget,
        );
        expect(find.text('View sample'), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await runtime?.close();
        await dir.delete(recursive: true);
        tester.testTextInput.unregister();
      }
    },
  );
}
