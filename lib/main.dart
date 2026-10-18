import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/app_runtime.dart';
import 'app/bootstrap.dart';
import 'bindings/configuration.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final result = await bootstrap();
  switch (result) {
    case Success<AppRuntime>(:final value):
      runApp(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            configStoreProvider.overrideWithValue(value.configStore),
            initialConfigurationProvider.overrideWithValue(value.initial),
          ],
          child: DimseDashApp(runtime: value),
        ),
      );
    case Failure<AppRuntime>(:final error):
      runApp(StartupFailureApp(error));
  }
}
