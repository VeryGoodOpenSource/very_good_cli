@Tags(['e2e'])
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../../../../../helpers/helpers.dart';

void main() {
  test(
    'create flame_game',
    withRunner((commandRunner, logger, updater, logs) async {
      final directory = Directory.systemTemp.createTempSync();

      final result = await commandRunner.run(
        [
          'create',
          'flame_game',
          'very_good_flame_game',
          '-o',
          directory.path,
        ],
      );
      expect(result, equals(ExitCode.success.code));

      final formatResult = await Process.run(
        'flutter',
        ['format', '--set-exit-if-changed', '.'],
        workingDirectory: path.join(directory.path, 'very_good_flame_game'),
        runInShell: true,
      );
      expect(formatResult.exitCode, equals(ExitCode.success.code));
      expect(formatResult.stderr, isEmpty);

      final analyzeResult = await Process.run(
        'flutter',
        ['analyze', '.'],
        workingDirectory: path.join(directory.path, 'very_good_flame_game'),
        runInShell: true,
      );
      expect(analyzeResult.exitCode, equals(ExitCode.success.code));
      expect(analyzeResult.stderr, isEmpty);
      expect(analyzeResult.stdout, contains('No issues found!'));

      final testResult = await Process.run(
        'flutter',
        ['test', '--no-pub', '--coverage'],
        workingDirectory: path.join(directory.path, 'very_good_flame_game'),
        runInShell: true,
      );
      expect(testResult.exitCode, equals(ExitCode.success.code));
      expect(testResult.stderr, isEmpty);
      expect(testResult.stdout, contains('All tests passed!'));

      final testCoverageResult = await Process.run(
        'genhtml',
        ['coverage/lcov.info', '-o', 'coverage'],
        workingDirectory: path.join(directory.path, 'very_good_flame_game'),
        runInShell: true,
      );
      expect(testCoverageResult.exitCode, equals(ExitCode.success.code));
      expect(testCoverageResult.stderr, isEmpty);
      expect(testCoverageResult.stdout, contains('lines......: 97.8%'));
    }),
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
