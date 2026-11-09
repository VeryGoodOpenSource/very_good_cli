import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:checked_yaml/checked_yaml.dart';
import 'package:dart_mcp/server.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mason/mason.dart' hide packageVersion;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:very_good_cli/src/cli/cli.dart';

part 'structured_tool_error.g.dart';

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
    PathAccessException() => ToolFailureType.permission,
    _ => ToolFailureType.business,
  };

  /// The default [ToolFailureReason] for a failure of this type, when no more
  /// specific cause has been told apart.
  ///
  /// A caller with extra context may override this — for example, exit code
  /// 64 ([ExitCode.usage]) is a [validation] failure with a
  /// [ToolFailureReason.usageError] reason, and a test runner distinguishes
  /// failing tests from an unmet coverage threshold, both of which exit with
  /// [ExitCode.software].
  ToolFailureReason get failureReason => switch (this) {
    ToolFailureType.validation => ToolFailureReason.invalidInput,
    ToolFailureType.permission => ToolFailureReason.permissionDenied,
    ToolFailureType.transient => ToolFailureReason.toolCrash,
    ToolFailureType.timeout => ToolFailureReason.timeout,
    ToolFailureType.business => ToolFailureReason.checkFailed,
  };
}

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

  /// A deterministic check reported a failure without naming a more specific
  /// cause. Re-running the same command reproduces the same outcome.
  checkFailed('check_failed'),

  /// The tool exited unexpectedly or threw a transient error; a retry may
  /// succeed.
  toolCrash('tool_crash'),

  /// A caller-supplied argument, or the project it points to, was invalid.
  invalidInput('invalid_input'),

  /// The command line built from the tool arguments was rejected.
  usageError('usage_error'),

  /// The run exceeded its wall-clock budget.
  timeout('timeout'),

  /// The process lacked permission to complete the action.
  permissionDenied('permission_denied');

  /// Suggests alternative approaches to try after a failure of this reason.
  ///
  /// These are surfaced verbatim in the structured error payload so an agent
  /// coordinator has recovery options attached to every failure without
  /// having to reason about the failure itself.
  List<String> get alternativeApproaches => switch (this) {
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
    ToolFailureReason.checkFailed => const [
      'Read the captured output for the specific check that failed.',
      '''Fix the underlying cause; an unchanged re-run fails the same way.''',
      '''Escalate to the user if the cause is outside the project, such as a broken SDK install.''',
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
}

/// The most failing tests a [StructuredToolError] lists.
const maxFailingTests = 20;

/// The most files a [StructuredToolError] lists the uncovered lines of.
const maxUncoveredFiles = 20;

/// The most uncovered lines a [StructuredToolError] lists per file.
const maxUncoveredLinesPerFile = 20;

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
///   [maxFailingTests] failing tests. For a `coverage_below_threshold`
///   failure, `coverage` holds the actual and required coverage and the
///   uncovered lines of the first [maxUncoveredFiles] files, at most
///   [maxUncoveredLinesPerFile] each, relative to the current directory.
/// * `partialResults` — the sanitized captured command output, when any.
/// * `alternativeApproaches` — recovery suggestions for the `failureReason`,
///   from [ToolFailureReason.alternativeApproaches].
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
      'test': ?_testPayload?.toJson(),
      if (_hasPartialResults) 'partialResults': capturedOutput,
      'alternativeApproaches': failureReason.alternativeApproaches,
    };
  }

  _TestPayload? get _testPayload {
    final testRun = this.testRun;
    if (testRun == null) return null;

    final coverageNotMet =
        failureReason == ToolFailureReason.coverageBelowThreshold
        ? testRun.coverageNotMet
        : null;
    if (!testRun.hasResults && coverageNotMet == null) return null;

    return _TestPayload(
      results: testRun.hasResults ? _TestResultsPayload.of(testRun) : null,
      coverage: coverageNotMet == null
          ? null
          : _CoveragePayload.of(coverageNotMet),
    );
  }

  /// Renders this failure as a [CallToolResult] whose single text content is
  /// the pretty-printed [toJson] payload.
  CallToolResult toCallToolResult() {
    final text = const JsonEncoder.withIndent('  ').convert(toJson());

    return CallToolResult(content: [TextContent(text: text)], isError: true);
  }
}

/// The structured `test` block of a failure payload.
///
/// Either or both of [results] and [coverage] may be null; a null field is
/// omitted from the serialized JSON.
@JsonSerializable(createFactory: false, includeIfNull: false)
class const _TestPayload({
  final _TestResultsPayload? results,
  final _CoveragePayload? coverage,
}) {
  Map<String, Object?> toJson() => _$TestPayloadToJson(this);
}

/// The structured results of a test run attached to a failure payload.
///
/// [failed] is the total number of failing tests, [failingTests] is capped at
/// [maxFailingTests] entries with [failingTestsTruncated] flagging that the
/// cap was hit.
@JsonSerializable(createFactory: false)
class const _TestResultsPayload({
  required final int passed,
  required final int failed,
  required final int skipped,
  required final int durationMs,
  required final List<_FailingTestPayload> failingTests,
  required final bool failingTestsTruncated,
}) {
  factory of(TestRunRecorder testRun) {
    final failingTests = testRun.failingTests;
    return _TestResultsPayload(
      passed: testRun.passed,
      failed: failingTests.length,
      skipped: testRun.skipped,
      durationMs: testRun.durationMs,
      failingTests: [
        for (final (:file, :name, :error) in failingTests.take(maxFailingTests))
          _FailingTestPayload(file: file, name: name, error: error),
      ],
      failingTestsTruncated: failingTests.length > maxFailingTests,
    );
  }

  Map<String, Object?> toJson() => _$TestResultsPayloadToJson(this);
}

/// One failing test or test file load failure in a [_TestResultsPayload].
@JsonSerializable(createFactory: false)
class const _FailingTestPayload({
  required final String file,
  required final String name,
  required final String error,
}) {
  Map<String, Object?> toJson() => _$FailingTestPayloadToJson(this);
}

/// The structured coverage breakdown of a `coverage_below_threshold` failure.
///
/// [uncoveredLines] is capped at [maxUncoveredFiles] files, each with at most
/// [maxUncoveredLinesPerFile] line numbers, with [uncoveredLinesTruncated]
/// flagging that either cap was hit.
@JsonSerializable(createFactory: false)
class const _CoveragePayload({
  required final double actual,
  @JsonKey(name: 'required') required final double requiredCoverage,
  required final List<_UncoveredFilePayload> uncoveredLines,
  required final bool uncoveredLinesTruncated,
}) {
  factory of(MinCoverageNotMet coverageNotMet) {
    final MinCoverageNotMet(:uncoveredLines, :packageRoot) = coverageNotMet;
    final files = uncoveredLines.entries.take(maxUncoveredFiles).toList();

    return _CoveragePayload(
      actual: coverageNotMet.coverage,
      requiredCoverage: coverageNotMet.minCoverage,
      uncoveredLines: [
        for (final MapEntry(key: file, value: lines) in files)
          _UncoveredFilePayload(
            file: p.relative(p.join(packageRoot, file)),
            lines: lines.take(maxUncoveredLinesPerFile).toList(),
          ),
      ],
      uncoveredLinesTruncated:
          uncoveredLines.length > maxUncoveredFiles ||
          files.any((file) => file.value.length > maxUncoveredLinesPerFile),
    );
  }

  Map<String, Object?> toJson() => _$CoveragePayloadToJson(this);
}

/// The uncovered lines of one file in a [_CoveragePayload].
@JsonSerializable(createFactory: false)
class const _UncoveredFilePayload({
  required final String file,
  required final List<int> lines,
}) {
  Map<String, Object?> toJson() => _$UncoveredFilePayloadToJson(this);
}
