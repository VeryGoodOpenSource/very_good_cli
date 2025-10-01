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

class _MockProcess extends Mock implements _TestProcess {}

class _MockLogger extends Mock implements Logger {}

class _MockProgress extends Mock implements Progress {}

class _FakeGeneratorTarget extends Fake implements GeneratorTarget {}

void main() {
  final successProcessResult = ProcessResult(
    42,
    ExitCode.success.code,
    '',
    '',
  );
  final softwareErrorProcessResult = ProcessResult(
    42,
    ExitCode.software.code,
    '',
    'Some error',
  );

  group('Flutter', () {
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

      test(
        'completes when there is a pubspec.yaml and '
        'directory is ignored (recursive)',
        () async {
          final tempDirectory = Directory.systemTemp.createTempSync();
          addTearDown(() => tempDirectory.deleteSync(recursive: true));

          final nestedDirectory = Directory(p.join(tempDirectory.path, 'test'))
            ..createSync();
          final ignoredDirectory = Directory(
            p.join(tempDirectory.path, 'test_plugin'),
          )..createSync();

          File(
            p.join(nestedDirectory.path, 'pubspec.yaml'),
          ).writeAsStringSync(_pubspec);
          File(
            p.join(ignoredDirectory.path, 'pubspec.yaml'),
          ).writeAsStringSync(_pubspec);

          final relativePathPrefix = '.${p.context.separator}';

          await ProcessOverrides.runZoned(
            () => expectLater(
              Dart.pubGet(
                cwd: tempDirectory.path,
                recursive: true,
                ignore: {
                  'test_plugin',
                  '/**/test_plugin_two/**',
                },
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
        },
      );

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

        File(
          p.join(tempDirectory.path, 'pubspec.yaml'),
        ).writeAsStringSync(_unreachableGitUrlPubspec);

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
    });
  });
}
