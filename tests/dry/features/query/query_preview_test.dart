import 'package:dimsedash/features/query/query_preview.dart';
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter_test/flutter_test.dart';

const config = AppConfiguration(
  node: PacsNode(
    id: 'one',
    label: 'Example node',
    host: '192.0.2.1',
    port: 104,
    calledAe: 'PACS_AET',
  ),
);
void main() {
  late QueryPreviewController c;
  setUp(() => c = QueryPreviewController('one'));
  tearDown(() => c.dispose());
  test(
    'blank return, disabled omission, literal matching and frozen request',
    () {
      expect(c.result, isNull);
      expect(c.draft.identifier, contains('PatientID = <empty · return key>'));
      c.edit(PreviewKey.patientId, 'SYNTH-*');
      c.advanced(PreviewKey.patientId, enabled: false);
      expect(c.draft.identifier, isNot(contains('PatientID')));
      c.edit(PreviewKey.patientId, 'SYNTH-*');
      expect(c.run(config, echoActive: false), isNull);
      final request = c.result!.request;
      c.advanced(PreviewKey.patientId, purpose: IdentifierPurpose.returnKey);
      expect(c.draft.entry(PreviewKey.patientId).value, 'SYNTH-*');
      expect(c.draft.identifier, contains('PatientID = <empty · return key>'));
      expect(request.draft.identifier, contains('PatientID = SYNTH-*'));
      expect(c.dirty, isTrue);
      expect(() => request.draft.entries.clear(), throwsUnsupportedError);
      expect(() => c.result!.rows.clear(), throwsUnsupportedError);
    },
  );
  test('required matches, real calendar dates and open ranges validate', () {
    c.advanced(PreviewKey.patientName, purpose: IdentifierPurpose.match);
    expect(c.run(config, echoActive: false), contains('matching value'));
    c.advanced(PreviewKey.patientName, enabled: false);
    for (final value in [
      '20260230',
      '20261022-20261001',
      '202610',
      '-',
      '20261301',
    ]) {
      c.edit(PreviewKey.date, value);
      expect(c.draft.validation, isNotNull, reason: value);
    }
    for (final value in [
      '',
      '20260228',
      '20261001-',
      '-20261022',
      '20261001-20261022',
      '20240229',
    ]) {
      c.edit(PreviewKey.date, value);
      expect(c.draft.validation, isNull, reason: value);
    }
  });
  test(
    'fixed scenarios do not evaluate criteria; admission and node checks',
    () {
      c.edit(PreviewKey.patientId, 'NO-SUCH-SAMPLE');
      expect(c.run(config, echoActive: true), contains('Echo is active'));
      expect(c.result, isNull);
      expect(
        c.run(const AppConfiguration(), echoActive: false),
        contains('no longer selected'),
      );
      for (final scenario in PreviewScenario.values) {
        c.setScenario(scenario);
        expect(c.run(config, echoActive: false), isNull);
        expect(c.result!.rows.length, switch (scenario) {
          PreviewScenario.complete => 3,
          PreviewScenario.partial => 1,
          _ => 0,
        });
        expect(c.result!.scenario, scenario);
      }
    },
  );
  test(
    'hierarchy requires explicit preview and preserves frozen parent context',
    () {
      c.edit(PreviewKey.bodyPart, 'CHEST');
      expect(c.draft.identifier, isNot(contains('BodyPartExamined')));
      c.run(config, echoActive: false);
      final parent = c.result!;
      c.select(parent.rows.first);
      c.openChild(parent.rows.first);
      expect(c.selected, isNull);
      expect(c.result, isNull);
      expect(c.draft.level, QueryLevel.series);
      expect(c.draft.identifier, contains('BodyPartExamined = CHEST'));
      expect(c.draft.studyUid, parent.rows.first.studyUid);
      c.run(config, echoActive: false);
      final series = c.result!.rows.first;
      expect(series.patientName, parent.rows.first.patientName);
      c.openChild(series);
      expect(c.result, isNull);
      expect(c.draft.seriesUid, series.seriesUid);
      c.run(config, echoActive: false);
      c.select(c.result!.rows.first);
      final identifier = c.selected!.targetIdentifier(QueryLevel.image);
      expect(identifier, contains('StudyInstanceUID = ${series.studyUid}'));
      expect(identifier, contains('SeriesInstanceUID = ${series.seriesUid}'));
      expect(identifier, contains('SOPInstanceUID = ${c.selected!.sopUid}'));
      c.backTo(QueryLevel.study);
      expect(c.result, same(parent));
      expect(c.selected, isNull);
      c.openChild(parent.rows[1]);
      expect(c.result, isNull);
      expect(c.draft.studyUid, parent.rows[1].studyUid);
    },
  );
  test('missing UID is never a broad query or retrieval target', () {
    final row = PreviewMatch(
      description: 'Missing UID',
      patientId: 'SYNTH',
      patientName: 'DEMO',
      accession: 'DEMO',
      date: '2026-10-01',
      modality: 'CT',
    );
    for (final level in QueryLevel.values) {
      expect(row.canTarget(level), isFalse);
    }
    expect(
      QueryPreviewDraft(level: QueryLevel.series).validation,
      contains('Study Instance UID'),
    );
    expect(
      QueryPreviewDraft(level: QueryLevel.image, studyUid: '2.25.1').validation,
      contains('Series Instance UID'),
    );
    c.openChild(row);
    c.select(row);
    expect(c.draft.level, QueryLevel.study);
    expect(c.selected, isNull);
  });
  test('settings changes are separate from immutable executed settings', () {
    c.run(config, echoActive: false);
    final updated = AppConfiguration(
      node: config.node,
      client: const ClientSettings(callingAe: 'OTHER_AE'),
    );
    expect(c.result!.request.settingsDiffer(updated), isTrue);
    expect(c.result!.request.client.callingAe, 'DIMSE_DASH');
    expect(c.result!.request.settingsDiffer(config), isFalse);
  });
}
