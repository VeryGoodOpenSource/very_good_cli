import 'package:lcov_parser/lcov_parser.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/cli/cli.dart';

void main() {
  group(checkCoverage, () {
    late List<String> stdoutLogs;

    final records = Parser.parseLines([
      'SF:lib/a.dart',
      'DA:1,1',
      'DA:2,0',
      'LF:2',
      'LH:1',
      'end_of_record',
      'SF:lib/b.dart',
      'DA:1,1',
      'DA:2,1',
      'LF:2',
      'LH:2',
      'end_of_record',
    ]);

    setUp(() {
      stdoutLogs = [];
    });

    test('does nothing when no threshold is set', () {
      checkCoverage(records, stdout: stdoutLogs.add);

      expect(stdoutLogs, isEmpty);
    });

    test('completes when the threshold is met', () {
      checkCoverage(records, minCoverage: 75, stdout: stdoutLogs.add);

      expect(stdoutLogs, isEmpty);
    });

    test('throws $MinCoverageNotMet when the threshold is not met', () {
      expect(
        () => checkCoverage(records, minCoverage: 80),
        throwsA(
          isA<MinCoverageNotMet>()
              .having((e) => e.coverage, 'coverage', equals(75))
              .having((e) => e.uncoveredLines, 'uncoveredLines', isNull),
        ),
      );
    });

    test('throws with uncovered lines when show uncovered is set', () {
      expect(
        () => checkCoverage(records, minCoverage: 80, showUncovered: true),
        throwsA(
          isA<MinCoverageNotMet>().having(
            (e) => e.uncoveredLines,
            'uncoveredLines',
            equals({
              'lib/a.dart': [2],
            }),
          ),
        ),
      );
    });

    test('logs uncovered lines when the threshold is met', () {
      checkCoverage(
        records,
        minCoverage: 75,
        showUncovered: true,
        stdout: stdoutLogs.add,
      );

      expect(stdoutLogs, equals(['Lines not covered:\n\t- lib/a.dart: 2\n']));
    });

    test(
      'logs nothing when show uncovered is set and all lines are covered',
      () {
        checkCoverage(
          records,
          showUncovered: true,
          excludeFromCoverage: 'lib/a.dart',
          stdout: stdoutLogs.add,
        );

        expect(stdoutLogs, isEmpty);
      },
    );

    test('ignores files matching the exclude globs', () {
      checkCoverage(
        records,
        minCoverage: 100,
        excludeFromCoverage: 'lib/a.dart lib/c.dart',
      );
    });
  });
}
