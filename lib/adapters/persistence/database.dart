import 'package:drift/drift.dart';
part 'database.g.dart';

class AppSettings extends Table {
  IntColumn get id => integer()();
  TextColumn get callingAe => text()();
  IntColumn get listenPort => integer()();
  TextColumn get appearance => text()();
  IntColumn get revision => integer()();
  IntColumn get connectTimeout => integer().withDefault(const Constant(30))();
  IntColumn get associationTimeout =>
      integer().withDefault(const Constant(30))();
  IntColumn get dimseTimeout => integer().withDefault(const Constant(30))();
  IntColumn get idleTimeout => integer().withDefault(const Constant(60))();
  TextColumn get selectedNodeId => text().nullable().references(Nodes, #id)();
  @override
  Set<Column> get primaryKey => {id};
}

class Nodes extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  TextColumn get calledAe => text()();
  TextColumn get host => text()();
  IntColumn get port => integer()();
  TextColumn get environment => text()();
  IntColumn get revision => integer()();
  @override
  Set<Column> get primaryKey => {id};
}

class NewerSchemaException implements Exception {}

class Runs extends Table {
  TextColumn get id => text()();
  TextColumn get nodeId =>
      text().nullable().references(Nodes, #id, onDelete: KeyAction.setNull)();
  IntColumn get started => integer()();
  IntColumn get ended => integer().nullable()();
  TextColumn get summary => text()();
  IntColumn get omitted => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {id};
}

class RunEvents extends Table {
  TextColumn get runId =>
      text().references(Runs, #id, onDelete: KeyAction.cascade)();
  IntColumn get sequence => integer()();
  TextColumn get payload => text()();
  IntColumn get bytes => integer()();
  @override
  Set<Column> get primaryKey => {runId, sequence};
}

@DriftDatabase(tables: [AppSettings, Nodes, Runs, RunEvents])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);
  @override
  int get schemaVersion => 2;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from > to) throw NewerSchemaException();
      if (from != 1 || to != 2) {
        throw StateError('No migration is defined for this schema.');
      }
      await transaction(() async {
        await customSelect(
          'SELECT id, label, called_ae, host, port, environment, revision FROM nodes LIMIT 0',
        ).get();
        await m.addColumn(appSettings, appSettings.connectTimeout);
        await m.addColumn(appSettings, appSettings.associationTimeout);
        await m.addColumn(appSettings, appSettings.dimseTimeout);
        await m.addColumn(appSettings, appSettings.idleTimeout);
        await m.createTable(runs);
        await m.createTable(runEvents);
        await validateIntegrity();
      });
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await validateIntegrity();
    },
  );
  Future<void> validateIntegrity() async {
    final errors = await customSelect('PRAGMA foreign_key_check').get();
    final integrity = await customSelect('PRAGMA integrity_check').get();
    if (errors.isNotEmpty ||
        integrity.length != 1 ||
        integrity.single.data.values.single != 'ok') {
      throw StateError('Database integrity check failed.');
    }
  }
}
