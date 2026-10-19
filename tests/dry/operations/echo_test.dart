import 'dart:async';
import 'dart:convert';

import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter_test/flutter_test.dart';

class Config implements ConfigStore {
  AppConfiguration value = const AppConfiguration(
    revision: 1,
    node: PacsNode(
      id: 'node',
      label: 'CANARY_LABEL',
      calledAe: 'CANARY_AE',
      host: '192.0.2.3',
      port: 104,
      revision: 1,
    ),
  );
  @override
  Future<Result<AppConfiguration>> load() async => Success(value);
  @override
  Future<Result<AppConfiguration>> save(AppConfiguration draft) async {
    value = draft;
    return Success(value);
  }

  @override
  Future<void> close() async {}
}

class Runs implements RunStore {
  bool failBegin = false,
      failAppend = false,
      failFinish = false,
      unavailable = false;
  final summaries = <RunSummary>[];
  final events = <EchoObservation>[];
  @override
  Future<Result<void>> begin(RunSummary s) async {
    if (failBegin) return failure;
    summaries.add(s);
    return const Success(null);
  }

  @override
  Future<Result<void>> append(String id, EchoObservation e) async {
    events.add(e);
    return failAppend ? failure : const Success(null);
  }

  @override
  Future<Result<void>> finish(RunSummary s) async {
    summaries.add(s);
    return failFinish ? failure : const Success(null);
  }

  @override
  Future<Result<void>> checkAvailable() async =>
      unavailable ? failure : const Success(null);
  @override
  Future<Result<void>> recoverAndPrune(DateTime now) async =>
      const Success(null);
  Result<void> get failure =>
      const Failure(AppFailure(FailureKind.storage, 'Unavailable'));
}

class Gateway implements DimseGateway {
  final calls = <Session>[];
  @override
  GatewayRun echo(
    String id,
    ResolvedEchoRequest request,
    void Function(EchoObservation) observe,
  ) {
    final session = Session(request, observe);
    calls.add(session);
    return session;
  }
}

class Session implements GatewayRun {
  Session(this.request, this.observe);
  final ResolvedEchoRequest request;
  final void Function(EchoObservation) observe;
  final completer = Completer<EchoOutcome>();
  bool stopped = false, forced = false;
  @override
  Future<EchoOutcome> get done => completer.future;
  @override
  void stop() {
    stopped = true;
  }

  @override
  void forceClose() {
    forced = true;
    if (!completer.isCompleted) {
      completer.complete(const EchoOutcome(EchoDisposition.interrupted));
    }
  }
}

void main() {
  late Config config;
  late Runs runs;
  late Gateway gateway;
  late OperationRunner runner;
  setUp(() {
    config = Config();
    runs = Runs();
    gateway = Gateway();
    var id = 0;
    runner = OperationRunner(
      configuration: config,
      gateway: gateway,
      store: runs,
      newId: () => '${++id}',
      appVersion: 'test',
      libraryVersion: 'test',
    );
  });
  test(
    'durable start, admission, immutable settings, explicit retry',
    () async {
      final first = (await runner.start(1) as Success<RunHandle>).value;
      expect(runs.summaries.single.id, first.id);
      expect((await runner.start(1) as Failure).error.kind, FailureKind.busy);
      config.value = const AppConfiguration(revision: 2);
      expect(gateway.calls.single.request.node.host, '192.0.2.3');
      gateway.calls.single.completer.complete(
        const EchoOutcome(EchoDisposition.success, status: 0),
      );
      await first.done;
      expect(runner.state.summary!.outcome!.status, 0);
      expect(
        (await runner.start(1) as Failure).error.kind,
        FailureKind.conflict,
      );
      expect(gateway.calls.length, 1);
      config.value = Config().value;
      final second = (await runner.start(1) as Success<RunHandle>).value;
      expect(second.id, isNot(first.id));
      first.stop();
      expect(
        gateway.calls.last.stopped,
        isFalse,
        reason: 'A stale handle cannot stop a later retry.',
      );
      gateway.calls.last.completer.complete(
        const EchoOutcome(EchoDisposition.success, status: 0),
      );
      await second.done;
    },
  );
  test('initial persistence failure sends no traffic', () async {
    runs.failBegin = true;
    expect(await runner.start(1), isA<Failure>());
    expect(gateway.calls, isEmpty);
    expect(runner.state.historyAvailable, isFalse);
  });
  test(
    'mid-run storage failure preserves result and gates next start',
    () async {
      runs.failAppend = true;
      runs.unavailable = true;
      final handle = (await runner.start(1) as Success<RunHandle>).value;
      gateway.calls.single.observe(
        EchoObservation(
          sequence: 1,
          elapsedMicros: 1,
          kind: EvidenceKind.dimse,
          status: 0,
        ),
      );
      gateway.calls.single.completer.complete(
        const EchoOutcome(EchoDisposition.success, status: 0),
      );
      await handle.done;
      expect(runner.state.historyAvailable, isFalse);
      expect(runner.state.summary!.outcome!.status, 0);
      expect(await runner.start(1), isA<Failure>());
      expect(gateway.calls.length, 1);
    },
  );
  test('stop intent does not replace a racing successful response', () async {
    final handle = (await runner.start(1) as Success<RunHandle>).value;
    handle.stop();
    expect(gateway.calls.single.stopped, isTrue);
    expect((await runner.start(1) as Failure).error.kind, FailureKind.busy);
    gateway.calls.single.completer.complete(
      const EchoOutcome(
        EchoDisposition.warning,
        status: 0,
        cleanupFailed: true,
      ),
    );
    await handle.done;
    expect(runner.state.summary!.stopRequested, isTrue);
    expect(runner.state.summary!.outcome!.status, 0);
  });
  test(
    'oversize evidence omitted and privacy projection excludes snapshot',
    () async {
      final handle = (await runner.start(1) as Success<RunHandle>).value;
      gateway.calls.single.observe(
        EchoObservation(
          sequence: 1,
          elapsedMicros: 1,
          kind: EvidenceKind.associateRequest,
          contexts: List.generate(
            1000,
            (i) => NegotiatedContext(
              id: i,
              abstractSyntax: '1.2.840.10008.1.1',
              proposed: ['1.2.840.10008.1.2'],
            ),
          ),
        ),
      );
      gateway.calls.single.completer.complete(
        const EchoOutcome(EchoDisposition.success, status: 0),
      );
      await handle.done;
      expect(runner.state.summary!.omitted, 1);
      expect(runner.state.events, isEmpty);
      final json = jsonEncode(runner.state.summary!.toHistory());
      expect(json, isNot(contains('CANARY')));
      expect(json, isNot(contains('192.0.2.3')));
    },
  );
  test('view subscriptions can disappear without stopping I/O', () async {
    final sub = runner.changes.listen((_) {});
    final handle = (await runner.start(1) as Success<RunHandle>).value;
    await sub.cancel();
    expect(gateway.calls.single.stopped, isFalse);
    expect(runner.active, isTrue);
    gateway.calls.single.completer.complete(
      const EchoOutcome(EchoDisposition.success, status: 0),
    );
    await handle.done;
  });
  test(
    'bounded write queue reports history loss separately from live detail',
    () async {
      final handle = (await runner.start(1) as Success<RunHandle>).value;
      for (var i = 0; i < 500; i++) {
        gateway.calls.single.observe(
          EchoObservation(
            sequence: i,
            elapsedMicros: i,
            kind: EvidenceKind.data,
          ),
        );
      }
      gateway.calls.single.completer.complete(
        const EchoOutcome(EchoDisposition.success, status: 0),
      );
      await handle.done;
      expect(runner.state.events.length, 500);
      expect(runner.state.omitted, 0);
      expect(runner.state.historyDropped, 244);
      expect(runs.events.length, 256);
    },
  );
  test('history projection rejects arbitrary text in protocol UID fields', () {
    final event = EchoObservation(
      sequence: 1,
      elapsedMicros: 1,
      kind: EvidenceKind.associateAccept,
      peerImplementationClassUid: 'CANARY_PEER',
      contexts: [
        NegotiatedContext(
          id: 1,
          abstractSyntax: 'CANARY_SOP',
          proposed: ['CANARY_SYNTAX', '1.2.3'],
          selected: 'CANARY_SELECTED',
        ),
      ],
    );
    final encoded = jsonEncode(event.toHistory());
    expect(encoded, isNot(contains('CANARY')));
    expect(encoded, contains('1.2.3'));
  });
  testWidgets('shutdown forces a stalled transport within five seconds', (
    tester,
  ) async {
    await runner.start(1);
    final closing = runner.shutdown();
    await tester.pump(const Duration(milliseconds: 3900));
    expect(gateway.calls.single.forced, isFalse);
    await tester.pump(const Duration(milliseconds: 100));
    await closing;
    expect(gateway.calls.single.forced, isTrue);
  });
}
