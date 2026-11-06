import 'package:dimsedash/features/query/find_composer.dart';
import 'package:dimsedash/features/query/find_field.dart';
import 'package:dimsedash/features/query/query_session.dart';
import 'package:dimsedash/ui/theme.dart';
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Finder field(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is FindField && w.label == label),
  matching: find.byType(TextField),
);
Future<void> tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<QuerySession> mount(
  WidgetTester t, {
  double width = 1200,
  double scale = 1,
  Brightness brightness = Brightness.light,
}) async {
  t.view.physicalSize = Size(width, 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final session = QuerySession('synthetic', null);
  addTearDown(session.dispose);
  await t.pumpWidget(
    MaterialApp(
      theme: workbenchTheme(brightness),
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: SingleChildScrollView(
            child: ListenableBuilder(
              listenable: session,
              builder: (_, _) => FindComposer(session: session, reveal: true),
            ),
          ),
        ),
      ),
    ),
  );
  return session;
}

void main() {
  testWidgets('three logical columns, editable modality and advanced states', (
    t,
  ) async {
    final c = await mount(t);
    expect(
      t.getTopLeft(field('Patient ID')).dy,
      t.getTopLeft(field('Patient name')).dy,
    );
    expect(
      t.getTopLeft(field('Patient ID')).dy,
      t.getTopLeft(field('Accession number')).dy,
    );
    expect(find.byType(TabBar), findsOneWidget);
    await tap(t, find.byTooltip('Choose modality'));
    await tap(t, find.text('MR').last);
    expect(c.draft.entry(FindKey.modality).value, 'MR');
    await t.enterText(field('Modalities in study'), 'OT*');
    expect(c.draft.entry(FindKey.modality).value, 'OT*');
    c.advanced(FindKey.patientId, enabled: false);
    await t.pumpAndSettle();
    expect(find.textContaining('Omitted'), findsOneWidget);
    await t.enterText(field('Patient ID'), 'SYNTH-1');
    expect(c.draft.entry(FindKey.patientId).enabled, isTrue);
    await t.enterText(field('Body part (optional)'), 'CHEST');
    expect(c.draft.elements.any((e) => e.tag == 0x00180015), isFalse);
    await tap(t, find.text('Resolved Identifier'));
    expect(field('Patient ID'), findsNothing);
    expect(find.textContaining('SYNTH-1'), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(t.takeException(), isNull);
    await tap(t, find.text('Filters'));
    expect(
      t.widget<TextField>(field('Patient ID')).controller!.text,
      'SYNTH-1',
    );
  });
  for (final scale in [1.0, 1.5]) {
    testWidgets('filter input borders align at text scale $scale', (t) async {
      final c = await mount(t, width: 1200 * scale, scale: scale);
      Rect border(String label) {
        final decorator = find.descendant(
          of: field(label),
          matching: find.byType(EditableText),
        );
        final box = InputDecorator.containerOf(t.element(decorator))!;
        return box.localToGlobal(Offset.zero) & box.size;
      }

      void expectAligned() {
        final date = border('From');
        for (final label in [
          'Through',
          'Modalities in study',
          'Body part (optional)',
        ]) {
          expect(border(label).top, closeTo(date.top, 0.01));
          expect(border(label).bottom, closeTo(date.bottom, 0.01));
        }
      }

      expectAligned();
      c.editDate('From', 'invalid');
      c.advanced(FindKey.modality, enabled: false);
      await t.pumpAndSettle();
      expectAligned();
      expect(t.takeException(), isNull);
    });
  }
  testWidgets(
    'dates preserve ranges and calendar cancellation; no inferred endpoint',
    (t) async {
      final c = await mount(t);
      await t.enterText(field('From'), '2026-11-05');
      expect(c.draft.entry(FindKey.date).value, '20261105-');
      await t.enterText(field('Through'), '2026-11-04');
      await t.pumpAndSettle();
      expect(find.text('From must not be later than Through.'), findsOneWidget);
      await t.enterText(field('Through'), '2026-11-05');
      expect(c.draft.entry(FindKey.date).value, '20261105');
      await t.enterText(field('Through'), '2026-02-30');
      expect(c.dateError, isNotNull);
      expect(
        t.widget<TextField>(field('Through')).controller!.text,
        '2026-02-30',
      );
      await tap(t, find.byTooltip('Choose Through date'));
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(c.dateText('Through'), '2026-02-30');
      c.editDate('Through', '2026-11-06');
      await t.pumpAndSettle();
      await tap(t, find.byTooltip('Choose Through date'));
      final picker = t.widget<DatePickerDialog>(find.byType(DatePickerDialog));
      expect(picker.firstDate.year, 1);
      expect(picker.lastDate.year, 9999);
      expect(picker.initialDate, DateTime(2026, 11, 6));
      await tap(t, find.text('7').last);
      await tap(t, find.text('OK'));
      expect(c.dateText('Through'), '2026-11-07');
      await tap(t, find.text('Clear From date'));
      expect(c.draft.entry(FindKey.date).value, '-20261107');
      await tap(t, find.text('Clear Through date'));
      expect(c.draft.entry(FindKey.date).value, '');
      c.advanced(
        FindKey.date,
        value: '20260101-20260131',
        purpose: FindPurpose.match,
      );
      await t.pumpAndSettle();
      expect(t.widget<TextField>(field('From')).controller!.text, '2026-01-01');
      expect(
        t.widget<TextField>(field('Through')).controller!.text,
        '2026-01-31',
      );
    },
  );
  for (final brightness in Brightness.values) {
    testWidgets(
      'narrow scaled ${brightness.name} composer and help restoration',
      (t) async {
        final c = await mount(
          t,
          width: 480,
          scale: 1.5,
          brightness: brightness,
        );
        expect(
          t.getTopLeft(field('Patient name')).dy,
          greaterThan(t.getTopLeft(field('Patient ID')).dy),
        );
        await tap(t, find.text('Matching help'));
        expect(c.matchingHelpExpanded, isTrue);
        await tap(t, find.text('Resolved Identifier'));
        await tap(t, find.text('Filters'));
        expect(
          find.textContaining('Values are sent literally'),
          findsOneWidget,
        );
        await tap(t, find.byTooltip('Choose From date'));
        await t.sendKeyEvent(LogicalKeyboardKey.escape);
        await t.pumpAndSettle();
        expect(c.draft.entry(FindKey.date).value, '');
        expect(t.takeException(), isNull);
      },
    );
  }
}
