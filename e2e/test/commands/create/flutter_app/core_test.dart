import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../../../../helpers/helpers.dart';

void main() {
  test(
    'create flutter_app',
    timeout: const Timeout(Duration(minutes: 2)),
    withRunner((commandRunner, logger, updater, logs, progressLogs) async {
      final tempDirectory = Directory.systemTemp.createTempSync();
      addTearDown(() => tempDirectory.deleteSync(recursive: true));

      final result = await commandRunner.run([
        'create',
        'flutter_app',
        'very_good_core',
        '-o',
        tempDirectory.path,
      ]);
      expect(result, equals(ExitCode.success.code));

      final workingDirectory = path.join(tempDirectory.path, 'very_good_core');

      await expectSuccessfulProcessResult('dart', [
        'format',
      ], workingDirectory: workingDirectory);

      final analyzeResult = await expectSuccessfulProcessResult('flutter', [
        'analyze',
        '.',
      ], workingDirectory: workingDirectory);
      expect(analyzeResult.stdout, contains('No issues found!'));

      final testResult = await expectSuccessfulProcessResult('flutter', [
        'test',
        '--no-pub',
        '--coverage',
        '--reporter',
        'compact',
      ], workingDirectory: workingDirectory);
      expect(testResult.stdout, contains('All tests passed!'));

      final lcovContents = await File(
        path.join(workingDirectory, 'coverage', 'lcov.info'),
      ).readAsString();
      await expectSuccessfulProcessResult(
        'echo',
        [
          lcovContents,
        ],
        workingDirectory: workingDirectory,
      );

      // In the context of a test using withRunner, print() output is typically
      // captured and not shown in the console. To ensure output is visible,
      // use the provided logger or logs list if available.
      // For demonstration, we'll use logger.info (assuming logger is available):

      logger.info(
        '==== coverage/lcov.info ====\n$lcovContents\n==== end coverage/lcov.info ====',
      );

      expect(lcovContents, matches(RegExp('lines(.+) 100.0%')));

      final testCoverageResult = await expectSuccessfulProcessResult(
        'genhtml',
        ['coverage/lcov.info', '-o', 'coverage'],
        workingDirectory: workingDirectory,
      );
      expect(testCoverageResult.stdout, matches(RegExp('lines(.+) 100.0%')));
    }),
  );
}
