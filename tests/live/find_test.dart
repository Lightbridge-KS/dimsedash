import 'dart:io';

import 'package:dimsedash/app/bootstrap.dart';
import 'package:dimsedash/app/app_runtime.dart';
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const base = int.fromEnvironment('PEER_PORT', defaultValue: 4250);
  const orthanc = int.fromEnvironment('ORTHANC_PORT', defaultValue: 4242);
  late Directory directory;
  late AppRuntime runtime;
  late int revision;
  Future<void> configure(
    int port, {
    String ae = 'PACS_AET',
    int dimse = 1,
  }) async {
    final current =
        (await runtime.configStore.load() as Success<AppConfiguration>).value;
    revision = (await runtime.configStore.save(
      AppConfiguration(
        revision: current.revision,
        client: ClientSettings(
          timeouts: EchoTimeouts(
            connect: 1,
            association: 1,
            dimse: dimse,
            idle: 4,
          ),
        ),
        node: PacsNode(
          id: current.node?.id ?? '',
          label: 'Synthetic Find peer',
          calledAe: ae,
          host: '127.0.0.1',
          port: port,
        ),
      ),
    ) as Success<AppConfiguration>).value.revision;
  }

  Future<QueryResultContext> run(FindIdentifier id) async {
    final h = (await runtime.runner!.startFind(
      revision,
      id,
    ) as Success<RunHandle>).value;
    await h.done.timeout(const Duration(seconds: 8));
    expect(runtime.runner!.state.historyAvailable, isTrue);
    return runtime.runner!.findResult(h.id)!;
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('dimsedash-live-find-');
    runtime = (await bootstrap(
      supportDirectory: directory,
    ) as Success<AppRuntime>).value;
  });
  tearDown(() async {
    await runtime.close();
    await directory.delete(recursive: true);
  });
  test('seeded Orthanc filters actual results and navigates study/series/image without body part', () async {
    await configure(orthanc);
    final all = await run(FindIdentifier());
    expect(all.rows, hasLength(2));
    expect(all.outcome!.status, 0);
    final study = await run(
      FindIdentifier(
        entries: {
          FindKey.patientId: const FindEntry(
            value: 'SYNTH-1',
            purpose: FindPurpose.match,
          ),
          FindKey.date: const FindEntry(
            value: '20260101-20260131',
            purpose: FindPurpose.match,
          ),
          FindKey.modality: const FindEntry(
            value: 'CT',
            purpose: FindPurpose.match,
          ),
        },
      ),
    );
    expect(study.rows, hasLength(1));
    expect(study.rows.single.studyUid, '2.25.8000.1');
    final series = await run(
      FindIdentifier(
        level: FindLevel.series,
        studyUid: study.rows.single.studyUid,
      ),
    );
    expect(series.rows, hasLength(2));
    expect(
      series.rows.any(
        (r) => r.value(0x00180015) == null || r.value(0x00180015)!.isEmpty,
      ),
      isTrue,
    );
    final chest = await run(
      FindIdentifier(
        level: FindLevel.series,
        studyUid: study.rows.single.studyUid,
        entries: {
          FindKey.bodyPart: const FindEntry(
            value: 'CHEST',
            purpose: FindPurpose.match,
          ),
        },
      ),
    );
    expect(chest.rows, hasLength(1));
    final image = await run(
      FindIdentifier(
        level: FindLevel.image,
        studyUid: chest.rows.single.studyUid,
        seriesUid: chest.rows.single.seriesUid,
      ),
    );
    expect(image.rows, hasLength(1));
    expect(image.rows.single.targetProblem(image.request.identifier), isNull);
    final empty = await run(
      FindIdentifier(
        entries: {
          FindKey.patientId: const FindEntry(
            value: 'NO_MATCH',
            purpose: FindPurpose.match,
          ),
        },
      ),
    );
    expect(empty.rows, isEmpty);
    expect(empty.outcome!.status, 0);
  });
  for (final scenario in [
    (7, 'warning success', null, 0),
    (8, 'failure after results', null, 0xA700),
    (10, 'abort', FindFailure.peerAbort, null),
    (11, 'oversize Identifier', FindFailure.identifierTooLarge, null),
    (14, 'DIMSE timeout', FindFailure.timeout, null),
    (2, 'association timeout', FindFailure.timeout, null),
    (1, 'unsupported Find context', FindFailure.contextRejected, null),
  ]) {
    test('real adapter ${scenario.$2}', () async {
      await configure(base + scenario.$1);
      final r = await run(FindIdentifier());
      expect(r.outcome!.failure, scenario.$3);
      expect(r.outcome!.status, scenario.$4);
      if ([7, 8].contains(scenario.$1)) {
        expect(r.rows, hasLength(1));
        expect(r.outcome!.optionalKeysUnsupported, isTrue);
      }
      if (scenario.$1 == 11) expect(r.rows, isEmpty);
    });
  }
  test('rejection and failed release preserve numeric evidence', () async {
    await configure(base, ae: 'WRONG_AET');
    final reject = await run(FindIdentifier());
    expect(reject.outcome!.failure, FindFailure.associationRejected);
    expect(
      runtime.runner!.state.events.any(
        (e) => e.source != null && e.reason != null,
      ),
      isTrue,
    );
    await configure(base + 5);
    final released = await run(FindIdentifier());
    expect(released.outcome!.status, 0);
    expect(released.outcome!.cleanupFailed, isTrue);
  });
  test('missing UID is visible and unselectable; unsupported charset is decode-limited', () async {
    await configure(base + 13);
    final missing = await run(FindIdentifier());
    expect(missing.rows, hasLength(1));
    expect(
      missing.rows.single.targetProblem(missing.request.identifier),
      isNotNull,
    );
    await configure(base + 12);
    final limited = await run(FindIdentifier());
    expect(limited.rows.single.attribute(0x00100010)!.decodeLimited, isTrue);
  });
  for (final offset in [2, 9, 14]) {
    test(
      'cancel during peer $offset retains independent completion and permits explicit retry',
      () async {
        await configure(base + offset, dimse: 2);
        final h = (await runtime.runner!.startFind(
          revision,
          FindIdentifier(),
        ) as Success<RunHandle>).value;
        await runtime.runner!.changes
            .firstWhere(
              (s) => s.events.any(
                (e) => offset == 2
                    ? e.kind == EvidenceKind.associateRequest
                    : e.kind == EvidenceKind.dimse && e.status == 0xFF01,
              ),
            )
            .timeout(const Duration(seconds: 4));
        h.stop();
        await h.done.timeout(const Duration(seconds: 5));
        final r = runtime.runner!.findResult(h.id)!;
        expect(r.outcome!.cancelRequested, isTrue);
        expect(r.outcome!.cancellationConfirmed, offset == 9);
        if (offset == 14) expect(r.outcome!.failure, FindFailure.timeout);
        await configure(orthanc);
        final retry = await run(FindIdentifier());
        expect(retry.outcome!.status, 0);
        expect(retry.runId, isNot(h.id));
      },
    );
  }
  test('row limit cancels a real Find and retains incomplete rows', () async {
    await configure(base + 9, dimse: 2);
    final r = await run(FindIdentifier(rowLimit: 1));
    expect(r.rows, hasLength(1));
    expect(r.outcome!.disposition, FindDisposition.limited);
    expect(r.outcome!.cancellationConfirmed, isTrue);
  });
}
