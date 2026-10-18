import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Production dependency rules. Tests deliberately exercise concrete adapters.
List<String> checkArchitecture(Directory root) {
  final errors = <String>[];
  final base = p.normalize(root.absolute.path);
  const core = 'packages/dimsedash_core/lib';
  final sources = <String>[];
  for (final path in ['lib', core]) {
    final dir = Directory(p.join(base, path));
    final files = dir.existsSync()
        ? dir
              .listSync(recursive: true, followLinks: false)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))
              .toList()
        : <File>[];
    if (files.isEmpty) errors.add('$path: not scaffolded');
    sources.addAll(files.map((f) => p.relative(f.path, from: base)));
  }
  const coreDependencies = {'dartdicom'};
  final declared = <String, Set<String>>{};
  for (final manifest in [
    'pubspec.yaml',
    'packages/dimsedash_core/pubspec.yaml',
  ]) {
    final file = File(p.join(base, manifest));
    if (!file.existsSync()) {
      errors.add('$manifest: not scaffolded');
      continue;
    }
    final yaml = loadYaml(file.readAsStringSync()) as YamlMap;
    final deps = yaml['dependencies'] as YamlMap? ?? YamlMap();
    declared[manifest.startsWith('packages/') ? 'core' : 'app'] = deps.keys
        .cast<String>()
        .toSet();
    if (manifest.startsWith('packages/')) {
      for (final dep in deps.keys) {
        if (!coreDependencies.contains(dep)) {
          errors.add('$manifest -> $dep: forbidden core dependency');
        }
      }
    } else if (!deps.containsKey('dimsedash_core')) {
      errors.add('$manifest: missing core dependency');
    }
  }
  String module(String path) {
    if (path.startsWith('$core/')) {
      final rest = path.substring(core.length + 1);
      return rest.startsWith('src/') ? 'core:${rest.split('/')[1]}' : 'core';
    }
    final parts = path.split('/');
    if (path == 'lib/main.dart' || path.startsWith('lib/app/')) return 'app';
    if (parts.length < 3) return 'unknown';
    return switch (parts[1]) {
      'features' => 'feature:${parts[2]}',
      'adapters' => 'adapter:${parts[2]}',
      'ui' => 'ui',
      'bindings' => 'bindings',
      _ => 'unknown',
    };
  }

  bool allowedLocal(String from, String to) {
    if (from == 'unknown' || to == 'unknown') return false;
    if (from.startsWith('core')) {
      return to == from ||
          to == 'core:foundation' ||
          from == 'core' && to.startsWith('core:');
    }
    if (to == 'core') return true;
    if (to.startsWith('core:')) return false;
    if (from == 'app') return true;
    if (from == to) return true;
    return from.startsWith('feature:') && (to == 'ui' || to == 'bindings');
  }

  for (final source in sources) {
    final owner = module(source);
    if (owner == 'unknown') {
      errors.add('$source: unclassified production module');
    }
    final parsed = parseString(
      content: File(p.join(base, source)).readAsStringSync(),
      throwIfDiagnostics: false,
    );
    for (final error in parsed.errors) {
      errors.add('$source: invalid Dart directive/source: ${error.message}');
    }
    void check(String? raw, {bool part = false}) {
      if (raw == null) {
        errors.add('$source: named part ownership is not supported; use a URI');
        return;
      }
      final uri = Uri.parse(raw);
      String? target;
      if (uri.scheme == 'package') {
        final segments = uri.pathSegments;
        final package = segments.first;
        final rest = segments.skip(1).join('/');
        if (package == 'dimsedash') {
          target = p.normalize('lib/$rest');
        } else if (package == 'dimsedash_core') {
          target = p.normalize('$core/$rest');
        } else {
          if (!(declared[owner.startsWith('core') ? 'core' : 'app'] ?? {})
              .contains(package)) {
            errors.add(
              '$source -> $raw: package is not a direct declared dependency',
            );
          }
          if (part || segments.skip(1).contains('src')) {
            errors.add('$source -> $raw: external private API or part');
          }
          final allowed = owner.startsWith('core')
              ? coreDependencies.contains(package)
              : owner == 'app' ||
                    owner.startsWith('adapter:') ||
                    {'flutter', 'flutter_riverpod'}.contains(package);
          if (!allowed) {
            errors.add('$source -> $raw: forbidden external dependency');
          }
          return;
        }
      } else if (uri.scheme == 'dart') {
        final allowed = owner.startsWith('core')
            ? {
                'async',
                'collection',
                'convert',
                'math',
                'typed_data',
                'core',
              }.contains(uri.path)
            : owner == 'app' ||
                  owner.startsWith('adapter:') ||
                  !{
                    'io',
                    'ffi',
                    'isolate',
                    'html',
                    'js_interop',
                  }.contains(uri.path);
        if (part || !allowed) {
          errors.add('$source -> $raw: forbidden SDK dependency');
        }
        return;
      } else if (uri.scheme.isEmpty) {
        target = p.normalize(p.join(p.dirname(source), uri.path));
      } else {
        errors.add('$source -> $raw: unsupported import URI');
        return;
      }
      final targetOwner = module(target);
      final inTree = sources.contains(target);
      if (!inTree ||
          !allowedLocal(owner, targetOwner) ||
          part &&
              (owner != targetOwner ||
                  p.dirname(source) != p.dirname(target))) {
        errors.add(
          '$source -> $raw ($target): forbidden boundary or missing source',
        );
      }
    }

    for (final directive in parsed.unit.directives) {
      if (directive is NamespaceDirective) {
        check(directive.uri.stringValue);
        for (final branch in directive.configurations) {
          check(branch.uri.stringValue);
        }
      } else if (directive is PartDirective) {
        check(directive.uri.stringValue, part: true);
      } else if (directive is PartOfDirective) {
        check(directive.uri?.stringValue, part: true);
      }
    }
  }
  return errors;
}

void main(List<String> args) {
  final errors = checkArchitecture(Directory(args.isEmpty ? '.' : args.single));
  if (errors.isNotEmpty) {
    stderr.writeln(errors.join('\n'));
    exitCode = 1;
  } else {
    stdout.writeln('Architecture boundaries passed.');
  }
}
