import 'package:dart_mcp/server.dart';
import 'package:meta/meta.dart';
import 'package:very_good_cli/src/mcp/structured_tool_error.dart';
import 'package:very_good_cli/src/mcp/tool_runner.dart';

/// {@template very_good_tool}
/// One MCP tool served by the Very Good CLI server: its [definition] (name,
/// description, annotations and schemas) and the [call] that handles it.
///
/// One subclass per tool, each wrapping one Very Good CLI command.
/// {@endtemplate}
abstract class VeryGoodTool(
  /// Runs the Very Good CLI command the tool wraps.
  final ToolRunner runner,
) {
  /// {@macro very_good_tool}
  this;

  /// The tool as advertised to clients in `tools/list`.
  Tool get definition;

  /// Handles a `tools/call` for this tool.
  ///
  /// Arguments that do not match the [definition]'s input schema are reported
  /// as a [StructuredToolError], like every other failure, and never reach
  /// [run].
  Future<CallToolResult> call(CallToolRequest request) async {
    final arguments = request.arguments ?? const <String, Object?>{};
    final errors = definition.inputSchema.validate(arguments);
    if (errors.isEmpty) return await run(arguments);

    final details = errors.map((error) => error.toErrorString()).join('; ');
    return invalidInput('Invalid arguments: $details.', arguments);
  }

  /// Runs the tool with [arguments] that match the [definition]'s input
  /// schema.
  @protected
  Future<CallToolResult> run(Map<String, Object?> arguments);

  /// A tool error telling the client its [arguments] were rejected because of
  /// [reason], before any command ran.
  @protected
  CallToolResult invalidInput(String reason, Map<String, Object?> arguments) =>
      StructuredToolError(
        toolName: definition.name,
        reason: reason,
        failureType: ToolFailureType.validation,
        failureReason: ToolFailureReason.invalidInput,
        attemptedArguments: arguments,
      ).toCallToolResult();
}
