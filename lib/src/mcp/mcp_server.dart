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
  }) : _logger = logger ?? Logger(),
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
Create a very good project in seconds based on the provided template. Each template has a corresponding subcommand. 
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
            'description': StringSchema(description: 'Project description'),
            'org_name': StringSchema(
              description: 'Organization name (e.g., com.example)',
            ),
            'output_directory': StringSchema(
              description: 'Output directory path',
            ),
            'application_id': StringSchema(
              description: 'Application/bundle ID (flutter_app only)',
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
Create a new Wear OS app (flutter_app only). 
The value must be: wear''',
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
        description: 'Run tests for a Dart/Flutter project',
        inputSchema: ObjectSchema(
          properties: {
            'directory': StringSchema(description: 'Project directory'),
            'coverage': BooleanSchema(description: 'Collect coverage'),
            'recursive': BooleanSchema(description: 'Run recursively'),
            'optimization': BooleanSchema(description: 'Optimize performance'),
            'concurrency': StringSchema(description: 'Concurrent test suites'),
            'tags': StringSchema(description: 'Run tests with these tags'),
            'exclude_tags': StringSchema(
              description: 'Exclude tests with these tags',
            ),
            'min_coverage': StringSchema(description: 'Minimum coverage %'),
            'update_goldens': BooleanSchema(description: 'Update golden files'),
            'platform': StringSchema(description: 'Platform (chrome, vm, etc)'),
          },
        ),
      ),
      _handleTest,
    );

    // Packages get tool
    registerTool(
      Tool(
        name: 'packages_get',
        description:
            'Install or update Dart/Flutter package dependencies. '
            'Use after creating a project or modifying pubspec.yaml. '
            'Supports recursive installation and package exclusion.',
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
        description:
            'Verify package licenses for compliance and validation. '
            'Identifies license types (MIT, BSD, Apache, etc.) for all '
            'dependencies. Use to ensure license compatibility.',
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
    try {
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
          '--output-directory',
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
        cliArgs.addAll(['--template', args['template']! as String]);
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
    } on Exception catch (e, stackTrace) {
      return CallToolResult(
        content: [
          TextContent(text: 'Error: $e'),
          TextContent(text: 'Stack trace: $stackTrace'),
        ],
        isError: true,
      );
    }
  }

  Future<CallToolResult> _handleTest(CallToolRequest request) async {
    try {
      final args = request.arguments ?? {};

      final cliArgs = <String>['test'];

      if (args['directory'] != null) {
        cliArgs.add(args['directory']! as String);
      }
      if (args['coverage'] == true) {
        cliArgs.add('--coverage');
      }
      if (args['recursive'] == true) {
        cliArgs.add('--recursive');
      }
      if (args['optimization'] == false) {
        cliArgs.add('--no-optimization');
      }
      if (args['concurrency'] != null) {
        cliArgs.addAll(['-j', args['concurrency']! as String]);
      }
      if (args['tags'] != null) {
        cliArgs.addAll(['-t', args['tags']! as String]);
      }
      if (args['exclude_tags'] != null) {
        cliArgs.addAll(['-x', args['exclude_tags']! as String]);
      }
      if (args['min_coverage'] != null) {
        cliArgs.addAll(['--min-coverage', args['min_coverage']! as String]);
      }
      if (args['update_goldens'] == true) {
        cliArgs.add('--update-goldens');
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
    } on Exception catch (e, stackTrace) {
      return CallToolResult(
        content: [
          TextContent(text: 'Error: $e'),
          TextContent(text: 'Stack trace: $stackTrace'),
        ],
        isError: true,
      );
    }
  }

  Future<CallToolResult> _handlePackagesGet(CallToolRequest request) async {
    try {
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
    } on Exception catch (e, stackTrace) {
      return CallToolResult(
        content: [
          TextContent(text: 'Error: $e'),
          TextContent(text: 'Stack trace: $stackTrace'),
        ],
        isError: true,
      );
    }
  }

  Future<CallToolResult> _handlePackagesCheck(CallToolRequest request) async {
    try {
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
    } on Exception catch (e, stackTrace) {
      return CallToolResult(
        content: [
          TextContent(text: 'Error: $e'),
          TextContent(text: 'Stack trace: $stackTrace'),
        ],
        isError: true,
      );
    }
  }

  /// Runs CLI commands through the command runner.
  /// Commands parse their own arguments using their argParser.
  Future<int> _runCommand(List<String> args) async {
    try {
      _logger.detail('Running: very_good ${args.join(' ')}');

      final runner = VeryGoodCommandRunner(logger: _logger);

      final exitCode = await runner.run(args);

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
