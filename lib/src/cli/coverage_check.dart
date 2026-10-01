part of 'cli.dart';

/// Checks the coverage [metrics] against [minCoverage].
///
/// Throws [MinCoverageNotMet] when the coverage is below [minCoverage],
/// carrying the uncovered lines when [showUncovered] is set. Otherwise, when
/// [showUncovered] is set and some lines are not covered, they are written to
/// [stdout] as informational output.
void checkCoverage(
  CoverageMetrics metrics, {
  double? minCoverage,
  bool showUncovered = false,
  void Function(String)? stdout,
}) {
  final coverage = metrics.percentage;
  final uncoveredLines = showUncovered && metrics.uncoveredLines.isNotEmpty
      ? metrics.uncoveredLines
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
