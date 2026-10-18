import 'dart:io';

import 'package:dimsedash/app/bootstrap.dart';
import 'package:dimsedash/app/app_runtime.dart';
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/synthetic_configuration.dart';

void main() {
  late Directory dir;
  late File file;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('dimsedash-storage-');
    file = File('${dir.path}/dimsedash.sqlite');
  });
  tearDown(() => dir.deleteSync(recursive: true));
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
