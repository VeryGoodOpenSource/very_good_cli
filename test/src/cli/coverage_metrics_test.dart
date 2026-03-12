import 'package:lcov_parser/lcov_parser.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/cli/cli.dart';

List<Record> _records(List<String> lines) => Parser.parseLines(lines);

void main() {
  group('CoverageMetrics.fromLcovRecords', () {
    test('returns empty metrics for an empty record list', () {
      final metrics = CoverageMetrics.fromLcovRecords([]);

      expect(metrics.totalHits, 0);
      expect(metrics.totalFound, 0);
      expect(metrics.uncoveredLines, isEmpty);
    });

    test('aggregates hits and found across records', () {
      final records = _records([
        'SF:lib/a.dart',
        'LF:10',
        'LH:8',
        'end_of_record',
        'SF:lib/b.dart',
        'LF:5',
        'LH:5',
        'end_of_record',
      ]);

      final metrics = CoverageMetrics.fromLcovRecords(records);

      expect(metrics.totalFound, 15);
      expect(metrics.totalHits, 13);
    });

    test('collects uncovered lines per file', () {
      final records = _records([
        'SF:lib/a.dart',
        'DA:1,1',
        'DA:2,0',
        'DA:3,0',
        'LF:3',
        'LH:1',
        'end_of_record',
      ]);

      final metrics = CoverageMetrics.fromLcovRecords(records);

      expect(metrics.uncoveredLines, {
        'lib/a.dart': [2, 3],
      });
    });

    test('excludes a single glob-matched file from metrics', () {
      final records = _records([
        'SF:lib/a.dart',
        'LF:10',
        'LH:8',
        'end_of_record',
        'SF:lib/generated/b.g.dart',
        'LF:5',
        'LH:5',
        'end_of_record',
      ]);

      final metrics = CoverageMetrics.fromLcovRecords(
        records,
        excludeFromCoverage: 'lib/generated/**',
      );

      expect(metrics.totalFound, 10);
      expect(metrics.totalHits, 8);
    });

    test('excludes multiple space-separated globs', () {
      final records = _records([
        'SF:lib/a.dart',
        'LF:10',
        'LH:8',
        'end_of_record',
        'SF:lib/generated/b.g.dart',
        'LF:5',
        'LH:5',
        'end_of_record',
        'SF:lib/mocks/mock_c.dart',
        'LF:4',
        'LH:4',
        'end_of_record',
      ]);

      final metrics = CoverageMetrics.fromLcovRecords(
        records,
        excludeFromCoverage: 'lib/generated/** lib/mocks/**',
      );

      expect(metrics.totalFound, 10);
      expect(metrics.totalHits, 8);
    });

    test('handles null excludeFromCoverage', () {
      final records = _records([
        'SF:lib/a.dart',
        'LF:3',
        'LH:3',
        'end_of_record',
      ]);

      final metrics = CoverageMetrics.fromLcovRecords(
        records,
      );

      expect(metrics.totalFound, 3);
      expect(metrics.totalHits, 3);
    });

    test('handles empty string excludeFromCoverage', () {
      final records = _records([
        'SF:lib/a.dart',
        'LF:3',
        'LH:3',
        'end_of_record',
      ]);

      final metrics = CoverageMetrics.fromLcovRecords(
        records,
        excludeFromCoverage: '',
      );

      expect(metrics.totalFound, 3);
      expect(metrics.totalHits, 3);
    });

    test('handles records with no DA entries', () {
      final records = _records([
        'SF:lib/a.dart',
        'LF:0',
        'LH:0',
        'end_of_record',
        'SF:lib/b.dart',
        'LF:4',
        'LH:4',
        'end_of_record',
      ]);

      final metrics = CoverageMetrics.fromLcovRecords(records);

      expect(metrics.totalFound, 4);
      expect(metrics.totalHits, 4);
      expect(metrics.uncoveredLines, isEmpty);
    });

    test('accumulates uncovered lines across multiple records', () {
      final records = _records([
        'SF:lib/a.dart',
        'DA:10,0',
        'DA:20,1',
        'LF:2',
        'LH:1',
        'end_of_record',
        'SF:lib/b.dart',
        'DA:5,0',
        'DA:6,0',
        'LF:2',
        'LH:0',
        'end_of_record',
      ]);

      final metrics = CoverageMetrics.fromLcovRecords(records);

      expect(metrics.uncoveredLines, {
        'lib/a.dart': [10],
        'lib/b.dart': [5, 6],
      });
    });

    test('non-matching glob does not exclude file', () {
      final records = _records([
        'SF:lib/a.dart',
        'LF:5',
        'LH:5',
        'end_of_record',
      ]);

      final metrics = CoverageMetrics.fromLcovRecords(
        records,
        excludeFromCoverage: 'lib/generated/**',
      );

      expect(metrics.totalFound, 5);
      expect(metrics.totalHits, 5);
    });
  });
}
