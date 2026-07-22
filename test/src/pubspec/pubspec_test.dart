import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/pubspec/pubspec.dart';

void main() {
  group('$PubspecDependencyType', () {
    group('parse', () {
      test('parses successfully `direct main`', () {
        expect(
          PubspecDependencyType.parse('direct main'),
          equals(PubspecDependencyType.directMain),
        );
      });

      test('parses successfully `direct dev`', () {
        expect(
          PubspecDependencyType.parse('direct dev'),
          equals(PubspecDependencyType.directDev),
        );
      });

      test('parses successfully `direct overridden`', () {
        expect(
          PubspecDependencyType.parse('direct overridden'),
          equals(PubspecDependencyType.directOverridden),
        );
      });

      test('parses successfully `transitive`', () {
        expect(
          PubspecDependencyType.parse('transitive'),
          equals(PubspecDependencyType.transitive),
        );
      });

      test('throws a $ArgumentError when type is invalid', () {
        expect(
          () => PubspecDependencyType.parse('invalid'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });

  group('tryParsePubspec', () {
    late Directory tempDirectory;

    setUp(() {
      tempDirectory = Directory.systemTemp.createTempSync();
      addTearDown(() => tempDirectory.deleteSync(recursive: true));
    });

    File pubspecFile(String content) {
      return File(path.join(tempDirectory.path, 'pubspec.yaml'))
        ..writeAsStringSync(content);
    }

    test('returns null when the file does not exist', () {
      final file = File(path.join(tempDirectory.path, 'pubspec.yaml'));

      expect(tryParsePubspec(file), isNull);
    });

    test('returns null when the content cannot be parsed', () {
      final file = pubspecFile('{{{ not valid yaml');

      expect(tryParsePubspec(file), isNull);
    });

    test('parses a valid pubspec', () {
      final file = pubspecFile('''
name: example
environment:
  sdk: ^3.11.0
dependencies:
  path: ^1.9.0
''');

      final pubspec = tryParsePubspec(file);

      expect(pubspec, isA<Pubspec>());
      expect(pubspec!.name, equals('example'));
      expect(pubspec.dependencies.keys, contains('path'));
    });

    test('tolerates valid-but-unmodeled keys', () {
      final file = pubspecFile('''
name: example
environment:
  sdk: ^3.11.0
flutter:
  uses-material-design: true
''');

      final pubspec = tryParsePubspec(file);

      expect(pubspec, isA<Pubspec>());
      expect(pubspec!.name, equals('example'));
    });
  });
}
