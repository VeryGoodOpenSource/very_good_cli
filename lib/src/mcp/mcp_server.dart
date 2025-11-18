import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:dart_mcp/server.dart';
import 'package:mason/mason.dart' hide packageVersion;
// Note: stream_channel is a transitive dependency via dart_mcp
// ignore: depend_on_referenced_packages
import 'package:stream_channel/stream_channel.dart';
import 'package:very_good_cli/src/command_runner.dart';
import 'package:very_good_cli/src/version.dart';

/// {@template very_good_mcp_server}
/// MCP Server for Very Good CLI.
///
/// This server exposes Very Good CLI functionality through the
/// Model Context Protocol, allowing AI assistants to interact
/// with the CLI programmatically.
/// {@endtemplate}
final class VeryGoodMCPServer extends MCPServer with ToolsSupport {
  /// {@macro very_good_mcp_server}
  VeryGoodMCPServer({
    required StreamChannel<String> channel,
    Logger? logger,
    VeryGoodCommandRunner? commandRunner,
  }) : _logger = logger ?? Logger(),
       _commandRunner =
           commandRunner ?? VeryGoodCommandRunner(logger: logger ?? Logger()),
       super.fromStreamChannel(
         channel,
         implementation: Implementation(
           name: 'very_good_cli',
           version: packageVersion,
         ),
         instructions:
             'A Very Good CLI MCP server that provides tools '
             'for creating and managing Dart/Flutter projects.',
       );

  final Logger _logger;

  final VeryGoodCommandRunner _commandRunner;

  @override
  FutureOr<InitializeResult> initialize(InitializeRequest request) async {
    final result = await super.initialize(request);

    _registerTools();

    return result;
  }

  void _registerTools() {
    // Create project tool
    registerTool(
      Tool(
        name: 'create',
        description: '''
Create a very good Dart or Flutter project in seconds based on the provided template. Each template has a corresponding sub-command.
        ''',
        inputSchema: ObjectSchema(
          properties: {
            'subcommand': StringSchema(
              description: '''
The available subcommands to provide an specific template, are:
dart_cli - Generate a Very Good Dart CLI application.
dart_package - Generate a Very Good Dart package.
docs_site - Generate a Very Good documentation site.
flame_game - Generate a Very Good Flame game.
flutter_app - Generate a Very Good Flutter application.
flutter_package - Generate a Very Good Flutter package.
flutter_plugin - Generate a Very Good Flutter plugin.
''',
              enumValues: [
                'flame_game',
                'flutter_app',
                'flutter_package',
                'flutter_plugin',
                'dart_cli',
                'dart_package',
                'docs_site',
              ],
            ),
            'name': StringSchema(description: 'Project name'),
            'description': StringSchema(
              description: '''
The description for this new project.
(defaults to "A Very Good Project created by Very Good CLI.")''',
            ),
            'org_name': StringSchema(
              description: '''
The organization for this new project.
(defaults to "com.example.verygoodcore")''',
            ),
            'output_directory': StringSchema(
              description:
                  '''The desired output directory when creating a new project.''',
            ),
            'application_id': StringSchema(
              description:
                  '''The bundle identifier on iOS or application id on Android. (defaults to <org-name>.<project-name>)''',
            ),
            'platforms': StringSchema(
              description: '''
Comma-separated platforms. 'Example: "android,ios,web".
The values for platforms are: android, ios, web, macos, linux, and windows.
If is omitted, then all platforms are enabled by default.
Only available for subcommands: flutter_plugin with all values) and flame_game (only android and ios)
                  ''',
            ),
            'publishable': BooleanSchema(
              description: '''
Whether package is intended for publishing (flutter_package, dart_package  only)''',
            ),
            'executable-name': StringSchema(
              description: '''
CLI custom executable name (dart_cli  only)''',
            ),
            'template': StringSchema(
              description: '''
The template used to generate this new project.
The values are:
core - Generate a Very Good Flutter application.
wear - Generate a Very Good Flutter Wear OS application.
If is omitted, then core will be selected.
''',
            ),
          },
          required: ['subcommand', 'name'],
        ),
      ),
      _handleCreate,
    );

    // Test tool
    registerTool(
      Tool(
        name: 'test',
        description: 'Run tests in a Dart or Flutter project.',
        inputSchema: ObjectSchema(
          properties: {
            'dart': BooleanSchema(
              description:
                  '''Whether to run Dart tests. If not specified, Flutter tests will be run if a Flutter project is detected.''',
            ),
            'directory': StringSchema(description: 'Project directory'),
            'coverage': BooleanSchema(
              description: 'Whether to collect coverage information.',
            ),
            'recursive': BooleanSchema(
              description: 'Run tests recursively for all nested packages.',
            ),
            'optimization': BooleanSchema(
              description: '''
Whether to apply optimizations for test performance.
Automatically disabled when --platform is specified.
Add the `skip_very_good_optimization` tag to specific test files to disable them individually.
(defaults to on)''',
            ),
            'concurrency': StringSchema(
              description: '''
The number of concurrent test suites run. 
Automatically set to 1 when --platform is specified.
(defaults to "4")''',
            ),
            'tags': StringSchema(
              description:
                  '''Run only tests associated with the specified tags.''',
            ),
            'exclude_coverage': BooleanSchema(
              description:
                  '''A glob which will be used to exclude files that match from the coverage.''',
            ),
            'exclude_tags': StringSchema(
              description:
                  'Run only tests that do not have the specified tags.',
            ),
            'min_coverage': StringSchema(
              description:
                  '''Whether to enforce a minimum coverage percentage.''',
            ),
            'test_randomize_ordering_seed': StringSchema(
              description:
                  '''The seed to randomize the execution order of test cases within test files.''',
            ),
            'update_goldens': BooleanSchema(
              description: '''
Whether "matchesGoldenFile()" calls within your test methods should update the golden files.''',
            ),
            'force_ansi': BooleanSchema(
              description: '''
Whether to force ansi output. If not specified, it will maintain the default behavior based on stdout and stderr.''',
            ),
            'dart-define': StringSchema(
              description: '''
Additional key-value pairs that will be available as constants from the String.fromEnvironment, bool.fromEnvironment, int.fromEnvironment, and double.fromEnvironment constructors. 
Multiple defines can be passed by repeating "--dart-define" multiple times.
(e.g., foo=bar)
''',
            ),
            'dart-define-from-file': StringSchema(
              description: '''
The path of a .json or .env file containing key-value pairs that will be available as environment variables. These can be accessed using the String.fromEnvironment, bool.fromEnvironment, and int.fromEnvironment constructors. 
Multiple defines can be passed by repeating "--dart-define-from-file" multiple times. Entries from "--dart-define" with identical keys take precedence over entries from these files.''',
            ),
            'platform': StringSchema(
              description: '''
The platform to run tests on.
The available values are: chrome, vm, android, ios.
Only one value can be selected.
  ''',
            ),
          },
        ),
      ),
      _handleTest,
    );

    // Packages get tool
    registerTool(
      Tool(
        name: 'packages_get',
        description: '''
            Install or update a Dart/Flutter package dependencies.
            Use after creating a project or modifying pubspec.yaml.
            Supports recursive installation and package exclusion.''',
        inputSchema: ObjectSchema(
          properties: {
            'directory': StringSchema(
              description:
                  'Target directory path (defaults to current directory). '
                  'Can be absolute or relative path to project root.',
            ),
            'recursive': BooleanSchema(
              description:
                  'Install dependencies for all nested packages recursively. '
                  'Useful for monorepos or projects with multiple packages.',
            ),
            'ignore': StringSchema(
              description:
                  'Comma-separated list of package names to skip. '
                  'Example: "package1,package2". '
                  'Useful to avoid processing problematic packages.',
            ),
          },
        ),
      ),
      _handlePackagesGet,
    );

    // Packages check tool
    registerTool(
      Tool(
        name: 'packages_check',
        description: '''
            Verify package licenses for compliance and validation in a Dart or Flutter project.
            Identifies license types (MIT, BSD, Apache, etc.) for all 
            dependencies. Use to ensure license compatibility.''',
        inputSchema: ObjectSchema(
          properties: {
            'directory': StringSchema(
              description:
                  'Target directory path (defaults to current directory). '
                  'Path to the project root containing pubspec.yaml.',
            ),
            'licenses': BooleanSchema(
              description:
                  'Verify all package licenses (defaults to true). '
                  'Currently the only supported check type. '
                  'Reports license types for all dependencies.',
            ),
          },
        ),
      ),
      _handlePackagesCheck,
    );
  }

  Future<CallToolResult> _handleCreate(CallToolRequest request) async {
    final args = request.arguments ?? {};
    final subcommand = args['subcommand']! as String;
    final name = args['name']! as String;

    final cliArgs = <String>['create', subcommand, name];

    if (args['description'] != null) {
      cliArgs.addAll(['--desc', args['description']! as String]);
    }
    if (args['org_name'] != null) {
      cliArgs.addAll(['--org-name', args['org_name']! as String]);
    }
    if (args['output_directory'] != null) {
      cliArgs.addAll([
        '-o',
        args['output_directory']! as String,
      ]);
    }
    if (args['application_id'] != null) {
      cliArgs.addAll(['--application-id', args['application_id']! as String]);
    }
    if (args['platforms'] != null) {
      cliArgs.addAll(['--platforms', args['platforms']! as String]);
    }
    if (args['publishable'] == true) {
      cliArgs.add('--publishable');
    }
    if (args['template'] != null) {
      cliArgs.addAll(['-t', args['template']! as String]);
    }

    final exitCode = await _runCommand(cliArgs);

    return CallToolResult(
      content: [
        TextContent(
          text: exitCode == ExitCode.success.code
              ? 'Project created successfully'
              : 'Failed to create project',
        ),
      ],
      isError: exitCode != ExitCode.success.code,
    );
  }

  Future<CallToolResult> _handleTest(CallToolRequest request) async {
    final args = request.arguments ?? {};

    final cliArgs = <String>[
      if (args['dart'] == true) 'dart',
      'test',
    ];

    if (args['directory'] != null) {
      cliArgs.add(args['directory']! as String);
    }
    if (args['coverage'] == true) {
      cliArgs.add('--coverage');
    }
    if (args['recursive'] == true) {
      cliArgs.add('-r');
    }
    if (args['optimization'] == true) {
      cliArgs.add('--optimization');
    } else {
      cliArgs.add('--no-optimization');
    }
    if (args['concurrency'] != null) {
      cliArgs.addAll(['-j', args['concurrency']! as String]);
    }
    if (args['tags'] != null) {
      cliArgs.addAll(['-t', args['tags']! as String]);
    }
    if (args['exclude_coverage'] == false) {
      cliArgs.add('--exclude-coverage');
    }
    if (args['exclude_tags'] != null) {
      cliArgs.addAll(['-x', args['exclude_tags']! as String]);
    }
    if (args['min_coverage'] != null) {
      cliArgs.addAll(['--min-coverage', args['min_coverage']! as String]);
    }
    if (args['test_randomize_ordering_seed'] != null) {
      cliArgs.addAll([
        '--test-randomize-ordering-seed',
        args['test_randomize_ordering_seed']! as String,
      ]);
    }
    if (args['update_goldens'] == true) {
      cliArgs.add('--update-goldens');
    }
    if (args['force_ansi'] == true) {
      cliArgs.add('--force-ansi');
    }
    if (args['dart-define'] != null) {
      cliArgs.addAll(['--dart-define', args['dart-define']! as String]);
    }
    if (args['dart-define-from-file'] != null) {
      cliArgs.addAll([
        '--dart-define-from-file',
        args['dart-define-from-file']! as String,
      ]);
    }
    if (args['platform'] != null) {
      cliArgs.addAll(['--platform', args['platform']! as String]);
    }

    final exitCode = await _runCommand(cliArgs);

    return CallToolResult(
      content: [
        TextContent(
          text: exitCode == ExitCode.success.code
              ? 'Tests completed successfully'
              : 'Tests failed',
        ),
      ],
      isError: exitCode != ExitCode.success.code,
    );
  }

  Future<CallToolResult> _handlePackagesGet(CallToolRequest request) async {
    final args = request.arguments ?? {};

    final cliArgs = <String>['packages', 'get'];

    if (args['directory'] != null) {
      cliArgs.add(args['directory']! as String);
    }
    if (args['recursive'] == true) {
      cliArgs.add('--recursive');
    }
    if (args['ignore'] != null) {
      final ignore = (args['ignore']! as String).split(',');
      for (final pkg in ignore) {
        cliArgs.addAll(['--ignore', pkg.trim()]);
      }
    }

    final exitCode = await _runCommand(cliArgs);

    return CallToolResult(
      content: [
        TextContent(
          text: exitCode == ExitCode.success.code
              ? 'Packages retrieved successfully'
              : 'Failed to get packages',
        ),
      ],
      isError: exitCode != ExitCode.success.code,
    );
  }

  Future<CallToolResult> _handlePackagesCheck(CallToolRequest request) async {
    final args = request.arguments ?? {};

    // Currently, 'packages check' only has 'licenses' as a subcommand
    // Default to checking licenses if not explicitly set to false
    final checkLicenses = args['licenses'] as bool? ?? true;

    if (!checkLicenses) {
      return CallToolResult(
        content: [
          TextContent(
            text:
                'No check specified. Currently only "licenses" check is '
                'supported. Set licenses=true to run license checks.',
          ),
        ],
        isError: true,
      );
    }

    final cliArgs = <String>['packages', 'check', 'licenses'];

    if (args['directory'] != null) {
      cliArgs.add(args['directory']! as String);
    }

    final exitCode = await _runCommand(cliArgs);

    return CallToolResult(
      content: [
        TextContent(
          text: exitCode == ExitCode.success.code
              ? 'Package license check completed successfully'
              : 'Package license check failed',
        ),
      ],
      isError: exitCode != ExitCode.success.code,
    );
  }

  /// Runs CLI commands through the command runner.
  /// Commands parse their own arguments using their argParser.
  Future<int> _runCommand(List<String> args) async {
    try {
      _logger.detail('Running: very_good ${args.join(' ')}');

      final exitCode = await _commandRunner.run(args);

      return exitCode;
    } on UsageException catch (e) {
      _logger.err('Usage error: ${e.message}');
      return ExitCode.usage.code;
    } on Exception catch (e, stackTrace) {
      _logger
        ..err('Command error: $e')
        ..err('Stack trace: $stackTrace');
      return ExitCode.software.code;
    }
  }
}
