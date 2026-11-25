import 'package:dart_mcp/server.dart';
import 'package:very_good_cli/src/mcp/runner/runner.dart';
import 'package:very_good_cli/src/mcp/tools/cli_arguments.dart';
import 'package:very_good_cli/src/mcp/tools/very_good_tool.dart';

/// {@template create_tool}
/// `create`: generates a project from a Very Good template, by running
/// `very_good create <subcommand> <name>`.
/// {@endtemplate}
class CreateTool(super.runner) extends VeryGoodTool {
  /// {@macro create_tool}
  this;

  /// The tool's name.
  static const name = 'create';

  /// The `create` subcommands that define the `--workspace` flag.
  ///
  /// `docs_site` is intentionally excluded because it does not mix in the
  /// `Workspace` mixin and therefore rejects the flag.
  static const _workspaceSubcommands = {
    'app_ui_package',
    'flame_game',
    'flutter_app',
    'flutter_package',
    'flutter_plugin',
    'dart_cli',
    'dart_package',
  };

  @override
  Tool get definition => Tool(
    name: name,
    description:
        'Create a new Dart or Flutter project from a Very Good template. '
        'Generates the project in "<output_directory>/<name>" and, for '
        'every template but docs_site, installs its dependencies. Fails '
        'instead of overwriting a file that already exists there with '
        'different content. Some arguments only apply to some '
        'templates; passing one to a template that does not accept it '
        'fails with a usage error.',
    annotations: ToolAnnotations(
      title: 'Create a Very Good project',
      readOnlyHint: false,
      destructiveHint: false,
      idempotentHint: false,
      openWorldHint: true,
    ),
    inputSchema: ObjectSchema(
      properties: {
        'subcommand': UntitledSingleSelectEnumSchema(
          description:
              'The template to generate: flutter_app (Flutter '
              'application), flutter_package, flutter_plugin (federated '
              'plugin), flame_game, app_ui_package (Flutter UI package), '
              'dart_package, dart_cli (Dart command-line application) or '
              'docs_site (Docusaurus documentation site).',
          values: [
            'app_ui_package',
            'flame_game',
            'flutter_app',
            'flutter_package',
            'flutter_plugin',
            'dart_cli',
            'dart_package',
            'docs_site',
          ],
        ),
        'name': StringSchema(
          description:
              'The project name, a valid Dart package name in snake_case '
              '(e.g. "my_app").',
        ),
        'description': StringSchema(
          description:
              'The project description. Defaults to "A Very Good Project '
              'created by Very Good CLI.".',
        ),
        'org_name': StringSchema(
          description:
              'The organization (e.g. "com.example.app"). Only for '
              'flutter_app, flutter_plugin and flame_game, where it '
              'defaults to "com.example.verygoodcore", and docs_site, '
              'where it defaults to "my-org".',
        ),
        'output_directory': StringSchema(
          description:
              'The directory to create the project folder in. Absolute, '
              'or relative to the directory the server was started in, '
              'which is the default.',
        ),
        'application_id': StringSchema(
          description:
              'The bundle identifier on iOS or application id on Android '
              '(e.g. "com.example.my_app"). Only for flutter_app. '
              'Defaults to "<org_name>.<name>".',
        ),
        'platforms': ListSchema(
          description:
              'The platforms to support (e.g. ["android", "ios"]). Only '
              'for flutter_app, flame_game and flutter_plugin. "linux" '
              'is only accepted by flutter_plugin. Defaults to every '
              'platform the template supports.',
          items: UntitledSingleSelectEnumSchema(
            values: ['android', 'ios', 'web', 'macos', 'linux', 'windows'],
          ),
          uniqueItems: true,
        ),
        'publishable': BooleanSchema(
          description:
              'Whether the project is intended to be published. Defaults '
              'to false.',
        ),
        'workspace': BooleanSchema(
          description:
              'Whether to add the project to the closest parent Pub '
              'workspace and resolve its dependencies from it. Ignored for '
              'docs_site.',
        ),
        'executable_name': StringSchema(
          description:
              'The CLI executable name. Only for dart_cli. Defaults to '
              'the project name.',
        ),
      },
      required: ['subcommand', 'name'],
      additionalProperties: false,
    ),
    outputSchema: toolOutputSchema,
  );

  @override
  Future<CallToolResult> run(Map<String, Object?> arguments) {
    final subcommand = arguments['subcommand']! as String;
    final projectName = arguments['name']! as String;

    return runner.run(
      [
        'create',
        subcommand,
        projectName,
        ...arguments.option('description', '--desc'),
        ...arguments.option('org_name', '--org-name'),
        ...arguments.option('output_directory', '-o'),
        ...arguments.option('application_id', '--application-id'),
        ...arguments.multiOption('platforms', '--platforms'),
        ...arguments.flag('publishable', '--publishable'),
        if (_workspaceSubcommands.contains(subcommand))
          ...arguments.negatableFlag('workspace', 'workspace'),
        ...arguments.option('executable_name', '--executable-name'),
      ],
      toolName: name,
      requestArguments: arguments,
    );
  }
}
