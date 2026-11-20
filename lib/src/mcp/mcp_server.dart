import 'package:dart_mcp/server.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:very_good_cli/src/mcp/tool_runner.dart';
import 'package:very_good_cli/src/mcp/tools/tools.dart';
import 'package:very_good_cli/src/version.dart';

/// {@template very_good_mcp_server}
/// MCP Server for Very Good CLI.
///
/// Exposes Very Good CLI commands through the Model Context Protocol, one
/// [VeryGoodTool] per command:
///
///  1. [CreateTool] — `very_good create`.
///  2. [TestTool] — `very_good test` and `very_good dart test`.
///  3. [PackagesGetTool] — `very_good packages get`.
///  4. [PackagesCheckLicensesTool] — `very_good packages check licenses`.
///
/// Every tool runs its command through the same [ToolRunner], which keeps
/// tool calls from overlapping.
/// {@endtemplate}
final class VeryGoodMCPServer({
  required StreamChannel<String> channel,

  /// Runs the commands of the tools. Defaults to a new [ToolRunner].
  ToolRunner? toolRunner,
}) extends MCPServer with ToolsSupport {
  /// {@macro very_good_mcp_server}
  this
    : super.fromStreamChannel(
        channel,
        implementation: Implementation(
          name: 'very_good_cli',
          version: packageVersion,
        ),
        instructions:
            'Tools from Very Good CLI for Dart and Flutter projects. '
            'Workflow: call ${CreateTool.name} to generate a project from a '
            'template, ${PackagesGetTool.name} to install dependencies after '
            'changing a pubspec.yaml, ${TestTool.name} to run tests with '
            'coverage, and ${PackagesCheckLicensesTool.name} to check '
            'dependency licenses. Tool calls run one at a time. A relative '
            '"directory" resolves against the directory the server was '
            'started in. A failed call returns a JSON payload: read its '
            '"failureType" and "failureReason" to decide whether a retry can '
            'help, and its "alternativeApproaches" for what to try next.',
      ) {
    final runner = toolRunner ?? ToolRunner();
    final tools = <VeryGoodTool>[
      CreateTool(runner),
      TestTool(runner),
      PackagesGetTool(runner),
      PackagesCheckLicensesTool(runner),
    ];
    for (final tool in tools) {
      // Each tool validates its own arguments, to report a mismatch with the
      // same structured payload as every other failure.
      registerTool(tool.definition, tool.call, validateArguments: false);
    }
  }
}
