import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:drift/drift.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:uuid/uuid.dart';

import 'database.dart';

class SqliteConfigStore implements ConfigStore {
  SqliteConfigStore(this.database);
  final AppDatabase database;
  Future<void> _pending = Future.value();
  Future<void>? _closing;

  @override
  Future<Result<AppConfiguration>> load() async {
    if (_closing != null) return _storageFailure();
    try {
      return Success(await _read());
    } on NewerSchemaException {
      return const Failure(
        AppFailure(
          FailureKind.newerSchema,
          'This database was created by a newer DimseDash version. Use that version; no data was changed.',
        ),
      );
    } on SqliteException {
      return _storageFailure();
    } on ArgumentError {
      return _storageFailure();
    } on StateError {
      return _storageFailure();
    }
  }

  @override
  Future<Result<AppConfiguration>> save(AppConfiguration draft) {
    if (_closing != null) return Future.value(_storageFailure());
    final operation = _pending.then((_) => _save(draft));
    // Await accepted work before closing; a defect must not poison the queue.
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  @override
  Future<void> close() => _closing ??= _close();

  Future<Result<AppConfiguration>> _save(AppConfiguration draft) async {
    if (validateConfiguration(draft).isNotEmpty) {
      return const Failure(
        AppFailure(
          FailureKind.validation,
          'Correct the highlighted connection fields.',
        ),
      );
    }
    try {
      return await database.transaction(() async {
        final current = await _read();
        if (current.revision != draft.revision) {
          return const Failure<AppConfiguration>(
            AppFailure(
              FailureKind.conflict,
              'Settings changed. Reload the saved configuration before applying.',
            ),
          );
        }
        final node = draft.node;
        String? id;
        if (node != null) {
          id = current.node?.id ?? const Uuid().v4();
          await database
              .into(database.nodes)
              .insertOnConflictUpdate(
                NodesCompanion.insert(
                  id: id,
                  label: node.label,
                  calledAe: node.calledAe,
                  host: node.host,
                  port: node.port,
                  environment: node.environment.name,
                  revision: _sameNode(current.node, node)
                      ? current.node!.revision
                      : (current.node?.revision ?? 0) + 1,
                ),
              );
        }
        await database
            .into(database.appSettings)
            .insertOnConflictUpdate(
              AppSettingsCompanion.insert(
                id: const Value(1),
                callingAe: draft.client.callingAe,
                listenPort: draft.client.listenPort,
                appearance: draft.client.appearance.name,
                revision: current.revision + 1,
                selectedNodeId: Value(id),
              ),
            );
        return Success(await _read());
      });
    } on SqliteException {
      return _storageFailure();
    }
  }

  Future<void> _close() async {
    await _pending;
    await database.close();
  }

  bool _sameNode(PacsNode? a, PacsNode b) =>
      a != null &&
      a.label == b.label &&
      a.calledAe == b.calledAe &&
      a.host == b.host &&
      a.port == b.port &&
      a.environment == b.environment;

  Future<AppConfiguration> _read() async {
    final row = await (database.select(
      database.appSettings,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    if (row == null) return const AppConfiguration();
    final node = row.selectedNodeId == null
        ? null
        : await (database.select(
            database.nodes,
          )..where((t) => t.id.equals(row.selectedNodeId!))).getSingle();
    final configuration = AppConfiguration(
      client: ClientSettings(
        callingAe: row.callingAe,
        listenPort: row.listenPort,
        appearance: Appearance.values.byName(row.appearance),
      ),
      revision: row.revision,
      node: node == null
          ? null
          : PacsNode(
              id: node.id,
              label: node.label,
              calledAe: node.calledAe,
              host: node.host,
              port: node.port,
              environment: NodeEnvironment.values.byName(node.environment),
              revision: node.revision,
            ),
    );
    if (validateConfiguration(configuration).isNotEmpty ||
        row.revision < 1 ||
        (node != null && node.revision < 1)) {
      throw StateError('Invalid stored configuration.');
    }
    return configuration;
  }

  Failure<AppConfiguration> _storageFailure() => const Failure(
    AppFailure(
      FailureKind.storage,
      'Configuration storage is unavailable. Existing data was preserved. Check access and free space, then reopen.',
    ),
  );
}
