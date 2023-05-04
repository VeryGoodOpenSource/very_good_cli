import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../../../../helpers/helpers.dart';

void main() {
  test(
    'create flutter_package',
    timeout: const Timeout(Duration(minutes: 2)),
    withRunner((commandRunner, logger, updater, logs) async {
      final tempDirectory = Directory.systemTemp.createTempSync();
      addTearDown(() => tempDirectory.deleteSync(recursive: true));

      final result = await commandRunner.run(
        [
          'create',
          'flutter_package',
          'very_good_flutter',
          '-o',
          tempDirectory.path,
        ],
      );
      expect(result, equals(ExitCode.success.code));

      final workingDirectory =
          path.join(tempDirectory.path, 'very_good_flutter');

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
  );
}
