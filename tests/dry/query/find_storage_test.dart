import 'dart:convert';

import 'package:dimsedash/adapters/persistence/database.dart';
import 'package:dimsedash/adapters/persistence/run_store.dart';
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v2 Find history coexists with Echo and recovers without replay or datasets', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final store = SqliteRunStore(db);
    final now = DateTime.utc(2026, 11, 4);
    for (final kind in OperationKind.values) {
      await store.begin(
        RunSummary(
          id: kind.name,
          nodeId: null,
          nodeRevision: 1,
          configurationRevision: 1,
          started: now,
          timeouts: const EchoTimeouts(),
          appVersion: 'test',
          libraryVersion: 'test',
          operation: kind,
          findLevel: kind == OperationKind.find ? FindLevel.study : null,
          rowLimit: kind == OperationKind.find ? 1000 : null,
        ),
      );
      await store.append(
        kind.name,
        EchoObservation(
          sequence: 1,
          elapsedMicros: 1,
          kind: EvidenceKind.dimse,
          command: kind == OperationKind.find ? 0x8020 : 0x8030,
          status: 0,
        ),
      );
    }
    expect(
      await store.recoverAndPrune(now.add(const Duration(seconds: 1))),
      isA<Success>(),
    );
    final rows = await db.select(db.runs).get();
    expect(rows, hasLength(2));
    for (final row in rows) {
      final json = jsonDecode(row.summary) as Map<String, dynamic>;
      expect(json['disposition'], 'interrupted');
      expect(json['provenance'], 'startupReconciliation');
      expect(json['status'], isNull);
      expect(json['v'], row.id == 'find' ? 2 : 1);
      for (final key in [
        'identifier',
        'criteria',
        'patientId',
        'studyUid',
        'endpoint',
        'callingAe',
      ]) {
        expect(json.containsKey(key), isFalse);
      }
    }
    expect((await db.select(db.runEvents).get()).length, 2);
    await db.close();
  });
}
