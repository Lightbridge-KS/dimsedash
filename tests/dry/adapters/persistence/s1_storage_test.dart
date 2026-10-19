import 'dart:convert';
import 'dart:io';

import 'package:dimsedash/adapters/persistence/config_store.dart';
import 'package:dimsedash/adapters/persistence/database.dart';
import 'package:dimsedash/adapters/persistence/run_store.dart';
import 'package:dimsedash/adapters/persistence/migration_snapshot.dart';
import 'package:dimsedash/app/bootstrap.dart';
import 'package:dimsedash/app/app_runtime.dart';
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  const node = PacsNode(
    id: '',
    label: 'CANARY_LABEL',
    calledAe: 'CANARY_AE',
    host: '192.0.2.7',
    port: 104,
  );
  final now = DateTime.utc(2026, 10, 19);
  RunSummary summary(String id, {String? nodeId, DateTime? end}) => RunSummary(
    id: id,
    nodeId: nodeId,
    nodeRevision: 1,
    configurationRevision: 1,
    started: now,
    ended: end,
    timeouts: const EchoTimeouts(),
    appVersion: 'test',
    libraryVersion: 'test',
    outcome: end == null
        ? null
        : const EchoOutcome(EchoDisposition.success, status: 0),
  );
  test(
    'multi-node CRUD, draft duplication, selection and retained history',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final config = SqliteConfigStore(db);
      final runs = SqliteRunStore(db);
      final first = (await config.changeNode(
        const AddNode(0, node),
      ) as Success<AppConfiguration>).value;
      final draft = duplicateNode(first.node!);
      expect(draft.id, '');
      expect(first.nodes.length, 1);
      final second = (await config.changeNode(
        AddNode(first.revision, draft),
      ) as Success<AppConfiguration>).value;
      expect(second.nodes.length, 2);
      expect(second.node!.id, isNot(first.node!.id));
      expect(second.searchNodes('canary_ae').length, 2);
      expect(second.searchNodes('192.0.2').length, 2);
      final selected = (await config.changeNode(
        SelectNode(second.revision, first.node!.id),
      ) as Success<AppConfiguration>).value;
      expect(selected.node!.revision, first.node!.revision);
      expect(
        await config.changeNode(RemoveNode(0, first.node!.id)),
        isA<Failure>(),
      );
      await runs.begin(summary('run', nodeId: first.node!.id));
      final removed = (await config.changeNode(
        RemoveNode(selected.revision, first.node!.id),
      ) as Success<AppConfiguration>).value;
      expect(removed.node, isNull);
      expect(removed.nodes.length, 1);
      final history = await db.select(db.runs).getSingle();
      expect(history.nodeId, isNull);
      expect(history.id, 'run');
      await config.close();
    },
  );
  test(
    'retention protects active rows and keeps summaries after detail eviction',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final runs = SqliteRunStore(
        db,
        maxRuns: 2,
        runBytes: 1100,
        totalBytes: 1500,
        eventBytes: 600,
      );
      for (final id in ['a', 'b', 'c', 'active']) {
        expect(await runs.begin(summary(id)), isA<Success>());
        for (var i = 1; i <= 5; i++) {
          await runs.append(
            id,
            EchoObservation(
              sequence: i,
              elapsedMicros: i,
              kind: EvidenceKind.dimse,
              status: 0,
            ),
          );
        }
        if (id != 'active') await runs.finish(summary(id, end: now));
      }
      final rows = await db.select(db.runs).get();
      expect(rows.length, 3);
      expect(rows.any((r) => r.id == 'active' && r.ended == null), isTrue);
      expect(rows.any((r) => r.omitted > 0), isTrue);
      final total = await db.select(db.runEvents).get();
      expect(total.fold(0, (n, e) => n + e.bytes), lessThanOrEqualTo(1500));
      await runs.recoverAndPrune(now.add(const Duration(days: 31)));
      final recovered = await db.select(db.runs).getSingle();
      expect(recovered.id, 'active');
      final payload = jsonDecode(recovered.summary) as Map;
      expect(payload['disposition'], 'interrupted');
      expect(payload['provenance'], 'startupReconciliation');
      await db.close();
    },
  );
  test('event size and age cutoff boundaries are exact', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final event = EchoObservation(
      sequence: 1,
      elapsedMicros: 1,
      kind: EvidenceKind.dimse,
    );
    final runs = SqliteRunStore(db, eventBytes: event.encodedBytes);
    await runs.begin(summary('exact'));
    expect(await runs.append('exact', event), isA<Success>());
    expect((await db.select(db.runEvents).get()).length, 1);
    final tooSmall = SqliteRunStore(db, eventBytes: event.encodedBytes - 1);
    await tooSmall.append(
      'exact',
      EchoObservation(sequence: 2, elapsedMicros: 1, kind: EvidenceKind.dimse),
    );
    expect((await db.select(db.runEvents).get()).length, 1);
    expect((await db.select(db.runs).getSingle()).omitted, 1);
    await runs.finish(summary('exact', end: now));
    await runs.recoverAndPrune(now.add(const Duration(days: 30)));
    expect((await db.select(db.runs).get()).length, 1);
    await runs.recoverAndPrune(
      now.add(const Duration(days: 30, milliseconds: 1)),
    );
    expect(await db.select(db.runs).get(), isEmpty);
    await db.close();
  });
  test('privacy canaries stay out of persistent run and event projections', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final config = SqliteConfigStore(db);
    final runs = SqliteRunStore(db);
    final saved = (await config.changeNode(
      const AddNode(0, node),
    ) as Success<AppConfiguration>).value;
    await runs.begin(summary('run', nodeId: saved.node!.id));
    await runs.append(
      'run',
      EchoObservation(
        sequence: 1,
        elapsedMicros: 100,
        kind: EvidenceKind.abort,
        source: 2,
        reason: 2,
      ),
    );
    await runs.finish(summary('run', nodeId: saved.node!.id, end: now));
    final text =
        '${(await db.select(db.runs).getSingle()).summary} ${(await db.select(db.runEvents).getSingle()).payload}';
    expect(text, isNot(contains('CANARY')));
    expect(text, isNot(contains('192.0.2.7')));
    await config.close();
  });
  test(
    'v1 migration uses consistent snapshot and preserves configuration',
    () async {
      final dir = Directory.systemTemp.createTempSync('dimsedash-migration-');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/dimsedash.sqlite');
      final old = sqlite3.open(file.path);
      old.execute(
        'CREATE TABLE nodes (id TEXT PRIMARY KEY, label TEXT NOT NULL, called_ae TEXT NOT NULL, host TEXT NOT NULL, port INTEGER NOT NULL, environment TEXT NOT NULL, revision INTEGER NOT NULL)',
      );
      old.execute(
        'CREATE TABLE app_settings (id INTEGER PRIMARY KEY, calling_ae TEXT NOT NULL, listen_port INTEGER NOT NULL, appearance TEXT NOT NULL, revision INTEGER NOT NULL, selected_node_id TEXT REFERENCES nodes(id))',
      );
      old.execute(
        "INSERT INTO nodes VALUES ('id', 'Synthetic', 'PACS_AET', '192.0.2.8', 104, 'test', 2)",
      );
      old.execute(
        "INSERT INTO app_settings VALUES (1, 'CLIENT', 11112, 'dark', 3, 'id')",
      );
      old.execute('PRAGMA user_version=1');
      old.execute('PRAGMA journal_mode=WAL');
      old.close();
      final runtime =
          (await bootstrap(supportDirectory: dir) as Success<AppRuntime>).value;
      expect(runtime.initial.node!.revision, 2);
      expect(runtime.initial.client.appearance, Appearance.dark);
      expect(runtime.initial.client.timeouts.connect, 30);
      expect(File('${file.path}.recovery').existsSync(), isFalse);
      await runtime.close();
      final check = sqlite3.open(file.path);
      expect(check.select('PRAGMA user_version').single.values.single, 2);
      check.close();
    },
  );
  test(
    'recovery snapshot includes committed WAL data before checkpoint',
    () async {
      final dir = Directory.systemTemp.createTempSync(
        'dimsedash-wal-snapshot-',
      );
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/dimsedash.sqlite');
      final writer = sqlite3.open(file.path);
      try {
        writer.execute('PRAGMA journal_mode=WAL');
        writer.execute('PRAGMA wal_autocheckpoint=0');
        writer.execute('CREATE TABLE marker(value TEXT)');
        writer.execute(
          "INSERT INTO marker VALUES ('committed synthetic value')",
        );
        writer.execute('PRAGMA user_version=1');
        expect(File('${file.path}-wal').lengthSync(), greaterThan(0));
        final recovery = await prepareMigration(file);
        final snapshot = sqlite3.open(recovery!.path);
        try {
          expect(
            snapshot.select('SELECT value FROM marker').single.values.single,
            'committed synthetic value',
          );
        } finally {
          snapshot.close();
        }
      } finally {
        writer.close();
      }
    },
  );
  test(
    'failed migration retains original and recovery and blocks reopening',
    () async {
      final dir = Directory.systemTemp.createTempSync('dimsedash-migration-');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/dimsedash.sqlite');
      final old = sqlite3.open(file.path);
      old.execute('CREATE TABLE app_settings(id INTEGER PRIMARY KEY)');
      old.execute('PRAGMA user_version=1');
      old.close();
      expect(await bootstrap(supportDirectory: dir), isA<Failure>());
      expect(File('${file.path}.recovery').existsSync(), isTrue);
      final check = sqlite3.open(file.path);
      expect(check.select('PRAGMA user_version').single.values.single, 1);
      check.close();
      await expectLater(
        prepareMigration(file),
        throwsA(isA<MigrationRecoveryException>()),
      );
    },
  );
}
