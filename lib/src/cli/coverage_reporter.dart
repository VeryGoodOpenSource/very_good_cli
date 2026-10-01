part of 'cli.dart';

/// Checks the coverage of [records] against [minCoverage].
///
/// Files matching [excludeFromCoverage] (space separated globs) are left out
/// of the measurement.
///
/// Throws [MinCoverageNotMet] when the coverage is below [minCoverage],
/// carrying the uncovered lines when [showUncovered] is set. Otherwise, when
/// [showUncovered] is set and some lines are not covered, they are written to
/// [stdout] as informational output.
void checkCoverage(
  List<Record> records, {
  double? minCoverage,
  bool showUncovered = false,
  String? excludeFromCoverage,
  void Function(String)? stdout,
}) {
  final coverageMetrics = CoverageMetrics.fromLcovRecords(
    records,
    excludeFromCoverage: excludeFromCoverage,
  );
  final coverage = coverageMetrics.percentage;
  final uncoveredLines =
      showUncovered && coverageMetrics.uncoveredLines.isNotEmpty
      ? coverageMetrics.uncoveredLines
      : null;

  if (minCoverage != null && coverage < minCoverage) {
    throw MinCoverageNotMet(coverage, uncoveredLines: uncoveredLines);
  }

  // When coverage passes but is below 100%,
  // show uncovered lines as informational output.
  if (uncoveredLines != null) {
    stdout?.call('${TestCLIRunner.formatUncoveredLines(uncoveredLines)}\n');
  }
}
