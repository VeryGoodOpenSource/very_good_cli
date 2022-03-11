import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/cli/cli.dart';

const testContents = '''
import 'package:test/test.dart';

void main() {
  test('example', () {
    expect(true, isTrue);
  });
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

const invalidPubspec = 'name: example';

class MockLogger extends Mock implements Logger {}

void main() {
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

      setUp(() {
        logger = MockLogger();
      });

      test('throws when there is no pubspec.yaml', () {
        expectLater(
          Flutter.test(cwd: Directory.systemTemp.path),
          throwsException,
        );
      });

      test('throws when process fails', () {
        final directory = Directory.systemTemp.createTempSync();
        File(p.join(directory.path, 'pubspec.yaml'))
            .writeAsStringSync(invalidPubspec);

        expectLater(
          Flutter.test(cwd: directory.path),
          throwsA('Test directory "test" not found.'),
        );
      });

      test('throws when there is no test directory', () {
        final directory = Directory.systemTemp.createTempSync();
        File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync(pubspec);

        expectLater(
          Flutter.test(cwd: directory.path),
          throwsA('Test directory "test" not found.'),
        );
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
          completes,
        );
        verify(
          () => logger.write(
            any(that: contains('Running "flutter test" in ${directory.path}')),
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
          completes,
        );
        verify(
          () => logger.write(
            any(that: contains('Running "flutter test" in ${directory.path}')),
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
          completes,
        );
        verify(
          () => logger.write(
            any(that: contains('Running "flutter test" in ${directory.path}')),
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
          completes,
        );
        verify(
          () => logger.write(
            any(that: contains('Running "flutter test" in ${directory.path}')),
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
          completes,
        );
        verify(
          () => logger.write(
            any(that: contains('Running "flutter test" in ${directory.path}')),
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
      });

      test('completes when there is a test directory w/out stdout,stderr', () {
        final directory = Directory.systemTemp.createTempSync();
        final testDirectory = Directory(p.join(directory.path, 'test'))
          ..createSync();
        File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync(pubspec);
        File(
          p.join(testDirectory.path, 'example_test.dart'),
        ).writeAsStringSync(testContents);
        expectLater(Flutter.test(cwd: directory.path), completes);
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
          completes,
        );
        verify(
          () => logger.write(
            any(that: contains('Running "flutter test" in ${directory.path}')),
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
          completes,
        );
        verify(
          () => logger.write(
            any(
              that: contains(
                'Running "flutter test" in ${nestedDirectory.path}',
              ),
            ),
          ),
        ).called(1);
        verify(
          () => logger.write(any(that: contains('+1: All tests passed!'))),
        ).called(1);
      });
    });
  });
}
