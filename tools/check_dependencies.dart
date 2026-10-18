import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Pub's advisory check covers hosted packages; Git pins need separate review.
Future<void> main() async {
  final dart = p.join(p.dirname(Platform.resolvedExecutable), 'dart');
  final result = await Process.run(dart, [
    'pub',
    'outdated',
    '--json',
    '--show-all',
  ]);
  if (result.exitCode != 0) {
    stderr.writeln(result.stderr);
    exitCode = result.exitCode;
    return;
  }
  final report = jsonDecode(result.stdout as String) as Map<String, dynamic>;
  final packages = report['packages'] as List<dynamic>;
  if (packages.isEmpty) throw StateError('No dependency audit results.');
  var failures = 0;
  for (final item in packages.cast<Map<String, dynamic>>()) {
    if (item['isCurrentAffectedByAdvisory'] != false ||
        item['isCurrentRetracted'] != false) {
      stderr.writeln(
        '${item['package']}: advisory, retraction or missing audit status',
      );
      failures++;
    }
  }
  stdout.writeln(
    'Checked ${packages.length} package records; $failures advisory/retraction failures. Git source review remains separate.',
  );
  if (failures > 0) exitCode = 1;
}
