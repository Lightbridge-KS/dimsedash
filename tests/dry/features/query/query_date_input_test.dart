import 'package:dimsedash/features/query/query_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/query_workbench_harness.dart';

void main() {
  Future<void> enter(WidgetTester tester, String label, String value) async {
    final field = find.widgetWithText(TextFormField, label);
    await tester.ensureVisible(field);
    await tester.enterText(field, value);
    await tester.pumpAndSettle();
  }

  FilledButton runButton(WidgetTester tester) => tester.widget<FilledButton>(
    find.byKey(const ValueKey('run-query-preview')),
  );
  testWidgets('friendly dates reject malformed separators in either bound', (
    tester,
  ) async {
    await launch(tester);
    final c = controller(tester);
    for (final label in ['Study date From', 'Study date Through']) {
      for (final value in [
        '2026--10--01',
        '2026-1-001',
        '20261001-',
        '-20261001',
        '20261001-20261022',
      ]) {
        await enter(tester, 'Study date From', '');
        await enter(tester, 'Study date Through', '');
        await enter(tester, label, value);
        expect(c.draft.validation, isNotNull, reason: '$label: $value');
        expect(runButton(tester).onPressed, isNull, reason: '$label: $value');
      }
    }
  });
  testWidgets(
    'editing one date bound cannot repair malformed text in the other',
    (tester) async {
      final (store, _) = await launch(tester);
      final c = controller(tester);
      await enter(tester, 'Study date From', '2026--10--01');
      await enter(tester, 'Study date Through', '2026-10-22');
      expect(c.draft.validation, isNotNull);
      expect(c.draft.entry(PreviewKey.date).value, contains('2026--10--01'));
      expect(runButton(tester).onPressed, isNull);
      await enter(tester, 'Study date From', '2026-10-01');
      expect(c.draft.validation, isNull);
      expect(c.draft.entry(PreviewKey.date).value, '20261001-20261022');
      await enter(tester, 'Study date Through', '2026--10--22');
      await enter(tester, 'Study date From', '2026-10-02');
      expect(c.draft.validation, isNotNull);
      expect(runButton(tester).onPressed, isNull);
      // Navigation must not turn an invalid literal into a valid range fragment.
      await tap(tester, find.text('Advanced Identifier'));
      await tap(tester, find.text('Filters'));
      expect(c.draft.validation, isNotNull);
      expect(runButton(tester).onPressed, isNull);
      // Repair both fields after returning from the shared advanced draft.
      await enter(tester, 'Study date From', '2026-10-02');
      await enter(tester, 'Study date Through', '2026-10-22');
      expect(c.draft.validation, isNull);
      expect(c.run(store.value, echoActive: false), isNull);
      expect(
        c.result!.request.draft.identifier,
        contains('StudyDate = 20261002-20261022'),
      );
    },
  );
  testWidgets(
    'friendly dates preserve compact input, calendar checks and open bounds',
    (tester) async {
      await launch(tester);
      final c = controller(tester);
      await enter(tester, 'Study date From', '20240229');
      expect(c.draft.entry(PreviewKey.date).value, '20240229-');
      expect(c.draft.validation, isNull);
      await enter(tester, 'Study date Through', '2024-03-01');
      expect(c.draft.entry(PreviewKey.date).value, '20240229-20240301');
      await enter(tester, 'Study date From', '2024-02-30');
      expect(c.draft.validation, isNotNull);
      await enter(tester, 'Study date From', '2024-03-02');
      expect(c.draft.validation, contains('From must not be later'));
      await enter(tester, 'Study date From', '');
      expect(c.draft.entry(PreviewKey.date).value, '-20240301');
      expect(c.draft.validation, isNull);
      await enter(tester, 'Study date Through', '');
      expect(c.draft.entry(PreviewKey.date).value, isEmpty);
      expect(c.draft.validation, isNull);
      c.advanced(
        PreviewKey.date,
        value: '20261001-',
        purpose: IdentifierPurpose.match,
      );
      c.setEditor(QueryEditor.advanced);
      await tester.pumpAndSettle();
      await tap(tester, find.text('Filters'));
      expect(find.widgetWithText(TextFormField, '2026-10-01'), findsOneWidget);
      expect(c.draft.entry(PreviewKey.date).value, '20261001-');
    },
  );
  testWidgets('friendly date edits use the latest externally updated draft', (
    tester,
  ) async {
    await launch(tester);
    final c = controller(tester);
    c.edit(PreviewKey.date, '20261001-20261022');
    await tester.pumpAndSettle();
    await enter(tester, 'Study date From', '2026-10-02');
    expect(c.draft.entry(PreviewKey.date).value, '20261002-20261022');
    c.advanced(PreviewKey.date, value: '20261005-20261020');
    await tester.pumpAndSettle();
    await enter(tester, 'Study date Through', '2026-10-21');
    expect(c.draft.entry(PreviewKey.date).value, '20261005-20261021');
    c.edit(PreviewKey.date, '');
    await tester.pumpAndSettle();
    await enter(tester, 'Study date Through', '2026-10-22');
    expect(c.draft.entry(PreviewKey.date).value, '-20261022');
  });
}
