import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../../../../helpers/helpers.dart';

void main() {
  test(
    'create dart_cli',
    timeout: const Timeout(Duration(minutes: 2)),
    withRunner((commandRunner, logger, updater, logs) async {
      final tempDirectory = Directory.systemTemp.createTempSync();
      addTearDown(() => tempDirectory.deleteSync(recursive: true));

      final result = await commandRunner.run(
        [
          'create',
          'dart_cli',
          'my_cli',
          '-o',
          tempDirectory.path,
        ],
      );
      expect(result, equals(ExitCode.success.code));

      final workingDirectory = path.join(tempDirectory.path, 'my_cli');

      // add coverage to collect coverage on dart test
      await expectSuccessfulProcessResult(
        'dart',
        ['pub', 'add', 'coverage:1.2.0'],
        workingDirectory: workingDirectory,
      );

      await expectSuccessfulProcessResult(
        'dart',
        ['format'],
        workingDirectory: workingDirectory,
      );

      final analyzeResult = await expectSuccessfulProcessResult(
        'flutter',
        ['analyze', '.'],
        workingDirectory: workingDirectory,
      );
      expect(analyzeResult.stdout, contains('No issues found!'));

      final testResult = await expectSuccessfulProcessResult(
        'dart',
        ['test', '--coverage=coverage', '--reporter=compact'],
        workingDirectory: workingDirectory,
      );
      expect(testResult.stdout, contains('All tests passed!'));

      // collect coverage
      await expectSuccessfulProcessResult(
        'dart',
        [
          'pub',
          'run',
          'coverage:format_coverage',
          '--lcov',
          '--in=coverage',
          '--out=coverage/lcov.info',
          '--packages=.dart_tool/package_config.json',
          '--report-on=lib',
        ],
        workingDirectory: workingDirectory,
      );

      final testCoverageResult = await expectSuccessfulProcessResult(
        'genhtml',
        ['coverage/lcov.info', '-o', 'coverage'],
        workingDirectory: workingDirectory,
      );
      expect(testCoverageResult.stdout, contains('lines......: 100.0%'));
    }),
  );
}
