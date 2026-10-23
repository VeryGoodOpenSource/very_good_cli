import 'dart:convert';

import 'package:dart_mcp/server.dart';
import 'package:mason/mason.dart' hide packageVersion;
import 'package:meta/meta.dart';

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
///   safest default for an outcome that can't be attributed to the other
///   three.
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
}

/// Suggests alternative approaches keyed on [failureType].
///
/// These are surfaced verbatim in the structured error payload so an agent
/// coordinator has recovery options attached to every failure without having
/// to reason about the failure type itself.
@visibleForTesting
List<String> alternativeApproachesFor(ToolFailureType failureType) {
  const alternativeApproachesByFailureType = {
    ToolFailureType.transient: [
      'Retry the command; the failure may resolve on its own.',
      'Check network and remote service availability, then retry.',
      'If retries keep failing with the same error, switch approach.',
    ],
    ToolFailureType.validation: [
      'Correct any invalid tool arguments before retrying.',
      'Consult the tool schema for accepted parameters and values.',
      'Inspect the captured output for the field the CLI rejected.',
    ],
    ToolFailureType.permission: [
      'Ensure the process can read and write the target directory.',
      'Retry after adjusting filesystem permissions or credentials.',
      'Cannot be retried as-is without an authorization change.',
    ],
    ToolFailureType.business: [
      'Read the captured output for the check that failed.',
      'Fix the reported problem; an unchanged re-run fails the same way.',
      'Escalate to the user if the constraint cannot be satisfied.',
    ],
    ToolFailureType.timeout: [
      '''Inspect the captured output for the test that was running when the timeout fired; a deterministic hang will reproduce on a retry.''',
      '''Investigate hangs in tester.pumpAndSettle and tester.runAsync, which bypass the per-test timeout when they await a future that never completes.''',
      '''Raise the "timeout_seconds" budget only after confirming the hang is not deterministic.''',
    ],
  };

  return alternativeApproachesByFailureType[failureType]!;
}

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
/// * `attemptedAction` — the tool name, the concrete CLI command that was
///   invoked (when known), the working directory (when set), and the raw
///   caller-supplied arguments.
/// * `reason` — the human-readable failure cause.
/// * `partialResults` — the sanitized captured command output, when any.
/// * `alternativeApproaches` — recovery suggestions from
///   [alternativeApproachesFor].
/// {@endtemplate}
class const StructuredToolError({
  /// The name of the tool that failed.
  required final String toolName,

  /// The human-readable failure cause.
  required final String reason,

  /// The bucket this failure falls into.
  required final ToolFailureType failureType,

  /// The concrete CLI command that was invoked, when known.
  final String? commandString,

  /// The working directory the command ran in, when set.
  final String? directory,

  /// The sanitized captured command output, when any.
  final String? capturedOutput,

  /// The raw caller-supplied arguments.
  final Map<String, Object?>? attemptedArguments,
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
      'attemptedAction': attemptedAction,
      'reason': reason,
      if (_hasPartialResults) 'partialResults': capturedOutput,
      'alternativeApproaches': alternativeApproachesFor(failureType),
    };
  }

  /// Renders this failure as a [CallToolResult] whose single text content is
  /// the pretty-printed [toJson] payload.
  CallToolResult toCallToolResult() {
    final text = const JsonEncoder.withIndent('  ').convert(toJson());

    return CallToolResult(content: [TextContent(text: text)], isError: true);
  }
}
