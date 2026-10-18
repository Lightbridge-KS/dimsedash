import 'dart:io';

/// Keep the same lock file inode: unlinking it allows a second owner to enter.
class ProcessGuard {
  ProcessGuard._(this._handle);
  final RandomAccessFile _handle;
  static Future<ProcessGuard> acquire(File file) async {
    final handle = await file.open(mode: FileMode.append);
    try {
      await handle.lock(FileLock.exclusive);
      return ProcessGuard._(handle);
    } catch (_) {
      await handle.close();
      rethrow;
    }
  }

  Future<void> close() async {
    await _handle.unlock();
    await _handle.close();
  }
}
