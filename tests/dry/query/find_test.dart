import 'dart:async';
import 'dart:convert';

import 'package:dartdicom/dartdicom.dart' as dicom;
import 'package:dimsedash/adapters/dicom/find_gateway.dart';
import 'package:dimsedash/features/query/query.dart';
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../operations/echo_test.dart' show Config, Runs, Gateway;

class FindFake extends Gateway implements FindGateway {
  final finds = <FindCall>[];
  @override
  String? validateFind(FindIdentifier id) => validateFindEncoding(id);
  @override
  FindGatewayRun find(
    String id,
    ResolvedFindRequest request,
    void Function(EchoObservation) observe,
    void Function(QueryMatch) match,
  ) {
    final call = FindCall(request, observe, match);
    finds.add(call);
    return call;
  }
}

class FindCall implements FindGatewayRun {
  FindCall(this.request, this.observe, this.match);
  final ResolvedFindRequest request;
  final void Function(EchoObservation) observe;
  final void Function(QueryMatch) match;
  final completer = Completer<FindOutcome>();
  bool cancelled = false, forced = false;
  @override
  Future<FindOutcome> get done => completer.future;
  @override
  void cancel() {
    cancelled = true;
  }

  @override
  void forceClose() {
    forced = true;
    if (!completer.isCompleted) finish(failure: FindFailure.transport);
  }

  void finish({
    int status = 0,
    int responses = 1,
    FindFailure? failure,
    bool cleanup = false,
  }) => completer.complete(
    FindOutcome(
      disposition: failure == null
          ? FindDisposition.complete
          : FindDisposition.failed,
      status: status,
      failure: failure,
      cancelRequested: cancelled,
      responses: responses,
      cleanupFailed: cleanup,
    ),
  );
}

QueryMatch row({
  int n = 1,
  String? study = '2.25.1',
  String? series,
  String? sop,
  int bytes = 100,
  String patient = 'CANARY_PATIENT',
}) => QueryMatch(
  ordinal: n,
  encodedBytes: bytes,
  attributes: [
    if (study != null)
      QueryAttribute(
        tag: 0x0020000D,
        keyword: 'StudyInstanceUID',
        vr: 'UI',
        values: [study],
      ),
    if (series != null)
      QueryAttribute(
        tag: 0x0020000E,
        keyword: 'SeriesInstanceUID',
        vr: 'UI',
        values: [series],
      ),
    if (sop != null)
      QueryAttribute(
        tag: 0x00080018,
        keyword: 'SOPInstanceUID',
        vr: 'UI',
        values: [sop],
      ),
    QueryAttribute(
      tag: 0x00100010,
      keyword: 'PatientName',
      vr: 'PN',
      values: [patient],
    ),
  ],
);

void main() {
  late Config config;
  late Runs store;
  late FindFake gateway;
  late OperationRunner runner;
  setUp(() {
    config = Config();
    store = Runs();
    gateway = FindFake();
    var id = 0;
    runner = OperationRunner(
      configuration: config,
      gateway: gateway,
      store: store,
      newId: () => 'find-${++id}',
      appVersion: 'test',
      libraryVersion: 'test',
    );
  });
  Future<RunHandle> start([FindIdentifier? id]) async =>
      (await runner.startFind(
        config.value.revision,
        id ?? FindIdentifier(),
      ) as Success<RunHandle>).value;

  test('Identifier blank optional body part, date ranges, charset and literal matching', () {
    var id = FindIdentifier(
      entries: {
        FindKey.bodyPart: const FindEntry(
          value: 'CHEST',
          purpose: FindPurpose.match,
        ),
        FindKey.patientName: const FindEntry(
          value: 'SYNTH^É',
          purpose: FindPurpose.match,
        ),
      },
    );
    expect(id.elements.any((e) => e.tag == 0x00180015), isFalse);
    expect(
      id.elements.singleWhere((e) => e.tag == 0x00080005).value,
      'ISO_IR 192',
    );
    expect(validateFindEncoding(id), isNull);
    for (final range in [
      '20240229',
      '-20240101',
      '20240101-',
      '20240101-20241231',
    ]) {
      expect(
        id
            .copy(
              key: FindKey.date,
              value: FindEntry(value: range, purpose: FindPurpose.match),
            )
            .validation,
        isNull,
      );
    }
    for (final range in ['20230229', '20241231-20240101', '-', '20240132']) {
      expect(
        id
            .copy(
              key: FindKey.date,
              value: FindEntry(value: range, purpose: FindPurpose.match),
            )
            .validation,
        isNotNull,
      );
    }
    id = FindIdentifier(level: FindLevel.series, studyUid: '2.25.1');
    expect(id.elements.singleWhere((e) => e.tag == 0x00180015).value, '');
    expect(id.validation, isNull);
    expect(FindIdentifier(level: FindLevel.image).validation, isNotNull);
    expect(
      FindIdentifier(
        level: FindLevel.image,
        studyUid: '2.25.1',
        seriesUid: '2.25.2',
      ).validation,
      isNull,
    );
    expect(validQueryUid('2.025.1'), isFalse);
    expect(validQueryUid('1.${'2' * 64}'), isFalse);
  });
  test('read-owned metadata preserves nested, missing, empty and decode-limited values', () {
    final d = dicom.Dataset()
      ..setRaw(dicom.DicomTags.specificCharacterSet, dicom.Vr.CS, [
        'ISO_IR 999',
      ])
      ..setRaw(dicom.DicomTags.patientName, dicom.Vr.PN, ['UNKNOWN'])
      ..setEmpty(dicom.DicomTags.patientId);
    final a = projectQueryMetadata(d);
    expect(a.singleWhere((a) => a.tag == 0x00100010).decodeLimited, isTrue);
    expect(a.singleWhere((a) => a.tag == 0x00100020).text, '');
    expect(a.any((a) => a.tag == 0x00080050), isFalse);
    expect(() => a.first.values.add('change'), throwsUnsupportedError);
  });
  test(
    'durable Find, shared admission, bounded row retention and privacy',
    () async {
      final id = FindIdentifier(
        rowLimit: 2,
        entries: {
          FindKey.patientId: const FindEntry(
            value: 'CANARY_ID',
            purpose: FindPurpose.match,
          ),
        },
      );
      final h = await start(id);
      expect(store.summaries.single.operation, OperationKind.find);
      expect(await runner.start(1), isA<Failure>());
      expect(await runner.startFind(1, id), isA<Failure>());
      gateway.finds.single.match(row());
      gateway.finds.single.match(row(n: 2));
      gateway.finds.single.match(row(n: 3));
      expect(gateway.finds.single.cancelled, isTrue);
      expect(runner.findResult(h.id)!.rows.length, 2);
      gateway.finds.single.finish(responses: 3);
      await h.done;
      final result = runner.findResult(h.id)!;
      expect(result.outcome!.disposition, FindDisposition.limited);
      expect(result.outcome!.status, 0);
      expect(result.received, 3);
      expect(result.active, isFalse);
      final json = jsonEncode(
        store.summaries.map((s) => s.toHistory()).toList(),
      );
      for (final canary in ['CANARY', '192.0.2.3', '2.25.1']) {
        expect(json, isNot(contains(canary)));
      }
      expect(json, contains('"v":2'));
      expect(store.summaries.last.retained, 2);
    },
  );
  test(
    'byte boundary across contexts cancels, no unbounded match queue',
    () async {
      final h = await start();
      gateway.finds.single.match(row(bytes: findSessionByteLimit));
      expect(runner.findResult(h.id)!.rows, isEmpty);
      expect(gateway.finds.single.cancelled, isTrue);
      gateway.finds.single.finish();
      await h.done;
      expect(runner.retainedQueryBytes, 0);
    },
  );
  test('failed initial history prevents traffic; failed terminal history preserves success', () async {
    store.failBegin = true;
    expect(await runner.startFind(1, FindIdentifier()), isA<Failure>());
    expect(gateway.finds, isEmpty);
    store.failBegin = false;
    store.failFinish = true;
    store.unavailable = true;
    // Recover storage first, then fail its terminal write.
    store.unavailable = false;
    final h = await start();
    gateway.finds.single.finish(cleanup: true);
    await h.done;
    store.unavailable = true;
    expect(runner.state.historyAvailable, isFalse);
    expect(runner.findResult(h.id)!.outcome!.status, 0);
    expect(runner.findResult(h.id)!.outcome!.cleanupFailed, isTrue);
    expect(await runner.start(1), isA<Failure>());
  });
  test(
    'Find stop intent and final success remain independent through cleanup',
    () async {
      final h = await start();
      h.stop();
      expect(gateway.finds.single.cancelled, isTrue);
      expect(runner.active, isTrue);
      gateway.finds.single.finish();
      await h.done;
      expect(runner.findResult(h.id)!.outcome!.status, 0);
      expect(runner.findResult(h.id)!.outcome!.cancelRequested, isTrue);
      expect(runner.findResult(h.id)!.outcome!.cancellationConfirmed, isFalse);
      final echo = (await runner.start(1) as Success<RunHandle>).value;
      h.stop();
      expect(gateway.calls.single.stopped, isFalse);
      gateway.calls.single.completer.complete(
        const EchoOutcome(EchoDisposition.success),
      );
      await echo.done;
      expect(runner.findResult(h.id), isNull);
    },
  );
  test('session hierarchy prepares only, restores results, optional body part and frozen evidence', () async {
    final c = QuerySession('node', runner);
    c.syncConfiguration(config.value);
    c.edit(FindKey.bodyPart, 'CHEST');
    await c.run(config.value);
    final first = c.runId!;
    final r = row();
    gateway.finds.last.match(r);
    gateway.finds.last.finish();
    await Future<void>.delayed(Duration.zero);
    c.select(r);
    expect(c.selected, r);
    c.openChild(r);
    expect(c.draft.level, FindLevel.series);
    expect(c.result, isNull);
    expect(gateway.finds.length, 1);
    expect(c.draft.entry(FindKey.bodyPart).value, 'CHEST');
    await c.run(config.value);
    final series = row(series: '2.25.2');
    gateway.finds.last.match(series);
    gateway.finds.last.finish();
    await Future<void>.delayed(Duration.zero);
    c.openChild(series);
    expect(c.draft.studyUid, '2.25.1');
    expect(c.draft.seriesUid, '2.25.2');
    expect(gateway.finds.length, 2);
    c.backTo(FindLevel.study);
    expect(c.runId, first);
    expect(c.result!.rows.single, r);
    c.edit(FindKey.patientId, 'NEXT');
    expect(c.dirty, isTrue);
    expect(c.result!.request.identifier.entry(FindKey.patientId).value, '');
    c.dispose();
    expect(runner.active, isFalse);
  });
  test('session invalidation, required identities, fresh encoding and draft semantics', () async {
    final c = QuerySession('node', runner);
    c.syncConfiguration(config.value);
    c.advanced(FindKey.patientId, enabled: false);
    c.edit(FindKey.patientId, 'EXACT');
    expect(c.draft.entry(FindKey.patientId).enabled, isTrue);
    expect(
      c.draft.elements.singleWhere((e) => e.tag == 0x00100020).value,
      'EXACT',
    );
    c.advanced(FindKey.patientId, purpose: FindPurpose.returnKey);
    expect(c.draft.elements.singleWhere((e) => e.tag == 0x00100020).value, '');
    c.editDate('From', '2024-02-30');
    expect(c.dateError, isNotNull);
    c.editDate('From', '2024-02-29');
    c.editDate('Through', '');
    expect(c.draft.entry(FindKey.date).value, '20240229-');
    await c.run(config.value);
    final r = row();
    gateway.finds.last.match(r);
    gateway.finds.last.finish();
    await Future<void>.delayed(Duration.zero);
    expect(c.actionProblem(row(study: null)), isNotNull);
    expect(
      row(study: '2.25.9', series: '2.25.2').targetProblem(
        FindIdentifier(level: FindLevel.series, studyUid: '2.25.1'),
      ),
      isNotNull,
    );
    c.select(r);
    config.value = AppConfiguration(
      revision: 2,
      node: config.value.node,
      client: const ClientSettings(callingAe: 'CHANGED'),
    );
    c.syncConfiguration(config.value);
    expect(c.selected, isNull);
    expect(c.stale, isTrue);
    expect(c.result!.request.client.callingAe, 'DIMSE_DASH');
    c.dispose();
  });
  test(
    '10,000-row synthetic burst has bounded updates and retained payload',
    () async {
      var updates = 0;
      final subscription = runner.changes.listen((_) => updates++);
      final h = await start(FindIdentifier(rowLimit: 10000));
      for (var i = 0; i < 10001; i++) {
        gateway.finds.single.match(row(n: i + 1, bytes: 1024));
      }
      expect(runner.findResult(h.id)!.rows.length, 10000);
      expect(
        runner.retainedQueryBytes,
        lessThanOrEqualTo(findSessionByteLimit),
      );
      expect(updates, lessThan(10));
      gateway.finds.single.finish(responses: 10001);
      await h.done;
      expect(
        runner.findResult(h.id)!.outcome!.disposition,
        FindDisposition.limited,
      );
      await subscription.cancel();
    },
  );
  testWidgets('Find shutdown bounds a noncooperative transport', (
    tester,
  ) async {
    await start();
    final close = runner.shutdown();
    await tester.pump(const Duration(seconds: 4));
    await close;
    expect(gateway.finds.single.forced, isTrue);
    await tester.pump();
  });
}
