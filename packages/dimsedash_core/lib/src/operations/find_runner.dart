part of 'echo.dart';

abstract interface class FindGatewayRun {
  Future<FindOutcome> get done;
  void cancel();
  void forceClose();
}

/// Separate optional capability preserves existing Echo-only gateway consumers.
abstract interface class FindGateway {
  String? validateFind(FindIdentifier identifier);
  FindGatewayRun find(
    String runId,
    ResolvedFindRequest request,
    void Function(EchoObservation) observe,
    void Function(QueryMatch) match,
  );
}

final class _FindBuffer {
  _FindBuffer(this.request);
  final ResolvedFindRequest request;
  final rows = <QueryMatch>[];
  int received = 0, bytes = 0;
  bool active = true, limitReached = false;
  FindOutcome? outcome;
  QueryResultContext snapshot(String id) => QueryResultContext(
    runId: id,
    request: request,
    rows: rows,
    received: outcome?.responses ?? received,
    accountedBytes: bytes,
    active: active,
    limitReached: limitReached,
    outcome: outcome,
  );
}

extension FindExecution on OperationRunner {
  QueryResultContext? findResult(String id) => _findBuffers[id]?.snapshot(id);
  QueryResultContext? get latestFindResult =>
      _summary?.operation == OperationKind.find
      ? findResult(_summary!.id)
      : null;
  int get retainedQueryBytes =>
      _findBuffers.values.fold(0, (n, b) => n + b.bytes);

  /// A single workspace retains only its current hierarchy. Active/latest Find
  /// remains available independently for navigation and frozen evidence.
  void retainFindResults(Set<String> ids) {
    _retainedFindIds = Set.of(ids.take(3));
    _pruneFindBuffers();
  }

  void _pruneFindBuffers() {
    _findBuffers.removeWhere(
      (id, b) =>
          !b.active &&
          !_retainedFindIds.contains(id) &&
          !(_summary?.operation == OperationKind.find && _summary?.id == id),
    );
  }

  void _matchFind(String id, QueryMatch row) {
    final buffer = _findBuffers[id];
    if (buffer == null || !buffer.active) return;
    buffer.received++;
    if (buffer.limitReached) return;
    if (buffer.rows.length >= buffer.request.identifier.rowLimit ||
        retainedQueryBytes + row.accountedBytes > findSessionByteLimit) {
      buffer.limitReached = true;
      _findTransport?.cancel();
    } else {
      buffer.rows.add(row);
      buffer.bytes += row.accountedBytes;
      if (buffer.rows.length == buffer.request.identifier.rowLimit) {
        buffer.limitReached = true;
        _findTransport?.cancel();
      }
    }
    _publish();
  }

  Future<void> _executeFind(String id) async {
    FindOutcome outcome;
    try {
      _findTransport = (gateway as FindGateway).find(
        id,
        _findBuffers[id]!.request,
        _observe,
        (row) => _matchFind(id, row),
      );
      if (_stopRequested || _findBuffers[id]!.limitReached) {
        _findTransport!.cancel();
      }
      outcome = await _findTransport!.done;
    } catch (_) {
      outcome = const FindOutcome(
        disposition: FindDisposition.failed,
        failure: FindFailure.unexpected,
      );
    }
    if (_findBuffers[id]!.limitReached) {
      outcome = FindOutcome(
        disposition: FindDisposition.limited,
        status: outcome.status,
        failure: outcome.failure,
        cancelRequested: outcome.cancelRequested,
        cancellationConfirmed: outcome.cancellationConfirmed,
        optionalKeysUnsupported: outcome.optionalKeysUnsupported,
        cleanupFailed: outcome.cleanupFailed,
        responses: outcome.responses,
      );
    }
    await _complete(null, findOutcome: outcome);
  }
}
