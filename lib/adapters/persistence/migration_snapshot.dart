import 'dart:io';
import 'dart:isolate';

import 'package:sqlite3/sqlite3.dart';

import 'database.dart';

class MigrationRecoveryException implements Exception {}

/// VACUUM INTO reads a consistent SQLite snapshot, including committed WAL data.
/// A retained recovery file blocks writes until recovery is explicitly resolved.
Future<File?> prepareMigration(File file) => Isolate.run(() {
  final recovery = File('${file.path}.recovery');
  if (recovery.existsSync()) throw MigrationRecoveryException();
  if (!file.existsSync()) return null;
  final db = sqlite3.open(file.path);
  try {
    final version =
        db.select('PRAGMA user_version').single.values.single as int;
    if (version > 2) throw NewerSchemaException();
    if (version != 1) return null;
    if (db.select('PRAGMA integrity_check').single.values.single != 'ok') {
      throw StateError('Database integrity check failed.');
    }
    db.execute('VACUUM INTO ?', [recovery.path]);
    return recovery;
  } finally {
    db.close();
  }
});
