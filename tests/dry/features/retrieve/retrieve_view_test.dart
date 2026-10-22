import 'package:dimsedash/bindings/configuration.dart';
import 'package:dimsedash/features/retrieve/retrieve_preview.dart';
import 'package:dimsedash/features/retrieve/retrieve_view.dart';
import 'package:dimsedash/features/query/query_preview.dart';
import 'package:dimsedash/features/query/query_view.dart';
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../query/query_view_test.dart' show launch, controller, tap;

RetrievePreviewController retrieve(WidgetTester tester) => tester
    .widget<RetrievePreviewView>(find.byType(RetrievePreviewView))
    .controller;
Future<void> enter(WidgetTester tester) async {
  await tap(tester, find.byKey(const ValueKey('run-query-preview')));
  await tap(tester, find.text('Select').first);
  await tap(tester, find.text('Review retrieve'));
}

void main() {
  testWidgets('review and run preserve Query state and focus, without writes', (
    tester,
  ) async {
    final (store, _) = await launch(tester);
    final query = controller(tester);
    query.edit(PreviewKey.patientId, 'FIXTURE');
    query.setCollapsed(true);
    await tester.pumpAndSettle();
    await enter(tester);
    final c = retrieve(tester);
    final offset = query.scrollOffset;
    expect(find.text('Query'), findsNothing);
    expect(
      find.text('UI preview · synthetic data · no network or files'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('show-retrieve-sample')),
          )
          .onPressed,
      isNull,
    );
    await tap(tester, find.text('Choose sample folder'));
    await tap(tester, find.byKey(const ValueKey('show-retrieve-sample')));
    expect(
      find.textContaining('Synthetic final status 0x0000'),
      findsOneWidget,
    );
    expect(c.latest!.receipts.length, 3);
    await tap(tester, find.text('Inspect headers 1'));
    expect(find.textContaining('Headers hidden'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(FocusManager.instance.primaryFocus?.context, isNotNull);
    await tap(tester, find.text('Back to results'));
    expect(controller(tester), same(query));
    expect(query.selected, isNotNull);
    expect(query.collapsed, isTrue);
    expect(query.scrollOffset, closeTo(offset, 1));
    final button = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Review retrieve'),
    );
    expect(button.focusNode!.hasFocus, isTrue);
    expect(store.commands, isEmpty);
    expect(store.value.revision, 0);
    await tap(tester, find.text('View sample'));
    expect(retrieve(tester), same(c));
  });
  testWidgets(
    'MOVE readiness, UID mask/edit, settings mismatch and node deletion',
    (tester) async {
      final (store, container) = await launch(tester);
      await enter(tester);
      final c = retrieve(tester);
      await tap(tester, find.text('C-MOVE'));
      await tap(tester, find.text('Choose sample folder'));
      expect(c.receiverReady(store.value), isFalse);
      await tap(tester, find.text('Preview receiver started'));
      expect(c.receiverReady(store.value), isTrue);
      expect(find.text('Stopped'), findsOneWidget);
      await tap(tester, find.text('Advanced Identifier'));
      final uid = find.widgetWithText(TextFormField, 'StudyInstanceUID · UI');
      expect(tester.widget<TextFormField>(uid).enabled, isFalse);
      await tap(tester, find.text('Reveal values'));
      await tester.ensureVisible(uid);
      await tester.enterText(uid, '2.3.4');
      await tester.pumpAndSettle();
      expect(find.textContaining('Edited identifier'), findsOneWidget);
      await tap(tester, find.text('Reset to selected target'));
      expect(c.draft.edited, isFalse);
      await tap(tester, find.byKey(const ValueKey('show-retrieve-sample')));
      final frozen = c.latest!;
      await container
          .read(configurationProvider.notifier)
          .saveClientSettings(
            const ClientSettings(callingAe: 'CHANGED'),
            expectedRevision: store.value.revision,
          );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Current connection settings differ'),
        findsOneWidget,
      );
      expect(frozen.request.client.callingAe, 'DIMSE_DASH');
      await tap(tester, find.text('Review new retrieve'));
      expect(c.receiverReady(store.value), isFalse);
      expect(
        find.textContaining('Connection settings changed since'),
        findsOneWidget,
      );
      await container
          .read(configurationProvider.notifier)
          .changeNode(RemoveNode(store.value.revision, 'one'));
      await tester.pumpAndSettle();
      expect(find.text('DICOM nodes'), findsOneWidget);
      expect(find.text('View sample'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'same node survives Settings and library, different node clears; stale run route is honest',
    (tester) async {
      final (store, _) = await launch(tester);
      await enter(tester);
      final c = retrieve(tester);
      c.chooseFolder(true);
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const ValueKey('show-retrieve-sample')));
      final originalId = c.latest!.id;
      c.showSample(store.value, echoActive: false);
      await tester.pumpAndSettle();
      expect(c.latest!.id, isNot(originalId));
      expect(
        find.text('This sample detail is no longer retained.'),
        findsOneWidget,
      );
      await tap(tester, find.widgetWithText(ListTile, 'Settings'));
      await tap(tester, find.widgetWithText(ListTile, 'Nodes'));
      await tap(tester, find.byKey(const ValueKey('open-node-one')));
      await tap(tester, find.text('View sample'));
      expect(retrieve(tester), same(c));
      expect(find.textContaining('Synthetic final status'), findsOneWidget);
      await tap(tester, find.widgetWithText(ListTile, 'Nodes'));
      await tap(tester, find.byKey(const ValueKey('open-node-two')));
      expect(find.text('View sample'), findsNothing);
      await tap(tester, find.text('Query'));
      expect(controller(tester).result, isNull);
    },
  );
  for (final brightness in Brightness.values) {
    testWidgets(
      '760x600 at 150% ${brightness.name}, masked inspection and keyboard',
      (tester) async {
        await launch(
          tester,
          brightness: brightness,
          size: const Size(760, 600),
          scale: 1.5,
        );
        final query = controller(tester);
        query.setCollapsed(true);
        await tester.pumpAndSettle();
        await enter(tester);
        await tap(tester, find.text('C-MOVE'));
        await tap(tester, find.text('Choose sample folder'));
        await tap(tester, find.text('Preview receiver started'));
        await tap(tester, find.text('Resolved request'));
        expect(tester.takeException(), isNull);
        await tap(tester, find.byKey(const ValueKey('show-retrieve-sample')));
        await tap(tester, find.text('Thumbnail 2'));
        expect(find.textContaining('Unsupported preview'), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        await tap(tester, find.text('Thumbnail 1'));
        expect(find.text('Thumbnail placeholder hidden'), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        expect(tester.takeException(), isNull);
        expect(find.byType(QueryPreviewView), findsNothing);
        final status = find.byKey(const ValueKey('receiver-status'));
        expect(
          tester.getTopLeft(status).dx,
          tester.getTopLeft(find.text('LOCAL RECEIVER')).dx,
        );
      },
    );
  }
}
