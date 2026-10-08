part of 'coverage.dart';

/// {@template coverage_not_met}
/// Thrown when `flutter test ---coverage --min-coverage`
/// does not meet the provided minimum coverage threshold.
/// {@endtemplate}
class MinCoverageNotMet implements Exception {
  /// {@macro coverage_not_met}
  const new(this.coverage, {required this.minCoverage, this.uncoveredLines});

  /// The measured coverage percentage (total hits / total found * 100).
  final double coverage;

  /// The minimum coverage percentage the run had to reach.
  final double minCoverage;

  /// Lines not covered, keyed by file path, values are line numbers.
  ///
  /// Only populated when `--show-uncovered` is set.
  final Map<String, List<int>>? uncoveredLines;
}

/// {@template coverage_report}
/// The coverage of the tests of the package at [packageRoot], kept in
/// `coverage/lcov.info` and checked against the [options].
///
/// Each test runner writes coverage differently, so there is one report per
/// runner: [FlutterCoverageReport] and [DartCoverageReport].
/// {@endtemplate}
sealed class CoverageReport {
  /// {@macro coverage_report}
  const new({required this.packageRoot, required this.options});

  /// The root of the package whose tests are covered.
  final String packageRoot;

  /// The coverage settings of the test run.
  final CoverageOptions options;

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
  /// Throws [MinCoverageNotMet] when the coverage is below the threshold.
  Future<void> finalize({void Function(String)? stdout}) async {
    if (options.collect) await _write();

    if (options.minCoverage != null || options.showUncovered) {
      await _check(stdout: stdout);
    }
  }

  Future<void> _write() async {
    await _writeLcov();

    assert(lcovFile.existsSync(), 'coverage/lcov.info must exist');

    if (options.collectFrom == CoverageCollectionMode.all) {
      await _addUntestedFiles(
        lcovPath: lcovFile.path,
        cwd: packageRoot,
        reportOn: options.reportOn,
        excludeFromCoverage: options.excludeFromCoverage,
      );
    }
  }

  /// Leaves the coverage the test runner collected in [lcovFile].
  Future<void> _writeLcov();

  Future<void> _check({required void Function(String)? stdout}) async {
    final records = await Parser.parse(lcovFile.path);
    final coverageMetrics = CoverageMetrics.fromLcovRecords(
      records,
      excludeFromCoverage: options.excludeFromCoverage,
    );
    final percentage = coverageMetrics.percentage;
    final uncoveredLines =
        options.showUncovered && coverageMetrics.uncoveredLines.isNotEmpty
        ? coverageMetrics.uncoveredLines
        : null;

    final minCoverage = options.minCoverage;
    if (minCoverage != null && percentage < minCoverage) {
      throw MinCoverageNotMet(
        percentage,
        minCoverage: minCoverage,
        uncoveredLines: uncoveredLines,
      );
    }

    // When coverage passes but is below 100%,
    // show uncovered lines as informational output.
    if (uncoveredLines != null) {
      stdout?.call('${formatUncoveredLines(uncoveredLines)}\n');
    }
  }
}

/// {@template flutter_coverage_report}
/// The [CoverageReport] of a `flutter test` run, which writes the lcov file
/// itself.
/// {@endtemplate}
final class FlutterCoverageReport extends CoverageReport {
  /// {@macro flutter_coverage_report}
  const new({required super.packageRoot, required super.options});

  @override
  String get _collectArgument => '--coverage';

  @override
  Future<void> _writeLcov() async {}
}

/// {@template dart_coverage_report}
/// The [CoverageReport] of a `dart test` run, which writes json coverage
/// that the report converts into lcov.
/// {@endtemplate}
final class DartCoverageReport extends CoverageReport {
  /// {@macro dart_coverage_report}
  const new({required super.packageRoot, required super.options});

  @override
  String get _collectArgument => '--coverage=coverage';

  @override
  Future<void> _writeLcov() async {
    final files = Directory(p.join(packageRoot, 'coverage'))
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList();

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
