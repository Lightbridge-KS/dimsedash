import 'dart:io';

import 'package:dimsedash/adapters/persistence/process_guard.dart';

Future<void> main(List<String> args) async {
  try {
    final guard = await ProcessGuard.acquire(File(args.single));
    await guard.close();
  } on FileSystemException {
    exitCode = 42;
  }
}
