import 'dart:io';

import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../../../../helpers/helpers.dart';

/// Objectives:
///
/// * Generate a new Dart project using (`dart create`)
/// * Add dependencies to `pubspec.yaml` with an MIT license
/// * Run `very_good packages check licenses --forbidden="MIT"` and expect
/// failure
void main() {
  test(
    'packages check licenses --forbidden="MIT"',
    timeout: const Timeout(Duration(minutes: 2)),
    withRunner((commandRunner, logger, updater, logs) async {
      final tempDirectory = Directory.systemTemp.createTempSync();
      addTearDown(() => tempDirectory.deleteSync(recursive: true));

      const projectName = 'my_dart_project';
      await expectSuccessfulProcessResult(
        'dart',
        ['create', 'my_dart_project', '--no-pub'],
        workingDirectory: tempDirectory.path,
      );
      final projectPath = path.join(tempDirectory.path, projectName);
      await expectSuccessfulProcessResult(
        'dart',
        ['pub', 'add', 'formz'],
        workingDirectory: projectPath,
      );
      await expectSuccessfulProcessResult(
        'dart',
        ['pub', 'get'],
        workingDirectory: projectPath,
      );

      final relativeProjectPath = path.relative(
        projectPath,
        from: Directory.current.path,
      );

      final resultForbidden = await commandRunner.run(
        [
          'packages',
          'check',
          'licenses',
          '--forbidden=MIT',
          relativeProjectPath,
        ],
      );
      expect(
        resultForbidden,
        equals(ExitCode.config.code),
        reason: 'Should fail when forbidden licenses are used',
      );
    }),
  );
}
