import 'dart:async';
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
  Future<void> configure(int port, {String ae = 'PACS_AET'}) async {
    final current =
        (await runtime.configStore.load() as Success<AppConfiguration>).value;
    final result = await runtime.configStore.save(
      AppConfiguration(
        revision: current.revision,
        client: const ClientSettings(
          timeouts: EchoTimeouts(connect: 1, association: 1, dimse: 1, idle: 2),
        ),
        node: PacsNode(
          id: current.node?.id ?? '',
          label: 'Synthetic fixture',
          calledAe: ae,
          host: '127.0.0.1',
          port: port,
        ),
      ),
    );
    revision = (result as Success<AppConfiguration>).value.revision;
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('dimsedash-live-');
    runtime = (await bootstrap(
      supportDirectory: directory,
    ) as Success<AppRuntime>).value;
  });
  tearDown(() async {
    await runtime.close();
    await directory.delete(recursive: true);
  });
  for (final scenario in [
    ('Orthanc success', orthanc, 'PACS_AET', EchoDisposition.success, null),
    (
      'wrong called AE',
      base,
      'WRONG_AET',
      EchoDisposition.failed,
      EchoFailure.associationRejected,
    ),
    (
      'unsupported context',
      base + 1,
      'PACS_AET',
      EchoDisposition.failed,
      EchoFailure.contextRejected,
    ),
    (
      'association timeout',
      base + 2,
      'PACS_AET',
      EchoDisposition.failed,
      EchoFailure.timeout,
    ),
    (
      'DIMSE timeout',
      base + 3,
      'PACS_AET',
      EchoDisposition.failed,
      EchoFailure.timeout,
    ),
    (
      'peer abort',
      base + 4,
      'PACS_AET',
      EchoDisposition.failed,
      EchoFailure.peerAbort,
    ),
    (
      'release failure retains successful Echo',
      base + 5,
      'PACS_AET',
      EchoDisposition.warning,
      null,
    ),
  ]) {
    test(scenario.$1, () async {
      await configure(scenario.$2, ae: scenario.$3);
      final handle =
          (await runtime.runner!.start(revision) as Success<RunHandle>).value;
      await handle.done.timeout(const Duration(seconds: 8));
      final state = runtime.runner!.state;
      expect(state.summary!.outcome!.disposition, scenario.$4);
      expect(state.summary!.outcome!.failure, scenario.$5);
      expect(
        state.events.any((e) => e.kind == EvidenceKind.transportClosed),
        isTrue,
      );
      expect(state.historyAvailable, isTrue);
      if (scenario.$4 == EchoDisposition.warning) {
        expect(state.summary!.outcome!.status, 0);
        expect(state.summary!.outcome!.cleanupFailed, isTrue);
      }
      if (scenario.$5 == EchoFailure.associationRejected) {
        expect(
          state.events.any(
            (e) => e.result != null && e.source != null && e.reason != null,
          ),
          isTrue,
        );
      }
    });
  }
  test('refused connection uses actual unbound loopback port', () async {
    final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = probe.port;
    await probe.close();
    await configure(port);
    final handle =
        (await runtime.runner!.start(revision) as Success<RunHandle>).value;
    await handle.done;
    expect(
      runtime.runner!.state.summary!.outcome!.failure,
      EchoFailure.connection,
    );
  });
  for (final offset in [2, 3]) {
    test(
      'stop during ${offset == 2 ? 'establishment' : 'operation'} and retry',
      () async {
        await configure(base + offset);
        final reached = Completer<void>();
        final sub = runtime.runner!.changes.listen((s) {
          if (s.events.any(
                (e) =>
                    e.kind ==
                    (offset == 2
                        ? EvidenceKind.associateRequest
                        : EvidenceKind.dimse),
              ) &&
              !reached.isCompleted) {
            reached.complete();
          }
        });
        final first =
            (await runtime.runner!.start(revision) as Success<RunHandle>).value;
        await reached.future.timeout(const Duration(seconds: 3));
        first.stop();
        await first.done.timeout(const Duration(seconds: 4));
        await sub.cancel();
        expect(runtime.runner!.state.summary!.stopRequested, isTrue);
        expect(runtime.runner!.state.summary!.outcome!.status, isNull);
        await configure(orthanc);
        final retry =
            (await runtime.runner!.start(revision) as Success<RunHandle>).value;
        await retry.done;
        expect(retry.id, isNot(first.id));
        expect(runtime.runner!.state.summary!.outcome!.status, 0);
      },
    );
  }
}
