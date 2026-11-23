import 'dart:convert';

import 'package:dart_mcp/server.dart';
import 'package:very_good_cli/src/cli/cli.dart';
import 'package:very_good_cli/src/mcp/runner/models/attempted_action.dart';
import 'package:very_good_cli/src/mcp/runner/models/test_payload.dart';
import 'package:very_good_cli/src/mcp/runner/models/tool_failure.dart';

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
/// * `test` — what the test run recorded, when any: `results` holds the test
///   counts, the run's duration and the first [maxPayloadItems] failing
///   tests. `coverage` holds the actual and required coverage and the
///   uncovered lines of the first [maxPayloadItems] files, at most
///   [maxPayloadItems] each, relative to the current directory.
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

  /// What the test run recorded, when any.
  final TestRunResults? testResults,

  /// The unmet coverage threshold of the test run, when the failure reason
  /// is [ToolFailureReason.coverageBelowThreshold].
  final MinCoverageNotMet? coverage,
}) {
  /// {@macro structured_tool_error}
  this;

  bool get _hasPartialResults =>
      capturedOutput != null && capturedOutput!.isNotEmpty;

  /// The JSON payload describing this failure.
  Map<String, Object?> toJson() => {
    'status': _hasPartialResults ? 'partial_failure' : 'failure',
    'failureType': failureType.name,
    'failureReason': failureReason.jsonName,
    'attemptedAction': attemptedActionPayload(
      toolName: toolName,
      commandString: commandString,
      directory: directory,
      arguments: attemptedArguments,
    ),
    'reason': reason,
    'test': ?TestPayload.maybeOf(testResults, coverage: coverage)?.toJson(),
    if (_hasPartialResults) 'partialResults': capturedOutput,
    'alternativeApproaches': failureReason.alternativeApproaches,
  };

  /// Renders this failure as a [CallToolResult].
  ///
  /// The single text content is the pretty-printed [toJson] payload, and the
  /// structured content is the payload itself.
  CallToolResult toCallToolResult() {
    final payload = toJson();
    final text = const JsonEncoder.withIndent('  ').convert(payload);

    return CallToolResult(
      content: [TextContent(text: text)],
      structuredContent: payload,
      isError: true,
    );
  }
}
