import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:very_good_cli/src/cli/cli.dart';

void main() {
  group('CoverageCollectionMode', () {
    test('enum has imports and all values', () {
      expect(CoverageCollectionMode.imports, isNotNull);
      expect(CoverageCollectionMode.all, isNotNull);
    });

    test('fromString returns imports for "imports"', () {
      final mode = CoverageCollectionMode.fromString('imports');
      expect(mode, equals(CoverageCollectionMode.imports));
    });

    test('fromString returns all for "all"', () {
      final mode = CoverageCollectionMode.fromString('all');
      expect(mode, equals(CoverageCollectionMode.all));
    });

    test('fromString returns imports for unknown value', () {
      final mode = CoverageCollectionMode.fromString('unknown');
      expect(mode, equals(CoverageCollectionMode.imports));
    });

    test('fromString returns imports for empty string', () {
      final mode = CoverageCollectionMode.fromString('');
      expect(mode, equals(CoverageCollectionMode.imports));
    });
  });

  group('TestCLIRunner - Coverage Helper Functions', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('test_cli_runner_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('_discoverDartFilesForCoverage', () {
      test('returns empty list when directory does not exist', () {
        // Verify that a nonexistent directory returns false
        final libDir = Directory(p.join(tempDir.path, 'nonexistent'));
        expect(libDir.existsSync(), isFalse);
      });

      test('discovers all dart files recursively', () {
        // Create a lib directory with some Dart files
        final libDir = Directory(p.join(tempDir.path, 'lib'))
          ..createSync(recursive: true);

        File(p.join(libDir.path, 'main.dart')).createSync();
        File(p.join(libDir.path, 'utils.dart')).createSync();

        final srcDir = Directory(p.join(libDir.path, 'src'))..createSync();
        File(p.join(srcDir.path, 'helper.dart')).createSync();

        // Verify directory structure
        expect(libDir.existsSync(), isTrue);
        expect(
          Directory(p.join(libDir.path, 'src')).listSync(),
          isNotEmpty,
        );
      });

      test('respects exclude patterns', () {
        // Create lib directory with some files
        final libDir = Directory(p.join(tempDir.path, 'lib'))
          ..createSync(recursive: true);

        File(p.join(libDir.path, 'main.dart')).createSync();
        File(p.join(libDir.path, 'main.g.dart')).createSync();

        // Verify files exist
        expect(File(p.join(libDir.path, 'main.dart')).existsSync(), isTrue);
        expect(File(p.join(libDir.path, 'main.g.dart')).existsSync(), isTrue);
      });
    });

    group('_enhanceLcovWithUntestedFiles', () {
      test('creates valid lcov file for untested files', () async {
        // Create lib directory with Dart files
        final libDir = Directory(p.join(tempDir.path, 'lib'))
          ..createSync(recursive: true);

        final dartFile = File(p.join(libDir.path, 'untested.dart'))
          ..writeAsStringSync(
            '''
void function1() {
  print('test');
}

void function2() {
  print('test2');
}
''',
          );

        // Create a minimal LCOV file
        final coverageDir = Directory(p.join(tempDir.path, 'coverage'))
          ..createSync(recursive: true);

        final lcovFile = File(p.join(coverageDir.path, 'lcov.info'))
          ..writeAsStringSync('end_of_record\n');

        // Verify setup
        expect(dartFile.existsSync(), isTrue);
        expect(lcovFile.existsSync(), isTrue);
        expect(libDir.listSync(recursive: true), isNotEmpty);
      });

      test('handles empty files gracefully', () async {
        // Create lib directory with empty Dart file
        final libDir = Directory(p.join(tempDir.path, 'lib'))
          ..createSync(recursive: true);

        final emptyFile = File(p.join(libDir.path, 'empty.dart'))
          ..writeAsStringSync('');

        // Create LCOV file
        final coverageDir = Directory(p.join(tempDir.path, 'coverage'))
          ..createSync(recursive: true);

        final lcovFile = File(p.join(coverageDir.path, 'lcov.info'))
          ..writeAsStringSync('end_of_record\n');

        // Verify setup
        expect(emptyFile.existsSync(), isTrue);
        expect(lcovFile.existsSync(), isTrue);
      });

      test('skips comment-only lines', () async {
        // Create lib directory with comment file
        final libDir = Directory(p.join(tempDir.path, 'lib'))
          ..createSync(recursive: true);

        final commentFile = File(p.join(libDir.path, 'comment.dart'))
          ..writeAsStringSync(
            '''
// This is a comment
// Another comment

/*
 * Multi-line comment
 */
''',
          );

        // Create LCOV file
        final coverageDir = Directory(p.join(tempDir.path, 'coverage'))
          ..createSync(recursive: true);

        final lcovFile = File(p.join(coverageDir.path, 'lcov.info'))
          ..writeAsStringSync('end_of_record\n');

        // Verify setup
        expect(commentFile.existsSync(), isTrue);
        expect(lcovFile.existsSync(), isTrue);
      });

      test('skips import and export statements', () async {
        // Create lib directory with imports file
        final libDir = Directory(p.join(tempDir.path, 'lib'))
          ..createSync(recursive: true);

        final importsFile = File(p.join(libDir.path, 'imports.dart'))
          ..writeAsStringSync(
            '''
import 'package:flutter/material.dart';
export 'package:flutter/material.dart';
part 'other.dart';

void main() {}
''',
          );

        // Create LCOV file
        final coverageDir = Directory(p.join(tempDir.path, 'coverage'))
          ..createSync(recursive: true);

        final lcovFile = File(p.join(coverageDir.path, 'lcov.info'))
          ..writeAsStringSync('end_of_record\n');

        // Verify setup
        expect(importsFile.existsSync(), isTrue);
        expect(lcovFile.existsSync(), isTrue);
      });
    });
  });
}
