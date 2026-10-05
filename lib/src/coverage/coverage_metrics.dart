part of 'coverage.dart';

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

  /// Generate coverage metrics from a list of lcov records.
  factory fromLcovRecords(List<Record> records, {String? excludeFromCoverage}) {
    final excludedGlobs = _parseExcludeGlobs(excludeFromCoverage);
    return records
        .whereNot((record) => _isExcluded(record.file, excludedGlobs))
        .fold(
          const CoverageMetrics(),
          (metrics, record) => metrics._add(record),
        );
  }

  static bool _isExcluded(String? file, List<Glob> excludedGlobs) =>
      file != null && excludedGlobs.any((glob) => glob.matches(file));

  /// Line numbers in [record] that were instrumented but never hit.
  static List<int> _uncoveredLineNumbersOf(Record record) => [
    for (final detail in record.lines?.details ?? const <Never>[])
      if (detail.line case final line? when (detail.hit ?? 1) == 0) line,
  ];

  /// Returns new metrics with the counts and uncovered lines of [record].
  CoverageMetrics _add(Record record) {
    final lines = record.lines;
    return CoverageMetrics(
      totalFound: totalFound + (lines?.found ?? 0),
      totalHits: totalHits + (lines?.hit ?? 0),
      uncoveredLines: _uncoveredLinesWith(record),
    );
  }

  Map<String, List<int>> _uncoveredLinesWith(Record record) {
    final file = record.file;
    if (file == null) return uncoveredLines;

    final newLines = _uncoveredLineNumbersOf(record);
    return {
      ...uncoveredLines,
      if (newLines.isNotEmpty) file: [...?uncoveredLines[file], ...newLines],
    };
  }

  /// Total number of lines hit (covered) across all included files.
  final int totalHits;

  /// Total number of instrumented lines found across all included files.
  final int totalFound;

  /// Lines not covered.
  /// Keyed by file path, values are line numbers in the order the records
  /// list them.
  final Map<String, List<int>> uncoveredLines;

  /// Coverage percentage: [totalHits] / [totalFound] * 100.
  ///
  /// Returns `0` when [totalFound] is less than 1.
  double get percentage {
    return totalFound < 1 ? 0 : (totalHits / totalFound * 100);
  }
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
