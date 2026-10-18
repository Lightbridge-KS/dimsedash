import 'dart:io';

import 'package:dimsedash/adapters/persistence/config_store.dart';
import 'package:dimsedash/adapters/persistence/database.dart';
import 'package:dimsedash/app/bootstrap.dart';
import 'package:dimsedash/app/app_runtime.dart';
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

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
  test('corrupt file is preserved on startup failure', () async {
    final bytes = List.generate(200, (i) => i % 255);
    file.writeAsBytesSync(bytes);
    expect(await bootstrap(supportDirectory: dir), isA<Failure<AppRuntime>>());
    expect(file.readAsBytesSync(), bytes);
  });
  test('runtime can close and reopen the same support directory', () async {
    final first =
        (await bootstrap(supportDirectory: dir) as Success<AppRuntime>).value;
    await first.configStore.save(draft());
    await first.close();
    final second =
        (await bootstrap(supportDirectory: dir) as Success<AppRuntime>).value;
    expect(second.initial.node!.host, '192.0.2.1');
    await second.close();
  });
}

AppConfiguration draft({int revision = 0, String host = '192.0.2.1'}) =>
    AppConfiguration(
      revision: revision,
      client: const ClientSettings(
        callingAe: 'TEST_CLIENT',
        listenPort: 11113,
        appearance: Appearance.dark,
      ),
      node: PacsNode(
        id: '',
        label: 'Synthetic PACS',
        calledAe: 'PACS_AET',
        host: host,
        port: 104,
      ),
    );
