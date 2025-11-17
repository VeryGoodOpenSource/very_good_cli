import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_mcp/stdio.dart';
import 'package:mason/mason.dart';
import 'package:very_good_cli/src/mcp/mcp_server.dart';

/// {@template mcp_command}
/// `very_good mcp` command starts the MCP (Model Context Protocol) server.
/// {@endtemplate}
class MCPCommand extends Command<int> {
  /// {@macro mcp_command}
  MCPCommand({Logger? logger}) : _logger = logger ?? Logger();

  /// The [name] of the command. But static.
  static const String commandName = 'mcp';

  @override
  String get description => 'Start the MCP (Model Context Protocol) server';

  @override
  String get name => commandName;

  final Logger _logger;

  @override
  Future<int> run() async {
    try {
      _logger
        ..info('Starting Very Good CLI MCP Server...')
        ..info(
          'Server will listen on stdin/stdout for MCP protocol messages',
        );

      // Create a channel from stdin/stdout using the stdio helper
      final channel = stdioChannel(
        input: stdin,
        output: stdout,
      );

      // Create and start the MCP server
      final server = VeryGoodMCPServer(
        channel: channel,
        logger: _logger,
      );

      _logger
        ..info('MCP Server started successfully')
        ..info('Available tools:')
        ..info('''
  - create: Create a very good Dart or Flutter project in seconds based on the provided template. Each template has a corresponding sub-command.''')
        ..info('  - test: Run tests in a Dart or Flutter project.')
        ..info(
          '  - packages_get: Install or update Dart/Flutter package dependencies. '
          'Use after creating a project or modifying pubspec.yaml. '
          'Supports recursive installation and package exclusion.',
        )
        ..info(
          '''
  - packages_check: Verify package licenses for compliance and validation in a Dart or Flutter project.
            Identifies license types (MIT, BSD, Apache, etc.) for all 
            dependencies. Use to ensure license compatibility.''',
        );

      // Wait for the server to complete
      // (this will block until the connection is closed)
      await server.done;

      return ExitCode.success.code;
    } on Exception catch (e, stackTrace) {
      _logger
        ..err('Failed to start MCP server: $e')
        ..err('Stack trace: $stackTrace');
      return ExitCode.software.code;
    }
  }
}
