import 'dart:io';

import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../adapters/persistence/config_store.dart';
import '../adapters/persistence/database.dart';
import '../adapters/persistence/process_guard.dart';
import 'app_runtime.dart';

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
    store = SqliteConfigStore(
      AppDatabase(
        NativeDatabase.createInBackground(
          File(p.join(dir.path, 'dimsedash.sqlite')),
        ),
      ),
    );
    final loaded = await store.load();
    if (loaded case Success<AppConfiguration>(:final value)) {
      return Success(
        AppRuntime(configStore: store, initial: value, guard: guard),
      );
    }
    await store.close();
    await guard.close();
    return Failure((loaded as Failure<AppConfiguration>).error);
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
