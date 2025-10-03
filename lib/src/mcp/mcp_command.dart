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
        ..info('  - create: Create new projects')
        ..info('  - test: Run tests')
        ..info('  - packages_get: Get package dependencies')
        ..info('  - packages_check: Check packages for issues');

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
