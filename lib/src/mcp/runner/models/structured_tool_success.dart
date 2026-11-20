import 'package:dart_mcp/server.dart';
import 'package:very_good_cli/src/cli/cli.dart';
import 'package:very_good_cli/src/mcp/runner/models/attempted_action.dart';
import 'package:very_good_cli/src/mcp/runner/models/structured_tool_error.dart';
import 'package:very_good_cli/src/mcp/runner/models/test_payload.dart';

/// {@template structured_tool_success}
/// A structured description of a tool success, renderable as a
/// [CallToolResult].
///
/// The JSON payload mirrors [StructuredToolError]:
///
/// * `status` — always `success`.
/// * `attemptedAction` — the tool name, the CLI command that was invoked,
///   the working directory (when set), and the raw caller-supplied arguments.
/// * `test` — the counts and duration the test run recorded, when any.
/// * `output` — the sanitized captured command output, when any.
/// {@endtemplate}
class const StructuredToolSuccess({
  /// The name of the tool that succeeded.
  required final String toolName,

  /// The concrete CLI command that was invoked.
  required final String commandString,

  /// The working directory the command ran in, when set.
  final String? directory,

  /// The sanitized captured command output, when any.
  final String capturedOutput = '',

  /// The raw caller-supplied arguments.
  final Map<String, Object?>? attemptedArguments,

  /// What the test run recorded, when any.
  final TestRunResults? testResults,
}) {
  /// {@macro structured_tool_success}
  this;

  /// The JSON payload describing this success.
  Map<String, Object?> toJson() => {
    'status': 'success',
    'attemptedAction': attemptedActionPayload(
      toolName: toolName,
      commandString: commandString,
      directory: directory,
      arguments: attemptedArguments,
    ),
    'test': ?TestPayload.maybeOf(testResults)?.toJson(),
    if (capturedOutput.isNotEmpty) 'output': capturedOutput,
  };

  /// Renders this success as a [CallToolResult].
  ///
  /// The text content is a one-line summary followed by the captured output,
  /// when any. The structured content is the [toJson] payload.
  CallToolResult toCallToolResult() => CallToolResult(
    content: [
      TextContent(text: '"$toolName" completed successfully.'),
      if (capturedOutput.isNotEmpty) TextContent(text: capturedOutput),
    ],
    structuredContent: toJson(),
    isError: false,
  );
}
