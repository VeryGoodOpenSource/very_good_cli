import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/flutter_cli.dart';

const pubspec = '''
name: example
environment:
  sdk: ">=2.13.0 <3.0.0"
''';

const invalidPubspec = '''
name: example
''';

void main() {
  group('Flutter CLI', () {
    group('packages get', () {
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

    group('pub get', () {
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
        expectLater(Flutter.pubGet(), completes);
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
  });
}
