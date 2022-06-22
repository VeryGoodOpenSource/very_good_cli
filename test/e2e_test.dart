@Tags(['e2e'])
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';
import 'package:usage/usage.dart';
import 'package:very_good_cli/src/command_runner.dart';

class MockAnalytics extends Mock implements Analytics {}

class MockLogger extends Mock implements Logger {}

class MockProgress extends Mock implements Progress {}

void main() {
  group(
    'E2E',
    () {
      late Analytics analytics;
      late Logger logger;
      late Progress progress;
      late VeryGoodCommandRunner commandRunner;

      void _removeTemporaryFiles() {
        try {
          Directory('.tmp').deleteSync(recursive: true);
        } catch (_) {}
      }

      setUpAll(_removeTemporaryFiles);
      tearDownAll(_removeTemporaryFiles);

      setUp(() {
        analytics = MockAnalytics();
        logger = MockLogger();

        when(() => analytics.firstRun).thenReturn(false);
        when(() => analytics.enabled).thenReturn(false);
        when(
          () => analytics.sendEvent(any(), any(), label: any(named: 'label')),
        ).thenAnswer((_) async {});
        when(
          () => analytics.waitForLastPing(timeout: any(named: 'timeout')),
        ).thenAnswer((_) async {});

        logger = MockLogger();
        progress = MockProgress();
        when(() => logger.progress(any())).thenReturn(progress);

        commandRunner = VeryGoodCommandRunner(
          analytics: analytics,
          logger: logger,
        );
      });

      test('create -t dart_pkg', () async {
        final directory = Directory(path.join('.tmp', 'very_good_dart'));

        final result = await commandRunner.run(
          ['create', directory.path, '-t', 'dart_pkg'],
        );
        expect(result, equals(ExitCode.success.code));

        final formatResult = await Process.run(
          'flutter',
          ['format', '--set-exit-if-changed', '.'],
          workingDirectory: directory.path,
          runInShell: true,
        );
        expect(formatResult.exitCode, equals(ExitCode.success.code));
        expect(formatResult.stderr, isEmpty);

        final analyzeResult = await Process.run(
          'flutter',
          ['analyze', '.'],
          workingDirectory: directory.path,
          runInShell: true,
        );
        expect(analyzeResult.exitCode, equals(ExitCode.success.code));
        expect(analyzeResult.stderr, isEmpty);
        expect(analyzeResult.stdout, contains('No issues found!'));

        final testResult = await Process.run(
          'flutter',
          ['test', '--no-pub', '--coverage'],
          workingDirectory: directory.path,
          runInShell: true,
        );
        expect(testResult.exitCode, equals(ExitCode.success.code));
        expect(testResult.stderr, isEmpty);
        expect(testResult.stdout, contains('All tests passed!'));

        final testCoverageResult = await Process.run(
          'genhtml',
          ['coverage/lcov.info', '-o', 'coverage'],
          workingDirectory: directory.path,
          runInShell: true,
        );
        expect(testCoverageResult.exitCode, equals(ExitCode.success.code));
        expect(testCoverageResult.stderr, isEmpty);
        expect(testCoverageResult.stdout, contains('lines......: 100.0%'));
      });

      test('create -t flutter_pkg', () async {
        final directory = Directory(path.join('.tmp', 'very_good_flutter'));

        final result = await commandRunner.run(
          ['create', directory.path, '-t', 'flutter_pkg'],
        );
        expect(result, equals(ExitCode.success.code));

        final formatResult = await Process.run(
          'flutter',
          ['format', '--set-exit-if-changed', '.'],
          workingDirectory: directory.path,
          runInShell: true,
        );
        expect(formatResult.exitCode, equals(ExitCode.success.code));
        expect(formatResult.stderr, isEmpty);

        final analyzeResult = await Process.run(
          'flutter',
          ['analyze', '.'],
          workingDirectory: directory.path,
          runInShell: true,
        );
        expect(analyzeResult.exitCode, equals(ExitCode.success.code));
        expect(analyzeResult.stderr, isEmpty);
        expect(analyzeResult.stdout, contains('No issues found!'));

        final testResult = await Process.run(
          'flutter',
          ['test', '--no-pub', '--coverage'],
          workingDirectory: directory.path,
          runInShell: true,
        );
        expect(testResult.exitCode, equals(ExitCode.success.code));
        expect(testResult.stderr, isEmpty);
        expect(testResult.stdout, contains('All tests passed!'));

        final testCoverageResult = await Process.run(
          'genhtml',
          ['coverage/lcov.info', '-o', 'coverage'],
          workingDirectory: directory.path,
          runInShell: true,
        );
        expect(testCoverageResult.exitCode, equals(ExitCode.success.code));
        expect(testCoverageResult.stderr, isEmpty);
        expect(testCoverageResult.stdout, contains('lines......: 100.0%'));
      });

      test('create -t dart_cli', () async {
        final directory = Directory(path.join('.tmp', 'very_good_dart_cli'));

        final result = await commandRunner.run(
          ['create', directory.path, '-t', 'dart_cli'],
        );
        expect(result, equals(ExitCode.success.code));

        final formatResult = await Process.run(
          'flutter',
          ['format', '--set-exit-if-changed', '.'],
          workingDirectory: directory.path,
          runInShell: true,
        );
        expect(formatResult.exitCode, equals(ExitCode.success.code));
        expect(formatResult.stderr, isEmpty);

        final analyzeResult = await Process.run(
          'flutter',
          ['analyze', '.'],
          workingDirectory: directory.path,
          runInShell: true,
        );
        expect(analyzeResult.exitCode, equals(ExitCode.success.code));
        expect(analyzeResult.stderr, isEmpty);
        expect(analyzeResult.stdout, contains('No issues found!'));

        final testResult = await Process.run(
          'flutter',
          ['test', '--no-pub', '--coverage'],
          workingDirectory: directory.path,
          runInShell: true,
        );
        expect(testResult.exitCode, equals(ExitCode.success.code));
        expect(testResult.stderr, isEmpty);
        expect(testResult.stdout, contains('All tests passed!'));

        final testCoverageResult = await Process.run(
          'genhtml',
          ['coverage/lcov.info', '-o', 'coverage'],
          workingDirectory: directory.path,
          runInShell: true,
        );
        expect(testCoverageResult.exitCode, equals(ExitCode.success.code));
        expect(testCoverageResult.stderr, isEmpty);
        expect(testCoverageResult.stdout, contains('lines......: 100.0%'));
      });

      test('create -t core', () async {
        final directory = Directory(path.join('.tmp', 'very_good_core'));

        final result = await commandRunner.run(
          ['create', directory.path, '-t', 'core'],
        );
        expect(result, equals(ExitCode.success.code));

        final formatResult = await Process.run(
          'flutter',
          ['format', '--set-exit-if-changed', '.'],
          workingDirectory: directory.path,
          runInShell: true,
        );
        expect(formatResult.exitCode, equals(ExitCode.success.code));
        expect(formatResult.stderr, isEmpty);

        final analyzeResult = await Process.run(
          'flutter',
          ['analyze', '.'],
          workingDirectory: directory.path,
          runInShell: true,
        );
        expect(analyzeResult.exitCode, equals(ExitCode.success.code));
        expect(analyzeResult.stderr, isEmpty);
        expect(analyzeResult.stdout, contains('No issues found!'));

        final testResult = await Process.run(
          'flutter',
          ['test', '--no-pub', '--coverage'],
          workingDirectory: directory.path,
          runInShell: true,
        );
        expect(testResult.exitCode, equals(ExitCode.success.code));
        expect(testResult.stderr, isEmpty);
        expect(testResult.stdout, contains('All tests passed!'));

        final testCoverageResult = await Process.run(
          'genhtml',
          ['coverage/lcov.info', '-o', 'coverage'],
          workingDirectory: directory.path,
          runInShell: true,
        );
        expect(testCoverageResult.exitCode, equals(ExitCode.success.code));
        expect(testCoverageResult.stderr, isEmpty);
        expect(testCoverageResult.stdout, contains('lines......: 100.0%'));
      });
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );
}
