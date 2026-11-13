part of 'cli.dart';

/// A test that failed, or a test file that failed to load (named
/// `loading <file>`).
///
/// `file` is relative to the current directory, and `error` is a short,
/// single line summary of the error the test reported.
typedef FailingTest = ({String file, String name, String error});

/// {@template test_run_results}
/// An immutable snapshot of what a test run reported beyond its exit code:
/// counts of passing, failing and skipped tests, the time they took, and the
/// failing tests themselves.
/// {@endtemplate}
class const TestRunResults({
  final int passed = 0,
  final int skipped = 0,
  final int durationMs = 0,
  final List<FailingTest> failingTests = const [],
}) {
  /// {@macro test_run_results}
  this;

  /// Whether a test failed, or a test file failed to load.
  bool get testsFailed => failingTests.isNotEmpty;

  /// Whether any test outcome was recorded.
  bool get hasResults => passed > 0 || skipped > 0 || testsFailed;

  /// Returns a new [TestRunResults] that adds [other]'s counts, duration and
  /// failing tests to this one's.
  TestRunResults merge(TestRunResults other) => TestRunResults(
    passed: passed + other.passed,
    skipped: skipped + other.skipped,
    durationMs: durationMs + other.durationMs,
    failingTests: [...failingTests, ...other.failingTests],
  );
}

/// {@template test_run_recorder}
/// Records what a test run reported beyond its exit code, for a caller that
/// needs to tell the outcomes sharing an exit code apart.
///
/// Failing tests and an unmet coverage threshold both exit with
/// [ExitCode.software], and their details are only printed. The MCP server
/// installs a recorder around each tool call with [runZoned], and the test
/// runner reports its per-package results with [recordPackage]. On the
/// command line there is no recorder, so nothing is recorded.
/// {@endtemplate}
class TestRunRecorder {
  static final _token = Object();

  /// Returns the [TestRunRecorder] of the current [Zone].
  ///
  /// This will return `null` if the current [Zone] does not contain any
  /// [TestRunRecorder].
  ///
  /// See also:
  /// * [TestRunRecorder.runZoned] to provide a [TestRunRecorder] in a fresh
  ///   [Zone].
  static TestRunRecorder? get current =>
      Zone.current[_token] as TestRunRecorder?;

  /// Runs [body] in a fresh [Zone] that records to [recorder].
  static R runZoned<R>(
    R Function() body, {
    required TestRunRecorder recorder,
  }) => _asyncRunZoned(body, zoneValues: {_token: recorder});

  TestRunResults _results = const TestRunResults();

  /// The accumulated results of every package [recordPackage] was called for.
  ///
  /// Each call returns a fresh snapshot; a later [recordPackage] cannot mutate
  /// an already-returned value.
  TestRunResults get results => _results;

  /// Accumulates the [packageResults] of a single package into [results].
  void recordPackage(TestRunResults packageResults) {
    _results = _results.merge(packageResults);
  }

  /// The unmet coverage threshold of the run, if any.
  MinCoverageNotMet? coverageNotMet;

  /// Whether a test failed, or a test file failed to load.
  bool get testsFailed => _results.testsFailed;

  /// Whether any test outcome was recorded.
  bool get hasResults => _results.hasResults;
}
