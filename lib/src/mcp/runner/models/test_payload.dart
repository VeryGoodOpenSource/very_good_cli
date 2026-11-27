import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as p;
import 'package:very_good_cli/src/cli/cli.dart';

part 'test_payload.g.dart';

/// The most items (failing tests, uncovered files, uncovered lines per file)
/// a [TestPayload] lists before truncating.
const maxPayloadItems = 20;

/// {@template test_payload}
/// The `test` block of a tool result: what a test run recorded.
///
/// Either or both of [results] and [coverage] may be null; a null field is
/// omitted from the serialized JSON.
/// {@endtemplate}
@JsonSerializable(
  createFactory: false,
  includeIfNull: false,
  explicitToJson: true,
)
class const TestPayload({
  /// The test counts, the duration and the failing tests, when any test
  /// outcome was recorded.
  final TestResultsPayload? results,

  /// The coverage breakdown, when coverage is below the required threshold.
  final CoveragePayload? coverage,
}) {
  /// {@macro test_payload}
  this;

  /// The payload for the [results] and unmet [coverage] threshold of a test
  /// run, or null when it recorded neither.
  static TestPayload? maybeOf(
    TestRunResults? results, {
    MinCoverageNotMet? coverage,
  }) {
    final hasResults = results != null && results.hasResults;
    if (!hasResults && coverage == null) return null;

    return TestPayload(
      results: hasResults ? TestResultsPayload.of(results) : null,
      coverage: coverage == null ? null : CoveragePayload.of(coverage),
    );
  }

  /// The JSON form of this payload.
  Map<String, Object?> toJson() => _$TestPayloadToJson(this);
}

/// {@template test_results_payload}
/// The results of a test run in a [TestPayload].
///
/// [failed] is the total number of failing tests, [failingTests] is capped at
/// [maxPayloadItems] entries. A reader can tell the list was truncated by
/// comparing its length against [failed].
/// {@endtemplate}
@JsonSerializable(createFactory: false, explicitToJson: true)
class const TestResultsPayload({
  /// The number of tests that passed.
  required final int passed,

  /// The number of tests that failed, or test files that failed to load.
  required final int failed,

  /// The number of tests that were skipped.
  required final int skipped,

  /// How long the tests ran for, in milliseconds.
  required final int durationMs,

  /// The first [maxPayloadItems] failing tests.
  required final List<FailingTestPayload> failingTests,
}) {
  /// {@macro test_results_payload}
  this;

  /// The payload for the [results] of a test run.
  factory of(TestRunResults results) {
    final failingTests = results.failingTests;
    return TestResultsPayload(
      passed: results.passed,
      failed: failingTests.length,
      skipped: results.skipped,
      durationMs: results.durationMs,
      failingTests: [
        for (final (:file, :name, :error) in failingTests.take(maxPayloadItems))
          FailingTestPayload(file: file, name: name, error: error),
      ],
    );
  }

  /// The JSON form of this payload.
  Map<String, Object?> toJson() => _$TestResultsPayloadToJson(this);
}

/// {@template failing_test_payload}
/// One failing test or test file load failure in a [TestResultsPayload].
/// {@endtemplate}
@JsonSerializable(createFactory: false)
class const FailingTestPayload({
  /// The test file.
  required final String file,

  /// The name of the test, or `loading <file>` for a file that failed to
  /// load.
  required final String name,

  /// The single-line error of the test.
  required final String error,
}) {
  /// {@macro failing_test_payload}
  this;

  /// The JSON form of this payload.
  Map<String, Object?> toJson() => _$FailingTestPayloadToJson(this);
}

/// {@template coverage_payload}
/// The coverage breakdown of a `coverage_below_threshold` failure.
///
/// [uncoveredLines] is capped at [maxPayloadItems] files, each with at most
/// [maxPayloadItems] line numbers, with [uncoveredLinesTruncated] flagging
/// that either cap was hit.
/// {@endtemplate}
@JsonSerializable(createFactory: false, explicitToJson: true)
class const CoveragePayload({
  /// The coverage percentage the test run reached.
  required final double actual,

  /// The coverage percentage the test run had to reach.
  @JsonKey(name: 'required') required final double requiredCoverage,

  /// The uncovered lines, grouped per file.
  required final List<UncoveredFilePayload> uncoveredLines,

  /// Whether files or lines were left out of [uncoveredLines].
  required final bool uncoveredLinesTruncated,
}) {
  /// {@macro coverage_payload}
  this;

  /// The payload for an unmet coverage threshold, with file paths relative
  /// to the current directory.
  factory of(MinCoverageNotMet coverageNotMet) {
    final MinCoverageNotMet(:uncoveredLines, :packageRoot) = coverageNotMet;
    final files = uncoveredLines.entries.take(maxPayloadItems).toList();

    return CoveragePayload(
      actual: coverageNotMet.coverage,
      requiredCoverage: coverageNotMet.minCoverage,
      uncoveredLines: [
        for (final MapEntry(key: file, value: lines) in files)
          UncoveredFilePayload(
            file: p.relative(p.join(packageRoot, file)),
            lines: lines.take(maxPayloadItems).toList(),
          ),
      ],
      uncoveredLinesTruncated:
          uncoveredLines.length > maxPayloadItems ||
          files.any((file) => file.value.length > maxPayloadItems),
    );
  }

  /// The JSON form of this payload.
  Map<String, Object?> toJson() => _$CoveragePayloadToJson(this);
}

/// {@template uncovered_file_payload}
/// The uncovered lines of one file in a [CoveragePayload].
/// {@endtemplate}
@JsonSerializable(createFactory: false)
class const UncoveredFilePayload({
  /// The file, relative to the current directory.
  required final String file,

  /// The first [maxPayloadItems] uncovered line numbers.
  required final List<int> lines,
}) {
  /// {@macro uncovered_file_payload}
  this;

  /// The JSON form of this payload.
  Map<String, Object?> toJson() => _$UncoveredFilePayloadToJson(this);
}
