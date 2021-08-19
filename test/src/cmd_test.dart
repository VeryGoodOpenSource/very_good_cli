import 'package:test/test.dart';
import 'package:universal_io/io.dart';
import 'package:very_good_cli/src/flutter_cli.dart';

void main() {
  group('Flutter CLI', () {
    group('packages get', () {
      test('throws when there is no pubspec.yaml', () {
        expectLater(
          Flutter.packagesGet(cwd: Directory.systemTemp.path, recursive: false),
          throwsException,
        );
      });

      test('completes when there is a pubspec.yaml', () {
        expectLater(Flutter.packagesGet(recursive: false), completes);
      });
    });

    group('pub get', () {
      test('throws when there is no pubspec.yaml', () {
        expectLater(
          Flutter.pubGet(cwd: Directory.systemTemp.path, recursive: false),
          throwsException,
        );
      });

      test('completes when there is a pubspec.yaml', () {
        expectLater(Flutter.pubGet(recursive: false), completes);
      });
    });
  });
}
