@Tags(['e2e'])
library flutter_plugin_test;

import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import '../../../../../helpers/helpers.dart';

void main() {
  test(
    'create flutter_plugin',
    timeout: const Timeout(Duration(minutes: 2)),
    withRunner((commandRunner, logger, updater, logs) async {
      final directory = Directory.systemTemp.createTempSync();
      const pluginName = 'very_good_flutter_plugin';
      final pluginDirectory = path.join(directory.path, pluginName);

      final result = await commandRunner.run(
        ['create', 'flutter_plugin', pluginName, '-o', directory.path],
      );
      expect(
        result,
        equals(ExitCode.success.code),
        reason: '`very_good create flutter_plugin` failed with $result',
      );

      final formatResult = await Process.run(
        'dart',
        ['format', '--set-exit-if-changed', '.'],
        workingDirectory: pluginDirectory,
        runInShell: true,
      );
      expect(
        formatResult.exitCode,
        equals(ExitCode.success.code),
        reason: '`dart format` failed with ${formatResult.stderr}',
      );
      expect(formatResult.stderr, isEmpty);

      final analyzeResult = await Process.run(
        'flutter',
        ['analyze', '.'],
        workingDirectory: pluginDirectory,
        runInShell: true,
      );
      expect(
        analyzeResult.exitCode,
        equals(ExitCode.success.code),
        reason: '`flutter analyze` failed with ${analyzeResult.stderr}',
      );
      expect(analyzeResult.stderr, isEmpty);
      expect(analyzeResult.stdout, contains('No issues found!'));

      final testResult = await Process.run(
        'flutter',
        ['test', '--no-pub', '--coverage', '--reporter', 'compact'],
        workingDirectory: pluginDirectory,
        runInShell: true,
      );
      expect(
        testResult.exitCode,
        equals(ExitCode.success.code),
        reason: '`flutter test` failed with ${testResult.stderr}',
      );
      expect(testResult.stderr, isEmpty);
      expect(testResult.stdout, contains('All tests passed!'));

      final testCoverageResult = await Process.run(
        'genhtml',
        ['coverage/lcov.info', '-o', 'coverage'],
        workingDirectory: pluginDirectory,
        runInShell: true,
      );
      expect(
        testCoverageResult.exitCode,
        equals(ExitCode.success.code),
        reason: '`genhtml` failed with ${testCoverageResult.stderr}',
      );
      expect(testCoverageResult.stderr, isEmpty);
      expect(testCoverageResult.stdout, contains('lines......: 100.0%'));

      directory.deleteSync();
    }),
  );
}
