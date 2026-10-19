import 'dart:io';

import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../adapters/persistence/config_store.dart';
import '../adapters/persistence/database.dart';
import '../adapters/persistence/process_guard.dart';
import '../adapters/persistence/migration_snapshot.dart';
import '../adapters/persistence/run_store.dart';
import '../adapters/dicom/echo_gateway.dart';

import 'package:uuid/uuid.dart';

import 'app_runtime.dart';
import 'build_versions.dart' as versions;

Future<Result<AppRuntime>> bootstrap({Directory? supportDirectory}) async {
  ProcessGuard? guard;
  SqliteConfigStore? store;
  try {
    final dir = supportDirectory ?? await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    try {
      guard = await ProcessGuard.acquire(
        File(p.join(dir.path, 'dimsedash.lock')),
      );
    } on FileSystemException {
      return const Failure(
        AppFailure(
          FailureKind.alreadyOpen,
          'Cannot acquire the application lock. Close another DimseDash window or check storage permissions, then reopen.',
        ),
      );
    }
    final file = File(p.join(dir.path, 'dimsedash.sqlite'));
    final recovery = await prepareMigration(file);
    store = SqliteConfigStore(
      AppDatabase(NativeDatabase.createInBackground(file)),
    );
    final loaded = await store.load();
    if (loaded case Success<AppConfiguration>(:final value)) {
      if (recovery != null) await recovery.delete();
      final runs = SqliteRunStore(store.database);
      final reconciled = await runs.recoverAndPrune(DateTime.now().toUtc());
      if (reconciled is Failure<void>) {
        await store.close();
        await guard.close();
        return Failure(reconciled.error);
      }
      return Success(
        AppRuntime(
          configStore: store,
          initial: value,
          guard: guard,
          runner: OperationRunner(
            configuration: store,
            gateway: DartDicomGateway(),
            store: runs,
            newId: const Uuid().v4,
            appVersion: versions.appVersion,
            libraryVersion: versions.libraryVersion,
          ),
        ),
      );
    }
    await store.close();
    await guard.close();
    if (recovery != null && recovery.existsSync()) {
      return const Failure(
        AppFailure(
          FailureKind.storage,
          'Migration failed. The original data and a consistent recovery snapshot are retained. Recovery is required before further writes.',
        ),
      );
    }
    return Failure((loaded as Failure<AppConfiguration>).error);
  } on MigrationRecoveryException {
    await store?.close();
    await guard?.close();
    return const Failure(
      AppFailure(
        FailureKind.storage,
        'A migration recovery snapshot is present. Writes are blocked. Resolve recovery before reopening; no reset was performed.',
      ),
    );
  } on NewerSchemaException {
    await store?.close();
    await guard?.close();
    return const Failure(
      AppFailure(
        FailureKind.newerSchema,
        'This database was created by a newer DimseDash version. Use that version; no data was changed.',
      ),
    );
  } on FileSystemException {
    await store?.close();
    await guard?.close();
    return const Failure(
      AppFailure(
        FailureKind.storage,
        'Application storage could not be opened. Check access and free space. No reset was performed.',
      ),
    );
  } catch (_) {
    await store?.close();
    await guard?.close();
    return const Failure(
      AppFailure(
        FailureKind.storage,
        'Startup failed. Existing data was preserved. Close the app and check the installation.',
      ),
    );
  }
}
