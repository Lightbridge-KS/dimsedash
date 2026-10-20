import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:drift/drift.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:uuid/uuid.dart';

import 'database.dart';

class SqliteConfigStore implements ConfigStore, NodeStore {
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
  Future<Result<AppConfiguration>> saveClientSettings(
    ClientSettings settings, {
    required int expectedRevision,
  }) {
    if (_closing != null) return Future.value(_storageFailure());
    final operation = _pending.then(
      (_) => _save(
        AppConfiguration(client: settings, revision: expectedRevision),
        clientOnly: true,
      ),
    );
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  @override
  Future<Result<AppConfiguration>> changeNode(NodeCommand command) {
    if (_closing != null) return Future.value(_storageFailure());
    final operation = _pending.then((_) => _changeNode(command));
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<Result<AppConfiguration>> _changeNode(NodeCommand command) async {
    try {
      return await database.transaction(() async {
        final current = await _read();
        if (current.revision != command.expectedRevision) {
          return const Failure<AppConfiguration>(
            AppFailure(
              FailureKind.conflict,
              'Configuration changed. Reload before editing.',
            ),
          );
        }
        String? selected = current.selectedNodeId;
        PacsNode? node;
        switch (command) {
          case AddNode(:final draft):
            node = draft;
          case EditNode(:final node):
            final saved = current.nodes
                .where((n) => n.id == node.id)
                .firstOrNull;
            if (saved == null || saved.revision != node.revision) {
              return const Failure<AppConfiguration>(
                AppFailure(
                  FailureKind.conflict,
                  'Node changed. Reload before editing.',
                ),
              );
            }
          case SelectNode(:final id):
            if (id != null && !current.nodes.any((n) => n.id == id)) {
              return const Failure<AppConfiguration>(
                AppFailure(FailureKind.validation, 'Select a saved node.'),
              );
            }
            selected = id;
          case RemoveNode(:final id):
            if (!current.nodes.any((n) => n.id == id)) {
              return const Failure<AppConfiguration>(
                AppFailure(FailureKind.conflict, 'Node no longer exists.'),
              );
            }
            if (selected == id) {
              selected = null;
              await (database.update(
                database.appSettings,
              )..where((t) => t.id.equals(1))).write(
                const AppSettingsCompanion(selectedNodeId: Value(null)),
              );
            }
            await (database.delete(
              database.nodes,
            )..where((t) => t.id.equals(id))).go();
        }
        if (command is EditNode) node = command.node;
        if (node != null) {
          if (validateConfiguration(
            AppConfiguration(client: current.client, node: node),
          ).isNotEmpty) {
            return const Failure<AppConfiguration>(
              AppFailure(
                FailureKind.validation,
                'Correct the highlighted connection fields.',
              ),
            );
          }
          final id = command is AddNode ? const Uuid().v4() : node.id;
          final old = current.nodes.where((n) => n.id == id).firstOrNull;
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
                  revision: _sameNode(old, node)
                      ? old!.revision
                      : (old?.revision ?? 0) + 1,
                ),
              );
          if (command is AddNode) selected = id;
        }
        await database
            .into(database.appSettings)
            .insertOnConflictUpdate(
              AppSettingsCompanion.insert(
                id: const Value(1),
                callingAe: current.client.callingAe,
                listenPort: current.client.listenPort,
                appearance: current.client.appearance.name,
                revision: current.revision + 1,
                selectedNodeId: Value(selected),
                connectTimeout: Value(current.client.timeouts.connect),
                associationTimeout: Value(current.client.timeouts.association),
                dimseTimeout: Value(current.client.timeouts.dimse),
                idleTimeout: Value(current.client.timeouts.idle),
              ),
            );
        return Success(await _read());
      });
    } on SqliteException {
      return _storageFailure();
    }
  }

  @override
  Future<void> close() => _closing ??= _close();

  Future<Result<AppConfiguration>> _save(
    AppConfiguration draft, {
    bool clientOnly = false,
  }) async {
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
        final node = clientOnly ? null : draft.node;
        String? id = clientOnly ? current.selectedNodeId : null;
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
                connectTimeout: Value(draft.client.timeouts.connect),
                associationTimeout: Value(draft.client.timeouts.association),
                dimseTimeout: Value(draft.client.timeouts.dimse),
                idleTimeout: Value(draft.client.timeouts.idle),
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
    final savedNodes = await database.select(database.nodes).get();
    final nodes = savedNodes
        .map(
          (n) => PacsNode(
            id: n.id,
            label: n.label,
            calledAe: n.calledAe,
            host: n.host,
            port: n.port,
            environment: NodeEnvironment.values.byName(n.environment),
            revision: n.revision,
          ),
        )
        .toList();
    final configuration = AppConfiguration(
      client: ClientSettings(
        callingAe: row.callingAe,
        listenPort: row.listenPort,
        appearance: Appearance.values.byName(row.appearance),
        timeouts: EchoTimeouts(
          connect: row.connectTimeout,
          association: row.associationTimeout,
          dimse: row.dimseTimeout,
          idle: row.idleTimeout,
        ),
      ),
      revision: row.revision,
      nodes: List.unmodifiable(nodes),
      selectedNodeId: row.selectedNodeId,
    );
    if (validateConfiguration(configuration).isNotEmpty ||
        row.revision < 1 ||
        nodes.any(
          (n) =>
              n.revision < 1 ||
              validateConfiguration(AppConfiguration(node: n)).isNotEmpty,
        )) {
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
