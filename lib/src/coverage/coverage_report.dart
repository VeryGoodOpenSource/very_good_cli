part of 'coverage.dart';

/// {@template coverage_not_met}
/// Thrown when `flutter test ---coverage --min-coverage`
/// does not meet the provided minimum coverage threshold.
/// {@endtemplate}
class const MinCoverageNotMet(
  /// The measured coverage percentage (total hits / total found * 100).
  final double coverage, {

  /// The minimum coverage percentage the run had to reach.
  required final double minCoverage,

  /// Lines not covered, keyed by file path relative to [packageRoot], values
  /// are line numbers.
  final Map<String, List<int>> uncoveredLines = const {},

  /// Whether to list the [uncoveredLines] along with the error, as asked by
  /// `--show-uncovered`.
  final bool showUncovered = false,

  /// The root of the package whose coverage was not met.
  final String packageRoot = '.',
}) implements Exception {
  /// {@macro coverage_not_met}
  this;
}

/// {@template coverage_report_missing}
/// Thrown when a test run that collects coverage left no coverage behind,
/// although it ran to completion and reported no failing test.
///
/// The test runner most likely crashed before writing the report, so a retry
/// may succeed.
/// {@endtemplate}
class const CoverageReportMissing(
  /// The root of the package whose coverage is missing.
  final String packageRoot,
) implements Exception {
  /// {@macro coverage_report_missing}
  this;

  @override
  String toString() =>
      'The test runner exited without writing the coverage of $packageRoot. '
      'It may have crashed; a retry may succeed.';
}

/// {@template coverage_report}
/// The coverage of the tests of the package at [packageRoot], kept in
/// `coverage/lcov.info` and checked against the [options].
///
/// Each test runner writes coverage differently, so there is one report per
/// runner: [FlutterCoverageReport] and [DartCoverageReport].
/// {@endtemplate}
sealed class const CoverageReport({
  /// The root of the package whose tests are covered.
  required final String packageRoot,

  /// The coverage settings of the test run.
  required final CoverageOptions options,
}) {
  /// {@macro coverage_report}
  this;

  /// The lcov file the report is kept in.
  File get lcovFile => File(p.join(packageRoot, 'coverage', 'lcov.info'));

  /// The arguments that make the test runner collect coverage, which are
  /// empty when coverage is not collected.
  List<String> get collectArguments => [if (options.collect) _collectArgument];

  String get _collectArgument;

  /// Deletes the report of a previous run, when coverage is collected.
  Future<void> clean() async {
    if (options.collect && lcovFile.existsSync()) await lcovFile.delete();
  }

  /// Leaves an empty report behind, when coverage is collected, for a run
  /// that had no tests to run.
  Future<void> writeEmpty() async {
    if (options.collect) await lcovFile.create(recursive: true);
  }

  /// Writes the report of a finished test run, when coverage is collected,
  /// then checks it against [CoverageOptions.minCoverage] and lists the
  /// uncovered lines to [stdout] when [CoverageOptions.showUncovered] is set.
  ///
  /// A test runner can leave no coverage behind when it is interrupted, or
  /// when it fails, for example before running any test. Pass `false` for
  /// [reportExpected] in those cases to skip the coverage of the run instead.
  ///
  /// Throws [MinCoverageNotMet] when the coverage is below the threshold, and
  /// [CoverageReportMissing] when the test runner left no coverage behind
  /// although [reportExpected].
  Future<void> finalize({
    bool reportExpected = true,
    void Function(String)? stdout,
  }) async {
    if (options.collect) {
      if (!_collected) {
        if (reportExpected) throw CoverageReportMissing(packageRoot);
        return;
      }
      await _write();
    }

    if (options.minCoverage != null || options.showUncovered) {
      await _check(stdout: stdout);
    }
  }

  Future<void> _write() async {
    await _writeLcov();

    if (options.collectFrom == CoverageCollectionMode.all) {
      await _addUntestedFiles(
        lcovPath: lcovFile.path,
        cwd: packageRoot,
        reportOn: options.reportOn,
        excludeFromCoverage: options.excludeFromCoverage,
      );
    }
  }

  /// Whether the test runner left the coverage it collected behind.
  bool get _collected;

  /// Leaves the coverage the test runner collected in [lcovFile].
  Future<void> _writeLcov();

  Future<void> _check({required void Function(String)? stdout}) async {
    final records = await Parser.parse(lcovFile.path);
    final coverageMetrics = CoverageMetrics.fromLcovRecords(
      records,
      excludeFromCoverage: options.excludeFromCoverage,
    );
    final percentage = coverageMetrics.percentage;
    final uncoveredLines = coverageMetrics.uncoveredLines;

    final minCoverage = options.minCoverage;
    if (minCoverage != null && percentage < minCoverage) {
      throw MinCoverageNotMet(
        percentage,
        minCoverage: minCoverage,
        uncoveredLines: uncoveredLines,
        showUncovered: options.showUncovered,
        packageRoot: packageRoot,
      );
    }

    // When coverage passes but is below 100%,
    // show uncovered lines as informational output.
    if (options.showUncovered && uncoveredLines.isNotEmpty) {
      stdout?.call('${formatUncoveredLines(uncoveredLines)}\n');
    }
  }
}

/// {@template flutter_coverage_report}
/// The [CoverageReport] of a `flutter test` run, which writes the lcov file
/// itself.
/// {@endtemplate}
final class const FlutterCoverageReport({
  required super.packageRoot,
  required super.options,
}) extends CoverageReport {
  /// {@macro flutter_coverage_report}
  this;

  @override
  String get _collectArgument => '--coverage';

  @override
  bool get _collected => lcovFile.existsSync();

  @override
  Future<void> _writeLcov() async {}
}

/// {@template dart_coverage_report}
/// The [CoverageReport] of a `dart test` run, which writes json coverage
/// that the report converts into lcov.
/// {@endtemplate}
final class const DartCoverageReport({
  required super.packageRoot,
  required super.options,
}) extends CoverageReport {
  /// {@macro dart_coverage_report}
  this;

  @override
  String get _collectArgument => '--coverage=coverage';

  Directory get _coverageDirectory =>
      Directory(p.join(packageRoot, 'coverage'));

  List<File> get _jsonFiles => _coverageDirectory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.json'))
      .toList();

  @override
  bool get _collected =>
      _coverageDirectory.existsSync() && _jsonFiles.isNotEmpty;

  @override
  Future<void> clean() async {
    await super.clean();
    if (!options.collect || !_coverageDirectory.existsSync()) return;
    for (final file in _jsonFiles) {
      await file.delete();
    }
  }

  @override
  Future<void> _writeLcov() async {
    final files = _jsonFiles;

    final resolvedRoot = Directory(packageRoot).resolveSymbolicLinksSync();
    final resolvedReportOn = [
      for (final path in options.reportOn) p.join(resolvedRoot, path),
    ];

    final hitmap = await coverage.HitMap.parseFiles(
      files,
      packagePath: resolvedRoot,
      checkIgnoredLines: options.checkIgnore,
    );

    final resolver = await coverage.Resolver.create(packagePath: resolvedRoot);

    final output = hitmap.formatLcov(
      resolver,
      reportOn: resolvedReportOn,
      basePath: resolvedRoot,
    );

    await lcovFile.create(recursive: true);
    await lcovFile.writeAsString(output);
  }
}
