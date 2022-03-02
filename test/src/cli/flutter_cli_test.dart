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

const pubspec = '''
name: example
environment:
  sdk: ">=2.13.0 <3.0.0"

dev_dependencies:
  test: any''';

const invalidPubspec = 'name: example';

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
          throwsException,
        );
      });

      test('throws when there is no test directory', () {
        final directory = Directory.systemTemp.createTempSync();
        File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync(pubspec);

        expectLater(
          Flutter.test(cwd: directory.path),
          throwsException,
        );
      });

      test('throws when there is no pubspec.yaml (recursive)', () {
        final directory = Directory.systemTemp.createTempSync();
        expectLater(
          Flutter.test(cwd: directory.path, recursive: true),
          throwsException,
        );
      });

      test('completes when there is a test directory', () {
        final directory = Directory.systemTemp.createTempSync();
        final testDirectory = Directory(p.join(directory.path, 'test'))
          ..createSync();
        File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync(pubspec);
        File(
          p.join(testDirectory.path, 'example_test.dart'),
        ).writeAsStringSync(testContents);
        expectLater(Flutter.test(cwd: directory.path), completes);
      });

      test('completes when there is a test directory (recursive)', () {
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
        expectLater(
          Flutter.test(cwd: directory.path, recursive: true),
          completes,
        );
      });
    });
  });
}
