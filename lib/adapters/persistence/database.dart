import 'package:drift/drift.dart';
part 'database.g.dart';

class AppSettings extends Table {
  IntColumn get id => integer()();
  TextColumn get callingAe => text()();
  IntColumn get listenPort => integer()();
  TextColumn get appearance => text()();
  IntColumn get revision => integer()();
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

@DriftDatabase(tables: [AppSettings, Nodes])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);
  @override
  int get schemaVersion => 1;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from > to) throw NewerSchemaException();
      throw StateError('No migration is defined for this schema.');
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
      final errors = await customSelect('PRAGMA foreign_key_check').get();
      if (errors.isNotEmpty) {
        throw StateError('Database integrity check failed.');
      }
    },
  );
}
