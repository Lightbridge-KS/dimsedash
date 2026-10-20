import 'dart:io';

import 'package:dimsedash/adapters/persistence/config_store.dart';
import 'package:dimsedash/adapters/persistence/database.dart';
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../../support/synthetic_configuration.dart';

void main() {
  late Directory dir;
  late File file;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('dimsedash-storage-');
    file = File('${dir.path}/dimsedash.sqlite');
  });
  tearDown(() => dir.deleteSync(recursive: true));
  SqliteConfigStore open() =>
      SqliteConfigStore(AppDatabase(NativeDatabase(file)));
  test('global settings never write nodes or change selection across reopen', () async {
    var store = open();
    var saved = (await store.save(draft()) as Success<AppConfiguration>).value;
    saved = (await store.changeNode(
      AddNode(
        saved.revision,
        const PacsNode(
          id: '',
          label: 'Second',
          calledAe: 'SECOND',
          host: '192.0.2.2',
          port: 104,
        ),
      ),
    ) as Success<AppConfiguration>).value;
    final nodesBefore = await store.database
        .customSelect('SELECT * FROM nodes ORDER BY id')
        .get();
    final rowsBefore = nodesBefore.map((r) => r.data).toList();
    // Proves the global-only path does not even issue node writes.
    for (final event in ['INSERT', 'UPDATE', 'DELETE']) {
      await store.database.customStatement(
        "CREATE TRIGGER deny_node_$event BEFORE $event ON nodes BEGIN SELECT RAISE(ABORT, 'node write forbidden'); END",
      );
    }
    final selected = saved.selectedNodeId;
    saved = (await store.saveClientSettings(
      const ClientSettings(
        callingAe: 'GLOBAL_AE',
        listenPort: 11114,
        appearance: Appearance.light,
        timeouts: EchoTimeouts(dimse: 5),
      ),
      expectedRevision: saved.revision,
    ) as Success<AppConfiguration>).value;
    expect(saved.selectedNodeId, selected);
    expect(saved.nodes.length, 2);
    expect(
      (await store.database
              .customSelect('SELECT * FROM nodes ORDER BY id')
              .get())
          .map((r) => r.data)
          .toList(),
      rowsBefore,
    );
    saved = (await store.changeNode(
      SelectNode(saved.revision, null),
    ) as Success<AppConfiguration>).value;
    saved = (await store.saveClientSettings(
      saved.client,
      expectedRevision: saved.revision,
    ) as Success<AppConfiguration>).value;
    expect(saved.selectedNodeId, isNull);
    await store.close();
    store = open();
    final reopened = (await store.load() as Success<AppConfiguration>).value;
    expect(reopened.selectedNodeId, isNull);
    expect(reopened.client.callingAe, 'GLOBAL_AE');
    expect(reopened.client.timeouts.dimse, 5);
    expect(
      (await store.database
              .customSelect('SELECT * FROM nodes ORDER BY id')
              .get())
          .map((r) => r.data)
          .toList(),
      rowsBefore,
    );
    await store.close();
  });

  test('global settings reject stale and invalid drafts and preserve data on storage failure', () async {
    final store = open();
    final initial = (await store.saveClientSettings(
      const ClientSettings(),
      expectedRevision: 0,
    ) as Success<AppConfiguration>).value;
    expect(initial.nodes, isEmpty);
    final edited = (await store.changeNode(
      AddNode(
        initial.revision,
        const PacsNode(
          id: '',
          label: 'Node',
          calledAe: 'PACS_AET',
          host: '192.0.2.1',
          port: 104,
        ),
      ),
    ) as Success<AppConfiguration>).value;
    expect(
      (await store.saveClientSettings(
        const ClientSettings(callingAe: 'STALE'),
        expectedRevision: initial.revision,
      ) as Failure).error.kind,
      FailureKind.conflict,
    );
    expect(
      (await store.saveClientSettings(
        const ClientSettings(listenPort: 0),
        expectedRevision: edited.revision,
      ) as Failure).error.kind,
      FailureKind.validation,
    );
    await store.database.customStatement(
      "CREATE TRIGGER fail_global BEFORE UPDATE ON app_settings BEGIN SELECT RAISE(ABORT, 'synthetic failure'); END",
    );
    expect(
      (await store.saveClientSettings(
        const ClientSettings(callingAe: 'FAILED'),
        expectedRevision: edited.revision,
      ) as Failure).error.kind,
      FailureKind.storage,
    );
    final after = (await store.load() as Success<AppConfiguration>).value;
    expect(after.client.callingAe, 'DIMSE_DASH');
    expect(after.revision, edited.revision);
    expect(after.selectedNodeId, edited.selectedNodeId);
    expect(after.node!.revision, edited.node!.revision);
    await store.close();
    expect(
      (await store.saveClientSettings(
        const ClientSettings(),
        expectedRevision: after.revision,
      ) as Failure).error.kind,
      FailureKind.storage,
    );
  });

  test('persists all fields and stable node identity across reopen', () async {
    var store = open();
    final empty = (await store.load() as Success<AppConfiguration>).value;
    expect(empty.node, isNull);
    final saved =
        (await store.save(draft()) as Success<AppConfiguration>).value;
    expect(saved.revision, 1);
    expect(saved.node!.revision, 1);
    await store.close();
    store = open();
    final restored = (await store.load() as Success<AppConfiguration>).value;
    expect(restored.node!.id, saved.node!.id);
    expect(restored.node!.host, '192.0.2.1');
    expect(restored.node!.calledAe, 'PACS_AET');
    expect(restored.node!.port, 104);
    expect(restored.client.callingAe, 'TEST_CLIENT');
    expect(restored.client.listenPort, 11113);
    expect(restored.client.appearance, Appearance.dark);
    final edited = (await store.save(
      draft(revision: 1, host: '192.0.2.2'),
    ) as Success<AppConfiguration>).value;
    expect(edited.node!.id, saved.node!.id);
    expect(edited.node!.revision, 2);
    expect(saved.node!.host, '192.0.2.1');
    final localOnly = (await store.save(
      AppConfiguration(revision: 2, node: edited.node),
    ) as Success<AppConfiguration>).value;
    expect(localOnly.node!.revision, 2);
    await store.close();
  });
  test('validation and stale writes leave saved state intact', () async {
    final store = open();
    await store.save(draft());
    expect(
      (await store.save(draft()) as Failure).error.kind,
      FailureKind.conflict,
    );
    expect(
      (await store.save(
        draft(revision: 1, host: 'invalid/host'),
      ) as Failure).error.kind,
      FailureKind.validation,
    );
    expect((await store.load() as Success<AppConfiguration>).value.revision, 1);
    await store.close();
  });
  test('failed transaction cannot commit half of a connection', () async {
    final store = open();
    await store.save(draft());
    await store.database.customStatement(
      "CREATE TRIGGER fail_settings BEFORE UPDATE ON app_settings BEGIN SELECT RAISE(ABORT, 'synthetic failure'); END",
    );
    expect(
      await store.save(draft(revision: 1, host: '192.0.2.2')),
      isA<Failure>(),
    );
    final loaded = (await store.load() as Success<AppConfiguration>).value;
    expect(loaded.node!.host, '192.0.2.1');
    expect(loaded.revision, 1);
    await store.close();
  });
  test('close drains accepted writes and rejects new work', () async {
    final store = open();
    final save = store.save(draft());
    final closing = store.close();
    expect(await store.save(draft()), isA<Failure>());
    expect(await save, isA<Success>());
    await closing;
    final reopened = open();
    expect(
      (await reopened.load() as Success<AppConfiguration>).value.revision,
      1,
    );
    await reopened.close();
  });
  test('newer schema refuses startup without lowering its version', () async {
    var db = sqlite3.open(file.path);
    db.execute('PRAGMA user_version = 99');
    db.close();
    final store = open();
    expect((await store.load() as Failure).error.kind, FailureKind.newerSchema);
    await store.close();
    db = sqlite3.open(file.path);
    expect(db.select('PRAGMA user_version').single.values.single, 99);
    db.close();
  });
}
