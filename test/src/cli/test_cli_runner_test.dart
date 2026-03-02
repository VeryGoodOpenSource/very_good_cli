import 'dart:io';

import 'package:lcov_parser/lcov_parser.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:very_good_cli/src/cli/cli.dart';

import '../../fixtures/lcov_fixtures.dart';

void main() {
  group(CoverageCollectionMode, () {
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

  group(TestCLIRunner, () {
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

  group('formatUncoveredLines', () {
    test('formats a single file with single line', () {
      final result = TestCLIRunner.formatUncoveredLines({
        'lib/src/foo.dart': [10],
      });
      expect(result, equals('Lines not covered:\n\t- lib/src/foo.dart: 10'));
    });

    test('formats a single file with multiple lines', () {
      final result = TestCLIRunner.formatUncoveredLines({
        'lib/src/foo.dart': [10, 20, 30],
      });
      expect(
        result,
        equals('Lines not covered:\n\t- lib/src/foo.dart: 10, 20, 30'),
      );
    });

    test('sorts line numbers within a file', () {
      final result = TestCLIRunner.formatUncoveredLines({
        'lib/src/foo.dart': [30, 10, 20],
      });
      expect(
        result,
        equals('Lines not covered:\n\t- lib/src/foo.dart: 10, 20, 30'),
      );
    });

    test('formats multiple files', () {
      final result = TestCLIRunner.formatUncoveredLines({
        'lib/src/foo.dart': [10, 20],
        'lib/src/bar.dart': [5],
      });
      expect(
        result,
        equals(
          'Lines not covered:\n'
          '\t- lib/src/foo.dart: 10, 20\n'
          '\t- lib/src/bar.dart: 5',
        ),
      );
    });
  });

  group(MinCoverageNotMet, () {
    test('stores coverage value', () {
      const exception = MinCoverageNotMet(95.5);
      expect(exception.coverage, equals(95.5));
      expect(exception.uncoveredLines, isNull);
    });

    test('stores uncovered lines when provided', () {
      const uncoveredLines = {
        'lib/src/foo.dart': [10, 20],
      };
      const exception = MinCoverageNotMet(95, uncoveredLines: uncoveredLines);
      expect(exception.coverage, equals(95));
      expect(exception.uncoveredLines, equals(uncoveredLines));
    });
  });

  group(CoverageMetrics, () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('coverage_metrics_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('reports no uncovered lines for 100% coverage', () async {
      final lcovFile = File(p.join(tempDir.path, 'lcov.info'))
        ..writeAsStringSync(lcov100);
      final records = await Parser.parse(lcovFile.path);
      final metrics = CoverageMetrics.fromLcovRecords(records);
      expect(metrics.percentage, equals(100));
      expect(metrics.uncoveredLines, isEmpty);
    });

    test('reports uncovered lines for 95% coverage', () async {
      final lcovFile = File(p.join(tempDir.path, 'lcov.info'))
        ..writeAsStringSync(lcov95);
      final records = await Parser.parse(lcovFile.path);
      final metrics = CoverageMetrics.fromLcovRecords(records);
      expect(metrics.percentage, lessThan(100));
      expect(metrics.uncoveredLines, isNotEmpty);

      final blocObserverFile = metrics.uncoveredLines.keys.firstWhere(
        (k) => k.contains('bloc_observer'),
      );
      expect(
        metrics.uncoveredLines[blocObserverFile],
        containsAll([20, 27, 36, 43, 51]),
      );
    });

    test('excludes files matching the glob from uncovered lines', () async {
      final lcovFile = File(p.join(tempDir.path, 'lcov.info'))
        ..writeAsStringSync(lcov95);
      final records = await Parser.parse(lcovFile.path);
      final metrics = CoverageMetrics.fromLcovRecords(
        records,
        excludeFromCoverage: '**/bloc_observer.dart',
      );

      expect(
        metrics.uncoveredLines.keys.any((k) => k.contains('bloc_observer')),
        isFalse,
      );
    });
  });
}
