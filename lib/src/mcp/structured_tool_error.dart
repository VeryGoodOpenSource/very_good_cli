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
/// * `business` — a domain rule was violated; the safest default for an
///   outcome that can't be attributed to the other three.
enum ToolFailureType {
  /// A caller-supplied argument was invalid.
  validation,

  /// The process lacked permission to complete the action.
  permission,

  /// An environment or infrastructure hiccup; retrying may resolve it.
  transient,

  /// A domain rule was violated.
  business,
}

/// Classifies an [exitCode] into a [ToolFailureType].
///
/// Codes follow the sysexits.h conventions surfaced by `package:io`'s
/// [ExitCode]; unknown codes fall back to [ToolFailureType.business], the
/// safest default for an outcome we can't attribute to a transient failure or
/// a bad input.
ToolFailureType failureTypeForExitCode(int exitCode) {
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
      'Inspect the captured output for the specific rule reported.',
      'Try an alternate subcommand, template, or configuration.',
      'Escalate to the user if the constraint cannot be satisfied.',
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
class StructuredToolError {
  /// {@macro structured_tool_error}
  const StructuredToolError({
    required this.toolName,
    required this.reason,
    required this.failureType,
    this.commandString,
    this.directory,
    this.capturedOutput,
    this.attemptedArguments,
  });

  /// The name of the tool that failed.
  final String toolName;

  /// The human-readable failure cause.
  final String reason;

  /// The bucket this failure falls into.
  final ToolFailureType failureType;

  /// The concrete CLI command that was invoked, when known.
  final String? commandString;

  /// The working directory the command ran in, when set.
  final String? directory;

  /// The sanitized captured command output, when any.
  final String? capturedOutput;

  /// The raw caller-supplied arguments.
  final Map<String, Object?>? attemptedArguments;

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
