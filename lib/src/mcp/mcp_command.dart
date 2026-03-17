import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_mcp/server.dart';
import 'package:dart_mcp/stdio.dart';
import 'package:mason/mason.dart' show ExitCode;
import 'package:stream_channel/stream_channel.dart';
import 'package:very_good_cli/src/mcp/mcp_server.dart';

/// Type definition for a factory that creates a [VeryGoodMCPServer].
typedef ServerFactory =
    MCPServer Function({
      required StreamChannel<String> channel,
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
    ChannelFactory? channelFactory,
    ServerFactory? serverFactory,
  }) : _channelFactory = channelFactory ?? _defaultChannelFactory,
       _serverFactory = serverFactory ?? VeryGoodMCPServer.new;

  /// The [name] of the command. But static.
  static const String commandName = 'mcp';

  @override
  String get description => '''
Start the MCP (Model Context Protocol) server. WARNING: This is an experimental package and may change or become unstable without notice. Use it with caution at your own risk.''';

  @override
  String get name => commandName;

  final ChannelFactory _channelFactory;

  final ServerFactory _serverFactory;

  @override
  Future<int> run() async {
    try {
      final channel = _channelFactory();
      final server = _serverFactory(channel: channel);
      await server.done;

      return ExitCode.success.code;
    } on Exception catch (e, stackTrace) {
      stderr
        ..writeln('[very_good_mcp] Failed to start MCP server: $e')
        ..writeln('[very_good_mcp] Stack trace: $stackTrace');
      return ExitCode.software.code;
    }
  }
}
