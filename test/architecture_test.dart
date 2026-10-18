import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/check_architecture.dart';

void main() {
  late Directory root;
  void put(String path, String text) {
    final f = File('${root.path}/$path');
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(text);
  }

  setUp(() {
    root = Directory.systemTemp.createTempSync('dimsedash-boundary-');
    put('pubspec.yaml', 'dependencies:\n  dimsedash_core: any\n');
    put(
      'packages/dimsedash_core/pubspec.yaml',
      'dependencies:\n  dartdicom: any\n',
    );
    put(
      'packages/dimsedash_core/lib/dimsedash_core.dart',
      'export "src/configuration/config.dart";',
    );
    put(
      'packages/dimsedash_core/lib/src/configuration/config.dart',
      'class Config {}',
    );
    put(
      'lib/app/app.dart',
      'import "package:dimsedash_core/dimsedash_core.dart";',
    );
    put('lib/features/settings/view.dart', 'import "../../ui/theme.dart";');
    put('lib/ui/theme.dart', 'class Theme {}');
    put('lib/adapters/persistence/db.dart', 'class Database {}');
  });
  tearDown(() => root.deleteSync(recursive: true));
  test(
    'allowed imports and public exports pass',
    () => expect(checkArchitecture(root), isEmpty),
  );
  for (final directive in [
    'import "../../adapters/persistence/db.dart";',
    'export "package:dimsedash/adapters/persistence/db.dart";',
    'import "../../ui/theme.dart" if (dart.library.io) "../../adapters/persistence/db.dart";',
    'import "package:drift/src/runtime/api/runtime_api.dart";',
    'import "package:dimsedash_core/src/configuration/config.dart";',
    'part "../../adapters/persistence/db.dart";',
    'import "dart:io";',
  ]) {
    test('rejects $directive', () {
      put('lib/features/settings/view.dart', directive);
      expect(checkArchitecture(root), isNotEmpty);
    });
  }
  test('core manifest cannot hide an unused effect dependency', () {
    put(
      'packages/dimsedash_core/pubspec.yaml',
      'dependencies:\n  flutter: any\n',
    );
    expect(checkArchitecture(root), isNotEmpty);
  });
  test('core SDK restriction and normalized traversal apply', () {
    put(
      'packages/dimsedash_core/lib/src/configuration/config.dart',
      'import "dart:io";',
    );
    expect(checkArchitecture(root), isNotEmpty);
    put(
      'lib/features/settings/view.dart',
      'import "../../ui/../adapters/persistence/db.dart";',
    );
    expect(checkArchitecture(root).length, greaterThan(1));
  });
  test('composition cannot rely on an undeclared transitive dependency', () {
    put('lib/app/app.dart', 'import "package:uuid/uuid.dart";');
    expect(
      checkArchitecture(root).join(),
      contains('direct declared dependency'),
    );
  });
  test('empty app cannot give a green gate', () {
    Directory('${root.path}/lib').deleteSync(recursive: true);
    expect(checkArchitecture(root).join(), contains('not scaffolded'));
  });
}
