// Expected usage of the plugin will need to be adjacent strings due to format.

import 'dart:async';

import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/cli/cli.dart';

const _pubspec = '''
name: example

dev_dependencies:
  test: any''';

const _unreachableGitUrlPubspec = '''
name: example

dev_dependencies:
  very_good_analysis:
    git:
      url: https://github.com/verygoodopensource/_very_good_analysis
''';

class _TestProcess {
  Future<ProcessResult> run(
    String command,
    List<String> args, {
    bool runInShell = false,
    String? workingDirectory,
  }) {
    throw UnimplementedError();
  }
}

class _MockProcess extends Mock implements _TestProcess;

class _MockLogger extends Mock implements Logger;

class _MockProgress extends Mock implements Progress;

class _FakeGeneratorTarget extends Fake implements GeneratorTarget;

void main() {
  final successProcessResult = ProcessResult(42, ExitCode.success.code, '', '');
  final softwareErrorProcessResult = ProcessResult(
    42,
    ExitCode.software.code,
    '',
    'Some error',
  );

  group(Flutter, () {
    late _TestProcess process;
    late Logger logger;
    late Progress progress;

    setUpAll(() {
      registerFallbackValue(_FakeGeneratorTarget());
      registerFallbackValue(FileConflictResolution.prompt);
    });

    setUp(() {
      logger = _MockLogger();
      progress = _MockProgress();
      when(() => logger.progress(any())).thenReturn(progress);

      process = _MockProcess();
      when(
        () => process.run(
          any(),
          any(),
          runInShell: any(named: 'runInShell'),
          workingDirectory: any(named: 'workingDirectory'),
        ),
      ).thenAnswer((_) async => successProcessResult);
    });

    group('.installed', () {
      test('returns true when flutter is installed', () async {
        when(
          () => process.run(
            'flutter',
            ['--version'],
            runInShell: any(named: 'runInShell'),
            workingDirectory: any(named: 'workingDirectory'),
          ),
        ).thenAnswer((_) async => successProcessResult);

        await ProcessOverrides.runZoned(
          () => expectLater(
            Flutter.installed(logger: logger),
            completion(isTrue),
          ),
          runProcess: process.run,
        );
      });

      test('returns false when flutter is not installed', () async {
        when(
          () => process.run(
            'flutter',
            any(),
            runInShell: any(named: 'runInShell'),
            workingDirectory: any(named: 'workingDirectory'),
          ),
        ).thenThrow(Exception('flutter not installed'));

        await ProcessOverrides.runZoned(
          () => expectLater(
            Flutter.installed(logger: logger),
            completion(isFalse),
          ),
          runProcess: process.run,
        );
      });
    });

    group('.pubGet', () {
      test('throws when there is no pubspec.yaml', () async {
        await ProcessOverrides.runZoned(
          () => expectLater(
            Flutter.pubGet(cwd: Directory.systemTemp.path, logger: logger),
            throwsA(isA<PubspecNotFound>()),
          ),
          runProcess: process.run,
        );
      });

      test('throws when process fails', () async {
        when(
          () => process.run(
            'flutter',
            any(),
            runInShell: any(named: 'runInShell'),
            workingDirectory: any(named: 'workingDirectory'),
          ),
        ).thenAnswer((_) async => softwareErrorProcessResult);

        await ProcessOverrides.runZoned(
          () => expectLater(
            Flutter.pubGet(cwd: Directory.systemTemp.path, logger: logger),
            throwsException,
          ),
          runProcess: process.run,
        );
      });

      test('completes when the process succeeds', () async {
        await ProcessOverrides.runZoned(
          () => expectLater(Flutter.pubGet(logger: logger), completes),
          runProcess: process.run,
        );
      });

      test('completes when the process succeeds (recursive)', () async {
        await ProcessOverrides.runZoned(
          () => expectLater(
            Flutter.pubGet(recursive: true, logger: logger),
            completes,
          ),
          runProcess: process.run,
        );
      });

      test('completes when there is a pubspec.yaml and '
          'directory is ignored (recursive)', () async {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final nestedDirectory = Directory(p.join(tempDirectory.path, 'test'))
          ..createSync();
        final ignoredDirectory = Directory(
          p.join(tempDirectory.path, 'test_plugin'),
        )..createSync();

        File(p.join(nestedDirectory.path, 'pubspec.yaml'))
            .writeAsStringSync(_pubspec);
        File(p.join(ignoredDirectory.path, 'pubspec.yaml'))
            .writeAsStringSync(_pubspec);

        final relativePathPrefix = '.${p.context.separator}';

        await ProcessOverrides.runZoned(
          () => expectLater(
            Dart.pubGet(
              cwd: tempDirectory.path,
              recursive: true,
              ignore: {'test_plugin', '/**/test_plugin_two/**'},
              logger: logger,
            ),
            completes,
          ),
          runProcess: process.run,
        ).whenComplete(() {
          final nestedRelativePath = p.relative(
            nestedDirectory.path,
            from: tempDirectory.path,
          );

          verify(() {
            logger.progress(
              any(
                that: contains(
                  '''Running "dart pub get" in $relativePathPrefix$nestedRelativePath''',
                ),
              ),
            );
          }).called(1);

          verifyNever(() {
            final ignoredRelativePath = p.relative(
              ignoredDirectory.path,
              from: tempDirectory.path,
            );

            logger.progress(
              any(
                that: contains(
                  '''Running "dart pub get" in $relativePathPrefix$ignoredRelativePath''',
                ),
              ),
            );
          });
        });
      });

      test('throws when process fails', () async {
        when(
          () => process.run(
            any(),
            any(),
            runInShell: any(named: 'runInShell'),
            workingDirectory: any(named: 'workingDirectory'),
          ),
        ).thenAnswer((_) async => softwareErrorProcessResult);

        await ProcessOverrides.runZoned(
          () => expectLater(Flutter.pubGet(logger: logger), throwsException),
          runProcess: process.run,
        );
      });

      test('throws when process fails (recursive)', () async {
        when(
          () => process.run(
            any(),
            any(),
            runInShell: any(named: 'runInShell'),
            workingDirectory: any(named: 'workingDirectory'),
          ),
        ).thenAnswer((_) async => softwareErrorProcessResult);

        await ProcessOverrides.runZoned(
          () => expectLater(
            Flutter.pubGet(recursive: true, logger: logger),
            throwsException,
          ),
          runProcess: process.run,
        );
      });

      test('throws when there is an unreachable git url', () async {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        File(p.join(tempDirectory.path, 'pubspec.yaml'))
            .writeAsStringSync(_unreachableGitUrlPubspec);

        when(
          () => process.run(
            'git',
            any(that: contains('ls-remote')),
            runInShell: any(named: 'runInShell'),
            workingDirectory: any(named: 'workingDirectory'),
          ),
        ).thenAnswer((_) async => softwareErrorProcessResult);

        await ProcessOverrides.runZoned(
          () => expectLater(
            () => Flutter.pubGet(cwd: tempDirectory.path, logger: logger),
            throwsA(isA<UnreachableGitDependency>()),
          ),
          runProcess: process.run,
        );
      });

      test('throws ProcessException when pub get times out', () async {
        when(
          () => process.run(
            'flutter',
            any(that: contains('pub')),
            runInShell: any(named: 'runInShell'),
            workingDirectory: any(named: 'workingDirectory'),
          ),
        ).thenAnswer((_) => Completer<ProcessResult>().future);

        await ProcessOverrides.runZoned(
          () => expectLater(
            Flutter.pubGet(
              logger: logger,
              timeout: const Duration(milliseconds: 100),
            ),
            throwsA(
              isA<ProcessException>().having(
                (e) => e.message,
                'message',
                contains('Timed out'),
              ),
            ),
          ),
          runProcess: process.run,
        );
      });
    });
  });

  group(CoverageMetrics, () {
    group('fromLcov', () {
      test('returns empty metrics for an empty record list', () {
        final metrics = CoverageMetrics.fromLcov([]);

        expect(metrics.totalHits, equals(0));
        expect(metrics.totalFound, equals(0));
        expect(metrics.uncoveredLines, isEmpty);
      });

      test('derives the totals and uncovered lines from the line hits', () {
        final metrics = CoverageMetrics.fromLcov([
          LcovRecord('lib/a.dart', lines: {3: 0, 1: 2, 2: 0}),
          LcovRecord('lib/b.dart', lines: {1: 1}),
        ]);

        expect(metrics.totalFound, equals(4));
        expect(metrics.totalHits, equals(2));
        expect(
          metrics.uncoveredLines,
          equals({
            'lib/a.dart': [2, 3],
          }),
        );
      });

      test('accumulates uncovered lines across multiple records', () {
        final metrics = CoverageMetrics.fromLcov([
          LcovRecord('lib/a.dart', lines: {10: 0, 20: 1}),
          LcovRecord('lib/b.dart', lines: {5: 0, 6: 0}),
        ]);

        expect(
          metrics.uncoveredLines,
          equals({
            'lib/a.dart': [10],
            'lib/b.dart': [5, 6],
          }),
        );
      });

      test('handles records with no DA entries', () {
        final metrics = CoverageMetrics.fromLcov([
          LcovRecord('lib/a.dart'),
          LcovRecord('lib/b.dart', lines: {1: 1, 2: 1}),
        ]);

        expect(metrics.totalFound, equals(2));
        expect(metrics.totalHits, equals(2));
        expect(metrics.uncoveredLines, isEmpty);
      });

      test('keeps source paths that contain a colon', () {
        final metrics = CoverageMetrics.fromLcov([
          LcovRecord('C:/runner/lib/a.dart', lines: {1: 0}),
          LcovRecord('D:/runner/lib/b.dart', lines: {1: 0}),
        ]);

        expect(
          metrics.uncoveredLines.keys,
          equals(['C:/runner/lib/a.dart', 'D:/runner/lib/b.dart']),
        );
      });

      group('excludeFromCoverage', () {
        final records = [
          LcovRecord('lib/a.dart', lines: {1: 1, 2: 0}),
          LcovRecord('lib/generated/b.g.dart', lines: {1: 0}),
          LcovRecord('lib/mocks/mock_c.dart', lines: {1: 0}),
        ];

        for (final (description, excludeFromCoverage) in [
          ('handles null', null),
          ('handles empty string', ''),
          ('does not exclude files when no glob matches', 'lib/other/**'),
        ]) {
          test(description, () {
            final metrics = CoverageMetrics.fromLcov(
              records,
              excludeFromCoverage: excludeFromCoverage,
            );

            expect(metrics.totalFound, equals(4));
            expect(metrics.totalHits, equals(1));
          });
        }

        test('excludes a single glob-matched file', () {
          final metrics = CoverageMetrics.fromLcov(
            records,
            excludeFromCoverage: 'lib/generated/**',
          );

          expect(metrics.totalFound, equals(3));
          expect(
            metrics.uncoveredLines.keys,
            isNot(contains(startsWith('lib/generated'))),
          );
        });

        for (final excludeFromCoverage in [
          'lib/generated/** lib/mocks/**',
          'lib/generated/**  lib/mocks/**',
        ]) {
          test('excludes space-separated globs "$excludeFromCoverage"', () {
            final metrics = CoverageMetrics.fromLcov(
              records,
              excludeFromCoverage: excludeFromCoverage,
            );

            expect(metrics.totalFound, equals(2));
            expect(metrics.totalHits, equals(1));
          });
        }

        test('excludes source paths that contain a colon', () {
          final metrics = CoverageMetrics.fromLcov([
            LcovRecord('lib/a.dart', lines: {1: 1}),
            LcovRecord('C:/runner/lib/b.g.dart', lines: {1: 0}),
          ], excludeFromCoverage: '**/*.g.dart');

          expect(metrics.totalFound, equals(1));
          expect(metrics.totalHits, equals(1));
        });

        test('matches globs against paths relative to packagePaths', () {
          final metrics = CoverageMetrics.fromLcov(
            [
              LcovRecord('packages/foo/lib/a.dart', lines: {1: 1}),
              LcovRecord('packages/foo/lib/gen/b.dart', lines: {1: 0}),
              LcovRecord('packages/bar/lib/gen/c.dart', lines: {1: 0}),
            ],
            excludeFromCoverage: 'lib/gen/**',
            packagePaths: ['packages/foo'],
          );

          expect(metrics.totalFound, equals(2));
          expect(
            metrics.uncoveredLines.keys,
            equals(['packages/bar/lib/gen/c.dart']),
          );
        });
      });
    });
  });
}
