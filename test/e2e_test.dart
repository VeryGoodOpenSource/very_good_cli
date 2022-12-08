@Tags(['e2e'])
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';
import 'package:usage/usage.dart';
import 'package:very_good_cli/src/command_runner.dart';

class _MockAnalytics extends Mock implements Analytics {}

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

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
        analytics = _MockAnalytics();
        logger = _MockLogger();

        when(() => analytics.firstRun).thenReturn(false);
        when(() => analytics.enabled).thenReturn(false);
        when(
          () => analytics.sendEvent(any(), any(), label: any(named: 'label')),
        ).thenAnswer((_) async {});
        when(
          () => analytics.waitForLastPing(timeout: any(named: 'timeout')),
        ).thenAnswer((_) async {});

        logger = _MockLogger();
        progress = _MockProgress();
        when(() => logger.progress(any())).thenReturn(progress);

        commandRunner = VeryGoodCommandRunner(
          analytics: analytics,
          logger: logger,
        );
      });

      group('create', () {
        test('-t dart_pkg', () async {
          final directory = Directory(path.join('.tmp', 'very_good_dart'));

          final result = await commandRunner.run(
            ['create', 'very_good_dart', '-t', 'dart_pkg', '-o', '.tmp'],
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

        test('-t flutter_pkg', () async {
          final directory = Directory(path.join('.tmp', 'very_good_flutter'));

          final result = await commandRunner.run(
            ['create', 'very_good_flutter', '-t', 'flutter_pkg', '-o', '.tmp'],
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

        test('-t dart_cli', () async {
          final directory = Directory(path.join('.tmp', 'very_good_dart_cli'));

          final result = await commandRunner.run(
            ['create', 'very_good_dart_cli', '-t', 'dart_cli', '-o', '.tmp'],
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

        test('-t docs_site', () async {
          final directory = Directory(path.join('.tmp', 'very_good_docs_site'));

          final result = await commandRunner.run(
            ['create', 'very_good_docs_site', '-t', 'docs_site', '-o', '.tmp'],
          );
          expect(result, equals(ExitCode.success.code));

          final installResult = await Process.run(
            'npm',
            ['install'],
            workingDirectory: directory.path,
            runInShell: true,
          );
          expect(installResult.exitCode, equals(ExitCode.success.code));

          final formatResult = await Process.run(
            'npm',
            ['run', 'format'],
            workingDirectory: directory.path,
            runInShell: true,
          );
          expect(formatResult.exitCode, equals(ExitCode.success.code));
          expect(formatResult.stderr, isEmpty);

          final lintResult = await Process.run(
            'npm',
            ['run', 'lint'],
            workingDirectory: directory.path,
            runInShell: true,
          );
          expect(lintResult.exitCode, equals(ExitCode.success.code));
          expect(lintResult.stderr, isEmpty);

          final buildResult = await Process.run(
            'npm',
            ['run', 'build'],
            workingDirectory: directory.path,
            runInShell: true,
          );
          expect(buildResult.exitCode, equals(ExitCode.success.code));
          expect(buildResult.stderr, isEmpty);
        });

        test('-t flame_game', () async {
          final directory =
              Directory(path.join('.tmp', 'very_good_flame_game'));

          final result = await commandRunner.run(
            [
              'create',
              'very_good_flame_game',
              '-t',
              'flame_game',
              '-o',
              '.tmp'
            ],
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
          expect(testCoverageResult.stdout, contains('lines......: 97.8%'));
        });

        test('-t core', () async {
          final directory = Directory(path.join('.tmp', 'very_good_core'));

          final result = await commandRunner.run(
            ['create', 'very_good_core', '-t', 'core', '-o', '.tmp'],
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
      });

      group('test', () {
        setUp(_removeTemporaryFiles);

        test('fails if the project does not exist', () async {
          final directory = Directory(
            path.join(Directory.current.path, '.tmp', 'not_a_project'),
          );
          await directory.create(recursive: true);

          await IOOverrides.runZoned(
            () async {
              final result = await commandRunner.run(['test']);
              expect(result, equals(ExitCode.noInput.code));
            },
            getCurrentDirectory: () => directory,
          );
        });

        test('supports async main methods', () async {
          final directory = Directory(
            path.join(Directory.current.path, '.tmp', 'async_main'),
          );
          await copyDirectory(Directory('test/fixtures/async_main'), directory);

          final pubGetResult = await Process.run(
            'flutter',
            ['pub', 'get'],
            workingDirectory: directory.path,
            runInShell: true,
          );

          expect(pubGetResult.exitCode, equals(ExitCode.success.code));

          await IOOverrides.runZoned(
            () async {
              final result = await commandRunner.run(['test']);
              expect(result, equals(ExitCode.success.code));
            },
            getCurrentDirectory: () => directory,
          );
        });
      });
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Future<void> copyDirectory(Directory from, Directory to) async {
  await to.create(recursive: true);
  await for (final entity in from.list(recursive: true)) {
    final toPath = path.join(
      to.path,
      path.relative(entity.path, from: from.path),
    );
    if (entity is Directory) {
      await Directory(toPath).create();
    } else if (entity is File) {
      await entity.copy(toPath);
    }
  }
}
