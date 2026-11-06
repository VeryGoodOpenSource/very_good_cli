part of 'cli.dart';

/// A test that failed, or a test file that failed to load (named
/// `loading <file>`).
///
/// `file` is relative to the current directory, and `error` is a short,
/// single line summary of the error the test reported.
typedef FailingTest = ({String file, String name, String error});

/// {@template test_run_recorder}
/// Records what a test run reported beyond its exit code, for a caller that
/// needs to tell the outcomes sharing an exit code apart.
///
/// Failing tests and an unmet coverage threshold both exit with
/// [ExitCode.software], and their details are only printed. The MCP server
/// installs a recorder around each tool call with [runZoned], and the test
/// runner writes to [current] when one is installed. On the command line
/// there is none, so nothing is recorded.
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

  /// The number of tests that passed.
  int passed = 0;

  /// The number of tests that were skipped.
  int skipped = 0;

  /// How long the tests ran for, in milliseconds, added up across packages.
  int durationMs = 0;

  /// The tests that failed, and the test files that failed to load, in the
  /// order they were reported.
  final List<FailingTest> failingTests = [];

  /// Whether a test failed, or a test file failed to load.
  bool get testsFailed => failingTests.isNotEmpty;

  /// Whether any test outcome was recorded.
  bool get hasResults => passed > 0 || skipped > 0 || testsFailed;

  /// The unmet coverage threshold of the run, if any.
  MinCoverageNotMet? coverageNotMet;
}
