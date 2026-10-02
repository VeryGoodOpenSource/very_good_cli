import 'package:test/test.dart';
import 'package:very_good_cli/src/cli/cli.dart';

void main() {
  group(checkCoverage, () {
    late List<String> stdoutLogs;

    final metrics = CoverageMetrics.fromLcov([
      LcovRecord('lib/a.dart', lines: {1: 1, 2: 0}),
      LcovRecord('lib/b.dart', lines: {1: 1, 2: 1}),
    ]);

    setUp(() {
      stdoutLogs = [];
    });

    test('does nothing when no threshold is set', () {
      checkCoverage(metrics, stdout: stdoutLogs.add);

      expect(stdoutLogs, isEmpty);
    });

    test('completes when the threshold is met', () {
      checkCoverage(metrics, minCoverage: 75, stdout: stdoutLogs.add);

      expect(stdoutLogs, isEmpty);
    });

    test('throws $MinCoverageNotMet when the threshold is not met', () {
      expect(
        () => checkCoverage(metrics, minCoverage: 80),
        throwsA(
          isA<MinCoverageNotMet>()
              .having((e) => e.coverage, 'coverage', equals(75))
              .having((e) => e.uncoveredLines, 'uncoveredLines', isNull),
        ),
      );
    });

    test('throws with uncovered lines when show uncovered is set', () {
      expect(
        () => checkCoverage(metrics, minCoverage: 80, showUncovered: true),
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
        metrics,
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
          const CoverageMetrics(totalHits: 2, totalFound: 2),
          showUncovered: true,
          stdout: stdoutLogs.add,
        );

        expect(stdoutLogs, isEmpty);
      },
    );
  });
}
