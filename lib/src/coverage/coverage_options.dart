part of 'coverage.dart';

/// The help of the `--exclude-coverage` option, shared by every command and
/// tool that forwards it.
const excludeCoverageHelp =
    'One or more space-separated globs, relative to the package root, which '
    'will be used to exclude files that match from the coverage '
    "(e.g. '**/*.g.dart **/*.freezed.dart').";

/// How to collect coverage.
enum CoverageCollectionMode {
  /// Collect coverage from imported files only (default behavior).
  imports,

  /// Collect coverage from all files in the project.
  all;

  /// Parses a string value into a [CoverageCollectionMode].
  static CoverageCollectionMode fromString(String value) {
    return CoverageCollectionMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => CoverageCollectionMode.imports,
    );
  }
}

/// {@template coverage_options}
/// The coverage settings shared by every package of a test run.
/// {@endtemplate}
@immutable
class CoverageOptions {
  /// {@macro coverage_options}
  const new({
    this.collect = false,
    this.collectFrom = CoverageCollectionMode.imports,
    this.minCoverage,
    this.showUncovered = false,
    this.excludeFromCoverage,
    this.reportOn = const ['lib'],
    this.checkIgnore = false,
  });

  /// Whether to collect coverage into `coverage/lcov.info`.
  final bool collect;

  /// Which files the lcov report accounts for.
  final CoverageCollectionMode collectFrom;

  /// The minimum coverage percentage the run must reach, if any.
  final double? minCoverage;

  /// Whether to list the lines left uncovered.
  final bool showUncovered;

  /// Whitespace-separated globs of the files left out of the coverage,
  /// matched against paths relative to the package root.
  final String? excludeFromCoverage;

  /// The directories, relative to the package, the coverage reports on.
  final List<String> reportOn;

  /// Whether to honor the `coverage:ignore` comments.
  final bool checkIgnore;
}
