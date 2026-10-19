import 'dart:io';

import 'package:dimsedash/app/bootstrap.dart';
import 'package:dimsedash/app/app_runtime.dart';
import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';

/// Separate release-mode verification target; never part of the shipped entrypoint.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      home: Scaffold(body: Center(child: Text('Release Echo verification'))),
    ),
  );
  final directory = await Directory.systemTemp.createTemp(
    'dimsedash-release-probe-',
  );
  AppRuntime? runtime;
  var passed = false;
  try {
    runtime = (await bootstrap(
      supportDirectory: directory,
    ) as Success<AppRuntime>).value;
    final config = (await runtime.configStore.save(
      const AppConfiguration(
        node: PacsNode(
          id: '',
          label: 'Synthetic release peer',
          calledAe: 'PACS_AET',
          host: '127.0.0.1',
          port: int.fromEnvironment('ORTHANC_PORT', defaultValue: 4242),
        ),
      ),
    )) as Success<AppConfiguration>;
    final handle = (await runtime.runner!.start(
      config.value.revision,
    ) as Success<RunHandle>).value;
    await handle.done.timeout(const Duration(seconds: 10));
    passed =
        runtime.runner!.state.summary!.outcome!.status == 0 &&
        runtime.runner!.state.historyAvailable;
  } finally {
    await runtime?.close();
    await directory.delete(recursive: true);
    stdout.writeln(
      passed ? 'DIMSEDASH_RELEASE_ECHO_PASS' : 'DIMSEDASH_RELEASE_ECHO_FAIL',
    );
    exit(passed ? 0 : 1);
  }
}
