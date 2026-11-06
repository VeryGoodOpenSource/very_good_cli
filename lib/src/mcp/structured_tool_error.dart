import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:checked_yaml/checked_yaml.dart';
import 'package:dart_mcp/server.dart';
import 'package:mason/mason.dart' hide packageVersion;
import 'package:meta/meta.dart';
import 'package:very_good_cli/src/cli/cli.dart';

/// Classifies a tool failure into a bucket an agent loop can act on without
/// parsing free-form text.
///
/// * `validation` — the caller supplied bad input; retrying as-is won't help.
/// * `permission` — the process lacks filesystem or credential access.
/// * `transient` — an environment or infrastructure hiccup; retrying may
///   succeed.
/// * `timeout` — the run exceeded its wall-clock budget and was abandoned
///   before completing. Retrying as-is is unlikely to help if the cause is
///   deterministic.
/// * `business` — a deterministic check reported a failure: a failing test
///   suite, an unmet coverage threshold, a violated project rule. Also the
///   safest default for an outcome or exception that can't be attributed to
///   the other buckets.
///
/// A failure is classified from the command's exit code with
/// [ToolFailureType.fromExitCode], or from the exception it threw with
/// [ToolFailureType.fromException].
enum ToolFailureType {
  /// A caller-supplied argument was invalid.
  validation,

  /// The process lacked permission to complete the action.
  permission,

  /// An environment or infrastructure hiccup; retrying may resolve it.
  transient,

  /// The run exceeded its wall-clock budget before completing and was
  /// abandoned.
  timeout,

  /// A deterministic check reported a failure. Re-running the same command
  /// reproduces the same outcome.
  business;

  /// Classifies an [exitCode] into a [ToolFailureType].
  ///
  /// Codes follow the sysexits.h conventions surfaced by `package:io`'s
  /// [ExitCode]. A deterministic failure reports [ExitCode.software]; a run
  /// that could not complete at all reports [ExitCode.unavailable]. Unknown
  /// codes fall back to [ToolFailureType.business], the safest default for an
  /// outcome we can't attribute to a transient failure or a bad input.
  factory fromExitCode(int exitCode) {
    if (exitCode == ExitCode.usage.code ||
        exitCode == ExitCode.data.code ||
        exitCode == ExitCode.noInput.code ||
        exitCode == ExitCode.config.code) {
      return ToolFailureType.validation;
    }

    if (exitCode == ExitCode.noPerm.code) {
      return ToolFailureType.permission;
    }

    if (exitCode == ExitCode.unavailable.code ||
        exitCode == ExitCode.tempFail.code ||
        exitCode == ExitCode.ioError.code ||
        exitCode == ExitCode.osError.code ||
        exitCode == ExitCode.osFile.code ||
        exitCode == ExitCode.cantCreate.code) {
      return ToolFailureType.transient;
    }

    return ToolFailureType.business;
  }

  /// Classifies an [exception] thrown by a command into a [ToolFailureType].
  ///
  /// Only network and timeout exceptions are [ToolFailureType.transient], so
  /// a deterministic exception is never reported as worth a retry. Exceptions
  /// caused by bad input (an invalid argument, malformed YAML, a missing path)
  /// are [ToolFailureType.validation], and a file system operation denied by
  /// the OS is [ToolFailureType.permission]. Anything else falls back to
  /// [ToolFailureType.business].
  factory fromException(Exception exception) => switch (exception) {
    SocketException() ||
    HttpException() ||
    TlsException() ||
    TimeoutException() => ToolFailureType.transient,
    UsageException() ||
    FormatException() ||
    ParsedYamlException() ||
    PathNotFoundException() => ToolFailureType.validation,
    FileSystemException(:final osError?)
        when _permissionDeniedErrorCodes.contains(osError.errorCode) =>
      ToolFailureType.permission,
    _ => ToolFailureType.business,
  };
}

/// The OS error codes of a denied file system operation: `EPERM` (1) and
/// `EACCES` (13) on POSIX systems, `ERROR_ACCESS_DENIED` (5) on Windows.
const _permissionDeniedErrorCodes = {1, 5, 13};

/// The specific cause of a tool failure, more precise than its
/// [ToolFailureType], so an agent can pick a recovery strategy.
///
/// Serialized as its [jsonName].
enum ToolFailureReason(
  /// The name of the reason in the JSON payload.
  final String jsonName,
) {
  /// A test failed, or a test file failed to load.
  testFailure('test_failure'),

  /// The tests passed, but their coverage is below the required threshold.
  coverageBelowThreshold('coverage_below_threshold'),

  /// The tool exited unexpectedly or threw, without reporting a more specific
  /// cause.
  toolCrash('tool_crash'),

  /// A caller-supplied argument, or the project it points to, was invalid.
  invalidInput('invalid_input'),

  /// The command line built from the tool arguments was rejected.
  usageError('usage_error'),

  /// The run exceeded its wall-clock budget.
  timeout('timeout'),

  /// The process lacked permission to complete the action.
  permissionDenied('permission_denied')
}

/// Suggests alternative approaches keyed on [failureReason].
///
/// These are surfaced verbatim in the structured error payload so an agent
/// coordinator has recovery options attached to every failure without having
/// to reason about the failure itself.
@visibleForTesting
List<String> alternativeApproachesFor(ToolFailureReason failureReason) =>
    switch (failureReason) {
      ToolFailureReason.testFailure => const [
        'Read the failing tests and their errors in the captured output.',
        '''Fix the code under test or the failing tests; an unchanged re-run fails the same way.''',
        '''Run only the failing test files while iterating, then the whole suite.''',
      ],
      ToolFailureReason.coverageBelowThreshold => const [
        '''Run with "show_uncovered": true to list the lines left uncovered.''',
        '''Add tests that cover those lines; an unchanged re-run fails the same way.''',
        '''Lower "min_coverage" or exclude files from coverage only with the user's agreement.''',
      ],
      ToolFailureReason.toolCrash => const [
        'Retry the command once; a crash or network hiccup may not recur.',
        '''If it fails the same way again, read the captured output for the cause and fix it before retrying.''',
        '''Escalate to the user if the cause is outside the project, such as a broken SDK install.''',
      ],
      ToolFailureReason.invalidInput => const [
        'Correct any invalid tool arguments before retrying.',
        'Check that the target directory holds the expected project.',
        'Inspect the captured output for the input the CLI rejected.',
      ],
      ToolFailureReason.usageError => const [
        'Consult the tool schema for accepted parameters and values.',
        'Correct the argument named in the reason before retrying.',
      ],
      ToolFailureReason.timeout => const [
        '''Inspect the captured output for the test that was running when the timeout fired; a deterministic hang will reproduce on a retry.''',
        '''Investigate hangs in tester.pumpAndSettle and tester.runAsync, which bypass the per-test timeout when they await a future that never completes.''',
        '''Raise the "timeout_seconds" budget only after confirming the hang is not deterministic.''',
      ],
      ToolFailureReason.permissionDenied => const [
        'Ensure the process can read and write the target directory.',
        'Adjust filesystem permissions or credentials, then run again.',
        'Cannot succeed as-is without an authorization change.',
      ],
    };

/// The most failing tests a [StructuredToolError] lists.
const maxFailingTests = 20;

/// {@template structured_tool_error}
/// A structured description of a tool failure, renderable as a
/// [CallToolResult].
///
/// Encapsulates the JSON payload shape agents rely on to pick a recovery
/// strategy:
///
/// * `status` — `partial_failure` if [capturedOutput] is non-empty, else
///   `failure`.
/// * `failureType` — the [ToolFailureType] name.
/// * `failureReason` — the [ToolFailureReason.jsonName].
/// * `attemptedAction` — the tool name, the concrete CLI command that was
///   invoked (when known), the working directory (when set), and the raw
///   caller-supplied arguments.
/// * `reason` — the human-readable failure cause.
/// * `test` — what the [testRun] recorded, when it recorded any test result:
///   `results` holds the test counts, the run's duration and the first
///   [maxFailingTests] failing tests.
/// * `partialResults` — the sanitized captured command output, when any.
/// * `alternativeApproaches` — recovery suggestions for the `failureReason`,
///   from [alternativeApproachesFor].
/// {@endtemplate}
class const StructuredToolError({
  /// The name of the tool that failed.
  required final String toolName,

  /// The human-readable failure cause.
  required final String reason,

  /// The bucket this failure falls into.
  required final ToolFailureType failureType,

  /// The specific cause of this failure.
  required final ToolFailureReason failureReason,

  /// The concrete CLI command that was invoked, when known.
  final String? commandString,

  /// The working directory the command ran in, when set.
  final String? directory,

  /// The sanitized captured command output, when any.
  final String? capturedOutput,

  /// The raw caller-supplied arguments.
  final Map<String, Object?>? attemptedArguments,

  /// What the test run of the tool recorded, if it ran tests.
  final TestRunRecorder? testRun,
}) {
  /// {@macro structured_tool_error}
  this;

  bool get _hasPartialResults =>
      capturedOutput != null && capturedOutput!.isNotEmpty;

  /// The JSON payload describing this failure.
  Map<String, Object?> toJson() {
    final attemptedAction = <String, Object?>{
      'tool': toolName,
      'command': ?commandString,
      'directory': ?directory,
      if (attemptedArguments != null && attemptedArguments!.isNotEmpty)
        'arguments': attemptedArguments,
    };

    return {
      'status': _hasPartialResults ? 'partial_failure' : 'failure',
      'failureType': failureType.name,
      'failureReason': failureReason.jsonName,
      'attemptedAction': attemptedAction,
      'reason': reason,
      'test': ?_testJson,
      if (_hasPartialResults) 'partialResults': capturedOutput,
      'alternativeApproaches': alternativeApproachesFor(failureReason),
    };
  }

  Map<String, Object?>? get _testJson {
    final testRun = this.testRun;
    if (testRun == null || !testRun.hasResults) return null;

    final failingTests = testRun.failingTests;
    return {
      'results': {
        'passed': testRun.passed,
        'failed': failingTests.length,
        'skipped': testRun.skipped,
        'durationMs': testRun.durationMs,
        'failingTests': [
          for (final (:file, :name, :error) in failingTests.take(
            maxFailingTests,
          ))
            {'file': file, 'name': name, 'error': error},
        ],
        'failingTestsTruncated': failingTests.length > maxFailingTests,
      },
    };
  }

  /// Renders this failure as a [CallToolResult] whose single text content is
  /// the pretty-printed [toJson] payload.
  CallToolResult toCallToolResult() {
    final text = const JsonEncoder.withIndent('  ').convert(toJson());

    return CallToolResult(content: [TextContent(text: text)], isError: true);
  }
}
