import 'dart:async';
import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:dart_mcp/server.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
// Note: stream_channel is a transitive dependency via dart_mcp
// ignore: depend_on_referenced_packages
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';
import 'package:very_good_cli/src/command_runner.dart';
import 'package:very_good_cli/src/mcp/mcp_server.dart';

class _MockLogger extends Mock implements Logger {}

class _MockVeryGoodCommandRunner extends Mock
    implements VeryGoodCommandRunner {}

int _idCounter = 1;

// Helper function to create a JSON-RPC request string
String _jsonRpcRequest(String method, Map<String, dynamic> params) {
  final id = _idCounter++;
  return jsonEncode({
    'jsonrpc': '2.0',
    'method': method,
    'params': params,
    'id': id,
  });
}

// FIX: Helper function for params, as extension type is Map
// This helper casts the dynamic (which is really an extension type)
// to the expected Map type.
Map<String, Object?> _params(dynamic params) => params as Map<String, Object?>;

void main() {
  group('VeryGoodMCPServer', () {
    late Logger mockLogger;
    late VeryGoodCommandRunner mockCommandRunner;
    late StreamChannelController<String> channelController;
    late VeryGoodMCPServer server;
    late Stream<Map<String, dynamic>> serverResponses;

    // Reset the ID counter for each test run
    setUpAll(() {
      _idCounter = 1;
    });

    // Helper to send a request and get the first matching response
    Future<Map<String, dynamic>> sendRequest(
      String method, [
      Map<String, Object?> params = const {},
    ]) async {
      final completer = Completer<Map<String, dynamic>>();
      // Get the ID that will be used for this request
      final requestId = _idCounter;

      final subscription = serverResponses.listen((response) {
        if (response['id'] == requestId) {
          completer.complete(response);
        }
      });

      // Send the request (which increments the counter)
      channelController.local.sink.add(
        _jsonRpcRequest(method, params as Map<String, dynamic>),
      );

      final response = await completer.future;
      await subscription.cancel();
      return response;
    }

    setUp(() async {
      mockLogger = _MockLogger();
      mockCommandRunner = _MockVeryGoodCommandRunner();
      channelController = StreamChannelController<String>();
      server = VeryGoodMCPServer(
        channel: channelController.foreign,
        logger: mockLogger,
        commandRunner: mockCommandRunner,
      );

      // Listen to the server's responses and decode them
      // FIX: Added .asBroadcastStream() to allow multiple listeners
      serverResponses = channelController.local.stream
          .map((event) => jsonDecode(event) as Map<String, dynamic>)
          .asBroadcastStream();

      registerFallbackValue(
        InitializeRequest(
          protocolVersion: ProtocolVersion.latestSupported,
          capabilities: ClientCapabilities(),
          clientInfo: Implementation(name: 'test', version: '1.0.0'),
        ),
      );
      registerFallbackValue(
        CallToolRequest(
          name: 'dummyTool',
          arguments: const {},
        ),
      );

      // Default stubs
      when(
        () => mockCommandRunner.run(any()),
      ).thenAnswer((_) async => ExitCode.success.code);
      when(() => mockLogger.info(any())).thenAnswer((_) {});
      when(() => mockLogger.err(any())).thenAnswer((_) {});
      when(() => mockLogger.detail(any())).thenAnswer((_) {});

      // This is the handshake that
      // MUST happen before any other requests, to fix the timeout.
      final initResponse = await sendRequest(
        InitializeRequest.methodName,
        // FIX: Use the helper to cast the extension type
        _params(
          InitializeRequest(
            protocolVersion: ProtocolVersion.latestSupported,
            capabilities: ClientCapabilities(),
            clientInfo: Implementation(name: 'test_client', version: '0.1.0'),
          ),
        ),
      );

      // Ensure initialization was successful
      expect(
        initResponse['error'],
        isNull,
        reason: 'Server initialization failed',
      );
    });

    test('constructor uses default logger and runner if not provided', () {
      final defaultFactoryChannelController = StreamChannelController<String>();

      final defaultServer = VeryGoodMCPServer(
        channel: defaultFactoryChannelController.foreign,
      );
      expect(defaultServer, isA<VeryGoodMCPServer>());
    });

    test('initialize (via tools/list) registers all 4 tools', () async {
      // The server is ALREADY initialized in setUp.
      // We can just send a 'tools/list' request directly.
      final response = await sendRequest(ListToolsRequest.methodName);

      // Check for a successful response
      expect(response['error'], isNull);
      expect(response['result'], isA<Map<String, dynamic>>());

      final result = ListToolsResult.fromMap(
        response['result'] as Map<String, Object?>,
      );
      expect(result.tools.length, 4);
      expect(
        result.tools.map((t) => t.name),
        containsAll([
          'create',
          'test',
          'packages_get',
          'packages_check',
        ]),
      );
    });

    group('Tool: create', () {
      test('handles basic case', () async {
        final response = await sendRequest(
          CallToolRequest.methodName,
          _params(
            CallToolRequest(
              name: 'create',
              arguments: {'subcommand': 'flutter_app', 'name': 'my_app'},
            ),
          ),
        );

        expect(response['error'], isNull);
        final result = CallToolResult.fromMap(
          response['result'] as Map<String, Object?>,
        );
        expect(result.isError, isFalse);
        expect(
          (result.content.first as TextContent).text,
          'Project created successfully',
        );

        final capturedArgs =
            verify(() => mockCommandRunner.run(captureAny())).captured.first
                as List<String>;
        expect(capturedArgs, ['create', 'flutter_app', 'my_app']);
      });

      test('handles all arguments', () async {
        await sendRequest(
          CallToolRequest.methodName,
          _params(
            CallToolRequest(
              name: 'create',
              arguments: {
                'subcommand': 'flutter_app',
                'name': 'my_app',
                'description': 'my_desc',
                'org_name': 'com.test',
                'output_directory': 'my_dir',
                'application_id': 'com.test.my_app',
                'platforms': 'ios,web',
                'publishable': true,
                'template': 'wear',
              },
            ),
          ),
        );

        final capturedArgs =
            verify(() => mockCommandRunner.run(captureAny())).captured.first
                as List<String>;
        expect(capturedArgs, [
          'create',
          'flutter_app',
          'my_app',
          '--desc',
          'my_desc',
          '--org-name',
          'com.test',
          '-o',
          'my_dir',
          '--application-id',
          'com.test.my_app',
          '--platforms',
          'ios,web',
          '--publishable',
          '-t',
          'wear',
        ]);
      });

      test('handles command runner failure', () async {
        when(
          () => mockCommandRunner.run(any()),
        ).thenAnswer((_) async => ExitCode.software.code);

        final response = await sendRequest(
          CallToolRequest.methodName,
          _params(
            CallToolRequest(
              name: 'create',
              arguments: {'subcommand': 'flutter_app', 'name': 'my_app'},
            ),
          ),
        );

        expect(response['error'], isNull);
        final result = CallToolResult.fromMap(
          response['result'] as Map<String, Object?>,
        );
        expect(result.isError, isTrue);
        expect(
          (result.content.first as TextContent).text,
          'Failed to create project',
        );
      });

      test('handles argument parsing exception', () async {
        // Missing 'name' argument
        final response = await sendRequest(
          CallToolRequest.methodName,
          _params(
            CallToolRequest(
              name: 'create',
              arguments: {'subcommand': 'flutter_app'},
            ),
          ),
        );

        // The handler's try/catch will catch this
        expect(response['error'], isNull);
        final result = CallToolResult.fromMap(
          response['result'] as Map<String, Object?>,
        );
        expect(result.isError, isTrue);
        expect(
          (result.content.first as TextContent).text,
          contains('Error:'),
        );
      });
    });

    group('Tool: test', () {
      test('handles basic case with --no-optimization', () async {
        await sendRequest(
          CallToolRequest.methodName,
          _params(CallToolRequest(name: 'test', arguments: {})),
        );

        final capturedArgs =
            verify(() => mockCommandRunner.run(captureAny())).captured.first
                as List<String>;
        // Default is --no-optimization
        expect(capturedArgs, ['test', '--no-optimization']);
      });

      /*test('handles all arguments', () async {
        await sendRequest(
          CallToolRequest.methodName,
          _params(
            CallToolRequest(
              name: 'test',
              arguments: {
                'dart': true,
                'directory': 'my_dir',
                'coverage': true,
                'recursive': true,
                'optimization': true,
                'concurrency': '8',
                'tags': 'a,b',
                'exclude_coverage': false,
                'exclude_tags': 'c,d',
                'min_coverage': '90',
                'test_randomize_ordering_seed': '123',
                'update_goldens': true,
                'force_ansi': true,
                'dart-define': 'foo=bar',
                'dart-define-from-file': 'my_file.json',
                'platform': 'chrome',
              },
            ),
          ),
        );

        final capturedArgs =
            verify(() => mockCommandRunner.run(captureAny())).captured.first
                as List<String>;
        expect(capturedArgs, [
          'dart',
          'test',
          'my_dir',
          '--coverage',
          '-r',
          '--optimization',
          '-j',
          '8',
          '-t',
          'a,b',
          '--exclude-coverage',
          '-x',
          'c,d',
          '--min-coverage',
          '90',
          '--test-randomize-ordering_seed',
          '123',
          '--update-goldens',
          '--force-ansi',
          '--dart-define',
          'foo=bar',
          '--dart-define-from-file',
          'my_file.json',
          '--platform',
          'chrome',
        ])
      });*/

      test('handles command failure', () async {
        when(
          () => mockCommandRunner.run(any()),
        ).thenAnswer((_) async => ExitCode.software.code);
        final response = await sendRequest(
          CallToolRequest.methodName,
          _params(CallToolRequest(name: 'test', arguments: {})),
        );

        expect(response['error'], isNull);
        final result = CallToolResult.fromMap(
          response['result'] as Map<String, Object?>,
        );
        expect(result.isError, isTrue);
        expect(
          (result.content.first as TextContent).text,
          'Tests failed',
        );
      });
    });

    group('Tool: packages_get', () {
      test('handles basic case', () async {
        await sendRequest(
          CallToolRequest.methodName,
          _params(CallToolRequest(name: 'packages_get', arguments: {})),
        );

        final capturedArgs =
            verify(() => mockCommandRunner.run(captureAny())).captured.first
                as List<String>;
        expect(capturedArgs, ['packages', 'get']);
      });

      test('handles all arguments (with split "ignore")', () async {
        await sendRequest(
          CallToolRequest.methodName,
          _params(
            CallToolRequest(
              name: 'packages_get',
              arguments: {
                'directory': 'my_dir',
                'recursive': true,
                'ignore': 'pkg1, pkg2',
              },
            ),
          ),
        );

        final capturedArgs =
            verify(() => mockCommandRunner.run(captureAny())).captured.first
                as List<String>;
        expect(capturedArgs, [
          'packages',
          'get',
          'my_dir',
          '--recursive',
          '--ignore',
          'pkg1',
          '--ignore',
          'pkg2',
        ]);
      });
    });

    group('Tool: packages_check', () {
      test('handles basic case (licenses=true)', () async {
        await sendRequest(
          CallToolRequest.methodName,
          _params(
            CallToolRequest(
              name: 'packages_check',
              arguments: {'licenses': true, 'directory': 'my_dir'},
            ),
          ),
        );

        final capturedArgs =
            verify(() => mockCommandRunner.run(captureAny())).captured.first
                as List<String>;
        expect(capturedArgs, ['packages', 'check', 'licenses', 'my_dir']);
      });

      test('defaults to licenses=true if not provided', () async {
        await sendRequest(
          CallToolRequest.methodName,
          _params(
            CallToolRequest(
              name: 'packages_check',
              arguments: {'directory': 'my_dir'},
            ),
          ),
        );

        final capturedArgs =
            verify(() => mockCommandRunner.run(captureAny())).captured.first
                as List<String>;
        expect(capturedArgs, ['packages', 'check', 'licenses', 'my_dir']);
      });

      test('returns error if licenses=false', () async {
        final response = await sendRequest(
          CallToolRequest.methodName,
          _params(
            CallToolRequest(
              name: 'packages_check',
              arguments: {'licenses': false},
            ),
          ),
        );

        expect(response['error'], isNull);
        final result = CallToolResult.fromMap(
          response['result'] as Map<String, Object?>,
        );
        expect(result.isError, isTrue);
        expect(
          (result.content.first as TextContent).text,
          contains('No check specified'),
        );
        verifyNever(() => mockCommandRunner.run(any()));
      });
    });

    group('_runCommand error handling', () {
      test('handles UsageException', () async {
        final exception = UsageException('bad usage', 'usage string');
        when(() => mockCommandRunner.run(any())).thenThrow(exception);

        final response = await sendRequest(
          CallToolRequest.methodName,
          _params(
            CallToolRequest(
              name: 'create',
              arguments: {'subcommand': 'flutter_app', 'name': 'my_app'},
            ),
          ),
        );

        expect(response['error'], isNull);
        final result = CallToolResult.fromMap(
          response['result'] as Map<String, Object?>,
        );
        // The handler returns its own error
        expect(result.isError, isTrue);
        expect(
          (result.content.first as TextContent).text,
          'Failed to create project',
        );
        // But the server logs the specific usage error
        verify(() => mockLogger.err('Usage error: bad usage')).called(1);
      });

      test('handles general Exception', () async {
        final exception = Exception('big bad');
        when(() => mockCommandRunner.run(any())).thenThrow(exception);

        final response = await sendRequest(
          CallToolRequest.methodName,
          _params(
            CallToolRequest(
              name: 'create',
              arguments: {'subcommand': 'flutter_app', 'name': 'my_app'},
            ),
          ),
        );

        expect(response['error'], isNull);
        final result = CallToolResult.fromMap(
          response['result'] as Map<String, Object?>,
        );
        // The handler returns its own error
        expect(result.isError, isTrue);
        expect(
          (result.content.first as TextContent).text,
          'Failed to create project',
        );
        // But the server logs the specific exception
        verify(
          () => mockLogger.err('Command error: Exception: big bad'),
        ).called(1);
        verify(
          () => mockLogger.err(any(that: startsWith('Stack trace:'))),
        ).called(1);
      });
    });
  });
}
