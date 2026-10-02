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
    stdout?.call('${formatUncoveredLines(uncoveredLines)}\n');
  }
}

/// {@template coverage_not_met}
/// Thrown when `flutter test ---coverage --min-coverage`
/// does not meet the provided minimum coverage threshold.
/// {@endtemplate}
class MinCoverageNotMet implements Exception {
  /// {@macro coverage_not_met}
  const new(this.coverage, {this.uncoveredLines});

  /// The measured coverage percentage (total hits / total found * 100).
  final double coverage;

  /// Lines not covered, keyed by file path, values are line numbers.
  ///
  /// Only populated when `--show-uncovered` is set.
  final Map<String, List<int>>? uncoveredLines;
}

/// {@template coverage_metrics}
/// Aggregated coverage metrics computed from a list of LCOV records.
/// {@endtemplate}
class CoverageMetrics {
  /// {@macro coverage_metrics}
  @visibleForTesting
  const new({
    this.totalHits = 0,
    this.totalFound = 0,
    this.uncoveredLines = const {},
  });

  /// Generate coverage metrics from a list of [LcovRecord]s, as returned by
  /// [parseLcov].
  ///
  /// Files matching any of the space separated [excludeFromCoverage] globs are
  /// left out. The globs are also matched against the paths relative to each
  /// of [packagePaths], so that a glob written for a single package, like
  /// `lib/src/gen/**`, still applies once its report is rebased onto the
  /// package by [normalizeLcovRecords].
  factory fromLcov(
    Iterable<LcovRecord> records, {
    String? excludeFromCoverage,
    Iterable<String> packagePaths = const [],
  }) {
    final globs = [
      for (final glob in (excludeFromCoverage ?? '').trim().split(' '))
        if (glob.isNotEmpty) Glob(glob),
    ];

    bool isExcluded(String file) => [
      file,
      for (final package in packagePaths)
        if (p.posix.isWithin(package, file))
          p.posix.relative(file, from: package),
    ].any((path) => globs.any((glob) => glob.matches(path)));

    var totalFound = 0;
    var totalHits = 0;
    final uncoveredLines = <String, List<int>>{};
    for (final LcovRecord(:file, :lines) in records) {
      if (isExcluded(file)) continue;

      totalFound += lines.length;
      totalHits += lines.values.where((hits) => hits > 0).length;
      final uncovered = [
        for (final MapEntry(key: line, value: hits)
            in lines.entries.sortedBy<num>((entry) => entry.key))
          if (hits == 0) line,
      ];
      if (uncovered.isNotEmpty) {
        (uncoveredLines[file] ??= []).addAll(uncovered);
      }
    }

    return CoverageMetrics(
      totalFound: totalFound,
      totalHits: totalHits,
      uncoveredLines: uncoveredLines,
    );
  }

  /// Total number of lines hit (covered) across all included files.
  final int totalHits;

  /// Total number of instrumented lines found across all included files.
  final int totalFound;

  /// Lines not covered.
  /// Keyed by file path, values are sorted line numbers.
  final Map<String, List<int>> uncoveredLines;

  /// Coverage percentage: [totalHits] / [totalFound] * 100.
  ///
  /// Returns `0` when [totalFound] is less than 1.
  double get percentage {
    return totalFound < 1 ? 0 : (totalHits / totalFound * 100);
  }
}

/// Logs [error], along with its uncovered lines when it carries any, and
/// returns the exit code an unmet coverage threshold reports.
int handleMinCoverageNotMet(
  MinCoverageNotMet error, {
  required Logger logger,
  double? minCoverage,
}) {
  var decimalPlaces = 2;

  double round(double x) {
    final b = pow(10, decimalPlaces);
    return (x * b).roundToDouble() / b;
  }

  if (error.coverage < minCoverage!) {
    var rounded = round(error.coverage);
    while (rounded == minCoverage) {
      decimalPlaces++;
      rounded = round(error.coverage);
    }
  }

  logger.err(
    '''Expected coverage >= ${minCoverage.toStringAsFixed(decimalPlaces)}% but actual is ${error.coverage.toStringAsFixed(decimalPlaces)}%.''',
  );

  final uncoveredLines = error.uncoveredLines;
  if (uncoveredLines != null && uncoveredLines.isNotEmpty) {
    logger.err(formatUncoveredLines(uncoveredLines));
  }

  return ExitCode.software.code;
}

/// Formats a map of uncovered lines into a human-readable string.
///
/// The [uncoveredLines] map is keyed by file path, with values being lists
/// of uncovered line numbers.
///
/// Example output:
/// ```dart
/// Lines not covered:
///   - lib/src/foo.dart: 10, 20, 30
///   - lib/src/bar.dart: 5
/// ```
String formatUncoveredLines(Map<String, List<int>> uncoveredLines) {
  final lines = uncoveredLines.entries.map((entry) {
    final sortedLines = [...entry.value]..sort();
    return '\t- ${entry.key}: ${sortedLines.join(', ')}';
  });
  return 'Lines not covered:\n${lines.join('\n')}';
}
