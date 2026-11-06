import 'package:dimsedash/features/query/find_composer.dart';
import 'package:dimsedash/features/query/find_identifier_editor.dart';
import 'package:dimsedash/features/query/query_session.dart';
import 'package:dimsedash/ui/theme.dart';
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Finder value(String name) => find.widgetWithText(TextField, '$name value');
Finder purpose(String name) =>
    find.widgetWithText(DropdownButtonFormField<FindPurpose>, '$name purpose');
Finder include(String name) => find.byWidgetPredicate(
  (w) => w is Checkbox && w.semanticLabel == 'Include $name',
);
Future<void> tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<QuerySession> mount(
  WidgetTester t, {
  FindIdentifier? id,
  bool reveal = false,
  double width = 1200,
  double scale = 1,
  Brightness brightness = Brightness.light,
}) async {
  t.view.physicalSize = Size(width, 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final session = QuerySession('synthetic', null)
    ..setEditor(FindEditor.advanced);
  if (id != null) session.draft = id;
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
              builder: (_, _) => FindComposer(session: session, reveal: reveal),
            ),
          ),
        ),
      ),
    ),
  );
  return session;
}

void main() {
  testWidgets(
    'table states retain values without sending omitted or return values',
    (t) async {
      final c = await mount(t);
      expect(find.byType(Table), findsNWidgets(2));
      expect(find.text('Study description'), findsOneWidget);
      expect(find.text('Number of series'), findsOneWidget);
      expect(
        find.text('Not included in this study Identifier'),
        findsOneWidget,
      );
      expect(value('Patient ID'), findsNothing);
      await tap(t, purpose('Patient ID'));
      await tap(t, find.text('Match').last);
      expect(find.text('Enter a matching value.'), findsOneWidget);
      await t.enterText(value('Patient ID'), 'SYNTH-PRIVATE');
      await t.pumpAndSettle();
      expect(t.widget<TextField>(value('Patient ID')).obscureText, isTrue);
      await tap(t, purpose('Patient ID'));
      await tap(t, find.text('Return only').last);
      expect(value('Patient ID'), findsNothing);
      expect(find.text('SYNTH-PRIVATE'), findsNothing);
      expect(find.text('Saved draft value · not sent'), findsOneWidget);
      expect(
        c.draft.elements.singleWhere((e) => e.tag == 0x00100020).value,
        '',
      );
      await tap(t, include('Patient ID'));
      expect(c.draft.elements.any((e) => e.tag == 0x00100020), isFalse);
      expect(
        t
            .widget<DropdownButton<FindPurpose>>(
              find.descendant(
                of: purpose('Patient ID'),
                matching: find.byType(DropdownButton<FindPurpose>),
              ),
            )
            .onChanged,
        isNull,
      );
      await tap(t, include('Patient ID'));
      await tap(t, purpose('Patient ID'));
      await tap(t, find.text('Match').last);
      expect(
        t.widget<TextField>(value('Patient ID')).controller!.text,
        'SYNTH-PRIVATE',
      );
      expect(c.runId, isNull);
    },
  );

  testWidgets(
    'focus and caret survive notifications and responsive reparenting',
    (t) async {
      final c = await mount(t, reveal: true);
      c.edit(FindKey.patientId, 'SYNTH-1');
      await t.pumpAndSettle();
      await tap(t, value('Patient ID'));
      final input = t.widget<TextField>(value('Patient ID'));
      input.controller!.selection = const TextSelection.collapsed(offset: 3);
      c.setEditor(c.editor);
      await t.pump();
      expect(
        t.widget<TextField>(value('Patient ID')).controller,
        same(input.controller),
      );
      t.view.physicalSize = const Size(520, 900);
      await t.pumpAndSettle();
      expect(find.byType(Table), findsNothing);
      final resized = t.widget<TextField>(value('Patient ID'));
      expect(resized.controller, same(input.controller));
      expect(resized.controller!.selection.baseOffset, 3);
      expect(resized.focusNode!.hasFocus, isTrue);
      c.advanced(FindKey.patientId, purpose: FindPurpose.returnKey);
      await t.pumpAndSettle();
      expect(
        t
            .widget<DropdownButton<FindPurpose>>(
              find.descendant(
                of: purpose('Patient ID'),
                matching: find.byType(DropdownButton<FindPurpose>),
              ),
            )
            .focusNode!
            .hasFocus,
        isTrue,
      );
      c.advanced(FindKey.patientId, enabled: false);
      await t.pumpAndSettle();
      expect(
        t.widget<Checkbox>(include('Patient ID')).focusNode!.hasFocus,
        isTrue,
      );
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'required hierarchy, automatic fields and pending body part stay truthful',
    (t) async {
      final c = await mount(t);
      c.edit(FindKey.patientName, 'SYNTH^É');
      c.edit(FindKey.bodyPart, 'CHEST');
      await t.pumpAndSettle();
      expect(find.text('Specific character set'), findsOneWidget);
      expect(find.text('Automatic'), findsOneWidget);
      expect(c.draft.elements.any((e) => e.tag == 0x00180015), isFalse);
      c.draft = FindIdentifier(
        level: FindLevel.series,
        studyUid: '1.2.3',
        entries: c.draft.entries,
      );
      c.setEditor(c.editor);
      await t.pumpAndSettle();
      expect(find.text('Series modality'), findsOneWidget);
      expect(find.text('Next series query'), findsNothing);
      expect(find.text('1.2.3'), findsNothing);
      expect(
        c.draft.elements.singleWhere((e) => e.tag == 0x00180015).value,
        'CHEST',
      );
      c.draft = FindIdentifier(
        level: FindLevel.image,
        studyUid: '1.2.3',
        seriesUid: '1.2.3.4',
      );
      c.setEditor(c.editor);
      await t.pumpAndSettle();
      expect(find.text('SOP Instance UID'), findsOneWidget);
      expect(find.text('Instance number'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.text('1.2.3.4'), findsNothing);
    },
  );

  testWidgets(
    'invalid friendly dates survive tabs; advanced date edits synchronize',
    (t) async {
      final c = await mount(t, reveal: true);
      c.editDate('From', 'not-a-date');
      await t.pumpAndSettle();
      expect(
        find.text('Use a valid date in YYYY-MM-DD format.'),
        findsOneWidget,
      );
      await tap(t, find.text('Filters'));
      expect(c.dateText('From'), 'not-a-date');
      await tap(t, find.text('Advanced Identifier'));
      expect(c.dateText('From'), 'not-a-date');
      await tap(t, purpose('Study date'));
      await tap(t, find.text('Match').last);
      await t.enterText(value('Study date'), '20261101-20261105');
      await t.pumpAndSettle();
      expect(c.dateText('From'), '2026-11-01');
      expect(c.dateError, isNull);
      await tap(t, find.text('Resolved Identifier'));
      expect(find.textContaining('20261101-20261105'), findsOneWidget);
      expect(find.byType(FindIdentifierEditor), findsNothing);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'scaled narrow ${brightness.name} layout and keyboard traversal',
      (t) async {
        final c = await mount(
          t,
          width: 490,
          scale: 1.5,
          brightness: brightness,
        );
        c.edit(FindKey.patientName, 'A' * 64);
        await t.pumpAndSettle();
        expect(find.byType(Table), findsNothing);
        await tap(t, include('Patient ID'));
        await tap(t, include('Patient ID'));
        await t.sendKeyEvent(LogicalKeyboardKey.tab);
        await t.pumpAndSettle();
        expect(
          t
              .widget<DropdownButton<FindPurpose>>(
                find.descendant(
                  of: purpose('Patient ID'),
                  matching: find.byType(DropdownButton<FindPurpose>),
                ),
              )
              .focusNode!
              .hasFocus,
          isTrue,
        );
        await tap(t, find.text('Identifier editing help'));
        expect(c.identifierHelpExpanded, isTrue);
        await tap(t, find.text('Filters'));
        await tap(t, find.text('Advanced Identifier'));
        expect(
          find.textContaining('Match sends the literal value.'),
          findsOneWidget,
        );
        expect(t.takeException(), isNull);
      },
    );
  }
}
