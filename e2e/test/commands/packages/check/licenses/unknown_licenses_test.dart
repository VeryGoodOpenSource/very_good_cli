import 'dart:io';

import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../../../../helpers/helpers.dart';

/// Objectives:
///
/// * Generate a new Dart project using (`dart create`)
/// * Add dependencies to `pubspec.yaml` with an unknown license
/// * Run `very_good packages check licenses` and expect it to
///   report 1 unknown license
void main() {
  test(
    'packages check licenses (unknown license)',
    timeout: const Timeout(Duration(minutes: 2)),
    withRunner((commandRunner, logger, updater, logs, progressLogs) async {
      final tempDirectory = Directory.systemTemp.createTempSync();
      addTearDown(() => tempDirectory.deleteSync(recursive: true));

      const projectName = 'my_dart_project';
      await expectSuccessfulProcessResult('dart', [
        'create',
        'my_dart_project',
        '--no-pub',
      ], workingDirectory: tempDirectory.path);
      final projectPath = path.join(tempDirectory.path, projectName);
      await expectSuccessfulProcessResult('dart', [
        'pub',
        'add',
        'rxdart:0.27.7',
      ], workingDirectory: projectPath);
      await expectSuccessfulProcessResult('dart', [
        'pub',
        'get',
      ], workingDirectory: projectPath);

      final relativeProjectPath = path.relative(
        projectPath,
        from: Directory.current.path,
      );

      final result = await commandRunner.run([
        'packages',
        'check',
        'licenses',
        relativeProjectPath,
      ]);

      expect(
        result,
        equals(ExitCode.success.code),
      );

      expect(
        progressLogs,
        contains('Retrieved 1 license from 1 package of type: unknown (1).'),
      );
    }),
  );
}
