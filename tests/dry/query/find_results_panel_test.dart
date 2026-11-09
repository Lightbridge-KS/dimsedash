import 'package:dimsedash/features/query/find_results_panel.dart';
import 'package:dimsedash/ui/theme.dart';
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'find_test.dart' show row;
import 'find_view_test.dart' show node;

QueryResultContext result(
  List<QueryMatch> rows, {
  FindLevel level = FindLevel.study,
  FindDisposition disposition = FindDisposition.complete,
  bool active = false,
  bool cleanup = false,
}) => QueryResultContext(
  runId: 'run',
  request: ResolvedFindRequest(
    node: node,
    client: const ClientSettings(),
    configurationRevision: 0,
    identifier: FindIdentifier(level: level),
  ),
  rows: rows,
  received: rows.length,
  active: active,
  outcome: active
      ? null
      : FindOutcome(disposition: disposition, cleanupFailed: cleanup),
);

void main() {
  late FocusNode retrieve;
  setUp(() => retrieve = FocusNode());
  tearDown(() => retrieve.dispose());

  Future<void> mount(
    WidgetTester t, {
    QueryResultContext? data,
    QueryMatch? selected,
    int page = 0,
    bool reveal = false,
    double width = 1400,
    double scale = 1,
    Brightness brightness = Brightness.light,
    ValueChanged<QueryMatch>? onSelect,
    ValueChanged<int>? onPage,
    VoidCallback? onClear,
    String? problem,
  }) async {
    t.view.physicalSize = Size(width, 900);
    t.view.devicePixelRatio = 1;
    await t.pumpWidget(
      MaterialApp(
        theme: workbenchTheme(brightness),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: FindResultsPanel(
                level: data?.request.identifier.level ?? FindLevel.study,
                result: data,
                selected: selected,
                page: page,
                reveal: reveal,
                warnings: const [],
                actionProblem: (_) => problem,
                onSelect: onSelect ?? (_) {},
                onClear: onClear ?? () {},
                onPage: onPage ?? (_) {},
                onInspect: (_) {},
                onOpenChild: (_) {},
                onRetrieve: selected == null ? null : () {},
                retrieveFocus: retrieve,
              ),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets(
    'bounded local pages and selection footer do not confuse off-page target',
    (t) async {
      addTearDown(t.view.reset);
      final rows = List.generate(51, (i) => row(n: i + 1));
      var page = -1, cleared = false;
      await mount(
        t,
        data: result(rows),
        selected: rows.last,
        onPage: (p) => page = p,
        onClear: () => cleared = true,
      );
      expect(find.byType(Radio<QueryMatch>), findsNWidgets(50));
      expect(find.text('Selected target is on page 2'), findsOneWidget);
      await t.ensureVisible(find.text('Show selected'));
      await t.tap(find.text('Show selected'));
      await t.pumpAndSettle();
      expect(page, 1);
      await mount(
        t,
        data: result(rows),
        selected: rows.last,
        page: 1,
        onClear: () => cleared = true,
      );
      expect(find.byType(Radio<QueryMatch>), findsOneWidget);
      expect(find.text('Showing 51–51 of 51 retained results'), findsOneWidget);
      await t.ensureVisible(find.text('Clear selection'));
      await t.tap(find.text('Clear selection'));
      expect(cleared, isTrue);
      expect(find.textContaining('CANARY_PATIENT'), findsNothing);
    },
  );

  testWidgets(
    'focus survives streaming and table to stacked resize; row text does not select',
    (t) async {
      addTearDown(t.view.reset);
      final first = row();
      QueryMatch? selected;
      await mount(
        t,
        data: result([first], active: true),
        onSelect: (r) => selected = r,
      );
      expect(find.byKey(const ValueKey('results-table')), findsOneWidget);
      final button = t.widget<TextButton>(
        find.widgetWithText(TextButton, 'Inspect'),
      );
      // Use the focus owned by the Material button, as in keyboard navigation.
      final element = t.element(find.text('Inspect'));
      final focus = Focus.of(element);
      focus.requestFocus();
      await t.pump();
      final primary = FocusManager.instance.primaryFocus;
      await mount(
        t,
        data: result([first, row(n: 2)], active: true),
        width: 760,
        onSelect: (r) => selected = r,
      );
      expect(find.byKey(const ValueKey('results-stacked')), findsOneWidget);
      expect(FocusManager.instance.primaryFocus, same(primary));
      expect(button.onPressed, isNotNull);
      await t.tap(find.text('Study: Result 1 · Not returned').first);
      expect(selected, isNull);
      await t.tap(find.byType(Radio<QueryMatch>).first);
      expect(selected, same(first));
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('masked lookalike rows retain visible result identity', (
    t,
  ) async {
    addTearDown(t.view.reset);
    final rows = [row(n: 1), row(n: 2)];
    for (final width in [1400.0, 760.0]) {
      await mount(t, data: result(rows), selected: rows.last, width: width);
      expect(find.text('Study: Result 1 · Not returned'), findsOneWidget);
      expect(find.text('Study: Result 2 · Not returned'), findsOneWidget);
      expect(
        find.text('Selected study · Result 2 · Not returned'),
        findsOneWidget,
      );
      expect(find.textContaining('CANARY_PATIENT'), findsNothing);
    }
  });

  testWidgets('honest empty states and cleanup warning', (t) async {
    addTearDown(t.view.reset);
    await mount(t);
    expect(find.textContaining('No query has run'), findsOneWidget);
    await mount(t, data: result([], active: true));
    expect(find.text('Waiting for responses…'), findsOneWidget);
    await mount(t, data: result([]));
    expect(find.text('No matches returned.'), findsOneWidget);
    for (final disposition in FindDisposition.values.where(
      (d) => d != FindDisposition.complete,
    )) {
      await mount(t, data: result([], disposition: disposition));
      expect(find.text('No matches returned.'), findsNothing);
      expect(
        find.textContaining('Query ended without retained results'),
        findsOneWidget,
      );
    }
    await mount(t, data: result([row()], cleanup: true));
    expect(find.text('Complete'), findsOneWidget);
    expect(find.textContaining('Cleanup failed'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    for (final level in FindLevel.values) {
      testWidgets(
        '${brightness.name} ${level.name} narrow scaled metadata and blocked actions',
        (t) async {
          addTearDown(t.view.reset);
          final r = QueryMatch(
            ordinal: 1,
            encodedBytes: 0,
            attributes: [
              QueryAttribute(
                tag: 0x00080020,
                keyword: 'StudyDate',
                vr: 'DA',
                values: ['20240229'],
              ),
              QueryAttribute(
                tag: 0x00081030,
                keyword: 'StudyDescription',
                vr: 'LO',
                values: ['Long description ' * 30],
              ),
              QueryAttribute(
                tag: 0x00080018,
                keyword: 'SOPInstanceUID',
                vr: 'UI',
                values: ['1.' * 100],
              ),
              QueryAttribute(
                tag: 0x00100020,
                keyword: 'PatientID',
                vr: 'LO',
                values: [],
              ),
            ],
          );
          await mount(
            t,
            data: result([r], level: level),
            width: 760,
            scale: 1.5,
            brightness: brightness,
            reveal: true,
            problem: 'Required UID missing or invalid.',
          );
          expect(find.byKey(const ValueKey('results-stacked')), findsOneWidget);
          expect(
            t.widget<Radio<QueryMatch>>(find.byType(Radio<QueryMatch>)).enabled,
            isFalse,
          );
          expect(find.text('Required UID missing or invalid.'), findsOneWidget);
          if (level == FindLevel.study) {
            expect(find.text('Study date: 2024-02-29'), findsOneWidget);
            expect(find.text('ID: Empty'), findsOneWidget);
          }
          expect(t.takeException(), isNull);
        },
      );
    }
  }
}
