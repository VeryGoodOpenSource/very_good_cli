import 'package:dart_mcp/server.dart';
import 'package:very_good_cli/src/mcp/structured_tool_error.dart';
import 'package:very_good_cli/src/mcp/tools/cli_arguments.dart';
import 'package:very_good_cli/src/mcp/tools/very_good_tool.dart';

/// {@template packages_get_tool}
/// `packages_get`: installs the dependencies of a package, by running
/// `very_good packages get`.
/// {@endtemplate}
class PackagesGetTool(super.runner) extends VeryGoodTool {
  /// {@macro packages_get_tool}
  this;

  /// The tool's name.
  static const name = 'packages_get';

  @override
  Tool get definition => Tool(
    name: name,
    description:
        'Install the dependencies of a Dart or Flutter package with "pub '
        'get". Use after creating a project or changing a pubspec.yaml.',
    annotations: ToolAnnotations(
      title: 'Get packages',
      readOnlyHint: false,
      destructiveHint: false,
      idempotentHint: true,
      openWorldHint: true,
    ),
    inputSchema: ObjectSchema(
      properties: {
        'directory': StringSchema(
          description:
              'The package to install dependencies for. Absolute, or '
              'relative to the directory the server was started in, '
              'which is the default.',
        ),
        'recursive': BooleanSchema(
          description:
              'Whether to install the dependencies of every package '
              'nested under "directory", as in a monorepo. Defaults to '
              'false.',
        ),
        'ignore': ListSchema(
          description:
              'Names of the packages to skip in a recursive run (e.g. '
              '["package_a", "package_b"]).',
          items: StringSchema(),
        ),
      },
      additionalProperties: false,
    ),
    outputSchema: toolOutputSchema,
  );

  @override
  Future<CallToolResult> run(Map<String, Object?> arguments) => runner.run(
    [
      'packages',
      'get',
      ...arguments.flag('recursive', '--recursive'),
      ...arguments.multiOption('ignore', '--ignore'),
    ],
    toolName: name,
    directory: arguments['directory'] as String?,
    requestArguments: arguments,
  );
}
