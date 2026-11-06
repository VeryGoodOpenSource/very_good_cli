part of 'cli.dart';

/// {@template test_run_recorder}
/// Records what a test run reported beyond its exit code, for a caller that
/// needs to tell the outcomes sharing an exit code apart.
///
/// Failing tests and an unmet coverage threshold both exit with
/// [ExitCode.software]. The MCP server installs a recorder around each tool
/// call with [runZoned], and the test runner writes to [current] when one is
/// installed. On the command line there is none, so nothing is recorded.
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

  /// Whether a test failed, or a test file failed to load.
  bool testsFailed = false;

  /// The unmet coverage threshold of the run, if any.
  MinCoverageNotMet? coverageNotMet;
}
