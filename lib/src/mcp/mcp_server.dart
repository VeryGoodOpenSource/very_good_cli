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
        description: 'Create a new Dart/Flutter project',
        inputSchema: ObjectSchema(
          properties: {
            'template': StringSchema(
              description: 'Project template',
              enumValues: [
                'flutter_app',
                'dart_package',
                'flutter_package',
                'flutter_plugin',
                'dart_cli',
                'docs_site',
                'flame_game',
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
              description:
                  'Comma-separated platforms (flutter_plugin only). '
                  'Example: "android,ios,web"',
            ),
            'publishable': BooleanSchema(
              description: 'Whether package is intended for publishing',
            ),
          },
          required: ['template', 'name'],
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
        description: 'Get package dependencies',
        inputSchema: ObjectSchema(
          properties: {
            'directory': StringSchema(description: 'Project directory'),
            'recursive': BooleanSchema(
              description: 'Get packages recursively',
            ),
            'ignore': StringSchema(
              description: 'Comma-separated packages to ignore',
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
        description: 'Check packages for issues',
        inputSchema: ObjectSchema(
          properties: {
            'directory': StringSchema(description: 'Project directory'),
            'licenses': BooleanSchema(
              description:
                  'Check licenses (currently the only supported check, '
                  'defaults to true)',
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
      final template = args['template']! as String;
      final name = args['name']! as String;

      final cliArgs = <String>['create', template, name];

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
