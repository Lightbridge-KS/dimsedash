import 'dart:io';

import 'package:dimsedash/adapters/persistence/process_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('another OS process is refused until the owner closes', () async {
    final dir = Directory.systemTemp.createTempSync('dimsedash-lock-');
    final lock = File('${dir.path}/app.lock');
    final guard = await ProcessGuard.acquire(lock);
    Future<ProcessResult> probe() => Process.run(
      Platform.environment['DART_BIN'] ?? 'dart',
      ['test/support/lock_probe.dart', lock.path],
    );
    try {
      expect((await probe()).exitCode, 42);
    } finally {
      await guard.close();
    }
    try {
      expect((await probe()).exitCode, 0);
      expect(lock.existsSync(), isTrue);
    } finally {
      dir.deleteSync(recursive: true);
    }
  });
}
