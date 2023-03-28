@Tags(['e2e'])
library legacy.core_test;

import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../../../../../helpers/helpers.dart';

void main() {
  test(
    'create -t core',
    withRunner((commandRunner, logger, updater, logs) async {
      final directory = Directory.systemTemp.createTempSync();

      final result = await commandRunner.run(
        ['create', 'very_good_core', '-t', 'core', '-o', directory.path],
      );
      expect(result, equals(ExitCode.success.code));

      final workingDirectory = path.join(directory.path, 'very_good_core');

      await expectSuccessfulProcessResult(
        'dart',
        ['format', '--set-exit-if-changed', '.'],
        workingDirectory: workingDirectory,
      );

      final analyzeResult = await expectSuccessfulProcessResult(
        'flutter',
        ['analyze', '.'],
        workingDirectory: workingDirectory,
      );
      expect(analyzeResult.stdout, contains('No issues found!'));

      final testResult = await expectSuccessfulProcessResult(
        'flutter',
        ['test', '--no-pub', '--coverage', '--reporter', 'compact'],
        workingDirectory: workingDirectory,
      );
      expect(testResult.stdout, contains('All tests passed!'));

      final testCoverageResult = await expectSuccessfulProcessResult(
        'genhtml',
        ['coverage/lcov.info', '-o', 'coverage'],
        workingDirectory: workingDirectory,
      );
      expect(testCoverageResult.stdout, contains('lines......: 100.0%'));
    }),
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
