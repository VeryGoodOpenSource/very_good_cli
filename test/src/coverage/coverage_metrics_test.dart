import 'package:lcov_parser/lcov_parser.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/coverage/coverage.dart';

void main() {
  group(CoverageMetrics, () {
    List<Record> parseRecords(List<String> lines) => Parser.parseLines(lines);

    group('.fromLcovRecords', () {
      test('returns empty metrics for an empty record list', () {
        final metrics = CoverageMetrics.fromLcovRecords([]);

        expect(metrics.totalHits, equals(0));
        expect(metrics.totalFound, equals(0));
        expect(metrics.uncoveredLines, isEmpty);
      });

      test('aggregates hits and found across records', () {
        final records = parseRecords([
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

        expect(metrics.totalFound, equals(15));
        expect(metrics.totalHits, equals(13));
      });

      test('collects uncovered lines per file', () {
        final records = parseRecords([
          'SF:lib/a.dart',
          'DA:1,1',
          'DA:2,0',
          'DA:3,0',
          'LF:3',
          'LH:1',
          'end_of_record',
        ]);

        final metrics = CoverageMetrics.fromLcovRecords(records);

        expect(
          metrics.uncoveredLines,
          equals({
            'lib/a.dart': [2, 3],
          }),
        );
      });

      test('accumulates uncovered lines across multiple records', () {
        final records = parseRecords([
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

        expect(
          metrics.uncoveredLines,
          equals({
            'lib/a.dart': [10],
            'lib/b.dart': [5, 6],
          }),
        );
      });

      test('counts records without a source file but skips their lines', () {
        final records = parseRecords([
          'DA:1,0',
          'LF:1',
          'LH:0',
          'end_of_record',
        ]);

        final metrics = CoverageMetrics.fromLcovRecords(records);

        expect(records.single.file, isNull);
        expect(metrics.totalFound, equals(1));
        expect(metrics.uncoveredLines, isEmpty);
      });

      test('handles records with no DA entries', () {
        final records = parseRecords([
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

        expect(metrics.totalFound, equals(4));
        expect(metrics.totalHits, equals(4));
        expect(metrics.uncoveredLines, isEmpty);
      });

      group('excludeFromCoverage', () {
        test('handles null', () {
          final records = parseRecords([
            'SF:lib/a.dart',
            'LF:3',
            'LH:3',
            'end_of_record',
          ]);

          final metrics = CoverageMetrics.fromLcovRecords(records);

          expect(metrics.totalFound, equals(3));
          expect(metrics.totalHits, equals(3));
        });

        test('handles empty string', () {
          final records = parseRecords([
            'SF:lib/a.dart',
            'LF:3',
            'LH:3',
            'end_of_record',
          ]);

          final metrics = CoverageMetrics.fromLcovRecords(
            records,
            excludeFromCoverage: '',
          );

          expect(metrics.totalFound, equals(3));
          expect(metrics.totalHits, equals(3));
        });

        test('excludes a single glob-matched file', () {
          final records = parseRecords([
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

          expect(metrics.totalFound, equals(10));
          expect(metrics.totalHits, equals(8));
        });

        test('excludes multiple space-separated globs', () {
          final records = parseRecords([
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

          expect(metrics.totalFound, equals(10));
          expect(metrics.totalHits, equals(8));
        });

        for (final (description, separator) in [
          ('multiple consecutive spaces', '  '),
          ('tabs and newlines', '\t\n'),
        ]) {
          test('handles $description between globs', () {
            final records = parseRecords([
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
              excludeFromCoverage: 'lib/generated/**${separator}lib/mocks/**',
            );

            expect(metrics.totalFound, equals(10));
            expect(metrics.totalHits, equals(8));
          });
        }

        test('does not exclude file when glob does not match', () {
          final records = parseRecords([
            'SF:lib/a.dart',
            'LF:5',
            'LH:5',
            'end_of_record',
          ]);

          final metrics = CoverageMetrics.fromLcovRecords(
            records,
            excludeFromCoverage: 'lib/generated/**',
          );

          expect(metrics.totalFound, equals(5));
          expect(metrics.totalHits, equals(5));
        });
      });
    });
  });

  group('formatUncoveredLines', () {
    test('lists the sorted uncovered lines of every file', () {
      expect(
        formatUncoveredLines({
          'lib/a.dart': [30, 10, 20],
          'lib/b.dart': [5],
        }),
        equals(
          'Lines not covered:\n\t- lib/a.dart: 10, 20, 30\n\t- lib/b.dart: 5',
        ),
      );
    });
  });
}
