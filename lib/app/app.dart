import 'dart:ui' show AppExitResponse;

import 'package:dimsedash_core/dimsedash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bindings/configuration.dart';
import '../ui/theme.dart';
import 'app_runtime.dart';
import 'shell.dart';

class DimseDashApp extends ConsumerStatefulWidget {
  const DimseDashApp({super.key, required this.runtime});
  final AppRuntime runtime;
  @override
  ConsumerState<DimseDashApp> createState() => _DimseDashAppState();
}

class _DimseDashAppState extends ConsumerState<DimseDashApp> {
  late final AppLifecycleListener _lifecycle;
  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onExitRequested: () async {
        try {
          await widget.runtime.close().timeout(const Duration(seconds: 5));
        } catch (_) {
          /* Forced exit/recovery remains distinct from a completed close. */
        }
        return AppExitResponse.exit;
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appearance = ref.watch(
      configurationProvider.select((c) => c.client.appearance),
    );
    return MaterialApp(
      title: 'DimseDash',
      debugShowCheckedModeBanner: false,
      theme: workbenchTheme(Brightness.light),
      darkTheme: workbenchTheme(Brightness.dark),
      themeMode: switch (appearance) {
        Appearance.system => ThemeMode.system,
        Appearance.light => ThemeMode.light,
        Appearance.dark => ThemeMode.dark,
      },
      home: const WorkbenchShell(),
    );
  }
}

class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp(this.failure, {super.key});
  final AppFailure failure;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'DimseDash',
    theme: workbenchTheme(Brightness.light),
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40),
              const SizedBox(height: 16),
              Text(
                'DimseDash could not open',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(failure.message),
              const SizedBox(height: 12),
              const Text(
                'Close this window after resolving the problem, then launch again.',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
