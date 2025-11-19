import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_mcp/server.dart';
import 'package:dart_mcp/stdio.dart';
import 'package:mason/mason.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:very_good_cli/src/mcp/mcp_server.dart';

/// Type definition for a factory that creates a [VeryGoodMCPServer].
typedef ServerFactory =
    MCPServer Function({
      required StreamChannel<String> channel,
      required Logger logger,
    });

/// Factory function to create a [StreamChannel] from input and output streams.
typedef ChannelFactory = StreamChannel<String> Function();

// Private default implementation for the channel factory
StreamChannel<String> _defaultChannelFactory() {
  return stdioChannel(input: stdin, output: stdout);
}

/// {@template mcp_command}
/// `very_good mcp` command starts the MCP (Model Context Protocol) server.
/// {@endtemplate}
class MCPCommand extends Command<int> {
  /// {@macro mcp_command}
  MCPCommand({
    Logger? logger,
    ChannelFactory? channelFactory,
    ServerFactory? serverFactory,
  }) : _logger = logger ?? Logger(),
       _channelFactory = channelFactory ?? _defaultChannelFactory,
       _serverFactory = serverFactory ?? VeryGoodMCPServer.new;

  /// The [name] of the command. But static.
  static const String commandName = 'mcp';

  @override
  String get description => '''
Start the MCP (Model Context Protocol) server. WARNING: This is an experimental package and may change or become unstable without notice. Use it with caution at your own risk.''';

  @override
  String get name => commandName;

  final Logger _logger;

  final ChannelFactory _channelFactory;

  final ServerFactory _serverFactory;

  @override
  Future<int> run() async {
    try {
      _logger
        ..info('Starting Very Good CLI MCP Server...')
        ..info(
          'Server will listen on stdin/stdout for MCP protocol messages',
        );

      // Create a channel from stdin/stdout using the stdio helper
      final channel = _channelFactory();

      // Create and start the MCP server
      final server = _serverFactory(
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
          '''
           - packages_get: Install or update Dart/Flutter package dependencies.
          Use after creating a project or modifying pubspec.yaml.
          Supports recursive installation and package exclusion.''',
        )
        ..info(
          '''
  - packages_check_licenses: Verify package licenses for compliance and validation in a Dart or Flutter project.
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
