import 'dart:convert';

import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:drift/drift.dart';

import 'database.dart';

import 'package:sqlite3/sqlite3.dart' show SqliteException;

/// History is serialized only from the explicit core allowlist, never a request.
class SqliteRunStore implements RunStore {
  SqliteRunStore(
    this.database, {
    this.maxRuns = 1000,
    this.maxAge = const Duration(days: 30),
    this.eventBytes = 16 * 1024,
    this.runBytes = 4 * 1024 * 1024,
    this.totalBytes = 64 * 1024 * 1024,
  });
  final AppDatabase database;
  final int maxRuns, eventBytes, runBytes, totalBytes;
  final Duration maxAge;
  Future<Result<void>> _guard(Future<void> Function() work) async {
    try {
      await work();
      return const Success(null);
    } on SqliteException {
      return _failure();
    } on StateError {
      return _failure();
    } on FormatException {
      return _failure();
    }
  }

  Failure<void> _failure() => const Failure(
    AppFailure(
      FailureKind.storage,
      'Run history is unavailable. Check storage and retry; observed protocol evidence is unchanged.',
    ),
  );

  @override
  Future<Result<void>> checkAvailable() => _guard(
    () => database.transaction(() async {
      // Exercise a write, not just SELECT, before readmitting network work.
      await database.customStatement(
        'UPDATE runs SET omitted = omitted WHERE id = ?',
        [''],
      );
    }),
  );
  @override
  Future<Result<void>> begin(RunSummary summary) => _guard(() async {
    await database
        .into(database.runs)
        .insert(
          RunsCompanion.insert(
            id: summary.id,
            nodeId: Value(summary.nodeId),
            started: summary.started.millisecondsSinceEpoch,
            summary: jsonEncode(summary.toHistory()),
          ),
        );
  });
  @override
  Future<Result<void>> append(String id, EchoObservation observation) => _guard(
    () => database.transaction(() async {
      final payload = jsonEncode(observation.toHistory());
      final size = utf8.encode(payload).length;
      if (size > eventBytes) {
        await _omit(id, 1);
        return;
      }
      await database
          .into(database.runEvents)
          .insert(
            RunEventsCompanion.insert(
              runId: id,
              sequence: observation.sequence,
              payload: payload,
              bytes: size,
            ),
          );
      await _trimDetails(id);
    }),
  );
  @override
  Future<Result<void>> finish(RunSummary summary) => _guard(
    () => database.transaction(() async {
      await (database.update(
        database.runs,
      )..where((t) => t.id.equals(summary.id))).write(
        RunsCompanion(
          ended: Value(summary.ended!.millisecondsSinceEpoch),
          summary: Value(jsonEncode(summary.toHistory())),
        ),
      );
      await _prune(summary.ended!);
    }),
  );
  @override
  Future<Result<void>> recoverAndPrune(DateTime now) => _guard(
    () => database.transaction(() async {
      final unfinished = await (database.select(
        database.runs,
      )..where((t) => t.ended.isNull())).get();
      for (final row in unfinished) {
        final summary = jsonDecode(row.summary) as Map<String, dynamic>;
        // End time is the reconciliation time, never an invented network end.
        summary.addAll({
          'disposition': 'interrupted',
          'ended': now.toUtc().toIso8601String(),
          'recoveredAt': now.toUtc().toIso8601String(),
          'provenance': 'startupReconciliation',
        });
        await (database.update(
          database.runs,
        )..where((t) => t.id.equals(row.id))).write(
          RunsCompanion(
            ended: Value(now.millisecondsSinceEpoch),
            summary: Value(jsonEncode(summary)),
          ),
        );
      }
      await _prune(now);
    }),
  );
  Future<void> _omit(String id, int count) => database.customStatement(
    'UPDATE runs SET omitted = omitted + ? WHERE id = ?',
    [count, id],
  );
  Future<void> _trimDetails(String id) async {
    var bytes =
        (await database
                .customSelect(
                  'SELECT COALESCE(SUM(bytes),0) AS n FROM run_events WHERE run_id = ?',
                  variables: [Variable(id)],
                )
                .getSingle())
            .read<int>('n');
    final events =
        await (database.select(database.runEvents)
              ..where((t) => t.runId.equals(id))
              ..orderBy([(t) => OrderingTerm.asc(t.sequence)]))
            .get();
    for (final event in events) {
      if (bytes <= runBytes) break;
      await (database.delete(database.runEvents)..where(
            (t) => t.runId.equals(id) & t.sequence.equals(event.sequence),
          ))
          .go();
      bytes -= event.bytes;
      await _omit(id, 1);
    }
    await _trimTotal();
  }

  Future<void> _trimTotal() async {
    var bytes =
        (await database
                .customSelect(
                  'SELECT COALESCE(SUM(bytes),0) AS n FROM run_events',
                )
                .getSingle())
            .read<int>('n');
    // Protect active work; its own per-run window is still bounded.
    while (bytes > totalBytes) {
      final oldest = await database
          .customSelect(
            'SELECT e.run_id, e.sequence, e.bytes FROM run_events e JOIN runs r ON r.id=e.run_id WHERE r.ended IS NOT NULL ORDER BY r.ended, r.id, e.sequence LIMIT 1',
          )
          .getSingleOrNull();
      if (oldest == null) break;
      final id = oldest.read<String>('run_id');
      await database.customStatement(
        'DELETE FROM run_events WHERE run_id=? AND sequence=?',
        [id, oldest.read<int>('sequence')],
      );
      bytes -= oldest.read<int>('bytes');
      await _omit(id, 1);
    }
  }

  Future<void> _prune(DateTime now) async {
    await database.customStatement(
      'DELETE FROM runs WHERE ended IS NOT NULL AND ended < ?',
      [now.subtract(maxAge).millisecondsSinceEpoch],
    );
    await database.customStatement(
      'DELETE FROM runs WHERE id IN (SELECT id FROM runs WHERE ended IS NOT NULL ORDER BY ended DESC, id DESC LIMIT -1 OFFSET ?)',
      [maxRuns],
    );
    await _trimTotal();
  }
}
