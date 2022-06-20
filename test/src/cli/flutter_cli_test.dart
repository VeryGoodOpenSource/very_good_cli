import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/cli/cli.dart';

const otherContents = '''
class Other {
  void foo() {
    print('hello world');
  }
}''';

const calculatorContents = '''
class Calculator {
  int add(int x, int y) => x + y;
  int subtract(int x, int y) => x - y;
}''';

const calculatorTestContents = '''
import 'package:test/test.dart';
import 'package:example/calculator.dart';

void main() {
  test('...', () {
    expect(Calculator().add(1, 2), equals(3));
    expect(Calculator().subtract(43, 1), equals(42));
  });
}''';

const calculatorTestContentsMissingCoverage = '''
import 'package:test/test.dart';
import 'package:example/calculator.dart';

void main() {
  test('...', () {
    expect(Calculator().add(1, 2), equals(3));
  });
}''';

const calculatorTestContentsWithOtherImport = '''
import 'package:test/test.dart';
import 'package:example/calculator.dart';
import 'package:example/other.dart';

void main() {
  test('...', () {
    expect(Calculator().add(1, 2), equals(3));
    expect(Calculator().subtract(43, 1), equals(42));
  });
}''';

const testContents = '''
import 'package:test/test.dart';

void main() {
  test('example', () {
    expect(true, isTrue);
  });
}''';

const flutterTestContents = '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('example', () {
    expect(true, isTrue);
  });
}''';

const flutterGoldenTestContents = '''
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('test with golden', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          appBar: AppBar(),
          body: Center(child: ColoredBox(color: Colors.blue)),
        ),
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('golden_test.png'),
    );
  });
}
''';

const longTestNameContents = '''
import 'package:test/test.dart';

void main() {
  test('reeeeeaaaaalllllllllyyyyyyyyyyyloooonnnnnnngggggggggtestttttttttttttttnameeeeeeeeeeeeeeeee', () {
    expect(true, isTrue);
  });
}''';

const extraLongTestNameContents = '''
import 'package:test/test.dart';

void main() {
  test('reeeeeaaaaalllllllllyyyyyyyyyyyloooonnnnnnngggggggggtestttttttttttttttnameeeeeeeeeeeeeeeee', () {
    expect(true, isTrue);
  });

  test('extraaaaaareeeeeaaaaalllllllllyyyyyyyyyyyloooonnnnnnngggggggggtestttttttttttttttnameeeeeeeeeeeeeeeee', () {
    expect(true, isFalse);
  });

  test('superrrrrrr  extraaaaaa  reeeeeaaaaalllllllllyyyyyyyyyyy   loooonnnnnnnggggggggg    testtttttttttttttt  nameeeeeeeeeeeeeeeee', () {
    expect(true, isFalse);
  }, skip: true);
}''';

const loggingTestContents = '''
import 'package:test/test.dart';

void main() {
  test('example', () {
    print('Hello World!');
    expect(true, isTrue);
  });
}''';

const failingTestContents = '''
import 'package:test/test.dart';
void main() {
  test('example', () {
    expect(true, isFalse);
  });
}''';

const exceptionTestContents = '''
import 'package:test/test.dart';
void main() {
  test('example', () {
    print('EXCEPTION');
    throw Exception('oops');
  });
}''';

const registerExceptionNoStackTraceContents = '''
import 'package:test/test.dart';
import 'package:stack_trace/stack_trace.dart' as stack_trace;
void main() {
  test('example', () {
    print('EXCEPTION');
    registerException(
      'fake error',
      stack_trace.Chain(<stack_trace.Trace>[]),
    );
  });
}''';

String registerExceptionCustomStackTraceContents(String stackTrace) => '''
import 'package:test/test.dart';
import 'package:stack_trace/stack_trace.dart' as stack_trace;
void main() {
  test('example', () {
    print('EXCEPTION');
    registerException(
      'fake error',
      stack_trace.Trace.parse('$stackTrace'),
    );
  });
}''';

const skippedTestContents = '''
import 'package:test/test.dart';
void main() {
  test('skipped example', () {
    expect(true, isTrue);
  }, skip: true);

  test('example', () {
    expect(true, isTrue);
  });
}''';

const tagsTestContents = '''
import 'package:test/test.dart';
void main() {
  test('skipped example', () {
    expect(true, isTrue);
  }, tags: 'pr-only');

  test('example', () {
    expect(true, isTrue);
  });
}''';

const dartTestYamlContents = '''
tags:
  pr-only:
    skip: "Should only be run during pull request"  
''';

const pubspec = '''
name: example
environment:
  sdk: ">=2.13.0 <3.0.0"

dev_dependencies:
  test: any''';

const pubspecFlutter = '''
name: example
environment:
  sdk: ">=2.13.0 <3.0.0"

dev_dependencies:
  flutter_test:
    sdk: flutter''';

const invalidPubspec = 'name: example';

const unreachableGitUrlPubspec = '''
name: example
environment:
  sdk: ">=2.13.0 <3.0.0"

dev_dependencies:
  very_good_analysis:
    git:
      url: https://github.com/verygoodopensource/_very_good_analysis''';

class MockLogger extends Mock implements Logger {}

class MockProgress extends Mock implements Progress {}

void main() {
  final cwd = Directory.current;

  group('Flutter', () {
    group('.packagesGet', () {
      test('throws when there is no pubspec.yaml', () {
        expectLater(
          Flutter.packagesGet(cwd: Directory.systemTemp.path),
          throwsException,
        );
      });

      test('throws when process fails', () {
        final directory = Directory.systemTemp.createTempSync();
        File(p.join(directory.path, 'pubspec.yaml'))
            .writeAsStringSync(invalidPubspec);

        expectLater(
          Flutter.packagesGet(cwd: directory.path),
          throwsException,
        );
      });

      test('throws when there is an unreachable git url', () {
        final directory = Directory.systemTemp.createTempSync();
        File(p.join(directory.path, 'pubspec.yaml'))
            .writeAsStringSync(unreachableGitUrlPubspec);

        expectLater(
          Flutter.packagesGet(cwd: directory.path),
          throwsA(isA<UnreachableGitDependency>()),
        );
      });

      test('completes when there is a pubspec.yaml', () {
        expectLater(Flutter.packagesGet(), completes);
      });

      test('throws when there is no pubspec.yaml (recursive)', () {
        final directory = Directory.systemTemp.createTempSync();
        expectLater(
          Flutter.packagesGet(cwd: directory.path, recursive: true),
          throwsException,
        );
      });

      test('completes when there is a pubspec.yaml (recursive)', () {
        final directory = Directory.systemTemp.createTempSync();
        final nestedDirectory = Directory(p.join(directory.path, 'test'))
          ..createSync();
        File(p.join(nestedDirectory.path, 'pubspec.yaml'))
            .writeAsStringSync(pubspec);
        expectLater(
          Flutter.packagesGet(cwd: directory.path, recursive: true),
          completes,
        );
      });
    });

    group('.pubGet', () {
      test('throws when there is no pubspec.yaml', () {
        expectLater(
          Flutter.pubGet(cwd: Directory.systemTemp.path),
          throwsException,
        );
      });

      test('throws when process fails', () {
        final directory = Directory.systemTemp.createTempSync();
        File(p.join(directory.path, 'pubspec.yaml'))
            .writeAsStringSync(invalidPubspec);

        expectLater(
          Flutter.pubGet(cwd: directory.path),
          throwsException,
        );
      });

      test('throws when there is an unreachable git url', () {
        final directory = Directory.systemTemp.createTempSync();
        File(p.join(directory.path, 'pubspec.yaml'))
            .writeAsStringSync(unreachableGitUrlPubspec);

        expectLater(
          Flutter.packagesGet(cwd: directory.path),
          throwsA(isA<UnreachableGitDependency>()),
        );
      });

      test('completes when there is a pubspec.yaml', () {
        final directory = Directory.systemTemp.createTempSync();
        File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync(pubspec);
        expectLater(Flutter.pubGet(cwd: directory.path), completes);
      });

      test('throws when there is no pubspec.yaml (recursive)', () {
        final directory = Directory.systemTemp.createTempSync();
        expectLater(
          Flutter.pubGet(cwd: directory.path, recursive: true),
          throwsException,
        );
      });

      test('completes when there is a pubspec.yaml (recursive)', () {
        final directory = Directory.systemTemp.createTempSync();
        final nestedDirectory = Directory(p.join(directory.path, 'test'))
          ..createSync();
        File(p.join(nestedDirectory.path, 'pubspec.yaml'))
            .writeAsStringSync(pubspec);
        expectLater(
          Flutter.pubGet(cwd: directory.path, recursive: true),
          completes,
        );
      });
    });

    group('.test', () {
      late Logger logger;
      late Progress progress;

      setUp(() {
        logger = MockLogger();
        progress = MockProgress();
        when(() => logger.progress(any())).thenReturn(progress);
      });

      test('throws when there is no pubspec.yaml', () {
        expectLater(
          Flutter.test(cwd: Directory.systemTemp.path),
          throwsException,
        );
      });

      test('exits with code 69 when process fails (with cleanup)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final testDirectory = Directory(p.join(directory.path, 'test'))
          ..createSync();
        File(p.join(directory.path, 'pubspec.yaml'))
            .writeAsStringSync(pubspecFlutter);
        File(p.join(testDirectory.path, 'example_test.dart'))
            .writeAsStringSync(testContents);
        await expectLater(
          Flutter.test(cwd: directory.path, optimizePerformance: true),
          completion(equals([69])),
        );
        await File(
          p.join(testDirectory.path, '.test_runner.dart'),
        ).ensureDeleted();
      });

      test('exits with code 0 when there is no test directory', () {
        final directory = Directory.systemTemp.createTempSync();
        File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync(pubspec);

        expectLater(
          Flutter.test(cwd: directory.path, stdout: logger.write),
          completion(equals([ExitCode.success.code])),
        );

        verify(
          () => logger.write(
            any(
              that: contains(
                'No test folder found in ${directory.path}\n',
              ),
            ),
          ),
        ).called(1);
      });

      test('throws when there is no pubspec.yaml (recursive)', () {
        final directory = Directory.systemTemp.createTempSync();
        expectLater(
          Flutter.test(cwd: directory.path, recursive: true),
          throwsException,
        );
      });

      test('completes when there is a test directory (failing)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final testDirectory = Directory(p.join(directory.path, 'test'))
          ..createSync();
        File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync(pubspec);
        final testFile = File(
          p.join(testDirectory.path, 'example_test.dart'),
        )..writeAsStringSync(failingTestContents);
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            stdout: logger.write,
            stderr: logger.err,
          ),
          completion(equals([ExitCode.unavailable.code])),
        );
        verify(
          () => logger.write(
            any(
              that: contains(
                'Running "flutter test" in ${p.dirname(directory.path)}',
              ),
            ),
          ),
        ).called(1);
        verify(
          () => logger.err(any(that: contains('${testFile.path} (FAILED)'))),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('-1: example'))),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('Some tests failed.'))),
        ).called(1);
        verify(
          () => logger.err(
            any(that: contains('- [FAILED] test/example_test.dart:4:5')),
          ),
        ).called(1);
      });

      test('completes when there is a test directory (skipping)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final testDirectory = Directory(p.join(directory.path, 'test'))
          ..createSync();
        File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync(pubspec);
        final testFile = File(
          p.join(testDirectory.path, 'example_test.dart'),
        )..writeAsStringSync(skippedTestContents);
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            stdout: logger.write,
            stderr: logger.err,
          ),
          completion(equals([ExitCode.success.code])),
        );
        verify(
          () => logger.write(
            any(
              that: contains(
                'Running "flutter test" in ${p.dirname(directory.path)}',
              ),
            ),
          ),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('${testFile.path} (SKIPPED)'))),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('+1 ~1: example'))),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('+1 ~1: All tests passed!'))),
        ).called(1);
      });

      test('completes when there is a test directory (tags)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final testDirectory = Directory(p.join(directory.path, 'test'))
          ..createSync();
        File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync(pubspec);
        File(
          p.join(directory.path, 'dart_test.yaml'),
        ).writeAsStringSync(dartTestYamlContents);
        final testFile = File(
          p.join(testDirectory.path, 'example_test.dart'),
        )..writeAsStringSync(tagsTestContents);
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            stdout: logger.write,
            stderr: logger.err,
          ),
          completion(equals([ExitCode.success.code])),
        );
        verify(
          () => logger.write(
            any(
              that: contains(
                'Running "flutter test" in ${p.dirname(directory.path)}',
              ),
            ),
          ),
        ).called(1);
        verify(
          () => logger.write(
            any(that: contains('Skip: Should only be run during pull request')),
          ),
        );
        verify(
          () => logger.write(any(that: contains('${testFile.path} (SKIPPED)'))),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('+1 ~1: example'))),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('+1 ~1: All tests passed!'))),
        ).called(1);
      });

      test('completes when there is a test directory (w/logs)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final testDirectory = Directory(p.join(directory.path, 'test'))
          ..createSync();
        File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync(pubspec);
        File(
          p.join(testDirectory.path, 'example_test.dart'),
        ).writeAsStringSync(loggingTestContents);
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            stdout: logger.write,
            stderr: logger.err,
          ),
          completion(equals([ExitCode.success.code])),
        );
        verify(
          () => logger.write(
            any(
              that: contains(
                'Running "flutter test" in ${p.dirname(directory.path)}',
              ),
            ),
          ),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('Hello World'))),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('+1: example'))),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('+1: All tests passed!'))),
        ).called(1);
      });

      test('completes when there is a test directory (w/exception)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final testDirectory = Directory(p.join(directory.path, 'test'))
          ..createSync();
        File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync(pubspec);
        File(
          p.join(testDirectory.path, 'example_test.dart'),
        ).writeAsStringSync(exceptionTestContents);
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            stdout: logger.write,
            stderr: logger.err,
          ),
          completion(equals([ExitCode.unavailable.code])),
        );
        verify(
          () => logger.write(
            any(
              that: contains(
                'Running "flutter test" in ${p.dirname(directory.path)}',
              ),
            ),
          ),
        ).called(1);
        verify(() => logger.err(any(that: contains('EXCEPTION')))).called(1);
        verify(
          () => logger.err(any(that: contains('Exception: oops'))),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('-1: example'))),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('-1: Some tests failed.'))),
        ).called(1);
        verify(
          () => logger
              .err(any(that: contains('- [ERROR] test/example_test.dart:5:5'))),
        ).called(1);
      });

      test(
        'completes when there is a test directory (exception w/o trace)',
        () async {
          final directory = Directory.systemTemp.createTempSync();
          final testDirectory = Directory(p.join(directory.path, 'test'))
            ..createSync();
          File(p.join(directory.path, 'pubspec.yaml'))
              .writeAsStringSync(pubspec);
          File(
            p.join(testDirectory.path, 'example_test.dart'),
          ).writeAsStringSync(registerExceptionNoStackTraceContents);
          await expectLater(
            Flutter.test(
              cwd: directory.path,
              stdout: logger.write,
              stderr: logger.err,
            ),
            completion(equals([ExitCode.unavailable.code])),
          );
          verify(
            () => logger.write(
              any(
                that: contains(
                  'Running "flutter test" in ${p.dirname(directory.path)}',
                ),
              ),
            ),
          ).called(1);
          verify(() => logger.err(any(that: contains('EXCEPTION')))).called(1);
          verify(
            () => logger.write(any(that: contains('-1: Some tests failed.'))),
          ).called(1);
          verify(
            () => logger.err(any(that: contains('- [ERROR] fake error'))),
          ).called(1);
        },
      );

      test(
        'completes when there is a test directory (exception w/ custom trace)',
        () async {
          final directory = Directory.systemTemp.createTempSync();
          final testDirectory = Directory(p.join(directory.path, 'test'))
            ..createSync();
          File(p.join(directory.path, 'pubspec.yaml'))
              .writeAsStringSync(pubspec);
          File(
            p.join(testDirectory.path, 'example_test.dart'),
          ).writeAsStringSync(
            registerExceptionCustomStackTraceContents(
              'test/example_test.dart 4 main',
            ),
          );
          await expectLater(
            Flutter.test(
              cwd: directory.path,
              stdout: logger.write,
              stderr: logger.err,
            ),
            completion(equals([ExitCode.unavailable.code])),
          );
          verify(
            () => logger.write(
              any(
                that: contains(
                  'Running "flutter test" in ${p.dirname(directory.path)}',
                ),
              ),
            ),
          ).called(1);
          verify(() => logger.err(any(that: contains('EXCEPTION')))).called(1);
          verify(
            () => logger.write(any(that: contains('-1: Some tests failed.'))),
          ).called(1);
          verify(
            () => logger.err(
              any(that: contains('- [ERROR] test/example_test.dart:4')),
            ),
          ).called(1);
        },
      );

      test('completes and truncates really long test name', () async {
        final directory = Directory.systemTemp.createTempSync();
        final testDirectory = Directory(p.join(directory.path, 'test'))
          ..createSync();
        File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync(pubspec);
        File(
          p.join(testDirectory.path, 'example_test.dart'),
        ).writeAsStringSync(longTestNameContents);
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            stdout: logger.write,
            stderr: logger.err,
          ),
          completion(equals([ExitCode.success.code])),
        );
        verify(
          () => logger.write(
            any(
              that: contains(
                'Running "flutter test" in ${p.dirname(directory.path)}',
              ),
            ),
          ),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('+1: ...'))),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('+1: All tests passed!'))),
        ).called(1);
      });

      test('completes and truncates extra long test name', () async {
        final directory = Directory.systemTemp.createTempSync();
        final testDirectory = Directory(p.join(directory.path, 'test'))
          ..createSync();
        File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync(pubspec);
        File(
          p.join(testDirectory.path, 'example_test.dart'),
        ).writeAsStringSync(extraLongTestNameContents);
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            stdout: logger.write,
            stderr: logger.err,
          ),
          completion(equals([ExitCode.unavailable.code])),
        );
        verify(
          () => logger.write(
            any(
              that: contains(
                'Running "flutter test" in ${p.dirname(directory.path)}',
              ),
            ),
          ),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('+1: ...'))),
        ).called(1);
        verify(
          () => logger.write(
            any(that: contains('+1 -1 ~1: Some tests failed.')),
          ),
        ).called(1);
      });

      test('completes when there is a test directory w/out stdout,stderr', () {
        final directory = Directory.systemTemp.createTempSync();
        final testDirectory = Directory(p.join(directory.path, 'test'))
          ..createSync();
        File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync(pubspec);
        File(
          p.join(testDirectory.path, 'example_test.dart'),
        ).writeAsStringSync(testContents);
        expectLater(
          Flutter.test(cwd: directory.path),
          completion(equals([ExitCode.success.code])),
        );
      });

      test('completes when there is a test directory (passing)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final testDirectory = Directory(p.join(directory.path, 'test'))
          ..createSync();
        File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync(pubspec);
        File(
          p.join(testDirectory.path, 'example_test.dart'),
        ).writeAsStringSync(testContents);
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            stdout: logger.write,
            stderr: logger.err,
          ),
          completion(equals([ExitCode.success.code])),
        );
        verify(
          () => logger.write(
            any(
              that: contains(
                'Running "flutter test" in ${p.dirname(directory.path)}',
              ),
            ),
          ),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('+1: All tests passed!'))),
        ).called(1);
      });

      test(
          'completes when there is a test directory w/optimizations Dart (passing)',
          () async {
        final directory = Directory.systemTemp.createTempSync();
        final testDirectory = Directory(p.join(directory.path, 'test'))
          ..createSync();
        File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync(pubspec);
        File(
          p.join(testDirectory.path, 'example_test.dart'),
        ).writeAsStringSync(testContents);
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            optimizePerformance: true,
            stdout: logger.write,
            stderr: logger.err,
            logger: logger,
          ),
          completion(equals([ExitCode.success.code])),
        );
        verify(() => logger.progress('Optimizing tests')).called(1);
        verify(
          () => logger.write(
            any(
              that: contains(
                'Running "flutter test" in ${p.dirname(directory.path)}',
              ),
            ),
          ),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('+1: All tests passed!'))),
        ).called(1);
      });

      test(
          'completes when there is a test directory w/optimizations Flutter (passing)',
          () async {
        final directory = Directory.systemTemp.createTempSync();
        final testDirectory = Directory(p.join(directory.path, 'test'))
          ..createSync();
        File(
          p.join(directory.path, 'pubspec.yaml'),
        ).writeAsStringSync(pubspecFlutter);
        File(
          p.join(testDirectory.path, 'example_test.dart'),
        ).writeAsStringSync(flutterTestContents);
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            optimizePerformance: true,
            stdout: logger.write,
            stderr: logger.err,
            logger: logger,
          ),
          completion(equals([ExitCode.success.code])),
        );
        verify(() => logger.progress('Optimizing tests')).called(1);
        verify(
          () => logger.write(
            any(
              that: contains(
                'Running "flutter test" in ${p.dirname(directory.path)}',
              ),
            ),
          ),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('+1: All tests passed!'))),
        ).called(1);
      });

      test(
          'completes when there is a nested golden test w/optimizations Flutter (passing)',
          () async {
        final directory = Directory.systemTemp.createTempSync();
        final testDirectory = Directory(p.join(directory.path, 'test'))
          ..createSync();
        final goldenTestDirectory =
            Directory(p.join(testDirectory.path, 'golden'))..createSync();
        File(
          p.join(directory.path, 'pubspec.yaml'),
        ).writeAsStringSync(pubspecFlutter);
        File(
          p.join(goldenTestDirectory.path, 'golden_test.dart'),
        ).writeAsStringSync(flutterGoldenTestContents);
        File(
          p.join(goldenTestDirectory.path, 'golden_test.png'),
        ).writeAsBytesSync(
          File(p.join(cwd.path, 'test', 'fixtures', 'golden_test.png'))
              .readAsBytesSync(),
        );
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            optimizePerformance: true,
            stdout: logger.write,
            stderr: logger.err,
            logger: logger,
          ),
          completion(equals([ExitCode.success.code])),
        );
        verify(() => logger.progress('Optimizing tests')).called(1);
        verify(
          () => logger.write(
            any(
              that: contains(
                'Running "flutter test" in ${p.dirname(directory.path)}',
              ),
            ),
          ),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('+1: All tests passed!'))),
        ).called(1);
      });

      test('completes when there is a test directory (recursive)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final nestedDirectory = Directory(p.join(directory.path, 'nested'))
          ..createSync();
        final testDirectory = Directory(p.join(nestedDirectory.path, 'test'))
          ..createSync();
        File(
          p.join(nestedDirectory.path, 'pubspec.yaml'),
        ).writeAsStringSync(pubspec);
        File(
          p.join(testDirectory.path, 'example_test.dart'),
        ).writeAsStringSync(testContents);
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            recursive: true,
            stdout: logger.write,
            stderr: logger.err,
          ),
          completion(equals([ExitCode.success.code])),
        );
        verify(
          () => logger.write(
            any(
              that: contains(
                'Running "flutter test" in ${p.dirname(nestedDirectory.path)}',
              ),
            ),
          ),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('+1: All tests passed!'))),
        ).called(1);
      });

      test('completes w specific test target', () async {
        final directory = Directory.systemTemp.createTempSync();
        final libDirectory = Directory(p.join(directory.path, 'lib'))
          ..createSync();
        final testDirectory = Directory(p.join(directory.path, 'test'))
          ..createSync();
        File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync(pubspec);
        File(
          p.join(libDirectory.path, 'calculator.dart'),
        ).writeAsStringSync(calculatorContents);
        File(
          p.join(testDirectory.path, 'calculator_test.dart'),
        ).writeAsStringSync(calculatorTestContents);
        final otherTest = File(
          p.join(testDirectory.path, 'other_test.dart'),
        )..writeAsStringSync(testContents);
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            stdout: logger.write,
            stderr: logger.err,
            arguments: [otherTest.path],
          ),
          completion(equals([ExitCode.success.code])),
        );
        verify(
          () => logger.write(
            any(
              that: contains(
                'Running "flutter test" in ${p.dirname(directory.path)}',
              ),
            ),
          ),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('+1: All tests passed!'))),
        ).called(1);
      });

      test('completes w/randomSeed', () async {
        const randomSeed = '2305182648';
        final directory = Directory.systemTemp.createTempSync();
        final libDirectory = Directory(p.join(directory.path, 'lib'))
          ..createSync();
        final testDirectory = Directory(p.join(directory.path, 'test'))
          ..createSync();
        File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync(pubspec);
        File(
          p.join(libDirectory.path, 'calculator.dart'),
        ).writeAsStringSync(calculatorContents);
        File(
          p.join(testDirectory.path, 'calculator_test.dart'),
        ).writeAsStringSync(calculatorTestContents);
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            stdout: logger.write,
            stderr: logger.err,
            randomSeed: randomSeed,
          ),
          completion(equals([ExitCode.success.code])),
        );
        verify(
          () => logger.write(
            any(
              that: contains(
                'Running "flutter test" in ${p.dirname(directory.path)}',
              ),
            ),
          ),
        ).called(1);
        verify(
          () => logger.write(
            any(
              that: contains(
                '''Shuffling test order with --test-randomize-ordering-seed=$randomSeed\n''',
              ),
            ),
          ),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('+1: All tests passed!'))),
        ).called(1);
      });

      test('completes w/coverage', () async {
        final directory = Directory.systemTemp.createTempSync();
        final libDirectory = Directory(p.join(directory.path, 'lib'))
          ..createSync();
        final testDirectory = Directory(p.join(directory.path, 'test'))
          ..createSync();
        File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync(pubspec);
        File(
          p.join(libDirectory.path, 'calculator.dart'),
        ).writeAsStringSync(calculatorContents);
        File(
          p.join(testDirectory.path, 'calculator_test.dart'),
        ).writeAsStringSync(calculatorTestContents);
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            stdout: logger.write,
            stderr: logger.err,
            collectCoverage: true,
          ),
          completion(equals([ExitCode.success.code])),
        );
        verify(
          () => logger.write(
            any(
              that: contains(
                'Running "flutter test" in ${p.dirname(directory.path)}',
              ),
            ),
          ),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('+1: All tests passed!'))),
        ).called(1);
        expect(
          File(p.join(directory.path, 'coverage', 'lcov.info')).existsSync(),
          isTrue,
        );
      });

      test('overwrites previous coverage file', () async {
        final directory = Directory.systemTemp.createTempSync();
        final coverageDirectory = Directory(p.join(directory.path, 'coverage'))
          ..createSync();
        final libDirectory = Directory(p.join(directory.path, 'lib'))
          ..createSync();
        final testDirectory = Directory(p.join(directory.path, 'test'))
          ..createSync();
        File(p.join(coverageDirectory.path, 'lcov.info'))
            .writeAsStringSync('HI');
        File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync(pubspec);
        File(
          p.join(libDirectory.path, 'calculator.dart'),
        ).writeAsStringSync(calculatorContents);
        File(
          p.join(testDirectory.path, 'calculator_test.dart'),
        ).writeAsStringSync(calculatorTestContents);
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            stdout: logger.write,
            stderr: logger.err,
            collectCoverage: true,
          ),
          completion(equals([ExitCode.success.code])),
        );
        verify(
          () => logger.write(
            any(
              that: contains(
                'Running "flutter test" in ${p.dirname(directory.path)}',
              ),
            ),
          ),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('+1: All tests passed!'))),
        ).called(1);
        expect(
          File(
            p.join(directory.path, 'coverage', 'lcov.info'),
          ).readAsStringSync(),
          isNot(equals('HI')),
        );
      });

      test('completes w/coverage and --min-coverage 100', () async {
        final directory = Directory.systemTemp.createTempSync();
        final libDirectory = Directory(p.join(directory.path, 'lib'))
          ..createSync();
        final testDirectory = Directory(p.join(directory.path, 'test'))
          ..createSync();
        File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync(pubspec);
        File(
          p.join(libDirectory.path, 'calculator.dart'),
        ).writeAsStringSync(calculatorContents);
        File(
          p.join(testDirectory.path, 'calculator_test.dart'),
        ).writeAsStringSync(calculatorTestContents);
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            stdout: logger.write,
            stderr: logger.err,
            collectCoverage: true,
            minCoverage: 100,
          ),
          completion(equals([ExitCode.success.code])),
        );
        verify(
          () => logger.write(
            any(
              that: contains(
                'Running "flutter test" in ${p.dirname(directory.path)}',
              ),
            ),
          ),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('+1: All tests passed!'))),
        ).called(1);
        expect(
          File(p.join(directory.path, 'coverage', 'lcov.info')).existsSync(),
          isTrue,
        );
      });

      test('throws when --min-coverage 100 not met (50%)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final libDirectory = Directory(p.join(directory.path, 'lib'))
          ..createSync();
        final testDirectory = Directory(p.join(directory.path, 'test'))
          ..createSync();
        File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync(pubspec);
        File(
          p.join(libDirectory.path, 'calculator.dart'),
        ).writeAsStringSync(calculatorContents);
        File(
          p.join(testDirectory.path, 'calculator_test.dart'),
        ).writeAsStringSync(calculatorTestContentsMissingCoverage);
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            stdout: logger.write,
            stderr: logger.err,
            collectCoverage: true,
            minCoverage: 100,
          ),
          throwsA(
            isA<MinCoverageNotMet>().having((e) => e.coverage, 'coverage', 50),
          ),
        );
        verify(
          () => logger.write(
            any(
              that: contains(
                'Running "flutter test" in ${p.dirname(directory.path)}',
              ),
            ),
          ),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('+1: All tests passed!'))),
        ).called(1);
        expect(
          File(p.join(directory.path, 'coverage', 'lcov.info')).existsSync(),
          isTrue,
        );
      });

      test('passes when --min-coverage 100 w/exclude coverage', () async {
        final directory = Directory.systemTemp.createTempSync();
        final libDirectory = Directory(p.join(directory.path, 'lib'))
          ..createSync();
        final testDirectory = Directory(p.join(directory.path, 'test'))
          ..createSync();
        File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync(pubspec);
        File(
          p.join(libDirectory.path, 'calculator.dart'),
        ).writeAsStringSync(calculatorContents);
        File(
          p.join(libDirectory.path, 'other.dart'),
        ).writeAsStringSync(otherContents);
        File(
          p.join(testDirectory.path, 'calculator_test.dart'),
        ).writeAsStringSync(calculatorTestContentsWithOtherImport);
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            excludeFromCoverage: 'lib/other.dart',
            stdout: logger.write,
            stderr: logger.err,
            collectCoverage: true,
            minCoverage: 100,
          ),
          completion(equals([ExitCode.success.code])),
        );
        verify(
          () => logger.write(
            any(
              that: contains(
                'Running "flutter test" in ${p.dirname(directory.path)}',
              ),
            ),
          ),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('+1: All tests passed!'))),
        ).called(1);
        expect(
          File(p.join(directory.path, 'coverage', 'lcov.info')).existsSync(),
          isTrue,
        );
      });

      test('passes when --min-coverage 50 met (50%)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final libDirectory = Directory(p.join(directory.path, 'lib'))
          ..createSync();
        final testDirectory = Directory(p.join(directory.path, 'test'))
          ..createSync();
        File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync(pubspec);
        File(
          p.join(libDirectory.path, 'calculator.dart'),
        ).writeAsStringSync(calculatorContents);
        File(
          p.join(testDirectory.path, 'calculator_test.dart'),
        ).writeAsStringSync(calculatorTestContentsMissingCoverage);
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            stdout: logger.write,
            stderr: logger.err,
            collectCoverage: true,
            minCoverage: 50,
          ),
          completion(equals([ExitCode.success.code])),
        );
        verify(
          () => logger.write(
            any(
              that: contains(
                'Running "flutter test" in ${p.dirname(directory.path)}',
              ),
            ),
          ),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('+1: All tests passed!'))),
        ).called(1);
        expect(
          File(p.join(directory.path, 'coverage', 'lcov.info')).existsSync(),
          isTrue,
        );
      });

      test('passes when --min-coverage 49 met (50%)', () async {
        final directory = Directory.systemTemp.createTempSync();
        final libDirectory = Directory(p.join(directory.path, 'lib'))
          ..createSync();
        final testDirectory = Directory(p.join(directory.path, 'test'))
          ..createSync();
        File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync(pubspec);
        File(
          p.join(libDirectory.path, 'calculator.dart'),
        ).writeAsStringSync(calculatorContents);
        File(
          p.join(testDirectory.path, 'calculator_test.dart'),
        ).writeAsStringSync(calculatorTestContentsMissingCoverage);
        await expectLater(
          Flutter.test(
            cwd: directory.path,
            stdout: logger.write,
            stderr: logger.err,
            collectCoverage: true,
            minCoverage: 49,
          ),
          completion(equals([ExitCode.success.code])),
        );
        verify(
          () => logger.write(
            any(
              that: contains(
                'Running "flutter test" in ${p.dirname(directory.path)}',
              ),
            ),
          ),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('+1: All tests passed!'))),
        ).called(1);
        expect(
          File(p.join(directory.path, 'coverage', 'lcov.info')).existsSync(),
          isTrue,
        );
      });
    });
  });
}

extension on File {
  Future<void> ensureDeleted({
    Duration timeout = const Duration(seconds: 1),
    Duration interval = const Duration(milliseconds: 50),
  }) async {
    var elapsedTime = Duration.zero;
    while (existsSync()) {
      await Future<void>.delayed(interval);
      elapsedTime += interval;
      if (elapsedTime >= timeout) throw Exception('timed out');
    }
  }
}
