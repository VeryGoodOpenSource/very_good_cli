import 'dart:async';
import 'dart:convert';

import 'package:dart_mcp/server.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/mcp/mcp_server.dart';

import '../../helpers/helpers.dart';

void main() {
  group(VeryGoodMCPServer, () {
    late MockToolRunner runner;
    late StreamChannelController<String> channelController;
    late Stream<Map<String, Object?>> responses;
    var nextId = 0;

    /// Sends a JSON-RPC request to the server and returns its response.
    Future<Map<String, Object?>> send(
      String method, [
      Map<String, Object?> params = const {},
    ]) {
      final id = ++nextId;
      final response = responses.firstWhere((response) => response['id'] == id);
      channelController.local.sink.add(
        jsonEncode({
          'jsonrpc': '2.0',
          'method': method,
          'params': params,
          'id': id,
        }),
      );
      return response;
    }

    Future<InitializeResult> initialize() async {
      final response = await send(
        InitializeRequest.methodName,
        InitializeRequest(
          protocolVersion: ProtocolVersion.latestSupported,
          capabilities: ClientCapabilities(),
          clientInfo: Implementation(name: 'test_client', version: '0.1.0'),
        ) as Map<String, Object?>,
      );
      expect(response['error'], isNull, reason: 'initialization failed');
      return InitializeResult.fromMap(
        response['result']! as Map<String, Object?>,
      );
    }

    Future<List<Tool>> listTools() async {
      final response = await send(ListToolsRequest.methodName);
      return ListToolsResult.fromMap(
        response['result']! as Map<String, Object?>,
      ).tools;
    }

    Future<CallToolResult> callTool(
      String name,
      Map<String, Object?> arguments,
    ) async {
      final response = await send(
        CallToolRequest.methodName,
        CallToolRequest(name: name, arguments: arguments)
            as Map<String, Object?>,
      );
      expect(response['error'], isNull);
      return CallToolResult.fromMap(
        response['result']! as Map<String, Object?>,
      );
    }

    setUp(() {
      runner = MockToolRunner();
      stubRun(runner);
      channelController = StreamChannelController<String>();
      responses = channelController.local.stream
          .map((event) => jsonDecode(event) as Map<String, Object?>)
          .asBroadcastStream();
      VeryGoodMCPServer(channel: channelController.foreign, toolRunner: runner);
    });

    test('can be instantiated without a tool runner', () {
      expect(
        VeryGoodMCPServer(channel: StreamChannelController<String>().foreign),
        isA<VeryGoodMCPServer>(),
      );
    });

    test('introduces itself with the workflow of its tools', () async {
      final result = await initialize();

      expect(result.serverInfo.name, equals('very_good_cli'));
      expect(
        result.instructions,
        allOf(
          contains('create'),
          contains('test'),
          contains('packages_get'),
          contains('packages_check_licenses'),
          contains('failureType'),
        ),
      );
    });

    test('lists its four tools', () async {
      await initialize();

      final tools = await listTools();

      expect(
        tools.map((tool) => tool.name),
        equals(['create', 'test', 'packages_get', 'packages_check_licenses']),
      );
    });

    test('describes every tool with a title, hints and schemas', () async {
      await initialize();

      for (final tool in await listTools()) {
        final annotations = tool.toolAnnotations;
        expect(tool.description, isNotEmpty, reason: tool.name);
        expect(annotations?.title, isNotEmpty, reason: tool.name);
        expect(annotations?.readOnlyHint, isNotNull, reason: tool.name);
        expect(annotations?.idempotentHint, isNotNull, reason: tool.name);
        expect(annotations?.openWorldHint, isNotNull, reason: tool.name);
        expect(
          tool.inputSchema.additionalProperties,
          isFalse,
          reason: tool.name,
        );
        expect(
          tool.outputSchema?.required,
          equals(['status', 'attemptedAction']),
          reason: tool.name,
        );
      }
    });

    test('routes a call to its tool', () async {
      await initialize();

      final result = await callTool('packages_get', {'recursive': true});

      expect(result, equals(stubbedRunResult));
      final run = verifyRun(runner);
      expect(run.args, equals(['packages', 'get', '--recursive']));
      expect(run.toolName, equals('packages_get'));
    });

    test(
      'leaves argument validation to the tool, for a structured failure',
      () async {
        await initialize();

        final result = await callTool('create', {'subcommand': 'flutter_app'});

        expect(result.isError, isTrue);
        final payload = result.structuredContent!;
        expect(payload['failureReason'], equals('invalid_input'));
        expect(
          jsonDecode((result.content.single as TextContent).text),
          equals(payload),
        );
        verifyNoRun(runner);
      },
    );
  });
}
