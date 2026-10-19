import 'dart:async';
import 'dart:convert';

import '../configuration/configuration.dart';
import '../configuration/configuration_validation.dart';
import '../configuration/config_store.dart';
import '../foundation/result.dart';

final class ResolvedEchoRequest {
  const ResolvedEchoRequest({
    required this.node,
    required this.client,
    required this.configurationRevision,
  });
  final PacsNode node;
  final ClientSettings client;
  final int configurationRevision;
}

enum EvidenceKind {
  connecting,
  connected,
  associateRequest,
  associateAccept,
  associateReject,
  data,
  releaseRequest,
  releaseResponse,
  abort,
  transportClosed,
  dimse,
  timeout,
  stopRequested,
}

enum EchoTimeoutPhase { connect, association, dimse, idle }

enum EvidenceDirection { local, outgoing, incoming }

enum EchoDisposition { success, warning, failed, stopped, interrupted }

enum EchoFailure {
  connection,
  associationRejected,
  contextRejected,
  timeout,
  peerAbort,
  protocol,
  transport,
  unexpected,
}

/// Deliberately separate from execution configuration; only permitted facts fit.
final class NegotiatedContext {
  NegotiatedContext({
    required this.id,
    required this.abstractSyntax,
    required Iterable<String> proposed,
    this.result,
    this.selected,
    this.scuRole,
    this.scpRole,
  }) : proposed = List.unmodifiable(proposed);
  final int id;
  final bool? scuRole, scpRole;
  final String abstractSyntax;
  final List<String> proposed;
  final int? result;
  final String? selected;
  Map<String, Object?> toHistory() => {
    'id': id,
    'scuRole': scuRole,
    'scpRole': scpRole,
    'abstractSyntax': _historyUid(abstractSyntax),
    'proposed': proposed.map(_historyUid).whereType<String>().toList(),
    'result': result,
    'selected': _historyUid(selected),
  };
}

final class EchoObservation {
  EchoObservation({
    required this.sequence,
    required this.elapsedMicros,
    required this.kind,
    this.direction = EvidenceDirection.local,
    Iterable<NegotiatedContext> contexts = const [],
    this.result,
    this.source,
    this.reason,
    this.command,
    this.messageId,
    this.responseTo,
    this.status,
    this.contextId,
    this.peerMaxPduLength,
    this.timeoutPhase,
    this.peerImplementationClassUid,
    this.maxInvoked,
    this.maxPerformed,
  }) : contexts = List.unmodifiable(contexts);
  final EchoTimeoutPhase? timeoutPhase;
  final String? peerImplementationClassUid;
  final int? maxInvoked, maxPerformed;
  final int sequence, elapsedMicros;
  final EvidenceKind kind;
  final EvidenceDirection direction;
  final List<NegotiatedContext> contexts;
  final int? result,
      source,
      reason,
      command,
      messageId,
      responseTo,
      status,
      contextId,
      peerMaxPduLength;
  Map<String, Object?> toHistory() => {
    'v': 1,
    'timeoutPhase': timeoutPhase?.name,
    'peerImplementationClassUid': _historyUid(peerImplementationClassUid),
    'maxInvoked': maxInvoked,
    'maxPerformed': maxPerformed,
    'sequence': sequence,
    'elapsedMicros': elapsedMicros,
    'kind': kind.name,
    'direction': direction.name,
    'contexts': contexts.map((c) => c.toHistory()).toList(),
    'result': result,
    'source': source,
    'reason': reason,
    'command': command,
    'messageId': messageId,
    'responseTo': responseTo,
    'status': status,
    'contextId': contextId,
    'peerMaxPduLength': peerMaxPduLength,
  };
  int get encodedBytes => utf8.encode(jsonEncode(toHistory())).length;
}

final class EchoOutcome {
  const EchoOutcome(
    this.disposition, {
    this.status,
    this.failure,
    this.cleanupFailed = false,
  });
  final EchoDisposition disposition;
  final int? status;
  final EchoFailure? failure;
  final bool cleanupFailed;
}

abstract interface class GatewayRun {
  Future<EchoOutcome> get done;
  void stop();
  void forceClose();
}

abstract interface class DimseGateway {
  GatewayRun echo(
    String runId,
    ResolvedEchoRequest request,
    void Function(EchoObservation) observe,
  );
}

final class RunSummary {
  const RunSummary({
    required this.id,
    required this.nodeId,
    required this.nodeRevision,
    required this.configurationRevision,
    required this.started,
    required this.timeouts,
    required this.appVersion,
    required this.libraryVersion,
    this.ended,
    this.outcome,
    this.stopRequested = false,
    this.omitted = 0,
    this.historyDropped = 0,
    this.historyAvailable = true,
    this.recoveredAt,
    this.elapsedMicros,
  });
  final String id;
  final String? nodeId;
  final int nodeRevision, configurationRevision;
  final int? elapsedMicros;
  final DateTime started;
  final DateTime? ended, recoveredAt;
  final EchoTimeouts timeouts;
  final String appVersion, libraryVersion;
  final EchoOutcome? outcome;
  final bool stopRequested, historyAvailable;
  final int omitted, historyDropped;
  Map<String, Object?> toHistory() => {
    'v': 1,
    'operation': 'echo',
    'elapsedMicros': elapsedMicros,
    'nodeRevision': nodeRevision,
    'configurationRevision': configurationRevision,
    'started': started.toUtc().toIso8601String(),
    'ended': ended?.toUtc().toIso8601String(),
    'timeouts': timeouts.values,
    'appVersion': appVersion,
    'libraryVersion': libraryVersion,
    'disposition': outcome?.disposition.name,
    'status': outcome?.status,
    'failure': outcome?.failure?.name,
    'cleanupFailed': outcome?.cleanupFailed,
    'stopRequested': stopRequested,
    'liveOmitted': omitted,
    'historyDroppedBeforeWrite': historyDropped,
    'historyAvailable': historyAvailable,
    'recoveredAt': recoveredAt?.toUtc().toIso8601String(),
    'provenance': recoveredAt == null ? 'observed' : 'startupReconciliation',
    'omissions': [
      'endpoint',
      'aeTitles',
      'label',
      'paths',
      'datasets',
      'payload',
      'peerComments',
    ],
  };
}

abstract interface class RunStore {
  Future<Result<void>> begin(RunSummary summary);
  Future<Result<void>> append(String id, EchoObservation observation);
  Future<Result<void>> finish(RunSummary summary);
  Future<Result<void>> recoverAndPrune(DateTime now);
  Future<Result<void>> checkAvailable();
}

/// Immutable presentation snapshot; the runner, not its observers, owns I/O.
final class EchoState {
  EchoState({
    this.request,
    this.summary,
    Iterable<EchoObservation> events = const [],
    this.active = false,
    this.stopRequested = false,
    this.omitted = 0,
    this.historyDropped = 0,
    this.historyAvailable = true,
  }) : events = List.unmodifiable(events);
  final ResolvedEchoRequest? request;
  final RunSummary? summary;
  final List<EchoObservation> events;
  final bool active, historyAvailable, stopRequested;
  final int omitted, historyDropped;
}

final class RunHandle {
  RunHandle(this.id, this.done, this.stop);
  final String id;
  final Future<void> done;
  final void Function() stop;
}

final class OperationRunner {
  OperationRunner({
    required this.configuration,
    required this.gateway,
    required this.store,
    required this.newId,
    required this.appVersion,
    required this.libraryVersion,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;
  final ConfigStore configuration;
  final DimseGateway gateway;
  final RunStore store;
  final String Function() newId;
  final String appVersion, libraryVersion;
  final DateTime Function() now;
  final _changes = StreamController<EchoState>.broadcast(sync: true);
  EchoState _state = EchoState();
  EchoState get state => _state;
  Stream<EchoState> get changes => _changes.stream;
  bool _occupied = false,
      _closing = false,
      _historyAvailable = true,
      _stopRequested = false;
  GatewayRun? _transport;
  Future<void>? _running;
  Future<void> _writes = Future.value();
  final List<EchoObservation> _events = [];
  int _bytes = 0, _omitted = 0, _historyDropped = 0;
  ResolvedEchoRequest? _request;
  RunSummary? _summary;
  String? _activeId;
  Stopwatch? _clock;
  bool get active => _occupied;

  Completer<void>? _admission;
  Future<Result<RunHandle>> start(int expectedConfigurationRevision) async {
    if (_occupied || _closing) {
      return const Failure(
        AppFailure(
          FailureKind.busy,
          'An Echo is already running or shutting down.',
        ),
      );
    }
    final admission = Completer<void>();
    _admission = admission;
    try {
      return await _start(expectedConfigurationRevision);
    } finally {
      admission.complete();
    }
  }

  Future<Result<RunHandle>> _start(int expectedConfigurationRevision) async {
    if (_closing || _occupied) {
      return const Failure(
        AppFailure(
          FailureKind.busy,
          'An Echo is already running or shutting down.',
        ),
      );
    }
    _occupied = true;
    _activeId = null;
    _stopRequested = false;
    final loaded = await configuration.load();
    if (loaded case Failure<AppConfiguration>(:final error)) {
      _occupied = false;
      return Failure(error);
    }
    final config = (loaded as Success<AppConfiguration>).value;
    if (config.revision != expectedConfigurationRevision) {
      _occupied = false;
      return const Failure(
        AppFailure(
          FailureKind.conflict,
          'Configuration changed. Review the resolved target again.',
        ),
      );
    }
    if (config.node == null || validateConfiguration(config).isNotEmpty) {
      _occupied = false;
      return const Failure(
        AppFailure(
          FailureKind.validation,
          'Select a valid saved node before running Echo.',
        ),
      );
    }
    if (!_historyAvailable) {
      final check = await store.checkAvailable();
      if (check is Failure<void>) {
        _occupied = false;
        return Failure(check.error);
      }
      if (_summary?.outcome != null) {
        final retried = await store.finish(_summary!);
        if (retried is Failure<void>) {
          _occupied = false;
          return Failure(retried.error);
        }
      }
      _historyAvailable = true;
    }
    if (_closing) {
      _occupied = false;
      return const Failure(
        AppFailure(FailureKind.busy, 'Application is shutting down.'),
      );
    }
    final request = ResolvedEchoRequest(
      node: config.node!,
      client: config.client,
      configurationRevision: config.revision,
    );
    _clock = Stopwatch()..start();
    final summary = RunSummary(
      id: newId(),
      nodeId: request.node.id,
      nodeRevision: request.node.revision,
      configurationRevision: config.revision,
      started: now().toUtc(),
      timeouts: request.client.timeouts,
      appVersion: appVersion,
      libraryVersion: libraryVersion,
    );
    final saved = await store.begin(summary);
    if (saved is Failure<void>) {
      _occupied = false;
      _historyAvailable = false;
      _publish();
      return Failure(saved.error);
    }
    _events.clear();
    _bytes = 0;
    _omitted = 0;
    _historyDropped = 0;
    _request = request;
    _summary = summary;
    _activeId = summary.id;
    _publish();
    final completed = Completer<void>();
    _running = completed.future;
    if (_closing || _stopRequested) {
      unawaited(
        _complete(const EchoOutcome(EchoDisposition.stopped))
            .whenComplete(completed.complete),
      );
      return Success(
        RunHandle(summary.id, completed.future, () => _stopRun(summary.id)),
      );
    }
    // Dispatch is synchronous after the durable start; shutdown cannot interleave.
    try {
      _transport = gateway.echo(summary.id, request, _observe);
    } catch (_) {
      _running = _complete(
        const EchoOutcome(
          EchoDisposition.failed,
          failure: EchoFailure.unexpected,
        ),
      ).whenComplete(completed.complete);
      return Success(
        RunHandle(summary.id, completed.future, () => _stopRun(summary.id)),
      );
    }
    unawaited(_execute().whenComplete(completed.complete));
    return Success(
      RunHandle(summary.id, completed.future, () => _stopRun(summary.id)),
    );
  }

  void stop() {
    if (!_occupied || _stopRequested) return;
    _stopRequested = true;
    _transport?.stop();
    _publish();
  }

  Future<void> shutdown() async {
    _closing = true;
    stop();
    try {
      await (() async {
        await _admission?.future;
        await _running;
      })().timeout(const Duration(seconds: 4));
    } on TimeoutException {
      _transport?.forceClose();
    }
    // A still-pending durable record is reconciled on restart, never retried.
  }

  void _stopRun(String id) {
    if (_activeId == id) stop();
  }

  Future<void> _execute() async {
    EchoOutcome outcome;
    try {
      outcome = await _transport!.done;
    } catch (_) {
      outcome = const EchoOutcome(
        EchoDisposition.failed,
        failure: EchoFailure.unexpected,
      );
    }
    await _complete(outcome);
  }

  Future<void> _complete(EchoOutcome outcome) async {
    await _writes;
    final s = _summary!;
    _summary = RunSummary(
      id: s.id,
      nodeId: s.nodeId,
      nodeRevision: s.nodeRevision,
      configurationRevision: s.configurationRevision,
      started: s.started,
      ended: now().toUtc(),
      elapsedMicros: _clock?.elapsedMicroseconds,
      timeouts: s.timeouts,
      appVersion: s.appVersion,
      libraryVersion: s.libraryVersion,
      outcome: outcome,
      stopRequested: _stopRequested,
      omitted: _omitted,
      historyDropped: _historyDropped,
      historyAvailable: _historyAvailable,
    );
    final result = await store.finish(_summary!);
    if (result is Failure<void>) _historyAvailable = false;
    _occupied = false;
    _activeId = null;
    _transport = null;
    _publish();
  }

  void _observe(EchoObservation event) {
    final size = event.encodedBytes;
    if (size > 16 * 1024) {
      _omitted++;
      _historyDropped++;
      _publish();
      return;
    }
    _events.add(event);
    _bytes += size;
    while (_bytes > 4 * 1024 * 1024) {
      _bytes -= _events.removeAt(0).encodedBytes;
      _omitted++;
    }
    // The pending persistence queue is bounded as well as the displayed window.
    if (_pendingWrites >= 256) {
      _historyDropped++;
      _publish();
      return;
    }
    _pendingWrites++;
    final id = _summary!.id;
    _writes = _writes.then((_) async {
      if (_historyAvailable) {
        final result = await store.append(id, event);
        if (result is Failure<void>) _historyAvailable = false;
      }
      _pendingWrites--;
      _publish();
    });
    _publish();
  }

  int _pendingWrites = 0;
  void _publish() {
    _state = EchoState(
      request: _request,
      summary: _summary,
      events: _events,
      active: _occupied,
      stopRequested: _stopRequested,
      omitted: _omitted,
      historyDropped: _historyDropped,
      historyAvailable: _historyAvailable,
    );
    _changes.add(_state);
  }
}

// Validate protocol text again at persistence, independently of any adapter.
String? _historyUid(String? value) =>
    value != null &&
        value.length <= 64 &&
        RegExp(r'^[0-9]+(?:\.[0-9]+)+$').hasMatch(value)
    ? value
    : null;
